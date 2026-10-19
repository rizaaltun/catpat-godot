extends Node2D
## Executable graybox/measurement scene. Uses the actual V4 player; no copied physics.
const Actor = preload("res://scripts/polish_actor.gd")
var player
var cam: Camera2D
var solids: Node2D
var ui: CanvasLayer
var automatic=false
var results=[]
var failures=[]
var tick=0

func _ready():
	solids=Node2D.new();add_child(solids)
	player=Actor.new();player.controlled=true;player.position=Vector2(120,600);player.checkpoint=player.position;add_child(player)
	cam=Camera2D.new();cam.position=Vector2(0,-240);cam.limit_left=0;cam.limit_right=5000;cam.limit_top=0;cam.limit_bottom=720
	cam.process_callback=Camera2D.CAMERA2D_PROCESS_PHYSICS
	cam.position_smoothing_enabled=true;cam.position_smoothing_speed=5;player.add_child(cam)
	ui=CanvasLayer.new();add_child(ui)
	var title=Label.new();title.position=Vector2(25,20);title.add_theme_font_size_override("font_size",23);title.text="HAREKET PARKURU · Teknik blok testi\n← → / A D: yürü · Boşluk: zıpla · R: başa dön";ui.add_child(title)
	for action in ["lab_left","lab_right","lab_jump","lab_reset"]:
		if not InputMap.has_action(action):InputMap.add_action(action)
	for pair in [["lab_left",KEY_LEFT],["lab_left",KEY_A],["lab_right",KEY_RIGHT],["lab_right",KEY_D],["lab_jump",KEY_SPACE],["lab_reset",KEY_R]]:
		var ev=InputEventKey.new();ev.physical_keycode=pair[1];InputMap.action_add_event(pair[0],ev)
	build_course()
	automatic="--measure" in OS.get_cmdline_user_args() or "--envelope" in OS.get_cmdline_user_args() or "--edges" in OS.get_cmdline_user_args()
	if "--measure" in OS.get_cmdline_user_args():call_deferred("measure")
	if "--envelope" in OS.get_cmdline_user_args():call_deferred("measure_envelope")
	if "--edges" in OS.get_cmdline_user_args():call_deferred("measure_edges")
	if "--lab-capture" in OS.get_cmdline_user_args():call_deferred("capture_course")

func _physics_process(_delta):
	if not automatic:
		player.input_axis=Input.get_axis("lab_left","lab_right")
		player.jump_held=Input.is_action_pressed("lab_jump")
		if Input.is_action_just_pressed("lab_jump"):player.jump_request=true
		if Input.is_action_just_pressed("lab_reset"):
			player.position=Vector2(120,600);player.velocity=Vector2.ZERO;cam.reset_smoothing()

func box(x:float,y:float,w:float,h:float=240):
	var body=StaticBody2D.new();body.position=Vector2(x,y);body.collision_layer=1;solids.add_child(body)
	var collider=CollisionShape2D.new();var shape=RectangleShape2D.new();shape.size=Vector2(w,h);collider.shape=shape;collider.position=shape.size/2;body.add_child(collider)
	var visual=Polygon2D.new();visual.polygon=PackedVector2Array([Vector2(0,0),Vector2(w,0),Vector2(w,h),Vector2(0,h)]);visual.color=Color("345e55");body.add_child(visual)
	var top=Line2D.new();top.points=PackedVector2Array([Vector2(0,0),Vector2(w,0)]);top.width=4;top.default_color=Color("e8bd69");body.add_child(top)

func ramp(x:float,y:float,w:float,rise:float):
	var body=StaticBody2D.new();body.collision_layer=1;solids.add_child(body)
	var poly=PackedVector2Array([Vector2(x,y),Vector2(x+w,y-rise),Vector2(x+w,850),Vector2(x,850)])
	var collision=CollisionPolygon2D.new();collision.polygon=poly;body.add_child(collision)
	var visual=Polygon2D.new();visual.polygon=poly;visual.color=Color("345e55");body.add_child(visual)

