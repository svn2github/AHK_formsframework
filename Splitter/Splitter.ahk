/*
 Title:    Splitter
			*Implementation of the Splitter control*
 :
			Both Windows and AHK don't have splitter control. 
			With this module you can add splitters to your GUIs. 
			
			(see splitter.gif)
 */

/*---------------------------------------------------------------------------------
 Function:	Add
 			Add new Splitter
 
 Parameters:
 			Opt	  - Splitter Gui options. Splitter is subclassed Text control (Static), so it accepts any Text options.
			Style - blackframe , blackrect , grayframe , grayrect , sunken , whiteframe , whiterect

 Returns:
			Splitter handle

 Remarks:
			This function adds a new splitter on the given position. User is responsible for correct position of the splitter.
			Splitter is inactive until you call <Set> function.

 */
Splitter_Add(Opt, Style="sunken", Text="") {
	static SS_NOTIFY=0x100, SS_BLACKFRAME = 7, SS_BLACKRECT = 4,SS_GRAYFRAME = 0x8, SS_GRAYRECT = 0x5, SS_SUNKEN = 0x1000, SS_WHITEFRAME = 9, SS_WHITERECT = 6

	Style := SS_%STYLE%	

	Opt .= Type = "hor" ? " h" Dim : " w" Dim
	Gui, Add, Text, HWNDhSep %opt% %Style% %SS_NOTIFY%, %Text%	
	return hSep
}

/*---------------------------------------------------------------------------------
 Function:	Set
 			Initiates separation of controls
 
 Parameters:
 			hSep - Splitter handle
			Def	 - Splitter definition. The syntax is:

 >		c11 c12 c13 ... Type c21 c22 c23 ...
		
		c1n - Controls left or top of the Splitter
		Type - Denotates Splitter type: " | " vertical or " - " horizontal
		c2n	- Controls right or bottom of the Splitter
							
 Returns:
		Splitter handle
 */
Splitter_Set( HSep, Def ) {
	type := InStr(Def, "|") ? "ver" : "hor"
	Splitter_wndProc(0, type, DEF, 0)
	Win_subclass(HSep, "Splitter_wndProc")
}


Splitter_wndProc(Hwnd, UMsg, WParam, LParam) {	
	static WM_SETCURSOR := 0x20, WM_MOUSEMOVE := 0x200, WM_LBUTTONDOWN=0x201, WM_LBUTTONUP=0x202, WM_LBUTTONDBLCLK=0x203
	static SIZENS := 32645,  SIZEWE := 32644
	static cursor, delta, moving, type, def

	if !Hwnd{
		type := Umsg, def := WParam, 
		cursor := DllCall("LoadCursor", "Uint", 0, "Int", type="hor" ? SIZENS : SIZEWE, "Uint")	
		return
	}
		
	If (UMsg = WM_SETCURSOR) 
	  return 1 

	if (UMsg =  WM_LBUTTONDBLCLK)
	{
		return	; move splitter to 0 or to max
	}
	
	if (UMsg = WM_MOUSEMOVE) {
		DllCall("SetCursor", "uint", cursor)
		if moving 
			Splitter_UpdateVisual(Hwnd, type)
	}

	if (UMsg = WM_LBUTTONDOWN)
	{
		DllCall("SetCapture", "uint", Hwnd)
		VarSetCapacity(RECT, 16)
		DllCall("GetWindowRect", "uint", DllCall("GetParent", "uint", Hwnd) , "uint", &RECT)

		sz := Win_GetRect(Hwnd,  type = "ver" ? "w" : "h") // 2			
		capy := Win_Get(DllCall("GetParent", "uint", Hwnd), "Nh" )		;get caption size of parent window

	  ;prevent user from going offscreen with separator
	  ; let the separator always be visible a little if it is pulled up to the edge
		NumPut( NumGet(Rect, 0) + sz	,RECT, 0)
		NumPut( NumGet(RECT, 4) + sz + capy	,RECT, 4)
		NumPut( NumGet(RECT, 8) - sz	,RECT, 8)
		NumPut( NumGet(RECT, 12)- sz	,RECT, 12)
		
		DllCall("ClipCursor", "uint", &RECT)
		DllCall("SetCursor", "uint", cursor)
		moving := true
	}
	if (UMsg = WM_LBUTTONUP)
	{
		delta := type = "hor" ? (LParam >> 16) : LParam & 0xFFFF
		if delta > 10000 
			delta -= 0xFFFF 

		DllCall("ClipCursor", "uint", 0),  DllCall("ReleaseCapture")
		
		DllCall("SetCursor", "uint", cursor)
		moving := false, Splitter_UpdateVisual()
		Splitter_move(Hwnd, type, delta, def)
	}

	return DllCall("CallWindowProc","uint",A_EventInfo,"uint",hwnd,"uint",uMsg,"uint",wParam,"uint",lParam)
}

