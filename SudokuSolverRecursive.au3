#include-once
#include <SudokuSolverAuxiliary.au3>
#include <Array.au3>

Func SolveSudokuRecursive($sudokuRowColumn, $sudokuTileClues, $solveSingles, $solveTumors, $solveCables, $solveCycles, $maxCycleDepth)
	; if at an impasse test a clue
	; if clue is incorrect, return false
	; if clue solves sudoku, return the solved sudoku
	Local $recursionStep

	If HasSudokuError($sudokuRowColumn, $sudokuTileClues) Then
		$recursionStep = InitStep($sudokuRowColumn, $sudokuTileClues)
		Return $recursionStep
	EndIf

	While HasClues($sudokuRowColumn, $sudokuTileClues) And Not SudokuCompletedRecursive($sudokuRowColumn) And Not HasSudokuError($sudokuRowColumn, $sudokuTileClues)
		; make copy of clues for use by the pivot element
		$sudokuRowColumnPivot = $sudokuRowColumn
		$sudokuTileCluesPivot = $sudokuTileClues

		; guess a value here
		$pivotElement = ChoosePivotElement($sudokuRowColumnPivot, $sudokuTileCluesPivot)
		$sudokuRowColumnPivot[$pivotElement[1]][$pivotElement[2]] = $pivotElement[0]

		; only needed fot only-recursion test!
		$sudokuTileCluesPivot = CalculateCluesRecursive($sudokuRowColumnPivot, $sudokuTileCluesPivot)

		; inner loop checking the current pivot element
		Local $changeOccured = True
		While $changeOccured
			Local $tmpRecursioStep

			; check for single values
			If $solveSingles Then
				$sudokuTileCluesPivot = CalculateCluesRecursive($sudokuRowColumnPivot, $sudokuTileCluesPivot)
				$tmpRecursioStep = SolveSinglesRecursive($sudokuRowColumnPivot, $sudokuTileCluesPivot)

				$changeOccured = $tmpRecursioStep[0]
				$sudokuRowColumnPivot = $tmpRecursioStep[1]
				$sudokuTileCluesPivot = $tmpRecursioStep[2]
			Else
				$changeOccured = False
			EndIf

			; check for blocks influencing rows/columns
			; two blocks blocking two rows/columns and forcing the row/column for the third block not yet implemented !!!

			If Not $changeOccured And $solveTumors Then
				$sudokuTileCluesPivot = CalculateCluesRecursive($sudokuRowColumnPivot, $sudokuTileCluesPivot)
				$tmpRecursioStep = SolveTumorRecursive($sudokuRowColumnPivot, $sudokuTileCluesPivot)

				$changeOccured = $tmpRecursioStep[0]
				$sudokuRowColumnPivot = $tmpRecursioStep[1]
				$sudokuTileCluesPivot = $tmpRecursioStep[2]
			EndIf

			#cs not yet implemented
			If Not $changeOccured And $solveCables Then
				$sudokuTileCluesPivot = CalculateCluesRecursive($sudokuRowColumnPivot, $sudokuTileCluesPivot)
				$tmpRecursioStep = SolveCableRecursive($sudokuRowColumnPivot, $sudokuTileCluesPivot)

				$changeOccured = $tmpRecursioStep[0]
				$sudokuRowColumnPivot = $tmpRecursioStep[1]
				$sudokuTileCluesPivot = $tmpRecursioStep[2]
			EndIf
			#ce not yet implemented

			If Not $changeOccured And $solveCycles Then
				If Not $solveTumors Or Not $solveCables Then
					$sudokuTileCluesPivot = CalculateCluesRecursive($sudokuRowColumnPivot, $sudokuTileCluesPivot)
				EndIf
				$tmpRecursioStep = SolveCyclesRecursive($maxCycleDepth, $sudokuRowColumnPivot, $sudokuTileCluesPivot)

				If $tmpRecursioStep[0] = Null Then
					$recursionStep = InitStep($sudokuRowColumn, $sudokuTileClues)
					Return $recursionStep
				EndIf

				$changeOccured = $tmpRecursioStep[0]
				$sudokuRowColumnPivot = $tmpRecursioStep[1]
				$sudokuTileCluesPivot = $tmpRecursioStep[2]
			EndIf
		WEnd

		$recursionStep = InitStep($sudokuRowColumnPivot, $sudokuTileCluesPivot)

		; if not solved, try next recursion step, else returned the solved sudoku
		If Not SudokuCompletedRecursive($sudokuRowColumnPivot) Then
			$recursionResult = SolveSudokuRecursive($sudokuRowColumnPivot, $sudokuTileCluesPivot, $solveSingles, $solveTumors, $solveCables, $solveCycles, $maxCycleDepth)
			$recursionStep = SetStepSolution($recursionResult, $recursionStep)
		Else
			$recursionStep[0] = True
			Return $recursionStep
		EndIf

		; if the next recursion step solved the sudoku, return it
		; remove pivot element if recursion step could not solve the sudoku
		If $recursionStep[0] Then
			Return $recursionStep
		Else
			; remove clue
			$sudokuTileClues[$pivotElement[1]][$pivotElement[2]][$pivotElement[0] -1] = False
		EndIf
	WEnd

	Return $recursionStep
