import os, shutil
from spec import SPEC, NAMESPACES, NS_ORDER

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

def w(path, s):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    open(path, "w").write(s.rstrip() + "\n")

# ─────────────────────────────────────────────────────────── mock modules ────

def gen_module(ns, name, d):
    base = f"{ROOT}/modules/{ns}/{name}"

    w(f"{base}/root.tf", '''terraform {
  required_providers {
    random = {
      source  = "hashicorp/random"
      version = "3.6.0"
    }
    time = {
      source  = "hashicorp/time"
      version = "0.11.2"
    }
  }
}''')

    # variables: the from_* dep inputs (any type — they arrive as the upstream's
    # whole output map) plus the module's own literals.
    v = []
    for dep_var, target in sorted(d["deps"].items()):
        v.append(f'''variable "{dep_var}" {{
  description = "All outputs of the '{target}' module, wired by Snap CD."
  type        = any
  default     = {{}}
}}''')
    for var, default in sorted(d["vars"].items()):
        v.append(f'''variable "{var}" {{
  type    = string
  default = "{default}"
}}''')
    w(f"{base}/variables.tf", "\n\n".join(v) if v else "# no inputs")

    # main: a settle delay so jobs take visible time on camera, plus a uuid per
    # uuid-kind output.
    uuids = [k for k, kind in d["outputs"].items() if kind == "uuid"]
    m = ['''variable "settle_seconds" {
  description = "Mock work. Gives jobs a visible duration in the dashboard."
  type        = string
  default     = "5s"
}

resource "time_sleep" "settle" {
  create_duration  = var.settle_seconds
  destroy_duration = var.settle_seconds
}''']
    for u in uuids:
        m.append(f'''resource "random_uuid" "{u}" {{
  depends_on = [time_sleep.settle]
}}''')
    w(f"{base}/main.tf", "\n\n".join(m))

    # outputs
    o = []
    for k, kind in d["outputs"].items():
        if kind == "uuid":
            val = f"random_uuid.{k}.result"
        elif kind.startswith("var:"):
            val = f"var.{kind[4:]}"
        elif kind.startswith("list:"):
            items = ", ".join(f'"{x}"' for x in kind[5:].split(","))
            val = f"[{items}]"
        else:
            val = f'"{kind[4:]}"'
        o.append(f'output "{k}" {{\n  value = {val}\n}}')
    w(f"{base}/outputs.tf", "\n\n".join(o))

# ────────────────────────────────────────────────────────── snapcd wiring ────

