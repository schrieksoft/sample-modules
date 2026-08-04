///////////////////////////////////////////////////////////////////////////////
//
//  namespace: analytics
//
///////////////////////////////////////////////////////////////////////////////

resource "snapcd_namespace" "analytics" {
  name                               = "analytics"
  stack_id                           = snapcd_stack.prod.id
  default_apply_approval_threshold   = 0
  default_destroy_approval_threshold = 0
}

resource "snapcd_runner_namespace_supply" "analytics" {
  runner_id    = data.snapcd_runner.analytics.id
  namespace_id = snapcd_namespace.analytics.id
}

// ── state: Snap CD's built-in State Store, as the Terraform HTTP backend ──
//
// Every module in this namespace gets an `extra_root.tf` declaring the http backend,
// plus the -backend-config flags pointing it at the State Store API. State is keyed by
// <namespace>--<module> so two modules can share a name across namespaces without
// colliding.

resource "snapcd_namespace_extra_file" "analytics_http_backend" {
  file_name    = "extra_root.tf"
  contents     = <<EOT
terraform {
  backend "http" {}
}
  EOT
  namespace_id = snapcd_namespace.analytics.id
  overwrite    = false
}

resource "snapcd_namespace_terraform_flag" "analytics_init_flags" {
  for_each = toset(["Upgrade", "MigrateState"])

  namespace_id = snapcd_namespace.analytics.id
  task         = "Init"
  flag         = each.value
}

resource "snapcd_namespace_input_from_definition" "analytics_state_key" {
  for_each = {
    SNAPCD_NAMESPACE_NAME = "NamespaceName"
    SNAPCD_MODULE_NAME    = "ModuleName"
  }

  name            = each.key
  definition_name = each.value
  usage_mode      = "UseByDefault"
  namespace_id    = snapcd_namespace.analytics.id
  input_kind      = "EnvVar"
}

resource "snapcd_namespace_terraform_array_flag" "analytics_http_backend" {
  for_each = {
    address        = "${var.snapcd_server_url_from_runner}/api/${var.organization_id}/state/${data.snapcd_state_store.default.id}/$${SNAPCD_NAMESPACE_NAME}--$${SNAPCD_MODULE_NAME}"
    lock_address   = "${var.snapcd_server_url_from_runner}/api/${var.organization_id}/state/${data.snapcd_state_store.default.id}/$${SNAPCD_NAMESPACE_NAME}--$${SNAPCD_MODULE_NAME}/lock"
    unlock_address = "${var.snapcd_server_url_from_runner}/api/${var.organization_id}/state/${data.snapcd_state_store.default.id}/$${SNAPCD_NAMESPACE_NAME}--$${SNAPCD_MODULE_NAME}/unlock"
    lock_method    = "POST"
    unlock_method  = "POST"
    username       = "$${SNAPCD_CLIENT_ID}"
    password       = "$${SNAPCD_CLIENT_SECRET}"
  }

  namespace_id = snapcd_namespace.analytics.id
  task         = "Init"
  flag         = "BackendConfig"
  value        = "${each.key}=${each.value}"
}

// ── analytics/data_lake ──

resource "snapcd_module" "analytics_data_lake" {
  depends_on          = [snapcd_runner_namespace_supply.analytics]
  name                = "data_lake"
  namespace_id        = snapcd_namespace.analytics.id
  source_url          = var.source_url
  source_revision     = var.source_revision
  source_subdirectory = "modules/analytics/data_lake"
  runner_id           = data.snapcd_runner.analytics.id
}

resource "snapcd_module_input_from_output_set" "analytics_data_lake__from_private_dns" {
  input_kind       = "Param"
  module_id        = snapcd_module.analytics_data_lake.id
  name             = "from_private_dns"
  output_module_id = snapcd_module.networking_private_dns.id
}

resource "snapcd_module_input_from_output_set" "analytics_data_lake__from_storage_accounts" {
  input_kind       = "Param"
  module_id        = snapcd_module.analytics_data_lake.id
  name             = "from_storage_accounts"
  output_module_id = snapcd_module.storage_storage_accounts.id
}

// ── analytics/databricks ──

resource "snapcd_module" "analytics_databricks" {
  depends_on          = [snapcd_runner_namespace_supply.analytics]
  name                = "databricks"
  namespace_id        = snapcd_namespace.analytics.id
  source_url          = var.source_url
  source_revision     = var.source_revision
  source_subdirectory = "modules/analytics/databricks"
  runner_id           = data.snapcd_runner.analytics.id
}

resource "snapcd_module_input_from_output_set" "analytics_databricks__from_azure_ad_groups" {
  input_kind       = "Param"
  module_id        = snapcd_module.analytics_databricks.id
  name             = "from_azure_ad_groups"
  output_module_id = snapcd_module.identity_azure_ad_groups.id
}

resource "snapcd_module_input_from_output_set" "analytics_databricks__from_data_lake" {
  input_kind       = "Param"
  module_id        = snapcd_module.analytics_databricks.id
  name             = "from_data_lake"
  output_module_id = snapcd_module.analytics_data_lake.id
}

