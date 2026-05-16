$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent $MyInvocation.MyCommand.Path
$Backend = Join-Path $Root "backend"
Set-Location $Backend

function Resolve-NodeDir {
  foreach ($p in @(
      "C:\Program Files\nodejs",
      "C:\Program Files (x86)\nodejs"
    )) {
    if (Test-Path (Join-Path $p "node.exe")) { return $p }
  }
  $node = Get-Command node.exe -ErrorAction SilentlyContinue
  if ($node) { return Split-Path -Parent $node.Source }
  if ($env:NVM_HOME) {
    $nvmNode = Join-Path $env:NVM_HOME "node.exe"
    if (Test-Path $nvmNode) { return Split-Path -Parent $nvmNode }
  }
  return $null
}

function Resolve-NpmCmd {
  $nodeDir = Resolve-NodeDir
  if ($nodeDir) {
    $fromNode = Join-Path $nodeDir "npm.cmd"
    if (Test-Path $fromNode) { return $fromNode }
  }
  $cmd = Get-Command npm.cmd -ErrorAction SilentlyContinue
  if ($cmd) { return $cmd.Source }
  foreach ($p in @(
      "C:\Program Files\nodejs\npm.cmd",
      "C:\Program Files (x86)\nodejs\npm.cmd",
      (Join-Path $env:APPDATA "npm\npm.cmd")
    )) {
    if (Test-Path $p) { return $p }
  }
  return $null
}

$nodeDir = Resolve-NodeDir
if (-not $nodeDir) {
  Write-Host ""
  Write-Host "Node.js introuvable. Installez Node.js LTS :" -ForegroundColor Yellow
  Write-Host "  https://nodejs.org/  ou  winget install OpenJS.NodeJS.LTS" -ForegroundColor Yellow
  Write-Host "Puis fermez et rouvrez le terminal." -ForegroundColor Yellow
  Write-Host ""
  exit 1
}

if (($env:Path -split ';' | Where-Object { $_ -eq $nodeDir }).Count -eq 0) {
  $env:Path = "$nodeDir;$env:Path"
}

$nodeExe = Join-Path $nodeDir "node.exe"
$npm = Resolve-NpmCmd
if (-not $npm) {
  Write-Host "npm introuvable dans $nodeDir" -ForegroundColor Yellow
  exit 1
}

if (-not (Test-Path (Join-Path $Backend "dist\main.js"))) {
  Write-Error "backend\dist\main.js introuvable."
}

if (-not (Test-Path (Join-Path $Backend "node_modules\@nestjs\common"))) {
  Write-Host "Installation des dependances npm (backend)..." -ForegroundColor Cyan
  & $npm install --omit=dev
  if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
}

if (-not (Test-Path (Join-Path $Backend ".env"))) {
  if (Test-Path (Join-Path $Backend ".env.example")) {
    Copy-Item (Join-Path $Backend ".env.example") (Join-Path $Backend ".env")
    Write-Host "Fichier .env cree depuis .env.example (PostgreSQL + seed admin)." -ForegroundColor Yellow
  } else {
    Write-Error "Creez backend\.env (voir .env.example)."
  }
}

$pgPort = 5432
if (Test-Path (Join-Path $Backend ".env")) {
  foreach ($line in Get-Content (Join-Path $Backend ".env")) {
    if ($line -match '^\s*DATABASE_PORT\s*=\s*(\d+)') { $pgPort = [int]$Matches[1]; break }
  }
}
$pgOk = $false
try {
  $tcp = Test-NetConnection -ComputerName localhost -Port $pgPort -WarningAction SilentlyContinue -ErrorAction Stop
  $pgOk = $tcp.TcpTestSucceeded
} catch { $pgOk = $false }
if (-not $pgOk) {
  Write-Host ""
  Write-Host "PostgreSQL ne repond pas sur localhost:$pgPort (ECONNREFUSED)." -ForegroundColor Yellow
  Write-Host "1. winget install PostgreSQL.PostgreSQL.17  (mot de passe superuser conseille : postgres)" -ForegroundColor Yellow
  Write-Host "2. powershell -ExecutionPolicy Bypass -File .\setup_postgres.ps1" -ForegroundColor Yellow
  Write-Host "3. Verifiez backend\.env (DATABASE_PASSWORD = mot de passe choisi a l'install)" -ForegroundColor Yellow
  Write-Host ""
  exit 3
}

Write-Host "Demarrage API http://127.0.0.1:3000/api ..." -ForegroundColor Green
Write-Host "Node: $nodeExe" -ForegroundColor DarkGray
& $nodeExe dist/main.js
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
