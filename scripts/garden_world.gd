extends Node2D
var control_display=preload("res://scripts/core/control_display.gd").new()
const Quest=preload("res://scripts/core/quest_state.gd")
const Save=preload("res://scripts/core/save_service.gd")
const Director=preload("res://scripts/core/level_director.gd")
const Level=preload("res://scripts/core/garden_level.gd")
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
var rabbit
var flower_bed
var windscreen: Sprite2D
var delivered_basket: Sprite2D
var basket_vine: Sprite2D
var lever: Sprite2D
var lower_elapsed=0.0
var wind_clock=0.0
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
var tie: Sprite2D
var basket: Sprite2D
var notice=0.0
var test_failed=false
var transition_change:Callable
func _ready():
	save_path=str(get_tree().get_meta("journey_save_path",save_path))
	process_physics_priority=-20
	automated="--v12-test" in OS.get_cmdline_user_args() or "--v12-capture" in OS.get_cmdline_user_args() or "--v13-test" in OS.get_cmdline_user_args() or "--v13-capture" in OS.get_cmdline_user_args()
	if automated:save_path="user://v12-test-isolated.json"
	var mapping={"left":[KEY_A,KEY_LEFT],"right":[KEY_D,KEY_RIGHT],"jump":[KEY_SPACE,KEY_W,KEY_UP],"interact":[KEY_E],"pause":[KEY_ESCAPE]}
	for a in mapping:
		if not InputMap.has_action(a):InputMap.add_action(a)
		for key in mapping[a]:
			var ev=InputEventKey.new();ev.physical_keycode=key;InputMap.action_add_event(a,ev)
	backdrop=Sprite2D.new();backdrop.texture=load("res://assets/chapter-v12/garden.webp");backdrop.centered=false;backdrop.z_index=-30;backdrop.scale=Vector2.ONE*720.0/backdrop.texture.get_height();add_child(backdrop)
	level=Level.new();add_child(level)
	player=Actor.new();player.controlled=true;player.position=Vector2(560,539);add_child(player)
	badger=Actor.new();badger.character_id="badger";badger.position=Vector2(400,539);add_child(badger)
	monkey=Monkey.new();monkey.character_id="monkey";monkey.position=Vector2(220,539);add_child(monkey)
	rabbit=preload("res://scripts/rabbit_actor.gd").new();rabbit.character_id="rabbit";rabbit.position=Vector2(830,539);add_child(rabbit)
	delivered_basket=Sprite2D.new();delivered_basket.texture=load("res://assets/chapter-v12/basket.webp");delivered_basket.scale=Vector2.ONE*0.045;delivered_basket.position=Vector2(42,-40);delivered_basket.z_index=1;rabbit.add_child(delivered_basket)
	camera=preload("res://scripts/core/camera_rig.gd").new();camera.configure(Level.WIDTH);player.add_child(camera)
	tie=object_sprite("res://assets/chapter-v10/rope.webp",Vector2(1960,580),0.095);tie.position.y+=24
	basket=object_sprite("res://assets/chapter-v12/basket.webp",Vector2(2310,260),0.105)
	lever=object_sprite("res://assets/chapter-v10/rope.webp",Vector2(1740,320),0.09);lever.position.y+=26
	windscreen=object_sprite("res://assets/chapter-v12/windbreak.webp",Vector2(980,515),0.18);windscreen.z_index=-8
	flower_bed=preload("res://scripts/core/garden_flowers.gd").new();add_child(flower_bed)
	basket_vine=Sprite2D.new();basket_vine.texture=load("res://assets/chapter-v8/vine.webp");basket_vine.z_index=-6;add_child(basket_vine)
	var layer=CanvasLayer.new();add_child(layer);screen=Control.new();layer.add_child(screen)
	runner.load_data(JSON.parse_string(FileAccess.get_file_as_string("res://preproduction/story/garden-dialogue.json")));runner.completed.connect(dialogue_done)
	var loaded={"ok":true,"data":fixture()} if automated else saves.load_progress(save_path)
	if not loaded.ok or loaded.data.chapter_id!="B03":
		mode="error";freeze(true);message("Bahçe kaydı açılamadı","Ana menüye dönüp yeniden deneyebilirsin.",to_menu);return
	apply_data(loaded.data);spawn_saved();build_hud();resume_pending()
	if automated:run_test()
