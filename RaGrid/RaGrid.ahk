/* Title: RaGrid
		  Advanced grid custom control.
 */

/*
 Function:	Add
			Create control.
 
 Parameters:
			X..H	- Position of the control.
			Style	- Space separated list of control styles, by default both scroll bars are visible. You can use numbers or style strings.
			Handler	- Notification events handler. 
			DllPath	- Path of the control dll, by default control is searched in the current folder.		

 Styles: 
			NOSEL, NOFOCUS, HGRIDLINES, VGRIDLINES, GRIDLINES, GRIDFRAME, NOCOLSIZE.

 Handler:
 >     	Result := Handler(HCtrl, Event, EventInfo, Col, Row )

		HCtrl	- Control sending the event.
		Event   - Specifies event that occurred. Event must be registered to be able to monitor it. 
		Col,Row - Cell coordinates.
		Result  - Return 1 to prevent action.

 Events:
         Headerclick	 - Sent when user clicks header. 
         Buttonclick	 - Sent when user clicks the button in a button cell. 
         Checkclick		 - Sent when user double clicks the checkbox in a checkbox cell. 
         Imageclick		 - Sent when user double clicks the image in an image cell. 
         Beforeselchange - Sent when user request a selection change. 
         Afterselchange  - Sent after a selection change. 
         Beforeedit		 - Sent before the cell edit control shows. 
         Afteredit		 - Sent when the cell edit control is about to close. 
         Beforeupdate	 - Sent before a cell updates grid data. 
         Afterupdate	 - Sent after grid data has been updated. 
         Userconvert	 - Sent when user cell needs to be converted.  

 Returns:
		Control's handle.
  
 */
RG_Add(HParent,X,Y,W,H, Style="", Handler="", DllPath=""){
	static	WS_VISIBLE=0x10000000, WS_CHILD=0x40000000
	static	NOSEL=0x1, NOFOCUS=0x2, HGRIDLINES=0x4, VGRIDLINES=0x8,GRIDLINES=12, GRIDFRAME=0x10, NOCOLSIZE=0x20, MODULEID

	hStyle := 0
	loop, parse, style, %A_Tab%%A_Space%
		IfEqual, A_LoopField, , continue
		else hStyle |= %A_LOOPFIELD%
	
	if !MODULEID {
		ifEqual, DllPath, ,SetEnv, DllPath, RAGrid.dll
		DllCall("LoadLibrary", "Str", DllPath)

		old := OnMessage(0x4E, "RG_onNotify"),	MODULEID := 300909
		if old != RG_onNotify
			RG("oldNotify", RegisterCallback(old))
	}

	hCtrl := DllCall("CreateWindowEx"
      , "Uint", 0x200       ; WS_EX_CLIENTEDGE
      , "str",  "RAGrid"    ; ClassName
      , "str",  ""	        ; WindowName
      , "Uint", WS_CHILD | WS_VISIBLE | hStyle
      , "int",  X            ; Left
      , "int",  Y            ; Top
      , "int",  W            ; Width
      , "int",  H            ; Height
      , "Uint", HParent      ; hWndParent
      , "Uint", MODULEID     ; hMenu
      , "Uint", 0            ; hInstance
      , "Uint", 0, "Uint")

	if IsFunc(Handler)
		RG(hCtrl "Handler", Handler)

	return hCtrl
}

/*
 Function:	AddColumn
			Add column.
 
 Parameters:
			o1..o7	- Named parameters.

 Named Parameters:
			type	- Column data type. See bellow list of types.
			w		- Width.
			txt		- Column caption.
			txtmax	- Max text lenght for EDITTEXT and EDITLONG types.
			hdral	- Header text alignment. Number, LEFT=0, CENTER=1, RIGHT=2
			txtal	- Column text alignment.
			sort	- Sort type. Number, ASC=0, DES=1, INVERT=2.
			il		- Handle of the image list. For the image columns and combobox only.
			format	- Format string for the EDITLONG type.

 Types:
			EDITTEXT, EDITLONG, CHECKBOX, COMBOBOX, BUTTON, EDITBUTTON, HOTKEY, IMAGE, DATE, TIME, USER.
 */
