extends SceneTree
const Map=preload("res://scripts/core/journey_map.gd")
const MapPanel=preload("res://scripts/ui/journey_map_panel.gd")
const Save=preload("res://scripts/core/save_service.gd")
const Quest=preload("res://scripts/core/quest_state.gd")
const Replay=preload("res://scripts/core/replay_service.gd")
const PATH="user://journey-map-test.json"
const OTHER="user://journey-map-other.json"
var checks=0
var failures=0
var model=Map.new()
var store=Save.new()
var capture_enabled=false
func _initialize():call_deferred("run")
func check(ok:bool,label:String):
 checks+=1
 if not ok:failures+=1
 print("PASS " if ok else "FAIL ",label)
func clean(path:String):
 for suffix in Replay.SLOT_SUFFIXES:DirAccess.remove_absolute(path+suffix)
func fixture(chapter:String)->Dictionary:
 var state=Quest.new()
 var index=Replay.CHAPTERS.find(chapter)
 if index>0:
  for event in Quest.HOME_EVENTS:state.apply(event)
  if index>1:
   for event in Quest.EVENTS:
    state.apply(event)
    if event==Replay.COMPLETION[Replay.CHAPTERS[index-1]]:break
 var d=store.fresh_journey();d.chapter_id=chapter;d.geometry=Replay.ENTRIES[chapter][0];d.checkpoint_id=Replay.ENTRIES[chapter][1]
 d.quest_flags=state.flags;d.party_ids=state.party_ids();d.summit=Save.Summit.fresh() if chapter=="B04" else {}
 d.settings={"onboarding_origin":"new-journey-v1","music":0.0,"sfx":0.0}
 return d
func capture(tag:String):
 if not capture_enabled:return
 await process_frame;await RenderingServer.frame_post_draw
 var image=root.get_texture().get_image()
 check(not image.is_empty(),tag+" has real rendered pixels")
 var folder="res://build/journey-map";DirAccess.make_dir_recursive_absolute(folder)
 check(image.save_png(folder+"/"+tag+".png")==OK,tag+" saves review frame")
 print("MAP_FRAME:",ProjectSettings.globalize_path(folder+"/"+tag+".png"))
