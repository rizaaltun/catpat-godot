extends Node2D
## T20b: playable solo blockout; separate two-carrier party rehearsal.
const Surface=preload("res://scripts/core/moving_surface.gd")
const Queue=preload("res://scripts/core/carrier_queue.gd")
const Cat=preload("res://scripts/polish_actor.gd")
const Monkey=preload("res://scripts/monkey_actor.gd")
const Rabbit=preload("res://scripts/rabbit_actor.gd")
const Router=preload("res://scripts/core/input_router.gd")
const BANKS=[Vector2(0,700),Vector2(1040,780),Vector2(2160,700)]
const EDGES=[Vector2(700,1040),Vector2(1820,2160)]
var arena: Node2D
var camera: Camera2D
var carriers=[]
var team=[]
var queues=[]
var player
var basket: Sprite2D
var active_queue=-1
var route_side=1
var party_stage="idle"
var mode="solo"
var paused=false
var automatic=false
var driver=false
var keys={}
var router=Router.new()
var last_jump=false
var status: Label
var subtitle: Label
var results=[]
var failures=[]
var observed_max_step=0.0
var observed_min_spacing=10000.0
var observed_max_riders=0
var last_positions=[]
var seam_times=[]
var ui_layer: CanvasLayer
var touch_buttons=[]
func _ready():
	process_physics_priority=-20
	automatic="--route-test" in OS.get_cmdline_user_args() or "--party-test" in OS.get_cmdline_user_args()
	driver=automatic
	var background=CanvasLayer.new();background.layer=-10;add_child(background)
	var image=TextureRect.new();image.texture=load("res://assets/chapter-v12/garden.webp");image.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;image.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_COVERED;image.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);background.add_child(image)
	arena=Node2D.new();add_child(arena)
	camera=preload("res://tests/summit-route/route_camera.gd").new();camera.position=Vector2(650,460);camera.zoom=Vector2.ONE*0.9;add_child(camera)
	build_ui();build("party" if "--party-test" in OS.get_cmdline_user_args() else "solo")
	if "--route-test" in OS.get_cmdline_user_args():call_deferred("test_solo")
	elif "--party-test" in OS.get_cmdline_user_args():call_deferred("test_party")
func build_ui():
	ui_layer=CanvasLayer.new();add_child(ui_layer)
	var panel=preload("res://scripts/polish_ui.gd")
	panel.texture("res://assets/polish-v3/panel.webp",Rect2(24,16,900,122),ui_layer)
	panel.label("RÜZGÂRLI YAMAÇ · İKİ GEÇİT",Rect2(58,36,830,38),24,ui_layer)
	status=panel.label("",Rect2(58,76,830,40),21,ui_layer)
	panel.texture("res://assets/polish-v3/panel.webp",Rect2(35,626,1210,86),ui_layer)
	subtitle=panel.label("",Rect2(80,639,1120,64),19,ui_layer)
	for spec in [["←",Rect2(24,548,85,66)],["→",Rect2(121,548,85,66)],["Zıpla",Rect2(1143,548,113,66)]]:
		var b=Button.new();b.text=spec[0];b.position=spec[1].position;b.size=spec[1].size;b.mouse_filter=Control.MOUSE_FILTER_IGNORE;b.add_theme_font_size_override("font_size",22);ui_layer.add_child(b);touch_buttons.append(b)
	router.bind_controls(Rect2(24,548,85,66),Rect2(121,548,85,66),Rect2(1143,548,113,66),Rect2())
