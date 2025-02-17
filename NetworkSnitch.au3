#include <MsgBoxConstants.au3>
#include <Array.au3>

#Region Global Declarations
Global $sDatabase_Path, $sPrimaryIP, $aIP, $aARP_Table
Global $aLocal_ARP_Table[1][2] = [["IP", "MAC"]]
#EndRegion

$sDatabase_Path = @ScriptDir & "\NetworkSnitch.ini"
$sPrimaryIP = _GetIPAuto()
$aIP = StringSplit($sPrimaryIP, ".")
$aARP_Table = _GetARPTable()

_CreateLocalARPTableDatabase()

#Region Update Globals
AdlibRegister("_GetARPTable", 1000*60*5) ; (Default: 5 minutes) This will determine how often we look for NEW devices.
AdlibRegister("_CreateLocalARPTableDatabase", 1000*60*5)
#EndRegion

; At this point $aLocal_ARP_Table is filled with the local ARP Table.
; You can use this to check if a device is on the network by checking the MAC Address.
; The NetworkSnitch.ini file has to be modified to include the MAC Address of the device you want to monitor.
; [Monitor]
; be-b8-d0-71-15-fa=Jimmy's - Pixel 6
; e2-c5-d3-fb-0a-fd=Nola's - Pixel 6

$aData = IniReadSection($sDatabase_Path, "Monitor")
;_ArrayDisplay($aData)
While 1
	For $N = 1 To $aData[0][0]
		;$aData[$N][0] = MAC Address
		$lReturn = _PingMAC($aData[$N][0])
		If @error or $lReturn = False Then 
			ConsoleWrite("WARNING: Unable to communicate with " & $aData[$N][0] & @CRLF)
			MsgBox($MB_OK, "Network Snitch", $aData[$N][1] & " left the network!")
		Else
			ConsoleWrite("Ping: " & $aData[$N][0] & " = " & $lReturn & @CRLF)
		endif
		Sleep(500)
	Next
WEnd
Func _CreateLocalARPTableDatabase()
	For $N = 1 To $aARP_Table[0]
		If _ContainsNetworkIP($aARP_Table[$N]) Then
			$Test = StringRegExp($aARP_Table[$N], "(\d+\.\d+\.\d+\.\d+)\s+(..-..-..-..-..-..)", 3)
			If IsArray($Test) Then
				_ArrayAdd($aLocal_ARP_Table, $Test[0] & "|" & $Test[1])
				IniWrite($sDatabase_Path, "Entry", $Test[0], $Test[1])
			EndIf
		EndIf
	Next
EndFunc

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

Func _GetIPAuto()
	Local $lReturn = _GetReturn("tracert -d -h 1 -4 8.8.8.8")
	Local $aIPs = StringRegExp($lReturn, "(\d+\.\d+\.\d+\.\d+)", 3)
	_ArrayDisplay($aIPs)
	Return $aIPs[1]
EndFunc

Func _Fill_ARP_Table()
	Local $lIP
	Local $lProgress
	SplashTextOn("Network Snitch", "Scanning Network...", 300, 100, -1, -1, 1, "", 14)
	For $N = 1 To 255
		$lIP = $aIP[1] & "." & $aIP[2] & "." & $aIP[3] & "." & $N
		ConsoleWrite("Pinging: " & $lIP & @CRLF)
		Run(@ComSpec & " /c ping -n 5 -w 2000 " & $lIP, "", @SW_HIDE)
		$lProgress = Round(($N / 255) * 100, 2)
		ControlSetText("Network Snitch", "", "Static1", "Scanning Network..." & @CRLF & "Progress: " & $lProgress & "%")
		Sleep(10)
	Next
	SplashOff()
EndFunc   ;==>_Fill_ARP_Table

Func _GetARPTable()
	_Fill_ARP_Table()
	Local $lReturn = _GetReturn("arp -a")
	$lReturn = StringSplit($lReturn, @CRLF, 1)
	Return $lReturn
EndFunc   ;==>_GetARPTable

Func _Ping($pIP)
	$lReturn = Ping($pIP)
	If Not @error And $lReturn >=1 Then
		Return True
	Else
		Return SetError(1, 0, False)
	EndIf
EndFunc   ;==>_Ping

Func _ContainsNetworkIP($pIP)
	If StringInStr($pIP, $aIP[1] & "." & $aIP[2] & "." & $aIP[3] ) Then
		Return True
	EndIf
EndFunc   ;==>_ContainsNetworkIP

Func _PingMAC($sMAC)
	ConsoleWrite("_PingMAC(): " & $sMAC & @CRLF)
	Local $aMonitor = IniReadSection($sDatabase_Path, "Entry")
	For $N = 1 To $aMonitor[0][0]
		If StringInStr($aMonitor[$N][1], $sMAC) Then
			ConsoleWrite("_PingMAC(): IP = " & $aMonitor[$N][0] & @CRLF)
			Return _Ping($aMonitor[$N][0])
		EndIf
	Next
	Return SetError(1, 0, False)
EndFunc   ;==>_PingMAC