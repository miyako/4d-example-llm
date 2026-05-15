property tools : Collection

shared singleton Class constructor
	
	var $tools : Collection
	$tools:=[]
	
	var $OpenAITool : cs:C1710.AIKit.OpenAITool
	
	$OpenAITool:=cs:C1710.AIKit.OpenAITool.new({\
		type: "function"; \
		function: {\
		name: "systemInfo"; \
		description: "The System info command returns an object containg information about the operating system and the characteristics of the system hardware and software from the machine it's executed on."; \
		parameters: {\
		type: "object"; \
		properties: {}}}})
	
	$tools.push($OpenAITool)
	
	$OpenAITool:=cs:C1710.AIKit.OpenAITool.new({\
		type: "function"; \
		function: {\
		name: "cacheInfo"; \
		description: "The Cache info command returns an object that contains detailed information about the current cache contents (used memory, loaded tables and indexes, etc.) ."; \
		parameters: {\
		type: "object"; \
		properties: {}}}})
	
	$tools.push($OpenAITool)
	
	$OpenAITool:=cs:C1710.AIKit.OpenAITool.new({\
		type: "function"; \
		function: {\
		name: "databaseMeasures"; \
		description: "The Database measures command allows you to get detailed information about engine events. Returned information includes data read/write access from/to the disk or the memory cache, as well as t"+"he use of database indexes, queries and sorts."; \
		parameters: {\
		type: "object"; \
		properties: {}}}})
	
	$tools.push($OpenAITool)
	
	This:C1470.tools:=$tools.copy(ck shared:K85:29)
	
Function systemInfo($object : Object) : Object
	
	return System info:C1571
	
Function cacheInfo($object : Object) : Object
	
	return Cache info:C1402
	
Function databaseMeasures($object : Object) : Object
	
	return Database measures:C1314