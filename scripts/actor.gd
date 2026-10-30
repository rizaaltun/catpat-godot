extends CharacterBody2D
## Shared physics and frame animations for player and every companion.
const Profile=preload("res://scripts/core/movement_profile.gd")
const CharacterPerformance=preload("res://scripts/core/performance_library.gd")
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
var performance_state=""
var performance_role=""
var performance_owner:WeakRef
var performance_owner_id=0
var performance_seconds=-1.0
var performance_elapsed=0.0
var performance_focus=true
var turn_seconds=0.0
var land_seconds=0.0
var performance_direction=0

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
	CharacterPerformance.install(anim.sprite_frames,character_id)
	add_to_group("catpat_performance_actors")
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
	_tick_performance(delta)
	if frozen:
		_update_frozen_performance()
		return
	var performance_was_grounded=is_on_floor()
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
	if not performance_was_grounded and is_on_floor():land_seconds=0.10
	var direction=int(signf(velocity.x)) if absf(velocity.x)>15 else 0
	if direction!=0:
		if performance_direction!=0 and direction!=performance_direction and is_on_floor():turn_seconds=0.10
		performance_direction=direction
	_update_moving_performance()

func set_performance(state:String,owner:Object=null,duration:float=-1.0,role:String="")->bool:
	if state not in CharacterPerformance.STATES or not is_instance_valid(anim) or not anim.sprite_frames.has_animation(state):return false
	var owner_id=owner.get_instance_id() if is_instance_valid(owner) else 0
	if performance_state==state and performance_owner_id==owner_id and performance_role==role:return true
	performance_state=state;performance_role=role;performance_owner_id=owner_id
	performance_owner=weakref(owner) if is_instance_valid(owner) else null
	performance_seconds=duration;performance_elapsed=0.0
	return true
func clear_performance(owner:Object=null)->bool:
	if is_instance_valid(owner) and performance_owner_id!=owner.get_instance_id():return false
	performance_state="";performance_role="";performance_owner=null;performance_owner_id=0;performance_seconds=-1.0;performance_elapsed=0.0
	if is_instance_valid(anim):anim.offset=Vector2.ZERO
	return true
func performance_reduced_motion()->bool:
	var preferences=get_tree().root.get_meta("catpat_preferences",{})
	return bool(preferences.get("reduced_motion",get_meta("presentation_reduced_motion",false))) if preferences is Dictionary else bool(get_meta("presentation_reduced_motion",false))
func _performance_active()->bool:
	if not performance_focus or get_tree().paused:return false
	var owner=performance_owner.get_ref() if performance_owner else null
	if owner is Control:return owner.is_visible_in_tree()
	var scene=get_tree().current_scene
	if is_instance_valid(scene):
		for property in scene.get_property_list():
			if property.name=="mode" and str(scene.get("mode")) in ["pause","menu","journal","settings","parent_summary"]:return false
			if property.name=="paused" and bool(scene.get("paused")):
				var final_panel=scene.get_node_or_null("FinalPanel")
				if not is_instance_valid(final_panel) or not final_panel is Control or not final_panel.visible:return false
	return true
func _tick_performance(delta:float):
	if performance_owner and not is_instance_valid(performance_owner.get_ref()):clear_performance()
	if not _performance_active():return
	turn_seconds=maxf(0,turn_seconds-delta);land_seconds=maxf(0,land_seconds-delta)
	if not performance_reduced_motion():performance_elapsed+=delta
	if performance_seconds>=0:
		performance_seconds=maxf(0,performance_seconds-delta)
		if performance_seconds<=0:clear_performance()
func _play_performance(animation:String):
	if anim.animation!=animation:anim.play(animation)
	elif animation in ["idle","run","jump","fall"] or anim.sprite_frames.get_animation_loop(animation):anim.play()
	anim.speed_scale=1.0
	var restrained=animation in ["talk","listen","help","celebrate","turn","land"]
	if restrained and (not _performance_active() or performance_reduced_motion()):anim.pause()
	var nod=sin(performance_elapsed*6.0)*1.5 if animation=="talk" else sin(minf(performance_elapsed,0.6)*PI/0.6)*1.5 if animation=="help" else 0.0
	anim.offset=Vector2(0,-nod/maxf(0.01,absf(anim.scale.y))) if restrained and _performance_active() and not performance_reduced_motion() else Vector2.ZERO
func _update_frozen_performance():
	var state=performance_state if performance_state!="" else "celebrate" if celebrating else "idle"
	_play_performance(state)
	if performance_state=="" and not celebrating or not _performance_active():anim.pause()
func _update_moving_performance():
	if celebrating:_play_performance("celebrate")
	elif not is_on_floor():_play_performance("jump" if velocity.y<0 else "fall")
	elif performance_state!="" and absf(velocity.x)<=15:_play_performance(performance_state)
	elif land_seconds>0:_play_performance("land")
	elif turn_seconds>0:_play_performance("turn")
	elif absf(velocity.x)>15:
		_play_performance("run");anim.speed_scale=clampf(absf(velocity.x)/SPEED,0.5,1.2)
	else:_play_performance("idle")
func _notification(what):
	if what in [NOTIFICATION_APPLICATION_FOCUS_OUT,NOTIFICATION_APPLICATION_PAUSED]:performance_focus=false
	elif what in [NOTIFICATION_APPLICATION_FOCUS_IN,NOTIFICATION_APPLICATION_RESUMED]:performance_focus=true
