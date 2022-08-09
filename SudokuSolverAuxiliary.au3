#include <Array.au3>
#include <Math.au3>

Func IsLegalTileValue($value, $size)
	If $value >= 1 And $value <= $size Then
		Return True
	Else
		Return False
	EndIf
EndFunc

Func IsLegalSize($size)
	If IsInt(Sqrt($size)) And Sqrt($size) >= 2 And Sqrt($size) <= 5 Then
		Return True
	Else
		Return False
	EndIf
EndFunc

Func CalculateCyclesSize($size, $maxCycleSize)
	Local $cycleSizeSum = 0
	For $i = 2 To $maxCycleSize
		$cycleSizeSum += BinomialCoefficient($size, $i)
	Next
	Return $cycleSizeSum
EndFunc

Func BinomialCoefficient($topValue, $lowerValue)
	If $topValue < $lowerValue Then
		Return -1
	EndIf

	Local $numerator[0]
	Local $denominator[0]

	For $i = _Max($topValue - $lowerValue +1, 2) To $topValue
		_ArrayAdd($numerator, $i)
	Next

	For $i = 2 To $lowerValue
		_ArrayAdd($denominator, $i)
	Next

	Local $primeArray = PrimeNumbersToValue($topValue)
	Local $numeratorPrimeFactors = ArrayIntegerFactorization($numerator)
	Local $denominatorPrimeFactors = ArrayIntegerFactorization($denominator)

	Local $totalPrimeFactors[_Max(UBound($numeratorPrimeFactors), UBound($denominatorPrimeFactors))]
	For $i = 0 To UBound($totalPrimeFactors) -1
		If $i < UBound($numeratorPrimeFactors) And $i < UBound($denominatorPrimeFactors) Then
			$totalPrimeFactors[$i] = $numeratorPrimeFactors[$i] - $denominatorPrimeFactors[$i]
		ElseIf $i >= UBound($numeratorPrimeFactors) Then
			$totalPrimeFactors[$i] = (- $denominatorPrimeFactors[$i])
		Else
			$totalPrimeFactors[$i] = $numeratorPrimeFactors[$i]
		EndIf
	Next

	$result = 1
	For $i = 0 To UBound($primeArray) -1
		If $totalPrimeFactors[$i] > 0 Then
			$result *= PowerOf($primeArray[$i], $totalPrimeFactors[$i])
		ElseIf $totalPrimeFactors[$i] < 0 Then
			$result /= PowerOf($primeArray[$i], $totalPrimeFactors[$i])
		EndIf
	Next
	Return $result
EndFunc

Func ArrayIntegerFactorization($numberArray)
	Local $primeArray = PrimeNumbersToValue(HighestValue($numberArray))
	Local $primeCountArray[UBound($primeArray)]

	For $i = 0 To UBound($numberArray) -1
		Local $primeFactors = IntegerFactorization($numberArray[$i])
		For $j = 0 To UBound($primeFactors) -1
			$primeCountArray[$j] += $primeFactors[$j]
		Next
	Next

	Return $primeCountArray
EndFunc

Func IntegerFactorization($value)
	Local $primeArray = PrimeNumbersToValue($value)
	Local $primeCountArray[UBound($primeArray)]

	For $i = 0 To UBound($primeArray) -1
		While IsDivisor($value, $primeArray[$i])
			$primeCountArray[$i] += 1
			$value /= $primeArray[$i]
		WEnd
		If $value = 1 Then
			Return $primeCountArray
		EndIf
	Next
	Return Null
EndFunc

Func PrimeNumbersToValue($value)
	Local $primeArray[0]

	For $i = 2 To $value
		If IsPrime($i) Then
			_ArrayAdd($primeArray, $i)
		EndIf
	Next
	Return $primeArray
EndFunc

Func IsPrime($value)
	For $i = 2 To $value -1
		If Floor($value / $i) * $i = $value Then
			Return False
		EndIf
	Next
	Return True
EndFunc

Func IsDivisor($value, $divider)
	If Floor($value / $divider) * $divider = $value Then
		Return True
	Else
		Return False
	EndIf
EndFunc

Func HighestValue($numberArray)
	Local $maxValue = 0
	For $i = 0 To UBound($numberArray) -1
		$maxValue = _Max($maxValue, $numberArray[$i])
	Next
	Return $maxValue
EndFunc

Func PowerOf($base, $exponent)
	Local $ret = 1
	For $i = 1 To $exponent
		$ret *= $base
	Next
	Return $ret
EndFunc

Func CalculateNextCycleValues($lastValueCombination, $maxCycleDepth, $sudokuRowSize)
	If $lastValueCombination = Null Or UBound($lastValueCombination) < 2 Then
		Local $startValues[2]
		$startValues[0] = 0
		$startValues[1] = 1
		Return $startValues
	EndIf

	; find the first non-max-value starting from the last number and add 1
	For $i = 1 To UBound($lastValueCombination)
		If $lastValueCombination[UBound($lastValueCombination) -$i] <= $sudokuRowSize -$i Then
			$lastValueCombination[UBound($lastValueCombination) -$i] += 1
			; if found, set all proceeding value to be one greater than the previous value
			For $j = 1 To $i -1
				$lastValueCombination[UBound($lastValueCombination) -$i + $j] = $lastValueCombination[UBound($lastValueCombination) -$i + $j -1] +1
			Next
		EndIf
	Next

	; if all values are at max, reset them to 0,1,...
	For $i = 0 To UBound($lastValueCombination) -1
		$lastValueCombination[$i] = $i
	Next
	; add additinal value, if max depth is not reached yet
	If UBound($lastValueCombination) < $maxCycleDepth Then
		_ArrayAdd($lastValueCombination, UBound($lastValueCombination))
		Return $lastValueCombination
	Else
		Return -1
	EndIf
EndFunc