func build(next_mode: String):
	mode=next_mode;active_queue=-1;party_stage="idle";paused=false;seam_times.clear();queues.clear();team.clear();carriers.clear();last_positions.clear();reset_input()
	for b in touch_buttons:b.visible=mode=="solo"
	observed_max_step=0;observed_min_spacing=10000;observed_max_riders=0
	for c in arena.get_children():arena.remove_child(c);c.queue_free()
	for b in BANKS:ledge(b.x,b.y,540,true)
	ledge(-100,3060,870,false)
	for origin in [100.0,1220.0,2340.0]:
		ledge(origin,210,790,false);ledge(origin+130,210,705,false);ledge(origin,210,620,false)
	wall(-115);wall(2975)
	for i in 2:
		var s=Surface.new();s.start=Vector2(EDGES[i].x+90,540);s.finish=Vector2(EDGES[i].y-90,540)
		s.speed=100 if mode=="solo" else 200;s.auto_cycle=mode=="solo";s.dwell_seconds=1.0 if mode=="solo" else 0.12
		s.enabled=mode=="solo";s.dwell=1.0;arena.add_child(s);carriers.append(s)
	for i in (4 if mode=="party" else 1):
		var id=["catpat","rabbit","badger","monkey"][i]
		var a=Rabbit.new() if id=="rabbit" else Monkey.new() if id=="monkey" else Cat.new()
		a.character_id=id;a.controlled=true;a.recruited=false;arena.add_child(a)
		a.position=Vector2(600-i*140,539);a.checkpoint=a.position
		for s in carriers:s.bind_rider(a)
		team.append(a)
		if id=="rabbit":
			basket=Sprite2D.new();basket.texture=load("res://assets/chapter-v12/basket.webp");basket.scale=Vector2.ONE*0.045;basket.position=Vector2(42,-40);basket.z_index=1;a.add_child(basket)
	player=team[0]
	for i in 2:
		var q=Queue.new();q.configure(carriers[i],team);q.set_stations(EDGES[i].x,EDGES[i].y);queues.append(q)
	subtitle.text="← → / A D: yürü · Boşluk: zıpla · Esc: duraklat\nAlt patikadan basamaklarla geri çık · Tab: ekip provası" if mode=="solo" else "E: iki geçidi aş · R: iki geçitten geri dön · Esc: duraklat\nKontrollü ekip provası · Tab: serbest Çatpat kontrolü"
	update_camera(true)
func ledge(x:float,width:float,y:float,bank_art:bool):
	var body=StaticBody2D.new();arena.add_child(body)
	var collision=CollisionShape2D.new();var shape=RectangleShape2D.new();shape.size=Vector2(width,20)
	collision.shape=shape;collision.position=Vector2(x+width/2,y+10);collision.one_way_collision=true;collision.one_way_collision_margin=6;body.add_child(collision)
	if bank_art:
		var art=Sprite2D.new();art.texture=load("res://assets/chapter-v11/bank.webp");art.centered=false;art.scale=Vector2.ONE*width/2110.0;art.position=Vector2(x,y)-Vector2(30,160)*art.scale;art.z_index=-5;arena.add_child(art)
	else:
		var p=Polygon2D.new();p.polygon=PackedVector2Array([Vector2(x,y),Vector2(x+width,y),Vector2(x+width,y+20),Vector2(x,y+20)]);p.color=Color("526c60");p.z_index=-4;arena.add_child(p)
		var line=Line2D.new();line.points=PackedVector2Array([Vector2(x,y),Vector2(x+width,y)]);line.width=4;line.default_color=Color("dcc898");line.z_index=-3;arena.add_child(line)
func wall(x:float):
	var body=StaticBody2D.new();arena.add_child(body);var c=CollisionShape2D.new();var shape=RectangleShape2D.new();shape.size=Vector2(30,1600);c.shape=shape;c.position=Vector2(x,400);body.add_child(c)
func reset_input():
	keys.clear();router.reset();last_jump=false
	for a in team:a.input_axis=0;a.jump_request=false;a.jump_held=false;a.jump_buffer=0
func set_pause(value:bool):
	paused=value;reset_input()
	for a in team:a.frozen=value
	for s in carriers:s.paused=value
	for q in queues:q.enabled=not value
func _notification(what):
	if what==NOTIFICATION_APPLICATION_FOCUS_OUT and is_instance_valid(player):set_pause(true)
func _input(e):
	if automatic:return
	if e is InputEventKey:
		if e.echo:return
		if e.pressed and e.keycode==KEY_ESCAPE:set_pause(not paused);return
		if paused:return
		keys[e.keycode]=e.pressed
		if e.pressed and e.keycode==KEY_TAB:build("party" if mode=="solo" else "solo")
		if mode=="party" and e.pressed:
			if e.keycode==KEY_E:begin_party(1)
			if e.keycode==KEY_R:begin_party(-1)
	elif not paused:router.consume(e)