func fixture() -> Dictionary:
	var q=Quest.new()
	for e in [Quest.ACCEPTED]+Quest.LIGHTS+[Quest.JOINED,Quest.COMPLETE]+Quest.RIVER_EVENTS:q.apply(e)
	var d=saves.fresh();d.chapter_id="B03";d.geometry="garden-v12";d.checkpoint_id="b03.entry";d.quest_flags=q.flags;d.party_ids=q.party_ids();return d
func object_sprite(file: String, foot: Vector2, factor: float) -> Sprite2D:
	var sprite=Sprite2D.new();sprite.texture=load(file);sprite.scale=Vector2.ONE*factor;sprite.position=foot-Vector2(0,55);add_child(sprite);return sprite
func clear_screen():
	for c in screen.get_children():screen.remove_child(c);c.queue_free()
func freeze(value: bool):
	for a in [player,badger,monkey,rabbit]:a.frozen=value
func reset_input():
	axis=0;jump=false;action=false;router.reset();last_jump=Input.is_action_pressed("jump")
	player.input_axis=0;player.jump_request=false;player.jump_buffer=0;player.jump_held=false;player.velocity=Vector2.ZERO
func build_hud():
	clear_screen()
	UI.texture("res://assets/polish-v3/panel.webp",Rect2(28,18,425,120),screen)
	UI.label("03  /  PAPATYA BAHÇESİ",Rect2(57,43,350,25),16,screen,Color("ebc774"))
	quest=UI.label("",Rect2(57,74,375,60),22,screen)
	UI.texture("res://assets/polish-v3/panel.webp",Rect2(911,24,239,104),screen)
	counter=UI.label("",Rect2(945,48,185,60),20,screen)
	UI.button("Ⅱ",Rect2(1158,28,96,96),screen,pause_game)
	hint=UI.label("",Rect2(252,624,776,42),20,screen);hint.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_color_override("font_shadow_color",Color("102925"));hint.add_theme_constant_override("shadow_outline_size",5)
	var left=UI.button("‹",Rect2(28,593,96,96),screen,func():pass)
	var right=UI.button("›",Rect2(140,593,96,96),screen,func():pass)
	var use=UI.button("E",Rect2(1043,593,96,96),screen,func():pass)
	var up=UI.button("↑",Rect2(1154,583,106,106),screen,func():pass,true)
	for b in [left,right,use,up]:
		b.mouse_filter=Control.MOUSE_FILTER_IGNORE
		for key in ["normal","hover","pressed","focus"]:
			var skin=StyleBoxTexture.new();skin.texture=load("res://assets/polish-v3/jump-button.webp");skin.region_rect=Rect2(130,130,1000,1000)
			if b!=up:skin.modulate_color=Color(0.25,0.40,0.34)
			b.add_theme_stylebox_override(key,skin)
	control_display.bind([left,right,use,up])
	router.bind_controls(left.get_rect(),right.get_rect(),up.get_rect(),use.get_rect());update_hud()
func update_hud():
	if not is_instance_valid(quest):return
	quest.text="Pıtpıt ile konuş" if not state.has(Quest.GARDEN_ACCEPTED) else "Sepeti indir · Bağ ipini bul" if not state.has(Quest.GARDEN_SUPPLIED) else "Rüzgâr siperini sabitle" if not state.has(Quest.PROTECTED) else "Pıtpıt’ı yolculuğa çağır" if not state.has(Quest.RABBIT) else "Dördünüz birlikte ilerleyin"
	if state.has(Quest.TIE) and state.has(Quest.BASKET) and not state.has(Quest.GARDEN_SUPPLIED):quest.text="Sepeti Pıtpıt’a götür"
	if state.has(Quest.GARDEN_COMPLETE):quest.text="Bahçe artık güvende"
	counter.text="Bağ ipi  %s\nSepet  %s"%["✓" if state.has(Quest.TIE) else "—","✓" if state.has(Quest.BASKET) else "—"]
