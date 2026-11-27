"""
DAG de verificacao do ambiente.

Confirma que o git-sync entregou o codigo, o scheduler agendou
e o KubernetesExecutor criou um pod para cada task.
"""

from datetime import datetime

from airflow.sdk import dag, task


@dag(
    dag_id="banvic_smoke_test",
    description="Verificacao do ambiente: git-sync, scheduler e KubernetesExecutor",
    schedule=None,  # roda apenas quando disparada manualmente
    start_date=datetime(2026, 11, 1),
    catchup=False,
    tags=["banvic", "infra"],
)
def banvic_smoke_test():
    @task
    def ola():
        import socket

        hostname = socket.gethostname()
        print(f"Task executada no pod: {hostname}")
        return hostname

    @task
    def confirma(pod_anterior: str):
        import socket

        print(f"Task anterior rodou no pod: {pod_anterior}")
        print(f"Esta task roda no pod: {socket.gethostname()}")

    confirma(ola())


banvic_smoke_test()