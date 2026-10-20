extends SceneTree

const UI = preload("res://scripts/polish_ui.gd")
var failures = 0

func _initialize():
	call_deferred("_run")

func _run():
	var font = UI.font()
	for codepoint in [0x00C7, 0x011E, 0x0130, 0x00D6, 0x015E, 0x00DC, 0x00E7, 0x011F, 0x0131, 0x00F6, 0x015F, 0x00FC]:
		_check(font.has_char(codepoint), "Turkish glyph %s is available" % String.chr(codepoint))

	var game = load("res://scenes/polish_v3.tscn").instantiate()
	game.automated = true
	root.add_child(game)
	await process_frame
	_check(game.mode == "menu", "project opens on the playable main menu")
	var opening_copy = _find_label_contains(game, "Festival bugün!")
	_check(opening_copy != null and opening_copy.text.contains("Patikadan gidersem oraya ulaşabilirim."), "main menu displays the complete opening story copy")
	var start_button = _find_button(game, "Yola çık")
	_check(start_button != null, "new game button is visible")
	if start_button != null:
		start_button.pressed.emit()
		await process_frame
		_check(game.mode == "dialogue", "start button begins the first playable scene")
		game._dialogue_done("invalid.quest.event", false)
		_check(game.mode == "notice", "rejected quest progress shows a recovery notice")
		_check(_find_button(game, "Devam et") != null, "recovery notice can return to the game")
	game.queue_free()
	print("STARTUP REGRESSION FAILED: %d checks" % failures if failures else "STARTUP REGRESSION PASSED")
	quit(1 if failures else 0)

func _find_label_contains(node: Node, text: String) -> Label:
	if node is Label and node.text.contains(text):
		return node
	for child in node.get_children():
		var found = _find_label_contains(child, text)
		if found != null:
			return found
	return null

func _find_button(node: Node, text: String) -> Button:
	if node is Button and node.text == text:
		return node
	for child in node.get_children():
		var found = _find_button(child, text)
		if found != null:
			return found
	return null

func _check(condition: bool, description: String):
	if condition:
		print("PASS: " + description)
	else:
		failures += 1
		push_error("FAIL: " + description)
