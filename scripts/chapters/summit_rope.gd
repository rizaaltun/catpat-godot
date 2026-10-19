extends "res://scripts/chapters/summit_lantern.gd"
## Z42: carry the rope across the first carrier; durable repair enables the second.
const COIL_POINT=Vector2(600,540)
const WINCH_POINT=Vector2(1820,540)
const ROPE_DIALOGUE=[
	{"side":"left","text":"Halatı getirdim, Maymun. Gevşek ucu birlikte sabitleyelim."},
	{"side":"right","text":"Sen ucu tut, ben düğümü bağlayayım. Sonra hepimiz geçebiliriz."}]
var coil:Sprite2D
var winch:Sprite2D
var carried_coil:Sprite2D
var tied_coil:Sprite2D
var tow_line:Sprite2D
var winch_label:Label
var rope_events=[]
var return_access=false
func _ready():
	super._ready();refresh_rope()
func build(next_mode:String):
	super.build(next_mode)
	coil=Sprite2D.new();coil.texture=load("res://assets/chapter-v10/rope.webp");coil.scale=Vector2.ONE*0.09;coil.position=COIL_POINT+Vector2(-3,-30);coil.z_index=2;arena.add_child(coil)
	winch=Sprite2D.new();winch.texture=load("res://assets/chapter-v19/rope-winch-v2.webp");winch.centered=false;winch.scale=Vector2.ONE*0.13;winch.position=WINCH_POINT-Vector2(710,880)*0.13;winch.z_index=-2;arena.add_child(winch)
	carried_coil=Sprite2D.new();carried_coil.texture=coil.texture;carried_coil.scale=Vector2.ONE*0.065;carried_coil.position=Vector2(46,-45);carried_coil.z_index=2;player.add_child(carried_coil)
	tied_coil=Sprite2D.new();tied_coil.texture=coil.texture;tied_coil.scale=Vector2.ONE*0.065;tied_coil.position=WINCH_POINT+Vector2(5,-63);tied_coil.z_index=-1;arena.add_child(tied_coil)
	tow_line=Sprite2D.new();tow_line.texture=load("res://assets/chapter-v8/vine.webp");tow_line.z_index=-2;arena.add_child(tow_line)
	winch_label=UI.label("",Rect2(WINCH_POINT+Vector2(-150,-162),Vector2(330,42)),23,arena)
	winch_label.add_theme_color_override("font_shadow_color",Color("173d37"));winch_label.add_theme_constant_override("shadow_outline_size",5)
	refresh_rope()
func load_checkpoint():
	super.load_checkpoint()
	# Old previews allowed reaching the far shore before this repair existed.
	# Give the whole restored party a return passage, then dock the empty carrier.
	return_access=rope_stage!="ready" and safe_bank==2
	refresh_rope()
func near_ground_point(point:Vector2,radius:float=90) -> bool:
	return player.is_on_floor() and absf(player.position.y-point.y)<6 and absf(player.position.x-point.x)<radius
func close_to_monkey() -> bool:
	return team.size()==4 and party.bank_of(player)==1 and party.bank_of(team[3])==1 and absf(player.position.x-team[3].position.x)<=210
func available_action() -> String:
	if lantern_stage!="lit":return super.available_action()
	if rope_stage=="loose" and near_ground_point(COIL_POINT):return "Halatı al"
	if rope_stage=="carried" and near_ground_point(WINCH_POINT):return "Halatı yerleştir"
	if rope_stage=="requested" and close_to_monkey():return "Maymun ile sabitle"
	return ""
func interact():
	if lantern_stage!="lit":super.interact();return
	if paused or dialogue_active or action_cooldown>0 or available_action().is_empty():return
	action_cooldown=0.25;quest_error=""
	if rope_stage=="loose":commit_rope("carried")
	elif rope_stage=="carried":commit_rope("requested")
	elif rope_stage=="requested":begin_dialogue(ROPE_DIALOGUE,"rope.ready")
func begin_dialogue(lines:Array,target:String):
	if target=="rope.ready":comic.set_partner("Maymun","res://assets/chapter-v10/monkey-idle.webp","RÜZGÂRLI YAMAÇ · HALAT BAĞLANTISI","Birlikte sabitleyelim",true)
	else:comic.set_partner("Porsuk","res://assets/review-v2/badger-idle-r2.webp","RÜZGÂRLI YAMAÇ · YOL FENERİ")
	super.begin_dialogue(lines,target)
