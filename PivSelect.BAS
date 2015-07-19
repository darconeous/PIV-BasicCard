Command PivSelect(CLA=&H00, INS=&HA4, iData$ as String*11, Disable Le)

Rem  ACR:  Always


If Left$ (iData$, 9) = AID$ Then    ' Return APT

    ResponseBuffer$ = ApplicationPropertiesTemplate$

    SW1 = &H61

    SW2 = Len (ResponseBuffer$)

    SecurityStatus.CardholderPinVerified = False

    SecurityStatus.AdminKeyVerified = False

    SecurityStatus.ChallengeFlag = False

Else                        ' Select failed, don't change security state

Rem    oData$ = ""

    SW1SW2 = &H6A82

End If

Call SuspendSW1SW2Processing()

End Command '===========================================================
