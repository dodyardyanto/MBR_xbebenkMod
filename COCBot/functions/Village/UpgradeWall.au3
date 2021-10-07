; #FUNCTION# ====================================================================================================================
; Name ..........: UpgradeWall
; Description ...: This file checks if enough resources to upgrade walls, and upgrades them
; Syntax ........: UpgradeWall()
; Parameters ....:
; Return values .: None
; Author ........: ProMac (2015), HungLe (2015)
; Modified ......: Sardo (08-2015), KnowJack (08-2015), MonkeyHunter(06-2016) , trlopes (07-2016)
; Remarks .......: This file is part of MyBot, previously known as ClashGameBot. Copyright 2015-2021
;                  MyBot is distributed under the terms of the GNU GPL
; Related .......: checkwall.au3
; Link ..........: https://github.com/MyBotRun/MyBot/wiki
; Example .......: No
; ===============================================================================================================================

Func UpgradeWall()

	Local $iWallCost = Int($g_iWallCost - ($g_iWallCost * Number($g_iBuilderBoostDiscount) / 100))
	Local $GoUpgrade = False
	If Not $g_bRunState Then Return
	
	If Not $g_bAutoUpgradeWallsEnable Then Return
	
	SetLog("Checking Upgrade Walls", $COLOR_INFO)
	VillageReport(True, True) ;update village resource capacity
	SetLog("FreeBuilderCount: " & $g_iFreeBuilderCount, $COLOR_DEBUG)
	
	If Not IsResourceEnough($iWallCost) Then Return
	
	If $g_iFreeBuilderCount = 0 Then
		SetLog("No builder available, Upgrade Walls skipped", $COLOR_DEBUG)
		Return
	EndIf
	
	If $g_iFreeBuilderCount > 0 Then $GoUpgrade = True
	If $g_bChkOnly1Builder And $g_iFreeBuilderCount > 1 Then 
		SetLog("Have more than 1 builder, Upgrade Walls skipped", $COLOR_DEBUG)
		$GoUpgrade = False
	EndIf
	
	If $GoUpgrade Then
		ClickAway()
		Local $MinWallGold = Number($g_aiCurrentLoot[$eLootGold] - $iWallCost) > Number($g_iUpgradeWallMinGold) ; Check if enough Gold
		Local $MinWallElixir = Number($g_aiCurrentLoot[$eLootElixir] - $iWallCost) > Number($g_iUpgradeWallMinElixir) ; Check if enough Elixir

		While ($g_iUpgradeWallLootType = 0 And $MinWallGold) Or ($g_iUpgradeWallLootType = 1 And $MinWallElixir) Or ($g_iUpgradeWallLootType = 2 And ($MinWallGold Or $MinWallElixir))
			Switch $g_iUpgradeWallLootType
				Case 0
					If $MinWallGold Then
						SetLog("Upgrading Wall using Gold", $COLOR_SUCCESS)
						If imglocCheckWall() Then
							If Not UpgradeWallGold($iWallCost) Then
								SetLog("Upgrade with Gold failed, skipping...", $COLOR_ERROR)
								Return
							EndIf
						ElseIf SwitchToNextWallLevel() Then
							SetLog("No more walls of current level, switching to next", $COLOR_ACTION)
						Else
							Return
						EndIf
					Else
						SetLog("Gold is below minimum, Skipping Upgrade", $COLOR_ERROR)
					EndIf
				Case 1
					If $MinWallElixir Then
						SetLog("Upgrading Wall using Elixir", $COLOR_SUCCESS)
						If imglocCheckWall() Then
							If Not UpgradeWallElixir($iWallCost) Then
								SetLog("Upgrade with Elixier failed, skipping...", $COLOR_ERROR)
								Return
							EndIf
						ElseIf SwitchToNextWallLevel() Then
							SetLog("No more walls of current level, switching to next", $COLOR_ACTION)
						Else
							Return
						EndIf
					Else
						SetLog("Elixir is below minimum, Skipping Upgrade", $COLOR_ERROR)
					EndIf
				Case 2
					If $MinWallElixir Then
						SetLog("Upgrading Wall using Elixir", $COLOR_SUCCESS)
						If imglocCheckWall() Then
							If Not UpgradeWallElixir($iWallCost) Then
								SetLog("Upgrade with Elixir failed, attempt to upgrade using Gold", $COLOR_ERROR)
								If Not UpgradeWallGold($iWallCost) Then
									SetLog("Upgrade with Gold failed, skipping...", $COLOR_ERROR)
									Return
								EndIf
							EndIf
						ElseIf SwitchToNextWallLevel() Then
							SetLog("No more walls of current level, switching to next", $COLOR_ACTION)
						Else
							Return
						EndIf
					Else
						SetLog("Elixir is below minimum, attempt to upgrade using Gold", $COLOR_ERROR)
						If $MinWallGold Then
							If imglocCheckWall() Then
								If Not UpgradeWallGold($iWallCost) Then
									SetLog("Upgrade with Gold failed, skipping...", $COLOR_ERROR)
									Return
								EndIf
							ElseIf SwitchToNextWallLevel() Then
								SetLog("No more walls of current level, switching to next", $COLOR_ACTION)
							Else
								Return
							EndIf
						Else
							SetLog("Gold is below minimum, Skipping Upgrade", $COLOR_ERROR)
						EndIf
					EndIf
			EndSwitch

			; Check Builder/Shop if open by accident
			If _CheckPixel($g_aShopWindowOpen, $g_bCapturePixel, Default, "ChkShopOpen", $COLOR_DEBUG) = True Then
				Click(820, 40, 1, 0, "#0315") ; Close it
			EndIf

			ClickAway()
			VillageReport(True, True)
			If Not IsResourceEnough($iWallCost) Then Return
			$MinWallGold = Number($g_aiCurrentLoot[$eLootGold] - $iWallCost) > Number($g_iUpgradeWallMinGold) ; Check if enough Gold
			$MinWallElixir = Number($g_aiCurrentLoot[$eLootElixir] - $iWallCost) > Number($g_iUpgradeWallMinElixir) ; Check if enough Elixir

		WEnd
	EndIf
	checkMainScreen(False) ; Check for errors during function

