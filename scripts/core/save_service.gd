extends RefCounted
## Checked pending write -> verified backup -> atomic replacement. Never replace a
## valid backup with corrupt primary bytes. Web durability still needs device QA.
const Quest=preload("res://scripts/core/quest_state.gd")
const Director=preload("res://scripts/core/level_director.gd")
const Summit=preload("res://scripts/core/summit_progress.gd")
const VERSION=10
const MAIN_FIELDS=["schema_version","chapter_id","geometry","checkpoint_id","quest_flags","party_ids","collectibles","settings","ending_seen","summit"]
var director=Director.new()
var fault="" # Deterministic test seam; empty in shipping runtime.
var last_error=""
func fresh() -> Dictionary:
	return {"schema_version":VERSION,"chapter_id":"B01","geometry":Director.GEOMETRY,"checkpoint_id":"b01.island.0","quest_flags":[],"party_ids":[],"collectibles":[],"settings":{},"ending_seen":false,"summit":{}}
func fresh_journey() -> Dictionary:
	var data=fresh()
	data.chapter_id="B00";data.geometry="home-v1";data.checkpoint_id="b00.entry"
	data.settings.onboarding_origin="new-journey-v1"
	return data
func migrate_onboarding(data:Dictionary) -> Dictionary:
	# Older journeys begin at B01. Preserve their route and explicitly mark bypass,
	# rather than reporting that the player performed the new tutorial.
	if not valid(data):return {"ok":false,"reason":"invalid_state"}
	var result=data.duplicate(true)
	if result.chapter_id=="B00" or Quest.HOME_EXIT in result.quest_flags:return {"ok":true,"data":result,"migrated":false}
	for event in Quest.HOME_EVENTS:
		if event not in result.quest_flags:result.quest_flags.append(event)
	result.settings.onboarding_origin="legacy-bypass-v1"
	return {"ok":valid(result),"data":result,"migrated":true}
func persist_onboarding_migration(path:String,data:Dictionary) -> bool:
	var original=path+".onboarding-v1.original"
	if FileAccess.file_exists(original):
		if not read_file(original).ok:last_error="onboarding_backup_invalid";return false
	else:
		var source=path if read_file(path).ok else path+".bak"
		var pending=original+".pending"
		if not read_file(source).ok or DirAccess.copy_absolute(source,pending)!=OK or not read_file(pending).ok or DirAccess.rename_absolute(pending,original)!=OK:
			last_error="onboarding_backup_failed";return false
	return save(path,data)
func valid(data) -> bool:
	if not data is Dictionary or data.size()!=MAIN_FIELDS.size() or not data.has_all(MAIN_FIELDS):return false
	if typeof(data.schema_version) not in [TYPE_INT,TYPE_FLOAT] or data.schema_version!=VERSION:return false
	if not data.quest_flags is Array or not data.settings is Dictionary or not data.ending_seen is bool or not data.summit is Dictionary:return false
	if not director.validate(data) or not Quest.valid(data):return false
	if data.chapter_id=="B00":
		var required={"b00.walk":Quest.WALK,"b00.short":Quest.SHORT_JUMP,"b00.long":Quest.TUTORIAL_JUMP,"b00.exit":Quest.HOME_EXIT}
		if required.has(data.checkpoint_id) and required[data.checkpoint_id] not in data.quest_flags:return false
		return data.summit.is_empty() and data.party_ids.is_empty() and not data.ending_seen and data.quest_flags.all(func(e):return e in Quest.HOME_EVENTS) and data.collectibles.all(func(e):return e=="b00.ribbon")
	if data.chapter_id=="B05":
		return data.summit.is_empty() and data.party_ids==["badger","monkey","rabbit"] and Quest.SUMMIT_COMPLETE in data.quest_flags and (Quest.FESTIVAL_COMPLETE not in data.quest_flags or data.ending_seen)
	if data.chapter_id=="B04":
		return Summit.valid(data.summit) and data.checkpoint_id=="b04.bank.%d"%int(data.summit.bank) and data.party_ids==["badger","monkey","rabbit"] and ((Quest.SUMMIT_COMPLETE in data.quest_flags)==(data.summit.waymark=="seen"))
	return data.summit.is_empty() and Quest.SUMMIT_COMPLETE not in data.quest_flags and not data.quest_flags.any(func(e):return e in Quest.FESTIVAL_EVENTS)
func encode(data: Dictionary) -> String:
	var normalized=JSON.parse_string(JSON.stringify(data))
	return JSON.stringify({"payload":normalized,"sha256":JSON.stringify(normalized).sha256_text()})
