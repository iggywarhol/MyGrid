;- MyEdit PB Module 
; offers an editing area within a canvas-gadget similar to a string gadget (one line Edit)
; all coordinates are relative to the parent canvas gadget
DeclareModule MyEdit
    Enumeration
        #MyEdit_BackColor
        #MyEdit_TextColor
        #MyEdit_SelectionBackColor
        #MyEdit_SelectionTextColor
        #MyEdit_CaretColor
        #MyEdit_Align
        #MyEdit_ReadOnly
        #MyEdit_LineSpacing
    EndEnumeration
        
    #MyEdit_FirstCaretPos = 0
    #MyEdit_LastCaretPos  = -1
    
    Declare.i   ManageEvent(Edit.i, eType)
    Declare.i   Resize(Edit.i, X = #PB_Ignore, Y = #PB_Ignore, W = #PB_Ignore, H = #PB_Ignore)
    Declare.s   GetText(Edit)
    Declare.i   SetText(Edit, Txt.s)
    Declare.i   SetCaretPos(Edit, Pos = #MyEdit_LastCaretPos)
    Declare.i   SelectText(Edit, StartPos, Length = -1)
    Declare.i   SetAttribute(Edit, Attribute = #MyEdit_BackColor, Value = $FFFFFF)
    Declare.i   GetAttribute(Edit, Attribute = #MyEdit_BackColor)
    Declare.s   CloseEdit(Edit)
    Declare.i   IsLastPosition(Edit)
    Declare.i   OpenEdit(WinNbr, Gadget, Text.s, X=#PB_Default, Y=#PB_Default, W=#PB_Default, H=#PB_Default, FontNbr = -1)
    
EndDeclareModule

;-\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
;-......... CORE MODULE
;-\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\

Module MyEdit
    EnableExplicit
    ; internal constants:
    
    #LineStart      =  1                ; Line start - preceeds each hard line
    #RowStart       =  2                ; Row start - preceeds each artificial row due to wrapping
    
    Enumeration
        #Move_Right
        #Move_Left
        #Move_Up
        #Move_Down
        #Move_PageUp
        #Move_PageDown
        #Move_NextWord
        #Move_PreviousWord
        #Move_FirstInRow
        #Move_LastInRow
        #Move_First
        #Move_Last
    EndEnumeration
    
    ; all coordinates refer to the Edit (not to parent gadget)
    Structure TChar                     ; rectangle in the drawing area, can be associated with a real char or a line-start
        C.c                             ; actual char/line-start/row-start
        W.u                             ; 
        Txt.s   ; for debugging
    EndStructure
    
    Structure TEdit
        Window.i
        Gadget.i
        Cursor.i                        ; original canvas cursor, to be restored when exiting Edit
        
        X.i                             ; coord of the Edit within its parent canvas-gadget
        Y.i
        W.i
        H.i
        
        FontNbr.i
        FontHeight.i
        BColor.i                        ; background color
        FColor.i                        ; Text of Fore color
        SelBColor.i                     ; selection/highlight color
        SelFColor.i                     ; selection/highlight color
        CaretColor.i
        Align.i                         ; 0 / #PB_Text_Right / #PB_Text_Center
        ReadOnly.i                      ; 0/1
        AcceptTab.i                     ; 0/1 ???? canvas cant intercept tab-key!
        
        NoDrawing.i
        ; --------------- internal data / use
        List    Chars.TChar()
        
        FirstChar.i                     ; index of the first char to display
        Caret.i                         ; current X of Caret (needed for blinking)
        CaretX.i
        
        SelStart.i                      ; -1 ... n (-1 -> no selection) - selected block first pos included
        SelEnd.i                        ; SelStart ... n - selected block last pos included
    EndStructure
    
    Global NewMap Edits()               ; list of currently opened Edits
    
    ; the caret is drawn before the char holding it
    
    Declare Draw(*E.TEdit)
    ; ----
    Macro       ResetSelection(Edit)
        Edit\SelStart = -1 : Edit\SelEnd = -1
    EndMacro
    Macro       HasSelection(Edit)
        Bool( (Edit\SelStart >= 0) And (Edit\SelEnd >= 0) And (Edit\SelStart <> Edit\SelEnd) )
    EndMacro
    Macro       IsValueInRange(_I, _S, _E)
        Bool( ((_S <= _I) And ( _I <= _E)) Or ((_E <= _I) And (_I <= _S)) )
    EndMacro
    
    Procedure   AdjustSelection(*E.TEdit, Index)
        If IsValueInRange(Index, 0, ListSize(*E\Chars())-1)
            If *E\SelStart = -1
                *E\SelStart = Index
                *E\SelEnd   = Index
            Else
                *E\SelEnd   = Index
            EndIf
        EndIf
    EndProcedure
    Procedure   EnhanceCaretVisibility(*E.TEdit)
        ; adjusts the FirstChar so caret is really visible
        Protected   i, w, max_w, mrgn, recalc
        
        If *E\FirstChar > *E\Caret : *E\FirstChar = *E\Caret : EndIf
        
        ForEach *E\Chars()
            If max_w < *E\Chars()\W : max_w = *E\Chars()\W : EndIf
        Next
        
        ; w is the distance between current FirstChar and the char/caret ... within the TEdit
        If SelectElement(*E\Chars(), *E\FirstChar)
            w = 0
            Repeat
                w = w + *E\Chars()\W
                If ListIndex(*E\Chars()) = *E\Caret : Break : EndIf
            Until Not NextElement(*E\Chars())
        EndIf
        
        ; calculating a relative margin when caret is on the border
        For i = 2 To 0 Step -1
            If *E\W > i*max_w : mrgn = i*max_w : Break : EndIf
        Next
        
        If w > (*E\W - mrgn)
            If SelectElement(*E\Chars(), *E\Caret)
                w = *E\Chars()\W
                While PreviousElement(*E\Chars())
                    w = w + *E\Chars()\W
                    If w > (*E\W - mrgn) : Break : EndIf
                    *E\FirstChar = ListIndex(*E\Chars())
                Wend
            EndIf
            
        ElseIf w < mrgn
            If SelectElement(*E\Chars(), *E\Caret)
                w = *E\Chars()\W
                While PreviousElement(*E\Chars())
                    w = w + *E\Chars()\W
                    If w > mrgn : Break : EndIf
                    *E\FirstChar = ListIndex(*E\Chars())
                Wend
            EndIf
        EndIf
        
    EndProcedure
    
    Procedure.i AddChar(*E.TEdit, C.c)
        ; user input, usual text adds the char C after current Caret (before char holding caret)
        Protected   i,n, img
        
        If *E\ReadOnly : ProcedureReturn : EndIf
        
        If SelectElement(*E\Chars(), *E\Caret)
            If InsertElement(*E\Chars())
                *E\Caret = ListIndex(*E\Chars()) + 1
                Img = CreateImage(#PB_Any, 1, 1)
                If Img And StartDrawing(ImageOutput(Img))
                    DrawingFont( FontID(*E\FontNbr) )
                    *E\Chars()\W = TextWidth( Chr(C) )
                    *E\Chars()\C = C
                    *E\Chars()\Txt = Chr(C)
                    StopDrawing()
                    FreeImage(Img)
                EndIf
                Draw(*E)
            EndIf
        EndIf
        
    EndProcedure
    Procedure.i ProcessKey(*E.TEdit, Ky, DrawNow = #True)
        ; user input, special key (Backspace, del, enter, ...)
        Protected   i,a,s,h, L
        
        If *E\ReadOnly : ProcedureReturn : EndIf
        If SelectElement(*E\Chars(), *E\Caret)
            Select ky
                Case #PB_Shortcut_Back
                    Debug "backspace [Before] Caret = " + Str(*E\Caret) + " ... ListIndex = " + Str( ListIndex(*E\Chars()))
                    If PreviousElement(*E\Chars())
                        DeleteElement(*E\Chars())
                        *E\Caret = *E\Caret - 1
                    EndIf
                    Debug "backspace [After] Caret = " + Str(*E\Caret) + " ... ListIndex = " + Str( ListIndex(*E\Chars()))
                    
                Case #PB_Shortcut_Delete
                    If *E\Caret < ListSize(*E\Chars()) - 1  ; we dont delete the last virtual char
                        DeleteElement(*E\Chars())
                    EndIf
                    
                Case #PB_Shortcut_Return
                    
                Case #PB_Shortcut_Tab       ; ?
            EndSelect
        EndIf
        If DrawNow : Draw(*E) : EndIf
        
    EndProcedure
    
    Procedure   DeleteSelection(*E.TEdit)
        Protected  n
        
        If HasSelection(*E) = #False : ProcedureReturn : EndIf
        
        If *E\SelStart > *E\SelEnd
            Swap *E\SelEnd, *E\SelStart
        EndIf
        n = *E\SelEnd - *E\SelStart
        If SelectElement(*E\Chars(), *E\SelStart)
            *E\Caret = *E\SelStart
            Repeat
                ProcessKey(*E, #PB_Shortcut_Delete, #False)
                n - 1
            Until n <= 0
            ResetSelection(*E)
            Draw(*E)
        EndIf
        
    EndProcedure
    
    Procedure   BlinkCaretTimer()
        Protected   *E.TEdit
        Static i
        
        If GetActiveWindow() = EventWindow()
            ForEach Edits()
                *E = Val(MapKey(Edits()))
                If *E = 0 : Continue : EndIf
                If *E <> EventTimer()               : Continue : EndIf
                If *E\Window <> EventWindow()       : Continue : EndIf
                If *E\Gadget <> GetActiveGadget()   : Continue : EndIf
                ;Debug "BlinkCaretTimer >>>>> Caret = " + Str(*E\Caret) + " .... Sel = [" + Str(*E\SelStart) + " , " + Str(*E\SelEnd) + "]"
                If IsValueInRange(*E\CaretX, *E\X, *E\X + *E\W)
                    If StartDrawing(CanvasOutput(*E\Gadget))
                        DrawingMode(#PB_2DDrawing_Default)
                        If i
                            Line(*E\CaretX, *E\Y, 1, *E\FontHeight, *E\BColor)
                            i = 0
                        Else
                            Line(*E\CaretX, *E\Y , 1, *E\FontHeight, *E\CaretColor)
                            i = 1
                        EndIf
                        StopDrawing()
                    EndIf
                EndIf
            Next
        EndIf
        
    EndProcedure
    Procedure   AddCaretTimer(*E.TEdit)
        ; adds a timer to WinNbr with value *E
        
        ;Debug "adding a timer ..."
        AddWindowTimer(*E\Window, *E, 500)
        BindEvent(#PB_Event_Timer , @BlinkCaretTimer(), *E\Window)
    EndProcedure
    Procedure   RemoveCaretTimer(*E.TEdit)
        ; removes the timer #TimerNumber if no longer needed - last Edit in that window about to be closed
        
        UnbindEvent(#PB_Event_Timer , @BlinkCaretTimer(), *E\Window)
        RemoveWindowTimer(*E\Window, *E)
    EndProcedure
    
    Procedure.i Draw(*E.TEdit)
        ; draw as per current settings/counters
        Protected   x, y, w, h, w_m, crt_vis, frst, t, sel_s.f, sel_e.f
        
        If *E\NoDrawing = #True : ProcedureReturn : EndIf
        
        t = ElapsedMilliseconds()
        
        If HasSelection(*E)
            sel_s = *E\SelStart - 0.5
            sel_e = *E\SelEnd - 0.5
        EndIf
        
        If StartDrawing(CanvasOutput(*E\Gadget))
            DrawingMode(#PB_2DDrawing_Default)
            
            Box(*E\X, *E\Y, *E\W, *E\H, *E\BColor)
            If ListSize(*E\Chars()) > 0
                EnhanceCaretVisibility(*E)
                x = *E\X + 2
                w = 0
                w_m = *E\W - 4
                
                DrawingFont( FontID(*E\FontNbr) )
                ForEach *E\Chars()
                    If ListIndex(*E\Chars()) < *E\FirstChar : Continue : EndIf
                    If (w + *E\Chars()\W ) > w_m : Break : EndIf
                    
                    If ListIndex(*E\Chars()) = *E\Caret : *E\CaretX = x : EndIf
                    
                    If HasSelection(*E) And IsValueInRange(0.0 + ListIndex(*E\Chars()), sel_s, sel_e)
                        Box(x, *E\Y, *E\Chars()\W, *E\H, *E\SelBColor)
                        x = DrawText(x, *E\Y, Chr(*E\Chars()\C), *E\SelFColor, *E\SelBColor)
                    Else
                        x = DrawText(x, *E\Y, Chr(*E\Chars()\C), *E\FColor, *E\BColor)
                    EndIf
                    w + *E\Chars()\W
                Next
            EndIf
            StopDrawing()
        EndIf
        
        ;Debug " >>>>>>>>>>>>>>>>> Draw time: " + Str( ElapsedMilliseconds() - t)
        

    EndProcedure
    
    ;-------------------------------------------------------------------------------
    
    ; X, Y are coordinates in the parent canvas
    ; ----
    Procedure   SetCaretFromXY(*E.TEdit, X, Y)
        Protected   w, dlt, idx_r, idx_s, idx_v, rr
        
        If IsValueInRange(X, *E\X, *E\X + *E\W) And IsValueInRange(Y, *E\Y, *E\Y + *E\H)
            w   = *E\X
            dlt = *E\W
            
            If SelectElement( *E\Chars(), *E\FirstChar)
                Repeat
                    If Abs(w-X) > dlt : Break : EndIf
                    dlt = Abs(w-X)
                    *E\Caret = ListIndex(*E\Chars())
                    w = w + *E\Chars()\W
                Until NextElement(*E\Chars()) = 0
            EndIf
        EndIf
        
    EndProcedure
    
    Procedure   MoveCaret(*E.TEdit, Direction, sel = 0)
        Protected old_c = *E\Caret, space_found, char_found
        
        If sel
            AdjustSelection(*E, *E\Caret)
        Else
            ResetSelection(*E)
        EndIf
        
        Select Direction
            Case #Move_Right, #Move_Down
                SelectElement(*E\Chars(), *E\Caret)
                If NextElement(*E\Chars()) : *E\Caret = ListIndex(*E\Chars()) : EndIf
                
            Case #Move_Left, #Move_Up
                SelectElement(*E\Chars(), *E\Caret)
                If PreviousElement(*E\Chars()) : *E\Caret = ListIndex(*E\Chars()) : EndIf
                
            Case #Move_First
                *E\Caret = 0
                ;*E\FirstChar = 0
                
            Case #Move_Last
                *E\Caret = ListSize(*E\Chars()) - 1
                ;*E\FirstChar = ListSize(*E\Chars()) - 1
                
            Case #Move_NextWord
                ; we should stop at the first next char that's not a space and is preceeded by a space
                SelectElement(*E\Chars(), *E\Caret)
                While NextElement(*E\Chars())
                    *E\Caret = ListIndex(*E\Chars())
                    If *E\Chars()\C = 32 : space_found = #True : EndIf
                    If *E\Chars()\C <> 32 And space_found = #True : Break : EndIf
                Wend
                
            Case #Move_PreviousWord
                ; we should stop at the first previous char that's not a space and is preceeded by a space
                SelectElement(*E\Chars(), *E\Caret)
                While PreviousElement(*E\Chars())
                    If *E\Chars()\C <> 32 : char_found = #True : EndIf
                    If *E\Chars()\C = 32 And char_found = #True : Break : EndIf
                    *E\Caret = ListIndex(*E\Chars())
                Wend
        EndSelect
        
        If sel : AdjustSelection(*E, *E\Caret) : EndIf
        
        Draw(*E)
        
    EndProcedure
    
    ;-------------------------------------------------------------------------------
    ;---- Interface
    Procedure.i SetAttribute(Edit, Attribute = #MyEdit_BackColor, Value = $FFFFFF)
        Protected   *E.TEdit = Edit
        If Edits(Str(*E)) = 0 : ProcedureReturn : EndIf
        If Value < 0 : ProcedureReturn : EndIf
        
        Select Attribute
            Case #MyEdit_BackColor            : *E\BColor = Value
            Case #MyEdit_TextColor            : *E\FColor = Value
            Case #MyEdit_SelectionBackColor   : *E\SelBColor = Value
            Case #MyEdit_SelectionTextColor   : *E\SelFColor = Value
            Case #MyEdit_CaretColor           : *E\CaretColor = Value
            Case #MyEdit_Align                : *E\Align = Value
            Case #MyEdit_ReadOnly             : *E\ReadOnly = Value
        EndSelect
        
    EndProcedure
    Procedure.i GetAttribute(Edit, Attribute = #MyEdit_BackColor)
        Protected   V, *E.TEdit = Edit
        If Edits(Str(*E)) = 0 : ProcedureReturn : EndIf
        
        Select Attribute
            Case #MyEdit_BackColor            : V = *E\BColor
            Case #MyEdit_TextColor            : V = *E\FColor
            Case #MyEdit_SelectionBackColor   : V = *E\SelBColor
            Case #MyEdit_SelectionTextColor   : V = *E\SelFColor
            Case #MyEdit_CaretColor           : V = *E\CaretColor
            Case #MyEdit_Align                : V = *E\Align
            Case #MyEdit_ReadOnly             : V = *E\ReadOnly
        EndSelect
        ProcedureReturn V
    EndProcedure
    Procedure.i SetCaretPos(Edit, Pos = #MyEdit_LastCaretPos)
        Protected   *E.TEdit = Edit
        If Edits(Str(*E)) = 0 : ProcedureReturn : EndIf
        
        Protected   i
        Select Pos
            Case #MyEdit_FirstCaretPos    : MoveCaret(*E, #Move_First)
            Case #MyEdit_LastCaretPos     : MoveCaret(*E, #Move_Last)
            Default
                If i >= 0 And i <= ListSize(*E\Chars()) - 1
                    *E\Caret = i
                    Draw(*E)
                EndIf
        EndSelect
        
    EndProcedure
    Procedure.i SelectText(Edit, Start, Length = -1)
        Protected   *E.TEdit = Edit
        Protected   s,e
        
        If Edits(Str(*E)) = 0 : ProcedureReturn : EndIf
        
        If Length = -1
            e = ListSize(*E\Chars()) - 1
        Else
            e = Start + Length - 1
        EndIf
        If s = -1 Or e = -1 : ProcedureReturn : EndIf
        If SelectElement(*E\Chars(), s) And SelectElement(*E\Chars(), e)
            *E\SelStart = s
            *E\SelEnd = e
        EndIf
        
        Draw(*E)
        
    EndProcedure
    ;-----
    Procedure.i ManageEvent(Edit.i, eType)
        ; Gdt is the canvas gadget that first received this event and passed it to its associated Edit
        Protected   Gdt.i, *E.TEdit = Edit
        Protected   ky,mf, x,y, dlt,i, sel
        
        If Edits(Str(*E)) = 0 : ProcedureReturn : EndIf
        Gdt = *E\Gadget
        ;Debug "MyEdit received this message: " + Str(eType)
        Select eType
            Case #PB_EventType_KeyDown
                ky = GetGadgetAttribute(gdt, #PB_Canvas_Key )
                mf = GetGadgetAttribute(gdt, #PB_Canvas_Modifiers )
                
                If mf & #PB_Canvas_Shift : sel = 1 : EndIf
                ;If sel = 0 : ResetSelection(*E) : EndIf
                
                If mf & #PB_Canvas_Control
                    Select ky
                        Case #PB_Shortcut_Left      : MoveCaret(*E, #Move_PreviousWord, sel)
                        Case #PB_Shortcut_Right     : MoveCaret(*E, #Move_NextWord, sel)
                        Case #PB_Shortcut_Up        : 
                        Case #PB_Shortcut_Down      : 
                        Case #PB_Shortcut_Home      : MoveCaret(*E, #Move_First, sel)
                        Case #PB_Shortcut_End       : MoveCaret(*E, #Move_Last, sel)
                    EndSelect
                Else
                    Select ky
                        Case #PB_Shortcut_Left      : MoveCaret(*E, #Move_Left, sel)
                        Case #PB_Shortcut_Right     : MoveCaret(*E, #Move_Right, sel)
                        Case #PB_Shortcut_Up        : MoveCaret(*E, #Move_Up, sel)
                        Case #PB_Shortcut_Down      : MoveCaret(*E, #Move_Down, sel)
                        Case #PB_Shortcut_Home      : MoveCaret(*E, #Move_First, sel)
                        Case #PB_Shortcut_End       : MoveCaret(*E, #Move_Last, sel)
                    EndSelect
                EndIf
                
                Select ky
                    Case #PB_Shortcut_Delete, #PB_Shortcut_Back, #PB_Shortcut_Tab
                        If HasSelection(*E)
                            DeleteSelection(*E)
                        Else
                            ProcessKey(*E, Ky)
                        EndIf
                        ;Draw(*E)
                        
                    Case #PB_Shortcut_Return
                        DeleteSelection(*E)
                        ProcessKey(*E, Ky)
                        ;Draw(*E)
                EndSelect
                
            Case #PB_EventType_Input                                ; add a new char after current element
                    DeleteSelection(*E)
                    AddChar(*E, GetGadgetAttribute(gdt, #PB_Canvas_Input))
                    ;Draw(*E)
                
            Case #PB_EventType_MouseWheel
                
            Case #PB_EventType_LeftDoubleClick
            Case #PB_EventType_MouseEnter
            Case #PB_EventType_MouseMove                ; selecting via mouse
                x = GetGadgetAttribute(gdt, #PB_Canvas_MouseX)
                y = GetGadgetAttribute(gdt, #PB_Canvas_MouseY)
                ;x = RelativeX(*E, GetGadgetAttribute(gdt, #PB_Canvas_MouseX))
                ;y = RelativeY(*E, GetGadgetAttribute(gdt, #PB_Canvas_MouseY))
                
                If GetGadgetAttribute(gdt, #PB_Canvas_Buttons) = #PB_Canvas_LeftButton
                    SetCaretFromXY(*E, x, y)
                    AdjustSelection(*E, *E\Caret)
                    Draw(*E)
                EndIf
                
            Case #PB_EventType_MouseLeave
            Case #PB_EventType_LeftButtonUp
            Case #PB_EventType_LeftButtonDown
                x = GetGadgetAttribute(gdt, #PB_Canvas_MouseX)
                y = GetGadgetAttribute(gdt, #PB_Canvas_MouseY)
                ;x = RelativeX(*E, GetGadgetAttribute(gdt, #PB_Canvas_MouseX))
                ;y = RelativeY(*E, GetGadgetAttribute(gdt, #PB_Canvas_MouseY))
                ResetSelection(*E)
                SetCaretFromXY(*E, x, y)
                Draw(*E)
                
            Case #PB_EventType_RightButtonDown
                
            Default
                ProcedureReturn #False 
        EndSelect
        

    EndProcedure
    ;-----
    
    Procedure.i Resize(Edit.i, X = #PB_Ignore, Y = #PB_Ignore, W = #PB_Ignore, H = #PB_Ignore)
        Protected   *E.TEdit = Edit
        
        If Edits(Str(*E)) = 0 : ProcedureReturn : EndIf
        
        If X <> #PB_Ignore : *E\X = X : EndIf
        If Y <> #PB_Ignore : *E\Y = Y : EndIf
        If W <> #PB_Ignore : *E\W = W : EndIf
        If H <> #PB_Ignore : *E\H = H : EndIf
        Draw(*E)

    EndProcedure
    
    Procedure.i SetText(Edit, Txt.s)
        Protected   *E.TEdit = Edit
        Protected   i, img, *c.Character
        
        If Edits(Str(*E)) = 0 : ProcedureReturn : EndIf
        ClearList(*E\Chars())
        Img = CreateImage(#PB_Any, 1, 1)
        If Img 
            If StartDrawing(ImageOutput(Img))
                DrawingFont( FontID(*E\FontNbr) )
                
                For i=1 To Len(Txt)
                    *c = @Txt + ((i-1) * SizeOf(Character))
                    AddElement(*E\Chars())
                    *E\Chars()\C = *c\c
                    *E\Chars()\W = TextWidth( Chr(*c\c) )
                    *E\Chars()\Txt = Chr(*c\c)
                Next
                *E\FontHeight = TextHeight("A")
                StopDrawing()
                
                AddElement(*E\Chars())      ; this virtual char will serve 2 purposes
                *E\Chars()\C = 0            ; 1. will allow displaying caret after the last char
                *E\Chars()\W = 0            ; 2. when returning the string contained in MyEdit, adds \0 for PeekS()
            EndIf
            FreeImage(Img)
        EndIf
        
    EndProcedure
    Procedure.s GetText(Edit)
        Protected   *E.TEdit = Edit
        Protected   i,n, ret.s, Dim ary.c(0)
        
        If Edits(Str(*E)) = 0 : ProcedureReturn "" : EndIf
        n = ListSize(*E\Chars())
        ReDim ary(n-1)
        i = 0
        ForEach *E\Chars()
            ary(i) = *E\Chars()\C
            i+1
        Next
        ret = PeekS( @ary(0), n )
        ProcedureReturn ret
        
    EndProcedure
    
    Procedure.s CloseEdit(Edit)
        ; close the Edit and return its content
        Protected   *E.TEdit = Edit
        Protected   ret.s
        
        If Edits(Str(*E)) = 0 : ProcedureReturn : EndIf
        ;Debug "closing editor"
        ret = GetText(*E)
        RemoveCaretTimer(*E)
        SetGadgetAttribute(*E\Gadget, #PB_Canvas_Cursor, *E\Cursor)
        FreeStructure(*E)
        DeleteMapElement(Edits(), Str(Edit))
        ProcedureReturn ret
    EndProcedure
    Procedure.i IsLastPosition(Edit)
        ; when at last position -> navigation keys received in MyGrid will close the editor
        Protected   *E.TEdit = Edit
        
        If Edits(Str(*E)) = 0 : ProcedureReturn #False : EndIf
        ProcedureReturn Bool( *E\Caret = ListSize(*E\Chars()) - 1)
        
    EndProcedure
    
    Procedure.i OpenEdit(WinNbr, Gadget, Text.s, X=#PB_Default, Y=#PB_Default, W=#PB_Default, H=#PB_Default, FontNbr = -1)
        ; return an Edit (a raw pointer to TEdit)
        Protected *E.TEdit
        
        If IsGadget(Gadget) And GadgetType(Gadget) = #PB_GadgetType_Canvas
            If X = #PB_Default : X = 0                      : EndIf
            If Y = #PB_Default : Y = 0                      : EndIf
            If W = #PB_Default : W = GadgetWidth(Gadget)    : EndIf
            If H = #PB_Default : H = GadgetHeight(Gadget)   : EndIf
        Else
            MessageRequester("Error","Gadget needs to be an existing canvas gadget!")
            ProcedureReturn 0
        EndIf
        
        *E              = AllocateStructure(TEdit)
        
        *E\Window       = WinNbr
        *E\Gadget       = Gadget
        Edits(Str(*E))  = 1
        AddCaretTimer(*E)           ; adds a Caret-timer if not added to that window already
        
        *E\X            = X
        *E\Y            = Y
        *E\W            = W 
        *E\H            = H
        
        *E\BColor       = RGB(255,255,255)
        *E\FColor       = RGB(0, 0, 139)
        *E\SelBColor    = RGB(30, 144, 255)
        *E\SelFColor    = *E\BColor
        *E\CaretColor   = RGB(255, 0, 0)
        *E\FontNbr      = FontNbr
        ;*E\Align        = #PB_Text_Center
        
        If *E\Align <> #PB_Text_Right And *E\Align <> #PB_Text_Center : *E\Align = 0 : EndIf
        
        *E\Cursor = GetGadgetAttribute(Gadget, #PB_Canvas_Cursor)
        SetGadgetAttribute(Gadget, #PB_Canvas_Cursor, #PB_Cursor_IBeam)
        
        SetText(*E, Text)
        
        ResetSelection(*E)
        Draw(*E)
        
        ProcedureReturn *E

    EndProcedure
    
    
EndModule

; IDE Options = PureBasic 5.61 (Windows - x86)
; CursorPosition = 703
; FirstLine = 259
; Folding = DwCA0
; EnableXP
; EnableUnicode