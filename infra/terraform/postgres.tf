locals {
  postgres_image = "postgres:17@sha256:97fb53376be3e4fb1a8a61421daa69dcc3bf2fa39bda3259f5245f9a455af1a9"
}

# Data warehouse do BanVic: acessivel pelo Power BI em localhost:5432
module "warehouse" {
  source = "./modules/postgres"

  name         = "warehouse"
  namespace    = kubernetes_namespace_v1.this["warehouse"].metadata[0].name
  database     = "banvic_dw"
  username     = "banvic_admin"
  password     = var.warehouse_db_password
  image        = local.postgres_image
  storage_size = "5Gi"
  node_port    = 30432
  memory_limit = "2Gi"
  labels       = local.common_labels
}

# Metadata DB do Airflow: isolado, sem acesso externo
module "airflow_metadb" {
  source = "./modules/postgres"

  name         = "airflow-metadb"
  namespace    = kubernetes_namespace_v1.this["orchestration"].metadata[0].name
  database     = "airflow"
  username     = "airflow"
  password     = var.airflow_db_password
  image        = local.postgres_image
  storage_size = "2Gi"
  labels       = local.common_labels
}