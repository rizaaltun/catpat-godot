extends SceneTree
const Store=preload("res://scripts/core/shared_route_save.gd")
var svc=Store.new()
var scene
var checks=[]
var failures=[]
var base="user://independent-v20-scene-"+str(Time.get_ticks_usec())
func _initialize():call_deferred("run")
func tick(n=1):
	for _i in n:await physics_frame
func check(ok,id):
	checks.append({"id":id,"ok":ok});print(("PASS " if ok else "FAIL ")+id)
	if not ok:failures.append(id)
func state(stage="loose",bank=2):
	var d=svc.fresh();d.bank=bank;d.lantern="lit";d.rope="ready";d.waymark=stage;return d
func reset(path):
	if scene:root.remove_child(scene);scene.queue_free();await tick(2)
	scene=load("res://tests/shared-route/shared.tscn").instantiate();scene.save_path=path;root.add_child(scene);scene.driver=true;await tick(40)
func fixture(x,y=539):
	scene.player.position=Vector2(x,y);scene.player.velocity=Vector2.ZERO;scene.player.input_axis=0;scene.player.jump_request=false;scene.player.jump_held=false
func key(code):
	var e=InputEventKey.new();e.keycode=code;e.pressed=true;scene._input(e)
func finish():
	while scene.dialogue_active:await tick(16);scene.advance_dialogue()
func write(path,text):
	var f=FileAccess.open(path,FileAccess.WRITE);f.store_string(text);f.close()
