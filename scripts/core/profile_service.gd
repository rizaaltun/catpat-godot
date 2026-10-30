extends Node
## Local, pseudonymous travellers. Scene navigation and parent confirmation belong to UI.
const Store=preload("res://scripts/core/save_service.gd")
const Documents=preload("res://scripts/core/local_document_store.gd")
const Replay=preload("res://scripts/core/replay_service.gd")
const INDEX_VERSION=1
const MAX_PROFILES=6
const BUNDLE_FORMAT="catpat-local-profile"
var root_path="user://catpat-profiles"
var legacy_path="user://festival_v3.json"
var documents=Documents.new()
var journeys=Store.new()
var index:Dictionary={}
var _loading=false
var last_error=""
var fault=""
var journal_adapter:Object
var observations_resolver:Callable
func _ready():
 if not get_tree().has_meta("journey_save_path"):
  var result=ensure_loaded()
  if result.ok:
   if get_tree().has_meta("profile_context_error"):get_tree().remove_meta("profile_context_error")
   apply_active_context();retry_cleanup()
  else:get_tree().set_meta("profile_context_error",result.get("reason","profile_context_unavailable"))
func configure(directory:String,legacy:String)->void:
 root_path=directory.trim_suffix("/");legacy_path=legacy;index={}
func index_path()->String:return root_path+"/index.json"
func _id_valid(id)->bool:
 if not id is String or id.length()!=32:return false
 for character in id:
  if character not in "0123456789abcdef":return false
 return true
func _timestamp_valid(value)->bool:
 if not value is String or value.length()!=19:return false
 var pattern=RegEx.new();pattern.compile("^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}$")
 if pattern.search(value)==null:return false
 var year=int(value.substr(0,4));var month=int(value.substr(5,2));var day=int(value.substr(8,2))
 if year<1970 or month<1 or month>12 or day<1 or int(value.substr(11,2))>23 or int(value.substr(14,2))>59 or int(value.substr(17,2))>59:return false
 var days=[31,29 if year%4==0 and (year%100!=0 or year%400==0) else 28,31,30,31,30,31,31,30,31,30,31]
 return day<=days[month-1]
func _label_valid(value)->bool:
 if not value is String or not value.begins_with("Yolcu "):return false
 var number=value.trim_prefix("Yolcu ")
 return number.is_valid_int() and int(number)>0 and number==str(int(number))
func valid_index(data:Dictionary)->bool:
 if data.size()!=3 or not data.has_all(["schema_version","active_id","profiles"]) or typeof(data.schema_version) not in [TYPE_INT,TYPE_FLOAT] or data.schema_version!=INDEX_VERSION or not data.profiles is Array:return false
 if data.profiles.is_empty() or data.profiles.size()>MAX_PROFILES or not _id_valid(data.active_id):return false
 var ids=[];var labels=[];var legacy_count=0
 for profile in data.profiles:
  if not profile is Dictionary or profile.size()!=5 or not profile.has_all(["profile_id","label","journey_path","journal_path","created_at"]):return false
  if not profile.journey_path is String or not profile.journal_path is String:return false
  if not _id_valid(profile.profile_id) or profile.profile_id in ids or not _label_valid(profile.label) or profile.label in labels or not _timestamp_valid(profile.created_at):return false
  if profile.journey_path!=_journey_path(profile.profile_id) and profile.journey_path!=legacy_path:return false
  if profile.journal_path!=_journal_path(profile.profile_id):return false
  if profile.journey_path==legacy_path:legacy_count+=1
  ids.append(profile.profile_id);labels.append(profile.label)
 return data.active_id in ids and legacy_count<=1
func _journey_path(id:String)->String:return root_path+"/"+id+"-journey.json"
func _journal_path(id:String)->String:return root_path+"/"+id+"-journal.json"
func _new_record(existing:Array)->Dictionary:
 var id=""
 for attempt in 20:
  id=Crypto.new().generate_random_bytes(16).hex_encode()
  if not existing.any(func(profile):return profile.profile_id==id) and not FileAccess.file_exists(_journey_path(id)) and not FileAccess.file_exists(_journal_path(id)):break
  id=""
 if id.is_empty():return {}
 var number=1
 while existing.any(func(profile):return profile.label=="Yolcu "+str(number)):number+=1
 return {"profile_id":id,"label":"Yolcu "+str(number),"journey_path":_journey_path(id),"journal_path":_journal_path(id),"created_at":Time.get_datetime_string_from_system(true)}
