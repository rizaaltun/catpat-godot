extends SceneTree
const Save=preload("res://scripts/core/save_service.gd")
const Quest=preload("res://scripts/core/quest_state.gd")
var failed=0
var checks=0
var out="res://preproduction/qa/v11/"
func ck(ok,title):
	checks+=1;print(("PASS RATIO: " if ok else "FAIL RATIO: ")+title)
	if not ok:failed+=1
func _initialize():call_deferred("run")
func settle():
	for i in 6:await process_frame
	await RenderingServer.frame_post_draw
func capture(name):
	await settle();root.get_texture().get_image().save_png(out+name+".webp")
func fit_controls(parent):
	var fits=true
	for c in parent.get_children():
		if c is Control and c.visible:
			var r=c.get_global_rect()
			if r.size.x>0 and r.size.y>0 and not Rect2(-1,-1,1282,722).encloses(r):
				print("OUTSIDE ",c.get_class()," ",c.text if c is Label or c is Button else "", " ",r);fits=false
	return fits
func run():
	var w=load("res://scenes/polish_v3.tscn").instantiate();w.save_path="user://v11-independent-ratio-empty.json";root.add_child(w);current_scene=w
	var sizes=[Vector2i(1280,720),Vector2i(1024,768),Vector2i(1920,800),Vector2i(844,390),Vector2i(667,375)]
	for sz in sizes:
		root.size=sz;w.show_menu();await settle()
		var t=root.get_screen_transform();print("MEASURE window=",root.size," visible=",root.get_visible_rect()," transform=",t)
		ck(root.get_visible_rect().size.is_equal_approx(Vector2(1280,720)),"Logical design area preserved at "+str(sz))
		ck(fit_controls(w.screen),"Menu controls within canvas at "+str(sz))
		if sz in [Vector2i(1024,768),Vector2i(667,375)]:await capture("ratio-menu-"+str(sz.x))
		w.show_help();await settle();ck(fit_controls(w.screen),"Help controls within canvas at "+str(sz))
		if sz in [Vector2i(1024,768),Vector2i(667,375)]:await capture("ratio-help-"+str(sz.x))
	root.remove_child(w);w.queue_free();await process_frame
	var save=Save.new();var q=Quest.new()
	for e in [Quest.ACCEPTED]+Quest.LIGHTS+[Quest.JOINED,Quest.COMPLETE]:q.apply(e)
	var d=save.fresh();d.chapter_id="B02";d.geometry="river-v10";d.checkpoint_id="b02.entry";d.quest_flags=q.flags;d.party_ids=q.party_ids()
	var path="user://v11-independent-ratio.json";save.save(path,d)
	w=load("res://scenes/river.tscn").instantiate();w.save_path=path;root.add_child(w);current_scene=w;await settle()
	for sz in sizes:
		root.size=sz;w.build_hud();w.control_display.touch_mode=true;w.control_display.refresh();await settle()
		ck(fit_controls(w.screen),"B02 touch HUD within canvas at "+str(sz))
		var scale_factor=minf(float(sz.x)/1280.0,float(sz.y)/720.0)
		var min_target=96*scale_factor
		ck(min_target>=44,"96-unit controls reach44 native window pixels at "+str(sz)+": "+str(min_target))
		if sz in [Vector2i(1920,800),Vector2i(667,375),Vector2i(844,390)]:await capture("ratio-river-touch-"+str(sz.x))
	root.size=Vector2i(667,375);w.dialogue("river_meet");await settle();ck(fit_controls(w.comic),"B02 comic portraits/buttons within small landscape canvas")
	w.runner.revealed=true;w.refresh_line();await capture("ratio-comic-667")
	print("RATIO TOTAL ",checks," FAILURES ",failed);quit(1 if failed else 0)
