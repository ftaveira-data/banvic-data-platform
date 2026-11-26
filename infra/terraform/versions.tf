terraform {
  required_version = ">= 1.6"

  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 3.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 3.2"
    }
    minio = {
      source  = "aminueza/minio"
      version = "~> 3.38"
    }
  }
}