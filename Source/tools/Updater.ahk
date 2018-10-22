#SingleInstance Force
guiHWND	:= {}
update := new UpdateBase
update.FullUpdate()
Return

class UpdateBase
{
	; ===== Variables =====
	; URLS
	baseURL		:=	"https://github.com/GroggyOtter"
	sourceURL	:=	this.baseURL "/SciTE4AHK_GO/archive/master.zip"
	sevenZipURL	:=	this.baseURL "/GroggyRepo/raw/master/Programs/7za.exe"
	
	; Paths and files
	tmpLoc		:=	A_Temp "\SciTE4AKH_GO"
	subDirA		:=	{"B"	:this.tmpLoc "\Backup"			; Backup location for current installed files
					,"U"	:this.tmpLoc "\Updater"			; Store secondary updater if primary needs updated
					,"D"	:this.tmpLoc "\Download"		; Store downloaded files
					,"S"	:this.tmpLoc "\SourceFiles"	}	; Extraction location for new files
	
	updateZip	:=	"SciTEUpdate.zip"
	updateZipLoc:=	this.subDirA.D "\" this.updateZip
	
	sevenZip	:=	"7za.exe"
	sevenZipLoc	:=	this.subDirA.D "\" this.sevenZip
	
	SciTEExe	:=	"SciTE.exe"
	SciTELoc	:=	A_ScriptDir "\.."

	permBack	:= 
	permBackLoc	:=	A_AppData "\SciTE4AHK_GO"
	
	; ===== Methods =====
	; Do a full update for SciTE
	FullUpdate(){
		; Create user interface for update
		MakeUpdateGUI()

		UpProg("Checking for Administrator rights.")
		; Verify admin rights
		If !A_IsAdmin
		{
			MsgBox, Administrator rights required to run this.`nClosing updater.
			ExitApp
		}
		UpProg("User rights are OK.")

		UpProg("Creating temp folders.")
		; Make a temp location for files
		this.CreateTempLocation()
		UpProg("Temporary directories successfully created.")

		UpProg("Downloading SciTE4AHK_GO from GitHub.")
		; Download zip of program files
		this.Download(this.sourceURL, this.updateZipLoc)
		UpProg("Download successful.")
		
		UpProg("Unzipping files.")
		; Unzip file
		this.UnZip(this.updateZipLoc, this.subDirA.S)
		UpProg("Files successfully unzipped.")

		UpProg("Backing up current SciTE4AHK_GO files.")
		; Backup current SciTE install folder to temporary folder
		this.CopyFolder(this.SciTELoc, this.subDirA.B)

		UpProg("Installing new files.")
		; Move new SciTE files to SciTE install folder
		this.CopyFolder(this.subDirA.S "\SciTE4AHK_GO-master\Source", this.SciTELoc)
		
		UpProg("Cleaning up install files.")
		; Clean up temp folder
		this.Cleanup(this.tmpLoc)
		
		; Restart SciTE
		GuiControl, Text, guiHWND.btn, % "OK"
		UpProg("Click OK to restart SciTE4AHK_GO")
		;Run, % SciTELoc "\" SciTEExe

		return
	}
	
	; Cleanup
	Cleanup(dir)
	{
		; Removes all temp files
		FileRemoveDir, % dir, 1
		If (ErrorLevel > 0)
		{
			MsgBox, 8245, Cleanup Error, % "There was an error while deleting files`n"
				. "Problem:  " dir "`n`n"
				. "Click RETRY to try deleting these files again.`n"
				. "Click CANCEL to ignore and continue."
			IfMsgBox, Retry
				this.Cleanup(dir)
			UpProg("`tDeleted:`n" dir)
		}
	}
	
