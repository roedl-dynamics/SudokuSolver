#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_Icon=Scissors.ico
#AutoIt3Wrapper_Outfile=..\TruncateDatabaseCruft.exe
#AutoIt3Wrapper_Outfile_x64=..\TruncateDatabaseCruft.exe
#AutoIt3Wrapper_Res_Fileversion=1.0.0.40
#AutoIt3Wrapper_Res_Fileversion_AutoIncrement=y
#AutoIt3Wrapper_Res_CompanyName=Rödl Dynamics GmbH
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****
#cs ----------------------------------------------------------------------------

 AutoIt Version: 3.3.14.5
 Author:         Henryk Ohls

 Script Function:
	GUI for truncating tables.

#ce ----------------------------------------------------------------------------

; Script Start - Add your code below here
#include-once
#include <Array.au3>
#include <SudokuSolverRecursive.au3>	; the recursive part of the sudoku solver

Global $size

; Game Logic
; sudokuRowColumn vs sudokuBlock
Global $sudokuRowColumn[0][0]		; [column][row]

; Clues
Global $sudokuTileClues[0][0][0]

Func GraphicToLogic($sudokuTileGrid)
	$size = Sqrt(UBound($sudokuTileGrid))

	ReDim $sudokuRowColumn[$size * $size][$size * $size]
	ReDim $sudokuTileClues[$size * $size][$size * $size][$size * $size]

	For $i = 0 To UBound($sudokuRowColumn) -1
		For $j = 0 To UBound($sudokuRowColumn) -1
			$sudokuRowColumn[$i][$j] = GUICtrlRead($sudokuTileGrid[$j][$i])
		Next
	Next

	For $i = 0 To UBound($sudokuTileClues, 1) -1
		For $j = 0 To UBound($sudokuTileClues, 2) -1
			For $k = 0 To UBound($sudokuTileClues, 3) -1
				$sudokuTileClues[$i][$j][$k] = True
			Next
		Next
	Next
EndFunc

Func CalculateBlock($posX, $posY)
	Local $blockValues[$size][$size]
	$offsetX = Mod($posX, $size)
	$offsetY = Mod($posY, $size)
	For $i = 0 To UBound($blockValues, 1) -1
		For $j = 0 To UBound($blockValues, 2) -1
			$blockValues[$i][$j] = $sudokuRowColumn[$posX + $i - $offsetX][$posY + $j - $offsetY]
		Next
	Next
	Return $blockValues
EndFunc

Func WriteBlockToSudoku($block, $posX, $posY)
	$offsetX = Mod($posX, $size)
	$offsetY = Mod($posY, $size)
	For $i = 0 To UBound($block, 1) -1
		For $j = 0 To UBound($block, 2) -1
			$sudokuRowColumn[$posX + $i - $offsetX][$posY + $j - $offsetY] = $block[$i][$j]
		Next
	Next
EndFunc

Func SolveSudoku($sudokuTileGrid, $solveSingles, $solveTumors, $solveCables, $solveCycles, $maxCycleDepth)
	GraphicToLogic($sudokuTileGrid)

	; start timer
	Local $calcTimer = TimerInit()

	Local $changeOccured = False
	Do
		; check for single values
		If $solveSingles Then
			CalculateClues()
			$changeOccured = SolveSingles()
		Else
			$changeOccured = False
		EndIf

		; check for blocks influencing rows/columns
		; two blocks blocking two rows/columns and forcing the row/column for the third block not yet implemented !!!
		If Not $changeOccured And $solveTumors Then
			CalculateClues()
			$changeOccured = SolveTumor()
		EndIf

		If Not $changeOccured And $solveCables Then
			CalculateClues()
			$changeOccured = SolveCable()
		EndIf

		If Not $changeOccured And $solveCycles Then
			If Not $solveTumors Or Not $solveCables Then
				CalculateClues()
			EndIf
			$changeOccured = SolveCycles($maxCycleDepth)

			If $changeOccured = Null Then
				Return CreateSudokuReturn($calcTimer)
			EndIf
		EndIf
	Until Not $changeOccured

	Local $recursionResult
	If Not SudokuCompleted() Then
		$recursionResult = SolveSudokuRecursive($sudokuRowColumn, $sudokuTileClues, $solveSingles, $solveTumors, $solveCables, $solveCycles, $maxCycleDepth)

		; use the recursion result
		$sudokuRowColumn = $recursionResult[1]
		$sudokuTileClues = $recursionResult[2]
	EndIf

	; check if finished, return
	; return used time
	Return CreateSudokuReturn($calcTimer)
