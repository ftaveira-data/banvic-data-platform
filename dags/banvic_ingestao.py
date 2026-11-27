"""
Ingestao diaria do export do ERP do BanVic.

Fluxo:
    1. espera o zip do dia em s3://landing/banvic/dt=<ds>/banvic_data.zip
    2. valida o contrato (7 tabelas esperadas) e grava cada CSV em
       s3://raw/banvic/dt=<ds>/<tabela>.csv, sobrescrevendo a particao inteira
"""

from __future__ import annotations

import csv
import io
import logging
import zipfile
from datetime import datetime, timedelta
from pathlib import PurePosixPath

from airflow.providers.amazon.aws.hooks.s3 import S3Hook
from airflow.providers.amazon.aws.sensors.s3 import S3KeySensor
from airflow.sdk import dag, task

log = logging.getLogger(__name__)

MINIO_CONN_ID = "minio_default"
BUCKET_LANDING = "landing"
BUCKET_RAW = "raw"
PREFIXO = "banvic"

# Contrato de dados: o export do ERP deve conter exatamente estas tabelas
TABELAS_ESPERADAS = {
    "agencias",
    "clientes",
    "colaborador_agencia",
    "colaboradores",
    "contas",
    "propostas_credito",
    "transacoes",
}

default_args = {
    "owner": "engenharia-dados",
    "retries": 3,
    "retry_delay": timedelta(minutes=2),
    "retry_exponential_backoff": True,
}


@dag(
    dag_id="banvic_ingestao",
    description="Ingestao diaria do export do ERP: landing -> raw (MinIO)",
    schedule="0 5 * * *",  # todo dia as 05:00
    start_date=datetime(2026, 11, 25),
    catchup=False,
    max_active_runs=1,
    default_args=default_args,
    tags=["banvic", "ingestao"],
)
def banvic_ingestao():
    espera_export = S3KeySensor(
        task_id="espera_export_erp",
        aws_conn_id=MINIO_CONN_ID,
        bucket_name=BUCKET_LANDING,
        bucket_key=PREFIXO + "/dt={{ ds }}/banvic_data.zip",
        mode="reschedule",  # libera o worker entre as verificacoes
        poke_interval=60,  # verifica a cada 1 minuto
        timeout=60 * 60 * 6,  # desiste apos 6 horas
    )

    @task
    def descompacta_para_raw(ds: str | None = None) -> dict[str, int]:
        hook = S3Hook(aws_conn_id=MINIO_CONN_ID)
        chave_zip = f"{PREFIXO}/dt={ds}/banvic_data.zip"
        prefixo_raw = f"{PREFIXO}/dt={ds}/"

        # 1. Le o zip da landing
        conteudo = hook.get_key(chave_zip, bucket_name=BUCKET_LANDING).get()["Body"].read()
        with zipfile.ZipFile(io.BytesIO(conteudo)) as zf:
            csvs = {
                PurePosixPath(nome).name: zf.read(nome)
                for nome in zf.namelist()
                if nome.lower().endswith(".csv")
            }

        # 2. Valida o contrato antes de tocar no raw
        tabelas = {PurePosixPath(nome).stem for nome in csvs}
        faltando = TABELAS_ESPERADAS - tabelas
        inesperadas = tabelas - TABELAS_ESPERADAS
        if faltando:
            raise ValueError(f"Export de {ds} incompleto. Tabelas ausentes: {sorted(faltando)}")
        if inesperadas:
            log.warning("Tabelas nao previstas no contrato serao ignoradas: %s", sorted(inesperadas))

        # 3. Sobrescreve a particao inteira: apaga o que existir no dia
        existentes = hook.list_keys(bucket_name=BUCKET_RAW, prefix=prefixo_raw)
        if existentes:
            hook.delete_objects(bucket=BUCKET_RAW, keys=existentes)
            log.info("Particao %s limpa: %d objetos removidos", prefixo_raw, len(existentes))

        # 4. Grava cada CSV e conta as linhas (sem o cabecalho)
        linhas_por_tabela: dict[str, int] = {}
        for nome, dados in csvs.items():
            tabela = PurePosixPath(nome).stem
            if tabela not in TABELAS_ESPERADAS:
                continue
            hook.load_bytes(dados, key=prefixo_raw + nome, bucket_name=BUCKET_RAW, replace=True)
            linhas = sum(1 for _ in csv.reader(io.StringIO(dados.decode("utf-8")))) - 1
            linhas_por_tabela[tabela] = linhas
            log.info("%s: %d linhas gravadas em s3://%s/%s%s", tabela, linhas, BUCKET_RAW, prefixo_raw, nome)

        return linhas_por_tabela

    espera_export >> descompacta_para_raw()


banvic_ingestao()