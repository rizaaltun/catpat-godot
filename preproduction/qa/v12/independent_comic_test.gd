extends SceneTree
var failures=0
var checks=0
func ck(ok,title):
	checks+=1
	print(("PASS COMIC: " if ok else "FAIL COMIC: ")+title)
	if not ok:failures+=1
func _initialize():call_deferred("run")
func run():
	var panel=load("res://scripts/core/comic_panel.gd").new();root.add_child(panel)
	panel.build("PAPATYA BAHÇESİ / DİKKATLİ ADIMLAR",func():pass,"Çatpat","Pıtpıt","res://assets/review-v2/catpat-idle-r2.webp","res://assets/chapter-v12/rabbit-idle.webp")
	var data=JSON.parse_string(FileAccess.get_file_as_string("res://preproduction/story/garden-dialogue.json"))
	for line in data.lines:
		var label=panel.present(line);await process_frame
		ck(label.get_minimum_size().y<=136 and label.size.x<=434,"Balloon fits authored text "+line.id)
		ck(panel.speaker_text.text==("Çatpat" if line.side=="left" else "Pıtpıt"),"Speaker matches side "+line.id)
	var runner=load("res://scripts/dialogue_runner.gd").new();runner.load_data(data)
	ck(not runner.begin("garden_join",{"ready":false}),"Join blocked without garden protection")
	ck(runner.begin("garden_meet",{"meet":true}),"Meeting begins")
	var id=runner.current.id;runner.advance();ck(runner.current.id==id,"Opening press cannot skip first line")
	runner.tick(0.2);runner.advance();runner.advance();ck(runner.current.id==id and runner.revealed,"Rapid double input reveals without advancing")
	print("COMIC TOTAL ",checks," FAILURES ",failures);quit(1 if failures else 0)
