# Lanceur technique (console) — le raccourci Bureau utilise Al-Fakhir.vbs (sans fenetre noire).
$ErrorActionPreference = "Stop"
$InstallRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$Vbs = Join-Path $InstallRoot "Al-Fakhir.vbs"
if (-not (Test-Path $Vbs)) {
  Write-Error "Introuvable : $Vbs"
}
Start-Process wscript.exe -ArgumentList @("//B", "//Nologo", $Vbs) -WindowStyle Hidden
