;
; File encoding:  UTF-8
;

goto _aaa_skip

UpdateProfile:
    ;if (SciTEVLocal > SciTEVRunning) || (SciTEVLocal < "3.0.00")
    if !IsRunningVersionNewer(SciTEVRunning, SciTEVLocal){
    	SciTEVLocal := ""
    	return
    }

    ; Delete property and version file
    FileDelete, %LocalSciTEPath%\_platform.properties
    FileDelete, %LocalSciTEPath%\$VER

    ; Create new version file
    FileAppend, %SciTEVRunning%, %LocalSciTEPath%\$VER
    
    ; Store current local
    OldVer := SciTEVLocal
    
    ; Update current local with current running
    SciTEVLocal := SciTEVRunning

    regenerateUserProps := true
    
    ; Check to see if version is prior to 4.0
    ;Loop, Parse, OldVer
    ;if (OldVer < "3.0.05")
    ;	gosub UpdateV4
    RegExMatch(OldVer, "\d+(?=\.)", match)
    if (match < 4)
        return

    ; Styles to backup and install
    StyleA  :=  ["Blank", "Classic", "HappyHacker", "HatOfGod", "Light", "Noir", "PSPad", "tidRich_Zenburn", "VisualStudio"]

    ; Loop through style array
    for index, name in StyleA
    {
        ; Back up the style if it exists
        BackupIfExist(LocalSciTEPath "\Styles\" name ".style.properties")
        ; Install the updated file
        FileCopy, %SciTEDir%\newuser\Styles\" name ".style.properties, %LocalSciTEPath%\Styles\" name ".style.properties, 1
    }
    ;BackupIfExist(LocalSciTEPath "\Styles\Blank.style.properties")
    ;BackupIfExist(LocalSciTEPath "\Styles\Classic.style.properties")
    ;BackupIfExist(LocalSciTEPath "\Styles\Light.style.properties")
    ;BackupIfExist(LocalSciTEPath "\Styles\VisualStudio.style.properties")
    ;FileCopy, %SciTEDir%\newuser\Styles\Blank.style.properties, %LocalSciTEPath%\Styles\Blank.style.properties, 1
    ;FileCopy, %SciTEDir%\newuser\Styles\Classic.style.properties, %LocalSciTEPath%\Styles\Classic.style.properties, 1
    ;FileCopy, %SciTEDir%\newuser\Styles\Light.style.properties, %LocalSciTEPath%\Styles\Light.style.properties, 1
    ;FileCopy, %SciTEDir%\newuser\Styles\VisualStudio.style.properties, %LocalSciTEPath%\Styles\VisualStudio.style.properties, 1
return

; Backs up a file if it exists
BackupIfExist(file)
{
    FileMove, %file%, %file%.old, 1
}

_aaa_skip:
_=_
