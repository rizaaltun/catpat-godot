extends RefCounted
## Completed chapters replay in an isolated slot. Primary save bytes are read-only.
const Save=preload("res://scripts/core/save_service.gd")
const Quest=preload("res://scripts/core/quest_state.gd")
const CHAPTERS=["B00","B01","B02","B03","B04","B05"]
const TITLES={"B00":"Davet Yolu","B01":"Fenerli Patika","B02":"Dostluk Deresi","B03":"Papatya Bahçesi","B04":"Rüzgârlı Yamaç","B05":"Festival Alanı"}
const COMPLETION={"B00":Quest.HOME_EXIT,"B01":Quest.COMPLETE,"B02":Quest.RIVER_COMPLETE,"B03":Quest.GARDEN_COMPLETE,"B04":Quest.SUMMIT_COMPLETE,"B05":Quest.FESTIVAL_COMPLETE}
const ENTRIES={"B00":["home-v1","b00.entry","res://scenes/home.tscn"],"B01":["islands-v6","b01.island.0","res://scenes/polish_v3.tscn"],"B02":["river-v10","b02.entry","res://scenes/river.tscn"],"B03":["garden-v12","b03.entry","res://scenes/garden.tscn"],"B04":["shared-v16","b04.bank.0","res://scenes/summit.tscn"],"B05":["festival-v1","b05.entry","res://scenes/festival.tscn"]}
const META_KEYS=["journey_save_path","journey_autostart","replay_primary_path","replay_chapter","replay_autostart"]
const SLOT_SUFFIXES=["",".bak",".pending",".bak.pending",".legacy",".onboarding-v1.original"]
var store=Save.new()
func tree() -> SceneTree:return Engine.get_main_loop() as SceneTree
func primary_path(candidate:String) -> String:
 var active=str(tree().get_meta("replay_primary_path",""))
 return active if not active.is_empty() else candidate
func replay_path(primary:String) -> String:
 return "user://catpat-replay-"+primary.sha256_text().substr(0,16)+".json"
func read_source(candidate:String) -> Dictionary:
 var path=primary_path(candidate)
 var loaded=store.load_progress(path)
 if not loaded.ok or loaded.get("new",false):return {"ok":false,"reason":"no_completed_journey","primary_path":path}
 return {"ok":true,"data":loaded.data,"primary_path":path,"recovered":loaded.get("recovered",false)}
func completed_from(data:Dictionary) -> Array:
 var result=[]
 for chapter in CHAPTERS:
  if COMPLETION[chapter] not in data.quest_flags:continue
  # A compatibility/user skip is not evidence that the new tutorial was played.
  if chapter=="B00" and data.settings.get("onboarding_origin","") in ["legacy-bypass-v1","user-skipped-v1"]:continue
  result.append(chapter)
 return result
func completed_chapters(candidate:String) -> Array:
 var source=read_source(candidate)
 return completed_from(source.data) if source.ok else []
func prepare(chapter:String,candidate:String) -> Dictionary:
 var source=read_source(candidate)
 if not source.ok:return source
 if chapter not in completed_from(source.data):return {"ok":false,"reason":"chapter_not_completed"}
 var data=store.fresh_journey() if chapter=="B00" else store.fresh()
 data.chapter_id=chapter;data.geometry=ENTRIES[chapter][0];data.checkpoint_id=ENTRIES[chapter][1]
 data.settings=source.data.settings.duplicate(true)
 var state=Quest.new()
 if chapter!="B00":
  # Prior chapter facts are prerequisites, never copied target/future completions.
  for event in Quest.HOME_EVENTS:
   if event in source.data.quest_flags:state.apply(event)
  var prior=CHAPTERS[CHAPTERS.find(chapter)-1]
  if prior!="B00":
   for event in Quest.EVENTS:
    if not state.apply(event):return {"ok":false,"reason":"invalid_prerequisite"}
    if event==COMPLETION[prior]:break
 data.quest_flags=state.flags.duplicate();data.party_ids=state.party_ids()
 if chapter=="B04":data.summit=Save.Summit.fresh()
 if not store.valid(data):return {"ok":false,"reason":"invalid_replay_snapshot"}
 var slot=replay_path(source.primary_path)
 if slot==source.primary_path or slot==source.primary_path+".bak":return {"ok":false,"reason":"unsafe_replay_path"}
 return {"ok":true,"data":data,"path":slot,"primary_path":source.primary_path,"scene_path":ENTRIES[chapter][2],"chapter":chapter}
