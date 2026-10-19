extends Node
## Single carry owner; layer-4 automatic platform velocity is disabled.
## Apply only a physics-server swept displacement, excluding the support body.
## No collision-exception toggling: it invalidates one-way contacts for a tick.
var surface
var actor
var applied_motion=Vector2.ZERO
func _ready():process_physics_priority=20
func _physics_process(_delta):
	applied_motion=Vector2.ZERO
	if not is_instance_valid(surface) or not is_instance_valid(actor):return
	if actor.frozen or surface.paused or not surface.is_riding(actor):return
	if surface.motion_delta.length_squared()==0:return
	var parameters=PhysicsTestMotionParameters2D.new()
	parameters.from=actor.global_transform
	parameters.motion=surface.motion_delta
	parameters.margin=actor.safe_margin
	parameters.exclude_bodies=[surface.get_rid()]
	var result=PhysicsTestMotionResult2D.new()
	var blocked=PhysicsServer2D.body_test_motion(actor.get_rid(),parameters,result)
	applied_motion=result.get_travel() if blocked else surface.motion_delta
	actor.global_position+=applied_motion
