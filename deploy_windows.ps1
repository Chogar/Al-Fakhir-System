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

function Stop-AlFakhirDesktopApp {
  $names = @('alfakhir_desktop')
  foreach ($n in $names) {
    Get-Process -Name $n -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
  }
  Start-Sleep -Seconds 1
}

function Invoke-FlutterWindowsReleaseBuild {
  param([string]$FlutterBat, [string]$DesktopDir)
  Push-Location $DesktopDir
  try {
    & $FlutterBat build windows --release
    if ($LASTEXITCODE -eq 0) { return }
    Write-Host "Build echoue (souvent dossier build corrompu ou exe verrouille). Nettoyage..." -ForegroundColor Yellow
    Stop-AlFakhirDesktopApp
    & $FlutterBat clean
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
    Remove-Item -Recurse -Force -ErrorAction SilentlyContinue (Join-Path $DesktopDir "build")
    & $FlutterBat build windows --release
    if ($LASTEXITCODE -ne 0) {
      Write-Host "Fermez Al-Fakhir puis relancez mettre_a_jour_desktop.ps1" -ForegroundColor Red
      exit $LASTEXITCODE
    }
  } finally {
    Pop-Location
  }
}

function New-Shortcut {
  param(
    [string]$Path,
    [string]$Target,
    [string]$Arguments,
    [string]$WorkingDirectory,
    [string]$Description,
    [string]$IconLocation
  )
  $wsh = New-Object -ComObject WScript.Shell
  $sc = $wsh.CreateShortcut($Path)
  $sc.TargetPath = $Target
  if ($Arguments) { $sc.Arguments = $Arguments }
  $sc.WorkingDirectory = $WorkingDirectory
  if ($Description) { $sc.Description = $Description }
  if ($IconLocation) { $sc.IconLocation = $IconLocation }
  $sc.Save()
}

$flutterBat = Resolve-FlutterBat
if (-not $flutterBat) {
  Write-Error "Flutter introuvable. Installez Flutter ou definissez FLUTTER_ROOT."
}

if (-not $SkipBuild) {
  Stop-AlFakhirDesktopApp
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
  $flutterBin = Split-Path -Parent $flutterBat
  $dartBat = Join-Path $flutterBin "dart.bat"
  $iconScript = Join-Path $DesktopApp "scripts\generate_app_icon.ps1"
  if (Test-Path $iconScript) {
    Write-Host "Icone application (design + ICO raccourci)..." -ForegroundColor DarkGray
    & powershell -NoProfile -ExecutionPolicy Bypass -File $iconScript
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
  }
  if (Test-Path $dartBat) {
    & $dartBat run flutter_launcher_icons
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
  }
  Invoke-FlutterWindowsReleaseBuild -FlutterBat $flutterBat -DesktopDir $DesktopApp
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

foreach ($file in @("Al-Fakhir.ps1", "start-backend.ps1", "Al-Fakhir.vbs", "Al-Fakhir-API.vbs", "receipt_printer.txt", "Al-Fakhir.ico")) {
  $src = Join-Path $Root "install\$file"
  if (Test-Path $src) {
    Copy-Item $src (Join-Path $InstallDir $file) -Force
  }
}

$scriptsSrc = Join-Path $Root "install\scripts"
$scriptsDest = Join-Path $InstallDir "scripts"
if (Test-Path $scriptsSrc) {
  New-Item -ItemType Directory -Force -Path $scriptsDest | Out-Null
  robocopy $scriptsSrc $scriptsDest /MIR /NFL /NDL /NJH /NJS /NC /NS | Out-Null
}

Write-Host "Demarrage automatique (API a la connexion)..." -ForegroundColor DarkGray
& powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $Root "install\configure_autostart.ps1") -InstallDir $InstallDir
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Host "Raccourcis Bureau / Menu Demarrer..." -ForegroundColor DarkGray
& powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $Root "install\update_shortcuts.ps1") -InstallDir $InstallDir
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

$shortcutDesktop = Join-Path ([Environment]::GetFolderPath("Desktop")) "Al-Fakhir.lnk"
$shortcutMenu = Join-Path $env:APPDATA "Microsoft\Windows\Start Menu\Programs\Al-Fakhir.lnk"

Write-Host ""
Write-Host "Installation terminee." -ForegroundColor Green
Write-Host "  Dossier : $InstallDir" -ForegroundColor DarkGray
Write-Host "  Raccourci Bureau : $shortcutDesktop" -ForegroundColor DarkGray
Write-Host "  Menu Demarrer : Al-Fakhir" -ForegroundColor DarkGray
Write-Host ""
Write-Host "Double-cliquez sur Al-Fakhir : l'API demarre automatiquement a la connexion Windows." -ForegroundColor Cyan
Write-Host "Aucune commande a taper : uniquement le raccourci Bureau ou Menu Demarrer." -ForegroundColor DarkGray
Write-Host "Connexion : identifiants dans backend\.env (ex. Chogar)." -ForegroundColor DarkGray
