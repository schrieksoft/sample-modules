///////////////////////////////////////////////////////////////////////////////
//
//  namespace: platform
//
///////////////////////////////////////////////////////////////////////////////

resource "snapcd_namespace" "platform" {
  name                               = "platform"
  stack_id                           = snapcd_stack.prod.id
  default_apply_approval_threshold   = 1
  default_destroy_approval_threshold = 2
}

resource "snapcd_runner_namespace_supply" "platform" {
  runner_id    = data.snapcd_runner.k8s.id
  namespace_id = snapcd_namespace.platform.id
}

// ── platform/cluster ──

resource "snapcd_module" "platform_cluster" {
  depends_on          = [snapcd_runner_namespace_supply.platform]
  name                = "cluster"
  namespace_id        = snapcd_namespace.platform.id
  source_url          = var.source_url
  source_revision     = var.source_revision
  source_subdirectory = "modules/platform/cluster"
  runner_id           = data.snapcd_runner.k8s.id
}

resource "snapcd_module_input_from_literal" "platform_cluster" {
  for_each = {
    cluster_name       = "aks-prod"
    kubernetes_version = "1.32.10"
  }
  input_kind    = "Param"
  module_id     = snapcd_module.platform_cluster.id
  name          = each.key
  literal_value = each.value
  type          = "String"
}

resource "snapcd_module_input_from_output_set" "platform_cluster__from_base" {
  input_kind       = "Param"
  module_id        = snapcd_module.platform_cluster.id
  name             = "from_base"
  output_module_id = snapcd_module.storage_base.id
}

resource "snapcd_module_input_from_output_set" "platform_cluster__from_vpc" {
  input_kind       = "Param"
  module_id        = snapcd_module.platform_cluster.id
  name             = "from_vpc"
  output_module_id = snapcd_module.networking_vpc.id
}

// ── platform/workload_identity_webhook ──

resource "snapcd_module" "platform_workload_identity_webhook" {
  depends_on          = [snapcd_runner_namespace_supply.platform]
  name                = "workload_identity_webhook"
  namespace_id        = snapcd_namespace.platform.id
  source_url          = var.source_url
  source_revision     = var.source_revision
  source_subdirectory = "modules/platform/workload_identity_webhook"
  runner_id           = data.snapcd_runner.k8s.id
}

resource "snapcd_module_input_from_output_set" "platform_workload_identity_webhook__from_cluster" {
  input_kind       = "Param"
  module_id        = snapcd_module.platform_workload_identity_webhook.id
  name             = "from_cluster"
  output_module_id = snapcd_module.platform_cluster.id
}

// ── platform/istio ──

resource "snapcd_module" "platform_istio" {
  depends_on          = [snapcd_runner_namespace_supply.platform]
  name                = "istio"
  namespace_id        = snapcd_namespace.platform.id
  source_url          = var.source_url
  source_revision     = var.source_revision
  source_subdirectory = "modules/platform/istio"
  runner_id           = data.snapcd_runner.k8s.id
}

resource "snapcd_module_input_from_literal" "platform_istio" {
  for_each = {
    istio_version = "1.24.2"
  }
  input_kind    = "Param"
  module_id     = snapcd_module.platform_istio.id
  name          = each.key
  literal_value = each.value
  type          = "String"
}

resource "snapcd_module_input_from_output_set" "platform_istio__from_base" {
  input_kind       = "Param"
  module_id        = snapcd_module.platform_istio.id
  name             = "from_base"
  output_module_id = snapcd_module.storage_base.id
}

resource "snapcd_module_input_from_output_set" "platform_istio__from_cluster" {
  input_kind       = "Param"
  module_id        = snapcd_module.platform_istio.id
  name             = "from_cluster"
  output_module_id = snapcd_module.platform_cluster.id
}

resource "snapcd_module_input_from_output_set" "platform_istio__from_vpc" {
  input_kind       = "Param"
  module_id        = snapcd_module.platform_istio.id
  name             = "from_vpc"
  output_module_id = snapcd_module.networking_vpc.id
}

// ── platform/cert_manager ──

resource "snapcd_module" "platform_cert_manager" {
  depends_on          = [snapcd_runner_namespace_supply.platform]
  name                = "cert_manager"
  namespace_id        = snapcd_namespace.platform.id
  source_url          = var.source_url
  source_revision     = var.source_revision
  source_subdirectory = "modules/platform/cert_manager"
  runner_id           = data.snapcd_runner.k8s.id
}

resource "snapcd_module_input_from_literal" "platform_cert_manager" {
  for_each = {
    cert_manager_version = "1.16.2"
  }
  input_kind    = "Param"
  module_id     = snapcd_module.platform_cert_manager.id
  name          = each.key
  literal_value = each.value
  type          = "String"
}

resource "snapcd_module_input_from_output_set" "platform_cert_manager__from_cluster" {
  input_kind       = "Param"
  module_id        = snapcd_module.platform_cert_manager.id
  name             = "from_cluster"
  output_module_id = snapcd_module.platform_cluster.id
}

// ── platform/cloudflare_dns ──

