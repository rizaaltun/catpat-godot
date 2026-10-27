extends SceneTree
const Route=preload("res://scripts/chapters/summit_main.gd")
const Main=preload("res://scripts/core/save_service.gd")
const PATH="user://root-v21-main-quest.json"
var route
var results=[]
var failed=[]
func _initialize():call_deferred("run")
func ticks(n):
	for i in n:await physics_frame
func check(ok,id,detail={}):
	results.append({"id":id,"ok":ok,"detail":detail});print(("PASS " if ok else "FAIL ")+id+" "+str(detail))
	if not ok:failed.append(id)
func capture(label):
	if "--v21-capture" not in OS.get_cmdline_user_args():return
	if label not in ["04-monkey-comic-first","06-winch-ready","14-shared-route-finish"]:return
	await RenderingServer.frame_post_draw
	var frame=root.get_texture().get_image()
	print("VISUAL_CAPTURE:B04-"+label+":"+Marshalls.raw_to_base64(frame.save_webp_to_buffer(true,0.82)))
func create_route():
	get_tree_dummy()
	if not FileAccess.file_exists(PATH):
		var s=Main.new();var q=Main.Quest.new()
		for e in Main.Quest.EVENTS:
			if e!=Main.Quest.SUMMIT_COMPLETE:q.apply(e)
		var d=s.fresh();d.chapter_id="B04";d.geometry="shared-v16";d.checkpoint_id="b04.bank.0";d.quest_flags=q.flags;d.party_ids=q.party_ids();d.summit=Main.Summit.fresh();d.settings={"music":false};d.collectibles=["b01.mote.2"];s.save(PATH,d)
	route=Route.new();route.save_path=PATH;root.add_child(route);route.driver=true
func get_tree_dummy():set_meta("journey_save_path",PATH)
func dialogue_to_end():
	for i in 4:
		await ticks(30)
		if route.dialogue_active:route.advance_dialogue()
func at_target(position:Vector2, grounded:bool, point:Vector2) -> bool:
	return grounded and absf(position.y-point.y)<6 and absf(position.x-point.x)<15

func jump_to(point:Vector2) -> bool:
	route.player.jump_request=true;route.player.jump_held=true
	for f in 150:
		route.steer_to(point.x);await ticks(1)
		if f>10 and at_target(route.player.position,route.player.is_on_floor(),point):break
	route.player.jump_held=false;route.player.input_axis=0;await ticks(12)
	return at_target(route.player.position,route.player.is_on_floor(),point)
func descend_to_lantern():
	await route.walk_to(650)
	for i in 1200:
		await ticks(1)
		if route.carriers[0].fraction>0.99 and route.carriers[0].dwell>1.0:break
	await route.walk_to(800);await ticks(50);await route.walk_to(650);await ticks(50)
