locals {
  kubeconfig_path = pathexpand("~/.kube/config")
  kube_context    = "kind-banvic"
}

provider "kubernetes" {
  config_path    = local.kubeconfig_path
  config_context = local.kube_context
}

provider "helm" {
  kubernetes = {
    config_path    = local.kubeconfig_path
    config_context = local.kube_context
  }
}