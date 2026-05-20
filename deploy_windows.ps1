# Installe Al-Fakhir sur ce PC : build release Flutter + API + raccourcis Bureau / Menu Demarrer.
param(
  [string]$InstallDir = (Join-Path $env:LOCALAPPDATA "Programs\Al-Fakhir"),
  [switch]$SkipBuild,
  [switch]$SkipSymlinkProbe
)

$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent $MyInvocation.MyCommand.Path
$DesktopApp = Join-Path $Root "alfakhir_desktop"
$BackendSrc = Join-Path $Root "backend"
$ReleaseSrc = Join-Path $DesktopApp "build\windows\x64\runner\Release"
$AppDest = Join-Path $InstallDir "app"
$BackendDest = Join-Path $InstallDir "backend"

function Resolve-FlutterBat {
  if ($env:FLUTTER_ROOT) {
    $c = Join-Path $env:FLUTTER_ROOT "bin\flutter.bat"
    if (Test-Path $c) { return $c }
  }
  foreach ($c in @(
      (Join-Path $env:USERPROFILE "Downloads\flutter_windows_3.41.9-stable\flutter\bin\flutter.bat"),
      "C:\src\flutter\bin\flutter.bat",
      "C:\flutter\bin\flutter.bat"
    )) {
    if (Test-Path $c) { return $c }
  }
  $cmd = Get-Command flutter -ErrorAction SilentlyContinue
  if ($cmd) { return $cmd.Source }
  return $null
}

function New-Shortcut {
  param([string]$Path, [string]$Target, [string]$Arguments, [string]$WorkingDirectory, [string]$Description)
  $wsh = New-Object -ComObject WScript.Shell
  $sc = $wsh.CreateShortcut($Path)
  $sc.TargetPath = $Target
  if ($Arguments) { $sc.Arguments = $Arguments }
  $sc.WorkingDirectory = $WorkingDirectory
  if ($Description) { $sc.Description = $Description }
  $sc.Save()
}

$flutterBat = Resolve-FlutterBat
if (-not $flutterBat) {
  Write-Error "Flutter introuvable. Installez Flutter ou definissez FLUTTER_ROOT."
}

if (-not $SkipBuild) {
  Set-Location $DesktopApp
  if (-not $SkipSymlinkProbe) {
    $pubspec = Join-Path (Get-Location) "pubspec.yaml"
    $probe = Join-Path (Get-Location) ".flutter_symlink_probe_$PID"
    if (Test-Path -LiteralPath $probe) { Remove-Item -LiteralPath $probe -Force -ErrorAction SilentlyContinue }
    try {
      $null = New-Item -ItemType SymbolicLink -LiteralPath $probe -Target $pubspec -ErrorAction Stop
    } catch {
      Write-Host "Symlinks refuses : relancez avec -SkipSymlinkProbe si le build a deja reussi." -ForegroundColor Yellow
      exit 2
    } finally {
      if (Test-Path -LiteralPath $probe) { Remove-Item -LiteralPath $probe -Force -ErrorAction SilentlyContinue }
    }
  }
  Write-Host "Compilation release Windows..." -ForegroundColor Cyan
  & $flutterBat pub get
  if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
  & $flutterBat build windows --release
  if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
  Set-Location $Root
}

if (-not (Test-Path (Join-Path $ReleaseSrc "alfakhir_desktop.exe"))) {
  Write-Error "Executable introuvable : $ReleaseSrc\alfakhir_desktop.exe (lancez sans -SkipBuild)."
}

if (-not (Test-Path (Join-Path $BackendSrc "dist\main.js"))) {
  Write-Error "backend\dist\main.js introuvable."
}

Write-Host "Installation dans : $InstallDir" -ForegroundColor Cyan
New-Item -ItemType Directory -Force -Path $AppDest, $BackendDest | Out-Null

Write-Host "Copie application..." -ForegroundColor DarkGray
robocopy $ReleaseSrc $AppDest /MIR /NFL /NDL /NJH /NJS /NC /NS | Out-Null
if ($LASTEXITCODE -ge 8) { Write-Error "Echec copie application (robocopy $LASTEXITCODE)." }

Write-Host "Copie API..." -ForegroundColor DarkGray
foreach ($name in @("dist", "node_modules", "package.json", ".env", ".env.example")) {
  $src = Join-Path $BackendSrc $name
  if (-not (Test-Path $src)) { continue }
  $dest = Join-Path $BackendDest $name
  if (Test-Path $src -PathType Container) {
    robocopy $src $dest /MIR /NFL /NDL /NJH /NJS /NC /NS | Out-Null
    if ($LASTEXITCODE -ge 8) { Write-Error "Echec copie $name." }
  } else {
    Copy-Item $src $dest -Force
  }
}
if (-not (Test-Path (Join-Path $BackendDest ".env"))) {
  if (Test-Path (Join-Path $BackendDest ".env.example")) {
    Copy-Item (Join-Path $BackendDest ".env.example") (Join-Path $BackendDest ".env")
  }
}

