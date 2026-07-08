' Lanceur Al-Fakhir : demarre l'API si besoin, puis l'app graphique.
' Gere les processus zombies (presents sans fenetre) : relance propre.
Option Explicit

Dim fso, sh, installRoot, appExe, startScript, healthUrl, rc

Set fso = CreateObject("Scripting.FileSystemObject")
Set sh = CreateObject("WScript.Shell")
installRoot = fso.GetParentFolderName(WScript.ScriptFullName)
appExe = installRoot & "\app\alfakhir_desktop.exe"
startScript = installRoot & "\start-backend.ps1"
healthUrl = "http://127.0.0.1:3000/api/health"

If Not fso.FileExists(appExe) Then
  MsgBox "Application introuvable :" & vbCrLf & appExe, vbCritical, "Al-Fakhir"
  WScript.Quit 1
End If

If AppProcessCount() > 0 Then
  If ActivateExisting() Then
    WScript.Quit 0
  End If
  KillAppProcesses
  WScript.Sleep 800
End If

If Not ApiHealthOk(healthUrl) And fso.FileExists(startScript) Then
  sh.Run "powershell.exe -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File """ & startScript & """", 0, False
End If

' Lancer via cmd start pour fiabiliser le demarrage depuis wscript //B.
rc = sh.Run( _
  "cmd.exe /c start """" /D """ & fso.GetParentFolderName(appExe) & """ """ & appExe & """", _
  0, _
  False _
)
If rc <> 0 Then
  MsgBox "Echec du demarrage (code " & rc & ").", vbExclamation, "Al-Fakhir"
  WScript.Quit 1
End If

Function AppProcessCount()
  Dim wmi, items
  AppProcessCount = 0
  On Error Resume Next
  Set wmi = GetObject("winmgmts:\\.\root\cimv2")
  If wmi Is Nothing Then Exit Function
  Set items = wmi.ExecQuery("SELECT ProcessId FROM Win32_Process WHERE Name='alfakhir_desktop.exe'")
  If Not (items Is Nothing) Then AppProcessCount = items.Count
  On Error GoTo 0
End Function

Function ActivateExisting()
  Dim titles, i, ok
  ActivateExisting = False
  titles = Array("Restaurant Al-Fakhir", "alfakhir_desktop", "Al-Fakhir")
  On Error Resume Next
  For i = 0 To UBound(titles)
    ok = sh.AppActivate(titles(i))
    If ok = True Or ok = 1 Then
      ActivateExisting = True
      Exit Function
    End If
  Next
  On Error GoTo 0
End Function

Sub KillAppProcesses()
  Dim wmi, items, proc
  On Error Resume Next
  Set wmi = GetObject("winmgmts:\\.\root\cimv2")
  If wmi Is Nothing Then Exit Sub
  Set items = wmi.ExecQuery("SELECT ProcessId FROM Win32_Process WHERE Name='alfakhir_desktop.exe'")
  If items Is Nothing Then Exit Sub
  For Each proc In items
    proc.Terminate
  Next
  On Error GoTo 0
End Sub

Function ApiHealthOk(url)
  Dim http
  On Error Resume Next
  ApiHealthOk = False
  Set http = CreateObject("MSXML2.ServerXMLHTTP.6.0")
  If http Is Nothing Then Set http = CreateObject("MSXML2.XMLHTTP")
  If http Is Nothing Then Exit Function
  http.Open "GET", url, False
  http.setTimeouts 800, 800, 1500, 1500
  http.Send
  If Err.Number = 0 Then ApiHealthOk = (http.Status = 200)
  Set http = Nothing
  On Error GoTo 0
End Function
