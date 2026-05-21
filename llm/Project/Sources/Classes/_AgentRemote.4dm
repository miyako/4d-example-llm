property OpenAI : cs:C1710.AIKit.OpenAI
property ChatResult : Text
property model : Text
property preemptive : Boolean
property messages : Collection
property _onResponse : 4D:C1709.Function
property stream : Boolean
property reasoning_content : Text
property apiKey : Text
property provider : Text
property task : Text
property name : Text
property api : Text
property passage : Text
property query : Text
property passage_hash : Text
property query_hash : Text
property file : 4D:C1709.File

Class constructor($provider : Text; $model : Text)
	
	var $OpenAI : cs:C1710.RemoteLLM
	$OpenAI:=cs:C1710.RemoteLLM.new($provider)
	var $baseURL; $apiKey : Text
	$baseURL:=$OpenAI.endpoint
	$apiKey:=$OpenAI.getAccessToken($provider)
	This:C1470.stream:=True:C214
	This:C1470.model:=$model
	This:C1470.provider:=$provider
	This:C1470.OpenAI:=cs:C1710.AIKit.OpenAI.new({baseURL: $baseURL; apiKey: $apiKey})
	This:C1470.preemptive:=Process info:C1843(Current process:C322).preemptive
	
Function clearConversation() : cs:C1710._AgentRemote
	
	This:C1470.ChatResult:=""
	This:C1470.reasoning_content:=""
	This:C1470.messages:=[]
	
	return This:C1470
	
