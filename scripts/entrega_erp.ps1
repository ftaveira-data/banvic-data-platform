<#
.SYNOPSIS
    Simula o ERP do BanVic entregando o export diario na landing zone (MinIO).

.DESCRIPTION
    Envia data/source/banvic_data.zip para s3://landing/banvic/dt=<DATA>/
    usando o MinIO Client (mc) em container e a credencial de menor
    privilegio pipeline-svc, lida do arquivo .env.

.EXAMPLE
    .\scripts\entrega_erp.ps1
    .\scripts\entrega_erp.ps1 -Data 2026-11-26
#>
param(
    [ValidatePattern('^\d{4}-\d{2}-\d{2}$')]
    [string]$Data = (Get-Date -Format "yyyy-MM-dd")
)

$ErrorActionPreference = "Stop"

$Raiz    = Split-Path -Parent $PSScriptRoot
$Origem  = Join-Path $Raiz "data\source"
$EnvFile = Join-Path $Raiz ".env"

# Imagem do mc fixada por digest (mesma politica do Terraform)
$ImagemMc = "cgr.dev/chainguard/minio-client@sha256:fac83a05890847b4af12e406018088d54f16f1d53e6e39cb68e56591be6e5b3a"

# --- Validacoes -------------------------------------------------------------
if (-not (Test-Path (Join-Path $Origem "banvic_data.zip"))) {
    throw "Arquivo de origem nao encontrado: $Origem\banvic_data.zip"
}
if (-not (Test-Path $EnvFile)) {
    throw "Arquivo .env nao encontrado. Copie .env.example para .env e preencha."
}

# --- Le o .env (formato CHAVE=VALOR, ignora comentarios) --------------------
$Vars = @{}
Get-Content $EnvFile | Where-Object { $_ -match '^\s*[^#\s].*=' } | ForEach-Object {
    $Chave, $Valor = $_ -split '=', 2
    $Vars[$Chave.Trim()] = $Valor.Trim()
}
foreach ($Chave in "MINIO_PIPELINE_USER", "MINIO_PIPELINE_PASSWORD") {
    if (-not $Vars[$Chave]) { throw "Variavel $Chave ausente ou vazia no .env" }
}

# --- Upload -----------------------------------------------------------------
$Destino = "banvic/landing/banvic/dt=$Data/banvic_data.zip"
Write-Host "Entregando export do ERP de $Data em s3://landing/banvic/dt=$Data/ ..."

docker run --rm --network kind `
    -e "MC_HOST_banvic=http://$($Vars.MINIO_PIPELINE_USER):$($Vars.MINIO_PIPELINE_PASSWORD)@banvic-control-plane:30900" `
    -e "MC_CONFIG_DIR=/tmp/.mc" `
    -v "${Origem}:/origem:ro" `
    $ImagemMc cp /origem/banvic_data.zip $Destino

if ($LASTEXITCODE -ne 0) { throw "Falha no upload (codigo de saida $LASTEXITCODE)" }
Write-Host "Entrega concluida."