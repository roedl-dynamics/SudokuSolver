#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_Icon=gnomesudoku_104207.ico
#AutoIt3Wrapper_Outfile_x64=SudokuSolver.exe
#AutoIt3Wrapper_UseX64=y
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****
#include-once
#include <GUIConstantsEx.au3>
#include <GuiSlider.au3>				; use slider
#include <GDIPlus.au3>					; do graphics
#include <File.au3>						; read and write .csv
#include <SudokuSolver.au3>

If (DirCreate(@TempDir & '\Scripts\')) Then
	FileInstall(".\SudokuSolverGUI.au3", @TempDir & '\Scripts\SudokuSolverGUI.au3')
	FileInstall(".\SudokuSolver.au3", @TempDir & '\Scripts\SudokuSolver.au3')
	FileInstall(".\SudokuSolverRecursive.au3", @TempDir & '\Scripts\SudokuSolverRecursive.au3')
	FileInstall(".\SudokuSolverAuxiliary.au3", @TempDir & '\Scripts\SudokuSolverAuxiliary.au3')
EndIf

; GUI and graphics elements
Global $linePen, $sudokuSeparationLines, $hGUI

; Sudoku Grid
Global $sudokuSize
Global $sudokuTileGrid[0][0]		; [row][column]

; Buttons
Global $idSolve, $idSolveOnlyRecursion, $idClear, $idLoadCSV, $idSave, $idChangeSize

; Checkbox
Global $idStrategySingles, $idStrategyTumors, $idStrategyCables, $idStrategyCycles
Global $strategySingles, $strategyTumors, $strategyCables, $strategyCycles

; Slider
Global $sliderGameSize
Global $sliderCycleDepth

; Label
Global $idWarning
Global $idCycleCombinations
Global $sliderCycleDepthLabels
Global $depthOfCycle

InitGUI()

Func InitGUI()
	; Start graphics elements
	_GDIPlus_Startup()

	; set start size
	$sudokuSize = 3
	$sudokuSizePerRow = $sudokuSize * $sudokuSize

	; resize Sudoku tile array
	ReDim $sudokuTileGrid[$sudokuSizePerRow][$sudokuSizePerRow]

	DrawGUI()

    ; Loop until the user exits.
    While 1
		; not performend over 25x25 sudokus
		If $sudokuSize <= 5 Then
			CheckSudokuTiles()
		EndIf
		If $sudokuSize > 5 And _IsChecked($idStrategyCycles) Then
			If GUICtrlRead($sliderCycleDepth) < 1 Or GUICtrlRead($sliderCycleDepth) > ($sudokuSize * $sudokuSize / 2) Then
				GUICtrlSetData($sliderCycleDepth, "")
			EndIf
		Endif
        Switch GUIGetMsg()
			Case $idLoadCSV
				LoadCSV()
			Case $idSave
				SaveCSV()
			Case $idClear
				ClearSudokuTiles()
			Case $idChangeSize
				ResizeSudoku()
			Case $idSolve
				CheckSudokuTiles()
				SolveSudokuGUI()
			Case $idStrategyCycles
				If _IsChecked($idStrategyCycles) Then
					$strategyCycles = True
					GUICtrlSetState($sliderCycleDepth, $GUI_SHOW)
					If $sudokuSize <= 5 Then
						For $i = 0 To UBound($sliderCycleDepthLabels) -1
							GUICtrlSetState($sliderCycleDepthLabels[$i], $GUI_SHOW)
						Next
					EndIf
					GUICtrlSetData($idCycleCombinations, CalculateCyclesSize($sudokuSize * $sudokuSize, GUICtrlRead($sliderCycleDepth)) & " combinations")
					GUICtrlSetState($idCycleCombinations, $GUI_SHOW)
					GUICtrlSetState($depthOfCycle, $GUI_SHOW)
				Else
					$strategyCycles = False
					GUICtrlSetState($sliderCycleDepth, $GUI_HIDE)
					If $sudokuSize <= 5 Then
						For $i = 0 To UBound($sliderCycleDepthLabels) -1
							GUICtrlSetState($sliderCycleDepthLabels[$i], $GUI_HIDE)
						Next
					EndIf
					GUICtrlSetState($idCycleCombinations, $GUI_HIDE)
					GUICtrlSetState($depthOfCycle, $GUI_HIDE)
				EndIf
			Case $idStrategySingles
				If _IsChecked($idStrategySingles) Then
					$strategySingles = True
				Else
					$strategySingles = False
				EndIf
			Case $idStrategyTumors
				If _IsChecked($idStrategyTumors) Then
					$strategyTumors = True
				Else
					$strategyTumors = False
				EndIf
			Case $idStrategyCables
				If _IsChecked($idStrategyCables) Then
					$strategyCables = True
				Else
					$strategyCables = False
				EndIf
			Case $sliderCycleDepth
				GUICtrlSetData($idCycleCombinations, CalculateCyclesSize($sudokuSize * $sudokuSize, GUICtrlRead($sliderCycleDepth)) & " combinations")
            Case $GUI_EVENT_CLOSE
				_DeleteTemp()
                ExitLoop
		EndSwitch

					;Case $idSolveOnlyRecursion
				;SolveSudokuOnlyRecursionGUI()
    WEnd

    ; Delete the previous GUI and all controls.
    GUIDelete($hGUI)
	_GDIPlus_PenDispose($linePen)
	_GDIPlus_GraphicsDispose($sudokuSeparationLines)
	_GDIPlus_Shutdown()
EndFunc   ;==>Example

Func DrawGUI()
	; Delete the previous GUI and all controls.
    GUIDelete($hGUI)

	; Create a GUI with various controls.
    $hGUI 							= GUICreate("SudokuSolver", 1600, 1000)

	; Buttons
    $idSolve 						= GUICtrlCreateButton("Solve", 40, 200, 150, 50)
	GUICtrlSetFont($idSolve, 20)
	$idClear						= GUICtrlCreateButton("Clear", 40, 800, 150, 50)
	GUICtrlSetFont($idClear, 20)
	$idLoadCSV 						= GUICtrlCreateButton("Load", 1400, 200, 150, 50)
	GUICtrlSetFont($idLoadCSV, 20)
	$idSave 						= GUICtrlCreateButton("Save", 1400, 400, 150, 50)
	GUICtrlSetFont($idSave, 20)
	$idChangeSize					= GUICtrlCreateButton("Resize", 1400, 800, 150, 50)
	GUICtrlSetFont($idChangeSize, 20)

	; Labels
	If $sudokuSize > 5 Then
		$idWarning					= GUICtrlCreateLabel("WARNING! No auto-check for values at this size!", 1350, 670, 200, 25)
		GUICtrlSetColor($idWarning, 0xFF0000) ; Red
	EndIf

	; Checkbox
	$idStrategySingles = GUICtrlCreateCheckbox("Solve singles", 200, 200, 120, 25)
	GUICtrlSetFont($idStrategySingles, 12)
	If $strategySingles Then
		GUICtrlSetState($idStrategySingles, $GUI_CHECKED)
	EndIf
	$idStrategyTumors = GUICtrlCreateCheckbox("Solve tumors", 200, 230, 120, 25)
	GUICtrlSetFont($idStrategyTumors, 12)
	If $strategyTumors Then
		GUICtrlSetState($idStrategyTumors, $GUI_CHECKED)
	EndIf
	$idStrategyCables = GUICtrlCreateCheckbox("Solve cables", 200, 260, 120, 25)
	GUICtrlSetFont($idStrategyCables, 12)
	If $strategyCables Then
		GUICtrlSetState($idStrategyCables, $GUI_CHECKED)
	EndIf
	$idStrategyCycles = GUICtrlCreateCheckbox("Solve cycles", 200, 290, 120, 25)
	GUICtrlSetFont($idStrategyCycles, 12)
	If $strategyCycles Then
		GUICtrlSetState($idStrategyCycles, $GUI_CHECKED)
	EndIf

	; Slider
	$sliderGameSize = CreateSlider(1350, 700, 7)[0];

	; Input
	CreateSudokuArea(350, 30);

	If $sudokuSize <= 5 Then
		$createSliderCycleDepthResult = CreateSlider(40, 340, Floor($sudokuSize * $sudokuSize / 2))
		$sliderCycleDepth = $createSliderCycleDepthResult[0];
		If Not $strategyCycles Then
			GUICtrlSetState($sliderCycleDepth, $GUI_HIDE)
		EndIf
		If $sudokuSize = 3 Then
			GUICtrlSetData($sliderCycleDepth, 4)
		ElseIf $sudokuSize = 4 Or $sudokuSize = 4 Then
			GUICtrlSetData($sliderCycleDepth, 3)
		Else
			GUICtrlSetData($sliderCycleDepth, 2)
		EndIf
		$sliderCycleDepthLabels = $createSliderCycleDepthResult[1]
		If Not $strategyCycles Then
			For $i = 0 To UBound($sliderCycleDepthLabels) -1
				GUICtrlSetState($sliderCycleDepthLabels[$i], $GUI_HIDE)
			Next
		EndIf
	Else
		$sliderCycleDepth = GUICtrlCreateInput("2", 120, 340, 50, 25)
		GUICtrlSetFont($sliderCycleDepth, 15)
		$countMagnitude = 1
		While Floor(($sudokuSize * $sudokuSize) / 10^$countMagnitude) > 0
			$countMagnitude += 1
		WEnd
		GUICtrlSetLimit($sliderCycleDepth, $countMagnitude)
		If Not $strategyCycles Then
			GUICtrlSetState($sliderCycleDepth, $GUI_HIDE)
		EndIf
	EndIf
	$idCycleCombinations = GUICtrlCreateLabel("", 250, 340, 100, 25)
	$depthOfCycle = GUICtrlCreateLabel("Cycle depth:", 40, 310, 150, 30)
	GUICtrlSetFont($depthOfCycle, 15)
	If Not $strategyCycles Then
		GUICtrlSetState($idCycleCombinations, $GUI_HIDE)
		GUICtrlSetState($depthOfCycle, $GUI_HIDE)
	Else
		GUICtrlSetData($idCycleCombinations, CalculateCyclesSize($sudokuSize * $sudokuSize, GUICtrlRead($sliderCycleDepth)) & " combinations")
	EndIf

    ; Display the GUI.
    GUISetState(@SW_SHOW, $hGUI)
EndFunc

Func CreateSlider($sliderX, $sliderY, $max)
	Local $sliderWidth 			= 200
	Local $sliderHeight 		= 25

	Local $sliderMin			= 2
	Local $sliderMax			= $max
	Local $sliderTic			= 1
	Local $sliderStartValue		= $sudokuSize

	Local $sliderLabelCount 	= Floor(($sliderMax - $sliderMin) / $sliderTic) +1
	Local $sliderLabelWidth 	= 25
	Local $sliderLabelHeight 	= 20
	Local $sliderLabelX			= Floor((($sliderWidth - 30) * $sliderTic) / ($sliderMax - $sliderMin))

	Local $sliderLabelOffsetX	= 10
	Local $sliderLabelOffsetY	= 30

	Local $slider					= GUICtrlCreateSlider($sliderX, $sliderY, $sliderWidth, $sliderHeight);
	GUICtrlSetLimit($slider, $sliderMax, $sliderMin) ; change min/max value
	GUICtrlSetData($slider, $sliderStartValue) ; set cursor

	Local $sliderLabels[0]
	For $i = $sliderMin To $sliderMax + 1
		; Clear overspill flag
		$bOverspill = False
		; Calculate tic value
		; Check if over max
		If $i >= $sliderMax Then
			$bOverspill = True
			$i = $sliderMax
		EndIf

		; Create label
		If $max <= 12 Then
			_ArrayAdd($sliderLabels, GUICtrlCreateLabel($i, $sliderX + $sliderLabelOffsetX + (($i - $sliderMin) * $sliderLabelX), $sliderY + $sliderLabelOffsetY, $sliderLabelWidth, $sliderLabelHeight)) ; Add 10 to allow for unused space at beginning of slider
		Else
			_ArrayAdd($sliderLabels, GUICtrlCreateLabel($i, $sliderX + $sliderLabelOffsetX + (($i - $sliderMin) * $sliderLabelX), $sliderY + $sliderLabelOffsetY, $sliderLabelWidth, $sliderLabelHeight)) ; Add 10 to allow for unused space at beginning of slider
			GUICtrlSetFont(-1, 10)
		EndIf
		; check for overspill
		If $bOverspill Then ExitLoop
	Next

	Local $ret[2]
	$ret[0] = $slider
	$ret[1] = $sliderLabels

	Return $ret
EndFunc

Func CreateSudokuArea($sudokuX, $sudokuY)
	Local $sudokuPixelSize
	Local $separatorSize = 2
	If $sudokuSize == 2 Or $sudokuSize == 3 Or $sudokuSize == 5 Or $sudokuSize = 6 Then
		$sudokuPixelSize = 900
	ElseIf $sudokuSize == 4 Then
		$sudokuPixelSize = 912
	ElseIf $sudokuSize == 7 Then
		$sudokuPixelSize = 931
	EndIf
	Local $sudokuTotalSize = $sudokuPixelSize + $separatorSize * ($sudokuSize -1)
	Local $sudokuTilePerRow	= $sudokuSize * $sudokuSize
	Local $sudokuTileSize	= $sudokuPixelSize / $sudokuTilePerRow

	GUISetState(@SW_SHOW, $hGUI)

	$sudokuSeparationLines = _GDIPlus_GraphicsCreateFromHWND($hGUI)
	$linePen = _GDIPlus_PenCreate(0xFFFF0000, 20)

	; draw lines vertical
	For $i = 1 To $sudokuSize -1
		_GDIPlus_GraphicsDrawLine($sudokuSeparationLines, $sudokuX + $i * $sudokuSize * $sudokuTileSize + ($i - 1) * $separatorSize - 5, $sudokuY, $sudokuX + $i * $sudokuSize * $sudokuTileSize + ($i - 1) * $separatorSize, $sudokuY + $sudokuTotalSize -1, $linePen)
	Next

	; draw lines horizontal
	For $i = 1 To $sudokuSize -1
		_GDIPlus_GraphicsDrawLine($sudokuSeparationLines, $sudokuX, $sudokuY + $i * $sudokuSize * $sudokuTileSize + ($i - 1) * $separatorSize - 5, $sudokuX + $sudokuTotalSize -1, $sudokuY + $i * $sudokuSize * $sudokuTileSize + ($i - 1) * $separatorSize, $linePen)
	Next

	; draw Sudoku tiles
	For $i = 0 To $sudokuTilePerRow -1
		For $j = 0 To $sudokuTilePerRow -1
			Local $sudokuTile = GUICtrlCreateInput("", $sudokuX + $j * $sudokuTileSize + $separatorSize * Mod(Floor($j / $sudokuSize), $sudokuSize), $sudokuY + $i * $sudokuTileSize + $separatorSize * Mod(Floor($i / $sudokuSize), $sudokuSize), $sudokuTileSize, $sudokuTileSize, 0x0001)
			If $sudokuSize < 7 Then
				GUICtrlSetFont($sudokuTile, $sudokuTileSize / 2)
			Else
				GUICtrlSetFont($sudokuTile, 8)
			EndIf
			GUICtrlSetLimit($sudokuTile, CalculateMaxDigits())

			$sudokuTileGrid[$j][$i] = $sudokuTile
		Next
	Next
EndFunc

Func CalculateMaxDigits()
	$countMagnitude = 1
	While Floor(($sudokuSize * $sudokuSize) / 10^$countMagnitude) > 0
		$countMagnitude += 1
	WEnd
	Return $countMagnitude
EndFunc

Func CheckSudokuTiles()
	For $i = 0 To UBound($sudokuTileGrid) -1
		For $j = 0 To UBound($sudokuTileGrid) -1
			If Not StringIsDigit(GUICtrlRead($sudokuTileGrid[$i][$j])) Or Not IsLegalTileValue(GUICtrlRead($sudokuTileGrid[$i][$j]), $sudokuSize * $sudokuSize) Then
				GUICtrlSetData($sudokuTileGrid[$i][$j], "")
			EndIf
		Next
	Next
EndFunc

Func ClearSudokuTiles()
	For $i = 0 To UBound($sudokuTileGrid) -1
		For $j = 0 To UBound($sudokuTileGrid) -1
				GUICtrlSetData($sudokuTileGrid[$i][$j], "")
		Next
	Next
EndFunc

Func ResizeSudoku()
	If $sudokuSize <> GUICtrlRead($sliderGameSize) Then
		$sudokuSize = GUICtrlRead($sliderGameSize)
		$sudokuSizePerRow = $sudokuSize * $sudokuSize

		; resize Sudoku tile array
		ReDim $sudokuTileGrid[$sudokuSizePerRow][$sudokuSizePerRow]
		ClearSudokuTiles()

		DrawGUI()
	EndIf
EndFunc

Func LoadCSV()
	$file = FileOpenDialog("Datei öffnen", @ScriptDir , "CSV Dateien (*.csv)", 1)
	Dim $csvFileLineArray[0]
	Dim $csvFileLineValueArray[0][0]
	_FileReadToArray($file, $csvFileLineArray)
	;RemoveEmptyLines($csvFileLineArray)
	ReDim $csvFileLineValueArray[UBound($csvFileLineArray) -1][UBound($csvFileLineArray) -1]

	$illegalLineLength = False

	For $i = 1 To UBound($csvFileLineArray) -1
		Dim $tmpArray = StringSplit($csvFileLineArray[$i], ";")
		For $j = 1 To UBound($tmpArray) -1
			If $j -1 < UBound($csvFileLineArray) -1 Then
				$csvFileLineValueArray[$i -1][$j -1] = $tmpArray[$j]
			EndIf
		Next
	Next

	If UBound($csvFileLineValueArray, 1) = UBound($csvFileLineValueArray, 2) And IsLegalSize(UBound($csvFileLineValueArray)) Then
		GUICtrlSetData($sliderGameSize, Sqrt(UBound($csvFileLineValueArray)))
		ResizeSudoku()
		For $i = 0 To UBound($csvFileLineValueArray, 2) -1
			For $j = 0 To UBound($csvFileLineValueArray, 2) -1
				GUICtrlSetData($sudokuTileGrid[$i][$j], $csvFileLineValueArray[$j][$i])
			Next
		Next
	Else
		CreateNotice("Illegal size of sudoku!")
	EndIf
EndFunc

Func SaveCSV()
	$file = FileOpenDialog("Datei auswählen", @ScriptDir , "CSV Dateien (*.csv)", 8)
	$file = FileOpen($file, 2)
	FileWrite($file, SudokuToString())
EndFunc

Func SudokuToString()
	Local $sudokuString = ""
	For $i = 0 To UBound($sudokuTileGrid, 1) -1
		For $j = 0 To UBound($sudokuTileGrid, 2) -1
			$sudokuString = $sudokuString & GUICtrlRead($sudokuTileGrid[$j][$i])
			If $j < UBound($sudokuTileGrid, 2) -1 Then
				$sudokuString = $sudokuString & ";"
			EndIf
		Next
		$sudokuString = $sudokuString & @crlf
	Next
	Return $sudokuString
EndFunc

Func SolveSudokuGUI()
	$solution = SolveSudoku($sudokuTileGrid, _IsChecked($idStrategySingles), _IsChecked($idStrategyTumors), _IsChecked($idStrategyCables), _IsChecked($idStrategyCycles), GUICtrlRead($sliderCycleDepth))

	; show time used for calculations
	Local $solutionCalcTime = StringFormat("Calculation done (Sek: %s)", $solution[2])

	LogicToGraphic($solution[1])

	If Not $solution[0] Then
		$solutionCalcTime = "Sudoku cannot be solved!" & @CRLF & $solutionCalcTime
	Else
		$solutionCalcTime = "Sudoku solved!" & @CRLF & $solutionCalcTime
	EndIf
	CreateNotice($solutionCalcTime)
EndFunc

Func LogicToGraphic($solutionSudoku)
	For $i = 0 To $sudokuSize * $sudokuSize -1
		For $j = 0 To $sudokuSize * $sudokuSize -1
			GUICtrlSetData($sudokuTileGrid[$i][$j], $solutionSudoku[$j][$i])
		Next
	Next
EndFunc

Func _IsChecked($idControlID)
        Return BitAND(GUICtrlRead($idControlID), $GUI_CHECKED) = $GUI_CHECKED
EndFunc   ;==>_IsChecked

Func CreateNotice($notice)
	Local $noticeGUI 	= GUICreate("Notice", 200, 100)
	Local $idOK 		= GUICtrlCreateButton("OK", 75, 60, 50, 30)
	Local $noticeLabel	= GUICtrlCreateLabel($notice, 20, 10, 160, 40)

	GUISetState(@SW_SHOW, $noticeGUI)

	While 1
		Switch GUIGetMsg()
			Case $GUI_EVENT_CLOSE, $idOK
				ExitLoop
		EndSwitch
	WEnd

	GUIDelete($noticeGUI)
EndFunc

; Delete files created for execution
Func _DeleteTemp($iDelay = 0)
    Local $sCmdFile
	;DirRemove(@ScriptDir & '\Scripts\', 1)
    FileDelete(@TempDir & "\Scripts\scratch.bat")
    $sCmdFile = 'ping -n ' & $iDelay & '127.0.0.1 > nul' & @CRLF _
            & ':loop' & @CRLF _
            & 'del /s /q "' & @TempDir & '\Scripts"' & @CRLF _
            & 'if exist "' & @TempDir & '\Scripts\Scripts" goto loop' & @CRLF _
            & 'del ' & @TempDir & '\Scripts\scratch.bat'
    FileWrite(@TempDir & "\Scripts\scratch.bat", $sCmdFile)
    Run(@TempDir & "\Scripts\scratch.bat", @TempDir, @SW_HIDE)
EndFunc