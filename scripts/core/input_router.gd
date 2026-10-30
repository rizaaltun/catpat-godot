extends RefCounted
## Each pointer owns one control until release. UI rebuild/pause clears ownership.
var regions={}
var owners={}
var axis=0.0
var jump_held=false
var interact_pressed=false
func bind_controls(left: Rect2,right: Rect2,jump: Rect2,action: Rect2):
	regions={"left":left,"right":right,"jump":jump,"action":action}
	reset()
func reset():
	owners.clear();axis=0.0;jump_held=false;interact_pressed=false
func consume(event: InputEvent) -> bool:
	interact_pressed=false
	# Godot emits this mouse event for a finger already represented by ScreenTouch.
	if event is InputEventMouseButton and event.device==InputEvent.DEVICE_ID_EMULATION:return false
	var id=-999
	var pressed=false
	var pos=Vector2.ZERO
	if event is InputEventScreenTouch:
		id=event.index;pressed=event.pressed and not event.canceled;pos=event.position
	elif event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT:
		id=-1;pressed=event.pressed;pos=event.position
	else:return false
	if not pressed:owners.erase(id)
	else:
		for role in regions:
			if regions[role].has_point(pos):
				owners[id]=role
				if role=="action":interact_pressed=true
				break
	axis=0.0;jump_held=false
	for role in owners.values():
		if role=="left":axis-=1
		if role=="right":axis+=1
		if role=="jump":jump_held=true
	axis=clampf(axis,-1,1)
	return true
