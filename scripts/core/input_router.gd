extends RefCounted
## A pointer owns its original control until release or a drag outside its tolerance.
const DRAG_TOLERANCE = 24.0
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
	# A finger already has a ScreenTouch owner; never add its synthesized mouse.
	if (event is InputEventMouseButton or event is InputEventMouseMotion) and event.device==InputEvent.DEVICE_ID_EMULATION:return false
	var id=-999
	var pressed=false
	var dragging=false
	var pos=Vector2.ZERO
	if event is InputEventScreenTouch:
		id=event.index;pressed=event.pressed and not event.canceled;pos=event.position
	elif event is InputEventScreenDrag:
		id=event.index;dragging=true;pos=event.position
	elif event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT:
		id=-1;pressed=event.pressed;pos=event.position
	elif event is InputEventMouseMotion:
		id=-1;dragging=true;pos=event.position
		if not event.button_mask & MOUSE_BUTTON_MASK_LEFT:owners.erase(id)
	else:return false
	if dragging:
		# Once canceled, moving back or across another control cannot reacquire it.
		if owners.has(id):
			var original:Rect2=regions[owners[id]]
			if pos.distance_to(pos.clamp(original.position,original.end))>DRAG_TOLERANCE:owners.erase(id)
	elif not pressed:owners.erase(id)
	else:
		owners.erase(id)
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
