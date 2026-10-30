extends "res://tests/shared-route/shared.gd"
## First B04 help beat on the existing shared route. No main-story save changes.
const Comic=preload("res://scripts/core/summit_comic.gd")
const UI=preload("res://scripts/polish_ui.gd")
const LANTERN_POINT=Vector2(680,705)
const INTRO=[
	{"side":"right","text":"Rüzgâr alt patikadaki feneri söndürmüş. Kapağı açık kalmış!"},
	{"side":"left","text":"Basamaklardan fenerin yanına inerim. Kapağını kapatıp geri dönerim."},
	{"side":"right","text":"Sonra yanıma dön. Feneri birlikte yakalım; yolumuz aydınlansın."}]
const FINISH=[
	{"side":"left","text":"Kapağı kapattım, Porsuk. Artık rüzgâr içeri giremez."},
	{"side":"right","text":"Ben de ışığını yakayım. Bak, alt patika artık aydınlık!","final":true}]
var comic
var dialogue_active=false
var dialogue_lines=[]
var dialogue_index=0
var dialogue_target=""
var action_cooldown=0.0
var quest_error=""
var quest_label:Label
var action_button:Button
var lamp:Sprite2D
var halo:Sprite2D
var lid:Sprite2D
var world_hint:Label
var glow_time=0.0
var quest_events=[]
func _ready():
	super._ready()
	refresh_lantern()
func build_ui():
	super.build_ui()
	for child in ui_layer.get_children():
		if child is Label and child.text.begins_with("RÜZGÂRLI YAMAÇ"):child.text="RÜZGÂRLI YAMAÇ · YOL FENERİ"
	quest_label=UI.label("",Rect2(52,188,840,72),27,ui_layer)
	quest_label.add_theme_color_override("font_shadow_color",Color("173d37"));quest_label.add_theme_constant_override("shadow_outline_size",6)
	action_button=UI.button("",Rect2(720,528,380,88),ui_layer,interact,true)
	action_button.add_theme_font_size_override("font_size",28);action_button.hide()
	comic=Comic.new();ui_layer.add_child(comic);comic.setup(advance_dialogue,cancel_dialogue);comic.hide()
	ui_layer.move_child(pause_root,-1)
func build(next_mode:String):
	super.build(next_mode)
	# The fener is on an already measured return step. Do not pile new ledges on the shore.
	lamp=Sprite2D.new();lamp.texture=load("res://assets/polish-v3/lantern.webp");lamp.centered=false
	lamp.scale=Vector2.ONE*0.12;lamp.position=LANTERN_POINT-Vector2(590,1230)*0.12;lamp.z_index=-2;arena.add_child(lamp)
	halo=Sprite2D.new();halo.name="LanternImageGlow";halo.texture=load("res://assets/runtime/effects/catpat_b05_lantern_glow_v001.png")
	halo.position=LANTERN_POINT+Vector2(10,-55);halo.scale=Vector2.ONE*640.0/maxf(1.0,halo.texture.get_width());halo.modulate.a=0.42;halo.z_index=3;arena.add_child(halo)
	# Small raised/slanted latch is an effect marker on the intact generated lamp asset.
	lid=Sprite2D.new();lid.texture=load("res://assets/chapter-v10/plank.webp");lid.scale=Vector2(0.025,0.012);lid.position=LANTERN_POINT+Vector2(16,-76);lid.z_index=-1;arena.add_child(lid)
	world_hint=UI.label("",Rect2(LANTERN_POINT+Vector2(-145,-177),Vector2(320,45)),22,arena)
	world_hint.add_theme_color_override("font_shadow_color",Color("173d37"));world_hint.add_theme_constant_override("shadow_outline_size",5)
	refresh_lantern()
	subtitle.text="← → / A D: yürü · Boşluk: zıpla · E: yardım et · Esc: duraklat\nAlt patikadan basamaklarla geri çık · Arkadaşların kıyıda seni bekler"
func load_checkpoint():
	super.load_checkpoint();refresh_lantern()
func reload_checkpoint():
	if not paused or not persistence_enabled or saved_bank<0:return
	dialogue_active=false;dialogue_target="";dialogue_lines=[];dialogue_index=0
	comic.hide();quest_error="";action_cooldown=0.25
	super.reload_checkpoint()
func close_to_badger() -> bool:
	return team.size()==4 and party.bank_of(player)==0 and party.bank_of(team[2])==0 and absf(player.position.x-team[2].position.x)<=200
func at_lantern() -> bool:
	return player.is_on_floor() and absf(player.position.y-LANTERN_POINT.y)<6 and absf(player.position.x-LANTERN_POINT.x)<78
func available_action() -> String:
	if lantern_stage=="unseen" and close_to_badger():return "Porsuk ile konuş"
	if lantern_stage=="accepted" and at_lantern():return "Fenerin kapağını kapat"
	if lantern_stage=="prepared" and close_to_badger():return "Porsuk ile feneri yak"
	return ""
