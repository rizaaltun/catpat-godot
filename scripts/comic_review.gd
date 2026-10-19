extends Control
## Isolated visual/interaction review. No main-game save or quest mutation.
const Runner = preload("res://scripts/dialogue_runner.gd")
var runner = Runner.new()
var left: Label
var right: Label
var subtitle: Label
var next_button: Button
var cat: Sprite2D
var badger: Sprite2D
var chars := 0.0
var prior_id := ""
var recording := false
var record_time := 0.0
var recorded_steps := 0

func label_at(text: String, rect: Rect2, font_size: int) -> Label:
	var l = Label.new()
	l.text = text
	l.position = rect.position
	l.size = rect.size
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", Color("193c35"))
	add_child(l)
	return l

func button_at(text: String, x: float, width: float, callback: Callable) -> Button:
	var b = Button.new()
	b.text = text
	b.position = Vector2(x, 661)
	b.size = Vector2(width, 45)
	b.add_theme_font_size_override("font_size", 18)
	b.pressed.connect(callback)
	add_child(b)
	return b

func portrait(path: String, pos: Vector2, height: float, flip: bool) -> Sprite2D:
	var s = Sprite2D.new()
	s.texture = load(path)
	s.position = pos
	s.scale = Vector2.ONE * height / s.texture.get_height()
	s.flip_h = flip
	add_child(s)
	return s

func _ready():
	var bg = TextureRect.new()
	bg.texture = load("res://assets/review-v2/comic-stage-r2.png")
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.size = Vector2(1280,720)
	var night_material = ShaderMaterial.new()
	var night_shader = Shader.new()
	night_shader.code = "shader_type canvas_item; void fragment(){ vec4 c=texture(TEXTURE,UV); float lightness=dot(c.rgb,vec3(0.2126,0.7152,0.0722)); float paper=smoothstep(0.83,0.91,lightness)*(1.0-smoothstep(0.32,0.49,UV.y)); vec3 dusk=c.rgb*vec3(0.43,0.59,0.69); COLOR=vec4(mix(dusk,c.rgb,paper),c.a); }"
	night_material.shader = night_shader
	bg.material = night_material
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	cat = portrait("res://assets/review-v2/catpat-idle-r2.png", Vector2(287,469), 402, true)
	badger = portrait("res://assets/review-v2/badger-idle-r2.png", Vector2(968,466), 390, false)
	left = label_at("", Rect2(88,65,405,178), 29)
	right = label_at("", Rect2(774,65,411,178), 29)
	var strip = ColorRect.new()
	strip.position = Vector2(0,646)
	strip.size = Vector2(1280,74)
	strip.color = Color("173f38")
	add_child(strip)
	subtitle = label_at("", Rect2(400,613,480,28), 17)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_color_override("font_color", Color("fff9e9"))
	button_at("Oyuna dön", 22, 148, func(): get_tree().change_scene_to_file("res://scenes/main.tscn"))
	button_at("Karşılaşma", 182, 156, func(): start("badger_meet"))
	button_at("Yardım sonrası", 350, 178, func(): start("badger_helped"))
	var note = label_at("SAHNE TASLAĞI • Model onayı bekliyor", Rect2(550,671,425,30), 17)
	note.add_theme_color_override("font_color", Color("fff0bc"))
	next_button = button_at("Devam →", 1032, 222, advance)
	runner.load_data(JSON.parse_string(FileAccess.get_file_as_string("res://preproduction/story/lantern-dialogue.json")))
	runner.completed.connect(func(_event, _first): subtitle.text = "Sahne bitti • Oyun kaydı değiştirilmedi"; next_button.text = "Yeniden izle ↻")
	start("badger_meet")
	recording = "--comic-record" in OS.get_cmdline_user_args()
	if "--comic-capture" in OS.get_cmdline_user_args():
		capture()

func start(id: String):
	runner.begin(id, {"badger_not_recruited": true, "all_three_lanterns_lit": true})
	left.text = ""
	right.text = ""
	prior_id = ""
	next_button.text = "Devam →"
	refresh()

func refresh():
	if not runner.active:
		return
	if prior_id != runner.current.id:
		chars = 0
		prior_id = runner.current.id
		var target = left if runner.current.side == "left" else right
		target.text = runner.current.text
		target.visible_characters = 0
		cat.modulate = Color.WHITE if runner.current.side == "left" else Color(0.85,0.90,0.89)
		badger.modulate = Color.WHITE if runner.current.side == "right" else Color(0.85,0.90,0.89)
		subtitle.text = ("Çatpat" if runner.current.side == "left" else "Porsuk") + " konuşuyor"

func advance():
	if not runner.active:
		start(runner.scene.id)
	else:
		runner.advance()
		refresh()

func _process(delta):
	runner.tick(delta)
	if runner.active:
		chars += delta * 35
		var target = left if runner.current.side == "left" else right
		if chars >= runner.current.text.length():
			runner.revealed = true
		target.visible_characters = -1 if runner.revealed else int(chars)
	if recording:
		record_time += delta
		if record_time > (recorded_steps + 1) * 3.0 and recorded_steps < 4:
			runner.revealed = true
			runner.input_cooldown = 0
			advance()
			recorded_steps += 1
		if record_time > 13:
			get_tree().quit()

func _unhandled_key_input(event):
	if event.is_pressed() and not event.is_echo() and event.keycode in [KEY_SPACE, KEY_ENTER]:
		advance()
		get_viewport().set_input_as_handled()

func capture():
	await get_tree().create_timer(1.3).timeout
	runner.revealed = true
	runner.input_cooldown = 0
	advance()
	runner.revealed = true
	await get_tree().create_timer(0.2).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://preproduction/review-v2/comic-engine.png")
	get_tree().quit()