EndFunc

Func ChoosePivotElement($sudokuRowColumn, $sudokuTileClues)
	Local $size = UBound($sudokuRowColumn)

	Local $posX = -1
	Local $posY = -1
	Local $pivotValue = -1
	Local $pivotPositionClues
	Local $currentMinClues = $size +1

	For $i = 0 To UBound($sudokuTileClues, 1) -1
		For $j = 0 To UBound($sudokuTileClues, 2) -1
			Local $clueCount = 0
			If Not IsLegalTileValue($sudokuRowColumn[$i][$j], $size) Then
				Local $candidateValue = -1
				Local $candidateValuePositionClues[0]
				For $k = 0 To UBound($sudokuTileClues, 3) -1
					If $sudokuTileClues[$i][$j][$k] Then
						$clueCount += 1
						If $candidateValue > -1 Then
							_ArrayAdd($candidateValuePositionClues, $k)
						Else
							$candidateValue = $k
						EndIf
					EndIf
				Next
				If $clueCount > 0 And $clueCount < $currentMinClues Then
					$posX = $i
					$posY = $j
					$pivotValue = $candidateValue
					$pivotPositionClues = $candidateValuePositionClues
					$currentMinClues = $clueCount
				EndIf
			EndIf
		Next
	Next

	Local $pivotElement[4]
	$pivotElement[0] = $pivotValue +1		; value of the pivot element
	$pivotElement[1] = $posX
	$pivotElement[2] = $posY
	$pivotElement[3] = $pivotPositionClues

	Return $pivotElement
EndFunc

Func CalculateCluesRecursive($sudokuRowColumn, $sudokuTileClues)
	For $i = 0 To UBound($sudokuTileClues, 1) -1
		For $j = 0 To UBound($sudokuTileClues, 2) -1
			$sudokuTileClues = CalculateTileCluesRecursive($sudokuRowColumn, $sudokuTileClues, $i, $j)
		Next
	Next
	Return $sudokuTileClues
EndFunc

