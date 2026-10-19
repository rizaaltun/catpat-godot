extends CharacterBody2D
## Shared physics and frame animations for player and every companion.
const Profile=preload("res://scripts/core/movement_profile.gd")
const SPEED = Profile.RUN_SPEED
const ACCEL = Profile.ACCELERATION
const GRAVITY = Profile.GRAVITY
const JUMP = Profile.JUMP_VELOCITY
var character_id = "catpat"
var controlled = false
var recruited = false
var leader: Node2D
var following_distance = 95.0
var input_axis = 0.0
var jump_request = false
var jump_held = false
var frozen = false
var celebrating = false
var checkpoint = Vector2(160, 520)
var coyote = 0.0
var jump_buffer = 0.0
var follow_jump_cooldown = 0.0
var anim: AnimatedSprite2D
var frame_regions: Array[Rect2] = []

func _ready():
	collision_layer = 2
	collision_mask = 1
	var shape = CollisionShape2D.new()
	var capsule = CapsuleShape2D.new()
	capsule.radius = 19.0
	capsule.height = 76.0
	shape.shape = capsule
	shape.position.y = -38
	add_child(shape)
	anim = AnimatedSprite2D.new()
	add_child(anim)
	_build_frames()
	anim.play("idle")

func _build_frames():
	var texture = load("res://assets/animation/%s.webp" % character_id)
	var measured = JSON.parse_string(FileAccess.get_file_as_string("res://assets/animation/regions.json"))[character_id]
	var frames = SpriteFrames.new()
	frames.remove_animation("default")
	var mapping = {"run":[0,1,2,3,4,5], "idle":[6,6,6,6,6,7,6,6], "launch":[8], "jump":[9], "fall":[10], "celebrate":[11,6,11]}
	# Explicit cell atlas, generous canvas retained so frames have a stable world pivot.
	for key in mapping:
		frames.add_animation(key)
		frames.set_animation_speed(key, 11.0 if key == "run" else 4.0)
		for index in mapping[key]:
			var atlas = AtlasTexture.new()
			atlas.atlas = texture
			var box = measured[index]
			atlas.region = Rect2(box[0],box[1],box[2],box[3])
			atlas.margin = Rect2((256-box[2])/2.0,480-box[3],256-box[2],512-box[3])
			frames.add_frame(key, atlas)
	anim.sprite_frames = frames
	anim.scale = Vector2(0.31,0.31)
	anim.position = Vector2(0,-69.44)

func _physics_process(delta):
	if frozen:
		anim.play("idle")
		return
	coyote = Profile.COYOTE_SECONDS if is_on_floor() else maxf(coyote-delta,0)
	jump_buffer = maxf(jump_buffer-delta,0)
	follow_jump_cooldown = maxf(follow_jump_cooldown-delta,0)
	var axis = 0.0
	if controlled:
		axis = input_axis
		if jump_request:
			jump_buffer = Profile.BUFFER_SECONDS
			jump_request = false
	elif recruited and is_instance_valid(leader):
		var dx = leader.global_position.x-global_position.x
		if absf(dx) > following_distance:
			axis = signf(dx)
		if is_on_floor() and follow_jump_cooldown == 0 and absf(dx)>50 and (leader.global_position.y<global_position.y-45 or is_on_wall()):
			jump_buffer = Profile.BUFFER_SECONDS
			follow_jump_cooldown = 0.5
		# A companion cannot become permanently stranded off-screen.
		if global_position.distance_to(leader.global_position)>850:
			global_position = leader.global_position-Vector2(90,20)
	velocity.x = move_toward(velocity.x, axis*SPEED, ACCEL*delta)
	if jump_buffer > 0 and coyote > 0:
		velocity.y = JUMP
		jump_buffer = 0
		coyote = 0
	if controlled and not jump_held and velocity.y < -210:
		velocity.y += GRAVITY*delta*1.6
	velocity.y = minf(velocity.y+GRAVITY*delta, Profile.MAX_FALL_SPEED)
	move_and_slide()
	if global_position.y > 920:
		global_position = checkpoint if controlled else leader.global_position-Vector2(100,30) if is_instance_valid(leader) else checkpoint
		velocity = Vector2.ZERO
	if absf(velocity.x)>10:
		anim.flip_h = velocity.x < 0
	if celebrating:
		anim.play("celebrate")
	elif not is_on_floor():
		anim.play("jump" if velocity.y < 0 else "fall")
	elif absf(velocity.x)>15:
		anim.play("run")
		anim.speed_scale = clampf(absf(velocity.x)/SPEED,0.5,1.2)
	else:
		anim.speed_scale = 1
		anim.play("idle")