EndFunc

Func CreateSudokuReturn($calcTimer)
	Local $ret[3]
	$ret[0] = SudokuCompleted()
	$ret[1] = $sudokuRowColumn
	$ret[2] = Round((TimerDiff($calcTimer) / 1000),1)

	Return $ret
EndFunc

Func CalculateClues()
	For $i = 0 To UBound($sudokuTileClues, 1) -1
		For $j = 0 To UBound($sudokuTileClues, 2) -1
			CalculateTileClues($i, $j)
		Next
	Next
EndFunc

Func CalculateTileClues($posX, $posY)

	; check if already filled, remove all clues from field
	$tmpValue = $sudokuRowColumn[$posX][$posY]
	If IsLegalTileValue($tmpValue, $size * $size) Then
		For $i = 0 To $size * $size -1
			$sudokuTileClues[$posX][$posY][$i] = False
		Next
		Return
	EndIf

	; check in block, remove clue if value is in block
	$block = CalculateBlock($posX, $posY)
	For $i = 0 To UBound($block, 1) -1
		For $j = 0 To UBound($block, 2) -1
			$tmpValue = $block[$i][$j]
			If IsLegalTileValue($tmpValue, $size * $size) Then
				$sudokuTileClues[$posX][$posY][$tmpValue -1] = False
			EndIf
		Next
	Next

	; check in row, remove clue if value is in row
	For $i = 0 To UBound($sudokuRowColumn, 1) -1
		$tmpValue = $sudokuRowColumn[$i][$posY]
		If IsLegalTileValue($tmpValue, $size * $size) Then
			$sudokuTileClues[$posX][$posY][$tmpValue -1] = False
		EndIf
	Next

	; check in column, remove clue if value is in column
	For $i = 0 To UBound($sudokuRowColumn, 2) -1
		$tmpValue = $sudokuRowColumn[$posX][$i]
		If IsLegalTileValue($tmpValue, $size * $size) Then
			$sudokuTileClues[$posX][$posY][$tmpValue -1] = False
		EndIf
	Next
EndFunc

Func SolveSingles()
	Local $changeOccured = False

	; check tiles
	$changeOccured = $changeOccured Or CheckTilesForSingles()

	; check block
	$changeOccured = $changeOccured Or CheckBlockForSingles()

	; check row
	$changeOccured = $changeOccured Or CheckRowForSingles()

	; check column
	$changeOccured = $changeOccured Or CheckColumnForSingles()

	Return $changeOccured
EndFunc

Func CheckTilesForSingles()
	Local $changeOccured = False

	For $i = 0 To UBound($sudokuTileClues, 1) -1
		For $j = 0 To UBound($sudokuTileClues, 2) -1
			; check how many clues per tile
			$countClues = 0
			$lastClue = 0
			For $k = 0 To UBound($sudokuTileClues, 3) -1
				If $sudokuTileClues[$i][$j][$k] Then
					$countClues += 1
					$lastClue = $k +1
				EndIf
			Next

			; if exactly one clue, set value and remove tile clues
			If $countClues = 1 Then
				$sudokuRowColumn[$i][$j] = $lastClue
				CalculateTileClues($i, $j)
				$changeOccured = True
			EndIf
		Next
		CalculateClues()
	Next
	Return $changeOccured
EndFunc

