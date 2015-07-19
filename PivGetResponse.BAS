Command PivGetResponse (CLA=&H00, INS=&HC0, Lc=0, FirstByte@, oData$, Input Le)

Rem  Return Codes

Rem  61XX   Normal processing, XX bytes still available
Rem  6281   Part of returned data may be corrupt
Rem  6700   Wrong length (incorrect Le field)   *Not implemented, using 6CXX
Rem  6A86   Incorrect P1/P2
Rem  6CXX   Wrong length (incorrect Le field, XX specifies the exact length)
Rem  9000   Successful execution


Private BytesToRead@ = 0

Private RemainingBytes& = 0

Private fLen& = 0

Private CloseFlag = False


Rem  ResponseBuffer has priority over open files

If Len(ResponseBuffer$) > 0 Then

    Close

    FirstByte@ = Asc (ResponseBuffer$ (1))

    If Le = 0 Or Le >= Len (ResponseBuffer$) Then

        oData$ = Right$ (ResponseBuffer$, Len (ResponseBuffer$) - 1)

        ResponseBuffer$ = ""

        SW1SW2 = &H9000

    Else

        oData$ = Mid$ (ResponseBuffer$, 2, Le - 1)

        ResponseBuffer$ = Mid$ (ResponseBuffer$, Le + 1)

        SW1 = &H61

        SW2 = Len (ResponseBuffer$)

    End If

    GoTo EndProc

End If

Rem GoTo EndProc    '*******************************************************


Rem  Check for no open files or EOF on an open file:

If fNum% = 0 Or EOF (#fNum%) = True Then

    Close

    SW1SW2 = &H6C00

    GoTo EndProc

End If


Private FileLength& As Long

Private LenLowByte@ As Byte

Private LenHiByte@ As Byte

Private BerHeader$ As String


Rem  Build BER-TLV header if this is the first GET RESPONSE:

If Seek (#fNum%) = 1 Then       '  First read cycle, need BER-TLV

    FileLength& = Len (#fNum%)

    LenLowByte@ = FileLength&

    LenHiByte@ = FileLength& / 256

    If FileLength& <= &H7F Then                         '  1 byte tag

        BerHeader$ = Chr$ (&H53) + Chr$ (LenLowByte@)

    ElseIf FileLength& <= &HFF Then                     '  2 byte tag

        BerHeader$ = Chr$ (&H53) + Chr$ (&H81) + Chr$ (LenLowByte@)

    Else                                                '  3 byte tag

        BerHeader$ = Chr$ (&H53) + Chr$ (&H82) + Chr$ (LenHiByte@) + Chr$ (LenLowByte@)

    End If

End If


Rem  Calculate how many bytes to read based on Le and number of
Rem  bytes remaining in file.  Read remaining bytes, putting
Rem  first byte into FirstByte@ and the rest into oData$ so we
Rem  can return up to FF bytes.  Also need to allow for BER header,
Rem  which GET DATA includes in the total length returned in a
Rem  61XX response code:

RemainingBytes& = Len (#fNum%) - Seek (#fNum%) + 1

If Le = 0 Then Le = &HFF

If Len (BerHeader$) > 0 Then

    If Le < RemainingBytes& + Len (BerHeader$) Then

        BytesToRead@ = Le - Len (BerHeader$)

    Else

        BytesToRead@ = RemainingBytes&

        CloseFlag = True

    End If

    FirstByte@ = Asc (BerHeader$ (1))

    Get fNum%, , ResponseBuffer$, BytesToRead@

    Call CheckFileError ()

    oData$ = Right$ (BerHeader$, Len (BerHeader$) - 1) + ResponseBuffer$

Else

    If Le > RemainingBytes& Then

        BytesToRead@ = RemainingBytes&

        CloseFlag = True

    Else

        BytesToRead@ = Le

        If Le = RemainingBytes& Then CloseFlag = True

    End If

    Get fNum%, , ResponseBuffer$, 1 : Call CheckFileError ()

    FirstByte@ = Asc (ResponseBuffer$ (1))

    Get fNum%, , oData$, BytesToRead@ - 1 : Call CheckFileError ()

End If


Rem  Close file if all data has been read and set SW1SW2:

ResponseBuffer$ = ""

If CloseFlag = True Then

    Close

    SW1SW2 = &H9000

Else

    SW1 = &H61

    RemainingBytes& = Len (#fNum%) - Seek (#fNum%) + 1

    If RemainingBytes& <= &HFF Then

        SW2 = RemainingBytes&

    Else

        SW2 = &HFF

    End If

End If


EndProc:

Call SuspendSW1SW2Processing()

End Command '===========================================================

Function CheckFileError ()

If FileError <> 0 Then

    Close

Rem    oData$ = "BasicCard File Read Error: " + Hex$ (FileError)

    Exit

End If

End Function