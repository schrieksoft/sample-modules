///////////////////////////////////////////////////////////////////////////////
//
//  namespace: storage
//
///////////////////////////////////////////////////////////////////////////////

resource "snapcd_namespace" "storage" {
  name                               = "storage"
  stack_id                           = snapcd_stack.prod.id
  default_apply_approval_threshold   = 0
  default_destroy_approval_threshold = 0
}

resource "snapcd_runner_namespace_supply" "storage" {
  runner_id    = data.snapcd_runner.azure.id
  namespace_id = snapcd_namespace.storage.id
}

// ── state: Snap CD's built-in State Store, as the Terraform HTTP backend ──
//
// Every module in this namespace gets an `extra_root.tf` declaring the http backend,
// plus the -backend-config flags pointing it at the State Store API. State is keyed by
// <namespace>--<module> so two modules can share a name across namespaces without
// colliding.

resource "snapcd_namespace_extra_file" "storage_http_backend" {
  file_name    = "extra_root.tf"
  contents     = <<EOT
terraform {
  backend "http" {}
}
  EOT
  namespace_id = snapcd_namespace.storage.id
  overwrite    = false
}

resource "snapcd_namespace_terraform_flag" "storage_init_flags" {
  for_each = toset(["Upgrade", "MigrateState"])

  namespace_id = snapcd_namespace.storage.id
  task         = "Init"
  flag         = each.value
}

resource "snapcd_namespace_input_from_definition" "storage_state_key" {
  for_each = {
    SNAPCD_NAMESPACE_NAME = "NamespaceName"
    SNAPCD_MODULE_NAME    = "ModuleName"
  }

  name            = each.key
  definition_name = each.value
  usage_mode      = "UseByDefault"
  namespace_id    = snapcd_namespace.storage.id
  input_kind      = "EnvVar"
}

resource "snapcd_namespace_terraform_array_flag" "storage_http_backend" {
  for_each = {
    address        = "${var.snapcd_server_url_from_runner}/api/state/${data.snapcd_state_store.default.id}/$${SNAPCD_NAMESPACE_NAME}--$${SNAPCD_MODULE_NAME}"
    lock_address   = "${var.snapcd_server_url_from_runner}/api/state/${data.snapcd_state_store.default.id}/$${SNAPCD_NAMESPACE_NAME}--$${SNAPCD_MODULE_NAME}/lock"
    unlock_address = "${var.snapcd_server_url_from_runner}/api/state/${data.snapcd_state_store.default.id}/$${SNAPCD_NAMESPACE_NAME}--$${SNAPCD_MODULE_NAME}/unlock"
    lock_method    = "POST"
    unlock_method  = "POST"
    username       = "${var.organization_id}:$${SNAPCD_CLIENT_ID}"
    password       = "$${SNAPCD_CLIENT_SECRET}"
  }

  namespace_id = snapcd_namespace.storage.id
  task         = "Init"
  flag         = "BackendConfig"
  value        = "${each.key}=${each.value}"
}

// ── storage/base ──

resource "snapcd_module" "storage_base" {
  depends_on          = [snapcd_runner_namespace_supply.storage]
  name                = "base"
  namespace_id        = snapcd_namespace.storage.id
  source_url          = var.source_url
  source_revision     = var.source_revision
  source_subdirectory = "modules/storage/base"
  runner_id           = data.snapcd_runner.azure.id
}

resource "snapcd_module_input_from_literal" "storage_base" {
  for_each = {
    environment = "prod"
    location    = "westeurope"
  }
  input_kind    = "Param"
  module_id     = snapcd_module.storage_base.id
  name          = each.key
  literal_value = each.value
  type          = "String"
}

// ── storage/key_vaults ──

resource "snapcd_module" "storage_key_vaults" {
  depends_on          = [snapcd_runner_namespace_supply.storage]
  name                = "key_vaults"
  namespace_id        = snapcd_namespace.storage.id
  source_url          = var.source_url
  source_revision     = var.source_revision
  source_subdirectory = "modules/storage/key_vaults"
  runner_id           = data.snapcd_runner.azure.id
}

resource "snapcd_module_input_from_output_set" "storage_key_vaults__from_azure_ad_groups" {
  input_kind       = "Param"
  module_id        = snapcd_module.storage_key_vaults.id
  name             = "from_azure_ad_groups"
  output_module_id = snapcd_module.identity_azure_ad_groups.id
}

resource "snapcd_module_input_from_output_set" "storage_key_vaults__from_base" {
  input_kind       = "Param"
  module_id        = snapcd_module.storage_key_vaults.id
  name             = "from_base"
  output_module_id = snapcd_module.storage_base.id
}

// ── storage/state_backend ──

resource "snapcd_module" "storage_state_backend" {
  depends_on          = [snapcd_runner_namespace_supply.storage]
  name                = "state_backend"
  namespace_id        = snapcd_namespace.storage.id
  source_url          = var.source_url
  source_revision     = var.source_revision
  source_subdirectory = "modules/storage/state_backend"
  runner_id           = data.snapcd_runner.azure.id
}

resource "snapcd_module_input_from_output_set" "storage_state_backend__from_base" {
  input_kind       = "Param"
  module_id        = snapcd_module.storage_state_backend.id
  name             = "from_base"
  output_module_id = snapcd_module.storage_base.id
}

// ── storage/storage_accounts ──