Func CalculateTileCluesRecursive($sudokuRowColumn, $sudokuTileClues, $posX, $posY)
	Local $size = UBound($sudokuRowColumn)

	; check if already filled, remove all clues from field
	$tmpValue = $sudokuRowColumn[$posX][$posY]
	If IsLegalTileValue($tmpValue, $size) Then
		For $i = 0 To $size -1
			$sudokuTileClues[$posX][$posY][$i] = False
		Next
		Return $sudokuTileClues
	EndIf

	; check in block, remove clue if value is in block
	$block = CalculateBlockRecursive($sudokuRowColumn, $posX, $posY)
	For $i = 0 To UBound($block, 1) -1
		For $j = 0 To UBound($block, 2) -1
			$tmpValue = $block[$i][$j]
			If IsLegalTileValue($tmpValue, $size) Then
				$sudokuTileClues[$posX][$posY][$tmpValue -1] = False
			EndIf
		Next
	Next

	; check in row, remove clue if value is in row
	For $i = 0 To UBound($sudokuRowColumn, 1) -1
		$tmpValue = $sudokuRowColumn[$i][$posY]
		If IsLegalTileValue($tmpValue, $size) Then
			$sudokuTileClues[$posX][$posY][$tmpValue -1] = False
		EndIf
	Next

	; check in column, remove clue if value is in column
	For $i = 0 To UBound($sudokuRowColumn, 2) -1
		$tmpValue = $sudokuRowColumn[$posX][$i]
		If IsLegalTileValue($tmpValue, $size) Then
			$sudokuTileClues[$posX][$posY][$tmpValue -1] = False
		EndIf
	Next
	Return $sudokuTileClues
EndFunc

Func SolveSinglesRecursive($sudokuRowColumn, $sudokuTileClues)
	Local $recursionStep = InitStep($sudokuRowColumn, $sudokuTileClues)

	; check tiles
	$recursionStep = SetStepSolution(CheckTilesForSinglesRecursive($sudokuRowColumn, $sudokuTileClues), $recursionStep)

	; check block
	$recursionStep = SetStepSolution(CheckBlockForSinglesRecursive($sudokuRowColumn, $sudokuTileClues), $recursionStep)

	; check row
	$recursionStep = SetStepSolution(CheckRowForSinglesRecursive($sudokuRowColumn, $sudokuTileClues), $recursionStep)

	; check column
	$recursionStep = SetStepSolution(CheckColumnForSinglesRecursive($sudokuRowColumn, $sudokuTileClues), $recursionStep)

	Return $recursionStep
EndFunc

Func InitStep($sudokuRowColumn, $sudokuTileClues)
	Local $recursionStep[3]
	$recursionStep[0] = False
	$recursionStep[1] = $sudokuRowColumn
	$recursionStep[2] = $sudokuTileClues
	Return $recursionStep
EndFunc

Func SetStepSolution($tmpStep, $recursionStep)
	If $tmpStep[0] Then
		$recursionStep[0] = $recursionStep[0] Or $tmpStep[0]
		$recursionStep[1] = $tmpStep[1]
		$recursionStep[2] = $tmpStep[2]
	EndIf
	Return $recursionStep
EndFunc

Func CheckTilesForSinglesRecursive($sudokuRowColumn, $sudokuTileClues)
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
				CalculateTileCluesRecursive($sudokuRowColumn, $sudokuTileClues, $i, $j)
				$changeOccured = True
			EndIf
		Next
		CalculateCluesRecursive($sudokuRowColumn, $sudokuTileClues)
	Next
	Local $recursionStep = InitStep($sudokuRowColumn, $sudokuTileClues)
	$recursionStep[0] = $changeOccured
	Return $recursionStep
EndFunc

Func CheckRowForSinglesRecursive($sudokuRowColumn, $sudokuTileClues)
	Local $changeOccured = False
	For $i = 0 To UBound($sudokuTileClues, 1) -1
		For $value = 1 To UBound($sudokuRowColumn, 1)
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
				CalculateTileCluesRecursive($sudokuRowColumn, $sudokuTileClues, $lastPosX, $lastPosY)
				$changeOccured = True
			EndIf
		Next
		CalculateCluesRecursive($sudokuRowColumn, $sudokuTileClues)
	Next
	Local $recursionStep = InitStep($sudokuRowColumn, $sudokuTileClues)
	$recursionStep[0] = $changeOccured
	Return $recursionStep
EndFunc