func commit_quest(target:String) -> bool:
	if target=="rope.ready":return commit_rope("ready")
	var ok=super.commit_quest(target)
	if ok:refresh_rope()
	return ok
func commit_rope(target:String) -> bool:
	var stages=RouteSave.ROPE_STAGES
	if lantern_stage!="lit" or stages.find(target)!=stages.find(rope_stage)+1:return false
	if not persistence_enabled or not storage_writable:
		quest_error="Görev kaydedilemedi. Kayıt erişimi yeniden açılmalı.";return false
	var data=progress_snapshot();data.rope=target
	if not save_service.save(save_path,data):
		quest_error="Kayıt yazılamadı. Aynı noktada E ile tekrar dene.";return false
	rope_stage=target;rope_events.append(target);saved_bank=safe_bank;recovery_requires_progress=false;persistence_status="saved"
	save_message="Kaydedildi · "+bank_name(saved_bank)
	if OS.has_feature("web") and not OS.is_userfs_persistent():save_message="Bu tarayıcıda kayıt yalnız bu oturum için kullanılabilir."
	quest_error="";update_save_ui();refresh_rope();return true
func refresh_rope():
	if not is_instance_valid(coil):return
	coil.visible=rope_stage=="loose";coil.modulate=Color.WHITE if lantern_stage=="lit" else Color(0.65,0.7,0.7)
	carried_coil.visible=rope_stage=="carried";tied_coil.visible=rope_stage in ["requested","ready"]
	tied_coil.modulate=Color.WHITE if rope_stage=="ready" else Color(0.72,0.77,0.75)
	tow_line.visible=rope_stage=="ready"
	carriers[1].enabled=rope_stage=="ready" or return_access
	winch_label.text="Bağlantı tamam" if rope_stage=="ready" else "Maymun ile sabitle" if rope_stage=="requested" else "Halat bağlantısı ↓"
	update_tow_line()
func update_tow_line():
	if not is_instance_valid(tow_line):return
	var start=WINCH_POINT+Vector2(39,-73);var end=carriers[1].position+Vector2(-110,-8)
	tow_line.position=(start+end)/2;tow_line.rotation=(end-start).angle()-PI/2
	tow_line.scale=Vector2(0.013,start.distance_to(end)/tow_line.texture.get_height())
func _physics_process(delta):
	super._physics_process(delta)
	if not is_instance_valid(coil):return
	if not paused:
		if return_access and rope_stage!="ready" and team.all(func(a):return party.bank_of(a) in [0,1]) and carriers[1].fraction==0.0 and not team.any(func(a):return carriers[1].is_riding(a)):
			return_access=false;carriers[1].enabled=false
		carried_coil.position.x=46 if player.anim.flip_h else -46
		update_tow_line()
	if lantern_stage=="lit" and quest_error.is_empty():
		var goals={"loose":"Başlangıç kıyısındaki halatı al · İkinci taşıyıcı durmuş.","carried":"Halatı ilk taşıyıcıyla orta kıyıya götür · Sağdaki makaraya yerleştir.","requested":"Halat yerinde · Orta kıyıda Maymun'un yanına git.","ready":"Halat sağlam · Çalışan taşıyıcıyla birlikte karşıya geç."}
		quest_label.text=goals[rope_stage]
		if return_access and rope_stage!="ready":quest_label.text="Ekipçe orta kıyıya dön · Dönüş taşıyıcısı seni bekliyor."
	for child in ui_layer.get_children():
		if child is Label and child.text.begins_with("RÜZGÂRLI YAMAÇ"):
			child.text="RÜZGÂRLI YAMAÇ · HALAT BAĞLANTISI" if lantern_stage=="lit" else "RÜZGÂRLI YAMAÇ · YOL FENERİ"
func test_shared():
	# Explicit completed-quest fixture for the inherited carrier-only regression.
	lantern_stage="lit";rope_stage="ready";refresh_lantern();refresh_rope()
	await super.test_shared()
