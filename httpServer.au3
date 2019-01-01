#cs
    Run this script
    Point your browser to http://localhost:8082/
#ce

#include "_TCPServer.au3"

_TCPServer_OnReceive("received")

_TCPServer_DebugMode(True)
_TCPServer_SetMaxClients(10)

_TCPServer_Start(8002)
;_TCPServer_Close()

Global $IMG = "https://pbs.twimg.com/media/DvrCNXkUUAEFrf4.png"


Func received($iSocket, $sIP, $sData, $sParam)
	$dPos = StringMid($sData,5,StringInStr($sData," HTTP/1.1")-5)

    _TCPServer_Send($iSocket, "HTTP/1.0 200 OK" & @CRLF & _
                    "Content-Type: text/html" & @CRLF & @CRLF & _
					"<p>" & $dPos & "</p>" & _
					"<p>" & $sParam & "</p>" & _
                    "<p>"&$sIP&"</p>")
    _TCPServer_Close($iSocket)

EndFunc   ;==>received

While 1
    Sleep(100)
WEnd