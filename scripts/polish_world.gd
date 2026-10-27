extends Node2D
var control_display=preload("res://scripts/core/control_display.gd").new()
const QuestState=preload("res://scripts/core/quest_state.gd")
const SaveService=preload("res://scripts/core/save_service.gd")
const LevelDirector=preload("res://scripts/core/level_director.gd")
var quest_state=QuestState.new()
var saves=SaveService.new()
var director=LevelDirector.new()
var load_issue=false
var load_notice=""
var save_status="Yolculuğun kaydediliyor"
var save_status_label: Label
var pending_snapshot={}
var pending_callback: Callable
var pending_mode="play"
var settings={}
var ending_seen=false
const Level=preload("res://scripts/core/lantern_level.gd")
const Rig=preload("res://scripts/core/camera_rig.gd")
const Actor = preload("res://scripts/polish_actor.gd")
const UI = preload("res://scripts/polish_ui.gd")
const Runner = preload("res://scripts/dialogue_runner.gd")
var level
var gathered=[false,false,false,false,false]
var test_failed=false
var rescue_count=0
var friend_rescues=0
var rescue_note=0.0
var mote_label: Label
var player
var friend
var camera: Camera2D
var layer: CanvasLayer
var screen: Control
var hud: Control
var bg: Node2D
var quest: Label
var hint: Label
var count_label: Label
var dialogue: Control
var runner=Runner.new()
var line_text: Label
var line_id=""
var type_chars=0.0
var mode="menu"
var elapsed=0.0
var lit=[false,false,false]
var lanterns: Array=[]
var joined=false
var met=false
var last_jump=false
var touch_axis=0.0
var touch_jump=false
var touch_points={}
var input_router=preload("res://scripts/core/input_router.gd").new()
var interact=false
var particles: Array=[]
var terrain: Texture2D
var bank: Texture2D
# Collision follows the same hand-measured moss surface used by the bank artwork.
const BANK_SURFACE = [Vector2(40,610),Vector2(150,475),Vector2(300,355),Vector2(400,290),Vector2(510,266),Vector2(750,260),Vector2(1000,267),Vector2(1250,265),Vector2(1500,260),Vector2(1620,280),Vector2(1730,340),Vector2(1860,460),Vector2(1990,610)]
var segments=[] # V4 banks retired; Level owns all terrain
var jump_steps=[]
var platform_art: Texture2D
var platform_source=Rect2(400,260,920,724) # Art moss baseline; world scale 0.28, unwarped texture regions.
var mood=0.0
var chapter_note: Label
var lantern_pulse=0.0
var completed=false
var save_clock=0.0
var party=preload("res://scripts/core/party_controller.gd").new()
var moving_platform
var exit_lantern: Sprite2D
var follow_trail: Array[Vector2]:
	get:return party.trail
var movement_clock=0.0
var save_path="user://festival_v3.json"
var recording=false
var automated=false
var recorded_started=false
var next_capture=false

func _ready():
	save_path=str(get_tree().get_meta("journey_save_path",save_path))
	process_physics_priority=-20
	for action in {"left":[KEY_A,KEY_LEFT],"right":[KEY_D,KEY_RIGHT],"jump":[KEY_SPACE,KEY_UP,KEY_W],"interact":[KEY_E],"pause":[KEY_ESCAPE]}:
		if not InputMap.has_action(action): InputMap.add_action(action)
		for key in {"left":[KEY_A,KEY_LEFT],"right":[KEY_D,KEY_RIGHT],"jump":[KEY_SPACE,KEY_UP,KEY_W],"interact":[KEY_E],"pause":[KEY_ESCAPE]}[action]:
			var ev=InputEventKey.new();ev.physical_keycode=key;InputMap.action_add_event(action,ev)
	terrain=load("res://assets/polish-v3/terrain.webp")
	bank=load("res://assets/polish-v3/bank.webp")
	layer=CanvasLayer.new();add_child(layer)
	screen=Control.new();layer.add_child(screen)
	runner.load_data(JSON.parse_string(FileAccess.get_file_as_string("res://preproduction/story/lantern-dialogue.json")))
	runner.completed.connect(_dialogue_done)
	recording="--v3-record" in OS.get_cmdline_user_args()
	automated=recording or "--v3-test" in OS.get_cmdline_user_args() or "--v3-capture" in OS.get_cmdline_user_args() or "--v3-route-test" in OS.get_cmdline_user_args() or "--v4-test" in OS.get_cmdline_user_args()
	automated=automated or "--v5-test" in OS.get_cmdline_user_args() or "--v5-capture" in OS.get_cmdline_user_args()
	automated=automated or "--v6-test" in OS.get_cmdline_user_args() or "--v6-capture" in OS.get_cmdline_user_args()
	automated=automated or "--v7-test" in OS.get_cmdline_user_args() or "--v7-capture" in OS.get_cmdline_user_args()
	automated=automated or "--v8-test" in OS.get_cmdline_user_args() or "--v8-capture" in OS.get_cmdline_user_args()
	automated=automated or "--v9-test" in OS.get_cmdline_user_args() or "--v9-capture" in OS.get_cmdline_user_args()
	show_menu()
	if "--v9-capture" in OS.get_cmdline_user_args(): capture_v9_sequence()
	elif "--v9-test" in OS.get_cmdline_user_args(): run_v9_test()
	if "--v8-test" in OS.get_cmdline_user_args(): run_v8_test()
	if "--v8-capture" in OS.get_cmdline_user_args(): capture_v8_sequence()
	if "--v7-test" in OS.get_cmdline_user_args(): run_v7_test()
	if "--v7-capture" in OS.get_cmdline_user_args(): capture_v7_sequence()
	if "--v6-test" in OS.get_cmdline_user_args(): run_v6_test()
	if "--v6-capture" in OS.get_cmdline_user_args(): capture_v6_sequence()
	if "--v5-test" in OS.get_cmdline_user_args(): run_v5_test()
	if "--v5-capture" in OS.get_cmdline_user_args(): capture_v5_sequence()
	if "--v3-capture" in OS.get_cmdline_user_args(): capture_sequence()
	if "--v3-test" in OS.get_cmdline_user_args(): run_test()
	if "--v3-route-test" in OS.get_cmdline_user_args(): run_route_test()
	if "--v4-test" in OS.get_cmdline_user_args(): run_v4_test()

func clear_screen():
	for c in screen.get_children():
		screen.remove_child(c);c.queue_free()

func show_menu():
	mode="menu"
	reset_controls()
	if is_instance_valid(player): player.frozen=true;friend.frozen=true
	clear_screen()
	UI.texture("res://assets/chapter-v5/menu.webp",Rect2(0,0,1280,720),screen)
	UI.label("BİRLİKTE GİDİLEN BİR YOLCULUK",Rect2(85,110,520,35),17,screen,Color("b6dfcf"))
	var title=UI.label("Çatpat",Rect2(78,140,590,145),120,screen)
	title.add_theme_color_override("font_shadow_color",Color("173d38"));title.add_theme_constant_override("shadow_offset_y",5)
	UI.label("FESTİVAL YOLU",Rect2(87,282,510,55),34,screen,Color("efc97b"))
	UI.label("Festival bugün! Davetimi de yanıma alayım.\nIşıklar ağaçların ötesinde görünüyor.\nPatikadan gidersem oraya ulaşabilirim.",Rect2(89,350,465,92),18,screen)
	UI.button("Yolculuğa dön" if (FileAccess.file_exists(save_path) or FileAccess.file_exists(save_path+".bak")) else "Yola çık",Rect2(84,452,338,72),screen,begin_game,true).grab_focus()
	UI.button("Nasıl oynanır?",Rect2(76,535,355,58),screen,show_help)
	UI.button("Ebeveyn özeti",Rect2(76,602,355,50),screen,show_parent_summary)
	UI.texture("res://assets/review-v2/catpat-idle-r2.webp",Rect2(834,337,300,322),screen)
	UI.label("PATİKA  ·  DERE  ·  BAHÇE  ·  YAMAÇ",Rect2(88,668,600,24),15,screen,Color("a9d3c4"))
	if (FileAccess.file_exists(save_path) or FileAccess.file_exists(save_path+".bak")):
		UI.button("Yeni yolculuk",Rect2(892,640,308,52),screen,confirm_restart)

func show_help():
	clear_screen()
	UI.texture("res://assets/chapter-v5/menu.webp",Rect2(0,0,1280,720),screen)
	UI.texture("res://assets/polish-v3/panel.webp",Rect2(550,110,650,480),screen)
	UI.label("Küçük bir yardım, büyük bir yolculuk",Rect2(610,205,530,90),28,screen)
	UI.label("A / D veya oklar: yürü\nBoşluk: zıpla · Basılı tut: daha yükseğe\nE: konuş veya görev nesnesini kullan\nEsc: mola\n\nDokunmatik ekranda alttaki düğmeleri kullan.",Rect2(610,302,520,225),22,screen)
	UI.button("Anladım",Rect2(742,562,255,57),screen,show_menu,true)

func summary_count(state, events:Array) -> int:
	var total=0
	for event in events:
		if state.has(event):total+=1
	return total

func summary_status(state, complete_event:String, started_events:Array, current_chapter:String, chapter:String) -> String:
	if state.has(complete_event):return "Tamamlandı"
	if current_chapter==chapter or summary_count(state,started_events)>0:return "Devam ediyor"
	return "Henüz başlanmadı"

