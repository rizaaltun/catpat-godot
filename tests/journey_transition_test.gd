extends SceneTree
## Shipping scenes, actual GUI/input dispatch, one canonical save across hand-offs.
const Save=preload("res://scripts/core/save_service.gd")
const Quest=preload("res://scripts/core/quest_state.gd")
const PATH="user://journey-transition-audit.json"
const SCENES=["res://scenes/home.tscn","res://scenes/polish_v3.tscn","res://scenes/river.tscn","res://scenes/garden.tscn","res://scenes/summit.tscn","res://scenes/festival.tscn"]
var checks=0
var failures=0
var store=Save.new()
var touch_input=false
func _initialize():
 set_meta("manual_story_flow",true) # Retained manual controls/recovery contract.
 root.size=Vector2i(1280,720)
 set_meta("journey_save_path",PATH)
 touch_input="--audit-touch" in OS.get_cmdline_user_args()
 call_deferred("run")
func check(ok:bool,label:String):
 checks+=1
 if not ok:failures+=1
 print("PASS " if ok else "FAIL ",label)
func ticks(n:int):
 for frame in n:await physics_frame
func fixture(chapter:int)->Dictionary:
 var q=Quest.new()
 for event in Quest.HOME_EVENTS:q.apply(event)
 var end=["",Quest.COMPLETE,Quest.RIVER_COMPLETE,Quest.GARDEN_COMPLETE,Quest.SUMMIT_COMPLETE][chapter]
 if chapter>0:
  for event in Quest.EVENTS:
   q.apply(event)
   if event==end:break
 var d=store.fresh_journey();d.quest_flags=q.flags.duplicate();d.party_ids=q.party_ids()
 d.chapter_id="B0"+str(chapter)
 d.geometry=["home-v1","islands-v6","river-v10","garden-v12","shared-v16"][chapter]
 d.checkpoint_id=["b00.exit","b01.island.8","b02.exit","b03.exit","b04.bank.2"][chapter]
 d.settings={"onboarding_origin":"new-journey-v1","music":0.0}
 if chapter==4:d.summit={"bank":2,"facing":1,"lantern":"lit","rope":"ready","waymark":"seen"}
 return d
func click(text:String)->bool:
 var nodes=current_scene.find_children("*","Button",true,false).filter(func(b):return b.text==text and b.is_visible_in_tree())
 if nodes.size()!=1:
  check(false,"visible unique GUI action "+text+" count="+str(nodes.size()));return false
 var button=nodes[0]
 var point=button.get_global_transform_with_canvas()*(button.size/2)
 var motion=InputEventMouseMotion.new();motion.position=point;motion.global_position=point;root.push_input(motion,true);await process_frame
 var fired=[false];button.pressed.connect(func():fired[0]=true)
 if touch_input:
  var touch=InputEventScreenTouch.new();touch.index=0;touch.position=point;touch.pressed=true;root.push_input(touch,true)
 var event=InputEventMouseButton.new();event.position=point;event.global_position=point;event.button_index=MOUSE_BUTTON_LEFT;event.pressed=true
 if touch_input:event.device=InputEvent.DEVICE_ID_EMULATION
 root.push_input(event,true);await process_frame
 if touch_input:
  var touch=InputEventScreenTouch.new();touch.index=0;touch.position=point;touch.pressed=false;root.push_input(touch,true)
 event=event.duplicate();event.pressed=false;root.push_input(event,true);await ticks(8)
 check(fired[0],"real GUI press dispatched: "+text)
 return true
func boot(chapter:int):
 if is_instance_valid(current_scene):
  current_scene.queue_free();await process_frame
 set_meta("journey_save_path",PATH)
 check(store.save(PATH,fixture(chapter)),"B0%d completed shipping fixture saves"%chapter)
 check(change_scene_to_file(SCENES[chapter])==OK,"B0%d real scene loads"%chapter)
 await ticks(30)
 if chapter==1:await click("Yolculuğa dön");await ticks(10)
func run():
 var experience=root.get_node_or_null("CatpatExperience")
 if experience:experience.auto_observe=true
 for chapter in range(5):
  await boot(chapter)
  var source=current_scene
  if chapter==0:
   source.player.position=source.EXIT_POINT-Vector2(0,1);await ticks(15)
   await click("Patikaya ilerle")
  elif chapter==1:await click("Dostluk Deresi")
  elif chapter==2:await click("Papatya Bahçesi")
  elif chapter==3:
   source.complete();await ticks(3);await click("Rüzgârlı Yamaç'a ilerle")
  elif chapter==4:
   source.player.position=source.LOOKOUT_POINT-Vector2(0,1);await ticks(20)
   if touch_input:
    source.control_display.touch_mode=true;source.control_display.refresh();await ticks(3)
    await click("Festivale birlikte gir")
   else:
    var event=InputEventKey.new();event.keycode=KEY_E;event.physical_keycode=KEY_E;event.pressed=true;root.push_input(event)
    await ticks(5);event=event.duplicate();event.pressed=false;root.push_input(event)
  await ticks(30)
  check(current_scene!=source and current_scene.scene_file_path==SCENES[chapter+1],"B0%d -> B0%d real input replaces source scene"%[chapter,chapter+1])
  if "--journey-capture" in OS.get_cmdline_user_args():
   var directory=OS.get_environment("CATPAT_AUDIT_CAPTURE_DIR")
   if directory.is_empty():directory="user://journey-audit-captures"
   DirAccess.make_dir_recursive_absolute(directory)
   root.size=Vector2i(666,374);await process_frame;await RenderingServer.frame_post_draw
   check(root.get_texture().get_image().save_png(directory+"/journey-B0%d.png"%(chapter+1))==OK,"destination native capture saves")
   root.size=Vector2i(1280,720)
  var data=store.load_progress(PATH)
  check(data.ok and data.data.chapter_id=="B0"+str(chapter+1),"B0%d -> B0%d canonical save follows scene"%[chapter,chapter+1])
  await ticks(150)
  data=store.load_progress(PATH)
  check(data.ok and data.data.chapter_id=="B0"+str(chapter+1),"B0%d -> B0%d autosave never restores stale source"%[chapter,chapter+1])
  check(str(current_scene.get("save_path"))==PATH,"destination keeps exact journey path")
  # Menu continuation must reopen the destination, without rewriting chapter history.
  if is_instance_valid(current_scene):current_scene.queue_free();await process_frame
  change_scene_to_file(SCENES[1]);await ticks(15)
  await click("Yolculuğa dön");await ticks(20)
  check(current_scene.scene_file_path==SCENES[chapter+1],"B0%d destination survives menu/continue"%(chapter+1))
 if is_instance_valid(current_scene):
  current_scene.queue_free();current_scene=null;await ticks(3)
 for suffix in ["",".bak",".pending",".bak.pending",".onboarding-v1.original"]:DirAccess.remove_absolute(PATH+suffix)
 var audio=root.get_node_or_null("CatpatAudio")
 if is_instance_valid(audio):audio.shutdown()
 await create_timer(0.3).timeout
 print("JOURNEY TRANSITIONS: %d checks, %d failures"%[checks,failures])
 quit(1 if failures else 0)
