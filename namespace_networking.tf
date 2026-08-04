///////////////////////////////////////////////////////////////////////////////
//
//  namespace: networking
//
///////////////////////////////////////////////////////////////////////////////

resource "snapcd_namespace" "networking" {
  name                               = "networking"
  stack_id                           = snapcd_stack.prod.id
  default_apply_approval_threshold   = 0
  default_destroy_approval_threshold = 0
}

resource "snapcd_runner_namespace_supply" "networking" {
  runner_id    = data.snapcd_runner.azure.id
  namespace_id = snapcd_namespace.networking.id
}

// ── state: Snap CD's built-in State Store, as the Terraform HTTP backend ──
//
// Every module in this namespace gets an `extra_root.tf` declaring the http backend,
// plus the -backend-config flags pointing it at the State Store API. State is keyed by
// <namespace>--<module> so two modules can share a name across namespaces without
// colliding.

resource "snapcd_namespace_extra_file" "networking_http_backend" {
  file_name    = "extra_root.tf"
  contents     = <<EOT
terraform {
  backend "http" {}
}
  EOT
  namespace_id = snapcd_namespace.networking.id
  overwrite    = false
}

resource "snapcd_namespace_terraform_flag" "networking_init_flags" {
  for_each = toset(["Upgrade", "MigrateState"])

  namespace_id = snapcd_namespace.networking.id
  task         = "Init"
  flag         = each.value
}

resource "snapcd_namespace_input_from_definition" "networking_state_key" {
  for_each = {
    SNAPCD_NAMESPACE_NAME = "NamespaceName"
    SNAPCD_MODULE_NAME    = "ModuleName"
  }

  name            = each.key
  definition_name = each.value
  usage_mode      = "UseByDefault"
  namespace_id    = snapcd_namespace.networking.id
  input_kind      = "EnvVar"
}

resource "snapcd_namespace_terraform_array_flag" "networking_http_backend" {
  for_each = {
    address        = "${var.snapcd_server_url_from_runner}/api/${var.organization_id}/state/${data.snapcd_state_store.default.id}/$${SNAPCD_NAMESPACE_NAME}--$${SNAPCD_MODULE_NAME}"
    lock_address   = "${var.snapcd_server_url_from_runner}/api/${var.organization_id}/state/${data.snapcd_state_store.default.id}/$${SNAPCD_NAMESPACE_NAME}--$${SNAPCD_MODULE_NAME}/lock"
    unlock_address = "${var.snapcd_server_url_from_runner}/api/${var.organization_id}/state/${data.snapcd_state_store.default.id}/$${SNAPCD_NAMESPACE_NAME}--$${SNAPCD_MODULE_NAME}/unlock"
    lock_method    = "POST"
    unlock_method  = "POST"
    username       = "$${SNAPCD_CLIENT_ID}"
    password       = "$${SNAPCD_CLIENT_SECRET}"
  }

  namespace_id = snapcd_namespace.networking.id
  task         = "Init"
  flag         = "BackendConfig"
  value        = "${each.key}=${each.value}"
}

// ── networking/vpc ──

resource "snapcd_module" "networking_vpc" {
  depends_on          = [snapcd_runner_namespace_supply.networking]
  name                = "vpc"
  namespace_id        = snapcd_namespace.networking.id
  source_url          = var.source_url
  source_revision     = var.source_revision
  source_subdirectory = "modules/networking/vpc"
  runner_id           = data.snapcd_runner.azure.id
}

resource "snapcd_module_input_from_literal" "networking_vpc" {
  for_each = {
    apps_subnet_cidr    = "10.0.3.0/24"
    data_subnet_cidr    = "10.0.4.0/24"
    private_subnet_cidr = "10.0.1.0/24"
    public_subnet_cidr  = "10.0.2.0/24"
    vpc_cidr_block      = "10.0.0.0/16"
    vpc_name            = "vnet-prod"
  }
  input_kind    = "Param"
  module_id     = snapcd_module.networking_vpc.id
  name          = each.key
  literal_value = each.value
  type          = "String"
}

