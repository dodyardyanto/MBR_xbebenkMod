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

Func UpgradeWall($bTest = False)

	Local $aSelectedWall[3][2]
	For $z = 0 To 2
		$aSelectedWall[$z][0] = $g_aUpgradeWall[$z]
		$aSelectedWall[$z][1] = $g_aiWallCost[$g_aUpgradeWall[$z]]
	Next

	Local $iWallCost = $aSelectedWall[0][1]
	Local $iWallLevel = $aSelectedWall[0][0]
	Local $GoUpgrade = False
	If Not $g_bRunState Then Return

	If Not $g_bAutoUpgradeWallsEnable Then Return

	SetLog("Checking Upgrade Walls", $COLOR_INFO)
	VillageReport(True, True) ;update village resource capacity
	SetLog("FreeBuilderCount: " & $g_iFreeBuilderCount, $COLOR_DEBUG)
	If $g_iFreeBuilderCount < 1 Then Return
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
	If $g_iFreeBuilderCount > 1 And $g_bUpgradeWallSaveBuilder Then
		SetLog("Ooops, Chief you are reserve one for wall, sure we will Upgrade Walls", $COLOR_DEBUG)
		$GoUpgrade = True
	EndIf
	If Not $g_bRunState Then Return
	If $GoUpgrade And $g_bUpgradeLowWall Then
		UpgradeLowLevelWall($bTest)
	EndIf
	If Not $g_bRunState Then Return
	If $GoUpgrade Then
		ClickAway()
		VillageReport(True, True) ;update village resource capacity
		If $g_iFreeBuilderCount < 1 Then Return
		For $z = 0 To 2
			Local $searchcount = 0
			$iWallCost = $aSelectedWall[$z][1]
			$iWallLevel = $aSelectedWall[$z][0]
			SetLog("[" & $z & "] Try Upgrade WallLevel[" & $iWallLevel + 4 & "] Cost:" & $iWallCost, $COLOR_INFO)
			Local $MinWallGold = IsResourceEnough($iWallCost)
			Local $MinWallElixir = IsResourceEnough($iWallCost)
			If Not $MinWallGold And Not $MinWallElixir Then ExitLoop

			While $MinWallGold Or $MinWallElixir
				If $searchcount > 1 Then ExitLoop
				If Not $g_bRunState Then Return
				$searchcount += 1
				;check for gold wall upgrade
				If $g_iUpgradeWallLootType = 0 Then
					SetLog("Upgrading Wall using Gold", $COLOR_SUCCESS)
					If imglocCheckWall($iWallLevel) Then
						If Not UpgradeWallGold($iWallCost, $bTest) Then
							SetLog("Upgrade with Gold failed, skipping...", $COLOR_ERROR)
							ExitLoop
						EndIf
					Else
						SetLog("Wall Level " & $iWallLevel + 4 & " not Found", $COLOR_ERROR)
						ExitLoop
					EndIf
				EndIf

				;check for elixir wall upgrade
				If $g_iUpgradeWallLootType = 1 Then
					SetLog("Upgrading Wall using Elixir", $COLOR_SUCCESS)
					If imglocCheckWall($iWallLevel) Then
						If Not UpgradeWallElixir($iWallCost, $bTest) Then
							SetLog("Upgrade with Elixir failed, skipping...", $COLOR_ERROR)
							ExitLoop
						EndIf
					Else
						SetLog("Wall Level " & $iWallLevel + 4 & " not Found", $COLOR_ERROR)
						ExitLoop
					EndIf
				EndIf

				;check for both gold and elixir wall upgrade
				If $g_iUpgradeWallLootType = 2 Then
					If $MinWallElixir Or $MinWallGold Then
						If imglocCheckWall($iWallLevel) Then
							SetLog("Upgrading Wall using Elixir", $COLOR_SUCCESS)
							If Not UpgradeWallElixir($iWallCost, $bTest) Then
								SetLog("Upgrade with Elixir failed, attempt to upgrade using Gold", $COLOR_INFO)
							EndIf
							If Not UpgradeWallGold($iWallCost, $bTest) Then
								SetLog("Upgrade with Gold failed, skip!", $COLOR_ERROR)
								ExitLoop
							EndIf
						Else
							SetLog("Wall Level " & $iWallLevel + 4 & " not Found", $COLOR_ERROR)
						EndIf
					EndIf
					;If $MinWallElixir Then
					;	SetLog("Upgrading Wall using Elixir", $COLOR_SUCCESS)
					;	If imglocCheckWall($iWallLevel) Then
					;		If Not UpgradeWallElixir($iWallCost, $bTest) Then
					;			SetLog("Upgrade with Elixir failed, attempt to upgrade using Gold", $COLOR_ERROR)
					;		EndIf
					;	Else
					;		SetLog("Upgrade with Elixir For Wall Level " & $iWallLevel + 4 & " is Failed", $COLOR_ERROR)
					;		ExitLoop
					;	EndIf
					;Else
					;	SetLog("Elixir is below minimum, Skipping Upgrade", $COLOR_ERROR)
					;EndIf
					;
					;If $MinWallGold Then
					;	SetLog("Upgrading Wall using Gold", $COLOR_SUCCESS)
					;	If imglocCheckWall($iWallLevel) Then
					;		If Not UpgradeWallGold($iWallCost, $bTest) Then
					;			SetLog("Upgrade with Gold failed, skipping...", $COLOR_ERROR)
					;			ExitLoop
					;		EndIf
					;	Else
					;		SetLog("Upgrade with Gold For Wall Level " & $iWallLevel + 4 & " is Failed", $COLOR_ERROR)
					;		ExitLoop
					;	EndIf
					;Else
					;	SetLog("Gold is below minimum, Skipping Upgrade", $COLOR_ERROR)
					;EndIf

				EndIf

				; Check Builder/Shop if open by accident
				If _CheckPixel($g_aShopWindowOpen, $g_bCapturePixel, Default, "ChkShopOpen", $COLOR_DEBUG) = True Then
					Click(820, 40, 1, 0, "#0315") ; Close it
				EndIf

				ClickAway()
				VillageReport(True, True)
				If Not IsResourceEnough($iWallCost) Then ExitLoop
				$MinWallGold = Number($g_aiCurrentLoot[$eLootGold] - $iWallCost) > Number($g_iUpgradeWallMinGold) ; Check if enough Gold
				$MinWallElixir = Number($g_aiCurrentLoot[$eLootElixir] - $iWallCost) > Number($g_iUpgradeWallMinElixir) ; Check if enough Elixir
			WEnd
		Next

	EndIf
	checkMainScreen(False) ; Check for errors during function

