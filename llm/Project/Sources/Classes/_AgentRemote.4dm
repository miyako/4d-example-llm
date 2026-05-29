property provider : Text
property model : Text

Class extends _AgentTranslate

Class constructor($provider : Text; $model : Text)
	
	Super:C1705()
	
	var $OpenAI : cs:C1710.RemoteLLM
	$OpenAI:=cs:C1710.RemoteLLM.new($provider)
	var $baseURL; $apiKey : Text
	$baseURL:=$OpenAI.endpoint
	$apiKey:=$OpenAI.getAccessToken($provider)
	This:C1470.stream:=True:C214
	This:C1470.model:=$model
	This:C1470.provider:=$provider
	This:C1470.OpenAI:=cs:C1710.AIKit.OpenAI.new({baseURL: $baseURL; apiKey: $apiKey})
	
Function continueConversation($messages : Collection) : cs:C1710.AIKit.OpenAIChatCompletionsResult
	
	If (This:C1470.messages.length=0)
		This:C1470.messages.push({role: "system"; content: This:C1470.systemPrompt})
	End if 
	
	var $userPrompt : Text
	$userPrompt:=This:C1470.userPrompt
	PROCESS 4D TAGS:C816($userPrompt; $userPrompt; This:C1470)
	
	This:C1470.messages.push({role: "user"; content: $userPrompt})
	
	This:C1470.reasoning_content:=""
	
	This:C1470.vi:=Null:C1517
	This:C1470.id:=Null:C1517
	This:C1470.si:=Null:C1517
	This:C1470.ta:=Null:C1517
	
	If (This:C1470.ChatResult#"")
		This:C1470.ChatResult+="\r\r"
	End if 
	
	var $ChatCompletionsParameters : cs:C1710.AIKit.OpenAIChatCompletionsParameters
	$ChatCompletionsParameters:=cs:C1710.AIKit.OpenAIChatCompletionsParameters.new(This:C1470)
	$ChatCompletionsParameters.model:=This:C1470.model
	$ChatCompletionsParameters.stream:=This:C1470.stream
	$ChatCompletionsParameters.formula:=This:C1470.onEventStream
	
	var $response_format:={type: "json_schema"; json_schema: {}}
	$response_format.json_schema:={}
	$response_format.json_schema.name:="Translation"
	$response_format.json_schema.strict:=True:C214
	$response_format.json_schema.schema:={}
	$response_format.json_schema.schema.type:="object"
	$response_format.json_schema.schema.required:=["source_language"; "source_text"; "translations"]
	$response_format.json_schema.schema.additionalProperties:=False:C215
	$response_format.json_schema.schema.properties:={}
	
	// source_language
	$response_format.json_schema.schema.properties.source_language:={}
	$response_format.json_schema.schema.properties.source_language.type:="string"
	$response_format.json_schema.schema.properties.source_language.enum:=["ja"; "en"]
	
	// source_text
	$response_format.json_schema.schema.properties.source_text:={}
	$response_format.json_schema.schema.properties.source_text.type:="string"
	
	// translations (object with 4 language keys)
	$response_format.json_schema.schema.properties.translations:={}
	$response_format.json_schema.schema.properties.translations.type:="object"
	$response_format.json_schema.schema.properties.translations.required:=["vi"; "id"; "si"; "ta"]
	$response_format.json_schema.schema.properties.translations.additionalProperties:=False:C215
	$response_format.json_schema.schema.properties.translations.properties:={}
	
	// translation entry schema (reused for each language)
	var $entry:={}
	$entry.type:="object"
	$entry.required:=["text"; "notes"]
	$entry.additionalProperties:=False:C215
	$entry.properties:={}
	$entry.properties.text:={type: "string"}
	$entry.properties.notes:={type: "string"}
	
	$response_format.json_schema.schema.properties.translations.properties.vi:=$entry
	$response_format.json_schema.schema.properties.translations.properties.id:=$entry
	$response_format.json_schema.schema.properties.translations.properties.si:=$entry
	$response_format.json_schema.schema.properties.translations.properties.ta:=$entry
	
	$ChatCompletionsParameters.response_format:=$response_format
	
	var $ChatCompletionsResult : cs:C1710.AIKit.OpenAIChatCompletionsResult
	$ChatCompletionsResult:=This:C1470.OpenAI.chat.completions.create(This:C1470.messages; $ChatCompletionsParameters)
	
	return $ChatCompletionsResult
	
Function startConversation($onResponse : 4D:C1709.Function) : cs:C1710.AIKit.OpenAIChatCompletionsResult
	
	If (OB Instance of:C1731($onResponse; 4D:C1709.Function))
		This:C1470._onResponse:=$onResponse
	Else 
		This:C1470._onResponse:=Null:C1517
	End if 
	
	return This:C1470.clearConversation().continueConversation()
	
Function onCompletion($chatCompletionsResult : cs:C1710.AIKit.OpenAIChatCompletionsResult)
	
	If (OB Instance of:C1731(This:C1470._onResponse; 4D:C1709.Function))
		This:C1470._onResponse.call(This:C1470; $chatCompletionsResult)
	End if 
	
Function onEventStream($chatCompletionsResult : cs:C1710.AIKit.OpenAIChatCompletionsResult)
	
	If ($chatCompletionsResult.success)
		If ($chatCompletionsResult.terminated)
			//complete result
			If ($chatCompletionsResult.choice#Null:C1517)
				If ($chatCompletionsResult.choice.message=Null:C1517)  //streaming
					$chatCompletionsResult:=JSON Parse:C1218(JSON Stringify:C1217($chatCompletionsResult))
					$chatCompletionsResult.choice.message:={role: "assistant"; content: This:C1470.ChatResult}
				Else   //not streaming
					If ($chatCompletionsResult.choice.message.content#Null:C1517)
						This:C1470.ChatResult+=$chatCompletionsResult.choice.message.content
					End if 
				End if 
				This:C1470.messages.push($chatCompletionsResult.choice.message)
			Else 
				
			End if 
			This:C1470.onCompletion($chatCompletionsResult)
		Else 
			//partial result
			If ($chatCompletionsResult.choice#Null:C1517)
				If ($chatCompletionsResult.choice.delta.text#"")
					
					If (This:C1470.reasoning_content#"")
						This:C1470.reasoning_content:=""
						This:C1470.ChatResult:=This:C1470.reasoning_content
					End if 
					This:C1470.ChatResult+=$chatCompletionsResult.choice.delta.text
				Else 
					If ($chatCompletionsResult.choice.delta["reasoning_content"]#Null:C1517)
						This:C1470.reasoning_content+=$chatCompletionsResult.choice.delta["reasoning_content"]
						This:C1470.ChatResult:=This:C1470.reasoning_content
					End if 
				End if 
			Else 
			End if 
		End if 
	Else 
		If ($chatCompletionsResult.terminated)
			This:C1470.ChatResult+=$chatCompletionsResult.errors.extract("message").join("\r")
			DELAY PROCESS:C323(Current process:C322; 60*30)
			If (OB Instance of:C1731(This:C1470._onResponse; 4D:C1709.Function))
				This:C1470._onResponse.call(This:C1470; $chatCompletionsResult)
			End if 
		End if 
	End if 
	
	