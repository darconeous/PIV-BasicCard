Rem PivCard.BAS
Rem ********************************************************************
Rem *   PIV Example Card Main Source File                              *
Rem *                                                                  *
Rem *   PIV-Ex 73-1, 05/05/06                                          *
Rem *                                                                  *
Rem *   Author:  Jim Dray, U.S. National Institute of Standards and    *
Rem *            Technology                                            *
Rem *                                                                  *
Rem *   Disclaimer: Please read the file disclaimer.txt (included in   *
Rem *               this package) before using this software.  DO NOT  *
Rem *               under any circumstances use this software in       *
Rem *               a production or operational environment.  It is    *
Rem *               provided for educational purposes only and has not *
Rem *               been subjected to rigorous testing.                *
Rem *                                                                  *
Rem ********************************************************************

Rem ********************************************************************
Rem *   Compilation:                                                   *
Rem *                                                                  *
Rem *   1.  Compiler = BasicCard Professional IDE Version 5.22         *
Rem *                                                                  *
Rem *   2.  Target = ZC45D_F.zcf(e.g.,C:\BasicCardPro\Pro\ZC45D_F.zcf) *
Rem *                                                                  *
Rem *   3.  P-Code stack size = 80                                     *
Rem *                                                                  *
Rem *   4.  Data objects are loaded via a file definition section in   *
Rem *       PIVDATA.DEF.                                               *
Rem ********************************************************************


Rem CONSTANTS AND COMPILER FLAGS    ************************************

Declare ApplicationID = "A000000308000010001000"

#Pragma T=0

#Pragma ATR(HB="PIV-Ex 73-1")

Rem  Const  LOGTOFILE = -1

Const  REVD = -1

Rem  Const  SETSW1SW2 = -1

Rem  Const   PINCHECK = -1   ' If defined, allows card administrator to
                        ' enable/disable PIN ACR for PIV Authentication
                        ' Key via PivEnablePinCheck and PivDisablePin
                        ' Check APDUs.  This constant should be
                        ' commented out for a stock PIV card.

Const   KEYFILES = -1   ' Load PIV Authentication Key components from
                        ' terminal key files at startup.  Requires
                        ' PublicKey.bin and PrivateKey.bin in a
                        ' .\Keyfiles subdirectory.

Const   INCOPTDATA = -1 ' If defined, loads optional data objects onto
                        ' the card (e.g., printed information).


Rem DEFINITION FILES    ************************************************

#NoList
#Include FILEIO.DEF
#Include RSA.DEF
Rem #Include AES.DEF    
#List

#Include PIVCONSTANTS.DEF
#Include PIVTYPES.DEF
#Include PIVGLOBALS.DEF
#Include PIVFUNCTIONS.DEF
#Include PIVDATA.DEF
#Include PIVAPT.DEF

#IfDef  REVD
#Include MISC.DEF   ' For ZC4.5X Rev D+: SuspendSW1SW2Processing()
#EndIf


Rem PIV APDU CODE MODULES   ********************************************

#Include PivSelect.BAS

#Include PivVerify.BAS

#Include PivGetData.BAS

#Include PivGetResponse.BAS

#Include PivResetRetryCounter.BAS

#Include PivChangeReferenceData.BAS

#Include PivGeneralAuthenticate.BAS

#Include PivChGeneralAuthenticate.BAS

#Include sPivPutData.BAS                    ' Stubbed out version

#Include sPivGenerateAsymmetricKeyPair.BAS  ' Stubbed out version

#Include PivSetContactlessMode.BAS          ' Simulate prox card

#Include PivSetContactMode.BAS              ' Set contact mode