RG_AddColumn(hGrd, o1="", o2="", o3="", o4="", o5="", o6="", o7=""){
	static GM_ADDCOL=0x401, ;ASC=0, DES=1, INVERT=2,  LEFT=0, CENTER=1, RIGHT=2

	if !init
		init := VarSetCapacity(COL, 48) 

	type := "EDITTEXT"
	loop, 7 {
		ifEqual, o%A_Index%,,break
		else j := InStr( o%A_index%, "=" ), p := SubStr(o%A_index%, 1, j-1 ), %p% := SubStr( o%A_index%, j+1)
	}		
	hType := RG_getType(type)
                                                 
	 NumPut(w, COL, 0)
	 , NumPut(&txt,		COL, 4)
	 , NumPut(hdral,	COL, 8)
	 , NumPut(txtal,	COL, 12)
	 , NumPut(htype,	COL, 16)
	 , NumPut(txtmax,	COL, 20)
	 , NumPut(&format,	COL, 24)
	 , NumPut(il,		COL, 28)
	 , NumPut(sort,		COL, 32)
	 , NumPut(data	,	COL, 44)
															 	
	SendMessage,GM_ADDCOL,,&COL,, ahk_id %hGrd%
	return ErrorLevel										 
}

/*															 
 Function:	AddRow											 
			Add row.
 															 
 Parameters:		
			Row		- Row number. If omitted, row is appended.
			c1..c10	- Column values.

 */
RG_AddRow(hGrd, Row="", c1="", c2="", c3="", c4="", c5="", c6="", c7="", c8="", c9="", c10=""){ 
	static GM_ADDROW=0x402, GM_INSROW=0x403		;wParam=nRow, lParam=lpROWDATA (can be NULL)

	VarSetCapacity(ROWDATA, 40, 0)
	Loop, 10
	{
		ifEqual,c%A_Index%,,continue
		idx := A_Index*4 - 4

		type := RG_GetColumn(hGrd, A_Index)
		if type in COMBOBOX,CHECKBOX,EDITLONG,IMAGE
			 NumPut(c%A_Index%,  ROWDATA, idx)
		else NumPut(&c%A_Index%, ROWDATA, idx)
	}

	if (Row = "")
			SendMessage,GM_ADDROW,0,&ROWDATA,, ahk_id %hGrd% 
	else	SendMessage,GM_INSROW,Row-1,&ROWDATA,, ahk_id %hGrd%  
	return ErrorLevel 
}

/*
 Function:	ComboAddString
			Populate combo box.
 
 Parameters:
			Col		- Column number.
			Items	- "|" separated list of items.

 Returns:
  
 */
RG_ComboAddString(hGrd, Col, Items) {
	static GM_COMBOADDSTRING=0x406	;wParam=nCol, lParam=lpszString

	Col -= 1
	loop, parse, Items, |
		SendMessage, GM_COMBOADDSTRING, Col, &(s:=A_LoopField),, ahk_id %hGrd%
}
/*
 Function:	ComboClear
			Clear combo box.
 */
RG_ComboClear(hGrd, Col) {
	static GM_COMBOCLEAR=0x407	;wParam=nCol, lParam=0
	SendMessage, GM_COMBOCLEAR, Co-1l,,, ahk_id %hGrd%
	return ErrorLevel
}

/*
 Function:	EnterEdit
			Edit cell.

 Parameters:
			Col, Row	- Cell coordinates. If omitted, currently selected row/col is used.
 */
RG_EnterEdit(hGrd, Col="", Row="") {
	static GM_ENTEREDIT=0x41A		;wParam=nCol, lParam=nRow

	if (Col Row = "")
		RG_GetCurrentCell(hGrd, Col, Row)
	SendMessage, GM_ENTEREDIT,Col-1,Row-1,, ahk_id %hGrd% 
	return ErrorLevel 
}

/*
 Function:	DeleteRow
			Delete row.
 
 Parameters:
			Row - 1 based row index. Of omited, current row is deleted.
 */
RG_DeleteRow(hGrd, Row="") {
	static GM_DELROW=0x404		;wParam=nRow, lParam=0

	ifEqual, Row,, SetEnv, Row, % RG_GetCurrentRow(hGrd)
	SendMessage, GM_DELROW, Row-1,,, ahk_id %hGrd% 
	return ErrorLevel 
}

/*
 Function:	GetCell
			Get cell value.
 */
