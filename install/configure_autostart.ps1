# Demarrage automatique : PostgreSQL + API Al-Fakhir a la connexion Windows.
param(
  [string]$InstallDir = (Join-Path $env:LOCALAPPDATA "Programs\Al-Fakhir")
)

$ErrorActionPreference = "Stop"
$TaskName = "Al-Fakhir-API"
$BackendDir = Join-Path $InstallDir "backend"

function Resolve-NodeExe {
  foreach ($p in @(
      "C:\Program Files\nodejs\node.exe",
      "C:\Program Files (x86)\nodejs\node.exe"
    )) {
    if (Test-Path $p) { return $p }
  }
  $node = Get-Command node.exe -ErrorAction SilentlyContinue
  if ($node) { return $node.Source }
  return $null
}

$nodeExe = Resolve-NodeExe
if (-not $nodeExe) {
  Write-Error "Node.js introuvable. Installez : winget install OpenJS.NodeJS.LTS"
}
if (-not (Test-Path (Join-Path $BackendDir "dist\main.js"))) {
  Write-Error "Backend introuvable : $BackendDir"
}

foreach ($pgName in @("postgresql-x64-17", "postgresql-x64-16", "postgresql-x64-15")) {
  $svc = Get-Service -Name $pgName -ErrorAction SilentlyContinue
  if ($svc) {
    Set-Service -Name $pgName -StartupType Automatic -ErrorAction SilentlyContinue
    if ($svc.Status -ne "Running") {
      Start-Service -Name $pgName -ErrorAction SilentlyContinue
    }
    break
  }
}

$existing = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
if ($existing) {
  Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false
}

$action = New-ScheduledTaskAction -Execute $nodeExe -Argument "dist\main.js" -WorkingDirectory $BackendDir
$trigger = New-ScheduledTaskTrigger -AtLogOn
$principal = New-ScheduledTaskPrincipal -UserId $env:USERNAME -LogonType Interactive -RunLevel Limited
$settings = New-ScheduledTaskSettingsSet `
  -AllowStartIfOnBatteries `
  -DontStopIfGoingOnBatteries `
  -StartWhenAvailable `
  -RestartCount 5 `
  -RestartInterval (New-TimeSpan -Minutes 1)

Register-ScheduledTask `
  -TaskName $TaskName `
  -Action $action `
  -Trigger $trigger `
  -Principal $principal `
  -Settings $settings `
  -Description "API locale Restaurant Al-Fakhir (demarrage automatique)" | Out-Null

Start-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue

# Copie des scripts de lancement dans le dossier installe
$installSource = Join-Path (Split-Path -Parent $MyInvocation.MyCommand.Path) "."
foreach ($file in @("Al-Fakhir.vbs", "start-backend.ps1", "Al-Fakhir.ps1")) {
  $src = Join-Path $installSource $file
  if (Test-Path $src) {
    Copy-Item $src (Join-Path $InstallDir $file) -Force
  }
}

Write-Host "Demarrage automatique configure." -ForegroundColor Green
Write-Host "  Tache planifiee : $TaskName (a la connexion)" -ForegroundColor DarkGray
Write-Host "  Raccourci : double-clic sur Al-Fakhir (sans terminal)" -ForegroundColor DarkGray
