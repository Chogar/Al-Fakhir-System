# Enregistre l'imprimante ticket et le tiroir-caisse RJ11 (GF-405) pour Al-Fakhir.
param(
  [string]$PrinterName = "XP-58C",
  [string]$DrawerModel = "GF-405",
  [ValidateRange(0, 1)]
  [int]$DrawerPin = 0
)

$installDir = Join-Path $env:LOCALAPPDATA "Programs\Al-Fakhir"
if (-not (Test-Path $installDir)) {
  New-Item -ItemType Directory -Force -Path $installDir | Out-Null
}
$configFile = Join-Path $installDir "receipt_printer.txt"
@(
  $PrinterName.Trim()
  "drawer_model=$DrawerModel"
  "drawer_pin=$DrawerPin"
) | Set-Content -Path $configFile -Encoding UTF8

Write-Host "Imprimante ticket : $PrinterName" -ForegroundColor Green
Write-Host "Tiroir RJ11      : $DrawerModel (broche $DrawerPin)" -ForegroundColor Green
Write-Host "Fichier          : $configFile" -ForegroundColor DarkGray
Get-Printer -Name $PrinterName -ErrorAction SilentlyContinue | Format-List Name, DriverName, PortName, PrinterStatus
