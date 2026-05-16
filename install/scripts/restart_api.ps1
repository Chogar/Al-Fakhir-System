# Redemarre l'API Al-Fakhir (obligatoire apres mise a jour du backend).
$ErrorActionPreference = "Stop"
$InstallDir = Join-Path $env:LOCALAPPDATA "Programs\Al-Fakhir"
$start = Join-Path $InstallDir "start-backend.ps1"
if (-not (Test-Path $start)) {
  Write-Host "Introuvable : $start" -ForegroundColor Red
  exit 1
}
& $start

$healthUrl = "http://127.0.0.1:3000/api/health"
$ok = $false
for ($i = 1; $i -le 20; $i++) {
  Start-Sleep -Seconds 1
  try {
    $h = Invoke-RestMethod -Uri $healthUrl -TimeoutSec 4
    Write-Host "API OK : $($h.status) (apres ${i}s)" -ForegroundColor Green
    $ok = $true
    break
  } catch {
    if ($i -eq 5) {
      Write-Host "Demarrage en cours..." -ForegroundColor DarkGray
    }
  }
}

if (-not $ok) {
  $logDir = Join-Path $InstallDir "logs"
  $today = Get-Date -Format "yyyyMMdd"
  Write-Host "API ne repond pas apres 20 s." -ForegroundColor Red
  Write-Host "Consultez les journaux : $logDir\backend-$today.log" -ForegroundColor Yellow
  $latest = Get-ChildItem $logDir -Filter "backend-*.log" -ErrorAction SilentlyContinue |
    Sort-Object LastWriteTime -Descending |
    Select-Object -First 1
  if ($latest) {
    Write-Host "--- Dernieres lignes ---" -ForegroundColor DarkGray
    Get-Content $latest.FullName -Tail 12 -ErrorAction SilentlyContinue
  }
  exit 1
}
