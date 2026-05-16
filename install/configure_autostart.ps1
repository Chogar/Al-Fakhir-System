# Demarrage automatique : PostgreSQL + API Al-Fakhir a la connexion (sans admin).
param(
  [string]$InstallDir = (Join-Path $env:LOCALAPPDATA "Programs\Al-Fakhir")
)

$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent $MyInvocation.MyCommand.Path

foreach ($pgName in @("postgresql-x64-17", "postgresql-x64-16", "postgresql-x64-15")) {
  $svc = Get-Service -Name $pgName -ErrorAction SilentlyContinue
  if ($svc) {
    try { Set-Service -Name $pgName -StartupType Automatic -ErrorAction Stop } catch { }
    if ($svc.Status -ne "Running") {
      try { Start-Service -Name $pgName -ErrorAction SilentlyContinue } catch { }
    }
    break
  }
}

foreach ($file in @("Al-Fakhir.vbs", "Al-Fakhir-API.vbs", "start-backend.ps1", "Al-Fakhir.ps1")) {
  $src = Join-Path $Root $file
  if (Test-Path $src) {
    Copy-Item $src (Join-Path $InstallDir $file) -Force
  }
}

$wsh = New-Object -ComObject WScript.Shell
$wscript = Join-Path $env:WINDIR "System32\wscript.exe"
$apiVbs = Join-Path $InstallDir "Al-Fakhir-API.vbs"
$startup = [Environment]::GetFolderPath("Startup")
$startupLink = Join-Path $startup "Al-Fakhir-API.lnk"

$sc = $wsh.CreateShortcut($startupLink)
$sc.TargetPath = $wscript
$sc.Arguments = "`"$apiVbs`""
$sc.WorkingDirectory = $InstallDir
$sc.Description = "API Restaurant Al-Fakhir (demarrage automatique)"
$sc.WindowStyle = 7
$sc.Save()

# Demarrer l'API maintenant (sans attendre la prochaine connexion)
Start-Process -FilePath $wscript -ArgumentList "`"$apiVbs`"" -WindowStyle Hidden -WorkingDirectory $InstallDir

Write-Host "Demarrage automatique configure." -ForegroundColor Green
Write-Host "  Dossier Demarrage : $startupLink" -ForegroundColor DarkGray
Write-Host "  Double-clic Bureau : Al-Fakhir (sans terminal)" -ForegroundColor DarkGray
