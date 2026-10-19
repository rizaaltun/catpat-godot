extends Node2D
# One explicit flower bed behind the shelter; distant panorama is scenery.
# Wind is advanced by the world's active modes, never by an independent timer.
var sheltered=false
var wind_strength=1.0
var clock=0.0
var plants: Array[Sprite2D]=[]
const ROOT=Vector2(555,1375)
func _ready():
	z_index=-6
	var texture=load("res://assets/chapter-v13/daisies.webp")
	for i in 5:
		var plant=Sprite2D.new();plant.texture=texture;plant.centered=false
		plant.offset=-ROOT
		plant.scale=Vector2.ONE*(0.064+float(i%3)*0.004)
		plant.position=Vector2(905+i*43,539)
		plants.append(plant);add_child(plant)
	pose_plants()
func set_sheltered(value: bool):
	sheltered=value
	# Loading a completed chapter must immediately show the durable calm state.
	if value:wind_strength=0.0
	else:wind_strength=1.0
	pose_plants()
func advance_wind(delta: float):
	clock+=delta
	pose_plants()
func pose_plants():
	for i in plants.size():
		# Root stays fixed. A clear sideways gust becomes a small natural sway.
		var wave=sin(clock*3.1+float(i)*0.65)
		plants[i].rotation=(0.24+wave*0.12)*wind_strength+wave*0.014*(1.0-wind_strength)
