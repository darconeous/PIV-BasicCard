Command PivChangeReferenceData (CLA=&H00, INS=&H24, iData$ as String, Disable Le)

Rem  Compares the submitted and stored verification data indexed by the key
Rem  reference.  If the verification succeeds, the stored verification
Rem  data is replaced by the submitted data.

Rem ACR:    Verification data, cardholder's PIN.

Rem         This currently only works for the cardholder PIN.


SecurityStatus.ChallengeFlag = False

securityStatus.CardholderPinVerified = False


If CardholderPin.RetryCounter@ <= 0 Then   '  Application is blocked

    SW1SW2 = &H6983

    Exit

End If


If P2 <> &H80 Then          '  The key reference for cardholder PIN must be &H80

    SW1SW2 = &H6A88

    Exit

End If


If Lc <> &H10 Then          '  Lc must contain correct length of iData$ (16 bytes)

    SW1SW2 = &H6A80

    Exit

End If


If Len(iData$) <> Lc Then    '  Concatenated PINs must be 16 bytes

    SW1SW2 = &H6A80

    Exit

End If


If Left$ (iData$, 8) = CardholderPin.Value Then        '  PIN verified, set new PIN

    SecurityStatus.CardholderPinVerified = True

    CardholderPin.Value = Right$ (iData$, 8)

    CardholderPin.RetryCounter@ = MAXRETRIES

    SW1SW2 = &H9000

Else                        '  PIN verification failed, decrement RetryCounter

    SecurityStatus.CardholderPinVerified = False

    CardholderPin.RetryCounter@ = CardholderPin.RetryCounter@ - 1

    SW1SW2 = &H63C0 + CardholderPin.RetryCounter@

End If

End Command '===========================================================
