extends Camera2D
var desired_axis=0.0
func configure(width: float):
	position=Vector2(0,-220)
	limit_left=0;limit_right=int(width);limit_top=0;limit_bottom=720
	process_callback=Camera2D.CAMERA2D_PROCESS_PHYSICS
	position_smoothing_enabled=true;position_smoothing_speed=6.0
func _physics_process(delta):
	position.x=lerpf(position.x,desired_axis*70.0,1.0-exp(-delta*2.6))