func show_parent_summary():
	mode="parent_summary"
	clear_screen()
	UI.texture("res://assets/chapter-v5/menu.webp",Rect2(0,0,1280,720),screen)
	UI.texture("res://assets/polish-v3/panel.webp",Rect2(150,46,980,626),screen)
	UI.label("Ebeveyn özeti",Rect2(245,87,790,55),39,screen,Color("efc97b"))
	UI.label("Bu cihazdaki kaydedilmiş oyun ilerlemesi",Rect2(248,143,780,32),20,screen,Color("b6dfcf"))
	var loaded=saves.load_progress(save_path)
	if not loaded.ok:
		UI.label("Kayıt okunamadı. Dosyanı değiştirmedim; ana menüden yeniden deneyebilirsin.",Rect2(245,245,790,100),23,screen)
		UI.button("Ana menüye dön",Rect2(460,560,360,62),screen,show_menu,true)
		return
	var data=loaded.data
	var state=QuestState.new()
	state.read(data)
	var lights=summary_count(state,QuestState.LIGHTS)
	var river=summary_count(state,[QuestState.PLANK,QuestState.ROPE,QuestState.SUPPLIED,QuestState.READY,QuestState.MONKEY])
	var garden=summary_count(state,[QuestState.TIE,QuestState.RELEASED,QuestState.LOWERED,QuestState.BASKET,QuestState.GARDEN_SUPPLIED,QuestState.PROTECTED,QuestState.RABBIT])
	var festival=summary_count(state,[QuestState.FESTIVAL_LIGHT,QuestState.FESTIVAL_FLAGS,QuestState.FESTIVAL_FLOWERS])
	var b01=summary_status(state,QuestState.COMPLETE,[QuestState.ACCEPTED]+QuestState.LIGHTS,data.chapter_id,"B01")
	var b02=summary_status(state,QuestState.RIVER_COMPLETE,QuestState.RIVER_EVENTS,data.chapter_id,"B02")
	var b03=summary_status(state,QuestState.GARDEN_COMPLETE,QuestState.GARDEN_EVENTS,data.chapter_id,"B03")
	var b04=summary_status(state,QuestState.SUMMIT_COMPLETE,[],data.chapter_id,"B04")
	var b05=summary_status(state,QuestState.FESTIVAL_COMPLETE,QuestState.FESTIVAL_EVENTS,data.chapter_id,"B05")
	var rows=[
		"B01 Fenerli Patika — %s · %d/3 fener · %d/5 ışık izi"%[b01,lights,data.collectibles.size()],
		"B02 Dostluk Deresi — %s · %d/5 köprü ve ekip adımı"%[b02,river],
		"B03 Papatya Bahçesi — %s · %d/7 bahçe adımı"%[b03,garden],
		"B04 Rüzgârlı Yamaç — %s · fener, halat ve yön işareti rotası"%[b04],
		"B05 Festival Alanı — %s · %d/3 hazırlık görevi"%[b05,festival]
	]
	var rows_y=220
	if loaded.get("new",false):
		UI.label("Henüz kaydedilmiş bir yolculuk yok.",Rect2(248,190,780,34),21,screen)
		rows_y=232
	UI.label("\n".join(rows),Rect2(245,rows_y,790,260),20,screen)
	UI.label("Bu, görev ilerlemesi özetidir; beceri gelişimini veya gerçek yaşam davranışını ölçmez.",Rect2(245,496,790,48),18,screen,Color("b6dfcf"))
	UI.label("Deneme sayısı, ipucu kullanımı ve beceri değişimi kaydedilmediğinden bunlarla ilgili çıkarım yapılmaz.",Rect2(245,540,790,48),17,screen,Color("b6dfcf"))
	UI.button("Ana menüye dön",Rect2(460,602,360,54),screen,show_menu,true)

func confirm_restart():
	clear_screen()
	UI.texture("res://assets/chapter-v5/menu.webp",Rect2(0,0,1280,720),screen)
	UI.texture("res://assets/polish-v3/panel.webp",Rect2(290,165,700,380),screen)
	UI.label("Yeni yolculuğa başlansın mı?",Rect2(377,259,520,70),30,screen)
	UI.label("Bütün bölümlerdeki ilerleme ve yol arkadaşların sıfırlanır. Baştan başlayalım mı?",Rect2(379,345,510,60),22,screen)
	UI.button("Vazgeç",Rect2(369,437,240,62),screen,show_menu).grab_focus()
	UI.button("Yeniden başla",Rect2(642,437,270,62),screen,restart_game)

func restart_game():
	if not is_instance_valid(player):build_world()
	commit_snapshot(saves.fresh(),func():
		load_issue=false;load_notice="";reset_controls();rescue_count=0;friend_rescues=0
		runner.active=false;follow_trail.clear()
		spawn_saved(saves.fresh());camera.reset_smoothing();begin_game())

func begin_game():
	if not automated:
		var saved=saves.load_progress(save_path)
		if saved.ok and saved.data.chapter_id in ["B02","B03","B04","B05"]:
			var chapter_scene={"B02":"res://scenes/river.tscn","B03":"res://scenes/garden.tscn","B04":"res://scenes/summit.tscn","B05":"res://scenes/festival.tscn"}[saved.data.chapter_id]
			get_tree().set_meta("journey_save_path",save_path)
			if get_tree().change_scene_to_file(chapter_scene)!=OK:show_message("Bölümü açamadık","Kaydın korunuyor. Yeniden deneyebilirsin.",begin_game)
			return
	if not is_instance_valid(player): build_world()
	if load_issue:show_load_error();return
	if not load_notice.is_empty():
		var message=load_notice;load_notice=""
		show_message("Yolculuğun hazır",message,begin_game);return
	reset_controls()
	mode="play";clear_screen();build_hud()
	player.frozen=false;friend.frozen=false
	if completed: show_completion()
	elif not met: open_dialogue("badger_meet")

func build_world():
	bg=Node2D.new();bg.z_index=-30;add_child(bg)
	var backdrop=Sprite2D.new();backdrop.texture=load("res://assets/chapter-v6/panorama.webp");backdrop.centered=false
	backdrop.scale=Vector2.ONE*720.0/backdrop.texture.get_height();bg.add_child(backdrop)
	backdrop.modulate=Color(0.55,0.68,0.73)
	level=Level.new();add_child(level)
	moving_platform=preload("res://scripts/core/moving_platform.gd").new();level.add_child(moving_platform)
	player=Actor.new();player.controlled=true;player.position=Vector2(190,580);player.checkpoint=player.position;add_child(player)
	friend=Actor.new();friend.debug_route=automated;friend.character_id="badger";friend.position=Vector2(430,580);friend.checkpoint=friend.position;friend.following_distance=155;add_child(friend);friend.anim.flip_h=false
	party.configure(player,friend,level,moving_platform)
	camera=Rig.new();camera.configure(Level.WIDTH);player.add_child(camera)
	for p in Level.LANTERNS:
		var s=Sprite2D.new();s.texture=load("res://assets/polish-v3/lantern.webp");s.centered=false;s.scale=Vector2.ONE*0.15;s.position=p-Vector2(95,185);s.z_index=-1;s.modulate=Color(0.30,0.39,0.47);add_child(s)
		lanterns.append({"node":s,"pos":p,"glow":Vector2(p.x+19,p.y-98)})
	exit_lantern=Sprite2D.new();exit_lantern.texture=load("res://assets/polish-v3/lantern.webp");exit_lantern.centered=false
	exit_lantern.position=Vector2(3650,570)-Vector2(95,185);exit_lantern.scale=Vector2.ONE*0.15;exit_lantern.z_index=-1
	exit_lantern.modulate=Color(0.30,0.39,0.47);add_child(exit_lantern)
	for i in range(55): particles.append(Vector2(85+i*79,220+sin(i*2.13)*165))
	if not automated:load_saved_journey()
	camera.reset_smoothing()
	queue_redraw()

func build_hud():
	hud=Control.new();screen.add_child(hud)
	UI.texture("res://assets/polish-v3/panel.webp",Rect2(28,18,370,119),hud)
	UI.label("01  /  FENERLİ PATİKA",Rect2(57,43,300,25),16,hud,Color("ebc774"))
	quest=UI.label("Üç feneri yak",Rect2(57,72,310,38),23,hud)
	UI.texture("res://assets/polish-v3/panel.webp",Rect2(916,24,235,98),hud)
	count_label=UI.label("",Rect2(955,50,190,35),23,hud)
	mote_label=UI.label("",Rect2(955,85,220,30),17,hud,Color("e4c578"))
	UI.button("Ⅱ",Rect2(1158,28,96,96),hud,pause_game)
	hint=UI.label("",Rect2(252,669,776,42),20,hud);hint.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_color_override("font_shadow_color",Color("102925"));hint.add_theme_constant_override("shadow_outline_size",5)
	chapter_note=UI.label("",Rect2(420,30,470,65),20,hud,Color("ffdc8c"));chapter_note.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	var left_control=UI.button("‹",Rect2(28,593,96,96),hud,func(): pass)
	var right_control=UI.button("›",Rect2(140,593,96,96),hud,func(): pass)
	var action_control=UI.button("E",Rect2(1043,593,96,96),hud,func(): interact=true)
	var jump_control=UI.button("↑",Rect2(1154,583,106,106),hud,func(): pass,true)
	for state in ["normal","hover","pressed","focus"]:
		var circular=StyleBoxTexture.new();circular.texture=load("res://assets/polish-v3/jump-button.webp");circular.region_rect=Rect2(130,130,1000,1000)
		jump_control.add_theme_stylebox_override(state,circular)
	control_display.bind([left_control,right_control,action_control,jump_control])
	input_router.bind_controls(left_control.get_rect(),right_control.get_rect(),jump_control.get_rect(),action_control.get_rect())
	# Raw per-pointer ownership supports holding direction and jump together.
	for c in hud.get_children():
		if c is Button and c.position.y>580:
			c.mouse_filter=Control.MOUSE_FILTER_IGNORE
			if c!=jump_control:
				for state in ["normal","hover","pressed","focus"]:
					var round_skin=StyleBoxTexture.new();round_skin.texture=load("res://assets/polish-v3/jump-button.webp");round_skin.region_rect=Rect2(130,130,1000,1000);round_skin.modulate_color=Color(0.25,0.40,0.34)
					c.add_theme_stylebox_override(state,round_skin)
			c.add_theme_font_size_override("font_size",30)
	update_hud()