Func CheckColumnForSinglesRecursive($sudokuRowColumn, $sudokuTileClues)
	Local $changeOccured = False
	For $i = 0 To UBound($sudokuRowColumn, 2) -1
		For $value = 1 To UBound($sudokuRowColumn, 1)
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
				CalculateTileCluesRecursive($sudokuRowColumn, $sudokuTileClues, $lastPosX, $lastPosY)
				$changeOccured = True
			EndIf
		Next
		CalculateCluesRecursive($sudokuRowColumn, $sudokuTileClues)
	Next
	Local $recursionStep = InitStep($sudokuRowColumn, $sudokuTileClues)
	$recursionStep[0] = $changeOccured
	Return $recursionStep
EndFunc

Func CheckBlockForSinglesRecursive($sudokuRowColumn, $sudokuTileClues)
	Local $size = Sqrt(UBound($sudokuRowColumn))
	Local $changeOccured
	; first calculate each block, then check it
	For $i = 0 To $size -1
		For $j = 0 To $size -1
			$posX = $size * $i
			$posY = $size * $j

			$sudokuBlock = CalculateBlockRecursive($sudokuRowColumn, $posX, $posY)
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
			$sudokuRowColumn = WriteBlockToSudokuRecursive($sudokuRowColumn, $sudokuBlock, $posX, $posY)
			CalculateCluesRecursive($sudokuRowColumn, $sudokuTileClues)
		Next
	Next
	Local $recursionStep = InitStep($sudokuRowColumn, $sudokuTileClues)
	$recursionStep[0] = $changeOccured
	Return $recursionStep
EndFunc

Func CalculateBlockRecursive($sudokuRowColumn, $posX, $posY)
	Local $size = Sqrt(UBound($sudokuRowColumn))
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

Func WriteBlockToSudokuRecursive($sudokuRowColumn, $block, $posX, $posY)
	Local $size = Sqrt(UBound($sudokuRowColumn))
	$offsetX = Mod($posX, $size)
	$offsetY = Mod($posY, $size)
	For $i = 0 To UBound($block, 1) -1
		For $j = 0 To UBound($block, 2) -1
			$sudokuRowColumn[$posX + $i - $offsetX][$posY + $j - $offsetY] = $block[$i][$j]
		Next
	Next
	Return $sudokuRowColumn
EndFunc

; check block-rows/-columns blocking sudoku rows/columns
Func SolveTumorRecursive($sudokuRowColumn, $sudokuTileClues)
	Local $size = Sqrt(UBound($sudokuTileClues, 1))
	Local $changeOccured = False
	; check each block for values only in specific block-row/-columns
	; if found, block value for row/column
	; first calculate each block, then check it
	For $i = 0 To $size -1
		For $j = 0 To $size -1
			$posX = $size * $i
			$posY = $size * $j
			For $value = 0 To $size * $size -1
				$inRow = CheckBlockRowsRecursive($sudokuTileClues, $posX, $posY, $value)
				$inColumn = CheckBlockColumnsRecursive($sudokuTileClues, $posX, $posY, $value)
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
	$recursionStep = InitStep($sudokuRowColumn, $sudokuTileClues)
	$recursionStep[0] = $changeOccured
	Return $recursionStep
EndFunc

Func CheckBlockRowsRecursive($sudokuTileClues, $posX, $posY, $value)
	Local $size = Sqrt(UBound($sudokuTileClues))
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

Func CheckBlockColumnsRecursive($sudokuTileClues, $posX, $posY, $value)
	Local $size = Sqrt(UBound($sudokuTileClues))
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

Func SolveCyclesRecursive($maxCycleDepth, $sudokuRowColumn, $sudokuTileClues)
	Local $valueCombination = CalculateNextCycleValues(Null, $maxCycleDepth, UBound($sudokuRowColumn))
	Local $recursionStep = InitStep($sudokuRowColumn, $sudokuTileClues)
	While $valueCombination <> Null
		$recursionStep = SetStepSolution(CheckCyclesInBlockRecursive($valueCombination, $sudokuRowColumn, $sudokuTileClues), $recursionStep)
		If Not $recursionStep[0] = Null Then
			$recursionStep = SetStepSolution(CheckCyclesInRowRecursive($valueCombination, $sudokuRowColumn, $sudokuTileClues), $recursionStep)
		EndIf
		If Not $recursionStep[0] = Null Then
			$recursionStep = SetStepSolution(CheckCyclesInColumnRecursive($valueCombination, $sudokuRowColumn, $sudokuTileClues), $recursionStep)
		EndIf
		If Not $recursionStep[0] = Null Then
			$valueCombination = CalculateNextCycleValues($valueCombination, $maxCycleDepth, UBound($sudokuRowColumn))
		Else
			$valueCombination = Null
		EndIf
	WEnd

	If $recursionStep[0] = Null Then
	EndIf

	Local $recursionStep = InitStep($sudokuRowColumn, $sudokuTileClues)
	Return $recursionStep
