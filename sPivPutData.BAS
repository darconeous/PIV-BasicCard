Command sPivPutData (CLA=&H00, INS=&HDB, iData$)

Rem Stubbed out version

SW1SW2 = &H6A81     ' Function not supported

Exit


Rem  ACR:  Data dependent, see SP800-73 Table 1.

Rem  Lc = Length of data field

Rem  iData$ = Tag '5C + (Length of BER-TLV = 3) + (BER-TLV Tag of the
Rem    data object to be overwritten) + '53 + (Length of data) + data


Const TAGHEADER = 7     '  Length in bytes of the tag header information

Private fName$ As String


SecurityStatus.ChallengeFlag = False

If SecurityStatus.AdminKeyVerified <> True Then    '  Security condition not satisfied,
                                    '  Admin Key required for all writes
    SW1SW2 = &H6982

    Exit

End If


Close   '  Can't have multiple files open


Select Case Asc (iData$ (5))     '  Set filename

    Case CCC

        fName$ = "CCC"

    Case CHUID

        fName$ = "CHUID"

    Case AUTHKEY

        fName$ = "PivAuthKey"

    Case FINGER1

        fName$ = "Fingerprint1"

Rem    Case FINGER2

Rem        fName$ = "Fingerprint2"

    Case SECURITYOBJ

        fName$ = "SecurityObject"

    Case Else   ' Invalid tag

        SW1SW2 = &H6A82

        Exit

End Select


fNum% = Open fName$ For Binary


If FileError <> 0 Then  ' **TODO:  Need better mapping between file errors and SW

    SW1SW2 = &H6F + FileError      '  This is a non-SP800-73 file error

    Exit

End If


Put #fNum%, 1, Mid$ (iData$, TAGHEADER + 1)


If FileError <> 0 Then  ' **TODO:  Need better mapping between file errors and SW

    SW1SW2 = &H6F + FileError   '  This is a non-SP800-73 file error

    Exit

End If

End Command '===========================================================
