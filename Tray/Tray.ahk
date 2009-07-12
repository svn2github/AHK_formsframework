/* Title:		Tray
				*Tray icon controller*
 */

/*Function:		Add
 				Add icon in the system tray.
 
  Parameters:
 				hGui	- Handle of the parent window (the one that monitors notification messages)
 				Handler	- Notification handler.
 				Icon	- Icon path or handle. Icons allocated by module will be automatically destroyed when <Remove> function
 						  returns. If you pass icon handle, <Remove> will not destroy it. If path is an icon resource, you can 
						  use "path:idx" notation to get the handle of the desired icon by its resource index (0 based).
 				Tooltip	- Tooltip text.
 
  Notifications:
 >				Handler(Hwnd, Event)
 
 				Hwnd	- Handle of the tray icon.
 				Event	- L (Left click),R(Right click), M (Middle click), P (Position - mouse move).
		 				  CAdditionally, "u" or "d" can follow event name meaning "up" and "doubleclick".
 						  For example, you will be notified on "Lu" when user releases the left mouse button.
 				
  Returns:
 				0 on failure, handle on success.
 */
Tray_Add( hGui, Handler, Icon, Tooltip="") {
	static NIF_ICON=2, NIF_MESSAGE=1, NIF_TIP=4, MM_SHELLICON := 0x500
	static uid=100, hFlags

	if !hFlags
		OnMessage( MM_SHELLICON, "Tray_onShellIcon" ), hFlags := NIF_ICON | NIF_TIP | NIF_MESSAGE 

	if !IsFunc(Handler)
		return A_ThisFunc "> Invalid handler: " Handler

	hIcon := Icon/Icon ? Icon : Tray_loadIcon(Icon, 32)

	VarSetCapacity( NID, 88, 0) 
	 ,NumPut(88,	NID)
	 ,NumPut(hGui,	NID, 4)
	 ,NumPut(++uid,	NID, 8)
	 ,NumPut(hFlags, NID, 12)
	 ,NumPut(MM_SHELLICON, NID, 16)
	 ,NumPut(hIcon, NID, 20)
	 ,DllCall("lstrcpyn", "uint", &NID+24, "str", Tooltip, "int", 64)
	
	if !DllCall("shell32.dll\Shell_NotifyIconA", "uint", 0, "uint", &NID)
		return 0

	Tray( uid "handler", Handler)
	Icon/Icon ? Tray( uid "hIcon", hIcon) :		;save icon handle allocated by Tray module so icon can be destroyed.
	return uid
}

/*Function:		Define
 				Get information about system tray icons.
 
  Parameters:
				Filter  - Contains process name, ahk_pid or ahk_id for which to return information.
				pQ		- Query parameter, by default "phw"
				Sep		- Separator char, by default |.

  Query:
				h	- Handle.
				i	- PosItion (0 based).
				w	- Parent Window handle.
				p	- Process Pid.
				n	- Process Name.
 
  Returns:
				String containing icon information per line. 
				Icon infomration is separted list of position, icon handle and handle of the window responsible for the icon.
 */
