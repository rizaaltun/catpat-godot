extends "res://scripts/polish_actor.gd"
## B05 saves use body-center anchors. Adapt only the pivot/capsule; physics stays shared.
func _ready():
 super._ready()
 for child in get_children():
  if child is CollisionShape2D:
   child.position.y=0.0
   child.shape.height=64.0
 anim.position.y+=32.0
