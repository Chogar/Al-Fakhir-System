' Demarre l'API Al-Fakhir au demarrage de Windows (sans fenetre).
Option Explicit

Dim fso, sh, installRoot, startScript, healthUrl

Set fso = CreateObject("Scripting.FileSystemObject")
Set sh = CreateObject("WScript.Shell")
installRoot = fso.GetParentFolderName(WScript.ScriptFullName)
startScript = installRoot & "\start-backend.ps1"
healthUrl = "http://127.0.0.1:3000/api/health"

If ApiHealthOk(healthUrl) Then WScript.Quit 0

sh.Run "powershell.exe -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File """ & startScript & """", 0, False

Function ApiHealthOk(url)
  On Error Resume Next
  ApiHealthOk = False
  Dim http
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
