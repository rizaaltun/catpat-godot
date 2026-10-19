extends SceneTree
const Runner = preload("res://scripts/dialogue_runner.gd")
var emissions: Array = []
func _initialize():
	var r = Runner.new()
	r.load_data(JSON.parse_string(FileAccess.get_file_as_string("res://preproduction/story/lantern-dialogue.json")))
	r.completed.connect(func(id, first): emissions.append([id,first]))
	assert(not r.begin("badger_helped", {}), "Locked quest must not begin")
	assert(r.begin("badger_meet", {"badger_not_recruited":true}))
	var first_id = r.current.id
	assert(not r.advance(), "Opening click must not skip")
	r.tick(0.2)
	assert(r.advance() and r.revealed and r.current.id == first_id, "First press reveals only")
	assert(not r.advance(), "Double press must be ignored")
	r.tick(0.2)
	assert(r.advance() and r.current.id != first_id and not r.revealed)
	while r.active:
		r.tick(0.2)
		r.advance()
	assert(emissions.size() == 1 and emissions[0][1] == true)
	r.begin("badger_meet", {"badger_not_recruited":true})
	while r.active:
		r.tick(0.2)
		r.advance()
	assert(emissions.size() == 2 and emissions[1][1] == false, "Replay must not duplicate reward")
	print("PASS: conditions, reveal/advance, double-input guard, completion, replay idempotency")
	quit()