Func CheckRowForSingles()
	Local $changeOccured = False
	For $i = 0 To UBound($sudokuTileClues, 1) -1
		For $value = 1 To $size * $size
			$countClues = 0
			$lastPosX = -1
			$lastPosY = -1
			For $j = 0 To UBound($sudokuTileClues, 2) -1
				If $sudokuTileClues[$i][$j][$value -1] Then
					$countClues += 1
					$lastPosX = $i
					$lastPosY = $j
				EndIf
			Next
			; if exactly one clue, set value and remove tile clues
			If $countClues = 1 Then
				$sudokuRowColumn[$lastPosX][$lastPosY] = $value
				CalculateTileClues($lastPosX, $lastPosY)
				$changeOccured = True
			EndIf
		Next
		CalculateClues()
	Next
	Return $changeOccured
EndFunc

Func CheckColumnForSingles()
	Local $changeOccured = False
	For $i = 0 To UBound($sudokuRowColumn, 2) -1
		For $value = 1 To $size * $size
			$countClues = 0
			$lastPosX = -1
			$lastPosY = -1
			For $j = 0 To UBound($sudokuRowColumn, 1) -1
				If $sudokuTileClues[$j][$i][$value -1] Then
					$countClues += 1
					$lastPosX = $j
					$lastPosY = $i
				EndIf
			Next
			If $countClues = 1 Then
				$sudokuRowColumn[$lastPosX][$lastPosY] = $value
				CalculateTileClues($lastPosX, $lastPosY)
				$changeOccured = True
			EndIf
		Next
		CalculateClues()
	Next
	Return $changeOccured
EndFunc

Func CheckBlockForSingles()
	Local $changeOccured = False
	; first calculate each block, then check it
	For $i = 0 To $size -1
		For $j = 0 To $size -1
			$posX = $size * $i
			$posY = $size * $j

			$sudokuBlock = CalculateBlock($posX, $posY)
			For $value = 1 To $size * $size
				$countClues = 0
				$lastPosX = -1
				$lastPosY = -1
				For $k = 0 To UBound($sudokuBlock, 1) -1
					For $l = 0 To UBound($sudokuBlock, 2) -1
						If $sudokuTileClues[$posX + $k][$posY + $l][$value -1] Then
							$countClues += 1
							$lastPosX = $k
							$lastPosY = $l
						EndIf
					Next
				Next
				If $countClues = 1 Then
					$sudokuBlock[$lastPosX][$lastPosY] = $value
					$changeOccured = True
				EndIf
			Next

			; set value
			WriteBlockToSudoku($sudokuBlock, $posX, $posY)
			CalculateClues()
		Next
	Next
	Return $changeOccured
EndFunc

; check block-rows/-columns blocking sudoku rows/columns
Func SolveTumor()
	; check each block for values only in specific block-row/-columns
	; if found, block value for row/column
	Local $changeOccured = False
	; first calculate each block, then check it
	For $i = 0 To $size -1
		For $j = 0 To $size -1
			$posX = $size * $i
			$posY = $size * $j
			For $value = 0 To $size * $size -1
				$inRow = CheckBlockRows($posX, $posY, $value)
				$inColumn = CheckBlockColumns($posX, $posY, $value)
				If $inRow >= 0 Then
					For $k = 0 To UBound($sudokuTileClues, 2) -1
						If $k < $posY Or $k >= $posY +$size Then
							$changeOccured = $changeOccured Or $sudokuTileClues[$posX + $inRow][$k][$value]
							$sudokuTileClues[$posX + $inRow][$k][$value] = False
						EndIf
					Next
				ElseIf $inColumn >= 0 Then
					For $k = 0 To UBound($sudokuTileClues, 1) -1
						If $k < $posX Or $k >= $posX +$size Then
							$changeOccured = $changeOccured Or $sudokuTileClues[$k][$posY + $inColumn][$value]
							$sudokuTileClues[$k][$posY + $inColumn][$value] = False
						EndIf
					Next
				EndIf
			Next
		Next
	Next
	Return $changeOccured
EndFunc

Func CheckBlockRows($posX, $posY, $value)
	$countRows = 0
	$lastRow = -1
	For $i = 0 To $size -1
		$inRow = False
		For $j = 0 To $size -1
			$inRow = $inRow Or $sudokuTileClues[$posX + $i][$posY + $j][$value]
		Next
		If $inRow Then
			$countRows += 1
			$lastRow = $i
		EndIf
	Next
	If $countRows = 1 Then
		Return $lastRow
	Else
		Return -1
	EndIf
