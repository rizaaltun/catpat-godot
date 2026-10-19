extends Node2D
## One geometry source for rendering, collision, checkpoint and route design.
const WIDTH=4200.0
const SURFACES=[Rect2(0,580,540,440),Rect2(630,540,330,480),Rect2(1050,490,340,530),Rect2(1480,540,300,480),Rect2(1870,480,260,540),Rect2(2220,530,330,490),Rect2(2640,470,340,550),Rect2(3070,530,300,490),Rect2(3460,570,740,450)]
const PERCH=Rect2(1910,400,180,24)
const LANTERNS=[Vector2(1190,490),Vector2(2000,400),Vector2(2720,380)]
const MOTES=[Vector2(580,440),Vector2(1190,330),Vector2(1825,370),Vector2(2600,365),Vector2(3410,425)]
var bridges_open=false
var bridges: Array=[]
var soil: Texture2D
var branch: Texture2D
func _ready():
	z_index=-5
	soil=load("res://assets/chapter-v5/platform.png")
	branch=load("res://assets/chapter-v6/branch.png")
	for surface in SURFACES:add_surface(surface,false)
	add_surface(PERCH,true)
	for x in [1940.0,2060.0]:
		var vine=Sprite2D.new();vine.texture=load("res://assets/chapter-v8/vine.png")
		vine.position=Vector2(x,180);vine.scale=Vector2(0.065,440.0/vine.texture.get_height());add_child(vine)
	build_return_bridges()
	queue_redraw()
func add_surface(surface: Rect2, one_way: bool):
	var body=StaticBody2D.new();body.collision_layer=1;add_child(body)
	var collider=CollisionShape2D.new();var shape=RectangleShape2D.new();shape.size=surface.size;collider.shape=shape
	collider.position=surface.position+surface.size/2;collider.one_way_collision=one_way;collider.one_way_collision_margin=6
	body.add_child(collider)
func ground_y(x: float) -> float:
	for s in SURFACES:
		if x>=s.position.x and x<=s.end.x:return s.position.y
	if bridges_open:
		for i in range(SURFACES.size()-1):
			var a=Vector2(SURFACES[i].end.x,SURFACES[i].position.y)
			var b=SURFACES[i+1].position
			if x>=a.x and x<=b.x:return lerpf(a.y,b.y,(x-a.x)/(b.x-a.x))
	return 1100.0
func safe_anchor(x: float) -> Vector2:
	var best=Vector2(190,580);var distance=INF
	for s in SURFACES:
		var candidate=Vector2(clampf(x,s.position.x+65,s.end.x-65),s.position.y)
		if absf(candidate.x-x)<distance:best=candidate;distance=absf(candidate.x-x)
	return best
func surface_index(x: float) -> int:
	for i in SURFACES.size():
		if x>=SURFACES[i].position.x and x<=SURFACES[i].end.x:return i
	return -1
func _draw():
	if not soil:return
	var scale_factor=0.6
	for s in SURFACES:
		# One uninterrupted image region per island. The soil's bottom stays below the viewport.
		draw_texture_rect_region(soil,Rect2(s.position.x,s.position.y-60,s.size.x,338.4),Rect2(160,160,s.size.x/scale_factor,564))
	if branch:
		# Anchors are measured from the full branch asset; no character cropping.
		draw_texture_rect(branch,Rect2(PERCH.position-Vector2(18.6,31),branch.get_size()*0.1),false)

func build_return_bridges():
	for i in range(SURFACES.size()-1):
		var a=Vector2(SURFACES[i].end.x,SURFACES[i].position.y)
		var b=SURFACES[i+1].position
		var body=StaticBody2D.new();body.collision_layer=0;add_child(body)
		var collision=CollisionPolygon2D.new()
		collision.polygon=PackedVector2Array([a,b,b+Vector2(0,24),a+Vector2(0,24)]);body.add_child(collision)
		var art=Sprite2D.new();art.texture=load("res://assets/chapter-v9/bridge.png");art.centered=false;art.rotation=(b-a).angle()
		var scale_factor=a.distance_to(b)/1730.0
		art.scale=Vector2.ONE*scale_factor
		art.position=a-Vector2(75,389).rotated(art.rotation)*scale_factor
		body.add_child(art);body.visible=false;bridges.append(body)
func set_bridges(open: bool):
	if bridges_open==open:return
	bridges_open=open
	for body in bridges:
		body.visible=open;body.set_deferred("collision_layer",1 if open else 0)
