extends Node
## Local, prospective observations from durable commits. No network or legacy backfill.
const Save=preload("res://scripts/core/save_service.gd")
const Quest=preload("res://scripts/core/quest_state.gd")
const Documents=preload("res://scripts/core/local_document_store.gd")
const GAME_ID="catpat-festival-yolu"
const MAX_RECORDS=500
const SKILL_TAGS=["catpat.proposed.movement_control","catpat.proposed.route_problem_solving","catpat.proposed.story_participation","catpat.proposed.cooperative_task_content"]
const JOURNAL_KEYS=["schema_version","profile_id","baseline","records","dropped_records"]
const EVENT_KEYS=["event_id","session_id","attempt_id","game_id","activity_id","chapter_id","content_version","timestamp_utc","action","result","help","replay_context","skill_ids"]
var documents=Documents.new()
var profile_resolver:Callable
var profile_id_resolver:Callable
var clock:Callable
var session_id="ses_"+Crypto.new().generate_random_bytes(16).hex_encode()
var last_error=""
var _attempts={}
var _pending={}
var _pending_baselines={}
var _pending_dropped={}
var _seen={}
var _suspended={}
static func _token(value,limit:int=96)->bool:
 if not value is String or value.is_empty() or value.length()>limit:return false
 var regex=RegEx.new();regex.compile("^[A-Za-z0-9_.:/-]+$")
 return regex.search(value)!=null
static func _opaque(value,prefix:String)->bool:
 if not value is String:return false
 var regex=RegEx.new();regex.compile("^"+prefix+"[a-f0-9]{32,64}$")
 return regex.search(value)!=null
static func _profile_id(value)->bool:
 if not value is String or value.is_empty() or value.length()>64:return false
 var regex=RegEx.new();regex.compile("^[A-Za-z0-9_-]+$")
 return regex.search(value)!=null
static func _utc(value,allow_empty:bool=false)->bool:
 if allow_empty and value=="":return true
 if not value is String:return false
 var regex=RegEx.new();regex.compile("^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z$")
 return regex.search(value)!=null
static func fresh(profile_id:String)->Dictionary:
 return {"schema_version":1,"profile_id":profile_id,"baseline":{"initialized":false,"chapter_id":"","content_version":"","timestamp_utc":""},"records":[],"dropped_records":0}
static func valid_event(event)->bool:
 if not event is Dictionary or event.size()!=EVENT_KEYS.size() or not event.has_all(EVENT_KEYS):return false
 if not _opaque(event.event_id,"evt_") or not _opaque(event.session_id,"ses_") or not _opaque(event.attempt_id,"att_"):return false
 if event.game_id!=GAME_ID or event.chapter_id not in ["B00","B01","B02","B03","B04","B05"]:return false
 if not _token(event.activity_id,160) or not event.activity_id.begins_with(event.chapter_id+"/") or not _token(event.content_version,64) or not _utc(event.timestamp_utc):return false
 if event.action not in ["quest_commit","help_opened"] or event.result!=("saved" if event.action=="quest_commit" else "shown"):return false
 if not event.help is Dictionary or event.help.size()!=3 or not event.help.has_all(["requested","kind","request_id"]):return false
 if not event.help.requested is bool or event.help.requested!=(event.action=="help_opened"):return false
 if event.help.requested:
  if event.help.kind not in ["task_hint","controls_hint"] or not _token(event.help.request_id,64):return false
 elif event.help.kind!="none" or event.help.request_id!="":return false
 if not event.replay_context is Dictionary or event.replay_context!={"is_replay":false,"source":"registered_primary_journey"}:return false
 if not event.skill_ids is Array or event.skill_ids.size()>SKILL_TAGS.size():return false
 var seen={}
 for tag in event.skill_ids:
  if tag not in SKILL_TAGS or seen.has(tag):return false
  seen[tag]=true
 return true
