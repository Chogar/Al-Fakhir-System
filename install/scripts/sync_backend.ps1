# Copie le backend du projet vers l'installation locale puis redemarre l'API.
$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$ProjectRoot = Split-Path -Parent $Root
$BackendSrc = Join-Path $ProjectRoot "backend"
$InstallDir = Join-Path $env:LOCALAPPDATA "Programs\Al-Fakhir"
$BackendDest = Join-Path $InstallDir "backend"

if (-not (Test-Path (Join-Path $BackendSrc "dist\main.js"))) {
  Write-Error "Backend introuvable : $BackendSrc"
}

Write-Host "Copie API vers $BackendDest ..." -ForegroundColor Cyan
foreach ($name in @("dist", "node_modules", "package.json")) {
  $src = Join-Path $BackendSrc $name
  if (-not (Test-Path $src)) { continue }
  $dest = Join-Path $BackendDest $name
  if (Test-Path $src -PathType Container) {
    robocopy $src $dest /MIR /NFL /NDL /NJH /NJS /NC /NS | Out-Null
    if ($LASTEXITCODE -ge 8) { Write-Error "Echec copie $name (robocopy $LASTEXITCODE)." }
  } else {
    Copy-Item $src $dest -Force
  }
}

$restart = Join-Path $InstallDir "scripts\restart_api.ps1"
if (Test-Path $restart) {
  & powershell -NoProfile -ExecutionPolicy Bypass -File $restart
}
