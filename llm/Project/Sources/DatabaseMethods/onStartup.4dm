Use (Storage:C1525)
	Storage:C1525.chat:=New shared object:C1526("port"; 8181)
End use 

var $llama : cs:C1710.llama.llama
var $huggingfaces : cs:C1710.event.huggingfaces
var $embeddings; $rerank : cs:C1710.event.huggingface
var $homeFolder : 4D:C1709.Folder

var $file : 4D:C1709.File
var $URL : Text
var $port : Integer

var $event : cs:C1710.event.event
$event:=cs:C1710.event.event.new()

/*
これらのコールバックはプリエンプティブスレッドで実行されます。
*/

$event.onError:=Formula:C1597(OnModelDownloaded)
$event.onSuccess:=Formula:C1597(OnModelDownloaded)
$event.onData:=Formula:C1597(LOG EVENT:C667(Into 4D debug message:K38:5; This:C1470.file.fullName+":"+String:C10((This:C1470.range.end/This:C1470.range.length)*100; "###.00%")))
$event.onResponse:=Formula:C1597(LOG EVENT:C667(Into 4D debug message:K38:5; This:C1470.file.fullName+":download complete"))
$event.onTerminate:=Formula:C1597(LOG EVENT:C667(Into 4D debug message:K38:5; (["process"; $1.pid; "terminated!"].join(" "))))

$homeFolder:=Folder:C1567(fk home folder:K87:24).folder(".GGUF")
var $max_position_embeddings; $batch_size; $parallel : Integer
var $ubatch_size; $n_gpu_layers; $threads; $threads_batch; $batches : Integer
var $ctx_size; $temp; $min_p; $top_k; $top_p; $repeat_penalty; $presence_penalty : Integer

var $folder : 4D:C1709.Folder
var $logFile : 4D:C1709.File
var $path; $pooling : Text
var $options : Object

/*
* チャットモデル
 */

$folder:=$homeFolder.folder("tiny-aya")
$path:="tiny-aya-earth-q8_0.gguf"
//$path:="tiny-aya-earth-q4_k_m.gguf"
$URL:="CohereLabs/tiny-aya-earth-GGUF"

/*

チャットモデルのハイパーパラメーター

以下を間違えると起動しない

- ctx_size
- ubatch_size

以下はパフォーマンスを左右する

- n_gpu_layers
- ctx_size
- threads 
- threads_batch 

注記

- ubatch_sizeはbatch_sizeの倍数であるべき
- parallelはスロット数（単一リクエストで送信するバッチ数に合わせる）
- threads_httpには+1の余裕を持たせると良い（healthエンドポイントのため）
- ctx_sizeにはプロンプト全体が収まらなければならない
- threadsはデコーダー（出力）
- threads_batchはデコーダー（入力）
- threads,threads_batchはCPUのコア数（GPUではない）

 */

$batches:=1
$threads:=1
$threads_batch:=1
$batch_size:=512

$logFile:=$folder.file("llama.log")
$folder.create()
If (Not:C34($logFile.exists))
	$logFile.setContent(4D:C1709.Blob.new())
End if 

/*
* これらのハイパーパラメーターについてはモデルカードを参照のこと
 */

$temp:=0.7
$min_p:=0.05
$top_k:=40
$top_p:=0.9
$repeat_penalty:=1.1
$presence_penalty:=1.5
$ctx_size:=10000
$port:=Storage:C1525.chat.port  //インスタンス毎にllama.cppのポートを割り当てること
$options:={\
ctx_size: $ctx_size; \
batch_size: $batch_size*$batches; \
ubatch_size: $ubatch_size; \
parallel: $batches; \
threads: $threads; \
threads_batch: $threads_batch; \
threads_http: $batches+1; \
temp: $temp; \
min_p: $min_p; \
top_k: $top_k; \
top_p: $top_p; \
repeat_penalty: $repeat_penalty; \
presence_penalty: $presence_penalty; \
log_file: $logFile; \
log_disable: False:C215; \
n_gpu_layers: $n_gpu_layers}

var $chat : cs:C1710.event.huggingface
$chat:=cs:C1710.event.huggingface.new($folder; $URL; $path)
$huggingfaces:=cs:C1710.event.huggingfaces.new([$chat])
$llama:=cs:C1710.llama.llama.new($port; $huggingfaces; $homeFolder; $options; $event)