RG_GetCell(hGrd, Col="", Row="") {
	static GM_GETCELLDATA=0x410, BUF, init		;wParam=nRowCol, lParam=lpData


	if !init
		init := VarSetCapacity(BUF, 256)
	
	if (Col="" && Row="")
		RG_GetCurrentCell(hGrd, Col, Row)
	
	Col-=1, Row-=1

	m(col, row)
	type := RG_GetColumn(hGrd, Col+1, "type")
	SendMessage, GM_GETCELLDATA, (Row << 16) + Col, &BUF,, ahk_id %hGrd%
	
	if type in COMBOBOX,CHECKBOX,EDITLONG,IMAGE,HOTKEY,DATE,TIME
		 return NumGet(BUF, 0, "Int")		
	else return BUF
}

/*
 Function:	GetColCount
			Returns number of columnns.
 */
RG_GetColCount(hGrd) {
	static GM_GETCOLCOUNT=0x40E
	SendMessage,GM_GETCOLCOUNT,,,,ahk_id %hGrd% 
	return ErrorLevel 
}

/*
 Function:	GetColWidth
			Get column width. 
 */
RG_GetColWidth(hGrd, Col) {		;wParam=nCol, lParam=0
	static GM_GETCOLWIDTH=0x41C
	SendMessage,GM_GETCOLWIDTH,Col-1,,,ahk_id %hGrd% 
	return ErrorLevel 
}

/*
 Function:	GetColors
			Get colors.
 
 Parameters:
			pQ		- Query parameter, string of color types to get.
			o1..o3	- Reference to output variables.

 Returns:
			o1.
 */
RG_GetColors(hGrd, pQ, ByRef o1="", ByRef o2="", ByRef o3=""){
	static GM_B=0x414, GM_G=0x416, GM_F=0x418
	
	loop, parse, pQ	
	{	
		SendMessage,GM_%A_Index%,,,,ahk_id %hGrd%
		o%A_Index% := ErrorLevel
	}
	return o1
}

/*
 Function:	GetColumn
			Get column parameters.
 
 Parameters:
			Col		- 1 based column number.
			pQ		- Query parameter. Space separated list of named parameters. See <AddColumn> for details. By default, type is returned.
			o1..o7	- Reference to output variables.

 Returns:
			o1
 */
RG_GetColumn(hGrd, Col, pQ="type", ByRef o1="", ByRef o2="", ByRef o3="", ByRef o4="", ByRef o5="", ByRef o6="", ByRef o7="") {
	static GM_GETCOLDATA = 1068, init, COLUMN		;wParam=nCol, lParam=lpCOLUMN
		   , w=0, txt=4, hdral=8, txtal=12, type=16, txtmax=20, format=24, il=28, sort=32, data=44

	if !init
		init := VarSetCapacity(COLUMN, 48)  

	SendMessage,GM_GETCOLDATA, Col-1, &COLUMN,, ahk_id %hGrd%
	loop, parse, pQ, %A_Space% 
	{
		o%A_Index% := NumGet(COLUMN, %A_LoopField%)
		if A_LoopField in txt,format
			o%A_Index% := RG_strAtAdr(o%A_Index%)
		else if A_LoopField = type
			o%A_Index% := RG_getType(o%A_Index%)
	}

	return o1
}

/*
	Function:	GetCurrentCell
				Get current cell.

	Parameters:
				Col, Row - Reference to variables to receive output.
  */
RG_GetCurrentCell(hGrd, ByRef Col, ByRef Row) {
	static GM_GETCURSEL=0x408	
	SendMessage, GM_GETCURSEL,,,, ahk_id %hGrd%
	Row := (ErrorLevel >> 16) + 1,  Col := (ErrorLevel & 0xFFFF) + 1
}

/*
	Function:	GetCurrentCol
				Get current column . 
  */
RG_GetCurrentCol(hGrd) {	
	static GM_GETCURCOL=0x40A
	SendMessage, GM_GETCURCOL,,,, ahk_id %hGrd%
	return ERRORLEVEL + 1
}
/*
 Function:	GetCurrentRow
			Get currently selected row. 
 */
RG_GetCurrentRow(hGrd) {
	static GM_GETCURROW=0x40C
	SendMessage,GM_GETCURROW,,,,ahk_id %hGrd% 
	return ErrorLevel + 1
}
														 
/*
	Function: GetHdrHeight
			  Get height of the header row.
  */
RG_GetHdrHeight(hGrd) {		
	static GM_GETHDRHEIGHT=0x41E
	SendMessage,GM_GETHDRHEIGHT,,,, ahk_id %hGrd% 
	return ErrorLevel 
}

/*
 Function:	GetRowColor
			Get row color.
 
 Parameters:
			Row	- Row number. If omitted current row will be used.
			B,F	- Background, foreground color.
 */
