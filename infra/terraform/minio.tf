locals {
  minio_image     = "cgr.dev/chainguard/minio@sha256:b9b1cce81a4a6cc9bf250e68d621cc0b9fb8ed15aefe18fcd1840525eab6a81a"
  minio_namespace = kubernetes_namespace_v1.this["storage"].metadata[0].name
  minio_labels    = merge(local.common_labels, { "app.kubernetes.io/name" = "minio" })
}

# Credenciais de root, vindas do terraform.tfvars
resource "kubernetes_secret_v1" "minio_root" {
  metadata {
    name      = "minio-root-credentials"
    namespace = local.minio_namespace
    labels    = local.minio_labels
  }

  type = "Opaque"
  data = {
    MINIO_ROOT_USER     = var.minio_root_user
    MINIO_ROOT_PASSWORD = var.minio_root_password
  }
}

# Disco persistente: os arquivos sobrevivem ao reinicio do pod
resource "kubernetes_persistent_volume_claim_v1" "minio_data" {
  metadata {
    name      = "minio-data"
    namespace = local.minio_namespace
    labels    = local.minio_labels
  }

  spec {
    access_modes = ["ReadWriteOnce"]
    resources {
      requests = {
        storage = "5Gi"
      }
    }
  }

  # O disco do Kind so e criado quando um pod o usa
  wait_until_bound = false
}

resource "kubernetes_deployment_v1" "minio" {
  metadata {
    name      = "minio"
    namespace = local.minio_namespace
    labels    = local.minio_labels
  }

  spec {
    replicas = 1

    # Um disco ReadWriteOnce nao pode ser usado por dois pods ao mesmo tempo
    strategy {
      type = "Recreate"
    }

    selector {
      match_labels = {
        "app.kubernetes.io/name" = "minio"
      }
    }

    template {
      metadata {
        labels = local.minio_labels
      }

      spec {
        security_context {
          run_as_non_root = true
          run_as_user     = 65532
          run_as_group    = 65532
          fs_group        = 65532
        }

        container {
          name  = "minio"
          image = local.minio_image
          args  = ["server", "/data", "--address", ":9000", "--console-address", ":9001"]

          env_from {
            secret_ref {
              name = kubernetes_secret_v1.minio_root.metadata[0].name
            }
          }

          port {
            name           = "api"
            container_port = 9000
          }

          port {
            name           = "console"
            container_port = 9001
          }

          volume_mount {
            name       = "data"
            mount_path = "/data"
          }

          readiness_probe {
            http_get {
              path = "/minio/health/ready"
              port = "api"
            }
            initial_delay_seconds = 5
            period_seconds        = 10
          }

          liveness_probe {
            http_get {
              path = "/minio/health/live"
              port = "api"
            }
            initial_delay_seconds = 15
            period_seconds        = 20
          }

          resources {
            requests = {
              cpu    = "100m"
              memory = "256Mi"
            }
            limits = {
              memory = "1Gi"
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
            claim_name = kubernetes_persistent_volume_claim_v1.minio_data.metadata[0].name
          }
        }
      }
    }
  }
}

# Endereco fixo: minio.storage.svc.cluster.local (dentro do cluster)
# e localhost:9000 / localhost:9001 (fora, via NodePort + kind-config)
resource "kubernetes_service_v1" "minio" {
  metadata {
    name      = "minio"
    namespace = local.minio_namespace
    labels    = local.minio_labels
  }

  spec {
    type = "NodePort"

    selector = {
      "app.kubernetes.io/name" = "minio"
    }

    port {
      name        = "api"
      port        = 9000
      target_port = "api"
      node_port   = 30900
    }

    port {
      name        = "console"
      port        = 9001
      target_port = "console"
      node_port   = 30901
    }
  }
}