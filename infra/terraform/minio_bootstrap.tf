locals {
  # landing: onde o "ERP" entrega o zip | raw: CSVs extraidos, organizados por data
  minio_buckets = toset(["landing", "raw", "airflow-logs"])
}

resource "minio_s3_bucket" "this" {
  for_each = local.minio_buckets

  bucket = each.key
  acl    = "private"

  # So cria os buckets depois que o MinIO estiver no ar
  depends_on = [
    kubernetes_deployment_v1.minio,
    kubernetes_service_v1.minio,
  ]
}

# Menor privilegio: le e grava objetos APENAS nos buckets do pipeline.
# Nao pode criar/apagar buckets, nem administrar usuarios.
resource "minio_iam_policy" "pipeline_rw" {
  name = "banvic-pipeline-rw"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "ListarBucketsDoPipeline"
        Effect   = "Allow"
        Action   = ["s3:ListBucket", "s3:GetBucketLocation"]
        Resource = [for b in minio_s3_bucket.this : "arn:aws:s3:::${b.bucket}"]
      },
      {
        Sid      = "LerGravarObjetos"
        Effect   = "Allow"
        Action   = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"]
        Resource = [for b in minio_s3_bucket.this : "arn:aws:s3:::${b.bucket}/*"]
      },
    ]
  })
}

resource "minio_iam_user" "pipeline" {
  name   = "pipeline-svc"
  secret = var.minio_pipeline_password
}

resource "minio_iam_user_policy_attachment" "pipeline" {
  user_name   = minio_iam_user.pipeline.id
  policy_name = minio_iam_policy.pipeline_rw.id
}