RG_GetRowColor(hGrd, Row="", ByRef B="", ByRef F="") {	;wParam=nRow, lParam=lpROWCOLOR
	static GM_GETROWCOLOR=0x42C

	VarSetCapacity(RC, 8)
	SendMessage, GM_GETROWCOLOR, Row-1, &RC,,ahk_id %hGrd%
	B := NumGet(RC), F := NumPut(RC, 4)
}

/*
	Function: GetRowHeight
			  Get height of the row.
  */
RG_GetRowHeight(hGrd){		
	static GM_GETROWHEIGHT=0x420
	SendMessage,GM_GETROWHEIGHT,,,, ahk_id %hGrd%
	return ErrorLevel
}

/*
 Function: GetRowCount
		   Returns number of rows.

 */
RG_GetRowCount(hGrd) {
	static GM_GETROWCOUNT=0x40F		;wParam=0, lParam=0
	SendMessage,GM_GETROWCOUNT,,,,ahk_id %hGrd% 
	return ErrorLevel 
}

/*
 Function:	MoveRow
			Move row.
 
 Parameters:
			From - Number of the row to move.
			To	 - New position of the row. 
 */
RG_MoveRow(hGrd, From, To ){
	static GM_MOVEROW=0x405
	SendMessage,GM_MOVEROW,From-1,To-1,, ahk_id %hGrd% 
	return ErrorLevel 
}

/*
	Function: ResetContent
			  Reset content of the control.
  */
RG_ResetContent(hGrd) {
	static GM_RESETCONTENT=0x422
	SendMessage,GM_RESETCONTENT,,,, ahk_id %hGrd%
	return ErrorLevel
}

/*
	Function: ScrollCell
			  Scrolls current cell into view.
  */
RG_ScrollCell(hGrd){
	static GM_SCROLLCELL=0x413	;wParam=0, lParam=0
	SendMessage,GM_SCROLLCELL,,,, ahk_id %hGrd% 
	return ErrorLevel
}

/*
 Function:	SetCell
			Set cell value.
 */
RG_SetCell(hGrd, Col, Row, Value="") {
	static GM_SETCELLDATA=0x411		;wParam=nRowCol, lParam=lpData (can be NULL)

	type := RG_GetColumn(hGrd, Col)
	if type in COMBOBOX,CHECKBOX,EDITLONG
		NumPut(Value, Value)

	Row-=1, Col-=1
	SendMessage, GM_SETCELLDATA, (Row<<16)+Col, &Value,, ahk_id %hGrd%
	return ErrorLevel
}

/*
 Function:	SetColors
			Set colors.
 
 Parameters:
			Colors	- Space separated string of the color types and values. Possible types are B (background color), F (foreground color) and G (grid color).
 */
RG_SetColors(hGrd, Colors){
	static GM_SETBACKCOLOR=0x415, GM_SETGRIDCOLOR=0x417, GM_SETTEXTCOLOR=0x419

	Loop, Parse, colors, %A_Space%
		c := SubStr(A_LoopField, 1, 1), val := SubStr(A_LoopField, 2),  %c% := val

	ifNotEqual, B,, SendMessage,GM_SETBACKCOLOR,B,,, ahk_id %hGrd%
	ifNotEqual, G,, SendMessage,GM_SETGRIDCOLOR,G,,, ahk_id %hGrd%
	ifNotEqual, F,, SendMessage,GM_SETTEXTCOLOR,F,,, ahk_id %hGrd%
}

/*
	Function: SetColWidth
			  Set column width.
  */
RG_SetColWidth(hGrd, Col, Width) {		;wParam=nCol, lParam=nWidth
	static GM_GETCOLWIDTH=0x41D
	SendMessage,GM_GETCOLWIDTH,Col-1,Width,, ahk_id %hGrd% 
	return ErrorLevel 
}

/*
 Function:	SetCurrentRow
			Set currently selected row. 
 */
RG_SetCurrentRow(hGrd, Row) {		;wParam=nRow, lParam=0
	static GM_SETCURROW=0x40D
	SendMessage,GM_SETCURROW,Row-1,,, ahk_id %hGrd% 
	return ErrorLevel 
}

/*
	Function: SetCurrentCol
			  Set current column.
  */