static func valid(document)->bool:
 if not document is Dictionary or document.size()!=JOURNAL_KEYS.size() or not document.has_all(JOURNAL_KEYS):return false
 if typeof(document.schema_version) not in [TYPE_INT,TYPE_FLOAT] or document.schema_version!=1 or not _profile_id(document.profile_id):return false
 if not document.baseline is Dictionary or document.baseline.size()!=4 or not document.baseline.has_all(["initialized","chapter_id","content_version","timestamp_utc"]):return false
 var baseline:Dictionary=document.baseline
 if not baseline.initialized is bool:return false
 if baseline.initialized:
  if baseline.chapter_id not in ["B00","B01","B02","B03","B04","B05"] or not _token(baseline.content_version,64) or not _utc(baseline.timestamp_utc):return false
 elif baseline.chapter_id!="" or baseline.content_version!="" or baseline.timestamp_utc!="":return false
 if not document.records is Array or document.records.size()>MAX_RECORDS:return false
 if not baseline.initialized and not document.records.is_empty():return false
 if typeof(document.dropped_records) not in [TYPE_INT,TYPE_FLOAT] or not is_finite(float(document.dropped_records)) or document.dropped_records<0 or document.dropped_records!=floorf(float(document.dropped_records)):return false
 var seen={}
 for event in document.records:
  if not valid_event(event) or seen.has(event.event_id):return false
  seen[event.event_id]=true
 return true
static func valid_journal(document)->bool:return valid(document)
static func rebind(document,new_profile_id:String)->Dictionary:
 if not valid(document) or not _profile_id(new_profile_id):return {}
 var result:Dictionary=document.duplicate(true);result.profile_id=new_profile_id
 return result if valid(result) else {}
func _profiles():
 var loop=Engine.get_main_loop()
 return loop.root.get_node_or_null("CatpatProfiles") if loop is SceneTree else null
func _profile_for_path(path:String)->Dictionary:
 var row=profile_resolver.call(path) if profile_resolver.is_valid() else {}
 if not profile_resolver.is_valid():
  var profiles=_profiles()
  if is_instance_valid(profiles) and profiles.has_method("profile_for_path"):row=profiles.profile_for_path(path)
 if not row is Dictionary or not row.has_all(["profile_id","journey_path","journal_path"]):return {}
 if row.journey_path!=path or not _profile_id(row.profile_id) or not row.journal_path is String or not row.journal_path.begins_with("user://") or row.journal_path in [path,path+".bak"]:return {}
 return row
func _profile_by_id(profile_id:String)->Dictionary:
 var row=profile_id_resolver.call(profile_id) if profile_id_resolver.is_valid() else {}
 if not profile_id_resolver.is_valid():
  var profiles=_profiles()
  if is_instance_valid(profiles) and profiles.has_method("profile_by_id"):row=profiles.profile_by_id(profile_id)
 if not row is Dictionary or row.get("profile_id","")!=profile_id:return {}
 return _profile_for_path(str(row.get("journey_path","")))
func _now()->String:
 return str(clock.call()) if clock.is_valid() else Time.get_datetime_string_from_system(true,false)+"Z"
func _version()->String:return str(ProjectSettings.get_setting("application/config/version","unknown"))
func _attempt(profile_id:String,chapter:String,reset:bool=false)->String:
 var key=profile_id+"/"+chapter
 if reset or not _attempts.has(key):_attempts[key]="att_"+Crypto.new().generate_random_bytes(16).hex_encode()
 return _attempts[key]
func _chapter(event:String)->String:
 if event in Quest.HOME_EVENTS:return "B00"
 if event in Quest.RIVER_EVENTS:return "B02"
 if event in Quest.GARDEN_EVENTS:return "B03"
 if event==Quest.SUMMIT_COMPLETE or event.begins_with("summit."):return "B04"
 if event in Quest.FESTIVAL_EVENTS:return "B05"
 return "B01"