resource "snapcd_module" "storage_storage_accounts" {
  depends_on          = [snapcd_runner_namespace_supply.storage]
  name                = "storage_accounts"
  namespace_id        = snapcd_namespace.storage.id
  source_url          = var.source_url
  source_revision     = var.source_revision
  source_subdirectory = "modules/storage/storage_accounts"
  runner_id           = data.snapcd_runner.azure.id
}

resource "snapcd_module_input_from_output_set" "storage_storage_accounts__from_base" {
  input_kind       = "Param"
  module_id        = snapcd_module.storage_storage_accounts.id
  name             = "from_base"
  output_module_id = snapcd_module.storage_base.id
}

resource "snapcd_module_input_from_output_set" "storage_storage_accounts__from_vpc" {
  input_kind       = "Param"
  module_id        = snapcd_module.storage_storage_accounts.id
  name             = "from_vpc"
  output_module_id = snapcd_module.networking_vpc.id
}

// ── storage/sql_server ──

resource "snapcd_module" "storage_sql_server" {
  depends_on          = [snapcd_runner_namespace_supply.storage]
  name                = "sql_server"
  namespace_id        = snapcd_namespace.storage.id
  source_url          = var.source_url
  source_revision     = var.source_revision
  source_subdirectory = "modules/storage/sql_server"
  runner_id           = data.snapcd_runner.azure.id
}

resource "snapcd_module_input_from_literal" "storage_sql_server" {
  for_each = {
    sql_admin_login = "sqladmin"
    sql_server_name = "sql-prod"
  }
  input_kind    = "Param"
  module_id     = snapcd_module.storage_sql_server.id
  name          = each.key
  literal_value = each.value
  type          = "String"
}

resource "snapcd_module_input_from_output_set" "storage_sql_server__from_base" {
  input_kind       = "Param"
  module_id        = snapcd_module.storage_sql_server.id
  name             = "from_base"
  output_module_id = snapcd_module.storage_base.id
}

resource "snapcd_module_input_from_output_set" "storage_sql_server__from_private_dns" {
  input_kind       = "Param"
  module_id        = snapcd_module.storage_sql_server.id
  name             = "from_private_dns"
  output_module_id = snapcd_module.networking_private_dns.id
}

resource "snapcd_module_input_from_output_set" "storage_sql_server__from_vpc" {
  input_kind       = "Param"
  module_id        = snapcd_module.storage_sql_server.id
  name             = "from_vpc"
  output_module_id = snapcd_module.networking_vpc.id
}

// ── storage/postgres ──

resource "snapcd_module" "storage_postgres" {
  depends_on          = [snapcd_runner_namespace_supply.storage]
  name                = "postgres"
  namespace_id        = snapcd_namespace.storage.id
  source_url          = var.source_url
  source_revision     = var.source_revision
  source_subdirectory = "modules/storage/postgres"
  runner_id           = data.snapcd_runner.azure.id
}

resource "snapcd_module_input_from_literal" "storage_postgres" {
  for_each = {
    postgres_server_name = "pg-prod"
    postgres_version     = "16"
  }
  input_kind    = "Param"
  module_id     = snapcd_module.storage_postgres.id
  name          = each.key
  literal_value = each.value
  type          = "String"
}

resource "snapcd_module_input_from_output_set" "storage_postgres__from_base" {
  input_kind       = "Param"
  module_id        = snapcd_module.storage_postgres.id
  name             = "from_base"
  output_module_id = snapcd_module.storage_base.id
}

resource "snapcd_module_input_from_output_set" "storage_postgres__from_private_dns" {
  input_kind       = "Param"
  module_id        = snapcd_module.storage_postgres.id
  name             = "from_private_dns"
  output_module_id = snapcd_module.networking_private_dns.id
}

resource "snapcd_module_input_from_output_set" "storage_postgres__from_vpc" {
  input_kind       = "Param"
  module_id        = snapcd_module.storage_postgres.id
  name             = "from_vpc"
  output_module_id = snapcd_module.networking_vpc.id
}

// ── storage/redis ──

resource "snapcd_module" "storage_redis" {
  depends_on          = [snapcd_runner_namespace_supply.storage]
  name                = "redis"
  namespace_id        = snapcd_namespace.storage.id
  source_url          = var.source_url
  source_revision     = var.source_revision
  source_subdirectory = "modules/storage/redis"
  runner_id           = data.snapcd_runner.azure.id
}

resource "snapcd_module_input_from_literal" "storage_redis" {
  for_each = {
    redis_name = "redis-prod"
    redis_sku  = "Standard"
  }
  input_kind    = "Param"
  module_id     = snapcd_module.storage_redis.id
  name          = each.key
  literal_value = each.value
  type          = "String"
}

resource "snapcd_module_input_from_output_set" "storage_redis__from_base" {
  input_kind       = "Param"
  module_id        = snapcd_module.storage_redis.id
  name             = "from_base"
  output_module_id = snapcd_module.storage_base.id
}

resource "snapcd_module_input_from_output_set" "storage_redis__from_private_dns" {
  input_kind       = "Param"
  module_id        = snapcd_module.storage_redis.id
  name             = "from_private_dns"
  output_module_id = snapcd_module.networking_private_dns.id
}

resource "snapcd_module_input_from_output_set" "storage_redis__from_vpc" {
  input_kind       = "Param"
  module_id        = snapcd_module.storage_redis.id
  name             = "from_vpc"
  output_module_id = snapcd_module.networking_vpc.id
}
