extends "res://scripts/chapters/summit_waymark.gd"
const MainStore=preload("res://scripts/core/save_service.gd")
const MainRoute=preload("res://scripts/core/main_route_save.gd")
var load_blocked=false
var menu_button:Button
var menu_change:Callable
var control_display=preload("res://scripts/core/control_display.gd").new()
var keyboard_controls_hint=""
func _ready():
	save_path=str(get_tree().get_meta("journey_save_path","user://festival_v3.json"))
	var initial=MainStore.new().load_progress(save_path)
	if not initial.ok or initial.data.chapter_id!="B04":
		load_blocked=true;paused=true
		var layer=CanvasLayer.new();add_child(layer)
		UI.texture("res://assets/chapter-v5/menu.webp",Rect2(0,0,1280,720),layer)
		UI.texture("res://assets/polish-v3/panel.webp",Rect2(260,145,760,450),layer)
		UI.label("Yamaç kaydı açılamadı",Rect2(350,235,590,65),34,layer)
		UI.label("Yolculuk kaydını ana menüden yeniden açabilirsin. İlerlemen değiştirilmedi.",Rect2(350,325,575,100),26,layer)
		UI.button("Ana menü",Rect2(420,463,440,88),layer,go_menu,true)
		return
	save_service=MainRoute.new();save_service.main_data=initial.data.duplicate(true)
	super._ready()
	update_controls_hint()
func build_ui():
	super.build_ui()
	# Reuse the shipped image controls, with comfortable targets at narrow sizes.
	var control_rects=[Rect2(24,500,112,112),Rect2(152,500,112,112),Rect2(1116,500,140,112)]
	for i in touch_buttons.size():
		var control:Button=touch_buttons[i]
		control.position=control_rects[i].position;control.size=control_rects[i].size
		control.add_theme_font_override("font",UI.font())
		control.add_theme_color_override("font_color",Color("183d35"))
		for state in ["normal","hover","pressed","focus"]:
			var skin=StyleBoxTexture.new();skin.texture=load("res://assets/polish-v3/jump-button.webp");skin.region_rect=Rect2(130,130,1000,1000)
			if state=="pressed":skin.modulate_color=Color(0.86,0.91,0.91)
			control.add_theme_stylebox_override(state,skin)
	router.bind_controls(touch_buttons[0].get_rect(),touch_buttons[1].get_rect(),touch_buttons[2].get_rect(),Rect2())
	for child in pause_root.get_children():
		if child is TextureRect:child.position=Vector2(300,120);child.size=Vector2(680,520)
		elif child is Label and child!=pause_detail:child.position.y=170
	pause_detail.position.y=230;pause_detail.size.y=70
	resume_button.position.y=325;load_button.position.y=425
	menu_button=UI.button("Kaydet ve ana menü",Rect2(352,525,576,88),pause_root,save_menu)
	menu_button.add_theme_font_size_override("font_size",28)
	for style in ["normal","hover","pressed","focus"]:menu_button.get_theme_stylebox(style).region_rect=Rect2(91,118,1980,482)
func go_menu():
	get_tree().set_meta("journey_save_path",save_path)
	var err=menu_change.call() if menu_change.is_valid() else get_tree().change_scene_to_file("res://scenes/polish_v3.tscn")
	if err!=OK and not load_blocked:pause_detail.text="Menü açılamadı. Kaydın korunuyor; tekrar deneyebilirsin."
func save_menu():
	if not paused or dialogue_active:return
	if not commit_checkpoint():pause_detail.text="Kaydedemedik. Son kayıt korunuyor; yeniden deneyebilirsin.";return
	go_menu()
func _input(e):
	if not load_blocked:
		if control_display.observe(e):update_controls_hint()
		super._input(e)
func _physics_process(delta):
	if not load_blocked:
		super._physics_process(delta)
		update_controls_hint()
func update_controls_hint():
	if not is_instance_valid(subtitle):return
	if keyboard_controls_hint.is_empty():keyboard_controls_hint=subtitle.text
	var desired="Oklarla yürü · Zıpla ile atla · Görev düğmesine dokun" if control_display.touch_mode else keyboard_controls_hint
	if subtitle.text==desired:return
	subtitle.text=desired
	subtitle.add_theme_font_size_override("font_size",26 if control_display.touch_mode else 19)
	subtitle.position.y=642 if control_display.touch_mode else 639
	subtitle.size.y=54 if control_display.touch_mode else 64

# Main journey hand-off: write the validated B05 entry before opening its scene.
func available_action() -> String:
	if waymark_stage=="seen" and near_ground_point(LOOKOUT_POINT,85) and party_at_lookout():return "Festivale birlikte gir"
	return super.available_action()
func interact():
	if waymark_stage=="seen" and near_ground_point(LOOKOUT_POINT,85) and party_at_lookout():
		enter_festival()
		return
	super.interact()
func enter_festival():
	if paused or dialogue_active or action_cooldown>0:return
	var store=MainStore.new()
	var before=store.load_progress(save_path)
	if not before.ok or before.data.chapter_id!="B04" or not "chapter.B04.complete" in before.data.quest_flags:
		quest_error="Önce yamaç yolculuğunu tamamla.";return
	var prepared=store.director.prepare_transition("B05","b05.entry")
	if not prepared.ok:quest_error="Festival sahnesi açılamıyor. Kaydın korunuyor.";return
	var target=before.data.duplicate(true)
	target.chapter_id="B05";target.geometry="festival-v1";target.checkpoint_id="b05.entry";target.summit={}
	if not store.save(save_path,target):
		store.director.finish_transition(false,"B05")
		quest_error="Festival girişi kaydedilemedi. Yolculuğun korunuyor.";return
	get_tree().set_meta("journey_save_path",save_path)
	var err=get_tree().change_scene_to_packed(prepared.scene)
	store.director.finish_transition(err==OK,"B05")
	if err!=OK:
		if not store.save(save_path,before.data):quest_error="Sahne açılamadı. Güvenli festival giriş kaydı duruyor."
		else:quest_error="Festival açılamadı; yamaç kaydın korundu."
