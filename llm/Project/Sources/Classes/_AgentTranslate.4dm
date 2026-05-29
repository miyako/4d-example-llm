property vi : Object
property id : Object
property si : Object
property ta : Object

Class extends _Agent

Class constructor()
	
	Super:C1705()
	
Function onTranslate($chatCompletionsResult : cs:C1710.AIKit.OpenAIChatCompletionsResult)
	
	If (Form:C1466=Null:C1517)
		return 
	End if 
	
	OBJECT SET ENABLED:C1123(*; "btn.@"; True:C214)
	
	var $data : Object
	$data:=Try(JSON Parse:C1218(This:C1470.ChatResult; Is object:K8:27))
	
	If ($data=Null:C1517)
		return 
	End if 
	
	Form:C1466.vi:=$data.translations.vi
	Form:C1466.id:=$data.translations.id
	Form:C1466.si:=$data.translations.si
	Form:C1466.ta:=$data.translations.ta