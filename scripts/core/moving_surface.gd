extends StaticBody2D
## Reusable carrier. SurfaceRider exclusively owns carry on collision layer 4.
var start=Vector2(790,540)
var finish=Vector2(950,540)
var width=180.0
var speed=100.0
var dwell_seconds=0.4
var auto_cycle=true
var enabled=false
var fraction=0.0
var direction=1
var dwell=0.0
var reversals=0
var travelled=0.0
var paused=false
var motion_delta=Vector2.ZERO
var vines: Array[Sprite2D]=[]
var art: Sprite2D
func _ready():
	process_physics_priority=10
	collision_layer=4;collision_mask=0;z_index=-3
	position=start.lerp(finish,fraction)
	var collider=CollisionShape2D.new();var shape=RectangleShape2D.new();shape.size=Vector2(width,18)
	collider.shape=shape;collider.position.y=9;collider.one_way_collision=true;collider.one_way_collision_margin=6;add_child(collider)
	art=Sprite2D.new();art.texture=load("res://assets/chapter-v6/branch.png");art.centered=false
	art.scale=Vector2.ONE*width/1800.0;art.position=Vector2(-width/2,0)-Vector2(186,310)*art.scale;add_child(art)
	for i in 2:
		var vine=Sprite2D.new();vine.texture=load("res://assets/chapter-v8/vine.png");vine.z_index=-1;add_child(vine);vines.append(vine)
	update_vines()
func _physics_process(delta):
	motion_delta=Vector2.ZERO
	if paused or not enabled:return
	if dwell>0:dwell=maxf(0,dwell-delta);return
	var distance=start.distance_to(finish)
	if distance<0.001:return
	var old=fraction
	fraction=move_toward(fraction,1.0 if direction>0 else 0.0,speed*delta/distance)
	var previous=position
	position=start.lerp(finish,fraction);motion_delta=position-previous;travelled+=absf(fraction-old)*distance
	update_vines()
	if fraction==0.0 or fraction==1.0:
		direction=-direction;reversals+=1;dwell=dwell_seconds
		if not auto_cycle:enabled=false
func depart():
	if not paused:enabled=true
func at_end(end: int) -> bool:
	return absf(fraction-float(end))<0.00001 and not enabled
func is_riding(actor) -> bool:
	if not actor.is_on_floor():return false
	for i in actor.get_slide_collision_count():
		var c=actor.get_slide_collision(i)
		if c.get_collider()==self and c.get_normal().y < -0.5:return true
	return false
func snapshot() -> Dictionary:
	return {"fraction":fraction,"direction":direction,"dwell":dwell,"enabled":enabled}
func valid_snapshot(d: Dictionary) -> bool:
	if not d.has_all(["fraction","direction","dwell","enabled"]):return false
	if typeof(d.fraction) not in [TYPE_FLOAT,TYPE_INT] or typeof(d.dwell) not in [TYPE_FLOAT,TYPE_INT]:return false
	if not is_finite(float(d.fraction)) or not is_finite(float(d.dwell)):return false
	if d.fraction<0 or d.fraction>1 or d.dwell<0 or d.dwell>dwell_seconds:return false
	if d.direction!=1 and d.direction!=-1:return false
	return typeof(d.enabled)==TYPE_BOOL
func restore(d: Dictionary) -> bool:
	if not valid_snapshot(d):return false
	motion_delta=Vector2.ZERO
	fraction=float(d.fraction);direction=int(d.direction);dwell=float(d.dwell);enabled=d.enabled
	# Restore is used only while the caller freezes the entire scene.
	position=start.lerp(finish,fraction);update_vines()
	return true

func bind_rider(actor):
	for child in actor.get_children():
		if child.get_script()==preload("res://scripts/core/surface_rider.gd") and child.surface==self:return child
	var rider=preload("res://scripts/core/surface_rider.gd").new()
	rider.surface=self;rider.actor=actor
	actor.collision_mask=actor.collision_mask|4
	actor.platform_floor_layers=actor.platform_floor_layers&~4
	actor.add_child(rider)
	return rider

func update_vines():
	for i in vines.size():
		var side=-1.0 if i==0 else 1.0
		var anchor=Vector2((start.x+finish.x)/2+side*width*0.36,minf(start.y,finish.y)-650)-position
		var end=Vector2(side*width*0.36,0)
		vines[i].position=(anchor+end)/2;vines[i].rotation=(end-anchor).angle()-PI/2
		vines[i].scale=Vector2(0.045,anchor.distance_to(end)/vines[i].texture.get_height())