$launcher = @'
$ErrorActionPreference = "Stop"
$InstallRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$AppExe = Join-Path $InstallRoot "app\alfakhir_desktop.exe"
$BackendScript = Join-Path $InstallRoot "start-backend.ps1"
$HealthUrl = "http://127.0.0.1:3000/api/health"

function Test-ApiHealth {
  try {
    $r = Invoke-WebRequest -Uri $HealthUrl -UseBasicParsing -TimeoutSec 2
    return $r.StatusCode -eq 200
  } catch { return $false }
}

if (-not (Test-ApiHealth)) {
  Write-Host "Demarrage du serveur local..." -ForegroundColor Cyan
  Start-Process powershell -WindowStyle Hidden -ArgumentList @(
    "-NoProfile", "-ExecutionPolicy", "Bypass",
    "-File", $BackendScript
  ) | Out-Null
  $deadline = (Get-Date).AddSeconds(45)
  while ((Get-Date) -lt $deadline) {
    if (Test-ApiHealth) { break }
    Start-Sleep -Milliseconds 500
  }
  if (-not (Test-ApiHealth)) {
    Write-Host ""
    Write-Host "L'API ne repond pas. Verifiez PostgreSQL et backend\.env puis relancez." -ForegroundColor Red
    Write-Host "  winget install PostgreSQL.PostgreSQL.17" -ForegroundColor Yellow
    Write-Host "  powershell -File setup_postgres.ps1  (depuis le dossier projet)" -ForegroundColor Yellow
    Read-Host "Appuyez sur Entree pour fermer"
    exit 1
  }
}

Start-Process -FilePath $AppExe -WorkingDirectory (Split-Path $AppExe)
'@

$startBackend = @'
$ErrorActionPreference = "Stop"
$Backend = Join-Path (Split-Path -Parent $MyInvocation.MyCommand.Path) "backend"
Set-Location $Backend

function Resolve-NodeDir {
  foreach ($p in @("C:\Program Files\nodejs", "C:\Program Files (x86)\nodejs")) {
    if (Test-Path (Join-Path $p "node.exe")) { return $p }
  }
  $node = Get-Command node.exe -ErrorAction SilentlyContinue
  if ($node) { return Split-Path -Parent $node.Source }
  return $null
}

$nodeDir = Resolve-NodeDir
if (-not $nodeDir) { exit 1 }
if (($env:Path -split ';' | Where-Object { $_ -eq $nodeDir }).Count -eq 0) {
  $env:Path = "$nodeDir;$env:Path"
}
$nodeExe = Join-Path $nodeDir "node.exe"
& $nodeExe dist/main.js
'@

Set-Content -Path (Join-Path $InstallDir "Al-Fakhir.ps1") -Value $launcher -Encoding UTF8
Set-Content -Path (Join-Path $InstallDir "start-backend.ps1") -Value $startBackend -Encoding UTF8

$psExe = (Get-Command powershell.exe).Source
$launchArgs = "-NoProfile -ExecutionPolicy Bypass -File `"$(Join-Path $InstallDir 'Al-Fakhir.ps1')`""

$desktop = [Environment]::GetFolderPath("Desktop")
$startMenu = Join-Path $env:APPDATA "Microsoft\Windows\Start Menu\Programs"
New-Item -ItemType Directory -Force -Path $startMenu | Out-Null

$shortcutDesktop = Join-Path $desktop "Al-Fakhir.lnk"
$shortcutMenu = Join-Path $startMenu "Al-Fakhir.lnk"
New-Shortcut -Path $shortcutDesktop -Target $psExe -Arguments $launchArgs -WorkingDirectory $InstallDir -Description "Al-Fakhir System - Gestion restaurant"
New-Shortcut -Path $shortcutMenu -Target $psExe -Arguments $launchArgs -WorkingDirectory $InstallDir -Description "Al-Fakhir System - Gestion restaurant"

Write-Host ""
Write-Host "Installation terminee." -ForegroundColor Green
Write-Host "  Dossier : $InstallDir" -ForegroundColor DarkGray
Write-Host "  Raccourci Bureau : $shortcutDesktop" -ForegroundColor DarkGray
Write-Host "  Menu Demarrer : Al-Fakhir" -ForegroundColor DarkGray
Write-Host ""
Write-Host "Double-cliquez sur Al-Fakhir sur le Bureau pour utiliser l'application." -ForegroundColor Cyan
Write-Host "Connexion : identifiants configures dans backend\.env (ex. Chogar)." -ForegroundColor DarkGray