EndFunc

Func CheckCyclesInBlockRecursive($valueCombination, $sudokuRowColumn, $sudokuTileClues)
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
						Local $recursionStep = InitStep($sudokuRowColumn, $sudokuTileClues)
						$recursionStep[0] = False
						Return $recursionStep
					EndIf
					If HasCycleValueCluesRecursive($valueCombination, $i * $sudokuSize + $k, $j * $sudokuSize + $l, $sudokuRowColumn, $sudokuTileClues) Then
						$isPossibleCandidateCount += 1

						If $isPossibleCandidateCount -1 < UBound($isPossiblePosX) Then
							$isPossiblePosX[$isPossibleCandidateCount -1] = $i * $sudokuSize + $k
							$isPossiblePosY[$isPossibleCandidateCount -1] = $j * $sudokuSize + $l
						EndIf
					EndIf
					If HasNoCycleValueComplementCluesRecursive($valueCombination, $i * $sudokuSize + $k, $j * $sudokuSize + $l, $sudokuRowColumn, $sudokuTileClues) Then
						$noComplementCandidateCount += 1

						If $noComplementCandidateCount -1 < UBound($noComplementPosX) Then
							$noComplementPosX[$noComplementCandidateCount -1] = $i * $sudokuSize + $k
							$noComplementPosY[$noComplementCandidateCount -1] = $j * $sudokuSize + $l
						EndIf
					EndIf
				Next
			Next

			If $isPossibleCandidateCount < UBound($valueCombination) Or $noComplementCandidateCount > UBound($valueCombination) Then
				Local $recursionStep = InitStep($sudokuRowColumn, $sudokuTileClues)
				$recursionStep[0] = Null
				Return $recursionStep
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
	Local $recursionStep = InitStep($sudokuRowColumn, $sudokuTileClues)
	$recursionStep[0] = $changeOccured
	Return $recursionStep
EndFunc

Func CheckCyclesInRowRecursive($valueCombination, $sudokuRowColumn, $sudokuTileClues)
	Local $changeOccured = False

	For $i = 0 To UBound($sudokuTileClues, 1) -1
		Local $isPossibleCandidateCount = 0
		Local $isPossiblePosY[UBound($valueCombination)]

		Local $noComplementCandidateCount = 0
		Local $noComplementPosY[UBound($valueCombination)]

		For $j = 0 To UBound($sudokuTileClues, 2) -1
			If _ArraySearch($valueCombination, $sudokuRowColumn[$i][$j]) Then
				Local $recursionStep = InitStep($sudokuRowColumn, $sudokuTileClues)
				$recursionStep[0] = False
				Return $recursionStep
			EndIf
			If HasCycleValueCluesRecursive($valueCombination, $i, $j, $sudokuRowColumn, $sudokuTileClues) Then
				$isPossibleCandidateCount += 1

				If $isPossibleCandidateCount -1 < UBound($isPossiblePosY) Then
					$isPossiblePosY[$isPossibleCandidateCount -1] = $j
				EndIf
			EndIf
			If HasNoCycleValueComplementCluesRecursive($valueCombination, $i, $j, $sudokuRowColumn, $sudokuTileClues) Then
				$noComplementCandidateCount += 1

				If $noComplementCandidateCount -1 < UBound($noComplementPosY) Then
					$noComplementPosY[$noComplementCandidateCount -1] = $j
				EndIf
			EndIf
		Next

		If $isPossibleCandidateCount < UBound($valueCombination) Or $noComplementCandidateCount > UBound($valueCombination) Then
			Local $recursionStep = InitStep($sudokuRowColumn, $sudokuTileClues)
			$recursionStep[0] = Null
			Return $recursionStep
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
	Local $recursionStep = InitStep($sudokuRowColumn, $sudokuTileClues)
	$recursionStep[0] = $changeOccured
	Return $recursionStep
