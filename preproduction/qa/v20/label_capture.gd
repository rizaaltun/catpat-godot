extends SceneTree
const Route=preload("res://scripts/chapters/summit_waymark.gd")
const Save=preload("res://scripts/core/shared_route_save.gd")
func _initialize():call_deferred("run")
func ticks(n):
	for i in n:await physics_frame
func run():
	var path="user://v20-label-fixture.json";var d=Save.new().fresh();d.bank=2;d.lantern="lit";d.rope="ready";Save.new().save(path,d)
	var r=Route.new();r.save_path=path;root.add_child(r);r.driver=true;await ticks(50)
	# Native layout fixture; full natural descent is separately recorded.
	r.player.position=Vector2(2480,704);r.player.velocity=Vector2.ZERO;await ticks(120)
	await RenderingServer.frame_post_draw
	var name="20-label-full" if root.size.x>1000 else "21-label-small"
	root.get_texture().get_image().save_png("res://preproduction/qa/v20/"+name+".webp")
	print("PASS lower_hint_offset ",not r.fork_hint.visible," arrow label ",r.arrow_hint.position," player ",r.player.position)
	quit(0 if not r.fork_hint.visible and r.arrow_hint.position.x+r.arrow_hint.size.x<r.player.position.x-30 else 1)
