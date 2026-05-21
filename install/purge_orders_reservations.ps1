# Supprime toutes les commandes et reservations (base alfakhir).
# Conserve : utilisateurs, menu, tables, clients.
$ErrorActionPreference = "Stop"

$psql = @(
  "C:\Program Files\PostgreSQL\17\bin\psql.exe",
  "C:\Program Files\PostgreSQL\16\bin\psql.exe"
) | Where-Object { Test-Path $_ } | Select-Object -First 1

if (-not $psql) {
  Write-Error "psql introuvable. Installez PostgreSQL."
}

$envPath = Join-Path $env:LOCALAPPDATA "Programs\Al-Fakhir\backend\.env"
if (-not (Test-Path $envPath)) {
  $envPath = Join-Path (Split-Path -Parent $PSScriptRoot) "backend\.env"
}
$dbUser = "postgres"
$dbPass = "postgres"
$dbName = "alfakhir"
if (Test-Path $envPath) {
  Get-Content $envPath | ForEach-Object {
    if ($_ -match '^DATABASE_USER=(.+)$') { $dbUser = $matches[1].Trim() }
    if ($_ -match '^DATABASE_PASSWORD=(.+)$') { $dbPass = $matches[1].Trim() }
    if ($_ -match '^DATABASE_NAME=(.+)$') { $dbName = $matches[1].Trim() }
  }
}

$env:PGPASSWORD = $dbPass
$sqlFile = Join-Path $PSScriptRoot "purge_orders_reservations.sql"

Write-Host "Purge commandes + reservations ($dbName)..." -ForegroundColor Cyan
& $psql -h localhost -U $dbUser -d $dbName -f $sqlFile
Write-Host "Termine. Relancez Al-Fakhir." -ForegroundColor Green