func snapshot(q=null) -> Dictionary:
	if q==null:q=state
	var d=data.duplicate(true);d.quest_flags=q.flags.duplicate();d.collectibles=q.collectibles.duplicate();d.party_ids=q.party_ids()
	if player.is_on_floor() and absf(player.position.y-540)<5:
		if player.position.x<1150:d.checkpoint_id="b03.hub" if player.position.x>700 else "b03.entry"
		elif player.position.x>3500 and q.has(Quest.PROTECTED):d.checkpoint_id="b03.exit"
	return d
func apply_data(d: Dictionary):
	data=d.duplicate(true);state.read(data)
	tie.visible=not state.has(Quest.TIE);basket.visible=not state.has(Quest.BASKET)
	delivered_basket.visible=state.has(Quest.PROTECTED)
	flower_bed.set_sheltered(state.has(Quest.PROTECTED))
	lever.modulate=Color(0.65,0.75,0.68) if state.has(Quest.RELEASED) else Color.WHITE
	if mode!="lowering":basket.position=Vector2(2310,545 if state.has(Quest.LOWERED) else 205)
	level.finish_build_visual();level.set_bridge(state.has(Quest.PROTECTED))
	for a in [badger,monkey,rabbit]:a.recruited=state.has(Quest.RABBIT);a.route_walk_only=true
	update_hud()
func spawn_saved():
	player.position=director.anchor(data.checkpoint_id)-Vector2(0,1);player.velocity=Vector2.ZERO
	if state.has(Quest.RABBIT):
		rabbit.position=player.position-Vector2(145,0);badger.position=player.position-Vector2(285,0);monkey.position=player.position-Vector2(425,0)
	else:badger.position=Vector2(400,539);monkey.position=Vector2(220,539);rabbit.position=Vector2(830,539)
	for a in [badger,monkey,rabbit]:a.velocity=Vector2.ZERO;a.route_moving=false
	reset_input();camera.reset_smoothing()
func persist(d: Dictionary, after: Callable=Callable()) -> bool:
	if not saves.valid(d):push_error("Invalid garden state");return false
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
	clear_screen();UI.texture("res://assets/polish-v3/panel.webp",Rect2(285,150,710,440),screen)
	UI.label(title,Rect2(372,235,540,60),32,screen)
	UI.label(body,Rect2(375,315,530,100),24,screen)
	UI.button("Devam",Rect2(490,459,300,66),screen,callback,true)
func dialogue(id: String):
	if mode!="play":return
	if not runner.begin(id,{"meet":not state.has(Quest.GARDEN_ACCEPTED),"ready":state.has(Quest.PROTECTED) and not state.has(Quest.RABBIT),"exit":state.has(Quest.RABBIT) and not state.has(Quest.GARDEN_COMPLETE)}):return
	mode="dialogue";reset_input();freeze(true);clear_screen()
	comic=Comic.new();screen.add_child(comic)
	comic.build("PAPATYA BAHÇESİ  /  DİKKATLİ ADIMLAR",advance,"Çatpat","Pıtpıt","res://assets/review-v2/catpat-idle-r2.webp","res://assets/chapter-v12/rabbit-idle.webp","res://assets/chapter-v12/garden.webp")
	comic.portrait_right.flip_h=true;comic.portrait_right.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	comic.portrait_right.position=Vector2(797,260);comic.portrait_right.size=Vector2(420,440)
	line_id="";refresh_line()
func refresh_line():
	if runner.active and line_id!=runner.current.id:line_id=runner.current.id;chars=0;active_line=comic.present(runner.current)
func advance():runner.advance();refresh_line()
func dialogue_done(id: String,_first: bool):
	event(id,func():
		mode="play";build_hud();freeze(false);reset_input()
		if id==Quest.GARDEN_COMPLETE:complete()
		elif id==Quest.RABBIT:begin_gather())
func start_build():
	if not state.has(Quest.TIE) or not state.has(Quest.BASKET) or state.has(Quest.PROTECTED):return
	event(Quest.GARDEN_SUPPLIED,func():mode="building";build_elapsed=0;freeze(true);reset_input();hint.text="Pıtpıt sepetini alıyor · Arkadaşların bahçe yolunu hazırlıyor…")
func finish_build():
	event(Quest.PROTECTED,func():mode="play";build_hud();freeze(false);reset_input();notice=3)
