# Redemarre l'API Al-Fakhir (arrete l'ancien processus sur le port 3000).
$ErrorActionPreference = "Stop"
$InstallDir = Join-Path $env:LOCALAPPDATA "Programs\Al-Fakhir"
$Backend = Join-Path $InstallDir "backend"
$Port = 3000

function Stop-ApiListeners {
  foreach ($c in Get-NetTCPConnection -LocalPort $Port -State Listen -ErrorAction SilentlyContinue) {
    Stop-Process -Id $c.OwningProcess -Force -ErrorAction SilentlyContinue
  }
  foreach ($p in Get-Process -Name node -ErrorAction SilentlyContinue) {
    try {
      $cmd = (Get-CimInstance Win32_Process -Filter "ProcessId=$($p.Id)" -ErrorAction SilentlyContinue).CommandLine
      if ($cmd -and ($cmd -like "*$([regex]::Escape($Backend))*" -or $cmd -like "*dist\main.js*")) {
        Stop-Process -Id $p.Id -Force -ErrorAction SilentlyContinue
      }
    } catch {}
  }
  Start-Sleep -Seconds 1
}

Stop-ApiListeners

$start = Join-Path $InstallDir "start-backend.ps1"
if (-not (Test-Path $start)) {
  Write-Host "Introuvable : $start" -ForegroundColor Red
  exit 1
}
& powershell -NoProfile -ExecutionPolicy Bypass -File $start

$healthUrl = "http://127.0.0.1:$Port/api/health"
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
  Write-Host "Consultez : $logDir\backend-$today.log" -ForegroundColor Yellow
  exit 1
}
