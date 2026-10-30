extends SceneTree
const Save=preload("res://scripts/core/save_service.gd")
const Quest=preload("res://scripts/core/quest_state.gd")
const PATH="user://root-v21-lifecycle.json"
var svc=Save.new()
var checks=[]
var failures=[]
func _initialize():call_deferred("run")
func ticks(n):
	for i in n:await physics_frame
func check(ok,id):
	checks.append({"id":id,"ok":ok});print(("PASS " if ok else "FAIL ")+id)
	if not ok:failures.append(id)
func capture(name):
	if "--v21-capture" not in OS.get_cmdline_user_args():return
	if name not in ["00-garden-touch","01-garden-next-chapter","04-summit-main-entry","05-summit-pause-menu","07-resumed-summit"]:return
	await RenderingServer.frame_post_draw
	var frame=root.get_texture().get_image()
	print("VISUAL_CAPTURE:B03-B04-"+name+":"+Marshalls.raw_to_base64(frame.save_webp_to_buffer(true,0.82)))
	if name not in ["00-garden-touch","04-summit-main-entry","05-summit-pause-menu"]:return
	var old_size=root.size
	var scene=current_scene
	var garden=name=="00-garden-touch"
	var old_touch=false
	if garden:
		old_touch=scene.control_display.touch_mode
		scene.control_display.touch_mode=true;scene.control_display.refresh()
	root.size=Vector2i(666,374)
	await process_frame
	await RenderingServer.frame_post_draw
	var small=root.get_texture().get_image()
	check(not small.is_empty() and root.size==Vector2i(666,374),name+"_narrow_render")
	var controls=scene.control_display.buttons if garden else scene.touch_buttons
	var safe=Rect2(0,0,1280,720)
	check(controls.all(func(b):return b.visible and safe.encloses(b.get_global_rect())),name+"_touch_controls_fit")
	if garden:check(scene.hint.get_global_rect().end.y<=670,"B03_hint_clears_bottom_safe_area")
	else:
		check(controls.all(func(b):return b.size.x*374.0/720.0>=56 and b.size.y*374.0/720.0>=56),name+"_touch_targets_at_least_56_viewport_pixels")
		check(controls.all(func(b):return not b.get_rect().intersects(scene.action_button.get_rect()) and not b.get_rect().intersects(scene.subtitle.get_rect())),name+"_movement_controls_clear_action_and_subtitle")
		for i in controls.size():
			check(scene.router.regions[["left","right","jump"][i]]==controls[i].get_rect(),name+"_pointer_region_matches_control_"+str(i))
	print("VISUAL_CAPTURE:B03-B04-small-"+name+":"+Marshalls.raw_to_base64(small.save_webp_to_buffer(true,0.82)))
	root.size=old_size
	if garden:scene.control_display.touch_mode=old_touch;scene.control_display.refresh()
	await process_frame
