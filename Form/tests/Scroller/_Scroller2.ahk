_()
    w := 500, h := 400
    hForm  := Form_New("Resize e3 w500 h400")


    hToolbar := Form_Add(hForm, "Toolbar", "", "gOnToolbar style=flat il=3")
    hPanel   := Form_Add(hForm, "Panel", "", "x5 y50 w" w-15 " h" h-55, "Attach w h")

    Loop, 10
        Form_Add(hPanel, "Edit", "Edit " A_Index, "vscroll R5 H100 W200", "Attach h w")

    Toolbar_Insert(hToolbar, "cut`ncopy`npaste`nredo`nundo")

    Panel_SetStyle(hPanel, "scroll")
    Form_Show()
return 


Form1_Close:
    ExitApp
return

#include ..\..\inc
#include _Forms.ahk