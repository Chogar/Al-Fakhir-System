# Enregistre le nom exact de l'imprimante ticket pour Al-Fakhir.
param(
  [string]$PrinterName = "Printer usb printer port"
)

$installDir = Join-Path $env:LOCALAPPDATA "Programs\Al-Fakhir"
if (-not (Test-Path $installDir)) {
  New-Item -ItemType Directory -Force -Path $installDir | Out-Null
}
$configFile = Join-Path $installDir "receipt_printer.txt"
Set-Content -Path $configFile -Value $PrinterName.Trim() -Encoding UTF8
Write-Host "Imprimante ticket enregistree : $PrinterName" -ForegroundColor Green
Write-Host "Fichier : $configFile" -ForegroundColor DarkGray
Get-Printer -Name $PrinterName -ErrorAction SilentlyContinue | Format-List Name, DriverName, PortName, PrinterStatus