resource "snapcd_module" "platform_cloudflare_dns" {
  depends_on          = [snapcd_runner_namespace_supply.platform]
  name                = "cloudflare_dns"
  namespace_id        = snapcd_namespace.platform.id
  source_url          = var.source_url
  source_revision     = var.source_revision
  source_subdirectory = "modules/platform/cloudflare_dns"
  runner_id           = data.snapcd_runner.k8s.id
}

resource "snapcd_module_input_from_literal" "platform_cloudflare_dns" {
  for_each = {
    dns_zone = "example.com"
  }
  input_kind    = "Param"
  module_id     = snapcd_module.platform_cloudflare_dns.id
  name          = each.key
  literal_value = each.value
  type          = "String"
}

resource "snapcd_module_input_from_output_set" "platform_cloudflare_dns__from_istio" {
  input_kind       = "Param"
  module_id        = snapcd_module.platform_cloudflare_dns.id
  name             = "from_istio"
  output_module_id = snapcd_module.platform_istio.id
}

// ── platform/cert_manager_cluster_issuer ──

resource "snapcd_module" "platform_cert_manager_cluster_issuer" {
  depends_on          = [snapcd_runner_namespace_supply.platform]
  name                = "cert_manager_cluster_issuer"
  namespace_id        = snapcd_namespace.platform.id
  source_url          = var.source_url
  source_revision     = var.source_revision
  source_subdirectory = "modules/platform/cert_manager_cluster_issuer"
  runner_id           = data.snapcd_runner.k8s.id
}

resource "snapcd_module_input_from_output_set" "platform_cert_manager_cluster_issuer__from_cert_manager" {
  input_kind       = "Param"
  module_id        = snapcd_module.platform_cert_manager_cluster_issuer.id
  name             = "from_cert_manager"
  output_module_id = snapcd_module.platform_cert_manager.id
}

resource "snapcd_module_input_from_output_set" "platform_cert_manager_cluster_issuer__from_cloudflare_dns" {
  input_kind       = "Param"
  module_id        = snapcd_module.platform_cert_manager_cluster_issuer.id
  name             = "from_cloudflare_dns"
  output_module_id = snapcd_module.platform_cloudflare_dns.id
}

// ── platform/argocd ──

resource "snapcd_module" "platform_argocd" {
  depends_on          = [snapcd_runner_namespace_supply.platform]
  name                = "argocd"
  namespace_id        = snapcd_namespace.platform.id
  source_url          = var.source_url
  source_revision     = var.source_revision
  source_subdirectory = "modules/platform/argocd"
  runner_id           = data.snapcd_runner.k8s.id
}

resource "snapcd_module_input_from_output_set" "platform_argocd__from_cluster" {
  input_kind       = "Param"
  module_id        = snapcd_module.platform_argocd.id
  name             = "from_cluster"
  output_module_id = snapcd_module.platform_cluster.id
}

resource "snapcd_module_input_from_output_set" "platform_argocd__from_istio" {
  input_kind       = "Param"
  module_id        = snapcd_module.platform_argocd.id
  name             = "from_istio"
  output_module_id = snapcd_module.platform_istio.id
}

// ── platform/monitoring ──

resource "snapcd_module" "platform_monitoring" {
  depends_on          = [snapcd_runner_namespace_supply.platform]
  name                = "monitoring"
  namespace_id        = snapcd_namespace.platform.id
  source_url          = var.source_url
  source_revision     = var.source_revision
  source_subdirectory = "modules/platform/monitoring"
  runner_id           = data.snapcd_runner.k8s.id
}

resource "snapcd_module_input_from_output_set" "platform_monitoring__from_cluster" {
  input_kind       = "Param"
  module_id        = snapcd_module.platform_monitoring.id
  name             = "from_cluster"
  output_module_id = snapcd_module.platform_cluster.id
}

resource "snapcd_module_input_from_output_set" "platform_monitoring__from_istio" {
  input_kind       = "Param"
  module_id        = snapcd_module.platform_monitoring.id
  name             = "from_istio"
  output_module_id = snapcd_module.platform_istio.id
}

// ── platform/docs ──

resource "snapcd_module" "platform_docs" {
  depends_on          = [snapcd_runner_namespace_supply.platform]
  name                = "docs"
  namespace_id        = snapcd_namespace.platform.id
  source_url          = var.source_url
  source_revision     = var.source_revision
  source_subdirectory = "modules/platform/docs"
  runner_id           = data.snapcd_runner.k8s.id
}

resource "snapcd_module_input_from_output_set" "platform_docs__from_base" {
  input_kind       = "Param"
  module_id        = snapcd_module.platform_docs.id
  name             = "from_base"
  output_module_id = snapcd_module.storage_base.id
}

resource "snapcd_module_input_from_output_set" "platform_docs__from_cert_manager_cluster_issuer" {
  input_kind       = "Param"
  module_id        = snapcd_module.platform_docs.id
  name             = "from_cert_manager_cluster_issuer"
  output_module_id = snapcd_module.platform_cert_manager_cluster_issuer.id
}

resource "snapcd_module_input_from_output_set" "platform_docs__from_cloudflare_dns" {
  input_kind       = "Param"
  module_id        = snapcd_module.platform_docs.id
  name             = "from_cloudflare_dns"
  output_module_id = snapcd_module.platform_cloudflare_dns.id
}
