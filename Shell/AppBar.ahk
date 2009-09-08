/*
	Title:	Appbar

			An application desktop toolbar (also called an appbar) is a window that is similar to the Microsoft Windows taskbar. 
			It is anchored to an edge of the screen, and it typically contains buttons that give the user quick access to other applications and windows. 
			The system prevents other applications from using the desktop area occupied by an appbar. 
			Any number of appbars can exist on the desktop at any given time.
 */

/* 
	Function:	New
				Creates new Appbar
	
	Parameters:
				Hwnd	- Reference to the handle of the existing window. If variable is empty, function will create Gui
						  and you will get its handle returned in this parameter. 
				o1..o9	- Named arguments. All named arguments are optional.

	Named Arguments:
				Edge	 - Screen edge to glue Appbar to. Possible values are "Top" (default), "Right", "Left", "Bottom". 
				AutoHide - Makes Appbar autohide (off by default). Value represents animation type. Can be 0, 1, "Slide", "Blend" or "Center".
						   Window will be shown only if mouse is its in hot area. When Appbar is activated, it will not auto hide
						   until its deactivated again. 
						   Without this argument, the space on screenwill be reserved for the Appbar and all other windows will not be able to maximize over it the same as with
						   Taskbar which is set ontop without autohide.
				Pos		 - Position. String similar to AHK format without X and Y and with p instead. For instance "w300 h30 p10". "p" 
						   means position and it represents X for Edge type Top/Bottom or Y for Edge type Left/Right. If "p" is omited
						   Appbar will be put in center. If "p" is negative, window is positioned the oposite end.
				Style	 - Space separted list of Appbar styles. See below.
				Label	 - Used when function creates Gui, and for making an AHK Group. By default Hwnd is added to the group. You can add
						   more windows in the group that are part of the taskbar. Appbar with autohide style will not be hidden when 
						   window belonging to its group is activated. By default "Appbar".

	Styles:	
				OnTop	 -  Sets the Appbar alaways on top.
				Show	 -  Show the Appbar. If not present the Appbar will not be shown or visibility settings of passed window will not be changed.
						    By default "OnTop Show Reserve".
				Pin		-   Pin the Appbar to the Desktop (reserve the destop space for the Appbar). 
							The system prevents other applications from using the screen area occupied by the appbar. Ignored with AutoHide.

  Returns:
				Gui number if function created Gui.
 */
Appbar_New(ByRef Hwnd, o1="", o2="", o3="", o4="", o5="", o6="", o7="", o8="", o9=""){
	static CALLBACKMSG := 12345, ABM_SETAUTOHIDEBAR=8, ABM_NEW=0

	oldDetect := A_DetectHiddenWIndows
	DetectHiddenWIndows, on

   ;- handle args ------------
	Edge:="Top", AutoHide := Show := 0, Style := "OnTop Show Pin", Label := "Appbar"
	loop, 9	{
		f := o%A_Index%
		ifEqual, f,,break
		j := InStr(f, "="), n := SubStr(f, 1, j-1), %n% := SubStr(f,j+1)
	}

	StringSplit, s, Style, %A_Space%
	loop, %s0%
		s := s%A_Index%, %s% := 1

	StringSplit, s, Pos, %A_Space%
	loop, %s0%
		d := SubStr(s%A_Index%, 1, 1),	%d% := SubStr(s%A_Index%, 2)
   ;--------------------------

	if (Hwnd = "") {
		k := 1
		while (k) {					;find available gui number
			n := 100 - A_Index
			Gui %k%:+LastFoundExist
			k := WinExist()
		}
		Gui, %n%:+LastFound -Caption +ToolWindow +Label%Label%
		Hwnd := WinExist()
	} else WinGetPos, x, y, w, h, ahk_id %Hwnd%	

	ifEqual, h, ,SetEnv, h, % Edge="Top"  || Edge="Bottom" ? 32 : A_ScreenHeight
	ifEqual, w, ,SetEnv, w, % Edge="Left" || Edge="Right"  ? 50 : A_ScreenWidth

	VarSetCapacity(ABD,36,0), NumPut(36, ABD), NumPut(Hwnd, ABD, 4), NumPut(CALLBACKMSG, ABD, 8) 
	if (AutoHide || !Pin)
		 r := DllCall("Shell32.dll\SHAppBarMessage", "UInt", ABM_SETAUTOHIDEBAR, "UInt", &ABD)
	else r := DllCall("Shell32.dll\SHAppBarMessage", "UInt", ABM_NEW, "UInt", &ABD)

	if OnTop
		WinSet, AlwaysOnTop, on, ahk_id %Hwnd%

	if !r {
		ifNotEqual, n,, Gui, %n%:Destroy
		return 0
	} 

	Appbar_setPos(Hwnd, Edge, w, h, p)
	if Show {
		WinShow, ahk_id %Hwnd%
		WinActivate, ahk_id %Hwnd%
	}
	
	GroupAdd, %Label%, ahk_id %Hwnd%
	if AutoHide
		Appbar_setAutoHideBar(Hwnd, Edge, AutoHide)

	DetectHiddenWIndows, %oldDetect%
	return n
}

