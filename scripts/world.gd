extends Node2D
const Actor = preload("res://scripts/actor.gd")
const SaveStore = preload("res://scripts/save_store.gd")
var player
var friends: Array = []
var collected = {"lanterns":[],"wood":[],"flowers":[],"friends":[],"checkpoint":0,"finished":false}
var objects: Array = []
var bridge_nodes: Array = []
var camera: Camera2D
var hud: CanvasLayer
var title_label: Label
var mission_label: Label
var counter_label: Label
var prompt_label: Label
var overlay: Control
var touch_points = {}
var touch_axis = 0.0
var touch_jump = false
var interact_request = false
var dialog_open = false
var paused = false
var background: Sprite2D
var elapsed = 0.0
var last_jump_touch = false
var test_mode = false
const CHECKPOINTS = [Vector2(160,520),Vector2(1700,520),Vector2(3250,520),Vector2(4700,520)]

func _ready():
	test_mode = "--smoke" in OS.get_cmdline_user_args() or "--preview" in OS.get_cmdline_user_args()
	_setup_input()
	var saved = SaveStore.read_save() if not test_mode else {}
	if not saved.is_empty():
		collected = saved
	_build_background()
	_build_level()
	player = Actor.new()
	player.controlled = true
	player.position = CHECKPOINTS[collected.checkpoint]
	player.checkpoint = player.position
	add_child(player)
	camera = Camera2D.new()
	camera.position = Vector2(0,-210)
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = 6400
	camera.limit_bottom = 720
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 6
	player.add_child(camera)
	for i in range(3):
		var actor = Actor.new()
		actor.character_id = ["badger","monkey","rabbit"][i]
		actor.position = [Vector2(1540,540),Vector2(3020,540),Vector2(4650,540)][i]
		actor.checkpoint = actor.position
		friends.append(actor)
		add_child(actor)
		if i in collected.friends:
			_recruit(i,false)
	_build_hud()
	_refresh_bridge()
	_update_hud()
	if not test_mode:
		_show_intro()
	if "--screenshot" in OS.get_cmdline_user_args():
		_capture_later()
	if "--smoke" in OS.get_cmdline_user_args():
		_run_smoke()
	if "--preview" in OS.get_cmdline_user_args():
		_run_preview()

func _setup_input():
	for key in {"left":[KEY_A,KEY_LEFT],"right":[KEY_D,KEY_RIGHT],"jump":[KEY_SPACE,KEY_UP,KEY_W],"interact":[KEY_E],"pause":[KEY_ESCAPE]}:
		if not InputMap.has_action(key):
			InputMap.add_action(key)
		for code in {"left":[KEY_A,KEY_LEFT],"right":[KEY_D,KEY_RIGHT],"jump":[KEY_SPACE,KEY_UP,KEY_W],"interact":[KEY_E],"pause":[KEY_ESCAPE]}[key]:
			var event = InputEventKey.new()
			event.physical_keycode = code
			InputMap.action_add_event(key,event)

func _build_background():
	background = Sprite2D.new()
	background.texture = load("res://assets/world/forest.webp")
	background.centered = false
	background.scale = Vector2(1.25,0.8)
	background.position.y = -70
	background.modulate = Color(0.76,0.9,0.84)
	background.z_index = -20
	add_child(background)
	# Two repeating illustrated layers provide depth, never used for collision.
	for x in range(0,6600,650):
		var tree = Sprite2D.new()
		tree.texture = load("res://assets/world/tree.webp")
		tree.position = Vector2(x+340,170)
		tree.scale = Vector2(2,2)
		tree.modulate = Color(0.35,0.65,0.49,0.6)
		tree.z_index = -8
		add_child(tree)

func _platform(x:float,y:float,w:float,kind:int=0) -> StaticBody2D:
	var body = StaticBody2D.new()
	body.position = Vector2(x,y)
	body.collision_layer = 1
	body.collision_mask = 0
	var shape = CollisionShape2D.new()
	var rect = RectangleShape2D.new()
	rect.size = Vector2(w,30)
	shape.shape = rect
	shape.one_way_collision = kind == 1
	shape.position = Vector2(w/2,15)
	body.add_child(shape)
	var visual = Sprite2D.new()
	var atlas = AtlasTexture.new()
	atlas.atlas = load("res://assets/world/platforms.webp")
	# Crop transparent padding only; painted platform tops align with colliders.
	var regions = [Rect2(0,240,768,270),Rect2(780,268,750,245),Rect2(80,580,650,350),Rect2(780,670,750,300)]
	atlas.region = regions[kind]
	visual.texture = atlas
	visual.centered = false
	visual.scale = Vector2(w/atlas.region.size.x,0.65 if kind!=2 else 0.5)
	visual.position.y = -7
	body.add_child(visual)
	add_child(body)
	return body