func decode(text: String) -> Dictionary:
	var parser=JSON.new()
	if parser.parse(text)!=OK:return {"ok":false,"reason":"invalid_json"}
	var raw=parser.data
	if not raw is Dictionary:return {"ok":false,"reason":"invalid_json"}
	if raw.has("payload"):
		if not raw.payload is Dictionary or raw.get("sha256")!=JSON.stringify(raw.payload).sha256_text():return {"ok":false,"reason":"invalid_payload"}
		var old_version=raw.payload.get("schema_version")
		if typeof(old_version) not in [TYPE_INT,TYPE_FLOAT] or (old_version!=7 and old_version!=8 and old_version!=9 and old_version!=VERSION):return {"ok":false,"reason":"unsupported_schema"}
		if old_version!=VERSION:
			if raw.payload.size()!=9 or raw.payload.has("summit") or raw.payload.get("chapter_id") not in ["B01","B02","B03"] or not raw.payload.get("quest_flags") is Array or Quest.SUMMIT_COMPLETE in raw.payload.quest_flags:return {"ok":false,"reason":"invalid_legacy_payload"}
			raw.payload.summit={}
		if old_version==7:
			if raw.payload.get("chapter_id")!="B01" or not raw.payload.get("quest_flags") is Array:return {"ok":false,"reason":"invalid_v7_chapter"}
			for e in raw.payload.quest_flags:
				if e in Quest.RIVER_EVENTS+Quest.GARDEN_EVENTS:return {"ok":false,"reason":"invalid_v7_event"}
		if old_version==8:
			if raw.payload.get("chapter_id") not in ["B01","B02"] or not raw.payload.get("quest_flags") is Array:return {"ok":false,"reason":"invalid_v8_chapter"}
			for e in raw.payload.quest_flags:
				if e in Quest.GARDEN_EVENTS:return {"ok":false,"reason":"invalid_v8_event"}
		raw.payload.schema_version=VERSION
		if not valid(raw.payload):return {"ok":false,"reason":"invalid_payload"}
		return {"ok":true,"data":raw.payload,"migrated":old_version!=VERSION}
	if raw.get("version")!=4 and raw.get("version")!=5 and raw.get("version")!=6:return {"ok":false,"reason":"unsupported_schema"}
	if not raw.get("lit") is Array or raw.lit.size()!=3:return {"ok":false,"reason":"legacy_lights"}
	for key in ["met","joined","completed"]:
		if not raw.get(key) is bool:return {"ok":false,"reason":"legacy_flags"}
	for v in raw.lit:
		if not v is bool:return {"ok":false,"reason":"legacy_lights"}
	if not (raw.get("x") is float or raw.get("x") is int) or not is_finite(float(raw.x)):return {"ok":false,"reason":"legacy_position"}
	var state=Quest.new()
	if raw.met or raw.lit.count(true)>0:state.apply(Quest.ACCEPTED)
	for i in 3:
		if raw.lit[i]:state.apply(Quest.LIGHTS[i])
	if raw.joined:state.apply(Quest.JOINED)
	if raw.completed:state.apply(Quest.COMPLETE)
	if raw.has("gathered"):
		if not raw.gathered is Array or raw.gathered.size()!=5:return {"ok":false,"reason":"legacy_collectibles"}
		for i in 5:
			if not raw.gathered[i] is bool:return {"ok":false,"reason":"legacy_collectibles"}
			if raw.gathered[i]:state.collect(i)
	var data=fresh();data.quest_flags=state.flags;data.collectibles=state.collectibles;data.party_ids=["badger"] if state.has(Quest.JOINED) else []
	data.checkpoint_id=director.checkpoint_for(float(raw.x))
	if state.has(Quest.COMPLETE):data.checkpoint_id="b01.island.8"
	return {"ok":true,"data":data,"migrated":true}
func read_file(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):return {"ok":false,"reason":"missing"}
	return decode(FileAccess.get_file_as_string(path))
func load_progress(path: String) -> Dictionary:
	var primary=read_file(path)
	if primary.ok:primary["recovered"]=false;return primary
	var backup=read_file(path+".bak")
	if backup.ok:backup["recovered"]=true;return backup
	if primary.reason=="missing" and backup.reason=="missing":return {"ok":true,"data":fresh(),"migrated":false,"recovered":false,"new":true}
	return {"ok":false,"reason":"no_valid_save"}
func write_text(path: String, content: String) -> bool:
	var file=FileAccess.open(path,FileAccess.WRITE)
	if not file:return false
	file.store_string(content);file.flush()
	var error=file.get_error();file.close()
	return error==OK
func save(path: String, data: Dictionary) -> bool:
	last_error=""
	if not valid(data):last_error="invalid_state";return false
	var text=encode(data)
	if FileAccess.file_exists(path) and FileAccess.get_file_as_string(path)==text:
		_notify_observations(path,data,data)
		return true
	var pending=path+".pending"
	if fault=="write" or not write_text(pending,text):last_error="write_failed";return false
	if not read_file(pending).ok:last_error="verify_failed";return false
	var old=read_file(path)
	var observation_previous=old.data if old.ok else {}
	if not old.ok:
		var prior_backup=read_file(path+".bak")
		if prior_backup.ok:observation_previous=prior_backup.data
	if old.ok:
		if old.get("migrated",false) and not FileAccess.file_exists(path+".legacy"):
			if DirAccess.copy_absolute(path,path+".legacy")!=OK:last_error="migration_backup_failed";return false
		if not write_text(path+".bak.pending",FileAccess.get_file_as_string(path)):
			last_error="backup_write_failed";return false
		if DirAccess.rename_absolute(path+".bak.pending",path+".bak")!=OK:last_error="backup_commit_failed";return false
	if fault=="rename" or DirAccess.rename_absolute(pending,path)!=OK:last_error="commit_failed";return false
	_notify_observations(path,observation_previous,data)
	return true
func _notify_observations(path:String,previous:Dictionary,current:Dictionary):
	# Observation durability is separate: a journal failure never rejects a committed journey.
	var loop=Engine.get_main_loop()
	if not loop is SceneTree:return
	var observer=loop.root.get_node_or_null("CatpatObservations")
	if is_instance_valid(observer) and observer.has_method("observe_snapshot"):
		observer.observe_snapshot(path,previous,current)
func preserve_damaged(path: String) -> bool:
	var suffix=".damaged-"+str(Time.get_unix_time_from_system()).replace(".","-")
	for source in [path,path+".bak"]:
		if FileAccess.file_exists(source) and DirAccess.copy_absolute(source,source+suffix)!=OK:return false
	return true