EndFunc

Func CheckBlockColumns($posX, $posY, $value)
	$countColumns = 0
	$lastColumn = -1
	For $i = 0 To $size -1
		$inColumn = False
		For $j = 0 To $size -1
			$inColumn = $inColumn Or $sudokuTileClues[$posX + $j][$posY + $i][$value]
		Next
		If $inColumn Then
			$countColumns += 1
			$lastColumn = $i
		EndIf
	Next
	If $countColumns = 1 Then
		Return $lastColumn
	Else
		Return -1
	EndIf
EndFunc

Func SolveCable()

EndFunc

Func CheckDoubleBlockRows()








			; HERE <<<---------------------------------------------------------------------------------------------------------------









EndFunc

Func SolveCycles($maxCycleDepth)
	Local $valueCombination = CalculateNextCycleValues(Null, $maxCycleDepth, UBound($sudokuRowColumn))
	Local $changeOccured
	While $valueCombination <> Null
		$changeOccured = CheckCyclesInBlock($valueCombination)
		If Not $changeOccured = Null Then
			$changeOccured = $changeOccured Or CheckCyclesInRow($valueCombination)
		EndIf
		If Not $changeOccured = Null Then
			$changeOccured = $changeOccured Or CheckCyclesInColumn($valueCombination)
		EndIf
		If Not $changeOccured = Null Then
			$valueCombination = CalculateNextCycleValues($valueCombination, $maxCycleDepth, UBound($sudokuRowColumn))
		Else
			$valueCombination = Null
		EndIf
	WEnd
	Return $changeOccured
EndFunc

Func CheckCyclesInBlock($valueCombination)
	Local $changeOccured = False
	Local $sudokuSize = Sqrt(UBound($sudokuRowColumn, 1))

	For $i = 0 To $sudokuSize -1
		For $j = 0 To $sudokuSize -1
			; here on block level
			Local $isPossibleCandidateCount = 0
			Local $isPossiblePosX[UBound($valueCombination)]
			Local $isPossiblePosY[UBound($valueCombination)]

			Local $noComplementCandidateCount = 0
			Local $noComplementPosX[UBound($valueCombination)]
			Local $noComplementPosY[UBound($valueCombination)]

			For $k = 0 To $sudokuSize -1
				For $l = 0 To $sudokuSize -1
					If _ArraySearch($valueCombination, $sudokuRowColumn[$i * $sudokuSize + $k][$j * $sudokuSize + $l] -1) Then
						Return False
					EndIf
					If HasCycleValueClues($valueCombination, $i * $sudokuSize + $k, $j * $sudokuSize + $l) Then
						$isPossibleCandidateCount += 1

						If $isPossibleCandidateCount -1 < UBound($isPossiblePosX) Then
							$isPossiblePosX[$isPossibleCandidateCount -1] = $i * $sudokuSize + $k
							$isPossiblePosY[$isPossibleCandidateCount -1] = $j * $sudokuSize + $l
						EndIf
					EndIf
					If HasNoCycleValueComplementClues($valueCombination, $i * $sudokuSize + $k, $j * $sudokuSize + $l) Then
						$noComplementCandidateCount += 1

						If $noComplementCandidateCount -1 < UBound($noComplementPosX) Then
							$noComplementPosX[$noComplementCandidateCount -1] = $i * $sudokuSize + $k
							$noComplementPosY[$noComplementCandidateCount -1] = $j * $sudokuSize + $l
						EndIf
					EndIf
				Next
			Next

			If $isPossibleCandidateCount < UBound($valueCombination) Or $noComplementCandidateCount > UBound($valueCombination) Then
				Return Null
			ElseIf $isPossibleCandidateCount = UBound($valueCombination) And $noComplementCandidateCount < UBound($valueCombination) Then
				; remove all complement values from candidate fields
				For $k = 0 To UBound($isPossiblePosX) -1
					For $l = 0 To UBound($sudokuTileClues, 3) -1
						If _ArraySearch($valueCombination, $l) = -1 Then
							$tempPosX = $isPossiblePosX[$k]
							$tempPosY = $isPossiblePosY[$k]
							$changeOccured = $changeOccured Or $sudokuTileClues[$tempPosX][$tempPosY][$l]
							$sudokuTileClues[$tempPosX][$tempPosY][$l] = False
						EndIf
					Next
				Next
			ElseIf $isPossibleCandidateCount > UBound($valueCombination) And $noComplementCandidateCount = UBound($valueCombination) Then
				; remove all combination values from non-candidate fields
				For $k = 0 To $sudokuSize -1
					For $l = 0 To $sudokuSize -1
						If Not _ArraySearch($noComplementPosX, $k) Or Not _ArraySearch($noComplementPosY, $l) Then
							For $m = 0 To UBound($valueCombination) -1
								$changeOccured = $changeOccured Or $sudokuTileClues[$i * $sudokuSize + $k][$j * $sudokuSize + $l][$valueCombination[$m]]
								$sudokuTileClues[$i * $sudokuSize + $k][$j * $sudokuSize + $l][$valueCombination[$m]] = False
							Next
						EndIf
					Next
				Next
			EndIf
		Next
	Next
	Return $changeOccured