resource "snapcd_module_input_from_output_set" "networking_vpc__from_base" {
  input_kind       = "Param"
  module_id        = snapcd_module.networking_vpc.id
  name             = "from_base"
  output_module_id = snapcd_module.storage_base.id
}

// ── networking/nsg ──

resource "snapcd_module" "networking_nsg" {
  depends_on          = [snapcd_runner_namespace_supply.networking]
  name                = "nsg"
  namespace_id        = snapcd_namespace.networking.id
  source_url          = var.source_url
  source_revision     = var.source_revision
  source_subdirectory = "modules/networking/nsg"
  runner_id           = data.snapcd_runner.azure.id
}

resource "snapcd_module_input_from_output_set" "networking_nsg__from_vpc" {
  input_kind       = "Param"
  module_id        = snapcd_module.networking_nsg.id
  name             = "from_vpc"
  output_module_id = snapcd_module.networking_vpc.id
}

// ── networking/private_dns ──

resource "snapcd_module" "networking_private_dns" {
  depends_on          = [snapcd_runner_namespace_supply.networking]
  name                = "private_dns"
  namespace_id        = snapcd_namespace.networking.id
  source_url          = var.source_url
  source_revision     = var.source_revision
  source_subdirectory = "modules/networking/private_dns"
  runner_id           = data.snapcd_runner.azure.id
}

resource "snapcd_module_input_from_literal" "networking_private_dns" {
  for_each = {
    private_dns_zone_name = "prod.internal"
  }
  input_kind    = "Param"
  module_id     = snapcd_module.networking_private_dns.id
  name          = each.key
  literal_value = each.value
  type          = "String"
}

resource "snapcd_module_input_from_output_set" "networking_private_dns__from_vpc" {
  input_kind       = "Param"
  module_id        = snapcd_module.networking_private_dns.id
  name             = "from_vpc"
  output_module_id = snapcd_module.networking_vpc.id
}

// ── networking/vpn_gateway ──

resource "snapcd_module" "networking_vpn_gateway" {
  depends_on          = [snapcd_runner_namespace_supply.networking]
  name                = "vpn_gateway"
  namespace_id        = snapcd_namespace.networking.id
  source_url          = var.source_url
  source_revision     = var.source_revision
  source_subdirectory = "modules/networking/vpn_gateway"
  runner_id           = data.snapcd_runner.azure.id
}

resource "snapcd_module_input_from_output_set" "networking_vpn_gateway__from_azure_ad_groups" {
  input_kind       = "Param"
  module_id        = snapcd_module.networking_vpn_gateway.id
  name             = "from_azure_ad_groups"
  output_module_id = snapcd_module.identity_azure_ad_groups.id
}

resource "snapcd_module_input_from_output_set" "networking_vpn_gateway__from_vpc" {
  input_kind       = "Param"
  module_id        = snapcd_module.networking_vpn_gateway.id
  name             = "from_vpc"
  output_module_id = snapcd_module.networking_vpc.id
}

// ── networking/bastion ──

resource "snapcd_module" "networking_bastion" {
  depends_on          = [snapcd_runner_namespace_supply.networking]
  name                = "bastion"
  namespace_id        = snapcd_namespace.networking.id
  source_url          = var.source_url
  source_revision     = var.source_revision
  source_subdirectory = "modules/networking/bastion"
  runner_id           = data.snapcd_runner.azure.id
}

resource "snapcd_module_input_from_output_set" "networking_bastion__from_nsg" {
  input_kind       = "Param"
  module_id        = snapcd_module.networking_bastion.id
  name             = "from_nsg"
  output_module_id = snapcd_module.networking_nsg.id
}

resource "snapcd_module_input_from_output_set" "networking_bastion__from_vpc" {
  input_kind       = "Param"
  module_id        = snapcd_module.networking_bastion.id
  name             = "from_vpc"
  output_module_id = snapcd_module.networking_vpc.id
}
