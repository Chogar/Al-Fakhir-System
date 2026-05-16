$InstallRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$Backend = Join-Path $InstallRoot "backend"
$LogDir = Join-Path $InstallRoot "logs"
New-Item -ItemType Directory -Force -Path $LogDir | Out-Null
$LogFile = Join-Path $LogDir ("backend-" + (Get-Date -Format "yyyyMMdd") + ".log")

function Write-Log([string]$Message) {
  $line = "[{0}] {1}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"), $Message
  Add-Content -Path $LogFile -Value $line -Encoding UTF8
}

function Resolve-NodeExe {
  foreach ($p in @(
      "C:\Program Files\nodejs\node.exe",
      "C:\Program Files (x86)\nodejs\node.exe"
    )) {
    if (Test-Path $p) { return $p }
  }
  $node = Get-Command node.exe -ErrorAction SilentlyContinue
  if ($node) { return $node.Source }
  return $null
}

$nodeExe = Resolve-NodeExe
if (-not $nodeExe) {
  Write-Log "ERREUR: Node.js introuvable. Installez Node.js LTS : https://nodejs.org/"
  exit 1
}

if (-not (Test-Path (Join-Path $Backend "dist\main.js"))) {
  Write-Log "ERREUR: dist\main.js introuvable dans $Backend"
  exit 1
}

# Arreter l'ancienne API (sinon Node garde l'ancien code en memoire).
$port = 3000
try {
  $listeners = Get-NetTCPConnection -LocalPort $port -State Listen -ErrorAction SilentlyContinue
  foreach ($c in $listeners) {
    $oldPid = $c.OwningProcess
    if ($oldPid -and $oldPid -gt 0) {
      Write-Log "Arret processus API existant PID=$oldPid (port $port)"
      Stop-Process -Id $oldPid -Force -ErrorAction SilentlyContinue
    }
  }
  Start-Sleep -Seconds 1
} catch {
  Write-Log "Note: impossible de verifier le port $port : $_"
}

Write-Log "Demarrage API (node: $nodeExe, cwd: $Backend)"
$runLog = Join-Path $LogDir ("backend-run-" + (Get-Date -Format "yyyyMMdd") + ".log")
$cmd = "cd /d `"$Backend`" && `"$nodeExe`" dist\main.js >> `"$runLog`" 2>&1"
Start-Process -FilePath "cmd.exe" -ArgumentList "/c", $cmd -WindowStyle Hidden
exit 0
