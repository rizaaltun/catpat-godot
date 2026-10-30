extends RefCounted
## Validated, checksum-wrapped local JSON. Invalid source bytes remain recoverable.
var fault=""
var last_error=""
const MAX_BYTES=8388608
func encode(data:Dictionary)->String:
 var normalized=JSON.parse_string(JSON.stringify(data))
 return JSON.stringify({"payload":normalized,"sha256":JSON.stringify(normalized).sha256_text()})
func decode(text:String,validator:Callable)->Dictionary:
 if text.to_utf8_buffer().size()>MAX_BYTES:return {"ok":false,"reason":"too_large"}
 var parser=JSON.new()
 if parser.parse(text)!=OK:return {"ok":false,"reason":"invalid_document"}
 var parsed=parser.data
 if not parsed is Dictionary or parsed.size()!=2 or not parsed.get("payload") is Dictionary or not parsed.get("sha256") is String:return {"ok":false,"reason":"invalid_document"}
 if parsed.sha256!=JSON.stringify(parsed.payload).sha256_text():return {"ok":false,"reason":"checksum"}
 if not validator.is_valid() or not validator.call(parsed.payload):return {"ok":false,"reason":"invalid_payload"}
 return {"ok":true,"data":parsed.payload}
func read_file(path:String,validator:Callable)->Dictionary:
 if not FileAccess.file_exists(path):return {"ok":false,"reason":"missing"}
 return decode(FileAccess.get_file_as_string(path),validator)
func load_document(path:String,validator:Callable)->Dictionary:
 var primary=read_file(path,validator)
 if primary.ok:primary.recovered=false;return primary
 var backup=read_file(path+".bak",validator)
 if backup.ok:backup.recovered=true;return backup
 return {"ok":false,"reason":"missing" if primary.reason=="missing" and backup.reason=="missing" else "no_valid_document"}
func write_text(path:String,text:String)->bool:
 var file=FileAccess.open(path,FileAccess.WRITE)
 if not file:return false
 file.store_string(text);file.flush()
 var error=file.get_error();file.close();return error==OK
func preserve_invalid(path:String,validator:Callable)->bool:
 if not FileAccess.file_exists(path) or read_file(path,validator).ok:return true
 var bytes=FileAccess.get_file_as_bytes(path)
 var damaged=path+".damaged-"+bytes.hex_encode().sha256_text().substr(0,16)
 if FileAccess.file_exists(damaged):return FileAccess.get_file_as_bytes(damaged)==bytes
 return DirAccess.copy_absolute(path,damaged)==OK and FileAccess.get_file_as_bytes(damaged)==bytes
func save(path:String,data:Dictionary,validator:Callable)->bool:
 last_error=""
 if not validator.is_valid() or not validator.call(data):last_error="invalid_payload";return false
 var text=encode(data)
 if text.to_utf8_buffer().size()>MAX_BYTES:last_error="too_large";return false
 if FileAccess.file_exists(path) and FileAccess.get_file_as_string(path)==text:return true
 if DirAccess.make_dir_recursive_absolute(path.get_base_dir())!=OK:last_error="directory_failed";return false
 var pending=path+".pending"
 if fault=="write" or not write_text(pending,text):last_error="write_failed";return false
 if fault=="verify" or not read_file(pending,validator).ok:last_error="verify_failed";return false
 if not preserve_invalid(path,validator) or not preserve_invalid(path+".bak",validator):last_error="preserve_failed";return false
 if read_file(path,validator).ok:
  if fault=="backup" or not write_text(path+".bak.pending",FileAccess.get_file_as_string(path)):last_error="backup_failed";return false
  if DirAccess.rename_absolute(path+".bak.pending",path+".bak")!=OK:last_error="backup_commit_failed";return false
 if fault=="rename" or DirAccess.rename_absolute(pending,path)!=OK:last_error="commit_failed";return false
 return true
