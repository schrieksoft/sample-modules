///////////////////////////////////////////////////////////////////////////////
//
//  namespace: identity
//
///////////////////////////////////////////////////////////////////////////////

resource "snapcd_namespace" "identity" {
  name                               = "identity"
  stack_id                           = snapcd_stack.prod.id
  default_apply_approval_threshold   = 0
  default_destroy_approval_threshold = 0
}

resource "snapcd_runner_namespace_supply" "identity" {
  runner_id    = data.snapcd_runner.identity.id
  namespace_id = snapcd_namespace.identity.id
}

// ── state: Snap CD's built-in State Store, as the Terraform HTTP backend ──
//
// Every module in this namespace gets an `extra_root.tf` declaring the http backend,
// plus the -backend-config flags pointing it at the State Store API. State is keyed by
// <namespace>--<module> so two modules can share a name across namespaces without
// colliding.

resource "snapcd_namespace_extra_file" "identity_http_backend" {
  file_name    = "extra_root.tf"
  contents     = <<EOT
terraform {
  backend "http" {}
}
  EOT
  namespace_id = snapcd_namespace.identity.id
  overwrite    = false
}

resource "snapcd_namespace_terraform_flag" "identity_init_flags" {
  for_each = toset(["Upgrade", "MigrateState"])

  namespace_id = snapcd_namespace.identity.id
  task         = "Init"
  flag         = each.value
}

resource "snapcd_namespace_input_from_definition" "identity_state_key" {
  for_each = {
    SNAPCD_NAMESPACE_NAME = "NamespaceName"
    SNAPCD_MODULE_NAME    = "ModuleName"
  }

  name            = each.key
  definition_name = each.value
  usage_mode      = "UseByDefault"
  namespace_id    = snapcd_namespace.identity.id
  input_kind      = "EnvVar"
}

resource "snapcd_namespace_terraform_array_flag" "identity_http_backend" {
  for_each = {
    address        = "${var.snapcd_server_url_from_runner}/api/state/${data.snapcd_state_store.default.id}/$${SNAPCD_NAMESPACE_NAME}--$${SNAPCD_MODULE_NAME}"
    lock_address   = "${var.snapcd_server_url_from_runner}/api/state/${data.snapcd_state_store.default.id}/$${SNAPCD_NAMESPACE_NAME}--$${SNAPCD_MODULE_NAME}/lock"
    unlock_address = "${var.snapcd_server_url_from_runner}/api/state/${data.snapcd_state_store.default.id}/$${SNAPCD_NAMESPACE_NAME}--$${SNAPCD_MODULE_NAME}/unlock"
    lock_method    = "POST"
    unlock_method  = "POST"
    username       = "${var.organization_id}:$${SNAPCD_CLIENT_ID}"
    password       = "$${SNAPCD_CLIENT_SECRET}"
  }

  namespace_id = snapcd_namespace.identity.id
  task         = "Init"
  flag         = "BackendConfig"
  value        = "${each.key}=${each.value}"
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
