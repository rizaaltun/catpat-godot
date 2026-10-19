extends Node2D
const WIDTH=4000.0
const HUB=Rect2(0,540,1150,500)
const EXIT=Rect2(3000,540,1000,500)
const LOWER=[Rect2(1220,580,190,400),Rect2(1530,640,190,400),Rect2(1850,580,220,400),Rect2(2190,600,240,400)]
const UPPER=[Rect2(1070,450,160,24),Rect2(1340,360,180,24),Rect2(1620,320,240,24)]
const BRIDGE=Rect2(1150,540,1850,26)
var bridge_body: StaticBody2D
var deck: Node2D
var ready_bridge=false
var bank: Texture2D
var rock: Texture2D
var branch: Texture2D
var bridge_art: Sprite2D
var bridge_material: ShaderMaterial
func _ready():
	z_index=-5
	bank=load("res://assets/chapter-v11/bank.png");rock=load("res://assets/chapter-v13/garden-rock.png");branch=load("res://assets/chapter-v6/branch.png")
	for s in [HUB,EXIT]+LOWER:add_surface(s,false)
	for s in UPPER:
		add_surface(s,true)
		for x in [s.position.x+25,s.end.x-25]:
			var vine=Sprite2D.new();vine.texture=load("res://assets/chapter-v8/vine.png")
			vine.position=Vector2(x,(s.position.y-40)/2);vine.scale=Vector2(0.055,(s.position.y+40)/vine.texture.get_height());add_child(vine)
	bridge_body=add_surface(BRIDGE,false);bridge_body.collision_layer=0
	deck=Node2D.new();add_child(deck)
	bridge_art=Sprite2D.new();bridge_art.texture=load("res://assets/chapter-v13/garden-walkway.png");bridge_art.centered=false
	bridge_art.scale=Vector2.ONE*BRIDGE.size.x/2080.0
	bridge_art.position=BRIDGE.position-Vector2(45,295)*bridge_art.scale
	var shader=Shader.new()
	shader.code="shader_type canvas_item; uniform float progress = 1.0; void fragment(){ if(UV.x > progress) COLOR.a = 0.0; }"
	bridge_material=ShaderMaterial.new();bridge_material.shader=shader;bridge_art.material=bridge_material
	deck.add_child(bridge_art)
	deck.visible=false;queue_redraw()
func add_surface(s: Rect2, one_way: bool) -> StaticBody2D:
	var body=StaticBody2D.new();body.collision_layer=1;add_child(body)
	var c=CollisionShape2D.new();var shape=RectangleShape2D.new();shape.size=s.size;c.shape=shape;c.position=s.get_center();c.one_way_collision=one_way;c.one_way_collision_margin=6;body.add_child(c)
	return body
func set_bridge(value: bool):
	ready_bridge=value;deck.visible=value;bridge_body.collision_layer=1 if value else 0
func set_build_progress(fraction: float):
	if ready_bridge:return
	# Assembly preview is ghosted and has no collision until durable ready.
	deck.visible=fraction>0
	bridge_material.set_shader_parameter("progress",clampf(fraction,0,1))
	bridge_art.modulate=Color(1,1,1,0.48)
func finish_build_visual():
	bridge_material.set_shader_parameter("progress",1.0)
	bridge_art.modulate=Color.WHITE
func _draw():
	if not bank:return
	for s in [HUB,EXIT]:draw_surface(bank,s,Vector2(30,160),2110.0)
	for s in LOWER:draw_surface(rock,s,Vector2(45,275),925.0)
	for s in UPPER:
		var factor=s.size.x/1800.0
		draw_texture_rect(branch,Rect2(s.position-Vector2(186,310)*factor,branch.get_size()*factor),false)
func draw_surface(texture: Texture2D, surface: Rect2, anchor: Vector2, source_width: float):
	var factor=surface.size.x/source_width
	draw_texture_rect(texture,Rect2(surface.position-anchor*factor,texture.get_size()*factor),false)
