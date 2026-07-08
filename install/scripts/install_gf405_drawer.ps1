# Installation / configuration tiroir-caisse GF-405 (RJ11 sur imprimante XP-58C).
# Pas de pilote Windows separe : le tiroir s'ouvre via impulsions ESC/POS envoyees a l'imprimante.
param(
  [string]$PrinterName = "XP-58C",
  [string]$DrawerModel = "GF-405",
  [switch]$SkipTest
)

$ErrorActionPreference = "Stop"

function Write-Step($msg) { Write-Host "`n==> $msg" -ForegroundColor Cyan }
function Write-Ok($msg)   { Write-Host "    $msg" -ForegroundColor Green }
function Write-Warn($msg) { Write-Host "    $msg" -ForegroundColor Yellow }

$scriptDir = $PSScriptRoot
$installDir = Join-Path $env:LOCALAPPDATA "Programs\Al-Fakhir"
$scriptsDst = Join-Path $installDir "scripts"

Write-Host "=== Installation tiroir GF-405 (via $PrinterName) ===" -ForegroundColor White

# --- 1. Imprimante ticket ---
Write-Step "Verification imprimante $PrinterName"
$printer = Get-Printer -Name $PrinterName -ErrorAction SilentlyContinue
if (-not $printer) {
  $printer = Get-Printer | Where-Object {
    $_.Name -like '*58*' -or $_.Name -like '*XP*'
  } | Select-Object -First 1
}
if (-not $printer) {
  Write-Host "ERREUR : aucune imprimante XP-58 detectee. Branchez l'imprimante USB puis relancez." -ForegroundColor Red
  Get-Printer | Format-Table Name, DriverName, PortName, PrinterStatus
  exit 1
}
$PrinterName = $printer.Name
Write-Ok "Imprimante : $PrinterName (port $($printer.PortName), pilote $($printer.DriverName))"

# --- 2. Optimisation Windows (file RAW, sans bi-directionnel) ---
Write-Step "Optimisation pilote pour le tiroir RJ11"
try {
  $regPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Print\Printers\$PrinterName"
  if (Test-Path $regPath) {
    $attrs = (Get-ItemProperty -Path $regPath -Name Attributes -ErrorAction SilentlyContinue).Attributes
    if ($null -ne $attrs -and ($attrs -band 0x800)) {
      $newAttrs = $attrs -band (-bnot 0x800)
      Set-ItemProperty -Path $regPath -Name Attributes -Value $newAttrs
      Write-Ok "Support bi-directionnel desactive (meilleur passage RAW ESC/POS)"
    } else {
      Write-Ok "Registre imprimante deja compatible"
    }
  }
} catch {
  Write-Warn "Registre non modifie (droits admin requis) : $_"
}

Get-PrintJob -PrinterName $PrinterName -ErrorAction SilentlyContinue | Remove-PrintJob -ErrorAction SilentlyContinue
$cim = Get-CimInstance Win32_Printer -Filter "Name='$($PrinterName.Replace("'","''"))'"
if ($cim) {
  $null = Invoke-CimMethod -InputObject $cim -MethodName Resume -ErrorAction SilentlyContinue
}
Write-Ok "File d'impression videe"

# --- 3. Scripts Al-Fakhir ---
Write-Step "Copie des scripts d'ouverture tiroir"
New-Item -ItemType Directory -Force -Path $scriptsDst | Out-Null
foreach ($f in @('print_raw.ps1', 'test_drawer_gf405.ps1', 'fix_xp58_printer.ps1', 'set_receipt_printer.ps1')) {
  $src = Join-Path $scriptDir $f
  if (Test-Path $src) {
    Copy-Item $src (Join-Path $scriptsDst $f) -Force
    Write-Ok $f
  }
}

# --- 4. Configuration Al-Fakhir ---
Write-Step "Configuration GF-405"
$configFile = Join-Path $installDir "receipt_printer.txt"
@(
  $PrinterName
  "drawer_model=$DrawerModel"
  "drawer_pin=0"
  "drawer_both_pins=1"
  "drawer_on_ms=150"
  "drawer_off_ms=600"
) | Set-Content -Path $configFile -Encoding UTF8
Write-Ok "Fichier : $configFile"

$srcInstall = Join-Path (Split-Path $scriptDir -Parent) "receipt_printer.txt"
if (Test-Path (Split-Path $srcInstall -Parent)) {
  @(
    $PrinterName
    "drawer_model=$DrawerModel"
    "drawer_pin=0"
    "drawer_both_pins=1"
    "drawer_on_ms=150"
    "drawer_off_ms=600"
  ) | Set-Content -Path $srcInstall -Encoding UTF8
}

# --- 5. Raccourci test tiroir (Bureau) ---
Write-Step "Raccourci test tiroir sur le Bureau"
$desktop = [Environment]::GetFolderPath('Desktop')
$shortcutPath = Join-Path $desktop 'Tester tiroir GF-405.lnk'
$wsh = New-Object -ComObject WScript.Shell
$sc = $wsh.CreateShortcut($shortcutPath)
$sc.TargetPath = "powershell.exe"
$sc.Arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$(Join-Path $scriptsDst 'test_drawer_gf405.ps1')`" -PrinterName `"$PrinterName`" -BothPins"
$sc.WorkingDirectory = $scriptsDst
$sc.Description = "Ouvre le tiroir-caisse GF-405 via $PrinterName"
$sc.Save()
Write-Ok $shortcutPath

# --- 6. Tests ---
if (-not $SkipTest) {
  Write-Step 'Test ouverture tiroir (3 essais)'
  $testScript = Join-Path $scriptsDst "test_drawer_gf405.ps1"
  $ok = 0
  for ($i = 1; $i -le 3; $i++) {
    Write-Host "  Essai $i/3..." -ForegroundColor DarkGray
    try {
      & $testScript -PrinterName $PrinterName -BothPins
      $ok++
      Start-Sleep -Seconds 2
    } catch {
      Write-Warn "Essai $i echoue : $_"
    }
  }
  if ($ok -ge 2) {
    Write-Ok "$ok/3 ouvertures reussies - installation OK"
  } else {
    Write-Warn 'Peu douvertures. Verifiez cable RJ11 et alimentation 12V du tiroir.'
  }
}

Write-Host "`n=== Termine ===" -ForegroundColor Green
Write-Host "IMPORTANT :" -ForegroundColor White
Write-Host "  - Le GF-405 n a pas de pilote USB Windows (RJ11 sur imprimante)." -ForegroundColor White
Write-Host "  - L imprimante $PrinterName pilote le tiroir via ESC/POS." -ForegroundColor White
Write-Host "  - Cable RJ11 : tiroir -> prise DK de l imprimante XP-58C." -ForegroundColor White
Write-Host "  - Alimentation 12V obligatoire sur le tiroir." -ForegroundColor White
Write-Host "Relancez Al-Fakhir. Test : raccourci Bureau Tester tiroir GF-405." -ForegroundColor Yellow
