Command PivChGeneralAuthenticate (CLA=&H10, INS=&H87, iData$ As String, Disable Le)

If Len (ChainBuffer$) + Len (iData$) < &HFF Then

    ChainBuffer$ = ChainBuffer$ + iData$

Else

    SW1SW2 = &H6A80

End If

Call SuspendSW1SW2Processing()

End Command '===========================================================
