locals {
  common_labels = {
    "app.kubernetes.io/part-of"    = "banvic-data-platform"
    "app.kubernetes.io/managed-by" = "terraform"
  }

  namespaces = {
    storage       = "Data lake: MinIO (landing e raw)"
    warehouse     = "Data warehouse: Postgres (raw, staging, marts)"
    orchestration = "Orquestracao: Apache Airflow"
  }
}

resource "kubernetes_namespace_v1" "this" {
  for_each = local.namespaces

  metadata {
    name   = each.key
    labels = local.common_labels
    annotations = {
      description = each.value
    }
  }
}