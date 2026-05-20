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

Write-Log "Demarrage API (node: $nodeExe, cwd: $Backend)"
Start-Process -FilePath $nodeExe -ArgumentList "dist/main.js" -WorkingDirectory $Backend -WindowStyle Hidden
exit 0