EndFunc

Func CheckCyclesInColumnRecursive($valueCombination, $sudokuRowColumn, $sudokuTileClues)
	Local $changeOccured = False

	For $i = 0 To UBound($sudokuTileClues, 2) -1
		Local $isPossibleCandidateCount = 0
		Local $isPossiblePosX[UBound($valueCombination)]

		Local $noComplementCandidateCount = 0
		Local $noComplementPosX[UBound($valueCombination)]

		For $j = 0 To UBound($sudokuTileClues, 1) -1
			If _ArraySearch($valueCombination, $sudokuRowColumn[$j][$i]) Then
				Local $recursionStep = InitStep($sudokuRowColumn, $sudokuTileClues)
				$recursionStep[0] = False
				Return $recursionStep
			EndIf
			If HasCycleValueCluesRecursive($valueCombination, $j, $i, $sudokuRowColumn, $sudokuTileClues) Then
				$isPossibleCandidateCount += 1

				Local $countPosition = 0
				While $countPosition < UBound($isPossiblePosX) And $isPossiblePosX[$countPosition] = -1
					$countPosition += 1
				WEnd
				If $countPosition < UBound($isPossiblePosX) Then
					$isPossiblePosX[$countPosition] = $j
				EndIf
			EndIf
			If HasNoCycleValueComplementCluesRecursive($valueCombination, $j, $i, $sudokuRowColumn, $sudokuTileClues) Then
				$noComplementCandidateCount += 1

				If $noComplementCandidateCount -1 < UBound($noComplementPosX) Then
					$noComplementPosX[$noComplementCandidateCount -1] = $j
				EndIf
			EndIf
		Next

		If $isPossibleCandidateCount < UBound($valueCombination) Or $noComplementCandidateCount > UBound($valueCombination) Then
			Local $recursionStep = InitStep($sudokuRowColumn, $sudokuTileClues)
			$recursionStep[0] = Null
			Return $recursionStep
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
	Local $recursionStep = InitStep($sudokuRowColumn, $sudokuTileClues)
	$recursionStep[0] = $changeOccured
	Return $recursionStep
EndFunc

Func HasCycleValueCluesRecursive($valueCombination, $posX, $posY, $sudokuRowColumn, $sudokuTileClues)
	For $i = 0 To UBound($valueCombination) -1
		If Not IsLegalTileValue($sudokuRowColumn[$posX][$posY], UBound($sudokuRowColumn)) And $sudokuTileClues[$posX][$posY][$valueCombination[$i]] Then
			Return True
		EndIf
	Next
	Return False
EndFunc

Func HasNoCycleValueComplementCluesRecursive($valueCombination, $posX, $posY, $sudokuRowColumn, $sudokuTileClues)
	For $i = 0 To UBound($sudokuTileClues, 3) -1
		If IsLegalTileValue($sudokuRowColumn[$posX][$posY], UBound($sudokuRowColumn)) Or (_ArraySearch($valueCombination, $i) = -1 And $sudokuTileClues[$posX][$posY][$i]) Then
			Return False
		EndIf
	Next
	Return True
EndFunc

Func SudokuCompletedRecursive($sudokuRowColumn)
	Local $size = UBound($sudokuRowColumn)
	Local $isCompleted = True
	For $i = 0 To UBound($sudokuRowColumn, 1) -1
		For $j = 0 To UBound($sudokuRowColumn, 2) -1
			If Not IsLegalTileValue($sudokuRowColumn[$i][$j], $size) Then
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