func update_hud():
	if not is_instance_valid(quest):return
	var total=lit.count(true)
	mote_label.text="Işık izleri  %d / 5"%gathered.count(true)
	count_label.text="Fenerler  %d / 3"%total
	quest.text="Patika aydınlandı" if completed else "Porsuk’la çıkışı aydınlat" if joined else "Geçitlerden Porsuk’a dön" if total==3 else "İlk feneri yak" if not lit[0] else "Üst daldaki feneri yak" if not lit[1] else "Hareketli daldaki fener"

func open_dialogue(id: String):
	if mode!="play":return
	if not runner.begin(id,{"badger_not_recruited":not joined,"all_three_lanterns_lit":lit.count(true)==3,"badger_at_exit":joined and not completed}):return
	reset_controls()
	mode="dialogue";player.frozen=true;friend.frozen=true;touch_points.clear();touch_axis=0;touch_jump=false
	dialogue=preload("res://scripts/core/comic_panel.gd").new();screen.add_child(dialogue)
	var heading="BİR IŞIK ARAYIŞI" if id=="badger_meet" else "ÇIKIŞI BİRLİKTE AYDINLAT" if id=="badger_exit" else "ARTIK BİRLİKTE"
	dialogue.build("FENERLİ PATİKA  /  "+heading,advance_dialogue)
	line_id="";refresh_line()

func refresh_line():
	if not runner.active:return
	if line_id!=runner.current.id:
		line_id=runner.current.id;type_chars=0
		line_text=dialogue.present(runner.current)

func advance_dialogue():
	runner.advance();refresh_line()

func _dialogue_done(event_id: String, _first: bool):
	var next=quest_state.copy()
	if not next.apply(event_id):
		runner.active=false
		mode="play"
		reset_controls()
		if is_instance_valid(dialogue):dialogue.queue_free()
		if is_instance_valid(player):player.frozen=false
		if is_instance_valid(friend):friend.frozen=false
		clear_screen()
		show_message("Görev ilerlemesi kaydedilemedi","Son güvenli kaydın korunuyor. Bu konuşma görevi tamamlayamadı; yeniden deneyebilirsin.",Callable(self,"begin_game"))
		return
	commit_snapshot(snapshot_for(next),func():
		if is_instance_valid(dialogue):dialogue.queue_free()
		mode="play";reset_controls();player.frozen=false;friend.frozen=false
		clear_screen();build_hud()
		if event_id==QuestState.COMPLETE:reveal_exit())

func recruit():
	var next=quest_state.copy()
	if next.apply(QuestState.JOINED):commit_snapshot(snapshot_for(next),func():update_hud())

func apply_quest(data: Dictionary):
	quest_state.read(data);settings=data.settings.duplicate(true);ending_seen=data.ending_seen
	met=quest_state.has(QuestState.ACCEPTED);joined=quest_state.has(QuestState.JOINED);completed=quest_state.has(QuestState.COMPLETE)
	for i in 3:lit[i]=quest_state.has(QuestState.LIGHTS[i])
	for i in 5:gathered[i]="b01.mote.%d"%i in quest_state.collectibles
	runner.completed_events.clear()
	for event in quest_state.flags:runner.completed_events[event]=true
	if not is_instance_valid(player):return
	var was_recruited=friend.recruited
	friend.recruited=joined;friend.leader=player if joined else null
	if joined and not was_recruited:
		follow_trail.clear();follow_trail.append(friend.position);follow_trail.append(player.position)
	if not joined:friend.route_moving=false;friend.route_air_direction=0
	level.set_bridges(lit.count(true)==3)
	exit_lantern.modulate=Color(1.3,1.13,0.85) if completed else Color(0.30,0.39,0.47)
	for i in 3:lanterns[i].node.modulate=Color(1.3,1.13,0.85) if lit[i] else Color(0.30,0.39,0.47)

func pause_game():
	if mode!="play":return
	reset_controls()
	mode="pause";player.frozen=true;friend.frozen=true;touch_points.clear();touch_axis=0;touch_jump=false
	var box=Control.new();box.name="Pause";screen.add_child(box)
	UI.texture("res://assets/polish-v3/panel.webp",Rect2(350,115,580,510),box)
	UI.label("Küçük bir mola",Rect2(432,207,435,56),35,box)
	UI.button("Devam et",Rect2(452,313,375,64),box,func():box.queue_free();reset_controls();mode="play";player.frozen=false;friend.frozen=false,true)
	UI.button("Yolculuk defteri",Rect2(452,399,375,60),box,show_journal)
	UI.button("Ana menü",Rect2(452,483,375,57),box,func():save_progress(show_menu))
	save_progress()

func bank_surface(seg: Array) -> PackedVector2Array:
	var points=PackedVector2Array()
	var factor=float(seg[2])/1100.0
	for point in BANK_SURFACE: points.append(Vector2(seg[0]-474*factor,seg[1]-260*factor)+point*factor)
	return points

func ground_y(x: float) -> float:
	return level.ground_y(x) if is_instance_valid(level) else 580.0

func reset_controls():
	input_router.reset()
	touch_points.clear();touch_axis=0;touch_jump=false;interact=false;last_jump=Input.is_action_pressed("jump")
	if is_instance_valid(player):
		player.input_axis=0;player.jump_request=false;player.jump_held=false;player.jump_buffer=0;player.velocity=Vector2.ZERO
	if is_instance_valid(friend):friend.velocity=Vector2.ZERO

func snapshot_for(state) -> Dictionary:
	var data=saves.fresh()
	data.quest_flags=state.flags.duplicate();data.collectibles=state.collectibles.duplicate()
	data.party_ids=state.party_ids()
	data.checkpoint_id=director.checkpoint_for(player.checkpoint.x) if is_instance_valid(player) else "b01.island.0"
	data.settings=settings.duplicate(true);data.ending_seen=ending_seen
	return data

func progress_data() -> Dictionary:return snapshot_for(quest_state)

func spawn_saved(data: Dictionary):
	moving_platform.reset_phase();party.reset()
	var anchor=director.anchor(data.checkpoint_id)
	player.position=anchor-Vector2(0,1);player.checkpoint=anchor;player.velocity=Vector2.ZERO
	var friend_anchor=level.safe_anchor(anchor.x-100) if joined else Vector2(430,580)
	friend.position=friend_anchor-Vector2(0,1);friend.checkpoint=friend_anchor;friend.velocity=Vector2.ZERO
	friend.route_air_direction=0;friend.route_moving=false
	follow_trail.clear();follow_trail.append(friend.position);follow_trail.append(player.position)
	reset_controls();camera.reset_smoothing()

func restore_progress(data: Dictionary):
	if not saves.valid(data):
		var decoded=saves.decode(JSON.stringify(data))
		if not decoded.ok:return
		data=decoded.data
	apply_quest(data);spawn_saved(data)

func load_saved_journey():
	var result=saves.load_progress(save_path)
	load_issue=not result.ok
	if load_issue:return
	restore_progress(result.data)
	if result.get("recovered",false):load_notice="Son sağlam kaydına döndük. Fenerlerini ve arkadaşını bu kayıttan geri getirdik."
	elif result.get("migrated",false):load_notice="Patika kaydın yenilendi. Yakılan fenerler ve arkadaşın korunuyor; güvenli bir duraktan devam edeceksin."

func commit_snapshot(data: Dictionary, after: Callable=Callable()) -> bool:
	if not saves.valid(data):return false
	if not automated and not saves.save(save_path,data):
		pending_snapshot=data.duplicate(true);pending_callback=after;pending_mode=mode
		show_save_error();return false
	apply_quest(data);save_status="Yolculuğun kaydedildi"
	if is_instance_valid(save_status_label):save_status_label.text=save_status
	if after.is_valid():after.call()
	return true

func save_progress(after: Callable=Callable()) -> bool:
	if not is_instance_valid(player) or load_issue:return false
	return commit_snapshot(progress_data(),after)

func show_message(title: String, body: String, proceed: Callable):
	mode="notice";reset_controls();player.frozen=true;friend.frozen=true;clear_screen()
	UI.texture("res://assets/chapter-v5/menu.webp",Rect2(0,0,1280,720),screen)
	UI.texture("res://assets/polish-v3/panel.webp",Rect2(260,125,760,500),screen)
	UI.label(title,Rect2(358,215,570,55),32,screen,Color("efc97b"))
	UI.label(body,Rect2(358,295,568,150),25,screen)
	UI.button("Devam et",Rect2(483,489,314,66),screen,proceed,true).grab_focus()

func show_save_error():
	show_message("Yolculuk kaydedilemedi","Son güvenli kaydın korunuyor. Bu adımı kaydetmek için yeniden dene.",retry_save)
	mode="save_error"
	var button=screen.get_child(screen.get_child_count()-1)
	button.text="Yeniden dene"

