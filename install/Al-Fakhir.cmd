@echo off
setlocal
set "ROOT=%~dp0"
set "APP=%ROOT%app\alfakhir_desktop.exe"
set "START_API=%ROOT%start-backend.ps1"

if not exist "%APP%" (
  echo Application introuvable : %APP%
  pause
  exit /b 1
)

REM Demarrer l'API en arriere-plan si le script est present.
if exist "%START_API%" (
  start "" /B powershell.exe -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File "%START_API%"
)

cd /d "%ROOT%app"
start "" "%APP%"
exit /b 0
