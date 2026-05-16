# Racine du repo : backend (fenetre separee) + app Flutter Windows.
$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent $MyInvocation.MyCommand.Path

Write-Host "Backend dans une nouvelle fenetre..." -ForegroundColor Cyan
Start-Process powershell -ArgumentList @(
  "-NoExit", "-NoProfile", "-ExecutionPolicy", "Bypass",
  "-File", (Join-Path $Root "run_backend.ps1")
)

Start-Sleep -Seconds 5

Write-Host "Application Flutter..." -ForegroundColor Cyan
& powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $Root "run_flutter_desktop.ps1") -SkipSymlinkProbe