	; Copy files
	CopyFolder(source, dest){
		; Check source
		FileCopyDir, % source, % dest, 1

		; If there's an error, notify user
		if (ErrorLevel > 0){
			MsgBox, 8245, Backup Error, % "There was an error backing up the original files.`n`n"
				. "Click RETRY to try backing up the files again.`n"
				. "Click CANCEL to abort."
			IfMsgBox, Retry
				this.CopyFolder(source, dest)
			IfMsgBox, Cancel
				this.RestoreOriginalFiles()
		}
		UpProg("`tCopy From: " source "`n  Copy To: " dest)
	}
	
	; Restores backed up files
	RestoreOriginalFiles()
	{
		this.CopyFolder(this.subDirA.B, this.SciTELoc)
		UpProg("`tOriginal files restored.")
	}
	
	; Make sure temp location exists
	CreateTempLocation()
	{
		; Make a temp location for files
		for index, dir in this.subDirA
		{
			; Create directory
			FileCreateDir, % dir
			; If there's an error, notify user
			if (ErrorLevel > 0){
				MsgBox, 8245, Directory Creation Error, % "There was an error creating a necessary install temp directories.`n"
					. "Folder: " dir "`n`n"
					. "Click RETRY to try creating the folders again.`n"
					. "Click CANCEL to abort and restore original files."
				IfMsgBox, Retry
					this.CreateTempLocation()
			}Else
				UpProg("`t" dir)
		}
	}
	
	; Download files
	Download(url, filePath)
	{
		; Download url file to path
		UrlDownloadToFile, % url, % filepath
		
			; If there's an error, notify user
		if (ErrorLevel > 0){
			MsgBox, 8245, Download Error, % "There was an error downloading a file`n"
				. "URL:  " url "`n`n"
				. "Click RETRY to try downloading the files again.`n"
				. "Click CANCEL to abort and restore original files."
			IfMsgBox, Retry
				this.DownloadZip(url, filepath)
			IfMsgBox, Cancel
				this.RestoreOriginalFiles()
		}
	}
	
	; Unzip a zip
	UnZip(file, unzipPath)
	{
		; Check if zip program exists
		if !FileExist(this.sevenZipLoc)
			; If not, get it
			this.Download(this.sevenZipURL, this.sevenZipLoc)
		
		; Wait for unzip progress
		; 7zip switches: -aoa=Overwrite all, -o="output file", -y=assume yes to popups
		RunWait, % A_ComSpec " /c " this.sevenZipLoc " x " file " -aoa -y -o" unzipPath,, Hide UseErrorLevel
		; Set exit code
		ec := ErrorLevel
		
		; If there's an error, notify user
		If (ec > 0){
			; List of 7zip exit codes
			errorA :=	{0	:"No error."
						,1	:"Warning: Non fatal error(s)."
						,2	:"Fatal error."
						,7	:"Command line error."
						,8	:"Not enough memory for operation."
						,255:"User stopped the process."}
			
			MsgBox, 8245, Unzip Error, % "There was an error unzipping the files.`n"
				. "File:  " file "`n"
				. "Error: " errorA[ec] "`n`n"
				. "Click RETRY to try unzipping the files again.`n"
				. "Click CANCEL to abort and restore original files."
			IfMsgBox, Retry
				this.UnZip(file)
			IfMsgBox, Cancel
				this.RestoreOriginalFiles()
		}
	}
}