Func HasSudokuError($sudokuRowColumn, $sudokuTileClues)
	; check all tiles without value, if no clues for empty tile return false
	; else return true
	For $i = 0 To UBound($sudokuRowColumn, 1) -1
		For $j = 0 To UBound($sudokuRowColumn, 2) -1
			If Not IsLegalTileValue($sudokuRowColumn[$i][$j], UBound($sudokuRowColumn)) Then
				Local $hasClue = False
				For $k = 0 To UBound($sudokuTileClues, 3) -1
					$hasClue = $hasClue Or $sudokuTileClues[$i][$j][$k]
				Next
				If Not $hasClue Then
					Return True
				EndIf
			EndIf
		Next
	Next

	Local $size = Sqrt(UBound($sudokuRowColumn))
	; check rows
	For $i = 0 To UBound($sudokuRowColumn, 1) -1
		Local $rowContains[UBound($sudokuRowColumn, 1)]
		For $k = 0 To UBound($rowContains) -1
			$rowContains[$k] = False
		Next
		For $j = 0 To UBound($sudokuRowColumn, 2) -1
			If IsLegalTileValue($sudokuRowColumn[$i][$j], $size * $size) Then
				If $rowContains[$sudokuRowColumn[$i][$j] -1] Then
					Return True
				Else
					$rowContains[$sudokuRowColumn[$i][$j] -1] = True
				EndIf
			EndIf
		Next
	Next

	; check columns
	For $i = 0 To UBound($sudokuRowColumn, 2) -1
		Local $columnContains[UBound($sudokuRowColumn, 1)]
		For $k = 0 To UBound($columnContains) -1
			$columnContains[$k] = False
		Next
		For $j = 0 To UBound($sudokuRowColumn, 1) -1
			If IsLegalTileValue($sudokuRowColumn[$j][$i], $size * $size) Then
				If $columnContains[$sudokuRowColumn[$j][$i] -1] Then
					Return True
				Else
					$columnContains[$sudokuRowColumn[$j][$i] -1] = True
				EndIf
			EndIf
		Next
	Next

	; check blocks
	For $i = 0 To $size -1
		For $j = 0 To $size -1
			$block = CalculateBlockRecursive($sudokuRowColumn, $i, $j)
			Local $blockContains[UBound($sudokuRowColumn, 1)]
			For $k = 0 To UBound($blockContains) -1
				$blockContains[$k] = False
			Next
			For $k = 0 To UBound($block, 1) -1
				For $l = 0 To UBound($block, 2) -1
					If IsLegalTileValue($block[$k][$l], $size * $size) Then
						If $blockContains[$block[$k][$l] -1] Then
							Return True
						Else
							$columnContains[$block[$k][$l] -1] = True
						EndIf
					EndIf
				Next
			Next
		Next
	Next
	Return False
EndFunc

Func HasClues($sudokuRowColumn, $sudokuTileClues)
	Local $size = UBound($sudokuRowColumn)
	For $i = 0 To UBound($sudokuTileClues, 1) -1
		For $j = 0 To UBound($sudokuTileClues, 2) -1
			If Not IsLegalTileValue($sudokuRowColumn[$i][$j], $size) Then
				For $k = 0 To UBound($sudokuTileClues, 3) -1
					If $sudokuTileClues[$i][$j][$k] Then
						Return True
					EndIf
				Next
			EndIf
		Next
	Next
	Return False
EndFunc

Func CountClues($sudokuRowColumn, $sudokuTileClues)
	Local $size = UBound($sudokuRowColumn)
	Local $clueCount = 0
	For $i = 0 To UBound($sudokuTileClues, 1) -1
		For $j = 0 To UBound($sudokuTileClues, 2) -1
			;If Not IsLegalTileValue($sudokuRowColumn[$i][$j], $size) Then
				For $k = 0 To UBound($sudokuTileClues, 3) -1
					If $sudokuTileClues[$i][$j][$k] Then
						$clueCount += 1
					EndIf
				Next
			;EndIf
		Next
	Next
	Return $clueCount
EndFunc