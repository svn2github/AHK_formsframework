_()
	hForm1	:=	Form_New("w400 m0.0 e3 h500 Font='s8, Courier New'")
	Form_Add(hForm1, "Edit", "ESC to hide F1 to show. F2 to resize. Drag picture to move.", "-vscroll w200 r3 0x8000", "Cursor hand")
	Form_Add(hForm1, "Picture", "res\test.bmp", "gPictureDrag", "Cursor size")

	Form_AutoSize( hForm1 )
	Form_Show()
return

PictureDrag: 
	PostMessage, 0xA1, 2,,, A 
Return

F1:: 
	WinShow, ahk_id %hForm1%
	WinActivate, ahk_id %hForm1%
return

F2::
	WinSet, Style, ^0x40000, ahk_id %hForm1%
	Form_AutoSize(hForm1)
	Win_Redraw()
return

#include inc\Form.ahk
#include inc\Win.ahk
#include inc\Attach.ahk
#include inc\Cursor.ahk