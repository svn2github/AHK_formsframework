;AutoHide=blend,center,slide
AppBar_New(ByRef Hwnd, o1="", o2="", o3="", o4="", o5="", o6="", o7="", o8="", o9=""){
	static CALLBACKMSG := 12345, ABM_SETAUTOHIDEBAR=8, ABM_NEW=0

	oldDetect := A_DetectHiddenWIndows
	DetectHiddenWIndows, on

	Edge:="Top", AutoHide := Show := 0, Style := "OnTop Show", Label := "AppBar"
	loop, 9	{
		f := o%A_Index%
		ifEqual, f,,break
		j := InStr(f, "="), n := SubStr(f, 1, j-1), %n% := SubStr(f,j+1)
	}
	StringSplit, s, Style, %A_Space%
	loop, %s0%
		s := s%A_Index%, %s% := 1

	ifEqual, Height, ,SetEnv, Height, % Edge="Top"  || Edge="Bottom" ? 32 : A_ScreenHeight
	ifEqual, Width,  ,SetEnv, Width,  % Edge="Left" || Edge="Right"  ? 50 : A_ScreenWidth

	if (Hwnd = "") {
		k := 1
		while (k) {					;find available gui number
			n := 100 - A_Index
			Gui %k%:+LastFoundExist
			k := WinExist()
		}
		Gui, %n%:+LastFound -Caption +ToolWindow +Label%Label%
		Hwnd := WinExist()
	}

	if Show {
			WinShow, ahk_id %Hwnd%
			WinActivate, ahk_id %Hwnd%
	}

	VarSetCapacity(ABD,36,0), NumPut(36, ABD), NumPut(Hwnd, ABD, 4), NumPut(%Edge%, ABD, 12), NumPut(CALLBACKMSG, ABD, 8) 
	if AutoHide
		 r := DllCall("Shell32.dll\SHAppBarMessage", "UInt", ABM_SETAUTOHIDEBAR, "UInt", &ABD)	; r := AppBar_send("SETAUTOHIDEBAR", hGui, "", Edge)
	else r := DllCall("Shell32.dll\SHAppBarMessage", "UInt", ABM_NEW, "UInt", &ABD)				; AppBar_send("NEW", hGui, AB_CALLBACK)

	if OnTop
		WinSet, AlwaysOnTop, on, ahk_id %Hwnd%

	if !r {
		if n
			Gui, %n%:Destroy
		return 0
	} 
	AppBar_setPos(Hwnd, Edge, Width, Height)
	
	GroupAdd, AppBar, ahk_id %Hwnd%
	if AutoHide
		AppBar_setAutoHideBar(Hwnd, Edge, AutoHide, Width, Height)

	DetectHiddenWIndows, %oldDetect%
	return n
}

AppBar_setAutoHideBar(Hwnd, Edge, AnimType, Width, Height){
	static timer := 500

	d1 := Edge="Top" ? "vpos" : Edge="Left" ? "hpos" : Edge ="Right" ? "hneg" : "vneg"
	d2 := Edge="Top" ? "vneg" : Edge="Left" ? "hneg" : Edge ="Right" ? "hpos" : "vpos"
	animOn := AnimType " " d1, animOff := AnimType " hide " d2
	SetTimer, %A_ThisFunc%, %timer%
	
	AppBar_timer(Hwnd, Edge, animOn, animOff, Width, Height)
	return
	
 AppBar_setAutoHideBar:
	AppBar_timer()
 return
}

