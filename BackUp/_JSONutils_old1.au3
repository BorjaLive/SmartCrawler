#include-once
#include <__StringDecode.au3>
#include <_ArrayUtils.au3>
#include <Array.au3>

Global $strict_coma = True
Global $trash = False

Func __InternetGet($url)
	$text = BinaryToString(InetRead($url))
	If $strict_coma Then $text = StringReplace($text,'\"',"'")
	Return ___StringDecode($text)
EndFunc
Func __getJSON()
	Return __getArray()
EndFunc

Func __JSONparse($json)
	$data = __getArray()

	;If StringMid($json,1,8) = '"source"' Then $trash = True
	If $trash Then MsgBox(0,"",$json)
	$partes = ___Split($json)
	;If $trash Then _ArrayDisplay($partes)

	If $partes[0] = 1 Then
		$json = $partes[1]
		If ___isElement($json) Then Return __getArrayInicialzer($json)
		;MsgBox(0,"",$json)
		If ___isAsoc($json) Then
			$idens = ___IdenSplit($json)
			;If $trash Then  MsgBox(0,"Esto es un Asoc",$json)
			;If $trash Then _ArrayDisplay($idens)
			If $idens[0] <> 2 Then Return SetError(1)

			$data = __add($data,$idens[1])
			$idens = __JSONparse($idens[2])
			If @error Then Return SetError(@error)
			$data = __addEx($data,$idens)
		Else
			$data = __addEx($data,__JSONparse($json))
		EndIf
	Else
		For $i = 1 To $partes[0]
			$tmp = __JSONparse($partes[$i])
			If @error Then Return SetError(@error)
			$data = __addEx($data,$tmp)
		Next
	EndIf

	;MsgBox(0,"",$json)
	;If $trash Then _ArrayDisplay($data)
	;tmpRec($data)

	Return $data
EndFunc
Func __JSONgetElement($data, $identifier)
	$identifier = '"'&$identifier&'"'
	If $data[0] = 2 And (Not IsArray($data[1])) And $data[1] = $identifier Then Return $data[2]
	For $i = 1 To $data[0]
		$element = $data[$i]
		If (Not IsArray($element)) or $element[0] <> 2 Then ContinueLoop
		;If $identifier = "media" Then MsgBox(0,"CHECK",$element[1])
		If $element[1] = $identifier Then Return $element[2]
	Next
	Return False
EndFunc
Func __JSONadd($json,$identifier,$data)
	$tmp = __getArray()
	$tmp = __add($tmp,$identifier)
	$tmp = __add($tmp,$data)
	Return __add($json,$tmp)
EndFunc

Func __addEx($array,$element)
	;Bypass
	;Return __add($array,$element)

	If IsArray($element) And $element[0] = 1 Then
		Return __add($array,$element[1])
	Else
		Return __add($array,$element)
	EndIf
EndFunc




Func ___IdenSplit($text)
	$tmp = ""
	$partes = __getArray()

	$interiores = ____obtenerInteriores($text)
	For $i = 1 To StringLen($text)
		$c = StringMid($text,$i,1)
		If (Not $interiores[$i]) And $c = ":" Then
			$partes = __add($partes,$tmp)
			$tmp = ""
		Else
			$tmp &= $c
		EndIf
	Next

	If $tmp Then $partes = __add($partes,$tmp)

	Return $partes
EndFunc
Func ___Split($text)
	$levelA = 0
	$levelB = 0
	$levelC = False
	$partes = __getArray()
	$tmp = ""

	If (StringMid($text,1,1) = "{" And StringMid($text,StringLen($text),1) = "}") or (StringMid($text,1,1) = "[" And StringMid($text,StringLen($text),1) = "]") Then
		$text = StringTrimLeft(StringTrimRight($text,1),1)
		For $i = 1 To StringLen($text)
			$c = StringMid($text,$i,1)
			If $c = "[" Then $levelA += 1
			If $c = "]" Then $levelA -= 1
			If $c = "{" Then $levelB += 1
			If $c = "}" Then $levelB -= 1
			If $c = '"' Then $levelC = Not $levelC
			If $c = "," And $levelA = 0 And $levelB = 0 And $levelC = False Then
				$partes = __add($partes,$tmp)
				$tmp = ""
			Else
				$tmp &= $c
			EndIf
		Next
		If $tmp Then $partes = __add($partes,$tmp)
	Else
		$partes = __add($partes,$text)
	EndIf

	;_ArrayDisplay($partes)
	Return $partes
EndFunc