func pause_game():
	if mode not in ["play","building","lowering","gathering"]:return
	prior_mode=mode;mode="pause";freeze(true);reset_input();clear_screen()
	UI.texture("res://assets/polish-v3/panel.webp",Rect2(325,110,630,520),screen)
	UI.label("Küçük bir mola",Rect2(415,204,450,60),34,screen)
	UI.button("Devam et",Rect2(450,300,380,65),screen,resume,true)
	UI.button("Bahçeyi baştan oyna",Rect2(450,389,380,62),screen,confirm_restart)
	UI.button("Ana menü",Rect2(450,476,380,62),screen,save_menu)
func resume():
	mode=prior_mode;build_hud();freeze(mode in ["building","lowering"]);reset_input()
	if mode=="gathering":player.frozen=true
func confirm_restart():
	message("Bahçeyi baştan oynayalım mı?","Yalnız bahçe görevi sıfırlanır. Porsuk, Maymun ve önceki bölümler korunur.",restart)
	UI.button("Vazgeç",Rect2(490,540,300,48),screen,resume).grab_focus()
func restart():
	var q=state.copy()
	for id in Quest.GARDEN_EVENTS:q.flags.erase(id)
	var d=snapshot(q);d.checkpoint_id="b03.entry"
	persist(d,func():mode="play";spawn_saved();build_hud();freeze(false))
func save_menu():persist(snapshot(),to_menu)
func to_menu():get_tree().change_scene_to_file("res://scenes/polish_v3.tscn")
func chapter_panel():
	var backdrop=UI.texture("res://assets/polish-v3/panel.webp",Rect2(300,120,680,520),screen)
	var framed=AtlasTexture.new();framed.atlas=backdrop.texture;framed.region=Rect2(80,105,2010,520);backdrop.texture=framed
func complete():
	mode="complete";freeze(true);reset_input();clear_screen()
	chapter_panel()
	UI.label("Papatya Bahçesi tamamlandı",Rect2(350,175,580,60),32,screen)
	UI.label("Pıtpıt da aramızda! Dördümüz birlikte Rüzgârlı Yamaç'a ilerleyelim.",Rect2(350,255,580,100),27,screen)
	UI.button("Rüzgârlı Yamaç'a ilerle",Rect2(385,385,510,88),screen,go_summit,true)
	UI.button("Bahçede kal",Rect2(355,495,275,88),screen,func():mode="play";build_hud();freeze(false))
	UI.button("Ana menü",Rect2(650,495,275,88),screen,save_menu)
func go_summit():
	if not state.has(Quest.GARDEN_COMPLETE) or director.transitioning:return
	var previous=snapshot()
	if not saves.valid(previous) or previous.party_ids!=["badger","monkey","rabbit"]:return
	var prepared=director.prepare_transition("B04","b04.bank.0")
	if not prepared.ok:return
	var target=previous.duplicate(true);target.chapter_id="B04";target.geometry="shared-v16";target.checkpoint_id="b04.bank.0";target.summit=Save.Summit.fresh()
	if not saves.save(save_path,target):
		director.finish_transition(false,"B04");transition_error("Kaydedemedik. Bahçe ilerlemen korunuyor.");return
	get_tree().set_meta("journey_save_path",save_path)
	var error=transition_change.call(prepared.scene) if transition_change.is_valid() else get_tree().change_scene_to_packed(prepared.scene)
	if error!=OK:
		var restored=saves.save(save_path,previous)
		director.finish_transition(false,"B04")
		transition_error("Bahçe kaydına döndük. Yeniden deneyebilirsin." if restored else "Güvenli yamaç girişin kaydedildi. Yeniden deneyebilir veya ana menüden devam edebilirsin.")
	else:director.finish_transition(true,"B04")
func transition_error(body:String):
	mode="transition_error";freeze(true);reset_input();clear_screen();chapter_panel()
	UI.label("Yamaç yoluna geçemedik",Rect2(350,180,580,60),32,screen)
	UI.label(body,Rect2(350,275,580,120),26,screen)
	UI.button("Tekrar dene",Rect2(355,455,275,88),screen,go_summit,true)
	UI.button("Ana menü",Rect2(650,455,275,88),screen,to_menu)