func retry_save():
	var data=pending_snapshot.duplicate(true);var after=pending_callback;var previous=pending_mode
	if not automated and not saves.save(save_path,data):return
	pending_snapshot.clear();pending_callback=Callable();apply_quest(data)
	mode=previous;save_status="Yolculuğun kaydedildi"
	clear_screen();build_hud();player.frozen=mode!="play";friend.frozen=player.frozen
	if after.is_valid():after.call()
	elif previous=="pause":mode="play";pause_game()

func show_load_error():
	show_message("Kaydını açamadık","Yolculuk kaydın okunamıyor. Yeniden deneyebilir veya eski dosyalarını koruyarak yeni bir yolculuğa başlayabilirsin.",func():load_saved_journey();begin_game())
	mode="load_error"
	var button=screen.get_child(screen.get_child_count()-1);button.text="Yeniden dene";button.position=Vector2(342,489);button.size=Vector2(280,66)
	UI.button("Yeni yolculuk",Rect2(658,489,280,66),screen,func():
		show_message("Baştan başlayalım mı?","Okunamayan eski kayıtlar korunacak. Oyun ilk fenerden başlayacak.",func():
			if saves.preserve_damaged(save_path):restart_game()
			else:show_load_error())
		UI.button("Vazgeç",Rect2(483,565,314,56),screen,show_load_error).grab_focus())

func show_journal():
	mode="journal";reset_controls();player.frozen=true;friend.frozen=true;clear_screen()
	UI.texture("res://assets/chapter-v5/menu.webp",Rect2(0,0,1280,720),screen)
	UI.texture("res://assets/polish-v3/panel.webp",Rect2(195,72,890,590),screen)
	UI.label("Yolculuk defteri",Rect2(305,167,670,60),38,screen,Color("efc97b"))
	UI.label("01  /  FENERLİ PATİKA",Rect2(308,234,610,35),19,screen,Color("a9d3c4"))
	var objective="Porsuk ile patikada keşfe devam et" if completed else "Porsuk ile çıkışa ilerle" if joined else "Porsuk’a geri dön" if lit.count(true)==3 else "Sönmüş üç feneri yak"
	UI.label(objective,Rect2(308,286,670,62),28,screen)
	UI.label("Yanan fenerler     %d / 3\nIşık izleri              %d / 5\nYol arkadaşın       %s"%[lit.count(true),gathered.count(true),"Porsuk" if joined else "Porsuk seni bekliyor"],Rect2(308,364,660,128),25,screen)
	save_status_label=UI.label(save_status,Rect2(308,511,660,32),18,screen,Color("a9d3c4"))
	UI.button("Patikaya dön",Rect2(480,568,320,63),screen,func():mode="play";clear_screen();build_hud();reset_controls();player.frozen=false;friend.frozen=false,true).grab_focus()

func reveal_exit():
	mode="exit_reveal";player.frozen=true;friend.frozen=true
	friend.anim.flip_h=false;player.anim.flip_h=false
	quest.text="Porsuk çıkışı aydınlattı";hint.text="Şimdi birlikte dere yoluna!"
	queue_redraw()
	await get_tree().create_timer(1.8).timeout
	if mode=="exit_reveal":show_completion()

func show_completion():
	if mode=="complete":return
	if not completed:
		var next=quest_state.copy()
		if next.apply(QuestState.COMPLETE):commit_snapshot(snapshot_for(next),show_completion)
		return
	reset_controls()
	mode="complete";player.frozen=true;friend.frozen=true;clear_screen()
	var shade=ColorRect.new();shade.color=Color(0.02,0.08,0.08,0.80);shade.size=Vector2(1280,720);screen.add_child(shade)
	UI.texture("res://assets/polish-v3/panel.webp",Rect2(288,125,704,470),screen)
	UI.label("FENERLİ PATİKA TAMAMLANDI",Rect2(372,212,550,45),27,screen,Color("efc97b"))
	UI.label("Porsuk çıkışı aydınlattı. Dere yolu göründü!",Rect2(377,275,520,80),29,screen)
	UI.label("Birbirinize yardım ederek patikayı geçtiniz. Sıradaki durak: Dostluk Deresi.",Rect2(378,365,505,65),22,screen)
	UI.button("Dostluk Deresi",Rect2(365,466,267,62),screen,go_river,true)
	UI.button("Patikada dolaş",Rect2(652,466,261,62),screen,func():mode="play";clear_screen();build_hud();player.frozen=false;friend.frozen=false)
	UI.button("Ana menü",Rect2(503,540,270,50),screen,show_menu)

func _physics_process(delta):
	if is_instance_valid(moving_platform):
		moving_platform.enabled=mode=="play"
		var p=moving_platform.position+Vector2(20,0)
		lanterns[2].pos=p;lanterns[2].node.position=p-Vector2(95,185);lanterns[2].glow=p+Vector2(19,-98)
	if mode!="play" or not is_instance_valid(player):return
	if joined:party.update()
	for actor in [player,friend]:
		if actor.is_on_floor() and not moving_platform.is_riding(actor):actor.checkpoint=level.safe_anchor(actor.position.x)
		if actor.position.y>820:
			if automated:print("V6 FALL ","player" if actor==player else "friend"," at ",actor.position," anchor ",actor.checkpoint)
			actor.position=actor.checkpoint-Vector2(0,2);actor.velocity=Vector2.ZERO
			actor.jump_request=false;actor.jump_buffer=0
			if actor==player:rescue_count+=1;rescue_note=2.5
			else:friend_rescues+=1
			if joined:party.reset()
	rescue_note=maxf(0,rescue_note-delta)
	for i in Level.MOTES.size():
		if not gathered[i] and player.position.distance_to(Level.MOTES[i]+Vector2(0,65))<48:
			var next=quest_state.copy();next.collect(i)
			if not commit_snapshot(snapshot_for(next),update_hud):return
	save_clock+=delta
	if save_clock>2:save_clock=0;save_progress()

func _process(delta):
	elapsed+=delta
	if recording and mode=="menu" and elapsed>2 and not recorded_started:
		recorded_started=true;begin_game()
	runner.tick(delta)
	if mode=="dialogue":
		type_chars+=delta*34
		if type_chars>=runner.current.text.length():runner.revealed=true
		line_text.visible_characters=-1 if runner.revealed else int(type_chars)
		if recording and fmod(elapsed,1.7)<delta:runner.revealed=true;runner.input_cooldown=0;advance_dialogue()
	if not is_instance_valid(player):return
	bg.position.x=camera.get_screen_center_position().x-640-clampf(camera.get_screen_center_position().x-640,0,Level.WIDTH-1280)*0.15
	mood=move_toward(mood,float(lit.count(true))/3.0,delta*0.35)
	for tree_layer in bg.get_children():tree_layer.modulate=Color(0.55,0.68,0.73).lerp(Color(0.88,0.97,0.89),mood)
	lantern_pulse=maxf(0,lantern_pulse-delta)
	if is_instance_valid(chapter_note):chapter_note.text="Patika aydınlanıyor…" if lantern_pulse>0 else "Porsuk yolculuğa katıldı" if joined and player.position.x<850 else ""
	if mode=="play":camera.desired_axis=player.input_axis
	if mode!="play":return
	
	player.input_axis=clampf(Input.get_axis("left","right")+touch_axis,-1,1)
	player.jump_held=Input.is_action_pressed("jump") or touch_jump
	if recording:
		player.input_axis=1 if player.position.x<2650 else 0
		player.jump_held=player.is_on_wall() or (int(elapsed*2)%3==0)
		interact=true
	if player.jump_held and not last_jump:player.jump_request=true
	last_jump=player.jump_held
	var action=Input.is_action_just_pressed("interact") or interact;interact=false
	hint.text=""
	if not joined:
		if lit.count(true)==3:hint.text="Ahşap geçitler açıldı · Soldaki Porsuk’a dön"
		elif player.position.x<960:hint.text="Boşluk · Açıklığın üzerinden zıpla"
		elif player.position.x>1800 and player.position.x<2150 and not lit[1]:hint.text="Üst dala zıpla · İkinci fener orada"
		elif player.position.x>2550 and player.position.x<3000 and not lit[2]:hint.text="Hareketli dala bin · Son fener geçitleri açar"
	if rescue_note>0:hint.text="Bir daha dene; fenerlerin güvende."
	for i in range(3):
		if not lit[i] and can_light(i):
			hint.text="E · Feneri yak ve geçitleri aç" if lit.count(true)==2 else "E · Feneri yak"
			if action:light_lantern(i)
			if mode!="play":return
	if lit.count(true)==3 and not joined and player.is_on_floor() and absf(player.position.x-friend.position.x)<150:
		hint.text="E · Porsuk ile konuş"
		if action:open_dialogue("badger_helped");return
	if joined and not completed and player.position.x>3720:
		hint.text="Porsuk’la çıkış fenerine yaklaş"
		if player.position.distance_to(friend.position)<240 and absf(player.position.x-3860)<120 and player.is_on_floor() and friend.is_on_floor():
			hint.text="E · Porsuk’la çıkışı aydınlat"
			if action:open_dialogue("badger_exit");return
	if player.position.x<10:player.position.x=10
	if player.position.x>4170:player.position.x=4170
	queue_redraw()
	if recording and elapsed>22:get_tree().quit()

func can_light(i: int) -> bool:
	if not player.is_on_floor():return false
	if absf(player.position.x-lanterns[i].pos.x)>95:return false
	if i==1:return absf(player.position.y-Level.PERCH.position.y)<4
	if i==2:return moving_platform.is_riding(player)
	return absf(player.position.y-lanterns[i].pos.y)<8

