extends SceneTree
var failures=0
var checks=0
func check(ok: bool, message: String):
	checks+=1
	if not ok:failures+=1
	print(("PASS " if ok else "FAIL ")+message)
func _initialize():call_deferred("run")
func run():
	var panel=load("res://scripts/core/comic_panel.gd").new();root.add_child(panel)
	panel.build("FENERLİ PATİKA / ÇIKIŞI BİRLİKTE AYDINLAT",func():pass)
	var data=JSON.parse_string(FileAccess.get_file_as_string("res://preproduction/story/lantern-dialogue.json"))
	for line in data.lines:
		var label=panel.present(line)
		await process_frame
		check(label.get_minimum_size().y<=136 and label.size.x<=434,"comic text fits balloon: "+line.id)
		check(panel.speaker_text.text==("Çatpat" if line.side=="left" else "Porsuk"),"comic side matches speaker: "+line.id)
	var Runner=load("res://scripts/dialogue_runner.gd")
	var runner=Runner.new();runner.load_data(data)
	check(runner.begin("badger_exit",{"badger_at_exit":true}),"exit story begins with condition")
	var id=runner.current.id
	runner.advance();check(runner.current.id==id,"opening interaction cannot also skip first line")
	runner.tick(0.2);runner.advance();runner.advance()
	check(runner.current.id==id and runner.revealed,"rapid double input only reveals line")
	print("COMIC CONTRACT: %d checks, %d failures"%[checks,failures]);quit(1 if failures else 0)
