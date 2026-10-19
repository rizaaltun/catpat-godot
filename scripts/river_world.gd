extends Node2D
var control_display=preload("res://scripts/core/control_display.gd").new()
const Quest=preload("res://scripts/core/quest_state.gd")
const Save=preload("res://scripts/core/save_service.gd")
const Director=preload("res://scripts/core/level_director.gd")
const Level=preload("res://scripts/core/river_level.gd")
const Actor=preload("res://scripts/polish_actor.gd")
const Monkey=preload("res://scripts/monkey_actor.gd")
const UI=preload("res://scripts/polish_ui.gd")
const Comic=preload("res://scripts/core/comic_panel.gd")
var state=Quest.new()
var saves=Save.new()
var director=Director.new()
var runner=preload("res://scripts/dialogue_runner.gd").new()
var router=preload("res://scripts/core/input_router.gd").new()
var player
var badger
var monkey
var level
var camera
var backdrop: Sprite2D
var screen: Control
var quest: Label
var hint: Label
var counter: Label
var comic
var active_line: Label
var line_id=""
var chars=0.0
var mode="play"
var prior_mode="play"
var data={}
var save_path="user://festival_v3.json"
var automated=false
var pending={}
var pending_after: Callable
var axis=0.0
var jump=false
var last_jump=false
var action=false
var rescue_count=0
var follower_rescues=0
var build_elapsed=0.0
var save_clock=0.0
var plank: Sprite2D
var rope: Sprite2D
var notice=0.0
var test_failed=false
func _ready():
	save_path=str(get_tree().get_meta("journey_save_path",save_path))
	process_physics_priority=-20
	automated="--v10-test" in OS.get_cmdline_user_args() or "--v10-capture" in OS.get_cmdline_user_args()
	if automated:save_path="user://v10-test-isolated.json"
	for a in {"left":[KEY_A,KEY_LEFT],"right":[KEY_D,KEY_RIGHT],"jump":[KEY_SPACE,KEY_W,KEY_UP],"interact":[KEY_E],"pause":[KEY_ESCAPE]}:
		if not InputMap.has_action(a):InputMap.add_action(a)
		for key in {"left":[KEY_A,KEY_LEFT],"right":[KEY_D,KEY_RIGHT],"jump":[KEY_SPACE,KEY_W,KEY_UP],"interact":[KEY_E],"pause":[KEY_ESCAPE]}[a]:
			var ev=InputEventKey.new();ev.physical_keycode=key;InputMap.action_add_event(a,ev)
	backdrop=Sprite2D.new();backdrop.texture=load("res://assets/chapter-v10/river.png");backdrop.centered=false;backdrop.z_index=-30;backdrop.scale=Vector2.ONE*720.0/backdrop.texture.get_height();add_child(backdrop)
	level=Level.new();add_child(level)
	player=Actor.new();player.controlled=true;player.position=Vector2(200,519);player.checkpoint=Vector2(200,520);add_child(player)
	badger=Actor.new();badger.character_id="badger";badger.position=Vector2(1085,519);add_child(badger)
	monkey=Monkey.new();monkey.character_id="monkey";monkey.position=Vector2(935,519);add_child(monkey)
	camera=preload("res://scripts/core/camera_rig.gd").new();camera.configure(Level.WIDTH);player.add_child(camera)
	plank=object_sprite("plank.png",Vector2(2230,600),0.12)
	rope=object_sprite("rope.png",Vector2(2110,360),0.12)
	var layer=CanvasLayer.new();add_child(layer);screen=Control.new();layer.add_child(screen)
	runner.load_data(JSON.parse_string(FileAccess.get_file_as_string("res://preproduction/story/river-dialogue.json")));runner.completed.connect(dialogue_done)
	var loaded={"ok":true,"data":fixture()} if automated else saves.load_progress(save_path)
	if not loaded.ok or loaded.data.chapter_id!="B02":
		mode="error";freeze(true);message("Dere kaydı açılamadı","Patikaya dönüp yeniden deneyebilirsin.",to_menu);return
	apply_data(loaded.data);spawn_saved();build_hud()
	if state.has(Quest.RIVER_COMPLETE):complete()
	if automated:run_test()