func _physics_process(delta):
	if not is_instance_valid(player):return
	if not paused:
		if mode=="solo" and not driver:
			player.input_axis=clampf(float(keys.get(KEY_RIGHT,false) or keys.get(KEY_D,false))-float(keys.get(KEY_LEFT,false) or keys.get(KEY_A,false))+router.axis,-1,1)
			var jumping=keys.get(KEY_SPACE,false) or keys.get(KEY_UP,false) or keys.get(KEY_W,false) or router.jump_held
			player.jump_request=jumping and not last_jump;player.jump_held=jumping;last_jump=jumping
		if mode=="party" and active_queue>=0:
			var q=queues[active_queue];q.update(delta)
			if q.phase=="done":
				seam_times.append(q.arrival_times.duplicate());var following=active_queue+route_side
				if following in [0,1]:
					active_queue=following
					if not queues[active_queue].begin(route_side):party_stage="error";active_queue=-1
				else:party_stage="done";active_queue=-1
			elif q.phase=="error":party_stage="error";active_queue=-1
	if mode=="party" and is_instance_valid(basket):basket.position.x=-42 if team[1].anim.flip_h else 42
	status.text="Duraklatıldı · Esc ile devam" if paused else ("Serbest kontrol · İki taşıyıcı ve güvenli alt yol" if mode=="solo" else "Ekip provası · "+("İki geçit tamamlandı" if party_stage=="done" else "Geçit %d / 2"%(active_queue+1) if active_queue>=0 else "E ile başla"))
	if last_positions.size()==team.size():
		for i in team.size():observed_max_step=maxf(observed_max_step,team[i].position.distance_to(last_positions[i]))
	last_positions=team.map(func(a):return a.position)
	if mode=="party":
		for s in carriers:
			var riders=0
			for a in team:
				if s.is_riding(a):riders+=1
			observed_max_riders=maxi(observed_max_riders,riders)
		for i in team.size():
			for j in range(i+1,team.size()):observed_min_spacing=minf(observed_min_spacing,team[i].position.distance_to(team[j].position))
func begin_party(side:int) -> bool:
	if paused or mode!="party" or active_queue>=0 or side not in [-1,1]:return false
	var start_index=0 if side>0 else 1
	for s in carriers:
		if not s.at_end(0 if side>0 else 1):return false
	if not queues[start_index].begin(side):return false
	route_side=side;active_queue=start_index;party_stage="crossing";seam_times.clear();return true
func update_camera(immediate:bool):
	var target_x=player.position.x
	var framing_min=-INF
	var framing_max=INF
	if mode=="party":
		var low=team[0].position.x;var high=low
		for a in team:low=minf(low,a.position.x);high=maxf(high,a.position.x)
		target_x=(low+high)/2
	var target=Vector2(clampf(target_x,620,2240),clampf(player.position.y-80,455,615))
	for e in EDGES:
		if player.position.y<650 and player.position.x>e.x-220 and player.position.x<e.y+220:target.x=(e.x+e.y)/2
	if mode=="party":
		# Shore framing must not crop the tail of the physically waiting party.
		var low=team[0].position.x;var high=low
		for a in team:low=minf(low,a.position.x);high=maxf(high,a.position.x)
		var half_width=get_viewport_rect().size.x/(2.0*camera.zoom.x)
		if high-low+240<half_width*2:
			framing_min=high+120-half_width;framing_max=low-120+half_width
			target.x=clampf(target.x,framing_min,framing_max)
	camera.position=target if immediate else camera.position.lerp(target,0.13)
	camera.position.x=clampf(camera.position.x,framing_min,framing_max)
func ticks(n:int):
	for i in n:await get_tree().physics_frame
func check(ok:bool,id:String,detail={}):
	print(("PASS: " if ok else "FAIL: ")+id+" "+JSON.stringify(detail));results.append({"id":id,"ok":ok,"detail":detail})
	if not ok:failures.append(id)
func steer_to(x:float):player.input_axis=clampf((x-player.position.x)/35.0,-1,1)
func walk_to(x:float,limit=360) -> bool:
	for i in limit:
		steer_to(x);await ticks(1)
		if absf(player.position.x-x)<4 and absf(player.velocity.x)<5:player.input_axis=0;return true
	player.input_axis=0;return false
func cross_solo(index:int,side:int) -> bool:
	var s=carriers[index];var e=EDGES[index]
	if not await walk_to(e.x-35 if side>0 else e.y+35):return false
	for f in 800:
		await ticks(1)
		if absf(s.position.x-(s.start.x if side>0 else s.finish.x))<1 and s.dwell>0.5:break
	for f in 240:
		steer_to(s.position.x);await ticks(1)
		if s.is_riding(player) and absf(player.position.x-s.position.x)<8:break
	player.input_axis=0
	if not s.is_riding(player):return false
	for f in 600:
		await ticks(1)
		if absf(s.position.x-(s.finish.x if side>0 else s.start.x))<1:return await walk_to(e.y+80 if side>0 else e.x-80)
	return false
