#include <Array.au3>
#include <AutoItConstants.au3>
#include <TrayConstants.au3>
#include <MsgBoxConstants.au3>

Global $sDatabase_Path = @ScriptDir & "\DB.ini"
Global $bFill_ARP_Table_FirstRun = True
Global $bGet_ARP_Table_FirstRun = True
Global $aLocal_ARP_Table[1][2] = [["IP", "MAC"]]
Global $sIP = _GetGatewayIP()
Global $aIP = StringSplit($sIP, ".")
Global $aARP_Table = _Get_ARP_Table()

AdlibRegister("_Fill_ARP_Table", 1000 * 60 * 5)

$aDataMonitor = IniReadSection($sDatabase_Path, "Monitor")
;$aDataMonitor[$N][0] = MAC Address
;$aDataMonitor[$N][1] = User Info

While 1
	$aDataTracker = IniReadSection($sDatabase_Path, "Tracker")
	For $N = 1 To $aDataMonitor[0][0]
		$lReturn = _isAliveMAC($aDataMonitor[$N][0])
		;$aDataTracker[$N][0] = MAC Address
		;$aDataTracker[$N][1] = Status
		If $lReturn = False Then
			For $I = 1 To $aDataTracker[0][0]
				If $aDataMonitor[$N][0] = $aDataTracker[$I][0] And $aDataTracker[$I][1] = "UP" Then
					TrayTip("Family Tracker", $aDataMonitor[$N][1] & " has left the network!", 5, $TIP_ICONEXCLAMATION)
					_Tracker($aDataMonitor[$N][0], "DOWN")
				EndIf
			Next
		Else
			For $G = 1 To $aDataTracker[0][0]
				If $aDataMonitor[$N][0] = $aDataTracker[$G][0] And $aDataTracker[$G][1] = "DOWN" Then
					TrayTip("Family Tracker", $aDataMonitor[$N][1] & " has arrived!", 5, $TIP_ICONEXCLAMATION)
					_Tracker($aDataMonitor[$N][0], "UP")
				EndIf
			Next
		EndIf
		Sleep(500)
	Next
WEnd

Func _Get_ARP_Table()
	If $bGet_ARP_Table_FirstRun Then _Fill_ARP_Table()
	$bGet_ARP_Table_FirstRun = False
	Local $lReturn = _GetReturn("arp -a")
	$lReturn = StringSplit($lReturn, @CRLF, 1)
	Local $aFilteredARP[1] = [""]
	For $N = 1 To $lReturn[0]
		If StringInStr($lReturn[$N], "dynamic") Then
			_ArrayAdd($aFilteredARP, $lReturn[$N])
		EndIf
	Next
	$aFilteredARP[0] = UBound($aFilteredARP) - 1
	$lReturn = $aFilteredARP
	Return $lReturn
EndFunc   ;==>_Get_ARP_Table

Func _GetGatewayIP()
	Local $lReturn = _GetReturn("tracert -d -h 1 -4 8.8.8.8")
	Local $aIPs = StringRegExp($lReturn, "(\d+\.\d+\.\d+\.\d+)", 3)
	Return $aIPs[1]
EndFunc   ;==>_GetGatewayIP

Func _Fill_ARP_Table()
	; This function will scan the network for devices and add them to the ARP Table
	Local $lIP
	Local $lProgress
	If $bFill_ARP_Table_FirstRun Then SplashTextOn("Family Tracker", "Scanning Network...", 300, 100, -1, -1, $DLG_CENTERONTOP, "Verdana", 14)
	For $N = 1 To 255
		$lIP = $aIP[1] & "." & $aIP[2] & "." & $aIP[3] & "." & $N
		ConsoleWrite("Pinging: " & $lIP & @CRLF)
		Run(@ComSpec & " /c ping -n 5 -w 2000 " & $lIP, "", @SW_HIDE)
		If $bFill_ARP_Table_FirstRun Then $lProgress = Round(($N / 255) * 100, 2)
		If $bFill_ARP_Table_FirstRun Then ControlSetText("Family Tracker", "", "Static1", "Scanning Network..." & @CRLF & "Progress: " & $lProgress & "%")
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
		$lReturn = Ping($pIP, 1000)
		If Not @error And $lReturn >= 1 Then
			ContinueLoop
		Else
			$iFailCount += 1
		EndIf
		Sleep(50)
	Next
	If $iFailCount >= 4 Then
		Return SetError(1, 0, False)
	Else
		Return True
	EndIf
EndFunc   ;==>_isAliveIP

Func _Tracker($sMAC, $sStatus)
	IniWrite($sDatabase_Path, "Tracker", $sMAC, $sStatus)
	; Add additional tracking logic here if needed
EndFunc   ;==>_Tracker

Func _isAliveMAC($sMAC)
	Local $bReturn, $IP
	ConsoleWrite("_PingMAC(): MAC: " & $sMAC & @CRLF)
	For $N = 1 To $aARP_Table[0]
		If StringInStr($aARP_Table[$N], $sMAC) Then
			$IP = StringRegExp($aARP_Table[$N], "(\d+\.\d+\.\d+\.\d+)", $STR_REGEXPARRAYMATCH )[0]
			ConsoleWrite("_PingMAC(): IP: " & $IP & @CRLF)
			$bReturn = _isAliveIP($IP)
			If $bReturn Then
				ConsoleWrite("_PingMAC(): " & $sMAC & " is UP!" & @CRLF)
				Return True
			Else
				ConsoleWrite("_PingMAC(): " & $sMAC & " is DOWN!" & @CRLF)
				Return False
			EndIf
		EndIf
	Next
	ConsoleWrite("_PingMAC(): MAC not found in ARP Table!" & @CRLF)
	Return SetError(1, 0, False)
EndFunc   ;==>_isAliveMAC

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

Func _Error($pData)
	ConsoleWrite($pData & @CRLF)
	MsgBox($MB_ICONERROR, "ERROR", $pData)	
	Exit
EndFunc