func interact():
	if paused or dialogue_active or action_cooldown>0:return
	var action=available_action()
	if action.is_empty():return
	action_cooldown=0.25;quest_error=""
	if lantern_stage=="unseen":begin_dialogue(INTRO,"accepted")
	elif lantern_stage=="accepted":commit_quest("prepared")
	elif lantern_stage=="prepared":begin_dialogue(FINISH,"lit")
func begin_dialogue(lines:Array,target:String):
	dialogue_lines=lines;dialogue_index=0;dialogue_target=target;dialogue_active=true
	comic.left_line.text="";comic.right_line.text="";comic.show_line(lines[0],false)
	set_pause(false);action_cooldown=0.25
func advance_dialogue():
	if not dialogue_active or pause_root.visible or action_cooldown>0:return
	action_cooldown=0.25
	if dialogue_index+1<dialogue_lines.size():
		dialogue_index+=1;comic.show_line(dialogue_lines[dialogue_index],dialogue_index==dialogue_lines.size()-1)
	else:
		var target=dialogue_target;end_dialogue();commit_quest(target)
func cancel_dialogue():
	if not dialogue_active or pause_root.visible:return
	end_dialogue()
func end_dialogue():
	dialogue_active=false;dialogue_target="";comic.hide();set_pause(false);action_cooldown=0.25
func commit_quest(target:String) -> bool:
	var stages=RouteSave.LANTERN_STAGES
	if stages.find(target)!=stages.find(lantern_stage)+1:return false
	if not persistence_enabled or not storage_writable:
		quest_error="Görev kaydedilemedi. Kayıt erişimi yeniden açılmalı.";return false
	var data=progress_snapshot();data.lantern=target
	if not save_service.save(save_path,data):
		quest_error="Kayıt yazılamadı. Aynı noktada E ile tekrar dene.";return false
	lantern_stage=target;saved_bank=safe_bank;recovery_requires_progress=false;persistence_status="saved"
	quest_events.append(target);save_message="Kaydedildi · "+bank_name(saved_bank)
	if OS.has_feature("web") and not OS.is_userfs_persistent():save_message="Bu tarayıcıda kayıt yalnız bu oturum için kullanılabilir."
	quest_error="";update_save_ui();refresh_lantern();return true
func refresh_lantern():
	if not is_instance_valid(lamp):return
	lamp.modulate=Color.WHITE if lantern_stage=="lit" else Color(0.34,0.42,0.5)
	halo.visible=lantern_stage=="lit";lid.rotation=-0.55 if lantern_stage in ["unseen","accepted"] else 0.0
	lid.modulate=Color("b9ddce") if lantern_stage=="prepared" else Color("80796b")
	world_hint.text="Yol feneri yanıyor" if lantern_stage=="lit" else "Kapak kapalı · Porsuk'a dön" if lantern_stage=="prepared" else "Yol feneri ↓"
func halo_reduced_motion()->bool:
	var fallback={}
	for property in save_service.get_property_list():
		if property.name=="main_data":
			var data=save_service.get("main_data")
			if data is Dictionary:fallback=data.get("settings",{})
	var preferences=get_tree().root.get_meta("catpat_preferences",fallback)
	return bool(preferences.get("reduced_motion",false)) if preferences is Dictionary else false
func set_pause(value:bool):
	super.set_pause(value or dialogue_active)
	if not is_instance_valid(comic):return
	pause_root.visible=value;comic.visible=dialogue_active and not value;pause_button.visible=not value and not dialogue_active
	if is_instance_valid(action_button):action_button.visible=false
func _input(e):
	if dialogue_active and not pause_root.visible:
		if e is InputEventKey and e.pressed and not e.echo:
			if e.keycode in [KEY_E,KEY_SPACE,KEY_ENTER]:advance_dialogue()
			elif e.keycode==KEY_ESCAPE:cancel_dialogue()
		return
	if not paused and e is InputEventKey and e.pressed and not e.echo and e.keycode==KEY_E:interact();return
	if not paused and ((e is InputEventMouseButton and e.pressed) or (e is InputEventScreenTouch and e.pressed)):
		if action_button.visible and action_button.get_global_rect().has_point(e.position):return
	super._input(e)
func _physics_process(delta):
	super._physics_process(delta)
	if not is_instance_valid(quest_label):return
	if not pause_root.visible:action_cooldown=maxf(0,action_cooldown-delta)
	if not paused:
		var reduced=halo_reduced_motion()
		if not reduced:glow_time+=delta
		halo.modulate.a=0.42 if reduced else 0.42*(0.92+sin(glow_time*2.0)*0.06)
	var goals={"unseen":"Porsuk seni bekliyor · Başlangıç kıyısında onunla konuş.","accepted":"Basamaklardan yol fenerine in · Kapağını kapat.","prepared":"Kapak hazır · Başlangıç kıyısında Porsuk'un yanına dön.","lit":"Yol feneri yandı · Arkadaşlarınla geçitlere ilerle."}
	quest_label.text=quest_error if not quest_error.is_empty() else goals[lantern_stage]
	quest_label.visible=not paused
	var action=available_action() if not paused and not dialogue_active else ""
	action_button.visible=not action.is_empty();action_button.text=action