EndFunc   ;==>UpgradeWall

Func UpgradeLowLevelWallCheckResource()
	$g_aiCurrentLoot[$eLootGold] = getResourcesMainScreen(701, 23) ;get current Gold
	$g_aiCurrentLoot[$eLootElixir] = getResourcesMainScreen(701, 74) ;get current Elixir
	SetLog("Current Resource, Gold: " & $g_aiCurrentLoot[$eLootGold] & " Elix: " & $g_aiCurrentLoot[$eLootElixir], $COLOR_INFO)
	If $g_aiCurrentLoot[$eLootGold] < $g_iUpgradeWallMinGold Then
		SetLog("Current Gold: " & $g_aiCurrentLoot[$eLootGold] & ", already below " & $g_iUpgradeWallMinGold, $COLOR_INFO)
		Return False
	EndIf
	Return True
EndFunc

Func WallUpgradeCheckBuilder($bTest)
	Local $bRet = False
	getBuilderCount(True)
	If $bTest Then
		$bRet = True
	Else
		If $g_iFreeBuilderCount < 1 Then
			$bRet = False
		Else
			$bRet = True
		EndIf
	EndIf
	Return $bRet
EndFunc

Func TryUpgradeWall($aWallCoord, $bTest = False)
	Local $UpgradeToLvl = $g_iLowLevelWall
	For $i = 0 To UBound($aWallCoord) - 1
		If Not $g_bRunState Then Return
		If Not WallUpgradeCheckBuilder($bTest) Then Return
		ClickMainBuilder()
		SetLog("Wall " & "[" & $i & "] : [" & $aWallCoord[$i][0] & "," & $aWallCoord[$i][1] & " Cost = " & $aWallCoord[$i][2] & "]", $COLOR_DEBUG)
		Click($aWallCoord[$i][0], $aWallCoord[$i][1])

		If _Sleep(1000) Then Return
		Local $aWallLevel = BuildingInfo(242, 494)
		If $aWallLevel[0] = "" Or Not $aWallLevel[1] = "Wall" Then
			SetLog("Not Wall, wrong click...", $COLOR_ERROR)
			ContinueLoop
		EndIf

		If Not $g_bUpgradeAnyWallLevel And $aWallLevel[2] > $UpgradeToLvl Then
			SetLog("Skip this Wall, searching wall level " & $UpgradeToLvl & " and below", $COLOR_ERROR)
			ContinueLoop
		EndIf

		SetLog("Wall Level : " & $aWallLevel[2], $COLOR_SUCCESS)
		If DoLowLevelWallUpgrade($aWallLevel[2], $bTest, $aWallCoord[$i][2]) Then
			If _Sleep(1000) Then Return
			ContinueLoop
		Else
			If _Sleep(1000) Then Return
			SetLog("Failed to Upgrade Wall", $COLOR_ERROR)
		EndIf

		If Not UpgradeLowLevelWallCheckResource() Then ExitLoop
	Next
