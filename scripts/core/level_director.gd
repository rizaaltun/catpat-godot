extends RefCounted
## Implemented chapter registry; scene and named spawn validated before commit.
signal transition_failed(reason: String)
const CHAPTER="B01"
const GEOMETRY="islands-v6"
const ANCHORS=[Vector2(190,580),Vector2(795,540),Vector2(1190,490),Vector2(1630,540),Vector2(2000,480),Vector2(2385,530),Vector2(2800,470),Vector2(3220,530),Vector2(3940,570)]
const Level=preload("res://scripts/core/lantern_level.gd")
const RIVER_ANCHORS={"b02.entry":Vector2(420,520),"b02.hub":Vector2(1160,520),"b02.exit":Vector2(3230,520)}
const GARDEN_ANCHORS={"b03.entry":Vector2(560,540),"b03.hub":Vector2(980,540),"b03.exit":Vector2(3700,540)}
const HOME_ANCHORS={"b00.entry":Vector2(160,620),"b00.walk":Vector2(470,620),"b00.short":Vector2(820,620),"b00.long":Vector2(1320,620),"b00.exit":Vector2(2100,620)}
const FESTIVAL_ANCHORS={"b05.entry":Vector2(160,570),"b05.lights":Vector2(1050,570),"b05.flags":Vector2(2140,570),"b05.flowers":Vector2(3200,570),"b05.stage":Vector2(4230,442)}
const SUMMIT_ANCHORS={"b04.bank.0":Vector2(590,540),"b04.bank.1":Vector2(1810,540),"b04.bank.2":Vector2(3030,540)}
var chapter_id=CHAPTER
var transitioning=false
func checkpoint_for(x: float) -> String:
	var best=0;var distance=INF
	for i in ANCHORS.size():
		# Associate with the island footprint, not a raw airborne coordinate.
		var s=Level.SURFACES[i]
		var d=absf(x-clampf(x,s.position.x,s.end.x))
		if d<distance:distance=d;best=i
	return "b01.island.%d"%best
func valid_checkpoint(id, chapter="B01") -> bool:
	if chapter=="B00":return id is String and HOME_ANCHORS.has(id)
	if chapter=="B05":return id is String and FESTIVAL_ANCHORS.has(id)
	if chapter=="B04":return id is String and SUMMIT_ANCHORS.has(id)
	if chapter=="B03":return id is String and GARDEN_ANCHORS.has(id)
	if chapter=="B02":return id is String and RIVER_ANCHORS.has(id)
	return id is String and id in ["b01.island.0","b01.island.1","b01.island.2","b01.island.3","b01.island.4","b01.island.5","b01.island.6","b01.island.7","b01.island.8"]
func anchor(id: String) -> Vector2:
	if HOME_ANCHORS.has(id):return HOME_ANCHORS[id]
	if FESTIVAL_ANCHORS.has(id):return FESTIVAL_ANCHORS[id]
	if SUMMIT_ANCHORS.has(id):return SUMMIT_ANCHORS[id]
	if GARDEN_ANCHORS.has(id):return GARDEN_ANCHORS[id]
	if RIVER_ANCHORS.has(id):return RIVER_ANCHORS[id]
	return ANCHORS[int(id.get_slice(".",2))] if valid_checkpoint(id) else ANCHORS[0]
func validate(data: Dictionary) -> bool:
	if data.get("chapter_id")=="B00":return data.get("geometry")=="home-v1" and valid_checkpoint(data.get("checkpoint_id"),"B00")
	if data.get("chapter_id")=="B05":return data.get("geometry")=="festival-v1" and valid_checkpoint(data.get("checkpoint_id"),"B05") and "chapter.B04.complete" in data.get("quest_flags",[])
	if data.get("chapter_id")=="B04":return data.get("geometry")=="shared-v16" and valid_checkpoint(data.get("checkpoint_id"),"B04") and "chapter.B03.complete" in data.get("quest_flags",[])
	if data.get("chapter_id")=="B03":return data.get("geometry")=="garden-v12" and valid_checkpoint(data.get("checkpoint_id"),"B03") and "chapter.B02.complete" in data.get("quest_flags",[])
	if data.get("chapter_id")=="B02":return data.get("geometry")=="river-v10" and valid_checkpoint(data.get("checkpoint_id"),"B02") and "chapter.B01.complete" in data.get("quest_flags",[])
	return data.get("chapter_id")==CHAPTER and data.get("geometry")==GEOMETRY and valid_checkpoint(data.get("checkpoint_id"))
func prepare_transition(id: String, checkpoint: String) -> Dictionary:
	if transitioning:return {"ok":false,"reason":"busy"}
	if id not in ["B00",CHAPTER,"B02","B03","B04","B05"] or not valid_checkpoint(checkpoint,id):
		transition_failed.emit("unavailable_chapter_or_spawn")
		return {"ok":false,"reason":"unavailable_chapter_or_spawn"}
	var scene=load({"B00":"res://scenes/home.tscn","B01":"res://scenes/polish_v3.tscn","B02":"res://scenes/river.tscn","B03":"res://scenes/garden.tscn","B04":"res://scenes/summit.tscn","B05":"res://scenes/festival.tscn"}[id])
	if not scene is PackedScene:
		transition_failed.emit("missing_scene");return {"ok":false,"reason":"missing_scene"}
	transitioning=true
	return {"ok":true,"scene":scene,"chapter_id":id,"checkpoint_id":checkpoint,"anchor":anchor(checkpoint)}
func finish_transition(success: bool, target: String):
	if success:chapter_id=target
	transitioning=false
