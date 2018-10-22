;
; SciTE4AHK_GO Updater
;
#SingleInstance Off
#NoEnv
#NoTrayIcon
SendMode Input
SetWorkingDir, %A_ScriptDir%

; Set base URL
;baseurl = http://fincs.ahk4.net/scite4ahk
baseurl := "https://github.com/GroggyOtter/SciTE4AHK_GO"

; Check if portable version
isPortable := FileExist("..\$PORTABLE")

; Get todays date YYYYMMDD
today := A_YYYY A_MM A_DD

; If not portable, set local path to my docs
if !isPortable
    LocalSciTEPath = %A_MyDocuments%\AutoHotkey\SciTE
; If portable, set local path to SciTE's user folder
else
    LocalSciTEPath = %A_ScriptDir%\..\user

; Check if script arg is set to /silent
if 1 = /silent
    isSilent := true

; Check if script arg is set to /doupdate
if 1 = /doUpdate
{
    ; if not admin, exitapp
    if !A_IsAdmin
        ExitApp
                                        ; Set curRev to 2nd arg
                                        curRev = %2%
                                        ; Set toFetch to 3rd arg
                                        toFetch = %3%
                                        ; Force number update
                                        curRev += 0
                                        toFetch += 0
                                        ; Run the _doUpdate sub
    goto _doUpdate
}

; If script is set to /silent
if isSilent
{
    ; Read lastupdate file
    FileRead, lastUpdate, %LocalSciTEPath%\$LASTUPDATE
    ; If last update ocurred today, exitapp
    if (lastUpdate = today)
        ExitApp
}

; Make a temporary file named after tickcount in temp
f = %A_Temp%\%A_TickCount%.txt

; if script not set to silent
if !isSilent
    ; Inform user of fetching
    ToolTip, Fetching update info...
; Now try:
try
{
    ; URLDownloadToFile, %baseurl%/upd/version.txt, %f%
    ; FileRead, verOnline, %f%
    ; URLDownloadToFile, %baseurl%/upd/revision.txt, %f%
    ; FileRead, latestRev, %f%

    ; Get current posted version
    URLDownloadToFile, % "https://raw.githubusercontent.com/GroggyOtter/SciTE4AHK_GO/master/Source/%24VER", %f%
    ; Read version into var
    FileRead, verOnline, %f%
    ; Get current posted revision
;    URLDownloadToFile, % "https://raw.githubusercontent.com/GroggyOtter/SciTE4AHK_GO/master/Source/%24REVISION", %f%
    ; Read revision into var
;    FileRead, latestRev, %f%

    ; If not silent, clear tooltip
    if !isSilent
        ToolTip
; Catch errors
}catch{
    if !isSilent
    {
        ToolTip
        MsgBox, 16, SciTE4AHK_GO Updater, Can't connect to the Internet!
    }
    ExitApp
}

; Get current version from working directory
FileRead, verLocal, ..\$VER

; If online version is newer
;if (verLocal < verOnline)
if IsRunningVersionNewer(verOnline, verLocal){
    MsgBox, 67, SciTE4AHK_GO Updater, 
    (LTrim
        A new version of SciTE4AHK_GO is available!

        Current Version:`tv%verLocal%
        Available Version:`tv%verOnline%

        Automatically install updates?

        Yes`t> Download and install updates.
        No`t> Go to GitHub download page.
        Cancel`t> Don't download anything.
    )
    IfMsgBox, Yes
        DownloadAndInstall()
    IfMsgBox, No
        Run, % baseURL
    Else
        Return
    ExitApp
}

; Get current revision from working directory
FileRead, curRev, ..\$REVISION
; If blank, set to 0
if curRev =
    curRev := 0
; If current revision is greater than latest version
if (curRev >= latestRev)
{
    FileDelete, %LocalSciTEPath%\$LASTUPDATE
    FileAppend, %today%, %LocalSciTEPath%\$LASTUPDATE
    ; If not silent, inform user.
    if !isSilent
        MsgBox, 64, SciTE4AHK_GO Updater, SciTE4AHK_GO is up to date.
    ExitApp
}

; Set revisions left to fetch
toFetch := latestRev - curRev

; Inform user of revisions and ask to get them
MsgBox, 36, SciTE4AHK_GO Updater,
(
    There are %toFetch% update(s) available for SciTE4AHK_GO.

    Do you wish to download and install them?
)
; If no, exit app
IfMsgBox, No
    ExitApp
CloseSciTE()

; If not portable and not admin
if !isPortable && !A_IsAdmin
{
    ; Run script as admin with args
    Run, *RunAs "%A_AhkPath%" "%A_ScriptFullPath%" /doUpdate %curRev% %toFetch%
    ExitApp
}

_doUpdate:
    ; Create a gui notifying user of update
    Gui, Add, Text, x12 y10 w390 h20 vMainLabel, Please wait SciTE4AHK_GO updates.
    Gui, Add, ListView, x12 y30 w390 h180 NoSortHdr NoSort -LV0x10 LV0x1, #|Status|Title|Description
    Gui, Show, w411 h226, SciTE4AHK_GO Updater
    Gui, +OwnDialogs

    Loop, % toFetch
    {
        i := curRev + A_Index
        LV_Add("", i, "Queued", "<<not loaded>>", "<<not loaded>>")
    }
    LV_ModifyCol()

    Loop, % toFetch
    {
        i := curRev + A_Index
        LV_Modify(A_Index, "", i, "Downloading...", "<<not loaded>>", "<<not loaded>>")
        LV_ModifyCol()
        
        try
        {
            URLDownloadToFile, %baseurl%/upd/%i%.bin, %A_Temp%\S4AHKupd_%i%.bin
            
            upd := new Update(A_Temp "\S4AHKupd_" i ".bin", "{912B7AED-660B-4BC4-8DA3-34E394D9BBBA}")
            LV_Modify(A_Index, "", i, "Running...", upd.title, upd.descr)
            LV_ModifyCol()
            
            updfold = %A_Temp%\SciTEUpdate%A_Now%
            FileCreateDir, %updfold%
            upd.Run(updfold)
            FileRemoveDir, %updfold%, 1
            
            IfExist, ..\$REVISION
                FileDelete, ..\$REVISION
            FileAppend, %i%, ..\$REVISION
            
            LV_Modify(A_Index, "", i, "Done!", upd.title, upd.descr)
            LV_ModifyCol()
            
            upd := ""
        }catch e
        {
            GuiControl,, MainLabel, There were errors during the update.
            updDone := 1
            MsgBox, 16, SciTE4AHK_GO Updater, % "There was an error during the update!`n" e.message "`nwhat: " e.what "`nextra: " e.extra
            return
        }
    }

    FileDelete, %LocalSciTEPath%\$LASTUPDATE
    FileAppend, %today%, %LocalSciTEPath%\$LASTUPDATE

    GuiControl,, MainLabel, You may now close this window and reopen SciTE.
    updDone := 1
    MsgBox, 64, SciTE4AHK_GO Updater, SciTE4AHK_GO was successfully updated!