EndFunc

Func UpgradeLowLevelWall($bTest = False)
	SetLog("Upgrade LowLevel Wall using autoupgrade enabled", $COLOR_DEBUG)
	VillageReport(True, True) ;update village resource capacity
	ClickMainBuilder()
	Local $aWallCoord
	For $try = 1 To 2
		If Not $g_bRunState Then Return
		If Not WallUpgradeCheckBuilder($bTest) Then Return
		$aWallCoord = ClickDragFindWallUpgrade()
		If IsArray($aWallCoord) And UBound($aWallCoord) > 0 Then
			SetLog("[" & $try & "] Search Wall on Builder Menu", $COLOR_INFO)
			TryUpgradeWall($aWallCoord, $bTest)
		Else
			SetLog("[" & $try & "] Not Found Wall on Builder Menu", $COLOR_ERROR)
		EndIf
	Next
	ClickDragAUpgrade("down")
	CheckMainScreen(False)
EndFunc

Func DoLowLevelWallUpgrade($WallLevel = 1, $bTest = False, $iWallCost = 1000)
	
	Local $UpgradeToLvl = $g_iLowLevelWall
	If $WallLevel >= $UpgradeToLvl And $g_bUpgradeAnyWallLevel Then
		SetLog("Try to Upgrade Any Wall Level", $COLOR_INFO)
		Local $MinWallGold = IsResourceEnough($iWallCost)
		Local $MinWallElixir = IsResourceEnough($iWallCost)
		If Not $g_bRunState Then Return
		Switch $g_iUpgradeWallLootType
			Case 0 ;Gold
				If $MinWallGold Then
					SetLog("Try Upgrade Wall using Gold", $COLOR_INFO)
					If Not UpgradeWallGold($iWallCost, $bTest) Then
						SetLog("Upgrade with Gold failed", $COLOR_ERROR)
						Return False
					EndIf
				EndIf
			Case 1 ;Elixir
				If $MinWallElixir Then
					SetLog("Try Upgrade Wall using Elixir", $COLOR_INFO)
					If Not UpgradeWallElixir($iWallCost, $bTest) Then
						SetLog("Upgrade with Elixir failed", $COLOR_ERROR)
						Return False
					EndIf
				EndIf
			Case 2 ;Elixir then Gold
				If $MinWallElixir Then
					SetLog("Try Upgrade Wall using Elixir", $COLOR_INFO)
					If Not UpgradeWallElixir($iWallCost, $bTest) Then
						SetLog("Upgrade with Elixir failed, attempt to upgrade using Gold", $COLOR_INFO)
					Else
						Return True
					EndIf
				EndIf
				If $MinWallGold Then 
					SetLog("Try Upgrade Wall using Gold", $COLOR_INFO)
					If Not UpgradeWallGold($iWallCost, $bTest) Then
						SetLog("Upgrade with Gold failed, skip!", $COLOR_ERROR)
						Return False
					EndIf
				EndIf
		EndSwitch
		ClickAway()
		Return True
	EndIf

	If $WallLevel <= $UpgradeToLvl Then
		SetLog("Trying Upgrade Wall Level : " & $WallLevel & " Once in a Row", $COLOR_INFO)
		If ClickB("SelectRow") Then
			If _Sleep(1000) Then Return
			For $x = $WallLevel To $UpgradeToLvl ;try to upgrade till LowLevel Wall Setting
				If Not $g_bRunState Then Return
				If Not WallUpgradeCheckBuilder($bTest) Then Return
				If QuickMIS("BC1", $g_sImgAUpgradeWhiteZeroWallUpgrade, 400, 520, 530, 610) Then
					Click($g_iQuickMISX + 400, $g_iQuickMISY + 520)
					If _Sleep(1500) Then Return
					If QuickMIS("BC1", $g_sImgAUpgradeWallOK, 400, 350, 600, 450) Then
						If Not $bTest Then
							Click($g_iQuickMISX + 400, $g_iQuickMISY + 350)
							If _Sleep(1000) Then Return
						Else
							SetLog("Testing Only!", $COLOR_ERROR)
							ClickAway()
							If _Sleep(500) Then Return
							ClickAway()
							Return False
						EndIf
						If IsGemOpen(True) Then
							SetLog("Not Enough Resource...", $COLOR_ERROR)
							Return False
						Else
							SetLog("Successfully Upgrade a Row of Wall Level " & $x & " To lvl " & $x+1, $COLOR_SUCCESS)
						EndIf
					EndIf
				Else
					SetLog("Not Enough Resource...", $COLOR_ERROR)
					Return False
				EndIf
				If _Sleep(1000) Then Return
				If Not UpgradeLowLevelWallCheckResource() Then Return
			Next
		Else
			SetLog("Cannot Select Row", $COLOR_INFO)
			For $x = $WallLevel To $UpgradeToLvl ;try to upgrade till lvl 4
				If Not $g_bRunState Then Return
				If Not WallUpgradeCheckBuilder($bTest) Then Return
				If QuickMIS("BC1", $g_sImgAUpgradeWhiteZeroWallUpgrade, 400, 520, 530, 610) Then
					Click($g_iQuickMISX + 400, $g_iQuickMISY + 520)
					If _Sleep(1000) Then Return
					If Not $bTest Then
						Click(440, 530)
						If _Sleep(1000) Then Return
					Else
						SetLog("Testing Only!", $COLOR_ERROR)
						ClickAway()
						If _Sleep(500) Then Return
						ClickAway()
						Return False
					EndIf
					If IsGemOpen(True) Then
						SetLog("Not Enough Resource...", $COLOR_ERROR)
						Return False
					Else
						SetLog("Successfully Upgrade a Wall Level " & $x & " To lvl " & $x+1, $COLOR_SUCCESS)
					EndIf
				Else
					SetLog("Not Enough Resource...", $COLOR_ERROR)
					Return False
				EndIf
				If _Sleep(1000) Then Return
				If Not UpgradeLowLevelWallCheckResource() Then Return
			Next
		EndIf
		Return True
	EndIf
