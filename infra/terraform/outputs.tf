output "acessos" {
  description = "Como acessar cada servico a partir do Windows."
  value = {
    minio_console = "http://localhost:9001"
    minio_api     = "http://localhost:9000"
    warehouse     = "localhost:5432 | banco: ${module.warehouse.database} | usuario: ${module.warehouse.username}"
  }
}

output "enderecos_internos" {
  description = "Enderecos usados pelos servicos dentro do cluster."
  value = {
    minio          = "http://minio.storage.svc.cluster.local:9000"
    warehouse      = module.warehouse.host
    airflow_metadb = module.airflow_metadb.host
  }
}