RG_SetCurrentCol(hGrd, Col) {		;wParam=nCol, lParam=0
	static GM_SETCURCOL=0x40B
	SendMessage, GM_SETCURCOL,Col-1,,,ahk_id %hGrd%
	return ERRORLEVEL
}

/*
	Function:	SetCurrentCell
				Set current cell.

	Parameters:
				Col, Row	- Coordinates of the cell to select.
  */
RG_SetCurrentSel(hGrd, Col, Row) {	;wParam=nCol, lParam=nRow
	static GM_SETCURSEL=0x409
	SendMessage, GM_SETCURSEL, Col, Row,, ahk_id %hGrd%
	return ERRORLEVEL
}

/*
 Function: SetFont
			Sets the control font.

 Parameters:
			pFont	- AHK font definition: "Style, FontName"
 */
RG_SetFont(hGrd, pFont="") { 
   static WM_SETFONT := 0x30
 ;parse font 
   italic      := InStr(pFont, "italic")    ?  1    :  0 
   underline   := InStr(pFont, "underline") ?  1    :  0 
   strikeout   := InStr(pFont, "strikeout") ?  1    :  0 
   weight      := InStr(pFont, "bold")      ? 700   : 400 
 ;height 
   RegExMatch(pFont, "(?<=[S|s])(\d{1,2})(?=[ ,])", height) 
   if (height = "") 
      height := 10 
   RegRead, LogPixels, HKEY_LOCAL_MACHINE, SOFTWARE\Microsoft\Windows NT\CurrentVersion\FontDPI, LogPixels 
   height := -DllCall("MulDiv", "int", Height, "int", LogPixels, "int", 72) 
 ;face 
   RegExMatch(pFont, "(?<=,).+", fontFace)    
   if (fontFace != "") 
       fontFace := RegExReplace( fontFace, "(^\s*)|(\s*$)")      ;trim 
   else fontFace := "MS Sans Serif" 
 ;create font 
   hFont   := DllCall("CreateFont", "int",  height, "int",  0, "int",  0, "int", 0 
                      ,"int",  weight,   "Uint", italic,   "Uint", underline 
                      ,"uint", strikeOut, "Uint", nCharSet, "Uint", 0, "Uint", 0, "Uint", 0, "Uint", 0, "str", fontFace) 
   SendMessage,WM_SETFONT,hFont,TRUE,,ahk_id %hGrd%
   return ErrorLevel
}

/*
	Function: SetHdrHeight
			  Set height of the header row.
  */
RG_SetHdrHeight(hGrd, Height){
	static GM_SETHDRHEIGHT=0x41F
	SendMessage,GM_SETHDRHEIGHT,,Height,, ahk_id %hGrd%
	return ErrorLevel
}

/*
 Function:	SetRowColor
			Set row color.
 
 Parameters:
			Row	- Row number. If omitted current row will be used.
			B,F	- Background, foreground color, by default b/w.
 */
RG_SetRowColor(hGrd, Row="", B="", F="") { ;wParam=nRow, lParam=lpROWCOLOR
	static GM_SETROWCOLOR=0x42B

	ifEqual, Row,, SetEnv, Row, % RG_GetCurrentRow(hGrd)
	ifEqual, B,, SetEnv, B, 0xFFFFFF
	VarSetCapacity(RC, 8), NumPut(B, RC), NumPut(F, RC, 4)
	SendMessage, GM_SETROWCOLOR, Row-1, &RC,,ahk_id %hGrd%
	return ERRORLEVEL
}

/*
	Function: SetRowHeight
			  Set height of the row.
  */
RG_SetRowHeight(hGrd, Height){		
	static GM_SETROWHEIGHT=0x421
	SendMessage,GM_SETROWHEIGHT,,Height,, ahk_id %hGrd%
	return ErrorLevel
}

/*
 Function:	Sort
			Sort column.

 Parameters:
			SortType - Number, 1 (ASC), 2 (DES), 3 (INVERT)
 */
RG_Sort(hGrd, Col, SortType){
	static GM_COLUMNSORT=0x423
	SendMessage,GM_COLUMNSORT,Col-1,SortType,,ahk_id %hGrd%
}

;======================================= PRIVATE =================================
RG_getType( Type ) {
	static EDITTEXT=0, EDITLONG=1, CHECKBOX=2, COMBOBOX=3, HOTKEY=4, BUTTON=5, IMAGE=6, DATE=7, TIME=8, USER=9, EDITBUTTON=10
		  ,0="EDITTEXT",1="EDITLONG",2="CHECKBOX",3="COMBOBOX",4="HOTKEY",5="BUTTON",6="IMAGE",7="DATE",8="TIME",9="USER",10="EDITBUTTON"

	return (%Type%)
}