Tray_Define(Filter="", pQ="", Sep="|"){
	static TB_BUTTONCOUNT = 0x418, TB_GETBUTTON=0x417
	ifEqual, pQ,, SetEnv, pQ, ihw

	if Filter contains ahk_pid,ahk_id
		 bPid := InStr(Filter, "ahk_pid"),  bID := !bPid,  Filter := SubStr(Filter, 8)
	else bName := true

	oldDetect := A_DetectHiddenWindows
	DetectHiddenWindows, on

	WinGet,	pidTaskbar, PID, ahk_class Shell_TrayWnd
	hProc := DllCall("OpenProcess", "Uint", 0x38, "int", 0, "Uint", pidTaskbar)
	pProc := DllCall("VirtualAllocEx", "Uint", hProc, "Uint", 0, "Uint", 32, "Uint", 0x1000, "Uint", 0x4)
	idxTB := Tray_getTrayBar()
	SendMessage,TB_BUTTONCOUNT,,,ToolbarWindow32%idxTB%, ahk_class Shell_TrayWnd
	
	i := -1
	Loop, %ErrorLevel%
	{
		SendMessage, TB_GETBUTTON, A_Index-1, pProc, ToolbarWindow32%idxTB%, ahk_class Shell_TrayWnd

		VarSetCapacity(BTN,32), DllCall("ReadProcessMemory", "Uint", hProc, "Uint", pProc, "Uint", &BTN, "Uint", 32, "Uint", 0)
		dwData := NumGet(BTN,12)
		ifEqual, dwData, 0, SetEnv, dwData, % NumGet(BTN, 16, "Int64")

		VarSetCapacity(NFO,32), DllCall("ReadProcessMemory", "Uint", hProc, "Uint", dwData, "Uint", &NFO, "Uint", 32, "Uint", 0)
		w := NumGet(NFO),  h := NumGet(NFO, 8)
		
		WinGet, n, ProcessName, ahk_id %w%
		WinGet, p, PID, ahk_id %w%
		i++
		if !Filter|| (bName && Filter=n) || (bPid && Filter=p) || (bId && Filter=w) {
			loop, parse, pQ
				f := A_LoopField, res .= %f% Sep
			res := SubStr(res, 1, -1) "`n"		
		}
	}
	DllCall("VirtualFreeEx", "Uint", hProc, "Uint", pProc, "Uint", 0, "Uint", 0x8000), DllCall("CloseHandle", "Uint", hProc)

	DetectHiddenWindows,  %oldDetect%
	return SubStr(res, 1, -1)
}

Tray_Get(hGui, hTray, pQ, ByRef o1, ByRef o2, ByRef o3) {
	;tooltip, icon handle, position, class, processname, pid, tooltip, msgid

}


/*	Function:	Modify
				Modify icon properties.

	Parameters:
				hGui	- Handle of the parent window (the one that monitors notification messages).
				hTray	- Handle of the tray icon (returned by <Add> function)
				Icon	- Icon path or handle, set to "" to skip.
				Tooltip	- ToolTip text, omit to keep the current tooltip.

	Returns:
				TRUE on success, FALSE otherwise.
 */
Tray_Modify( hGui, hTray, Icon, Tooltip="~`a�" ) {
	static NIM_MODIFY=1, NIF_ICON=2, NIF_TIP=4

	VarSetCapacity( NID, 88, 0)
	NumPut(88, NID, 0)

	hFlags := 0
	hFlags |= Icon != "" ?  NIF_ICON : 0
	hFlags |= Tooltip != "" ? NIF_TIP : 0

	if (Icon != "") {
		hIcon := Icon/Icon ? Icon : Tray_loadIcon(Icon)
		DllCall("DestroyIcon", "uint", Tray( hTray "hIcon", "") )
		Icon/Icon ? Tray( hTray "hIcon", hIcon) :
	}

	if (Tooltip != "~`a�")
		DllCall("lstrcpyn", "uint", &NID+24, "str", Tooltip, "int", 64)


	NumPut(hGui,	  NID, 4)
	 ,NumPut(hTray,	  NID, 8)
	 ,NumPut(hFlags,  NID, 12)
	 ,NumPut(hIcon,   NID, 20)
	return DllCall("shell32.dll\Shell_NotifyIconA", "uint", NIM_MODIFY, "uint", &NID)	
}

/*	Function:	Move
 				Move the tray icons.
 
	Parameters:
				Pos		- Position of the icon to move, 1 based.
				NewPos	- New position of the icon, if omited, icon will be moved to the end.
	Returns:
 				TRUE on success, FALSE otherwise.
 */
Tray_Move(Pos, NewPos=""){
	static TB_MOVEBUTTON = 0x452
	idxTB := Tray_getTrayBar()

	if (NewPos = "") {
		SendMessage,TB_BUTTONCOUNT,,,ToolbarWindow32%idxTB%, ahk_class Shell_TrayWnd
		NewPos := ErrorLevel
	}

	SendMessage,TB_MOVEBUTTON, Pos-1, NewPos-1, ToolbarWindow32%idxTB%, ahk_class Shell_TrayWnd
}

