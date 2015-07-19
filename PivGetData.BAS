Command PivGetData(CLA=&H00, INS=&HCB, iData$ as String*5, Disable Le)


Rem  Three-byte tag value with third byte containing file ID:  5F C1 XX
Rem  One, two, or three byte Length:

Rem     One byte:  00-7F length
Rem     Two bytes: &H81, 00-FF length
Rem     Three bytes:    &H82, 0000-FFFF length

Rem     iData: Tag 5C: Length 4, 5, or 6: Value = BER-TLV of target object
Rem             iData length can be 

Rem     Parsing:

Rem         1.  iData(1) = 5C

Rem         2.  iData(2) = length of BER-TLV

Rem         3.  iData(3-5) = Object Tag '5F 'C1 XX

Rem         4.  File ID = XX

Rem         5.  If iData(2) = 4 then Object length = iData(6)

Rem         6.  If iData(2) = 5 then

Rem         7.      iData(6) = '81

Rem         8.      iData(7) = Object length@

Rem         9.  If iData(2) = 6 then

Rem         10.     iData(6) = '82

Rem         11.     iData(7,8) = Object length%


Private fName$ As String

Private fLen& As Long

Private BytesToRead@ As Byte


SecurityStatus.ChallengeFlag = False

Close                           '  Can't have multiple files open

fPosition& = 0

If Asc (iData$ (5)) = CSN Then  '  Asking for Card Serial Number

    ResponseBuffer$ = CardSerialNumber()

    SW1 = &H61

    SW2 = Len (ResponseBuffer$)

    GoTo EndProc

End If

Rem  Possible code change:  Use Hex$ to convert tag to string filename.

Select Case Asc (iData$ (5))    '  Set filename and check ACR

    Case CCC

        fName$ = "CCC"

    Case CHUID

        fName$ = "CHUID"

    Case AUTHKEY

        If ContactMode = False Then

            SW1SW2 = &H6982

            GoTo EndProc

        Else

            fName$ = "PivAuthKey"

        End If

    Case FINGER1

        If SecurityStatus.CardholderPinVerified = False Or_
            ContactMode = False Then

            SW1SW2 = &H6982

            GoTo EndProc

        Else

            fName$ = "Fingerprint1"

        End If

Rem  Second biometric object removed per SP800-73-1 update

Rem    Case FINGER2

Rem        If SecurityStatus.CardholderPinVerified = False Or_
Rem            ContactMode = False Then

Rem            SW1SW2 = &H6982

Rem            GoTo EndProc

Rem        Else

Rem            fName$ = "Fingerprint2"

Rem        End If

Rem Insert Below Here

Rem  Printed Information, Card Holder Facial Image, X.509 Certificate for 
Rem  Digital Signature, X.509 Certificate for Key Management, and X.509 
Rem  Certificate for Card Authentication are optional and can be loaded
Rem  by defining INCOPTDATA in PivCard.Bas.

#IfDef INCOPTDATA
    Case PRINTEDINFO

        If SecurityStatus.CardholderPinVerified = False Or_
            ContactMode = False Then

            SW1SW2 = &H6982

            GoTo EndProc

        Else

            fName$ = "PrintedInfo"

        End If

    Case FACIALINFO

        If SecurityStatus.CardholderPinVerified = False Or_
            ContactMode = False Then

            SW1SW2 = &H6982

            GoTo EndProc

        Else

            fName$ = "FacialInfo"

        End If

    Case DIGITALSIG

        fName$ = "DigitalSig"

    Case KEYMGNT

        fName$ = "KeyMgnt"

    Case CARDAUTH

        fName$ = "CardAuth"
#EndIf

Rem Insert Above Here

    Case SECURITYOBJ

        fName$ = "SecurityObject"

    Case Else   ' Invalid tag

        SW1SW2 = &H6A82

        GoTo EndProc

End Select

fNum% = Open fName$ For Binary

If FileError <> 0 Then

    SW1SW2 = &H6A82

    GoTo EndProc

End If

SW1 = &H61

Rem  GET RESPONSE will add 2, 3, or 4 byte BER-TLV header depending
Rem  on length of the file to be read.  

If Len (#fNum%) <= &H7F Then

    SW2 = Len (#fNum%) + 2

ElseIf Len (#fNum%) <= &HFF - 3 Then    ' Can't return 'FF + 3 bytes...
                                        ' SW2 will be <= 'FF
    SW2 = Len (#fNum%) + 3

Else                                ' File length + 3/4 byte header
                                    ' is > 'FF
    SW2 = &HFF

End If

EndProc:

Call SuspendSW1SW2Processing()

End Command