Function continueConversation($messages : Collection) : cs:C1710.AIKit.OpenAIChatCompletionsResult
	
	This:C1470.messages.combine($messages)
	
	This:C1470.reasoning_content:=""
	
	If (This:C1470.ChatResult#"")
		This:C1470.ChatResult+="\r\r"
	End if 
	
	var $ChatCompletionsParameters : cs:C1710.AIKit.OpenAIChatCompletionsParameters
	$ChatCompletionsParameters:=cs:C1710.AIKit.OpenAIChatCompletionsParameters.new(This:C1470)
	$ChatCompletionsParameters.model:=This:C1470.model
	$ChatCompletionsParameters.stream:=This:C1470.stream
	$ChatCompletionsParameters.formula:=This:C1470.onEventStream
	
	//var $response_format:={type: "json_schema"; json_schema: {}}
	//$response_format.json_schema:={}
	//$response_format.json_schema.name:="Example"
	//$response_format.json_schema.strict:=True
	//$response_format.json_schema.schema:={}
	//$response_format.json_schema.schema.type:="object"
	//$response_format.json_schema.schema.properties:={}
	//$response_format.json_schema.schema.required:=["invoice_amount_jpy"; "settlement_term_days"; \
		"analysis_timestamp"; "rates_timestamp"; "rates_verified"]
	//$response_format.json_schema.schema.additionalProperties:=False
	//$response_format.json_schema.schema.properties.invoice_amount_jpy:={}
	//$response_format.json_schema.schema.properties.invoice_amount_jpy.type:="number"
	//$response_format.json_schema.schema.properties.invoice_amount_jpy.description:="Target invoice value in JPY"
	
	// ============================================================
	//  CURRENCY RECOMMENDATION — JSON SCHEMA (4D)
	// ============================================================
	
	var $response_format : Object
	var $meta : Object
	var $rateItem : Object
	var $primaryRec : Object
	var $fallback : Object
	var $hedgeAdvisory : Object
	var $hedgeDetails : Object
	var $hedgeDetailsNull : Object
	var $riskItem : Object
	
	$response_format:={type: "json_schema"; json_schema: {}}
	$response_format.json_schema.name:="CurrencyRecommendationOutput"
	$response_format.json_schema.strict:=True:C214
	$response_format.json_schema.schema:={}
	$response_format.json_schema.schema.type:="object"
	$response_format.json_schema.schema.additionalProperties:=False:C215
	$response_format.json_schema.schema.required:=["meta"; "rate_summary"; \
		"primary_recommendation"; "fallback_option"; "hedge_advisory"; "risk_flags"]
	$response_format.json_schema.schema.properties:={}
	
	
	// ============================================================
	//  META
	// ============================================================
	
	$meta:={}
	$meta.type:="object"
	$meta.additionalProperties:=False:C215
	$meta.required:=["invoice_amount_jpy"; "settlement_term_days"; \
		"analysis_timestamp"; "rates_timestamp"; "rates_verified"]
	$meta.properties:={}
	
	$meta.properties.invoice_amount_jpy:={}
	$meta.properties.invoice_amount_jpy.type:="number"
	$meta.properties.invoice_amount_jpy.description:="Target invoice value in JPY"
	
	$meta.properties.settlement_term_days:={}
	$meta.properties.settlement_term_days.type:="integer"
	$meta.properties.settlement_term_days.description:="Expected days until payment settlement"
	
	$meta.properties.analysis_timestamp:={}
	$meta.properties.analysis_timestamp.type:="string"
	$meta.properties.analysis_timestamp.format:="date-time"
	$meta.properties.analysis_timestamp.description:="ISO 8601 timestamp of this analysis"
	
	$meta.properties.rates_timestamp:={}
	$meta.properties.rates_timestamp.anyOf:=[{type: "string"; format: "date-time"}; {type: "null"}]
	$meta.properties.rates_timestamp.description:="ISO 8601 timestamp of the rate data provided; null if not supplied"
	
	$meta.properties.rates_verified:={}
	$meta.properties.rates_verified.type:="boolean"
	$meta.properties.rates_verified.description:="False if rates are older than 4 hours or no timestamp was provided"
	
	$response_format.json_schema.schema.properties.meta:=$meta
	
	
	// ============================================================
	//  RATE SUMMARY  (array of ranked currency objects)
	// ============================================================
	
	$rateItem:={}
	$rateItem.type:="object"
	$rateItem.additionalProperties:=False:C215
	$rateItem.required:=["rank"; "currency"; "spot_rate_jpy"; "fee_rate"; \
		"forward_rate_jpy"; "effective_rate_jpy"; "expected_receivable_jpy"; \
		"arbitrage_path"; "arbitrage_gain_jpy"]
	$rateItem.properties:={}
	
	$rateItem.properties.rank:={}
	$rateItem.properties.rank.type:="integer"
	$rateItem.properties.rank.description:="Rank by effective JPY yield; 1 = best"
	
	$rateItem.properties.currency:={}
	$rateItem.properties.currency.type:="string"
	$rateItem.properties.currency.description:="ISO 4217 currency code"
	
	$rateItem.properties.spot_rate_jpy:={}
	$rateItem.properties.spot_rate_jpy.type:="number"
	$rateItem.properties.spot_rate_jpy.description:="Spot rate: JPY per 1 unit of this currency, 4 decimal places"
	
	$rateItem.properties.fee_rate:={}
	$rateItem.properties.fee_rate.type:="number"
	$rateItem.properties.fee_rate.description:="Conversion fee as a decimal (e.g. 0.005 for 0.5%); 0 if not provided"
	
	$rateItem.properties.forward_rate_jpy:={}
	$rateItem.properties.forward_rate_jpy.anyOf:=[{type: "number"}; {type: "null"}]
	$rateItem.properties.forward_rate_jpy.description:="Forward-adjusted rate for the settlement horizon; null if not available"
	
	$rateItem.properties.effective_rate_jpy:={}
	$rateItem.properties.effective_rate_jpy.type:="number"
	$rateItem.properties.effective_rate_jpy.description:="Final rate after forward adjustment and fee deduction, 4 decimal places"
	
	$rateItem.properties.expected_receivable_jpy:={}
	$rateItem.properties.expected_receivable_jpy.type:="number"
	$rateItem.properties.expected_receivable_jpy.description:="JPY receivable at effective rate for the invoice amount"
	
	$rateItem.properties.arbitrage_path:={}
	$rateItem.properties.arbitrage_path.anyOf:=[{type: "string"}; {type: "null"}]
	$rateItem.properties.arbitrage_path.description:="Indirect conversion path if triangular arbitrage applies (e.g. 'USD->EUR->JPY'); null if direct"
	
	$rateItem.properties.arbitrage_gain_jpy:={}
	$rateItem.properties.arbitrage_gain_jpy.anyOf:=[{type: "number"}; {type: "null"}]
	$rateItem.properties.arbitrage_gain_jpy.description:="Additional JPY gained via arbitrage path vs. direct spot; null if no arbitrage"
	
	$response_format.json_schema.schema.properties.rate_summary:={}
	$response_format.json_schema.schema.properties.rate_summary.type:="array"
	$response_format.json_schema.schema.properties.rate_summary.description:="All candidate currencies ranked by effective JPY yield, best first"
	$response_format.json_schema.schema.properties.rate_summary.items:=$rateItem
	
	
	// ============================================================
	//  PRIMARY RECOMMENDATION
	// ============================================================
	
	$primaryRec:={}
	$primaryRec.type:="object"
	$primaryRec.additionalProperties:=False:C215
	$primaryRec.required:=["currency"; "effective_rate_jpy"; "expected_receivable_jpy"; \
		"gain_vs_next_best_jpy"; "gain_vs_next_best_pct"; \
		"confidence"; "confidence_reason"; "rationale"]
	$primaryRec.properties:={}
	
	$primaryRec.properties.currency:={}
	$primaryRec.properties.currency.type:="string"
	$primaryRec.properties.currency.description:="ISO 4217 currency code"
	
	$primaryRec.properties.effective_rate_jpy:={}
	$primaryRec.properties.effective_rate_jpy.type:="number"
	$primaryRec.properties.effective_rate_jpy.description:="Effective JPY rate used for this recommendation, 4 decimal places"
	
	$primaryRec.properties.expected_receivable_jpy:={}
	$primaryRec.properties.expected_receivable_jpy.type:="number"
	$primaryRec.properties.expected_receivable_jpy.description:="Expected JPY receivable at settlement"
	
	$primaryRec.properties.gain_vs_next_best_jpy:={}
	$primaryRec.properties.gain_vs_next_best_jpy.type:="number"
	$primaryRec.properties.gain_vs_next_best_jpy.description:="JPY advantage over the second-ranked currency"
	
	$primaryRec.properties.gain_vs_next_best_pct:={}
	$primaryRec.properties.gain_vs_next_best_pct.type:="number"
	$primaryRec.properties.gain_vs_next_best_pct.description:="Percentage advantage over second-ranked currency, 4 decimal places"
	
	$primaryRec.properties.confidence:={}
	$primaryRec.properties.confidence.type:="string"
	$primaryRec.properties.confidence.enum:=["HIGH"; "MEDIUM"; "LOW"]
	$primaryRec.properties.confidence.description:="Confidence based on rate freshness, spread size, and volatility signals"
	
	$primaryRec.properties.confidence_reason:={}
	$primaryRec.properties.confidence_reason.type:="string"
	$primaryRec.properties.confidence_reason.description:="Brief explanation of why this confidence level was assigned"
	
	$primaryRec.properties.rationale:={}
	$primaryRec.properties.rationale.type:="string"
	$primaryRec.properties.rationale.description:="2-4 sentence explanation of the arbitrage or rate logic driving this recommendation"
	
	$response_format.json_schema.schema.properties.primary_recommendation:=$primaryRec
	
	
	// ============================================================
	//  FALLBACK OPTION
	// ============================================================
	
	$fallback:={}
	$fallback.type:="object"
	$fallback.additionalProperties:=False:C215
	$fallback.required:=["currency"; "effective_rate_jpy"; "expected_receivable_jpy"; "rationale"]
	$fallback.properties:={}
	
	$fallback.properties.currency:={}
	$fallback.properties.currency.type:="string"
	$fallback.properties.currency.description:="ISO 4217 currency code"
	
	$fallback.properties.effective_rate_jpy:={}
	$fallback.properties.effective_rate_jpy.type:="number"
	$fallback.properties.effective_rate_jpy.description:="Effective JPY rate, 4 decimal places"
	
	$fallback.properties.expected_receivable_jpy:={}
	$fallback.properties.expected_receivable_jpy.type:="number"
	$fallback.properties.expected_receivable_jpy.description:="Expected JPY receivable at settlement"
	
	$fallback.properties.rationale:={}
	$fallback.properties.rationale.type:="string"
	$fallback.properties.rationale.description:="1-2 sentence explanation of why this is the best fallback"
	
	$response_format.json_schema.schema.properties.fallback_option:=$fallback
	
	
	// ============================================================
	//  HEDGE ADVISORY
	//  details is object | null  →  use anyOf
	// ============================================================
	
	$hedgeDetails:={}
	$hedgeDetails.type:="object"
	$hedgeDetails.additionalProperties:=False:C215
	$hedgeDetails.required:=["instrument"; "currency_pair"; "rationale"]
	$hedgeDetails.properties:={}
	
	$hedgeDetails.properties.instrument:={}
	$hedgeDetails.properties.instrument.type:="string"
	$hedgeDetails.properties.instrument.description:="Recommended hedging instrument (e.g. 'Forward Contract', 'FX Option')"
	
	$hedgeDetails.properties.currency_pair:={}
	$hedgeDetails.properties.currency_pair.type:="string"
	$hedgeDetails.properties.currency_pair.description:="The pair to hedge (e.g. 'USD/JPY')"
	
	$hedgeDetails.properties.rationale:={}
	$hedgeDetails.properties.rationale.type:="string"
	$hedgeDetails.properties.rationale.description:="Explanation of why a hedge is warranted for this settlement horizon and currency"
	
	$hedgeAdvisory:={}
	$hedgeAdvisory.type:="object"
	$hedgeAdvisory.additionalProperties:=False:C215
	$hedgeAdvisory.required:=["hedge_recommended"; "details"]
	$hedgeAdvisory.properties:={}
	
	$hedgeAdvisory.properties.hedge_recommended:={}
	$hedgeAdvisory.properties.hedge_recommended.type:="boolean"
	$hedgeAdvisory.properties.hedge_recommended.description:="True if a hedge is advised for this transaction"
	
	$hedgeAdvisory.properties.details:={}
	$hedgeAdvisory.properties.details.anyOf:=[$hedgeDetails; {type: "null"}]
	$hedgeAdvisory.properties.details.description:="Populated only when hedge_recommended is true; null otherwise"
	
	$response_format.json_schema.schema.properties.hedge_advisory:=$hedgeAdvisory
	
	
	// ============================================================
	//  RISK FLAGS  (array — may be empty)
	// ============================================================
	
	$riskItem:={}
	$riskItem.type:="object"
	$riskItem.additionalProperties:=False:C215
	$riskItem.required:=["severity"; "currency"; "flag_type"; "description"]
	$riskItem.properties:={}
	
	$riskItem.properties.severity:={}
	$riskItem.properties.severity.type:="string"
	$riskItem.properties.severity.enum:=["HIGH"; "MEDIUM"; "LOW"]
	$riskItem.properties.severity.description:="Risk severity level"
	
	$riskItem.properties.currency:={}
	$riskItem.properties.currency.anyOf:=[{type: "string"}; {type: "null"}]
	$riskItem.properties.currency.description:="ISO 4217 code of the affected currency; null if flag applies globally"
	
	$riskItem.properties.flag_type:={}
	$riskItem.properties.flag_type.type:="string"
	$riskItem.properties.flag_type.enum:=["LIQUIDITY"; "CAPITAL_CONTROLS"; "RATE_ANOMALY"; \
		"CARRY_RISK"; "STALE_DATA"; "OTHER"]
	$riskItem.properties.flag_type.description:="Risk category"
	
	$riskItem.properties.description:={}
	$riskItem.properties.description.type:="string"
	$riskItem.properties.description.description:="Explanation of the risk and its potential impact on JPY receivables"
	
	$response_format.json_schema.schema.properties.risk_flags:={}
	$response_format.json_schema.schema.properties.risk_flags.type:="array"
	$response_format.json_schema.schema.properties.risk_flags.description:="Material risks identified; empty array if none"
	$response_format.json_schema.schema.properties.risk_flags.items:=$riskItem
	
	
	$ChatCompletionsParameters.response_format:=$response_format
	
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
	
Function _isFreshConversation() : Boolean
	
	return This:C1470.messages.length=0
	