extends AnimatableBody2D
## One-way carrier. CharacterBody2D alone owns passenger displacement.
const LEFT=2700.0
const RIGHT=2860.0
const TOP=380.0
const WIDTH=180.0
const SPEED=50.0
const DWELL=0.6
var direction=1.0
var dwell=DWELL
var enabled=false
var travelled=0.0
var reversals=0
var branch: Texture2D
var vines: Array[Sprite2D]=[]
func _ready():
	process_physics_priority=-10
	collision_layer=1;collision_mask=0;sync_to_physics=true
	position=Vector2(LEFT,TOP);z_index=-3
	var shape=CollisionShape2D.new();var rect=RectangleShape2D.new();rect.size=Vector2(WIDTH,18)
	shape.shape=rect;shape.position.y=9;shape.one_way_collision=true;shape.one_way_collision_margin=6;add_child(shape)
	branch=load("res://assets/chapter-v6/branch.png")
	if ResourceLoader.exists("res://assets/chapter-v8/vine.png"):
		for i in 2:
			var vine=Sprite2D.new();vine.texture=load("res://assets/chapter-v8/vine.png");vine.z_index=-1;add_child(vine);vines.append(vine)
	update_vines();queue_redraw()
func update_vines():
	for i in vines.size():
		var anchor=Vector2(2720 if i==0 else 2840,-40)-position
		var end=Vector2(-62 if i==0 else 62,4)
		vines[i].position=(anchor+end)/2
		vines[i].rotation=(end-anchor).angle()-PI/2
		vines[i].scale=Vector2(0.065,anchor.distance_to(end)/vines[i].texture.get_height())
func _physics_process(delta):
	if not enabled:return
	if dwell>0:dwell=maxf(0,dwell-delta);return
	var next=move_toward(position.x,RIGHT if direction>0 else LEFT,SPEED*delta)
	travelled+=absf(next-position.x);position.x=next
	if is_equal_approx(position.x,RIGHT if direction>0 else LEFT):direction*=-1;dwell=DWELL;reversals+=1
	update_vines()
func is_riding(actor) -> bool:
	if not actor.is_on_floor():return false
	for i in actor.get_slide_collision_count():
		var collision=actor.get_slide_collision(i)
		if collision.get_collider()==self and collision.get_normal().y<-0.5:return true
	return false
func reset_phase():
	position=Vector2(LEFT,TOP);direction=1;dwell=DWELL;travelled=0;reversals=0;update_vines()
func _draw():
	if branch:draw_texture_rect(branch,Rect2(Vector2(-108.6,-31),branch.get_size()*0.1),false)