func note(text:String,x:float,y:float):
	var label=Label.new();label.text=text;label.position=Vector2(x,y);label.add_theme_font_size_override("font_size",18);solids.add_child(label)

func clear_geometry():
	for node in solids.get_children():solids.remove_child(node);node.queue_free()

func build_course():
	clear_geometry()
	box(0,600,650);box(650,560,160);box(900,600,400);box(1430,600,400)
	box(1300,700,130);ramp(1830,600,220,120);box(2050,480,300)
	box(2430,410,240);box(2670,650,500);box(3170,580,220);box(3390,650,1500)
	note("01 · Düz zemin / hızlanma",100,455);note("02 · 40 yükselme",650,460)
	note("03 · 130 boşluk / güvenli alt yol",1190,470);note("04 · Eğim / iniş",1850,360)
	note("05 · 70 yükselme + 80 boşluk",2380,300);note("06 · Dönüş / kamera",3200,450)

func frames(n:int):
	for _i in range(n):await get_tree().physics_frame

func reset_at(pos:Vector2):
	player.position=pos;player.velocity=Vector2.ZERO;player.input_axis=0;player.jump_held=false;player.jump_request=false;player.coyote=0;player.jump_buffer=0
	player.checkpoint=pos;cam.reset_smoothing();await frames(6)

func record(id:String,ok:bool,data:Dictionary):
	data["id"]=id;data["passed"]=ok;results.append(data)
	if not ok:failures.append(id)
	print("PASS " if ok else "FAIL ",id," ",JSON.stringify(data))

