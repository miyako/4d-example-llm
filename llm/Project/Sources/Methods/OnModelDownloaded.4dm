//%attributes = {"invisible":true,"preemptive":"capable"}
#DECLARE($params : Object; $context : Object)

var $folder : 4D:C1709.Folder
var $file : 4D:C1709.File

Case of 
	: (OB Instance of:C1731($context; cs:C1710.event.error))
		
		ALERT:C41($context.message)
		return 
		
	: (OB Instance of:C1731($context; cs:C1710.event.models))
		
		$file:=This:C1470.options.model
		
	Else 
		
/*
この分岐はアプリケーションプロセスで実行されます。
*/
		
		var $huggingface : cs:C1710.event.huggingface
		$huggingface:=$params.huggingfaces.huggingfaces.first()
		$file:=$huggingface.folder.file($huggingface[($huggingface.name#"") ? "name" : "path"])
End case 

If (Not:C34($file.exists))
	ALERT:C41("model does not exist!")
	return 
End if 

Case of 
	: ($params.embeddings)
		ALERT:C41("Embeddings model loaded!")
	: ($params.reranking)
		ALERT:C41("Reranker model loaded!")
	Else 
		ALERT:C41("Chat completion model loaded!")
End case 