func run():
	set_meta("journey_save_path",PATH)
	for suffix in ["",".bak",".pending",".bak.pending",".legacy"]:DirAccess.remove_absolute(PATH+suffix)
	var q=Quest.new()
	for e in Quest.EVENTS:
		if e!=Quest.SUMMIT_COMPLETE:q.apply(e)
	var d=svc.fresh();d.chapter_id="B03";d.geometry="garden-v12";d.checkpoint_id="b03.hub";d.quest_flags=q.flags;d.party_ids=q.party_ids();d.settings={"music":false};d.collectibles=["b01.mote.3"]
	d.schema_version=9;d.erase("summit")
	var original=svc.encode(d);var f=FileAccess.open(PATH,FileAccess.WRITE);f.store_string(original);f.close()
	var g=load("res://scenes/garden.tscn").instantiate();root.add_child(g);current_scene=g;await ticks(45)
	check(g.data.schema_version==10 and g.state.has(Quest.GARDEN_COMPLETE),"old_completed_garden_migrates")
	await capture("00-garden-touch")
	print("V21 VIDEO READY")
	check(await g.walk_to(3760,1800),"walk_completed_garden_to_exit")
	await ticks(150);check(g.party_at_exit(),"three_friends_physically_reach_garden_exit")
	await g.use_action();await ticks(20);check(g.mode=="complete","old_completed_save_reopens_exit_panel")
	await capture("01-garden-next-chapter")
	var previous=FileAccess.get_file_as_string(PATH)
	for fault in ["write","rename"]:
		g.saves.fault=fault;g.go_summit();await ticks(10)
		check(current_scene==g and g.mode=="transition_error" and not g.director.transitioning and FileAccess.get_file_as_string(PATH)==previous,"transition_"+fault+"_keeps_garden")
	await capture("02-transition-save-error")
	g.saves.fault="";g.transition_change=func(_scene):return ERR_CANT_OPEN;g.go_summit();await ticks(10)
	check(current_scene==g and svc.load_progress(PATH).data.chapter_id=="B03" and not g.director.transitioning,"scene_failure_rolls_back_source")
	g.transition_change=func(_scene):g.saves.fault="write";return ERR_CANT_OPEN
	g.go_summit();await ticks(10)
	check(current_scene==g and svc.load_progress(PATH).data.chapter_id=="B04" and svc.load_progress(PATH).data.summit.bank==0,"failed_rollback_keeps_safe_target")
	await capture("03-transition-scene-error")
	g.saves.fault="";g.transition_change=Callable();g.go_summit();await ticks(55)
	var r=current_scene
	check(r.get_script().resource_path.ends_with("summit_main.gd") and not r.load_blocked,"actual_B03_to_B04_scene_switch")
	check(not is_instance_valid(g) and r.team.size()==4 and r.team.all(func(a):return r.party.bank_of(a)==0),"entry_has_validated_four_person_party")
	check(r.save_path==PATH and r.save_service.main_data.settings=={"music":false} and r.save_service.main_data.collectibles==["b01.mote.3"],"main_adapter_preserves_path_history_settings")
	check(FileAccess.get_file_as_string(PATH+".legacy")==original,"original_schema9_bytes_preserved")
	r.driver=true;await capture("04-summit-main-entry")
	await r.walk_to(360);await ticks(30);r.interact();await ticks(25)
	for i in 4:
		if r.dialogue_active:r.advance_dialogue();await ticks(25)
	check(r.lantern_stage=="accepted" and svc.load_progress(PATH).data.summit.lantern=="accepted","actual_lantern_dialogue_writes_main_save")
	r.set_pause(true);await ticks(10);await capture("05-summit-pause-menu")
	var expected_facing=-int(svc.load_progress(PATH).data.summit.facing)
	r.safe_facing=expected_facing;r.save_service.fault="write";previous=FileAccess.get_file_as_string(PATH);r.save_menu();await ticks(10)
	check(current_scene==r and r.paused and FileAccess.get_file_as_string(PATH)==previous,"save_menu_failure_keeps_scene_and_bytes")
	r.save_service.fault="";r.save_menu();await ticks(30)
	var menu=current_scene
	check(menu.get_script().resource_path.ends_with("polish_world.gd") and menu.mode=="menu" and menu.save_path==PATH,"actual_main_menu_returns_with_same_save")
	await capture("06-menu-continue")
	menu.begin_game();await ticks(55);r=current_scene;r.driver=true
	check(r.get_script().resource_path.ends_with("summit_main.gd") and r.lantern_stage=="accepted" and r.rope_stage=="loose" and r.waymark_stage=="loose","menu_continue_restores_B04_quest")
	check(r.safe_facing==expected_facing and r.saved_bank==0 and r.team.size()==4,"menu_continue_restores_bank_facing_party")
	await capture("07-resumed-summit")
	var out=FileAccess.open("res://preproduction/qa/v21/root-transition.json",FileAccess.WRITE)
	if out:out.store_string(JSON.stringify({"checks":checks,"failures":failures},"\t"));out.close()
	print("V21 lifecycle ",checks.size()," failures ",failures);quit(0 if failures.is_empty() else 1)