MakeUpdateGUI(){
	global	guiHWND

	gW		:= 500							; Width
	gH		:= 300							; Height
	gX		:= (A_ScreenWidth/2) - (gW/2)	; X coord
	gY		:= (A_ScreenHeight/2) - (gH/2)	; Y coord
	gP		:= 10							; Element padding
	gM		:= 10							; Margin
	gWM		:= gW - (gM*2)					; Full width minus margins
	gHM		:= gH - (gM*2)					; Full height minus margins
	; Button WHXY
	gBtnW	:= 80
	gBtnH	:= 25
	gBtnx	:= gW - (gM + gBtnW)
	gBtny	:= gH - (gM + gBtnH)
	; Edit Display WHXY
	gDispW	:= gWM
	gDispH	:= gHM - (gBtnH + gP)
	gDispX	:= gM
	gDispY	:= gM
	
	; Create new GUI and options
	Gui, Updater:New, HWNDgHWND
	guiHWND.gui := gHWND

	; Set Updater to default gui name
	Gui, Updater:Default

	Gui, Color, 0x000000
	Gui, Font, cWhite s10 q5, Lucida Console

	; Add display box
	Gui, Add, Edit, % "x" gDispX " y" gDispY " w" gDispW " h" gDispH " HWNDgDisp +HScroll ReadOnly -wrap", Starting Update:
	guiHWND.Disp := gDisp

	; Add button
	; Gui, Add, Button, x340 y290 w80 h30, Button
	Gui, Add, Button, % "x" gBtnX " y" gBtnY " w" gBtnW " h" gBtnH " HWNDgBtn", Cancel
	guiHWND.Btn := gBtn
	
	; Show GUI
	Gui, Show, % "x" gX " y" GY " w" gW " h" gH, SciTE4AHK_GO Updater
	Return
}
; Update the progress of the Update GUI
UpProg(msg){
	Gui, Submit, NoHide
	global	guiHWND

	; Get current info from edit box
	GuiControlGet, oldMsg,, % guiHWND.Disp
	
	; Append new message
	newMsg	:= oldMsg "`n" msg
	GuiControl, Text, % guiHWND.Disp, % newMsg

	ControlSend, guiHWND.Disp, {End}
	Return
}


; Original template I typed out to start making this.
; Programmer Easter Egg
	; Verify admin rights
	; Make a temp location for files
	;	temp\SciTE4AHK_GOUpdate
	;		\download|zip dir
	;		\backup dir
	;		\updateUpdater dir
	; Download zip to temp location.
	;	Link: https://github.com/GroggyOtter/SciTE4AHK_GO/tree/master/Source
	;	Error handling download failed
	;		Options: Try again or abort
	; Extract zip (will need to bundle 7zip extractor. check prior scripts for how to do this)
	;	Error handling extract failed
	;		Options: Retry extract, redownload, abort
	; Backup old files
	;	Along with backing up files, make an additional backup to the temp folder
	; Move zip files to current location
	;	Error handling if all files aren't moved
	;		Options: Restore backups, retry moving, redownload
	; Cleanup temp folder
	; Restart SciTE

