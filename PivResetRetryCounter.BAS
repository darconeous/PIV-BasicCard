Command PivResetRetryCounter (CLA=&H00, INS=&H2C, iData$ as String, Disable Le)

Rem  Resets the retry counter of the key reference to its initial value and
Rem     changes the verfication data indexed by the key reference.  If the
Rem     reset counter of the key reference is zero, the retry counter is not
Rem     reset and the verification data are not set to the new value.
Rem     If successful, the retry value of the key reference is reset and the
Rem     security status and reset counter are not changed.
Rem     If unsuccessful, the reset counter is decremented by one and the
Rem     security status of the key reference is set to FALSE.

Rem  ACR:  PIV Card Application Administrator's PIN Unlocking Key (PUK) AND
Rem         cardholder biometric (*card cannot verify cardholder's bio)

Rem  PINverified = False


SecurityStatus.ChallengeFlag = False

If CardholderPin.ResetCounter@ <= 0 Then   '  Resets are blocked

    SW1SW2 = &H6983

    Exit

End If


If P2 <> &H80 Then          '  The key reference for PIV application PIN must be &H80

    SW1SW2 = &H6A88

    Exit

End If


If Lc <> &H10 Or Len(iData$) <> &H10 Then    '  Concatenated PUK and PIN must be 16 bytes

    SW1SW2 = &H6A80

    Exit

End If


If Left$ (iData$, 8) = DEFAULTPUK Then      '  PUK verified, set new PIN

Rem SecurityStatus.CardholderPinVerified = True '  Don't change security status

    CardholderPin.Value = Right$ (iData$, 8)

    CardholderPin.RetryCounter@ = MAXRETRIES

    SW1SW2 = &H9000

Else                        '  PUK verification failed, decrement ResetCounter

    SecurityStatus.CardholderPinVerified = False

    CardholderPin.ResetCounter@ = CardholderPin.ResetCounter@ - 1

    SW1SW2 = &H63C0 + CardholderPin.ResetCounter@  '  Only works for one-nibble reset values...

End If

End Command '===========================================================
