Command PivGeneralAuthenticate (CLA=&H00, INS=&H87, iData$ As String, Disable Le)

Rem  ACR:  Key dependent.

Rem P1 = Algorithm reference, P2 = Key reference, Lc = Length of data field
Rem Le = Absent or length of expected response, here it is Disable Le (absent)

Rem iData$ = Dynamic Authentication Template (SP800-73 Table 17):

Rem             Tag 7C (Dynamic Authentication Template Tag)
Rem             Length (of Template)                        ' *Not yet implemented...
Rem             Tag 80 (Witness) OR
Rem                 81 (Challenge) OR
Rem                 82 (Response) OR
Rem                 83 (Committed Challenge) OR
Rem                 84 (Authentication code)
Rem             Length (of String)                          ' *Not yet implemented...
Rem             [String] (Dynamic authentication data)

Rem  Asymmetric challenge-response:

Rem                       *empty response?
Rem                       |     challenge to sign
Rem                       |     |
Rem  00 87 06 9A 0E 7C 0C 82 00 81 08 01 02 03 04 05 06 07 08
Rem    7C 0A 82 08 88 77 66 55 44 33 22 11
Rem          |
Rem          signed challenge

Rem  algid = &H06, keyref = 9A, empty response tag &H82, challenge request &H81
Rem  iData$ = 6-byte header + 128-byte challenge

Rem  Symmetric XAUTH:

Rem                       AES client challenge request
Rem                       |
Rem  00 87 08 00 04 7C 02 81 00
Rem    7C 0A 81 08 01 02 03 04 05 06 07 08
Rem          |
Rem          challenge

Rem  1.  algid = 00, P1P2 = &H0000, challenge request = &H81
Rem     iData$ = 4-byte header

Rem                       AES encrypted response
Rem                       |
Rem  00 87 08 9B 0C 7C 0A 82 08 88 77 66 55 44 33 22 11
Rem    SW1SW2 = 9000

Rem  2.  algid = 00, keyref &H9B, response &H82
Rem     iData$ = 4-byte header + 16-byte AES block


Rem  1.  Challenge request (P1 determines alg, P2 = key ID/irrelevant): 7c 02 81 00
Rem      Note that terminal may ask for a 128 byte challenge

Rem  2.  Challenge verification :  7c [len + 2 = 0A] 82 [len = 8]       7c 0A 82 08...

Rem  Signature request:  7c [len = 81 83] 82 00 81 [len = 80]           7C 81 83 82 00 81 80...

Rem  Card can be passed a 128 byte challenge to sign, or an 8 byte encrypted response
Rem  P1P2 determine algorithm ID/key reference


Private ChallengeLength As Byte

Rem klm 11/29/06 Private SignHeader$ As String*6 = &H7C, SIGNATURELENGTH + 4, &H82, &H81, &H00, SIGNATURELENGTH
Private SignHeader$ As String*6 = &H7C, &H81, &H83, &H82, &H81, SIGNATURELENGTH

Private RsaRequestHeader$ As String*5 = &H7C, SIGNATURELENGTH + 3, &H81, &H81, SIGNATURELENGTH

Private DesRequestHeader$ As String*4 = &H7C, SYMMETRICBLOCKSIZE + 2, &H81, SYMMETRICBLOCKSIZE

Private RequestHeader$

Private SignData$ ' klm added 06/16/06 to compansate for 127 byte challenge response

Private ChallengeRequest$ As String*4 = &H7C, &H02, &H81, &H00

Private ChallengeVerification$ As String*4 = &H7C, &H0A, &H82, &H08

Rem Private SignatureRequest$ As String*10 = &H7C, &H82, &H00, &H86, &H82, &H00, &H81, &H82, &H00, &H80    ' <-- current for NIST-ESI CSP; old #2 (chads middleware): Private SignatureRequest$ As String*8 = &H7C, &H81, &H85, &H82, &H00, &H81, &H81, &H80 klm removed on 10/27/06 
Private SignatureRequest$ As String*6 = &H7C, &H81, &H85, &H81, &H81, &H80 ' klm - going back to old string 10/27/06

Rem  7  = &H7C, &H81, &H83, &H82, &H00, &H81, &H80


If Len (ChainBuffer$) + Len (iData$) < &HFF Then

    ChainBuffer$ = ChainBuffer$ + iData$

Else

    SW1SW2 = &H6A81			' SHOULD BE 6A80

    GoTo EndProc

End If


If Left$ (ChainBuffer$, Len (ChallengeRequest$)) = ChallengeRequest$_
    Then

    If P1 = &H00 or P1 = &H03 Then

        ChallengeLength = SYMMETRICBLOCKSIZE

        RequestHeader$ = DesRequestHeader$

    ElseIf P1 = &H06 Then

        ChallengeLength = SIGNATURELENGTH

        RequestHeader$ = RsaRequestHeader$

    Else

        SW1SW2 = &H6A86     ' Incorrect parameter in P1P2

        GoTo EndProc

    End If

    Call RandomString (CurrentChallenge$, ChallengeLength)

    ResponseBuffer$ = RequestHeader$ + CurrentChallenge$

    SecurityStatus.ChallengeFlag = True

    SW1 = &H61 : SW2 = Len (ResponseBuffer$)

