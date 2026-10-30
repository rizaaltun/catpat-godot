extends SceneTree
const Experience=preload("res://scripts/core/experience_service.gd")
const Store=preload("res://scripts/core/save_service.gd")
const Replay=preload("res://scripts/core/replay_service.gd")
const Quest=preload("res://scripts/core/quest_state.gd")
const PATH="user://chapter-support-ui-test.json"
const PRIMARY="user://chapter-support-ui-primary.json"
const JOURNAL="user://chapter-support-ui-journal.json"
var checks=0
var failures=0
func check(ok:bool,label:String):
 checks+=1
 if not ok:failures+=1
 print("PASS " if ok else "FAIL ",label)
func ticks(count:int):
 for frame in count:await physics_frame
func clean(path:String):
 for suffix in Replay.SLOT_SUFFIXES:DirAccess.remove_absolute(path+suffix)
func capture(tag:String):
 if "--support-capture" not in OS.get_cmdline_user_args():return
 root.size=Vector2i(666,374)
 await process_frame;await RenderingServer.frame_post_draw
 var frame=root.get_texture().get_image()
 check(not frame.is_empty(),tag+" native support frame renders")
 print("VISUAL_CAPTURE:"+tag+":"+Marshalls.raw_to_base64(frame.save_webp_to_buffer(true,0.82)))
 root.size=Vector2i(1280,720)