def gen_namespace_tf(ns):
    cfg = NAMESPACES[ns]
    mods = SPEC[ns]
    L = [f'''///////////////////////////////////////////////////////////////////////////////
//
//  namespace: {ns}
//
///////////////////////////////////////////////////////////////////////////////

resource "snapcd_namespace" "{ns}" {{
  name                               = "{ns}"
  stack_id                           = snapcd_stack.prod.id
  default_apply_approval_threshold   = {cfg["apply"]}
  default_destroy_approval_threshold = {cfg["destroy"]}
}}

resource "snapcd_runner_namespace_supply" "{ns}" {{
  runner_id    = data.snapcd_runner.{cfg["runner"]}.id
  namespace_id = snapcd_namespace.{ns}.id
}}

// ── state: Snap CD's built-in State Store, as the Terraform HTTP backend ──
//
// Every module in this namespace gets an `extra_root.tf` declaring the http backend,
// plus the -backend-config flags pointing it at the State Store API. State is keyed by
// <namespace>--<module> so two modules can share a name across namespaces without
// colliding.

resource "snapcd_namespace_extra_file" "{ns}_http_backend" {{
  file_name    = "extra_root.tf"
  contents     = <<EOT
terraform {{
  backend "http" {{}}
}}
  EOT
  namespace_id = snapcd_namespace.{ns}.id
  overwrite    = false
}}

resource "snapcd_namespace_terraform_flag" "{ns}_init_flags" {{
  for_each = toset(["Upgrade", "MigrateState"])

  namespace_id = snapcd_namespace.{ns}.id
  task         = "Init"
  flag         = each.value
}}

resource "snapcd_namespace_input_from_definition" "{ns}_state_key" {{
  for_each = {{
    SNAPCD_NAMESPACE_NAME = "NamespaceName"
    SNAPCD_MODULE_NAME    = "ModuleName"
  }}

  name            = each.key
  definition_name = each.value
  usage_mode      = "UseByDefault"
  namespace_id    = snapcd_namespace.{ns}.id
  input_kind      = "EnvVar"
}}

resource "snapcd_namespace_terraform_array_flag" "{ns}_http_backend" {{
  for_each = {{
    address        = "${{var.snapcd_server_url_from_runner}}/api/state/${{data.snapcd_state_store.default.id}}/$${{SNAPCD_NAMESPACE_NAME}}--$${{SNAPCD_MODULE_NAME}}"
    lock_address   = "${{var.snapcd_server_url_from_runner}}/api/state/${{data.snapcd_state_store.default.id}}/$${{SNAPCD_NAMESPACE_NAME}}--$${{SNAPCD_MODULE_NAME}}/lock"
    unlock_address = "${{var.snapcd_server_url_from_runner}}/api/state/${{data.snapcd_state_store.default.id}}/$${{SNAPCD_NAMESPACE_NAME}}--$${{SNAPCD_MODULE_NAME}}/unlock"
    lock_method    = "POST"
    unlock_method  = "POST"
    username       = "${{var.organization_id}}:$${{SNAPCD_CLIENT_ID}}"
    password       = "$${{SNAPCD_CLIENT_SECRET}}"
  }}

  namespace_id = snapcd_namespace.{ns}.id
  task         = "Init"
  flag         = "BackendConfig"
  value        = "${{each.key}}=${{each.value}}"
}}''']

    for name, d in mods.items():
        L.append(f'''
// ── {ns}/{name} ──

resource "snapcd_module" "{ns}_{name}" {{
  depends_on          = [snapcd_runner_namespace_supply.{ns}]
  name                = "{name}"
  namespace_id        = snapcd_namespace.{ns}.id
  source_url          = var.source_url
  source_revision     = var.source_revision
  source_subdirectory = "modules/{ns}/{name}"
  runner_id           = data.snapcd_runner.{cfg["runner"]}.id
}}''')

        if d["vars"]:
            entries = "\n".join(f'    {k} = "{v}"' for k, v in sorted(d["vars"].items()))
            L.append(f'''
resource "snapcd_module_input_from_literal" "{ns}_{name}" {{
  for_each = {{
{entries}
  }}
  input_kind    = "Param"
  module_id     = snapcd_module.{ns}_{name}.id
  name          = each.key
  literal_value = each.value
  type          = "String"
}}''')

        for dep_var, target in sorted(d["deps"].items()):
            t_ns, t_mod = target.split("/")
            L.append(f'''
resource "snapcd_module_input_from_output_set" "{ns}_{name}__{dep_var}" {{
  input_kind       = "Param"
  module_id        = snapcd_module.{ns}_{name}.id
  name             = "{dep_var}"
  output_module_id = snapcd_module.{t_ns}_{t_mod}.id
}}''')

    w(f"{ROOT}/namespace_{ns}.tf", "\n".join(L))

# ───────────────────────────────────────────────────────────────── build ─────

# Prune anything no longer in the spec — otherwise renaming a namespace or
# module silently leaves the old directory behind and it still gets deployed.
want = {f"{ns}/{m}" for ns, mods in SPEC.items() for m in mods}
if os.path.isdir(f"{ROOT}/modules"):
    for ns in os.listdir(f"{ROOT}/modules"):
        for m in os.listdir(f"{ROOT}/modules/{ns}"):
            if f"{ns}/{m}" not in want:
                shutil.rmtree(f"{ROOT}/modules/{ns}/{m}")
                print(f"  pruned stale module: {ns}/{m}")
        if not os.listdir(f"{ROOT}/modules/{ns}"):
            os.rmdir(f"{ROOT}/modules/{ns}")
            print(f"  pruned stale namespace dir: {ns}")
for f in os.listdir(ROOT):
    if f.startswith("namespace_") and f.endswith(".tf"):
        if f[len("namespace_"):-3] not in SPEC:
            os.remove(f"{ROOT}/{f}")
            print(f"  pruned stale wiring: {f}")

for ns, mods in SPEC.items():
    for name, d in mods.items():
        gen_module(ns, name, d)
    gen_namespace_tf(ns)

n = sum(len(m) for m in SPEC.values())
print(f"generated {n} mock modules + {len(SPEC)} namespace files")
