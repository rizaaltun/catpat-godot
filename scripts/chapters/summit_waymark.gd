extends "res://scripts/chapters/summit_rope.gd"
## Z43: recover the fallen arrow, restore the real fork, reunite at the overlook.
const ARROW_POINT=Vector2(2460,705)
const POST_POINT=Vector2(2590,540)
const LOOKOUT_POINT=Vector2(3020,540)
const WAYMARK_DIALOGUE=[
	{"side":"left","text":"Düşen oku getirdim, Pıtpıt. Birlikte dikmeye takalım mı?"},
	{"side":"right","text":"Ben dikmeyi tutarım. Ok sağdaki seyir düzlüğünü göstersin!"}]
const LOOKOUT_DIALOGUE=[
	{"side":"left","text":"Fener yandı, halat sağlam, yol işareti de yerinde. Hepimiz buradayız!"},
	{"side":"right","text":"Birbirimize yardım ederek geldik. Şimdi festival yoluna hazırız!"}]
var fallen_arrow:Sprite2D
var carried_arrow:Sprite2D
var mounted_arrow:Sprite2D
var post:Sprite2D
var arrow_hint:Label
var fork_hint:Label
var lookout_hint:Label
var waymark_events=[]
func _ready():
	super._ready();refresh_waymark()
func arrow_sprite(parent:Node,point:Vector2,scale_value:float) -> Sprite2D:
	var s=Sprite2D.new();s.texture=load("res://assets/chapter-v20/festival-arrow.webp");s.scale=Vector2.ONE*scale_value;s.position=point;s.z_index=2;parent.add_child(s);return s
func hint(text:String,point:Vector2,width:float) -> Label:
	var label=UI.label(text,Rect2(point,Vector2(width,74)),23,arena)
	label.add_theme_color_override("font_shadow_color",Color("173d37"));label.add_theme_constant_override("shadow_outline_size",5)
	return label
func build(next_mode:String):
	super.build(next_mode)
	fallen_arrow=arrow_sprite(arena,ARROW_POINT+Vector2(0,-32),0.085);fallen_arrow.rotation=-0.15
	carried_arrow=arrow_sprite(player,Vector2(43,-47),0.05)
	post=Sprite2D.new();post.texture=load("res://assets/chapter-v20/waymark-post.webp");post.centered=false;post.scale=Vector2.ONE*0.15;post.position=POST_POINT-Vector2(512,1490)*0.15;post.z_index=-2;arena.add_child(post)
	mounted_arrow=arrow_sprite(arena,POST_POINT+Vector2(49,-180),0.12);mounted_arrow.z_index=-1
	arrow_hint=hint("Düşen festival oku →",ARROW_POINT+Vector2(-355,-52),280)
	fork_hint=hint("",POST_POINT+Vector2(-100,32),340)
	lookout_hint=hint("",LOOKOUT_POINT+Vector2(-190,32),380)
	refresh_waymark()
func load_checkpoint():
	super.load_checkpoint();refresh_waymark()
func close_to_rabbit() -> bool:
	return team.size()==4 and party.bank_of(player)==2 and party.bank_of(team[1])==2 and absf(player.position.x-team[1].position.x)<=210
func party_at_lookout() -> bool:
	return team.size()==4 and team.all(func(a):return party.bank_of(a)==2) and party.reservations==[-1,-1]
func available_action() -> String:
	if rope_stage!="ready":return super.available_action()
	if waymark_stage=="loose" and near_ground_point(ARROW_POINT,75):return "Festival okunu al"
	if waymark_stage=="carried" and near_ground_point(POST_POINT):return "Oku dikmeye yerleştir"
	if waymark_stage=="placed" and close_to_rabbit():return "Pıtpıt ile sabitle"
	if waymark_stage=="ready" and near_ground_point(LOOKOUT_POINT,85) and party_at_lookout():return "Birlikte manzaraya bak"
	return ""
func interact():
	if rope_stage!="ready":super.interact();return
	if paused or dialogue_active or action_cooldown>0 or available_action().is_empty():return
	action_cooldown=0.25;quest_error=""
	if waymark_stage=="loose":commit_waymark("carried")
	elif waymark_stage=="carried":commit_waymark("placed")
	elif waymark_stage=="placed":begin_dialogue(WAYMARK_DIALOGUE,"waymark.ready")
	elif waymark_stage=="ready":begin_dialogue(LOOKOUT_DIALOGUE,"waymark.seen")
func begin_dialogue(lines:Array,target:String):
	super.begin_dialogue(lines,target)
	if target.begins_with("waymark."):
		comic.set_partner("Pıtpıt","res://assets/chapter-v12/rabbit-idle.webp","RÜZGÂRLI YAMAÇ · FESTİVAL YÖNÜ","Birlikte sabitleyelim" if target=="waymark.ready" else "Manzaraya dön",true)