func fixture() -> Dictionary:
	var q=Quest.new()
	for e in [Quest.ACCEPTED]+Quest.LIGHTS+[Quest.JOINED,Quest.COMPLETE]:q.apply(e)
	var d=saves.fresh();d.chapter_id="B02";d.geometry="river-v10";d.checkpoint_id="b02.entry";d.quest_flags=q.flags;d.party_ids=q.party_ids();return d
func object_sprite(file: String, foot: Vector2, factor: float) -> Sprite2D:
	var s=Sprite2D.new();s.texture=load("res://assets/chapter-v10/"+file);s.scale=Vector2.ONE*factor;s.position=foot-Vector2(0,55);add_child(s);return s
func clear_screen():
	for c in screen.get_children():screen.remove_child(c);c.queue_free()
func freeze(value: bool):
	for a in [player,badger,monkey]:a.frozen=value
func reset_input():
	axis=0;jump=false;action=false;router.reset();last_jump=Input.is_action_pressed("jump")
	player.input_axis=0;player.jump_request=false;player.jump_buffer=0;player.jump_held=false;player.velocity=Vector2.ZERO
func build_hud():
	clear_screen()
	UI.texture("res://assets/polish-v3/panel.png",Rect2(28,18,425,120),screen)
	UI.label("02  /  DOSTLUK DERESİ",Rect2(57,43,350,25),16,screen,Color("ebc774"))
	quest=UI.label("",Rect2(57,74,375,60),22,screen)
	UI.texture("res://assets/polish-v3/panel.png",Rect2(911,24,239,104),screen)
	counter=UI.label("",Rect2(945,48,185,60),20,screen)
	UI.button("Ⅱ",Rect2(1158,28,96,96),screen,pause_game)
	hint=UI.label("",Rect2(252,669,776,42),20,screen);hint.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_color_override("font_shadow_color",Color("102925"));hint.add_theme_constant_override("shadow_outline_size",5)
	var left=UI.button("‹",Rect2(28,593,96,96),screen,func():pass)
	var right=UI.button("›",Rect2(140,593,96,96),screen,func():pass)
	var use=UI.button("E",Rect2(1043,593,96,96),screen,func():pass)
	var up=UI.button("↑",Rect2(1154,583,106,106),screen,func():pass,true)
	for b in [left,right,use,up]:
		b.mouse_filter=Control.MOUSE_FILTER_IGNORE
		for key in ["normal","hover","pressed","focus"]:
			var skin=StyleBoxTexture.new();skin.texture=load("res://assets/polish-v3/jump-button.png");skin.region_rect=Rect2(130,130,1000,1000)
			if b!=up:skin.modulate_color=Color(0.25,0.40,0.34)
			b.add_theme_stylebox_override(key,skin)
	control_display.bind([left,right,use,up])
	router.bind_controls(left.get_rect(),right.get_rect(),up.get_rect(),use.get_rect());update_hud()
	if state.has(Quest.RIVER_COMPLETE):UI.button("Papatya Bahçesi’ne geç",Rect2(470,30,395,70),screen,go_garden,true)
func update_hud():
	if not is_instance_valid(quest):return
	quest.text="Maymun ile konuş" if not state.has(Quest.RIVER_ACCEPTED) else "Tahta ve halatı bul" if not state.has(Quest.SUPPLIED) else "Köprüyü birlikte onar" if not state.has(Quest.READY) else "Maymun’u yolculuğa çağır" if not state.has(Quest.MONKEY) else "Birlikte karşı kıyıya geç"
	if state.has(Quest.PLANK) and state.has(Quest.ROPE) and not state.has(Quest.SUPPLIED):quest.text="Köprü başına dön"
	if state.has(Quest.RIVER_COMPLETE):quest.text="Birlikte karşı kıyıdayız"
	counter.text="Tahta  %s\nHalat  %s"%["✓" if state.has(Quest.PLANK) else "—","✓" if state.has(Quest.ROPE) else "—"]