func _process(delta):
	if not is_instance_valid(player):return
	backdrop.position.x=camera.get_screen_center_position().x-640-clampf(camera.get_screen_center_position().x-640,0,Level.WIDTH-1280)*0.15
	delivered_basket.position.x=-42 if rabbit.anim.flip_h else 42
	var rope_length=maxf(10,basket.position.y-62)
	basket_vine.position=Vector2(2310,rope_length/2);basket_vine.scale=Vector2(0.035,rope_length/basket_vine.texture.get_height());basket_vine.visible=not state.has(Quest.BASKET)
	if mode in ["play","building"]:
		wind_clock+=delta
		flower_bed.advance_wind(delta)
	windscreen.rotation=0.0 if state.has(Quest.PROTECTED) else -0.12+sin(wind_clock*2)*0.015
	runner.tick(delta)
	if mode=="dialogue":
		chars+=delta*34
		if chars>=runner.current.text.length():runner.revealed=true
		active_line.visible_characters=-1 if runner.revealed else int(chars)
		return
	if mode=="gathering":
		hint.text="Pıtpıt sepetini aldı · Arkadaşların yanına geliyor"
		if absf(rabbit.position.x-(player.position.x-145))<18 and absf(badger.position.x-(player.position.x-285))<18 and absf(monkey.position.x-(player.position.x-425))<18:
			mode="play";player.frozen=false;reset_input();update_hud()
		return
	if mode=="lowering":
		lower_elapsed+=delta;basket.position.y=lerpf(205,545,clampf(lower_elapsed/2.0,0,1))
		if lower_elapsed>=2.0:event(Quest.LOWERED,func():mode="play";build_hud();freeze(false);reset_input())
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
	if not state.has(Quest.GARDEN_ACCEPTED):
		hint.text="E · Pıtpıt ile konuş" if absf(player.position.x-rabbit.position.x)<145 else "Papatyaların yanındaki Pıtpıt’a ilerle"
		if use and absf(player.position.x-rabbit.position.x)<145 and player.is_on_floor():dialogue("garden_meet");return
	elif not state.has(Quest.PROTECTED):
		hint.text="Çiçeklere basmadan taşları ve dalları kullan"
		if not state.has(Quest.RELEASED) and near(Vector2(1740,320)):
			hint.text="E · Takılan sepetin ipini çöz"
			if use:event(Quest.RELEASED,begin_lowering);return
		if not state.has(Quest.TIE) and near(Vector2(1960,580)):
			hint.text="E · Siperin bağ ipini al"
			if use:event(Quest.TIE);return
		if state.has(Quest.LOWERED) and not state.has(Quest.BASKET) and near(Vector2(2310,600)):
			hint.text="E · İnen sepeti al"
			if use:event(Quest.BASKET);return
		if state.has(Quest.TIE) and state.has(Quest.BASKET):
			hint.text="Sepet ve bağ ipi hazır · Pıtpıt’a dön"
			if near(Vector2(1000,540),150):
				hint.text="E · Sepeti ver ve siperi sabitle"
				if use:start_build();return
	elif not state.has(Quest.RABBIT):
		hint.text="E · Pıtpıt’ı yolculuğa çağır" if near(Vector2(1000,540),150) else "Pıtpıt bahçe başında seni bekliyor"
		if use and near(Vector2(1000,540),150):dialogue("garden_join");return
	elif not state.has(Quest.GARDEN_COMPLETE) and player.position.x>3650:
		hint.text="Arkadaşlarınla çıkışta buluş"
		if party_at_exit():
			hint.text="E · Dördünüz birlikte yola devam edin"
			if use:dialogue("garden_exit");return
	elif state.has(Quest.GARDEN_COMPLETE) and player.position.x>3650:
		hint.text="E · Rüzgârlı Yamaç'a ilerle"
		if use:complete();return
	notice=maxf(0,notice-delta)
	if notice>0:hint.text="Çiçekler güvende · Ahşap yol açıldı!"
	save_clock+=delta
	if save_clock>2:save_clock=0;persist(snapshot())