func light_lantern(i: int):
	if lit[i]:return
	var next=quest_state.copy()
	if next.apply(QuestState.LIGHTS[i]):commit_snapshot(snapshot_for(next),func():lantern_pulse=3.0;update_hud())

func _input(event):
	if control_display.observe(event):input_router.reset();touch_axis=0;touch_jump=false;interact=false
	if event is InputEventKey and event.pressed and not event.echo and event.keycode==KEY_ESCAPE and mode=="journal":
		mode="play";clear_screen();build_hud();reset_controls();player.frozen=false;friend.frozen=false
		get_viewport().set_input_as_handled();return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode==KEY_ESCAPE and mode=="play":
		pause_game();get_viewport().set_input_as_handled();return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode==KEY_ESCAPE and mode=="pause":
		var box=screen.get_node_or_null("Pause")
		if box:box.queue_free()
		reset_controls();mode="play";player.frozen=false;friend.frozen=false
		get_viewport().set_input_as_handled();return
	if mode=="dialogue" and event is InputEventKey and event.pressed and not event.echo and event.keycode in [KEY_SPACE,KEY_ENTER,KEY_E]:advance_dialogue();return
	if mode!="play":return
	if control_display.accepts(event) and input_router.consume(event):
		touch_axis=input_router.axis;touch_jump=input_router.jump_held
		interact=interact or input_router.interact_pressed

func _notification(what):
	if what==NOTIFICATION_APPLICATION_FOCUS_OUT and mode=="play":pause_game()

func _draw():
	if not is_instance_valid(player):return
	for i in Level.MOTES.size():
		if not gathered[i]:
			var p=Level.MOTES[i]+Vector2(0,sin(elapsed*2.0+i)*5)
			for radius in [20,13,7]:draw_circle(p,radius,Color(1,0.80,0.28,0.12 if radius>7 else 0.95))
	for actor in [player,friend]:
		if actor.is_on_floor():
			draw_set_transform(actor.position+Vector2(0,3),0,Vector2(1,0.17))
			draw_circle(Vector2.ZERO,29,Color(0.01,0.04,0.035,0.30))
			draw_set_transform(Vector2.ZERO,0,Vector2.ONE)
	for i in range(particles.size()):
		var p=particles[i]+Vector2(sin(elapsed*0.45+i)*14,cos(elapsed*0.6+i)*10)
		draw_circle(p,2.0,Color(1,0.81,0.36,0.25+0.23*sin(elapsed+i)))
	if completed:
		for radius in range(12,170,12):draw_circle(Vector2(3669,472),radius,Color(1,0.73,0.25,0.03))
	for i in range(lanterns.size()):
		if lit[i]:
			for radius in range(12,160,12):draw_circle(lanterns[i].glow,radius,Color(1,0.73,0.25,0.025))

func capture_sequence():
	await get_tree().create_timer(0.5).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://preproduction/polish-v3/menu-engine.png")
	met=true;begin_game()
	await get_tree().create_timer(1).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://preproduction/polish-v3/game-engine.png")
	open_dialogue("badger_meet")
	await get_tree().create_timer(2).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://preproduction/polish-v3/dialogue-engine.png")
	get_tree().quit()

func run_test():
	begin_game();test_dialogue_finish()
	await get_tree().physics_frame
	for i in range(40):await get_tree().physics_frame
	assert(player.is_on_floor())
	var x=player.position.x
	touch_axis=1
	for i in range(35):await get_tree().physics_frame
	assert(player.position.x>x+50)
	touch_jump=true
	for i in range(12):await get_tree().physics_frame
	assert(player.position.y<550)
	touch_axis=0;touch_jump=false
	for i in range(3):light_lantern(i)
	assert(lit.count(true)==3)
	recruit();assert(friend.recruited and joined)
	pause_game();assert(player.frozen and mode=="pause")
	print("PASS V3: grounded movement, jump, lantern progress, companion recruitment, pause")
	get_tree().quit()

func run_route_test():
	met=true;begin_game()
	await get_tree().create_timer(0.4).timeout
	for goal in [Vector2(770,515),Vector2(1190,480),Vector2(1875,480),Vector2(430,580)]:
		var reached=false
		for frame in range(850):
			touch_axis=signf(goal.x-player.position.x) if absf(goal.x-player.position.x)>20 else 0.0
			touch_jump=(frame%70)<40
			interact=true
			await get_tree().physics_frame
			if mode=="dialogue":
				while runner.active:
					runner.input_cooldown=0;runner.revealed=true;advance_dialogue()
			if absf(goal.x-player.position.x)<35 and absf(goal.y-player.position.y)<65:
				reached=true;break
		assert(reached,"Route goal unreachable: "+str(goal)+" actual "+str(player.position))
		print("REACHED ",goal," lanterns=",lit)
	assert(lit.count(true)==3,"All lanterns should be reachable")
	if not joined:open_dialogue("badger_helped")
	while runner.active:
		runner.input_cooldown=0;runner.revealed=true;advance_dialogue()
	assert(joined and friend.recruited)
	print("PASS V3 ROUTE: three lanterns reached by physics inputs, return route, dialogue, recruitment")
	get_tree().quit()

func check_v4(ok: bool, message: String):
	if not ok:
		test_failed=true
		push_error("FAIL: "+message)
		return
	print("PASS V4: ",message)

func test_dialogue_finish():
	while runner.active:
		runner.input_cooldown=0;runner.revealed=true;advance_dialogue()

func run_v4_test():
	show_help();var help_count=screen.get_child_count();show_help()
	check_v4(screen.get_child_count()==help_count,"help screen does not stack")
	show_menu();begin_game();test_dialogue_finish()
	await get_tree().create_timer(0.3).timeout
	check_v4(met and mode=="play","opening dialogue accepts quest")
	open_dialogue("missing_scene")
	check_v4(mode=="play","invalid dialogue cannot trap controls")
	var last_pos=player.position
	# Walk the surface in both directions, without jumping: catches invisible walls.
	for goal in [770.0,1190.0,2040.0,430.0]:
		var reached=false
		for frame in range(1200):
			touch_axis=signf(goal-player.position.x) if absf(goal-player.position.x)>15 else 0.0
			interact=true
			await get_tree().physics_frame
			if mode=="dialogue":test_dialogue_finish()
			if player.is_on_floor():check_surface_contact(player)
			if absf(goal-player.position.x)<25:reached=true;break
		check_v4(reached,"walkable slope route to "+str(goal))
		if goal==1190.0:await capture_v4("slope")
	touch_axis=0
	check_v4(lit.count(true)==3,"all lanterns activated through proximity input")
	if not joined:open_dialogue("badger_helped");test_dialogue_finish()
	check_v4(joined,"companion recruitment")
	# Reverse on a slope and include an actual held/released jump before the exit.
	var jump_start_y=player.position.y
	touch_jump=true
	for frame in range(12):await get_tree().physics_frame
	check_v4(player.position.y<jump_start_y-40,"jump rises above terrain")
	touch_jump=false
	for frame in range(75):await get_tree().physics_frame
	check_v4(player.is_on_floor(),"released jump lands on terrain")
	for goal in [1250.0,720.0]:
		var reached=false
		for frame in range(600):
			touch_axis=signf(goal-player.position.x) if absf(goal-player.position.x)>15 else 0.0
			await get_tree().physics_frame
			if absf(goal-player.position.x)<25:reached=true;break
		check_v4(reached,"companion direction-change route "+str(goal))
	touch_axis=0
	for frame in range(140):await get_tree().physics_frame
	check_v4(friend.position.distance_to(player.position)<230,"companion catches up after reversal")
	# Real route following to the exit. No direct position injection or teleport.
	var max_step=0.0
	last_pos=friend.position
	for frame in range(2200):
		touch_axis=1.0 if player.position.x<2910 else 0.0
		await get_tree().physics_frame
		max_step=maxf(max_step,friend.position.distance_to(last_pos));last_pos=friend.position
		if mode=="complete":break
	check_v4(mode=="complete" and completed,"exit waits for both characters and completes")
	await capture_v4("completion")
	check_v4(max_step<35,"companion route has no teleport")
	# Completion is a stable terminal state, and free roam does not retrigger it.
	mode="play";clear_screen();build_hud();player.frozen=false;friend.frozen=false
	for frame in range(30):await get_tree().physics_frame
	check_v4(mode=="play","post-completion free roam does not pause-loop")
	var old_path=save_path
	save_path="user://v4-regression-only.json";automated=false;save_progress();automated=true
	check_v4((FileAccess.file_exists(save_path) or FileAccess.file_exists(save_path+".bak")),"atomic checkpoint file created")
	var saved=JSON.parse_string(FileAccess.get_file_as_string(save_path))
	check_v4(saved is Dictionary and saved.version==4,"checkpoint reopened from disk")
	DirAccess.remove_absolute(save_path);save_path=old_path
	player.position=Vector2(190,300);friend.position=Vector2(430,300)
	restore_progress(saved)
	check_v4(absf(player.position.y-ground_y(player.position.x))<2,"save restores on terrain")
	check_v4(friend.position.distance_to(player.position)<250,"save restores companion nearby")
	check_v4(lanterns[0].node.modulate.r>1,"save restores lantern appearance")
	pause_game()
	var ev=InputEventKey.new();ev.keycode=KEY_ESCAPE;ev.pressed=true;_input(ev)
	check_v4(mode=="play","Escape resumes pause")
	var left=InputEventScreenTouch.new();left.index=0;left.position=Vector2(160,650);left.pressed=true;_input(left)
	var jump=InputEventScreenTouch.new();jump.index=1;jump.position=Vector2(1200,640);jump.pressed=true;_input(jump)
	check_v4(touch_axis==1 and touch_jump,"two fingers can hold direction and jump")
	jump.pressed=false;_input(jump)
	check_v4(touch_axis==1 and not touch_jump,"jump finger release preserves direction")
	left.pressed=false;_input(left)
	check_v4(touch_axis==0 and not touch_jump,"all fingers released stops movement")
	touch_axis=1;touch_jump=true;player.jump_request=true;show_menu()
	check_v4(touch_axis==0 and not touch_jump and not player.jump_request,"menu clears held input")
	restart_game();test_dialogue_finish()
	check_v4(not joined and not completed and lit.count(true)==0 and player.position.x==190,"restart clears quest and positions")
	print("V4 REGRESSION SUITE COMPLETE")
	get_tree().quit()

