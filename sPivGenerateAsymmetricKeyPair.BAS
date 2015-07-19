Command sPivGenerateAsymmetricKeyPair (CLA=&H00, INS=&H47, iData$ As String*3, oData$, Input Le)

Rem Stubbed out version

Rem Need to mod this to work with GET RESPONSE

SW1SW2 = &H6A81     ' Function not supported

Exit


Rem  ACR:  PIV card application administrator via GENERATE CHALLENGE (algid = &H08, keyref = &H9B)

Rem  SP800-78 specifies a public key exponent length between 2^16 + 1 and 2^864 = 32 to 108 bytes

Rem  SP800-73 allows the caller to pass the public key exponent in the Control
Rem     Reference Template but the BasicCard RsaGenerateKey() call generates
Rem     it automatically, so this command ignores it if it is passed.

Rem  P1 = '00
Rem  P2 = Key reference to be assigned (&H9A for PIV auth key)
Rem  Lc = Length of data field (Control Reference Template = 3 bytes + public 
Rem         key exponent length, if present)

Rem  iData$ = Control Reference Template (SP800-73 Table 19):

Rem             Tag 'AC
Rem             Tag '80 (Cryptographic Mechanism Identifier)
Rem                 '06 (Algorithm Identifier for RSA 1024)
Rem             Tag '81 (Parameter)
Rem                 [String]:  Optional public key exponent encoded big-endian

Rem  oData$ = Data objects in the template:

Rem             Tag '7F49  (Template tag)
Rem             Tag '81  (Modulus)
Rem                 [String]:  Modulus
Rem             Tag '82  (Public exponent)
Rem                 [String]:  Public exponent


Private fNumKeys%

SecurityStatus.ChallengeFlag = False

If SecurityStatus.AdminKeyVerified <> True Then   '  Security condition not satisfied

    SW1SW2 = &H6982

    Exit

End If


If P2 <> &H9A Then              '  Key reference for PIV auth key must be &H9A
                                '  *Note that there is an error in the return
    SW1SW2 = &H6A86             '  code table in SP800-73, which references P1

    Exit

End If


If Lc > 3 Then                      '  Optional public exponent parameter present


    If Asc (iData$(4)) <> &H81 Then '  Check for valid public exponent parameter Tag

        Exit

    End If


End If


If Asc (iData$(1)) <> &HAC Then '  Check for valid Control Reference Template Tag

    SW1SW2 = &H6A80             '  Does 6A80 apply to invalid Tags?

    Exit

End If


If Asc (iData$(2)) <> &H80 Then '  Check for valid Algorithm identifier Tag

    SW1SW2 = &H6A80             '  Does 6A80 apply to invalid Tags?

    Exit

End If


If Asc (iData$(3)) <> &H06 Then '  Check for valid Algorithm identifier

    SW1SW2 = &H6A80             '  Does 6A80 apply to invalid Tags?

    Exit

End If


LibError = 0

Call RsaGenerateKey (NBITS, EBITS, PrivateKey.p$, PrivateKey.q$, PrivateKey.e$)


If LibError <> 0 Then

    Rem  Private key generation error processing...

End If


LibError = 0

PublicKey.n$ = RsaPublicKey (PrivateKey.p$, PrivateKey.q$)

PublicKey.e$ = PrivateKey.e$

If LibError <> 0 Then

    Rem  Public key generation error processing...

End If


PrivateKey.KeyRef@ = &H9A

PrivateKey.Cmid@ = &H06

Private TemplateTag$ As String*2 = &H7F, &H49

Private ModulusTag$ As String*1 = &H81

Private ExponentTag$ As String*1 = &H82

oData$ = TemplateTag$ + ModulusTag$ + PublicKey.n$ + ExponentTag$ + PublicKey.e$


Rem  Save keys to a file accessible to terminal:

fNumKeys% = Open "PublicKey.bin" For Output

Write #fNumKeys%, PublicKey

Close

fNumKeys% = Open "PrivateKey.bin" For Output

Write #fNumKeys%, PrivateKey

Close

End Command '===========================================================