func commit_quest(target:String) -> bool:
	if target.begins_with("waymark."):return commit_waymark(target.trim_prefix("waymark."))
	var ok=super.commit_quest(target)
	if ok:refresh_waymark()
	return ok
func commit_waymark(target:String) -> bool:
	var stages=RouteSave.WAYMARK_STAGES
	if rope_stage!="ready" or stages.find(target)!=stages.find(waymark_stage)+1:return false
	if target=="seen" and (not party_at_lookout() or not near_ground_point(LOOKOUT_POINT,85)):return false
	if not persistence_enabled or not storage_writable:
		quest_error="Görev kaydedilemedi. Kayıt erişimi yeniden açılmalı.";return false
	var data=progress_snapshot();data.waymark=target
	if not save_service.save(save_path,data):
		quest_error="Kayıt yazılamadı. Aynı noktada E ile tekrar dene.";return false
	waymark_stage=target;waymark_events.append(target);saved_bank=safe_bank;recovery_requires_progress=false;persistence_status="saved"
	save_message="Kaydedildi · "+bank_name(saved_bank)
	if OS.has_feature("web") and not OS.is_userfs_persistent():save_message="Bu tarayıcıda kayıt yalnız bu oturum için kullanılabilir."
	quest_error="";update_save_ui();refresh_waymark();return true
func refresh_waymark():
	if not is_instance_valid(fallen_arrow):return
	fallen_arrow.visible=waymark_stage=="loose";fallen_arrow.modulate=Color.WHITE if rope_stage=="ready" else Color(0.65,0.7,0.7)
	carried_arrow.visible=waymark_stage=="carried"
	mounted_arrow.visible=waymark_stage in ["placed","ready","seen"];mounted_arrow.rotation=0.3 if waymark_stage=="placed" else 0.0
	arrow_hint.visible=rope_stage=="ready" and waymark_stage=="loose"
	fork_hint.text="← Dönüş basamakları\nSeyir düzlüğü →" if waymark_stage in ["ready","seen"] else "Yol ayrımı · Ok eksik" if waymark_stage=="loose" else "Dikme burada ↓" if waymark_stage=="carried" else "Pıtpıt ile sabitle"
	lookout_hint.text="Festival yoluna hazırız!" if waymark_stage=="seen" else "Seyir düzlüğü ↓"
	lookout_hint.visible=waymark_stage in ["ready","seen"]
func hint_clipped_by_viewport(label:Label) -> bool:
	var transform=get_viewport().get_canvas_transform()*label.get_global_transform()
	var rect=Rect2(transform.origin,transform.basis_xform(label.size))
	var bounds=get_viewport_rect().size
	var overlaps=rect.end.x>0 and rect.position.x<bounds.x and rect.end.y>0 and rect.position.y<bounds.y
	var fully_inside=rect.position.x>=20 and rect.position.y>=20 and rect.end.x<=bounds.x-20 and rect.end.y<=bounds.y-20
	return overlaps and not fully_inside
func visible_hints_fit_viewport() -> bool:
	for label in [arrow_hint,fork_hint,lookout_hint]:
		if is_instance_valid(label) and label.visible and hint_clipped_by_viewport(label):return false
	return true
func _physics_process(delta):
	super._physics_process(delta)
	if not is_instance_valid(fallen_arrow):return
	if not paused:carried_arrow.position.x=43 if player.anim.flip_h else -43
	fork_hint.visible=player.position.y<580 and not hint_clipped_by_viewport(fork_hint)
	arrow_hint.visible=rope_stage=="ready" and waymark_stage=="loose" and not hint_clipped_by_viewport(arrow_hint)
	lookout_hint.visible=waymark_stage in ["ready","seen"] and not hint_clipped_by_viewport(lookout_hint)
	if rope_stage=="ready" and quest_error.is_empty():
		var goals={"loose":"İleri kıyının alt basamağında düşen oku bul · E ile al.","carried":"Basamaklarla yukarı dön · Oku yol ayrımındaki dikmeye yerleştir.","placed":"Ok dikmede · İleri kıyıda Pıtpıt'ın yanına git.","ready":"Ok sağa bakıyor · Arkadaşlarınla seyir düzlüğüne ilerle.","seen":"Üç yardım tamam · Hep birlikte festival yoluna hazırız!"}
		quest_label.text=goals[waymark_stage]
		if waymark_stage=="ready" and near_ground_point(LOOKOUT_POINT,85) and not party_at_lookout():quest_label.text="Seyir düzlüğündesin · Arkadaşlarının kıyıya ulaşmasını bekle."
		for child in ui_layer.get_children():
			if child is Label and child.text.begins_with("RÜZGÂRLI YAMAÇ"):child.text="RÜZGÂRLI YAMAÇ · FESTİVAL YÖNÜ"
