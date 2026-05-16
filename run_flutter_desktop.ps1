param([switch]$SkipSymlinkProbe)

$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location (Join-Path $Root "alfakhir_desktop")

$flutterBat = $null
if ($env:FLUTTER_ROOT) {
  $c = Join-Path $env:FLUTTER_ROOT "bin\flutter.bat"
  if (Test-Path $c) { $flutterBat = $c }
}
if (-not $flutterBat) {
  foreach ($c in @(
      (Join-Path $env:USERPROFILE "Downloads\flutter_windows_3.41.9-stable\flutter\bin\flutter.bat"),
      "C:\src\flutter\bin\flutter.bat",
      "C:\flutter\bin\flutter.bat"
    )) {
    if (Test-Path $c) { $flutterBat = $c; break }
  }
}
if (-not $flutterBat) {
  $cmd = Get-Command flutter -ErrorAction SilentlyContinue
  if ($cmd) { $flutterBat = $cmd.Source }
}
if (-not $flutterBat) {
  Write-Error "Flutter introuvable. Définissez FLUTTER_ROOT ou ajoutez ...\flutter\bin au PATH."
}

if (-not $SkipSymlinkProbe) {
  $pubspec = Join-Path (Get-Location) "pubspec.yaml"
  $probe = Join-Path (Get-Location) ".flutter_symlink_probe_$PID"
  if (-not (Test-Path -LiteralPath $pubspec)) {
    Write-Error "pubspec.yaml introuvable dans $(Get-Location)"
  }
  if (Test-Path -LiteralPath $probe) {
    Remove-Item -LiteralPath $probe -Force -ErrorAction SilentlyContinue
  }
  try {
    $null = New-Item -ItemType SymbolicLink -LiteralPath $probe -Target $pubspec -ErrorAction Stop
  } catch {
    Write-Host ""
    Write-Host "Windows refuse encore de creer des liens symboliques (Flutter en a besoin pour les plugins Windows)." -ForegroundColor Yellow
    Write-Host "Le mode developpeur peut apparaitre actif sans que le droit de creer des symlinks soit reellement applique." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "A essayer dans l'ordre :" -ForegroundColor Yellow
    Write-Host "  1. Redemarrer le PC." -ForegroundColor Yellow
    Write-Host "  2. Parametres > Mise a jour et securite > Pour les developpeurs : desactiver puis reactiver le mode developpeur." -ForegroundColor Yellow
    Write-Host "  3. Compte administrateur : Win+R, secpol.msc > Attribution des droits utilisateur > Creer des liens symboliques > ajouter Utilisateurs (ou votre compte)." -ForegroundColor Yellow
    Write-Host "  4. Contournement : PowerShell ou CMD en Executer en tant qu'administrateur, puis relancer ce script." -ForegroundColor Yellow
    Write-Host ""
    exit 2
  } finally {
    if (Test-Path -LiteralPath $probe) {
      Remove-Item -LiteralPath $probe -Force -ErrorAction SilentlyContinue
    }
  }
}

& $flutterBat pub get
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
& $flutterBat run -d windows
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