EndFunc   ;==>UpgradeWall


Func UpgradeWallGold($iWallCost = $g_iWallCost)

	If _Sleep($DELAYRESPOND) Then Return

	Local $aUpgradeButton = findButton("UpgradeWall", Default, 2, True)
	If IsArray($aUpgradeButton) And UBound($aUpgradeButton) > 0 Then
		;Check for Gold in right top button corner and click, if present
		Local $FoundGold = decodeSingleCoord(findImage("UpgradeWallGold", $g_sImgUpgradeWallGold, GetDiamondFromRect("200, 570, 670, 630"), 1, True))
		If UBound($FoundGold) > 1 Then 
			Click($FoundGold[0], $FoundGold[1])
		EndIf
	EndIf

	If _Sleep($DELAYUPGRADEWALLGOLD2) Then Return

	If _ColorCheck(_GetPixelColor(677, 150 + $g_iMidOffsetY, True), Hex(0xE1090E, 6), 20) Then ; wall upgrade window red x
		If isNoUpgradeLoot(False) = True Then
			SetLog("Upgrade stopped due no loot", $COLOR_ERROR)
			Return False
		EndIf
		Click(440, 480 + $g_iMidOffsetY, 1, 0, "#0317")
		If _Sleep(1000) Then Return
		If isGemOpen(True) Then
			ClickAway()
			SetLog("Upgrade stopped due no loot", $COLOR_ERROR)
			Return False
		ElseIf _ColorCheck(_GetPixelColor(677, 150 + $g_iMidOffsetY, True), Hex(0xE1090E, 6), 20) Then ; wall upgrade window red x, didnt closed on upgradeclick, so not able to upgrade
			ClickAway()
			SetLog("unable to upgrade", $COLOR_ERROR)
			Return False
		Else
			If _Sleep($DELAYUPGRADEWALLGOLD3) Then Return
			ClickAway()
			SetLog("Upgrade complete", $COLOR_SUCCESS)
			PushMsg("UpgradeWithGold")
			$g_iNbrOfWallsUppedGold += 1
			$g_iNbrOfWallsUpped += 1
			$g_iCostGoldWall += $iWallCost
			UpdateStats()
			Return True
		EndIf
	EndIf

	ClickAway()
	SetLog("No Upgrade Gold Button", $COLOR_ERROR)
	Pushmsg("NowUpgradeGoldButton")
	Return False

EndFunc   ;==>UpgradeWallGold