func run():
	if "--v21-restore" in OS.get_cmdline_user_args():
		create_route();await ticks(50)
		check(route.rope_stage=="ready" and route.lantern_stage=="lit","process_restores_both_quests")
		check(route.saved_bank==2 and route.team.all(func(a):return route.party.bank_of(a)==2),"process_restores_far_party")
		check(route.carriers[1].enabled and not route.coil.visible and not route.carried_coil.visible and route.tied_coil.visible,"process_restores_exact_rope_and_carrier")
		check(route.waymark_stage=="seen" and route.mounted_arrow.visible and not route.carried_arrow.visible and not route.fallen_arrow.visible,"process_restores_seen_single_arrow")
		finish("restore");return
	for suffix in ["",".bak",".pending",".bak.pending",".legacy"]:DirAccess.remove_absolute(PATH+suffix)
	create_route();await ticks(45);print("V21 VIDEO READY")
	check(not at_target(Vector2(120,620),true,Vector2(150,620)),"landing_at_wrong_x_is_not_arrival")
	var locked=route.carriers[1].position;await ticks(45)
	check(route.rope_stage=="loose" and route.carriers[1].position==locked,"new_second_carrier_stopped")
	await route.walk_to(600);route.interact();await ticks(25)
	check(route.rope_stage=="loose" and not route.carried_coil.visible,"rope_requires_lantern")
	await route.walk_to(360);await ticks(30);route.interact();await dialogue_to_end()
	check(route.lantern_stage=="accepted","lantern_intro_still_works")
	await descend_to_lantern();route.interact();await ticks(30)
	check(route.lantern_stage=="prepared","physical_lantern_preparation")
	check(await jump_to(Vector2(800,620)) and await jump_to(Vector2(630,540)),"lantern_return_jumps")
	await route.walk_to(360);await ticks(30);route.interact();await dialogue_to_end()
	check(route.lantern_stage=="lit" and route.rope_stage=="loose","lantern_unlocks_rope_goal")
	await route.walk_to(600);await ticks(25);await capture("01-rope-pickup")
	route.interact();await ticks(30)
	check(route.rope_stage=="carried" and route.carried_coil.visible and not route.coil.visible,"rope_pickup_single_item")
	await descend_to_lantern()
	check(route.rope_stage=="carried" and route.player.position.y>700,"fall_keeps_carried_rope")
	check(await jump_to(Vector2(800,620)) and await jump_to(Vector2(630,540)),"carried_rope_return_jumps")
	route.set_pause(true);route.reload_checkpoint();await ticks(40)
	check(route.rope_stage=="carried" and route.carried_coil.visible and not route.coil.visible,"carried_reload_no_duplicate")
	check(await route.cross_shared(0,1),"carry_rope_on_first_carrier")
	await route.walk_to(1760);check(await route.wait_for_team(1),"party_reunites_at_winch_shore")
	await capture("02-winch-loose")
	await route.walk_to(1810);await ticks(30)
	route.save_service.fault="write";route.interact();await ticks(30)
	check(route.rope_stage=="carried" and not route.carriers[1].enabled,"failed_place_preserves_rope_and_lock")
	route.save_service.fault="";route.interact();await ticks(30)
	check(route.rope_stage=="requested" and route.tied_coil.visible and not route.carried_coil.visible,"rope_placed_at_winch")
	await capture("03-winch-requested")
	route.set_pause(true);route.reload_checkpoint();await ticks(40)
	check(route.rope_stage=="requested" and not route.carriers[1].enabled,"requested_reload_not_auto_ready")
	# Follow the moving companion with inputs; a stale coordinate is not an approach.
	for i in 480:
		route.steer_to(route.team[3].position.x+165);await ticks(1)
		if route.close_to_monkey() and absf(route.player.velocity.x)<8:break
	route.player.input_axis=0;await ticks(30)
	check(route.close_to_monkey(),"physically_approach_monkey",{"positions":route.team.map(func(a):return str(a.position))})
	route.interact();await ticks(30);await capture("04-monkey-comic-first")
	check(route.dialogue_active and route.comic.names.right=="Maymun","opposing_monkey_dialogue")
	route.advance_dialogue();await ticks(30);await capture("05-monkey-comic-last")
	route.cancel_dialogue();await ticks(30)
	check(route.rope_stage=="requested" and not route.carriers[1].enabled,"cancel_keeps_carrier_locked")
	route.interact();await dialogue_to_end();await ticks(60)
	check(route.rope_stage=="ready" and route.carriers[1].enabled and route.tow_line.visible,"repair_activates_carrier_and_line")
	check(route.save_service.load_progress(PATH).data.rope=="ready","ready_durable_before_crossing")
	await route.walk_to(1870);await ticks(30);await capture("06-winch-ready")
	check(await route.cross_shared(1,1),"repaired_second_carrier_crossing")
	await route.walk_to(2960);check(await route.wait_for_team(2),"three_friends_cross_repaired_pass")
	await ticks(40);await capture("07-party-arrival")
	check(route.saved_bank==2 and route.save_service.load_progress(PATH).data.rope=="ready","far_checkpoint_keeps_repair")
	check(not route.commit_rope("ready") and route.rope_events.count("ready")==1,"repair_completion_idempotent")
	await route.walk_to(2510)
	for i in 1200:
		await ticks(1)
		if route.carriers[1].fraction<0.01 and route.carriers[1].dwell>1.0:break
	await route.walk_to(2340);await ticks(50);await route.walk_to(2480);await ticks(120)
	check(route.near_ground_point(route.ARROW_POINT,75),"physical_descent_to_fallen_arrow",{"position":str(route.player.position)})
	await capture("08-fallen-arrow")
	route.interact();await ticks(30)
	check(route.waymark_stage=="carried" and route.carried_arrow.visible and not route.fallen_arrow.visible,"arrow_pickup_single_instance")
	check(await jump_to(Vector2(2340,620)) and await jump_to(Vector2(2510,540)),"carry_arrow_two_return_jumps")
	await route.walk_to(2590);await ticks(30);await capture("09-carry-to-post")
	route.save_service.fault="write";route.interact();await ticks(30)
	check(route.waymark_stage=="carried" and not route.mounted_arrow.visible,"failed_arrow_place_keeps_item")
	route.save_service.fault="";route.interact();await ticks(30)
	check(route.waymark_stage=="placed" and route.mounted_arrow.visible and not route.carried_arrow.visible,"place_arrow_on_post")
	route.set_pause(true);route.reload_checkpoint();await ticks(40)
	check(route.waymark_stage=="placed" and route.rope_stage=="ready" and route.lantern_stage=="lit","reload_preserves_three_quest_snapshot")
	for i in 480:
		route.steer_to(route.team[1].position.x+165);await ticks(1)
		if route.close_to_rabbit() and absf(route.player.velocity.x)<8:break
	route.player.input_axis=0;await ticks(30)
	check(route.close_to_rabbit(),"physically_approach_pitpit")
	route.interact();await ticks(30);await capture("10-pitpit-left")
	check(route.dialogue_active and route.comic.names.right=="Pıtpıt","pitpit_opposing_comic")
	route.advance_dialogue();await ticks(30);await capture("11-pitpit-right")
	route.cancel_dialogue();await ticks(30)
	check(route.waymark_stage=="placed","cancel_does_not_fix_sign")
	route.interact();await dialogue_to_end();await ticks(30)
	check(route.waymark_stage=="ready" and route.mounted_arrow.rotation==0 and route.lookout_hint.text=="Seyir düzlüğü ↓","sign_points_to_real_right_path")
	await capture("12-repaired-fork")
	await route.walk_to(3020);await route.wait_for_team(2);await ticks(30)
	check(route.party_at_lookout() and route.available_action()=="Birlikte manzaraya bak","all_four_unlock_lookout")
	route.interact();await ticks(30);route.advance_dialogue();await ticks(30);await capture("13-lookout-comic")
	route.advance_dialogue();await ticks(30)
	check(route.waymark_stage=="seen" and route.save_service.load_progress(PATH).data.waymark=="seen","lookout_completion_durable")
	await capture("14-shared-route-finish")
	check(route.visible_hints_fit_viewport(),"visible_world_hints_not_clipped")
	check(not route.commit_waymark("seen") and route.waymark_events.count("seen")==1,"lookout_completion_idempotent")
	var main=Main.new().load_progress(PATH)
	check(main.ok and main.data.chapter_id=="B04" and Main.Quest.SUMMIT_COMPLETE in main.data.quest_flags and main.data.summit.waymark=="seen","main_B04_complete_durable")
	check(main.data.settings=={"music":false} and main.data.collectibles==["b01.mote.2"] and Main.Quest.GARDEN_COMPLETE in main.data.quest_flags,"main_history_settings_collectibles_preserved")
	finish("natural")
func finish(label):
	var f=FileAccess.open("res://preproduction/qa/v21/root-"+label+".json",FileAccess.WRITE)
	if f:f.store_string(JSON.stringify({"results":results,"failures":failed},"\t"));f.close()
	print("V21 "+label+" "+str(results.size())+" checks, failures "+str(failed));quit(0 if failed.is_empty() else 1)