EndFunc

Func CheckCyclesInRow($valueCombination)
	Local $changeOccured = False

	For $i = 0 To UBound($sudokuTileClues, 1) -1
		Local $isPossibleCandidateCount = 0
		Local $isPossiblePosY[UBound($valueCombination)]

		Local $noComplementCandidateCount = 0
		Local $noComplementPosY[UBound($valueCombination)]

		For $j = 0 To UBound($sudokuTileClues, 2) -1
			If _ArraySearch($valueCombination, $sudokuRowColumn[$i][$j]) Then
				Return False
			EndIf
			If HasCycleValueClues($valueCombination, $i, $j) Then
				$isPossibleCandidateCount += 1

				If $isPossibleCandidateCount -1 < UBound($isPossiblePosY) Then
					$isPossiblePosY[$isPossibleCandidateCount -1] = $j
				EndIf
			EndIf
			If HasNoCycleValueComplementClues($valueCombination, $i, $j) Then
				$noComplementCandidateCount += 1

				If $noComplementCandidateCount -1 < UBound($noComplementPosY) Then
					$noComplementPosY[$noComplementCandidateCount -1] = $j
				EndIf
			EndIf
		Next

		If $isPossibleCandidateCount < UBound($valueCombination) Or $noComplementCandidateCount > UBound($valueCombination) Then
			Return Null
		ElseIf $isPossibleCandidateCount = UBound($valueCombination) And $noComplementCandidateCount < UBound($valueCombination) Then
			; remove all complement values from candidate fields
			For $j = 0 To UBound($isPossiblePosY) -1
				For $k = 0 To UBound($sudokuTileClues, 3) -1
					If _ArraySearch($valueCombination, $k) = -1 Then
						$changeOccured = $changeOccured Or $sudokuTileClues[$i][$isPossiblePosY[$j]][$k]
						$sudokuTileClues[$i][$isPossiblePosY[$j]][$k] = False
					EndIf
				Next
			Next
		ElseIf $isPossibleCandidateCount > UBound($valueCombination) And $noComplementCandidateCount = UBound($valueCombination) Then
			; remove all combination values from non-candidate fields
			For $j = 0 To UBound($sudokuTileClues, 2) -1
				If Not _ArraySearch($noComplementPosY, $j) Then
					For $k = 0 To UBound($valueCombination) -1
						$changeOccured = $changeOccured Or $sudokuTileClues[$i][$j][$valueCombination[$k]]
						$sudokuTileClues[$i][$j][$valueCombination[$k]] = False
					Next
				EndIf
			Next
		EndIf
	Next
	Return $changeOccured
EndFunc

