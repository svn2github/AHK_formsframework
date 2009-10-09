_()
	hForm1	:=	Form_New("T w200 h500 Font='s8, Courier New' -Caption +ToolWindow")

	Form_Add(hForm1, "Edit", "ESC to hide F1 to show. F2 to resize. Drag picture to move.", "-vscroll w200 r3 0x8000", "Attach w", "Cursor hand")
	Form_Add(hForm1, "Picture", "res\test.bmp", "GuiMove", "Cursor size")

	Form_AutoSize(hForm1)
	Form_Show()
return

uiMove: 
	PostMessage, 0xA1, 2,,, A 
Return

F1::
	WinShow, ahk_id %hForm1%
	WInActivate, ahk_id %hForm1%
return

F2::
	WinSet, Style, ^0x40000, ahk_id %hForm1%
	Form_AutoSize(hForm1)
	Win_Redraw()
return

ESC::
	WinHide, ahk_id %hForm1%
return	

#include inc\Form.ahk
#include inc\Win.ahk
#include inc\Attach.ahk
#include inc\Cursor.ahk