func _build_level():
	# Walkable ground, safe gaps, and reachable stepped optional routes.
	for g in [[0,600,850],[1030,600,2100],[3430,600,2970]]:
		_platform(g[0],g[1],g[2])
	for p in [[340,475,190],[640,360,210],[930,470,170],[1240,450,210],[1830,470,180],[2120,370,190],[2430,460,220],[3570,470,210],[3880,360,210],[4200,460,200],[4960,470,180],[5250,365,230],[5590,465,190]]:
		_platform(p[0],p[1],p[2],1)
	# Broad bridge is built only after the monkey's three planks are collected.
	bridge_nodes.append(_platform(3130,600,300,3))
	for i in range(3):
		_add_object("lanterns",i,[Vector2(435,425),Vector2(745,310),Vector2(1340,400)][i],0)
		_add_object("wood",i,[Vector2(1910,420),Vector2(2215,320),Vector2(2530,410)][i],3)
	for i in range(5):
		_add_object("flowers",i,[Vector2(3590,550),Vector2(3670,420),Vector2(3970,310),Vector2(4290,410),Vector2(4470,550)][i],2)
	for i in range(1,4):
		var flag = _prop_sprite(5,Vector2(180,105))
		flag.position = CHECKPOINTS[i]+Vector2(0,-115)
		add_child(flag)
	var festival = _prop_sprite(5,Vector2(650,270))
	festival.position = Vector2(5960,330)
	add_child(festival)
	var label = Label.new()
	label.text = "ORMAN FESTİVALİ"
	label.position = Vector2(5660,255)
	label.add_theme_font_size_override("font_size",40)
	label.add_theme_color_override("font_color",Color("fff2c5"))
	add_child(label)

func _prop_sprite(index:int,box:Vector2) -> Sprite2D:
	var s = Sprite2D.new()
	var atlas = AtlasTexture.new()
	atlas.atlas = load("res://assets/world/props.webp")
	atlas.region = Rect2((index%3)*512,int(index/3)*512,512,512)
	s.texture = atlas
	s.scale = box/512.0
	return s

func _add_object(kind:String,id:int,pos:Vector2,frame:int):
	var s = _prop_sprite(frame,Vector2(85,85))
	s.position = pos
	add_child(s)
	var item = {"kind":kind,"id":id,"node":s,"base_y":pos.y,"done":id in collected[kind]}
	if item.done:
		if kind=="lanterns":
			s.texture.region.position.x = 512
		else:
			s.hide()
	objects.append(item)

func _process(delta):
	elapsed += delta
	if not is_instance_valid(player):
		return
	background.position.x = camera.get_screen_center_position().x-960
	if Input.is_action_just_pressed("pause"):
		if not dialog_open:
			_toggle_pause()
	var locked = paused or dialog_open
	player.frozen = locked
	for f in friends:
		f.frozen = locked
	if locked:
		player.input_axis = 0
		return
	player.input_axis = clampf(Input.get_axis("left","right")+touch_axis,-1,1)
	player.jump_held = Input.is_action_pressed("jump") or touch_jump
	if player.jump_held and not last_jump_touch:
		player.jump_request = true
	last_jump_touch = player.jump_held
	var interact = Input.is_action_just_pressed("interact") or interact_request
	interact_request = false
	var nearby = ""
	for object in objects:
		if object.done:
			continue
		object.node.position.y = object.base_y + sin(elapsed*2+object.id)*4
		if player.position.distance_to(object.node.position+Vector2(0,35))<90:
			if object.kind=="lanterns":
				nearby = "Feneri yak: E / el düğmesi"
				if interact:
					_collect(object)
			else:
				_collect(object)
	for i in range(3):
		if i in collected.friends:
			continue
		if player.position.distance_to(friends[i].position)<140:
			nearby = "%s ile konuş: E / el düğmesi" % ["Porsuk","Maymun","Pıtpıt"][i]
			if interact:
				_talk(i)
	prompt_label.text = nearby
	for i in range(1,4):
		if player.position.x > CHECKPOINTS[i].x and i > collected.checkpoint and player.is_on_floor():
			collected.checkpoint = i
			player.checkpoint = CHECKPOINTS[i]
			_save()
	if player.position.x>5870 and collected.friends.size()==3 and not collected.finished:
		collected.finished = true
		_save()
		_finish()