Esc::ExitApp
/*
TC(){
	Static i:=1
	i := 
	return i
}


#If WinExist("ahk_class CallTip ahk_exe SciTE.exe")
*WheelUp::
*WheelDown::
#If 

NextCard(){
	CoordMode, Mouse, Window
	MouseGetPos, mX, mY
	WinGetPos, ttX, ttY, , , ahk_class CallTip ahk_exe SciTE.exe
	card	:=	{next:{x:25,y:10}
				,prev:{x:12,y:10}}
	MsgBox, % "ttX: " ttX "`nttY: " ttY "`nx: " x "`ny: " y
	Click, %x%, %y%, Left
	MouseMove, % mX, % mY, 0
	return
}

LexiconToAPI(data){
	result	:= ""
	replace	:= True
	skip	:= False
	Loop, Parse, data, `n, `r
	{
		; MsgBox, % "This Line: " A_LoopField "`nSkip: " skip
		
		; Skip custom
		If (skip != False){
			if skip is number
				skip--
			Else
				if RegExMatch(A_LoopField, skip)
					skip := False
			Continue
		}
		
		; Keep blank line spacing
		if RegExMatch(A_LoopField, "^\s+$") || (A_LoopField = ""){
			result .= "`n`n"
			Continue
		}
		
		; Skip legend
		if RegExMatch(A_LoopField, "^\|\|\|CARD.*$"){
			skip	:= "^\|\|\|.*$"
			Continue
		}
		
		; Skip operators
		if RegExMatch(A_LoopField, "^\|\|\|OPERATORS.*$"){
			skip	:= "^\|\|\|.*$"
			Continue
		}
		
		; Stop \n replacement after other keywords
		if RegExMatch(A_LoopField, "^\|\|\|OTHER.*$"){
			replace	:= False
			Continue
		}
		
		; Skip directives
		if RegExMatch(A_LoopField, "^\|\|\|.*$")
			Continue
		
		; Record data
		; When replace is true, linebreaks are replaced with \n
		if (replace = True)
			result .= A_LoopField "\n"
		Else
			result .= A_LoopField "`n"
		;MsgBox, % result
	}
	return result
}







/*



;============================== Start Auto-Execution Section ==============================
; Always run as admin
if not A_IsAdmin
{
   Run *RunAs "%A_ScriptFullPath%"  ; Requires v1.0.92.01+
   ExitApp
}

; Keeps script permanently running
#Persistent

; Avoids checking empty variables to see if they are environment variables.
; Recommended for performance and compatibility with future AutoHotkey releases.
#NoEnv

; Ensures that there is only a single instance of this script running.
#SingleInstance, Force

; Determines how fast a script will run (affects CPU utilization).
; The value -1 means the script will run at it's max speed possible.
SetBatchLines, -1

; Makes a script unconditionally use its own folder as its working directory.
; Ensures a consistent starting directory.
SetWorkingDir %A_ScriptDir%

; sets title matching to search for "containing" instead of "exact"
SetTitleMatchMode, 2

GroupAdd, saveReload, %A_ScriptName%

; Decalre Variables
; First Letter Array
global	fla			:= ["a","b","c","d","e","f","g","h","i","j","k","l","m","n","o","p","q","r","s","t","u","v","w","x","y","z"]
; Current Letter Array
global	cla			:= {}
global	dlPath		:= A_Temp "\TVShowRenamer"
global	epAdd		:= "http://epguides.com"

IfNotExist, % dlPath
	FileCreateDir, % dlPath

GoSub, MakeGUI
;return

;============================== Main Script ==============================
;Start id:	id="eplist"
;Stop id:	id="latest"
;link:		http://epguides.com/menua/

;~ StartUp:
	;~ For key, val in fla
	;~ {
		;~ fli	:= fla[A_Index]
		;~ URLDownloadToFile, % epAdd "/menu" fli, % dlPath "\Menu" fli ".txt"
	;~ }
;~ return


MakeGUI:
	layout		:= {}
	t			:= 1
	size		:= 40
	FirstLetter	:=
	(
	"A|B|C|D|E|F
	G|H|I|J|K|L
	M|N|O|P|Q|R
	S|T|U|V|W|X
	Y|Z"
	)

	Gui, Destroy
	Gui, Margin, 5, 5
	Gui, Font, S15

	Loop, parse, FirstLetter, `n,`r
			layout[(A_LoopField)?(t++):]:=StrSplit(A_LoopField,"|")

	Gui, Add, Text, x5 y5 , TV Show Renamer

	index	:= 1
	for row, line in layout
		for column, key in line
			if (key||key=0)&&key!=A_Space
			{
				Gui, Add, Button, % "x" ((column-1)*size) " y" ((row-1)*size+40) " w" size " h" size " gGenerateLetter", % key
				index++
			}
	Gui, Show
return

GenerateLetter:

	currentLetter	:= A_GuiControl
	URLDownloadToFile, % epAdd "/menu" currentLetter, % dlPath "\current.txt"
	formatCurrentTxt()
	
	Gui, Destroy
	Gui, Add, Text, x5 y5 Section, % "Letter " currentLetter " list."
	
	Gui, Font, S10 underline
	
	currentRow	:= 0
	currentCol	:= 0
	currentH	:= 15
	currentW	:= 200
	
	for shName, shAdd in cla
	{
		if (currentRow = 60){
			currentRow	:= 0
			currentCol++
		}
		
		Gui, Add, Text, % "xs+" (currentCol * currentW)+5 " ys+" (currentRow * currentH)+5 " h" currentH " w" currentW " vaddress" A_Index, % shName
		address%A_Index%	:= shAdd
		currentRow++
	}
	
	Gui, Show
return



;~ MainGui:
	;~ Gui, Add, Edit, x22 y69 w210 h30 , Edit
	;~ Gui, Add, Button, x252 y69 w100 h30 , Search For Show
	;~ Gui, Add, Text, x22 y19 w210 h30 , Text
	;~ Gui, Add, Button, x252 y19 w100 h30 , Select Folder

	;~ Gui, Show, w379 h379, Untitled GUI
;~ return

GuiClose:
ExitApp

formatCurrentTxt(){
	FileDelete, % dlPath "\temp.txt"
	fctWrite	:= 0
	cla			:= {}
	Loop, Read, % dlPath "\current.txt"
	{
		tmp		:= A_LoopReadLine
		
		; Start Recording when tdmenu is reached
		IfInString, tmp, class='tdmenu'
			fctWrite	:= 1
		
		; Stop recording after close table tag
		IfInString, tmp, </table>
			fctWrite	:= 0
		
		if (fctWrite != 1)
			continue
		
		; Skips all lines that don't have title data
		IfNotInString, tmp, <li><b>
			continue
		
		; Get rid tags
		tmp			:= RegExReplace(tmp, "<li>", "")
		tmp			:= RegExReplace(tmp, "</li>", "")
		tmp			:= RegExReplace(tmp, "<b>", "")
		tmp			:= RegExReplace(tmp, "</b>", "")
		tmp			:= RegExReplace(tmp, "<a href=""..", "")
		tmp			:= RegExReplace(tmp, "</a>", "")
		
		; Replace html markup
		tmp			:= RegExReplace(tmp, "&amp;", "&")
		tmp			:= RegExReplace(tmp, "&eacute;", "é")
		tmp			:= RegExReplace(tmp, "&#xC4;", "Ä")
		tmp			:= RegExReplace(tmp, "&#xE4;", "ä")
		tmp			:= RegExReplace(tmp, "&#xFC;", "ü")
		tmp			:= RegExReplace(tmp, "&aelig;", "æ")
		tmp			:= RegExReplace(tmp, "&#231;", "ç")
		tmp			:= RegExReplace(tmp, "&#243;", "ó")
		tmp			:= RegExReplace(tmp, "&#237;", "í")
		tmp			:= RegExReplace(tmp, "&#233;", "é")
		tmp			:= RegExReplace(tmp, "&#xE9;", "é")
		
		; Add pipe divider between name and address
		tmp			:= RegExReplace(tmp, """>", "||")
		
		showName	:= RegExReplace(tmp, "^(.*?)\|\|", "")
		
		showAddress	:= RegExReplace(tmp, "\|\|(.*)$", "")
		showAddress	:= epAdd showAddress
		
		cla.Insert(showName, showAddress)
;		FileAppend, % showName "`n" showAddress "`n`n", % dlPath "\temp.txt"
		FileAppend, % tmp "`n", % dlPath "\temp.txt"
	}
}


;============================== Save Reload / Quick Stop ==============================
#IfWinActive, ahk_group saveReload

; Use Control+S to save your script and reload it at the same time.
~^s::
	TrayTip, Reloading updated script, %A_ScriptName%
	SetTimer, RemoveTrayTip, 1500
	Sleep, 1750
	Reload
return

; Removes any popped up tray tips.
RemoveTrayTip:
	SetTimer, RemoveTrayTip, Off 
	TrayTip 
return 

; Hard exit that just closes the script
^Esc::ExitApp


#IfWinActive

;============================== ini Section ==============================
; Do not remove /* or */ from this section. Only modify if you're
; storing values to this file that need to be permanantly saved.
/*
[SavedVariables]
Key=Value
*/
;============================== GroggyOtter ==============================
;============================== End Script ==============================
