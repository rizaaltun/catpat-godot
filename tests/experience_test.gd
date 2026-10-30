extends SceneTree
const Experience=preload("res://scripts/core/experience_service.gd")
const Store=preload("res://scripts/core/save_service.gd")
const Quest=preload("res://scripts/core/quest_state.gd")
const Replay=preload("res://scripts/core/replay_service.gd")
const PATH="user://experience-contract-test.json"
var checks=0
var failures=0
var service
func check(ok:bool,label:String):
 checks+=1
 if not ok:failures+=1
 print("PASS " if ok else "FAIL ",label)
func ticks(count:int):
 for frame in count:await physics_frame
func clean():
 for suffix in ["", ".bak", ".pending", ".bak.pending", ".legacy"]:DirAccess.remove_absolute(PATH+suffix)
func _initialize():call_deferred("run")
func run():
 clean()
 var existing=root.get_node_or_null("CatpatExperience")
 if existing:existing.auto_observe=false
 service=Experience.new();service.auto_observe=false;root.add_child(service)
 var store=Store.new();var data=store.fresh()
 check(store.save(PATH,data),"experience isolated journey fixture saves")
 set_meta("journey_save_path",PATH)
 var menu=load("res://scenes/polish_v3.tscn").instantiate();root.add_child(menu);current_scene=menu
 await process_frame
 check(service.actual_main_menu(menu),"actual main-menu guard recognizes start controls")
 service.settings=service.preferences.normalize();service._update_entries(menu)
 check(service.settings_entry.visible and service.chapters_entry.visible,"main menu exposes settings and completed chapters")
 var safe=Rect2(0,0,1280,720)
 check(safe.encloses(service.settings_entry.get_rect()) and safe.encloses(service.chapters_entry.get_rect()) and not service.settings_entry.get_rect().intersects(service.chapters_entry.get_rect()),"menu entry buttons fit logical viewport and do not overlap")
 var entries_clear=true
 for button in service.buttons_under(menu.screen):
  entries_clear=entries_clear and not button.get_global_rect().intersects(service.settings_entry.get_global_rect()) and not button.get_global_rect().intersects(service.chapters_entry.get_global_rect())
 check(entries_clear,"new menu entries clear all established menu buttons")
 menu.show_help();service._update_entries(menu)
 check(not service.settings_entry.visible and not service.chapters_entry.visible,"help is not mistaken for the main menu despite its legacy mode value")
 menu.show_menu()
 service.open_settings(menu)
 check(is_instance_valid(service.active_modal) and not menu.is_processing_input() and not menu.is_processing_unhandled_input(),"settings modal blocks host input")
 check(service.modal_layer.layer==100,"settings uses the top modal layer")
 service.active_modal.close();await process_frame
 check(menu.mode=="menu" and menu.is_processing_input(),"closing settings restores the menu input state")
 menu.begin_game();await ticks(3)
 service._update_entries(menu)
 check(not service.settings_entry.visible and not service.chapters_entry.visible,"gameplay/dialogue do not gain global settings clutter")
 check(menu.mode=="dialogue" and menu.runner.active,"B01 begins in a real meeting dialogue")
 var prefs=service.preferences.normalize({"text_speed":0.75,"text_scale":1.3,"full_text":false})
 var raw_settings_before=store.load_progress(PATH).data.settings.duplicate(true)
 service.apply_to_scene(menu,prefs)
 check(menu.settings==raw_settings_before and store.load_progress(PATH).data.settings==raw_settings_before,"visual defaults do not silently expand persisted chapter settings")
 menu.runner.revealed=false;menu.type_chars=0.0
 menu._process(0.1);service._apply_dialogue(menu,0.1)
 check(absf(menu.type_chars-2.55)<0.01,"text-speed preference changes actual B01 reveal pace")
 service.settings.full_text=true;service._apply_dialogue(menu,0.1)
 check(menu.runner.revealed and menu.line_text.visible_characters==-1,"full-text preference reveals the actual current dialogue")
 check(is_instance_valid(service.reader_text) and service.reader_text.text==menu.runner.current.text and service.reader_text.get_theme_font_size("font_size")==35,"large-text preference uses a live image-backed dialogue reader")
 await process_frame
 check(service.reader_text.get_minimum_size().y<=350 and safe.encloses(service.reader_text.get_rect()),"scaled dialogue reader text fits its reserved logical area")
 service.settings=service.preferences.normalize({"reduced_motion":true});service.apply_to_scene(menu,service.settings)
 check(not menu.camera.position_smoothing_enabled,"reduced motion disables the scene camera easing")
 menu.player.impact=1;menu.player.motion_time=2;service._apply_reduced_decorations(menu)
 check(menu.player.impact==0 and menu.player.anim.scale==Vector2.ONE*0.125,"reduced motion removes decorative actor squash without stopping gameplay")
 # Explicit replay guard: initial B01 menu must not return before its deferred dialogue.
 set_meta("replay_primary_path",PATH);set_meta("replay_chapter","B01");set_meta("replay_autostart",true)
 menu.show_menu()
 check(not service.guard_replay_return(menu) and has_meta("replay_primary_path"),"initial replayB01 menu waits for deferred autostart")
 menu.begin_game();await ticks(2)
 check(menu.mode=="dialogue" and not service.guard_replay_return(menu) and not has_meta("replay_autostart"),"dialogue-first replay entry clears the autostart guard")
 var original=FileAccess.get_file_as_bytes(PATH)
 menu.show_menu()
 check(service.guard_replay_return(menu) and not has_meta("replay_primary_path") and menu.save_path==PATH,"natural replay menu return restores the primary path and rerenders menu")
 check(FileAccess.get_file_as_bytes(PATH)==original,"replay return never modifies primary journey bytes")
 menu.queue_free();await process_frame
 var state=Quest.new()
 for id in Quest.EVENTS:
  if id in Quest.FESTIVAL_EVENTS:continue
  state.apply(id)
 data=store.fresh();data.chapter_id="B05";data.geometry="festival-v1";data.checkpoint_id="b05.entry";data.quest_flags=state.flags;data.party_ids=state.party_ids();data.summit={}
 check(store.save(PATH,data),"B05 fixture saves for settings lifecycle")
 var festival=load("res://scenes/festival.tscn").instantiate();root.add_child(festival);current_scene=festival
 await ticks(12)
 service.settings=service.preferences.normalize({"control_scale":1.3,"left_handed":true,"music":0.25})
 service.preferences.save(PATH,{"music":0.25})
 service.apply_to_scene(festival,service.settings)
 check(festival.save_data.settings.music==0.25,"applied preferences also update the chapter snapshot used by later progress saves")
 var controls=festival.control_display.buttons
 check(controls.all(func(button):return safe.encloses(button.get_rect())),"largest left-handed controls stay inside the viewport")
 var separated=true
 for i in controls.size():
  for j in range(i+1,controls.size()):separated=separated and not controls[i].get_rect().intersects(controls[j].get_rect())
 check(separated,"largest controls do not overlap one another")
 var hint_backing=service._hint_backing(festival.controls_hint)
 check(is_instance_valid(hint_backing) and controls.all(func(button):return not button.get_rect().intersects(hint_backing.get_rect())),"central hint image backing reflows clear of enlarged controls")
 var router=festival.input_router
 check(router.regions.left.position.x>640 and router.regions.jump.position.x<640 and router.regions.left.position.x<router.regions.right.position.x,"left-handed layout swaps groups while preserving left/right arrow order")
 check(router.owners.is_empty() and controls.all(func(button):return router.regions.values().has(button.get_rect())),"control reflow clears input ownership and matches actual pointer rectangles")
 service._update_entries(festival)
 check(not service.settings_entry.visible,"B05 gameplay has no global settings button")
 festival.toggle_pause();service._update_entries(festival)
 check(service.settings_entry.visible and not service.chapters_entry.visible,"actual B05 pause menu exposes only settings")
 service.open_settings(festival);service.active_modal.close();await process_frame
 check(festival.paused and festival.pause_panel.visible,"closing settings preserves an existing B05 pause")
 festival.toggle_pause();service.open_settings(festival)
 check(festival.paused and festival.actor.frozen,"programmatic settings opening pauses the live actor")
 service.active_modal.close();await process_frame
 check(not festival.paused and not festival.actor.frozen,"closing programmatic settings restores prior play state")
 var held=InputEventScreenTouch.new();held.index=91;held.pressed=true;held.position=festival.input_router.regions.left.get_center()
 festival._input(held)
 check(festival.input_router.owners.has(91) and festival.left_pressed,"actual B05 finger owns movement before web-window blur")
 service._notification(Node.NOTIFICATION_WM_WINDOW_FOCUS_OUT)
 check(festival.paused and festival.actor.frozen and festival.input_router.owners.is_empty() and not festival.left_pressed,"window focus loss forwards to actual B05 pause/input reset")
 var audio=root.get_node_or_null("CatpatAudio")
 check(not is_instance_valid(audio) or audio.backgrounded,"window focus loss backgrounds audio when the singleton exists")
 service._notification(Node.NOTIFICATION_WM_WINDOW_FOCUS_OUT)
 check(festival.paused and festival.pause_panel.visible,"repeated window focus loss has no toggle/resume side effect")
 service._notification(Node.NOTIFICATION_WM_WINDOW_FOCUS_IN)
 check(festival.paused and festival.actor.frozen and (not is_instance_valid(audio) or not audio.backgrounded),"window focus gain clears only audio background state and leaves gameplay paused")
 festival.toggle_pause()
 festival.notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
 service._notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
 service._notification(Node.NOTIFICATION_WM_WINDOW_FOCUS_OUT)
 check(festival.paused and festival.input_router.owners.is_empty(),"an application focus loss already received is not toggled by the window bridge")
 service._notification(Node.NOTIFICATION_WM_WINDOW_FOCUS_IN)
 festival.toggle_pause()
 festival.show_final();service._update_entries(festival)
 check(not service.settings_entry.visible,"final story is not mistaken for pause settings")
 festival.final_panel.hide();festival.set_game_paused(false);festival.toggle_pause();festival.show_help();service._update_entries(festival)
 check(not service.settings_entry.visible,"B05 task help is not mistaken for the pause menu")
 festival.queue_free();service.queue_free();await process_frame
 clean()
 set_meta("journey_save_path","user://festival_v3.json")
 if existing:existing.auto_observe=true
 print("EXPERIENCE CONTRACT: %d checks, %d failures"%[checks,failures])
 quit(1 if failures else 0)
