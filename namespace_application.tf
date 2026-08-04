///////////////////////////////////////////////////////////////////////////////
//
//  namespace: application
//
///////////////////////////////////////////////////////////////////////////////

resource "snapcd_namespace" "application" {
  name                               = "application"
  stack_id                           = snapcd_stack.prod.id
  default_apply_approval_threshold   = 0
  default_destroy_approval_threshold = 0
}

resource "snapcd_runner_namespace_supply" "application" {
  runner_id    = data.snapcd_runner.k8s.id
  namespace_id = snapcd_namespace.application.id
}

// ── state: Snap CD's built-in State Store, as the Terraform HTTP backend ──
//
// Every module in this namespace gets an `extra_root.tf` declaring the http backend,
// plus the -backend-config flags pointing it at the State Store API. State is keyed by
// <namespace>--<module> so two modules can share a name across namespaces without
// colliding.

resource "snapcd_namespace_extra_file" "application_http_backend" {
  file_name    = "extra_root.tf"
  contents     = <<EOT
terraform {
  backend "http" {}
}
  EOT
  namespace_id = snapcd_namespace.application.id
  overwrite    = false
}

resource "snapcd_namespace_terraform_flag" "application_init_flags" {
  for_each = toset(["Upgrade", "MigrateState"])

  namespace_id = snapcd_namespace.application.id
  task         = "Init"
  flag         = each.value
}

resource "snapcd_namespace_input_from_definition" "application_state_key" {
  for_each = {
    SNAPCD_NAMESPACE_NAME = "NamespaceName"
    SNAPCD_MODULE_NAME    = "ModuleName"
  }

  name            = each.key
  definition_name = each.value
  usage_mode      = "UseByDefault"
  namespace_id    = snapcd_namespace.application.id
  input_kind      = "EnvVar"
}

resource "snapcd_namespace_terraform_array_flag" "application_http_backend" {
  for_each = {
    address        = "${var.snapcd_server_url_from_runner}/api/${var.organization_id}/state/${data.snapcd_state_store.default.id}/$${SNAPCD_NAMESPACE_NAME}--$${SNAPCD_MODULE_NAME}"
    lock_address   = "${var.snapcd_server_url_from_runner}/api/${var.organization_id}/state/${data.snapcd_state_store.default.id}/$${SNAPCD_NAMESPACE_NAME}--$${SNAPCD_MODULE_NAME}/lock"
    unlock_address = "${var.snapcd_server_url_from_runner}/api/${var.organization_id}/state/${data.snapcd_state_store.default.id}/$${SNAPCD_NAMESPACE_NAME}--$${SNAPCD_MODULE_NAME}/unlock"
    lock_method    = "POST"
    unlock_method  = "POST"
    username       = "$${SNAPCD_CLIENT_ID}"
    password       = "$${SNAPCD_CLIENT_SECRET}"
  }

  namespace_id = snapcd_namespace.application.id
  task         = "Init"
  flag         = "BackendConfig"
  value        = "${each.key}=${each.value}"
}

// ── application/storefront_api_infra ──

resource "snapcd_module" "application_storefront_api_infra" {
  depends_on          = [snapcd_runner_namespace_supply.application]
  name                = "storefront_api_infra"
  namespace_id        = snapcd_namespace.application.id
  source_url          = var.source_url
  source_revision     = var.source_revision
  source_subdirectory = "modules/application/storefront_api_infra"
  runner_id           = data.snapcd_runner.k8s.id
}

resource "snapcd_module_input_from_literal" "application_storefront_api_infra" {
  for_each = {
    database_name = "storefront"
    database_sku  = "S1"
  }
  input_kind    = "Param"
  module_id     = snapcd_module.application_storefront_api_infra.id
  name          = each.key
  literal_value = each.value
  type          = "String"
}

resource "snapcd_module_input_from_output_set" "application_storefront_api_infra__from_base" {
  input_kind       = "Param"
  module_id        = snapcd_module.application_storefront_api_infra.id
  name             = "from_base"
  output_module_id = snapcd_module.storage_base.id
}

resource "snapcd_module_input_from_output_set" "application_storefront_api_infra__from_key_vaults" {
  input_kind       = "Param"
  module_id        = snapcd_module.application_storefront_api_infra.id
  name             = "from_key_vaults"
  output_module_id = snapcd_module.storage_key_vaults.id
}

resource "snapcd_module_input_from_output_set" "application_storefront_api_infra__from_sql_server" {
  input_kind       = "Param"
  module_id        = snapcd_module.application_storefront_api_infra.id
  name             = "from_sql_server"
  output_module_id = snapcd_module.storage_sql_server.id
}

// ── application/storefront_api_app ──

resource "snapcd_module" "application_storefront_api_app" {
  depends_on          = [snapcd_runner_namespace_supply.application]
  name                = "storefront_api_app"
  namespace_id        = snapcd_namespace.application.id
  source_url          = var.source_url
  source_revision     = var.source_revision
  source_subdirectory = "modules/application/storefront_api_app"
  runner_id           = data.snapcd_runner.k8s.id
}

