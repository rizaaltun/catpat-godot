extends SceneTree
const Store=preload("res://scripts/core/shared_route_save.gd")
var svc=Store.new()
var scene
var checks=[]
var failures=[]
var base="user://independent-v19-"+str(Time.get_ticks_usec())
func _initialize():call_deferred("run")
func tick(n=1):
	for _i in n:await physics_frame
func check(ok,id,detail={}):
	checks.append({"id":id,"ok":ok,"detail":detail});print(("PASS " if ok else "FAIL ")+id+" "+JSON.stringify(detail))
	if not ok:failures.append(id)
func write(path,text):
	var f=FileAccess.open(path,FileAccess.WRITE);f.store_string(text);f.close()
func state(bank=0,rope="loose",lantern="lit"):
	var d=svc.fresh();d.bank=bank;d.rope=rope;d.lantern=lantern;return d
func old_state(version,bank,face,lantern="lit"):
	var d=state(bank);d.schema_version=version;d.facing=face;d.erase("rope")
	if version==1:d.erase("lantern")
	else:d.lantern=lantern
	return d
func reset(path):
	if scene:root.remove_child(scene);scene.queue_free();await tick(2)
	scene=load("res://tests/shared-route/shared.tscn").instantiate();scene.save_path=path;root.add_child(scene);scene.driver=true
	await tick(40)
func fixture(x,y=539):
	scene.player.position=Vector2(x,y);scene.player.velocity=Vector2.ZERO;scene.player.input_axis=0;scene.player.jump_request=false;scene.player.jump_held=false
func key(code):
	var e=InputEventKey.new();e.keycode=code;e.pressed=true;scene._input(e)
func finish_dialogue():
	while scene.dialogue_active:
		await tick(16);scene.advance_dialogue()
