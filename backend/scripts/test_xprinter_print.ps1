# Test ESC/POS sur Xprinter XP-58 / XP-58IIT / XP-58C (Windows, mode RAW).
param(
  [string]$PrinterName = "XP-58C",
  [string]$Line1 = "Restaurant Al-Fakhir",
  [string]$Line2 = "Commande #123 - 2 Pizzas",
  [string]$Line3 = "Merci - bon appetit !"
)

$ErrorActionPreference = "Stop"

if (-not (Get-Printer -Name $PrinterName -ErrorAction SilentlyContinue)) {
  Write-Host "Imprimante '$PrinterName' introuvable. Imprimantes :" -ForegroundColor Red
  Get-Printer | Format-Table Name, DriverName, PortName
  exit 1
}

function New-EscPosBytes {
  param([string[]]$Lines)
  $ms = New-Object System.IO.MemoryStream
  $w = $ms.WriteByte
  # ESC @ init
  0x1B, 0x40 | ForEach-Object { $ms.WriteByte($_) | Out-Null }
  # ESC t 16 = Windows-1252
  0x1B, 0x74, 0x10 | ForEach-Object { $ms.WriteByte($_) | Out-Null }
  $enc = [System.Text.Encoding]::GetEncoding(1252)
  foreach ($line in $Lines) {
    $bytes = $enc.GetBytes($line)
    $ms.Write($bytes, 0, $bytes.Length) | Out-Null
    0x0D, 0x0A | ForEach-Object { $ms.WriteByte($_) | Out-Null }
  }
  0x1B, 0x64, 0x04 | ForEach-Object { $ms.WriteByte($_) | Out-Null }
  0x1D, 0x56, 0x00 | ForEach-Object { $ms.WriteByte($_) | Out-Null }
  return $ms.ToArray()
}

$bytes = New-EscPosBytes -Lines @($Line1, $Line2, $Line3)
$tmp = [System.IO.Path]::Combine($env:TEMP, "xprinter_test.bin")
[System.IO.File]::WriteAllBytes($tmp, $bytes)

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$rawScript = Join-Path (Split-Path $scriptDir -Parent) "..\install\scripts\print_raw.ps1"
if (-not (Test-Path $rawScript)) {
  $rawScript = Join-Path $env:LOCALAPPDATA "Programs\Al-Fakhir\scripts\print_raw.ps1"
}

Write-Host "Imprimante : $PrinterName" -ForegroundColor Cyan
Write-Host "Donnees    : $($bytes.Length) octets -> $tmp" -ForegroundColor DarkGray
& $rawScript -PrinterName $PrinterName -FilePath $tmp
Write-Host "OK — verifiez le ticket (texte visible)." -ForegroundColor Green