func _collect(object):
	object.done = true
	collected[object.kind].append(object.id)
	if object.kind == "lanterns":
		object.node.texture.region.position.x = 512
		object.node.modulate = Color(1.2,1.2,0.8)
	else:
		object.node.hide()
	_save()
	_update_hud()

func _talk(index:int):
	var key = ["lanterns","wood","flowers"][index]
	var needed = [3,3,5][index]
	var ready = collected[key].size() == needed
	var text = [
		["Porsuk", "Patika karanlık. Yukarıdaki üç feneri yakabilir misin?", "Artık yolu görebiliyorum! Seninle festivale geliyorum."],
		["Maymun", "Köprü için üç tahta gerekiyor. Dallardaki tahtaları bulalım mı?", "Tahtalar tamam! Köprüyü onardım. Haydi birlikte gidelim."],
		["Pıtpıt", "Rüzgâr beş papatyayı savurdu. Platformlardakileri toplar mısın?", "Çiçekler kurtuldu! Festivali birlikte süsleyelim."]
	][index]
	if ready:
		_recruit(index)
	_show_dialog(index,text[0],text[2] if ready else text[1],"Birlikte devam" if ready else "Yardım edeceğim")

func _recruit(index:int,persist=true):
	var f = friends[index]
	f.recruited = true
	f.leader = player if index==0 or not friends[index-1].recruited else friends[index-1]
	if not index in collected.friends:
		collected.friends.append(index)
	else:
		f.position = player.position-Vector2(80*(index+1),0)
	_refresh_bridge()
	if persist:
		_save()
		_update_hud()

func _refresh_bridge():
	for bridge in bridge_nodes:
		bridge.visible = 1 in collected.friends
		bridge.collision_layer = 1 if 1 in collected.friends else 0

func _save():
	if not test_mode:
		SaveStore.write_save(collected)

func _build_hud():
	hud = CanvasLayer.new()
	add_child(hud)
	var top = ColorRect.new()
	top.color = Color(0.03,0.16,0.15,0.9)
	top.size = Vector2(1280,96)
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(top)
	title_label = _label("ÇATPAT / FESTİVAL YOLU",Vector2(32,15),24)
	mission_label = _label("",Vector2(32,51),19)
	counter_label = _label("",Vector2(735,22),20)
	prompt_label = _label("",Vector2(340,560),23)
	var pause_button = Button.new()
	pause_button.text = "II"
	pause_button.position = Vector2(1200,16)
	pause_button.size = Vector2(55,55)
	pause_button.pressed.connect(_toggle_pause)
	hud.add_child(pause_button)
	for spec in [["◀",Rect2(25,600,94,92)],["▶",Rect2(135,600,94,92)],["YARDIM",Rect2(1010,610,100,80)],["ZIPLA",Rect2(1130,575,125,115)]]:
		var visual = Panel.new()
		visual.position = spec[1].position
		visual.size = spec[1].size
		visual.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var style = StyleBoxFlat.new()
		style.bg_color = Color(0.04,0.20,0.18,0.8)
		style.border_color = Color(0.89,0.78,0.43,0.8)
		style.set_border_width_all(2)
		style.set_corner_radius_all(22)
		visual.add_theme_stylebox_override("panel",style)
		hud.add_child(visual)
		var label = Label.new()
		label.text = spec[0]
		label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size",22)
		visual.add_child(label)

func _label(text:String,pos:Vector2,font_size:int) -> Label:
	var label = Label.new()
	label.text = text
	label.position = pos
	label.add_theme_font_size_override("font_size",font_size)
	label.add_theme_color_override("font_color",Color("fff3cb"))
	label.add_theme_color_override("font_shadow_color",Color("12372b"))
	label.add_theme_constant_override("shadow_offset_x",2)
	label.add_theme_constant_override("shadow_offset_y",2)
	hud.add_child(label)
	return label

