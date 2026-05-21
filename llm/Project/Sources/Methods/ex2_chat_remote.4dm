//%attributes = {"invisible":true}
#DECLARE($chatCompletionsResult : cs:C1710.AIKit.OpenAIChatCompletionsResult)

If (Count parameters:C259=0)
	
	CALL WORKER:C1389(Current method name:C684; Current method name:C684; {})
	
Else 
	
	If (This:C1470=Null:C1517)
		
		var $agent : cs:C1710._AgentRemote
		$agent:=cs:C1710._AgentRemote.new("OpenAI"; "gpt-5.5")
		
		var $folder : 4D:C1709.Folder
		$folder:=Folder:C1567("/DATA/prompts")
		var $systemPrompt; $userPrompt : Text
		$systemPrompt:=$folder.file("system.txt").getText()
		$userPrompt:=$folder.file("user.txt").getText()
		
		var $messages:=[]
		
		$messages.push({role: "system"; content: $systemPrompt})
		$messages.push({role: "user"; content: $userPrompt})
		
		$agent.api:=Current method name:C684
		$agent.startConversation($messages; Formula from string:C1601(Current method name:C684))
		
	Else 
		
		var $result : Object
		$result:=Try(JSON Parse:C1218(This:C1470.ChatResult; Is object:K8:27))
		
		If ($result#Null:C1517)
			
		End if 
		
	End if 
	
End if 