func snapshot(q=null) -> Dictionary:
	if q==null:q=state
	var d=data.duplicate(true);d.quest_flags=q.flags.duplicate();d.collectibles=q.collectibles.duplicate();d.party_ids=q.party_ids()
	if player.is_on_floor() and player.position.y>515 and player.position.y<525:
		if player.position.x<1450:d.checkpoint_id="b02.hub" if player.position.x>700 else "b02.entry"
		elif player.position.x>2920 and q.has(Quest.READY):d.checkpoint_id="b02.exit"
	return d
func apply_data(d: Dictionary):
	data=d.duplicate(true);state.read(data)
	plank.visible=not state.has(Quest.PLANK);rope.visible=not state.has(Quest.ROPE)
	level.finish_build_visual();level.set_bridge(state.has(Quest.READY))
	badger.recruited=state.has(Quest.MONKEY);monkey.recruited=state.has(Quest.MONKEY)
	for a in [badger,monkey]:a.route_walk_only=true
	update_hud()
func spawn_saved():
	player.position=director.anchor(data.checkpoint_id)-Vector2(0,1);player.velocity=Vector2.ZERO
	if state.has(Quest.MONKEY):
		badger.position=player.position-Vector2(145,0);monkey.position=player.position-Vector2(285,0)
	else:badger.position=Vector2(1085,519);monkey.position=Vector2(935,519)
	for a in [badger,monkey]:a.velocity=Vector2.ZERO;a.route_moving=false
	reset_input();camera.reset_smoothing()
func persist(d: Dictionary, after: Callable=Callable()) -> bool:
	if not saves.valid(d):push_error("Invalid river state");return false
	if not automated and not saves.save(save_path,d):
		pending=d.duplicate(true);pending_after=after;prior_mode=mode;mode="save_error";freeze(true);reset_input()
		message("Kaydedemedik","Eşyaların güvende. Devam etmek için yeniden deneyelim.",retry_save);return false
	apply_data(d)
	if after.is_valid():after.call()
	return true
func event(id: String, after: Callable=Callable()) -> bool:
	var q=state.copy()
	if not q.apply(id):return false
	return persist(snapshot(q),after)
func retry_save():
	if pending.is_empty():return
	var d=pending.duplicate(true);var after=pending_after
	mode=prior_mode
	if persist(d,after):
		pending.clear()
		if mode==prior_mode:mode="play";freeze(false);build_hud();reset_input()
func message(title: String, body: String, callback: Callable):
	clear_screen();UI.texture("res://assets/polish-v3/panel.png",Rect2(285,150,710,440),screen)
	UI.label(title,Rect2(372,235,540,60),32,screen)
	UI.label(body,Rect2(375,315,530,100),24,screen)
	UI.button("Devam",Rect2(490,459,300,66),screen,callback,true)
func dialogue(id: String):
	if mode!="play":return
	if not runner.begin(id,{"meet":not state.has(Quest.RIVER_ACCEPTED),"ready":state.has(Quest.READY) and not state.has(Quest.MONKEY),"exit":state.has(Quest.MONKEY) and not state.has(Quest.RIVER_COMPLETE)}):return
	mode="dialogue";reset_input();freeze(true);clear_screen()
	comic=Comic.new();screen.add_child(comic)
	comic.build("DOSTLUK DERESİ  /  BİRLİKTE BİR KÖPRÜ",advance,"Çatpat","Maymun","res://assets/review-v2/catpat-idle-r2.png","res://assets/chapter-v10/monkey-idle.png")
	comic.portrait_right.flip_h=true;comic.portrait_right.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	comic.portrait_right.position=Vector2(797,260);comic.portrait_right.size=Vector2(420,440)
	line_id="";refresh_line()
