extends Node2D
const Surface=preload("res://scripts/core/moving_surface.gd")
const Queue=preload("res://scripts/core/carrier_queue.gd")
const Cat=preload("res://scripts/polish_actor.gd")
const Monkey=preload("res://scripts/monkey_actor.gd")
const Rabbit=preload("res://scripts/rabbit_actor.gd")
var surface
var team=[]
var queue
var arena: Node2D
var automatic=false
var failures=[]
var results=[]
var status: Label
var paused=false
var min_separation=10000.0
var max_riders=0
var max_step=0.0
var last_positions=[]
func _ready():
	process_physics_priority=-20
	var backdrop=Sprite2D.new();backdrop.texture=load("res://assets/chapter-v12/garden.png");backdrop.centered=false;backdrop.z_index=-30;add_child(backdrop)
	var cam=Camera2D.new();cam.position=Vector2(850,360);cam.zoom=Vector2.ONE*0.73;add_child(cam)
	arena=Node2D.new();add_child(arena)
	var ui=CanvasLayer.new();add_child(ui)
	var panel=preload("res://scripts/polish_ui.gd")
	panel.texture("res://assets/polish-v3/panel.png",Rect2(25,20,760,132),ui)
	panel.label("RÜZGÂRLI YAMAÇ  /  GEÇİŞ HAZIRLIĞI",Rect2(58,44,710,40),22,ui)
	status=panel.label("Tek taşıyıcı · Dört arkadaş · Sırayla geçiş",Rect2(58,82,705,48),22,ui)
	panel.label("Çalışma sahnesi · E: karşıya geç · R: geri dön · Esc: duraklat",Rect2(175,655,1000,45),20,ui)
	automatic="--carrier-test" in OS.get_cmdline_user_args() or "--queue-test" in OS.get_cmdline_user_args()
	build_queue()
	if "--carrier-test" in OS.get_cmdline_user_args():call_deferred("measure_surfaces")
	elif "--queue-test" in OS.get_cmdline_user_args():call_deferred("measure_queue")
func make_actor(id: String):
	var a=Rabbit.new() if id=="rabbit" else Monkey.new() if id=="monkey" else Cat.new()
	a.character_id=id;a.controlled=true;arena.add_child(a);surface.bind_rider(a);return a
func clear_arena():
	queue=null;team.clear();last_positions.clear()
	for c in arena.get_children():arena.remove_child(c);c.queue_free()
func bank(x: float,w: float):
	var body=StaticBody2D.new();arena.add_child(body)
	var collision=CollisionShape2D.new();var shape=RectangleShape2D.new();shape.size=Vector2(w,500);collision.shape=shape;collision.position=Vector2(x+w/2,790);body.add_child(collision)
	var image=Sprite2D.new();image.texture=load("res://assets/chapter-v11/bank.png");image.centered=false;image.scale=Vector2.ONE*w/2110.0;image.position=Vector2(x,540)-Vector2(30,160)*image.scale;image.z_index=-5;arena.add_child(image)
func build_queue():
	clear_arena();bank(0,700);bank(1040,660)
	surface=Surface.new();surface.speed=200;surface.dwell_seconds=0.12;surface.auto_cycle=false;arena.add_child(surface)
	for i in 4:
		var a=make_actor(["catpat","rabbit","badger","monkey"][i]);a.position=Vector2(600-i*140,539);a.checkpoint=a.position;team.append(a)
	queue=Queue.new();queue.configure(surface,team)
func _physics_process(delta):
	if queue:
		queue.update(delta)
		if queue.phase not in ["idle","done"]:
			status.text="Arkadaşların geçiyor · %d / 4"%queue.completed.size()
		elif queue.phase=="done":status.text="Dördü de karşıda · Geri dönüş hazır"
	if team.size()==4 and queue:
		var riders=0
		for a in team:
			if surface.is_riding(a):riders+=1
		max_riders=max(max_riders,riders)
		for i in 4:
			for j in range(i+1,4):min_separation=minf(min_separation,team[i].position.distance_to(team[j].position))
		if last_positions.size()==4:
			for i in 4:max_step=maxf(max_step,team[i].position.distance_to(last_positions[i]))
		last_positions=team.map(func(a):return a.position)
func _unhandled_key_input(e):
	if not e.pressed or e.echo or automatic:return
	if e.keycode==KEY_E:queue.begin(1)
	if e.keycode==KEY_R:queue.begin(-1)
	if e.keycode==KEY_ESCAPE:set_pause(not paused)
func _notification(what):
	if what==NOTIFICATION_APPLICATION_FOCUS_OUT and queue:set_pause(true)