func run():
	var file=base+"-flow.json";svc.save(file,state());await reset(file)
	check(scene.waymark_stage=="loose" and scene.fallen_arrow.visible and not scene.carried_arrow.visible and not scene.mounted_arrow.visible,"loose_single_arrow")
	fixture(2460,660);await tick();check(scene.available_action().is_empty(),"airborne_pickup_denied")
	fixture(2460,704);await tick(5);check(scene.available_action()=="Festival okunu al","lower_step_pickup_action")
	scene.rope_stage="requested";check(scene.available_action().is_empty() and not scene.commit_waymark("carried"),"rope_prerequisite_blocks_pickup")
	scene.rope_stage="ready";scene.refresh_rope()
	for fault in ["write","rename"]:
		scene.save_service.fault=fault;scene.action_cooldown=0;scene.interact();check(scene.waymark_stage=="loose" and scene.fallen_arrow.visible and not scene.carried_arrow.visible and svc.read_file(file).data.waymark=="loose","pickup_"+fault+"_failure_no_world_change")
	scene.save_service.fault="";scene.action_cooldown=0;scene.interact();check(scene.waymark_stage=="carried" and scene.carried_arrow.visible and not scene.fallen_arrow.visible and not scene.mounted_arrow.visible,"pickup_retry_single_carried")
	check(not scene.commit_waymark("carried") and not scene.commit_waymark("ready") and scene.waymark_events==["carried"],"duplicate_and_skip_rejected")
	fixture(2260,780);await tick(80);check(scene.waymark_stage=="carried" and scene.carried_arrow.visible and svc.read_file(file).data.waymark=="carried","fall_keeps_arrow")
	await reset(file);check(scene.waymark_stage=="carried" and scene.carried_arrow.visible and not scene.fallen_arrow.visible,"carried_reload_single")
	scene.storage_writable=false;check(not scene.commit_waymark("placed") and scene.waymark_stage=="carried","storage_blocked_no_progress");scene.storage_writable=true
	scene.persistence_enabled=false;check(not scene.commit_waymark("placed") and scene.waymark_stage=="carried","persistence_disabled_no_progress");scene.persistence_enabled=true
	scene.safe_bank=1;scene.safe_facing=-1;check(scene.commit_checkpoint() and svc.read_file(file).data.waymark=="carried" and svc.read_file(file).data.rope=="ready" and svc.read_file(file).data.lantern=="lit","shore_snapshot_keeps_all_tasks")
	scene.safe_bank=2;scene.commit_checkpoint();fixture(2590);await tick(5);check(scene.available_action()=="Oku dikmeye yerleştir","post_action_grounded")
	scene.save_service.fault="rename";scene.action_cooldown=0;scene.interact();check(scene.waymark_stage=="carried" and scene.carried_arrow.visible and not scene.mounted_arrow.visible,"place_rename_failure_keeps_carried")
	scene.save_service.fault="";scene.action_cooldown=0;scene.interact();check(scene.waymark_stage=="placed" and scene.mounted_arrow.visible and not scene.carried_arrow.visible and scene.mounted_arrow.rotation!=0,"place_success_tilted_single")
	await reset(file);check(scene.waymark_stage=="placed" and not scene.dialogue_active and scene.mounted_arrow.rotation!=0,"placed_reload_not_ready")
	scene.begin_dialogue(scene.WAYMARK_DIALOGUE,"waymark.ready")
	var poses=scene.team.map(func(a):return a.position);var phases=scene.carriers.map(func(a):return a.fraction);var clock=scene.party.time;await tick(45)
	check(scene.dialogue_active and scene.paused and poses==scene.team.map(func(a):return a.position) and phases==scene.carriers.map(func(a):return a.fraction) and clock==scene.party.time,"repair_dialogue_freezes_world")
	check(scene.comic.names.right=="Pıtpıt" and scene.comic.portrait_right.texture.resource_path=="res://assets/chapter-v12/rabbit-idle.webp" and scene.comic.portrait_right.flip_h,"pitpit_partner_inward_source")
	scene.action_cooldown=0;scene.advance_dialogue();scene.advance_dialogue();check(scene.dialogue_index==1 and scene.waymark_stage=="placed" and scene.comic.advance_button.text=="Birlikte sabitleyelim","repair_double_input_debounced")
	key(KEY_ESCAPE);check(not scene.dialogue_active and not scene.paused and scene.waymark_stage=="placed","repair_cancel_no_progress")
	scene.begin_dialogue(scene.WAYMARK_DIALOGUE,"waymark.ready");scene._notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT);await tick(20)
	check(scene.pause_root.visible and scene.dialogue_active and not scene.comic.visible,"repair_focus_pauses_comic")
	scene.advance_dialogue();scene.cancel_dialogue();check(scene.dialogue_active and scene.dialogue_index==0,"paused_hidden_comic_ignores_controls")
	scene.resume_button.pressed.emit();check(scene.dialogue_active and scene.comic.visible and scene.paused and not scene.pause_root.visible,"resume_restores_comic")
	scene.set_pause(true);scene.reload_checkpoint();check(not scene.dialogue_active and not scene.paused and scene.dialogue_lines.is_empty() and scene.waymark_stage=="placed","reload_discards_half_comic")
	scene.save_service.fault="write";scene.begin_dialogue(scene.WAYMARK_DIALOGUE,"waymark.ready");await finish();check(scene.waymark_stage=="placed" and scene.mounted_arrow.rotation!=0 and svc.read_file(file).data.waymark=="placed","repair_write_failure_stays_tilted")
	scene.save_service.fault="";scene.begin_dialogue(scene.WAYMARK_DIALOGUE,"waymark.ready");scene.action_cooldown=0;scene.advance_dialogue();scene.action_cooldown=0;key(KEY_SPACE)
	check(scene.waymark_stage=="ready" and scene.mounted_arrow.rotation==0 and scene.lookout_hint.visible and svc.read_file(file).data.waymark=="ready","repair_retry_durable_ready")
	check(scene.keys.is_empty() and not scene.player.jump_request and not scene.player.jump_held,"closing_space_does_not_jump")
	scene.begin_dialogue(scene.INTRO,"accepted");check(scene.comic.names.right=="Porsuk" and not scene.comic.portrait_right.flip_h and scene.comic.finish_caption.is_empty(),"partner_reset_porsuk");scene.cancel_dialogue()
	scene.begin_dialogue(scene.ROPE_DIALOGUE,"rope.ready");check(scene.comic.names.right=="Maymun" and scene.comic.portrait_right.flip_h,"partner_reset_monkey");scene.cancel_dialogue()
	await reset(file);check(scene.waymark_stage=="ready" and not scene.fallen_arrow.visible and not scene.carried_arrow.visible and scene.mounted_arrow.visible,"ready_restore_single_mounted")
	fixture(3020);await tick(20);check(scene.party_at_lookout() and scene.available_action()=="Birlikte manzaraya bak","whole_party_finale_action")
	scene.team[3].position=Vector2(1700,539);scene.team[3].velocity=Vector2.ZERO;await tick(3);check(not scene.party_at_lookout() and scene.available_action().is_empty() and not scene.commit_waymark("seen"),"missing_friend_blocks_finale_and_commit")
	await reset(file);fixture(3020);await tick(20);scene.party.reservations[1]=0;check(not scene.party_at_lookout() and scene.available_action().is_empty() and not scene.commit_waymark("seen"),"carrier_reservation_blocks_finale");scene.party.reservations[1]=-1
	fixture(2700);await tick(3);check(scene.available_action().is_empty() and not scene.commit_waymark("seen"),"finale_requires_player_at_lookout")
	fixture(3020);await tick(20);scene.action_cooldown=0;scene.interact();check(scene.dialogue_active and scene.dialogue_target=="waymark.seen" and scene.dialogue_lines.size()==2,"finale_two_line_comic")
	key(KEY_ESCAPE);check(scene.waymark_stage=="ready" and not scene.dialogue_active,"finale_cancel_not_seen")
	scene.action_cooldown=0;scene.interact();scene.save_service.fault="rename";await finish();check(scene.waymark_stage=="ready" and svc.read_file(file).data.waymark=="ready","finale_failed_rename_not_seen")
	scene.save_service.fault="";scene.action_cooldown=0;scene.interact();await finish();check(scene.waymark_stage=="seen" and svc.read_file(file).data.waymark=="seen" and scene.waymark_events.count("seen")==1,"finale_seen_saved_once")
	scene.action_cooldown=0;scene.interact();check(not scene.dialogue_active and not scene.commit_waymark("seen") and scene.available_action().is_empty(),"seen_idempotent_no_replay")
	await reset(file);check(scene.waymark_stage=="seen" and scene.lantern_stage=="lit" and scene.rope_stage=="ready" and scene.waymark_events.is_empty() and not scene.dialogue_active,"seen_restore_whole_snapshot")
	# Snapshot function returns an independent dictionary, not a live mutable model.
	var snap=scene.progress_snapshot();snap.waymark="loose";snap.party_ids.clear();check(scene.waymark_stage=="seen" and scene.progress_snapshot().party_ids==Store.PARTY_IDS,"snapshot_detached_values")
	# Previous-quest writes use the same full snapshot. These are declared state fixtures.
	file=base+"-old-quest-writers.json";var old=state("loose",0);old.lantern="prepared";old.rope="loose";svc.save(file,old);await reset(file)
	check(scene.commit_quest("lit") and svc.read_file(file).data.waymark=="loose" and svc.read_file(file).data.rope=="loose","lantern_writer_preserves_new_field")
	check(scene.commit_rope("carried") and svc.read_file(file).data.waymark=="loose" and svc.read_file(file).data.lantern=="lit","rope_writer_preserves_new_field")
	var out={"checks":checks,"failures":failures,"engine":Engine.get_version_info(),"scope":"independent scene fixtures for save/modal/item/finale; fixture teleport is not natural route evidence"}
	write("res://preproduction/qa/v20/independent-scene-results.json",JSON.stringify(out,"\t"));print("INDEPENDENT V20 SCENE DONE ",checks.size()," failures ",failures);quit(0 if failures.is_empty() else 1)
