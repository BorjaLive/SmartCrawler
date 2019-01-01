#include <_JSONutils.au3>
#include <_TCPServer.au3>
#include <Array.au3>
#include <ColorConstantS.au3>
#include <GUIConstants.au3>
#include <GUIConstantsEx.au3>

Const $SERVER_PATH = "http://localhost/search.php"
Const $TANDA_SIZE = 100
Const $LOCAL_SERVER_PORT = 8003
Global $WEB_SELECTED_ITEMS
Global $WEB_SELECTED_JSON
Global $WEB_PROGRESS_BAR
Global $WEB_COUNTER
GLOBAL $WEB_IMG_LIST
Global $DOWNLOAD_FOLDER
Opt("GUIOnEventMode", 1)

#Region GUI
$GUI = GUICreate("SmartCrawler",370,305)
GUISetFont(12, 600)
GUICtrlCreateTab(10, 10, 350, 200)

GUICtrlCreateLabel("Elementos encontrados: ",25,220)
$GUI_total = GUICtrlCreateInput("",225,220,50,20,BitOR($ES_READONLY,$ES_RIGHT))
$GUI_progress = GUICtrlCreateProgress(30,255,310,35)

GUICtrlCreateTabItem("Twitter")
GUICtrlCreateLabel("Nombre de usuario", 30, 50)
$Twitter_user = GUICtrlCreateInput("Dev_Voxy", 25, 70, 200, 25)
$Twitter_all = GUICtrlCreateCheckbox("Descargar todo",25,110)
$Twitter_fast = GUICtrlCreateCheckbox("Seleccionar solo la primera tanda",25,140)
$Twitter_download = GUICtrlCreateButton("Iniciar", 135, 170, 100, 30)

GUICtrlCreateTabItem("DeviantART")
GUICtrlCreateLabel("Sigue soñando, creo que nunca"&@CRLF&"actualizare esto.", 30, 80)


GUISetOnEvent($GUI_EVENT_CLOSE, "salir")
GUICtrlSetOnEvent($Twitter_download, "Twitter")
GUISetState(@SW_SHOW,$GUI)
#EndRegion

While True
	Sleep(10)
WEnd

Func Twitter()
	$img = _getAllTwits(GUICtrlRead($Twitter_user),GUICtrlRead($Twitter_fast) = $GUI_CHECKED, $GUI_total, $GUI_progress)
	$DOWNLOAD_FOLDER = @DesktopDir&"\"&GUICtrlRead($Twitter_user)
	If GUICtrlRead($Twitter_all) = $GUI_CHECKED Then
		_Download($img,$GUI_progress)
	Else
		_WEBselect($img,$GUI_progress)
	EndIf
EndFunc
Func salir()
	Exit
EndFunc


#Region UDF Crawler
	Func _getAllTwits($user, $fast = False, $GUI_count = False, $GUI_bar = False)
		If $GUI_count Then GUICtrlSetData($GUI_count,"0")
		If $GUI_bar Then GUICtrlSetData($GUI_bar,0)

		$img = __getArray()

		$next = ""
		$ini = 1
		$percent_joke = 0
		Do
			$data = __getTwits($user,$next)
			;_ArrayDisplay($data)
			If $data = False Then
				$end = True
				ContinueLoop
			EndIf
			For $i = $ini To $data[0]-1
				$img = __add($img, $data[$i])
			Next
			$ini = 2
			$end = ($next = $data[$data[0]])
			$next = $data[$data[0]]

			If $GUI_count Then GUICtrlSetData($GUI_count,$img[0])
			If $GUI_bar Then
				$percent_joke += $data[0]*2
				While $percent_joke > 100
					$percent_joke -= 100
				WEnd
				GUICtrlSetData($GUI_bar,$percent_joke)
			EndIf
		Until $end or $data[0] = 0 or $fast

		If $GUI_bar Then GUICtrlSetData($GUI_bar,100)
		Return $img
	EndFunc
	Func __getTwits($user,$starter = "")
		$data = __JSONparse(__InternetGet($SERVER_PATH&"?user="&$user&"&num="&$TANDA_SIZE&"&start="&($starter?$starter:"START")))

		$array = __getArray()
		If $data[0] = 0 Then Return False
		For $i = 1 To $data[0]
			$twit = $data[$i]
			If Not IsArray($twit) Then ContinueLoop
			$entities = __JSONgetElement($twit,"extended_entities")
			If Not IsArray($entities) Then ContinueLoop
			$media = __JSONgetElement($entities,"media")
			If Not IsArray($media) Then ContinueLoop
			For $j = 1 To $media[0]
				$url = __JSONgetElement($media[$j],"media_url")
				If $url = False Then ContinueLoop
				$array = __add($array,StringTrimRight(StringTrimLeft($url,1),1))
				;ShellExecute($url)
			Next
		Next
		$twit = $data[$data[0]]
		$id = __JSONgetElement($twit,"id")
		$array = __add($array,$id)

		Return $array
	EndFunc
