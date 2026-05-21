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

Copy-Item (Join-Path $Root "install\Al-Fakhir.ps1") (Join-Path $InstallDir "Al-Fakhir.ps1") -Force
Copy-Item (Join-Path $Root "install\start-backend.ps1") (Join-Path $InstallDir "start-backend.ps1") -Force
if (Test-Path (Join-Path $Root "install\Al-Fakhir.vbs")) {
  Copy-Item (Join-Path $Root "install\Al-Fakhir.vbs") (Join-Path $InstallDir "Al-Fakhir.vbs") -Force
}

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
