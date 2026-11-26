variable "name" {
  description = "Nome da instancia (vira o nome do Deployment, Service, Secret e PVC)."
  type        = string
}

variable "namespace" {
  description = "Namespace onde a instancia sera criada."
  type        = string
}

variable "database" {
  description = "Nome do banco criado na inicializacao."
  type        = string
}

variable "username" {
  description = "Usuario administrador do banco."
  type        = string
}

variable "password" {
  description = "Senha do usuario administrador."
  type        = string
  sensitive   = true
}

variable "image" {
  description = "Imagem do Postgres, idealmente fixada por digest."
  type        = string
}

variable "storage_size" {
  description = "Tamanho do volume persistente."
  type        = string
  default     = "2Gi"
}

variable "node_port" {
  description = "Porta NodePort para acesso externo. null = acessivel apenas dentro do cluster."
  type        = number
  default     = null
}

variable "memory_request" {
  type    = string
  default = "256Mi"
}

variable "memory_limit" {
  type    = string
  default = "1Gi"
}

variable "cpu_request" {
  type    = string
  default = "100m"
}

variable "labels" {
  description = "Labels comuns aplicadas a todos os recursos."
  type        = map(string)
  default     = {}
}