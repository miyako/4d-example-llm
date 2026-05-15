property OpenAI : cs:C1710.AIKit.OpenAI
property tools : Collection
property stream : Boolean
property _onResponse : 4D:C1709.Function
property messages : Collection
property tool_calls : Collection
property text : Text
property reasoning_content : Text
property systemPrompt : Text
property userPrompt : Text

Class constructor($baseURL : Text)
	
	This:C1470.OpenAI:=cs:C1710.AIKit.OpenAI.new({baseURL: $baseURL})
	This:C1470.tools:=cs:C1710.Tools.me.tools
	This:C1470.stream:=True:C214
	
Function clearConversation() : cs:C1710._AgentLocal
	
	This:C1470.text:=""
	This:C1470.messages:=[]
	This:C1470.tool_calls:=[]
	This:C1470.reasoning_content:=""
	
	return This:C1470
	
Function onEventStream($ChatCompletionsResult : cs:C1710.AIKit.OpenAIChatCompletionsResult)
	
	If ($ChatCompletionsResult.errors#Null:C1517) && ($ChatCompletionsResult.errors.length#0)
		Form:C1466.reasoning_content:=$ChatCompletionsResult.errors.extract("message").join("\r")
		return 
	End if 
	
	If ($ChatCompletionsResult.success)
		If ($ChatCompletionsResult.terminated)
			
			If (Form:C1466#Null:C1517)
				OBJECT SET ENABLED:C1123(*; "btn.@"; True:C214)
				
				var $messages : Collection
				$messages:=Form:C1466.messages
				
				Case of 
					: ($ChatCompletionsResult.choice.finish_reason="length")
						Form:C1466.text:="too many tokens!"
					: ($ChatCompletionsResult.choice.finish_reason="stop")
						//success!
					: ($ChatCompletionsResult.choice.finish_reason="tool_calls")
						
						var $tool_call : cs:C1710.AIKit.OpenAITool
						var $Tools:=cs:C1710.Tools.me
						var $arguments : Object
						For each ($tool_call; Form:C1466.tool_calls)
							$arguments:=JSON Parse:C1218($tool_call.function.arguments)
							$tool_call.content:=$Tools[$tool_call.function.name].call(This:C1470; $arguments)
							
							$messages.push({\
								role: "tool"; \
								tool_call_id: $tool_call.id; \
								name: $tool_call.function.name; \
								content: JSON Stringify:C1217($tool_call.content)})
						End for each 
						
						This:C1470.startConversation($messages)
						
				End case 
				
			End if 
			
		Else 
			var $end : Integer
			If ($ChatCompletionsResult.choice.delta.text#Null:C1517)
				
				If (Form:C1466#Null:C1517)
					Form:C1466.text+=$ChatCompletionsResult.choice.delta.text
					$end:=Length:C16(Form:C1466.text)+1
					HIGHLIGHT TEXT:C210(*; "text"; $end; $end)
					If ($ChatCompletionsResult.choice.delta["reasoning_content"]#Null:C1517)
						Form:C1466.reasoning_content+=$ChatCompletionsResult.choice.delta["reasoning_content"]
						$end:=Length:C16(Form:C1466.reasoning_content)+1
						HIGHLIGHT TEXT:C210(*; "reasoning_content"; $end; $end)
					End if 
					If ($ChatCompletionsResult.choice.delta.tool_calls#Null:C1517)
						For each ($tool_call; $ChatCompletionsResult.choice.delta.tool_calls)
							var $tool : Object
							$tool:=Form:C1466.tool_calls.query("index == :1"; $tool_call.index).first()
							If ($tool=Null:C1517)
								$tool:=OB Copy:C1225($tool_call)
								Form:C1466.tool_calls.push($tool)
							Else 
								$tool.function.arguments+=$tool_call.function.arguments
							End if 
						End for each 
					End if 
				End if 
			End if 
		End if 
	End if 
	
Function continueConversation($messages : Collection) : cs:C1710.AIKit.OpenAIChatCompletionsResult
	
	This:C1470.messages.combine($messages)
	
	This:C1470.reasoning_content:=""
	
	If (This:C1470.text#"")
		This:C1470.text+="\r\r"
	End if 
	
	var $ChatCompletionsParameters : cs:C1710.AIKit.OpenAIChatCompletionsParameters
	$ChatCompletionsParameters:=cs:C1710.AIKit.OpenAIChatCompletionsParameters.new(This:C1470)
	$ChatCompletionsParameters.model:=""
	$ChatCompletionsParameters.stream:=This:C1470.stream
	$ChatCompletionsParameters.formula:=This:C1470.onEventStream
	
	//parameters for tool calling
	$ChatCompletionsParameters.temperature:=0.1
	$ChatCompletionsParameters.tool_choice:="auto"
	$ChatCompletionsParameters.tools:=This:C1470.tools
	
	var $ChatCompletionsResult : cs:C1710.AIKit.OpenAIChatCompletionsResult
	$ChatCompletionsResult:=This:C1470.OpenAI.chat.completions.create(This:C1470.messages; $ChatCompletionsParameters)
	
	return $ChatCompletionsResult
	
Function startConversation($messages : Collection; $onResponse : 4D:C1709.Function) : cs:C1710.AIKit.OpenAIChatCompletionsResult
	
	If (OB Instance of:C1731($onResponse; 4D:C1709.Function))
		This:C1470._onResponse:=$onResponse
	Else 
		This:C1470._onResponse:=Null:C1517
	End if 
	
	return This:C1470.clearConversation().continueConversation($messages)
	
Function _isFreshConversation() : Boolean
	
	return This:C1470.messages.length=0