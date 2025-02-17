#include <MsgBoxConstants.au3>
#include <Array.au3>

Global $sPrimaryIP = _GetActiveIP()
Global $aIP = StringSplit($sPrimaryIP, ".")
_Fill_ARP_Table()
Global $aARP_Table = _GetARPTable()
_ArrayDisplay($aARP_Table)

For $N = 1 To $aARP_Table[0]
	If _ContainsNetworkIP($aARP_Table[$N]) Then
		$Test  = StringRegExp($aARP_Table[$N], "(192.168.254.\d+)\s+(..-..-..-..-..-..)", 3)
		If IsArray($Test) Then
			ConsoleWrite("IP: " & $Test[0] & @CRLF)
			ConsoleWrite("MAC: " & $Test[1] & @CRLF)
		endif
	EndIf
Next

Func _GetReturn($sCommand)
	Local $lReturn = Run(@ComSpec & " /c " & $sCommand, "", @SW_HIDE, $STDERR_CHILD + $STDOUT_CHILD)
	Local $lOutput = ""
	While 1
		$lOutput &= StdoutRead($lReturn)
		If @error Then ExitLoop
	WEnd
	Return $lOutput
EndFunc   ;==>_GetReturn

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
EndFunc   ;==>_GetActiveIP

Func _Fill_ARP_Table($pIP = "")
	If $pIP = "" Then 
		$pIP = StringSplit("192.168.254.88", ".")
	EndIf
	Local $lIP
	Local $lProgress
	SplashTextOn("Network Snitch", "Scanning Network...", 300, 100, -1, -1, 1, "", 14)
	For $N = 1 To 255
		$lIP = $pIP[1] & "." & $pIP[2] & "." & $pIP[3] & "." & $N
		ConsoleWrite("Pinging: " & $lIP & @CRLF)
		Run(@ComSpec & " /c ping -n 1 -w 1 " & $lIP, "", @SW_HIDE)
		$lProgress = Round(($N / 255) * 100, 2)
		ControlSetText("Network Snitch", "", "Static1", "Scanning Network..." & @CRLF & "Progress: " & $lProgress & "%")
	Next
	SplashOff()
EndFunc   ;==>_Fill_ARP_Table

Func _GetARPTable()
	Local $lReturn = _GetReturn("arp -a")
	$lReturn = StringSplit($lReturn, @CRLF, 1)
	Return $lReturn
EndFunc   ;==>_GetARPTable



Func _ContainsNetworkIP($pIP)
	;For $N = 1 To 255
		If StringInStr($pIP, "192.168.254.") Then
			Return True
		EndIf
	;Next
	;Return False
EndFunc   ;==>_ContainsNetworkIP