EndFunc

Func ClickDragFindWallUpgrade()
	Local $x = 420, $yUp = 120, $Delay = 500
	Local $YY = 345
	Local $aTmpWallCoord, $aWallCoord[0][3], $aWall, $TmpUpgradeCost = 0, $UpgradeCost = 0
	For $checkCount = 0 To 9
		If Not $g_bRunState Then Return
		If _ColorCheck(_GetPixelColor(422, 73, True), "fdfefd", 20) Then
			ClickDrag($x, $YY, $x, $yUp, $Delay) ;drag up
			If _Sleep(1000) Then Return
			$aTmpWallCoord = QuickMIS("CX", $g_sImgAUpgradeWall, 210, 80, 260, 369, True)
			If IsArray($aTmpWallCoord) And UBound($aTmpWallCoord) > 0 Then
				SetLog("Found " & UBound($aTmpWallCoord) & " Image Wall", $COLOR_DEBUG)
				For $j = 0 To UBound($aTmpWallCoord) - 1
					$aWall = StringSplit($aTmpWallCoord[$j], ",", $STR_NOCOUNT)
					$UpgradeCost = getOcrAndCapture("coc-NewCapacity",$aWall[0] + 210 + 120, $aWall[1] + 80 - 8, 100, 20, True)
					If Not $UpgradeCost = "" Then
						_ArrayAdd($aWallCoord, $aWall[0]+210 & "|" & $aWall[1]+80 & "|" & $UpgradeCost)
					Else
						SetDebugLog("Wall " & $j & " not enough resource, skip!", $COLOR_DEBUG)
					EndIf
				Next
				_ArraySort($aWallCoord, 1, 0, 0, 1)
				Return $aWallCoord
			Else
				SetDebugLog("Not Array Wall", $COLOR_DEBUG)
			EndIf

			$TmpUpgradeCost = getOcrAndCapture("coc-NewCapacity",350, 335, 100, 30, True)
			SetDebugLog("TmpUpgradeCost = " & $TmpUpgradeCost & " UpgradeCost = " & $UpgradeCost, $COLOR_INFO)
			If $UpgradeCost = $TmpUpgradeCost And $checkCount > 6 Then ExitLoop
			$UpgradeCost = $TmpUpgradeCost
		EndIf
		If _ColorCheck(_GetPixelColor(422, 73, True), "fdfefd", 20) Then ;check upgrade window border
			SetDebugLog("Upgrade Window Exist", $COLOR_INFO)
		Else
			SetDebugLog("Upgrade Window Gone!", $COLOR_DEBUG)
			ClickMainBuilder()
		EndIf
	Next
	Return $aWallCoord
