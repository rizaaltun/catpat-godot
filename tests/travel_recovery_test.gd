extends SceneTree
const Save=preload("res://scripts/core/save_service.gd")
const Quest=preload("res://scripts/core/quest_state.gd")
const PATH="user://travel-recovery-audit.json"
var checks=0
var failures=0
var world
var store=Save.new()
func _initialize():
 set_meta("journey_save_path",PATH)
 call_deferred("run")
func check(ok:bool,label:String):
 checks+=1
 if not ok:failures+=1
 print("PASS " if ok else "FAIL ",label)
func ticks(n:int):
 for frame in n:await physics_frame
func fixture()->Dictionary:
 var q=Quest.new()
 for e in Quest.HOME_EVENTS:q.apply(e)
 for e in Quest.EVENTS:
  q.apply(e)
  if e==Quest.SUMMIT_COMPLETE:break
 var d=store.fresh();d.chapter_id="B04";d.geometry="shared-v16";d.checkpoint_id="b04.bank.2"
 d.quest_flags=q.flags;d.party_ids=q.party_ids();d.summit={"bank":2,"facing":1,"lantern":"lit","rope":"ready","waymark":"seen"}
 return d
func run():
 check(store.save(PATH,fixture()),"completed real summit fixture saves")
 world=load("res://scenes/summit.tscn").instantiate();root.add_child(world);current_scene=world
 await ticks(20)
 world.control_display.touch_mode=true;world.control_display.refresh();world.update_controls_hint()
 check(world.mode=="shared" and world.touch_buttons.all(func(b):return b.visible),"shared journey exposes touch movement controls")
 world.set_pause(true);await ticks(3)
 check(world.touch_buttons.all(func(b):return not b.visible),"pause hides touch movement behind menu")
 world.set_pause(false);await ticks(3)
 check(world.touch_buttons.all(func(b):return b.visible),"resume restores shared-mode touch movement controls")
 world.dialogue_active=true;world.set_pause(false);await ticks(3)
 check(world.paused and world.touch_buttons.all(func(b):return not b.visible),"story dialogue hides frozen movement controls")
 world.dialogue_active=false;world.set_pause(false);await ticks(3)
 check(not world.paused and world.touch_buttons.all(func(b):return b.visible),"closing dialogue restores every touch movement button")
 var before=FileAccess.get_file_as_bytes(PATH)
 world.festival_store.fault="write";world.enter_festival()
 check(FileAccess.get_file_as_bytes(PATH)==before and not world.load_blocked and not world.festival_store.director.transitioning,"failed festival write preserves exact summit bytes and allows retry")
 world.festival_store.fault=""
 world.festival_change=func(_scene):return ERR_CANT_OPEN
 world.enter_festival()
 check(store.load_progress(PATH).data.chapter_id=="B04" and not world.load_blocked,"failed scene load restores source summit and leaves retry available")
 world.festival_change=func(_scene):
  world.festival_store.fault="write"
  return ERR_CANT_OPEN
 world.enter_festival();await ticks(5)
 var safe=FileAccess.get_file_as_bytes(PATH)
 check(store.load_progress(PATH).data.chapter_id=="B05" and world.load_blocked and world.paused,"failed rollback keeps durable B05 target and blocks stale B04 world")
 check(not world.resume_button.visible and not world.load_button.visible and not world.menu_button.visible,"blocked source exposes no stale resume/reload/save-menu action")
 var event=InputEventKey.new();event.keycode=KEY_ESCAPE;event.pressed=true;world._input(event)
 world.save_menu();await ticks(150)
 check(FileAccess.get_file_as_bytes(PATH)==safe and world.paused,"Escape, save-menu and delayed checkpoint cannot overwrite safe B05 target")
 var returns=world.pause_root.find_children("*","Button",true,false).filter(func(b):return b.text=="Ana menüden devam et" and b.visible)
 check(returns.size()==1,"blocked source gives clear menu continuation")
 world.queue_free();world=null;current_scene=null;await ticks(3)
 var audio=root.get_node_or_null("CatpatAudio")
 if audio:audio.shutdown()
 await create_timer(0.25).timeout
 for suffix in ["",".bak",".pending",".bak.pending"]:DirAccess.remove_absolute(PATH+suffix)
 print("TRAVEL RECOVERY: %d checks, %d failures"%[checks,failures])
 quit(1 if failures else 0)
