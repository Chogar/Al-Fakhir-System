# Configuration locale Windows (sans elevation) : PATH Flutter, FLUTTER_ROOT, Git + core.symlinks
$ErrorActionPreference = "Stop"

function Add-UserPathEntry {
  param([string]$Dir)
  if (-not (Test-Path -LiteralPath $Dir)) { return $false }
  $cur = [Environment]::GetEnvironmentVariable("Path", "User")
  if (-not $cur) { $cur = "" }
  $parts = $cur -split ";" | Where-Object { $_ -ne "" }
  foreach ($p in $parts) {
    try {
      if ((Resolve-Path -LiteralPath $p -ErrorAction SilentlyContinue).Path -eq (Resolve-Path -LiteralPath $Dir).Path) {
        return $false
      }
    } catch { }
  }
  $new = if ($cur.TrimEnd(";") -eq "") { $Dir } else { "$cur;$Dir" }
  [Environment]::SetEnvironmentVariable("Path", $new, "User")
  if (-not ($env:Path -split ";" | Where-Object { $_ -eq $Dir })) {
    $env:Path += ";$Dir"
  }
  return $true
}

$flutterRoot = $null
foreach ($c in @(
    (Join-Path $env:USERPROFILE "Downloads\flutter_windows_3.41.9-stable\flutter"),
    "C:\src\flutter",
    "C:\flutter"
  )) {
  if (Test-Path (Join-Path $c "bin\flutter.bat")) { $flutterRoot = $c; break }
}
if (-not $flutterRoot -and $env:FLUTTER_ROOT) {
  if (Test-Path (Join-Path $env:FLUTTER_ROOT "bin\flutter.bat")) { $flutterRoot = $env:FLUTTER_ROOT }
}

if ($flutterRoot) {
  [Environment]::SetEnvironmentVariable("FLUTTER_ROOT", $flutterRoot, "User")
  $env:FLUTTER_ROOT = $flutterRoot
  $added = Add-UserPathEntry -Dir (Join-Path $flutterRoot "bin")
  Write-Host "FLUTTER_ROOT utilisateur = $flutterRoot"
  Write-Host $(if ($added) { "PATH : dossier bin Flutter ajoute (profil utilisateur)." } else { "PATH : bin Flutter deja present ou introuvable." })
} else {
  Write-Warning "SDK Flutter introuvable (Downloads\flutter_windows_* ou C:\src\flutter). Installe Flutter ou definis FLUTTER_ROOT."
}

$gitExe = $null
foreach ($g in @(
    "C:\Program Files\Git\cmd\git.exe",
    "C:\Program Files (x86)\Git\cmd\git.exe"
  )) {
  if (Test-Path $g) { $gitExe = $g; break }
}
if (-not $gitExe) {
  $w = Get-Command git.exe -ErrorAction SilentlyContinue
  if ($w) { $gitExe = $w.Source }
}

if ($gitExe) {
  $gitCmd = Split-Path -Parent $gitExe
  $null = Add-UserPathEntry -Dir $gitCmd
  & $gitExe config --global core.symlinks true
  Write-Host "Git : core.symlinks=true (global), PATH cmd ajoute si besoin : $gitCmd"
} else {
  Write-Warning "Git introuvable. Installe https://git-scm.com puis relance ce script."
}

Write-Host ""
Write-Host "Ouvre un NOUVEAU terminal pour que PATH / FLUTTER_ROOT soient pris en compte partout." -ForegroundColor Cyan
Write-Host "Symlinks + Visual Studio Build Tools : droits admin / redemarrage, voir messages de run_flutter_desktop.ps1 et flutter doctor." -ForegroundColor Cyan
