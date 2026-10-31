extends SceneTree
## Exercise the existing physical B02/B03 route without automated save bypasses.
const Save=preload("res://scripts/core/save_service.gd")
const Quest=preload("res://scripts/core/quest_state.gd")
var path="user://shipping-route-audit.json"
func _initialize():
 set_meta("journey_save_path",path)
 call_deferred("run")
func run():
 var garden="--audit-garden" in OS.get_cmdline_user_args()
 var scene=load("res://scenes/garden.tscn" if garden else "res://scenes/river.tscn").instantiate()
 var d=scene.fixture();var q=Quest.new();q.read(d)
 for event in Quest.HOME_EVENTS:q.apply(event)
 d.quest_flags=q.flags;d.settings.onboarding_origin="new-journey-v1"
 if not Save.new().save(path,d):push_error("Shipping route fixture failed");quit(1);return
 root.add_child(scene);current_scene=scene
 if scene.automated:push_error("Shipping route must retain real persistence");quit(1);return
 print("SHIPPING ROUTE: ",d.chapter_id," actual persistence enabled")
 scene.run_test()
