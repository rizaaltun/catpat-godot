extends "res://tests/summit-route/route.gd"
const SharedParty=preload("res://scripts/core/shared_party_route.gd")
const RouteSave=preload("res://scripts/core/shared_route_save.gd")
const LAND=[Vector2(0,700),Vector2(1180,780),Vector2(2440,700)]
const GAPS=[Vector2(700,1180),Vector2(1960,2440)]
var party
var save_service=RouteSave.new()
var save_path="user://shared-route-v1.json"
var persistence_enabled=true
var safe_bank=0
var safe_facing=1
var saved_bank=-1
var candidate_bank=-1
var candidate_seconds=0.0
var retry_seconds=0.0
var storage_writable=true
var progress_ready=false
var recovery_requires_progress=false
var save_message=""
var save_notice: Label
var pause_root: Control
var pause_detail: Label
var pause_button: Button
var resume_button: Button
var load_button: Button
var persistence_status="new"
var lantern_stage="unseen"
var rope_stage="loose"
var waymark_stage="loose"
var follower_min=10000.0
var capacity_max=0
var ai_capacity_max=0
var largest_step=0.0
var positions_before=[]
var reunions=[]
func _ready():
	super._ready()
	automatic="--shared-test" in OS.get_cmdline_user_args();driver=automatic
	if automatic:
		persistence_enabled=false
		call_deferred("test_shared")
	elif persistence_enabled:
		load_checkpoint()
	progress_ready=true
func build_ui():
	super.build_ui()
	var panel=preload("res://scripts/polish_ui.gd")
	pause_button=panel.button("Duraklat",Rect2(982,30,256,88),ui_layer,func():set_pause(true))
	panel.texture("res://assets/polish-v3/panel.png",Rect2(35,127,890,54),ui_layer)
	save_notice=panel.label("",Rect2(82,138,794,40),28,ui_layer)
	pause_root=Control.new();pause_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);ui_layer.add_child(pause_root)
	var shade=ColorRect.new();shade.color=Color(0.02,0.07,0.06,0.75);shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);pause_root.add_child(shade)
	var backdrop=panel.texture("res://assets/polish-v3/panel.png",Rect2(300,160,680,446),pause_root)
	var framed=AtlasTexture.new();framed.atlas=load("res://assets/polish-v3/panel.png");framed.region=Rect2(80,105,2010,520);backdrop.texture=framed
	panel.label("Biraz soluklanalım",Rect2(350,210,580,48),32,pause_root)
	pause_detail=panel.label("",Rect2(350,274,580,78),28,pause_root)
	resume_button=panel.button("Yolculuğa devam et",Rect2(352,363,576,88),pause_root,func():set_pause(false),true)
	load_button=panel.button("Kaydedilen kıyıdan başla",Rect2(352,475,576,88),pause_root,func():call_deferred("reload_checkpoint"))
	for button in [pause_button,resume_button,load_button]:button.add_theme_font_size_override("font_size",28)
	for button in [pause_button,load_button]:
		for style in ["normal","hover","pressed","focus"]:button.get_theme_stylebox(style).region_rect=Rect2(80,105,2010,520)
	pause_root.hide()
func bank_name(b:int) -> String:
	return ["Başlangıç kıyısı","Orta kıyı","İleri kıyı"][clampi(b,0,2)]
