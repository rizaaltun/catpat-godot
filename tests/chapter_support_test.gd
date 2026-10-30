extends SceneTree
const Support=preload("res://scripts/core/chapter_support.gd")
const Store=preload("res://scripts/core/save_service.gd")
const Replay=preload("res://scripts/core/replay_service.gd")
const Quest=preload("res://scripts/core/quest_state.gd")
const PATH="user://chapter-support-test.json"
const PRIMARY="user://chapter-support-primary-test.json"
const JOURNAL="user://chapter-support-journal-test.json"
var checks=0
var failures=0
func check(ok:bool,label:String):
 checks+=1
 if not ok:failures+=1
 print("PASS " if ok else "FAIL ",label)
func clean(path:String):
 for suffix in Replay.SLOT_SUFFIXES:DirAccess.remove_absolute(path+suffix)
func _initialize():call_deferred("run")
func make_scene(chapter:String,path:String):
 var scene=load(Replay.ENTRIES[chapter][2]).instantiate();scene.save_path=path;return scene
func completed_data(chapter:String,entry:Dictionary)->Dictionary:
 var data=entry.duplicate(true);var state=Quest.new();state.flags=data.quest_flags.duplicate()
 for event in Quest.HOME_EVENTS+Quest.EVENTS:
  if Support.new()._event_chapter(event)==chapter:state.apply(event)
 data.quest_flags=state.flags.duplicate();data.party_ids=state.party_ids()
 if chapter=="B04":data.summit.lantern="lit";data.summit.rope="ready";data.summit.waymark="seen";data.summit.bank=2;data.checkpoint_id="b04.bank.2"
 if chapter=="B05":data.ending_seen=true;data.checkpoint_id="b05.stage"
 return data
