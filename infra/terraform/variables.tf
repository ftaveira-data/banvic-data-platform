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

variable "warehouse_db_password" {
  description = "Senha do usuario banvic_admin no warehouse."
  type        = string
  sensitive   = true

  validation {
    condition     = length(var.warehouse_db_password) >= 12
    error_message = "A senha do warehouse precisa ter pelo menos 12 caracteres."
  }
}

variable "airflow_db_password" {
  description = "Senha do usuario airflow no metadata DB."
  type        = string
  sensitive   = true

  validation {
    condition     = length(var.airflow_db_password) >= 12
    error_message = "A senha do metadata DB precisa ter pelo menos 12 caracteres."
  }
}

variable "airflow_admin_password" {
  description = "Senha do usuario admin da interface do Airflow."
  type        = string
  sensitive   = true

  validation {
    condition     = length(var.airflow_admin_password) >= 12
    error_message = "A senha do admin do Airflow precisa ter pelo menos 12 caracteres."
  }
}

variable "airflow_dags_branch" {
  description = "Branch do GitHub que o git-sync usa para buscar as DAGs. Padrao: main."
  type        = string
  default     = "main"
}