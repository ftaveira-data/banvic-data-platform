# BanVic Data Platform

Pipeline de ingestão e infraestrutura de dados do Banco Vitória (BanVic).
Certificação Data Engineer by Indicium AI.

> Em construção.

banvic-data-platform/
├── infra/
│   ├── kind/            # config do cluster (kind-config.yaml)
│   └── terraform/       # namespaces, secrets, postgres, minio, airflow
├── docker/              # Dockerfile da imagem banvic-pipeline
├── meltano/             # meltano.yml (taps e targets)
├── dbt/                 # modelos staging → marts
├── dags/                # DAGs do Airflow  ← o edital exige este nome
├── data/landing/        # onde o banvic_data.zip "chega" (fora do Git)
├── analysis/            # ranking de alavancas (Python)
├── powerbi/             # .pbip do dashboard
├── docs/                # diagrama de arquitetura, imagens do README
├── .github/workflows/   # CI
├── .env.example         # modelo de variáveis, SEM valores reais
├── .gitignore
└── README.md