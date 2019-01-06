#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_Icon=resources\icon.ico
#AutoIt3Wrapper_Outfile=SmartCrawler_i386.Exe
#AutoIt3Wrapper_Outfile_x64=SmartCrawler_AMD64Exe.exe
#AutoIt3Wrapper_Compile_Both=y
#AutoIt3Wrapper_UseX64=y
#AutoIt3Wrapper_Res_Description=A mass-downloader for Social media and Image Boards
#AutoIt3Wrapper_Res_Fileversion=0.1.2.2
#AutoIt3Wrapper_Res_Fileversion_AutoIncrement=y
#AutoIt3Wrapper_Res_ProductVersion=0.1.2
#AutoIt3Wrapper_Res_CompanyName=Liveployers
#AutoIt3Wrapper_Res_LegalCopyright=BorjaLive (B0vE)
#AutoIt3Wrapper_Res_LegalTradeMarks=B0vE GNU GPL
#AutoIt3Wrapper_Res_Language=1034
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****
#include <_JSONutils.au3>
#include <_TCPServer.au3>
#include <Array.au3>
#include <ColorConstantS.au3>
#include <GUIConstants.au3>
#include <GUIConstantsEx.au3>

Const $SERVER_PATH = "http://casabore.ddns.net:8003/search.php"
Const $TANDA_SIZE = 100
Const $LOCAL_SERVER_PORT = 8003
Global $WEB_SELECTED_ITEMS
Global $WEB_SELECTED_JSON
Global $WEB_PROGRESS_BAR
Global $WEB_COUNTER
Global $WEB_IMG_LIST
Global $DOWNLOAD_FOLDER
Opt("GUIOnEventMode", 1)

#Region GUI
$GUI = GUICreate("SmartCrawler", 370, 365)
GUISetFont(12, 600)
GUICtrlCreateTab(10, 10, 350, 260)

GUICtrlCreateLabel("Elementos encontrados: ", 25, 280)
$GUI_total = GUICtrlCreateInput("", 225, 280, 50, 20, BitOR($ES_READONLY, $ES_RIGHT))
$GUI_progress = GUICtrlCreateProgress(30, 315, 310, 35)

GUICtrlCreateTabItem("Twitter")
GUICtrlCreateLabel("Nombre de usuario", 30, 50)
$Twitter_user = GUICtrlCreateInput("Dev_Voxy", 25, 70, 200, 25)
$Twitter_all = GUICtrlCreateCheckbox("Descargar sin preguntar", 25, 110)
$Twitter_noFilter = GUICtrlCreateCheckbox("Detectar absolutamente todo", 25, 140)
$Twitter_experimental = GUICtrlCreateCheckbox("Detección rápida (experimental)", 25, 170)
$Twitter_fast = GUICtrlCreateCheckbox("Seleccionar solo la primera tanda", 25, 200)
$Twitter_download = GUICtrlCreateButton("Iniciar", 135, 230, 100, 30)
$Twitter_reload = GUICtrlCreateButton("Reiniciar", 250, 230, 100, 30)

GUICtrlCreateTabItem("DeviantART")
GUICtrlCreateLabel("Sigue soñando, creo que nunca" & @CRLF & "actualizare esto.", 30, 80)


GUISetOnEvent($GUI_EVENT_CLOSE, "salir")
GUICtrlSetOnEvent($Twitter_reload, "_WEBserverRestart")
GUICtrlSetOnEvent($Twitter_download, "Twitter")
GUICtrlSetState($Twitter_reload, $GUI_HIDE)
GUISetState(@SW_SHOW, $GUI)


If Ping("google.com") = 0 Then
	MsgBox(16, "ERROR", "No hay conexión a Internet")
	Exit
EndIf
If Ping("casabore.ddns.net") = 0 Then
	MsgBox(16, "ERROR", "El servidor intermedio está caido")
	Exit
EndIf
#EndRegion GUI

While True
	Sleep(10)
WEnd

Func Twitter()
	GUICtrlSetState($Twitter_download, $GUI_DISABLE)
	$img = _getAllTwits(GUICtrlRead($Twitter_user), GUICtrlRead($Twitter_experimental) = $GUI_CHECKED, GUICtrlRead($Twitter_fast) = $GUI_CHECKED, GUICtrlRead($Twitter_noFilter) = $GUI_CHECKED, $GUI_total, $GUI_progress)
	$DOWNLOAD_FOLDER = @DesktopDir & "\" & GUICtrlRead($Twitter_user)
	If GUICtrlRead($Twitter_all) = $GUI_CHECKED Then
		_Download($img, $GUI_progress)
	Else
		_WEBselect($img, $GUI_progress)
	EndIf
EndFunc   ;==>Twitter
Func salir()
	Exit
EndFunc   ;==>salir


