$ErrorActionPreference = "Stop"
$InstallRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$Backend = Join-Path $InstallRoot "backend"
$LogDir = Join-Path $InstallRoot "logs"
New-Item -ItemType Directory -Force -Path $LogDir | Out-Null
$LogFile = Join-Path $LogDir ("backend-run-" + (Get-Date -Format "yyyyMMdd") + ".log")
$LogFileErr = Join-Path $LogDir ("backend-run-err-" + (Get-Date -Format "yyyyMMdd") + ".log")
$DailyLog = Join-Path $LogDir ("backend-" + (Get-Date -Format "yyyyMMdd") + ".log")

function Write-Log([string]$Message) {
  $line = "[{0}] {1}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"), $Message
  Add-Content -Path $DailyLog -Value $line -Encoding UTF8
}

function Resolve-NodeExe {
  foreach ($p in @(
      "C:\Program Files\nodejs\node.exe",
      "C:\Program Files (x86)\nodejs\node.exe"
    )) {
    if (Test-Path $p) { return $p }
  }
  $node = Get-Command node.exe -ErrorAction SilentlyContinue
  if ($node -and $node.Source -notmatch 'cursor|Cursor') {
    return $node.Source
  }
  return $null
}

$nodeExe = Resolve-NodeExe
if (-not $nodeExe) {
  Write-Log "ERREUR: Node.js introuvable (installez Node.js LTS)."
  exit 1
}

if (-not (Test-Path (Join-Path $Backend "dist\main.js"))) {
  Write-Log "ERREUR: dist\main.js introuvable dans $Backend"
  exit 1
}

# Arreter une ancienne instance API sur le port 3000 (si bloquee).
try {
  $conn = Get-NetTCPConnection -LocalPort 3000 -State Listen -ErrorAction SilentlyContinue |
    Select-Object -First 1
  if ($conn -and $conn.OwningProcess -gt 0) {
    Stop-Process -Id $conn.OwningProcess -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 1
    Write-Log "Ancienne instance API arretee (PID $($conn.OwningProcess))."
  }
} catch {
  # ignore
}

Write-Log "Demarrage API (node: $nodeExe)"
"[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] --- demarrage node dist/main.js ---" | Out-File -FilePath $LogFile -Encoding UTF8

Start-Process -FilePath $nodeExe `
  -ArgumentList "dist/main.js" `
  -WorkingDirectory $Backend `
  -WindowStyle Hidden `
  -RedirectStandardOutput $LogFile `
  -RedirectStandardError $LogFileErr

exit 0
