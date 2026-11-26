locals {
  selector = {
    "app.kubernetes.io/name"     = "postgres"
    "app.kubernetes.io/instance" = var.name
  }
  labels = merge(var.labels, local.selector)

  # Exame de saude: o Postgres aceita conexoes?
  pg_isready = ["sh", "-c", "pg_isready -h 127.0.0.1 -U \"$POSTGRES_USER\" -d \"$POSTGRES_DB\""]
}

resource "kubernetes_secret_v1" "this" {
  metadata {
    name      = "${var.name}-credentials"
    namespace = var.namespace
    labels    = local.labels
  }

  type = "Opaque"
  data = {
    POSTGRES_USER     = var.username
    POSTGRES_PASSWORD = var.password
    POSTGRES_DB       = var.database
  }
}

resource "kubernetes_persistent_volume_claim_v1" "this" {
  metadata {
    name      = "${var.name}-data"
    namespace = var.namespace
    labels    = local.labels
  }

  spec {
    access_modes = ["ReadWriteOnce"]
    resources {
      requests = {
        storage = var.storage_size
      }
    }
  }

  wait_until_bound = false
}

resource "kubernetes_deployment_v1" "this" {
  metadata {
    name      = var.name
    namespace = var.namespace
    labels    = local.labels
  }

  spec {
    replicas = 1

    strategy {
      type = "Recreate"
    }

    selector {
      match_labels = local.selector
    }

    template {
      metadata {
        labels = local.labels
      }

      spec {
        # 999 = usuario "postgres" da imagem oficial
        security_context {
          run_as_non_root = true
          run_as_user     = 999
          run_as_group    = 999
          fs_group        = 999
        }

        container {
          name  = "postgres"
          image = var.image

          env_from {
            secret_ref {
              name = kubernetes_secret_v1.this.metadata[0].name
            }
          }

          # Subpasta dentro do volume: evita conflito com arquivos do proprio disco
          env {
            name  = "PGDATA"
            value = "/var/lib/postgresql/data/pgdata"
          }

          port {
            name           = "postgres"
            container_port = 5432
          }

          volume_mount {
            name       = "data"
            mount_path = "/var/lib/postgresql/data"
          }

          readiness_probe {
            exec {
              command = local.pg_isready
            }
            initial_delay_seconds = 5
            period_seconds        = 10
          }

          liveness_probe {
            exec {
              command = local.pg_isready
            }
            initial_delay_seconds = 30
            period_seconds        = 20
            failure_threshold     = 5
          }

          resources {
            requests = {
              cpu    = var.cpu_request
              memory = var.memory_request
            }
            limits = {
              memory = var.memory_limit
            }
          }

          security_context {
            allow_privilege_escalation = false
            capabilities {
              drop = ["ALL"]
            }
          }
        }

        volume {
          name = "data"
          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim_v1.this.metadata[0].name
          }
        }
      }
    }
  }
}

resource "kubernetes_service_v1" "this" {
  metadata {
    name      = var.name
    namespace = var.namespace
    labels    = local.labels
  }

  spec {
    # Sem node_port: ClusterIP (so dentro do cluster). Com node_port: exposto.
    type     = var.node_port == null ? "ClusterIP" : "NodePort"
    selector = local.selector

    port {
      name        = "postgres"
      port        = 5432
      target_port = "postgres"
      node_port   = var.node_port
    }
  }
}