func _tags(chapter:String,event:String)->Array:
 if chapter=="B00" and event in [Quest.WALK,Quest.SHORT_JUMP,Quest.LONG_JUMP,Quest.TUTORIAL_JUMP]:return [SKILL_TAGS[0]]
 if event in [Quest.ACCEPTED,Quest.JOINED,Quest.COMPLETE,Quest.RIVER_ACCEPTED,Quest.MONKEY,Quest.RIVER_COMPLETE,Quest.GARDEN_ACCEPTED,Quest.RABBIT,Quest.GARDEN_COMPLETE,Quest.INVITATION,Quest.HOME_EXIT]:return [SKILL_TAGS[2]]
 return [SKILL_TAGS[3] if chapter in ["B04","B05"] else SKILL_TAGS[1]]
func _event(profile_id:String,chapter:String,activity:String,action:String,help_context:Dictionary)->Dictionary:
 var attempt=_attempt(profile_id,chapter)
 var key=session_id+"/"+attempt+"/"+activity+"/"+action+"/"+str(help_context.request_id)
 return {"event_id":"evt_"+key.sha256_text(),"session_id":session_id,"attempt_id":attempt,"game_id":GAME_ID,"activity_id":chapter+"/"+activity,"chapter_id":chapter,"content_version":_version(),"timestamp_utc":_now(),"action":action,"result":"saved" if action=="quest_commit" else "shown","help":help_context,"replay_context":{"is_replay":false,"source":"registered_primary_journey"},"skill_ids":_tags(chapter,activity)}
func _queue(profile_id:String,event:Dictionary)->bool:
 if not valid_event(event):last_error="invalid_observation";return false
 if not _seen.has(profile_id):_seen[profile_id]={}
 if _seen[profile_id].has(event.event_id):return false
 if not _pending.has(profile_id):_pending[profile_id]=[]
 _pending[profile_id].append(event);_seen[profile_id][event.event_id]=true
 while _pending[profile_id].size()>MAX_RECORDS:
  _pending[profile_id].pop_front();_pending_dropped[profile_id]=int(_pending_dropped.get(profile_id,0))+1
 while _seen[profile_id].size()>MAX_RECORDS*4:_seen[profile_id].erase(_seen[profile_id].keys()[0])
 return true
func _flush(profile:Dictionary)->Dictionary:
 var id:String=profile.profile_id
 var loaded=documents.load_document(profile.journal_path,valid)
 var journal=fresh(id)
 if loaded.ok:
  if loaded.data.profile_id!=id:last_error="journal_profile_mismatch";return {"ok":false,"reason":last_error}
  journal=loaded.data.duplicate(true)
 elif loaded.reason!="missing":last_error=str(loaded.reason);return {"ok":false,"reason":last_error}
 var has_changes=false
 if _pending_baselines.has(id) and not journal.baseline.initialized:
  journal.baseline=_pending_baselines[id].duplicate(true);has_changes=true
 var ids={}
 for event in journal.records:ids[event.event_id]=true
 for event in _pending.get(id,[]):
  if not ids.has(event.event_id):journal.records.append(event.duplicate(true));ids[event.event_id]=true;has_changes=true
 while journal.records.size()>MAX_RECORDS:journal.records.pop_front();journal.dropped_records+=1;has_changes=true
 if int(_pending_dropped.get(id,0))>0:journal.dropped_records+=_pending_dropped[id];has_changes=true
 if has_changes and not documents.save(profile.journal_path,journal,valid):last_error=documents.last_error;return {"ok":false,"reason":"journal_write_failed"}
 _pending.erase(id);_pending_baselines.erase(id);_pending_dropped.erase(id);last_error=""
 return {"ok":true,"data":journal,"recovered":loaded.get("recovered",false)}
