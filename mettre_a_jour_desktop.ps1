# Met a jour l'application installee sur le Bureau (build + copie + raccourcis).
param([switch]$SkipBuild)

$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent $MyInvocation.MyCommand.Path
$InstallDir = Join-Path $env:LOCALAPPDATA "Programs\Al-Fakhir"

Write-Host "=== Mise a jour Al-Fakhir Desktop ===" -ForegroundColor Cyan
Write-Host "Installation : $InstallDir" -ForegroundColor DarkGray

Stop-Process -Name alfakhir_desktop -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 2

$deployArgs = @("-NoProfile", "-ExecutionPolicy", "Bypass", "-File", (Join-Path $Root "deploy_windows.ps1"))
if ($SkipBuild) { $deployArgs += "-SkipBuild" }
$deployArgs += "-SkipSymlinkProbe"

& powershell @deployArgs
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

$exe = Join-Path $InstallDir "app\alfakhir_desktop.exe"
if (-not (Test-Path $exe)) {
  Write-Error "Application non trouvee apres deploiement : $exe"
}

$info = Get-Item $exe
Write-Host ""
Write-Host "Mise a jour terminee." -ForegroundColor Green
Write-Host "  Executable : $exe" -ForegroundColor DarkGray
Write-Host "  Date       : $($info.LastWriteTime)" -ForegroundColor DarkGray
Write-Host "  Taille     : $([math]::Round($info.Length / 1MB, 2)) Mo" -ForegroundColor DarkGray
Write-Host ""
Write-Host "Relancez Al-Fakhir depuis le raccourci Bureau (pas depuis Cursor)." -ForegroundColor Yellow