Appbar_setAutoHideBar(Hwnd, Edge, AnimType){
	static timer := 500
	
	d1 := Edge="Top" ? "vpos" : Edge="Left" ? "hpos" : Edge ="Right" ? "hneg" : "vneg"
	d2 := Edge="Top" ? "vneg" : Edge="Left" ? "hneg" : Edge ="Right" ? "hpos" : "vpos"
	animOn := AnimType " " d1, animOff := AnimType " hide " d2
	
	oldDetect := A_DetectHiddenWIndows
	DetectHiddenWIndows, on
	WinGetPos, x, y, w, h, ahk_id %Hwnd%
	DetectHiddenWIndows, %oldDetect%

	Appbar_timer(Hwnd, Edge, animOn, animOff)
	SetTimer, %A_ThisFunc%, %timer%
	return
	
 Appbar_setAutoHideBar:
	Appbar_timer()
 return
}

Appbar_timer(Hwnd="", Edge="", Anim1="", Anim2="") {
	static 

	if (Hwnd != "") {
		if !SX
			VarSetCapacity(POINT, 8)
			,adrGetCursorPos := DllCall("GetProcAddress", uint, DllCall("GetModuleHandle", str, "user32"), str, "GetCursorPos")
			,SY := A_ScreenHeight - 5, SX := A_ScreenWidth - 5, 

		oldDetect := A_DetectHiddenWindows
		DetectHiddenWIndows, on
		WinGetPos, wx, wy, ww, wh, ahk_id %Hwnd%
		DetectHiddenWIndows, %oldDetect%

		bVisible := DllCall("IsWindowVisible", "uint", Hwnd)

		m(animOn := Anim1, animOff := Anim2)
		e := Edge="Top" || Edge="Left"									
		bVert := Edge="Left" || Edge="Right"

		d1 :=  bVert ? ww : wh,		d2 := bVert ? wh : ww				;d - dimension , widht or height depending on style
		v1 :=  bVert ? "x" : "y",	v2 := bVert ? "y" : "x"				;v - affected variable for autohide , x or y depending on style.
		pos1 := bVert ? wy : wx,	pos2:= pos1 + (bVert ? wh : ww)	    ;limits for variable v.
		Wnd := Hwnd
		w := width, h := height
	}

	ifWinActive ahk_group Appbar
		return
	DllCall(adrGetCursorPos, "uint", &POINT), x := NumGet(POINT), y := NumGet(POINT, 4)

	p := %v1%,  q := %v2%,	 dp := d1,  dq := d2,  Sp := S%v1%, Sq := S%v2%		;For TOP, p=mY, q=mX, d1=Width, d2=Height, Sp=SY, Sq=SX
	if ((e && p<5) || (!e && p>Sp-5))  && (q>pos1 && q<pos2)
		Win_Animate(Wnd, animOn), bVisible := true
	else if (bVisible) && (e && p>dp) || (!e && p<Sp-dp) || (q<pos1) || (q > pos2)
		Win_Animate(Wnd, animOff), bVisible := false

/*
	if (E="Top") {
		if (Y < 5) && (X>(W-Width//2) && X < (W+Width)//2)
			Win_Animate(H, animOn), visible := true
		else if  visible && (Y>Height) || !(X>(W-Width//2) && X < (W+Width)//2)
			Win_Animate(H, animOff)
	} 
	if (E="Left") {
		if (X < 5)  && (Y>(H-Height//2) && Y<(H+Height)//2
			 Win_Animate(H, animOn), visible := true
		else if (X>Width) && visible
			Win_Animate(H, animOff)
	}

	if (E="Bottom") 
		if (Y > SH - 5)	&& (X>(W-Width//2) && X < (W+Width)//2)
			 Win_Animate(H, animOn), visible := true
		else if visible && (Y < SY-Height) || (X> W-Width//2) && X < (W+Width)//2)
			Win_Animate(H, animOff)
	}

	if (E="Right") {
		if (X > SW - 5)	 
			 Win_Animate(H, animOn), visible := true
		else if (X < SW-30) && visible
			Win_Animate(H, animOff)
	}
 */
}

