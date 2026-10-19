extends SceneTree
const Saves=preload("res://scripts/core/save_service.gd")
const Quest=preload("res://scripts/core/quest_state.gd")
const Director=preload("res://scripts/core/level_director.gd")
var failures=0
var checks=0
var service=Saves.new()
var path="user://v7-save-contract-test.json"
func check(ok: bool, label: String):
	checks+=1
	if not ok:failures+=1
	print("PASS " if ok else "FAIL ",label)
func _initialize():call_deferred("run")
func clean():
	for suffix in ["",".bak",".pending",".bak.pending",".legacy"]:DirAccess.remove_absolute(path+suffix)
func run():
	clean()
	var base=service.fresh()
	check(service.load_progress(path).get("new",false),"missing save produces explicit fresh state")
	var state=Quest.new()
	check(not state.apply(Quest.JOINED),"cannot recruit before three lights")
	check(not state.apply(Quest.COMPLETE),"cannot complete before recruitment")
	check(not state.apply("light.A"),"cannot light before accepted quest")
	check(state.apply(Quest.ACCEPTED),"accept event")
	for id in ["light.C","light.A","light.B"]:check(state.apply(id),"out-of-order unique light "+id)
	var n=state.flags.size();state.apply("light.A")
	check(n==state.flags.size(),"repeat event is idempotent")
	check(state.apply(Quest.JOINED) and state.apply(Quest.COMPLETE),"ordered recruit and completion")
	check(service.save(path,base),"first atomic save")
	var next=base.duplicate(true);next.quest_flags=[Quest.ACCEPTED,"light.A"];next.checkpoint_id="b01.island.2"
	check(service.save(path,next),"second save with verified backup")
	check(service.load_progress(path).data==next,"reopen exact persistent snapshot")
	check(service.read_file(path+".bak").data==base,"backup is last committed state")
	var bytes=FileAccess.get_file_as_string(path)
	for failure in ["write","rename"]:
		service.fault=failure
		check(not service.save(path,base),"injected "+failure+" failure is reported")
		check(FileAccess.get_file_as_string(path)==bytes,"failed "+failure+" preserves primary bytes")
	service.fault=""
	service.write_text(path,"{truncated")
	var recovery=service.load_progress(path)
	check(recovery.ok and recovery.recovered and recovery.data==next,"corrupt primary recovers verified backup")
	check(service.save(path,next),"repair primary from recovered state")
	check(service.read_file(path+".bak").data==next,"repair never backs up corrupted bytes")
	var old={"version":4,"met":true,"lit":[true,false,true],"joined":false,"completed":false,"x":1000}
	var migration=service.decode(JSON.stringify(old))
	check(migration.ok and migration.migrated and migration.data.quest_flags==[Quest.ACCEPTED,"light.A","light.C"],"V4 distinct events migrate without adding a missing light")
	check(migration.data.checkpoint_id=="b01.island.1","legacy gap X migrates to explicit safe checkpoint")
	old.version=6;old.joined=true;old.completed=true;old.lit=[true,true,true];old.gathered=[false,true,false,false,true]
	migration=service.decode(JSON.stringify(old))
	check(migration.ok and migration.data.party_ids==["badger"] and migration.data.collectibles.size()==2 and migration.data.checkpoint_id=="b01.island.8","V6 completed party and exploration migrate to exit")
	service.write_text(path,JSON.stringify(old))
	var legacy_bytes=FileAccess.get_file_as_string(path)
	check(service.save(path,migration.data) and FileAccess.get_file_as_string(path+".legacy")==legacy_bytes,"migration preserves original legacy file")
	check(not service.load_progress(path).migrated,"migrated schema reopens without repeating migration")
	old.lit=[true,false,true]
	migration=service.decode(JSON.stringify(old))
	check(migration.ok and migration.data.party_ids.is_empty() and Quest.COMPLETE not in migration.data.quest_flags,"inconsistent legacy completion cannot invent progress")
	for change in [{"schema_version":99},{"chapter_id":"B02"},{"checkpoint_id":"b01.island.999"},{"geometry":"unknown"},{"quest_flags":[Quest.JOINED],"party_ids":["badger"]},{"quest_flags":[Quest.ACCEPTED,Quest.ACCEPTED]},{"party_ids":["monkey"]},{"collectibles":["unknown"]},{"settings":[]}]:
		var bad=base.duplicate(true);bad.merge(change,true)
		check(not service.decode(service.encode(bad)).ok,"reject invalid schema field "+str(change.keys()))
	var encoded=JSON.parse_string(service.encode(next));encoded.payload.checkpoint_id="b01.island.8"
	check(not service.decode(JSON.stringify(encoded)).ok,"checksum detects altered payload")
	service.write_text(path,"broken");service.write_text(path+".bak","also broken")
	check(not service.load_progress(path).ok,"two corrupt files require explicit recovery UI")
	check(FileAccess.get_file_as_string(path)=="broken" and FileAccess.get_file_as_string(path+".bak")=="also broken","failed load does not overwrite either damaged file")
	var director=Director.new()
	check(not director.prepare_transition("B04","b03.entry").ok and director.chapter_id=="B01" and not director.transitioning,"unavailable chapter leaves current chapter untouched")
	var prepared=director.prepare_transition("B01","b01.island.2")
	check(prepared.ok and prepared.scene is PackedScene and prepared.anchor==Vector2(1190,490),"available scene and spawn resolve before commit")
	check(not director.prepare_transition("B01","b01.island.0").ok,"double transition is rejected")
	director.finish_transition(false,"B02")
	check(director.chapter_id=="B01" and not director.transitioning,"failed transition releases lock without changing chapter")
	clean()
	print("SAVE CONTRACT: ",checks," checks, ",failures," failures")
	quit(1 if failures else 0)
