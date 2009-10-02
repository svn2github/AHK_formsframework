#SingleInstance, force

	ssize	:= 30			;splitter size
	spos	:= 100			;initial position

	;=========================================

	pos := Win_Recall("<", 0, "config.ini")
	if (pos != "") {	
			StringSplit, p, pos, %A_Space%
			x:= p1, y:=p2,  w:=p6,  h:=p7
	} else 	x:=y:="Center", w:=600, h:=500

	h1 := spos,	 h2 := h-h1-ssize
	gui, margin, 0, 0
	Gui +Resize +LastFound ;-Caption
	hGui := WinExist()

	gui, add, edit, HWNDhc1 w%w% h%h1%, ESC - exit and save window.`nF1 - Set splitter position to 40
	hSep := Splitter_Add("h" ssize " w" w " center sunken", "drag me", "OnSplitter")
	w1 := w//2
	gui, add, monthcal, HWNDhc2 w%w1% h%h2%
	gui, add, monthcal, HWNDhc3 x+0 w%w1% h%h2%

	IniRead, spos, config.ini, Config, Splitter, %A_Space%
	Splitter_Set( hSep, hc1 " - " hc2 " " hc3, spos)

	Attach( hc1,  "w h r2")
	Attach( hSep, "y w r2")
	Attach( hc2,  "y w.5 r2")
	Attach( hc3,  "y x.5 w.5 r2")
	
	Gui, Show, x%x% y%y% w%w% h%h%
return

OnSplitter(HCtrl, Pos){
	txt = position: %pos%
	ControlSetText, ,%txt%, ahk_id %HCtrl%
}

F1::
	Splitter_SetPos(hSep, 40)
return

Esc:: 
GuiClose:
	Win_Recall(">", "", "config.ini")
	p := Splitter_GetPos(hSep)
	IniWrite, %p%, config.ini, Config, Splitter
	ExitApp
return

#include Splitter.ahk

#include inc
#include Attach.ahk
#include Win.ahk