func test_solo():
	await ticks(40);print("V15 SOLO VIDEO READY")
	check(BANKS[1].y>=550,"middle_island_team_budget",{"width":BANKS[1].y})
	for i in 2:
		check(await cross_solo(i,1),"solo_forward_"+str(i),{"position":str(player.position)});await capture("solo-forward-"+str(i))
	for i in [1,0]:check(await cross_solo(i,-1),"solo_reverse_"+str(i),{"position":str(player.position)})
	await walk_to(650)
	for i in 600:
		await ticks(1)
		if carriers[0].fraction>0.95:carriers[0].paused=true;break
	player.input_axis=1;await ticks(38);player.input_axis=0;await ticks(90)
	check(player.is_on_floor() and player.position.y>800 and player.position.y<900,"fall_reaches_lower_return_path",{"position":str(player.position)});await capture("lower-return-path")
	carriers[0].paused=false
	check(await walk_to(200),"return_path_walks_under_upper_bank")
	for target in [Vector2(200,790),Vector2(340,705),Vector2(220,620),Vector2(360,540)]:
		player.jump_request=true;player.jump_held=true
		for f in 100:
			steer_to(target.x);await ticks(1)
			if f>10 and player.is_on_floor() and absf(player.position.y-target.y)<5:break
		player.jump_held=false;player.input_axis=0
		check(player.is_on_floor() and absf(player.position.y-target.y)<5,"recovery_step_"+str(target.y),{"position":str(player.position)})
	await capture("recovered-on-bank")
	var before=team.map(func(a):return a.position);var phases=carriers.map(func(s):return s.fraction)
	set_pause(true);await ticks(35)
	check(before==team.map(func(a):return a.position) and phases==carriers.map(func(s):return s.fraction),"solo_pause_freezes_world")
	set_pause(false);check(player.input_axis==0 and not player.jump_held and not player.jump_request,"resume_clears_input")
	check(observed_max_step<16,"no_checkpoint_teleport_on_lower_route",{"max_step":observed_max_step});finish("solo")
func test_party():
	await ticks(40);print("V15 PARTY VIDEO READY")
	check(not begin_party(-1),"wrong_initial_direction_rejected")
	for side in [1,-1]:
		check(begin_party(side),"party_begin_"+str(side));await ticks(95)
		set_pause(true);var points=team.map(func(a):return a.position);var phases=carriers.map(func(s):return s.fraction);await ticks(30)
		check(points==team.map(func(a):return a.position) and phases==carriers.map(func(s):return s.fraction),"party_pause_"+str(side));set_pause(false)
		for f in 5000:
			await ticks(1)
			if party_stage in ["done","error"]:break
		check(party_stage=="done","party_two_carriers_"+str(side),{"stage":party_stage,"times":seam_times})
		for i in seam_times.size():check(seam_times[i].size()==4 and seam_times[i][3]-seam_times[i][0]<=10,"party_wait_"+str(side)+"_"+str(i),{"times":seam_times[i]})
		await ticks(180);check(team.all(func(a):return absf(a.velocity.x)<5),"party_done_stays_parked_"+str(side))
		check(not begin_party(side),"wrong_done_direction_rejected_"+str(side));await capture("party-bank-"+str(side))
	check(observed_max_riders==1,"one_passenger_on_each_carrier",{"max":observed_max_riders})
	check(observed_min_spacing>=105,"middle_transfer_spacing",{"minimum":observed_min_spacing})
	check(observed_max_step<=6,"party_no_teleport",{"max_step":observed_max_step});finish("party")
func capture(name:String):
	if not "--route-capture" in OS.get_cmdline_user_args():return
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://preproduction/qa/v15/"+name+".webp")
func finish(label:String):
	var f=FileAccess.open("res://preproduction/qa/v15/"+label+"-results.json",FileAccess.WRITE);f.store_string(JSON.stringify({"results":results,"failures":failures},"\t"));f.close()
	print("V15 "+label+" "+("PASSED" if failures.is_empty() else "FAILED"));get_tree().quit(0 if failures.is_empty() else 1)