func _initialize():call_deferred("run")
func run():
 for path in [PATH,PRIMARY,JOURNAL]:clean(path)
 var autoload=root.get_node_or_null("CatpatExperience")
 if autoload:autoload.auto_observe=false
 var service=Experience.new();service.auto_observe=false;root.add_child(service)
 var observer=root.get_node_or_null("CatpatObservations")
 var old_resolver:Callable
 var old_id_resolver:Callable
 if is_instance_valid(observer):
  old_resolver=observer.profile_resolver;old_id_resolver=observer.profile_id_resolver
  observer.profile_resolver=func(path):return {"profile_id":"chapter_support_ui","journey_path":PATH,"journal_path":JOURNAL} if path==PATH else {}
  observer.profile_id_resolver=func(id):return {"profile_id":"chapter_support_ui","journey_path":PATH,"journal_path":JOURNAL} if id=="chapter_support_ui" else {}
 var store=Store.new();var state=Quest.new()
 for event in Quest.HOME_EVENTS+Quest.EVENTS:state.apply(event)
 var full=store.fresh();full.chapter_id="B05";full.geometry="festival-v1";full.checkpoint_id="b05.stage";full.quest_flags=state.flags;full.party_ids=state.party_ids();full.ending_seen=true
 check(store.save(PRIMARY,full),"isolated complete source creates chapter UI fixtures")
 var fixtures={}
 for chapter in Replay.CHAPTERS:fixtures[chapter]=Replay.new().prepare(chapter,PRIMARY)
 var safe=Rect2(0,0,1280,720)
 var game
 for chapter in Replay.CHAPTERS:
  check(store.save(PATH,fixtures[chapter].data),chapter+" incomplete chapter source saves")
  set_meta("journey_save_path",PATH)
  game=load(fixtures[chapter].scene_path).instantiate();root.add_child(game);current_scene=game
  await ticks(5)
  if chapter=="B00":game.accept_invitation()
  if chapter=="B01":game.begin_game();await ticks(2);game.test_dialogue_finish()
  await ticks(3)
  if game.has_method("toggle_pause"):game.toggle_pause()
  elif game.has_method("set_pause"):game.set_pause(true)
  else:game.pause_game()
  service._update_entries(game)
  check(service.actual_pause_menu(game) and service.restart_entry.visible,chapter+" pause exposes current-chapter restart before completion")
  var entries=[service.settings_entry,service.restart_entry]
  if service.help_entry.visible:entries.append(service.help_entry)
  var clear=true
  for i in entries.size():
   clear=clear and safe.encloses(entries[i].get_rect())
   for j in range(i+1,entries.size()):clear=clear and not entries[i].get_rect().intersects(entries[j].get_rect())
   for button in service.buttons_under(game):
    if button not in entries and button.is_visible_in_tree():clear=clear and not button.get_global_rect().intersects(entries[i].get_global_rect())
  check(clear,chapter+" help/restart/settings entries fit and clear native pause controls")
  var count=observer.report_for("chapter_support_ui").events.size() if is_instance_valid(observer) else 0
  service.open_help(game)
  if chapter=="B05":
   check(game.help_panel.visible and game.paused and game.actor.frozen,chapter+" existing native help stays paused")
   service._observe_native_help(game);service._observe_native_help(game)
   game.close_help();service._observe_native_help(game)
  else:
   var panel=service.active_modal
   check(is_instance_valid(panel) and not game.is_processing_input() and not game.is_processing_unhandled_input(),chapter+" task-help modal blocks underlying input")
   await process_frame;await process_frame
   check(panel.body_label.text==service.chapter_support.help_context(game).text and panel.body_label.get_minimum_size().y<=240 and panel.title_label.get_minimum_size().y<=105,chapter+" actual task text and title fit the image panel")
   if chapter in ["B02","B03"]:await capture(chapter+"-pause-help")
   panel.close();await process_frame
  check(service.actual_pause_menu(game),chapter+" closing help returns to pause without auto-resume")
  if is_instance_valid(observer):check(observer.report_for("chapter_support_ui").events.size()==count+1,chapter+" one actual open records exactly one contextual help event")
  var original=Replay.new().slot_snapshot(PATH)
  service.open_restart(game)
  check(is_instance_valid(service.active_modal) and service.active_modal.body_label.text.contains("Yalnız mevcut bölüm yeniden başlar; önceki bölümler korunur"),chapter+" restart requires the explicit preservation confirmation")
  if chapter in ["B01","B05"]:await capture(chapter+"-restart-confirmation")
  service.active_modal.close();await process_frame
  check(Replay.new().slot_snapshot(PATH)==original and service.actual_pause_menu(game),chapter+" cancel leaves exact bytes untouched and remains paused")
  if chapter=="B01":
   service.chapter_support.store.fault="rename"
   service.open_restart(game);service.active_modal.confirm();await process_frame
   check(is_instance_valid(service.active_modal) and service.active_modal.message_label.text.contains("Kaydı değiştirmedik") and Replay.new().slot_snapshot(PATH)==original,chapter+" failed confirmed restart retains modal and restores source bytes")
   service.active_modal.close();await process_frame;service.chapter_support.store.fault=""
  game.queue_free();await process_frame
 # One actual Godot scene replacement checks B01's new incomplete attempt/autostart.
 store.save(PATH,fixtures.B01.data)
 set_meta("journey_save_path",PATH)
 game=load(fixtures.B01.scene_path).instantiate();root.add_child(game);current_scene=game
 game.begin_game();await ticks(2);game.test_dialogue_finish();game.pause_game()
 var old_id=game.get_instance_id()
 service.open_restart(game);service.active_modal.confirm()
 await ticks(15)
 game=current_scene
 check(is_instance_valid(game) and game.get_instance_id()!=old_id and game.mode=="dialogue" and game.runner.active,"confirmed B01 restart navigates and autostarts the actual first dialogue")
 check(Quest.ACCEPTED not in store.load_progress(PATH).data.quest_flags,"actual restarted dialogue has not fabricated its completion")
 game.queue_free();service.queue_free();await process_frame
 if is_instance_valid(observer):observer.profile_resolver=old_resolver;observer.profile_id_resolver=old_id_resolver
 for path in [PATH,PRIMARY,JOURNAL]:clean(path)
 set_meta("journey_save_path","user://festival_v3.json")
 if autoload:autoload.auto_observe=true
 print("CHAPTER SUPPORT UI: %d checks, %d failures"%[checks,failures])
 quit(1 if failures else 0)