func refresh_line():
	if runner.active and line_id!=runner.current.id:line_id=runner.current.id;chars=0;active_line=comic.present(runner.current)
func advance():runner.advance();refresh_line()
func dialogue_done(id: String,_first: bool):
	event(id,func():
		mode="play";build_hud();freeze(false);reset_input()
		if id==Quest.RIVER_COMPLETE:complete())
func start_build():
	if not state.has(Quest.PLANK) or not state.has(Quest.ROPE) or state.has(Quest.READY):return
	event(Quest.SUPPLIED,func():mode="building";build_elapsed=0;freeze(true);reset_input();hint.text="Maymun tahtaları halatla bağlıyor…")
func finish_build():
	event(Quest.READY,func():mode="play";build_hud();freeze(false);reset_input();notice=3)
func pause_game():
	if mode not in ["play","building"]:return
	prior_mode=mode;mode="pause";freeze(true);reset_input();clear_screen()
	UI.texture("res://assets/polish-v3/panel.png",Rect2(325,110,630,520),screen)
	UI.label("Küçük bir mola",Rect2(415,204,450,60),34,screen)
	UI.button("Devam et",Rect2(450,300,380,65),screen,resume,true)
	UI.button("Dereyi baştan oyna",Rect2(450,389,380,62),screen,confirm_restart)
	UI.button("Ana menü",Rect2(450,476,380,62),screen,save_menu)
func resume():mode=prior_mode;build_hud();freeze(mode=="building");reset_input()
func confirm_restart():
	message("Dereyi baştan oynayalım mı?","Yalnız dere görevi sıfırlanır. Porsuk ve patikadaki ilerlemen korunur.",restart)
	UI.button("Vazgeç",Rect2(490,540,300,48),screen,resume).grab_focus()
func restart():
	var q=state.copy()
	for id in Quest.RIVER_EVENTS:q.flags.erase(id)
	var d=snapshot(q);d.checkpoint_id="b02.entry"
	persist(d,func():mode="play";spawn_saved();build_hud();freeze(false))
func save_menu():persist(snapshot(),to_menu)
func to_menu():get_tree().change_scene_to_file("res://scenes/polish_v3.tscn")
func complete():
	mode="complete";freeze(true);reset_input();clear_screen()
	UI.texture("res://assets/polish-v3/panel.png",Rect2(260,115,760,510),screen)
	UI.label("Dostluk Deresi tamamlandı",Rect2(352,204,580,60),30,screen)
	UI.label("Maymun ekibe katıldı. Sıradaki durak Papatya Bahçesi!",Rect2(355,294,565,95),25,screen)
	UI.button("Papatya Bahçesi",Rect2(420,433,440,70),screen,go_garden,true)
	UI.button("Derede dolaş",Rect2(365,530,267,62),screen,func():mode="play";build_hud();freeze(false))
	UI.button("Ana menü",Rect2(655,530,267,62),screen,save_menu)
func go_garden():
	if not state.has(Quest.RIVER_COMPLETE) or director.transitioning:return
	var prepared=director.prepare_transition("B03","b03.entry")
	if not prepared.ok:return
	var previous=snapshot();var target=previous.duplicate(true)
	target.chapter_id="B03";target.geometry="garden-v12";target.checkpoint_id="b03.entry"
	if not saves.save(save_path,target):
		director.finish_transition(false,"B03");mode="transition_error";freeze(true);reset_input()
		message("Bahçe yoluna geçemedik","Dere kaydın korunuyor. Yeniden deneyebilirsin.",go_garden);return
	var error=get_tree().change_scene_to_packed(prepared.scene)
	if error!=OK:
		var restored=saves.save(save_path,previous)
		director.finish_transition(false,"B03");mode="transition_error";freeze(true)
		message("Bahçe sahnesi açılamadı","Dere kaydına döndük." if restored else "Güvenli bahçe giriş kaydın korunuyor.",go_garden)
	else:director.finish_transition(true,"B03")