Func ___isAsoc($text)
	$text = ____eliminarInteriores($text)
	;If $trash Then MsgBox(0,"Sin interiores",$text)
	$count = 0
	For $i = 1 To StringLen($text)
		If StringMid($text,$i,1) = ":" Then $count += 1
	Next
	Return $count = 1
EndFunc
Func ___isElement($text)
	$text = ____eliminarFlechas($text)

	$level = False
	For $i = 1 To StringLen($text)
		$c = StringMid($text,$i,1)
		If $c = '"' Then
			$level = Not $level
		Else
			If $level = False And ($c="{" or $c="}" or $c="[" or $c="]" or $c="," or $c=":") Then Return False
		EndIf
	Next
	;If $trash Then MsgBox(0,"Es elemento",$text)
	Return True
EndFunc
Func ___isString($text); Deprecated
	If StringMid($text,1,1) = '"' And StringMid($text,StringLen($text),1) = '"' Then
		$text = StringTrimLeft(StringTrimRight($text,1),1)
		If StringInStr($text,'"') = 0 Then
			Return $text
		Else
			Return SetError(1)
		EndIf
	Else
		Return SetError(1)
	EndIf
EndFunc

Func ____eliminarFlechas($text)
	$levelFL = False

	For $j = 1 To StringLen($text)
		$del = True
		$c = StringMid($text, $j, 1)
		If $levelFL Then
			$text = StringReplace($text, StringMid($text, $j), StringTrimLeft(StringMid($text, $j), 1))
			$del = False
			$j -= 1
		EndIf
		If $c = '<' Then $levelFL = True
		If $c = '>' Then $levelFL = False
		If $levelFL And $del Then
			$text = StringReplace($text, StringMid($text, $j), StringTrimLeft(StringMid($text, $j), 1))
			$j -= 1
		EndIf
	Next

	Return $text
EndFunc
Func ____eliminarInteriores($text)
	$levelSC = False
	$levelDC = False
	$levelFL = False
	$levelET = 0
	$levelPA = 0
	$levelCO = 0
	;MsgBox(0,"Entra",$text)
	For $j = 1 To StringLen($text)
		$del = True
		$c = StringMid($text, $j, 1)
		If $levelSC Or $levelDC or $levelFL Or $levelPA > 0 Or $levelCO > 0 or $levelET > 0 Then
			$text = StringReplace($text, StringMid($text, $j), StringTrimLeft(StringMid($text, $j), 1))
			$del = False
			$j -= 1
		EndIf
		If $c = "'" And Not $levelDC Then $levelSC = Not $levelSC
		If $c = '"' Then $levelDC = Not $levelDC
		If $c = '<' Then $levelFL = True
		If $c = '>' Then
			$levelFL = False
			$levelET = $levelET=0?1:0;Esto hay que mejorarlo
		EndIf
		If $c = "{" Then $levelPA += 1
		If $c = "}" Then $levelPA -= 1
		If $c = "[" Then $levelCO += 1
		If $c = "]" Then $levelCO -= 1
		If ($levelSC Or $levelDC Or $levelPA > 0 Or $levelCO > 0) And $del Then
			$text = StringReplace($text, StringMid($text, $j), StringTrimLeft(StringMid($text, $j), 1))
			$j -= 1
		EndIf
	Next
	;MsgBox(0,"Sale",$text)
	Return $text
EndFunc
Func ____obtenerInteriores($text)
	$lista = __getArray()

	$levelSC = False
	$levelDC = False
	$levelFL = False
	$levelET = 0
	$levelPA = 0
	$levelCO = 0
	;MsgBox(0,"Entra",$text)
	For $j = 1 To StringLen($text)
		$del = True
		$c = StringMid($text, $j, 1)
		If $levelSC Or $levelDC Or $levelFL Or $levelPA > 0 Or $levelCO > 0 Or $levelET > 0 Then
			$lista = __add($lista, True)
			$del = False
		EndIf
		If $c = "'" And Not $levelDC Then $levelSC = Not $levelSC
		If $c = '"' Then $levelDC = Not $levelDC
		If $c = '<' Then $levelFL = True
		If $c = '>' Then
			$levelFL = False
			$levelET = $levelET=0?1:0;Esto hay que mejorarlo
		EndIf
		If $c = "{" Then $levelPA += 1
		If $c = "}" Then $levelPA -= 1
		If $c = "[" Then $levelCO += 1
		If $c = "]" Then $levelCO -= 1
		If $del Then $lista = __add($lista, $levelSC Or $levelDC or $levelFL Or $levelPA > 0 Or $levelCO > 0 or $levelET > 0)
	Next
	;_ArrayDisplay($lista)
	Return $lista
EndFunc