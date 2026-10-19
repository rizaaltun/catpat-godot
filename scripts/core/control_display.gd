extends RefCounted
## Input presentation is shared across chapters; pointer ownership stays in InputRouter.
var touch_mode=DisplayServer.is_touchscreen_available()
var buttons: Array=[]
func bind(items: Array):
	buttons=items
	refresh()
func refresh():
	for button in buttons:
		if is_instance_valid(button):button.visible=touch_mode
func observe(event: InputEvent) -> bool:
	var previous=touch_mode
	if event is InputEventScreenTouch:touch_mode=true
	elif event is InputEventKey and event.pressed:touch_mode=false
	if previous!=touch_mode:refresh()
	return previous!=touch_mode
func accepts(event: InputEvent) -> bool:
	return touch_mode or not event is InputEventMouseButton