func observe_snapshot(path:String,previous:Dictionary,current:Dictionary)->Dictionary:
 if int(_suspended.get(path,0))>0:return {"ok":true,"recorded":0,"reason":"suppressed_transaction"}
 var profile=_profile_for_path(path)
 if profile.is_empty():return {"ok":true,"recorded":0,"reason":"unregistered_path"}
 var save=Save.new()
 if not save.valid(current):return {"ok":false,"reason":"invalid_snapshot"}
 var id:String=profile.profile_id
 _pending_baselines[id]={"initialized":true,"chapter_id":current.chapter_id,"content_version":_version(),"timestamp_utc":_now()}
 if not save.valid(previous):
  var baseline=_flush(profile);baseline.recorded=0;baseline.reason="initial_baseline_only";return baseline
 var before:Array=previous.quest_flags
 var after:Array=current.quest_flags
 for event in before:
  if event not in after:_attempt(id,_chapter(event),true)
 if previous.chapter_id=="B04" and current.chapter_id=="B04":
  for field in ["lantern","rope","waymark"]:
   var stages=Save.Summit.LANTERN if field=="lantern" else Save.Summit.ROPE if field=="rope" else Save.Summit.WAYMARK
   if stages.find(current.summit[field])<stages.find(previous.summit[field]):_attempt(id,"B04",true)
 var count=0
 var bypass=str(current.settings.get("onboarding_origin","")) in ["legacy-bypass-v1","user-skipped-v1"]
 for event in after:
  if event in before or (event in Quest.HOME_EVENTS and bypass):continue
  if _queue(id,_event(id,_chapter(event),event,"quest_commit",{"requested":false,"kind":"none","request_id":""})):count+=1
 if previous.chapter_id=="B04" and current.chapter_id=="B04":
  for field in ["lantern","rope","waymark"]:
   var stages=Save.Summit.LANTERN if field=="lantern" else Save.Summit.ROPE if field=="rope" else Save.Summit.WAYMARK
   if stages.find(current.summit[field])>stages.find(previous.summit[field]):
    var event="summit."+field+"."+str(current.summit[field])
    if _queue(id,_event(id,"B04",event,"quest_commit",{"requested":false,"kind":"none","request_id":""})):count+=1
 var result=_flush(profile);result.recorded=count if result.ok else 0;result.queued=count;return result
func _property(object,key:String,fallback=null):
 if not is_instance_valid(object):return fallback
 for item in object.get_property_list():
  if item.name==key:return object.get(key)
 return fallback
func _source_path(source)->String:
 if source is String:return source
 if source is Dictionary:return str(source.get("path",source.get("journey_path","")))
 return str(_property(source,"save_path","")) if typeof(source)==TYPE_OBJECT and is_instance_valid(source) else ""
func suspend_path(source)->Dictionary:
 var path=_source_path(source)
 if _profile_for_path(path).is_empty():return {"ok":true,"reason":"unregistered_path","depth":0}
 _suspended[path]=int(_suspended.get(path,0))+1
 return {"ok":true,"depth":_suspended[path]}
func resume_path(source)->Dictionary:
 var path=_source_path(source)
 var depth=maxi(0,int(_suspended.get(path,0))-1)
 if depth==0:_suspended.erase(path)
 else:_suspended[path]=depth
 return {"ok":true,"depth":depth}
func begin_attempt(source,chapter:String="")->Dictionary:
 var path=_source_path(source)
 var profile=_profile_for_path(path)
 if profile.is_empty():return {"ok":true,"recorded":0,"reason":"unregistered_path"}
 var snapshot=Save.new().load_progress(path)
 if not snapshot.ok or snapshot.get("new",false):return {"ok":false,"recorded":0,"reason":"no_journey_context"}
 if source is Dictionary and chapter.is_empty():chapter=str(source.get("chapter_id",""))
 if chapter.is_empty():chapter=str(snapshot.data.chapter_id)
 if chapter!=snapshot.data.chapter_id:return {"ok":false,"recorded":0,"reason":"invalid_attempt_context"}
 var attempt=_attempt(profile.profile_id,chapter,true)
 _pending_baselines[profile.profile_id]={"initialized":true,"chapter_id":chapter,"content_version":_version(),"timestamp_utc":_now()}
 var result=_flush(profile);result.recorded=0;result.attempt_id=attempt;return result
