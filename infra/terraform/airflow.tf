locals {
  airflow_namespace = kubernetes_namespace_v1.this["orchestration"].metadata[0].name
  airflow_labels    = merge(local.common_labels, { "app.kubernetes.io/name" = "airflow" })
}

# ---------------------------------------------------------------------------
# Chaves geradas pelo Terraform (ficam no state; nao mudam entre applys)
# ---------------------------------------------------------------------------

# Fernet exige 32 bytes em base64 "url-safe" (com - e _ no lugar de + e /)
resource "random_id" "airflow_fernet" {
  byte_length = 32
}

resource "random_password" "airflow_api_secret" {
  length  = 64
  special = false
}

resource "random_password" "airflow_jwt_secret" {
  length  = 64
  special = false
}

# ---------------------------------------------------------------------------
# Secrets no formato que o chart espera
# ---------------------------------------------------------------------------

resource "kubernetes_secret_v1" "airflow_metadata" {
  metadata {
    name      = "banvic-airflow-metadata"
    namespace = local.airflow_namespace
    labels    = local.airflow_labels
  }

  data = {
    connection = "postgresql://${module.airflow_metadb.username}:${var.airflow_db_password}@${module.airflow_metadb.host}:${module.airflow_metadb.port}/${module.airflow_metadb.database}"
  }
}

resource "kubernetes_secret_v1" "airflow_fernet" {
  metadata {
    name      = "banvic-airflow-fernet"
    namespace = local.airflow_namespace
    labels    = local.airflow_labels
  }

  data = {
    "fernet-key" = replace(replace(random_id.airflow_fernet.b64_std, "+", "-"), "/", "_")
  }
}

resource "kubernetes_secret_v1" "airflow_api_secret" {
  metadata {
    name      = "banvic-airflow-api-secret"
    namespace = local.airflow_namespace
    labels    = local.airflow_labels
  }

  data = {
    "api-secret-key" = random_password.airflow_api_secret.result
  }
}

resource "kubernetes_secret_v1" "airflow_jwt" {
  metadata {
    name      = "banvic-airflow-jwt"
    namespace = local.airflow_namespace
    labels    = local.airflow_labels
  }

  data = {
    "jwt-secret" = random_password.airflow_jwt_secret.result
  }
}

# ---------------------------------------------------------------------------
# Chart oficial do Apache Airflow
# ---------------------------------------------------------------------------

resource "helm_release" "airflow" {
  name       = "airflow"
  repository = "https://airflow.apache.org"
  chart      = "airflow"
  version    = "1.22.0"
  namespace  = local.airflow_namespace

  values = [file("${path.module}/values/airflow.yaml")]

  set_sensitive = [
    {
      name  = "createUserJob.defaultUser.password"
      value = var.airflow_admin_password
    },
  ]

  # Primeira instalacao: migracao do banco + subida de 4 componentes
  timeout = 900
  wait    = true

  depends_on = [
    module.airflow_metadb,
    kubernetes_secret_v1.airflow_metadata,
    kubernetes_secret_v1.airflow_fernet,
    kubernetes_secret_v1.airflow_api_secret,
    kubernetes_secret_v1.airflow_jwt,
  ]
}