func _index_snapshot()->Dictionary:
 var result={}
 for suffix in ["",".bak"]:
  if FileAccess.file_exists(index_path()+suffix):result[suffix]=FileAccess.get_file_as_bytes(index_path()+suffix)
 return result
func _restore_index(snapshot:Dictionary)->bool:
 var restored=true
 for suffix in ["",".bak"]:
  var path=index_path()+suffix
  if snapshot.has(suffix):
   var temporary=path+".rollback"
   var file=FileAccess.open(temporary,FileAccess.WRITE)
   if not file:restored=false;continue
   file.store_buffer(snapshot[suffix]);file.flush();var error=file.get_error();file.close()
   restored=error==OK and DirAccess.rename_absolute(temporary,path)==OK and restored
  elif FileAccess.file_exists(path):restored=DirAccess.remove_absolute(path)==OK and restored
 return restored
func _commit_index(next:Dictionary)->bool:
 var previous=_index_snapshot()
 if fault=="index_write":documents.fault="write"
 elif fault=="index_rename":documents.fault="rename"
 if not documents.save(index_path(),next,valid_index):
  documents.fault="";last_error=documents.last_error;return false
 documents.fault=""
 # A recovered index must not resurrect a removed profile or forget a new one.
 var backup=index_path()+".bak.pending"
 if fault=="index_backup" or not documents.write_text(backup,documents.encode(next)) or not documents.read_file(backup,valid_index).ok or DirAccess.rename_absolute(backup,index_path()+".bak")!=OK:
  if _restore_index(previous):last_error="index_backup_failed"
  else:last_error="index_rollback_failed";index={}
  return false
 index=next.duplicate(true);return true
func ensure_loaded()->Dictionary:
 if _loading:return {"ok":false,"reason":"initializing"}
 _loading=true
 var result=_load_index()
 _loading=false
 return result
func _load_index()->Dictionary:
 if not index.is_empty():return {"ok":true}
 var loaded=documents.load_document(index_path(),valid_index)
 if loaded.ok:index=loaded.data.duplicate(true);return {"ok":true,"recovered":loaded.recovered}
 if loaded.reason!="missing":last_error=loaded.reason;return {"ok":false,"reason":last_error}
 var profile=_new_record([])
 if profile.is_empty():return {"ok":false,"reason":"random_id_failed"}
 var legacy=FileAccess.file_exists(legacy_path) or FileAccess.file_exists(legacy_path+".bak")
 if legacy:profile.journey_path=legacy_path
 else:
  if not _write_journey(profile.journey_path,journeys.fresh_journey()):return {"ok":false,"reason":last_error}
 var next={"schema_version":INDEX_VERSION,"active_id":profile.profile_id,"profiles":[profile]}
 if not _commit_index(next):
  if not legacy and last_error!="index_rollback_failed":_remove_created(profile)
  return {"ok":false,"reason":last_error}
 return {"ok":true}
func list_profiles()->Array:
 if not ensure_loaded().ok:return []
 return index.profiles.duplicate(true)
func active_profile()->Dictionary:
 if not ensure_loaded().ok:return {}
 for profile in index.profiles:
  if profile.profile_id==index.active_id:return profile.duplicate(true)
 return {}
func _find(id:String)->Dictionary:
 for profile in index.get("profiles",[]):
  if profile.profile_id==id:return profile.duplicate(true)
 return {}
func apply_active_context()->bool:
 var profile=active_profile()
 if profile.is_empty() or not is_inside_tree():return false
 get_tree().set_meta("journey_save_path",profile.journey_path)
 get_tree().set_meta("journal_save_path",profile.journal_path)
 get_tree().set_meta("active_profile_id",profile.profile_id)
 return true
func _write_journey(path:String,data:Dictionary)->bool:
 if DirAccess.make_dir_recursive_absolute(path.get_base_dir())!=OK:last_error="directory_failed";return false
 journeys.fault="write" if fault=="journey_write" else ""
 var ok=journeys.save(path,data);last_error=journeys.last_error;journeys.fault="";return ok
