# Deploiement complet Al-Fakhir : compile, copie Release, API, raccourci Bureau.
param(
  [switch]$SkipBuild
)

$ErrorActionPreference = "Stop"
$ProjectRoot = Split-Path -Parent $PSScriptRoot
$Desktop = Join-Path $ProjectRoot "alfakhir_desktop"
$InstallDir = Join-Path $env:LOCALAPPDATA "Programs\Al-Fakhir"
$ReleaseDir = Join-Path $Desktop "build\windows\x64\runner\Release"
$AppDir = Join-Path $InstallDir "app"

Write-Host "=== Deploiement Al-Fakhir ===" -ForegroundColor Cyan

Get-Process alfakhir_desktop -ErrorAction SilentlyContinue | Stop-Process -Force
Start-Sleep -Seconds 2

if (-not $SkipBuild) {
  Write-Host "Compilation Flutter..." -ForegroundColor Yellow
  Push-Location $Desktop
  flutter build windows --release
  if ($LASTEXITCODE -ne 0) { Pop-Location; throw "Echec flutter build" }
  Pop-Location
}

if (-not (Test-Path (Join-Path $ReleaseDir "alfakhir_desktop.exe"))) {
  throw "Exe introuvable : $ReleaseDir\alfakhir_desktop.exe"
}

New-Item -ItemType Directory -Force -Path $InstallDir, $AppDir, (Join-Path $InstallDir "scripts") | Out-Null

Write-Host "Copie binaire Release..." -ForegroundColor Yellow
robocopy $ReleaseDir $AppDir /MIR /NFL /NDL /NJH /NJS /NC /NS | Out-Null
if ($LASTEXITCODE -ge 8) { throw "Echec robocopy app ($LASTEXITCODE)" }

foreach ($f in @("Al-Fakhir.ps1", "Al-Fakhir.vbs", "Al-Fakhir-API.vbs", "start-backend.ps1")) {
  Copy-Item (Join-Path $PSScriptRoot $f) $InstallDir -Force
}
if (Test-Path (Join-Path $PSScriptRoot "Al-Fakhir.ico")) {
  Copy-Item (Join-Path $PSScriptRoot "Al-Fakhir.ico") $InstallDir -Force
}
Copy-Item (Join-Path $PSScriptRoot "scripts\*") (Join-Path $InstallDir "scripts") -Force -Recurse
Copy-Item (Join-Path $PSScriptRoot "receipt_printer.txt") $InstallDir -Force

$buildInfo = @(
  "build_time=$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
  "source=$ReleaseDir"
  (Get-FileHash (Join-Path $AppDir "alfakhir_desktop.exe") -Algorithm SHA256).Hash
)
$buildInfo | Set-Content (Join-Path $InstallDir "BUILD_VERSION.txt") -Encoding UTF8

$sync = Join-Path $PSScriptRoot "scripts\sync_backend.ps1"
if (Test-Path $sync) {
  & powershell -NoProfile -ExecutionPolicy Bypass -File $sync
}

& powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot "update_shortcuts.ps1") -InstallDir $InstallDir

$exe = Get-Item (Join-Path $AppDir "alfakhir_desktop.exe")
Write-Host ""
Write-Host "OK - $($exe.LastWriteTime) - $($exe.Length) octets" -ForegroundColor Green
Write-Host "Raccourci Bureau : Al-Fakhir.lnk" -ForegroundColor Green
Write-Host "Version : $(Join-Path $InstallDir 'BUILD_VERSION.txt')" -ForegroundColor DarkGray
