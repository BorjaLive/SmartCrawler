Func __getArray()
	Local $array[1]
	$array[0] = 0
	Return $array
EndFunc   ;==>__getArray
Func __getArrayInicialzer($element)
	Local $array[2]
	$array[0] = 1
	$array[1] = $element
	Return $array
EndFunc   ;==>__getArrayInicialzer

Func __add($array, $element)
	ReDim $array[UBound($array) + 1]
	$array[UBound($array) - 1] = $element
	$array[0] += 1
	Return $array
EndFunc   ;==>__add

Func __addXOR($array, $element)
	If __ArrayContains($array, $element) Then Return $array
	ReDim $array[UBound($array) + 1]
	$array[UBound($array) - 1] = $element
	$array[0] += 1
	Return $array
EndFunc   ;==>__addXOR

Func __addList($array, $list)
	If Not IsArray($list) Then Return $array
	For $i = 1 To $list[0]
		$array = __add($array, $list[$i])
	Next
	Return $array
EndFunc   ;==>__addList

Func __addListXOR($array, $list)
	If Not IsArray($list) Then Return $array
	For $i = 1 To $list[0]
		If Not __ArrayContains($array, $list[$i], True) Then $array = __add($array, $list[$i])
	Next
	Return $array
EndFunc   ;==>__addListXOR

Func __remove($array, $n = 1)
	For $i = 1 To $n
		ReDim $array[UBound($array) - 1]
		$array[0] -= 1
		Return $array
	Next
	Return $array
EndFunc   ;==>__remove

Func __compareArray($array1, $array2)
	If Not IsArray($array1) Or Not IsArray($array2) Then Return False
	If $array1[0] <> $array2[0] Then Return False
	For $i = 1 To $array1[0]
		If IsArray($array1[$i]) And IsArray($array2[$i]) And Not __compareArray($array1[$i], $array2[$i]) Then Return False
		If $array1[$i] <> $array2[$i] Then Return False
	Next
	Return True
EndFunc   ;==>__compareArray

Func __ArrayContains($array, $element, $isSubArray = False)
	For $i = 1 To $array[0]
		If $isSubArray Then
			If __compareArray($array[$i], $element) Then Return True
		Else
			If $array[$i] = $element Then Return True
		EndIf
	Next
	Return False
EndFunc   ;==>__ArrayContains

Func __ArrayContainsSubStringPart($array, $part)
	For $i = 1 To $array[0]
		$element = $array[$i]
		For $j = 1 To $part[0]
			If $element[$j] <> $part[$j] Then ContinueLoop 2
		Next
		Return True
	Next
	Return False
EndFunc   ;==>__ArrayContainsSubStringPart