func update_save_ui():
	if not is_instance_valid(save_notice):return
	save_notice.text=save_message
	pause_detail.text=("Son kayıt: "+bank_name(saved_bank)+".
Ekip bu kıyıdan birlikte devam eder.") if saved_bank>=0 else "Henüz kayıt yok.
Bir kıyıya ulaşınca tekrar dene."
	load_button.disabled=saved_bank<0 or not storage_writable
func load_checkpoint():
	var result=save_service.load_progress(save_path)
	storage_writable=true
	recovery_requires_progress=false
	if result.ok:
		var data=result.data
		lantern_stage=data.lantern
		rope_stage=data.rope
		waymark_stage=data.waymark
		safe_bank=int(data.bank);safe_facing=int(data.facing)
		saved_bank=-1 if result.get("new",false) else safe_bank
		persistence_status="new" if result.get("new",false) else "backup" if result.get("recovered",false) else "loaded"
		save_message="Kıyıya ulaştığında yolculuğun kaydedilir." if saved_bank<0 else ("Yedek kayıt açıldı · " if result.get("recovered",false) else "Kaldığın kıyı · ")+bank_name(safe_bank)
	else:
		lantern_stage="unseen"
		rope_stage="loose"
		waymark_stage="loose"
		safe_bank=0;safe_facing=1;saved_bank=-1;recovery_requires_progress=true
		storage_writable=save_service.preserve_damaged(save_path)
		persistence_status="damaged_preserved" if storage_writable else "damaged_blocked"
		save_message="Kayıt açılamadı · Başlangıç kıyısından devam edebilirsin."
		if not storage_writable:save_message="Kayıt korunamadı · Bu oturumda yeni kayıt yazılmayacak."
	place_at_checkpoint()
	# A recovered backup is repaired through checked pending writes; corrupt primary is never copied over it.
	if result.ok and result.get("recovered",false):
		if not save_service.save(save_path,result.data):save_message="Yedek açıldı; yeni kayıt yazılamadı."
	update_save_ui()
func place_at_checkpoint():
	# Only initial load or explicit paused reload may reposition actors.
	reset_input()
	for i in team.size():
		var a=team[i];a.position=Vector2(LAND[safe_bank].x+LAND[safe_bank].y/2+safe_facing*(240-i*160),539)
		a.velocity=Vector2.ZERO;a.checkpoint=a.position;a.anim.flip_h=safe_facing<0
	party=SharedParty.new();party.configure(player,team.slice(1),carriers,LAND,GAPS);party.destination_bank=safe_bank;party.travel_direction=safe_facing
	for st in party.states:st.bank=safe_bank
	candidate_bank=-1;candidate_seconds=0;retry_seconds=0;positions_before.clear()
	update_camera(true)
func reload_checkpoint():
	if not paused or not persistence_enabled or saved_bank<0:return
	# Rebuild removes old physics contacts, rider bindings, reservations and queued inputs.
	build("shared");load_checkpoint();set_pause(false)
func progress_snapshot() -> Dictionary:
	var data=save_service.fresh();data.bank=safe_bank;data.facing=safe_facing
	data.lantern=lantern_stage;data.rope=rope_stage;data.waymark=waymark_stage
	return data
func commit_checkpoint() -> bool:
	if not persistence_enabled or not storage_writable:return false
	var data=progress_snapshot()
	if not save_service.save(save_path,data):
		save_message="Kayıt yazılamadı · Son başarılı kayıt korunuyor.";retry_seconds=5;update_save_ui();return false
	saved_bank=safe_bank;persistence_status="saved"
	save_message="Kaydedildi · "+bank_name(saved_bank)
	if OS.has_feature("web") and not OS.is_userfs_persistent():save_message="Bu tarayıcıda kayıt yalnız bu oturum için kullanılabilir."
	update_save_ui();return true
func update_checkpoint(delta:float):
	if not progress_ready or not persistence_enabled or paused or not storage_writable:return
	retry_seconds=maxf(0,retry_seconds-delta)
	var b=party.bank_of(player)
	if b>=0:
		if player.position.x<LAND[b].x+100 or player.position.x>LAND[b].x+LAND[b].y-100:b=-1
		elif carriers.any(func(s):return s.is_riding(player)):b=-1
	if b<0:candidate_bank=-1;candidate_seconds=0;return
	if b!=candidate_bank:candidate_bank=b;candidate_seconds=0
	candidate_seconds+=delta
	if candidate_seconds<0.35:return
	safe_bank=b
	if absf(player.input_axis)>0.1:safe_facing=1 if player.input_axis>0 else -1
	if recovery_requires_progress and b==0:return
	recovery_requires_progress=false
	if saved_bank!=safe_bank and retry_seconds<=0:commit_checkpoint()
func build(_next_mode:String):
	mode="shared";paused=false;reset_input();team.clear();carriers.clear();queues.clear();positions_before.clear()
	for b in touch_buttons:b.visible=true
	for c in arena.get_children():arena.remove_child(c);c.queue_free()
	for b in LAND:ledge(b.x,b.y,540,true)
	ledge(-100,3340,870,false)
	for i in LAND.size():
		for point in SharedParty.recovery_points(LAND[i],i).slice(0,3):ledge(point.x-105,210,point.y,false)
	wall(-115);wall(3255)
	for i in 2:
		var s=Surface.new();s.width=300;s.start=Vector2(GAPS[i].x+150,540);s.finish=Vector2(GAPS[i].y-150,540)
		s.speed=300;s.auto_cycle=true;s.dwell_seconds=1.4;s.dwell=1.4;s.enabled=true;arena.add_child(s);carriers.append(s)
	for i in 4:
		var id=["catpat","rabbit","badger","monkey"][i]
		var a=Rabbit.new() if id=="rabbit" else Monkey.new() if id=="monkey" else Cat.new()
		a.character_id=id;a.controlled=true;a.recruited=false;arena.add_child(a);a.position=Vector2(600-i*140,539);a.checkpoint=a.position
		for s in carriers:s.bind_rider(a)
		team.append(a)
		if i==1:
			basket=Sprite2D.new();basket.texture=load("res://assets/chapter-v12/basket.png");basket.scale=Vector2.ONE*0.045;basket.position=Vector2(42,-40);basket.z_index=1;a.add_child(basket)
	player=team[0];party=SharedParty.new();party.configure(player,team.slice(1),carriers,LAND,GAPS)
	subtitle.text="← → / A D: yürü · Boşluk: zıpla · Esc: duraklat\nArkadaşların seni takip eder · Taşıyıcıya bin, atla veya geri dön"
	update_camera(true)
func _input(e):
	if e is InputEventMouseButton and e.pressed and (paused or (is_instance_valid(pause_button) and pause_button.get_global_rect().has_point(e.position))):return
	if e is InputEventScreenTouch and e.pressed and (paused or (is_instance_valid(pause_button) and pause_button.get_global_rect().has_point(e.position))):return
	if e is InputEventKey and e.keycode==KEY_TAB:return
	super._input(e)
func set_pause(value:bool):
	super.set_pause(value)
	if party:party.set_paused(value)
	if is_instance_valid(pause_root):
		pause_root.visible=value;pause_button.visible=not value
		update_save_ui()
		if value:resume_button.grab_focus()
		else:get_viewport().gui_release_focus()
func _physics_process(delta):
	if not party:return
	if not paused:
		if not driver:
			player.input_axis=clampf(float(keys.get(KEY_RIGHT,false) or keys.get(KEY_D,false))-float(keys.get(KEY_LEFT,false) or keys.get(KEY_A,false))+router.axis,-1,1)
			var jumping=keys.get(KEY_SPACE,false) or keys.get(KEY_UP,false) or keys.get(KEY_W,false) or router.jump_held
			player.jump_request=jumping and not last_jump;player.jump_held=jumping;last_jump=jumping
		party.update(delta)
		update_checkpoint(delta)
	basket.position.x=-42 if team[1].anim.flip_h else 42
	var nearby=0;var left=0;var right=0
	for a in team.slice(1):
		if party.bank_of(a)==party.bank_of(player) and party.bank_of(player)>=0:nearby+=1
		elif a.position.x<player.position.x:left+=1
		else:right+=1
	status.text="Duraklatıldı · Esc ile devam" if paused else "Birlikte yolculuk · Yanında %d / 3"%nearby
	if not paused and left+right>0:status.text+="  ·  ← %d    %d →"%[left,right]
	if positions_before.size()==4:
		for i in 4:largest_step=maxf(largest_step,team[i].position.distance_to(positions_before[i]))
	positions_before=team.map(func(a):return a.position)
	for s in carriers:
		var total=0;var ai=0
		for i in 4:
			if s.is_riding(team[i]):total+=1;ai+=int(i>0)
		capacity_max=maxi(capacity_max,total);ai_capacity_max=maxi(ai_capacity_max,ai)
	for i in range(1,4):
		for j in range(i+1,4):follower_min=minf(follower_min,team[i].position.distance_to(team[j].position))
func update_camera(immediate:bool):
	if not is_instance_valid(player):return
	var target=Vector2(clampf(player.position.x+player.input_axis*90,620,2520),clampf(player.position.y-80,455,615))
	for e in GAPS:
		if player.position.y<650 and player.position.x>e.x-150 and player.position.x<e.y+150:target.x=(e.x+e.y)/2
	var low=player.position.x;var high=low
	for a in team:low=minf(low,a.position.x);high=maxf(high,a.position.x)
	var half=get_viewport_rect().size.x/(2*camera.zoom.x)
	var bound_low=player.position.x+120-half;var bound_high=player.position.x-120+half
	if high-low+240<half*2:bound_low=high+120-half;bound_high=low-120+half
	target.x=clampf(target.x,bound_low,bound_high)
	camera.position=target if immediate else camera.position.lerp(target,0.13)
	camera.position.x=clampf(camera.position.x,bound_low,bound_high)
func cross_shared(k:int,side:int) -> bool:
	var s=carriers[k];var e=GAPS[k]
	if not await walk_to(e.x-40 if side>0 else e.y+40,700):return false
	for f in 1200:
		await ticks(1)
		if absf(s.fraction-(0.0 if side>0 else 1.0))<0.0001 and s.dwell>1.2:break
	var seat=90.0*side
	for a in team.slice(1):
		if s.is_riding(a):seat=-90.0 if a.position.x>s.position.x else 90.0
	for f in 240:
		steer_to(s.position.x+seat);await ticks(1)
		if s.is_riding(player) and absf(player.position.x-s.position.x-seat)<8 and absf(player.velocity.x)<10:break
	player.input_axis=0
	if not s.is_riding(player):return false
	for f in 1200:
		await ticks(1)
		if absf(s.fraction-(1.0 if side>0 else 0.0))<0.0001 and s.dwell>1.0:return await walk_to(e.y+85 if side>0 else e.x-85,700)
	return false
func wait_for_team(b:int,limit=3600) -> bool:
	var start=party.time
	for f in limit:
		await ticks(1)
		if party.members.all(func(a):return party.bank_of(a)==b and absf(a.velocity.x)<5) and party.reservations==[-1,-1]:
			reunions.append({"bank":b,"seconds":party.time-start});return true
	return false
func test_shared():
	await ticks(45);print("V17 SHARED VIDEO READY")
	check(await cross_shared(0,1),"free_player_first_carrier")
	check(await cross_shared(1,1),"free_player_leaves_party_behind")
	check(await walk_to(2960),"free_player_reaches_far_bank")
	check(await wait_for_team(2),"three_friends_rejoin_far_bank",{"states":party.states,"positions":team.map(func(a):return str(a.position)),"reunions":reunions})
	await capture("shared-reunited-right")
	check(await cross_shared(1,-1),"player_reverses_to_middle")
	check(await cross_shared(1,1),"player_changes_mind_returns_right")
	await walk_to(2960)
	check(await wait_for_team(2),"party_recovers_from_mid_route_reversal",{"states":party.states,"reunions":reunions})
	check(await cross_shared(1,-1),"return_second_carrier")
	check(await cross_shared(0,-1),"return_first_carrier")
	await walk_to(540)
	check(await wait_for_team(0),"all_friends_return_left",{"states":party.states,"positions":team.map(func(a):return str(a.position)),"reunions":reunions})
	await capture("shared-reunited-left")
	set_pause(true);var before=team.map(func(a):return a.position);var phases=carriers.map(func(s):return s.fraction);var reserve=party.reservations.duplicate();await ticks(40)
	check(before==team.map(func(a):return a.position) and phases==carriers.map(func(s):return s.fraction) and reserve==party.reservations,"shared_pause_freezes_route")
	set_pause(false);check(team.all(func(a):return a.input_axis==0 and not a.jump_request and not a.jump_held),"shared_resume_clears_input")
	check(ai_capacity_max<=1 and capacity_max<=2,"one_friend_plus_free_player_capacity",{"ai":ai_capacity_max,"total":capacity_max})
	check(reunions.size()==3 and reunions.all(func(r):return r.seconds<=10),"reunion_wait_under_ten_seconds",{"reunions":reunions})
	check(follower_min>=105,"friends_keep_distinct_positions",{"minimum":follower_min})
	check(largest_step<17,"no_actor_teleport",{"maximum":largest_step})
	finish("shared")
func capture(name:String):
	if not "--shared-capture" in OS.get_cmdline_user_args():return
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://preproduction/qa/v17/"+name+".png")
func finish(label:String):
	var f=FileAccess.open("res://preproduction/qa/v17/"+label+"-results.json",FileAccess.WRITE)
	if f:f.store_string(JSON.stringify({"results":results,"failures":failures,"events":party.events},"\t"));f.close()
	print("V17 "+label+" "+("PASSED" if failures.is_empty() else "FAILED"));get_tree().quit(0 if failures.is_empty() else 1)