Appbar_setPos(Hwnd, Edge, Width, Height, Pos){
	static ABM_QUERYPOS=2, ABM_SETPOS=3, LEFT=0, TOP=1, RIGHT=2, BOTTOM=3

	H := A_ScreenHeight, W := A_ScreenWidth,  bVert := InStr("Left,Right", Edge)

	Height .= !Height ? H : ""
	Width  .= !Width  ? W : ""
	Pos	   .= !Pos	  ? bVert ? (H-Height)//2 : (W-Width)//2 : ""
	ifLess, Pos, 0, SetEnv, Pos, % bVert ? H + Pos : W + Pos
		
	VarSetCapacity(ABD,36,0), NumPut(36, ABD), NumPut(Hwnd, ABD, 4), NumPut(%Edge%, ABD, 12)
	if Edge = LEFT
		 r1 := 0, r2 := Pos, r3 := Width, r4 := r2 + Height
	else if Edge = RIGHT
		 r1 := W - Width, r2 := Pos, r3 := W, r4 := r2 + Height
	else if Edge = Top
		 r1 := Pos, r2 :=0, r3 := r1+Width, r4 := Height
	else r1 := Pos, r2 :=H-Height, r3 := r1+Width, r4 := H
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
	loop, 48
		NumPut(r%A_Index%, ABD, 12+A_Index*4, "Int") 

	DllCall("Shell32.dll\SHAppBarMessage", "UInt", ABM_SETPOS, "UInt", &ABD)
	DllCall("MoveWindow", "uint", Hwnd, "int", r1, "int", r2, "int", r3-r1, "int", r4-r2, "uint", 1)
}
/*	Function:	Remove
				Unregisters an appbar by removing it from the system's internal list. 
				The system no longer sends notification messages to the appbar or prevents other applications from using the screen area occupied 
				by the appbar.
 */
Appbar_Remove(Hwnd){
	static ABM_REMOVE=1
	VarSetCapacity(ABD,36,0), NumPut(36, ABD), NumPut(Hwnd, ABD, 4)
	DllCall("Shell32.dll\SHAppBarMessage", "UInt", ABM_REMOVE, "UInt", &ABD)
}

/*	Function: SetTaskBar
			  Set the state of the Taskbar.

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
Appbar_SetTaskBar(State=""){
	static ABM_SETSTATE=10, ABM_GETSTATE=4, AUTOHIDE=1, ONTOP=2, ALL=3, 1="AutoHide", 2="OnTop", 3="All"

	if (State="disable") {
		oldState := Appbar_SetTaskBar()
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

;Appbar_send( ABMsg, ByRef Hwnd="", CallbackMessage="", Edge="", Rect="", LParam="" ){
;	static ABM_NEW=0, ABM_REMOVE=1, ABM_QUERYPOS=2, ABM_SETPOS=3,ABM_GETSTATE=4, ABM_GETTASKBARPOS=5, ABM_ACTIVATE=6, ABM_GETAUTOHIDEBAR=7, ABM_SETAUTOHIDEBAR=8, ABM_WINDOWPOSCHANGED=9, ABM_SETSTATE=10
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

/* Group: About
	o v1.0 by majkinetor
	o Reference: <http://msdn.microsoft.com/en-us/library/cc144177(VS.85).aspx>
	o Licenced under GNU GPL <http://creativecommons.org/licenses/GPL/2.0/>
/*