func measure():
	# 10 identical repetitions each: short tap, medium hold, full hold.
	for hold in [1,8,30]:
		for rep in range(11):
			clear_geometry();box(0,600,5000);await reset_at(Vector2(120,600))
			player.input_axis=1
			if rep<10:await frames(20)
			var start=player.position;var takeoff_speed=player.velocity.x;var min_y=start.y;var airborne=false;var landed=false;var elapsed_frames=0
			player.jump_request=true
			for f in range(100):
				player.jump_held=f<hold;await frames(1);elapsed_frames+=1;min_y=minf(min_y,player.position.y)
				if not player.is_on_floor():airborne=true
				elif airborne:landed=true;break
			record("jump_%d_%02d"%[hold,rep],landed,{"hold_frames":hold,"run_up":rep<10,"takeoff_speed":takeoff_speed,"rise":snappedf(start.y-min_y,0.01),"distance":snappedf(player.position.x-start.x,0.01),"flight_frames":elapsed_frames})
	var measured_rises=[]
	for hold in [1,8,30]:
		var heights=[];var distances=[]
		for sample in results:
			if sample.get("hold_frames",0)==hold and sample.get("run_up",false):
				heights.append(sample.rise);distances.append(sample.distance)
		var spread=max(heights.max()-heights.min(),distances.max()-distances.min())
		measured_rises.append(heights[0])
		record("repeatability_%d"%hold,heights.size()==10 and spread<0.1,{"repetitions":heights.size(),"max_spread":spread})
	record("variable_jump_height",measured_rises[0]<measured_rises[1] and measured_rises[1]<measured_rises[2],{"rises":measured_rises})
	# Compound rise+gap trials use the same approach speed and takeoff point.
	for rise in [40,70,90]:
		for gap in [80,130,150,380]:
			clear_geometry();box(0,600,800);box(800+gap,600-rise,240);box(800,820,gap)
			await reset_at(Vector2(630,600));player.input_axis=1
			for _approach in range(120):
				if player.position.x>=770:break
				await frames(1)
			var actual_takeoff=player.position.x;var takeoff_speed=player.velocity.x
			player.jump_request=true;player.jump_held=true
			var reached=false
			for _f in range(100):
				await frames(1)
				if player.is_on_floor() and player.position.x>800+gap+24 and absf(player.position.y-(600-rise))<3:reached=true;break
				if player.position.y>760:break
			player.input_axis=0
			var stable=reached
			if reached:
				for _settle in range(30):
					await frames(1)
					stable=stable and player.is_on_floor() and absf(player.position.y-(600-rise))<3 and player.position.x>800+gap+19 and player.position.x<800+gap+240-19
			var expected_reachable=gap<300
			record("gap_%d_rise_%d"%[gap,rise],actual_takeoff>=770 and (stable if expected_reachable else not reached),{"gap":gap,"rise":rise,"takeoff_x":actual_takeoff,"takeoff_speed":takeoff_speed,"landing_width":240,"expected_reachable":expected_reachable,"reached":reached,"stable_30_frames":stable})
	# Up and down the actual slope without jump assistance.
	clear_geometry();box(0,600,700);ramp(700,600,220,120);box(920,480,600)
	await reset_at(Vector2(450,600));player.input_axis=1;await frames(140)
	record("slope_up",player.position.x>1000 and player.is_on_floor(),{"position":str(player.position)})
	player.input_axis=-1;await frames(150)
	record("slope_down",player.position.x<650 and player.is_on_floor(),{"position":str(player.position)})
	# Camera bounds/continuity measured during two direction changes, not image aesthetics.
	clear_geometry();box(0,600,5000);await reset_at(Vector2(1100,600));await frames(30)
	var max_step=0.0;var min_screen_x=9999.0;var max_screen_x=-9999.0;var prev=cam.get_screen_center_position().x
	for f in range(240):
		player.input_axis=1 if f<120 else -1;await frames(1)
		cam.force_update_scroll()
		var center=cam.get_screen_center_position().x
		max_step=maxf(max_step,absf(center-prev));prev=center
		var sx=player.position.x-center+640;min_screen_x=minf(min_screen_x,sx);max_screen_x=maxf(max_screen_x,sx)
	record("camera_candidate_physics_reversal",max_step<20 and min_screen_x>150 and max_screen_x<1130,{"max_center_step":max_step,"screen_x_min":min_screen_x,"screen_x_max":max_screen_x})
	var report={"engine":Engine.get_version_info().string,"physics_ticks":Engine.physics_ticks_per_second,"source":"actual polish_actor.gd V4 controller","results":results,"failed":failures,"not_tested":["Safari browser","physical iPhone","moving platforms","final character motion quality"]}
	var file=FileAccess.open("res://preproduction/qa/t02/measurements.json",FileAccess.WRITE);file.store_string(JSON.stringify(report,"\t"));file.close()
	get_tree().quit(0 if failures.is_empty() else 1)

func capture_course():
	automatic=true;player.input_axis=1
	for f in range(190):
		player.jump_held=f%65<32
		if f%65==0:player.jump_request=true
		await frames(1)
	player.input_axis=0;await frames(15)
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://preproduction/qa/t02/course.png")
	for size in [Vector2i(1024,768),Vector2i(1560,720)]:
		get_window().size=size;await frames(20)
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://preproduction/qa/t02/course_%d_%d.png"%[size.x,size.y])
	get_tree().quit()

func measure_envelope():
	var envelope=[]
	for run_up in [false,true]:
		clear_geometry();box(0,600,5000);await reset_at(Vector2(120,600))
		player.input_axis=1
		if run_up:await frames(20)
		var origin=player.position;var distances={"0":0.0,"40":0.0,"70":0.0,"90":0.0};var airborne=false
		player.jump_request=true;player.jump_held=true
		for _f in range(100):
			await frames(1)
			if not player.is_on_floor():airborne=true
			if player.velocity.y>0:
				for height in [0,40,70,90]:
					if player.position.y<=origin.y-height:distances[str(height)]=player.position.x-origin.x
			if airborne and player.is_on_floor():break
		var budgets={}
		for height in distances:
			# 70% of measured travel minus a 31-unit takeoff setback and
			# 24 units of full-foot landing margin; conservative, not a new physics claim.
			budgets[height]=floorf((float(distances[height])*0.70-31-24)/5)*5
		envelope.append({"running_start":run_up,"descending_reach":distances,"proposed_max_gap_with_margin":budgets})
	var f=FileAccess.open("res://preproduction/qa/t02/envelope.json",FileAccess.WRITE)
	f.store_string(JSON.stringify({"margin_policy":0.7,"takeoff_setback":31,"landing_margin":24,"samples":envelope},"\t"));f.close()
	print("ENVELOPE ",JSON.stringify(envelope));get_tree().quit()