#Region UDF Crawler
Func _getAllTwits($user, $experimental = False, $fast = False, $noFilter = False, $GUI_count = False, $GUI_bar = False)
	If $GUI_count Then GUICtrlSetData($GUI_count, "0")
	If $GUI_bar Then GUICtrlSetData($GUI_bar, 0)

	;Generar configuracion
	$parameters = ""
	If $noFilter Then $parameters &= "[exclude_replies=false[include_rts=true"

	$img = __getArray()

	$next = ""
	$ini = 1
	$percent_joke = 0
	Do
		If $experimental Then
			$data = __getTwitsFast($user, $next, $parameters)
		Else
			$data = __getTwits($user, $next, $parameters)
		EndIf
		;_ArrayDisplay($data)
		If $data = False Then
			$end = True
			ContinueLoop
		EndIf
		For $i = $ini To $data[0] - 1
			$img = __add($img, $data[$i])
		Next
		$ini = 2
		$end = ($next = $data[$data[0]])
		$next = $data[$data[0]]

		If $GUI_count Then GUICtrlSetData($GUI_count, $img[0])
		If $GUI_bar Then
			$percent_joke += $data[0] * 2
			While $percent_joke > 100
				$percent_joke -= 100
			WEnd
			GUICtrlSetData($GUI_bar, $percent_joke)
		EndIf
	Until $end Or $data[0] = 0 Or $fast Or ($data[0] = 1 And $data[1] = "")

	If $GUI_bar Then GUICtrlSetData($GUI_bar, 100)
	Return $img
EndFunc   ;==>_getAllTwits
Func __getTwits($user, $starter = "", $parameters = "")
	$data = __JSONparse(__InternetGet($SERVER_PATH & "?user=" & $user & "&num=" & $TANDA_SIZE & "&start=" & ($starter ? $starter : "START") & "&params=" & ($parameters=""?"NONE":$parameters)))

	$array = __getArray()
	If $data[0] = 0 Then Return False
	For $i = 1 To $data[0]
		$twit = $data[$i]
		If Not IsArray($twit) Then ContinueLoop
		$entities = __JSONgetElement($twit, "extended_entities")
		If Not IsArray($entities) Then ContinueLoop
		$media = __JSONgetElement($entities, "media")
		If Not IsArray($media) Then ContinueLoop
		For $j = 1 To $media[0]
			$url = __JSONgetElement($media[$j], "media_url")
			If $url = False Then ContinueLoop
			$array = __add($array, StringTrimRight(StringTrimLeft($url, 1), 1))
			;ShellExecute($url)
		Next
	Next
	$array = __add($array, __JSONgetElement($data[$data[0]], "id"))

	Return $array
EndFunc   ;==>__getTwits
Func __getTwitsFast($user, $starter = "", $parameters = "")
	$json = __InternetGet($SERVER_PATH & "?user=" & $user & "&num=" & $TANDA_SIZE & "&start=" & ($starter ? $starter : "START") & "&params=" & ($parameters=""?"NONE":$parameters))
	$data = __getArray()

	;Obtener la ultima ID
	$lastID = StringTrimLeft($json, StringInStr($json, '{"created_at":"', 0, -1))
	$lastID = StringMid($lastID, StringInStr($json, '"id":') + 3)
	$lastID = StringMid($lastID, 1, StringInStr($lastID, ',"id_str":"') - 1)

	While StringInStr($json, "media_url") > 0
		$json = StringMid($json, StringInStr($json, '"media_url_https":"') + 19)
		$data = __addXOR($data, StringMid($json, 1, StringInStr($json, '",') - 1))
	WEnd
	$data = __add($data, $lastID)

	;_ArrayDisplay($data)
	Return $data
EndFunc   ;==>__getTwitsFast
#EndRegion UDF Crawler
#Region WEB server
Func _WEBselect($list, $GUI_bar = False)
	$WEB_SELECTED_ITEMS = __getArray()
	$WEB_SELECTED_JSON = __getJSON()
	$WEB_PROGRESS_BAR = $GUI_bar
	$WEB_IMG_LIST = $list

	_TCPServer_OnReceive("__WEBrecive")
	_TCPServer_DebugMode(True)
	_TCPServer_SetMaxClients(10)
	_TCPServer_Start($LOCAL_SERVER_PORT)
	$WEB_COUNTER = 2
	Sleep(500)

	GUICtrlSetState($Twitter_reload, $GUI_SHOW)
	ShellExecute("http://" & @IPAddress1 & ":" & $LOCAL_SERVER_PORT & "/" & $WEB_IMG_LIST[1] & "?WAIT")
	If $WEB_PROGRESS_BAR Then GUICtrlSetData($WEB_PROGRESS_BAR, 0)
