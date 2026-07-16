///////////////////////////////////////////////////////////////////////////////
//
//  The "prod" stack, and the Runners its namespaces execute on.
//
//  Everything else is in namespace_<name>.tf — one file per namespace, each
//  declaring the namespace, its Runner supply, its modules, and the inputs that
//  wire the modules together.
//
//  The dependency graph is *derived* from those inputs. There is no ordering
//  declared anywhere in this repo: Snap CD works it out from the fact that one
//  module consumes another module's outputs.
//
///////////////////////////////////////////////////////////////////////////////

resource "snapcd_stack" "prod" {
  name = var.stack_name
}

data "snapcd_runner" "azure" {
  name = var.azure_runner_name
}

data "snapcd_runner" "k8s" {
  name = var.k8s_runner_name
}

data "snapcd_runner" "analytics" {
  name = var.analytics_runner_name
}

data "snapcd_runner" "identity" {
  name = var.identity_runner_name
}
