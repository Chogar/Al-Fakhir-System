# A executer avec le point:  . .\use_flutter_session.ps1
# (point + espace) pour que le PATH s'applique au terminal courant.

$flutterRoot = $env:FLUTTER_ROOT
if (-not $flutterRoot -or -not (Test-Path (Join-Path $flutterRoot "bin\flutter.bat"))) {
  $flutterRoot = "C:\Users\AL FAKHIR\Downloads\flutter_windows_3.41.9-stable\flutter"
}
$bin = Join-Path $flutterRoot "bin"
if (-not (Test-Path (Join-Path $bin "flutter.bat"))) {
  Write-Error "SDK Flutter introuvable. Definissez FLUTTER_ROOT ou editez ce script."
  return
}
$env:FLUTTER_ROOT = $flutterRoot
if ($env:Path -notlike "*$($bin.Replace('\','\\'))*") {
  $env:Path = "$bin;$env:Path"
}
Write-Host "Session: flutter = $bin\flutter.bat" -ForegroundColor Green