RG_onNotify(Wparam, Lparam, Msg, Hwnd) { 
	static MODULEID = 300909, oldNotify="*" 
		  ,GN_HEADERCLICK=0x1,GN_BUTTONCLICK=0x2,GN_CHECKCLICK=0x3,GN_IMAGECLICK=0x4, GN_BEFORESELCHANGE=0x5,GN_AFTERSELCHANGE=0x6,GN_BEFOREEDIT=0x7,GN_AFTEREDIT=0x8,GN_BEFOREUPDATE=0x9,GN_AFTERUPDATE=0xa,GN_USERCONVERT=0xb 

	if (_ := (NumGet(Lparam+4))) != MODULEID
	 ifLess _, 10000, return	;if ahk control, return asap (AHK increments control ID starting from 1. Custom controls use IDs > 10000 as its unlikely that u will use more then 10K ahk controls.
	 else {
		ifEqual, oldNotify, *, SetEnv, oldNotify, % RG("oldNotify")		
		if oldNotify !=
			return DllCall(oldNotify, "uint", Wparam, "uint", Lparam, "uint", Msg, "uint", Hwnd)
		return
	 }
    
   	hw :=  NumGet(Lparam+0), code := NumGet(Lparam+8),  handler := RG(hw "Handler") 
	ifEqual, handler,, return

	
	col := NumGet(Lparam+12)+1, row := NumGet(Lparam+16)+1, data := NumGet(Lparam+24)

	if (code = GN_HEADERCLICK) 
		return %handler%(hw, "HeaderClick", col, "")

	if (code = GN_BUTTONCLICK)
		return %handler%(hw, "ButtonClick", col, row, data)

	if (code = GN_CHECKCLICK)
		return %handler%(hw, "CheckClick", col, row, data)

	if (code = GN_IMAGECLICK) 
		return %handler%(hw, "ImageClick", col, row, data)
      
    if (code = GN_BEFORESELCHANGE) {
		if RG( hw "LastSel" ) = col " " row
			return NumPut(1, LParam+28)

		else RG( hw "LastSel", col " " row )
		r := %handler%(hw, "SelChange", col, row)				
	}

	if (code = GN_AFTERSELCHANGE) { 
		if RG( hw "AfterLastSel" ) = col " " row
			return
		else RG( hw "AfterLastSel", col " " row )
   		r := %handler%(hw, "Afterselchange", col, row)
	} 

	if (code = GN_BEFOREEDIT)
		r := %handler%(hw, "Beforeedit", col, row, data)

	if (code = GN_AFTEREDIT)
		return %handler%(hw, "Afteredit", col, row, data)

    if (code = GN_BEFOREUPDATE) 
		r := %handler%(hw, "Beforeupdate", col, row, data)

    if (code = GN_AFTERUPDATE)
		return %handler%(hw, "Afterupdate", col, row, data)

	NumPut(r, LParam+28)
}

;Storage
RG(var="", value="~`a", ByRef o1="", ByRef o2="", ByRef o3="", ByRef o4="", ByRef o5="", ByRef o6="") { 
	static
	if (var = "" ){
		if ( _ := InStr(value, ")") )
			__ := SubStr(value, 1, _-1), value := SubStr(value, _+1)
		loop, parse, value, %A_Space%
			_ := %__%%A_LoopField%,  o%A_Index% := _ != "" ? _ : %A_LoopField%
		return
	} else _ := %var%
	ifNotEqual, value, ~`a, SetEnv, %var%, %value%
	return _
}

RG_strAtAdr(adr) { 
   Return DllCall("MulDiv", "Int",adr, "Int",1, "Int",1, "str")
}

;Required function by Forms framework.
RaGrid_add2Form(hParent, Txt, Opt) {
	static f := "Form_Parse"
	%f%(Opt, "x# y# w# h# style dllPath g*", x, y, w, h, style, dllPath, handler)
	return RG_Add(hParent, x, y, w, h, style, handler, dllPath)
}

/* Group: About
	o RaGrid control version: 2.0.1.6 by KetilO. See <http://www.masm32.com/board/index.php?topic=55>
	o AHK module ver 2.0.1.6-1 by majkinetor.
	o Licenced under BSD <http://creativecommons.org/licenses/BSD/>.
 */