resource "snapcd_module_input_from_output_set" "analytics_databricks__from_vpc" {
  input_kind       = "Param"
  module_id        = snapcd_module.analytics_databricks.id
  name             = "from_vpc"
  output_module_id = snapcd_module.networking_vpc.id
}

// ── analytics/warehouse ──

resource "snapcd_module" "analytics_warehouse" {
  depends_on          = [snapcd_runner_namespace_supply.analytics]
  name                = "warehouse"
  namespace_id        = snapcd_namespace.analytics.id
  source_url          = var.source_url
  source_revision     = var.source_revision
  source_subdirectory = "modules/analytics/warehouse"
  runner_id           = data.snapcd_runner.analytics.id
}

resource "snapcd_module_input_from_literal" "analytics_warehouse" {
  for_each = {
    warehouse_name = "synapse-prod"
  }
  input_kind    = "Param"
  module_id     = snapcd_module.analytics_warehouse.id
  name          = each.key
  literal_value = each.value
  type          = "String"
}

resource "snapcd_module_input_from_output_set" "analytics_warehouse__from_base" {
  input_kind       = "Param"
  module_id        = snapcd_module.analytics_warehouse.id
  name             = "from_base"
  output_module_id = snapcd_module.storage_base.id
}

resource "snapcd_module_input_from_output_set" "analytics_warehouse__from_data_lake" {
  input_kind       = "Param"
  module_id        = snapcd_module.analytics_warehouse.id
  name             = "from_data_lake"
  output_module_id = snapcd_module.analytics_data_lake.id
}

resource "snapcd_module_input_from_output_set" "analytics_warehouse__from_private_dns" {
  input_kind       = "Param"
  module_id        = snapcd_module.analytics_warehouse.id
  name             = "from_private_dns"
  output_module_id = snapcd_module.networking_private_dns.id
}

// ── analytics/etl_pipeline_infra ──

resource "snapcd_module" "analytics_etl_pipeline_infra" {
  depends_on          = [snapcd_runner_namespace_supply.analytics]
  name                = "etl_pipeline_infra"
  namespace_id        = snapcd_namespace.analytics.id
  source_url          = var.source_url
  source_revision     = var.source_revision
  source_subdirectory = "modules/analytics/etl_pipeline_infra"
  runner_id           = data.snapcd_runner.analytics.id
}

resource "snapcd_module_input_from_output_set" "analytics_etl_pipeline_infra__from_base" {
  input_kind       = "Param"
  module_id        = snapcd_module.analytics_etl_pipeline_infra.id
  name             = "from_base"
  output_module_id = snapcd_module.storage_base.id
}

resource "snapcd_module_input_from_output_set" "analytics_etl_pipeline_infra__from_data_lake" {
  input_kind       = "Param"
  module_id        = snapcd_module.analytics_etl_pipeline_infra.id
  name             = "from_data_lake"
  output_module_id = snapcd_module.analytics_data_lake.id
}

resource "snapcd_module_input_from_output_set" "analytics_etl_pipeline_infra__from_databricks" {
  input_kind       = "Param"
  module_id        = snapcd_module.analytics_etl_pipeline_infra.id
  name             = "from_databricks"
  output_module_id = snapcd_module.analytics_databricks.id
}

// ── analytics/etl_pipeline_app ──

resource "snapcd_module" "analytics_etl_pipeline_app" {
  depends_on          = [snapcd_runner_namespace_supply.analytics]
  name                = "etl_pipeline_app"
  namespace_id        = snapcd_namespace.analytics.id
  source_url          = var.source_url
  source_revision     = var.source_revision
  source_subdirectory = "modules/analytics/etl_pipeline_app"
  runner_id           = data.snapcd_runner.analytics.id
}

resource "snapcd_module_input_from_literal" "analytics_etl_pipeline_app" {
  for_each = {
    schedule_cron = "0 2 * * *"
  }
  input_kind    = "Param"
  module_id     = snapcd_module.analytics_etl_pipeline_app.id
  name          = each.key
  literal_value = each.value
  type          = "String"
}

resource "snapcd_module_input_from_output_set" "analytics_etl_pipeline_app__from_databricks" {
  input_kind       = "Param"
  module_id        = snapcd_module.analytics_etl_pipeline_app.id
  name             = "from_databricks"
  output_module_id = snapcd_module.analytics_databricks.id
}

resource "snapcd_module_input_from_output_set" "analytics_etl_pipeline_app__from_etl_pipeline_infra" {
  input_kind       = "Param"
  module_id        = snapcd_module.analytics_etl_pipeline_app.id
  name             = "from_etl_pipeline_infra"
  output_module_id = snapcd_module.analytics_etl_pipeline_infra.id
}

resource "snapcd_module_input_from_output_set" "analytics_etl_pipeline_app__from_storefront_api_infra" {
  input_kind       = "Param"
  module_id        = snapcd_module.analytics_etl_pipeline_app.id
  name             = "from_storefront_api_infra"
  output_module_id = snapcd_module.application_storefront_api_infra.id
}

resource "snapcd_module_input_from_output_set" "analytics_etl_pipeline_app__from_warehouse" {
  input_kind       = "Param"
  module_id        = snapcd_module.analytics_etl_pipeline_app.id
  name             = "from_warehouse"
  output_module_id = snapcd_module.analytics_warehouse.id
}
