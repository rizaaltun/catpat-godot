extends SceneTree
const Store=preload("res://scripts/core/save_service.gd")
const Q=preload("res://scripts/core/quest_state.gd")
const Adapter=preload("res://scripts/core/main_route_save.gd")
var svc=Store.new()
var checks=[]
var failures=[]
var path="user://independent-v21-scene-"+str(Time.get_ticks_usec())+".json"
func _initialize():call_deferred("run")
func check(ok,id):
	checks.append({"id":id,"ok":ok});print(("PASS " if ok else "FAIL ")+id)
	if not ok:failures.append(id)
func ticks(n=10):
	for i in n:await physics_frame
func garden_state():
	var d=svc.fresh();var q=Q.new()
	for e in Q.EVENTS:
		if e!=Q.SUMMIT_COMPLETE:q.apply(e)
	d.chapter_id="B03";d.geometry="garden-v12";d.checkpoint_id="b03.exit";d.quest_flags=q.flags.duplicate();d.party_ids=q.party_ids();d.settings={"music":0.3,"touch":true};d.collectibles=["b01.mote.0","b01.mote.2"];return d
func summit_state():
	var d=garden_state();d.chapter_id="B04";d.geometry="shared-v16";d.checkpoint_id="b04.bank.0";d.summit=Store.Summit.fresh();return d
func clear():
	if is_instance_valid(current_scene):current_scene.queue_free()
	await process_frame;await process_frame
func start(scene):
	await clear();var node=load(scene).instantiate();root.add_child(node);current_scene=node;await ticks();return node
func write_fixture(d):
	for suffix in ["",".bak",".pending",".legacy"]:DirAccess.remove_absolute(path+suffix)
	check(svc.save(path,d),"seed_"+str(checks.size()))
func run():
	set_meta("journey_save_path",path)
	var main_default="user://festival_v3.json";var default_exists=FileAccess.file_exists(main_default);var default_bytes=FileAccess.get_file_as_bytes(main_default) if default_exists else PackedByteArray()
	write_fixture(garden_state());var garden=await start("res://scenes/garden.tscn")
	check(garden.save_path==path and garden.mode=="play" and garden.state.has(Q.GARDEN_COMPLETE),"B03_completed_load_scoped")
	garden.complete();check(garden.mode=="complete","completion_panel")
	var before=FileAccess.get_file_as_string(path)
	for fault in ["write","rename"]:
		garden.saves.fault=fault;garden.go_summit();check(garden.mode=="transition_error" and not garden.director.transitioning and FileAccess.get_file_as_string(path)==before,"transition_"+fault+"_keeps_B03")
	garden.saves.fault="";garden.transition_change=func(_scene):return ERR_CANT_CREATE
	garden.go_summit();check(garden.mode=="transition_error" and svc.load_progress(path).data.chapter_id=="B03" and not garden.director.transitioning,"scene_failure_rolls_back_B03")
	garden.transition_change=func(_scene):garden.saves.fault="write";return ERR_CANT_CREATE
	garden.go_summit();check(garden.mode=="transition_error" and svc.load_progress(path).data.chapter_id=="B04" and svc.load_progress(path).data.summit==JSON.parse_string(JSON.stringify(Store.Summit.fresh())),"rollback_failure_keeps_safe_B04")
	garden.saves.fault="";garden.transition_change=Callable();garden.go_summit();await process_frame;await process_frame;await ticks(20)
	var summit=current_scene
	check(summit.get_script().resource_path.ends_with("summit_main.gd") and not summit.load_blocked and summit.team.size()==4,"retry_real_scene_load_four")
	check(summit.save_path==path and summit.save_service is Adapter and summit.safe_bank==0,"main_adapter_scoped")
	check(summit.save_service.main_data.settings==garden_state().settings and summit.save_service.main_data.collectibles==garden_state().collectibles,"history_and_settings_kept")
	before=FileAccess.get_file_as_string(path)
	for fault in ["write","rename"]:
		summit.save_service.fault=fault;check(not summit.commit_quest("accepted") and summit.lantern_stage=="unseen" and FileAccess.get_file_as_string(path)==before,"quest_"+fault+"_no_visible_advance")
	summit.save_service.fault="";check(summit.commit_quest("accepted") and svc.load_progress(path).data.summit.lantern=="accepted","lantern_commits_main")
	summit.set_pause(true);summit.safe_bank=1;summit.safe_facing=-1;before=FileAccess.get_file_as_string(path);var menu_calls=[0]
	summit.menu_change=func():menu_calls[0]+=1;return ERR_CANT_CREATE
	summit.save_service.fault="write";summit.save_menu();check(menu_calls[0]==0 and FileAccess.get_file_as_string(path)==before and summit.paused,"pause_save_failure_blocks_menu")
	summit.save_service.fault="";summit.save_menu();check(menu_calls[0]==1 and svc.load_progress(path).data.summit.bank==1 and summit.paused,"menu_scene_failure_preserves_committed_snapshot")
	summit.menu_change=Callable();summit.save_menu();await process_frame;await process_frame;await ticks()
	var menu=current_scene;check(menu.get_script().resource_path.ends_with("polish_world.gd") and menu.save_path==path,"real_menu_lifecycle_scoped")
	menu.begin_game();await process_frame;await process_frame;await ticks(20);summit=current_scene
	check(not summit.load_blocked and summit.lantern_stage=="accepted" and summit.safe_bank==1 and summit.team.size()==4,"menu_continue_restores_main_checkpoint")
	# Adapter finale mapping uses a fixture; no claim of natural route movement.
	var route=summit.progress_snapshot();route.bank=2;route.lantern="lit";route.rope="ready";route.waymark="seen"
	check(summit.save_service.save(path,route),"adapter_seen_write")
	var done=svc.load_progress(path).data
	check(Q.SUMMIT_COMPLETE in done.quest_flags and done.summit.waymark=="seen" and done.quest_flags.has(Q.GARDEN_COMPLETE) and done.settings==garden_state().settings and done.collectibles==garden_state().collectibles,"seen_flag_whole_history")
	check(summit.save_service.save(path,route) and svc.load_progress(path).data.quest_flags.count(Q.SUMMIT_COMPLETE)==1,"seen_idempotent")
	route.waymark="ready";check(not summit.save_service.save(path,route) and svc.load_progress(path).data.summit.waymark=="seen","adapter_reject_completion_rollback")
	await clear()
	# Fail closed before actor construction; no unrelated preview progress read.
	for kind in ["missing","B03","missing_party","corrupt"]:
		for suffix in ["",".bak",".pending"]:DirAccess.remove_absolute(path+suffix)
		if kind=="B03":svc.save(path,garden_state())
		elif kind=="missing_party":
			var bad=summit_state();bad.party_ids=["badger","monkey"];svc.write_text(path,svc.encode(bad))
		elif kind=="corrupt":svc.write_text(path,"broken")
		var bad_scene=await start("res://scenes/summit.tscn")
		check(bad_scene.load_blocked and bad_scene.team.is_empty() and not is_instance_valid(bad_scene.player),"blocked_no_spawn_"+kind)
		await clear()
	check(FileAccess.file_exists(main_default)==default_exists and (not default_exists or FileAccess.get_file_as_bytes(main_default)==default_bytes),"default_save_untouched")
	var f=FileAccess.open("res://preproduction/qa/v21/independent-scene-results.json",FileAccess.WRITE);f.store_string(JSON.stringify({"checks":checks,"failures":failures},"\t"));f.close()
	print("INDEPENDENT V21 SCENE DONE ",checks.size()," failures ",failures);quit(0 if failures.is_empty() else 1)