#EndRegion
#Region WEB server
	Func _WEBselect($list,$GUI_bar = False)
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

		ShellExecute("http://"&@IPAddress1&":"&$LOCAL_SERVER_PORT&"/"&$WEB_IMG_LIST[1]&"?WAIT")
		If $WEB_PROGRESS_BAR Then GUICtrlSetData($WEB_PROGRESS_BAR,0)
	EndFunc
	Func _WEBdownloader($json)
		If $WEB_PROGRESS_BAR Then GUICtrlSetData($WEB_PROGRESS_BAR,0)
		DirCreate($DOWNLOAD_FOLDER)
		For $i = 1 To $json[0]
			$img = $json[$i]
			If $img[2] Then InetGet($img[1],$DOWNLOAD_FOLDER&"/"&StringMid($img[1],StringInStr($img[1],"/",2,-1)))
			If $WEB_PROGRESS_BAR Then GUICtrlSetData($WEB_PROGRESS_BAR,($i/$json[0])*100)
		Next
		MsgBox(0,"Smart Crawler","Operacion terminada con exito.")
	EndFunc
	Func _Download($list,$GUI_bar = False)
		If $WEB_PROGRESS_BAR Then GUICtrlSetData($WEB_PROGRESS_BAR,0)
		DirCreate($DOWNLOAD_FOLDER)
		For $i = 1 To $list[0]
			InetGet($list[$i],$DOWNLOAD_FOLDER&"/"&StringMid($list[$i],StringInStr($list[$i],"/",2,-1)))
			If $WEB_PROGRESS_BAR Then GUICtrlSetData($WEB_PROGRESS_BAR,($i/$list[0])*100)
		Next
		MsgBox(0,"Smart Crawler","Operacion terminada con exito.")
	Endfunc
	Func __WEBrecive($iSocket, $sIP, $sData, $sParam)
	$cImg = StringSplit(StringMid($sData,5,StringInStr($sData," HTTP/1.1")-5),"?")
	If $cImg[0] <> 2 Then Return
	$cSelected = $cImg[2]
	$cImg = $cImg[1]
	If StringMid($cImg,1,1) = "/" Then $cImg = StringTrimLeft($cImg,1)
	If StringMid($cSelected,StringLen($cSelected),1) = "/" Then $cSelected = StringTrimRight($cSelected,1)
	If $cSelected <> "WAIT" Then
		$WEB_SELECTED_JSON = __JSONadd($WEB_SELECTED_JSON,$cImg,$cSelected = "TRUE")
		If $WEB_SELECTED_JSON[0] = $WEB_IMG_LIST[0] Then
			_TCPServer_Send($iSocket, "HTTP/1.0 200 OK" & @CRLF & _
                    "Content-Type: text/html" & @CRLF & @CRLF & _
					'<h1>Terminado</h1>')
			_TCPServer_Close($iSocket)
			Return _WEBdownloader($WEB_SELECTED_JSON)
		Else
			$nImg = $WEB_IMG_LIST[$WEB_COUNTER]
			$WEB_COUNTER += 1
			If $WEB_PROGRESS_BAR Then GUICtrlSetData($WEB_PROGRESS_BAR,($WEB_SELECTED_JSON[0]/$WEB_IMG_LIST[0])*100)
		EndIf

	Else
		$nImg = $cImg
		$nSelected = "WAIT"
	EndIf


    _TCPServer_Send($iSocket, "HTTP/1.0 200 OK" & @CRLF & _
                    "Content-Type: text/html" & @CRLF & @CRLF & _
					'<img src="'&$nImg&'" /><br><hr>' & _
					'<a href="http://'&@IPAddress1&":"&$LOCAL_SERVER_PORT&"/"&$nImg&"?FALSE"&'">'& "RECHAZAR" & '</a> ____' & _
                    '<a href="http://'&@IPAddress1&":"&$LOCAL_SERVER_PORT&"/"&$nImg&"?TRUE"&'">'& "ACEPTAR" & '</a>')
    _TCPServer_Close($iSocket)

EndFunc
#EndRegion

;TODO: Un nuevo boton para reiniciar el servidor web.
;TODO: Un poco que css a las imagenes.