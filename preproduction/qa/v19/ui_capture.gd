extends SceneTree
const Route=preload("res://scripts/chapters/summit_rope.gd")
const Save=preload("res://scripts/core/shared_route_save.gd")
func _initialize():call_deferred("run")
func ticks(n):
	for i in n:await physics_frame
func capture(name):
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://preproduction/qa/v19/"+name+".webp")
func run():
	var path="user://v19-ui-fixture.json";var d=Save.new().fresh();d.bank=1;d.lantern="lit";d.rope="requested";Save.new().save(path,d)
	var r=Route.new();r.save_path=path;root.add_child(r);r.driver=true;await ticks(50)
	r.begin_dialogue(r.ROPE_DIALOGUE,"rope.ready");await ticks(30);await capture("08-small-comic-left")
	r.advance_dialogue();await ticks(30);await capture("09-small-comic-right")
	r.cancel_dialogue();r.rope_stage="carried";r.refresh_rope();await r.walk_to(1810);await ticks(30);await capture("10-small-place-action")
	print("V19 small UI fixture captured");quit()