func party_at_exit() -> bool:
	return state.has(Quest.RABBIT) and player.is_on_floor() and badger.is_on_floor() and monkey.is_on_floor() and rabbit.is_on_floor() and player.position.x>3650 and player.position.distance_to(rabbit.position)<240 and player.position.distance_to(badger.position)<390 and player.position.distance_to(monkey.position)<540
func _physics_process(_delta):
	if mode not in ["play","gathering"]:return
	player.position.x=clampf(player.position.x,500 if state.has(Quest.RABBIT) else 20,3970)
	if state.has(Quest.RABBIT):
		for pair in [[rabbit,player,145.0],[badger,rabbit,140.0],[monkey,badger,140.0]]:
			var actor=pair[0];var leader=pair[1]
			actor.route_target=Vector2(leader.position.x-float(pair[2]),540)
			actor.route_moving=absf(actor.route_target.x-actor.position.x)>10
		if absf(badger.velocity.x)<10:badger.anim.flip_h=player.anim.flip_h
		for a in [monkey,rabbit]:
			if absf(a.velocity.x)<10:a.anim.flip_h=not player.anim.flip_h
	for a in [player,badger,monkey,rabbit]:
		if a.position.y>790:
			if a==player:rescue_count+=1;a.position=Vector2(1000,539)
			else:follower_rescues+=1;a.position=Vector2(600 if a==badger else 440 if a==monkey else 280,539)
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
	if what==NOTIFICATION_APPLICATION_FOCUS_OUT and mode in ["play","building","lowering","gathering"]:pause_game()


func near(point: Vector2, radius=85.0) -> bool:
	return player.is_on_floor() and player.position.distance_to(point)<radius
func begin_lowering():
	mode="lowering";lower_elapsed=0;basket.position.y=205;freeze(true);reset_input();hint.text="Sepet usulca aşağı iniyor…"
func resume_pending():
	if state.has(Quest.RELEASED) and not state.has(Quest.LOWERED):begin_lowering()
	elif state.has(Quest.GARDEN_SUPPLIED) and not state.has(Quest.PROTECTED):start_build()
