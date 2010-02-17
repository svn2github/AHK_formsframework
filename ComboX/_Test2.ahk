#NoEnv
#SingleInstance Force  
SetBatchLines -1 
DetectHiddenWindows, on

	Gui, +LastFound  +Resize
	Gui, Add, Text, ,Choose Column to edit
	Gui, Add, DropDownList, gOnDropDown w200 vcbColumns HWNDhDropDown

	Gui, Font, s10
	Gui, Add, ListView, x w400 h300 hwndhLV gOnListView, Column 1|Column 2|Column 3
	Gui, Add, HotKey, hwndhED vvED, input1|input2|input3		;this will become ComboX 

	FillTheList() 
	FillTheCombo()

	ComboX_Set( hED, "esc enter", "OnComboX") 
	Attach(hLV, "w h r2")

	Gui, Show, autosize, ComboX In Cell Editing Test 
return 

SetComboPosition(HwndLV, HwndCombo) {
	global gColNumber

	Win_GetRect(HwndLv, "xywh", lx, ly, lw, lh)
	LV_ItemRect(HwndLV, LV_GetNext(), i1, i2, i3, i4)

	x := 0
	loop, % gColNumber - 1
		x += LV_ColumnWidth(HwndLV, A_Index)
	w := LV_ColumnWidth(HwndLV, gColNumber)

	x := lx+x+1,  y := ly+i2+1,  h := i4-i2
	Win_Move(HwndCombo,x,y,w,h)
}

ShowCombo(){
	global
	
	LV_GetText(txt, LV_GetNext(), gColNumber)
	SetComboPosition(hLV, hEd)
	ComboX_Show(hEd)
	ControlSetText,,%txt%, ahk_id %hEd%
	SendInput {End}^a
}

OnComboX(Hwnd, Event) { 
	if (Event != "select") 
		return

	LV_SetColumnValue()
} 

OnListView: 
	IF A_GuiControlEvent = DoubleClick 
		ShowCombo() 
return 

OnDropDown:
	GuiControlGet, gColNumber,, cbColumns
	ControlGet, gColNumber, FindString, %gColNumber%,,ahk_id %hDropDown%
return


FillTheList() {    
	loop, 10
	    LV_Add("", "Value 1." A_Index, "Longer Value 2." A_Index, "Some Slightly Longer Value 3." A_Index, A_Index) 
  
	loop, 3
	    LV_ModifyCol(A_Index,"Auto") 
} 

FillTheCombo() {
	global gColNumber

	loop, % gColNumber := LV_GetCount("Column")
		LV_GetText(txt, 0, A_Index), res .= txt "|"

	GuiControl, ,cbColumns, %res%|
}

;====================================================================================================

LV_SetColumnValue() {
	global 

	ControlGetText, value, , ahk_id %hED%	
	LV_Modify(LV_GetNext(), "Col" gColNumber , value) 
}

LV_ColumnWidth(HwndLV, Col=1) {
	static LVM_GETCOLUMNWIDTH=4125
	SendMessage, LVM_GETCOLUMNWIDTH, Col-1,,,ahk_id %HwndLV%
	return ErrorLevel
}

LV_ItemRect(HwndLV, Row, ByRef p1, ByRef p2, ByRef p3, ByRef p4) {
	static LVM_GETITEMRECT=4110

	VarSetCapacity(RECT, 16, 0), NumPut(3, RECT)
	SendMessage, LVM_GETITEMRECT, Row-1, &RECT,, ahk_id %HwndLv%
	res := ErrorLevel
	loop, 4
		p%A_Index% := NumGet(RECT, A_Index*4-4)
	return ErrorLevel
}

#include ComboX.ahk
#include inc\Attach.ahk   ;sample include