func _remove_created(profile:Dictionary):
 for path in [profile.journey_path,profile.journal_path]:
  for suffix in ["",".bak",".pending",".bak.pending"]:DirAccess.remove_absolute(path+suffix)
func create_profile()->Dictionary:
 if not ensure_loaded().ok:return {"ok":false,"reason":last_error}
 if index.profiles.size()>=MAX_PROFILES:return {"ok":false,"reason":"profile_limit"}
 var profile=_new_record(index.profiles)
 if profile.is_empty():return {"ok":false,"reason":"random_id_failed"}
 if not _write_journey(profile.journey_path,journeys.fresh_journey()):_remove_created(profile);return {"ok":false,"reason":last_error}
 var next=index.duplicate(true);next.profiles.append(profile);next.active_id=profile.profile_id
 if not _commit_index(next):
  if last_error!="index_rollback_failed":_remove_created(profile)
  return {"ok":false,"reason":last_error}
 apply_active_context();return {"ok":true,"profile":profile.duplicate(true)}
func activate_profile(id:String)->Dictionary:
 if not ensure_loaded().ok:return {"ok":false,"reason":last_error}
 var profile=_find(id)
 if profile.is_empty():return {"ok":false,"reason":"unknown_profile"}
 var next=index.duplicate(true);next.active_id=id
 if not _commit_index(next):return {"ok":false,"reason":last_error}
 apply_active_context();return {"ok":true,"profile":profile}
func profile_by_id(id:String)->Dictionary:return _find(id)
func profile_for_path(path:String)->Dictionary:
 for profile in index.get("profiles",[]):
  if profile.journey_path==path:return profile.duplicate(true)
 return {}
func _journal_class():
 if is_instance_valid(journal_adapter):return journal_adapter
 var path="res://scripts/core/observation_service.gd"
 return load(path) if ResourceLoader.exists(path) else null
func _journal_valid(data)->bool:
 var adapter=_journal_class()
 return adapter!=null and data is Dictionary and adapter.valid(data)
func _empty_journal(id:String)->Dictionary:
 var adapter=_journal_class()
 return adapter.fresh(id) if adapter!=null else {}
func export_bundle(id:String)->Dictionary:
 if not ensure_loaded().ok:return {"ok":false,"reason":last_error}
 var profile=_find(id)
 if profile.is_empty():return {"ok":false,"reason":"unknown_profile"}
 var journey=journeys.load_progress(profile.journey_path)
 if not journey.ok or journey.get("new",false) or not journeys.valid(journey.data):return {"ok":false,"reason":"invalid_journey"}
 var journal=documents.load_document(profile.journal_path,_journal_valid)
 if not journal.ok:
  if journal.reason!="missing":return {"ok":false,"reason":"invalid_journal"}
  journal={"ok":true,"data":_empty_journal(id)}
 if not _journal_valid(journal.data) or journal.data.profile_id!=id:return {"ok":false,"reason":"invalid_journal"}
 var bundle={"format":BUNDLE_FORMAT,"schema_version":1,"profile_id":id,"exported_at":Time.get_datetime_string_from_system(true),"journey":journey.data.duplicate(true),"journal":journal.data.duplicate(true)}
 return {"ok":true,"bundle":bundle}
func valid_bundle(bundle)->bool:
 if not bundle is Dictionary or bundle.size()!=6 or not bundle.has_all(["format","schema_version","profile_id","exported_at","journey","journal"]):return false
 if bundle.format!=BUNDLE_FORMAT or typeof(bundle.schema_version) not in [TYPE_INT,TYPE_FLOAT] or bundle.schema_version!=1 or not _id_valid(bundle.profile_id) or not _timestamp_valid(bundle.exported_at):return false
 if not bundle.journey is Dictionary or not journeys.valid(bundle.journey) or not _journal_valid(bundle.journal):return false
 return bundle.journal.profile_id==bundle.profile_id and JSON.stringify(bundle).to_utf8_buffer().size()<=Documents.MAX_BYTES
