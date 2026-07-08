param(
  [string]$InstallDir = (Join-Path $env:LOCALAPPDATA "Programs\Al-Fakhir")
)

$ErrorActionPreference = "Stop"

$wsh = New-Object -ComObject WScript.Shell
$appExe = Join-Path $InstallDir "app\alfakhir_desktop.exe"
$cmdLauncher = Join-Path $InstallDir "Al-Fakhir.cmd"
$iconCustom = Join-Path $InstallDir "Al-Fakhir.ico"

if (-not (Test-Path -LiteralPath $appExe)) {
  throw "Application introuvable : $appExe"
}

# Prefer .cmd launcher (API + app). Fallback = direct exe.
$target = if (Test-Path -LiteralPath $cmdLauncher) { $cmdLauncher } else { $appExe }
$workDir = if (Test-Path -LiteralPath $cmdLauncher) { $InstallDir } else { (Join-Path $InstallDir "app") }

$iconLoc = if (Test-Path -LiteralPath $iconCustom) {
  "$iconCustom,0"
} else {
  "$appExe,0"
}

$paths = @(
  (Join-Path ([Environment]::GetFolderPath("Desktop")) "Al-Fakhir.lnk"),
  (Join-Path $env:APPDATA "Microsoft\Windows\Start Menu\Programs\Al-Fakhir.lnk")
)

foreach ($p in $paths) {
  $dir = Split-Path $p
  if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Force -Path $dir | Out-Null }
  if (Test-Path -LiteralPath $p) { Remove-Item -LiteralPath $p -Force }
  $sc = $wsh.CreateShortcut($p)
  $sc.TargetPath = $target
  $sc.Arguments = ""
  $sc.WorkingDirectory = $workDir
  $sc.Description = "Restaurant Al-Fakhir"
  $sc.IconLocation = $iconLoc
  $sc.WindowStyle = 1
  $sc.Save()
  Write-Host "Raccourci : $p -> $target" -ForegroundColor Green
}
