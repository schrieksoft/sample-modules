"""Single source of truth for the sample-modules stack.

Both the mock modules and the Snap CD wiring are generated from SPEC, so the
DAG in the .tf can never drift from the DAG in the modules.

Each module:
  deps    — {local_var_name: "namespace/module"}  → snapcd_module_input_from_output_set
  outputs — {name: kind}   kind: "uuid" | "str:<value>" | "list:<a,b>" | "var:<varname>"
  vars    — {name: default} extra inputs set as literals
"""

SPEC = {
    "identity": {
        "azure_ad_groups": {
            "deps": {},
            "vars": {"tenant_id": "00000000-0000-0000-0000-000000000000"},
            "outputs": {
                "platform_team_group_id": "uuid",
                "analytics_team_group_id": "uuid",
                "product_team_group_id": "uuid",
                "security_team_group_id": "uuid",
                "group_names": "list:platform-team,analytics-team,product-team,security-team",
            },
        },
        "azure_service_principals": {
            "deps": {"from_azure_ad_groups": "identity/azure_ad_groups"},
            "vars": {},
            "outputs": {
                "runner_sp_object_id": "uuid",
                "runner_sp_client_id": "uuid",
                "agent_sp_object_id": "uuid",
                "agent_sp_client_id": "uuid",
            },
        },
        "azure_user_group_assignments": {
            "deps": {"from_azure_ad_groups": "identity/azure_ad_groups"},
            "vars": {},
            "outputs": {
                "assignment_count": "str:14",
                "assigned_upns": "list:karl@example.com,dev1@example.com,analyst1@example.com",
            },
        },
        "snapcd_groups": {
            "deps": {"from_azure_ad_groups": "identity/azure_ad_groups"},
            "vars": {},
            "outputs": {
                "platform_team_group_id": "uuid",
                "analytics_team_group_id": "uuid",
                "product_team_group_id": "uuid",
                "security_team_group_id": "uuid",
            },
        },
        "snapcd_user_group_assignments": {
            "deps": {
                "from_snapcd_groups": "identity/snapcd_groups",
                "from_azure_user_group_assignments": "identity/azure_user_group_assignments",
            },
            "vars": {},
            "outputs": {
                "member_count": "str:14",
                "managed_groups": "list:platform-team,analytics-team,product-team,security-team",
            },
        },
    },
    "storage": {
        "base": {
            "deps": {},
            "vars": {"location": "westeurope", "environment": "prod"},
            "outputs": {
                "resource_group_name": "str:rg-prod",
                "location": "var:location",
                "subscription_id": "uuid",
                "tenant_id": "uuid",
            },
        },
        "key_vaults": {
            "deps": {
                "from_base": "storage/base",
                "from_azure_ad_groups": "identity/azure_ad_groups",
            },
            "vars": {},
            "outputs": {
                "akv_id": "uuid",
                "akv_url": "str:https://kv-prod.vault.azure.net/",
            },
        },
        "state_backend": {
            "deps": {"from_base": "storage/base"},
            "vars": {},
            "outputs": {
                "backend_storage_account_name": "str:tfstatesprod8000",
                "backend_container_name": "str:terraform-states",
            },
        },
        "storage_accounts": {
            "deps": {"from_base": "storage/base", "from_vpc": "networking/vpc"},
            "vars": {},
            "outputs": {
                "storage_account_id": "uuid",
                "storage_account_name": "str:stprod8000",
                "blob_endpoint": "str:https://stprod8000.blob.core.windows.net/",
            },
        },
        "sql_server": {
            "deps": {
                "from_base": "storage/base",
                "from_vpc": "networking/vpc",
                "from_private_dns": "networking/private_dns",
            },
            "vars": {"sql_server_name": "sql-prod", "sql_admin_login": "sqladmin"},
            "outputs": {
                "sql_server_id": "uuid",
                "sql_server_fqdn": "str:sql-prod.database.windows.net",
                "sql_server_name": "var:sql_server_name",
            },
        },
        "postgres": {
            "deps": {
                "from_base": "storage/base",
                "from_vpc": "networking/vpc",
                "from_private_dns": "networking/private_dns",
            },
            "vars": {"postgres_server_name": "pg-prod", "postgres_version": "16"},
            "outputs": {
                "postgres_server_id": "uuid",
                "postgres_fqdn": "str:pg-prod.postgres.database.azure.com",
                "postgres_server_name": "var:postgres_server_name",
            },
        },
        "redis": {
            "deps": {
                "from_base": "storage/base",
                "from_vpc": "networking/vpc",
                "from_private_dns": "networking/private_dns",
            },
            "vars": {"redis_name": "redis-prod", "redis_sku": "Standard"},
            "outputs": {
                "redis_id": "uuid",
                "redis_hostname": "str:redis-prod.redis.cache.windows.net",
                "redis_connection_string_ref": "str:https://kv-prod.vault.azure.net/secrets/redis-conn",
            },
        },
    },
    "networking": {
        "vpc": {
            "deps": {"from_base": "storage/base"},
            "vars": {
                "vpc_name": "vnet-prod",
                "vpc_cidr_block": "10.0.0.0/16",
                "private_subnet_cidr": "10.0.1.0/24",
                "public_subnet_cidr": "10.0.2.0/24",
                "apps_subnet_cidr": "10.0.3.0/24",
                "data_subnet_cidr": "10.0.4.0/24",
            },
            "outputs": {
                "vnet_id": "uuid",
                "private_subnet_id": "uuid",
                "public_subnet_id": "uuid",
                "apps_subnet_id": "uuid",
                "data_subnet_id": "uuid",
                "private_subnet_cidr": "var:private_subnet_cidr",
            },
        },
        "nsg": {
            "deps": {"from_vpc": "networking/vpc"},
            "vars": {},
            "outputs": {"nsg_id": "uuid", "nsg_name": "str:nsg-prod"},
        },
        "private_dns": {
            "deps": {"from_vpc": "networking/vpc"},
            "vars": {"private_dns_zone_name": "prod.internal"},
            "outputs": {
                "private_dns_zone_id": "uuid",
                "private_dns_zone_name": "var:private_dns_zone_name",
            },
        },
        "vpn_gateway": {
            "deps": {
                "from_vpc": "networking/vpc",
                "from_azure_ad_groups": "identity/azure_ad_groups",
            },
            "vars": {},
            "outputs": {
                "vpn_gateway_id": "uuid",
                "vpn_gateway_ip": "str:20.50.120.14",
            },
        },
        "bastion": {
            "deps": {"from_vpc": "networking/vpc", "from_nsg": "networking/nsg"},
            "vars": {},
            "outputs": {"bastion_host_id": "uuid", "bastion_fqdn": "str:bastion.prod.internal"},
        },
    },
    "analytics": {
        "data_lake": {
            "deps": {
                "from_storage_accounts": "storage/storage_accounts",
                "from_private_dns": "networking/private_dns",
            },
            "vars": {},
            "outputs": {
                "data_lake_uri": "str:abfss://lake@stprod8000.dfs.core.windows.net/",
                "filesystem_names": "list:raw,curated,gold",
            },
        },
        "databricks": {
            "deps": {
                "from_data_lake": "analytics/data_lake",
                "from_vpc": "networking/vpc",
                "from_azure_ad_groups": "identity/azure_ad_groups",
            },
            "vars": {},
            "outputs": {
                "workspace_id": "uuid",
                "workspace_url": "str:https://adb-8000.11.azuredatabricks.net",
            },
        },
        "warehouse": {
            "deps": {
                "from_base": "storage/base",
                "from_data_lake": "analytics/data_lake",
                "from_private_dns": "networking/private_dns",
            },
            "vars": {"warehouse_name": "synapse-prod"},
            "outputs": {
                "warehouse_id": "uuid",
                "warehouse_fqdn": "str:synapse-prod.sql.azuresynapse.net",
            },
        },
        "etl_pipeline_infra": {
            "deps": {
                "from_base": "storage/base",
                "from_databricks": "analytics/databricks",
                "from_data_lake": "analytics/data_lake",
            },
            "vars": {},
            "outputs": {
                "job_cluster_id": "uuid",
                "lake_sas_secret_ref": "str:https://kv-prod.vault.azure.net/secrets/lake-sas",
            },
        },
        "etl_pipeline_app": {
            "deps": {
                "from_etl_pipeline_infra": "analytics/etl_pipeline_infra",
                "from_databricks": "analytics/databricks",
                "from_warehouse": "analytics/warehouse",
                "from_storefront_api_infra": "application/storefront_api_infra",
            },
            "vars": {"schedule_cron": "0 2 * * *"},
            "outputs": {"pipeline_job_id": "uuid", "schedule_cron": "var:schedule_cron"},
        },
    },
    "platform": {
        "cluster": {
            "deps": {"from_base": "storage/base", "from_vpc": "networking/vpc"},
            "vars": {"cluster_name": "aks-prod", "kubernetes_version": "1.32.10"},
            "outputs": {
                "cluster_name": "var:cluster_name",
                "cluster_id": "uuid",
                "kubelet_identity_id": "uuid",
                "oidc_issuer_url": "str:https://westeurope.oic.prod-aks.azure.com/8000/",
                "node_resource_group": "str:MC_rg-prod_aks-prod_westeurope",
            },
        },
        "workload_identity_webhook": {
            "deps": {"from_cluster": "platform/cluster"},
            "vars": {},
            "outputs": {"webhook_ready": "str:true", "webhook_namespace": "str:azure-workload-identity-system"},
        },
        "istio": {
            "deps": {
                "from_base": "storage/base",
                "from_vpc": "networking/vpc",
                "from_cluster": "platform/cluster",
            },
            "vars": {"istio_version": "1.24.2"},
            "outputs": {
                "ingress_ip": "str:20.50.99.201",
                "gateway_name": "str:istio-ingressgateway",
                "istio_version": "var:istio_version",
            },
        },
        "cert_manager": {
            "deps": {"from_cluster": "platform/cluster"},
            "vars": {"cert_manager_version": "1.16.2"},
            "outputs": {"cert_manager_ready": "str:true", "cert_manager_namespace": "str:cert-manager"},
        },
        "cloudflare_dns": {
            "deps": {"from_istio": "platform/istio"},
            "vars": {"dns_zone": "example.com"},
            "outputs": {
                "zone_id": "uuid",
                "zone_name": "var:dns_zone",
                "record_fqdns": "list:api.example.com,argocd.example.com,docs.example.com",
            },
        },
        "cert_manager_cluster_issuer": {
            "deps": {
                "from_cert_manager": "platform/cert_manager",
                "from_cloudflare_dns": "platform/cloudflare_dns",
            },
            "vars": {},
            "outputs": {"issuer_name": "str:letsencrypt-prod", "issuer_ready": "str:true"},
        },
        "argocd": {
            "deps": {"from_cluster": "platform/cluster", "from_istio": "platform/istio"},
            "vars": {},
            "outputs": {"argocd_url": "str:https://argocd.example.com", "argocd_namespace": "str:argocd"},
        },
        "monitoring": {
            "deps": {"from_cluster": "platform/cluster", "from_istio": "platform/istio"},
            "vars": {},
            "outputs": {
                "grafana_url": "str:https://grafana.example.com",
                "prometheus_endpoint": "str:http://prometheus.monitoring:9090",
            },
        },
        "docs": {
            "deps": {
                "from_base": "storage/base",
                "from_cloudflare_dns": "platform/cloudflare_dns",
                "from_cert_manager_cluster_issuer": "platform/cert_manager_cluster_issuer",
            },
            "vars": {},
            "outputs": {"docs_url": "str:https://docs.example.com"},
        },
    },
    "application": {
        "storefront_api_infra": {
            "deps": {
                "from_base": "storage/base",
                "from_key_vaults": "storage/key_vaults",
                "from_sql_server": "storage/sql_server",
            },
            "vars": {"database_name": "storefront", "database_sku": "S1"},
            "outputs": {
                "identity_id": "uuid",
                "identity_client_id": "uuid",
                "database_name": "var:database_name",
                "db_connection_secret_ref": "str:https://kv-prod.vault.azure.net/secrets/storefront-conn",
            },
        },
        "storefront_api_app": {
            "deps": {
                "from_storefront_api_infra": "application/storefront_api_infra",
                "from_cluster": "platform/cluster",
                "from_istio": "platform/istio",
                "from_cloudflare_dns": "platform/cloudflare_dns",
            },
            "vars": {"replicas": "3", "image_tag": "v1.4.0"},
            "outputs": {"service_url": "str:https://api.example.com", "deployed_tag": "var:image_tag"},
        },
        "orders_worker_infra": {
            "deps": {
                "from_base": "storage/base",
                "from_key_vaults": "storage/key_vaults",
                "from_postgres": "storage/postgres",
                "from_storage_accounts": "storage/storage_accounts",
            },
            "vars": {"database_name": "orders"},
            "outputs": {
                "identity_id": "uuid",
                "database_name": "var:database_name",
                "queue_name": "str:orders",
                "db_connection_secret_ref": "str:https://kv-prod.vault.azure.net/secrets/orders-conn",
                "queue_connection_secret_ref": "str:https://kv-prod.vault.azure.net/secrets/orders-queue-conn",
            },
        },
        "orders_worker_app": {
            "deps": {
                "from_orders_worker_infra": "application/orders_worker_infra",
                "from_redis": "storage/redis",
                "from_cluster": "platform/cluster",
            },
            "vars": {"replicas": "2", "image_tag": "v0.9.1"},
            "outputs": {"worker_replicas": "var:replicas", "deployed_tag": "var:image_tag"},
        },
    },
}

# Namespace-level config for the Snap CD wiring
NAMESPACES = {
    "identity":    {"runner": "identity", "apply": 2, "destroy": 2},
    "storage":     {"runner": "azure",    "apply": 1, "destroy": 2},
    "networking":  {"runner": "azure",    "apply": 1, "destroy": 2},
    "analytics":   {"runner": "analytics", "apply": 0, "destroy": 1},
    "platform":    {"runner": "k8s",      "apply": 1, "destroy": 2},
    "application": {"runner": "k8s",      "apply": 0, "destroy": 1},
}

NS_ORDER = ["identity", "storage", "networking", "analytics", "platform", "application"]