EndFunc ;==>IsUpgradeWindow

Func UpgradeWallGold($iWallCost = $g_iWallCost, $bTest = False)

	;Check for Gold in right top button corner and click, if present
	Local $FoundGold = decodeSingleCoord(findImage("UpgradeWallGold", $g_sImgUpgradeWallGold, GetDiamondFromRect("200, 530, 670, 600"), 1, True))
	If UBound($FoundGold) > 1 Then
		Click($FoundGold[0], $FoundGold[1])
	Else
		SetLog("No Upgrade Gold Button", $COLOR_ERROR)
		Return False
	EndIf

	If _Sleep($DELAYUPGRADEWALLGOLD2) Then Return

	If WaitforPixel(670, 140, 690, 150, Hex(0xFFFFFF, 6), 6, 2) Then ; wall upgrade window red x
		If Not $bTest Then
			Click(440, 500, 1, 0, "#0317")
		Else
			SetLog("Testing Only!", $COLOR_ERROR)
			ClickAway()
		EndIf
		If _Sleep(1000) Then Return
		If isGemOpen(True) Then
			ClickAway()
			SetLog("Upgrade stopped due no loot", $COLOR_ERROR)
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
EndFunc   ;==>UpgradeWallGold

Func UpgradeWallElixir($iWallCost = $g_iWallCost, $bTest = False)

	;Check for elixircolor in right top button corner and click, if present
	Local $FoundElixir = decodeSingleCoord(findImage("UpgradeWallElixir", $g_sImgUpgradeWallElix, GetDiamondFromRect("200, 530, 670, 600"), 1, True, Default))
	If UBound($FoundElixir) > 1 Then
		Click($FoundElixir[0], $FoundElixir[1])
	Else
		SetLog("No Upgrade Elixir Button", $COLOR_ERROR)
		Return False
	EndIf

	If _Sleep($DELAYUPGRADEWALLELIXIR2) Then Return

	If WaitforPixel(670, 140, 690, 150, Hex(0xFFFFFF, 6), 6, 2) Then ; wall upgrade window red x
		If Not $bTest Then
			Click(440, 500, 1, 0, "#0318")
		Else
			SetLog("Testing Only!", $COLOR_ERROR)
			ClickAway()
		EndIf
		If _Sleep(1000) Then Return
		If isGemOpen(True) Then
			SetLog("Upgrade stopped due to insufficient loot", $COLOR_ERROR)
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
EndFunc   ;==>UpgradeWallElixir