func run():
	check(svc.valid(svc.fresh()) and svc.fresh().schema_version==3 and svc.fresh().rope=="loose","schema3_fresh")
	for version in [1,2]:
		for bank in 3:
			for face in [-1,1]:
				var d=old_state(version,bank,face);var r=svc.decode(svc.encode(d))
				check(r.ok and r.migrated and r.data.bank==bank and r.data.facing==face and r.data.party_ids==Store.PARTY_IDS and r.data.rope=="loose" and r.data.lantern==("unseen" if version==1 else "lit"),"migrate_%s_%s_%s"%[version,bank,face])
	for stage in Store.LANTERN_STAGES:
		var r=svc.decode(svc.encode(old_state(2,2,-1,stage)))
		check(r.ok and r.data.lantern==stage and r.data.rope=="loose","v2_keeps_lantern_"+stage)
	for rope in Store.ROPE_STAGES:
		var r=svc.decode(svc.encode(state(2,rope)))
		check(r.ok and not r.migrated and r.data.rope==rope and r.data.bank==2,"schema3_roundtrip_"+rope)
	for rope in Store.ROPE_STAGES.slice(1):
		for lantern in Store.LANTERN_STAGES.slice(0,3):check(not svc.valid(state(0,rope,lantern)),"reject_prereq_"+rope+"_"+lantern)
	for field in Store.FIELDS:
		for value in [null,true,{},[],"invalid"]:
			var d=state();d[field]=value;check(not svc.decode(svc.encode(d)).ok,"reject_type_%s_%s"%[field,typeof(value)])
	for version in [1,2]:
		var d=old_state(version,0,1);d.rope="ready";check(not svc.decode(svc.encode(d)).ok,"legacy_no_rope_injection_"+str(version))
	for value in [-1,3,1.25]:
		var d=state();d.bank=value;check(not svc.decode(svc.encode(d)).ok,"reject_bank_"+str(value))
	for field in Store.FIELDS:
		var d=state();d.erase(field);check(not svc.decode(svc.encode(d)).ok,"reject_missing_"+field)
	var d=state();d.unknown=1;check(not svc.decode(svc.encode(d)).ok,"reject_extra")
	check(not svc.decode('{"payload":{},"sha256":"wrong"}').ok,"reject_checksum")
	var file=base+"-legacy.json";var original=svc.encode(old_state(2,2,-1,"prepared"));write(file,original)
	await reset(file);check(scene.safe_bank==2 and scene.safe_facing==-1 and scene.lantern_stage=="prepared" and scene.rope_stage=="loose" and scene.return_access and scene.carriers[1].enabled,"legacy_spawn_keeps_far_bank_and_grants_return_access")
	check(FileAccess.get_file_as_string(file)==original,"legacy_no_eager_rewrite")
	check(await scene.cross_shared(1,-1),"legacy_return_player_physical_crossing")
	check(scene.return_access and scene.rope_stage=="loose" and not scene.tow_line.visible,"return_access_until_last_companion_not_false_quest_success")
	await scene.walk_to(1510);check(await scene.wait_for_team(1),"legacy_return_three_friends_physically_rejoin")
	for _i in 360:
		await tick()
		if not scene.return_access:break
	check(not scene.return_access and not scene.carriers[1].enabled and scene.carriers[1].fraction==0.0 and not scene.team.any(func(a):return scene.carriers[1].is_riding(a)),"return_carrier_locks_only_at_empty_start_dock")
	scene.safe_bank=1;scene.commit_checkpoint();check(svc.read_file(file).data.schema_version==3 and FileAccess.get_file_as_string(file+".legacy")==original,"legacy_first_write_preserves_original")
	scene.set_pause(true);scene.reload_checkpoint();await tick(4);check(not scene.return_access and not scene.carriers[1].enabled and scene.rope_stage=="loose","middle_reload_has_no_return_bypass")
	file=base+"-flow.json";svc.save(file,state());await reset(file)
	check(scene.coil.visible and not scene.carried_coil.visible and not scene.tied_coil.visible and not scene.tow_line.visible and not scene.carriers[1].enabled and scene.carriers[0].enabled,"loose_visual_and_carrier_contract")
	fixture(600,470);await tick();check(scene.available_action().is_empty(),"airborne_cannot_pickup")
	fixture(600);await tick(4);check(scene.available_action()=="Halatı al","ground_pickup_action")
	scene.save_service.fault="write";scene.action_cooldown=0;scene.interact();check(scene.rope_stage=="loose" and scene.coil.visible and not scene.carried_coil.visible and svc.read_file(file).data.rope=="loose","pickup_write_failure_preserves_world_and_save")
	scene.save_service.fault="";scene.action_cooldown=0;scene.interact();check(scene.rope_stage=="carried" and not scene.coil.visible and scene.carried_coil.visible and scene.rope_events==["carried"],"pickup_retry_single_copy")
	scene.action_cooldown=0;scene.interact();check(scene.rope_events==["carried"],"pickup_idempotent")
	fixture(1010,730);await tick(70);check(scene.rope_stage=="carried" and scene.carried_coil.visible and svc.read_file(file).data.rope=="carried","fall_keeps_carried_rope")
	await reset(file);check(scene.rope_stage=="carried" and scene.carried_coil.visible and not scene.coil.visible and not scene.tied_coil.visible,"carried_reload_no_duplicate")
	check(not scene.commit_rope("ready") and not scene.commit_rope("carried"),"skip_and_duplicate_rejected")
	fixture(1820);await tick(4);check(scene.available_action()=="Halatı yerleştir","winch_ground_action")
	scene.safe_bank=1;scene.safe_facing=-1;scene.save_service.fault="rename";scene.action_cooldown=0;scene.interact();check(scene.rope_stage=="carried" and scene.carried_coil.visible and not scene.tied_coil.visible and svc.read_file(file).data.rope=="carried","requested_rename_failure_no_false_world_change")
	scene.save_service.fault="";scene.action_cooldown=0;scene.interact();check(scene.rope_stage=="requested" and not scene.carried_coil.visible and scene.tied_coil.visible and not scene.carriers[1].enabled,"requested_success_still_locked")
	check(svc.read_file(file).data.bank==1 and svc.read_file(file).data.facing==-1,"rope_save_keeps_bank_facing")
	await reset(file);check(scene.rope_stage=="requested" and scene.tied_coil.visible and not scene.dialogue_active and not scene.carriers[1].enabled,"requested_reload_does_not_autocomplete")
	scene.safe_bank=2;scene.commit_checkpoint();check(svc.read_file(file).data.rope=="requested" and svc.read_file(file).data.lantern=="lit","checkpoint_keeps_both_tasks")
	scene.safe_bank=1;scene.commit_checkpoint()
	scene.begin_dialogue(scene.ROPE_DIALOGUE,"rope.ready")
	var poses=scene.team.map(func(a):return a.position);var phases=scene.carriers.map(func(a):return a.fraction);var clock=scene.party.time;await tick(45)
	check(scene.dialogue_active and scene.paused and poses==scene.team.map(func(a):return a.position) and phases==scene.carriers.map(func(a):return a.fraction) and clock==scene.party.time,"rope_comic_freezes_world")
	check(scene.comic.names.right=="Maymun" and scene.comic.portrait_right.texture.resource_path=="res://assets/chapter-v10/monkey-idle.webp","rope_comic_partner")
	check(scene.comic.portrait_right.flip_h,"monkey_faces_inward")
	scene.action_cooldown=0;scene.advance_dialogue();scene.advance_dialogue();check(scene.dialogue_index==1 and scene.rope_stage=="requested" and scene.comic.advance_button.text=="Birlikte sabitleyelim","double_advance_debounced_and_final_caption")
	key(KEY_ESCAPE);check(not scene.dialogue_active and not scene.paused and scene.rope_stage=="requested" and not scene.carriers[1].enabled,"cancel_preserves_requested_and_lock")
	scene.begin_dialogue(scene.ROPE_DIALOGUE,"rope.ready");scene._notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT);await tick(20)
	check(scene.pause_root.visible and scene.dialogue_active and not scene.comic.visible,"focus_loss_pauses_rope_comic")
	scene.advance_dialogue();scene.cancel_dialogue();check(scene.dialogue_active and scene.dialogue_index==0,"pause_blocks_hidden_comic_controls")
	scene.resume_button.pressed.emit();check(scene.dialogue_active and scene.comic.visible and scene.paused and not scene.pause_root.visible,"resume_returns_to_rope_comic")
	scene.set_pause(true);scene.reload_checkpoint();check(not scene.dialogue_active and not scene.paused and not scene.comic.visible and scene.dialogue_lines.is_empty() and scene.rope_stage=="requested" and not scene.carriers[1].enabled,"reload_discards_half_comic_without_progress")
	scene.save_service.fault="rename";scene.begin_dialogue(scene.ROPE_DIALOGUE,"rope.ready");await finish_dialogue();check(scene.rope_stage=="requested" and not scene.carriers[1].enabled and not scene.tow_line.visible and svc.read_file(file).data.rope=="requested","ready_failed_rename_stays_locked")
	scene.save_service.fault="";scene.begin_dialogue(scene.ROPE_DIALOGUE,"rope.ready");scene.action_cooldown=0;scene.advance_dialogue();scene.action_cooldown=0;key(KEY_SPACE)
	check(scene.rope_stage=="ready" and scene.carriers[1].enabled and scene.tow_line.visible and svc.read_file(file).data.rope=="ready","ready_retry_durable_unlock")
	check(scene.keys.is_empty() and not scene.player.jump_request and not scene.player.jump_held,"closing_space_not_jump")
	check(not scene.commit_rope("ready") and scene.rope_events.count("ready")==1,"ready_idempotent")
	scene.begin_dialogue(scene.INTRO,"accepted");check(not scene.comic.portrait_right.flip_h and scene.comic.names.right=="Porsuk" and scene.comic.finish_caption.is_empty(),"switch_back_resets_badger_facing_and_caption");scene.cancel_dialogue()
	await reset(file);check(scene.rope_stage=="ready" and scene.carriers[1].enabled and scene.tow_line.visible and scene.rope_events.is_empty(),"ready_reload_no_replay")
	# Artificial fixtures probe the disabled AI queue; natural traversal is separately tested by root.
	file=base+"-disabled.json";svc.save(file,state(1,"carried"));await reset(file);fixture(2800);await tick(900)
	check(not scene.carriers[1].enabled and scene.carriers[1].fraction==0 and scene.party.reservations[1]==-1,"disabled_carrier_stays_still_without_reservation")
	check(not scene.party.events.any(func(e):return e.event=="reserve" and e.get("surface",-1)==1) and not scene.party.members.any(func(a):return scene.carriers[1].is_riding(a)),"disabled_carrier_ai_never_boards")
	check(scene.party.members.all(func(a):return scene.party.bank_of(a)==1),"team_waits_middle_when_player_bypasses")
	file=base+"-corrupt.json";svc.save(file,state(1,"carried"));svc.save(file,state(1,"requested"));write(file,"corrupt");await reset(file)
	check(scene.rope_stage=="carried" and scene.carried_coil.visible and not scene.carriers[1].enabled and svc.read_file(file).ok,"corrupt_primary_recovers_valid_backup")
	file=base+"-both-damaged.json";write(file,"bad-main");write(file+".bak","bad-backup");await reset(file)
	check(scene.persistence_status=="damaged_preserved" and scene.rope_stage=="loose" and scene.lantern_stage=="unseen" and FileAccess.get_file_as_string(file)=="bad-main" and FileAccess.get_file_as_string(file+".bak")=="bad-backup","both_damaged_preserved_without_false_progress")
	var out={"checks":checks,"failures":failures,"engine":Engine.get_version_info(),"test_files_prefix":base,"scope":"headless independent service/modal/AI fixtures; no natural traversal or device claim"}
	var revision="03" if "--revision-03" in OS.get_cmdline_user_args() else "02" if "--revision-02" in OS.get_cmdline_user_args() else "01"
	write("res://preproduction/qa/v19/independent-results-"+revision+".json",JSON.stringify(out,"\t"));print("INDEPENDENT V19 DONE ",checks.size()," failures ",failures);quit(0 if failures.is_empty() else 1)
