extends SceneTree
const Store=preload("res://scripts/core/save_service.gd")
const Quest=preload("res://scripts/core/quest_state.gd")
var svc=Store.new()
var checks=[]
var failures=[]
var path="user://independent-v21-service-"+str(Time.get_ticks_usec())+".json"
func _initialize():call_deferred("run")
func check(ok,id):
	checks.append({"id":id,"ok":ok});print(("PASS " if ok else "FAIL ")+id)
	if not ok:failures.append(id)
func state(chapter="B04",bank=0):
	var d=svc.fresh();var q=Quest.new()
	for e in Quest.EVENTS:
		if e=="chapter.B04.complete":continue
		if chapter=="B01":break
		if chapter=="B02" and e==Quest.RIVER_ACCEPTED:break
		if chapter=="B03" and e==Quest.GARDEN_ACCEPTED:break
		q.apply(e)
	d.chapter_id=chapter;d.quest_flags=q.flags.duplicate();d.party_ids=q.party_ids()
	d.settings={"music":0.25,"touch":true};d.collectibles=["b01.mote.1","b01.mote.4"]
	d.geometry={"B01":"islands-v6","B02":"river-v10","B03":"garden-v12","B04":"shared-v16"}[chapter]
	d.checkpoint_id={"B01":"b01.island.0","B02":"b02.entry","B03":"b03.entry","B04":"b04.bank."+str(bank)}[chapter]
	d.summit={"bank":bank,"facing":-1,"lantern":"unseen","rope":"loose","waymark":"loose"} if chapter=="B04" else {}
	return d
func reject(d,id):check(not svc.decode(svc.encode(d)).ok,id)
func write(file,text):
	var f=FileAccess.open(file,FileAccess.WRITE);f.store_string(text);f.close()
func run():
	check(svc.valid(svc.fresh()) and svc.fresh().schema_version==10 and svc.fresh().summit=={},"fresh_schema10")
	for ch in ["B01","B02","B03","B04"]:
		var d=state(ch);var r=svc.decode(svc.encode(d));check(r.ok and svc.encode(r.data)==svc.encode(d),"roundtrip_"+ch)
	for v in [7,8,9]:
		for ch in ["B01","B02","B03"]:
			if (v==7 and ch!="B01") or (v==8 and ch=="B03"):continue
			var d=state(ch);d.schema_version=v;d.erase("summit");var r=svc.decode(svc.encode(d))
			check(r.ok and r.migrated and r.data.summit=={} and r.data.settings==d.settings and r.data.collectibles==d.collectibles and r.data.quest_flags==d.quest_flags and r.data.party_ids==d.party_ids,"migration_%s_%s"%[v,ch])
		var injected=state();injected.schema_version=v;reject(injected,"reject_old_B04_"+str(v))
		injected=state("B01");injected.schema_version=v;reject(injected,"reject_old_summit_field_"+str(v))
	for v in [4,5,6]:
		for completed in [false,true]:
			var old={"version":v,"lit":[completed,completed,completed],"met":completed,"joined":completed,"completed":completed,"x":3940 if completed else 190,"gathered":[true,false,false,false,true]}
			var r=svc.decode(JSON.stringify(old));check(r.ok and r.data.schema_version==10 and r.data.summit=={} and r.data.collectibles==["b01.mote.0","b01.mote.4"] and (Quest.COMPLETE in r.data.quest_flags)==completed,"migration_legacy_%s_%s"%[v,completed])
	for bank in 3:
		for face in [-1,1]:
			var d=state("B04",bank);d.summit.facing=face;check(svc.decode(svc.encode(d)).ok,"bank_face_%s_%s"%[bank,face])
	for field in ["bank","facing","lantern","rope","waymark"]:
		for value in [null,true,{},[],"invalid"]:
			var d=state();d.summit[field]=value;reject(d,"summit_bad_%s_%s"%[field,typeof(value)])
		var d=state();d.summit.erase(field);reject(d,"missing_summit_"+field)
	for bank in [-1,3,1.5]:
		var d=state();d.summit.bank=bank;reject(d,"invalid_bank_"+str(bank))
	for face in [0,2,0.5]:
		var d=state();d.summit.facing=face;reject(d,"invalid_face_"+str(face))
	var d=state();d.summit.extra=true;reject(d,"summit_extra_field")
	d=state();d.summit.bank=1;reject(d,"checkpoint_bank_mismatch")
	d=state();d.quest_flags.erase(Quest.GARDEN_COMPLETE);reject(d,"missing_B03_completion")
	for party in [[],["badger"],["badger","monkey"],["monkey","badger","rabbit"],["badger","monkey","rabbit","rabbit"]]:
		d=state();d.party_ids=party;reject(d,"invalid_party_"+str(party))
	for ch in ["B01","B02","B03"]:
		d=state(ch);d.summit=state().summit;reject(d,"no_summit_in_"+ch)
	for lantern in ["unseen","accepted","prepared","lit"]:
		d=state();d.summit.lantern=lantern;check(svc.decode(svc.encode(d)).ok,"lantern_"+lantern)
	for rope in ["carried","requested","ready"]:
		d=state();d.summit.rope=rope;reject(d,"rope_requires_lit_"+rope);d.summit.lantern="lit";check(svc.decode(svc.encode(d)).ok,"rope_"+rope)
	for waymark in ["carried","placed","ready","seen"]:
		d=state();d.summit.lantern="lit";d.summit.waymark=waymark;reject(d,"waymark_requires_rope_"+waymark)
		d.summit.rope="ready"
		if waymark=="seen":
			reject(d,"seen_requires_complete");d.quest_flags.append("chapter.B04.complete")
		check(svc.decode(svc.encode(d)).ok,"waymark_"+waymark)
	d=state();d.quest_flags.append("chapter.B04.complete");reject(d,"complete_requires_seen")
	for version in [null,true,"10",9.5,11,-1]:
		d=state();d.schema_version=version;reject(d,"invalid_schema_"+str(version))
	check(not svc.decode('{"payload":{},"sha256":"wrong"}').ok,"checksum_rejected")
	d=state("B03");d.schema_version=9;d.erase("summit");var old=svc.encode(d);write(path,old)
	var loaded=svc.load_progress(path);check(loaded.ok and loaded.migrated and FileAccess.get_file_as_string(path)==old,"migration_read_non_destructive")
	check(svc.save(path,loaded.data) and FileAccess.get_file_as_string(path+".legacy")==old,"migration_write_preserves_original")
	for fault in ["write","rename"]:
		var before=FileAccess.get_file_as_string(path);svc.fault=fault;check(not svc.save(path,state()) and FileAccess.get_file_as_string(path)==before,"fault_"+fault+"_preserves_B03")
	svc.fault="";check(svc.save(path,state()),"B04_save");d=state();d.summit.lantern="accepted";check(svc.save(path,d),"B04_task_save")
	write(path,"bad");loaded=svc.load_progress(path);check(loaded.ok and loaded.recovered and loaded.data.summit.lantern=="unseen" and loaded.data.chapter_id=="B04","recover_whole_B04_snapshot")
	write(path+".bak","bad backup");check(not svc.load_progress(path).ok,"two_bad_fail_closed")
	write("res://preproduction/qa/v21/independent-service-results.json",JSON.stringify({"checks":checks,"failures":failures},"\t"))
	print("INDEPENDENT V21 SERVICE DONE ",checks.size()," failures ",failures);quit(0 if failures.is_empty() else 1)