func import_bundle(bundle:Dictionary,activate:bool=true)->Dictionary:
 if not valid_bundle(bundle):return {"ok":false,"reason":"invalid_bundle"}
 if not ensure_loaded().ok:return {"ok":false,"reason":last_error}
 if index.profiles.size()>=MAX_PROFILES:return {"ok":false,"reason":"profile_limit"}
 var profile=_new_record(index.profiles)
 if profile.is_empty():return {"ok":false,"reason":"random_id_failed"}
 var journal=_journal_class().rebind(bundle.journal,profile.profile_id)
 if not _journal_valid(journal) or journal.profile_id!=profile.profile_id:return {"ok":false,"reason":"invalid_journal"}
 if not _write_journey(profile.journey_path,bundle.journey):_remove_created(profile);return {"ok":false,"reason":last_error}
 if fault=="journal_write":documents.fault="write"
 var journal_saved=documents.save(profile.journal_path,journal,_journal_valid);documents.fault=""
 if not journal_saved:_remove_created(profile);return {"ok":false,"reason":"journal_write_failed"}
 var next=index.duplicate(true);next.profiles.append(profile)
 if activate:next.active_id=profile.profile_id
 if not _commit_index(next):
  if last_error!="index_rollback_failed":_remove_created(profile)
  return {"ok":false,"reason":last_error}
 apply_active_context();return {"ok":true,"profile":profile.duplicate(true)}
func _owned_paths(profile:Dictionary)->Array:
 var paths=[]
 for base in [profile.journey_path,profile.journal_path,Replay.new().replay_path(profile.journey_path)]:
  var directory=DirAccess.open(base.get_base_dir())
  if not directory:continue
  for filename in directory.get_files():
   if filename==base.get_file() or filename.begins_with(base.get_file()+"."):paths.append(base.get_base_dir()+"/"+filename)
 return paths
func _notify_profile_removed(id:String):
 var observer=observations_resolver.call() if observations_resolver.is_valid() else null
 if not observations_resolver.is_valid() and is_inside_tree():observer=get_tree().root.get_node_or_null("CatpatObservations")
 if is_instance_valid(observer) and observer.has_method("forget_profile"):observer.forget_profile(id)
func cleanup_path()->String:return root_path+"/cleanup.json"
func valid_cleanup(data:Dictionary)->bool:
 if data.size()!=2 or not data.has_all(["schema_version","entries"]) or typeof(data.schema_version) not in [TYPE_INT,TYPE_FLOAT] or data.schema_version!=1 or not data.entries is Array or data.entries.size()>128:return false
 var ids=[]
 for entry in data.entries:
  if not entry is Dictionary or entry.size()!=4 or not entry.has_all(["profile_id","legacy_journey","token","created_at"]):return false
  if not _id_valid(entry.profile_id) or entry.profile_id in ids or not entry.legacy_journey is bool or not _timestamp_valid(entry.created_at):return false
  if not entry.token is String or entry.token.length()!=16:return false
  for character in entry.token:
   if character not in "0123456789abcdef":return false
  ids.append(entry.profile_id)
 return true
func _cleanup_document()->Dictionary:
 var loaded=documents.load_document(cleanup_path(),valid_cleanup)
 if loaded.ok:return loaded
 if loaded.reason=="missing":return {"ok":true,"data":{"schema_version":1,"entries":[]}}
 return {"ok":false,"reason":"invalid_cleanup_document"}
func _cleanup_profile(entry:Dictionary)->Dictionary:
 return {"profile_id":entry.profile_id,"journey_path":legacy_path if entry.legacy_journey else _journey_path(entry.profile_id),"journal_path":_journal_path(entry.profile_id)}
func retry_cleanup()->Dictionary:
 if not ensure_loaded().ok:return {"ok":false,"pending_count":0,"reason":last_error}
 var loaded=_cleanup_document()
 if not loaded.ok:return {"ok":false,"pending_count":0,"reason":loaded.reason}
 var remaining=[]
 var removed=0
 for entry in loaded.data.entries:
  var profile=_cleanup_profile(entry)
  # An index rollback or corrupt/stale tombstone never deletes a current traveller.
  if not _find(entry.profile_id).is_empty() or index.profiles.any(func(row):return row.journey_path==profile.journey_path):remaining.append(entry);continue
  var failed=false
  for source in _owned_paths(profile):
   if fault=="cleanup_unlink" or (fault=="cleanup_unlink_after_first" and removed>0) or DirAccess.remove_absolute(source)!=OK:failed=true
   else:removed+=1
  if failed:remaining.append(entry)
 var next={"schema_version":1,"entries":remaining}
 if next!=loaded.data and not documents.save(cleanup_path(),next,valid_cleanup):return {"ok":false,"pending_count":loaded.data.entries.size(),"reason":"cleanup_commit_failed"}
 return {"ok":remaining.is_empty(),"pending_count":remaining.size(),"removed_count":removed}