func _update_hud():
	if not is_instance_valid(mission_label):
		return
	var goal = "Porsuk için üç feneri yak."
	if 0 in collected.friends:
		goal = "Maymun için üç tahta bul; köprüyü birlikte onarın."
	if 1 in collected.friends:
		goal = "Pıtpıt'ın beş papatyasını topla."
	if 2 in collected.friends:
		goal = "Arkadaşlarınla festival alanına ulaş!"
	mission_label.text = goal
	counter_label.text = "Fener %d/3   Tahta %d/3   Çiçek %d/5\nYol arkadaşları %d/3" % [collected.lanterns.size(),collected.wood.size(),collected.flowers.size(),collected.friends.size()]

func _input(event):
	if event is InputEventScreenTouch:
		if event.pressed:
			touch_points[event.index] = event.position
		else:
			touch_points.erase(event.index)
		_update_touches()
	elif event is InputEventScreenDrag:
		touch_points[event.index] = event.position
		_update_touches()
	elif event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT:
		if event.pressed:
			touch_points[-1] = event.position
		else:
			touch_points.erase(-1)
		_update_touches()

func _update_touches():
	touch_axis = 0
	touch_jump = false
	for point in touch_points.values():
		if Rect2(25,600,94,92).has_point(point):
			touch_axis -= 1
		if Rect2(135,600,94,92).has_point(point):
			touch_axis += 1
		if Rect2(1130,575,125,115).has_point(point):
			touch_jump = true
		if Rect2(1010,610,100,80).has_point(point):
			interact_request = true

func _clear_overlay():
	if is_instance_valid(overlay):
		overlay.queue_free()
	dialog_open = false
	paused = false
	touch_points.clear()
	_update_touches()
	interact_request = false
	last_jump_touch = false

func _panel(title:String,body:String,button:String,callback:Callable):
	overlay = ColorRect.new()
	overlay.color = Color(0.02,0.12,0.10,0.95)
	overlay.size = Vector2(1280,720)
	hud.add_child(overlay)
	var heading = Label.new()
	heading.text = title
	heading.position = Vector2(180,145)
	heading.add_theme_font_size_override("font_size",46)
	overlay.add_child(heading)
	var copy = Label.new()
	copy.text = body
	copy.position = Vector2(180,240)
	copy.size = Vector2(900,250)
	copy.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	copy.add_theme_font_size_override("font_size",27)
	overlay.add_child(copy)
	var b = Button.new()
	b.text = button
	b.position = Vector2(180,535)
	b.size = Vector2(420,75)
	b.add_theme_font_size_override("font_size",26)
	b.pressed.connect(callback)
	overlay.add_child(b)
	b.grab_focus()

func _show_intro():
	dialog_open = true
	_panel("Çatpat: Festival Yolu", "Koş, zıpla ve arkadaşlarına yardım et.\n\nA / D veya oklar: hareket     Boşluk: zıpla     E: konuş / fener yak\nTelefonda soldan yön, sağdan zıplama ve yardım.\n\nİlk hedef: yukarıdaki üç feneri yakıp Porsuk ile konuş.","Yola çık",_clear_overlay)

	var review_button = Button.new()
	review_button.text = "Yeni çizgi roman taslağı"
	review_button.position = Vector2(640,535)
	review_button.size = Vector2(450,75)
	review_button.add_theme_font_size_override("font_size",26)
	review_button.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/comic_review.tscn"))
	overlay.add_child(review_button)

func _show_dialog(index:int,speaker:String,body:String,button_text:String):
	dialog_open = true
	_panel(speaker,body,button_text,_clear_overlay)
	# Comic artwork is raster image; no code-drawn characters.
	var picture = TextureRect.new()
	var atlas = AtlasTexture.new()
	atlas.atlas = load("res://assets/world/comic.webp")
	atlas.region = Rect2(index*682.66,250,682.66,518)
	picture.texture = atlas
	picture.position = Vector2(790,175)
	picture.size = Vector2(350,280)
	picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	overlay.add_child(picture)
	# Keep dialogue copy out of the illustration.
	for child in overlay.get_children():
		if child is Label and child.position.y==240:
			child.size.x = 560