func forget_profile(profile_id:String):
 # Deletion clears volatile evidence too; it must never be flushed into a new profile.
 for cache in [_pending,_pending_baselines,_pending_dropped,_seen]:cache.erase(profile_id)
 for key in _attempts.keys():
  if str(key).begins_with(profile_id+"/"):_attempts.erase(key)
 for path in _suspended.keys():
  var profile=_profile_for_path(path)
  if profile.is_empty() or profile.profile_id==profile_id:_suspended.erase(path)
 last_error=""
func record_help(source,task_id:String="",kind:String="task_hint",request_id:String="")->Dictionary:
 var path="";var chapter=""
 if source is Dictionary:
  path=str(source.get("path",source.get("journey_path","")));chapter=str(source.get("chapter_id",""))
  task_id=str(source.get("activity_id",source.get("task_id",task_id)));kind=str(source.get("kind",kind));request_id=str(source.get("request_id",request_id))
 elif typeof(source)==TYPE_OBJECT and is_instance_valid(source):path=str(_property(source,"save_path",""))
 var profile=_profile_for_path(path)
 if profile.is_empty():return {"ok":true,"recorded":0,"reason":"unregistered_path"}
 var saved=Save.new().load_progress(path)
 if not saved.ok or saved.get("new",false):return {"ok":false,"reason":"no_journey_context"}
 if chapter.is_empty():chapter=str(saved.data.chapter_id)
 if chapter!=saved.data.chapter_id or chapter not in ["B00","B01","B02","B03","B04","B05"] or kind not in ["task_hint","controls_hint"]:return {"ok":false,"reason":"invalid_help_context"}
 if task_id.is_empty():task_id="chapter_help"
 if not _token(task_id,120):return {"ok":false,"reason":"invalid_help_activity"}
 if request_id.is_empty():request_id="help_"+Crypto.new().generate_random_bytes(16).hex_encode()
 if not _token(request_id,64):return {"ok":false,"reason":"invalid_help_request"}
 _pending_baselines[profile.profile_id]={"initialized":true,"chapter_id":chapter,"content_version":_version(),"timestamp_utc":_now()}
 var queued=_queue(profile.profile_id,_event(profile.profile_id,chapter,task_id,"help_opened",{"requested":true,"kind":kind,"request_id":request_id}))
 var result=_flush(profile);result.recorded=int(queued) if result.ok else 0;result.queued=int(queued);return result
func report_for(profile_id:String)->Dictionary:
 var profile=_profile_by_id(profile_id)
 if profile.is_empty():return {"ok":false,"events":[],"reason":"unknown_profile"}
 var loaded=_flush(profile)
 if not loaded.ok:return {"ok":false,"events":[],"reason":loaded.reason,"pending":_pending.get(profile_id,[]).size()}
 var journal:Dictionary=loaded.data
 var chapters=[]
 for event in journal.records:
  if event.chapter_id not in chapters:chapters.append(event.chapter_id)
 var suggestions=[]
 for chapter in chapters:suggestions.append({"chapter_id":chapter,"basis":"actual_recorded_activity","label":"Bu bölümdeki etkinlikleri birlikte yeniden keşfedebilirsiniz."})
 return {"ok":true,"events":journal.records.duplicate(true),"truncated":journal.dropped_records>0,"dropped_records":journal.dropped_records,"baseline":journal.baseline.duplicate(true),"pending":0,"recovered_from_backup":loaded.get("recovered",false),"suggested_activities":suggestions,"context":{"prospective_only":true,"skill_namespace":"catpat.proposed","canonical_skill_ids_known":false,"skill_mapping_meaning":"tasarım amacı, ölçüm değil","replay_observations":"unregistered_replay_paths_not_recorded","observations_are_not_development_measurements":true}}
