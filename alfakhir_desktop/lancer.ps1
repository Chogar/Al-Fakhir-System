# Depuis alfakhir_desktop : lance le backend puis l'app Flutter (scripts a la racine du repo).
$ErrorActionPreference = "Stop"
$Repo = Split-Path -Parent $PSScriptRoot

Write-Host "=== Backend (nouvelle fenetre) ===" -ForegroundColor Cyan
Start-Process powershell -ArgumentList @(
  "-NoProfile", "-ExecutionPolicy", "Bypass",
  "-File", (Join-Path $Repo "run_backend.ps1")
)

Start-Sleep -Seconds 4

Write-Host "=== Application Flutter ===" -ForegroundColor Cyan
& powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $Repo "run_flutter_desktop.ps1") -SkipSymlinkProbe