/* Function:	Remove
 				Removes the tray icon.
 
  Parameters:
 				hGui	- Handle of the parent window.
 				hTray	- Handle of the tray icon. If omited, all icons owned by the hGui will be removed.
 
  Returns:
 				TRUE on success, FALSE otherwise.
 */
Tray_Remove( hGui, hTray="") {
	static NIM_DELETE=2
	
	s := hTray
	if (hTray = "")
		s := Tray_Define("ahk_id " hGui, "h")

	res := 1
	loop, parse, s, `n
	{
		VarSetCapacity( NID, 88, 0), NumPut(88, NID),  NumPut(hGui, NID, 4), NumPut(A_LoopField, NID, 8)
		if hIcon := Tray(A_LoopField "hIcon", "")
			   DllCall("DestroyIcon", "uint", hIcon)
		res &= DllCall("shell32.dll\Shell_NotifyIconA", "uint", NIM_DELETE, "uint", &NID)
	}
}

/* Function:	Refresh
 				Refresh tray icons.
 
 */
Tray_Refresh(){ 
	static WM_MOUSEMOVE = 0x200

	ControlGetPos,,,w,h,ToolbarWindow321, AHK_class Shell_TrayWnd 
	width:=w, hight:=h 
	while % ((h:=h-5)>0 and w:=width)
		while % ((w:=w-5)>0)
			PostMessage, WM_MOUSEMOVE,0,% ((hight-h) >> 16)+width-w,ToolbarWindow321, AHK_class Shell_TrayWnd 
}

;======================================== PRIVATE ====================================

Tray_getTrayBar(){
	ControlGet, hParent, hWnd,, TrayNotifyWnd1  , ahk_class Shell_TrayWnd
	ControlGet, hChild , hWnd,, ToolbarWindow321, ahk_id %hParent%
	Loop {
		ControlGet, hwnd, HWND,, ToolbarWindow32%A_Index%, ahk_class Shell_TrayWnd
		IfEqual, hwnd, 0, return
		IfEqual, hwnd, %hChild%, return A_Index
	}
}


Tray_loadIcon(pPath, pSize=32){
	j := InStr(pPath, ":", 0, 0), idx := 0
	if j > 2
		idx := Substr( pPath, j+1), pPath := SubStr( pPath, 1, j-1)

	DllCall("PrivateExtractIcons"
            ,"str",pPath,"int",idx,"int",pSize,"int", pSize
            ,"uint*",hIcon,"uint*",0,"uint",1,"uint",0,"int")

	return hIcon
}



Tray_onShellIcon(Wparam, Lparam) {
	static EVENT_512="P", EVENT_513="L", EVENT_514="Lu", EVENT_515="Ld", EVENT_516="R", EVENT_517="Ru", EVENT_518="Rd", EVENT_519="M", EVENT_520="Mu", EVENT_521="Md"

	handler := Tray(Wparam "handler")
	 ,event := (Lparam & 0xFFFF)  
	 ,%handler%(Wparam, EVENT_%event%)
}


;storage
Tray(var="", value="~`a�") { 
	static
	_ := %var%
	ifNotEqual, value,~`a�, SetEnv, %var%, %value%
	return _
}


/* Group: Example
 (start code)
		Gui,  +LastFound
		hGui := WinExist()
 
		Tray_Add( hGui, "OnTrayIcon", "Tray.ico", "My Tray Icon")
	return
 
	OnTrayIcon(hCtrl, Event){
	  	if (Event != "R")		;return if event is not right click
			return
 
		MsgBox Right Button clicked
	}
 (end code)
*/

/* Group: About
	o v2.0 by majkinetor. See http://www.autohotkey.com/forum/topic26042.html
	o Tray_Refresh by HotKeyIt
	o Reference: <http://msdn2.microsoft.com/en-us/library/aa453686.aspx>
	o Licenced under GNU GPL <http://creativecommons.org/licenses/GPL/2.0/> 
 */