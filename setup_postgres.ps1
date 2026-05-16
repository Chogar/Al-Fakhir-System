# Apres installation PostgreSQL 17 : demarrer le service et creer la base alfakhir.
$ErrorActionPreference = "Stop"

$pgBin = "C:\Program Files\PostgreSQL\17\bin"
$psql = Join-Path $pgBin "psql.exe"
$serviceName = "postgresql-x64-17"

if (-not (Test-Path $psql)) {
  Write-Host "psql introuvable. Installez PostgreSQL :" -ForegroundColor Yellow
  Write-Host "  winget install PostgreSQL.PostgreSQL.17" -ForegroundColor Yellow
  exit 1
}

$svc = Get-Service -Name $serviceName -ErrorAction SilentlyContinue
if ($svc) {
  if ($svc.Status -ne "Running") {
    Write-Host "Demarrage du service $serviceName ..." -ForegroundColor Cyan
    Start-Service $serviceName
    Start-Sleep -Seconds 3
  }
} else {
  Write-Host "Service $serviceName introuvable. Attendez la fin de l'installation PostgreSQL." -ForegroundColor Yellow
  exit 2
}

$env:PGPASSWORD = "postgres"
Write-Host "Creation de la base alfakhir (si absente) ..." -ForegroundColor Cyan
& $psql -U postgres -h localhost -p 5432 -tc "SELECT 1 FROM pg_database WHERE datname = 'alfakhir'" | Out-Null
$exists = & $psql -U postgres -h localhost -p 5432 -tAc "SELECT 1 FROM pg_database WHERE datname = 'alfakhir'"
if ($exists -ne "1") {
  & $psql -U postgres -h localhost -p 5432 -c "CREATE DATABASE alfakhir;"
  Write-Host "Base alfakhir creee." -ForegroundColor Green
} else {
  Write-Host "Base alfakhir existe deja." -ForegroundColor Green
}

Write-Host ""
Write-Host "Relancez : powershell -ExecutionPolicy Bypass -File .\run_backend.ps1" -ForegroundColor Cyan
