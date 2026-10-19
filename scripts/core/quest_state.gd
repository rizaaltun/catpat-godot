extends RefCounted
## Canonical, idempotent B01 event state. Runtime art and counters are projections.
const LIGHTS=["light.A","light.B","light.C"]
const ACCEPTED="quest.lanterns.accepted"
const JOINED="party.badger.joined"
const COMPLETE="chapter.B01.complete"
const RIVER_ACCEPTED="quest.bridge.accepted"
const PLANK="b02.plank.carried"
const ROPE="b02.rope.carried"
const SUPPLIED="b02.bridge.supplied"
const READY="b02.bridge.ready"
const MONKEY="party.monkey.joined"
const RIVER_COMPLETE="chapter.B02.complete"
const RIVER_EVENTS=[RIVER_ACCEPTED,PLANK,ROPE,SUPPLIED,READY,MONKEY,RIVER_COMPLETE]
const GARDEN_ACCEPTED="quest.garden.accepted"
const TIE="b03.tie.carried"
const RELEASED="b03.basket.released"
const LOWERED="b03.basket.lowered"
const BASKET="b03.basket.carried"
const GARDEN_SUPPLIED="b03.garden.supplied"
const PROTECTED="b03.garden.protected"
const RABBIT="party.rabbit.joined"
const GARDEN_COMPLETE="chapter.B03.complete"
const GARDEN_EVENTS=[GARDEN_ACCEPTED,TIE,RELEASED,LOWERED,BASKET,GARDEN_SUPPLIED,PROTECTED,RABBIT,GARDEN_COMPLETE]
const SUMMIT_COMPLETE="chapter.B04.complete"
const FESTIVAL_LIGHT="b05.light.ready"
const FESTIVAL_FLAGS="b05.flags.ready"
const FESTIVAL_FLOWERS="b05.flowers.ready"
const FESTIVAL_COMPLETE="chapter.B05.complete"
const FESTIVAL_EVENTS=[FESTIVAL_LIGHT,FESTIVAL_FLAGS,FESTIVAL_FLOWERS,FESTIVAL_COMPLETE]
const EVENTS=[ACCEPTED,"light.A","light.B","light.C",JOINED,COMPLETE,RIVER_ACCEPTED,PLANK,ROPE,SUPPLIED,READY,MONKEY,RIVER_COMPLETE,GARDEN_ACCEPTED,TIE,RELEASED,LOWERED,BASKET,GARDEN_SUPPLIED,PROTECTED,RABBIT,GARDEN_COMPLETE,SUMMIT_COMPLETE]+FESTIVAL_EVENTS
func party_ids() -> Array:
	return ["badger","monkey","rabbit"] if has(RABBIT) else ["badger","monkey"] if has(MONKEY) else ["badger"] if has(JOINED) else []
func prerequisites(event_id: String) -> Array:
	match event_id:
		SUMMIT_COMPLETE:return [GARDEN_COMPLETE]
		FESTIVAL_LIGHT,FESTIVAL_FLAGS,FESTIVAL_FLOWERS:return [SUMMIT_COMPLETE]
		FESTIVAL_COMPLETE:return FESTIVAL_EVENTS.slice(0,3)
		GARDEN_ACCEPTED:return [RIVER_COMPLETE]
		TIE,RELEASED:return [GARDEN_ACCEPTED]
		LOWERED:return [RELEASED]
		BASKET:return [LOWERED]
		GARDEN_SUPPLIED:return [TIE,BASKET]
		PROTECTED:return [GARDEN_SUPPLIED]
		RABBIT:return [PROTECTED]
		GARDEN_COMPLETE:return [RABBIT]
		RIVER_ACCEPTED:return [COMPLETE]
		PLANK,ROPE:return [RIVER_ACCEPTED]
		SUPPLIED:return [PLANK,ROPE]
		READY:return [SUPPLIED]
		MONKEY:return [READY]
		RIVER_COMPLETE:return [MONKEY]
	return []
var flags: Array=[]
var collectibles: Array=[]
func has(event_id: String) -> bool:return event_id in flags
func all_lit() -> bool:
	for id in LIGHTS:
		if not has(id):return false
	return true
func apply(event_id: String) -> bool:
	if has(event_id):return true
	if event_id not in EVENTS:return false
	if event_id in LIGHTS and not has(ACCEPTED):return false
	if event_id==JOINED and not all_lit():return false
	if event_id==COMPLETE and not has(JOINED):return false
	for requirement in prerequisites(event_id):
		if not has(requirement):return false
	flags.append(event_id);return true
func collect(index: int) -> bool:
	if index<0 or index>4:return false
	var id="b01.mote.%d"%index
	if id not in collectibles:collectibles.append(id)
	return true
func copy():
	var result=get_script().new();result.flags=flags.duplicate();result.collectibles=collectibles.duplicate();return result
func read(data: Dictionary):
	flags=data.quest_flags.duplicate();collectibles=data.collectibles.duplicate()
static func valid(data: Dictionary) -> bool:
	if not data.get("quest_flags") is Array or not data.get("collectibles") is Array:return false
	var seen={}
	for id in data.quest_flags:
		if not id is String or id not in EVENTS or seen.has(id):return false
		seen[id]=true
	for id in LIGHTS:
		if seen.has(id) and not seen.has(ACCEPTED):return false
	if seen.has(JOINED):
		for id in LIGHTS:
			if not seen.has(id):return false
	if seen.has(COMPLETE) and not seen.has(JOINED):return false
	var state=load("res://scripts/core/quest_state.gd").new();state.flags=data.quest_flags
	for id in RIVER_EVENTS+GARDEN_EVENTS+[SUMMIT_COMPLETE]+FESTIVAL_EVENTS:
		if state.has(id):
			for requirement in state.prerequisites(id):
				if not state.has(requirement):return false
	seen.clear()
	for id in data.collectibles:
		if not id is String or id not in ["b01.mote.0","b01.mote.1","b01.mote.2","b01.mote.3","b01.mote.4"] or seen.has(id):return false
		seen[id]=true
	return data.get("party_ids")==state.party_ids()