resource "snapcd_module_input_from_literal" "application_storefront_api_app" {
  for_each = {
    image_tag = "v1.4.0"
    replicas  = "3"
  }
  input_kind    = "Param"
  module_id     = snapcd_module.application_storefront_api_app.id
  name          = each.key
  literal_value = each.value
  type          = "String"
}

resource "snapcd_module_input_from_output_set" "application_storefront_api_app__from_cloudflare_dns" {
  input_kind       = "Param"
  module_id        = snapcd_module.application_storefront_api_app.id
  name             = "from_cloudflare_dns"
  output_module_id = snapcd_module.platform_cloudflare_dns.id
}

resource "snapcd_module_input_from_output_set" "application_storefront_api_app__from_cluster" {
  input_kind       = "Param"
  module_id        = snapcd_module.application_storefront_api_app.id
  name             = "from_cluster"
  output_module_id = snapcd_module.platform_cluster.id
}

resource "snapcd_module_input_from_output_set" "application_storefront_api_app__from_istio" {
  input_kind       = "Param"
  module_id        = snapcd_module.application_storefront_api_app.id
  name             = "from_istio"
  output_module_id = snapcd_module.platform_istio.id
}

resource "snapcd_module_input_from_output_set" "application_storefront_api_app__from_storefront_api_infra" {
  input_kind       = "Param"
  module_id        = snapcd_module.application_storefront_api_app.id
  name             = "from_storefront_api_infra"
  output_module_id = snapcd_module.application_storefront_api_infra.id
}

// ── application/orders_worker_infra ──

resource "snapcd_module" "application_orders_worker_infra" {
  depends_on          = [snapcd_runner_namespace_supply.application]
  name                = "orders_worker_infra"
  namespace_id        = snapcd_namespace.application.id
  source_url          = var.source_url
  source_revision     = var.source_revision
  source_subdirectory = "modules/application/orders_worker_infra"
  runner_id           = data.snapcd_runner.k8s.id
}

resource "snapcd_module_input_from_literal" "application_orders_worker_infra" {
  for_each = {
    database_name = "orders"
  }
  input_kind    = "Param"
  module_id     = snapcd_module.application_orders_worker_infra.id
  name          = each.key
  literal_value = each.value
  type          = "String"
}

resource "snapcd_module_input_from_output_set" "application_orders_worker_infra__from_base" {
  input_kind       = "Param"
  module_id        = snapcd_module.application_orders_worker_infra.id
  name             = "from_base"
  output_module_id = snapcd_module.storage_base.id
}

resource "snapcd_module_input_from_output_set" "application_orders_worker_infra__from_key_vaults" {
  input_kind       = "Param"
  module_id        = snapcd_module.application_orders_worker_infra.id
  name             = "from_key_vaults"
  output_module_id = snapcd_module.storage_key_vaults.id
}

resource "snapcd_module_input_from_output_set" "application_orders_worker_infra__from_postgres" {
  input_kind       = "Param"
  module_id        = snapcd_module.application_orders_worker_infra.id
  name             = "from_postgres"
  output_module_id = snapcd_module.storage_postgres.id
}

resource "snapcd_module_input_from_output_set" "application_orders_worker_infra__from_storage_accounts" {
  input_kind       = "Param"
  module_id        = snapcd_module.application_orders_worker_infra.id
  name             = "from_storage_accounts"
  output_module_id = snapcd_module.storage_storage_accounts.id
}

// ── application/orders_worker_app ──

resource "snapcd_module" "application_orders_worker_app" {
  depends_on          = [snapcd_runner_namespace_supply.application]
  name                = "orders_worker_app"
  namespace_id        = snapcd_namespace.application.id
  source_url          = var.source_url
  source_revision     = var.source_revision
  source_subdirectory = "modules/application/orders_worker_app"
  runner_id           = data.snapcd_runner.k8s.id
}

resource "snapcd_module_input_from_literal" "application_orders_worker_app" {
  for_each = {
    image_tag = "v0.9.1"
    replicas  = "2"
  }
  input_kind    = "Param"
  module_id     = snapcd_module.application_orders_worker_app.id
  name          = each.key
  literal_value = each.value
  type          = "String"
}

resource "snapcd_module_input_from_output_set" "application_orders_worker_app__from_cluster" {
  input_kind       = "Param"
  module_id        = snapcd_module.application_orders_worker_app.id
  name             = "from_cluster"
  output_module_id = snapcd_module.platform_cluster.id
}

resource "snapcd_module_input_from_output_set" "application_orders_worker_app__from_orders_worker_infra" {
  input_kind       = "Param"
  module_id        = snapcd_module.application_orders_worker_app.id
  name             = "from_orders_worker_infra"
  output_module_id = snapcd_module.application_orders_worker_infra.id
}

resource "snapcd_module_input_from_output_set" "application_orders_worker_app__from_redis" {
  input_kind       = "Param"
  module_id        = snapcd_module.application_orders_worker_app.id
  name             = "from_redis"
  output_module_id = snapcd_module.storage_redis.id
}
