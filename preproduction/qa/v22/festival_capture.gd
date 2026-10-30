extends SceneTree
## Emits temporary Godot-rendered B05 frames into the Actions log; no image assets are committed.
const Store = preload("res://scripts/core/save_service.gd")
const Quest = preload("res://scripts/core/quest_state.gd")
const Path = "user://b05-visual-capture.json"
var failures := 0
var captures := 0
var game: Node
func _initialize():
	call_deferred("run")
func check(ok: bool, label: String):
	if not ok:
		failures += 1
		push_error("FAIL " + label)
	else:
		print("PASS " + label)
func seed_journey():
	var state = Quest.new()
	var ids = [Quest.ACCEPTED] + Quest.LIGHTS + [Quest.JOINED, Quest.COMPLETE, Quest.RIVER_ACCEPTED, Quest.PLANK, Quest.ROPE, Quest.SUPPLIED, Quest.READY, Quest.MONKEY, Quest.RIVER_COMPLETE, Quest.GARDEN_ACCEPTED, Quest.TIE, Quest.RELEASED, Quest.LOWERED, Quest.BASKET, Quest.GARDEN_SUPPLIED, Quest.PROTECTED, Quest.RABBIT, Quest.GARDEN_COMPLETE, Quest.SUMMIT_COMPLETE]
	for id in ids:
		if not state.apply(id):
			check(false, "fixture quest " + id)
			return {}
	var data = Store.new().fresh()
	data.chapter_id = "B05"
	data.geometry = "festival-v1"
	data.checkpoint_id = "b05.entry"
	data.quest_flags = state.flags.duplicate()
	data.party_ids = state.party_ids()
	data.summit = {}
	return data
func add_final_flags():
	# This is an explicit saved-final visual fixture, not an in-flight contribution.
	for tween in game.contribution_tweens + game.partner_tweens:
		if is_instance_valid(tween) and tween.is_valid():tween.kill()
	game.contribution_tweens.clear();game.partner_tweens.clear()
	game.gathering_partners = false
	for id in [Quest.FESTIVAL_LIGHT, Quest.FESTIVAL_FLAGS, Quest.FESTIVAL_FLOWERS, Quest.FESTIVAL_COMPLETE]:
		if id not in game.save_data.quest_flags:
			game.save_data.quest_flags.append(id)
	game.save_data.ending_seen = true
	game.save_data.checkpoint_id = "b05.stage"
	game.actor.position = Vector2(game.FINAL_ANCHOR_X, 442.0)
	game.all_on_stage = true
	for i in game.partner_sprites.size():
		game.partner_sprites[i].position = game.STAGE_ANCHORS[i]
	game.build_station_state()
	game.show_final()
func capture(tag: String, expected_size := Vector2i(1280, 720)):
	await process_frame
	await RenderingServer.frame_post_draw
	var shot = root.get_texture().get_image()
	print("CAPTURE_DIMENSIONS:" + tag + ":image=" + str(shot.get_size()) + ":window=" + str(DisplayServer.window_get_size()) + ":root=" + str(root.size))
	check(not shot.is_empty() and root.size == expected_size, tag + " window size is " + str(expected_size.x) + "x" + str(expected_size.y))
	if shot.is_empty():
		return
	var encoded = Marshalls.raw_to_base64(shot.save_webp_to_buffer(true, 0.82))
	check(not encoded.is_empty(), tag + " rendered frame encoded")
	captures += 1
	print("VISUAL_CAPTURE:" + tag + ":" + encoded)
func clean():
	for suffix in ["", ".bak", ".pending", ".bak.pending", ".legacy"]:
		var absolute = ProjectSettings.globalize_path(Path + suffix)
		if FileAccess.file_exists(absolute):
			DirAccess.remove_absolute(absolute)
func run():
	clean()
	var service = Store.new()
	var data = seed_journey()
	check(service.valid(data), "B05 visual fixture is a valid completed B04 save")
	check(service.save(Path, data), "B05 visual fixture is stored in isolated user data")
	set_meta("journey_save_path", Path)
	get_root().size = Vector2i(1280, 720)
	game = load("res://scenes/festival.tscn").instantiate()
	root.add_child(game)
	await process_frame
	check(not game.blocked and game.actor != null, "B05 entry scene renders from its normal save gate")
	if game.blocked or game.actor == null:
		quit(1)
		return
	await capture("entry")
	game.actor.position = Vector2(1150.0, 414.0)
	game.actor.velocity = Vector2.ZERO
	for frame in 60:
		await physics_frame
		if game.near_task == 0 and game.can_interact():
			break
	check(game.actor.is_on_floor() and game.near_task == 0 and game.can_interact(), "Porsuk task is active from its grounded station for task-complete frame")
	game.interact()
	check(Quest.FESTIVAL_LIGHT in game.save_data.quest_flags, "Porsuk contribution completes through the normal interaction")
	await capture("task-complete")
	get_root().size = Vector2i(666, 374)
	game.control_display.touch_mode = true
	game.control_display.refresh()
	game.update_controls_hint()
	await process_frame
	check(game.control_display.buttons.slice(0,3).all(func(button): return button.visible), "small viewport movement controls become visible")
	check(game.action_button.visible==game.can_interact(), "small viewport shows the action only for an available interaction")
	await capture("small-touch", Vector2i(666, 374))
	get_root().size = Vector2i(1280, 720)
	game.show_help()
	await capture("help")
	game.close_help()
	game.toggle_pause()
	get_root().size = Vector2i(1280, 720)
	game.control_display.touch_mode = false
	game.control_display.refresh()
	game.update_controls_hint()
	game.toggle_pause()
	check(game.paused and game.pause_panel.visible, "pause overlay is active for capture")
	await capture("pause")
	game.toggle_pause()
	add_final_flags()
	check(game.paused and game.final_panel.visible, "festival finale is active for capture")
	await capture("final")
	get_root().size = Vector2i(666, 374)
	await capture("small-final", Vector2i(666, 374))
	get_root().size = Vector2i(1280, 720)
	game.leave_final()
	await capture("stage-world")

	print("B05 VISUAL CAPTURE: %d frames, %d failures" % [captures, failures])
	clean()
	quit(1 if failures or captures != 8 else 0)
