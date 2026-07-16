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

// ── identity/azure_user_group_assignments ──

resource "snapcd_module" "identity_azure_user_group_assignments" {
  depends_on          = [snapcd_runner_namespace_supply.identity]
  name                = "azure_user_group_assignments"
  namespace_id        = snapcd_namespace.identity.id
  source_url          = var.source_url
  source_revision     = var.source_revision
  source_subdirectory = "modules/identity/azure_user_group_assignments"
  runner_id           = data.snapcd_runner.identity.id
}

resource "snapcd_module_input_from_output_set" "identity_azure_user_group_assignments__from_azure_ad_groups" {
  input_kind       = "Param"
  module_id        = snapcd_module.identity_azure_user_group_assignments.id
  name             = "from_azure_ad_groups"
  output_module_id = snapcd_module.identity_azure_ad_groups.id
}

// ── identity/snapcd_groups ──

resource "snapcd_module" "identity_snapcd_groups" {
  depends_on          = [snapcd_runner_namespace_supply.identity]
  name                = "snapcd_groups"
  namespace_id        = snapcd_namespace.identity.id
  source_url          = var.source_url
  source_revision     = var.source_revision
  source_subdirectory = "modules/identity/snapcd_groups"
  runner_id           = data.snapcd_runner.identity.id
}

resource "snapcd_module_input_from_output_set" "identity_snapcd_groups__from_azure_ad_groups" {
  input_kind       = "Param"
  module_id        = snapcd_module.identity_snapcd_groups.id
  name             = "from_azure_ad_groups"
  output_module_id = snapcd_module.identity_azure_ad_groups.id
}

// ── identity/snapcd_user_group_assignments ──

resource "snapcd_module" "identity_snapcd_user_group_assignments" {
  depends_on          = [snapcd_runner_namespace_supply.identity]
  name                = "snapcd_user_group_assignments"
  namespace_id        = snapcd_namespace.identity.id
  source_url          = var.source_url
  source_revision     = var.source_revision
  source_subdirectory = "modules/identity/snapcd_user_group_assignments"
  runner_id           = data.snapcd_runner.identity.id
}

resource "snapcd_module_input_from_output_set" "identity_snapcd_user_group_assignments__from_azure_user_group_assignments" {
  input_kind       = "Param"
  module_id        = snapcd_module.identity_snapcd_user_group_assignments.id
  name             = "from_azure_user_group_assignments"
  output_module_id = snapcd_module.identity_azure_user_group_assignments.id
}

resource "snapcd_module_input_from_output_set" "identity_snapcd_user_group_assignments__from_snapcd_groups" {
  input_kind       = "Param"
  module_id        = snapcd_module.identity_snapcd_user_group_assignments.id
  name             = "from_snapcd_groups"
  output_module_id = snapcd_module.identity_snapcd_groups.id
}
