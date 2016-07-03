#include-once
#include <GUIConstantsEx.au3>
#include <GuiListView.au3>

Func _loginArea()
	Local $hLoginGUI = GUICreate("SSH Private Client - LoginArea", 250, 190, -1, -1, -1, 0x00000080)
	GUICtrlCreateLabel("Username", 30, 20, 55, 14)
	GUICtrlSetFont(-1, 8.5, 400, 0, "Tahoma", 5)
	Local $hIUsername = GUICtrlCreateInput($Username, 90, 16, 115, 20)
	GUICtrlCreateLabel("Password", 30, 42, 55, 14)
	GUICtrlSetFont(-1, 8.5, 400, 0, "Tahoma", 5)
	Local $hIPassword = GUICtrlCreateInput($Password, 90, 40, 115, 19, 0x0020)
	Local $hCRemember = GUICtrlCreateCheckbox("Remember", 93, 65, 69, 15)
	If $Username And $Password Then GUICtrlSetState(-1, 1)
	GUICtrlSetFont(-1, 8.5, 400, 0, "Tahoma", 5)
	Local $hBLogin = GUICtrlCreateButton("Login", 90, 90, 95, 25)
	GUICtrlSetFont(-1, 9, 400, 0, "Tahoma", 5)
	GUICtrlCreateGroup(" Infomation ", 1, 125, 248, 65)
	GUICtrlSetFont(-1, 8.5, 400, 0, "Tahoma", 5)
	GUICtrlCreateLabel("SSH Private Server by YoloTEAM @ 2016", 27, 145, 200, 14)
	GUICtrlSetFont(-1, 8.5, 400, 0, "Tahoma", 5)
	Local $hLink = GUICtrlCreateLabel("http://YoloTEAM.github.io/PrivateSSHManager", 13, 165, 225, 15)
	GUICtrlSetColor(-1, 0x0080FF)
	GUICtrlSetFont(-1, 8.5, 400, 4, "Tahoma", 5)
	GUISetState(@SW_SHOW, $hLoginGUI)
	WinSetOnTop($hLoginGUI, '', 1)

	While 1
		Switch GUIGetMsg($hLoginGUI)
			Case -3
				Exit
			Case $hLink
				ShellExecute("http://YoloTEAM.github.io/PrivateSSHManager")
			Case $hBLogin
				GUICtrlSetState($hBLogin, 128)
				$Username = GUICtrlRead($hIUsername)
				$Password = GUICtrlRead($hIPassword)
				Local $getJWT = _getJWT()
				If $getJWT == 1 Then
					GUISetState(@SW_HIDE, $hLoginGUI)

					If _IsChecked($hCRemember) Then
						IniWrite($configFile, "SSHPrivateServer", "Username", $Username)
						IniWrite($configFile, "SSHPrivateServer", "Password", $Password)
					Else
						IniWrite($configFile, "SSHPrivateServer", "Username", "")
						IniWrite($configFile, "SSHPrivateServer", "Password", "")
					EndIf

					GUICtrlSetState($hBLogin, 64)
					GUIDelete($hLoginGUI)
					ExitLoop
				Else
					MsgBox(0, "Error", $getJWT, 0, $hLoginGUI)
				EndIf
				GUICtrlSetState($hBLogin, 64)
		EndSwitch
	WEnd
EndFunc   ;==>_loginArea

Func _SshToArray()
	GUICtrlSetData($hLStatus, ">> Request Sshs list from Server ...")
	Local $Sshs = REST_getSocks($countryISO, $SocksPerRq, $GlobalJWT)
	FileDelete(@ScriptDir & '\SaveSsh\get.txt')

	If StringInStr($Sshs, '{"sucess":false') Then
		GUICtrlSetData($hLStatus, ">> " & $Sshs)
		$stop_wait = True
	Else
		FileWrite(@ScriptDir & '\SaveSsh\get.txt', $Sshs)
		_FileReadToArray(@ScriptDir & '\SaveSsh\get.txt', $tempSsh, 1, "|")
		GUICtrlSetData($hLStatus, ">> READY .")
	EndIf
EndFunc   ;==>_SshToArray

Func _changeSsh()
	If UBound($tempSsh) < 2 Then Return
	Local $BvSsh_loginState, $Get_tempSsh

	While Not $stop_wait
		$Get_tempSsh = $tempSsh[1][0] & "|" & $tempSsh[1][1] & "|" & $tempSsh[1][2]

		If Not StringInStr(FileRead(@ScriptDir & '\SaveSsh\live.txt'), $tempSsh[1][0] & "|" & $tempSsh[1][1]) Or Not StringInStr(FileRead(@ScriptDir & '\SaveSsh\die.txt'), $tempSsh[1][0] & "|" & $tempSsh[1][1]) Then
			$BvSsh_loginState = _BvSsh_Login($tempSsh[1][0], $tempSsh[1][1], $tempSsh[1][2])
			ConsoleWrite($Get_tempSsh & @CRLF)

			If $BvSsh_loginState > 0 Then
				FileWrite(@ScriptDir & '\SaveSsh\live.txt', $Get_tempSsh & @CRLF)
				GUICtrlSetData($hLStatus, ">> Using Ssh: " & $tempSsh[1][0] & " - Forwarding 127.0.0.1:" & $BvSsh_forwardPort)
				Sleep(1000)
				_ArrayDelete($tempSsh, 1)
				ExitLoop
			ElseIf $BvSsh_loginState == 0 Then
				GUICtrlSetData($hLStatus, ">> Next Ssh ...")
				FileWrite(@ScriptDir & '\SaveSsh\die.txt', $Get_tempSsh & @CRLF)
			Else
				GUICtrlSetData($hLStatus, ">> Stoped . READY .")
			EndIf
		EndIf

		_ArrayDelete($tempSsh, 1)
		If UBound($tempSsh) < 2 Then _SshToArray()

		Sleep(500)
	WEnd

	$stop_wait = False