func check(ok: bool, title: String):
	print(("PASS V12: " if ok else "FAIL V12: ")+title)
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
	if "--v12-capture" not in OS.get_cmdline_user_args() and "--v13-capture" not in OS.get_cmdline_user_args():return
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://preproduction/qa/"+("v13" if "--v13-capture" in OS.get_cmdline_user_args() else "v12")+"/"+name+".webp")
func run_test():
	for i in 40:await get_tree().physics_frame
	check(state.has(Quest.RIVER_COMPLETE) and data.party_ids==["badger","monkey"],"B02 entry keeps two friends")
	check(not level.ready_bridge and level.bridge_body.collision_layer==0,"garden walkway closed")
	check(await walk_to(730),"walk to Pıtpıt")
	await use_action();check(mode=="dialogue","meet comic from proximity E")
	runner.revealed=true;await capture("meet-comic");test_finish_dialogue()
	check(state.has(Quest.GARDEN_ACCEPTED),"Pıtpıt help accepted")
	check(not event(Quest.BASKET) and not state.has(Quest.BASKET),"basket cannot be taken before lowering")
	await walk_to(1120);check(await hop_to(Vector2(1150,450)),"hop onto upper start")
	await walk_to(1200);check(await hop_to(Vector2(1420,360)),"upper second branch")
	await walk_to(1480);check(await hop_to(Vector2(1740,320)),"upper third branch")
	await use_action();check(mode=="lowering" and state.has(Quest.RELEASED) and not state.has(Quest.LOWERED),"upper rope releases basket")
	await get_tree().create_timer(0.4).timeout
	pause_game();var before=lower_elapsed;var before_y=basket.position.y
	await get_tree().create_timer(0.3).timeout
	check(lower_elapsed==before and basket.position.y==before_y,"pause freezes descending basket")
	resume()
	for i in 240:
		await get_tree().physics_frame
		if state.has(Quest.LOWERED):break
	check(state.has(Quest.LOWERED) and absf(basket.position.y-545)<2,"basket reaches lower route")
	await capture("basket-lowered")
	await walk_to(1645);check(await hop_to(Vector2(1470,360)),"return upper third")
	await walk_to(1380);check(await hop_to(Vector2(1170,450)),"return upper second")
	await walk_to(1040)
	for i in 60:await get_tree().physics_frame
	check(absf(player.position.y-540)<4,"return hub ground")
	await walk_to(1120);check(await hop_to(Vector2(1320,580)),"first garden stone")
	await walk_to(1380);check(await hop_to(Vector2(1620,640)),"second garden stone")
	await walk_to(1680);check(await hop_to(Vector2(1960,580)),"third garden stone")
	await use_action();check(state.has(Quest.TIE) and not tie.visible,"tie carried from lower stone")
	await walk_to(2030);check(await hop_to(Vector2(2310,600)),"reach lowered basket")
	await use_action();check(state.has(Quest.BASKET) and not basket.visible,"lowered basket carried")
	await capture("basket-collected")
	await walk_to(2220);check(await hop_to(Vector2(2010,580)),"return fourth stone")
	await walk_to(1890);check(await hop_to(Vector2(1660,640)),"return third stone")
	await walk_to(1560);check(await hop_to(Vector2(1370,580)),"return second stone")
	await walk_to(1250);check(await hop_to(Vector2(1120,450)),"return first stone via upper landing")
	await walk_to(1040)
	for i in 60:await get_tree().physics_frame
	check(rescue_count==0,"normal routes need no rescue")
	await walk_to(1000)
	for i in 60:await get_tree().physics_frame
	await capture("garden-exposed")
	await use_action()
	check(mode=="building" and state.has(Quest.GARDEN_SUPPLIED) and not state.has(Quest.PROTECTED),"delivery starts durable windscreen repair")
	await get_tree().create_timer(0.4).timeout
	_notification(NOTIFICATION_APPLICATION_FOCUS_OUT);before=build_elapsed
	await get_tree().create_timer(0.3).timeout
	check(mode=="pause" and build_elapsed==before and level.bridge_body.collision_layer==0,"focus loss freezes repair and keeps walkway closed")
	resume()
	for i in 260:
		await get_tree().physics_frame
		if state.has(Quest.PROTECTED):break
	check(state.has(Quest.PROTECTED) and level.ready_bridge and level.bridge_body.collision_layer==1,"secured windscreen enables safe walkway")
	for i in 120:await get_tree().physics_frame
	await capture("garden-protected")
	await use_action();test_finish_dialogue()
	check(state.has(Quest.RABBIT) and data.party_ids==["badger","monkey","rabbit"],"Pıtpıt joins three-companion party once")
	for i in 150:await get_tree().physics_frame
	print("V12 VIDEO READY")
	check(await walk_to(3760,1800),"walk across garden as four characters")
	for i in 180:await get_tree().physics_frame
	check(party_at_exit() and follower_rescues==0,"three physical followers reach exit without rescue")
	await capture("party-exit")
	check(await walk_to(3290),"party reverses safely")
	for i in 120:await get_tree().physics_frame
	check(absf(player.position.x-rabbit.position.x)>80 and absf(rabbit.position.x-badger.position.x)>80 and absf(badger.position.x-monkey.position.x)>80,"reverse has distinct four actor slots")
	await walk_to(3760)
	for i in 180:await get_tree().physics_frame
	check(not state.has(Quest.GARDEN_COMPLETE),"arrival alone does not finish garden")
	await use_action();test_finish_dialogue()
	check(state.has(Quest.GARDEN_COMPLETE) and mode=="complete","explicit exit comic completes garden")
	await capture("complete")
	var saved=snapshot();apply_data(saved);spawn_saved()
	check(state.has(Quest.GARDEN_COMPLETE) and level.ready_bridge and data.party_ids.size()==3,"completed garden reload keeps progress and all friends")
	restart();check(state.has(Quest.RIVER_COMPLETE) and not state.has(Quest.GARDEN_ACCEPTED) and data.party_ids==["badger","monkey"],"garden restart preserves B01 and B02 friends")
	print("V12 GARDEN SUITE FAILED" if test_failed else "V12 GARDEN SUITE PASSED")
	get_tree().quit(1 if test_failed else 0)

func begin_gather():
	mode="gathering";reset_input();freeze(false);player.frozen=true