func delete_profile(id:String)->Dictionary:
 if not ensure_loaded().ok:return {"ok":false,"reason":last_error}
 var profile=_find(id)
 if profile.is_empty():return {"ok":false,"reason":"unknown_profile"}
 var cleanup=_cleanup_document()
 if not cleanup.ok:return {"ok":false,"reason":cleanup.reason}
 if cleanup.data.entries.size()>=128:return {"ok":false,"reason":"cleanup_capacity"}
 var old_index=index.duplicate(true)
 var old_files=_index_snapshot()
 var next=index.duplicate(true)
 next.profiles=next.profiles.filter(func(row):return row.profile_id!=id)
 var replacement={}
 if next.profiles.is_empty():
  replacement=_new_record([])
  if replacement.is_empty():return {"ok":false,"reason":"random_id_failed"}
  if not _write_journey(replacement.journey_path,journeys.fresh_journey()):_remove_created(replacement);return {"ok":false,"reason":last_error}
  next.profiles.append(replacement)
 if next.active_id==id:next.active_id=next.profiles[0].profile_id
 if not _commit_index(next):
  if not replacement.is_empty() and last_error!="index_rollback_failed":_remove_created(replacement)
  return {"ok":false,"reason":last_error}
 # Persist a path-free cleanup instruction before touching the traveller's files.
 var token=Crypto.new().generate_random_bytes(8).hex_encode()
 var tombstones=cleanup.data.duplicate(true)
 tombstones.entries.append({"profile_id":id,"legacy_journey":profile.journey_path==legacy_path,"token":token,"created_at":Time.get_datetime_string_from_system(true)})
 if not documents.save(cleanup_path(),tombstones,valid_cleanup):
  var restored=_restore_index(old_files)
  index=old_index if restored else {}
  if restored and not replacement.is_empty():_remove_created(replacement)
  return {"ok":false,"reason":"cleanup_write_failed" if restored else "delete_rollback_failed"}
 var staged={}
 var stage_failed=false
 for path in _owned_paths(profile):
  var destination=path+".deleting-"+token
  if fault=="delete_stage" or (fault=="delete_stage_after_first" and not staged.is_empty()) or DirAccess.rename_absolute(path,destination)!=OK:stage_failed=true;break
  staged[path]=destination
 if stage_failed:
  var restored=true
  for path in staged:restored=DirAccess.rename_absolute(staged[path],path)==OK and restored
  restored=_restore_index(old_files) and restored
  if restored:
   index=old_index
   # A retained stale tombstone is safe: retry checks current index ownership.
   documents.save(cleanup_path(),cleanup.data,valid_cleanup)
  else:index={}
  if restored and not replacement.is_empty():_remove_created(replacement)
  last_error="delete_stage_failed" if restored else "delete_rollback_failed"
  return {"ok":false,"reason":last_error}
 _notify_profile_removed(id)
 var result=retry_cleanup()
 apply_active_context()
 return {"ok":true,"profile":active_profile(),"cleanup_pending":not result.ok,"pending_count":result.pending_count}
func export_json(id:String)->Dictionary:
 var result=export_bundle(id)
 if result.ok:result.text=JSON.stringify(result.bundle)
 return result
func import_json(text:String)->Dictionary:
 if text.to_utf8_buffer().size()>Documents.MAX_BYTES:return {"ok":false,"reason":"too_large"}
 var parser=JSON.new()
 if parser.parse(text)!=OK:return {"ok":false,"reason":"invalid_bundle"}
 var bundle=parser.data
 if not bundle is Dictionary:return {"ok":false,"reason":"invalid_bundle"}
 return import_bundle(bundle)
