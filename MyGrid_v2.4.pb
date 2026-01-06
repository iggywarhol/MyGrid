;-TOP

; -----------------------------------------------------------------------------

;- MyGrid

;  Author         : Said
;  Second Author  : mk-soft
;  Version        : v2.0
;  Update         : 22.11.2017
;   - Updates for PB 5.61 now using the canvas as the container
;
;  Version        : v2.4
;  Update         : 16.02.2022
;   - Added SetStyleItemList
;   - Added Keyboard Escape, Tab, Return to Combo
;   - Optimize open combo (position up or down)
;
;  Link: https://www.purebasic.fr/english/viewtopic.php?f=12&t=54022

XIncludeFile "MyEdit.pbi"           ; one line-editor

DeclareModule MyGrid
  ;{ OS customization
  CompilerSelect #PB_Compiler_OS
    CompilerCase #PB_OS_Linux           ; might need be tuned!
      #Text_MarginX       = 4           ; left/right margin in pixel
      #Text_MarginY       = 2           ; up/down margin in pixel
      #RowSep_Margin      = 6           ; 
      #ColSep_Margin      = 6           ; mouse-margin in pixel
      #Scroll_Width       = 18          ; 
      #Default_ColWidth   = 60          ; 
      #Default_RowHeight  = 22          ; 
      #CheckBox_Width     = 16          ; 
      #CheckBox_Color     = $C95718     ; square boredr color 
      #Combo_Height       = 80          ; height of listview associated with combo-cells
      #NewLine$           = #LF$
      
    CompilerCase #PB_OS_MacOS           ; might need be tuned!
      #Text_MarginX       = 4           ; left/right margin in pixel
      #Text_MarginY       = 2           ; up/down margin in pixel
      #RowSep_Margin      = 4           ; 
      #ColSep_Margin      = 4           ; mouse-margin in pixel
      #Scroll_Width       = 18          ; 
      #Default_ColWidth   = 60          ; 
      #Default_RowHeight  = 22          ; 
      #CheckBox_Width     = 16          ; 
      #CheckBox_Color     = $C95718     ; square boredr color 
      #Combo_Height       = 80          ; 
      #NewLine$           = #LF$
      
    CompilerDefault
      #Text_MarginX       = 4         ; left/right margin in pixel
      #Text_MarginY       = 2         ; up/down margin in pixel
      #RowSep_Margin      = 6         ; 
      #ColSep_Margin      = 6         ; mouse-margin in pixel
      #Scroll_Width       = 18        ; 
      #Default_ColWidth   = 60        ; 
      #Default_RowHeight  = 20        ; 
      #CheckBox_Width     = 14        ; 14,16
      #CheckBox_Color     = $C95718   ; square boredr color 
      #Combo_Height       = 80        ; 
      #NewLine$           = #CRLF$
  CompilerEndSelect ;}
  
  ;{ public constants and enum
  
  Enumeration #PB_Event_FirstCustomValue + 200        ; external events returned to caller application
    #Event_Change                                     ; fired when cell content has changed from outside / #Property_ChangedRow and #Property_ChangedCol can be used to see what cell has changed
    #Event_Click                                      ; fired when a button-cell received a full clikc   / #Property_ClickedRow and #Property_ClickedCol can be used to see what cell has been clicked
  EndEnumeration
  
  Enumeration 63050                   ; external menu events for combo shortcut key
    #EventMenu_Escape
    #EventMenu_Tab
    #EventMenu_Return
  EndEnumeration
  
  Enumeration #PB_EventType_FirstCustomValue          ; external menu events for combo shortcut key
    #EventTypeMenu_Escape
    #EventTypeMenu_Tab
    #EventTypeMenu_Return
  EndEnumeration
  
  Enumeration                         ; horizontal alignment
    #Align_Left      = 0              ; text left alignment - default
    #Align_Center                     ; text center alignment
    #Align_Right                      ; text right alignment
    #Align_Fit                        ; mainly for image (will resize the image to fit the cell sizes)
  EndEnumeration
  
  Enumeration                         ; what the cell is supposed to display - what to draw
    #CellType_Normal    = 0           ; text or number
    #CellType_Checkbox                ; 
    #CellType_Button                  ; 
    #CellType_Combo                   ; 
    #CellType_Image                   ; we internally store the associated PB img nbr 
  EndEnumeration
  
  ; Generic Rows/Cols
  #RC_Any              = -30          ; special value (<0) -> any row or any col
  #RC_Header           = -20          ; special value (<0) -> any row or any col that is header
  #RC_Data             = -10          ; special value (<0) -> any row or any col that is not header
  
  ;}
  
  ;{ public routines - work with PB Gadget Number
  
  ; --- Grid
  Declare.i NoRedraw(Gadget)
  Declare.i Redraw(Gadget)
  Declare.i Resize(Gadget, X, Y, Width, Height)
  Declare.i GetColorLine(Gadget)
  Declare.i GetColorBack(Gadget)
  Declare.i GetColorFocusBack(Gadget)
  Declare.i GetColorFocusBorder(Gadget)
  Declare.i GetColorBlockBack(Gadget)
  
  Declare.i SetColorLine(Gadget, Value.i)
  Declare.i SetColorBack(Gadget, Value.i)
  Declare.i SetColorFocusBack(Gadget, Value.i)
  Declare.i SetColorFocusBorder(Gadget, Value.i)
  Declare.i SetColorBlockBack(Gadget, Value.i)
  Declare.i HideZero(Gadget, State = #True)
  Declare.i AttachPopup(Gadget, Popup.i)
  Declare.i ClearData(Gadget)
  Declare.i Reset(Gadget, Rows, Cols)
  Declare.i UnFreeze(Gadget)
  Declare.i AutoAlignColumns(Gadget)
  Declare.i ShowRowNumbers(Gadget, State = #True)
  Declare.i SetDecimalCharacter(Gadget, Char.s = ".")
  Declare.i SetThousandsSeparator(Gadget, Char.s = ",")
  ; ---
  Declare.i New(WinNbr, Gadget, X, Y, W, H, Rows = 500, Cols = 100, DrawNow = #True, VerScrollBar = #True, HorScrollBar = #True, RowNumbers = #True)
  Declare.i Free(Gadget)
  
  ; Styles
  Declare.i AddNewStyle(Gadget, StyleName.s)
  Declare.i AssignStyle(Gadget, GRow, GCol, StyleName.s)
  Declare.i UnAssignStyles(Gadget)
  Declare.i ClearStyles(Gadget)
  Declare.i ListOfStyles(Gadget, List StyleNames.s())
  Declare.i SetStyleAlign(Gadget, StyleName.s, Value.i = #Align_Left)
  Declare.i SetStyleBackColor(Gadget, StyleName.s, Value.i = $FFFFFF)
  Declare.i SetStyleForeColor(Gadget, StyleName.s, Value.i = $000000)
  Declare.i SetStyleCellType(Gadget, StyleName.s, Value.i = #CellType_Normal)
  Declare.i SetStyleEditable(Gadget, StyleName.s, Value.i = #True)
  Declare.i SetStyleFont(Gadget, StyleName.s, FontNumber.i)
  Declare.i SetStyleGradient(Gadget, StyleName.s, Value.i = #True)
  Declare.i SetStyleItems(Gadget, StyleName.s, Items.s, ItemSep.s)
  Declare.i SetStyleItemList(Gdt, StyleName.s, List ItemList.s())
  
  Declare.i GetStyleAlign(Gadget, StyleName.s)
  Declare.i GetStyleBackColor(Gadget, StyleName.s)
  Declare.i GetStyleForeColor(Gadget, StyleName.s)
  Declare.i GetStyleCellType(Gadget, StyleName.s)
  Declare.i GetStyleEditable(Gadget, StyleName.s)
  Declare.i GetStyleFont(Gadget, StyleName.s)
  Declare.i GetStyleGradient(Gadget, StyleName.s)
  Declare.i GetStyleItems(Gadget, StyleName.s, List Items.s())
  
  
  ; Rows
  Declare.i AddRow(Gadget.i)
  Declare.i DrawRow(Gdt, Row)
  Declare.i GetCurRow(Gadget.i)
  Declare.i GetTopRow(Gadget.i)
  Declare.i GetRowCount(Gadget.i)
  Declare.i GetHeaderRowCount(Gadget.i)
  Declare.i SetCurRow(Gadget.i, Value.i)
  Declare.i SetTopRow(Gadget.i, Value.i)
  Declare.i SetRowCount(Gadget.i, Rows)
  Declare.i SetHeaderRowCount(Gadget.i, Cols)
  Declare.i SetRowHeight(Gadget.i, GRow.i, Height.i = #Default_RowHeight)
  Declare.i GetRowHeight(Gadget.i, Row.i)
  Declare.i AutoHeightRow(Gadget.i, GRow)
  Declare.i ShowRow(Gadget.i, Row)
  Declare.i HideRow(Gadget.i, GRow.i, State)
  Declare.i IsRowHidden(Gadget.i, Row.i)
  Declare.i GetNonHiddenRowCount(Gadget.i)
  
  Declare.i SetRowID(Gadget.i, Row.i, RowID.s)
  Declare.i ClearRowIDs(Gadget.i)
  Declare.i RowNumberOfRowID(Gadget.i, RowID.s)
  Declare.i ChangeRowID(Gadget.i, oldRowID.s, newRowID.s)
  Declare.s RowIdOfRowNumber(Gadget.i, Row)
  Declare.i FreezeRow(Gadget.i, Row.i)
  Declare.i FrozenRow(Gadget.i)
  
  
  ; Cols
  Declare.i AddCol(Gadget.i)
  Declare.i DrawCol(Gadget.i, Col)
  Declare.i GetCurCol(Gadget.i)
  Declare.i GetTopCol(Gadget.i)
  Declare.i GetColCount(Gadget.i)
  Declare.i GetHeaderColCount(Gadget.i)
  Declare.i SetCurCol(Gadget.i, Value.i)
  Declare.i SetTopCol(Gadget.i, Value.i)
  Declare.i SetColCount(Gadget.i, Cols)
  Declare.i SetHeaderColCount(Gadget.i, Rows)
  
  Declare.i SetColWidth(Gadget.i, GCol.i, Width.i = #Default_ColWidth)
  Declare.i GetColWidth(Gadget.i, Col.i)
  Declare.i AutoWidthCol(Gadget.i, GCol)
  Declare.i ShowCol(Gadget.i, Col)
  Declare.i HideCol(Gadget.i, GCol.i, State)
  Declare.i IsColHidden(Gadget.i, Col.i)
  Declare.i GetNonHiddenColCount(Gadget.i)
  
  Declare.i SetColID(Gadget.i, Col.i, ColID.s)
  Declare.i ClearColIDs(Gadget.i)
  Declare.i ColNumberOfColID(Gadget.i, ColID.s)
  Declare.i ChangeColID(Gadget.i, oldColID.s, newColID.s)
  Declare.s ColIdOfColNumber(Gadget.i, Col)
  Declare.i FreezeCol(Gadget.i, Col.i)
  Declare.i FrozenCol(Gadget.i)
  Declare.i SetColData(Gadget.i, Col.i, ColData.i)
  Declare.i GetColData(Gadget.i, Col.i)
  Declare.i EnableSortOnClick(Gadget.i, Col.i, State.i = 1)
  
  ; Cells
  Declare.i DrawCell(Gdt, Row, Col)
  Declare.i IsValidCell(Gadget.i, Row, Col)
  Declare.i ShowCell(Gadget.i, Row, Col, SetCellFocus = #False)
  Declare.i FocusCell(Gadget, Row, Col)
  Declare.i SetText(Gadget.i, Row.i, Col.i, Txt.s)
  Declare.s GetText(Gadget.i, Row.i, Col.i)
  Declare.i SetCurrentCellText(Gadget.i, Txt.s)
  Declare.s GetCurrentCellText(Gadget.i)
  Declare.s StyleOfCell(Gadget, Row, Col)
  Declare.i IsCellEditable(Gadget, Row, Col)
  
  ; ***
  ; Block-selection
  Declare.i SelectBlock(Gadget, Row1,Col1, Row2,Col2)
  Declare.i SetBlockRow2(Gadget.i, Value.i)
  Declare.i SetBlockCol2(Gadget.i, Value.i)
  Declare.i GetBlockRow2(Gadget.i)
  Declare.i GetBlockCol2(Gadget.i)
  Declare.i HasBlock(Gadget)
  Declare.i ResetBlock(Gadget)
  Declare.i ClearBlockContent(Gadget.i)
  Declare.i SelectAll(Gadget)
  Declare.s GetBlockText(Gadget.i, CellSep.s = #TAB$, RowSep.s = #NewLine$)
  Declare.i SetBlockText(Gadget.i, Txt.s, EditableOnly.i = #True, CellSep.s = #TAB$, RowSep.s = #NewLine$, AutoDim.i=#False)
  
  ; --- Events
  Declare.i GetChangedRow(Gadget.i)
  Declare.i GetChangedCol(Gadget.i)
  Declare.s GetChangedText(Gadget.i)
  Declare.i GetClickedRow(Gadget.i)
  Declare.i GetClickedCol(Gadget.i)
  Declare.i ClearLastChange(Gadget.i)
  Declare.i ClearLastClick(Gadget.i)
  
  ; --- cell merging (span)
  Declare.i MergeCells(Gadget, Row1,Col1, Row2,Col2, CheckIntersection.i=#True)
  Declare.i UnMergeCells(Gadget, Row,Col)
  Declare.i ClearMerges(Gadget)
  
  ; ---
  Declare.i ResetSort(Gadget.i)
  Declare.i AddSortingCol(Gadget.i, Col, Direction = #PB_Sort_Ascending)
  Declare.i Sort(Gadget.i, StartRow = -1, EndRow = -1)
  
  ; --- extra
  Declare.i SetMultiText(Gadget.i, Txt.s, GRow.i, GCol.i, Row2 = 0, Col2 = 0, UseSep.s = #TAB$)
  Declare.s GetMultiText(Gadget.i, GRow.i, GCol.i, Row2 = 0, Col2 = 0, CellSep.s = #TAB$, RowSep.s = #LF$)
  
  Declare.i ImportData(Gadget.i, Array A.s(2))
  Declare.i ExportData(Gadget.i, Array Ret.s(2), WithHeaders = #True, VisibleOnly = #True)
  
  Declare.i SaveToTextFile(Gadget.i, useSep.s, List extraHeaders.s(), fName.s, VisibleOnly = #True, format=#PB_Ascii)
  
  Declare.i Transpose(Gadget.i)
  ;}
  
  Global adResize
  Global adFree
  
EndDeclareModule

;-\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
;-......... CORE MODULE
;-\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\

Module MyGrid
  EnableExplicit
  
  ;{ private constants and enum
  #Scroll_Max          = 10000
  #Scroll_PageSize     = 20
  
  ; All possible mouse-move actions
  Enumeration
    #MouseMove_Nothing = 0      ; just changing the cursor ...
    #MouseMove_Resize           ; resizing col/row
    #MouseMove_Select           ; selecting a block
  EndEnumeration
  Enumeration
    #Move_Focus  = 0            ; what to move
    #Move_TopRC                 ; 
    #Move_Block                 ; 
  EndEnumeration
  #RC_WH_Hidden = -1              ; (< 0) special-value: height/width of a row/col hidden by application - for good, user cannot unhide via resizing
  
  
  ;}
  
  ;{ private MyGrid structures 
  Structure TAreaCol      ; Areas are dynamic depends on width of shown-columns/and height of shown-rows
    X.i                   ; Area of the canvas gadget that can receive events
    Width.i               ; actual drawn width
    Col.i                 ; related col >= 0
  EndStructure
  
  Structure TAreaRow      ; Areas are dynamic depends on width of shown-columns/and height of shown-rows
    Y.i                   ; Area of the canvas gadget that can receive events
    Height.i              ; actual drawn height
    Row.i                 ; related row >= 0
  EndStructure
  
  Structure TRectangle
    X.i                             ; 
    Y.i                             ; 
    W.i                             ; 
    H.i                             ; 
  EndStructure
  
  Structure TStyle                    ;--->>> Styles control all dispaly spec
    Name.s                            ; unique name identifies style
    Aling.i
    BackColor.i
    ForeColor.i
    Font.i
    CellType.i
    Editable.i                      ; 0/1
    Gradient.i                      ; 0/1
    List Item.s()                   ; when celltype is a combo, this is the seq of items to display
  EndStructure
  
  Structure TMultiCell    ; multi-cells or merged cells (cell span rows/cols)
    R1.i
    C1.i
    R2.i
    C2.i
  EndStructure
  
  Structure TSortingCol      ; 
    Col.i
    Direction.i                     ; 0 = Asc, 1 = Desc
  EndStructure
  Structure TRowRanks     ; internal used while sorting
    V.d
    ORank.i
    NRank.i
  EndStructure
  Structure TSortItem     ; internal used while sorting
    ORank.i
    NRank.i
    Flt.f
    Txt.s
  EndStructure
  
  Structure TGridBasic                ; --->>> TGridBasic doesnt contain PB objects: can be initialized with no harm
    Editor.i                          ; a rectangle area inside the grid to hold a MyEdit
    EditorX.i
    EditorY.i
    EditorW.i
    EditorH.i
    EditorRow.i
    EditorCol.i
    EditorFull.i                    ; 0/1 when 1 --> border-navigation-keys do not exit editor, we need Enter/Escape or a click away (we enter this mode either with dbl-click or pressing enter)
    
    Combo.i                         ; a rectangle area inside the grid to hold a list/combo
    ComboX.i
    ComboY.i
    ComboW.i
    ComboH.i
    ComboRow.i
    ComboCol.i
    
    ; sub-gadgets created while creating the Grid
    StateFactorCol.f                ; CurTop = Facor * State
    ColScrollMin.i                  ; Min-State for scrollbar ColScroll
    ColScrollMax.i                  ; Max-State for scrollbar ColScroll
    
    StateFactorRow.f                ; CurTop = Facor * State
    RowScrollMin.i                  ; Min-State for scrollbar RowScroll
    RowScrollMax.i                  ; Max-State for scrollbar RowScroll
    
    ; data in memory
    Rows.i
    HdrRows.i                       ; nbr of rows that are header of columns (defualt is 1 : row 0)
    Array RowHeight.i(0)            ; dimensioned by Rows
    Array RowData.i(0)              ; dimensioned by Rows - user defined value
    Map   DicRowID.i()              ; map of Unique ID to identify a Row, Rows can be accessed by index or by ID
    
    Cols.i                          ; total nbr of cols including hedaers/row-numbers ...
    HdrCols.i                       ; nbr of cols that are header of rows (defualt is 1 : col 0)
    Array ColWidth.i(0)             ; dimensioned by Cols
    Array ColData.i(0)              ; dimensioned by Cols - user defined value
    Array ColSortOnClick.a(0)       ; dimensioned by Cols
    Map   DicColID.i()              ; map of Unique ID to identify a Column, Cols can be accessed by index or by ID
    ColOfSort.i                     ; the current sorting column (in case of multi-sort, it is set to -1)
    ColOfSortDirection.i            ; 0/1 -> 0 = Ascending and 1 = Descending
    
    Array gData.s(0,0)              ; grid data (Cols, Rows) .. we can easily redim rows while preserving content
    
    ; current cell
    Row.i                           ; (Row, Col) of Current Cell
    Col.i
    
    TopRow.i                        ; (Row, Col) of Cell shown in Area(1,1)
    TopCol.i
    FrstTopRow.i
    LastTopRow.i
    FrstTopCol.i
    LastTopCol.i
    
    FrstVisRow.i
    LastVisRow.i
    FrstVisCol.i
    LastVisCol.i
    
    ; Visual on screen - Dynamic fields control drawing/scrolling/... 
    ; Area-Row 0 : will show Col-Headers
    ; Area-Col 0 : will show Row-Headers
    
    FrzCol.i                        ; last fixed col - cant scroll
    FrzRow.i                        ; last fixed row - cant scroll
    
    List LstAreaCol.TAreaCol() ; list of all defined col-screen-areas
    List LstAreaRow.TAreaRow() ; list of all defined row-screen-areas
    
    Map DicAreaOfRow.i()            ; area associtaed with that Row
    Map DicAreaOfCol.i()            ; area associtaed with that Col
    HdrWidth.i                      ; total headers width
    HdrHeight.i                     ; total headers height
    MoveStatus.i                    ; what the mouse-move is doing right now
    DownX.i
    DownY.i
    DownAreaRow.i
    DownAreaCol.i
    
    ColorLine.i                     ; grid-line color
    ColorBack.i                     ; grey-area color
    ColorFocusBack.i                ; while editing cells
    ColorFocusBorder.i              ; 
    ColorBlockBack.i                ; block highlight
    
    ; Block ... one block only, Block starts in (Row, Col) and ends in cell (Row2, Col2)
    Row2.i                          ; end cell can be above/before start cell !
    Col2.i                          ; 
    BlockX.i
    BlockY.i
    BlockW.i
    BlockH.i
    
    ChangedCol.i                    ; last changed cell via user-editing
    ChangedRow.i
    ChangedTxt.s                    ; last-changed cell old text
    
    ClickedCol.i                    ; last clicked cell via
    ClickedRow.i
    
    DrawingW.i
    DrawingH.i
    
    ; Styles control the Visual display of all Grid-elements
    Array Styles.TStyle(0)  ; never empty! Contains one element: 1st style (index 0), that apply to the whole grid by default
    Map   DicStyle.i()      ; [Key = Str(GRow)+":"Str(GCol)] [Val = style-index]
    
    ; cell span/ merged cells ---> one multi-cell
    List LstMulti.TMultiCell()
    ;
    List SortingCol.TSortingCol()   ; list of sorting cols
  EndStructure
  
  Structure TGrid Extends TGridBasic
    Window.i                        ; window number containing the grid (active)
    Gadget.i                        ; associated canvas gagdet number
    ColScroll.i                     ; gadget-nbr of attached hor sroll bar
    RowScroll.i                     ; gadget-nbr of attached ver sroll bar
    CmbEdit.i                       ; gadget-nbr of attached listview
    AttachedPopupMenu.i
    ShowRowNumbers.i
    WrapText.i
    HideZero.i
    DecimalCharacter.c
    ThousandsSeparator.c
    
    NoRedraw.i                      ; True/False - if true then we stop continuous redrawing
    Cursor.i
  EndStructure
  
  
  ;} privte structures
  
  ;--->>> Private Declares
  Declare.i _AdjustScrolls(*mg.TGrid)
  Declare.i _GridToScrolls(*mg.TGrid)
  Declare.i MySplitString(s.s, multiCharSep.s, Array a.s(1))
  Declare.i _CloseCombo(*mg.TGrid)
  
  ;--->>> Helpers routines
  
  Procedure.i MyBlendColor(Color1, Color2, Scale=50)
    Protected R1, G1, B1, R2, G2, B2, Scl.f = Scale/100
    
    R1 = Red(Color1): G1 = Green(Color1): B1 = Blue(Color1)
    R2 = Red(Color2): G2 = Green(Color2): B2 = Blue(Color2)
    ProcedureReturn RGB((R1*Scl) + (R2 * (1-Scl)), (G1*Scl) + (G2 * (1-Scl)), (B1*Scl) + (B2 * (1-Scl)))
    
  EndProcedure
  
  Procedure.i PosTextToWidth(Txt.s, Width)
    ; return under current Drawing, the left part of Txt that has a TextWidth() <= Width 
    Protected w, w0, e0, e1, e = Len(Txt)
    
    If Width <= 0 : ProcedureReturn 0 : EndIf
    Repeat
      w = TextWidth( Mid(Txt, e0+1, e-e0) )
      If (w0 + w) <= Width
        e0 = e : e = e1 : w0 = w0 + w   ; e0 succeeded so far
      Else
        e1 = e                          ; e1 denotes last failure
        e  = e0 + ((e-e0)/2)
      EndIf
      If e0 >= e : Break : EndIf
      
    ForEver
    ProcedureReturn e0
    
  EndProcedure
  
  Procedure.i MyDrawText(Txt.s,X,Y,W,H, MrgnX,MrgnY, Algn=0,Wrap=0)
    Protected x1,x2,y1,y2, mx,aw,my,ah, cc.s
    Protected i,j,n,ww,hh,x0,w0,h0,lines
    
    mx = MrgnX          ; default X-horizontal margin left/right
    my = MrgnY          ; default Y-vertical margin up/down
    aw = W - 2*mx       ; actual given width for drawing
    ah = H - 2*my       ; actual given height for drawing
    n = Len(txt)
    
    If (aw <= 0) Or (ah <= 0) Or (n <= 0) : ProcedureReturn : EndIf
    
    ww = TextWidth(txt)  
    hh = TextHeight(txt)
    If ah < hh : ProcedureReturn : EndIf
    
    If ww <= aw 
      ; we have enough room to write straight forward ...
      If algn = #Align_Left
        x1 = x + mx
      ElseIf algn = #Align_Right
        x1 = x + mx + (aw - ww)
      ElseIf algn = #Align_Center
        x1 = x + mx + ((aw - ww)/2)
      EndIf
      y1 = y + my + ((ah - hh)/2)
      DrawText(x1,y1,txt)
      ProcedureReturn
    Else
      x1 = x + mx : x2 = x1 + aw
      If wrap = #False
        aw = aw - TextWidth("...") 
        y1 = y + my + ((ah - hh)/2)
        If aw > 0 : DrawText(x1,y1, Mid(txt, 1, PosTextToWidth(txt, aw))+"...") : EndIf
        ;DrawText(x1,y1, Mid(txt, 1, PosTextToWidth(txt, aw)))
      Else
        ; we need to wrap text on another line(s) ... when wrapping we do not consider alignment (for now!)
        Protected drawnSome, iWrd,nWrd, Dim tWrd.s(0)
        
        y1 = y + my : y2 = y + H - my
        lines = Round(ww/aw,#PB_Round_Up)
        If ah - (lines*h) > 0
          y1 = y1 + ((ah - (lines*h))/2)
        EndIf
        
        nWrd = MySplitString(txt, " ", tWrd())
        For iWrd=2 To nWrd : tWrd(iWrd) = " " + tWrd(iWrd) : Next
        
        iWrd = 1
        Repeat
          If iWrd > nWrd : Break : EndIf
          ;If iWrd > 1 : x1 = DrawText(x1,y1," ") : EndIf
          ; 3 cases
          ; 1. enough room in avaliable width on current line
          ; 2. no enough room but a new line can hold the whole word
          ; 3. even a new line cant hold the word we draw whatever we can
          ww = TextWidth(tWrd(iWrd))
          If ww <= (x2-x1)
            x1 = DrawText(x1,y1,tWrd(iWrd))
            iWrd = iWrd + 1                 ; move to next word
            
          ElseIf ww <= aw
            y1 = y1 + hh : x1 = x + mx
            If y1+hh > y2 : Break : EndIf
            x1 = DrawText(x1,y1,tWrd(iWrd))
            iWrd = iWrd + 1                 ; move to next word
            
          Else
            n = PosTextToWidth(tWrd(iWrd), x2-x1)
            If n > 0
              x1 = DrawText(x1,y1, Mid(tWrd(iWrd),1,n))
              tWrd(iWrd) = Mid(tWrd(iWrd),n+1)
            Else
              y1 = y1 + hh : x1 = x + mx
              If y1+hh > y2 : Break : EndIf
            EndIf
            
          EndIf
          
          If y1+hh > y2 : Break : EndIf
        ForEver 
      EndIf
    EndIf
    
  EndProcedure
  
  Procedure.i DrawCheckBox(x,y,w,h, boxWidth, checked, borderColor)
    ; draw a check-box /(x,y,w,h) in the area given for drawing checkbox... assumes a StartDrawing!
    Protected ww,hh, x0,y0,xa,ya,xb,yb,xc,yc
    
    ww = boxWidth : hh = boxWidth
    If ww <= w And hh <= h 
      x0 = x + ((w - ww) / 2)
      y0 = y + ((h - hh) / 2)
      DrawingMode(#PB_2DDrawing_Default)
      Box(x0  ,y0  ,ww  ,hh  ,borderColor)
      Box(x0+1,y0+1,ww-2,hh-2,$D4D4D4)
      Box(x0+2,y0+2,ww-4,hh-4,$FFFFFF)
      
      If checked
        xb = x0 + (ww / 2) - 1  :   yb = y0 + hh - 5
        xa = x0 + 4             :   ya = yb - xb + xa
        xc = x0 + ww - 4        :   yc = yb + xb - xc
        
        FrontColor($C95718) ; color of the check mark: $C95718 $12A43A
        LineXY(xb,yb  ,xa,ya  ) :   LineXY(xb,yb  ,xc,yc  )
        LineXY(xb,yb-1,xa,ya-1) :   LineXY(xb,yb-1,xc,yc-1) ; move up by 1
        LineXY(xb,yb-2,xa,ya-2) :   LineXY(xb,yb-2,xc,yc-2) ; move up by 2
      EndIf
    EndIf
    
  EndProcedure
  
  Procedure.i DrawArrowDown(x,y,w,h, clr = $C95718)
    ; draw a combo-box-arrow ... assumes a StartDrawing!
    Protected xx,yy,ww,hh               ; box coord and dimensions
    
    ww = 16
    hh = 4
    If ww < w And hh < h 
      DrawingMode(#PB_2DDrawing_Default)
      xx = x + w - ww + 1
      ww = ww - 4: yy = (y+2) + (h-8)/2
      LineXY(xx+ 2,yy+ 1,xx+ww-3,yy+ 1,clr)
      LineXY(xx+ 3,yy+ 2,xx+ww-4,yy+ 2,clr)
      LineXY(xx+ 4,yy+ 3,xx+ww-5,yy+ 3,clr)
      LineXY(xx+ 5,yy+ 4,xx+ww-6,yy+ 4,clr)
    EndIf
    
  EndProcedure
  
  Procedure.i DrawArrowUp(x,y,w,h, clr = $C95718)
    ; draw a combo-box-arrow ... assumes a StartDrawing!
    Protected xx,yy,ww,hh               ; box coord and dimensions
    
    ww = 16
    hh = 4
    If ww < w And hh < h 
      DrawingMode(#PB_2DDrawing_Default)
      xx = x + w - ww + 1
      ww = ww - 4: yy = (y+1) + (h-8)/2
      LineXY(xx+ 2,yy+ 4,xx+ww-3,yy+ 4,clr)
      LineXY(xx+ 3,yy+ 3,xx+ww-4,yy+ 3,clr)
      LineXY(xx+ 4,yy+ 2,xx+ww-5,yy+ 2,clr)
      LineXY(xx+ 5,yy+ 1,xx+ww-6,yy+ 1,clr)
    EndIf
    
  EndProcedure
  
  Procedure.i DrawButton(x,y,w,h,bClr)
    ; draw a clickable button
    
    DrawingMode(#PB_2DDrawing_Default)
    Box(x,y,w,h,$FFFFFF)
    BackColor(MyBlendColor(RGB(255, 255, 255),bClr,70))
    FrontColor(bClr)
    LinearGradient(x,y,x,y+h)
    DrawingMode(#PB_2DDrawing_Gradient)
    Box(x+1,y+1,w-2,h-2)
    ;RoundBox(x,y,w,h,4,4)
    ;RoundBox(x+2,y+2,w-4,h-4,2,2)
    
    
  EndProcedure
  
  Macro       BlocksHaveIntersection(AR1,AR2,AC1,AC2, BR1,BR2,BC1,BC2)
    ; return true if there are cells in common between the two blocks A and B
    ; A is defined by AR1,AR2,AC1,AC2 .... R1 <= R2 and C1 <= C2
    ; B is defined by BR1,BR2,BC1,BC2
    
    ((AR2 >= BR1) And (BR2 >= AR1) And (AC2 >= BC1) And (BC2 >= AC1))
    
  EndMacro
  
  Macro       IsNavigationKey(K)
    Bool( (K=#PB_Shortcut_Left) Or (K=#PB_Shortcut_Right) Or (K=#PB_Shortcut_Up) Or (K=#PB_Shortcut_Down) Or (K=#PB_Shortcut_Home) Or (K=#PB_Shortcut_End) Or (K=#PB_Shortcut_PageUp) Or (K=#PB_Shortcut_PageDown) Or (K=#PB_Shortcut_Tab))
  EndMacro
  
  Procedure.i IsNumber(StrIn$, ThousandsSeparator.c, DecimalCharacter.c)
    ; skywalk SF_IsNumeric() form PB forum
    ; REV:  100405, Skywalk
    ;       Modified PureBasic Forum: Xombie(061129) + Demivec(100323)
    ;       Removed 3 constants, add Lcase, add 'd' exponent support
    ; REV:  110311, Skywalk
    ;       Enabled leading '.' to define a numeric: -.1 = -0.1
    ; Return: 0 = non-numeric value = 0
    ;         1 = positive integer
    ;        -1 = negative integer
    ;         2 = positive float
    ;        -2 = negative float
    StrIn$ = LCase(Trim(StrIn$))  ; eliminate comparisons for E & D
    Protected.i IsDecimal, CaughtThousand, CaughtDecimal, CaughtE
    Protected.i Sgn = 1, IsSignPresent, IsSignAllowed = 1, CountNumeric
    Protected.i *CurrentChar.Character = @StrIn$
    
    While *CurrentChar\c
      Select *CurrentChar\c
        Case '0' To '9'
          CountNumeric + 1
          If CaughtThousand And CountNumeric > 3
            ProcedureReturn 0
          EndIf
          IsSignAllowed = 0
        Case ThousandsSeparator
          If CaughtDecimal Or CaughtE Or CountNumeric = 0 Or (CaughtThousand And CountNumeric <> 3)
            ProcedureReturn 0
          EndIf
          CaughtThousand = 1
          CountNumeric = 0
        Case DecimalCharacter
          ;If CaughtDecimal Or CaughtE Or CountNumeric = 0 Or (CaughtThousand And CountNumeric <> 3)
          If CaughtDecimal Or CaughtE Or (CaughtThousand And CountNumeric <> 3) ; Allow leading decimal to signify a numeric
            ProcedureReturn 0
          EndIf
          CountNumeric = 0
          CaughtDecimal = 1
          IsDecimal = 1
          CaughtThousand = 0
        Case '-'
          If IsSignPresent Or Not IsSignAllowed
            ProcedureReturn 0
          EndIf 
          If Not CaughtE: Sgn = -1: EndIf
          IsSignPresent = 1
        Case '+'
          If IsSignPresent Or Not IsSignAllowed
            ProcedureReturn 0
          EndIf 
          IsSignPresent = 1
        Case 'e', 'd' ; Lcase = Don't Care -> 'E', 'D'
          If CaughtE Or CountNumeric = 0 Or (CaughtThousand And CountNumeric <> 3)
            ProcedureReturn 0
          EndIf
          CaughtE = 1
          CountNumeric = 0
          CaughtDecimal = 0
          CaughtThousand = 0
          IsSignPresent = 0
          IsSignAllowed = 1
        Default
          ProcedureReturn 0
      EndSelect
      *CurrentChar + SizeOf(Character)
    Wend
    If CountNumeric = 0 Or (CaughtThousand And CountNumeric <> 3)
      ProcedureReturn 0
    EndIf
    If IsDecimal
      ProcedureReturn 2 * Sgn ; -> Float
    EndIf
    ProcedureReturn Sgn       ; -> Integer
  EndProcedure
  
  ;--------------- >>>> Routines <<<------------------------------------------------------------
  ;--------------------------------------------------------------------------------------------------
  ;--- Row >= 0 , Col >= 0 , Tgrd is *TGrid
  
  Macro _IsValidRow( Tgrd, Row)
    Bool((Row >= 0) And (Row <= Tgrd\Rows))
  EndMacro
  
  Macro _IsValidCol( Tgrd, Col)
    Bool(Col >= 0 And Col <= Tgrd\Cols)
  EndMacro
  
  Macro _IsValidCell(Tgrd, Row, Col)
    Bool((Row >= 0) And (Row <= Tgrd\Rows) And (Col >= 0) And (Col <= Tgrd\Cols))
  EndMacro
  
  Macro _IsHeaderRow( Tgrd, Row)
    Bool((Row >= 0) And (Row < Tgrd\HdrRows))
  EndMacro
  
  Macro _IsDataRow( Tgrd, Row)
    Bool((Row >= Tgrd\HdrRows) And (Row <= Tgrd\Rows))
  EndMacro
  
  Macro _LastHeaderRow(Tgrd)
    Tgrd\HdrRows - 1
  EndMacro
  
  Macro _FirstDataRow(Tgrd)
    Tgrd\HdrRows
  EndMacro
  
  Macro _IsTopRow( Tgrd, Row)
    Bool((Row >= Tgrd\FrstTopRow) And (Row <= Tgrd\LastTopRow))
  EndMacro
  
  Macro _IsHeaderCol( Tgrd, Col)
    Bool((Col >= 0) And (Col < Tgrd\HdrCols))
  EndMacro
  
  Macro _IsDataCol( Tgrd, Col)
    Bool((Col >= Tgrd\HdrCols) And (Col <= Tgrd\Cols))
  EndMacro
  Macro _LastHeaderCol(Tgrd)
    Tgrd\HdrCols - 1
  EndMacro
  
  Macro _FirstDataCol(Tgrd)
    Tgrd\HdrCols
  EndMacro
  
  Macro _IsTopCol( Tgrd, Col)
    Bool((Col >= Tgrd\FrstTopCol) And (Col <= Tgrd\LastTopCol))
  EndMacro
  
  Macro _ResetBlock(Tgrd)
    Tgrd\Row2 = 0 : Tgrd\Col2 = 0 : Tgrd\BlockX = 0 : Tgrd\BlockY = 0 : Tgrd\BlockW = 0 : Tgrd\BlockH = 0
  EndMacro
  
  Macro _HasBlock(Tgrd)
    Bool((Tgrd\Row2 > 0) And (Tgrd\Col2 > 0) And (Tgrd\Row <> Tgrd\Row2 Or Tgrd\Col <> Tgrd\Col2))
  EndMacro
  
  Macro _ResetDownClick(Tgrd)
    Tgrd\DownX = 0 : Tgrd\DownY = 0 : Tgrd\DownAreaRow = -1 : Tgrd\DownAreaCol = -1
  EndMacro
  
  ;--- GRow , GCol Generic row/col
  
  Macro _IsValidGenericRow(Tgrd, GRow)
    Bool((GRow >= 0 And GRow <= Tgrd\Rows) Or (GRow = #RC_Any) Or (GRow = #RC_Header) Or (GRow = #RC_Data))
  EndMacro
  
  Macro _IsValidGenericCol(Tgrd, GCol)
    Bool((GCol >= 0 And GCol <= Tgrd\Cols) Or (GCol = #RC_Any) Or (GCol = #RC_Header) Or (GCol = #RC_Data))
  EndMacro
  
  Macro _ExpandGenericRow(Tgrd, GRow, R1, R2)
    If GRow >= 0
      R1 = GRow : R2 = GRow
    ElseIf GRow = #RC_Any
      R1 = 0    : R2 = Tgrd\Rows
    ElseIf GRow = #RC_Header
      R1 = 0    : R2 = Tgrd\HdrRows - 1
    ElseIf GRow = #RC_Data
      R1 = Tgrd\HdrRows  : R2 = Tgrd\Rows
    EndIf
  EndMacro
  
  Macro _ExpandGenericCol(Tgrd, GCol, C1, C2)
    If GCol >= 0
      C1 = GCol : C2 = GCol
    ElseIf GCol = #RC_Any
      C1 = 0    : C2 = Tgrd\Cols
    ElseIf GCol = #RC_Header
      C1 = 0    : C2 = Tgrd\HdrCols - 1
    ElseIf GCol = #RC_Data
      C1 = Tgrd\HdrCols  : C2 = Tgrd\Cols
    EndIf
  EndMacro
  
  Macro _AssignStyle(Tgrd, GRow, GCol, Style)
    Tgrd\DicStyle(Str(GRow) + ":" + Str(GCol)) = Style
  EndMacro
  
  Macro   _SetCellText(Tgrd, Row, Col, Txt)
    Tgrd\gData(Row, Col) = Txt
  EndMacro
  
  Macro   _GetCellText(Tgrd, Row, Col)
    Tgrd\gData(Row, Col)
  EndMacro
  
  Procedure.i _SetCellTextEvent(*mg.TGrid, Row, Col, Txt.s)
    ; used when cell content has changed via user input ... post event: #Event_Change
    *mg\ChangedCol = Col
    *mg\ChangedRow = Row
    *mg\ChangedTxt =_GetCellText(*mg, Row, Col) ; old text
    _SetCellText(*mg, Row, Col, Txt)
    PostEvent(#Event_Change, *mg\Window, *mg\Gadget) ; throw an event in the loop
  EndProcedure
  
  Procedure.i _IndexOfStyle(*mg.TGrid, StyleName.s)
    Protected i, Style = -1
    
    For i = 0 To ArraySize(*mg\Styles())
      If UCase(*mg\Styles(i)\Name) = UCase(StyleName)
        Style = i : Break
      EndIf
    Next
    ProcedureReturn Style
    
  EndProcedure
  
  Procedure.i _GetStyle( *mg.TGrid, Row, Col)
    ; R >= 0 can be masked by R, Data,Any ... a cell can be masked by upto 9 styles
    ; any parent style in that order: RD,DC,RA,AC,  DD,DA,AD,AA
    ; retunr the style index
    
    If FindMapElement(*mg\DicStyle(), Str(Row) + ":" + Str(Col)) : ProcedureReturn *mg\DicStyle() : EndIf
    
    Protected i,j, GRow, GCol
    Protected Dim row_sts(3)        ; 0: actual-row ; 1: data-row ; 2: header-row ; 3: any-row
    Protected Dim col_sts(3)        ; 0: actual-col ; 1: data-col ; 2: header-col ; 3: any-col
    
    If _IsValidRow(*mg, Row)    : row_sts(0) = 1 : EndIf
    If _IsDataRow(*mg, Row)     : row_sts(1) = 1 : EndIf
    If _IsHeaderRow(*mg, Row)   : row_sts(2) = 1 : EndIf
    
    If _IsValidCol(*mg, Col)    : col_sts(0) = 1 : EndIf
    If _IsDataCol(*mg, Col)     : col_sts(1) = 1 : EndIf
    If _IsHeaderCol(*mg, Col)   : col_sts(2) = 1 : EndIf
    
    row_sts(3) = 1
    col_sts(3) = 1
    
    For i=0 To 3
      If row_sts(i) = 0 : Continue : EndIf
      Select i
        Case 0 : GRow = Row
        Case 1 : GRow = #RC_Data
        Case 2 : GRow = #RC_Header
        Case 3 : GRow = #RC_Any
      EndSelect
      For j=0 To 3
        If col_sts(j) = 0 : Continue : EndIf
        Select j
          Case 0 : GCol = Col
          Case 1 : GCol = #RC_Data
          Case 2 : GCol = #RC_Header
          Case 3 : GCol = #RC_Any
        EndSelect
        
        If FindMapElement(*mg\DicStyle(), Str(GRow) + ":" + Str(GCol)) : ProcedureReturn *mg\DicStyle() : EndIf
        
      Next
    Next
    
    ProcedureReturn 0       ; default style
    
  EndProcedure
  
  Procedure.i _SelectStyle( *mg.TGrid, Row, Col)
    ; retunr address of relevant style
    Protected Style = _GetStyle(*mg, Row, Col)
    ProcedureReturn @*mg\Styles(Style)
    
  EndProcedure
  
  Procedure.i _MultiOfCell(*mg.TGrid, Row, Col)
    
    ForEach *mg\LstMulti()
      If Row < *mg\LstMulti()\R1 Or *mg\LstMulti()\R2 < Row : Continue : EndIf
      If Col < *mg\LstMulti()\C1 Or *mg\LstMulti()\C2 < Col : Continue : EndIf
      ProcedureReturn ListIndex(*mg\LstMulti())
    Next
    ProcedureReturn -1
    
  EndProcedure
  
  Procedure.i _ChangeColWidth(*mg.TGrid, GCol, Width, UserResize = #True, AdjustScrolls = #True)
    Protected i, C1,C2
    
    If Not _IsValidGenericCol(*mg, GCol) : ProcedureReturn : EndIf
    
    If Width < #Text_MarginX And Width <> #RC_WH_Hidden : Width = 0 : EndIf
    
    _ExpandGenericCol(*mg, GCol, C1, C2)
    If UserResize
      For i=C1 To C2
        If *mg\ColWidth(i) = #RC_WH_Hidden : Continue : EndIf
        *mg\ColWidth(i) = Width
      Next
    Else
      For i=C1 To C2
        *mg\ColWidth(i) = Width
      Next
    EndIf
    
    If AdjustScrolls : _AdjustScrolls(*mg) : EndIf
    
  EndProcedure
  
  Procedure.i _ChangeRowHeight(*mg.TGrid, GRow, Height, UserResize = #True, AdjustScrolls = #True)
    Protected i, R1,R2
    
    If Not _IsValidGenericRow(*mg, GRow) : ProcedureReturn : EndIf
    
    If Height < #Text_MarginY And Height <> #RC_WH_Hidden : Height = 0 : EndIf
    
    _ExpandGenericRow(*mg, GRow, R1, R2)
    If UserResize
      For i=R1 To R2
        If *mg\RowHeight(i) = #RC_WH_Hidden : Continue : EndIf
        *mg\RowHeight(i) = Height
      Next
    Else
      For i=R1 To R2
        *mg\RowHeight(i) = Height
      Next
    EndIf
    
    If AdjustScrolls : _AdjustScrolls(*mg) : EndIf
    
  EndProcedure
  
  Procedure.i _RefreshCombo(*mg.TGrid)
    Protected *s.TStyle
    
    *s = _SelectStyle(*mg, *mg\ComboRow, *mg\ComboCol)
    ClearGadgetItems(*mg\CmbEdit)
    If *s\CellType = #CellType_Combo
      ForEach *s\Item()
        AddGadgetItem(*mg\CmbEdit, -1, *s\Item())
      Next
    EndIf
    
  EndProcedure
  
  ;-------------------------------------------------------------------------------------------- 
  ;--- Areas & coordinates
  ;-------------------------------------------------------------------------------------------- 
  ; Row and Col are index in data-grid
  ; X, Y are coordinates on screen (visibe part of the grid)
  
  Macro _AddAreaRow(Tgrd, _Row, _Y, _H)
    AddElement( Tgrd\LstAreaRow() )
    Tgrd\LstAreaRow()\Y     = _Y
    Tgrd\LstAreaRow()\Row   = _Row
    Tgrd\LstAreaRow()\Height= _H
    Tgrd\DicAreaOfRow(Str(_Row)) = ListIndex( Tgrd\LstAreaRow() )
  EndMacro
  
  Macro _AddAreaCol(Tgrd, _Col, _X, _W)
    AddElement( Tgrd\LstAreaCol() )
    Tgrd\LstAreaCol()\X     = _X
    Tgrd\LstAreaCol()\Col   = _Col
    Tgrd\LstAreaCol()\Width = _W
    Tgrd\DicAreaOfCol(Str(_Col)) = ListIndex( Tgrd\LstAreaCol() )
  EndMacro
  
  Procedure.i _RefreshCounters(*mg.TGrid)
    ; getting first/last Top/Vis Rows/Cols
    Protected i, avl, act, strt
    
    *mg\FrstVisRow = 0
    For i = *mg\HdrRows To *mg\Rows
      If *mg\RowHeight(i) > 0 : *mg\FrstVisRow = i : Break : EndIf
    Next 
    *mg\LastVisRow  = 0
    For i = *mg\Rows To *mg\HdrRows Step -1
      If *mg\RowHeight(i) > 0 : *mg\LastVisRow = i : Break : EndIf
    Next 
    
    *mg\FrstTopRow = 0
    strt = *mg\HdrRows
    If *mg\FrzRow > strt : strt = *mg\FrzRow + 1 : EndIf
    For i = strt To *mg\Rows
      If *mg\RowHeight(i) > 0 : *mg\FrstTopRow = i : Break : EndIf
    Next
    *mg\LastTopRow = *mg\FrstTopRow
    
    avl = *mg\DrawingH
    For i = 0 To *mg\HdrRows - 1
      If *mg\RowHeight(i) > 0 : avl = avl - (*mg\RowHeight(i) - 1) : EndIf
    Next
    For i = *mg\HdrRows To *mg\FrzRow
      If *mg\RowHeight(i) > 0 : avl = avl - (*mg\RowHeight(i) - 1) : EndIf
    Next
    If avl > 0
      act = 0
      For i = *mg\Rows To *mg\FrstTopRow Step -1
        If *mg\RowHeight(i) > 0
          If act + (*mg\RowHeight(i) -1) > avl : Break : EndIf
          act = act + (*mg\RowHeight(i) - 1)
          *mg\LastTopRow = i
        EndIf
      Next
    EndIf
    If *mg\TopRow < *mg\FrstTopRow : *mg\TopRow = *mg\FrstTopRow : EndIf
    If *mg\TopRow > *mg\LastTopRow : *mg\TopRow = *mg\LastTopRow : EndIf
    
    ; ---- Cols
    *mg\FrstVisCol = 0
    For i = *mg\HdrCols To *mg\Cols
      If *mg\ColWidth(i) > 0 : *mg\FrstVisCol = i : Break : EndIf
    Next 
    *mg\LastVisCol = 0
    For i = *mg\Cols To *mg\HdrCols Step -1
      If *mg\ColWidth(i) > 0 : *mg\LastVisCol = i : Break : EndIf
    Next 
    
    *mg\FrstTopCol = 0
    strt = *mg\HdrCols
    If *mg\FrzCol > strt : strt = *mg\FrzCol + 1 : EndIf
    For i = strt To *mg\Cols
      If *mg\ColWidth(i) > 0 : *mg\FrstTopCol = i : Break : EndIf
    Next
    *mg\LastTopCol = *mg\FrstTopCol
    
    avl = *mg\DrawingW
    For i = 0 To *mg\HdrCols - 1
      If *mg\ColWidth(i) > 0 : avl = avl - (*mg\ColWidth(i) - 1) : EndIf
    Next
    For i = *mg\HdrCols To *mg\FrzCol
      If *mg\ColWidth(i) > 0 : avl = avl - (*mg\ColWidth(i) - 1) : EndIf
    Next
    If avl > 0
      act = 0
      For i = *mg\Cols To *mg\FrstTopCol Step -1
        If *mg\ColWidth(i) > 0
          If act + (*mg\ColWidth(i) -1) > avl : Break : EndIf
          act = act + (*mg\ColWidth(i) - 1)
          *mg\LastTopCol = i
        EndIf
      Next
    EndIf
    If *mg\TopCol < *mg\FrstTopCol : *mg\TopCol = *mg\FrstTopCol : EndIf
    If *mg\TopCol > *mg\LastTopCol : *mg\TopCol = *mg\LastTopCol : EndIf
    
  EndProcedure
  
  Procedure.i _BuildAreas(*mg.TGrid)
    ; Builds screen-areas Rows and Cols
    ; based on: TopRow , TopCol , visible-rows, visisble-cols
    Protected x,y,iCol,iRow,h,w
    Protected gW = *mg\DrawingW
    Protected gH = *mg\DrawingH
    
    ; initializing all non-hidden Rows, Cols to non-visible
    ClearMap(*mg\DicAreaOfRow())
    ClearMap(*mg\DicAreaOfCol())
    
    ClearList( *mg\LstAreaRow() )
    ClearList( *mg\LstAreaCol() )
    
    ; -- building row-areas
    y = 0
    *mg\HdrHeight = 0
    ; adjusts FrzRow [ HdrRows-1 ... Rows ]
    ; adjusts TopRow [ FrzRow +1 ... Rows ]
    If *mg\FrzRow < *mg\HdrRows - 1 : *mg\FrzRow = *mg\HdrRows - 1 : EndIf
    If *mg\TopRow < *mg\FrzRow  + 1 : *mg\TopRow = *mg\FrzRow  + 1 : EndIf
    For iRow = 0 To *mg\Rows 
      If y >= gH : Break : EndIf
      
      ; skip rows that are ] FrozenRow , TopRow [
      If iRow > *mg\FrzRow And iRow < *mg\TopRow : Continue : EndIf
      
      h = *mg\RowHeight(iRow)
      If h > 0
        _AddAreaRow(*mg, iRow, y, h)
        y = y + h - 1
        If _IsHeaderRow(*mg, iRow) : *mg\HdrHeight + h : EndIf
      EndIf
    Next
    
    ; -- building col-areas
    x = 0
    *mg\HdrWidth = 0
    ; adjusts FrzCol [ HdrCols - 1 ... Cols ]
    ; adjusts TopCol [ FrzCol  + 1 ... Cols ]
    If *mg\FrzCol < *mg\HdrCols - 1 : *mg\FrzCol = *mg\HdrCols - 1 : EndIf
    If *mg\TopCol < *mg\FrzCol  + 1 : *mg\TopCol = *mg\FrzCol  + 1 : EndIf
    For iCol = 0 To *mg\Cols
      If x >= gW : Break : EndIf
      
      ; skip cols that are ] FrozenCol , TopCol [
      If iCol > *mg\FrzCol And iCol < *mg\TopCol : Continue : EndIf
      
      w = *mg\ColWidth(iCol)
      If w > 0
        _AddAreaCol(*mg, iCol, x, w)
        x = x + w - 1
        If _IsHeaderCol(*mg, iCol) : *mg\HdrWidth + w : EndIf
      EndIf
    Next
    ProcedureReturn ListSize( *mg\LstAreaRow() ) * ListSize( *mg\LstAreaCol() )
    
  EndProcedure
  
  Procedure.i _AreaRow_Of_Y(*mg.TGrid, y)
    
    ForEach *mg\LstAreaRow()
      If y <= *mg\LstAreaRow()\Y                            : Continue : EndIf
      If y >  *mg\LstAreaRow()\Y + *mg\LstAreaRow()\Height  : Continue : EndIf
      ProcedureReturn ListIndex(*mg\LstAreaRow())
    Next
    ProcedureReturn -1      ; outside any area!
    
  EndProcedure
  
  Procedure.i _AreaCol_Of_X(*mg.TGrid, x)
    
    ForEach *mg\LstAreaCol()
      If x <= *mg\LstAreaCol()\X                            : Continue : EndIf
      If x >  *mg\LstAreaCol()\X + *mg\LstAreaCol()\Width   : Continue : EndIf
      ProcedureReturn ListIndex(*mg\LstAreaCol())
    Next
    ProcedureReturn -1      ; outside any area!
    
  EndProcedure
  
  Procedure.i _Row_Of_Y(*mg.TGrid, y)
    
    If _AreaRow_Of_Y(*mg, y) >= 0
      ProcedureReturn *mg\LstAreaRow()\Row
    EndIf
    ProcedureReturn -1
    
  EndProcedure
  
  Procedure.i _Col_Of_X(*mg.TGrid, x)
    
    If _AreaCol_Of_X(*mg, x) >= 0
      ProcedureReturn *mg\LstAreaCol()\Col
    EndIf
    
    ProcedureReturn -1
    
  EndProcedure
  
  Procedure.i _Area_Of_Row(*mg.TGrid, Row)
    
    If FindMapElement( *mg\DicAreaOfRow() , Str(Row))
      ProcedureReturn *mg\DicAreaOfRow()
    EndIf
    
    ProcedureReturn -1      ; row not visible
    
  EndProcedure
  
  Procedure.i _Area_Of_Col(*mg.TGrid, Col)
    
    If FindMapElement( *mg\DicAreaOfCol() , Str(Col))
      ProcedureReturn *mg\DicAreaOfCol()
    EndIf
    
    ProcedureReturn -1      ; col not visible
    
  EndProcedure
  
  Procedure.i _AreaResizeCol(*mg.TGrid, x, y)
    ; return the col-area affected by user-resize starting at (x,y)
    Protected i
    If _IsHeaderRow( *mg, _Row_Of_Y(*mg, y) )
      If x <= #ColSep_Margin
        If FirstElement(*mg\LstAreaCol())           ; checks if there is any hidden column to the left?
          For i = *mg\LstAreaCol()\Col-1 To 0 Step -1
            If *mg\ColWidth(i) = 0 : ProcedureReturn 0 : EndIf
          Next
        EndIf
      Else
        ForEach *mg\LstAreaCol()
          If Abs(*mg\LstAreaCol()\X + *mg\LstAreaCol()\Width - x) <= #ColSep_Margin
            ProcedureReturn ListIndex(*mg\LstAreaCol())
          EndIf
        Next
      EndIf
    EndIf
    ProcedureReturn -1
    
  EndProcedure
  
  Procedure.i _AreaResizeRow(*mg.TGrid, x, y)
    ; return the row-area affected by user-resize starting at (x,y)
    If _IsHeaderCol( *mg, _Col_Of_X(*mg, x) )
      ForEach *mg\LstAreaRow()
        If Abs(*mg\LstAreaRow()\Y + *mg\LstAreaRow()\Height - y) <= #RowSep_Margin
          ProcedureReturn ListIndex(*mg\LstAreaRow())
        EndIf
      Next
    EndIf
    ProcedureReturn -1
    
  EndProcedure
  
  Macro       _OverDataArea(Tgrd, _x, _y)
    Bool( (_x > Tgrd\HdrWidth) And (_y > Tgrd\HdrHeight) )
  EndMacro
  
  Macro       _OverResizeCol(Tgrd, _x, _y)
    Bool( _AreaResizeCol(Tgrd, _x, _y) >= 0 )
  EndMacro
  
  Macro       _OverResizeRow(Tgrd, _x, _y)
    Bool( _AreaResizeRow(Tgrd, _x, _y) >= 0 )
  EndMacro
  
  Macro       _OverBlock(Tgrd, _x, _y)
    Bool( Tgrd\BlockX < _x And _x <= (Tgrd\BlockX + Tgrd\BlockW) And Tgrd\BlockY < _y And _y <= (Tgrd\BlockY + Tgrd\BlockH) )
  EndMacro
  
  Macro       _OverEditor(Tgrd, _x, _y)
    Bool( Tgrd\EditorX < _x And _x <= (Tgrd\EditorX + Tgrd\EditorW) And Tgrd\EditorY < _y And _y <= (Tgrd\EditorY + Tgrd\EditorH) )
  EndMacro
  
  Macro       _OverCombo(Tgrd, _x, _y)
    Bool( Tgrd\ComboX < _x And _x <= (Tgrd\ComboX + Tgrd\ComboW) And Tgrd\ComboY < _y And _y <= (Tgrd\ComboY + Tgrd\ComboH) )
  EndMacro
  
  Procedure.i _ChangeMouse(*mg.TGrid, x, y)
    Protected r,c, *s.TStyle
    
    If _OverResizeCol(*mg, x, y)
      SetGadgetAttribute(*mg\Gadget, #PB_Canvas_Cursor,#PB_Cursor_LeftRight)
      ProcedureReturn
    EndIf
    
    If _OverResizeRow(*mg, x, y)
      SetGadgetAttribute(*mg\Gadget, #PB_Canvas_Cursor,#PB_Cursor_UpDown)
      ProcedureReturn
    EndIf
    
    If _OverDataArea(*mg, x, y)
      r = _Row_Of_Y(*mg, y)
      c = _Col_Of_X(*mg, x)
      *s = _SelectStyle(*mg, r, c)
      If *s\CellType <> #CellType_Normal
        SetGadgetAttribute(*mg\Gadget, #PB_Canvas_Cursor, #PB_Cursor_Default)
      Else
        SetGadgetAttribute(*mg\Gadget, #PB_Canvas_Cursor,#PB_Cursor_Cross)
      EndIf
      ProcedureReturn
    EndIf
    
    SetGadgetAttribute(*mg\Gadget, #PB_Canvas_Cursor,#PB_Cursor_Default)
    
    
  EndProcedure
  
  Procedure.i _RectCoord(*mg.TGrid, R1,C1,R2,C2,*bc.TRectangle)
    ; return in *bc its (X,Y,W,H) built from block [(R1,C1) ... (R2,C2)]
    Protected X,Y,W,H, ar,ac, iR,iC
    Protected gW = *mg\DrawingW
    Protected gH = *mg\DrawingH
    
    X = -1 : Y = -1 : H = 0 : W = 0
    If R1 > R2 : Swap R1 , R2 : EndIf
    If C1 > C2 : Swap C1 , C2 : EndIf
    
    PushListPosition(*mg\LstAreaRow())
    For iR = R1 To R2
      ar = _Area_Of_Row(*mg, iR)
      If ar >= 0
        SelectElement(*mg\LstAreaRow() , ar)
        If Y < 0 : Y = *mg\LstAreaRow()\Y : EndIf
        H = H + *mg\LstAreaRow()\Height - 1
      EndIf
      If Y + H > gH : Break : EndIf
    Next
    PopListPosition(*mg\LstAreaRow())
    
    PushListPosition(*mg\LstAreaCol())
    For iC = C1 To C2
      ac = _Area_Of_Col(*mg, iC)
      If ac >= 0
        SelectElement(*mg\LstAreaCol() , ac)
        If X < 0 : X = *mg\LstAreaCol()\X : EndIf
        W = W + *mg\LstAreaCol()\Width - 1
      EndIf
      If X + W > gW : Break : EndIf
    Next
    PopListPosition(*mg\LstAreaCol())
    
    If H > 0 And W > 0
      *bc\X = X
      *bc\Y = Y
      *bc\W = W+1
      *bc\H = H+1
      ProcedureReturn #True
    EndIf
    ProcedureReturn #False
    
  EndProcedure
  
  Procedure.i _BlockSize(*mg.TGrid)
    Protected bc.TRectangle
    
    _RectCoord(*mg, *mg\Row, *mg\Col, *mg\Row2, *mg\Col2, @bc)
    *mg\BlockX = bc\X
    *mg\BlockY = bc\Y
    *mg\BlockW = bc\W
    *mg\BlockH = bc\H
    
  EndProcedure
  
  Procedure.i _StartBlock(*mg.TGrid, Row1 = -1, Col1 = -1, Row2 = -1, Col2 = -1)
    ; start a new block ... reset existing one if any 
    Protected R1=Row1, C1=Col1, R2=Row2, C2=Col2, bc.TRectangle
    
    If _HasBlock(*mg)
      _ResetBlock(*mg)
    EndIf
    
    If R1 = -1 : R1 = *mg\Row : EndIf
    If R2 = -1 : R2 = *mg\Row : EndIf
    If C1 = -1 : C1 = *mg\Col : EndIf
    If C2 = -1 : C2 = *mg\Col : EndIf
    
    If Not _IsValidCell(*mg, R1, C1) : ProcedureReturn : EndIf
    If Not _IsValidCell(*mg, R2, C2) : ProcedureReturn : EndIf
    
    *mg\Row  = R1 : *mg\Col  = C1
    *mg\Row2 = R2 : *mg\Col2 = C2
    _BlockSize(*mg)
    
  EndProcedure
  
  Procedure.i _FreezeRow(*mg.TGrid, Row)
    ; freeze on specified row
    Protected iRow, rData, R1 = -1
    
    If Row < *mg\HdrRows  : ProcedureReturn : EndIf
    rData = _FirstDataRow(*mg)
    
    ; unfreezing previous frozen row
    For iRow = rData To *mg\FrzRow
      If *mg\RowHeight(iRow) < 0 And *mg\RowHeight(iRow) <> #RC_WH_Hidden
        *mg\RowHeight(iRow) = -1 * *mg\RowHeight(iRow)
      EndIf
    Next
    
    ; getting the currently first shown data-row, all non-shown above rows will be hidden
    ForEach *mg\LstAreaRow()
      If *mg\LstAreaRow()\Row >= rData
        R1 = *mg\LstAreaRow()\Row
        Break
      EndIf
    Next
    For iRow = rData To R1 - 1
      If *mg\RowHeight(iRow) > 0
        *mg\RowHeight(iRow) = -1 * *mg\RowHeight(iRow)
      EndIf
    Next
    *mg\FrzRow = Row
    
  EndProcedure
  
  Procedure.i _FreezeCol(*mg.TGrid, Col)
    ; freeze on specified col
    Protected iCol, cData, C1 = -1
    
    If Col < *mg\HdrCols  : ProcedureReturn : EndIf
    cData = _FirstDataCol(*mg)
    
    ; unfreezing previous frozen col
    For iCol = cData To *mg\FrzCol
      If *mg\ColWidth(iCol) < 0 And *mg\ColWidth(iCol) <> #RC_WH_Hidden
        *mg\ColWidth(iCol) = -1 * *mg\ColWidth(iCol)
      EndIf
    Next
    
    ; getting the currently first shown data-col, all non-shown left cols will be hidden
    ForEach *mg\LstAreaCol()
      If *mg\LstAreaCol()\Col >= cData
        C1 = *mg\LstAreaCol()\Col
        Break
      EndIf
    Next
    For iCol = cData To C1 - 1
      If *mg\ColWidth(iCol) > 0
        *mg\ColWidth(iCol) = -1 * *mg\ColWidth(iCol)
      EndIf
    Next
    *mg\FrzCol = Col
    
  EndProcedure
  
  Procedure.i _UnFreeze(*mg.TGrid)
    ; unfreeze whatever
    Protected iRow,iCol, rData,cData
    
    rData = _FirstDataRow(*mg)
    cData = _FirstDataCol(*mg)
    
    For iRow = rData To *mg\FrzRow
      If *mg\RowHeight(iRow) < 0 And *mg\RowHeight(iRow) <> #RC_WH_Hidden
        *mg\RowHeight(iRow) = -1 * *mg\RowHeight(iRow)
      EndIf
    Next
    For iCol = cData To *mg\FrzCol
      If *mg\ColWidth(iCol) < 0 And *mg\ColWidth(iCol) <> #RC_WH_Hidden
        *mg\ColWidth(iCol) = -1 * *mg\ColWidth(iCol)
      EndIf
    Next
    
    *mg\FrzRow = _LastHeaderRow(*mg)
    *mg\FrzCol = _LastHeaderCol(*mg)
    
    ; adjusting TopRow,TopCol
    ForEach *mg\LstAreaRow()
      If *mg\LstAreaRow()\Row >= rData
        *mg\TopRow = *mg\LstAreaRow()\Row
        Break
      EndIf
    Next
    ForEach *mg\LstAreaCol()
      If *mg\LstAreaCol()\Col >= cData
        *mg\TopCol = *mg\LstAreaCol()\Col
        Break
      EndIf
    Next
    
  EndProcedure
  
  ;--------------------------------------------------------------------------------------------
  ;--- Drawing
  ;--------------------------------------------------------------------------------------------
  
  Procedure.i __DrawSingleCell(*mg.TGrid, Row, Col)
    ; basic routine called by higher ones:   .......... assumes StartDrawing()
    ; _DrawCurrentCell()
    ; _Draw()
    Protected checked, wrd.s, SBColor, SFColor, SAlign, SFont, SType, SGrdnt, SImage
    Protected ar,ac,X,Y,W,H,W1,H1, img, *Style.TStyle
    
    ar = _Area_Of_Row(*mg, Row)
    ac = _Area_Of_Col(*mg, Col)
    If ar < 0 Or ac < 0 : ProcedureReturn : EndIf
    
    SelectElement(*mg\LstAreaCol(), ac)
    SelectElement(*mg\LstAreaRow(), ar)
    X  = *mg\LstAreaCol()\X
    W  = *mg\LstAreaCol()\Width
    Y  = *mg\LstAreaRow()\Y
    H  = *mg\LstAreaRow()\Height
    
    *Style = _SelectStyle(*mg, Row, Col)
    
    SBColor = *Style\BackColor
    SFColor = *Style\ForeColor
    SAlign  = *Style\Aling
    SFont   = *Style\Font
    SType   = *Style\CellType
    SGrdnt  = *Style\Gradient
    
    wrd = _GetCellText(*mg, Row, Col)
    If *mg\HideZero
      If IsNumber(wrd, *mg\ThousandsSeparator, *mg\DecimalCharacter)
        If ValD(wrd) = 0 : wrd = "" : EndIf
      EndIf
    EndIf
    
    If SGrdnt > 0
      DrawingMode(#PB_2DDrawing_Gradient)
      BackColor($F0F0F0) : FrontColor(SBColor) : LinearGradient(X,Y,X,Y+H/2)
      Box(X,Y,W,H)
    Else
      DrawingMode(#PB_2DDrawing_Default)
      Box(X,Y,W,H,SBColor)
    EndIf
    
    DrawingMode(#PB_2DDrawing_Outlined)
    Box(X,Y,W,H, *mg\ColorLine)
    
    Select SType
        
      Case #CellType_Normal
        
        If *mg\ColOfSort = Col And _IsHeaderRow(*mg, Row)
          If *mg\ColOfSortDirection = 0
            DrawArrowUp(X,Y,W,H, MyBlendColor(SBColor, SFColor, 30))
          Else
            DrawArrowDown(X,Y,W,H, MyBlendColor(SBColor, SFColor, 30))
          EndIf
          W - 16
        EndIf
        
        DrawingMode(#PB_2DDrawing_Transparent)
        If IsFont(SFont) : DrawingFont(FontID(SFont)) : EndIf
        FrontColor(SFColor)
        MyDrawText(wrd, X,Y,W,H, #Text_MarginX, #Text_MarginY, SAlign, *mg\WrapText)
        
        
      Case #CellType_Checkbox
        checked = Val(wrd)
        DrawingMode(#PB_2DDrawing_Default)
        DrawCheckBox(X,Y,W,H, #CheckBox_Width, checked, #CheckBox_Color)
        
      Case #CellType_Button
        ;DrawButton(X+2,Y+2,W-4,H-4,SBColor)
        DrawButton(X+1,Y+1,W-2,H-2,SBColor)
        DrawingMode(#PB_2DDrawing_Transparent)
        If IsFont(SFont) : DrawingFont(FontID(SFont)) : EndIf
        FrontColor(SFColor)
        MyDrawText(wrd, X,Y,W,H, #Text_MarginX, #Text_MarginY, SAlign, *mg\WrapText)
        
      Case #CellType_Combo
        DrawingMode(#PB_2DDrawing_Transparent)
        If IsFont(SFont) : DrawingFont(FontID(SFont)) : EndIf
        FrontColor(SFColor)
        MyDrawText(wrd, X,Y,W-16,H, #Text_MarginX, #Text_MarginY, SAlign, *mg\WrapText)
        
        DrawingMode(#PB_2DDrawing_Default)
        DrawArrowDown(X,Y,W,H)
        
      Case #CellType_Image
        SImage = Val(wrd)
        If IsImage(SImage)
          DrawingMode(#PB_2DDrawing_AlphaBlend) ;  #PB_2DDrawing_Default
          If SAlign = #Align_Fit
            DrawImage(ImageID(SImage), X+2,Y+2,W-4,H-4)
          Else
            If ImageWidth(SImage) <= W And ImageHeight(SImage) <= H
              W1 = (W - ImageWidth(SImage))/2
              H1 = (H - ImageHeight(SImage))/2
              DrawImage(ImageID(SImage), X+W1,Y+H1)
            Else
              img = GrabImage(SImage, #PB_Any, 0,0, W, H)
              If img
                DrawImage(ImageID(img), X, Y)
                FreeImage(img)
              EndIf
            EndIf
          EndIf
        EndIf
        
    EndSelect
    
  EndProcedure
  
  Procedure.i __DrawMultiCell(*mg.TGrid, Multi)
    ; basic routine called by higher ones:   .......... assumes StartDrawing()
    Protected checked, wrd.s, *Style.TStyle, SBColor, SFColor, SAlign, SFont, SType, SGrdnt
    Protected bc.TRectangle, mlt = -1, Row, Col, X,Y,W,H
    
    SelectElement(*mg\LstMulti(), Multi)
    If Not _RectCoord(*mg, *mg\LstMulti()\R1, *mg\LstMulti()\C1, *mg\LstMulti()\R2, *mg\LstMulti()\C2, @bc)
      ProcedureReturn
    EndIf
    
    X = bc\X
    Y = bc\Y
    W = bc\W
    H = bc\H
    
    Row = *mg\LstMulti()\R1
    Col = *mg\LstMulti()\C1
    
    *Style  = _SelectStyle(*mg, Row, Col)
    SBColor = *Style\BackColor
    SFColor = *Style\ForeColor
    SAlign  = *Style\Aling
    SFont   = *Style\Font
    SType   = *Style\CellType
    SGrdnt  = *Style\Gradient
    
    wrd = _GetCellText(*mg, Row, Col)
    If *mg\HideZero
      If IsNumber(wrd, *mg\ThousandsSeparator, *mg\DecimalCharacter)
        If ValD(wrd) = 0 : wrd = "" : EndIf
      EndIf
    EndIf
    
    If SGrdnt > 0
      DrawingMode(#PB_2DDrawing_Gradient)
      BackColor($F0F0F0) : FrontColor(SBColor) : LinearGradient(X,Y,X,Y+H/2)
      Box(X,Y,W,H)
    Else
      DrawingMode(#PB_2DDrawing_Default)
      Box(X,Y,W,H,SBColor)
    EndIf
    
    DrawingMode(#PB_2DDrawing_Outlined)
    Box(X,Y,W,H, *mg\ColorLine)
    
    Select SType
        
      Case #CellType_Normal
        
        DrawingMode(#PB_2DDrawing_Transparent)
        If IsFont(SFont) : DrawingFont(FontID(SFont)) : EndIf
        FrontColor(SFColor)
        MyDrawText(wrd, X,Y,W,H, #Text_MarginX, #Text_MarginY, SAlign, *mg\WrapText)
        
      Case #CellType_Checkbox
        checked = Val(wrd)
        DrawingMode(#PB_2DDrawing_Default)
        DrawCheckBox(X,Y,W,H, #CheckBox_Width, checked, #CheckBox_Color)
        
      Case #CellType_Button
        ;DrawButton(X+2,Y+2,W-4,H-4,SBColor)
        DrawButton(X+1,Y+1,W-2,H-2,SBColor)
        DrawingMode(#PB_2DDrawing_Transparent)
        If IsFont(SFont) : DrawingFont(FontID(SFont)) : EndIf
        FrontColor(SFColor)
        MyDrawText(wrd, X,Y,W,H, #Text_MarginX, #Text_MarginY, SAlign, *mg\WrapText)
        
      Case #CellType_Combo
        DrawingMode(#PB_2DDrawing_Transparent)
        If IsFont(SFont) : DrawingFont(FontID(SFont)) : EndIf
        FrontColor(SFColor)
        MyDrawText(wrd, X,Y,W-16,H, #Text_MarginX, #Text_MarginY, SAlign, *mg\WrapText)
        
        DrawingMode(#PB_2DDrawing_Default)
        DrawArrowDown(X,Y,W,H)
        
    EndSelect
    
  EndProcedure
  
  Procedure.i _DrawCell(*mg.TGrid, Row, Col)
    Protected Multi = _MultiOfCell(*mg, Row, Col)
    
    If Multi >= 0
      __DrawMultiCell(*mg, Multi)
    Else
      __DrawSingleCell(*mg, Row, Col)
    EndIf
    
  EndProcedure
  
  Procedure.i _DrawFocus(*mg.TGrid)
    ; draws rectangle focus in current cell .... assumes StartDrawing()
    Protected x,y,w,h,ar,ac, c, mlt
    Protected bc.TRectangle
    
    If _HasBlock(*mg)
      DrawingMode(#PB_2DDrawing_Outlined)
      x = *mg\BlockX
      w = *mg\BlockW
      y = *mg\BlockY
      h = *mg\BlockH
      c = *mg\ColorFocusBorder
      Box(x, y, w, h, c)
      Box(x+1, y+1, w-2, h-2, c)
      
    Else
      
      mlt = _MultiOfCell(*mg, *mg\Row, *mg\Col)
      If mlt < 0
        ar = _Area_Of_Row(*mg, *mg\Row)
        ac = _Area_Of_Col(*mg, *mg\Col)
        If ar >= 0 And ac >= 0
          
          SelectElement(*mg\LstAreaCol(), ac)
          SelectElement(*mg\LstAreaRow(), ar)
          DrawingMode(#PB_2DDrawing_Outlined)
          x = *mg\LstAreaCol()\X
          w = *mg\LstAreaCol()\Width
          y = *mg\LstAreaRow()\Y
          h = *mg\LstAreaRow()\Height
          c = *mg\ColorFocusBorder
          Box(x, y, w, h, c)
          Box(x+1, y+1, w-2, h-2, c)
        EndIf
        
      Else
        SelectElement( *mg\LstMulti() , mlt)
        If _RectCoord(*mg, *mg\LstMulti()\R1, *mg\LstMulti()\C1, *mg\LstMulti()\R2, *mg\LstMulti()\C2, @bc)
          DrawingMode(#PB_2DDrawing_Outlined)
          x = bc\X
          w = bc\W
          y = bc\Y
          h = bc\H
          c = *mg\ColorFocusBorder
          Box(x, y, w, h, c)
          Box(x+1, y+1, w-2, h-2, c)
        EndIf
        
      EndIf
    EndIf
    
  EndProcedure
  
  Procedure.i _MoveFocus(*mg.TGrid, Row, Col)
    If StartDrawing(CanvasOutput(*mg\Gadget)) 
      _DrawCell(*mg, *mg\Row, *mg\Col)
      *mg\Row = Row
      *mg\Col = Col
      _DrawFocus(*mg)
      StopDrawing()
    EndIf
    
  EndProcedure
  
  Procedure.i _DrawCurrentCell(*mg.TGrid)
    If StartDrawing(CanvasOutput(*mg\Gadget)) 
      _DrawCell(*mg, *mg\Row, *mg\Col)
      _DrawFocus(*mg)
      StopDrawing()
    EndIf
  EndProcedure
  
  Procedure   _Draw(*mg.TGrid, DrawNow = #False)
    Protected WW,HH,x,y,Row,Col,clr,area, ar, ac, t
    Protected mlt, Dim tMltDone.i(0)
    
    _CloseCombo(*mg)
    If (DrawNow = #False) And (*mg\NoRedraw = #True) : ProcedureReturn : EndIf
    t = ElapsedMilliseconds()
    WW = *mg\DrawingW
    HH = *mg\DrawingH
    
    ; buildign screen areas before drawing
    If _BuildAreas(*mg) = 0 : ProcedureReturn : EndIf
    ;Debug "_Draw call .."
    
    If Not StartDrawing(CanvasOutput(*mg\Gadget)) : ProcedureReturn : EndIf
    ResetGradientColors()
    
    ; 1. --- Drawing Backgrounds and Texts
    DrawingMode(#PB_2DDrawing_Default)
    Box(0,0, GadgetWidth(*mg\Gadget), GadgetHeight(*mg\Gadget), *mg\ColorBack)
    
    clr = *mg\Styles(0)\BackColor
    Box(0,0, *mg\DrawingW, *mg\DrawingH,clr)
    
    If ListSize(*mg\LstMulti()) = 0
      ForEach *mg\LstAreaRow()
        Row = *mg\LstAreaRow()\Row
        ForEach *mg\LstAreaCol()
          Col = *mg\LstAreaCol()\Col
          __DrawSingleCell(*mg, Row, Col)
        Next
      Next
    Else
      Dim tMltDone( ListSize( *mg\LstMulti()) )
      ForEach *mg\LstAreaRow()
        Row = *mg\LstAreaRow()\Row
        ForEach *mg\LstAreaCol()
          Col = *mg\LstAreaCol()\Col
          mlt = _MultiOfCell(*mg, Row, Col)
          If mlt >= 0
            If tMltDone(mlt) = 0
              __DrawMultiCell(*mg, mlt)
              tMltDone(mlt) = 1
            EndIf
          Else
            __DrawSingleCell(*mg, Row, Col)
          EndIf
        Next
      Next
    EndIf
    
    ; drawing block if any
    If _HasBlock(*mg)
      _BlockSize(*mg)
      DrawingMode(#PB_2DDrawing_AlphaBlend)
      Box(*mg\BlockX, *mg\BlockY, *mg\BlockW, *mg\BlockH,*mg\ColorBlockBack)
    EndIf
    
    ; grey-area back color
    DrawingMode(#PB_2DDrawing_Default)
    clr = *mg\ColorBack
    Box(*mg\DrawingW, 0, GadgetWidth(*mg\Gadget) - *mg\DrawingW, GadgetHeight(*mg\Gadget), clr)
    Box(0, *mg\DrawingH, GadgetHeight(*mg\Gadget) - *mg\DrawingH, GadgetWidth(*mg\Gadget), clr)
    
    If _IsHeaderRow(*mg, *mg\Row) : *mg\Row = _FirstDataRow(*mg) : EndIf
    If _IsHeaderCol(*mg, *mg\Col) : *mg\Col = _FirstDataCol(*mg) : EndIf
    
    _DrawFocus(*mg)
    
    StopDrawing()
    
    _GridToScrolls(*mg)
    
    ;Debug " DRAW .... : " + Str(ElapsedMilliseconds() - t) ;+  " ... " + _DebugBlock(*mg)
    
  EndProcedure
  
  ;-------------------------------------------------------------------------------------------- 
  ;--- Navigation & Scrolling
  ;-------------------------------------------------------------------------------------------- 
  
  Procedure.i _PrvCol(*mg.TGrid, Row, Col, MultiAsOneCell)
    ; return the previous col (left) having width > 0 OR -1
    Protected ret, multi, base = Col-1
    
    If MultiAsOneCell
      multi = _MultiOfCell(*mg, Row, Col)
      If multi >= 0
        SelectElement(*mg\LstMulti() , multi)
        base = *mg\LstMulti()\C1 - 1
      EndIf
    EndIf
    
    For ret = base To *mg\HdrCols Step  -1
      If *mg\ColWidth(ret) > 0  : ProcedureReturn ret : EndIf
    Next
    ProcedureReturn -1
    
  EndProcedure
  
  Procedure.i _NxtCol( *mg.TGrid, Row, Col, MultiAsOneCell)
    ; return the next col (right) having width > 0 OR -1
    Protected ret, multi, base = Col+1
    
    If MultiAsOneCell
      multi = _MultiOfCell(*mg, Row, Col)
      If multi >= 0
        SelectElement(*mg\LstMulti() , multi)
        base = *mg\LstMulti()\C2 + 1
      EndIf
    EndIf
    
    For ret = base To *mg\Cols
      If *mg\ColWidth(ret) > 0  : ProcedureReturn ret : EndIf
    Next
    ProcedureReturn -1
    
  EndProcedure
  
  Procedure.i _AbvRow(*mg.TGrid, Row, Col, MultiAsOneCell)
    ; return the above row (up) having height > 0 OR -1
    Protected ret, multi, base = Row-1
    
    If MultiAsOneCell
      multi = _MultiOfCell(*mg, Row, Col)
      If multi >= 0
        SelectElement(*mg\LstMulti() , multi)
        base = *mg\LstMulti()\R1 - 1
      EndIf
    EndIf
    
    For ret = base To *mg\HdrRows Step  -1
      If *mg\RowHeight(ret) > 0  : ProcedureReturn ret : EndIf
    Next
    ProcedureReturn -1
    
  EndProcedure
  
  Procedure.i _BlwRow(*mg.TGrid, Row, Col, MultiAsOneCell)
    ; return the below row (down) having height > 0 OR -1
    Protected ret, multi, base = Row+1
    
    If MultiAsOneCell
      multi = _MultiOfCell(*mg, Row, Col)
      If multi >= 0
        SelectElement(*mg\LstMulti() , multi)
        base = *mg\LstMulti()\R2 + 1
      EndIf
    EndIf
    
    For ret = base To *mg\Rows
      If *mg\RowHeight(ret) > 0  : ProcedureReturn ret : EndIf
    Next
    ProcedureReturn -1
    
  EndProcedure
  
  Procedure.i _PrvDataCol(*mg.TGrid, Col)
    ; return the previous col (left) having width > 0
    Repeat
      Col = Col - 1
      If Not _IsDataCol(*mg, Col) : Break : EndIf
      If *mg\ColWidth(Col) > 0  : ProcedureReturn Col : EndIf
    ForEver
    ProcedureReturn -1
    
  EndProcedure
  
  Procedure.i _NxtDataCol(*mg.TGrid, Col)
    ; return the next  col (left) having width > 0
    Repeat
      Col = Col + 1
      If Not _IsDataCol(*mg, Col) : Break : EndIf
      If *mg\ColWidth(Col) > 0  : ProcedureReturn Col : EndIf
    ForEver
    ProcedureReturn -1
    
  EndProcedure
  
  Procedure.i _NearestTopRow(*mg.TGrid, Row)
    ; return the TopRow that requires least moves so Row is visible
    Protected i, qH, ret, cH,cY, gH = *mg\DrawingH
    
    If Not _IsDataRow(*mg, Row)  : ProcedureReturn -1 : EndIf
    If *mg\RowHeight(Row) <= 0   : ProcedureReturn -1 : EndIf
    
    If Row < *mg\TopRow
      If Row < *mg\FrstTopRow : ProcedureReturn *mg\FrstTopRow : EndIf
      ProcedureReturn Row
      
    ElseIf FindMapElement( *mg\DicAreaOfRow() , Str(Row))                       ; Row is on screen fully/partially visible
      SelectElement(*mg\LstAreaRow() , *mg\DicAreaOfRow())
      cY = *mg\LstAreaRow()\Y
      cH = *mg\RowHeight(Row)
      
      For ret = *mg\TopRow To Row
        If *mg\RowHeight(ret) > 0 
          If cY + cH <= gH : ProcedureReturn ret : EndIf
          cY = cY - *mg\RowHeight(ret)
        EndIf
      Next
      ProcedureReturn Row
      
    Else                                                                        ; Row not on screen
      cH = 0
      ForEach *mg\LstAreaRow()
        i = *mg\LstAreaRow()\Row
        If i > *mg\FrzRow : Break : EndIf
        cH = cH + (*mg\RowHeight(i) - 1)
      Next
      cH = cH + (*mg\RowHeight(Row) - 1)
      
      ret = Row
      For i = Row-1 To *mg\FrstTopRow  Step -1
        If cH + *mg\RowHeight(i) > gH : Break : EndIf
        cH = cH + (*mg\RowHeight(i) - 1)
        ret = i
      Next
      ProcedureReturn ret
      
    EndIf
    
  EndProcedure
  
  Procedure.i _NearestTopCol(*mg.TGrid, Col)
    ; return the TopCol that requires least moves so Col is visible
    Protected i, qW, ret, cW,cX, gW = *mg\DrawingW
    
    If Not _IsDataCol(*mg, Col)  : ProcedureReturn -1 : EndIf
    If *mg\ColWidth(Col) <= 0    : ProcedureReturn -1 : EndIf
    
    If Col < *mg\TopCol
      If Col < *mg\FrstTopCol : ProcedureReturn *mg\FrstTopCol : EndIf
      ProcedureReturn Col
      
    ElseIf FindMapElement( *mg\DicAreaOfCol() , Str(Col))                       ; col is on screen fully/partially visible
      SelectElement(*mg\LstAreaCol() , *mg\DicAreaOfCol())
      cX = *mg\LstAreaCol()\X
      cW = *mg\ColWidth(Col)
      
      For ret = *mg\TopCol To Col
        If *mg\ColWidth(ret) > 0 
          If cX + cW <= gW : ProcedureReturn ret : EndIf
          cX = cX - *mg\ColWidth(ret)
        EndIf
      Next
      ProcedureReturn Col
      
    Else                                                                        ; col not on screen
      cW = 0
      ForEach *mg\LstAreaCol()
        i = *mg\LstAreaCol()\Col
        If i > *mg\FrzCol : Break : EndIf
        cW = cW + (*mg\ColWidth(i) - 1)
      Next
      cW = cW + (*mg\ColWidth(Col) - 1)
      
      ret = Col
      For i = Col-1 To *mg\FrstTopCol Step -1
        If cW + *mg\ColWidth(i) > gW : Break : EndIf
        cW = cW + (*mg\ColWidth(i) - 1)
        ret = i
      Next
      ProcedureReturn ret
      
    EndIf
    
  EndProcedure
  
  ; return true if we need to redraw
  Procedure.i _MoveUp(*mg.TGrid, xStep = 1, moveWhat = #Move_Focus)
    Protected i, stp, lmt, Row, Col
    
    If (moveWhat = #Move_Block) And (_HasBlock(*mg) = #False) : _StartBlock(*mg) : EndIf
    
    Select moveWhat
      Case #Move_Focus: Row = *mg\Row      : lmt = *mg\FrstVisRow
      Case #Move_TopRC: Row = *mg\TopRow   : lmt = *mg\FrstTopRow
      Case #Move_Block: Row = *mg\Row2     : lmt = *mg\FrstVisRow
    EndSelect
    
    If (xStep <= 0 ) Or (Row <= lmt) : ProcedureReturn #False : EndIf
    
    Col = *mg\Col
    Repeat
      i = _AbvRow(*mg, Row, Col, Bool(moveWhat = #Move_Focus))
      If i < *mg\HdrRows : Break : EndIf
      Row = i
      stp = stp + 1 : If stp >= xStep : Break : EndIf
    ForEver
    
    Select moveWhat
      Case #Move_Focus
        If Row = *mg\Row : ProcedureReturn #False : EndIf
        i = _NearestTopRow(*mg, Row)
        If *mg\TopRow <> i
          *mg\TopRow = i
          *mg\Row = Row
          ProcedureReturn #True
        Else
          _MoveFocus(*mg, Row, Col)
        EndIf
        
      Case #Move_TopRC
        If Row = *mg\TopRow : ProcedureReturn #False : EndIf
        *mg\TopRow = Row
        ProcedureReturn #True
        
      Case #Move_Block
        If Row = *mg\Row2 : ProcedureReturn #False : EndIf
        *mg\Row2 = Row
        *mg\TopRow = _NearestTopRow(*mg, *mg\Row2)
        ProcedureReturn #True
        
    EndSelect
    
  EndProcedure
  
  Procedure.i _MoveDown(*mg.TGrid, xStep = 1, moveWhat = #Move_Focus)
    Protected i, stp, lmt, Row, Col
    
    If (moveWhat = #Move_Block) And (_HasBlock(*mg) = #False) : _StartBlock(*mg) : EndIf
    
    Select moveWhat
      Case #Move_Focus: Row = *mg\Row      : lmt = *mg\LastVisRow
      Case #Move_TopRC: Row = *mg\TopRow   : lmt = *mg\LastTopRow
      Case #Move_Block: Row = *mg\Row2     : lmt = *mg\LastVisRow
    EndSelect
    
    If (xStep <= 0 ) Or (Row >= lmt) : ProcedureReturn #False : EndIf
    
    Col = *mg\Col
    Repeat
      i = _BlwRow(*mg, Row, Col, Bool(moveWhat = #Move_Focus))
      If i <= 0 : Break : EndIf
      Row = i
      stp = stp + 1 : If stp >= xStep : Break : EndIf
    ForEver
    
    Select moveWhat
      Case #Move_Focus
        If Row = *mg\Row : ProcedureReturn #False : EndIf
        i = _NearestTopRow(*mg, Row)
        If *mg\TopRow <> i
          *mg\TopRow = i
          *mg\Row = Row
          ProcedureReturn #True
        Else
          _MoveFocus(*mg, Row, Col)
        EndIf
        
      Case #Move_TopRC
        If Row = *mg\TopRow : ProcedureReturn #False : EndIf
        *mg\TopRow = Row
        ProcedureReturn #True
        
      Case #Move_Block
        If Row = *mg\Row2 : ProcedureReturn #False : EndIf
        *mg\Row2    = Row
        *mg\TopRow  = _NearestTopRow(*mg, *mg\Row2)
        ProcedureReturn #True
        
    EndSelect
    
  EndProcedure
  
  Procedure.i _MoveLeft(*mg.TGrid, xStep = 1, moveWhat = #Move_Focus)
    Protected i, stp, lmt, Row, Col
    
    If (moveWhat = #Move_Block) And (_HasBlock(*mg) = #False) : _StartBlock(*mg) : EndIf
    
    Select moveWhat
      Case #Move_Focus: Col = *mg\Col      : lmt = *mg\FrstVisCol
      Case #Move_TopRC: Col = *mg\TopCol   : lmt = *mg\FrstTopCol
      Case #Move_Block: Col = *mg\Col2     : lmt = *mg\FrstVisCol
    EndSelect
    
    If (xStep <= 0 ) Or (Col <= lmt) : ProcedureReturn #False : EndIf
    
    Row = *mg\Row
    Repeat
      i = _PrvCol(*mg, Row, Col, Bool(moveWhat = #Move_Focus))
      If i < *mg\HdrCols : Break : EndIf
      Col = i
      stp = stp + 1 : If stp >= xStep : Break : EndIf
    ForEver
    
    Select moveWhat
      Case #Move_Focus
        If Col = *mg\Col : ProcedureReturn #False : EndIf
        i = _NearestTopCol(*mg, Col)
        If *mg\TopCol <> i
          *mg\TopCol = i
          *mg\Col = Col
          ProcedureReturn #True
        Else
          _MoveFocus(*mg, Row, Col)
        EndIf
        
      Case #Move_TopRC
        If Col = *mg\TopCol : ProcedureReturn #False : EndIf
        *mg\TopCol = Col
        ProcedureReturn #True
        
      Case #Move_Block
        If Col = *mg\Col2 : ProcedureReturn #False : EndIf
        *mg\Col2    = Col
        ;*mg\TopRow  = _NearestTopRow(*mg, *mg\Row2)
        *mg\TopCol  = _NearestTopCol(*mg, *mg\Col2)
        ProcedureReturn #True
        
    EndSelect
    
  EndProcedure
  
  Procedure.i _MoveRight(*mg.TGrid, xStep = 1, moveWhat = #Move_Focus)
    Protected i, stp, lmt, Row, Col
    
    If (moveWhat = #Move_Block) And (_HasBlock(*mg) = #False) : _StartBlock(*mg) : EndIf
    
    Select moveWhat
      Case #Move_Focus: Col = *mg\Col      : lmt = *mg\LastVisCol
      Case #Move_TopRC: Col = *mg\TopCol   : lmt = *mg\LastTopCol
      Case #Move_Block: Col = *mg\Col2     : lmt = *mg\LastVisCol
    EndSelect
    
    If (xStep <= 0 ) Or (Col >= lmt) : ProcedureReturn #False : EndIf
    
    Row = *mg\Row
    Repeat
      i = _NxtCol(*mg, Row, Col, Bool(moveWhat = #Move_Focus))
      If i <= 0 : Break : EndIf
      Col = i
      stp = stp + 1 : If stp >= xStep : Break : EndIf
    ForEver
    
    Select moveWhat
      Case #Move_Focus
        If Col = *mg\Col : ProcedureReturn #False : EndIf
        i = _NearestTopCol(*mg, Col)
        If *mg\TopCol <> i
          *mg\TopCol = i
          *mg\Col = Col
          ProcedureReturn #True
        Else
          _MoveFocus(*mg, Row, Col)
        EndIf
        
      Case #Move_TopRC
        If Col = *mg\TopCol : ProcedureReturn #False : EndIf
        *mg\TopCol = Col
        ProcedureReturn #True
        
      Case #Move_Block
        If Col = *mg\Col2 : ProcedureReturn #False : EndIf
        *mg\Col2    = Col
        ;*mg\TopRow  = _NearestTopRow(*mg, *mg\Row2)
        *mg\TopCol  = _NearestTopCol(*mg, *mg\Col2)
        ProcedureReturn #True
        
    EndSelect
    
  EndProcedure
  
  Procedure.i _ExtendBlock_XY(*mg.TGrid, X,Y)
    ; extends current block via pressed mouse-move ; x,y are coord within canvas ( x<0 or x>gw -> outside)
    Protected Row,Col, xStep, oStep = 10
    Protected gW = *mg\DrawingW
    Protected gH = *mg\DrawingH
    
    ;Debug " XXXX _ExtendBlock_XY X = " + Str(X) + " , Y = " + Str(Y)
    ;If (Y < 0) Or (Y > *mg\Height) Or (X < 0) Or (X > *mg\Width) ; outside
    
    If (X < 0) And (Y < 0)
      _MoveLeft( *mg, oStep, #Move_Block)
      _MoveUp(   *mg, oStep, #Move_Block)
      ProcedureReturn #True
      
    ElseIf (X > gW) And (Y > gH)
      _MoveRight(*mg, oStep, #Move_Block)
      _MoveDown( *mg, oStep, #Move_Block)
      ProcedureReturn #True
      
    ElseIf (X > gW) And (Y < 0)
      _MoveRight(*mg, oStep, #Move_Block)
      _MoveUp(   *mg, oStep, #Move_Block)
      ProcedureReturn #True
      
    ElseIf (X < 0) And (Y > gH)
      _MoveLeft(*mg, oStep, #Move_Block)
      _MoveDown(*mg, oStep, #Move_Block)
      ProcedureReturn #True
      
    Else
      ; 0 < x < gW [OR] 0 < y < gH 
      Row = _Row_Of_Y(*mg, Y)
      Col = _Col_Of_X(*mg, X)
      
      If (Row = *mg\Row2) And (Col = *mg\Col2) : ProcedureReturn #False : EndIf
      ;Debug " XXXX _ExtendBlock_XY          Row = " + Str(Row) + " , Col = " + Str(Col)
      
      If (_IsHeaderCol(*mg, Col) = #False) And (*mg\Col2 <> Col) And (Col >= 0)
        xStep = Abs(*mg\Col2 - Col)
        If Col > *mg\Col2   : _MoveRight(*mg, xStep, #Move_Block) : EndIf
        If Col < *mg\Col2   : _MoveLeft( *mg, xStep, #Move_Block) : EndIf
        *mg\Col2 = Col
      EndIf
      If Col >= 0 And Row < 0
        If Y < 0            : _MoveUp(   *mg, oStep, #Move_Block) : EndIf
        If Y > gH           : _MoveDown( *mg, oStep, #Move_Block) : EndIf
      EndIf
      
      If (_IsHeaderRow(*mg,Row) = #False) And (*mg\Row2 <> Row) And (Row >= 0)
        xStep = Abs(*mg\Row2 - Row)
        If Row > *mg\Row2   : _MoveDown(*mg, xStep, #Move_Block) : EndIf
        If Row < *mg\Row2   : _MoveUp(  *mg, xStep, #Move_Block) : EndIf
        *mg\Row2 = Row
      EndIf
      If Col < 0 And Row >= 0
        If X < 0            : _MoveLeft( *mg, oStep, #Move_Block) : EndIf
        If X > gW           : _MoveRight(*mg, oStep, #Move_Block) : EndIf
      EndIf
      ProcedureReturn #True
    EndIf
    
  EndProcedure
  
  Procedure.i _AdjustScrolls(*mg.TGrid)
    ; Scrolls settings, ideally we have: [FirstTop = minState] And [LastTop = maxState] and [StateFactor = 1]
    ; if we cant then we use proprtional: FirstTop # minState and LastTop # maxState
    ; Needs be called after any change in the number of visible Cols/Rows
    Protected i, scrPage
    
    ;If *mg\NoRedraw : ProcedureReturn : EndIf       ; 17-aug-2014
    
    _RefreshCounters(*mg)
    If IsGadget(*mg\ColScroll)
      If *mg\LastTopCol <= #Scroll_Max
        ; LastTop = scrMax - scrPage + 1  ==>  scrMax = LastTop + scrPage - 1
        ; we have full match:  CurTop = 1 * CurState
        scrPage = #Scroll_PageSize
        SetGadgetAttribute(*mg\ColScroll, #PB_ScrollBar_Minimum, *mg\FrstTopCol)
        SetGadgetAttribute(*mg\ColScroll, #PB_ScrollBar_PageLength, scrPage)
        SetGadgetAttribute(*mg\ColScroll, #PB_ScrollBar_Maximum, *mg\LastTopCol + scrPage - 1)
        *mg\StateFactorCol = 1
        *mg\ColScrollMin   = *mg\FrstTopCol
        *mg\ColScrollMax   = *mg\LastTopCol
      Else
        ; we have packet match:  CurTop = Factor * CurState
        scrPage = #Scroll_PageSize
        SetGadgetAttribute(*mg\ColScroll, #PB_ScrollBar_Minimum, *mg\FrstTopCol)
        SetGadgetAttribute(*mg\ColScroll, #PB_ScrollBar_PageLength, scrPage)
        SetGadgetAttribute(*mg\ColScroll, #PB_ScrollBar_Maximum, #Scroll_Max + scrPage - 1)
        *mg\StateFactorCol = (*mg\LastTopCol - *mg\FrstTopCol) / (#Scroll_Max - *mg\FrstTopCol)
        *mg\ColScrollMin   = *mg\FrstTopCol
        *mg\ColScrollMax   = #Scroll_Max
      EndIf
    EndIf
    
    If IsGadget(*mg\RowScroll)
      If *mg\LastTopRow <= #Scroll_Max
        ; LastTop = scrMax - scrPage + 1  ==>  scrMax = LastTop + scrPage - 1
        ; we have full match:  CurTop = 1 * CurState
        scrPage = #Scroll_PageSize
        SetGadgetAttribute(*mg\RowScroll, #PB_ScrollBar_Minimum, *mg\FrstTopRow)
        SetGadgetAttribute(*mg\RowScroll, #PB_ScrollBar_PageLength, scrPage)
        SetGadgetAttribute(*mg\RowScroll, #PB_ScrollBar_Maximum, *mg\LastTopRow + scrPage - 1)
        *mg\StateFactorRow = 1
        *mg\RowScrollMin   = *mg\FrstTopRow
        *mg\RowScrollMax   = *mg\LastTopRow
      Else
        ; we have packet match:  CurTop = Factor * CurState
        scrPage = #Scroll_PageSize
        SetGadgetAttribute(*mg\RowScroll, #PB_ScrollBar_Minimum, *mg\FrstTopRow)
        SetGadgetAttribute(*mg\RowScroll, #PB_ScrollBar_PageLength, scrPage)
        SetGadgetAttribute(*mg\RowScroll, #PB_ScrollBar_Maximum, #Scroll_Max + scrPage - 1)
        *mg\StateFactorRow = (*mg\LastTopRow - *mg\FrstTopRow) / (#Scroll_Max - *mg\FrstTopRow)
        *mg\RowScrollMin   = *mg\FrstTopRow
        *mg\RowScrollMax   = #Scroll_Max
      EndIf
    EndIf
    ;Debug " StateFactorRow = " + StrF(*mg\StateFactorRow)
  EndProcedure
  
  Procedure.i _GridToScrolls(*mg.TGrid)
    ; updates Scrolls are per Grid fields: TopCol / TopRow
    Protected curState, curTop
    
    If IsGadget(*mg\ColScroll)
      curTop = *mg\TopCol
      
      If *mg\FrstTopCol = *mg\LastTopCol Or curTop = *mg\FrstTopCol
        curState = *mg\ColScrollMin
        
      ElseIf curTop = *mg\LastTopCol
        curState = *mg\ColScrollMax
        
      Else
        If *mg\StateFactorCol : curState = Int(curTop / *mg\StateFactorCol) : EndIf
      EndIf
      SetGadgetState(*mg\ColScroll , curState)
    EndIf
    
    If IsGadget(*mg\RowScroll)
      curTop = *mg\TopRow
      
      If *mg\FrstTopRow = *mg\LastTopRow Or curTop = *mg\FrstTopRow
        curState = *mg\RowScrollMin
        
      ElseIf curTop = *mg\LastTopRow
        curState = *mg\RowScrollMax
        
      Else
        If *mg\StateFactorRow : curState = Int(curTop / *mg\StateFactorRow) : EndIf
      EndIf
      SetGadgetState(*mg\RowScroll , curState)
    EndIf
    
  EndProcedure
  
  Procedure.i _ScrollsToGrid(*mg.TGrid, AdjustCol.i)
    ; read scrolls states and update grid fields: TopCol/TopRow
    Protected curState, curTop, redraw
    
    If IsGadget(*mg\ColScroll) And AdjustCol
      curState = GetGadgetState(*mg\ColScroll)
      
      If curState = *mg\ColScrollMin Or *mg\ColScrollMax = *mg\ColScrollMin
        curTop = *mg\FrstTopCol
      ElseIf curState = *mg\ColScrollMax
        curTop = *mg\LastTopCol
      Else
        curTop = *mg\StateFactorCol * curState
      EndIf
      If curTop < *mg\FrstTopCol : curTop = *mg\FrstTopCol : EndIf
      If curTop > *mg\LastTopCol : curTop = *mg\LastTopCol : EndIf
      
      If     curTop < *mg\TopCol  ; moving right
        Repeat
          If *mg\ColWidth(curTop) > 0  : Break : EndIf
          If curTop <= *mg\FrstTopCol : Break : EndIf
          curTop = curTop - 1
        ForEver
      ElseIf curTop > *mg\TopCol  ; moving left
        Repeat
          If *mg\ColWidth(curTop) > 0 : Break : EndIf
          If curTop >= *mg\LastTopCol : Break : EndIf
          curTop = curTop + 1
        ForEver
      EndIf
      
      If *mg\TopCol <> curTop
        *mg\TopCol = curTop
        redraw = #True
      EndIf
    EndIf
    
    If IsGadget(*mg\RowScroll)  And AdjustCol = 0
      curState = GetGadgetState(*mg\RowScroll)
      
      If curState = *mg\RowScrollMin Or *mg\RowScrollMax = *mg\RowScrollMin
        curTop = *mg\FrstTopRow
      ElseIf curState = *mg\RowScrollMax
        curTop = *mg\LastTopRow
      Else
        curTop = *mg\StateFactorRow * curState
      EndIf
      If curTop < *mg\FrstTopRow : curTop = *mg\FrstTopRow : EndIf
      If curTop > *mg\LastTopRow : curTop = *mg\LastTopRow : EndIf
      
      If     curTop < *mg\TopRow  ; moving up
        Repeat
          If *mg\RowHeight(curTop) > 0  : Break : EndIf
          If curTop <= *mg\FrstTopRow : Break : EndIf
          curTop = curTop - 1
        ForEver
      ElseIf curTop > *mg\TopRow  ; moving down
        Repeat
          If *mg\RowHeight(curTop) > 0 : Break : EndIf        ; [CHECK]
          If curTop >= *mg\LastTopRow : Break : EndIf
          curTop = curTop + 1
        ForEver
      EndIf
      
      If *mg\TopRow <> curTop
        *mg\TopRow = curTop
        redraw = #True
      EndIf
      ;Debug GetGadgetAttribute(*mg\RowScroll, #PB_ScrollBar_Minimum)
      ;Debug GetGadgetAttribute(*mg\RowScroll, #PB_ScrollBar_Maximum)
      ;Debug *mg\TopRow
    EndIf
    
    ProcedureReturn redraw
    
  EndProcedure
  
  Procedure.i _SynchronizeGridCols()
    ; internal event handler: update cols as per ColScroll ... requested by end-user
    Protected *mg.TGrid = GetGadgetData(EventGadget())
    
    If _ScrollsToGrid(*mg, #True)
      _Draw(*mg)
    EndIf
    
  EndProcedure
  
  Procedure.i _SynchronizeGridRows()
    ; internal event handler: update rows as per RowScroll ... requested by end-user
    Protected *mg.TGrid = GetGadgetData(EventGadget())
    
    If _ScrollsToGrid(*mg, #False)
      _Draw(*mg)
    EndIf
    
  EndProcedure
  
  ;-------------------------------------------------------------------------------------------- 
  ;--- Editing
  ;-------------------------------------------------------------------------------------------- 
  
  Procedure.i _HideCombo(*mg.TGrid, State)
    If state
      HideGadget(*mg\CmbEdit, 1)
      RemoveKeyboardShortcut(*mg\Window, #PB_Shortcut_Escape)
      RemoveKeyboardShortcut(*mg\Window, #PB_Shortcut_Tab)
      RemoveKeyboardShortcut(*mg\Window, #PB_Shortcut_Tab | #PB_Shortcut_Shift)
      RemoveKeyboardShortcut(*mg\Window, #PB_Shortcut_Return)
      SetActiveGadget(*mg\Gadget)
    Else
      HideGadget(*mg\CmbEdit, 0)
      AddKeyboardShortcut(*mg\Window, #PB_Shortcut_Escape, #EventMenu_Escape)
      AddKeyboardShortcut(*mg\Window, #PB_Shortcut_Tab, #EventMenu_Tab)
      AddKeyboardShortcut(*mg\Window, #PB_Shortcut_Tab | #PB_Shortcut_Shift, #EventMenu_Tab)
      AddKeyboardShortcut(*mg\Window, #PB_Shortcut_Return, #EventMenu_Return)
   EndIf    
  EndProcedure
  
  Procedure.i _CloseEdit(*mg.TGrid, Cancel = #False)
    Protected   txt.s
    If *mg\Editor
      txt = MyEdit::CloseEdit(*mg\Editor)
      If Not Cancel
        _SetCellTextEvent(*mg, *mg\EditorRow, *mg\EditorCol, txt)
      EndIf
      If StartDrawing(CanvasOutput(*mg\Gadget)) 
        _DrawCell(*mg, *mg\EditorRow, *mg\EditorCol)
        _DrawFocus(*mg)
        StopDrawing()
      EndIf
      *mg\Editor = 0
    EndIf
  EndProcedure
  
  Procedure.i _CloseCombo(*mg.TGrid)
    If *mg\Combo
      *mg\Combo = 0
      _HideCombo(*mg, 1)
    EndIf
  EndProcedure
  
  Procedure.i _ComboCallback()
    Protected   CmbGdt, GrdGdt, *mg.TGrid, txt.s
    
    CmbGdt  = EventGadget()
    GrdGdt  = GetGadgetData(CmbGdt)
    If IsGadget(GrdGdt)
      *mg = GetGadgetData(GrdGdt)
      If IsGadget(*mg\Combo)
        Select EventType()
          Case #EventTypeMenu_Escape
            _CloseCombo(*mg)
          Case #PB_EventType_LeftDoubleClick, #EventTypeMenu_Return, #EventTypeMenu_Tab
            txt = GetGadgetText(CmbGdt) 
            _SetCellTextEvent(*mg, *mg\ComboRow, *mg\ComboCol, txt)
            If StartDrawing(CanvasOutput(*mg\Gadget)) 
              _DrawCell(*mg, *mg\ComboRow, *mg\ComboCol)
              _DrawFocus(*mg)
              StopDrawing()
            EndIf
            _CloseCombo(*mg)
        EndSelect
      EndIf
    EndIf
    
  EndProcedure
  
  Procedure.i _ManageEdit(*mg.TGrid, ky.s, EnterPressed, SimpleClick)
    ; takes care of opening the editor/combo ...
    Protected winNbr, gdt, evnt, evMn, evGt, evTy, gEvt, exitEdit.i = #False, nr=-1,nc=-1
    Protected multi,ar,ac,r,c,x,y,w,h,editMode, lstEdit, oTxt.s, nTxt.s, wrd.s
    Protected *Style.TStyle
    Protected bc.TRectangle
    Protected gW = *mg\DrawingW
    Protected gH = *mg\DrawingH
    
    _CloseEdit(*mg, #True)
    _CloseCombo(*mg)
    
    multi = _MultiOfCell(*mg, *mg\Row, *mg\Col)
    If multi >= 0
      SelectElement(*mg\LstMulti() , multi)
      r = *mg\LstMulti()\R1 : c = *mg\LstMulti()\C1
    Else
      r = *mg\Row : c = *mg\Col
    EndIf
    *Style = _SelectStyle(*mg, r, c)
    
    If Not *Style\Editable : ProcedureReturn #False : EndIf
    
    ar = _Area_Of_Row(*mg, r)
    ac = _Area_Of_Col(*mg, c)
    If ar < 0 Or ac < 0 : ProcedureReturn #False : EndIf
    
    If multi >= 0
      SelectElement( *mg\LstMulti() , multi)
      If _RectCoord(*mg, *mg\LstMulti()\R1, *mg\LstMulti()\C1, *mg\LstMulti()\R2, *mg\LstMulti()\C2, @bc)
        x = bc\X
        w = bc\W
        y = bc\Y
        h = bc\H
      EndIf
    Else
      SelectElement(*mg\LstAreaCol(), ac)
      SelectElement(*mg\LstAreaRow(), ar)
      x = *mg\LstAreaCol()\X + 1 ;+ GadgetX(*mg\Gadget)
      w = *mg\LstAreaCol()\Width - 2
      y = *mg\LstAreaRow()\Y +1 ;+ GadgetY(*mg\Gadget)
      h = *mg\LstAreaRow()\Height - 2
    EndIf
    
    oTxt = _GetCellText(*mg, r, c)       ; original cell text
    nTxt = oTxt
    
    winNbr = *mg\Window
    
    Select *Style\CellType
        
      Case #CellType_Checkbox
        ; an Enter or Space in a Checkbox are equivalent to Button-Click (check/uncheck)
        If ky = " "  Or EnterPressed Or SimpleClick 
          If  Val(oTxt) = 0
            _SetCellTextEvent(*mg, r, c, "1")
          Else
            _SetCellTextEvent(*mg, r, c, "0")
          EndIf
          _DrawCurrentCell(*mg)
        EndIf
        ProcedureReturn #False
        
      Case #CellType_Button
        If ky = " "  Or EnterPressed Or SimpleClick 
          *mg\ClickedRow = r : *mg\ClickedCol = c
          PostEvent(#Event_Click, *mg\Window, *mg\Gadget) ; throw an event in the loop
        EndIf
        ProcedureReturn #False
        
      Case #CellType_Combo
        wrd = ky
        If SimpleClick Or EnterPressed : wrd = oTxt : EndIf
        
        With *mg            ; we enter edit mode
          If y + #Combo_Height < \DrawingH
            \ComboX = x
            \ComboY = y + h
          Else
            \ComboX = x
            \ComboY = y - #Combo_Height
          EndIf
          \ComboW = w
          \ComboH = #Combo_Height
          \ComboRow = r
          \ComboCol = c
        EndWith
        _RefreshCombo(*mg)
        ResizeGadget(*mg\CmbEdit, *mg\ComboX, *mg\ComboY, *mg\ComboW, *mg\ComboH)
        *mg\Combo = *mg\CmbEdit
        SetGadgetColor(*mg\CmbEdit, #PB_Gadget_BackColor, *Style\BackColor)
        SetGadgetColor(*mg\CmbEdit, #PB_Gadget_FrontColor, *Style\ForeColor)
        
        _HideCombo(*mg, 0)
        
        If wrd <> "" : SetGadgetText(*mg\CmbEdit, wrd) : EndIf
        SetActiveGadget(*mg\CmbEdit)
        ProcedureReturn #False
        
        
      Case #CellType_Normal
        If SimpleClick : ProcedureReturn #False : EndIf ; getting focus is not entring edit mode!
        wrd = ky
        If EnterPressed : wrd = oTxt : EndIf
        
        With *mg            ; we enter edit mode
          \EditorX = x
          \EditorY = y
          \EditorW = w
          \EditorH = h
          \EditorRow = r
          \EditorCol = c
          \Editor = MyEdit::OpenEdit(*mg\Window, *mg\Gadget, wrd, x,y,w,h, *Style\Font)
          \EditorFull = EnterPressed
        EndWith
        MyEdit::SetCaretPos(*mg\Editor)     ; sets the caret at the end
                                            ;MyEdit::SelectText(*mg\Editor, 1)    ; select all
        ProcedureReturn #False
        
      Default
        ProcedureReturn #False
        
    EndSelect
    
  EndProcedure
  
  Procedure.i _UserResize(*mg.TGrid, x, y)
    ; we resize only if:
    ;       1. we are in the area of col-header
    ;  OR   2. we are in the area of row-header
    ;  OR   3. we are in both col-header and row-header
    ;
    ; if resizing from left/up -> resizing that column/row
    ; if resizing from right/down -> un-hiding any next hidden column/row
    ; DownX, DownY store coord. when resizing started
    ;   
    Protected i, px, py, c, r, nwVal, oAreaRow, oAreaCol, crs
    
    px = *mg\DownX
    py = *mg\DownY
    If px = x  And py = y : ProcedureReturn : EndIf
    
    oAreaRow = _AreaResizeRow(*mg, px, py)
    oAreaCol = _AreaResizeCol(*mg, px, py)
    
    crs      = GetGadgetAttribute(*mg\Gadget, #PB_Canvas_Cursor)
    
    ; resizing column or unhiding a col that was shrunk to 0 by user
    If oAreaCol >= 0 And y < *mg\HdrHeight And crs = #PB_Cursor_LeftRight
      
      SelectElement(*mg\LstAreaCol() , oAreaCol)
      
      If oAreaCol = 0 And px <= #ColSep_Margin
        c = *mg\LstAreaCol()\Col
        For i = *mg\LstAreaCol()\Col-1 To 0 Step -1
          If *mg\ColWidth(i) = 0
            c = i: Break
          EndIf
          If *mg\ColWidth(i) > 0 : Break : EndIf
        Next
        nwVal = *mg\ColWidth(c) + (x - px) : If nwVal < 0 : nwVal = 0 : EndIf
        _ChangeColWidth(*mg, c, nwVal)
      Else
        If px <= *mg\LstAreaCol()\X + *mg\LstAreaCol()\Width
          c = *mg\LstAreaCol()\Col
          nwVal = *mg\ColWidth(c) + (x - px) : If nwVal < 0 : nwVal = 0 : EndIf
          _ChangeColWidth(*mg, c, nwVal)
        Else
          c = *mg\LstAreaCol()\Col
          For i = *mg\LstAreaCol()\Col+1 To *mg\Cols
            If *mg\ColWidth(i) = 0
              c = i: Break
            EndIf
            If *mg\ColWidth(i) > 0 : Break : EndIf
          Next
          nwVal = *mg\ColWidth(c) + (x - px) : If nwVal < 0 : nwVal = 0 : EndIf
          _ChangeColWidth(*mg, c, nwVal)
        EndIf
      EndIf
    EndIf
    
    ; resizing row or unhiding a row that was shrunk to 0 by user
    If oAreaRow >= 0 And x < *mg\HdrWidth And crs = #PB_Cursor_UpDown
      
      SelectElement(*mg\LstAreaRow() , oAreaRow)
      
      If py <= *mg\LstAreaRow()\Y + *mg\LstAreaRow()\Height
        r = *mg\LstAreaRow()\Row
        nwVal = *mg\RowHeight(r) + (y - py) : If nwVal < 0 : nwVal = 0 : EndIf
        _ChangeRowHeight(*mg, r, nwVal)
      Else
        r = *mg\LstAreaRow()\Row
        For i = *mg\LstAreaRow()\Row+1 To *mg\Rows
          If *mg\RowHeight(i) = 0
            r = i: Break
          EndIf
          If *mg\RowHeight(i) > 0 : Break : EndIf
        Next
        nwVal = *mg\RowHeight(r) + (y - py) : If nwVal < 0 : nwVal = 0 : EndIf
        _ChangeRowHeight(*mg, r, nwVal)
      EndIf
      
    EndIf
    
  EndProcedure
  
  Procedure.i _ManageMouseMove(*mg.TGrid, x, y)
    ; 1. Change cursor to allow resizing: Col/Row
    ; 2. Resizing Col/Row
    ; 3. Scrolling Up/Down
    ; 4. selecting a block of cell
    
    Protected ar, ac, mv, row, col
    
    mv = *mg\MoveStatus
    ;Debug " >>>>>> MoveStatus : " + Str(mv)
    Select mv
      Case #MouseMove_Nothing
        ar = _AreaRow_Of_Y(*mg, y)
        ac = _AreaCol_Of_X(*mg, x)
        
        If ar >= 0 And ac >= 0
          row = *mg\LstAreaRow()\Row
          col = *mg\LstAreaCol()\Col
          
          If _OverDataArea(*mg, x, y)      ; data area
            If *mg\DownAreaRow >= 0 And *mg\DownAreaCol >= 0 And (*mg\DownAreaRow <> ar Or *mg\DownAreaCol <> ac)
              *mg\MoveStatus = #MouseMove_Select
              _StartBlock(*mg)
            EndIf
            
          ElseIf _IsHeaderRow(*mg, row) And _IsHeaderCol(*mg, col)
            If Abs(*mg\LstAreaCol()\X + *mg\LstAreaCol()\Width - x) <= #ColSep_Margin Or Abs(*mg\LstAreaCol()\X - x) <= #ColSep_Margin Or Abs(*mg\LstAreaRow()\Y + *mg\LstAreaRow()\Height - y) <= #RowSep_Margin Or Abs(*mg\LstAreaRow()\Y - y) <= #RowSep_Margin
              *mg\MoveStatus = #MouseMove_Resize
            Else
              *mg\MoveStatus = #MouseMove_Select
              _StartBlock(*mg, *mg\FrstVisRow, *mg\FrstVisCol, *mg\LastVisRow, *mg\LastVisCol)
              _Draw(*mg)       ; <<<< return true
            EndIf
            
          ElseIf _IsHeaderRow(*mg, row) 
            If Abs(*mg\LstAreaCol()\X + *mg\LstAreaCol()\Width - x) <= #ColSep_Margin Or Abs(*mg\LstAreaCol()\X - x) <= #ColSep_Margin
              *mg\MoveStatus = #MouseMove_Resize
            Else
              *mg\MoveStatus = #MouseMove_Select
              _StartBlock(*mg, *mg\FrstVisRow, *mg\LstAreaCol()\Col, *mg\LastVisRow, *mg\LstAreaCol()\Col)
              _Draw(*mg)   ; <<<< return true
            EndIf
            
          ElseIf _IsHeaderCol(*mg, col) 
            If Abs(*mg\LstAreaRow()\Y + *mg\LstAreaRow()\Height - y) <= #RowSep_Margin Or Abs(*mg\LstAreaRow()\Y - y) <= #RowSep_Margin
              *mg\MoveStatus = #MouseMove_Resize
            Else
              *mg\MoveStatus = #MouseMove_Select
              _StartBlock(*mg, *mg\LstAreaRow()\Row, *mg\FrstVisCol, *mg\LstAreaRow()\Row, *mg\LastVisCol)
              _Draw(*mg)   ; <<<< return true
            EndIf
            
          EndIf
          
        EndIf
        
      Case #MouseMove_Select
        If _ExtendBlock_XY(*mg, x, y) : _Draw(*mg) : EndIf
        
      Case #MouseMove_Resize
        
    EndSelect
    
  EndProcedure
  
  Procedure.i _DoEventMenuShortcutKey()
    Protected gadget
    Select EventMenu()
      Case #EventMenu_Escape
        gadget = GetActiveGadget()
        If IsGadget(gadget) And GadgetType(gadget) = #PB_GadgetType_ListView
          PostEvent(#PB_Event_Gadget, GetActiveWindow(), gadget, #EventTypeMenu_Escape)
        EndIf
      Case #EventMenu_Tab
        gadget = GetActiveGadget()
        If IsGadget(gadget) And GadgetType(gadget) = #PB_GadgetType_ListView
          PostEvent(#PB_Event_Gadget, GetActiveWindow(), gadget, #EventTypeMenu_Tab)
        EndIf
      Case #EventMenu_Return
        gadget = GetActiveGadget()
        If IsGadget(gadget) And GadgetType(gadget) = #PB_GadgetType_ListView
          PostEvent(#PB_Event_Gadget, GetActiveWindow(), gadget, #EventTypeMenu_Return)
        EndIf
    EndSelect
  EndProcedure
  
  ;-------------------------------------------------------------------------------------------- 
  ;--- Init and default 
  ;-------------------------------------------------------------------------------------------- 
  
  Procedure.i _RefreshRowNumbers(*mg.TGrid)
    Protected   r
    If *mg\ShowRowNumbers
      For r = *mg\HdrRows To *mg\Rows
        _SetCellText(*mg, r, 0, Str(r))
      Next
    EndIf
  EndProcedure
  
  Procedure.i _Reset(*mg.TGrid, Rows, Cols)
    ; Reset everything so Grid can receive/show new data
    Protected i,j, *Style.TStyle
    
    ; 1. Reset the basic part (without PB objects - should not be reset)
    ClearStructure(*mg, TGridBasic)
    InitializeStructure(*mg, TGridBasic)
    
    ; 2. initializations
    If rows < 0 : rows = 0  : EndIf
    If cols < 0 : cols = 0  : EndIf
    
    *mg\Rows = rows : Dim *mg\RowHeight(rows)   : Dim *mg\RowData(rows)
    *mg\Cols = cols : Dim *mg\ColWidth(cols)    : Dim *mg\ColData(cols) : Dim *mg\ColSortOnClick(cols)
    
    Dim *mg\gData(*mg\Rows, *mg\Cols)       ; Reset data ---> gData(r,c) = ""
    If ArraySize(*mg\gData()) < 0 
      Debug "failed to allocate memory for the grid data !... "
      ProcedureReturn 0
    EndIf
    
    *mg\HdrRows             = 1
    *mg\HdrCols             = 1
    *mg\TopRow              = 1
    *mg\TopCol              = 1
    *mg\Row                 = 1
    *mg\Col                 = 1
    
    *mg\ColorLine          = RGB(230, 230, 230) ;RGB(224, 224, 224)
    *mg\ColorBlockBack     = RGBA(220, 220, 220, 90)
    *mg\ColorFocusBack     = RGB(255, 255, 255)
    *mg\ColorBack          = RGB(242, 242, 242)
    *mg\ColorFocusBorder   = RGB(198, 0, 0) ; RGB(0, 0, 198)
    
    ;"ABCDEFGHIJKLMNOPQRSTUVWXYZ"
    For i=1 To cols
      _SetCellText(*mg, 0, i, "Col " + Str(i))
    Next
    
    _RefreshRowNumbers(*mg)
    
    _ChangeColWidth(*mg, #RC_Any, #Default_ColWidth)
    _ChangeRowHeight(*mg, #RC_Any, #Default_RowHeight)
    
    
    ; adding one default style applies to the whole grid
    Dim *mg\Styles(0)
    *mg\Styles(0)\Name          = "Default"            ; this is the 'Default' style at index 0
    *mg\Styles(0)\Aling         = #Align_Left
    *mg\Styles(0)\BackColor     = $FFFFFF
    *mg\Styles(0)\ForeColor     = $000000
    *mg\Styles(0)\Font          = -1 ; LoadFont(#PB_Any, "Arial", 8)
    *mg\Styles(0)\CellType      = #CellType_Normal
    *mg\Styles(0)\Editable      = #False
    *mg\Styles(0)\Gradient      = 0
    
    *mg\ColOfSort               = -1
    ClearList(*mg\SortingCol())
    
    ; set first/last, ..., min/max/page of scrolls
    _AdjustScrolls(*mg)
    
    ProcedureReturn (*mg\Rows + 1) * (*mg\Cols + 1)
    
  EndProcedure
  
  Procedure.i _ChangRowCountAndColCount(*mg.TGrid, Rows, Cols)
    ; 'redim' rows and cols while preserving content
    Protected   r,c, oRows = *mg\Rows, oCols = *mg\Cols
    Protected   Dim t.s(0,0)
    
    CopyArray(*mg\gData(), t())
    If ArraySize(t()) < 0           : ProcedureReturn 0 : EndIf
    If Rows < 0 : Rows = 0 : EndIf
    If Cols < 0 : Cols = 0 : EndIf
    
    Dim *mg\gData(Rows, Cols)
    If ArraySize(*mg\gData()) < 0   : ProcedureReturn 0 : EndIf
    
    *mg\Rows = Rows : ReDim *mg\RowHeight(Rows) : ReDim *mg\RowData(Rows)
    *mg\Cols = Cols : ReDim *mg\ColWidth(Cols)  : ReDim *mg\ColData(Cols) : ReDim *mg\ColSortOnClick(Cols)
    
    For r = oRows + 1 To Rows
      *mg\RowHeight(r) = #Default_RowHeight
    Next
    For c = oCols + 1 To Cols
      *mg\ColWidth(c) = #Default_ColWidth
    Next
    
    For r = 0 To Rows
      If r > oRows : Break : EndIf
      For c = 0 To *mg\Cols
        If c > oCols : Break : EndIf
        *mg\gData(r, c) = t(r, c)
      Next
    Next
    
    _RefreshRowNumbers(*mg)
    
    If *mg\TopRow > *mg\Rows : *mg\TopRow = *mg\Rows : EndIf
    If *mg\Row    > *mg\Rows : *mg\Row    = *mg\Rows : EndIf
    If *mg\Row2   > *mg\Rows : *mg\Row2   = *mg\Rows : EndIf
    If *mg\TopCol > *mg\Cols : *mg\TopCol = *mg\Cols : EndIf
    If *mg\Col    > *mg\Cols : *mg\Col    = *mg\Cols : EndIf
    If *mg\Col2   > *mg\Cols : *mg\Col2   = *mg\Cols : EndIf
    
    _AdjustScrolls(*mg)      ; set min/max/page of scrolls
    
    ProcedureReturn 1
  EndProcedure
  
  Procedure.i _ChangRowCount(*mg.TGrid, Rows)
    ProcedureReturn _ChangRowCountAndColCount(*mg, Rows, *mg\Cols)
  EndProcedure
  
  Procedure.i _ChangColCount(*mg.TGrid, Cols)
    ProcedureReturn _ChangRowCountAndColCount(*mg, *mg\Rows, Cols)
  EndProcedure
  
  
  ;-------------------------------------------------------------------------------------------- 
  ;--<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
  ;-------------------------------------------------------------------------------------------- 
  ;--- Public - works with PB Gadget number
  ;    Only exposed routines should call _Draw()
  ;-------------------------------------------------------------------------------------------- 
  
  Procedure   Resize(Gdt.i, X,Y,W,H)
    Protected   *mg.TGrid = GetGadgetData(Gdt)
    
    If X = #PB_Ignore : X = GadgetX(Gdt)     : EndIf
    If Y = #PB_Ignore : Y = GadgetY(Gdt)     : EndIf
    If W = #PB_Ignore : W = GadgetWidth(Gdt) : EndIf
    If H = #PB_Ignore : H = GadgetHeight(Gdt): EndIf
    
    ResizeGadget(Gdt, X, Y , W, H)
    *mg\DrawingW = W
    *mg\DrawingH = H
    ; -- resizing scroll bars 
    If IsGadget(*mg\ColScroll) : *mg\DrawingH = *mg\DrawingH - #Scroll_Width : EndIf
    If IsGadget(*mg\RowScroll) : *mg\DrawingW = *mg\DrawingW - #Scroll_Width : EndIf
    
    If IsGadget(*mg\ColScroll)
      ResizeGadget( *mg\ColScroll, 0, *mg\DrawingH, *mg\DrawingW, #Scroll_Width)
    EndIf
    If IsGadget(*mg\RowScroll)
      ResizeGadget( *mg\RowScroll, *mg\DrawingW, 0, #Scroll_Width, *mg\DrawingH)
    EndIf    

    _AdjustScrolls(*mg)
    _Draw(*mg, #True)
    
  EndProcedure
  
  Procedure.i NoRedraw(Gdt)
    ; stops drawing - useful when many settings that should yield a drawing each are 
    ; grouped together ... once applying those settings is over, we draw once only
    Protected *mg.TGrid = GetGadgetData(Gdt)
    *mg\NoRedraw = #True
  EndProcedure
  
  Procedure.i Redraw(Gdt)
    Resize(Gdt, #PB_Ignore, #PB_Ignore, #PB_Ignore, #PB_Ignore)
  EndProcedure
  
  Procedure.i MoveUp(   Gdt, xStep, moveWhat)
    If _MoveUp(GetGadgetData(Gdt), xStep, moveWhat) : _Draw(GetGadgetData(Gdt)) : EndIf
  EndProcedure
  
  Procedure.i MoveDown( Gdt, xStep, moveWhat)
    If _MoveDown(GetGadgetData(Gdt), xStep, moveWhat) : _Draw(GetGadgetData(Gdt)) : EndIf
  EndProcedure
  
  Procedure.i MoveLeft( Gdt, xStep, moveWhat)
    If _MoveLeft(GetGadgetData(Gdt), xStep, moveWhat) : _Draw(GetGadgetData(Gdt)) : EndIf
  EndProcedure
  
  Procedure.i MoveRight(Gdt, xStep, moveWhat)
    If _MoveRight(GetGadgetData(Gdt), xStep, moveWhat) : _Draw(GetGadgetData(Gdt)) : EndIf
  EndProcedure
  
  Procedure.i ShowCell(Gdt.i, Row, Col, SetCellFocus = #False)
    ; makes sure cell defined by (Row,Col) is visible on screen - scrolls if need be
    Protected *mg.TGrid = GetGadgetData(Gdt)
    Protected tr, tc
    
    If _IsValidCell(*mg, Row, Col) = #False : ProcedureReturn #False : EndIf
    
    If *mg\RowHeight(Row) <= 0  : ProcedureReturn #False : EndIf
    If *mg\ColWidth(Col)  <= 0  : ProcedureReturn #False : EndIf
    
    tr = _NearestTopRow(*mg, Row)
    tc = _NearestTopCol(*mg, Col)
    If tr <> *mg\TopRow Or tc <> *mg\TopCol
      *mg\TopRow = tr   : *mg\TopCol = tc
      If SetCellFocus
        *mg\Row = row : *mg\Col = col
      EndIf
      _Draw(*mg)
    Else
      _MoveFocus(*mg, Row, Col)
    EndIf
    
    ProcedureReturn #True
    
  EndProcedure
  
  Procedure.i ShowRow(Gdt.i, Row)
    ; makes sure row is visible on screen - scrolls if need be
    Protected tr, *mg.TGrid = GetGadgetData(Gdt)
    
    If _IsValidRow(*mg, Row) = #False   : ProcedureReturn #False : EndIf
    If *mg\RowHeight(Row) <= 0          : ProcedureReturn #False : EndIf
    
    tr = _NearestTopRow(*mg, Row)
    If tr <> *mg\TopRow
      *mg\TopRow = tr
      _Draw(*mg)
    EndIf
    
    ProcedureReturn #True
    
  EndProcedure
  
  Procedure.i ShowCol(Gdt.i, Col)
    ; makes sure Col is visible on screen - scrolls if need be
    Protected tc, *mg.TGrid = GetGadgetData(Gdt)
    
    If _IsValidCol(*mg, Col) = #False   : ProcedureReturn #False : EndIf
    If *mg\ColWidth(Col)  <= 0          : ProcedureReturn #False : EndIf
    
    tc = _NearestTopCol(*mg, Col)
    If tc <> *mg\TopCol
      *mg\TopCol = tc
      _Draw(*mg)
    EndIf
    ProcedureReturn #True
    
  EndProcedure
  
  Procedure.i FocusCell(Gdt, Row, Col)
    ; moves the focus from current cell to the new one defind by param
    ShowCell(Gdt, Row, Col, #True)
  EndProcedure
  
  Procedure.i DrawCell(Gdt, Row, Col)
    Protected *mg.TGrid = GetGadgetData(Gdt)
    
    If Not StartDrawing(CanvasOutput(*mg\Gadget)) : ProcedureReturn : EndIf
    _DrawCell(*mg, Row, Col)
    StopDrawing()
    
  EndProcedure
  
  Procedure.i DrawRow(Gdt, Row)
    Protected Col, *mg.TGrid = GetGadgetData(Gdt)
    
    If Not StartDrawing(CanvasOutput(*mg\Gadget)) : ProcedureReturn : EndIf
    For Col = 0 To *mg\Cols
      _DrawCell(*mg, Row, Col)
    Next
    StopDrawing()
    
  EndProcedure
  
  Procedure.i DrawCol(Gdt, Col)
    Protected Row, *mg.TGrid = GetGadgetData(Gdt)
    
    If Not StartDrawing(CanvasOutput(*mg\Gadget)) : ProcedureReturn : EndIf
    For Row = 0 To *mg\Rows
      _DrawCell(*mg, Row, Col)
    Next
    StopDrawing()
    
  EndProcedure
  
  ;-- Grid level ------------------------------------------
  
  Procedure.i AddDefaultStyles(Gdt.i, HdrBColor.i = $DEC4B0)
    ; makes some useful styles available without assigning any!
    Protected   Style.s, cWhite, cBlack, cBlue, cDarkBlue, cBlueGray, cLightGray, cLavender
    
    cWhite      = $FFFFFF
    cBlack      = $000000
    cBlue       = $FF0000
    cDarkBlue   = $8B0000
    cBlueGray   = $997D5F
    cLightGray  = $F2F2F2
    cLavender   = $F5F0FF
    
    CompilerSelect #PB_Compiler_OS
      CompilerCase #PB_OS_Windows
        Protected   Font_T8    = LoadFont(#PB_Any, "Tahoma", 8)
      CompilerCase #PB_OS_MacOS
        Protected   Font_T8    = LoadFont(#PB_Any, "Arial",11)
    CompilerEndSelect
    
    ; removing any previously defined tyle
    ClearStyles(Gdt)
    
    ; ...................   Align       Back        Front       Font        Editable    Gradient
    ; Default               Left        White       Black       Font_T8     No          No
    ; HeaderGradient        Center      HdrBColor   cDarkBlue   Font_T8     No          Yes
    ; Header                Center      HdrBColor   cDarkBlue   Font_T8     No          No
    ; HeaderLeft            Left        HdrBColor   cDarkBlue   Font_T8     No          No
    ; HeaderRight           Right       HdrBColor   cDarkBlue   Font_T8     No          Yes
    ; Left                  Left        White       Black       Font_T8     No          No
    ; Center                Center      White       Black       Font_T8     No          No
    ; Right                 Right       White       Black       Font_T8     No          No
    ; EditLeft              Left        White       Black       Font_T8     Yes         No
    ; EditCenter            Center      White       Black       Font_T8     Yes         No
    ; EditRight             Right       White       Black       Font_T8     Yes         No
    ; Extra                 Right       cLightGray  Black       Font_T8     No          No
    ; Detail                Left        cLavender   Black       Font_T8     No          No
    ; Checkbox              Center      White       Black       Font_T8     Yes         No
    ; Combo                 Center      White       Black       Font_T8     Yes         No
    ; Button                Center      $CFCFCF     Black       Font_T8     Yes         No
    ; Image                 Center      White       Black       Font_T8     No          No
    ; ImageFit              Fit         White       Black       Font_T8     No          No
    
    ; revise default grid style: locked-left
    Style = "Default"
    SetStyleAlign(     Gdt, Style, #Align_Left)
    SetStyleBackColor( Gdt, Style, cWhite)
    SetStyleForeColor( Gdt, Style, cBlack)
    SetStyleFont(      Gdt, Style, Font_T8)
    SetStyleEditable(  Gdt, Style, #False)
    
    ; can be used as row-header style
    Style = "HeaderGradient" : AddNewStyle(Gdt, Style)
    SetStyleAlign(     Gdt, Style, #Align_Center)
    SetStyleBackColor( Gdt, Style, HdrBColor)
    SetStyleForeColor( Gdt, Style, cDarkBlue)
    SetStyleFont(      Gdt, Style, Font_T8)
    SetStyleEditable(  Gdt, Style, #False)
    SetStyleGradient(  Gdt, Style, #True)
    
    Style = "Header" : AddNewStyle(Gdt, Style)
    SetStyleAlign(     Gdt, Style, #Align_Center)
    SetStyleBackColor( Gdt, Style, HdrBColor)
    SetStyleForeColor( Gdt, Style, cDarkBlue)
    SetStyleFont(      Gdt, Style, Font_T8)
    SetStyleEditable(  Gdt, Style, #False)
    
    Style = "HeaderLeft" : AddNewStyle(Gdt, Style)
    SetStyleAlign(     Gdt, Style, #Align_Left)
    SetStyleBackColor( Gdt, Style, HdrBColor)
    SetStyleForeColor( Gdt, Style, cDarkBlue)
    SetStyleFont(      Gdt, Style, Font_T8)
    SetStyleEditable(  Gdt, Style, #False)
    
    Style = "HeaderRight" : AddNewStyle(Gdt, Style)
    SetStyleAlign(     Gdt, Style, #Align_Right)
    SetStyleBackColor( Gdt, Style, HdrBColor)
    SetStyleForeColor( Gdt, Style, cDarkBlue)
    SetStyleFont(      Gdt, Style, Font_T8)
    SetStyleEditable(  Gdt, Style, #False)
    
    Style = "Left" : AddNewStyle(Gdt, Style)
    SetStyleAlign(     Gdt, Style, #Align_Left)
    SetStyleEditable(  Gdt, Style, #False)
    
    Style = "Center" : AddNewStyle(Gdt, Style)
    SetStyleAlign(     Gdt, Style, #Align_Center)
    SetStyleEditable(  Gdt, Style, #False)
    
    Style = "Right" : AddNewStyle(Gdt, Style)
    SetStyleAlign(     Gdt, Style, #Align_Right)
    SetStyleEditable(  Gdt, Style, #False)
    
    Style = "EditLeft" : AddNewStyle(Gdt, Style)
    SetStyleAlign(     Gdt, Style, #Align_Left)
    SetStyleEditable(  Gdt, Style, #True)
    
    Style = "EditCenter" : AddNewStyle(Gdt, Style)
    SetStyleAlign(     Gdt, Style, #Align_Center)
    SetStyleEditable(  Gdt, Style, #True)
    
    Style = "EditRight" : AddNewStyle(Gdt, Style)
    SetStyleAlign(     Gdt, Style, #Align_Right)
    SetStyleEditable(  Gdt, Style, #True)
    
    Style = "Extra" : AddNewStyle(Gdt, Style)
    SetStyleAlign(     Gdt, Style, #Align_Right)
    SetStyleBackColor( Gdt, Style, cLightGray)
    SetStyleEditable(  Gdt, Style, #False)
    
    Style = "Detail" : AddNewStyle(Gdt, Style)
    SetStyleAlign(     Gdt, Style, #Align_Left)
    SetStyleBackColor( Gdt, Style, cLavender)
    SetStyleEditable(  Gdt, Style, #False)
    
    Style = "Checkbox" : AddNewStyle(Gdt, Style)
    SetStyleAlign(     Gdt, Style, #Align_Center)
    SetStyleCellType(  Gdt, Style, #CellType_Checkbox)
    SetStyleEditable(  Gdt, Style, #True)
    
    Style = "Combo" : AddNewStyle(Gdt, Style)
    SetStyleAlign(     Gdt, Style, #Align_Center)
    SetStyleCellType(  Gdt, Style, #CellType_Combo)
    SetStyleEditable(  Gdt, Style, #True)
    
    ; Edit col : button
    Style = "Button" : AddNewStyle(Gdt, Style)
    SetStyleAlign(     Gdt, Style, #Align_Center)
    SetStyleBackColor( Gdt, Style, RGB(207, 207, 207))
    SetStyleCellType(  Gdt, Style, #CellType_Button)
    SetStyleEditable(  Gdt, Style, #True)
    
    ; Image actual szie - centered within cell
    Style = "Image" : AddNewStyle(Gdt, Style)
    SetStyleBackColor( Gdt, Style, cWhite)
    SetStyleCellType(  Gdt, Style, #CellType_Image)
    SetStyleEditable(  Gdt, Style, #False)
    
    ; Image stretched
    Style = "ImageFit" : AddNewStyle(Gdt, Style)
    SetStyleAlign(     Gdt, Style, #Align_Fit)
    SetStyleCellType(  Gdt, Style, #CellType_Image)
    SetStyleEditable(  Gdt, Style, #False)
    
  EndProcedure
  
  Procedure.i IsValidCell(Gdt.i, Row, Col)
    Protected *mg.TGrid = GetGadgetData(Gdt)
    
    ProcedureReturn _IsValidCell(*mg, Row, Col)
  EndProcedure
  
  Procedure.i GetCurRow(Gdt.i)
    Protected   *mg.TGrid = GetGadgetData(Gdt)
    ProcedureReturn *mg\Row
  EndProcedure
  
  Procedure.i GetCurCol(Gdt.i)
    Protected   *mg.TGrid = GetGadgetData(Gdt)
    ProcedureReturn *mg\Col
  EndProcedure
  
  Procedure.i GetRowCount(Gdt.i)
    Protected   *mg.TGrid = GetGadgetData(Gdt)
    ProcedureReturn *mg\Rows
  EndProcedure
  
  Procedure.i GetColCount(Gdt.i)
    Protected   *mg.TGrid = GetGadgetData(Gdt)
    ProcedureReturn *mg\Cols
  EndProcedure
  
  Procedure.i GetHeaderRowCount(Gdt.i)
    Protected   *mg.TGrid = GetGadgetData(Gdt)
    ProcedureReturn *mg\HdrRows
  EndProcedure
  
  Procedure.i GetHeaderColCount(Gdt.i)
    Protected   *mg.TGrid = GetGadgetData(Gdt)
    ProcedureReturn *mg\HdrCols
  EndProcedure
  
  Procedure.i GetTopRow(Gdt.i)
    Protected   *mg.TGrid = GetGadgetData(Gdt)
    ProcedureReturn *mg\TopRow
  EndProcedure
  Procedure.i GetTopCol(Gdt.i)
    Protected   *mg.TGrid = GetGadgetData(Gdt)
    ProcedureReturn *mg\TopCol
  EndProcedure
  
  Procedure.i GetBlockRow2(Gdt.i)
    Protected   *mg.TGrid = GetGadgetData(Gdt)
    ProcedureReturn *mg\Row2
  EndProcedure
  
  Procedure.i GetBlockCol2(Gdt.i)
    Protected   *mg.TGrid = GetGadgetData(Gdt)
    ProcedureReturn *mg\Col2
  EndProcedure
  
  Procedure.i GetColorLine(Gdt.i)
    Protected   *mg.TGrid = GetGadgetData(Gdt)
    ProcedureReturn *mg\ColorLine
  EndProcedure
  
  Procedure.i GetColorBack(Gdt.i)
    Protected   *mg.TGrid = GetGadgetData(Gdt)
    ProcedureReturn *mg\ColorBack
  EndProcedure
  
  Procedure.i GetColorFocusBack(Gdt.i)
    Protected   *mg.TGrid = GetGadgetData(Gdt)
    ProcedureReturn *mg\ColorFocusBack
  EndProcedure
  
  Procedure.i GetColorFocusBorder(Gdt.i)
    Protected   *mg.TGrid = GetGadgetData(Gdt)
    ProcedureReturn *mg\ColorFocusBorder
  EndProcedure
  
  Procedure.i GetColorBlockBack(Gdt.i)
    Protected   *mg.TGrid = GetGadgetData(Gdt)
    ProcedureReturn *mg\ColorBlockBack
  EndProcedure
  
  Procedure.i GetNonHiddenRowCount(Gdt.i)
    ; rows that are not hidden for good (either visible or can be made visible by user)
    Protected i,n, *mg.TGrid = GetGadgetData(Gdt)
    For i=1 To *mg\Rows
      If *mg\RowHeight(i) <> -1 : n = n + 1: EndIf
    Next
    ProcedureReturn n
  EndProcedure
  
  Procedure.i GetNonHiddenColCount(Gdt.i)
    ; cols that are not hidden for good (either visible or can be made visible by user)
    Protected i,n, *mg.TGrid = GetGadgetData(Gdt)
    For i=1 To *mg\Cols
      If *mg\ColWidth(i) <> -1 : n = n + 1: EndIf
    Next
    ProcedureReturn n
  EndProcedure
  
  Procedure.i SetCurRow(Gdt.i, Value.i)
    Protected   *mg.TGrid = GetGadgetData(Gdt)
    If Value >= 0 And Value <= *mg\Rows : *mg\Row = Value : EndIf
  EndProcedure
  
  Procedure.i SetCurCol(Gdt.i, Value.i)
    Protected   *mg.TGrid = GetGadgetData(Gdt)
    If Value >= 0 And Value <= *mg\Cols : *mg\Col = Value : EndIf
  EndProcedure
  
  Procedure.i SetRowCount(Gdt.i, Rows.i)
    Protected *mg.TGrid = GetGadgetData(gdt)
    
    _ChangRowCount(*mg, Rows)
    _Draw(*mg)
    
  EndProcedure
  
  Procedure.i SetColCount(Gdt.i, Cols.i)
    Protected   *mg.TGrid = GetGadgetData(gdt)
    
    _ChangColCount(*mg, Cols)
    _Draw(*mg)
    
  EndProcedure
  
  Procedure.i SetHeaderRowCount(Gdt.i, Rows.i)
    Protected   *mg.TGrid = GetGadgetData(Gdt)
    *mg\HdrRows = Rows
  EndProcedure
  
  Procedure.i SetHeaderColCount(Gdt.i, Cols.i)
    Protected   *mg.TGrid = GetGadgetData(Gdt)
    *mg\HdrCols = Cols
  EndProcedure
  
  Procedure.i SetTopRow(Gdt.i, Value.i)
    Protected   *mg.TGrid = GetGadgetData(Gdt)
    If Value >= 0 And Value <= *mg\Rows : *mg\TopRow = Value : EndIf
  EndProcedure
  
  Procedure.i SetTopCol(Gdt.i, Value.i)
    Protected   *mg.TGrid = GetGadgetData(Gdt)
    If Value >= 0 And Value <= *mg\Cols : *mg\TopCol = Value : EndIf
  EndProcedure
  
  Procedure.i SetBlockRow2(Gdt.i, Value.i)
    Protected   *mg.TGrid = GetGadgetData(Gdt)
    If Value >= 0 And Value <= *mg\Rows : *mg\Row2 = Value : EndIf
  EndProcedure
  
  Procedure.i SetBlockCol2(Gdt.i, Value.i)
    Protected   *mg.TGrid = GetGadgetData(Gdt)
    If Value >= 0 And Value <= *mg\Cols : *mg\Col2 = Value : EndIf
  EndProcedure
  
  Procedure.i SetColorLine(Gdt.i, Value.i)
    Protected   *mg.TGrid = GetGadgetData(Gdt)
    *mg\ColorLine = Value
  EndProcedure
  
  Procedure.i SetColorBack(Gdt.i, Value.i)
    Protected   *mg.TGrid = GetGadgetData(Gdt)
    *mg\ColorBack = Value
  EndProcedure
  
  Procedure.i SetColorFocusBack(Gdt.i, Value.i)
    Protected   *mg.TGrid = GetGadgetData(Gdt)
    *mg\ColorFocusBack = Value
  EndProcedure
  
  Procedure.i SetColorFocusBorder(Gdt.i, Value.i)
    Protected   *mg.TGrid = GetGadgetData(Gdt)
    *mg\ColorFocusBorder = Value
  EndProcedure
  
  Procedure.i SetColorBlockBack(Gdt.i, Value.i)
    Protected   *mg.TGrid = GetGadgetData(Gdt)
    *mg\ColorBlockBack = Value
  EndProcedure
  
  ;- Event related
  
  Procedure.i GetChangedRow(Gdt.i)
    Protected *mg.TGrid = GetGadgetData(Gdt)
    ProcedureReturn *mg\ChangedRow
  EndProcedure
  
  Procedure.i GetChangedCol(Gdt.i)
    Protected *mg.TGrid = GetGadgetData(Gdt)
    ProcedureReturn *mg\ChangedCol
  EndProcedure
  
  Procedure.i GetClickedRow(Gdt.i)
    Protected *mg.TGrid = GetGadgetData(Gdt)
    ProcedureReturn *mg\ClickedRow
  EndProcedure
  
  Procedure.i GetClickedCol(Gdt.i)
    Protected *mg.TGrid = GetGadgetData(Gdt)
    ProcedureReturn *mg\ClickedCol
  EndProcedure
  
  Procedure.s GetChangedText(Gdt.i)
    Protected *mg.TGrid = GetGadgetData(Gdt)
    ProcedureReturn *mg\ChangedTxt
  EndProcedure
  
  Procedure.i ClearLastChange(Gdt.i)
    Protected *mg.TGrid = GetGadgetData(Gdt)
    
    *mg\ChangedRow = -1
    *mg\ChangedCol = -1
    *mg\ChangedTxt = ""
    
  EndProcedure
  
  Procedure.i ClearLastClick(Gdt.i)
    Protected *mg.TGrid = GetGadgetData(Gdt)
    
    *mg\ClickedRow = -1
    *mg\ClickedCol = -1
    
  EndProcedure
  
  Procedure.i HideZero(Gdt.i, State = #True)
    Protected *mg.TGrid = GetGadgetData(Gdt)
    *mg\HideZero = State
  EndProcedure
  
  Procedure.i ClearData(Gdt.i)
    ; clear the content of gData() array
    Protected *mg.TGrid = GetGadgetData(gdt)
    
    Dim *mg\gData(*mg\Rows, *mg\Cols)       ; clear data ---> gData(r,c) = ""
    _Draw(*mg)
    
  EndProcedure
  
  Procedure.i Reset(Gdt.i, Rows, Cols)
    Protected *mg.TGrid = GetGadgetData(gdt)
    
    _Reset(*mg, Rows, Cols)
    AddDefaultStyles(Gdt)
    _Draw(*mg)
    
  EndProcedure
  
  Procedure.i AddRow(Gdt.i)
    Protected *mg.TGrid = GetGadgetData(gdt)
    Protected nRows = *mg\Rows + 1
    
    If _ChangRowCount(*mg, nRows)
      ShowCell(Gdt, nRows, *mg\HdrCols, #True)
    EndIf
    
    ProcedureReturn *mg\Rows
    
  EndProcedure
  
  Procedure.i AddCol(Gdt.i)
    Protected *mg.TGrid = GetGadgetData(gdt)
    Protected nCols = *mg\Cols + 1
    
    If _ChangColCount(*mg, nCols)
      ShowCell(Gdt, *mg\HdrRows, nCols, #True)
    EndIf
    
    ProcedureReturn *mg\Cols
    
  EndProcedure
  
  Procedure.i SetText(Gdt.i, Row.i, Col.i, Txt.s)
    Protected *mg.TGrid = GetGadgetData(Gdt)
    
    If _IsValidCell(*mg, Row, Col)
      _SetCellText(*mg, Row, Col,  Txt)
      _Draw(*mg)
    EndIf
    
  EndProcedure
  
  Procedure.s GetText(Gdt.i, Row.i, Col.i)
    Protected *mg.TGrid = GetGadgetData(Gdt)
    
    If _IsValidCell(*mg, Row, Col)
      ProcedureReturn _GetCellText(*mg, Row, Col)
    EndIf
    ProcedureReturn ""
    
  EndProcedure
  
  Procedure.i SetCurrentCellText(Gdt.i, Txt.s)
    Protected *mg.TGrid = GetGadgetData(Gdt)
    
    If _IsValidCell(*mg, *mg\Row, *mg\Col)
      _SetCellText(*mg, *mg\Row, *mg\Col, Txt)
      _Draw(*mg)
    EndIf
    
  EndProcedure
  
  Procedure.s GetCurrentCellText(Gdt.i)
    Protected *mg.TGrid = GetGadgetData(Gdt)
    
    If _IsValidCell(*mg, *mg\Row, *mg\Col)
      ProcedureReturn _GetCellText(*mg, *mg\Row, *mg\Col)
    EndIf
    ProcedureReturn ""
    
  EndProcedure
  
  Procedure.i UnFreeze(Gdt.i)
    Protected *mg.TGrid = GetGadgetData(Gdt)
    
    _UnFreeze(*mg)
    _AdjustScrolls(*mg)
    
  EndProcedure
  
  ;-- Styles ----------------------------------------------
  
  ;--- Set Styles --
  
  Procedure.s StyleOfCell(Gdt, Row, Col)
    ; return the index of this Cell style in Styles()
    Protected *mg.TGrid = GetGadgetData(Gdt)
    Protected style = _GetStyle(*mg, Row, Col)
    If style >= 0
      ProcedureReturn *mg\Styles(style)\Name
    EndIf
  EndProcedure
  
  Procedure.i AddNewStyle(Gdt, StyleName.s)
    ; adds a new style that's a replica of 1st/default Style
    ; if StyleName exists already -> return it
    Protected   *mg.TGrid = GetGadgetData(Gdt)
    Protected   i, n = ArraySize(*mg\Styles())
    
    For i=0 To ArraySize(*mg\Styles())
      If UCase(*mg\Styles(i)\Name) = UCase(StyleName)
        ProcedureReturn i
      EndIf
    Next
    
    n = n + 1
    ReDim *mg\Styles(n)
    If ArraySize(*mg\Styles()) >= 0
      CopyStructure(@*mg\Styles(0), @*mg\Styles(n), TStyle)
      *mg\Styles(n)\Name = UCase(StyleName)
      ProcedureReturn n
    EndIf
    ProcedureReturn -1
  EndProcedure
  
  Procedure.i AssignStyle(Gdt, GRow, GCol, StyleName.s)
    ; applies a defined style to a set of cells
    Protected Style, *mg.TGrid = GetGadgetData(Gdt)
    
    If Not _IsValidGenericRow(*mg, GRow) : ProcedureReturn : EndIf
    If Not _IsValidGenericCol(*mg, GCol) : ProcedureReturn : EndIf
    
    For Style = 0 To ArraySize(*mg\Styles())
      If UCase(*mg\Styles(Style)\Name) = UCase(StyleName)
        _AssignStyle(*mg, GRow, GCol, Style)
        Break
      EndIf
    Next
  EndProcedure
  
  Procedure.i UnAssignStyles(Gdt)
    ; detach all cells from styles (after this, cells will have the defualt one: 0)
    Protected *mg.TGrid = GetGadgetData(Gdt)
    ClearMap(*mg\DicStyle())
  EndProcedure
  
  Procedure.i ClearStyles(Gdt)
    ; delete and detach all styles (keeping the defualt one only: 0)
    Protected *mg.TGrid = GetGadgetData(Gdt)
    
    ReDim *mg\Styles(0)
    ClearMap(*mg\DicStyle())
  EndProcedure
  
  Procedure.i ListOfStyles(Gdt.i, List StyleNames.s())
    Protected   i, *mg.TGrid   = GetGadgetData(Gdt)
    
    ClearList(StyleNames())
    For i = 0 To ArraySize(*mg\Styles())
      AddElement(StyleNames())
      StyleNames() = *mg\Styles(i)\Name
    Next
  EndProcedure
  
  ; --- Customizing defined Styles
  Procedure.i SetStyleAlign(Gdt, StyleName.s, Value.i = #Align_Left)
    Protected   *mg.TGrid   = GetGadgetData(Gdt)
    Protected   Style       = _IndexOfStyle(*mg, StyleName)
    
    If 0 <= Style And Style <= ArraySize(*mg\Styles()) : *mg\Styles(Style)\Aling = Value : EndIf
  EndProcedure
  Procedure.i SetStyleBackColor(Gdt, StyleName.s, Value.i = $FFFFFF)
    Protected   *mg.TGrid   = GetGadgetData(Gdt)
    Protected   Style       = _IndexOfStyle(*mg, StyleName)
    
    If 0 <= Style And Style <= ArraySize(*mg\Styles()) : *mg\Styles(Style)\BackColor = Value : EndIf
  EndProcedure
  
  Procedure.i SetStyleForeColor(Gdt, StyleName.s, Value.i = $000000)
    Protected   *mg.TGrid   = GetGadgetData(Gdt)
    Protected   Style       = _IndexOfStyle(*mg, StyleName)
    
    If 0 <= Style And Style <= ArraySize(*mg\Styles()) : *mg\Styles(Style)\ForeColor = Value : EndIf
  EndProcedure
  
  Procedure.i SetStyleCellType(Gdt, StyleName.s, Value.i = #CellType_Normal)
    Protected   *mg.TGrid   = GetGadgetData(Gdt)
    Protected   Style       = _IndexOfStyle(*mg, StyleName)
    
    If 0 <= Style And Style <= ArraySize(*mg\Styles()) : *mg\Styles(Style)\CellType = Value : EndIf
  EndProcedure
  
  Procedure.i SetStyleEditable(Gdt, StyleName.s, Value.i = #True)
    Protected   *mg.TGrid   = GetGadgetData(Gdt)
    Protected   Style       = _IndexOfStyle(*mg, StyleName)
    
    If 0 <= Style And Style <= ArraySize(*mg\Styles()) : *mg\Styles(Style)\Editable = Value : EndIf
  EndProcedure
  
  Procedure.i SetStyleFont(Gdt, StyleName.s, FontNumber.i)
    Protected   *mg.TGrid   = GetGadgetData(Gdt)
    Protected   Style       = _IndexOfStyle(*mg, StyleName)
    
    If 0 <= Style And Style <= ArraySize(*mg\Styles()) : *mg\Styles(Style)\Font = FontNumber : EndIf
  EndProcedure
  
  Procedure.i SetStyleGradient(Gdt, StyleName.s, Value.i = #True)
    Protected   *mg.TGrid   = GetGadgetData(Gdt)
    Protected   Style       = _IndexOfStyle(*mg, StyleName)
    
    If 0 <= Style And Style <= ArraySize(*mg\Styles()) : *mg\Styles(Style)\Gradient = Value : EndIf
  EndProcedure
  
  Procedure.i SetStyleItems(Gdt, StyleName.s, Items.s, ItemSep.s)
    Protected   *mg.TGrid   = GetGadgetData(Gdt)
    Protected   Style       = _IndexOfStyle(*mg, StyleName)
    Protected   iWrd, nWrd, Dim tWrd.s(0)
    
    If 0 <= Style And Style <= ArraySize(*mg\Styles())
      ClearList(*mg\Styles(Style)\Item())
      nWrd = MySplitString(Items, ItemSep, tWrd())
      For iWrd = 1 To nWrd
        AddElement(*mg\Styles(Style)\Item())
        *mg\Styles(Style)\Item() = tWrd(iWrd)
      Next
    EndIf
  EndProcedure
  
  Procedure.i SetStyleItemList(Gdt, StyleName.s, List ItemList.s())
    Protected   *mg.TGrid   = GetGadgetData(Gdt)
    Protected   Style       = _IndexOfStyle(*mg, StyleName)
    Protected   iWrd, nWrd, Dim tWrd.s(0)
    
    If 0 <= Style And Style <= ArraySize(*mg\Styles())
      ClearList(*mg\Styles(Style)\Item())
      CopyList(ItemList(), *mg\Styles(Style)\Item())
    EndIf
  EndProcedure
  
  ;--- Get Styles --
  
  Procedure.i GetStyleAlign(Gdt, StyleName.s)
    Protected   *mg.TGrid   = GetGadgetData(Gdt)
    Protected   Style       = _IndexOfStyle(*mg, StyleName)
    
    If 0 <= Style And Style <= ArraySize(*mg\Styles()) : ProcedureReturn *mg\Styles(Style)\Aling : EndIf
  EndProcedure
  
  Procedure.i GetStyleBackColor(Gdt, StyleName.s)
    Protected   *mg.TGrid   = GetGadgetData(Gdt)
    Protected   Style       = _IndexOfStyle(*mg, StyleName)
    
    If 0 <= Style And Style <= ArraySize(*mg\Styles()) : ProcedureReturn *mg\Styles(Style)\BackColor : EndIf
  EndProcedure
  
  Procedure.i GetStyleForeColor(Gdt, StyleName.s)
    Protected   *mg.TGrid   = GetGadgetData(Gdt)
    Protected   Style       = _IndexOfStyle(*mg, StyleName)
    
    If 0 <= Style And Style <= ArraySize(*mg\Styles()) : ProcedureReturn *mg\Styles(Style)\ForeColor : EndIf
  EndProcedure
  
  Procedure.i GetStyleCellType(Gdt, StyleName.s)
    Protected   *mg.TGrid   = GetGadgetData(Gdt)
    Protected   Style       = _IndexOfStyle(*mg, StyleName)
    
    If 0 <= Style And Style <= ArraySize(*mg\Styles()) : ProcedureReturn *mg\Styles(Style)\CellType : EndIf
  EndProcedure
  
  Procedure.i GetStyleEditable(Gdt, StyleName.s)
    Protected   *mg.TGrid   = GetGadgetData(Gdt)
    Protected   Style       = _IndexOfStyle(*mg, StyleName)
    
    If 0 <= Style And Style <= ArraySize(*mg\Styles()) : ProcedureReturn *mg\Styles(Style)\Editable : EndIf
  EndProcedure
  
  Procedure.i GetStyleFont(Gdt, StyleName.s)
    Protected   *mg.TGrid   = GetGadgetData(Gdt)
    Protected   Style       = _IndexOfStyle(*mg, StyleName)
    
    If 0 <= Style And Style <= ArraySize(*mg\Styles()) : ProcedureReturn *mg\Styles(Style)\Font : EndIf
  EndProcedure
  
  Procedure.i GetStyleGradient(Gdt, StyleName.s)
    Protected   *mg.TGrid   = GetGadgetData(Gdt)
    Protected   Style       = _IndexOfStyle(*mg, StyleName)
    
    If 0 <= Style And Style <= ArraySize(*mg\Styles()) : ProcedureReturn *mg\Styles(Style)\Gradient : EndIf
  EndProcedure
  
  Procedure.i GetStyleItems(Gdt, StyleName.s, List Items.s())
    Protected   *mg.TGrid   = GetGadgetData(Gdt)
    Protected   Style       = _IndexOfStyle(*mg, StyleName)
    
    If 0 <= Style And Style <= ArraySize(*mg\Styles()) : CopyList(*mg\Styles(Style)\Item(), Items()) : EndIf
  EndProcedure
  
  Procedure.i IsCellEditable(Gdt, Row, Col)
    Protected *mg.TGrid = GetGadgetData(Gdt)
    Protected style = _GetStyle(*mg, Row, Col)
    If style >= 0
      ProcedureReturn *mg\Styles(style)\Editable 
    EndIf
    ProcedureReturn #False
  EndProcedure
  
  ;-- For Columns -----------------------------------------
  
  Procedure.i ClearColIDs(Gdt.i)
    Protected *mg.TGrid = GetGadgetData(Gdt)
    ClearMap(*mg\DicColID())
  EndProcedure
  
  Procedure.i SetColID(Gdt.i, Col.i, ColID.s)
    Protected *mg.TGrid = GetGadgetData(Gdt)
    
    If (Col <= *mg\Cols) And (Col >= 0)
      *mg\DicColID(UCase(ColID)) = Col
    EndIf
  EndProcedure
  
  Procedure.i ColNumberOfColID(Gdt.i, ColID.s)
    Protected *mg.TGrid = GetGadgetData(Gdt)
    
    If FindMapElement(*mg\DicColID(), UCase(ColID))
      ProcedureReturn *mg\DicColID()
    EndIf
    ProcedureReturn -1
    
  EndProcedure
  
  Procedure.i ChangeColID(Gdt.i, oldColID.s, newColID.s)
    Protected col, *mg.TGrid = GetGadgetData(Gdt)
    
    If FindMapElement(*mg\DicColID(), UCase(oldColID))
      col = *mg\DicColID()
      DeleteMapElement(*mg\DicColID())
      *mg\DicColID(UCase(newColID)) = col     ; keep old value
      ProcedureReturn #True
    EndIf
    ProcedureReturn #False
    
  EndProcedure
  
  Procedure.s ColIdOfColNumber(Gdt.i, Col)
    Protected *mg.TGrid = GetGadgetData(Gdt)
    
    ForEach *mg\DicColID()
      If *mg\DicColID() = Col : ProcedureReturn MapKey(*mg\DicColID()) : EndIf
    Next
    ProcedureReturn ""
  EndProcedure
  
  Procedure.i SetColWidth(Gdt.i, GCol.i, Width.i = #Default_ColWidth)
    Protected *mg.TGrid = GetGadgetData(Gdt)
    
    _ChangeColWidth(*mg, GCol, Width)
    _Draw(*mg)
  EndProcedure
  
  Procedure.i GetColWidth(Gdt.i, Col.i)
    Protected *mg.TGrid = GetGadgetData(Gdt)
    
    If Col <= *mg\Cols And Col >= 0
      ProcedureReturn *mg\ColWidth(Col)
    EndIf
  EndProcedure
  
  Procedure.i SetColData(Gdt.i, Col.i, ColData.i)
    Protected *mg.TGrid = GetGadgetData(Gdt)
    
    If Col <= *mg\Cols And Col >= 0
      *mg\ColData(Col) = ColData
    EndIf
  EndProcedure
  
  Procedure.i GetColData(Gdt.i, Col.i)
    Protected *mg.TGrid = GetGadgetData(Gdt)
    
    If Col <= *mg\Cols And Col >= 0
      ProcedureReturn *mg\ColData(Col)
    EndIf
  EndProcedure
  
  Procedure.i HideCol(Gdt.i, GCol.i, State)
    Protected *mg.TGrid = GetGadgetData(Gdt)
    
    If State
      _ChangeColWidth(*mg, GCol, #RC_WH_Hidden, #False)   ; hidden by application cannot be un-hidden by user
      _Draw(*mg)
    Else
      _ChangeColWidth(*mg, GCol, #Default_ColWidth, #False)
      _Draw(*mg)
    EndIf
  EndProcedure
  
  Procedure.i AutoWidthCol(Gdt.i, GCol)
    Protected *mg.TGrid = GetGadgetData(Gdt)
    Protected i, SFont, mxWdh, wdh, iC, C1, C2, wrd.s, rdrw, *Style.TStyle
    Protected gW = *mg\DrawingW
    
    If Not _IsValidGenericCol(*mg, GCol) : ProcedureReturn : EndIf
    
    If GCol >= 0         : C1 = GCol :  C2 = GCol     : EndIf
    If GCol = #RC_Data   : C1 = 1    :  C2 = *mg\Cols : EndIf
    If GCol = #RC_Any    : C1 = 0    :  C2 = *mg\Cols : EndIf
    
    ; dummy StartDrawing to measure text-width
    If StartDrawing(CanvasOutput(*mg\Gadget)) 
      
      For iC = C1 To C2
        If *mg\ColWidth( iC) = -1 : Continue : EndIf
        
        mxWdh = 0
        For i = 0 To *mg\Rows
          wrd = _GetCellText(*mg, i, iC)
          If wrd <> ""
            *Style = _SelectStyle(*mg, i, iC)
            SFont  = *Style\Font
            If IsFont(SFont) : DrawingFont(FontID(SFont)) : EndIf
            wdh = TextWidth(wrd)
            If wdh > mxWdh : mxWdh = wdh : EndIf
          EndIf
        Next i
        mxWdh = mxWdh + (2*#Text_MarginX)
        
        If *mg\ColWidth( iC) <> mxWdh
          If mxWdh > 0.9 * gW : mxWdh = 0.9 * gW : EndIf
          _ChangeColWidth(*mg, iC, mxWdh)
          rdrw = #True
        EndIf
        
      Next iC
      
      StopDrawing()
    EndIf
    If rdrw : _Draw(*mg) : EndIf
    
  EndProcedure
  
  Procedure.i FreezeCol(Gdt.i, Col.i)
    Protected *mg.TGrid = GetGadgetData(Gdt)
    
    If Col <= *mg\Cols And Col >= 0
      _FreezeCol(*mg, Col)
      _AdjustScrolls(*mg)
    EndIf
    
  EndProcedure
  
  Procedure.i FrozenCol(Gdt.i)
    Protected *mg.TGrid = GetGadgetData(Gdt)
    ProcedureReturn *mg\FrzCol
  EndProcedure
  
  Procedure.i IsColHidden(Gdt.i, Col.i)
    Protected *mg.TGrid = GetGadgetData(Gdt)
    
    If Col <= *mg\Cols And Col >= 0
      ProcedureReturn Bool( *mg\ColWidth(Col) = #RC_WH_Hidden )
    EndIf
    
  EndProcedure
  
  Procedure.i EnableSortOnClick(Gdt.i, Col.i, State.i = 1)
    Protected *mg.TGrid = GetGadgetData(Gdt)
    
    If Col <= *mg\Cols And Col >= 0
      If State <> 0 : State = 1 : EndIf
      *mg\ColSortOnClick(Col) = State
    EndIf
  EndProcedure
  
  Procedure.i ShowRowNumbers(Gdt.i, State = #True)
    Protected *mg.TGrid = GetGadgetData(Gdt)
    
    *mg\ShowRowNumbers = State
  EndProcedure
  
  
  ;-- For Rows --------------------------------------------
  
  Procedure.i ClearRowIDs(Gdt.i)
    Protected *mg.TGrid = GetGadgetData(Gdt)
    ClearMap(*mg\DicRowID())
  EndProcedure
  
  Procedure.i SetRowID(Gdt.i, Row.i, RowID.s)
    Protected *mg.TGrid = GetGadgetData(Gdt)
    
    If (Row <= *mg\Rows) And (Row >= 0)
      *mg\DicRowID(UCase(RowID)) = Row
    EndIf
    
  EndProcedure
  
  Procedure.i RowNumberOfRowID(Gdt.i, RowID.s)
    Protected *mg.TGrid = GetGadgetData(Gdt)
    
    If FindMapElement(*mg\DicRowID(), UCase(RowID))
      ProcedureReturn *mg\DicRowID()
    EndIf
    ProcedureReturn -1
    
  EndProcedure
  
  Procedure.i ChangeRowID(Gdt.i, oldRowID.s, newRowID.s)
    Protected row, *mg.TGrid = GetGadgetData(Gdt)
    
    If FindMapElement(*mg\DicRowID(), UCase(oldRowID))
      row = *mg\DicRowID()
      DeleteMapElement(*mg\DicRowID())
      *mg\DicRowID(UCase(newRowID)) = row     ; keep old value
      ProcedureReturn #True
    EndIf
    ProcedureReturn #False
    
  EndProcedure
  
  Procedure.s RowIdOfRowNumber(Gdt.i, Row)
    Protected *mg.TGrid = GetGadgetData(Gdt)
    
    ForEach *mg\DicRowID()
      If *mg\DicRowID() = Row : ProcedureReturn MapKey(*mg\DicRowID()) : EndIf
    Next
    ProcedureReturn ""
    
  EndProcedure
  
  Procedure.i SetRowHeight(Gdt.i, GRow.i, Height.i = #Default_RowHeight)
    Protected *mg.TGrid = GetGadgetData(Gdt)
    
    _ChangeRowHeight(*mg, GRow, Height)
    _Draw(*mg)
    
  EndProcedure
  
  Procedure.i GetRowHeight(Gdt.i, Row.i)
    Protected *mg.TGrid = GetGadgetData(Gdt)
    
    If Row <= *mg\Rows And Row >= 0
      ProcedureReturn *mg\RowHeight(Row)
    EndIf
    
  EndProcedure
  
  Procedure.i SetRowData(Gdt.i, Row.i, RowData.i)
    Protected *mg.TGrid = GetGadgetData(Gdt)
    
    If Row <= *mg\Rows And Row >= 0
      *mg\RowData(Row) = RowData
    EndIf
    
  EndProcedure
  
  Procedure.i GetRowData(Gdt.i, Row.i)
    Protected *mg.TGrid = GetGadgetData(Gdt)
    
    If Row <= *mg\Rows And Row >= 0
      ProcedureReturn *mg\RowData(Row)
    EndIf
    
  EndProcedure
  
  Procedure.i HideRow(Gdt.i, GRow.i, State)
    Protected *mg.TGrid = GetGadgetData(Gdt)
    
    If State
      _ChangeRowHeight(*mg, GRow, #RC_WH_Hidden, #False)  ; hidden by application cannot be un-hidden by user
      _Draw(*mg)
    Else
      _ChangeRowHeight(*mg, GRow, #Default_RowHeight, #False)
      _Draw(*mg)
    EndIf
    
  EndProcedure
  
  Procedure.i AutoHeightRow(Gdt.i, GRow)
    Protected *mg.TGrid = GetGadgetData(Gdt)
    Protected i, SFont,  mxHgt, hgt, iR, R1, R2, wrd.s, rdrw, *Style.TStyle
    Protected gH = *mg\DrawingH
    
    If Not _IsValidGenericRow(*mg, GRow) : ProcedureReturn : EndIf
    
    If GRow >= 0         : R1 = GRow :  R2 = GRow     : EndIf
    If GRow = #RC_Data   : R1 = 1    :  R2 = *mg\Rows : EndIf
    If GRow = #RC_Any    : R1 = 0    :  R2 = *mg\Rows : EndIf
    
    ; dummy StartDrawing to measure text-width
    If StartDrawing(CanvasOutput(*mg\Gadget)) 
      
      For iR = R1 To R2
        If *mg\RowHeight( iR) = -1 : Continue : EndIf
        
        mxHgt = 0
        For i = 0 To *mg\Cols
          wrd = _GetCellText(*mg, iR, i)
          If wrd <> ""
            *Style = _SelectStyle(*mg, iR, i)
            SFont  = *Style\Font
            If IsFont(SFont) : DrawingFont(FontID(SFont)) : EndIf
            hgt = TextHeight(wrd)
            If hgt > mxHgt : mxHgt = hgt : EndIf
          EndIf
        Next i
        mxHgt = mxHgt + (2*#Text_MarginY)
        
        If *mg\RowHeight(iR) <> mxHgt
          If mxHgt > 0.9 * gH : mxHgt = 0.9 * gH : EndIf
          _ChangeRowHeight(*mg, iR, mxHgt)
          rdrw = #True
        EndIf
        
      Next iR
      
      StopDrawing()
    EndIf
    If rdrw : _Draw(*mg) : EndIf
    
  EndProcedure
  
  Procedure.i FreezeRow(Gdt.i, Row.i)
    Protected *mg.TGrid = GetGadgetData(Gdt)
    
    If Row <= *mg\Rows And Row >= 0
      _FreezeRow(*mg, Row)
      _AdjustScrolls(*mg)
    EndIf
    
  EndProcedure
  
  Procedure.i FrozenRow(Gdt.i)
    Protected *mg.TGrid = GetGadgetData(Gdt)
    ProcedureReturn *mg\FrzRow
  EndProcedure
  
  Procedure.i IsRowHidden(Gdt.i, Row.i)
    Protected *mg.TGrid = GetGadgetData(Gdt)
    
    If Row <= *mg\Rows And Row >= 0
      ProcedureReturn Bool( *mg\RowHeight(Row) = #RC_WH_Hidden )
    EndIf
    
  EndProcedure
  
  ;-- For Cells -------------------------------------------
  
  Procedure.i MergeCells(Gdt, Row1,Col1, Row2,Col2, CheckIntersection.i=#True)
    ; return the index of the multi-cell in LstMulti()
    ; if Style = -1 ---> multi-cell will receive the style of its upper-left cell
    Protected *mg.TGrid = GetGadgetData(Gdt)
    Protected iR, iC, multi
    
    If Row1 > Row2 : Swap Row1 , Row2 : EndIf
    If Col1 > Col2 : Swap Col1 , Col2 : EndIf
    If Row1 = Row2 And Col1 = Col2 : ProcedureReturn -1 : EndIf
    
    If _IsValidCell(*mg, Row1, Col1) And _IsValidCell(*mg, Row2, Col2)
      
      If CheckIntersection
        ForEach *mg\LstMulti()
          If BlocksHaveIntersection(*mg\LstMulti()\R1, *mg\LstMulti()\R2, *mg\LstMulti()\C1, *mg\LstMulti()\C2, Row1, Row2, Col1, Col2)
            ProcedureReturn -1 ; we stop merging! 2 multis cant overlap
          EndIf
        Next
      EndIf
      
      AddElement( *mg\LstMulti() )
      multi = ListIndex(*mg\LstMulti())
      
      *mg\LstMulti()\R1 = Row1
      *mg\LstMulti()\R2 = Row2
      *mg\LstMulti()\C1 = Col1
      *mg\LstMulti()\C2 = Col2
      
      ProcedureReturn multi
    EndIf
    
    ProcedureReturn -1
    
  EndProcedure
  
  Procedure.i UnMergeCells(Gdt, Row,Col)
    ; un-merge cells ... (Row, Col) is any cell member of the multi-cell
    Protected *mg.TGrid = GetGadgetData(Gdt)
    Protected iR, iC, multi
    
    If _IsValidCell(*mg, Row, Col)
      multi = _MultiOfCell(*mg, Row, Col)
      If multi >= 0 
        SelectElement(*mg\LstMulti() , multi)
        DeleteElement(*mg\LstMulti())
      EndIf
    EndIf
    
  EndProcedure
  
  Procedure.i ClearMerges(Gdt)
    ; clear all merged cells
    Protected *mg.TGrid = GetGadgetData(Gdt)
    
    ClearList(*mg\LstMulti())
    
  EndProcedure
  
  Procedure.i HasBlock(Gdt)
    Protected *mg.TGrid = GetGadgetData(Gdt)
    
    If _HasBlock(*mg) : ProcedureReturn #True : EndIf
    
  EndProcedure
  
  Procedure.i ResetBlock(Gdt)
    Protected *mg.TGrid = GetGadgetData(Gdt)
    
    If _HasBlock(*mg)
      _ResetBlock(*mg)
      _Draw(*mg)
    Else
      _ResetBlock(*mg)
    EndIf
    
  EndProcedure
  
  Procedure.i SelectBlock(Gdt, Row1,Col1, Row2,Col2)
    Protected *mg.TGrid = GetGadgetData(Gdt)
    
    _StartBlock(*mg, Row1,Col1, Row2,Col2)
    _Draw(*mg)
    
  EndProcedure
  
  Procedure.i ClearBlockContent(Gdt.i)
    Protected i, iC, iR, R1,R2,C1,C2, Style, rdrw, *s.TStyle
    Protected *mg.TGrid = GetGadgetData(Gdt)
    
    R1 = *mg\Row    :   R2 = *mg\Row2
    C1 = *mg\Col    :   C2 = *mg\Col2
    If Not _IsValidRow(*mg, R1) : ProcedureReturn : EndIf
    If Not _IsValidRow(*mg, R2) : ProcedureReturn : EndIf
    If Not _IsValidCol(*mg, C1) : ProcedureReturn : EndIf
    If Not _IsValidCol(*mg, C2) : ProcedureReturn : EndIf
    
    For iR = R1 To R2
      For iC = C1 To C2
        *s = _SelectStyle(*mg, iR, iC)
        If Not *s\Editable : Continue : EndIf
        _SetCellText(*mg , iR, iC, "")
        rdrw = #True
      Next iC
    Next iR
    If rdrw : _Draw(*mg) : EndIf
    
  EndProcedure
  
  Procedure.i SelectAll(Gdt)
    Protected *mg.TGrid = GetGadgetData(Gdt)
    Protected Row1 = 1, Col1 = 1, Row2 = *mg\Rows, Col2 = *mg\Cols
    
    _StartBlock(*mg, Row1,Col1, Row2,Col2)
    _Draw(*mg)
    
  EndProcedure
  
  ;------------------------------------------- 
  
  Procedure.i AttachPopup(Gdt.i, Popup.i)
    Protected *mg.TGrid = GetGadgetData(Gdt)
    
    *mg\AttachedPopupMenu = Popup
    
  EndProcedure
  
  ; ---- sorting related
  
  Procedure.i ResetSort(Gdt.i)
    Protected   *mg.TGrid = GetGadgetData(Gdt)
    ClearList( *mg\SortingCol() )
  EndProcedure
  
  Procedure.i AddSortingCol(Gdt.i, Col, Direction = #PB_Sort_Ascending)
    Protected   *mg.TGrid = GetGadgetData(Gdt)
    If AddElement( *mg\SortingCol())
      *mg\SortingCol()\Col       = Col
      *mg\SortingCol()\Direction = Direction
    EndIf
  EndProcedure
  
  Procedure.i Sort(Gdt.i, StartRow = -1, EndRow = -1)
    ; runs a multi-col Sort as defined in SortingCol() on full row - sort by blocks
    ; stable sort - working fine but not very efficient (room for improving!)
    ; >>>> !!! THIS SORT DOESNT INCLUDE STYLES !!! <<<<<< can be used if the col-data all belongs to one style!
    Protected   *mg.TGrid = GetGadgetData(Gdt)
    Protected   NewList Flds.i(), NewList Drcs.i(), NewList Typs.i()
    Protected   Dim row_val.TSortItem(0)
    Protected   nbrFlds, i,j,k,n, R1,R2, I1,I2, B1,B2, iR,iC, typ,drc, vFlt.f, vTxt.s, ky.s, oRnk,nRnk, dif
    
    ; validation
    R1 = StartRow   : If R1 = -1 : R1 = _FirstDataRow(*mg)   : EndIf
    R2 = EndRow     : If R2 = -1 : R2 = *mg\Rows             : EndIf
    If _IsValidRow(*mg, R1) = 0  : ProcedureReturn 0 : EndIf
    If _IsValidRow(*mg, R2) = 0  : ProcedureReturn 0 : EndIf
    If R1 = R2                   : ProcedureReturn 0 : EndIf
    If R1 > R2                   : Swap R1, R2       : EndIf
    
    ForEach *mg\SortingCol()
      If _IsValidCol(*mg, *mg\SortingCol()\Col)
        If AddElement( Flds() ) And AddElement( Drcs() ) And AddElement( Typs() )
          Flds() = *mg\SortingCol()\Col
          Drcs() = *mg\SortingCol()\Direction
          If Drcs() <> #PB_Sort_Ascending : Drcs() = #PB_Sort_Descending : EndIf
          *mg\ColOfSort = *mg\SortingCol()\Col
        EndIf
      EndIf
    Next
    If ListSize(Flds()) <= 0    : ProcedureReturn 0     : EndIf
    If ListSize(Flds())  > 1    : *mg\ColOfSort = -1    : EndIf
    
    ; detecting data types, a column can contain numbers or texts --> Typs() = 0 (number) or = 1 (text)
    ForEach Flds()
      iC = Flds()
      For iR = R1 To R2
        If *mg\gData(iR, iC) = "" : Continue : EndIf    ; empty is interpreted as zero
        If Not IsNumber(*mg\gData(iR, iC), *mg\ThousandsSeparator, *mg\DecimalCharacter)
          SelectElement(Typs(), ListIndex(Flds())) : Typs() = 1 : Break
        EndIf
      Next
    Next
    ; injecting original order --> guarantee a stable sort
    I1 = 0 : I2 = R2 - R1
    Dim row_val(I2)
    For i = I1 To I2
      row_val(i)\ORank = R1 + i
    Next
    
    ForEach Flds()
      iC = Flds()
      SelectElement(Typs(), ListIndex(Flds())) : typ = Typs()
      SelectElement(Drcs(), ListIndex(Flds())) : drc = Drcs()
      
      B1 = -1 : B2 = -1
      For i=I1 To I2
        ; looking for a block identified by [B1,B2] having equal NRank
        If i = I2
          B2 = i
        Else
          If row_val(i)\NRank = row_val(i+1)\NRank
            If B1 < 0   : B1 = i   : B2 = i+1
            Else        : B2 = i+1
            EndIf
            Continue
          EndIf
        EndIf
        
        If B1 >= 0 And B2 > B1                  ; we have a block [B1,B2] that needs be sorted
          dif = B2 - B1
          For j=B2+1 To I2
            row_val(j)\NRank + dif          ; pushing NRank after B2 by the difference
          Next
          
          ; all elements between [B1,B2] will have their revised NRank --> [ rank_B1, rank_B1 + dif]
          oRnk = row_val(B1)\NRank
          If typ = 0
            For j = B1 To B2
              iR = row_val(j)\ORank
              row_val(j)\Flt = ValF( _GetCellText(*mg, iR, iC) )
            Next
            SortStructuredArray(row_val(), drc, OffsetOf(TSortItem\Flt), #PB_Float, B1, B2)
            
            vFlt = row_val(B1)\Flt
            For j = B1+1 To B2
              If row_val(j)\Flt <> vFlt
                oRnk + 1 : vFlt = row_val(j)\Flt
              EndIf
              row_val(j)\NRank = oRnk
            Next
          Else
            For j = B1 To B2
              iR = row_val(j)\ORank
              row_val(j)\Txt = _GetCellText(*mg, iR, iC)
            Next
            SortStructuredArray(row_val(), drc, OffsetOf(TSortItem\Txt), #PB_String, B1, B2)
            
            vTxt = row_val(B1)\Txt
            For j = B1+1 To B2
              If row_val(j)\Txt <> vTxt
                oRnk + 1 : vTxt = row_val(j)\Txt
              EndIf
              row_val(j)\NRank = oRnk
            Next
          EndIf
          
          ; preparing for next step
          B1 = -1 : B2 = -1
        EndIf
      Next
    Next
    
    ; we need to process stable sort here.... building final rank
    vFlt = Pow(10, Len(Str(I2)))
    For i = I1 To I2
      row_val(i)\Flt = (row_val(i)\NRank * vFlt) + row_val(i)\ORank
    Next
    SortStructuredArray(row_val(), #PB_Sort_Ascending, OffsetOf(TSortItem\Flt), #PB_Float)
    For i = I1 To I2
      row_val(i)\NRank = i
    Next
    
    ; by now we know for each row its final rank in \NRank ... we start shifting cell contents
    Protected Dim b.s(R2-R1, *mg\Cols)
    For iC = 0 To *mg\Cols
      For iR = R1 To R2
        j = iR - R1
        b(j, iC) = *mg\gData(iR, iC)
      Next
    Next
    For iC = 0 To *mg\Cols
      For iR = R1 To R2
        j = iR - R1
        oRnk = row_val(j)\ORank
        nRnk = row_val(j)\NRank
        *mg\gData(R1 + nRnk, iC) = b(oRnk - R1, iC)
        
        ; shifting row-id as well if available
        ForEach *mg\DicRowID()
          If *mg\DicRowID() = iR
            *mg\DicRowID() = R1 + nRnk      ; assign the new row for this same row-id
            Break
          EndIf
        Next
        
      Next
    Next
    FreeArray(b())
    
    ClearList(*mg\SortingCol())                     ; after a sort is done we clear sorting-columns
    _RefreshRowNumbers(*mg)
    _Draw(*mg)
    
    ProcedureReturn 1
    
  EndProcedure
  
  Procedure.i SortOnColumn(Gdt.i, Col.i)
    ; runs a single-col sort on Col (full row)
    ; 
    Protected   direction, *mg.TGrid = GetGadgetData(Gdt)
    
    If _IsValidCol(*mg, Col) = 0 : ProcedureReturn : EndIf
    
    If *mg\ColOfSort = Col
      *mg\ColOfSortDirection = Bool(*mg\ColOfSortDirection XOr 1)
    Else
      *mg\ColOfSortDirection = 0      ; the first sort is ascending then we alternate
    EndIf
    
    ClearList( *mg\SortingCol() )
    direction = #PB_Sort_Ascending
    If *mg\ColOfSortDirection = 1 : direction = #PB_Sort_Descending : EndIf
    
    AddSortingCol(Gdt, Col, direction)
    
    Sort(Gdt)
    
  EndProcedure
  
  ; --- Event Manager: all events are processed here!
  
  Procedure.i ManageEvent(Gdt.i, eType)
    Protected *mg.TGrid = GetGadgetData(Gdt)
    Protected ky,mf, prvState,mx,my,x,y,w,h,ar,ac,col,row,mv,dlt,i,keepOn,crs, txt.s
    Protected *Style.TStyle
    
    If eType = #PB_EventType_Resize
      Resize(Gdt, GadgetX(Gdt), GadgetY(Gdt), GadgetWidth(Gdt), GadgetHeight(Gdt))
      ProcedureReturn
    EndIf
    
    x = GetGadgetAttribute(gdt, #PB_Canvas_MouseX)
    y = GetGadgetAttribute(gdt, #PB_Canvas_MouseY)
    
    ; first we check if an editor is open and requires some validation/cancellation ....
    If *mg\Editor
      If *mg\EditorFull
        ; we enter in this mode with double-click or enter-key press
        ; in this mode we can only exit with Return/Escape or a click away
        If eType = #PB_EventType_KeyDown
          ky = GetGadgetAttribute(gdt, #PB_Canvas_Key )
          If ky = #PB_Shortcut_Return                     ; validation
            _CloseEdit(*mg)
            ProcedureReturn                             ; otherwise the Return will re-open the editor again
          ElseIf ky = #PB_Shortcut_Escape               ; cancel
            _CloseEdit(*mg, #True)
          EndIf
        EndIf
      Else
        ; we enter in this mode when we start typing over an editable- cell
        If MyEdit::IsLastPosition(*mg\Editor) And  eType = #PB_EventType_KeyDown
          ky = GetGadgetAttribute(gdt, #PB_Canvas_Key )
          
          If IsNavigationKey(ky)                            ; validation
            _CloseEdit(*mg)
          ElseIf ky = #PB_Shortcut_Return                   ; validation
            _CloseEdit(*mg)
            ProcedureReturn                                 ; otherwise the Return will re-open the editor again
          ElseIf ky = #PB_Shortcut_Escape                   ; cancel
            _CloseEdit(*mg, #True)
          EndIf
        EndIf
      EndIf
      
      If eType = #PB_EventType_LostFocus
        _CloseEdit(*mg)
      EndIf
      
      If eType = #PB_EventType_LeftButtonDown
        If Not _OverEditor(*mg, x, y) : _CloseEdit(*mg) : EndIf
      EndIf
      
      ; we pass the event to the editor if not closed yet!
      ; when editor is closed, the last event that closed it is passed to the grid
      ; e.g. navigation keys should still be interpreted by the grid ...
      If *mg\Editor
        MyEdit::ManageEvent(*mg\Editor, eType)
        ProcedureReturn
      EndIf
    EndIf
    
    ; ususal processing of grid events
    Select eType
        
      Case #PB_EventType_KeyDown
        ky = GetGadgetAttribute(gdt, #PB_Canvas_Key )
        mf = GetGadgetAttribute(gdt, #PB_Canvas_Modifiers )
        
        If mf & #PB_Canvas_Shift
          ; navigation key + shift => start a new block And/Or extend current block
          If mf & #PB_Canvas_Control
            Select ky
              Case #PB_Shortcut_Left  : MoveLeft( Gdt, *mg\Cols, #Move_Block)
              Case #PB_Shortcut_Right : MoveRight(Gdt, *mg\Cols, #Move_Block)
              Case #PB_Shortcut_Up    : MoveUp(   Gdt, *mg\Rows, #Move_Block)
              Case #PB_Shortcut_Down  : MoveDown( Gdt, *mg\Rows, #Move_Block)
              Case #PB_Shortcut_Home
                MoveUp(  Gdt, *mg\Rows, #Move_Block)
                MoveLeft(Gdt, *mg\Cols, #Move_Block)
              Case #PB_Shortcut_End
                MoveDown( Gdt, *mg\Rows, #Move_Block)
                MoveRight(Gdt, *mg\Cols, #Move_Block)
            EndSelect
          Else
            Select ky
              Case #PB_Shortcut_Left      : MoveLeft( Gdt, 1, #Move_Block)
              Case #PB_Shortcut_Right     : MoveRight(Gdt, 1, #Move_Block)
              Case #PB_Shortcut_Up        : MoveUp(   Gdt, 1, #Move_Block)
              Case #PB_Shortcut_Down      : MoveDown( Gdt, 1, #Move_Block)
              Case #PB_Shortcut_PageUp    : MoveUp(   Gdt, #Scroll_PageSize, #Move_Block)
              Case #PB_Shortcut_PageDown  : MoveDown( Gdt, #Scroll_PageSize, #Move_Block)
            EndSelect
          EndIf
          
        Else                ; >>>>> no shift key and no control --> block de-selection
          
          If (mf & #PB_Canvas_Control) = 0 : ResetBlock(gdt) : EndIf
          
          If (mf & #PB_Canvas_Control)
            Select ky
              Case #PB_Shortcut_Left      : FocusCell(gdt, *mg\Row, *mg\FrstTopCol)
              Case #PB_Shortcut_Right     : FocusCell(gdt, *mg\Row, *mg\LastVisCol)
              Case #PB_Shortcut_Up        : FocusCell(gdt, *mg\FrstTopRow, *mg\Col)
              Case #PB_Shortcut_Down      : FocusCell(gdt, *mg\LastVisRow,  *mg\Col)
              Case #PB_Shortcut_Home      : FocusCell(gdt, *mg\FrstTopRow, *mg\FrstTopCol)
              Case #PB_Shortcut_End       : FocusCell(gdt, *mg\LastVisRow,  *mg\LastVisCol)
                
              Case #PB_Shortcut_C         : txt = GetBlockText(gdt)   : SetClipboardText(txt)
              Case #PB_Shortcut_V         : txt = GetClipboardText()  : SetBlockText(gdt, txt)
              Case #PB_Shortcut_X         : ClearBlockContent(gdt)
            EndSelect
          Else
            Select ky
              Case #PB_Shortcut_Left      : MoveLeft( Gdt, 1, #Move_Focus)
              Case #PB_Shortcut_Right     : MoveRight(Gdt, 1, #Move_Focus)
              Case #PB_Shortcut_Up        : MoveUp(   Gdt, 1, #Move_Focus)
              Case #PB_Shortcut_Down      : MoveDown( Gdt, 1, #Move_Focus)
              Case #PB_Shortcut_PageUp    : MoveUp(   Gdt, #Scroll_PageSize, #Move_Focus)
              Case #PB_Shortcut_PageDown  : MoveDown( Gdt, #Scroll_PageSize, #Move_Focus)
              Case #PB_Shortcut_Tab       : MoveRight(Gdt, 1, #Move_Focus)
                
              Case #PB_Shortcut_Delete, #PB_Shortcut_Back
                *Style = _SelectStyle(*mg, *mg\Row, *mg\Col)
                If *Style\Editable
                  _SetCellTextEvent(*mg, *mg\Row, *mg\Col, "")
                  _DrawCurrentCell(*mg)
                EndIf
                
              Case #PB_Shortcut_Return, #PB_Shortcut_F2
                ; text input takes place in current cell regardless of mouse position
                If ShowCell(gdt, *mg\Row, *mg\Col)
                  If _ManageEdit(*mg , "", #True, #False) : _Draw(*mg) : EndIf
                EndIf
                
            EndSelect
          EndIf
          
        EndIf
        
        ; text input takes place in current cell regardless of mouse position
      Case #PB_EventType_Input
        ResetBlock(gdt)
        If ShowCell(gdt, *mg\Row, *mg\Col)
          If _ManageEdit(*mg , Chr(GetGadgetAttribute(gdt, #PB_Canvas_Input)), #False, #False ) : _Draw(*mg) : EndIf
        EndIf
        
      Case #PB_EventType_MouseWheel
        dlt = GetGadgetAttribute(gdt, #PB_Canvas_WheelDelta)
        ; when moving wheel down towards me (like pressing key-down) => dlt < 0
        ; when moving wheel up   towards screen (like pressing key-up) => dlt > 0
        If dlt < 0
          MoveDown(gdt, -dlt, #Move_TopRC)
        ElseIf dlt > 0
          MoveUp(gdt, dlt, #Move_TopRC)
        EndIf
        
      Case #PB_EventType_LeftDoubleClick
        ; text input takes place in current cell regardless of mouse position
        ac = _AreaCol_Of_X(*mg, x)
        ar = _AreaRow_Of_Y(*mg, y)
        If ( _IsHeaderCol(*mg, ac) = #False ) And ( _IsHeaderRow(*mg, ar) = #False )
          ; cell area
          ResetBlock(gdt)
          If ShowCell(gdt, *mg\Row, *mg\Col)
            If _ManageEdit(*mg , "", #True, #False) : _Draw(*mg) : EndIf
          EndIf
          
        Else
          ; header area ?
          ac = _AreaResizeCol(*mg, x, y)
          If ac >= 0
            SelectElement(*mg\LstAreaCol() , ac)
            AutoWidthCol(gdt, *mg\LstAreaCol()\Col)
          Else
            ar = _AreaResizeRow(*mg, x, y)
            If ar >= 0
              SelectElement(*mg\LstAreaRow() , ar)
              AutoHeightRow(gdt, *mg\LstAreaRow()\Row)
            EndIf
          EndIf
          
        EndIf
        
      Case #PB_EventType_MouseEnter
        
      Case #PB_EventType_MouseMove 
        x = GetGadgetAttribute(gdt, #PB_Canvas_MouseX)
        y = GetGadgetAttribute(gdt, #PB_Canvas_MouseY)
        
        If GetGadgetAttribute(gdt, #PB_Canvas_Buttons) = #PB_Canvas_LeftButton
          ; continuing the current move-action if any ... or starting new one
          _ManageMouseMove(*mg, x, y)
        Else
          *mg\MoveStatus = #MouseMove_Nothing ; no move-action
          _ChangeMouse(*mg, x, y)
        EndIf
        
        
      Case #PB_EventType_MouseLeave
        
      Case #PB_EventType_LeftButtonUp
        x = GetGadgetAttribute(gdt, #PB_Canvas_MouseX)
        y = GetGadgetAttribute(gdt, #PB_Canvas_MouseY)
        
        mv = *mg\MoveStatus
        Select mv
          Case #MouseMove_Nothing
            ; a simple click in a cell
            row = _Row_Of_Y(*mg, y)
            col = _Col_Of_X(*mg, x)
            
            If row = *mg\Row And col = *mg\Col
              If _ManageEdit(*mg, "", #False, #True) : _Draw(*mg) : EndIf
            Else
              If _IsValidCol(*mg, col) And *mg\ColSortOnClick(col) And _IsHeaderRow(*mg, row) And ( _OverResizeCol(*mg, x, y) = #False )
                If *mg\DownAreaCol = _AreaCol_Of_X(*mg, x)
                  SortOnColumn(Gdt, col)
                EndIf
              EndIf
            EndIf
            
          Case #MouseMove_Select
            
          Case #MouseMove_Resize
            _UserResize(*mg, x, y)
            _Draw(*mg)
            *mg\MoveStatus = #MouseMove_Nothing
            
        EndSelect
        _ResetDownClick(*mg)
        
      Case #PB_EventType_LeftButtonDown
        x = GetGadgetAttribute(gdt, #PB_Canvas_MouseX)
        y = GetGadgetAttribute(gdt, #PB_Canvas_MouseY)
        ac = _AreaCol_Of_X(*mg, x)
        ar = _AreaRow_Of_Y(*mg, y)
        *mg\DownX = x : *mg\DownY = y
        *mg\DownAreaRow = ar : *mg\DownAreaCol = ac
        If ar >= 0 And ac >= 0
          row = *mg\LstAreaRow()\Row
          col = *mg\LstAreaCol()\Col
          
          If (_IsHeaderRow(*mg, row) = #False) And (_IsHeaderCol(*mg, col) = #False)
            ResetBlock(gdt)
            FocusCell(gdt, row, col)
          EndIf
        EndIf
        
      Case #PB_EventType_RightButtonDown
        If IsMenu(*mg\AttachedPopupMenu)
          ; launches the attachd popup menu - that's all! selected menu-items will need be handled by caller (via EvenMenu())!
          x = GetGadgetAttribute(gdt, #PB_Canvas_MouseX)
          y = GetGadgetAttribute(gdt, #PB_Canvas_MouseY)
          If _OverDataArea(*mg, x, y)
            If Not _OverBlock(*mg, x, y) : ResetBlock(gdt) : EndIf
            ;row = _Row_Of_Y(*mg, y)
            ;col = _Col_Of_X(*mg, x)
            ;MyGrid::FocusCell(gdt, row, col)
            ;DisplayPopupMenu(*mg\AttachedPopupMenu, WindowID(*mg\Window), x, y)
            DisplayPopupMenu(*mg\AttachedPopupMenu, WindowID(*mg\Window))
          EndIf
        EndIf
        
      Default ; any other event is simply ignored ... for now
        ProcedureReturn #False 
    EndSelect
    
  EndProcedure
  
  Procedure.i GridCallback()
    ManageEvent(EventGadget(), EventType())
  EndProcedure
  
  Procedure   Free(Gdt.i)
    Protected *mg.TGrid
    
    If IsGadget(Gdt)
      *mg = GetGadgetData(Gdt)
      If IsGadget(*mg\ColScroll)
        UnbindGadgetEvent(*mg\ColScroll, @_SynchronizeGridCols(), #PB_All)
      EndIf
      If IsGadget(*mg\RowScroll)
        UnbindGadgetEvent(*mg\RowScroll, @_SynchronizeGridRows(), #PB_All)
      EndIf
      UnbindGadgetEvent(Gdt, @GridCallback())
      
      UnbindGadgetEvent(*mg\CmbEdit, @_ComboCallback())
      FreeGadget(Gdt)
      FreeStructure(*mg)
    EndIf
    
  EndProcedure
  
  ;-- New Grid --------------------------------------------
  
  Procedure.i New(WinNbr, Gadget, X, Y, W, H, Rows = 500, Cols = 100, DrawNow = #True, VerScrollBar = #True, HorScrollBar = #True, RowNumbers = #True)
    Protected *mg.TGrid, oldGdtList
    Protected ret,i,j,ttlW,ttlH,xx,yy
    
    If Not IsWindow(WinNbr) : ProcedureReturn -1 : EndIf
    If IsGadget(Gadget)     : ProcedureReturn -1 : EndIf
    
    *mg = AllocateStructure(TGrid)
    
    ; -- sub-gadgets creation
    oldGdtList = UseGadgetList(WindowID(WinNbr)) 
    ret = CanvasGadget(Gadget, X, Y, W, H, #PB_Canvas_Keyboard|#PB_Canvas_Container);|#PB_Canvas_Border)
    If Gadget = #PB_Any : Gadget = ret: EndIf
    
    *mg\RowScroll = -1
    *mg\ColScroll = -1
    If VerScrollBar
      *mg\RowScroll = ScrollBarGadget(#PB_Any,0,0,10,20,0,100,10, #PB_ScrollBar_Vertical)
      SetGadgetData(*mg\RowScroll, *mg)
      BindGadgetEvent(*mg\RowScroll, @_SynchronizeGridRows(), #PB_All)
    EndIf
    
    If HorScrollBar
      *mg\ColScroll = ScrollBarGadget(#PB_Any,0,0,20,10,0,100,10)
      SetGadgetData(*mg\ColScroll, *mg)
      BindGadgetEvent(*mg\ColScroll, @_SynchronizeGridCols(), #PB_All)
    EndIf
    
    *mg\CmbEdit = ListViewGadget(#PB_Any,0,0,0,0)
    SetGadgetData(*mg\CmbEdit, Gadget)
    BindGadgetEvent(*mg\CmbEdit, @_ComboCallback())
    
    CloseGadgetList()
    BindGadgetEvent(Gadget, @GridCallback(), #PB_All)
    
    *mg\Window              = WinNbr
    *mg\Gadget              = Gadget
    *mg\ShowRowNumbers      = RowNumbers        ; 0/1
    *mg\WrapText            = #True
    *mg\HideZero            = #False
    *mg\DecimalCharacter    = '.'
    *mg\ThousandsSeparator  = ','
    *mg\DrawingW            = GadgetWidth(*mg\Gadget)
    *mg\DrawingH            = GadgetHeight(*mg\Gadget)
    If IsGadget(*mg\ColScroll) : *mg\DrawingH = *mg\DrawingH - #Scroll_Width : EndIf
    If IsGadget(*mg\RowScroll) : *mg\DrawingW = *mg\DrawingW - #Scroll_Width : EndIf
    
    SetGadgetData(Gadget, *mg)
    
    UseGadgetList(oldGdtList)
    
    _Reset(*mg, Rows, Cols)
    
    AddDefaultStyles(Gadget)
    
    ; Bind Event ShortcutReturn
    BindEvent(#PB_Event_Menu, @_DoEventMenuShortcutKey())
    
    ; no drawing - useful if we need to customize the grid first
    If DrawNow
      Resize(Gadget, X, Y, W, H)
    EndIf
    
    ProcedureReturn Gadget
    
  EndProcedure
  
  ;-------------------------------------------------------------------------------------------- 
  ;--- EXTRA Routines
  ;-------------------------------------------------------------------------------------------- 
  
  adResize = @Resize()
  adFree   = @Free()
  
  Structure TBigStr
    *Pointer
    CurOffset.i ; <= next offset (we write at that position at next append) ... when < 0 then allocation (re-allocation) is no more possible!
  EndStructure
  
  Procedure.i BigStrAppend(*me.TBigStr, nwStr.s)
    ; the fastest! saves a lot of time by avoiding repetitive memory allocation/move!
    ; the price is the reservation of a descent block of memory ~ 10 KB !
    Protected chunk,addReq,totSize, *p
    chunk = 10240
    
    If *me\CurOffset < 0    : ProcedureReturn  #False : EndIf
    If *me\Pointer = 0      : *me\Pointer = ReAllocateMemory(*me\Pointer, chunk) : EndIf
    
    ;addReq = Len(nwStr) * SizeOf(Character)    ; bit faster than: 
    addReq = StringByteLength(nwStr) 
    
    If addReq = 0           : ProcedureReturn  #True : EndIf
    totSize = MemorySize(*me\Pointer) 
    If totSize < *me\curOffset + addReq + 2
      ;*me\Pointer = ReAllocateMemory(*me\Pointer,*me\CurOffset + chunk + addReq + 2)
      *p = ReAllocateMemory(*me\Pointer,*me\CurOffset + chunk + addReq + 2)
      If *p
        *me\Pointer = *p
      Else
        *me\curOffset = -1
        ProcedureReturn #False
      EndIf
      totSize = MemorySize(*me\Pointer) 
    EndIf
    
    PokeS(*me\Pointer + *me\curOffset, nwStr) ; -1,#PB_Ascii)
    *me\curOffset = *me\curOffset + addReq
    ProcedureReturn #True
    
  EndProcedure
  
  Procedure.s BigStrGetString(*me.TBigStr)
    Protected strRet.s
    If *me\Pointer
      strRet = PeekS(*me\Pointer)
      *me\CurOffset = 0
      FreeMemory(*me\Pointer)
      ClearStructure(*me,TBigStr)
    EndIf
    
    ProcedureReturn strRet
  EndProcedure
  
  Procedure.i MySplitString(s.s, multiCharSep.s, Array a.s(1))
    ; last substring is not necesseraly followed by a char-sep
    Protected count, i, soc, lnStr,lnBStr, lnSep,lnBSep, ss, ee
    
    soc     = SizeOf(Character)
    lnSep   = Len(multiCharSep) :   lnBSep  = lnSep * soc
    lnStr   = Len(s)            :   lnBStr  = lnStr * soc
    If lnStr <= 0               :   ProcedureReturn 0       : EndIf
    
    count   = CountString(s,multiCharSep)
    If count <= 0
      Dim a(1) : a(1) = s : ProcedureReturn 1
    EndIf
    
    If Right(s,lnSep) <> multiCharSep : count + 1 : EndIf 
    
    Dim a(count) ; a(0) is ignored
    
    i = 1: ss = 0: ee = 0
    While ee < lnBStr
      If CompareMemory(@s + ee, @multiCharSep, lnBSep)
        a(i) = PeekS(@s + ss, (ee-ss)/soc)
        ss = ee + lnBSep: ee = ss: i+1
      Else
        ee + soc
      EndIf
    Wend
    
    If i < count+1 : a(count) = PeekS(@s + ss, (ee-ss)/soc) : EndIf
    ProcedureReturn count ;return count of substrings
    
  EndProcedure
  
  Procedure.i SplitStringClipboard(s.s, multiCharSep.s, Array a.s(1))
    ; char-sep is present between elements like in the clipboard
    ; a >> b >> c        will generate 3 elements 
    ; a >> b >>          will generate 3 elements as well
    Protected count, i, soc, lnStr,lnBStr, lnSep,lnBSep, ss, ee
    
    soc     = SizeOf(Character)
    lnSep   = Len(multiCharSep) :   lnBSep  = lnSep * soc
    lnStr   = Len(s)            :   lnBStr  = lnStr * soc
    If lnStr <= 0               :   ProcedureReturn 0       : EndIf
    
    count   = CountString(s,multiCharSep) + 1
    If count <= 1
      Dim a(1) : a(1) = s : ProcedureReturn 1
    EndIf
    
    Dim a(count) ; a(0) is ignored
    
    i = 1: ss = 0: ee = 0
    While ee < lnBStr
      If CompareMemory(@s + ee, @multiCharSep, lnBSep)
        a(i) = PeekS(@s + ss, (ee-ss)/soc)
        ss = ee + lnBSep: ee = ss: i+1
      Else
        ee + soc
      EndIf
    Wend
    
    If i < count+1: a(count) = PeekS(@s + ss, (ee-ss)/soc) : EndIf
    ProcedureReturn count ;return count of substrings
    
  EndProcedure
  
  Procedure.i StringToTable(s.s, ColSep.s, RowSep.s, Array a.s(2))
    ; converts a string having cellsep and rowsep to a 2-dim array
    Protected i, j, rows, cols, n
    Protected Dim tRows.s(0), Dim t.s(0)
    
    rows = MySplitString(s, RowSep, tRows())
    Dim a(rows, 0)
    For i=1 To rows
      n = SplitStringClipboard(tRows(i), ColSep, t())
      If n > cols
        cols = n
        ReDim a(rows, cols)
      EndIf
      For j=1 To n
        a(i, j) = t(j)
      Next
    Next
    ProcedureReturn rows * cols
    
  EndProcedure
  
  Procedure.i SetMultiText(Gdt.i, Txt.s, GRow.i, GCol.i, Row2 = 0, Col2 = 0, UseSep.s = #TAB$)
    ; Txt can be a single word OR a sequence with defined separator UseSep
    ; In case Txt is a sequence and it has less elements than required by (Row,Col)
    ;    then the last item in Txt is repeatedly used
    Protected i, iC, iR, R1,R2,C1,C2, *mg.TGrid = GetGadgetData(Gdt)
    Protected iWrd, nWrd, Dim tWrd.s(0)
    
    If Not _IsValidGenericRow(*mg, GRow) : ProcedureReturn #False : EndIf
    If Not _IsValidGenericCol(*mg, GCol) : ProcedureReturn #False : EndIf
    
    If UseSep <> ""
      nWrd = MySplitString(Txt, UseSep, tWrd())
    EndIf
    If nWrd <= 0 : nWrd = 1 : Dim tWrd(nWrd) : tWrd(1) = Txt : EndIf
    iWrd = 1
    
    If GRow = #RC_Data   : R1 = 1 :  R2 = *mg\Rows : EndIf
    If GRow = #RC_Any    : R1 = 0 :  R2 = *mg\Rows : EndIf
    
    If GCol = #RC_Data   : C1 = 1 :  C2 = *mg\Cols : EndIf
    If GCol = #RC_Any    : C1 = 0 :  C2 = *mg\Cols : EndIf
    
    If GRow >= 0 
      R1 = GRow : R2 = GRow
      If Row2 > GRow And Row2 <= *mg\Rows : R2 = Row2 : EndIf
    EndIf
    
    If GCol >= 0 
      C1 = GCol : C2 = GCol
      If Col2 > GCol And Col2 <= *mg\Cols : C2 = Col2 : EndIf
    EndIf
    
    For iR = R1 To R2
      For iC = C1 To C2
        _SetCellText( *mg , iR, iC, tWrd(iWrd) )
        If iWrd < nWrd : iWrd = iWrd + 1 : EndIf
      Next iC
    Next iR
    
  EndProcedure
  
  Procedure.s GetMultiText(Gdt.i, GRow.i, GCol.i, Row2 = 0, Col2 = 0, CellSep.s = #TAB$, RowSep.s = #LF$)
    Protected i, iC, iR, R1,R2,C1,C2, *mg.TGrid = GetGadgetData(Gdt)
    Protected bs.TBigStr
    
    If Not _IsValidGenericRow(*mg, GRow) : ProcedureReturn "" : EndIf
    If Not _IsValidGenericCol(*mg, GCol) : ProcedureReturn "" : EndIf
    
    If GRow = #RC_Data    : R1 = 1 :  R2 = *mg\Rows : EndIf
    If GRow = #RC_Any     : R1 = 0 :  R2 = *mg\Rows : EndIf
    
    If GCol = #RC_Data    : C1 = 1 :  C2 = *mg\Cols : EndIf
    If GCol = #RC_Any     : C1 = 0 :  C2 = *mg\Cols : EndIf
    
    If GRow >= 0 
      R1 = GRow : R2 = GRow
      If Row2 > GRow And Row2 <= *mg\Rows : R2 = Row2 : EndIf
    EndIf
    
    If GCol >= 0 
      C1 = GCol : C2 = GCol
      If Col2 > GCol And Col2 <= *mg\Cols : C2 = Col2 : EndIf
    EndIf
    
    For iR = R1 To R2
      For iC = C1 To C2
        BigStrAppend(@bs, _GetCellText(*mg , iR, iC))
        If iC < C2 : BigStrAppend(@bs, CellSep) : EndIf
      Next iC
      BigStrAppend(@bs, RowSep)
    Next iR
    
    ProcedureReturn BigStrGetString(@bs)
    
  EndProcedure
  
  Procedure.i ExportData(Gdt.i, Array Ret.s(2), WithHeaders = #True, VisibleOnly = #True)
    Protected i,j,n,m, iC, iR, R1,R2,C1,C2, *mg.TGrid = GetGadgetData(Gdt)
    
    If WithHeaders
      R1 = 0 : C1 = 0
    Else
      R1 = *mg\HdrRows : C1 = *mg\HdrCols
    EndIf
    R2 = *mg\Rows
    C2 = *mg\Cols
    
    If VisibleOnly
      n = GetNonHiddenRowCount(Gdt) - R1
      m = GetNonHiddenColCount(Gdt) - C1
      Dim Ret(n,m)
      
      If ArraySize(Ret()) = -1 : ProcedureReturn #False : EndIf
      i = 0
      For iR = R1 To R2
        If *mg\RowHeight(iR) <> -1
          j = 0
          For iC = C1 To C2
            If *mg\ColWidth(iC) <> -1
              Ret(i,j) = _GetCellText(*mg , iR, iC)
              j = j + 1
            EndIf
            If j > m : Break : EndIf
          Next iC
          i = i + 1
        EndIf
        If i > n : Break : EndIf
      Next iR
      
    Else
      n = R2 - R1
      m = C2 - C1
      Dim Ret(n,m)
      
      If ArraySize(Ret()) = -1 : ProcedureReturn #False : EndIf
      i = 0
      For iR = R1 To R2
        j = 0
        For iC = C1 To C2
          Ret(i,j) = _GetCellText(*mg , iR, iC)
          j = j + 1
          If j > m : Break : EndIf
        Next iC
        i = i + 1
        If i > n : Break : EndIf
      Next iR
      
    EndIf
    
    ProcedureReturn #True
    
  EndProcedure
  
  Procedure.i ImportData(Gdt.i, Array A.s(2))
    ; A() is expected to hold all data the grid will receive icluding headers!
    Protected   rows, cols, *mg.TGrid = GetGadgetData(Gdt)
    
    rows    = ArraySize(A(), 1)
    cols    = ArraySize(A(), 2)
    If rows >= 0 And cols >= 0
      _ChangRowCountAndColCount(*mg, rows, cols)
      CopyArray(A(), *mg\gData())
      _RefreshRowNumbers(*mg)
      _Draw(*mg)
    EndIf
    
  EndProcedure
  
  Procedure.s GetBlockText(Gdt.i, CellSep.s = #TAB$, RowSep.s = #NewLine$)
    Protected i, iC, iR, R1,R2,C1,C2, *mg.TGrid = GetGadgetData(Gdt)
    Protected bs.TBigStr
    
    R1 = *mg\Row    :   R2 = *mg\Row2   : If R2 <= 0 : R2 = R1 : EndIf
    C1 = *mg\Col    :   C2 = *mg\Col2   : If C2 <= 0 : C2 = C1 : EndIf
    
    If Not _IsValidRow(*mg, R1) : ProcedureReturn "" : EndIf
    If Not _IsValidRow(*mg, R2) : ProcedureReturn "" : EndIf
    If Not _IsValidCol(*mg, C1) : ProcedureReturn "" : EndIf
    If Not _IsValidCol(*mg, C2) : ProcedureReturn "" : EndIf
    
    For iR = R1 To R2
      If *mg\RowHeight(iR) <= 0 : Continue : EndIf
      For iC = C1 To C2
        If *mg\ColWidth(iC) <= 0 : Continue : EndIf
        If (iC > C1) : BigStrAppend(@bs, CellSep) : EndIf
        BigStrAppend(@bs, _GetCellText(*mg , iR, iC))
      Next iC
      BigStrAppend(@bs, RowSep)
    Next iR
    
    ProcedureReturn BigStrGetString(@bs)
    
  EndProcedure
  
  Procedure.i SetBlockText(Gdt.i, Txt.s, EditableOnly.i = #True, CellSep.s = #TAB$, RowSep.s = #NewLine$, AutoDim.i=#False)
    ; useful when pasting, procees to setting text in grid as blocks in circular manner
    ; 
    Protected Dim a.s(0,0), m, n, tr, tc,ret, *s.TStyle
    Protected i, j, iC, iR, R1,R2,C1,C2, *mg.TGrid = GetGadgetData(Gdt)
    
    If StringToTable(Txt, CellSep, RowSep, a())
      tr = ArraySize(a(), 1)
      tc = ArraySize(a(), 2)
      
      If AutoDim
        _ChangRowCountAndColCount(*mg, tr, tc)
        For iR = 1 To tr
          For iC = 1 To tc
            If EditableOnly
              *s = _SelectStyle(*mg, iR, iC)
              If *s\Editable
                _SetCellText(*mg, iR, iC, a(iR, iC))
              EndIf
            Else
              _SetCellText(*mg, iR, iC, a(iR, iC))
            EndIf
          Next
        Next
        *mg\Row = 1 : *mg\Col = 1
        _Draw(*mg)
        ProcedureReturn
      EndIf
      
      R1 = *mg\Row    :   R2 = *mg\Row2
      C1 = *mg\Col    :   C2 = *mg\Col2
      
      If Not _IsValidRow(*mg, R1) : ProcedureReturn : EndIf
      If Not _IsValidCol(*mg, C1) : ProcedureReturn : EndIf
      If Not _IsValidRow(*mg, R2) : ProcedureReturn : EndIf
      If Not _IsValidCol(*mg, C2) : ProcedureReturn : EndIf
      
      ; no block is selected ... we paste as much available
      If R2 = 0
        ;R2 = R1
        ;For i=2 To tr
        ;    ret = _BelowRow(*mg, R2, C1, #False)
        ;    If ret >= 0 : R2 = ret : EndIf
        ;Next
        *mg\Row2 = *mg\Row
        _MoveDown(*mg, tr-1, #Move_Block)
        R2 = *mg\Row2
      EndIf
      If  C2 = 0
        ;C2 = C1
        ;For i=2 To tc
        ;    ret = _NextCol(*mg, R1, C2, #False)
        ;    If ret >= 0 : C2 = ret : EndIf
        ;Next
        *mg\Col2 = *mg\Col
        _MoveRight(*mg, tc-1, #Move_Block)
        C2 = *mg\Col2
      EndIf
      
      m = 0
      For iR = R1 To R2
        m = m + 1
        n = 0
        If m > tr : m = 1 : EndIf
        For iC = C1 To C2
          n = n + 1
          If n > tc : n = 1 : EndIf
          If EditableOnly
            *s = _SelectStyle(*mg, iR, iC)
            If *s\Editable
              _SetCellText(*mg , iR, iC, a(m,n))
            EndIf
          Else
            _SetCellText(*mg , iR, iC, a(m,n))
          EndIf
        Next iC
      Next iR
      _Draw(*mg)
      
    EndIf
    
  EndProcedure
  
  Procedure.i SaveToTextFile(gdt.i, useSep.s, List extraHeaders.s(), fName.s, VisibleOnly = #True, format=#PB_Ascii)
    ; 
    Protected   *mg.TGrid = GetGadgetData(gdt)
    Protected   i,j,nbItems,fileNbr, curLine.s
    
    If *mg\Cols <= 0 Or *mg\Rows <= 0 : ProcedureReturn : EndIf
    
    fileNbr = CreateFile(#PB_Any, fName)
    If fileNbr <= 0        
      MessageRequester("Error","Unable to create file ...", #PB_MessageRequester_Error)
      ProcedureReturn 0
    EndIf 
    If useSep = "" : useSep = #TAB$ : EndIf
    
    WriteStringFormat(fileNbr, format)
    
    ; building the text file from gadget content
    Protected bs.TBigStr,r,c
    
    ForEach extraHeaders()
      WriteStringN(fileNbr, extraHeaders(), format)
    Next
    If ListSize(extraHeaders()) > 0
      WriteStringN(fileNbr, "", format)
    EndIf
    If VisibleOnly
      For r = 0 To *mg\Rows
        If *mg\RowHeight(r) <= 0 : Continue : EndIf
        For c = 0 To *mg\Cols
          If *mg\ColWidth(c) <= 0 : Continue : EndIf
          BigStrAppend(@bs, _GetCellText(*mg,r,c))
          If c < *mg\Cols : BigStrAppend(@bs, useSep) : EndIf
        Next
        curLine = BigStrGetString(@bs)
        WriteStringN(fileNbr, curLine, format)
      Next
    Else
      For r = 0 To *mg\Rows
        For c = 0 To *mg\Cols
          BigStrAppend(@bs, _GetCellText(*mg,r,c))
          If c < *mg\Cols : BigStrAppend(@bs, useSep) : EndIf
        Next
        curLine = BigStrGetString(@bs)
        WriteStringN(fileNbr, curLine, format)
      Next
    EndIf
    
    CloseFile(fileNbr)
    
    ProcedureReturn 1
    
  EndProcedure
  
  Procedure.i AutoAlignColumns(Gdt.i)
    ; browse thru data-rows of various cols and assign the suitable alignment
    ; Left for text and Right for numbers
    Protected   *mg.TGrid = GetGadgetData(Gdt)
    Protected   iR,iC, R1,R2, C1,C2, ali
    
    R1 = _FirstDataRow(*mg) : R2 = *mg\Rows
    C1 = _FirstDataCol(*mg) : C2 = *mg\Cols
    
    For iC = C1 To C2
      ali = #Align_Right
      For iR = R1 To R2
        If *mg\gData(iR, iC) = "" : Continue : EndIf
        If Not IsNumber(*mg\gData(iR, iC), *mg\ThousandsSeparator, *mg\DecimalCharacter )
          ali = #Align_Left : Break
        EndIf
      Next
      
      If ali = #Align_Right
        AssignStyle(Gdt, #RC_Data, iC, "Right")
      Else
        AssignStyle(Gdt, #RC_Data, iC, "Left")
      EndIf
    Next
    
  EndProcedure
  
  Procedure.i Transpose(Gdt.i)
    ; does not preserve styles!
    Protected   *mg.TGrid = GetGadgetData(Gdt)
    Protected   iR,iC, h_row, h_col
    Protected   Dim t.s(0,0)
    
    h_row = *mg\HdrRows
    h_col = *mg\HdrCols
    Dim t(*mg\Cols, *mg\Rows)
    For iC = 0 To *mg\Cols
      For iR = 0 To *mg\Rows
        t(iC, iR) = *mg\gData(iR, iC)
      Next
    Next
    _Reset(*mg, *mg\Cols, *mg\Rows)
    CopyArray(t(), *mg\gData())
    
    *mg\HdrRows = h_col
    *mg\HdrCols = h_row
    _Draw(*mg)
    
  EndProcedure
  
  ; these routines are not used to format numbers, they are used to parse text to numbers (in auto-align and in sorting)
  
  Procedure.i SetDecimalCharacter(Gdt.i, Char.s = ".")
    Protected   *mg.TGrid = GetGadgetData(Gdt)
    *mg\DecimalCharacter = Asc(Left(Char, 1))
  EndProcedure
  
  Procedure.i SetThousandsSeparator(Gdt.i, Char.s = ",")
    Protected   *mg.TGrid = GetGadgetData(Gdt)
    *mg\ThousandsSeparator = Asc(Left(Char, 1))
  EndProcedure
  
  
EndModule


;-------------------------------------------------------------------------------------------- 
;--- Test and examples
;-------------------------------------------------------------------------------------------- 

CompilerIf #PB_Compiler_IsMainFile
  EnableExplicit
  
  Enumeration 
    #Win_Nbr
    #Grid_Nbr
    #Grid_PopupMenu
    #MenuItem_1
    #MenuItem_2
    #MenuItem_3
    #MenuItem_4
    #MenuItem_5
    #Cntr_Nbr
    #Btn_Save
    #Btn_Load
    #Btn_Sort
  EndEnumeration
  
  Global i,j,r,c,s.s, EvGd, Evnt, EvTp, EvMn, txt.s, NewList lst.s()
  Global Font_A16    = LoadFont(#PB_Any, "Arial", 16)
  Global Dim Images(2)
  
  UsePNGImageDecoder()
  Images(0) = LoadImage(#PB_Any, #PB_Compiler_Home + "examples/sources/Data/world.png")
  Images(1) = LoadImage(#PB_Any, #PB_Compiler_Home + "examples/sources/Data/file.bmp")
  Images(2) = LoadImage(#PB_Any, #PB_Compiler_Home + "examples/sources/Data/PureBasic.bmp")
  
  Procedure.s random_text(max_len)
    Protected   txt.s, buf.s = "ABCDEFGHIJKLMNOPQRSTUVWXYZ" + "abcdefghijklmnopqrstuvwxyz" + " 0123456789"
    Protected   i, n = Len(buf), j = Random(max_len)
    
    For i=1 To j
      txt + Mid(buf, Random(n,1), 1)
    Next
    ProcedureReturn txt
    
  EndProcedure
  
  Procedure update_window()
    ResizeGadget(#Cntr_Nbr, WindowWidth(#Win_Nbr) - 80, #PB_Ignore, #PB_Ignore, #PB_Ignore)
    ResizeGadget(#Grid_Nbr, #PB_Ignore, #PB_Ignore, WindowWidth(#Win_Nbr) - 100, WindowHeight(#Win_Nbr) - 20)
    ;MyGrid::Resize(#Grid_Nbr, #PB_Ignore, #PB_Ignore, WindowWidth(#Win_Nbr) - 100, WindowHeight(#Win_Nbr) - 20)
    
  EndProcedure
  
          
  If OpenWindow(#Win_Nbr, 0, 0, 800, 420, "MyGrid", #PB_Window_SystemMenu | #PB_Window_MinimizeGadget | #PB_Window_MaximizeGadget | #PB_Window_ScreenCentered|#PB_Window_SizeGadget)
    SetWindowColor(#Win_Nbr,#White)
    
    If CreatePopupMenu(#Grid_PopupMenu)      ; creation of the pop-up menu begins...
      MenuItem(#MenuItem_1, "Copy")
      MenuItem(#MenuItem_2, "Paste")
      MenuBar()
      MenuItem(#MenuItem_3, "Show")
      MenuItem(#MenuItem_4, "Hide")
      MenuItem(#MenuItem_5, "Freeze here")
    EndIf
    
    r = 200 : c = 50
    MyGrid::New(#Win_Nbr, #Grid_Nbr, 10, 10, 700, 380, r, c, #False)
    
    ContainerGadget(#Cntr_Nbr, 720, 10, 80, 390, #PB_Container_Flat)
    SetGadgetColor(#Cntr_Nbr, #PB_Gadget_BackColor, #White)
    ButtonGadget(#Btn_Save, 5, 10, 70, 20,"Save to txt")
    ButtonGadget(#Btn_Load, 5, 40, 70, 20,"Load from txt")
    ButtonGadget(#Btn_Sort, 5, 70, 70, 20,"Multi-Sort")
    CloseGadgetList()
    
    ; ---- names of builtin styles - ready to use by name
    ; "Default", "HeaderGradient", "Header", "HeaderLeft", "HeaderRight"
    ; "Center", "Left", "Right", "EditLeft", "EditRight", "EditCenter"
    ; "Extra", "Detail", "Checkbox", "Combo", "Button", "Image", "ImageFit"
    
    For i = 1 To MyGrid::GetRowCount(#Grid_Nbr)
      MyGrid::SetText(#Grid_Nbr, i, 3, Str(Random(1000)))
      MyGrid::SetText(#Grid_Nbr, i, 4, random_text(5))
      MyGrid::SetText(#Grid_Nbr, i, 5, random_text(40))
      MyGrid::SetText(#Grid_Nbr, i, 6, StrF(Random(1000) / 100.0, 2))
      MyGrid::SetText(#Grid_Nbr, i, 9, "Button " + Str(i))
      MyGrid::SetText(#Grid_Nbr, i,10, Str(Images(Random(2))))            ; any one of the 3 loaded images
      MyGrid::SetText(#Grid_Nbr, i,11, Str(Images(Random(2))))            ; any one of the 3 loaded images
    Next
    
    ; customizing headers
    MyGrid::AssignStyle(#Grid_Nbr, MyGrid::#RC_Header, MyGrid::#RC_Any, "Header")
    MyGrid::AssignStyle(#Grid_Nbr, MyGrid::#RC_Any, MyGrid::#RC_Header, "Header")
    
    MyGrid::SetText(#Grid_Nbr, 0, 1, "Editable Center")
    MyGrid::SetText(#Grid_Nbr, 0, 2, "Editable Left")
    MyGrid::SetText(#Grid_Nbr, 0, 3, "Click to Sort")
    MyGrid::SetText(#Grid_Nbr, 0, 4, "Click to Sort")
    MyGrid::SetText(#Grid_Nbr, 0,10, "Image")
    MyGrid::SetText(#Grid_Nbr, 0,11, "Fit Image")
    MyGrid::SetRowHeight(#Grid_Nbr, 0, 2 * MyGrid::#Default_RowHeight)
    
    UseModule MyGrid
    
    ; defining own style
    Define NewList myItems.s()
    AddElement(myItems())
    myItems() = "String"
    AddElement(myItems())
    myItems() = "Integer"
    AddElement(myItems())
    myItems() = "Double"
    AddElement(myItems())
    myItems() = "Double"
    AddElement(myItems())
    myItems() = "Double"
    AddElement(myItems())
    myItems() = "Double"
    AddElement(myItems())
    myItems() = "Double"
    
    AddNewStyle(#Grid_Nbr, "MyCombo")
    SetStyleCellType(#Grid_Nbr, "MyCombo", #CellType_Combo)
    SetStyleEditable(#Grid_Nbr, "MyCombo")
    SetStyleAlign(#Grid_Nbr, "MyCombo", #Align_Center)
    SetStyleForeColor(#Grid_Nbr, "MyCombo", #Blue)
    SetStyleItemList(#Grid_Nbr, "MyCombo", myItems())
    
    UnuseModule MyGrid
    
    ; defining style for columns (can de defined for rows/cells as well...)
    MyGrid::AssignStyle(#Grid_Nbr, MyGrid::#RC_Data, 1, "EditCenter")  ; assign to data-cells in col# 1 editable center-alignment
    MyGrid::AssignStyle(#Grid_Nbr, MyGrid::#RC_Data, 2, "EditLeft")    ; assign to data-cells in col# 2 editable left-alignment
    MyGrid::AssignStyle(#Grid_Nbr, MyGrid::#RC_Data, 3, "Right")       ; assign to data-cells in col# 3 non-editable right-alignment
    MyGrid::AssignStyle(#Grid_Nbr, MyGrid::#RC_Data, 4, "EditCenter")  ; assign to data-cells in col# 4 editable center-alignment
    MyGrid::AssignStyle(#Grid_Nbr, MyGrid::#RC_Data, 6, "EditRight")   ; assign to data-cells in col# 6 editable right-alignment
    MyGrid::AssignStyle(#Grid_Nbr, MyGrid::#RC_Data, 7, "Checkbox")    ; assign to data-cells in col# 7 default checkbox
    MyGrid::AssignStyle(#Grid_Nbr, MyGrid::#RC_Data, 8, "MyCombo")       ; assign to data-cells in col# 8 default combo
    MyGrid::AssignStyle(#Grid_Nbr, MyGrid::#RC_Data, 9, "Button")      ; assign to data-cells in col# 8 default Button
    MyGrid::AssignStyle(#Grid_Nbr, MyGrid::#RC_Data,10, "Image")       ; assign to data-cells in col# 8 default Image
    MyGrid::AssignStyle(#Grid_Nbr, MyGrid::#RC_Data,11, "ImageFit")    ; assign to data-cells in col# 8 default ImageFit (resize image)
    
    ; customizing a builtin style
    MyGrid::SetStyleItems(#Grid_Nbr, "Combo", "A,B,C,D,AA,BBB,CCC,ABCD,EF,XXX,AAA,ZZZ", ",")
    MyGrid::SetStyleForeColor(#Grid_Nbr, "Combo", $2A2AA5)
    
    ; hiding col 15 and row 17 ... for good user cannot un-hide via resizing
    MyGrid::HideCol(#Grid_Nbr,15, 1)
    MyGrid::HideRow(#Grid_Nbr,17, 1)
    
    ; enabling sort-on-click for cols: 3, 4, 6
    MyGrid::EnableSortOnClick(#Grid_Nbr, 3)
    MyGrid::EnableSortOnClick(#Grid_Nbr, 4)
    MyGrid::EnableSortOnClick(#Grid_Nbr, 6)
    
    MyGrid::AttachPopup(#Grid_Nbr, #Grid_PopupMenu)
    
    ; adding a new custom-style
    MyGrid::AddNewStyle(#Grid_Nbr, "BlueYellowRight")   ; at creation its is a replica of the default style
    MyGrid::SetStyleAlign(#Grid_Nbr, "BlueYellowRight", MyGrid::#Align_Right)
    MyGrid::SetStyleBackColor(#Grid_Nbr, "BlueYellowRight", #Yellow)
    MyGrid::SetStyleForeColor(#Grid_Nbr, "BlueYellowRight", #Blue)
    MyGrid::SetStyleFont(#Grid_Nbr, "BlueYellowRight", LoadFont(#PB_Any, "Veradna", 14))
    MyGrid::SetStyleEditable(#Grid_Nbr, "BlueYellowRight", #True)
    
    ; assigning this custom style to some cells:
    ; styles assigned at cell levels will overwrite styles assigned at higher levels (at row/ col/...)
    MyGrid::AssignStyle(#Grid_Nbr, 3, 1, "BlueYellowRight")
    MyGrid::AssignStyle(#Grid_Nbr, 7, 2, "BlueYellowRight")
    MyGrid::AssignStyle(#Grid_Nbr, 9, 5, "BlueYellowRight")
    
    ; <<<--------------- Hiding Focus Rectangle ------------------------>>>
    ; Example: to hide focus-rectangle,. change its color to -1 / ozzie / un-comment below line
    ;MyGrid::SetColorAttribute(#Grid_Nbr, #MyGrid::Color_FocusBorder, -1)
    
    MyGrid::Redraw(#Grid_Nbr)
    
    MyGrid::AutoHeightRow(#Grid_Nbr, 1)
    MyGrid::AutoHeightRow(#Grid_Nbr, 2)
    MyGrid::AutoHeightRow(#Grid_Nbr, 9)
    
    Define row
    For row = 1 To MyGrid::GetRowCount(#Grid_Nbr)
      MyGrid::AutoHeightRow(#Grid_Nbr, row)
    Next
      
    MyGrid::AutoWidthCol(#Grid_Nbr,5)
    
    BindEvent(#PB_Event_SizeWindow, @update_window(), #Win_Nbr)
    
    Repeat
      EvGd = -1
      EvTp = -1
      EvMn = -1
      Evnt = WaitWindowEvent()
      Select Evnt
          
        Case MyGrid::#Event_Change
          r = MyGrid::GetChangedRow(EventGadget())
          c = MyGrid::GetChangedCol(EventGadget())
          Debug " ... Change occured in Cell (" + Str(r) +","+ Str(c) + ") old text: >>" + MyGrid::GetChangedText(EventGadget()) + "<< and new text: >>" + MyGrid::GetText(EventGadget(), r, c) +"<<"
          
        Case MyGrid::#Event_Click
          r = MyGrid::GetClickedRow(EventGadget())
          c = MyGrid::GetClickedCol(EventGadget())
          Debug " ... Button clicked in Cell (" + Str(r) +","+ Str(c) + ")"
          
        Case #PB_Event_SizeWindow
;           ResizeGadget(#Cntr_Nbr, WindowWidth(#Win_Nbr) - 80, #PB_Ignore, #PB_Ignore, #PB_Ignore)
;           MyGrid::Resize(#Grid_Nbr, #PB_Ignore, #PB_Ignore, WindowWidth(#Win_Nbr) - 100, WindowHeight(#Win_Nbr) - 20)
;           
        Case #PB_Event_Gadget 
          EvGd = EventGadget()
          EvTp = EventType()
          Select EvGd
            Case #Btn_Save
              txt = OpenFileRequester("Save", GetTemporaryDirectory() + "MyGrid.TXT", "Text (*.txt)|*.txt;*.bat|All files (*.*)|*.*",0)
              If txt <> ""
                MyGrid::SaveToTextFile(#Grid_Nbr, #TAB$, lst(), txt)
              EndIf
              
            Case #Btn_Sort
              MessageRequester("Sort","the grid will be sorted on col 6 (asc) and then col 4 (desc)")
              MyGrid::ResetSort(#Grid_Nbr)
              MyGrid::AddSortingCol(#Grid_Nbr, 6, #PB_Sort_Ascending)
              MyGrid::AddSortingCol(#Grid_Nbr, 4, #PB_Sort_Descending)
              MyGrid::Sort(#Grid_Nbr)
              
              
          EndSelect
          
        Case #PB_Event_Menu
          EvMn = EventMenu()
          Select EvMn
            Case #MenuItem_1 :
              SetClipboardText(MyGrid::GetBlockText(#Grid_Nbr))
              MessageRequester("Copy","Selected block copied to clipboard")
            Case #MenuItem_2 : 
              MyGrid::SetBlockText(#Grid_Nbr, GetClipboardText())
              
            Case #MenuItem_3 : Debug " popup menu 3 "
            Case #MenuItem_4 : Debug " popup menu 4 "
            Case #MenuItem_5 : Debug " popup menu 5 "
          EndSelect
          
      EndSelect
      
      
    Until  Evnt = #PB_Event_CloseWindow
  EndIf
CompilerEndIf
; IDE Options = PureBasic 6.00 LTS (MacOS X - x64)
; CursorPosition = 5578
; Folding = ---------------------------------------------
; Markers = 5539
; EnableXP
; CompileSourceDirectory
; Compiler = PureBasic 6.00 Beta 4 - C Backend (Windows - x64)