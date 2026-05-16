' Lance Al-Fakhir sans fenetre console : demarre l'API si besoin, puis l'application.
Option Explicit

Dim fso, sh, installRoot, appExe, startScript, healthUrl
Dim deadline, apiOk, http

Set fso = CreateObject("Scripting.FileSystemObject")
Set sh = CreateObject("WScript.Shell")
installRoot = fso.GetParentFolderName(WScript.ScriptFullName)
appExe = installRoot & "\app\alfakhir_desktop.exe"
startScript = installRoot & "\start-backend.ps1"
healthUrl = "http://127.0.0.1:3000/api/health"

If Not fso.FileExists(appExe) Then
  MsgBox "Application introuvable." & vbCrLf & appExe, vbCritical, "Al-Fakhir"
  WScript.Quit 1
End If

apiOk = ApiHealthOk(healthUrl)
If Not apiOk Then
  sh.Run "powershell.exe -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File """ & startScript & """", 0, False
  deadline = DateAdd("s", 90, Now)
  Do While Now < deadline
    WScript.Sleep 750
    If ApiHealthOk(healthUrl) Then
      apiOk = True
      Exit Do
    End If
  Loop
End If

If Not apiOk Then
  MsgBox "Le serveur local ne repond pas." & vbCrLf & vbCrLf & _
    "Verifiez que PostgreSQL est demarre et le fichier backend\.env." & vbCrLf & _
    "Journal : " & installRoot & "\logs\", vbExclamation, "Al-Fakhir"
  WScript.Quit 1
End If

sh.CurrentDirectory = fso.GetParentFolderName(appExe)
sh.Run """" & appExe & """", 1, False

Function ApiHealthOk(url)
  On Error Resume Next
  ApiHealthOk = False
  Set http = CreateObject("MSXML2.ServerXMLHTTP.6.0")
  If http Is Nothing Then Set http = CreateObject("MSXML2.XMLHTTP")
  If http Is Nothing Then Exit Function
  http.Open "GET", url, False
  http.setTimeouts 2000, 2000, 2000, 2000
  http.Send
  If Err.Number = 0 Then ApiHealthOk = (http.Status = 200)
  Set http = Nothing
  On Error GoTo 0
End Function
