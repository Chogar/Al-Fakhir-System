# Debloque l'imprimante ticket XP-58 : vide la file d'attente et reprend l'impression.
param([string]$PrinterName = "XP-58")

$ErrorActionPreference = "SilentlyContinue"

$printer = Get-Printer -Name $PrinterName
if (-not $printer) {
  $printer = Get-Printer | Where-Object { $_.Name -like "*58*" -or $_.Name -like "*XP*" } | Select-Object -First 1
}
if (-not $printer) {
  Write-Host "Imprimante XP-58 introuvable." -ForegroundColor Red
  Get-Printer | Format-Table Name, PrinterStatus, JobCount
  exit 1
}

$name = $printer.Name
Write-Host "Imprimante : $name (etat: $($printer.PrinterStatus), jobs: $($printer.JobCount))" -ForegroundColor Cyan

Get-PrintJob -PrinterName $name | Remove-PrintJob
$cim = Get-CimInstance -ClassName Win32_Printer -Filter "Name='$($name.Replace("'","''"))'"
if ($cim) {
  $null = Invoke-CimMethod -InputObject $cim -MethodName Resume
  $null = Invoke-CimMethod -InputObject $cim -MethodName SetPrinterAttributes -Arguments @{ Attributes = 0 }
}

Start-Sleep -Seconds 1
$p = Get-Printer -Name $name
Write-Host "Apres correction : $($p.PrinterStatus), jobs: $($p.JobCount)" -ForegroundColor Green
Write-Host "Relancez l'impression depuis Al-Fakhir." -ForegroundColor Yellow