Splitter_move(HSep, type, Delta, Def){
	static f := "Attach"
	Delta -= Win_GetRect(HSep,  type = "ver" ? "w" : "h") // 2
	j := InStr(Def, "|") or InStr(Def, "-")
	StringSplit, s, Def, %A_Space%
	
	if type = ver
		 v := Delta
	else h := Delta

	loop, %s0%
	{
		s := s%A_Index%
		if !otherSide
		{
			Win_MoveDelta(s, "", "", v, h, "R")
			if s in |,-
				otherSide := true, Win_MoveDelta(HSep, v, h, "", "", "R")
		} else 	Win_MoveDelta(s, v, h, -v, -h, "R")
	}		
					
	Win_Redraw(Win_Get(hSep, "A"))
	IsFunc(f) ? %f%(DllCall("GetParent", "uint", hSep, "Uint")) : 
}

Splitter_updateVisual( HSep="", Type="" ) {
	static sz, dc, RECT, parent

	if !HSep
		return dc := 0

	MouseGetPos, mx, my
	if !dc
	{
		capy := Win_Get(DllCall("GetParent", "uint", HSep), "Nh" )		;get caption size of parent window
		parent := DllCall("GetParent", "uint", HSep)
		dc := DllCall("GetDC", "uint", parent)
		VarSetCapacity(RECT, 16)
				
	 	DllCall("GetClientRect", "uint", parent, "uint", &RECT)
		sz := Win_GetRect(HSep, Type = "ver" ? "w" : "h") // 2


		my -= capy
		if (Type = "ver")
			 NumPut(mx-sz, RECT, 0),	 NumPut(mx+sz, RECT, 8)
		else NumPut(my-sz, RECT, 4),	 NumPut(my+sz, RECT, 12)

		DllCall("DrawFocusRect", "uint", dc, "uint", &RECT)	
		return
	}
	DllCall("DrawFocusRect", "uint", dc, "uint", &RECT)

	my -= capy
	if (Type = "ver")
		 NumPut(mx-sz, RECT, 0),	 NumPut(mx+sz, RECT, 8)
	else NumPut(my-sz, RECT, 4),	 NumPut(my+sz, RECT, 12)

	DllCall("DrawFocusRect", "uint", dc, "uint", &RECT)
}

#include Win.ahk

/* ---------------------------------------------------------------------------------
 Group: Example
 (start code)
		w := 500, h := 600, sep := 5
		w1 := w//3, w2 := w-w1 , h1 := h // 2, h2 := h // 3

		gui, margin, 0, 0
		gui, add, edit, HWNDc11 w%w1% h%h1%
		gui, add, edit, HWNDc12 w%w1% h%h1%
		hSepV := Splitter_Add( "x+0 y0 h" h " w" sep )
		gui, add, monthcal, HWNDc21 w%w2% h%h2% x+0
		gui, add, ListView, HWNDc22 w%w2% h%h2%, c1|c2|c3
		gui, add, ListBox, HWNDc23 w%w2% h%h2% , 1|2|3

		sdef = %c11% %c12% | %c21% %c22% %c23%
		Splitter_Set( hSepV, sdef )

		gui, show, w%w% h%h%	
	return

	#include Splitter.ahk
 (end code)
 */

/* ---------------------------------------------------------------------------------
 Group: About
	o Ver 1.0a by majkinetor. 
	o Licenced under Creative Commons Attribution-Noncommercial <http://creativecommons.org/licenses/by-nc/3.0/>.  

 */