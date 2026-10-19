extends "res://scripts/core/shared_route_save.gd"
## Validated bridge: shared-route projections never replace main-story history.
const Main=preload("res://scripts/core/save_service.gd")
var main=Main.new()
var main_data={}
func load_progress(path:String) -> Dictionary:
	var loaded=main.load_progress(path)
	if not loaded.ok or loaded.data.chapter_id!="B04":return {"ok":false,"reason":"invalid_main_summit"}
	main_data=loaded.data.duplicate(true)
	var route=fresh()
	for key in Main.Summit.FIELDS:route[key]=main_data.summit[key]
	return {"ok":true,"data":route,"new":false,"recovered":loaded.get("recovered",false),"migrated":loaded.get("migrated",false)}
func save(path:String,route:Dictionary) -> bool:
	if not valid(route) or not main.valid(main_data) or main_data.chapter_id!="B04":last_error="invalid_main_context";return false
	var target=main_data.duplicate(true)
	for key in Main.Summit.FIELDS:target.summit[key]=route[key]
	target.checkpoint_id="b04.bank.%d"%int(route.bank)
	if route.waymark=="seen" and Main.Quest.SUMMIT_COMPLETE not in target.quest_flags:target.quest_flags.append(Main.Quest.SUMMIT_COMPLETE)
	main.fault=fault
	if not main.save(path,target):last_error=main.last_error;return false
	main_data=target;last_error="";return true
