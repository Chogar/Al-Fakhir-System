param(
  [string]$InstallDir = (Join-Path $env:LOCALAPPDATA "Programs\Al-Fakhir")
)

$wsh = New-Object -ComObject WScript.Shell
$vbs = Join-Path $InstallDir "Al-Fakhir.vbs"
$wscript = Join-Path $env:WINDIR "System32\wscript.exe"
$appExe = Join-Path $InstallDir "app\alfakhir_desktop.exe"
$iconLoc = "$appExe,0"

$paths = @(
  (Join-Path ([Environment]::GetFolderPath("Desktop")) "Al-Fakhir.lnk"),
  (Join-Path $env:APPDATA "Microsoft\Windows\Start Menu\Programs\Al-Fakhir.lnk")
)

foreach ($p in $paths) {
  $dir = Split-Path $p
  if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Force -Path $dir | Out-Null }
  $sc = $wsh.CreateShortcut($p)
  $sc.TargetPath = $wscript
  $sc.Arguments = "`"$vbs`""
  $sc.WorkingDirectory = $InstallDir
  $sc.Description = "Restaurant Al-Fakhir"
  $sc.IconLocation = $iconLoc
  $sc.Save()
  Write-Host "Raccourci : $p"
}