func _toggle_pause():
	if dialog_open:
		return
	if paused:
		_clear_overlay()
	else:
		paused = true
		_panel("Kısa bir mola", "İlerlemen kaydedildi. Hazır olunca yola devam edelim.\n\nDüşersen son bayrağa dönersin. Arkadaşların seni bekler.","Devam et",_clear_overlay)

func _finish():
	player.celebrating = true
	for f in friends:
		f.celebrating = true
	dialog_open = true
	_panel("Birlikte geldik!", "Porsuk ışıkları, Maymun köprüyü, Pıtpıt çiçekleri getirdi.\nÇatpat artık biliyor: festivalin en güzel yanı, arkadaşlarla olmak.\n\nBirinci gün platform bölümü tamamlandı.","Festivalde dolaş",_clear_overlay)

func _notification(what):
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		touch_points.clear()
		_update_touches()
		if is_instance_valid(player) and not dialog_open and not paused:
			_toggle_pause()

func _capture_later():
	await get_tree().create_timer(1.0).timeout
	_clear_overlay()
	await get_tree().create_timer(1.0).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://docs/gameplay.png")
	get_tree().quit()

func _run_smoke():
	await get_tree().create_timer(0.5).timeout
	assert(player.is_on_floor(),"Player should stand on starting platform")
	var start = player.position.x
	Input.action_press("right")
	await get_tree().create_timer(0.5).timeout
	Input.action_release("right")
	assert(player.position.x > start+80,"Horizontal movement failed")
	var floor_y = player.position.y
	Input.action_press("jump")
	await get_tree().create_timer(0.18).timeout
	assert(player.position.y < floor_y-30,"Jump failed")
	assert(player.anim.animation=="jump","Airborne animation failed")
	Input.action_release("jump")
	await get_tree().create_timer(0.9).timeout
	assert(player.is_on_floor(),"Landing failed")
	# Reachability gate: the first 125-unit raised platform must be jumpable.
	player.position = Vector2(285,599)
	player.velocity = Vector2.ZERO
	await get_tree().create_timer(0.1).timeout
	Input.action_press("right")
	Input.action_press("jump")
	await get_tree().create_timer(0.45).timeout
	Input.action_release("right")
	await get_tree().create_timer(0.45).timeout
	Input.action_release("jump")
	assert(player.is_on_floor() and player.position.y < 500,"First platform unreachable")
	touch_points = {1:Vector2(180,650),2:Vector2(1200,630)}
	_update_touches()
	assert(touch_axis==1 and touch_jump,"Simultaneous touch failed")
	touch_points.erase(1)
	_update_touches()
	assert(touch_axis==0 and touch_jump,"Independent touch release failed")
	touch_points.clear()
	_update_touches()
	for f in friends:
		assert(f.anim.sprite_frames.get_frame_count("run")==6,"Companion missing run frames")
	for object in objects:
		_collect(object)
	for i in range(3):
		_recruit(i)
	assert(collected.friends.size()==3,"Recruitment failed")
	assert(bridge_nodes[0].collision_layer==1,"Bridge not enabled")
	player.position.y = 1000
	await get_tree().create_timer(0.1).timeout
	assert(player.position.y < 700,"Checkpoint reset failed")
	print("PASS: movement, jump, landing, raised platform, multi-touch, frame states, three companions, bridge, checkpoint")
	get_tree().quit()

func _run_preview():
	await get_tree().create_timer(0.2).timeout
	player.position = Vector2(250,570)
	for i in range(3):
		_recruit(i,false)
		friends[i].position = Vector2(175-i*65,570)
	_update_hud()
	await get_tree().create_timer(0.3).timeout
	Input.action_press("right")
	Input.action_press("jump")
	await get_tree().create_timer(0.65).timeout
	Input.action_release("jump")
	await get_tree().create_timer(0.35).timeout
	Input.action_press("jump")
	await get_tree().create_timer(0.7).timeout
	Input.action_release("jump")
	await get_tree().create_timer(0.6).timeout
	Input.action_press("jump")
	await get_tree().create_timer(0.8).timeout
	Input.action_release("jump")
	await get_tree().create_timer(1.0).timeout
	Input.action_release("right")
	await get_tree().create_timer(0.5).timeout
	get_tree().quit()
