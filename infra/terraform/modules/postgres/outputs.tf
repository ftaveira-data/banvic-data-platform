output "host" {
  description = "Endereco DNS interno (usado por Airflow, Meltano e dbt)."
  value       = "${kubernetes_service_v1.this.metadata[0].name}.${var.namespace}.svc.cluster.local"
}

output "port" {
  value = 5432
}

output "database" {
  value = var.database
}

output "username" {
  value = var.username
}

output "secret_name" {
  description = "Secret com as credenciais (reutilizado pelo Airflow)."
  value       = kubernetes_secret_v1.this.metadata[0].name
}