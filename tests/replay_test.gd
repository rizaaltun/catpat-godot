extends SceneTree
const Save=preload("res://scripts/core/save_service.gd")
const Quest=preload("res://scripts/core/quest_state.gd")
const Replay=preload("res://scripts/core/replay_service.gd")
const ChapterPanel=preload("res://scripts/ui/chapter_select_panel.gd")
const PRIMARY="user://replay-contract-primary.json"
const LOCKED="user://replay-contract-locked.json"
var checks=0
var failures=0
var service=Replay.new()
var active_scene:Node
func _initialize():call_deferred("run")
func check(ok:bool,label:String):
 checks+=1
 if not ok:failures+=1
 print("PASS " if ok else "FAIL ",label)
func ticks(n:int):
 for i in n:await physics_frame
func clean_path(path:String):
 for suffix in Replay.SLOT_SUFFIXES:
  if FileAccess.file_exists(path+suffix):DirAccess.remove_absolute(path+suffix)
func completed_fixture() -> Dictionary:
 var state=Quest.new()
 for event in Quest.HOME_EVENTS+Quest.EVENTS:state.apply(event)
 var data=Save.new().fresh()
 data.chapter_id="B05";data.geometry="festival-v1";data.checkpoint_id="b05.stage"
 data.quest_flags=state.flags.duplicate();data.party_ids=state.party_ids();data.ending_seen=true
 data.collectibles=["b00.ribbon","b01.mote.2"]
 data.settings={"music":0.25,"sfx":0.5,"reduced_motion":true,"onboarding_origin":"new-journey-v1"}
 return data
func bytes_at(path:String) -> PackedByteArray:
 return FileAccess.get_file_as_bytes(path) if FileAccess.file_exists(path) else PackedByteArray()
func capture(tag:String):
 if "--replay-capture" not in OS.get_cmdline_user_args():return
 await process_frame;await RenderingServer.frame_post_draw
 var shot=root.get_texture().get_image()
 check(not shot.is_empty(),tag+" real replay menu renders")
 print("VISUAL_CAPTURE:replay-"+tag+":"+Marshalls.raw_to_base64(shot.save_webp_to_buffer(true,0.82)))
func open_scene(path:String) -> int:
 var packed=load(path)
 if not packed is PackedScene:return ERR_CANT_OPEN
 active_scene=packed.instantiate();root.add_child(active_scene);current_scene=active_scene
 return OK