Func CheckCyclesInColumn($valueCombination)
	Local $changeOccured = False

	For $i = 0 To UBound($sudokuTileClues, 2) -1
		Local $isPossibleCandidateCount = 0
		Local $isPossiblePosX[UBound($valueCombination)]

		Local $noComplementCandidateCount = 0
		Local $noComplementPosX[UBound($valueCombination)]

		For $j = 0 To UBound($sudokuTileClues, 1) -1
			If _ArraySearch($valueCombination, $sudokuRowColumn[$j][$i]) Then
				Return False
			EndIf
			If HasCycleValueClues($valueCombination, $j, $i) Then
				$isPossibleCandidateCount += 1

				Local $countPosition = 0
				While $countPosition < UBound($isPossiblePosX) And $isPossiblePosX[$countPosition] = -1
					$countPosition += 1
				WEnd
				If $countPosition < UBound($isPossiblePosX) Then
					$isPossiblePosX[$countPosition] = $j
				EndIf
			EndIf
			If HasNoCycleValueComplementClues($valueCombination, $j, $i) Then
				$noComplementCandidateCount += 1

				If $noComplementCandidateCount -1 < UBound($noComplementPosX) Then
					$noComplementPosX[$noComplementCandidateCount -1] = $j
				EndIf
			EndIf
		Next

		If $isPossibleCandidateCount < UBound($valueCombination) Or $noComplementCandidateCount > UBound($valueCombination) Then
			Return Null
		ElseIf $isPossibleCandidateCount = UBound($valueCombination) And $noComplementCandidateCount < UBound($valueCombination) Then
			; remove all complement values from candidate fields
			For $j = 0 To UBound($isPossiblePosX) -1
				For $k = 0 To UBound($sudokuTileClues, 3) -1
					If _ArraySearch($valueCombination, $k) = -1 Then
						$changeOccured = $changeOccured Or $sudokuTileClues[$isPossiblePosX[$j]][$i][$k]
						$sudokuTileClues[$isPossiblePosX[$j]][$i][$k] = False
					EndIf
				Next
			Next
		ElseIf $isPossibleCandidateCount > UBound($valueCombination) And $noComplementCandidateCount = UBound($valueCombination) Then
			; remove all combination values from non-candidate fields
			For $j = 0 To UBound($sudokuTileClues, 1) -1
				If Not _ArraySearch($noComplementPosX, $j) Then
					For $k = 0 To UBound($valueCombination) -1
						$changeOccured = $changeOccured Or $sudokuTileClues[$j][$i][$valueCombination[$k]]
						$sudokuTileClues[$j][$i][$valueCombination[$k]] = False
					Next
				EndIf
			Next
		EndIf
	Next
	Return $changeOccured
EndFunc

Func HasCycleValueClues($valueCombination, $posX, $posY)
	For $i = 0 To UBound($valueCombination) -1
		If Not IsLegalTileValue($sudokuRowColumn[$posX][$posY], UBound($sudokuRowColumn)) And $sudokuTileClues[$posX][$posY][$valueCombination[$i]] Then
			Return True
		EndIf
	Next
	Return False
EndFunc

Func HasNoCycleValueComplementClues($valueCombination, $posX, $posY)
	For $i = 0 To UBound($sudokuTileClues, 3) -1
		If IsLegalTileValue($sudokuRowColumn[$posX][$posY], UBound($sudokuRowColumn)) Or (_ArraySearch($valueCombination, $i) = -1 And $sudokuTileClues[$posX][$posY][$i]) Then
			Return False
		EndIf
	Next
	Return True
EndFunc

Func SudokuCompleted()
	Local $isCompleted = True
	For $i = 0 To UBound($sudokuRowColumn, 1) -1
		For $j = 0 To UBound($sudokuRowColumn, 2) -1
			If Not IsLegalTileValue($sudokuRowColumn[$i][$j], $size * $size) Then
				$isCompleted = False
			EndIf
			If Not $isCompleted Then
				$i = UBound($sudokuRowColumn, 1)
				$j = UBound($sudokuRowColumn, 2)
			EndIf
		Next
	Next
	Return $isCompleted
EndFunc