func run():
 for path in [PATH,PRIMARY,JOURNAL]:clean(path)
 var store=Store.new();var service=Support.new();var replay=Replay.new()
 var state=Quest.new()
 for event in Quest.HOME_EVENTS+Quest.EVENTS:state.apply(event)
 var full=store.fresh();full.chapter_id="B05";full.geometry="festival-v1";full.checkpoint_id="b05.stage";full.quest_flags=state.flags;full.party_ids=state.party_ids();full.ending_seen=true;full.settings={"music":0.25,"full_text":true,"custom_host_key":"preserved"};full.collectibles=["b00.ribbon","b01.mote.2"]
 check(store.save(PRIMARY,full),"completed isolated source stored")
 var entries={}
 for chapter in Replay.CHAPTERS:entries[chapter]=replay.prepare(chapter,PRIMARY).data
 for chapter in Replay.CHAPTERS:
  for completed in [false,true]:
   clean(PATH)
   var data=completed_data(chapter,entries[chapter]) if completed else entries[chapter].duplicate(true)
   data.collectibles=[]
   if chapter!="B00":data.collectibles.append("b00.ribbon")
   if Replay.CHAPTERS.find(chapter)>=1:data.collectibles.append("b01.mote.2")
   if chapter=="B00" and completed:data.collectibles=["b00.ribbon"]
   check(store.valid(data) and store.save(PATH,data),chapter+" "+str(completed)+" valid current snapshot")
   var scene=make_scene(chapter,PATH)
   var help=service.help_context(scene)
   check(help.ok and not help.task_id.is_empty() and not help.text.is_empty(),chapter+" "+str(completed)+" contextual help uses actual saved state")
   var prepared=service.prepare_restart(scene)
   check(prepared.ok and store.valid(prepared.data),chapter+" "+str(completed)+" current restart is valid without a completed gate")
   var index=Replay.CHAPTERS.find(chapter)
   check(prepared.data.quest_flags.all(func(event):return Replay.CHAPTERS.find(service._event_chapter(event))<index),chapter+" current and future flags are cleared")
   check(prepared.data.settings==data.settings and prepared.data.collectibles==data.collectibles.filter(func(id):return (0 if id=="b00.ribbon" else 1)<index),chapter+" earlier collectibles and all settings are preserved")
   check(prepared.data.checkpoint_id==Replay.ENTRIES[chapter][1] and not prepared.data.ending_seen and (prepared.data.summit==Store.Summit.fresh() if chapter=="B04" else prepared.data.summit.is_empty()),chapter+" entry checkpoint and internal chapter state reset")
   var navigated=[""]
   var result=service.restart(scene,func(path):navigated[0]=path;return OK)
   check(result.ok and navigated[0]==Replay.ENTRIES[chapter][2] and store.encode(store.load_progress(PATH).data)==store.encode(prepared.data),chapter+" restart persists before navigating to the existing scene")
   scene.free()
 # Future flags in a permissive older B01 snapshot must not survive a B01 restart.
 var future=completed_data("B03",entries.B03);future.chapter_id="B01";future.geometry="islands-v6";future.checkpoint_id="b01.island.0";future.summit={};future.ending_seen=false
 check(store.save(PATH,future),"legacy B01 fixture with later chapter facts remains schema-valid")
 var scene=make_scene("B01",PATH)
 check(service.prepare_restart(scene).data.quest_flags.all(func(event):return event in Quest.HOME_EVENTS),"restart removes future chapter facts in a legacy snapshot")
 scene.free()
 var b01=completed_data("B01",entries.B01);check(store.save(PATH,b01),"rollback fixture saves")
 scene=make_scene("B01",PATH)
 var before=replay.slot_snapshot(PATH)
 set_meta("journey_save_path",PATH);set_meta("replay_primary_path",PRIMARY);set_meta("replay_chapter","B01");set_meta("replay_autostart",false)
 var meta=replay.metadata_snapshot()
 var primary=replay.slot_snapshot(PRIMARY)
 for fault in ["write","rename"]:
  service.store.fault=fault
  var result=service.restart(scene,func(_path):return OK)
  check(not result.ok and result.rollback_ok and replay.slot_snapshot(PATH)==before and replay.metadata_snapshot()==meta,"restart "+fault+" failure preserves exact save family and metadata")
 service.store.fault=""
 for error in [ERR_CANT_OPEN,null,false]:
  var result=service.restart(scene,func(_path):return error)
  check(not result.ok and result.rollback_ok and replay.slot_snapshot(PATH)==before and replay.metadata_snapshot()==meta,"navigation "+str(error)+" failure rolls bytes and metadata back")
 check(replay.slot_snapshot(PRIMARY)==primary,"failed replay-slot restarts never alter primary journey bytes")
 check(service.restart(scene,func(_path):return OK).ok and replay.slot_snapshot(PRIMARY)==primary and get_meta("journey_save_path")==PATH,"successful replay restart stays in the actual isolated slot")
 for key in ["replay_primary_path","replay_chapter","replay_autostart","journey_autostart"]:
  if has_meta(key):remove_meta(key)
 var wrong=make_scene("B02",PATH)
 before=replay.slot_snapshot(PATH)
 check(not service.restart(wrong,func(_path):return OK).ok and replay.slot_snapshot(PATH)==before,"saved chapter and actual scene mismatch rejects without writes")
 wrong.free();scene.free()
 clean(PATH)
 scene=make_scene("B01",PATH)
 check(not service.restart(scene).ok and not FileAccess.file_exists(PATH),"missing journey cannot be silently replaced by restart")
 var corrupt=FileAccess.open(PATH,FileAccess.WRITE);corrupt.store_string("{invalid original}");corrupt.close();before=replay.slot_snapshot(PATH)
 check(not service.restart(scene).ok and replay.slot_snapshot(PATH)==before,"corrupt journey bytes survive a rejected restart")
 scene.free()
 # Registered prospective observations: help dedupe, no negative progress, fresh attempt.
 var observer=root.get_node_or_null("CatpatObservations")
 if is_instance_valid(observer):
  var old_resolver=observer.profile_resolver;var old_id_resolver=observer.profile_id_resolver
  observer.profile_resolver=func(path):return {"profile_id":"chapter_support_test","journey_path":PATH,"journal_path":JOURNAL} if path==PATH else {}
  observer.profile_id_resolver=func(id):return {"profile_id":"chapter_support_test","journey_path":PATH,"journal_path":JOURNAL} if id=="chapter_support_test" else {}
  clean(PATH);store.save(PATH,entries.B01);var accepted=entries.B01.duplicate(true);accepted.quest_flags.append(Quest.ACCEPTED);store.save(PATH,accepted)
  scene=make_scene("B01",PATH)
  var first=service.record_help(scene,"same_help_open");var duplicate=service.record_help(scene,"same_help_open")
  check(first.ok and first.recorded==1 and duplicate.recorded==0,"same actual help request is journaled once")
  var report=observer.report_for("chapter_support_test");var count=report.events.size();var previous_attempt=report.events[-1].attempt_id
  var result=service.restart(scene,func(_path):return ERR_CANT_OPEN)
  check(not result.ok and observer.report_for("chapter_support_test").events.size()==count,"failed restart and rollback emit no negative or repeated quest observations")
  result=service.restart(scene,func(_path):return OK)
  check(result.ok and result.attempt.get("recorded",-1)==0 and observer.report_for("chapter_support_test").events.size()==count,"successful restart begins an attempt without emitting progress")
  accepted=store.load_progress(PATH).data;accepted.quest_flags.append(Quest.ACCEPTED);store.save(PATH,accepted)
  report=observer.report_for("chapter_support_test")
  check(report.events.size()==count+1 and report.events[-1].attempt_id!=previous_attempt,"real new progress after restart receives a new attempt ID")
  scene.free();observer.profile_resolver=old_resolver;observer.profile_id_resolver=old_id_resolver
 for path in [PATH,PRIMARY,JOURNAL]:clean(path)
 set_meta("journey_save_path","user://festival_v3.json")
 print("CHAPTER SUPPORT: %d checks, %d failures"%[checks,failures])
 quit(1 if failures else 0)