func check_surface_contact(actor):
	# Capsule feet can sit slightly above the centre-line on a slope. Large errors
	# indicate collision that no longer follows the textured bank.
	var error=absf(actor.position.y-ground_y(actor.position.x))
	if error>24:check_v4(false,"surface contact error "+str(error)+" at "+str(actor.position))

func capture_v4(label_name: String):
	if not "--v4-capture" in OS.get_cmdline_user_args():return
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://preproduction/qa/v4-"+label_name+".webp")

func capture_v5_sequence():
	await get_tree().create_timer(0.5).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://preproduction/qa/v5/menu.png")
	met=true;begin_game()
	player.position=Vector2(1450,ground_y(1450)-1);camera.reset_smoothing()
	await get_tree().create_timer(1).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://preproduction/qa/v5/game.png")
	open_dialogue("badger_meet")
	runner.revealed=true;runner.input_cooldown=0;advance_dialogue();runner.revealed=true
	await get_tree().create_timer(0.3).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://preproduction/qa/v5/comic.png")
	get_tree().quit()

func run_v5_test():
	begin_game();test_dialogue_finish()
	await get_tree().create_timer(0.3).timeout
	check_v4(met and mode=="play","V5 opening comic accepts quest")
	var max_step=0.0
	var jumped=false
	for goal in [770.0,1190.0,1875.0,430.0,2910.0]:
		var reached=false
		var previous=friend.position
		for frame in range(1500):
			touch_axis=signf(goal-player.position.x) if absf(goal-player.position.x)>14 else 0.0
			touch_jump=player.position.x>1390 and player.position.x<2040 and (frame%65)<36
			interact=true
			await get_tree().physics_frame
			if mode=="dialogue":test_dialogue_finish()
			if not player.is_on_floor() and player.position.x>1500:jumped=true
			if joined:max_step=maxf(max_step,friend.position.distance_to(previous))
			previous=friend.position
			if mode=="complete":reached=true;break
			if absf(goal-player.position.x)<25 and (goal!=1875.0 or lit[2]):reached=true;break
		check_v4(reached,"V5 route by input to "+str(goal))
		if goal==430.0:
			check_v4(lit.count(true)==3,"V5 all lanterns reached and lit")
			if not joined:open_dialogue("badger_helped");test_dialogue_finish()
			check_v4(joined,"V5 comic recruits companion")
	touch_axis=0;touch_jump=false
	for frame in range(900):
		await get_tree().physics_frame
		if mode=="complete":break
	check_v4(jumped,"V5 raised route uses real jumping")
	check_v4(completed and mode=="complete","V5 both characters finish")
	check_v4(max_step<35,"V5 follower does not teleport")
	var data=progress_data();restore_progress(data)
	check_v4(completed and joined and lit.count(true)==3,"V5 state roundtrip preserves quest")
	mode="play";clear_screen();build_hud();player.frozen=false;friend.frozen=false
	pause_game();check_v4(mode=="pause" and player.frozen,"V5 pause freezes actors")
	var ev=InputEventKey.new();ev.keycode=KEY_ESCAPE;ev.pressed=true;_input(ev)
	check_v4(mode=="play","V5 Escape resumes")
	restart_game();test_dialogue_finish()
	check_v4(not joined and not completed and lit.count(true)==0,"V5 restart clears quest")
	print("V5 ROUTE COMPLETE")
	get_tree().quit()

func capture_v6_sequence():
	await get_tree().create_timer(0.4).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://preproduction/qa/v6/menu.png")
	show_help()
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://preproduction/qa/v6/help.png")
	met=true;begin_game()
	for x in [300.0,1260.0,2070.0,3200.0]:
		player.position=level.safe_anchor(x)-Vector2(0,1);player.velocity=Vector2.ZERO
		camera.reset_smoothing()
		await get_tree().create_timer(0.4).timeout
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://preproduction/qa/v6/route-%d.png"%int(x))
	get_tree().quit()

func drive_v6(goal: float, activate=true) -> bool:
	var hold=0
	for frame in range(2400):
		var dx=goal-player.position.x
		touch_axis=signf(dx) if absf(dx)>12 else 0.0
		var surface=level.surface_index(player.position.x)
		if player.is_on_floor() and surface>=0 and touch_axis!=0:
			var rect=Level.PERCH if absf(player.position.y-Level.PERCH.position.y)<3 else Level.SURFACES[surface]
			var distance=rect.end.x-player.position.x if touch_axis>0 else player.position.x-rect.position.x
			if distance<58 and absf(dx)>distance+30:hold=37
		touch_jump=hold>0;hold=maxi(hold-1,0);interact=activate
		await get_tree().physics_frame
		if mode=="dialogue":test_dialogue_finish()
		if absf(goal-player.position.x)<22:return true
	return false

func run_v6_test():
	begin_game();test_dialogue_finish()
	await get_tree().create_timer(0.3).timeout
	check_v4(bg.get_child_count()==1,"V6 single panorama, no repeated backdrop")
	for i in range(Level.SURFACES.size()-1):check_v4(Level.SURFACES[i].end.x<Level.SURFACES[i+1].position.x,"V6 terrain islands do not overlap %d"%i)
	# Walking alone must fall and return to a safe anchor, rather than bypass the jumps.
	touch_axis=1
	for frame in range(250):
		await get_tree().physics_frame
		if rescue_count>0:break
	check_v4(rescue_count==1 and player.position.x<540,"V6 no walking-only bypass, safe fall recovery")
	restart_game();test_dialogue_finish()
	for goal in [800.0,1190.0,2000.0,2800.0,430.0]:
		var reached=await drive_v6(goal)
		check_v4(reached,"V6 input route to "+str(goal))
		if goal==1190.0:
			touch_axis=0;touch_jump=false
			for frame in range(70):await get_tree().physics_frame
			touch_jump=true
			for frame in range(38):await get_tree().physics_frame
			touch_jump=false
			for frame in range(60):await get_tree().physics_frame
			check_v4(player.is_on_floor() and absf(player.position.y-Level.PERCH.position.y)<3,"V6 optional upper perch reached with jump")
			check_v4(gathered[1],"V6 upper exploration light collected")
	check_v4(lit.count(true)==3,"V6 all lanterns reached through inputs")
	touch_axis=0;touch_jump=false
	for frame in range(120):
		interact=true
		await get_tree().physics_frame
		if mode=="dialogue":test_dialogue_finish()
		if joined:break
	check_v4(joined,"V6 friend joins through proximity input after return")
	check_v4(await drive_v6(1190),"V6 party reaches first clearing again")
	touch_axis=0;touch_jump=false
	for frame in range(150):await get_tree().physics_frame
	check_v4(await drive_v6(430),"V6 party reverses across gaps")
	touch_axis=0;touch_jump=false
	for frame in range(200):await get_tree().physics_frame
	check_v4(friend.position.distance_to(player.position)<260,"V6 companion catches up after reversal")
	check_v4(await drive_v6(3970),"V6 player reaches exit over all gaps")
	touch_axis=0;touch_jump=false
	for frame in range(1500):
		await get_tree().physics_frame
		if completed:break
	print("V6 positions ",player.position," friend ",friend.position," rescues ",rescue_count,"/",friend_rescues," trail ",follow_trail.size())
	check_v4(completed,"V6 companion crosses gaps and completes together")
	check_v4(rescue_count==0 and friend_rescues==0,"V6 successful route needs no rescue teleport")
	var saved=progress_data()
	var old_path=save_path;save_path="user://v6-regression.json";automated=false;save_progress();automated=true
	var reread=saves.load_progress(save_path).data;DirAccess.remove_absolute(save_path);save_path=old_path
	check_v4(reread is Dictionary and reread.schema_version==7,"V6 checkpoint written and reopened")
	restore_progress(reread)
	check_v4(completed and joined and gathered[1],"V6 restore preserves quest and exploration")
	var old_data={"version":4,"met":true,"lit":[true,true,true],"joined":true,"completed":false,"x":1000};restore_progress(old_data)
	check_v4(level.surface_index(player.position.x)>=0,"V6 old checkpoint in gap migrates to safe island")
	check_v4(friend.position.distance_to(player.position)<260,"V6 restored party stays on nearby safe island")
	mode="play";clear_screen();build_hud();player.frozen=false;friend.frozen=false
	var move_touch=InputEventScreenTouch.new();move_touch.index=0;move_touch.position=Vector2(165,650);move_touch.pressed=true;_input(move_touch)
	var jump_touch=InputEventScreenTouch.new();jump_touch.index=1;jump_touch.position=Vector2(1200,640);jump_touch.pressed=true;_input(jump_touch)
	check_v4(touch_axis==1 and touch_jump,"V6 input router holds two controls")
	jump_touch.pressed=false;_input(jump_touch)
	check_v4(touch_axis==1 and not touch_jump,"V6 one finger release keeps movement")
	_notification(NOTIFICATION_APPLICATION_FOCUS_OUT)
	check_v4(mode=="pause" and input_router.owners.is_empty() and touch_axis==0,"V6 focus loss pauses and releases ownership")
	show_menu();show_help();check_v4(mode=="menu","V6 help remains within menu state")
	print("V6 ROUTE SUITE FAILED" if test_failed else "V6 ROUTE SUITE PASSED")
	get_tree().quit(1 if test_failed else 0)