func measure_edges():
	# Coyote tolerance: after leaving the real collider, early press works and late does not.
	for delay in [3,12]:
		clear_geometry();box(0,600,800);await reset_at(Vector2(700,600));player.input_axis=1
		var left_floor=false
		for _f in range(70):
			await frames(1)
			if not player.is_on_floor():left_floor=true;break
		await frames(delay);player.jump_request=true;player.jump_held=true;await frames(3)
		record("coyote_%d"%delay,left_floor and ((player.velocity.y<0) if delay==3 else (player.velocity.y>=0)),{"delay_frames":delay,"velocity_y":player.velocity.y})
	# A press shortly before touchdown buffers; an old press expires.
	for early in [false,true]:
		clear_geometry();box(0,600,2000);await reset_at(Vector2(400,300 if early else 460))
		if not early:
			for _f in range(60):
				if player.position.y>=560:break
				await frames(1)
		player.jump_request=true;player.jump_held=true
		var bounced=false
		for _f in range(65):
			await frames(1)
			if player.velocity.y<0:bounced=true;break
		record("buffer_expired" if early else "buffer_touchdown",not bounced if early else bounced,{"bounced":bounced})
	clear_geometry();box(0,600,2000);box(0,360,1200,40);await reset_at(Vector2(400,600))
	player.jump_request=true;player.jump_held=true
	var min_foot=600.0
	for _f in range(90):await frames(1);min_foot=minf(min_foot,player.position.y)
	record("ceiling_contact",min_foot>=475 and min_foot<490 and player.is_on_floor(),{"minimum_foot_y":min_foot,"landed":player.is_on_floor()})
	clear_geometry();box(0,600,2200);box(600,480,200);await reset_at(Vector2(450,600));player.input_axis=1;await frames(45)
	var wall_seen=player.is_on_wall()
	player.jump_request=true;player.jump_held=true;await frames(90)
	record("wall_corner_escape",wall_seen and player.position.x>830,{"wall_seen":wall_seen,"final_position":str(player.position)})
	# Logical framing at multiple window sizes. This is not touch/device ergonomics QA.
	for size in [Vector2i(1280,720),Vector2i(1024,768),Vector2i(1560,720)]:
		get_window().size=size;await frames(4)
		clear_geometry();box(0,600,5000);await reset_at(Vector2(1500,600));await frames(30)
		var visible=true;var max_offset=0.0
		for f in range(120):
			player.input_axis=1 if f<60 else -1;await frames(1);cam.force_update_scroll()
			var vp=get_viewport_rect().size;var delta=player.position-cam.get_screen_center_position()
			max_offset=maxf(max_offset,absf(delta.x));visible=visible and absf(delta.x)<vp.x*0.4 and absf(delta.y)<vp.y*0.45
		record("camera_size_%d_%d"%[size.x,size.y],visible,{"requested_size":str(size),"logical_viewport":str(get_viewport_rect().size),"max_horizontal_offset":max_offset})
	var f=FileAccess.open("res://preproduction/qa/t02/edges.json",FileAccess.WRITE)
	f.store_string(JSON.stringify({"results":results,"failed":failures,"scope":"real controller edges and logical camera frame; physical devices not tested"},"\t"));f.close()
	get_tree().quit(0 if failures.is_empty() else 1)
