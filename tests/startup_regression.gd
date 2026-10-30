extends SceneTree

const Quest = preload("res://scripts/core/quest_state.gd")
const UI = preload("res://scripts/polish_ui.gd")
var failures = 0

func _initialize():
	call_deferred("_run")

func _run():
	var font = UI.font()
	_check(font is FontFile and font.get_string_size("Çatpat İı Şş Ğğ Çç Öö Üü").x > 0.0, "shared font renders Turkish game text without variation wrappers")
	for codepoint in [0x00C7, 0x011E, 0x0130, 0x00D6, 0x015E, 0x00DC, 0x00E7, 0x011F, 0x0131, 0x00F6, 0x015F, 0x00FC]:
		_check(font.has_char(codepoint), "Turkish glyph %s is available" % String.chr(codepoint))

	var game = load("res://scenes/polish_v3.tscn").instantiate()
	# This suite tests the B01 menu/dialogue. Fresh-player B00 routing has its own suite.
	var menu_path="user://startup-menu-regression.json"
	for suffix in ["",".bak",".pending",".bak.pending",".legacy",".onboarding-v1.original",".onboarding-v1.original.pending"]:DirAccess.remove_absolute(menu_path+suffix)
	get_root().get_tree().set_meta("journey_save_path",menu_path)
	game.saves.save(menu_path,game.saves.fresh())
	game.automated = true
	root.add_child(game)
	await process_frame
	_check(game.mode == "menu", "project opens on the playable main menu")
	var opening_copy = _find_label_contains(game, "Festival bugün!")
	_check(opening_copy != null and opening_copy.text.contains("Patikadan gidersem oraya ulaşabilirim."), "main menu displays the complete opening story copy")
	var start_button = _find_button(game, "Yolculuğa dön")
	_check(start_button != null, "saved B01 continue button is visible")
	if start_button != null:
		start_button.pressed.emit()
		await process_frame
		_check(game.mode == "dialogue", "start button begins the first playable scene")
		game._dialogue_done("invalid.quest.event", false)
		_check(game.mode == "notice", "rejected quest progress shows a recovery notice")
		_check(_find_button(game, "Devam et") != null, "recovery notice can return to the game")
	game.show_menu()
	_check(_find_button(game,"Ebeveyn özeti")!=null,"parent progress summary is reachable from the main menu")
	var summary_path="user://startup-parent-summary.json"
	game.save_path=summary_path
	var summary_data=game.saves.fresh()
	var summary_state=Quest.new()
	for event in [Quest.ACCEPTED]+Quest.LIGHTS+[Quest.JOINED,Quest.COMPLETE]:
		summary_state.apply(event)
	summary_data.quest_flags=summary_state.flags
	summary_data.party_ids=summary_state.party_ids()
	summary_data.checkpoint_id="b01.island.8"
	summary_data.collectibles=["b00.ribbon","b01.mote.1"]
	_check(game.saves.save(summary_path,summary_data),"parent summary fixture writes a valid local save")
	game.show_parent_summary()
	game.parent_panel.open_report()
	_check(_find_label_contains(game,"B01 Fenerli Patika — Tamamlandı")!=null,"summary reports completed B01 from saved quest evidence")
	_check(_find_label_contains(game,"B02 Dostluk Deresi — Henüz başlanmadı")!=null,"summary distinguishes a chapter with no progress")
	_check(_find_label_contains(game,"1/5 ışık izi")!=null,"B00 decoration is not counted as a B01 light keepsake")
	var compatible=game.saves.migrate_onboarding(summary_data)
	_check(compatible.ok and game.saves.persist_onboarding_migration(summary_path,compatible.data),"summary legacy bypass fixture persists with explicit origin")
	game.show_parent_summary()
	game.parent_panel.open_report()
	_check(_find_label_contains(game,"öğretici oynanmadı")!=null,"summary does not report compatibility flags as an observed tutorial")
	_check(_find_label_contains(game,"beceri gelişimini veya gerçek yaşam davranışını ölçmez")!=null,"summary states its evidence and development limits")
	var return_button=_find_button(game,"Ana menüye dön")
	_check(return_button!=null,"summary provides a clear return to the main menu")
	if return_button!=null:return_button.pressed.emit()
	_check(game.mode=="menu","parent summary returns to the main menu")
	for suffix in ["",".bak",".pending",".bak.pending",".legacy",".onboarding-v1.original",".onboarding-v1.original.pending"]:DirAccess.remove_absolute(summary_path+suffix)
	game.queue_free()
	for suffix in ["",".bak",".pending",".bak.pending",".legacy",".onboarding-v1.original",".onboarding-v1.original.pending"]:DirAccess.remove_absolute(menu_path+suffix)
	set_meta("journey_save_path","user://festival_v3.json")
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