func run():
 capture_enabled="--map-capture" in OS.get_cmdline_user_args()
 var host=root.get_node("CatpatExperience");host.auto_observe=false
 var old_meta=model.replay.metadata_snapshot()
 for key in Replay.META_KEYS:
  if has_meta(key):remove_meta(key)
 for path in [PATH,OTHER,model.replay.replay_path(PATH)]:clean(path)
 var blank=model.snapshot(PATH)
 check(not blank.ok and blank.rows.size()==6 and blank.rows.all(func(r):return r.state=="locked"),"missing journey previews all six regions without inventing progress")
 check(not FileAccess.file_exists(PATH) and not model.continue_primary(PATH,func(_p):return OK).ok,"map inspection/continue cannot create a journey")
 for chapter in Replay.CHAPTERS:
  clean(PATH);var d=fixture(chapter)
  check(store.save(PATH,d),chapter+" canonical fixture saves")
  var before=model.replay.slot_snapshot(PATH)
  var snap=model.snapshot(PATH)
  check(snap.ok and snap.current==chapter and snap.rows.filter(func(r):return r.current).size()==1,chapter+" has exactly one current region")
  check(snap.rows.all(func(r):return r.completed==(r.id in model.replay.completed_from(d))),chapter+" completed regions use canonical quest facts")
  var meta=model.replay.metadata_snapshot()
  check(not model.continue_primary(PATH,func(_p):return ERR_CANT_OPEN).ok and model.replay.metadata_snapshot()==meta,chapter+" rejected continuation restores all context")
  var route=[""]
  var result=model.continue_primary(PATH,func(p):route[0]=p;return OK)
  check(result.ok and route[0]==Replay.ENTRIES[chapter][2] and result.checkpoint==d.checkpoint_id,chapter+" continues at exact saved chapter/checkpoint")
  check(model.replay.slot_snapshot(PATH)==before,chapter+" map read/continue leaves primary and backup bytes untouched")
  model.replay.restore_metadata(meta)
 # An already-open panel must re-read state at activation time.
 clean(PATH);store.save(PATH,fixture("B02"));var before=model.replay.slot_snapshot(PATH)
 var panel=MapPanel.new();root.add_child(panel);var calls=[0]
 panel.setup(PATH,func():pass,func(_p):calls[0]+=1;return ERR_CANT_OPEN)
 await process_frame
 panel.select_region("B02");await process_frame
 var key=InputEventKey.new();key.keycode=KEY_RIGHT;key.pressed=true
 root.push_input(key,true);await process_frame
 check(panel.selected=="B03","real arrow-key input selects the next map region")
 panel.select_region("B02");await process_frame
 var point=panel.nodes[2].get_global_transform_with_canvas()*(panel.nodes[2].size/2)
 var press=InputEventMouseButton.new();press.button_index=MOUSE_BUTTON_LEFT;press.position=point;press.pressed=true
 root.push_input(press,true);var release=press.duplicate();release.pressed=false;root.push_input(release,true);await process_frame
 check(panel.selected=="B02","real mouse input selects the painted creek region")
 panel.select_region("B03");await process_frame
 var touch=InputEventScreenTouch.new();touch.index=9;touch.pressed=true;touch.position=point
 root.push_input(touch,true);var up=touch.duplicate();up.pressed=false;root.push_input(up,true);await process_frame
 check(panel.selected=="B02","real touch input selects a map region")
 panel.select_region("B03");await process_frame
 touch=touch.duplicate();touch.index=10;root.push_input(touch,true)
 up=touch.duplicate();up.pressed=false;up.canceled=true;root.push_input(up,true);await process_frame
 check(panel.selected=="B03","cancelled map touch cannot select a region")
 touch=touch.duplicate();touch.index=11;root.push_input(touch,true)
 var drag=InputEventScreenDrag.new();drag.index=11;drag.position=point+Vector2(50,0);drag.relative=Vector2(50,0);root.push_input(drag,true)
 up=touch.duplicate();up.pressed=false;up.position=drag.position;root.push_input(up,true);await process_frame
 check(panel.selected=="B03","dragging across a map marker never selects it")
 var emulated=InputEventMouseButton.new();emulated.button_index=MOUSE_BUTTON_LEFT;emulated.position=point;emulated.pressed=true;emulated.device=InputEvent.DEVICE_ID_EMULATION
 root.push_input(emulated,true);emulated=emulated.duplicate();emulated.pressed=false;root.push_input(emulated,true);await process_frame
 check(panel.selected=="B03","emulated mouse cannot repeat or change a map touch selection")
 panel.select_region("B05");panel.activate()
 check(calls[0]==0 and not panel.primary_button.visible and panel.description.text==Map.PREVIEWS.B05,"locked region shows a world preview and cannot navigate")
 check(model.replay.slot_snapshot(PATH)==before,"locked preview never changes save bytes")
 panel.select_region("B02");panel.activate()
 check(calls[0]==1 and not panel.status_label.text.is_empty() and is_instance_valid(panel),"failed current-region navigation stays open for retry")
 panel.select_region("B01");panel.replay_selected()
 check(calls[0]==2 and model.replay.slot_snapshot(PATH)==before,"completed region uses isolated replay and preserves primary bytes on failure")
 host.application_focus_lost=true;panel.activate();panel.replay_selected()
 check(calls[0]==2,"covered window cannot activate map navigation")
 host.application_focus_lost=false
 panel.select_region("B02")
 store.save(PATH,fixture("B03"));var navigated=[""]
 panel.navigation=func(p):navigated[0]=p;return ERR_CANT_OPEN
 panel.activate()
 check(navigated[0].is_empty(),"stale current selection cannot launch a different active chapter")
 panel.select_region("B03");panel.activate()
 check(navigated[0]==Replay.ENTRIES.B03[2],"freshly selected current region uses latest saved route")
 # Distinct profile paths remain independent; the replay context resolves primary correctly.
 store.save(OTHER,fixture("B00"))
 check(model.snapshot(OTHER).current=="B00" and model.snapshot(PATH).current=="B03","profile maps never share a progress counter")
 for suffix in ["",".bak"]:
  var broken=FileAccess.open(OTHER+suffix,FileAccess.WRITE);broken.store_string("{invalid");broken.close()
 var corrupt=model.replay.slot_snapshot(OTHER)
 check(not model.snapshot(OTHER).ok and not model.continue_primary(OTHER,func(_p):return OK).ok,"corrupt source cannot unlock or continue any region")
 check(model.replay.slot_snapshot(OTHER)==corrupt,"corrupt source bytes are preserved")
 var backup=FileAccess.open(OTHER+".bak",FileAccess.WRITE);backup.store_string(store.encode(fixture("B04")));backup.close()
 var recovered=model.replay.slot_snapshot(OTHER)
 check(model.snapshot(OTHER).recovered and model.snapshot(OTHER).current=="B04","a validated backup supplies the real current map region")
 check(model.continue_primary(OTHER,func(_p):return OK).ok and model.replay.slot_snapshot(OTHER)==recovered,"backup continuation never silently repairs primary bytes")
 set_meta("replay_primary_path",PATH);set_meta("replay_chapter","B01");set_meta("journey_save_path",model.replay.replay_path(PATH))
 var meta=model.replay.metadata_snapshot()
 check(model.snapshot(model.replay.replay_path(PATH)).current=="B03","map in replay describes the primary journey")
 check(not model.continue_primary(PATH,func(_p):return ERR_CANT_OPEN).ok and model.replay.metadata_snapshot()==meta,"failed primary continuation preserves replay return context")
 model.replay.restore_metadata({})
 panel.queue_free();await process_frame
 for size in [Vector2i(1280,720),Vector2i(666,374)]:
  root.size=size
  root.set_meta("catpat_preferences",{"text_scale":1.3,"left_handed":true})
  panel=MapPanel.new();root.add_child(panel);panel.setup(PATH,func():pass)
  await process_frame;await process_frame
  check(panel.nodes.size()==6 and panel.nodes.all(func(b):return b.get_theme_stylebox("normal") is StyleBoxTexture),str(size)+" has six image-backed region controls")
  var separated=true
  for i in panel.nodes.size():
   for j in range(i+1,panel.nodes.size()):separated=separated and not panel.nodes[i].get_rect().intersects(panel.nodes[j].get_rect())
  check(separated,str(size)+" region hit targets do not overlap")
  for chapter in Replay.CHAPTERS:
   panel.select_region(chapter);await process_frame;await process_frame
   check(panel.title_label.get_minimum_size().y<=108 and panel.description.get_minimum_size().y<=170,chapter+" large live text fits at "+str(size))
  check(panel.compact==(size.x<900),str(size)+" selects scrollable small-screen composition")
  if panel.compact:
   panel.select_region("B00");await process_frame;await process_frame
   var old_scroll=panel.scroll.scroll_horizontal
   touch=InputEventScreenTouch.new();touch.index=12;touch.position=Vector2(420,350);touch.pressed=true;root.push_input(touch,true)
   drag=InputEventScreenDrag.new();drag.index=12;drag.position=Vector2(180,350);drag.relative=Vector2(-240,0);root.push_input(drag,true)
   up=touch.duplicate();up.pressed=false;up.position=drag.position;root.push_input(up,true);await process_frame
   check(panel.scroll.scroll_horizontal>old_scroll and panel.selected=="B00","small-screen raw touch drag scrolls the world without changing selection")
  panel.select_region("B03");await capture("map-"+str(size.x))
  panel.queue_free();await process_frame
 root.size=Vector2i(1280,720)
 # Real pause integration uses each chapter's own visible resume action.
 for chapter in Replay.CHAPTERS:
  var d=fixture(chapter)
  if chapter=="B00":d.quest_flags.append(Quest.INVITATION)
  if chapter=="B01":d.quest_flags.append(Quest.ACCEPTED)
  clean(PATH);store.save(PATH,d);set_meta("journey_save_path",PATH)
  var world=load(Replay.ENTRIES[chapter][2]).instantiate();root.add_child(world);current_scene=world
  for i in 10:await physics_frame
  if chapter=="B01":world.begin_game();await process_frame
  if chapter=="B04":world.set_pause(true)
  elif chapter=="B05":world.toggle_pause()
  else:world.pause_game()
  var saved=model.replay.slot_snapshot(PATH)
  check(host.actual_pause_menu(world),chapter+" real pause is recognized")
  host.open_chapters(world)
  check(is_instance_valid(host.active_modal) and host.active_modal is MapPanel and not world.is_processing_input(),chapter+" pause map blocks underlying input")
  host.active_modal.activate();await process_frame
  check(not is_instance_valid(host.active_modal) and not host.actual_pause_menu(world) and world.is_processing_input(),chapter+" map resumes world and removes its pause panel")
  check(model.replay.slot_snapshot(PATH)==saved,chapter+" pause-map round trip preserves save and backup bytes")
  world.queue_free();current_scene=null;await process_frame
 for path in [PATH,OTHER,model.replay.replay_path(PATH)]:clean(path)
 model.replay.restore_metadata(old_meta)
 var audio=root.get_node_or_null("CatpatAudio")
 if is_instance_valid(audio):audio.shutdown();await create_timer(0.35).timeout
 print("JOURNEY MAP: %d checks, %d failures"%[checks,failures])
 quit(1 if failures else 0)