func _process(delta):
	if not is_instance_valid(player):return
	backdrop.position.x=camera.get_screen_center_position().x-640-clampf(camera.get_screen_center_position().x-640,0,Level.WIDTH-1280)*0.15
	runner.tick(delta)
	if mode=="dialogue":
		chars+=delta*34
		if chars>=runner.current.text.length():runner.revealed=true
		active_line.visible_characters=-1 if runner.revealed else int(chars)
		return
	if mode=="building":
		build_elapsed+=delta;level.set_build_progress(build_elapsed/2.5)
		if build_elapsed>=2.5:finish_build()
		return
	if mode!="play":return
	player.input_axis=clampf(Input.get_axis("left","right")+axis,-1,1);camera.desired_axis=player.input_axis
	player.jump_held=Input.is_action_pressed("jump") or jump
	if player.jump_held and not last_jump:player.jump_request=true
	last_jump=player.jump_held
	var use=action or Input.is_action_just_pressed("interact");action=false
	hint.text=""
	if not state.has(Quest.RIVER_ACCEPTED):
		hint.text="E · Maymun ile konuş" if absf(player.position.x-monkey.position.x)<145 else "Köprü başındaki Maymun’a ilerle"
		if use and absf(player.position.x-monkey.position.x)<145 and player.is_on_floor():dialogue("river_meet");return
	elif not state.has(Quest.READY):
		hint.text="Üst dallarda halat · Alt kıyıda tahta"
		for item in [{"id":Quest.PLANK,"pos":Vector2(2230,600),"name":"Tahtaları al"},{"id":Quest.ROPE,"pos":Vector2(2110,360),"name":"Halatı al"}]:
			if not state.has(item.id) and player.is_on_floor() and player.position.distance_to(item.pos)<85:
				hint.text="E · "+item.name
				if use:event(item.id);return
		if state.has(Quest.PLANK) and state.has(Quest.ROPE):
			hint.text="İki parça hazır · Köprü başına dön"
			if absf(player.position.x-1250)<140 and absf(player.position.y-520)<4:
				hint.text="E · Köprüyü birlikte onar"
				if use:start_build();return
	elif not state.has(Quest.MONKEY):
		hint.text="E · Maymun’u yolculuğa çağır" if absf(player.position.x-1250)<140 else "Maymun köprü başında seni bekliyor"
		if use and absf(player.position.x-1250)<140 and player.is_on_floor():dialogue("river_join");return
	elif not state.has(Quest.RIVER_COMPLETE) and player.position.x>3180:
		hint.text="Arkadaşlarınla birlikte çıkışa yaklaş"
		if party_at_exit():
			hint.text="E · Birlikte yolculuğa devam et"
			if use:dialogue("river_exit");return
	notice=maxf(0,notice-delta)
	if notice>0:hint.text="Köprü hazır! Maymun’u yanına çağır."
	save_clock+=delta
	if save_clock>2:save_clock=0;persist(snapshot())
func party_at_exit() -> bool:
	return state.has(Quest.MONKEY) and player.is_on_floor() and badger.is_on_floor() and monkey.is_on_floor() and player.position.x>3180 and player.position.distance_to(monkey.position)<380 and player.position.distance_to(badger.position)<240
