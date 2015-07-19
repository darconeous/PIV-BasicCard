Command PivVerify (CLA=&H00, INS=&H20, iData$ As String, Disable Le)


SecurityStatus.ChallengeFlag = False

SecurityStatus.CardholderPinVerified = False


If CardholderPin.RetryCounter@ <= 0 Then   '  MAXRETRIES exceeded

    SW1SW2 = &H6983

    Exit

End If

If P2 <> &H80 Then          '  The key reference for PIV application PIN must be &H80

    SW1SW2 = &H6A88

    Exit

End If

If Len(iData$) <> 8 Then    '  PIN must be 8 bytes

    SW1SW2 = &H6A80

    Exit

End If

If iData$ = CardholderPin.Value Then        '  PIN verified, reset RetryCounter

    SecurityStatus.CardholderPinVerified = True

    CardholderPin.RetryCounter@ = MAXRETRIES

   SW1SW2 = &H9000

Else                        '  PIN verification failed, decrement RetryCounter
                            '  *SW2 contains retries, so only &H0F allowed

    CardholderPin.RetryCounter@ = CardholderPin.RetryCounter@ - 1

    If CardholderPin.RetryCounter@ < &H10 Then

        SW1SW2 = &H63C0 + CardholderPin.RetryCounter@

    Else

        SW1SW2 = &H63CF

    End If

End If

Call SuspendSW1SW2Processing()

End Command '===========================================================