Func UpgradeWallElixir($iWallCost = $g_iWallCost)

	If _Sleep($DELAYRESPOND) Then Return

	Local $aUpgradeButton = findButton("UpgradeWall", Default, 2, True)
	If IsArray($aUpgradeButton) And UBound($aUpgradeButton) > 0 Then
		;Check for elixircolor in right top button corner and click, if present
		Local $FoundElixir = decodeSingleCoord(findImage("UpgradeWallElixir", $g_sImgUpgradeWallElix, GetDiamondFromRect("200, 570, 670, 630"), 1, True, Default))
		If UBound($FoundElixir) > 1 Then 
			Click($FoundElixir[0], $FoundElixir[1])		
		EndIf	
	EndIf

	If _Sleep($DELAYUPGRADEWALLELIXIR2) Then Return

	If _ColorCheck(_GetPixelColor(677, 150 + $g_iMidOffsetY, True), Hex(0xE1090E, 6), 20) Then
		If isNoUpgradeLoot(False) = True Then
			SetLog("Upgrade stopped due to insufficient loot", $COLOR_ERROR)
			Return False
		EndIf
		Click(440, 480 + $g_iMidOffsetY, 1, 0, "#0318")
		If _Sleep(1000) Then Return
		If isGemOpen(True) Then
			ClickAway()
			SetLog("Upgrade stopped due to insufficient loot", $COLOR_ERROR)
			Return False
		ElseIf _ColorCheck(_GetPixelColor(677, 150 + $g_iMidOffsetY, True), Hex(0xE1090E, 6), 20) Then ; wall upgrade window red x, didnt closed on upgradeclick, so not able to upgrade
			ClickAway()
			SetLog("unable to upgrade", $COLOR_ERROR)
			Return False
		Else
			If _Sleep($DELAYUPGRADEWALLELIXIR3) Then Return
			ClickAway()
			SetLog("Upgrade complete", $COLOR_SUCCESS)
			PushMsg("UpgradeWithElixir")
			$g_iNbrOfWallsUppedElixir += 1
			$g_iNbrOfWallsUpped += 1
			$g_iCostElixirWall += $iWallCost
			UpdateStats()
			Return True
		EndIf
	EndIf

	ClickAway()
	SetLog("No Upgrade Elixir Button", $COLOR_ERROR)
	Pushmsg("NowUpgradeElixirButton")
	Return False

EndFunc   ;==>UpgradeWallElixir

Func IsResourceEnough($iWallCost = $g_iWallCost)
	Local $EnoughGold = True, $EnoughElix = True
	Switch $g_iUpgradeWallLootType
		Case 0 ; Using gold
			If ($g_aiCurrentLoot[$eLootGold] - $iWallCost) < $g_iUpgradeWallMinGold Then
				SetLog("Skip Wall upgrade -insufficient gold", $COLOR_WARNING)
				Return False
			EndIf
		Case 1 ; Using elixir
			If ($g_aiCurrentLoot[$eLootElixir] - $iWallCost) < $g_iUpgradeWallMinElixir Then
				SetLog("Skip Wall upgrade - insufficient elixir", $COLOR_WARNING)
				Return False
			EndIf
		Case 2 ; Using gold and elixir
			If ($g_aiCurrentLoot[$eLootGold] - $iWallCost) < $g_iUpgradeWallMinGold Then
				$EnoughGold = False
			EndIf
			If ($g_aiCurrentLoot[$eLootElixir] - $iWallCost) < $g_iUpgradeWallMinElixir Then
				$EnoughElix = False
			EndIf
			If Not $EnoughGold And Not $EnoughElix Then 
				SetLog("Skip Wall upgrade - insufficient gold or elixir", $COLOR_WARNING)
				Return False
			EndIf
	EndSwitch
	Return True
EndFunc

Func SwitchToNextWallLevel() ; switches wall level to upgrade to next level
	If $g_aiWallsCurrentCount[$g_iCmbUpgradeWallsLevel + 4] = 0 And $g_iCmbUpgradeWallsLevel < 9 Then
		SetDebugLog("$g_aiWallsCurrentCount = " & $g_aiWallsCurrentCount)
		SetDebugLog("$g_iCmbUpgradeWallsLevel = " & $g_iCmbUpgradeWallsLevel)

		EnableGuiControls()
		_GUICtrlComboBox_SetCurSel($g_hCmbWalls, $g_iCmbUpgradeWallsLevel + 1)
		cmbWalls()
		If $g_iCmbUpgradeWallsLevel = 4 Then
			GUICtrlSetState($g_hRdoUseElixirGold, $GUI_CHECKED)
			GUICtrlSetData($g_hTxtWallMinElixir, GUICtrlRead($g_hTxtWallMinGold))
		EndIf
		SaveConfig()
		DisableGuiControls()
		Return True
	EndIf
	Return False
EndFunc   ;==>SwitchToNextWallLevel