func _physics_process(_delta):
	if mode!="play":return
	player.position.x=clampf(player.position.x,380 if state.has(Quest.MONKEY) else 20,3570)
	if state.has(Quest.MONKEY):
		for pair in [[badger,player,145.0],[monkey,badger,140.0]]:
			var actor=pair[0];var leader=pair[1];var dx=leader.position.x-actor.position.x
			actor.route_target=Vector2(leader.position.x-float(pair[2]),520)
			actor.route_moving=absf(actor.route_target.x-actor.position.x)>10
	if state.has(Quest.MONKEY):
		if absf(badger.velocity.x)<10:badger.anim.flip_h=player.anim.flip_h
		if absf(monkey.velocity.x)<10:monkey.anim.flip_h=not player.anim.flip_h
	for a in [player,badger,monkey]:
		if a.position.y>790:
			if a==player:rescue_count+=1;a.position=Vector2(1160,519)
			else:follower_rescues+=1;a.position=Vector2(1100 if a==badger else 940,519)
			a.velocity=Vector2.ZERO;a.jump_request=false;a.jump_buffer=0
			if a==player:reset_input();camera.reset_smoothing()
func _input(e):
	if control_display.observe(e):router.reset();axis=0;jump=false;action=false
	if e is InputEventKey and e.pressed and not e.echo and e.keycode==KEY_ESCAPE:
		if mode=="pause":resume()
		else:pause_game()
		return
	if mode=="dialogue" and e is InputEventKey and e.pressed and not e.echo and e.keycode in [KEY_E,KEY_SPACE,KEY_ENTER]:advance();return
	if mode=="play" and control_display.accepts(e) and router.consume(e):axis=router.axis;jump=router.jump_held;action=action or router.interact_pressed
func _notification(what):
	if what==NOTIFICATION_APPLICATION_FOCUS_OUT and mode in ["play","building"]:pause_game()

func check(ok: bool, title: String):
	print(("PASS V10: " if ok else "FAIL V10: ")+title)
	if not ok:test_failed=true
func test_finish_dialogue():
	for i in 24:
		if not runner.active:break
		runner.revealed=true;runner.input_cooldown=0;advance()
func walk_to(x: float, frames=900) -> bool:
	jump=false
	for i in frames:
		axis=signf(x-player.position.x) if absf(x-player.position.x)>8 else 0.0
		await get_tree().physics_frame
		if absf(x-player.position.x)<12 and player.is_on_floor():axis=0;return true
	axis=0;return false
func hop_to(target: Vector2) -> bool:
	jump=false;axis=0
	for i in 8:await get_tree().physics_frame
	jump=true
	for i in 115:
		axis=signf(target.x-player.position.x) if absf(target.x-player.position.x)>8 else 0.0
		if i>40:jump=false
		await get_tree().physics_frame
		if i>15 and player.is_on_floor() and player.position.distance_to(target)<24:axis=0;jump=false;return true
	axis=0;jump=false;return false
func use_action():
	action=true
	# Rendering can batch physics ticks; interaction is consumed by _process.
	for i in 3:await get_tree().process_frame
	for i in 5:await get_tree().physics_frame
