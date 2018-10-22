;
; SciTE4AutoHotkey New User Profile Script
;

#NoEnv
#NoTrayIcon
#SingleInstance Ignore
SendMode Input
SetWorkingDir, %A_ScriptDir%

; Notification of first time run
Progress, m2 b zh0, Preparing SciTE4AutoHotkey to run for the first time...

; Create directories
FileCreateDir, %A_MyDocuments%\AutoHotkey
FileCreateDir, %A_MyDocuments%\AutoHotkey\Lib
; If already exist, backup SciTE directory
IfExist, %A_MyDocuments%\AutoHotkey\SciTE
{
	; use tickcount for backup name
    FileMoveDir, %A_MyDocuments%\AutoHotkey\SciTE, %A_MyDocuments%\AutoHotkey\SciTE%A_TickCount%, R
    ; If error, exit script
    if ErrorLevel
        ExitApp
}

; Copy the current newuser directory to the local location
FileCopyDir, %A_ScriptDir%\..\newuser, %A_MyDocuments%\AutoHotkey\SciTE

; Mainly to avoid an annoying flashing window:
Sleep, 1000
