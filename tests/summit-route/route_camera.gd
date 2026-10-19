extends Camera2D
## Frame actors only after ordinary motion (0) and carrier motion/carry (10/20).
func _ready():process_physics_priority=30
func _physics_process(_delta):get_parent().update_camera(false)