func capture(name: String):
	if "--v10-capture" not in OS.get_cmdline_user_args():return
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://preproduction/qa/v11/"+name+".png")
func run_test():
	for i in 40:await get_tree().physics_frame
	check(state.has(Quest.COMPLETE) and not state.has(Quest.RIVER_ACCEPTED),"B01 preserved on river entry")
	check(not level.ready_bridge and not level.deck.visible and level.bridge_body.collision_layer==0,"bridge starts visibly and physically closed")
	check(await walk_to(800),"walk from entry to Maymun")
	await use_action();check(mode=="dialogue","meet comic via proximity E")
	runner.revealed=true;await capture("meet-comic");test_finish_dialogue()
	check(state.has(Quest.RIVER_ACCEPTED),"meet accepts bridge quest")
	await walk_to(1300)
	check(await hop_to(Vector2(1310,430)),"jump from hub onto upper start")
	await walk_to(1360)
	check(await hop_to(Vector2(1530,350)),"upper jump one")
	await walk_to(1590)
	check(await hop_to(Vector2(1780,310)),"upper jump two")
	await walk_to(1860)
	check(await hop_to(Vector2(2100,360)),"upper jump three")
	await use_action();check(state.has(Quest.ROPE) and not rope.visible,"rope collected by grounded E")
	await capture("upper-rope")
	# Walk back to each take-off point before returning; no teleport route fixtures.
	await walk_to(2015)
	check(await hop_to(Vector2(1830,310)),"return upper three")
	await walk_to(1740)
	check(await hop_to(Vector2(1560,350)),"return upper two")
	await walk_to(1480)
	check(await hop_to(Vector2(1320,430)),"return upper one")
	await walk_to(1415)
	for i in 65:await get_tree().physics_frame
	check(absf(player.position.y-520)<4,"return to ground hub")
	check(await hop_to(Vector2(1620,600)),"lower drop onto first bank")
	await walk_to(1680)
	check(await hop_to(Vector2(1900,650)),"lower jump to second bank")
	await walk_to(1980)
	check(await hop_to(Vector2(2230,600)),"lower jump to planks")
	await use_action();check(state.has(Quest.PLANK) and not plank.visible,"planks collected by grounded E")
	await capture("lower-planks")
	await walk_to(2150)
	check(await hop_to(Vector2(1950,650)),"return lower third bank")
	await walk_to(1840)
	check(await hop_to(Vector2(1660,600)),"return lower second bank")
	await walk_to(1550)
	check(await hop_to(Vector2(1380,520)),"return lower first bank")
	check(rescue_count==0,"normal collection routes require no rescue")
	await walk_to(1250);await use_action()
	check(mode=="building" and state.has(Quest.SUPPLIED) and not state.has(Quest.READY),"build starts from durable supplied state")
	await get_tree().create_timer(0.6).timeout
	pause_game();var elapsed_before=build_elapsed
	await get_tree().create_timer(0.3).timeout
	check(mode=="pause" and build_elapsed==elapsed_before and level.bridge_body.collision_layer==0,"pause freezes assembly and keeps collision closed")
	resume()
	for i in 240:
		await get_tree().physics_frame
		if state.has(Quest.READY):break
	check(state.has(Quest.READY) and level.deck.visible and level.bridge_body.collision_layer==1,"ready commit enables visible and physical bridge")
	await capture("bridge-ready")
	await walk_to(1250);await use_action();test_finish_dialogue()
	check(state.has(Quest.MONKEY) and data.party_ids==["badger","monkey"],"Maymun joins exactly once")
	print("V10 VIDEO READY")
	check(await walk_to(3250,1600),"walk across repaired bridge")
	for i in 180:await get_tree().physics_frame
	check(party_at_exit(),"two physical followers reach exit")
	check(follower_rescues==0,"followers crossed without rescue or teleport")
	check(not state.has(Quest.RIVER_COMPLETE),"arrival alone does not complete chapter")
	await capture("party-exit")
	check(await walk_to(2940),"party reverses on bridge")
	for i in 120:await get_tree().physics_frame
	check(absf(player.position.x-badger.position.x)>80 and absf(badger.position.x-monkey.position.x)>80,"reversal settles into distinct party slots")
	await walk_to(3250)
	for i in 120:await get_tree().physics_frame
	await use_action();test_finish_dialogue()
	check(state.has(Quest.RIVER_COMPLETE) and mode=="complete","explicit three-person exit completes B02")
	await capture("complete")
	var saved=snapshot();apply_data(saved);spawn_saved()
	check(state.has(Quest.RIVER_COMPLETE) and level.ready_bridge and data.party_ids.size()==2,"completed reload preserves bridge and party")
	restart();check(state.has(Quest.COMPLETE) and not state.has(Quest.RIVER_ACCEPTED) and data.party_ids==["badger"],"B02 restart preserves B01 and Porsuk")
	print("V10 RIVER SUITE FAILED" if test_failed else "V10 RIVER SUITE PASSED")
	get_tree().quit(1 if test_failed else 0)
