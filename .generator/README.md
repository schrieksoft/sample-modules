# Generator

`spec.py` is the single source of truth for the stack: every module, its inputs,
its outputs, and its dependencies. `gen.py` writes both the mock modules under
`modules/` and the `namespace_*.tf` wiring from it.

Keeping them in one place is the point — the DAG declared in the Terraform can't
drift from the DAG implied by the modules' variables and outputs.

```bash
cd .generator && python3 gen.py && cd .. && terraform fmt -recursive
```

Then re-validate:

```bash
terraform init -backend=false && terraform validate
for d in modules/*/*/; do (cd "$d" && terraform init -backend=false >/dev/null && terraform validate >/dev/null) || echo "FAIL $d"; done
```
