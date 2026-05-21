$ErrorActionPreference = "Stop"
$InstallRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$AppExe = Join-Path $InstallRoot "app\alfakhir_desktop.exe"
$BackendScript = Join-Path $InstallRoot "start-backend.ps1"
$LogDir = Join-Path $InstallRoot "logs"
$LogFile = Join-Path $LogDir ("backend-" + (Get-Date -Format "yyyyMMdd") + ".log")
$HealthUrl = "http://127.0.0.1:3000/api/health"

function Test-ApiHealth {
  try {
    $r = Invoke-WebRequest -Uri $HealthUrl -UseBasicParsing -TimeoutSec 3
    return $r.StatusCode -eq 200
  } catch { return $false }
}

function Test-PostgresPort([int]$Port = 5432) {
  try {
    $tcp = Test-NetConnection -ComputerName localhost -Port $Port -WarningAction SilentlyContinue -ErrorAction Stop
    return $tcp.TcpTestSucceeded
  } catch { return $false }
}

function Ensure-PostgresService {
  foreach ($name in @("postgresql-x64-17", "postgresql-x64-16", "postgresql-x64-15")) {
    $svc = Get-Service -Name $name -ErrorAction SilentlyContinue
    if (-not $svc) { continue }
    if ($svc.Status -ne "Running") {
      Write-Host "Demarrage PostgreSQL ($name)..." -ForegroundColor Cyan
      Start-Service -Name $name -ErrorAction SilentlyContinue
      Start-Sleep -Seconds 3
    }
    return
  }
}

function Show-BackendLogTail {
  if (-not (Test-Path $LogFile)) { return }
  Write-Host ""
  Write-Host "Dernieres lignes du journal ($LogFile) :" -ForegroundColor DarkGray
  Get-Content $LogFile -Tail 12 -ErrorAction SilentlyContinue | ForEach-Object { Write-Host "  $_" }
}

function Test-NodeInstalled {
  foreach ($p in @(
      "C:\Program Files\nodejs\node.exe",
      "C:\Program Files (x86)\nodejs\node.exe"
    )) {
    if (Test-Path $p) { return $true }
  }
  return $null -ne (Get-Command node.exe -ErrorAction SilentlyContinue)
}

if (-not (Test-NodeInstalled)) {
  Write-Host ""
  Write-Host "Node.js est requis pour le serveur local." -ForegroundColor Red
  Write-Host "  winget install OpenJS.NodeJS.LTS" -ForegroundColor Yellow
  Write-Host "  Puis redemarrez le PC et relancez Al-Fakhir." -ForegroundColor Yellow
  Read-Host "Appuyez sur Entree pour fermer"
  exit 1
}

Ensure-PostgresService

if (-not (Test-PostgresPort)) {
  Write-Host ""
  Write-Host "PostgreSQL ne repond pas sur le port 5432." -ForegroundColor Red
  Write-Host "  winget install PostgreSQL.PostgreSQL.17" -ForegroundColor Yellow
  Write-Host "  Depuis le projet : powershell -ExecutionPolicy Bypass -File setup_postgres.ps1" -ForegroundColor Yellow
  Write-Host "  Verifiez le mot de passe dans : $InstallRoot\backend\.env" -ForegroundColor Yellow
  Read-Host "Appuyez sur Entree pour fermer"
  exit 1
}

if (-not (Test-ApiHealth)) {
  Write-Host "Demarrage du serveur local (patientez 10-30 s)..." -ForegroundColor Cyan
  New-Item -ItemType Directory -Force -Path $LogDir | Out-Null
  Start-Process powershell -WindowStyle Hidden -WorkingDirectory $InstallRoot -ArgumentList @(
    "-NoProfile", "-ExecutionPolicy", "Bypass",
    "-File", $BackendScript
  ) | Out-Null
  $deadline = (Get-Date).AddSeconds(90)
  $dots = 0
  while ((Get-Date) -lt $deadline) {
    if (Test-ApiHealth) { break }
    $dots = ($dots + 1) % 4
    Write-Host "`r  En cours$('.' * $dots)   " -NoNewline -ForegroundColor DarkGray
    Start-Sleep -Milliseconds 750
  }
  Write-Host ""
  if (-not (Test-ApiHealth)) {
    Write-Host ""
    Write-Host "L'API ne repond pas sur http://127.0.0.1:3000/api" -ForegroundColor Red
    Write-Host "  1. Verifiez backend\.env (DATABASE_PASSWORD = mot de passe PostgreSQL)" -ForegroundColor Yellow
    Write-Host "  2. Journal : $LogFile" -ForegroundColor Yellow
    Show-BackendLogTail
    Read-Host "Appuyez sur Entree pour fermer"
    exit 1
  }
  Write-Host "Serveur local pret." -ForegroundColor Green
}

Start-Process -FilePath $AppExe -WorkingDirectory (Split-Path $AppExe)