EndFunc   ;==>_changeSsh

Func _selectCountry()
	Local $hSelectCountryGUI = GUICreate("Window", 375, 220, -1, -1)
	GUISetBkColor(0x008080)
	Local $hCountryListView = GUICtrlCreateListView("N.|Country|ISO|Socks", 0, 0, 375, 180)
	ControlDisable($hSelectCountryGUI, "", HWnd(_GUICtrlListView_GetHeader($hCountryListView)))

	GUICtrlCreateLabel("Number of Socks / Request:", 10, 193, 160, 15)
	GUICtrlSetColor(-1, 0xFFFFFF)
	GUICtrlSetFont(-1, 8.5, 800, 0, "Tahoma", 5)
	Local $hISpR = GUICtrlCreateInput($SocksPerRq, 175, 190, 40, 20)
	GUICtrlSetFont(-1, 8.5, 400, 0, "Tahoma", 5)
	Local $hBSave = GUICtrlCreateButton("Save", 230, 185, 80, 30)
	GUICtrlSetFont(-1, 8.5, 800, 0, "Tahoma", 5)
	Local $hBReload = GUICtrlCreateButton("Reload", 315, 185, 50, 30)
	GUICtrlSetFont(-1, 8.5, 400, 0, "Tahoma", 5)
	GUICtrlSetState(-1, 128)

	_countryReload($hCountryListView)

	GUISetState(@SW_SHOW, $hSelectCountryGUI)

	While 1
		Switch GUIGetMsg()
			Case -3
				GUIDelete($hSelectCountryGUI)
				ExitLoop
			Case $hBSave
				Local $iSelect = _GUICtrlListView_GetSelectedIndices($hCountryListView, True)
				If Not $iSelect[0] Or GUICtrlRead($hISpR) < 1 Then ContinueCase

				Local $tempCountry = _GUICtrlListView_GetItemText($hCountryListView, $iSelect[1], 2)
				If $tempCountry <> $countryISO Then
					If IsArray($tempSsh) Then
						For $i = 1 To UBound($tempSsh) - 1
							FileWrite(@ScriptDir & '\SaveSsh\unUSED\unUSED-' & $countryISO & '.txt', $tempSsh[$i][0] & "|" & $tempSsh[$i][1] & "|" & $tempSsh[$i][2] & @CRLF)
						Next
					EndIf

					$countryISO = $tempCountry
					IniWrite($configFile, "SSHPrivateServer", "CountryISO", $countryISO)

					$tempSsh = 0
				EndIf

				$SocksPerRq = GUICtrlRead($hISpR)
				IniWrite($configFile, "SSHPrivateServer", "SocksPerRequest", $SocksPerRq)

				GUICtrlSetData($hLCountry, "Country:    " & _GUICtrlListView_GetItemText($hCountryListView, $iSelect[1], 1))

				GUIDelete($hSelectCountryGUI)
				ExitLoop
			Case $hBReload
				_countryReload($hCountryListView)
		EndSwitch
	WEnd
EndFunc   ;==>_selectCountry

Func _countryReload($hWnd)
	_GUICtrlListView_DeleteAllItems($hWnd)

	For $i = 1 To _FileCountLines(@ScriptDir & '\country.iso')
		GUICtrlCreateListViewItem($i & "|" & FileReadLine(@ScriptDir & '\country.iso', $i), $hWnd)
	Next

	_ListviewSetWidth($hWnd)
EndFunc   ;==>_countryReload

Func _ListviewSetWidth($hWnd)
	GUICtrlSendMsg($hWnd, $LVM_SETCOLUMNWIDTH, 0, 30)
	GUICtrlSendMsg($hWnd, $LVM_SETCOLUMNWIDTH, 1, 170)
	GUICtrlSendMsg($hWnd, $LVM_SETCOLUMNWIDTH, 2, 35)
	GUICtrlSendMsg($hWnd, $LVM_SETCOLUMNWIDTH, 3, 119)
EndFunc   ;==>_ListviewSetWidth

Func _IsChecked($idControlID)
	Return BitAND(GUICtrlRead($idControlID), $GUI_CHECKED) = $GUI_CHECKED
EndFunc   ;==>_IsChecked
