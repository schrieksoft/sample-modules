# sample-modules

A **full mocked Snap CD stack** — 35 modules across 6 namespaces, with a real dependency
graph. Built for demos, screenshots and videos: big enough that the graph is the point,
structured the way a real org would structure it, and safe to run anywhere.

Nothing here touches a cloud. Every module is `random_uuid` + `time_sleep`, producing
plausible outputs and no side effects.

```
.
├── stack.tf              the "prod" stack + the Runners
├── namespace_*.tf        one per namespace: the namespace, its modules, and the
│                         inputs that wire them together
└── modules/
    └── <namespace>/
        └── <module>/     a mock deployment: variables in, outputs out
```

## The point

**There is no ordering declared anywhere in this repo.** No `depends_on` between modules,
no pipeline, no glue. Snap CD derives the entire graph from one fact: some modules consume
other modules' outputs.

```hcl
resource "snapcd_module_input_from_output_set" "platform_cluster__from_vpc" {
  input_kind       = "Param"
  module_id        = snapcd_module.platform_cluster.id
  name             = "from_vpc"
  output_module_id = snapcd_module.networking_vpc.id
}
```

That single resource is the whole dependency. `cluster` declares a `variable "from_vpc"`;
`vpc` produces outputs; Snap CD matches them up, works out that `vpc` must apply first, and
re-plans `cluster` whenever `vpc`'s outputs change.

The result is **7 stages** deep. Changing `networking/vpc` cascades to **26 of the 35
modules across 5 namespaces**, in the right order, in parallel where possible.

## Namespaces

Ownership boundaries, not layers — each maps to a team that could own a pager.

| Namespace | Modules | Owns |
|---|---|---|
| `identity` | 5 | Azure AD groups + Snap CD groups, service principals, and **who is in which group — on both sides** |
| `storage` | 7 | Resource groups, Key Vaults, storage accounts, state backend, and the shared database engines — SQL Server, Postgres, Redis |
| `networking` | 5 | VNet, subnets, NSGs, private DNS, VPN, bastion |
| `analytics` | 5 | Data lake, Databricks, warehouse, ETL pipelines |
| `platform` | 9 | AKS, istio, cert-manager, ArgoCD, Cloudflare DNS, docs |
| `application` | 4 | Storefront API, orders worker |

**`storage` owns the database *servers*; each application owns its own *database*.** The
SQL Server instance is shared estate with the storage team's lifecycle; the `storefront`
database on it belongs to the storefront app and is created by `storefront_api_infra`. That
split is why there's no `data` namespace — a database with an application's lifecycle
belongs to the application.

**`analytics` is the warehousing estate** — the lake, Databricks, the warehouse, and the
ETL that fills them. It reaches *into* `application/storefront_api_infra` to read the app's
database, and nothing reaches back. One-way, which is what makes it a real boundary.

`identity` is the interesting one. It manages group *membership* on both Azure AD and Snap
CD, in one graph:

```
azure_ad_groups ──┬── azure_user_group_assignments ──┐
                  │                                  ├── snapcd_user_group_assignments
                  └── snapcd_groups ─────────────────┘
```

`snapcd_user_group_assignments` depends on both the Snap CD groups existing *and* the Azure
side being settled — so onboarding someone is one apply, and their access to Snap CD and to
Azure can't drift apart. Membership is its own module because it changes every time someone
joins or leaves, which is a completely different cadence from the group definitions.

Applications follow an `infra` → `app` couplet: `*_infra` provisions the Azure side —
including the app's own database on the shared server — and outputs a *reference* to a Key
Vault secret; `*_app` deploys the workload and resolves it. The secret value is never a
Snap CD input and never enters state.

## Run it

Defaults target `snapcd-deployment-docker` with a Runner named `default`.

```bash
terraform init
terraform apply
```

Then open the Dashboard — the `prod` stack, its namespaces, and 35 modules will be there,
planning in dependency order.

Against a different Server:

```bash
terraform apply \
  -var snapcd_server_url=https://snapcd.io \
  -var insecure_skip_verify=false \
  -var organization_id=<your-org-guid> \
  -var client_id=<...> -var client_secret=<...>
```

### Runners

The stack declares four Runners, one per credential boundary (`azure`, `k8s`, `analytics`,
`identity`). **For a local demo, leave them all at `default`** — the defaults do this
already, so one Runner serves everything.

Splitting them only matters when the Runners hold genuinely different credentials:

```bash
terraform apply \
  -var azure_runner_name=azure-prod \
  -var k8s_runner_name=k8s-prod \
  -var analytics_runner_name=analytics-prod \
  -var identity_runner_name=identity-prod
```

### Module source

Every `snapcd_module` points at this repo (`var.source_url`) and selects one directory via
`source_subdirectory`. Fork it and set `-var source_url=<your fork>` if you want to edit a
mock and watch Snap CD detect the commit and redeploy.

## The mock modules

Each is four files, following the `snapcd-samples/mock-module-*` convention:

| File | |
|---|---|
| `root.tf` | providers — only `random` and `time`, never a cloud provider |
| `variables.tf` | `from_*` (an upstream's whole output map) + the module's own literals |
| `main.tf` | a `time_sleep` so jobs have a visible duration, and a `random_uuid` per ID output |
| `outputs.tf` | what the module publishes — **this is what the DAG is built from** |

A `from_<x>` variable is typed `any` and defaults to `{}`, because Snap CD passes the
upstream module's entire output set into it. That's what
`snapcd_module_input_from_output_set` does.

Every module takes `settle_seconds` (default `5s`) — the mock "work", and what makes a job
take long enough to watch. Set it to `0s` to converge the whole stack fast, or turn it up
if you want time to talk over a running job.

## Notes

- The modules and the `namespace_*.tf` wiring were generated from a single spec so the
  DAG in the Terraform can't drift from the DAG in the modules. Prefer regenerating over
  hand-editing 35 directories.
- Approval thresholds are set per namespace and get stricter as you go down the stack:
  `application` and `analytics` apply freely, `identity` needs two approvals. See
  `namespace_*.tf`.
- The graph is acyclic and every dependency resolves — verified, along with all 35 modules
  passing `terraform validate`.