AppBar_timer(Hwnd="", Edge="", Anim1="", Anim2="", Width="", Height="") {
	static 		
	if (Hwnd != "") {
		if !SX
			VarSetCapacity(POINT, 8), adrGetCursorPos := DllCall("GetProcAddress", uint, DllCall("GetModuleHandle", str, "user32"), str, "GetCursorPos")
			,SY := A_ScreenHeight - 5, SX := A_ScreenWidth - 5, 

		bVisible := DllCall("IsWindowVisible", "uint", Hwnd)
		
		animOn := Anim1, animOff := Anim2
		e := Edge="Top" || Edge="Left"		
		d := Edge="Top" || Edge="Bottom"
		v1 := d ? "y" : "x",  v2 := d ? "x" : "y"
		d1 := d ? Height : Width,  d2 := d ? Width : Height
		Wnd := Hwnd
		w := width, h := height
	}

	ifWinActive ahk_group AppBar
		return
	DllCall(adrGetCursorPos, "uint", &POINT), x := NumGet(POINT), y := NumGet(POINT, 4)
	
	p := %v1%,  q := %v2%,	 dp := d1,  dq := d2,  Sp := S%v1%, Sq := S%v2%
	if ((e && p<5) || (!e && p>Sp-5)) && (q>(Sq-dq)//2 && q<(Sq+dq)//2)
		Win_Animate(Wnd, animOn), bVisible := true
	else if (bVisible) && (e && p>dp) || (!e && p<Sp-dp) || (q<(Sq-dq)//2) || (q > (Sq+dq)//2)
		Win_Animate(Wnd, animOff), bVisible := false
}

AppBar_setPos(Hwnd, Edge, Width, Height){
		static ABM_QUERYPOS=2, ABM_SETPOS=3, LEFT=0, TOP=1, RIGHT=2, BOTTOM=3

	H := A_ScreenHeight, W := A_ScreenWidth

	Height.= !Height ? H : ""
	Width .= !Width  ? W : ""

	VarSetCapacity(ABD,36,0), NumPut(36, ABD), NumPut(Hwnd, ABD, 4), NumPut(%Edge%, ABD, 12)
	if Edge = LEFT
		 r1 := 0, r2 := (H-Height)//2, r3 := Width, r4 := r2 + Height
	else if Edge = RIGHT
		 r1 := W - Width, r2 := (H-Height)//2, r3 := W, r4 := r2 + Height
	else if Edge = Top
		 r1 := (W - Width)//2, r2 :=0, r3 := r1+Width, r4 := Height
	else r1 := (W - Width)//2, r2 :=H-Height, r3 := r1+Width, r4 := H
	loop, 4                                          
		NumPut(r%A_Index%, ABD, 12+A_Index*4, "Int") 

	DllCall("Shell32.dll\SHAppBarMessage", "UInt", ABM_QUERYPOS, "UInt", &ABD)
	loop, 4
		r%A_Index% := NumGet(ABD, 12 + 4*A_Index, "Int")
                                               
	if Edge = LEFT
		 r3 := r1+Width
	else if Edge = RIGHT
		 r1 := r3-Width
	else if Edge = TOP
		 r4 := r2+Height
	else r2 := r4-Height
	loop, 4
		NumPut(r%A_Index%, ABD, 12+A_Index*4, "Int") 

	DllCall("Shell32.dll\SHAppBarMessage", "UInt", ABM_SETPOS, "UInt", &ABD)
	DllCall("MoveWindow", "uint", Hwnd, "int", r1, "int", r2, "int", r3-r1, "int", r4-r2, "uint", 1)
}



;AppBar_send( ABMsg, ByRef Hwnd="", CallbackMessage="", Edge="", Rect="", LParam="" ){
;	static ABM_NEW=0, ABM_REMOVE=1, ABM_QUERYPOS=2, ABM_SETPOS=3,ABM_GETSTATE=4, ABM_GETTASKBARPOS=5, ABM_ACTIVATE=6, ABM_GETAUTOHIDEBAR=7, , ABM_WINDOWPOSCHANGED=9, ABM_SETSTATE=10
;	static LEFT=0,TOP=1,RIGHT=2,BOTTOM=3, init
;
;	if !init 
;		init := VarSetCapacity(ABD,36,0), NumPut(36, ABD)
;	
;	IfEqual Hwnd, , SetEnv, Hwnd, % WinExist( "ahk_class Shell_TrayWnd" )
;	NumPut(Hwnd, ABD, 4)
;
;	CallbackMessage ? NumPut(CallbackMessage, ABD, 8) : 
;	LParam ? NumPut(LParam, ABD, 32) : 
;	Edge != "" ? NumPut(%Edge%, ABD, 12) : 
;	if (Rect != "") {
;		StringSplit, r, Rect, %A_Space%
;		loop, 4
;			NumPut(r%A_Index%, ABD, 12+A_Index*4, "Int")
;	}
;	msg := "ABM_" ABMsg
;	r := DllCall("Shell32.dll\SHAppBarMessage", "UInt", %msg%, "UInt", &ABD),
;	if ABMsg in QUERYPOS
;		Hwnd := &ABD
;	return r
;}

AppBar_Remove(Hwnd){
	AppBar_send("REMOVE", Hwnd)
}

/*	Function: SetTaskBar
			  Set state of the Taskbar.

	Parameters:
			State - "autohide", "ontop", "all". You can also remove (-), add (+) or toggle (^) state. Omit to disable all states.
					You can also pass "disable". This is the only good way to remove TaskBar (simply hiding the window isn't enough).					
					
	Return:
			Previous state. 

	Examples:
		(start code)
			Shell_SetTaskBar()				;remove all states of TaskBar
			Shell_SetTaskBar("+autohide")	;add autohide state
			Shell_SetTaskBar("-autohide")	;remove autohide state
			Shell_SetTaskBar("ontop")		;set state to ontop
			Shell_SetTaskBar("^ontop")		;toggle ontop state
			
			oldState := Shell_SetTaskBar("disable")		;disable it.
			Shell_SetTaskBar( oldState )				; & restore it when you are done ...
		(end code)
*/
AppBar_SetTaskBar(State=""){
	static ABM_SETSTATE=10, ABM_GETSTATE=4, AUTOHIDE=1, ONTOP=2, ALL=3, 1="AutoHide", 2="OnTop", 3="All"

	if (State="disable") {
		oldState := AppBar_SetTaskBar()
		WinHide, ahk_class Shell_TrayWnd
		return oldState
	}
		
	VarSetCapacity(ABD,36,0), NumPut(36, ABD), NumPut(Hwnd, ABD, 4)
	curState := DllCall("Shell32.dll\SHAppBarMessage", "UInt", ABM_GETSTATE, "UInt", &ABD)
	c := SubStr(State, 1, 1)
	if (bToggle :=  c = "^") || (bDisable := c = "-") || (c = "+")
		State := SubStr(State, 2), b := 1

	ifEqual, State, ,SetEnv, State, 0
	else State := %State%

	sd := curState & ~State, sa := curState | State
	if (b)
		State := bToggle ? (curState & State ? sd : sa) : bDisable ? sd : sa 
	NumPut(State, ABD, 32), DllCall("Shell32.dll\SHAppBarMessage", "UInt", ABM_SETSTATE, "UInt", &ABD)

	WinShow, ahk_class Shell_TrayWnd
	return (%curState%)
}

AppBar_send( ABMsg, ByRef Hwnd="", CallbackMessage="", Edge="", Rect="", LParam="" ){
	static ABM_NEW=0, ABM_REMOVE=1, ABM_QUERYPOS=2, ABM_SETPOS=3,ABM_GETSTATE=4, ABM_GETTASKBARPOS=5, ABM_ACTIVATE=6, ABM_GETAUTOHIDEBAR=7, ABM_SETAUTOHIDEBAR=8, ABM_WINDOWPOSCHANGED=9, ABM_SETSTATE=10
	static LEFT=0,TOP=1,RIGHT=2,BOTTOM=3, init

	if !init 
		init := VarSetCapacity(ABD,36,0), NumPut(36, ABD)
	
	IfEqual Hwnd, , SetEnv, Hwnd, % WinExist( "ahk_class Shell_TrayWnd" )
	NumPut(Hwnd, ABD, 4)

	CallbackMessage ? NumPut(CallbackMessage, ABD, 8) : 
	LParam ? NumPut(LParam, ABD, 32) : 
	Edge != "" ? NumPut(%Edge%, ABD, 12) : 
	if (Rect != "") {
		StringSplit, r, Rect, %A_Space%
		loop, 4
			NumPut(r%A_Index%, ABD, 12+A_Index*4, "Int")
	}
	msg := "ABM_" ABMsg
	r := DllCall("Shell32.dll\SHAppBarMessage", "UInt", %msg%, "UInt", &ABD),
	if ABMsg in QUERYPOS
		Hwnd := &ABD
	return r
}