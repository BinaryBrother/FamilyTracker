#include <Array.au3>

Global $sDatabase_Path = @ScriptDir & "\NetworkSnitch.ini"
Global $bFill_ARP_Table_FirstRun = True
Global $bGet_ARP_Table_FirstRun = True
Global $sIP = _GetGatewayIP()
Global $aIP = StringSplit($sIP, ".")
Global $aARP_Table = _Get_ARP_Table()

AdlibRegister("_Fill_ARP_Table", 1000*60*5)
$aData = IniReadSection($sDatabase_Path, "Monitor")

While 1
	For $N = 1 To $aData[0][0]
		;$aData[$N][0] = MAC Address
		;$aData[$N][1] = User
		$lReturn = _isAliveMAC($aData[$N][0])
		If $lReturn = False Then
			ConsoleWrite("WARNING: Unable to communicate with " & $aData[$N][1] & @CRLF)
			_Tracker($aData[$N][0], "DOWN")
		Else
			_Tracker($aData[$N][0], "UP")
		EndIf
		Sleep(500)
	Next
WEnd

Func _Get_ARP_Table()
	If $bGet_ARP_Table_FirstRun Then _Fill_ARP_Table()
	$bGet_ARP_Table_FirstRun = False
	Local $lReturn = _GetReturn("arp -a")
	$lReturn = StringSplit($lReturn, @CRLF, 1)
	$bGet_ARP_Table_FirstRun = False
	Return $lReturn
EndFunc   ;==>_Get_ARP_Table



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

Func _GetGatewayIP()
	Local $lReturn = _GetReturn("tracert -d -h 1 -4 8.8.8.8")
	Local $aIPs = StringRegExp($lReturn, "(\d+\.\d+\.\d+\.\d+)", 3)
	Return $aIPs[1]
EndFunc   ;==>_GetGatewayIP

Func _Fill_ARP_Table()
	; This function will scan the network for devices and add them to the ARP Table
	Local $lIP
	Local $lProgress
	If $bFill_ARP_Table_FirstRun Then SplashTextOn("Network Snitch", "Scanning Network...", 300, 100, -1, -1, 1, "", 14)
	For $N = 1 To 255
		$lIP = $aIP[1] & "." & $aIP[2] & "." & $aIP[3] & "." & $N
		ConsoleWrite("Pinging: " & $lIP & @CRLF)
		Run(@ComSpec & " /c ping -n 5 -w 2000 " & $lIP, "", @SW_HIDE)
		If $bFill_ARP_Table_FirstRun Then $lProgress = Round(($N / 255) * 100, 2)
		If $bFill_ARP_Table_FirstRun Then ControlSetText("Network Snitch", "", "Static1", "Scanning Network..." & @CRLF & "Progress: " & $lProgress & "%")
		If $bFill_ARP_Table_FirstRun Then Sleep(10)
		If Not $bFill_ARP_Table_FirstRun Then Sleep(100)
	Next
	If $bFill_ARP_Table_FirstRun Then SplashOff()
	$bFill_ARP_Table_FirstRun = False
EndFunc   ;==>_Fill_ARP_Table



Func _isAliveIP($pIP)
	Local $iFailCount = 0
	Local $lReturn
	For $N = 1 To 4
		$lReturn = Ping($pIP, 2000)
		If Not @error And $lReturn >= 1 Then
			ContinueLoop
		Else
			$iFailCount += 1
		EndIf
		Sleep(500)
	Next
	If $iFailCount >= 4 Then
		Return SetError(1, 0, False)
	Else
		Return True
	EndIf
EndFunc   ;==>_PingIP

Func _Tracker($sMAC, $sStatus)
	IniWrite($sDatabase_Path, "Tracker", $sMAC, $sStatus)
	; Add additional tracking logic here if needed
EndFunc   ;==>_Tracker

Func _isAliveMAC($sMAC)
	Local $bReturn
	ConsoleWrite("_PingMAC(): MAC: " & $sMAC & @CRLF)
	Local $aEntries = IniReadSection($sDatabase_Path, "Entry")
	For $N = 1 To $aEntries[0][0]
		If StringInStr($aEntries[$N][1], $sMAC) Then
			ConsoleWrite("_PingMAC(): IP: " & $aEntries[$N][0] & @CRLF)
			$bReturn = _isAliveIP($aEntries[$N][0])
			If $bReturn Then
				ConsoleWrite("_PingMAC(): " & $aEntries[$N][0] & " is UP!" & @CRLF)
				Return True
			Else
				ConsoleWrite("_PingMAC(): " & $aEntries[$N][0] & " is DOWN!" & @CRLF)
				Return False
			EndIf
		EndIf
	Next
	ConsoleWrite("_PingMAC(): MAC not found in ARP Table!" & @CRLF)
	Return SetError(1, 0, False)
EndFunc   ;==>_PingMAC

Func _GetReturn($sCommand)
	Local $lReturn = Run(@ComSpec & " /c " & $sCommand, "", @SW_HIDE, $STDERR_CHILD + $STDOUT_CHILD)
	Local $lOutput = ""
	While 1
		$lOutput &= StdoutRead($lReturn)
		If @error Then ExitLoop
		$lOutput &= StderrRead("ERROR:" & $lReturn)
	WEnd
	Return $lOutput
EndFunc   ;==>_GetReturn
