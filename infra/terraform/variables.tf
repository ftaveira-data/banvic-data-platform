variable "minio_root_user" {
  description = "Usuario administrador (root) do MinIO."
  type        = string
  default     = "banvic-admin"
}

variable "minio_root_password" {
  description = "Senha do usuario root do MinIO. Minimo de 8 caracteres."
  type        = string
  sensitive   = true

  validation {
    condition     = length(var.minio_root_password) >= 8
    error_message = "A senha do MinIO precisa ter pelo menos 8 caracteres."
  }
}

variable "minio_pipeline_password" {
  description = "Senha do usuario de servico pipeline-svc (Airflow e Meltano). Minimo de 8 caracteres."
  type        = string
  sensitive   = true

  validation {
    condition     = length(var.minio_pipeline_password) >= 8
    error_message = "A senha do pipeline-svc precisa ter pelo menos 8 caracteres."
  }
}