func set_pause(value: bool):
	paused=value
	if queue:queue.set_paused(value)
func ticks(n: int):
	for i in n:await get_tree().physics_frame
func check(ok: bool,title: String,detail={}):
	print(("PASS: " if ok else "FAIL: ")+title+" "+JSON.stringify(detail))
	results.append({"id":title,"ok":ok,"detail":detail.duplicate(true)})
	if not ok:failures.append(title)
func measure_surfaces():
	await ticks(5)
	for route in [Vector2(160,0),Vector2(0,-100),Vector2(120,-80)]:
		for id in ["catpat","rabbit","badger","monkey"]:
			for rep in 10:
				clear_arena();surface=Surface.new();surface.start=Vector2(700,540);surface.finish=surface.start+route;surface.speed=100;arena.add_child(surface)
				var a=make_actor(id);a.position=surface.start-Vector2(0,60);a.checkpoint=Vector2(700,850)
				await ticks(40)
				var landed=surface.is_riding(a);var offset=a.position-surface.position;var drift=0.0;var grounded=true
				surface.enabled=true
				for f in 290:
					await ticks(1);drift=maxf(drift,(a.position-surface.position-offset).length());grounded=grounded and surface.is_riding(a)
				check(landed and grounded and drift<=2.0 and surface.reversals>=2,"ride_"+str(route)+"_"+id+"_"+str(rep),{"drift":drift,"reversals":surface.reversals})
				if rep==0:
					surface.paused=true;a.frozen=true;var pos=a.position;var sp=surface.position;var snapshot=surface.snapshot()
					await ticks(30);check(a.position==pos and surface.position==sp,"pause_"+str(route)+"_"+id)
					var parsed=JSON.parse_string(JSON.stringify(snapshot));check(surface.restore(parsed),"phase_json_restore_"+str(route)+"_"+id)
					surface.paused=false;a.frozen=false;await ticks(8)
					a.jump_held=true;a.jump_request=true;await ticks(8)
					check(not surface.is_riding(a) and absf(a.velocity.x)<0.01,"jump_no_inherited_x_"+str(route)+"_"+id,{"vx":a.velocity.x})
	var prior=surface.snapshot();var invalid=prior.duplicate();invalid.fraction=1.5
	check(not surface.restore(invalid) and surface.snapshot()==prior,"invalid_phase_no_mutation")
	finish("surface")
func measure_queue():
	await ticks(40);queue.begin(1);print("V14 QUEUE VIDEO READY")
	await ticks(95);set_pause(true);var sp=surface.position;var positions=team.map(func(a):return a.position)
	await ticks(35);check(surface.position==sp and team.map(func(a):return a.position)==positions,"queue_pause_freezes_everyone")
	set_pause(false)
	for i in 2400:
		await ticks(1)
		if queue.phase in ["done","error"]:break
	check(queue.phase=="done","four_actors_reach_right",{"phase":queue.phase,"elapsed":queue.elapsed,"arrivals":queue.arrival_times})
	check(max_riders==1,"one_passenger_reservation",{"max":max_riders})
	check(min_separation>=105,"distinct_waiting_and_exit_slots",{"min":min_separation})
	check(max_step<=6,"no_teleport_in_queue",{"max_step":max_step})
	if queue.arrival_times.size()==4:check(queue.arrival_times[3]-queue.arrival_times[0]<=10,"party_wait_under_ten_seconds",{"wait":queue.arrival_times[3]-queue.arrival_times[0]})
	await capture("right-bank")
	await ticks(120)
	check(queue.begin(-1),"reverse_queue_requested")
	for i in 2400:
		await ticks(1)
		if queue.phase in ["done","error"]:break
	check(queue.phase=="done","four_actors_return_left",{"phase":queue.phase,"elapsed":queue.elapsed,"arrivals":queue.arrival_times})
	check(max_riders==1 and min_separation>=105 and max_step<=6,"reverse_keeps_reservation_and_spacing",{"min":min_separation,"max_step":max_step,"riders":max_riders})
	await capture("left-bank")
	await ticks(90)
	finish("queue")
func capture(label: String):
	if "--carrier-capture" not in OS.get_cmdline_user_args():return
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://preproduction/qa/v14/"+label+".png")
func finish(name: String):
	var file=FileAccess.open("res://preproduction/qa/v14/"+name+"-results.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"results":results,"failures":failures},"\t"));file.close()
	print("V14 "+name+" "+("PASSED" if failures.is_empty() else "FAILED"))
	get_tree().quit(0 if failures.is_empty() else 1)