func run_v7_test():
	begin_game();test_dialogue_finish()
	await get_tree().create_timer(0.2).timeout
	var old_path=save_path;save_path="user://v7-world-regression.json"
	for suffix in ["",".bak",".pending"]:DirAccess.remove_absolute(save_path+suffix)
	automated=false;save_progress()
	var old_flags=quest_state.flags.duplicate();var old_colour=lanterns[0].node.modulate
	saves.fault="write";light_lantern(0)
	check_v4(mode=="save_error" and not lit[0] and quest_state.flags==old_flags and lanterns[0].node.modulate==old_colour,"V7 failed event changes neither quest nor world")
	check_v4(player.frozen and friend.frozen,"V7 failed save freezes controls safely")
	saves.fault="";retry_save()
	check_v4(mode=="play" and lit[0] and saves.load_progress(save_path).data.quest_flags.count("light.A")==1,"V7 retry commits event once and resumes")
	light_lantern(0)
	check_v4(quest_state.flags.count("light.A")==1,"V7 repeated interaction does not duplicate light")
	light_lantern(1);light_lantern(2)
	open_dialogue("badger_helped");saves.fault="rename";test_dialogue_finish()
	check_v4(mode=="save_error" and not joined and not friend.recruited,"V7 dialogue result waits for persistent commit")
	saves.fault="";retry_save()
	check_v4(joined and friend.recruited and mode=="play" and runner.completed_events.has(QuestState.JOINED),"V7 dialogue retry joins exactly once")
	player.checkpoint=Vector2(1190,490);save_progress()
	var data=saves.load_progress(save_path).data
	player.velocity=Vector2(200,300);touch_jump=true;restore_progress(data)
	check_v4(player.checkpoint==Vector2(1190,490) and player.velocity==Vector2.ZERO and not touch_jump,"V7 restore uses named spawn and clears held input")
	pause_game();show_journal()
	check_v4(mode=="journal" and player.frozen,"V7 journal pauses traversal")
	var damaged=save_path+".damaged-test";saves.write_text(damaged,"broken");saves.write_text(damaged+".bak","broken backup")
	save_path=damaged;load_saved_journey();begin_game()
	check_v4(mode=="load_error" and load_issue,"V7 unreadable saves show explicit recovery screen")
	check_v4(FileAccess.get_file_as_string(damaged)=="broken","V7 recovery screen preserves original bytes")
	for file in [damaged,damaged+".bak","user://v7-world-regression.json","user://v7-world-regression.json.bak","user://v7-world-regression.json.pending"]:DirAccess.remove_absolute(file)
	save_path=old_path;automated=true
	print("V7 WORLD SUITE FAILED" if test_failed else "V7 WORLD SUITE PASSED")
	get_tree().quit(1 if test_failed else 0)

func capture_v7_sequence():
	await get_tree().create_timer(0.5).timeout
	get_viewport().get_texture().get_image().save_png("res://preproduction/qa/v7/menu.png")
	confirm_restart();await get_tree().create_timer(0.3).timeout
	get_viewport().get_texture().get_image().save_png("res://preproduction/qa/v7/restart-confirm.png")
	begin_game();test_dialogue_finish()
	light_lantern(0);light_lantern(1)
	show_journal();await get_tree().create_timer(0.4).timeout
	get_viewport().get_texture().get_image().save_png("res://preproduction/qa/v7/journal.png")
	begin_game();pause_game();await get_tree().create_timer(0.3).timeout
	get_viewport().get_texture().get_image().save_png("res://preproduction/qa/v7/pause.png")
	pending_snapshot=progress_data();show_save_error();await get_tree().create_timer(0.3).timeout
	get_viewport().get_texture().get_image().save_png("res://preproduction/qa/v7/save-error.png")
	show_load_error();await get_tree().create_timer(0.3).timeout
	get_viewport().get_texture().get_image().save_png("res://preproduction/qa/v7/load-error.png")
	load_issue=false;begin_game();open_dialogue("badger_meet");runner.revealed=true
	await get_tree().create_timer(0.3).timeout
	get_viewport().get_texture().get_image().save_png("res://preproduction/qa/v7/dialogue.png")
	get_tree().quit()

func v8_walk_to(goal: float, limit=600) -> bool:
	for frame in limit:
		touch_axis=signf(goal-player.position.x) if absf(goal-player.position.x)>14 else 0.0;touch_jump=false
		await get_tree().physics_frame
		if absf(goal-player.position.x)<18 and player.is_on_floor():touch_axis=0;return true
	touch_axis=0;return false

func v8_board(limit=750, side=45.0) -> bool:
	for frame in limit:
		var dx=moving_platform.position.x+side-player.position.x
		touch_axis=signf(dx) if absf(dx)>10 else 0.0
		touch_jump=(frame%80)<45
		await get_tree().physics_frame
		if moving_platform.is_riding(player):touch_axis=0;touch_jump=false;return true
	touch_axis=0;touch_jump=false;return false

func v8_fixture():
	begin_game();test_dialogue_finish()
	for i in 3:light_lantern(i)
	recruit()
	var next=quest_state.copy();next.apply(QuestState.COMPLETE);commit_snapshot(snapshot_for(next))
	mode="play";clear_screen();build_hud();player.frozen=false;friend.frozen=false
	player.position=Vector2(3600,569);player.checkpoint=Vector2(3600,570)
	friend.position=Vector2(3490,569);friend.checkpoint=Vector2(3490,570);party.reset()

func run_v8_test():
	v8_fixture()
	for frame in 60:await get_tree().physics_frame
	check_v4(player.is_on_floor() and friend.is_on_floor(),"V8 fixed safe bank fixture")
	check_v4(await v8_board(),"V8 player boards from below by movement and jump")
	var joined_on_carrier=false
	for frame in 600:
		await get_tree().physics_frame
		if moving_platform.is_riding(friend):joined_on_carrier=true;break
	check_v4(joined_on_carrier,"V8 companion boards with shared jump physics")
	print("V8 boarding positions ",player.position," / ",friend.position," carrier ",moving_platform.position," state ",party.state)
	check_v4(not gathered[4],"V8 high light cannot be collected by ground boarding jump")
	var offset=player.position.x-moving_platform.position.x
	var friend_offset=friend.position.x-moving_platform.position.x
	var travel=moving_platform.travelled
	var every_frame_carried=true;var separate=true
	for frame in 510:
		await get_tree().physics_frame
		if not moving_platform.is_riding(player) or not moving_platform.is_riding(friend):every_frame_carried=false
		if absf(player.position.x-friend.position.x)<38:separate=false
	check_v4(every_frame_carried and moving_platform.travelled-travel>300,"V8 both passengers ride through turnarounds")
	check_v4(absf(player.position.x-moving_platform.position.x-offset)<4 and absf(friend.position.x-moving_platform.position.x-friend_offset)<18,"V8 carry has no drift or double velocity")
	check_v4(separate,"V8 passenger bodies remain separated")
	# Walk across the occupied deck: companion yields via the safe bank, no passing through.
	for side in [-48.0,48.0]:
		for frame in 100:
			var dx=moving_platform.position.x+side-player.position.x
			touch_axis=signf(dx) if absf(dx)>7 else 0.0
			await get_tree().physics_frame
			if absf(dx)<7:break
		touch_axis=0
		for frame in 600:
			await get_tree().physics_frame
			if moving_platform.is_riding(friend) and absf(friend.position.x-player.position.x)>45:break
		check_v4(moving_platform.is_riding(player) and moving_platform.is_riding(friend) and absf(friend.position.x-player.position.x)>45,"V8 deck side change settles with separate riders "+str(side))
	check_v4(party.yield_count>0,"V8 companion gives way through safe bank")
	for frame in 480:
		await get_tree().physics_frame
		if absf(player.position.x-3740)<18:break
	touch_jump=true
	for frame in 40:await get_tree().physics_frame
	touch_jump=false
	for frame in 70:await get_tree().physics_frame
	check_v4(gathered[4],"V8 optional high light collected from carrier jump")
	check_v4(moving_platform.is_riding(player) and moving_platform.is_riding(friend),"V8 companion waits while leader jumps for light")
	var fixed_checkpoint=player.checkpoint
	check_v4(fixed_checkpoint.y==570,"V8 riding never writes moving checkpoint")
	pause_game();await get_tree().physics_frame
	var paused=moving_platform.position
	for frame in 90:await get_tree().physics_frame
	check_v4(moving_platform.position==paused and player.frozen,"V8 pause freezes platform and actors")
	var escape=InputEventKey.new();escape.keycode=KEY_ESCAPE;escape.pressed=true;_input(escape)
	for frame in 60:await get_tree().physics_frame
	check_v4(mode=="play" and moving_platform.is_riding(player),"V8 resume preserves rider contact")
	for context in ["dialogue","menu","journal","save_error","complete"]:
		match context:
			"dialogue":open_dialogue("badger_helped")
			"menu":show_menu()
			"journal":show_journal()
			"save_error":pending_snapshot=progress_data();show_save_error()
			"complete":show_completion()
		await get_tree().physics_frame
		var stopped=moving_platform.position
		for frame in 30:await get_tree().physics_frame
		check_v4(mode==context and moving_platform.position==stopped,"V8 carrier freezes in "+context)
		if context=="dialogue":test_dialogue_finish()
	mode="play";clear_screen();build_hud();player.frozen=false;friend.frozen=false;reset_controls()
	check_v4(await v8_walk_to(3500),"V8 player disembarks left onto safe bank")
	for frame in 180:await get_tree().physics_frame
	check_v4(not moving_platform.is_riding(friend) and friend.is_on_floor() and absf(player.position.x-friend.position.x)<240,"V8 friend exits left and resumes follow")
	check_v4(await v8_board(),"V8 reboard at later moving phase")
	for frame in 600:
		await get_tree().physics_frame
		if moving_platform.is_riding(friend):break
	check_v4(moving_platform.is_riding(friend),"V8 companion reboards without stale trail loop")
	check_v4(await v8_walk_to(4000),"V8 player disembarks right")
	for frame in 180:await get_tree().physics_frame
	check_v4(friend.is_on_floor() and not moving_platform.is_riding(friend) and absf(player.position.x-friend.position.x)<240,"V8 friend exits right")
	check_v4(rescue_count==0 and friend_rescues==0,"V8 no rescue or teleport during carrier route")
	check_v4(await v8_board(),"V8 carrier accessible from right")
	var snapshot=progress_data();restore_progress(snapshot)
	for frame in 45:await get_tree().physics_frame
	check_v4(player.is_on_floor() and absf(player.position.y-570)<2 and not moving_platform.is_riding(player),"V8 load restores fixed bank rather than moving phase")
	check_v4(not touch_jump and input_router.owners.is_empty(),"V8 load releases transient input")
	print("V8 PLATFORM SUITE FAILED" if test_failed else "V8 PLATFORM SUITE PASSED")
	get_tree().quit(1 if test_failed else 0)

