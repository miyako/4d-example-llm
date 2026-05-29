//%attributes = {"invisible":true}
#DECLARE($params : Object)

If (Count parameters:C259=0)
	
	CALL WORKER:C1389(1; Current method name:C684; {})
	
Else 
	
	var $agent : cs:C1710._AgentLocal
	$agent:=cs:C1710._AgentLocal.new("http://127.0.0.1:"+String:C10(Storage:C1525.chat.port)+"/v1")
	$agent.systemPrompt:="The tools return information about about the current OS and database application. Use them to statisfy the user's requests."
	$agent.userPrompt:="Tell me about the current OS and database application."
	
	var $window : Integer
	$window:=Open form window:C675("LocalLLM")
	DIALOG:C40("LocalLLM"; $agent; *)
	
End if 