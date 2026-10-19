extends "res://scripts/actor.gd"
## Full independent source images, explicit anatomical origin; no cell or alpha crop.
var route_target=Vector2.ZERO
var route_moving=false
var route_air_direction=0.0
var debug_route=false
var route_carrier=false
var route_walk_only=false

func _ready():
	super._ready()
	platform_on_leave=CharacterBody2D.PLATFORM_ON_LEAVE_DO_NOTHING
	floor_snap_length=18.0
	floor_max_angle=deg_to_rad(58)
	floor_constant_speed=true

var motion_time := 0.0
var impact := 0.0
var grounded_before := false
func _build_frames():
	var cat = character_id == "catpat"
	var files = ["res://assets/review-v2/%s-idle-r2.webp" % character_id]
	for pose in ["a","pass","b"]:
		files.append("res://assets/polish-v3/%s-%s.webp" % [character_id,pose])
	files.append("res://assets/polish-v3/catpat-jump.webp" if cat else files[2])
	var roots = [Vector2(670,1200),Vector2(700,1210),Vector2(670,1200),Vector2(685,1210),Vector2(665,1200)] if cat else [Vector2(925,1070),Vector2(925,1070),Vector2(925,1070),Vector2(925,1070),Vector2(925,1070)]
	var frames = SpriteFrames.new()
	frames.remove_animation("default")
	var images: Array = []
	for i in range(files.size()):
		var tex = load(files[i])
		var a = AtlasTexture.new()
		a.atlas = tex
		a.region = Rect2(Vector2.ZERO,tex.get_size())
		a.margin = Rect2(Vector2(950,1400)-roots[i],Vector2(2000,1700)-tex.get_size())
		images.append(a)
	for key in {"idle":[0],"run":[1,2,3,2],"jump":[4],"fall":[4],"launch":[2],"celebrate":[0,4,0]}:
		frames.add_animation(key)
		frames.set_animation_speed(key,8 if key=="run" else 3)
		for i in {"idle":[0],"run":[1,2,3,2],"jump":[4],"fall":[4],"launch":[2],"celebrate":[0,4,0]}[key]:
			frames.add_frame(key,images[i])
	anim.sprite_frames = frames
	anim.scale = Vector2.ONE*0.125
	anim.position = (Vector2(1000,850)-Vector2(950,1400))*0.125
	anim.flip_h = true

func _physics_process(delta):
	if frozen:
		input_axis=0;jump_request=false;jump_buffer=0;anim.play("idle");return
	# Route-driven companion uses the shared physical controller, never parent teleport AI.
	if recruited and not controlled:
		controlled=true
		input_axis=signf(route_target.x-position.x) if route_moving and absf(route_target.x-position.x)>8 else 0.0
		if is_on_floor():route_air_direction=0.0
		elif route_air_direction!=0 and not route_carrier:input_axis=route_air_direction
		jump_held=true
		var edge_ahead=false
		if route_moving and is_on_floor() and input_axis!=0:
			var origin=global_position+Vector2(input_axis*48,-15)
			var query=PhysicsRayQueryParameters2D.create(origin,origin+Vector2(0,100),1)
			edge_ahead=get_world_2d().direct_space_state.intersect_ray(query).is_empty()
		if route_carrier:
			jump_request=route_moving and is_on_floor() and route_target.y<position.y-50 and absf(route_target.x-position.x)<72
		else:jump_request=not route_walk_only and route_moving and is_on_floor() and (edge_ahead or is_on_wall() or route_target.y<position.y-50)
		if jump_request:
			route_air_direction=input_axis
			if debug_route:print("FOLLOW JUMP ",position," velocity ",velocity," target ",route_target)
		grounded_before=is_on_floor()
		super._physics_process(delta)
		controlled=false
	else:
		grounded_before = is_on_floor()
		super._physics_process(delta)
	motion_time += delta
	if absf(velocity.x)>10:
		anim.flip_h = velocity.x > 0

	if not grounded_before and is_on_floor():
		impact = 1.0
	impact = maxf(0,impact-delta*7)
	# Gentle physical landing compression; limb motion remains separate image frames.
	var breath = sin(motion_time*2.5)*0.003 if anim.animation=="idle" else 0.0
	anim.scale = Vector2(0.125*(1+impact*0.035),0.125*(1-impact*0.045+breath))