EndFunc   ;==>_WEBselect
Func _WEBdownloader($json)
	If $WEB_PROGRESS_BAR Then GUICtrlSetData($WEB_PROGRESS_BAR, 0)
	GUICtrlSetState($Twitter_reload, $GUI_HIDE)
	DirCreate($DOWNLOAD_FOLDER)
	For $i = 1 To $json[0]
		$img = $json[$i]
		If $img[2] Then InetGet($img[1], $DOWNLOAD_FOLDER & "/" & StringMid($img[1], StringInStr($img[1], "/", 2, -1)))
		If $WEB_PROGRESS_BAR Then GUICtrlSetData($WEB_PROGRESS_BAR, ($i / $json[0]) * 100)
	Next
	MsgBox(0, "Smart Crawler", "Operacion terminada con exito.")
	GUICtrlSetState($Twitter_download, $GUI_ENABLE)
EndFunc   ;==>_WEBdownloader
Func _Download($list, $GUI_bar = False)
	If $WEB_PROGRESS_BAR Then GUICtrlSetData($WEB_PROGRESS_BAR, 0)
	DirCreate($DOWNLOAD_FOLDER)
	For $i = 1 To $list[0]
		InetGet($list[$i], $DOWNLOAD_FOLDER & "/" & StringMid($list[$i], StringInStr($list[$i], "/", 2, -1)))
		If $WEB_PROGRESS_BAR Then GUICtrlSetData($WEB_PROGRESS_BAR, ($i / $list[0]) * 100)
	Next
	MsgBox(0, "Smart Crawler", "Operacion terminada con exito.")
	GUICtrlSetState($Twitter_download, $GUI_ENABLE)
EndFunc   ;==>_Download
Func __WEBrecive($iSocket, $sIP, $sData, $sParam)
	$cImg = StringSplit(StringMid($sData, 5, StringInStr($sData, " HTTP/1.1") - 5), "?")
	If $cImg[0] <> 2 Then Return
	$cSelected = $cImg[2]
	$cImg = $cImg[1]
	If StringMid($cImg, 1, 1) = "/" Then $cImg = StringTrimLeft($cImg, 1)
	If StringMid($cSelected, StringLen($cSelected), 1) = "/" Then $cSelected = StringTrimRight($cSelected, 1)
	If $cSelected <> "WAIT" Then
		$WEB_SELECTED_JSON = __JSONadd($WEB_SELECTED_JSON, $cImg, $cSelected = "TRUE")
		If $WEB_SELECTED_JSON[0] = $WEB_IMG_LIST[0] Then
			_TCPServer_Send($iSocket, "HTTP/1.0 200 OK" & @CRLF & _
					"Content-Type: text/html" & @CRLF & @CRLF & _
					'<h1>Terminado</h1>')
			_TCPServer_Close($iSocket)
			Return _WEBdownloader($WEB_SELECTED_JSON)
		Else
			$nImg = $WEB_IMG_LIST[$WEB_COUNTER]
			$WEB_COUNTER += 1
			If $WEB_PROGRESS_BAR Then GUICtrlSetData($WEB_PROGRESS_BAR, ($WEB_SELECTED_JSON[0] / $WEB_IMG_LIST[0]) * 100)
			If Mod($WEB_COUNTER, 9) = 0 Then _WEBserverRestart()
		EndIf

	Else
		$nImg = $cImg
		$nSelected = "WAIT"
	EndIf

	$type = StringMid($nImg, StringLen($nImg) - 2)
	If $type = "jpg" Or $type = "png" Or $type = "gif" Or $type = "ebp" Then
		$media = '<img style="width: auto;height: 80%;margin-left: auto;margin-right: auto;display: block;" src="' & $nImg & '" /><br><hr>'
	ElseIf $type = "mp4" Then
		$media = '<video style="width: auto;height: 80%;margin-left: auto;margin-right: auto;display: block;" controls><source src="' & $nImg & '" type="video/mp4">ERROR</video>'
	EndIf

	_TCPServer_Send($iSocket, "HTTP/1.0 200 OK" & @CRLF & _
			"Content-Type: text/html" & @CRLF & @CRLF & _
			$media & _
			'<div botones style="text-align: center;"><a href="http://' & @IPAddress1 & ":" & $LOCAL_SERVER_PORT & "/" & $nImg & "?FALSE" & '">' & "RECHAZAR" & '</a> ____ ' & _
			'<a href="http://' & @IPAddress1 & ":" & $LOCAL_SERVER_PORT & "/" & $nImg & "?TRUE" & '">' & "ACEPTAR" & '</a></div>')
	_TCPServer_Close($iSocket)

EndFunc   ;==>__WEBrecive
Func _WEBserverRestart()
	GUICtrlSetState($Twitter_reload, $GUI_DISABLE)
	_TCPServer_Stop()
	Sleep(500)
	_TCPServer_OnReceive("__WEBrecive")
	_TCPServer_DebugMode(True)
	_TCPServer_SetMaxClients(10)
	_TCPServer_Start($LOCAL_SERVER_PORT)
	GUICtrlSetState($Twitter_reload, $GUI_ENABLE)
EndFunc   ;==>_WEBserverRestart
#EndRegion WEB server

;TODO: Un modo para buscar twits rápidamente.