return

GuiClose:
if !updDone
{
    MsgBox, 48, SciTE4AHK_GO Updater, You cannot stop the updating process.
    return
}
ExitApp

/*
Format of a SciTE4AHK_GO update file:

typedef struct
{
    char magic[4]; // fUPD
    byte_t guid[16]; // program GUID
    int revision;
    int fileCount;
    int scriptFile;
    int infoOff;
} updateHeader_t;

typedef struct
{
    int dataLen;
    byte_t data[dataLen];
} updateFile_t;

typedef struct
{
    int nameLen, descrLen;
    char name[nameLen]; // UTF-8
    char descr[descrLen]; // UTF-8
} updateInfo_t;
*/


class Update
{
    __New(filename, reqGUID)
    {
        f := FileOpen(filename, "r", "UTF-8-RAW")
        if f.Read(4) != "fUPD"
            throw Exception("Invalid update file!", 0, filename)
        if ReadGUID(f) != reqGUID
            throw Exception("Invalid update file!", 0, filename)
        this.f := f
        this.revision := f.ReadUInt()
        this.fileCount := f.ReadUInt()
        this.scriptID := f.ReadUInt()
        infoPos := f.ReadUInt()
        this.filePos := f.Pos
        f.Pos := infoPos
        titleLen := f.ReadUInt(), descrLen := f.ReadUInt()
        VarSetCapacity(buf, infoSize := titleLen + descrLen) ; + 2)
        f.RawRead(buf, infoSize)
        this.title := StrGet(&buf, titleLen, "UTF-8")
        this.descr := StrGet(&buf + titleLen, descrLen, "UTF-8")
    }
    
    Run(target)
    {
        sID := this.scriptID
        f := this.f
        f.Pos := this.filePos
        Loop, % this.fileCount
        {
            id := A_Index-1
            size := f.ReadUInt()
            if !size
                continue
            f2 := FileOpen(target "\" (id != sID ? id ".bin" : "update.ahk"), "w")
            VarSetCapacity(buf, size)
            f.RawRead(buf, size)
            f2.RawWrite(buf, size)
            f2 := ""
        }
        VarSetCapacity(buf, 0)
        
        FileCreateDir, %target%\Lib
        FileCopy, %A_ScriptDir%\Lib\SUpd.ahk, %target%\Lib\SUpd.ahk
        
        RunWait, "%A_AhkPath%" "%target%\update.ahk"
        if ErrorLevel != 0
            throw Exception("Update failed.", 0, "Revision " this.revision)
    }
    
    __Delete()
    {
        this.f.Close()
    }
}

CloseSciTE()
{
    ComObjError(0)
    o := ComObjActive("SciTE4AHK.Application")
    ComObjError(1)
    if !o
        return
    hWnd := o.SciTEHandle
    o := ""
    WinClose, ahk_id %hwnd%
    WinWaitClose, ahk_id %hwnd%,, 5
    if ErrorLevel = 1
        ExitApp
}

ReadGUID(f)
{
    VarSetCapacity(bGUID, 16)
    f.RawRead(bGUID, 16)
    VarSetCapacity(guid, 100)
    DllCall("ole32\StringFromGUID2", "ptr", &bGUID, "ptr", &guid, "int", 50)
    return StrGet(&guid, "UTF-16")
}

; Check to see if the running version is newer than the local/portable local install
; vCur = Current/newer version
; vLocal = Local/existing version
IsRunningVersionNewer(vCur, vLocal){
    ; Declare variables
    result := False, cA := [], lA := []
    ; Split version fields into array elements
    cA := StrSplit(vCur, ".", " `t`n`r"), lA := StrSplit(vLocal, ".", " `t`n`r")
    ; Loop. Use A_Index to compare version fields
    Loop
    {
        ; If running is ever greater than local
        if (cA[A_Index] > lA[A_Index]){
            ; Set result to true and break
            result := true
            Break
        }
    ; Break when element is no longer a digit
    }Until !(cA[A_Index] ~= "\d")

    Return result
}
