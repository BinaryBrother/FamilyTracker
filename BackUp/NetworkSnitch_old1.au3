#include <MsgBoxConstants.au3>
#include <Array.au3>

$sPrimaryIP = _GetActiveIP()
$aIP = StringSplit($sPrimaryIP, ".")
_ArrayDisplay($aIP)

Func _GetActiveIP()
    Local $aIP_Address[5]
    $aIP_Address[1] = @IPAddress1
    $aIP_Address[2] = @IPAddress2
    $aIP_Address[3] = @IPAddress3
    $aIP_Address[4] = @IPAddress4
    For $N = 1 To 4
        $lReturn = MsgBox($MB_YESNO + $MB_TOPMOST + $MB_ICONQUESTION, "Network Snitch", "Is this your proper network IP?" & @CRLF & $aIP_Address[$N])
        If $lReturn = $IDYES Then
            Return $aIP_Address[$N]
        EndIf
    Next
EndFunc