# Ouvre le tiroir GF-405 (RJ11) — job RAW init + double impulsion (XP-58C).
param(
  [string]$PrinterName = "XP-58C",
  [int]$Pin = 0,
  [switch]$BothPins
)

$ErrorActionPreference = "Stop"
$rawScript = Join-Path $PSScriptRoot "print_raw.ps1"
if (-not (Test-Path $rawScript)) {
  Write-Error "Script introuvable : $rawScript"
}

function New-DrawerKick {
  param([int]$M, [int]$OnMs = 150, [int]$OffMs = 600)
  $t1 = [Math]::Max(1, [Math]::Min(255, [int]($OnMs / 2)))
  $t2 = [Math]::Max(1, [Math]::Min(255, [int]($OffMs / 2)))
  return [byte[]](0x1B, 0x70, $M, $t1, $t2)
}

$list = New-Object System.Collections.Generic.List[byte]
# ESC @ init imprimante
0x1B, 0x40 | ForEach-Object { $list.Add($_) | Out-Null }

if ($BothPins) {
  foreach ($b in (New-DrawerKick -M 0)) { $list.Add($b) | Out-Null }
  foreach ($b in (New-DrawerKick -M 0)) { $list.Add($b) | Out-Null }
  foreach ($b in (New-DrawerKick -M 1)) { $list.Add($b) | Out-Null }
  foreach ($b in (New-DrawerKick -M 1)) { $list.Add($b) | Out-Null }
} else {
  foreach ($b in (New-DrawerKick -M $Pin)) { $list.Add($b) | Out-Null }
  foreach ($b in (New-DrawerKick -M $Pin)) { $list.Add($b) | Out-Null }
}
$bytes = $list.ToArray()

$tmp = [System.IO.Path]::Combine($env:TEMP, "gf405_drawer_kick.bin")
[System.IO.File]::WriteAllBytes($tmp, $bytes)

Write-Host "Imprimante : $PrinterName" -ForegroundColor Cyan
Write-Host "Impulsion   : $($bytes.Length) octets" -ForegroundColor DarkGray
function Wait-PrinterIdle {
  param([string]$Name, [int]$MaxSec = 15)
  $deadline = (Get-Date).AddSeconds($MaxSec)
  do {
    $jobs = @(Get-PrintJob -PrinterName $Name -ErrorAction SilentlyContinue)
    if ($jobs.Count -eq 0) { return }
    Start-Sleep -Milliseconds 200
  } while ((Get-Date) -lt $deadline)
}

& $rawScript -PrinterName $PrinterName -FilePath $tmp
Wait-PrinterIdle -Name $PrinterName
Start-Sleep -Milliseconds 500
& $rawScript -PrinterName $PrinterName -FilePath $tmp
Wait-PrinterIdle -Name $PrinterName
Write-Host "OK - tiroir GF-405" -ForegroundColor Green