func capture_v8_sequence():
	v8_fixture()
	for frame in 60:await get_tree().physics_frame
	await v8_board()
	for frame in 600:
		await get_tree().physics_frame
		if moving_platform.is_riding(friend):break
	for frame in 30:await get_tree().physics_frame
	get_viewport().get_texture().get_image().save_png("res://preproduction/qa/v8/together.png")
	print("V8 VIDEO READY")
	for frame in 510:await get_tree().physics_frame
	get_viewport().get_texture().get_image().save_png("res://preproduction/qa/v8/turnaround.png")
	pause_game();await get_tree().create_timer(0.2).timeout
	get_viewport().get_texture().get_image().save_png("res://preproduction/qa/v8/pause.png")
	get_tree().quit()


func v9_capture(name: String):
	if "--v9-capture" not in OS.get_cmdline_user_args():return
	if name not in ["upper-lantern","exit-comic","complete"]:return
	await RenderingServer.frame_post_draw
	var frame=get_viewport().get_texture().get_image()
	print("VISUAL_CAPTURE:B01-"+name+":"+Marshalls.raw_to_base64(frame.save_webp_to_buffer(true,0.82)))
	if name == "upper-lantern":
		var old_size = get_root().size
		var old_touch = control_display.touch_mode
		get_root().size = Vector2i(666, 374)
		control_display.touch_mode = true
		control_display.refresh()
		await process_frame
		await RenderingServer.frame_post_draw
		var mobile_frame = get_viewport().get_texture().get_image()
		var safe_area = Rect2(Vector2.ZERO, Vector2(get_root().size))
		var controls_fit = control_display.buttons.all(func(button): return is_instance_valid(button) and button.visible and safe_area.encloses(button.get_global_rect()))
		check_v4(not mobile_frame.is_empty(), "B01 touch viewport rendered at 666x374")
		check_v4(controls_fit, "B01 touch controls fit fully inside 666x374")
		print("VISUAL_CAPTURE:B01-touch-small:" + Marshalls.raw_to_base64(mobile_frame.save_webp_to_buffer(true, 0.82)))
		get_root().size = old_size
		control_display.touch_mode = old_touch
		control_display.refresh()
		await process_frame

func capture_v9_sequence():
	run_v9_test()

func run_v9_test():
	begin_game();test_dialogue_finish()
	for frame in 30:await get_tree().physics_frame
	check_v4(not level.bridges_open,"V9 bridges closed at start")
	check_v4(await drive_v6(1190),"V9 input route to ground lantern")
	touch_axis=0;touch_jump=false
	for frame in 65:interact=true;await get_tree().physics_frame
	check_v4(lit[0],"V9 first lantern activated on ground")
	check_v4(await drive_v6(2000,false),"V9 input route to upper lantern clearing")
	await v8_walk_to(2120)
	for frame in 60:await get_tree().physics_frame
	await v8_walk_to(2000)
	touch_axis=0;touch_jump=false
	for frame in 65:interact=true;await get_tree().physics_frame
	check_v4(not lit[1] and not can_light(1),"V9 upper lantern cannot activate from ground")
	touch_jump=true
	for frame in 38:await get_tree().physics_frame
	touch_jump=false
	for frame in 60:interact=true;await get_tree().physics_frame
	check_v4(lit[1] and absf(player.position.y-400)<4,"V9 upper lantern reached by jump")
	await v9_capture("upper-lantern")
	check_v4(not level.bridges_open,"V9 two lanterns do not open bridges")
	check_v4(await drive_v6(2780,false),"V9 input route to moving lantern clearing")
	await v8_walk_to(2960)
	for frame in 180:await get_tree().physics_frame
	await v8_walk_to(2780)
	touch_axis=0;touch_jump=false
	for frame in 60:interact=true;await get_tree().physics_frame
	check_v4(absf(player.position.y-470)<4,"V9 moving lantern negative fixture on real ground")
	check_v4(not lit[2] and not can_light(2),"V9 moving lantern cannot activate from ground")
	check_v4(await v8_board(),"V9 board moving branch using jump inputs")
	for frame in 30:interact=true;await get_tree().physics_frame
	check_v4(lit.count(true)==3 and level.bridges_open,"V9 third lantern opens return bridges")
	await v9_capture("moving-lantern")
	var bridge_collision=true
	for bridge in level.bridges:bridge_collision=bridge_collision and bridge.visible and bridge.collision_layer==1
	check_v4(bridge_collision,"V9 all eight bridges visible and collidable")
	check_v4(await v8_walk_to(430,1600),"V9 return across all opened bridges without jumping")
	await v9_capture("return")
	for frame in 60:
		interact=true;await get_tree().physics_frame
		if mode=="dialogue":test_dialogue_finish()
		if joined:break
	check_v4(joined,"V9 return interaction recruits Porsuk")
	check_v4(await v8_walk_to(3850,1800),"V9 party exit route without jump inputs")
	for frame in 180:await get_tree().physics_frame
	check_v4(friend.is_on_floor() and friend.position.distance_to(player.position)<240,"V9 companion reaches exit by walking")
	check_v4(not completed,"V9 exit proximity alone never completes chapter")
	interact=true
	for frame in 10:await get_tree().physics_frame
	check_v4(mode=="dialogue" and runner.current.id=="exit_01","V9 explicit exit starts shared comic")
	runner.revealed=true;await v9_capture("exit-comic")
	test_dialogue_finish()
	check_v4(completed and mode=="exit_reveal","V9 help result shown before completion panel")
	await v9_capture("exit-light")
	await get_tree().create_timer(2.0).timeout
	check_v4(completed and mode=="complete","V9 Porsuk contribution completes chapter")
	check_v4(exit_lantern.modulate.r>0.9,"V9 Porsuk exit light is visibly lit")
	await v9_capture("complete")
	check_v4(rescue_count==0 and friend_rescues==0,"V9 full normal route needs no rescue teleport")
	var snapshot=progress_data();restore_progress(snapshot)
	for frame in 5:await get_tree().physics_frame
	check_v4(completed and joined and level.bridges_open,"V9 completed reload restores party and bridges")
	mode="play";clear_screen();build_hud();player.frozen=false;friend.frozen=false
	restart_game();test_dialogue_finish()
	for frame in 5:await get_tree().physics_frame
	check_v4(not level.bridges_open and lit.count(true)==0 and not joined,"V9 restart clears chapter shortcut and party")
	for i in [2,0]:light_lantern(i)
	var partial=progress_data();restore_progress(partial)
	for frame in 5:await get_tree().physics_frame
	check_v4(lit[2] and lit[0] and not lit[1] and not level.bridges_open,"V9 out-of-order partial reload keeps bridges closed")
	light_lantern(1)
	for frame in 5:await get_tree().physics_frame
	check_v4(level.bridges_open,"V9 any third lantern opens shortcut")
	print("V9 CHAPTER SUITE FAILED" if test_failed else "V9 CHAPTER SUITE PASSED")
	get_tree().quit(1 if test_failed else 0)

func go_river():
	if not completed:return
	var prepared=director.prepare_transition("B02","b02.entry")
	if not prepared.ok:return
	var previous=progress_data();var target=previous.duplicate(true)
	target.chapter_id="B02";target.geometry="river-v10";target.checkpoint_id="b02.entry"
	if not automated and not saves.save(save_path,target):
		director.finish_transition(false,"B02")
		show_message("Dere yoluna geçemedik","Kaydın değişmedi. Yeniden deneyebilirsin.",go_river);return
	var error=get_tree().change_scene_to_packed(prepared.scene)
	director.finish_transition(error==OK,"B02")
	if error!=OK:
		if not automated:saves.save(save_path,previous)
		show_message("Dere yolu açılamadı","Patikadaki ilerlemen korunuyor. Yeniden deneyebilirsin.",go_river)