func run():
 # Host auto-observation has its own integration suite; keep these callback seams isolated.
 var host=root.get_node_or_null("CatpatExperience")
 if host:host.auto_observe=false
 for path in [PRIMARY,LOCKED,service.replay_path(PRIMARY),service.replay_path(LOCKED)]:clean_path(path)
 for key in Replay.META_KEYS:
  if has_meta(key):remove_meta(key)
 check(service.completed_chapters(PRIMARY).is_empty() and not service.start("B01",PRIMARY,func(_p):return OK).ok,"missing source cannot unlock or create replay")
 var store=Save.new()
 var primary=completed_fixture()
 check(store.valid(primary) and store.save(PRIMARY,primary),"completed B00–B05 fixture validates and saves")
 primary.settings.sfx=0.75
 check(store.save(PRIMARY,primary),"primary backup is present before replay")
 var original=bytes_at(PRIMARY);var backup=bytes_at(PRIMARY+".bak")
 check(not backup.is_empty(),"primary backup has real immutable test bytes")
 check(service.completed_chapters(PRIMARY)==Replay.CHAPTERS,"only genuinely completed chapters appear in order")
 for chapter in Replay.CHAPTERS:
  var prepared=service.prepare(chapter,PRIMARY)
  check(prepared.ok and store.valid(prepared.data),chapter+" fresh replay snapshot passes canonical schema gate")
  check(prepared.data==service.prepare(chapter,PRIMARY).data,chapter+" preparation is deterministic")
  check(Replay.COMPLETION[chapter] not in prepared.data.quest_flags and not prepared.data.ending_seen,chapter+" target completion is reset")
  check(prepared.data.settings==primary.settings,chapter+" preserves journey preferences without aliasing")
  prepared.data.settings.music=0.9
  check(primary.settings.music==0.25,chapter+" settings snapshot is detached from source")
  var started=service.start(chapter,PRIMARY,open_scene)
  check(started.ok and started.path!=PRIMARY and started.path!=PRIMARY+".bak",chapter+" launches through isolated replay navigation")
  await ticks(18)
  check(is_instance_valid(active_scene) and active_scene.save_path==started.path,chapter+" actual chapter reads the replay slot")
  match chapter:
   "B00":check(not active_scene.blocked and active_scene.modal.visible and active_scene.paused,"B00 replay opens real invitation gate")
   "B01":check(not active_scene.load_issue and not active_scene.completed and active_scene.mode=="dialogue","B01 replay autostarts the actual first meeting")
   "B02","B03":check(active_scene.mode!="error" and active_scene.data.chapter_id==chapter,chapter+" actual entry accepts prerequisites and party")
   "B04":check(not active_scene.load_blocked and active_scene.team.size()==4 and active_scene.lantern_stage=="unseen" and active_scene.rope_stage=="loose" and active_scene.waymark_stage=="loose","B04 replay restores four-person entry without completed internal tasks")
   "B05":check(not active_scene.blocked and not active_scene.paused and active_scene.partner_sprites.size()==3,"B05 replay starts three fresh contribution tasks")
  var replay_data=store.load_progress(started.path).data
  replay_data.settings.sfx=0.1
  check(store.save(started.path,replay_data),chapter+" can write replay progress/preferences independently")
  check(bytes_at(PRIMARY)==original and bytes_at(PRIMARY+".bak")==backup,chapter+" leaves primary and backup byte-identical")
  current_scene=null;active_scene.queue_free();await process_frame
  var returned=service.return_to_primary(func(path):return OK if path=="res://scenes/polish_v3.tscn" else ERR_CANT_OPEN)
  check(returned.ok and get_meta("journey_save_path")==PRIMARY and not has_meta("replay_primary_path") and not has_meta("journey_autostart"),chapter+" returns safely to primary menu metadata")
 var slot=service.replay_path(PRIMARY)
 check(service.start("B02",PRIMARY,func(_p):return OK).ok,"active replay opens for rollback checks")
 var old_meta=service.metadata_snapshot();var old_slot=service.slot_snapshot(slot)
 var rejected=service.start("B03",slot,func(_p):return ERR_CANT_OPEN)
 check(not rejected.ok and rejected.slot_restored and service.metadata_snapshot()==old_meta and service.slot_snapshot(slot)==old_slot,"failed nested replay navigation restores slot and all prior metadata")
 rejected=service.start("B01",PRIMARY,func(_p):return null)
 check(not rejected.ok and service.metadata_snapshot()==old_meta and service.slot_snapshot(slot)==old_slot,"navigation without an explicit success code cannot enter replay")
 check(service.primary_path(slot)==PRIMARY and service.completed_chapters(slot)==Replay.CHAPTERS,"active replay always resolves availability against the primary journey")
 service.store.fault="write"
 rejected=service.start("B04",PRIMARY,func(_p):return OK)
 check(not rejected.ok and rejected.slot_restored and service.metadata_snapshot()==old_meta and service.slot_snapshot(slot)==old_slot,"failed replay write preserves previous replay and metadata")
 service.store.fault=""
 check(not service.return_to_primary(func(_p):return ERR_CANT_OPEN).ok and service.metadata_snapshot()==old_meta,"failed primary-menu navigation leaves replay return route intact")
 check(service.return_to_primary(func(_p):return OK).ok,"retry returns to the primary journey")
 check(bytes_at(PRIMARY)==original and bytes_at(PRIMARY+".bak")==backup,"failure/retry paths never write primary or backup")
 var locked=store.fresh();check(store.save(LOCKED,locked),"unfinished fixture saves")
 check(service.completed_chapters(LOCKED).is_empty() and not service.start("B01",LOCKED,func(_p):return OK).ok,"unfinished chapter never unlocks itself")
 for origin in ["legacy-bypass-v1","user-skipped-v1"]:
  locked=store.fresh();locked.quest_flags=Quest.HOME_EVENTS.duplicate();locked.settings.onboarding_origin=origin
  store.save(LOCKED,locked)
  check("B00" not in service.completed_chapters(LOCKED),origin+" is not misreported as a played tutorial")
 for suffix in ["",".bak"]:
  var file=FileAccess.open(LOCKED+suffix,FileAccess.WRITE);file.store_string("{broken");file.close()
 var corrupt=bytes_at(LOCKED);var corrupt_backup=bytes_at(LOCKED+".bak")
 check(service.completed_chapters(LOCKED).is_empty() and not service.start("B00",LOCKED,func(_p):return OK).ok,"corrupt primary and backup cannot unlock replay")
 check(bytes_at(LOCKED)==corrupt and bytes_at(LOCKED+".bak")==corrupt_backup,"corrupt source bytes are preserved")
 var file=FileAccess.open(LOCKED+".bak",FileAccess.WRITE);file.store_string(store.encode(completed_fixture()));file.close()
 var good_backup=bytes_at(LOCKED+".bak")
 check(service.completed_chapters(LOCKED)==Replay.CHAPTERS,"a validated backup can supply completed chapters without repairing the corrupt primary")
 check(not service.start("B05",LOCKED,func(_p):return ERR_CANT_OPEN).ok and bytes_at(LOCKED)==corrupt and bytes_at(LOCKED+".bak")==good_backup,"backup-based navigation failure preserves both source files byte-for-byte")
 var panel=ChapterPanel.new();root.add_child(panel);panel.setup(PRIMARY,func():pass,func(_p):return ERR_CANT_OPEN)
 await process_frame
 check(panel.buttons.size()==7 and panel.buttons.all(func(b):return b.get_theme_stylebox("normal") is StyleBoxTexture),"six completed chapters and back use actual image skins")
 var no_overlap=true
 for i in panel.buttons.size():
  for j in range(i+1,panel.buttons.size()):
   if panel.buttons[i].get_rect().intersects(panel.buttons[j].get_rect()):no_overlap=false
 check(no_overlap,"chapter selection buttons do not overlap after font minimum-size calculation")
 check(panel.buttons.all(func(b):return b.get_theme_font("font").get_string_size(b.text,HORIZONTAL_ALIGNMENT_LEFT,-1,b.get_theme_font_size("font_size")).x<=b.size.x-24),"live Turkish chapter labels fit their actual image buttons")
 panel.start_chapter("B01")
 check(not panel.status_label.text.is_empty() and is_instance_valid(panel),"failed selection remains visible with a safe retry explanation")
 await capture("wide")
 var old_size=root.size;root.size=Vector2i(666,374);await process_frame
 check(panel.buttons.all(func(b):return Rect2(0,0,1280,720).encloses(b.get_rect())),"chapter selection controls stay inside narrow logical viewport")
 await capture("small")
 root.size=old_size;panel.queue_free();await process_frame
 check(bytes_at(PRIMARY)==original and bytes_at(PRIMARY+".bak")==backup,"selection UI never changes primary journey bytes")
 for path in [PRIMARY,LOCKED,service.replay_path(PRIMARY),service.replay_path(LOCKED)]:clean_path(path)
 for key in Replay.META_KEYS:
  if has_meta(key):remove_meta(key)
 print("REPLAY CONTRACT: %d checks, %d failures"%[checks,failures])
 quit(1 if failures else 0)
