extends RefCounted
## Pure dialogue state. Quest events are returned once; caller owns persistence.
signal completed(event_id: String, first_completion: bool)
var lines: Dictionary = {}
var scenes: Dictionary = {}
var completed_events: Dictionary = {}
var current: Dictionary = {}
var scene: Dictionary = {}
var active := false
var revealed := false
var input_cooldown := 0.0

func load_data(data: Dictionary):
	for line in data.lines:
		lines[line.id] = line
	for entry in data.scenes:
		scenes[entry.id] = entry

func begin(id: String, conditions: Dictionary) -> bool:
	if not scenes.has(id):
		return false
	var requested: Dictionary = scenes[id]
	if not conditions.get(requested.condition, false):
		return false
	scene = requested
	current = lines[scene.entry]
	active = true
	revealed = false
	input_cooldown = 0.18
	return true

func tick(delta: float):
	input_cooldown = maxf(0.0, input_cooldown - delta)

func advance() -> bool:
	if not active or input_cooldown > 0:
		return false
	input_cooldown = 0.18
	if not revealed:
		revealed = true
		return true
	if current.next == null:
		finish()
	else:
		current = lines[current.next]
		revealed = false
	return true

func finish():
	if not active:
		return
	active = false
	var event_id: String = scene.on_complete_once
	var first := not completed_events.has(event_id)
	completed_events[event_id] = true
	completed.emit(event_id, first)
