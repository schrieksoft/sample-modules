///////////////////////////////////////////////////////////////////////////////
//
//  namespace: identity
//
///////////////////////////////////////////////////////////////////////////////

resource "snapcd_namespace" "identity" {
  name                               = "identity"
  stack_id                           = snapcd_stack.prod.id
  default_apply_approval_threshold   = 2
  default_destroy_approval_threshold = 2
}

resource "snapcd_runner_namespace_supply" "identity" {
  runner_id    = data.snapcd_runner.identity.id
  namespace_id = snapcd_namespace.identity.id
}

// ── identity/azure_ad_groups ──

resource "snapcd_module" "identity_azure_ad_groups" {
  depends_on          = [snapcd_runner_namespace_supply.identity]
  name                = "azure_ad_groups"
  namespace_id        = snapcd_namespace.identity.id
  source_url          = var.source_url
  source_revision     = var.source_revision
  source_subdirectory = "modules/identity/azure_ad_groups"
  runner_id           = data.snapcd_runner.identity.id
}

resource "snapcd_module_input_from_literal" "identity_azure_ad_groups" {
  for_each = {
    tenant_id = "00000000-0000-0000-0000-000000000000"
  }
  input_kind    = "Param"
  module_id     = snapcd_module.identity_azure_ad_groups.id
  name          = each.key
  literal_value = each.value
  type          = "String"
}

// ── identity/azure_service_principals ──

resource "snapcd_module" "identity_azure_service_principals" {
  depends_on          = [snapcd_runner_namespace_supply.identity]
  name                = "azure_service_principals"
  namespace_id        = snapcd_namespace.identity.id
  source_url          = var.source_url
  source_revision     = var.source_revision
  source_subdirectory = "modules/identity/azure_service_principals"
  runner_id           = data.snapcd_runner.identity.id
}

resource "snapcd_module_input_from_output_set" "identity_azure_service_principals__from_azure_ad_groups" {
  input_kind       = "Param"
  module_id        = snapcd_module.identity_azure_service_principals.id
  name             = "from_azure_ad_groups"
  output_module_id = snapcd_module.identity_azure_ad_groups.id
}

// ── identity/snapcd_rbac ──

resource "snapcd_module" "identity_snapcd_rbac" {
  depends_on          = [snapcd_runner_namespace_supply.identity]
  name                = "snapcd_rbac"
  namespace_id        = snapcd_namespace.identity.id
  source_url          = var.source_url
  source_revision     = var.source_revision
  source_subdirectory = "modules/identity/snapcd_rbac"
  runner_id           = data.snapcd_runner.identity.id
}

resource "snapcd_module_input_from_output_set" "identity_snapcd_rbac__from_azure_ad_groups" {
  input_kind       = "Param"
  module_id        = snapcd_module.identity_snapcd_rbac.id
  name             = "from_azure_ad_groups"
  output_module_id = snapcd_module.identity_azure_ad_groups.id
}

// ── identity/snapcd_runners ──

resource "snapcd_module" "identity_snapcd_runners" {
  depends_on          = [snapcd_runner_namespace_supply.identity]
  name                = "snapcd_runners"
  namespace_id        = snapcd_namespace.identity.id
  source_url          = var.source_url
  source_revision     = var.source_revision
  source_subdirectory = "modules/identity/snapcd_runners"
  runner_id           = data.snapcd_runner.identity.id
}

resource "snapcd_module_input_from_output_set" "identity_snapcd_runners__from_azure_service_principals" {
  input_kind       = "Param"
  module_id        = snapcd_module.identity_snapcd_runners.id
  name             = "from_azure_service_principals"
  output_module_id = snapcd_module.identity_azure_service_principals.id
}
