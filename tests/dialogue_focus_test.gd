extends SceneTree
## Exercise actual chapter callbacks, including keyboard and late GUI delivery.
const Comic=preload("res://scripts/core/comic_panel.gd")
var checks=0
var failures=0
func _initialize():call_deferred("run")
func check(ok:bool,label:String):
	checks+=1
	if not ok:failures+=1
	print("PASS " if ok else "FAIL ",label)
func run():
	var host=root.get_node("CatpatExperience")
	var old_focus=host.application_focus_lost
	var old_modal=host.active_modal
	var modal=Control.new();root.add_child(modal)
	for chapter in ["polish_world","river_world","garden_world"]:
		var world=load("res://scripts/"+chapter+".gd").new()
		var panel=Comic.new();root.add_child(panel)
		panel.build("",func():pass)
		world.set("dialogue" if chapter=="polish_world" else "comic",panel)
		world.runner.load_data({"lines":[{"id":"a","next":"b","side":"left","text":"Bir"},{"id":"b","next":null,"side":"right","text":"İki"}],"scenes":[{"id":"test","condition":"ready","entry":"a","on_complete_once":"done"}]})
		world.runner.begin("test",{"ready":true});world.runner.revealed=true;world.runner.tick(1)
		var callback=world.advance_dialogue if chapter=="polish_world" else world.advance
		host.application_focus_lost=true;callback.call()
		check(world.runner.current.id=="a",chapter+" ignores keyboard callback while unfocused")
		host.application_focus_lost=false;host.active_modal=modal;callback.call()
		check(world.runner.current.id=="a",chapter+" ignores callback under modal")
		host.active_modal=null;panel.hide();callback.call()
		check(world.runner.current.id=="a",chapter+" ignores callback after dialogue is hidden")
		panel.show();callback.call()
		check(world.runner.current.id=="b",chapter+" resumes exactly once when visible and focused")
		world.free();panel.free()
	var summit=load("res://scripts/chapters/summit_main.gd").new()
	var panel=load("res://scripts/core/summit_comic.gd").new();root.add_child(panel)
	panel.setup(func():pass,func():pass)
	summit.comic=panel;summit.pause_root=Control.new();summit.pause_root.hide()
	summit.dialogue_active=true;summit.action_cooldown=0
	summit.dialogue_lines=[{"side":"left","text":"Bir"},{"side":"right","text":"İki"}]
	host.application_focus_lost=true;summit.advance_dialogue()
	check(summit.dialogue_index==0,"B04 ignores keyboard callback while unfocused")
	host.application_focus_lost=false;host.active_modal=modal;summit.advance_dialogue()
	check(summit.dialogue_index==0,"B04 ignores callback under modal")
	host.active_modal=null;panel.hide();summit.advance_dialogue()
	check(summit.dialogue_index==0,"B04 ignores callback after dialogue is hidden")
	panel.show();summit.advance_dialogue()
	check(summit.dialogue_index==1,"B04 resumes exactly once when visible and focused")
	summit.pause_root.free();summit.free();panel.free();modal.free()
	host.application_focus_lost=old_focus;host.active_modal=old_modal
	print("DIALOGUE FOCUS: %d checks, %d failures"%[checks,failures])
	quit(1 if failures else 0)
