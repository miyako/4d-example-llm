property OpenAI : cs:C1710.AIKit.OpenAI
property stream : Boolean
property _onResponse : 4D:C1709.Function
property ChatResult : Text
property messages : Collection
property preemptive : Boolean
property systemPrompt : Text
property userPrompt : Text
property text : Text
property context : Text
property content_type : Text
property register : Text
property max_length : Integer
property do_not_translate : Text
property glossary : Text
property reasoning_content : Text

Class constructor()
	
	This:C1470.preemptive:=Process info:C1843(Current process:C322).preemptive
	
Function _isFreshConversation() : Boolean
	
	return This:C1470.messages.length=0
	
Function clearConversation() : cs:C1710._AgentRemote
	
	This:C1470.ChatResult:=""
	This:C1470.reasoning_content:=""
	This:C1470.messages:=[]
	
	return This:C1470
	