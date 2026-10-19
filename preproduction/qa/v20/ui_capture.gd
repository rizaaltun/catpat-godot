extends SceneTree
const Route=preload("res://scripts/chapters/summit_waymark.gd")
const Save=preload("res://scripts/core/shared_route_save.gd")
func _initialize():call_deferred("run")
func ticks(n):
	for i in n:await physics_frame
func capture(name):
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://preproduction/qa/v20/"+name+".webp")
func run():
	var path="user://v20-ui-fixture.json";var d=Save.new().fresh();d.bank=2;d.lantern="lit";d.rope="ready";d.waymark="placed";Save.new().save(path,d)
	var r=Route.new();r.save_path=path;root.add_child(r);r.driver=true;await ticks(50)
	r.begin_dialogue(r.WAYMARK_DIALOGUE,"waymark.ready");await ticks(30);await capture("15-small-comic-left")
	r.advance_dialogue();await ticks(30);await capture("16-small-comic-right")
	r.cancel_dialogue();r.waymark_stage="carried";r.refresh_waymark();await r.walk_to(2590);await ticks(30);await capture("17-small-place-action")
	r.waymark_stage="ready";r.refresh_waymark();await r.walk_to(3020);await r.wait_for_team(2);await ticks(30);await capture("18-small-lookout")
	r.begin_dialogue(r.LOOKOUT_DIALOGUE,"waymark.seen");await ticks(30);await capture("19-small-longest-comic")
	print("V20 small UI fixture captured");quit()
