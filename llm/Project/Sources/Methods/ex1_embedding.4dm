//%attributes = {"invisible":true}
var $llama : cs:C1710.AIKit.OpenAI
$llama:=cs:C1710.AIKit.OpenAI.new()
$llama.baseURL:="http://127.0.0.1:"+String:C10(Storage:C1525.embeddings.port)+"/v1"

/*

1件のテキスト

*/

var $input : Text
$input:="株式会社フォーディー・ジャパンは東京都渋谷区にオフィスを構えています。"

var $batch : cs:C1710.AIKit.OpenAIEmbeddingsResult
$batch:=$llama.embeddings.create($input)

var $embedding : 4D:C1709.Vector
If ($batch.success)
	$embedding:=$batch.embedding.embedding
End if 

/*

2件のテキスト

*/

var $inputs : Collection
$inputs:=[$input]
$inputs.push("4d japan is located in shibuya which is in tokyo.")

$batch:=$llama.embeddings.create($inputs)

var $embeddings : Collection
If ($batch.success)
	$embeddings:=$batch.embeddings
	var $cosineSimilarity : Real
	$cosineSimilarity:=$embeddings[0].embedding.cosineSimilarity($embeddings[1].embedding)
End if 