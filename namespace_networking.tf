///////////////////////////////////////////////////////////////////////////////
//
//  namespace: networking
//
///////////////////////////////////////////////////////////////////////////////

resource "snapcd_namespace" "networking" {
  name                               = "networking"
  stack_id                           = snapcd_stack.prod.id
  default_apply_approval_threshold   = 1
  default_destroy_approval_threshold = 2
}

resource "snapcd_runner_namespace_supply" "networking" {
  runner_id    = data.snapcd_runner.azure.id
  namespace_id = snapcd_namespace.networking.id
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
