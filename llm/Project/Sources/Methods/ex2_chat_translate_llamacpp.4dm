//%attributes = {}
#DECLARE($params : Object)

If (Count parameters:C259=0)
	
	CALL WORKER:C1389(1; Current method name:C684; {})
	
Else 
	
	var $agent : cs:C1710._AgentLocal
	$agent:=cs:C1710._AgentLocal.new("http://127.0.0.1:"+String:C10(Storage:C1525.chat.port)+"/v1")
	
	var $folder : 4D:C1709.Folder
	$folder:=Folder:C1567("/DATA/prompts")
	var $systemPrompt; $userPrompt : Text
	$systemPrompt:=$folder.file("system.txt").getText()
	$userPrompt:=$folder.file("user.txt").getText()
	
	$agent.systemPrompt:=$systemPrompt
	$agent.userPrompt:=$userPrompt
	$agent.text:="Open 4D Web Server Advanced Settings"
	$agent.context:="desktop application called \"4D\""
	$agent.content_type:="user interface"
	$agent.register:="modern"
	$agent.max_length:=50
	$agent.do_not_translate:="4D"
	$agent.glossary:=""
	
	var $window : Integer
	$window:=Open form window:C675("LLM")
	SET WINDOW TITLE:C213(Split string:C1554(Current method name:C684; "_").last(); $window)
	DIALOG:C40("LLM"; $agent; *)
	
End if 