Func IsResourceEnough($iWallCost = $g_aUpgradeWall[0])
	Local $EnoughGold = True, $EnoughElix = True
	Switch $g_iUpgradeWallLootType
		Case 0 ; Using gold
			If ($g_aiCurrentLoot[$eLootGold] - $iWallCost) < $g_iUpgradeWallMinGold Then
				If $g_bDebugClick Then SetLog("[Insufficient Gold] " & $g_aiCurrentLoot[$eLootGold] & " - " & $iWallCost & " = " & ($g_aiCurrentLoot[$eLootGold] - $iWallCost) & " < " & $g_iUpgradeWallMinGold, $COLOR_INFO)
				SetLog("Skip Wall upgrade - Insufficient Gold", $COLOR_DEBUG)
				Return False
			EndIf
		Case 1 ; Using elixir
			If ($g_aiCurrentLoot[$eLootElixir] - $iWallCost) < $g_iUpgradeWallMinElixir Then
				If $g_bDebugClick Then SetLog("[Insufficient Elixir] " & $g_aiCurrentLoot[$eLootElixir] & " - " & $iWallCost & " = " & ($g_aiCurrentLoot[$eLootElixir] - $iWallCost) & " < " & $g_iUpgradeWallMinElixir, $COLOR_INFO)
				SetLog("Skip Wall upgrade - Insufficient Elixir", $COLOR_DEBUG)
				Return False
			EndIf
		Case 2 ; Using gold and elixir
			If ($g_aiCurrentLoot[$eLootGold] - $iWallCost) < $g_iUpgradeWallMinGold Then
				If $g_bDebugClick Then SetLog("[Insufficient Gold] " & $g_aiCurrentLoot[$eLootGold] & " - " & $iWallCost & " = " & ($g_aiCurrentLoot[$eLootGold] - $iWallCost) & " < " & $g_iUpgradeWallMinGold, $COLOR_INFO)
				$EnoughGold = False
			EndIf
			If ($g_aiCurrentLoot[$eLootElixir] - $iWallCost) < $g_iUpgradeWallMinElixir Then
				If $g_bDebugClick Then SetLog("[Insufficient Elixir] " & $g_aiCurrentLoot[$eLootElixir] & " - " & $iWallCost & " = " & ($g_aiCurrentLoot[$eLootElixir] - $iWallCost) & " < " & $g_iUpgradeWallMinElixir, $COLOR_INFO)
				$EnoughElix = False
			EndIf
			If Not $EnoughGold And Not $EnoughElix Then
				SetLog("Skip Wall upgrade - Insufficient Gold or Elixir", $COLOR_ERROR)
				Return False
			EndIf
	EndSwitch
	Return True
EndFunc