func metadata_snapshot() -> Dictionary:
 var snapshot={}
 for key in META_KEYS:
  if tree().has_meta(key):snapshot[key]=tree().get_meta(key)
 return snapshot
func restore_metadata(snapshot:Dictionary):
 for key in META_KEYS:
  if snapshot.has(key):tree().set_meta(key,snapshot[key])
  elif tree().has_meta(key):tree().remove_meta(key)
func slot_snapshot(path:String) -> Dictionary:
 var snapshot={}
 for suffix in SLOT_SUFFIXES:
  if FileAccess.file_exists(path+suffix):snapshot[suffix]=FileAccess.get_file_as_bytes(path+suffix)
 return snapshot
func restore_slot(path:String,snapshot:Dictionary) -> bool:
 var ok=true
 for suffix in SLOT_SUFFIXES:
  var target=path+suffix
  if snapshot.has(suffix):
   var file=FileAccess.open(target,FileAccess.WRITE)
   if not file:ok=false;continue
   file.store_buffer(snapshot[suffix]);file.flush();ok=ok and file.get_error()==OK;file.close()
  elif FileAccess.file_exists(target):ok=DirAccess.remove_absolute(target)==OK and ok
 return ok
func navigate_to(path:String,navigation:Callable) -> int:
 if not navigation.is_valid():return tree().change_scene_to_file(path)
 var result=navigation.call(path)
 return result if typeof(result)==TYPE_INT else ERR_CANT_OPEN
func start(chapter:String,candidate:String,navigation:Callable=Callable()) -> Dictionary:
 var prepared=prepare(chapter,candidate)
 if not prepared.ok:return prepared
 if not load(prepared.scene_path) is PackedScene:return {"ok":false,"reason":"missing_scene"}
 var previous_meta=metadata_snapshot()
 var previous_slot=slot_snapshot(prepared.path)
 if not store.save(prepared.path,prepared.data):
  var restored=restore_slot(prepared.path,previous_slot)
  return {"ok":false,"reason":"replay_save_failed","slot_restored":restored}
 tree().set_meta("journey_save_path",prepared.path)
 tree().set_meta("replay_primary_path",prepared.primary_path)
 tree().set_meta("replay_chapter",chapter)
 tree().set_meta("replay_autostart",chapter=="B01")
 tree().set_meta("journey_autostart",chapter=="B01")
 var error=navigate_to(prepared.scene_path,navigation)
 if error!=OK:
  restore_metadata(previous_meta)
  var restored=restore_slot(prepared.path,previous_slot)
  return {"ok":false,"reason":"replay_navigation_failed","error":error,"slot_restored":restored}
 return prepared
func return_to_primary(navigation:Callable=Callable()) -> Dictionary:
 var path=str(tree().get_meta("replay_primary_path",""))
 if path.is_empty():return {"ok":false,"reason":"no_active_replay"}
 var previous=metadata_snapshot()
 for key in ["replay_primary_path","replay_chapter","replay_autostart","journey_autostart"]:
  if tree().has_meta(key):tree().remove_meta(key)
 tree().set_meta("journey_save_path",path)
 var error=navigate_to("res://scenes/polish_v3.tscn",navigation)
 if error!=OK:
  restore_metadata(previous)
  return {"ok":false,"reason":"return_navigation_failed","error":error}
 return {"ok":true,"primary_path":path}