ElseIf Left$ (ChainBuffer$, Len (ChallengeVerification$)) =_  'Stack overflow...
    ChallengeVerification$ Then

    If SecurityStatus.ChallengeFlag = False Then

        SW1SW2 = &H6982     ' Security condition not satisfied
                            ' if no prior challenge requested
        GoTo EndProc

    End If

    If (P1 <> &H00 And P1 <> &H03) Or P2 <> &H9B Then
                            ' Must reference TDES and PIV
        SW1SW2 = &H6A86     ' Card Application Admin key

        GoTo EndProc

    End If

    SecurityStatus.AdminKeyVerified = VerifyResponse (Mid$_
        (ChainBuffer$, Len (ChallengeVerification$) + 1,_
        SYMMETRICBLOCKSIZE))

    SecurityStatus.ChallengeFlag = False

    If SecurityStatus.AdminKeyVerified = True Then

        SW1SW2 = &H9000

    Else

        SW1SW2 = &H6A82			' SHOULD BE 6A80

    End If

rem klm 10/27/06 going back to old string ElseIf Left$ (ChainBuffer$, 10) = SignatureRequest$ Then           '<--- Current for NIST-ESI CSP; old #2 (chad's middleware): ElseIf Left$ (ChainBuffer$, 8) = SignatureRequest$ Then		'
ElseIf Left$ (ChainBuffer$, 6) = SignatureRequest$ Then

    If SecurityStatus.CardholderPinVerified = False Or_
        ContactMode = False Or P1P2 <> &H069A Then

        SW1SW2 = &H6982

        GoTo EndProc

    End If

Rem   My original

Rem Replace next two lines with the logic to compansate for 127 bytes response
Rem   ResponseBuffer$ = SignHeader$ + SignChallenge$ (Mid$_
Rem      (ChainBuffer$, 11, SIGNATURELENGTH))   '<--- Current for NIST-ESI CSP; old #2 (chad's middleware):   ' old: (ChainBuffer$, 7, SIGNATURELENGTH))

Rem klm - Start of new logic - 03/2006
    SignData$ = SignChallenge$ (Mid$(ChainBuffer$, 7, SIGNATURELENGTH)) 'klm 10/27/06 changed 11 to 7 due to header change
    If Len (SignData$) = 127 Then
        ResponseBuffer$ = SignHeader$ + Chr$(0) + SignData$
    Else 
        ResponseBuffer$ = SignHeader$ + SignData$
    End If 
Rem klm - end of the new logic.

Rem Ketan's challenge debugging
Rem   ResponseBuffer$ = Mid$(ChainBuffer$, 11, SIGNATURELENGTH)
Rem     SecurityStatus.ChallengeFlag = False

      SW1 = &H61 : SW2 = Len (ResponseBuffer$)

Else

    SecurityStatus.ChallengeFlag = False

    SW1SW2 = &H6A80

End If


EndProc:

ChainBuffer$ = ""

Call SuspendSW1SW2Processing()

End Command '===========================================================


Function SignChallenge$(Challenge$) As String

Rem RSA 1024 signature via RsaDecrypt, plaintext length <= 128 bytes:


If Len(Challenge$) < 128 Then		' old : If Len(Challenge$) > 128 Then

    SW1SW2 = &H6A84			' SHOULD BE 6A80

    GoTo EndFunc

End If

LibError = 0

Call RsaDecrypt (Challenge$, PrivateKey.p$, PrivateKey.q$, PrivateKey.e$)


If LibError <> 0 Then

    Rem  Public key generation error processing...

End If


EndFunc:

#IfDef LOGTOFILE

Rem  Debug code to print to a file that the terminal can access

Public fNumDebugCard% As Integer

fNumDebugCard% = Open "@:\CardDebug.log" For Output

Print #fNumDebugCard%, "Challenge$ (CARD):" : Print #fNumDebugCard%

Call PrintBinaryStringToFile$ (Challenge$)

Close

Rem  End debug code

#EndIf

SignChallenge$ = Challenge$

End Function  '=========================================================


Function VerifyResponse(Response$) As Integer

Rem  TDES inverse transformation:  (Dk3(Ek2(Dk)))

Rem  How many retries are allowed?

Rem  +1 = E, -1 = D

Private PlainTextChallenge$ As String


PlainTextChallenge$ = DES (-1, Right$ (DEFAULTADMINKEY, 8), Response$)

PlainTextChallenge$ = DES (+1, Mid$ (DEFAULTADMINKEY, 9, 8), PlainTextChallenge$)

PlainTextChallenge$ = DES (-1, Left$ (DEFAULTADMINKEY, 8), PlainTextChallenge$)

If PlainTextChallenge$ = CurrentChallenge$ Then

     VerifyResponse = True

Else

     VerifyResponse = False

End If

SecurityStatus.ChallengeFlag = False

End Function  '========================================================
