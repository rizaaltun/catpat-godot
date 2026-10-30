extends SceneTree
const Preferences=preload("res://scripts/core/preferences.gd")
const Store=preload("res://scripts/core/save_service.gd")
const Quest=preload("res://scripts/core/quest_state.gd")
const PATH="user://preferences-contract-test.json"
var checks=0
var failures=0
func check(ok:bool,label:String):
 checks+=1
 if not ok:failures+=1
 print("PASS " if ok else "FAIL ",label)
func clean():
 for suffix in ["", ".bak", ".pending", ".bak.pending", ".legacy"]:DirAccess.remove_absolute(PATH+suffix)
func bytes(suffix=""):
 return FileAccess.get_file_as_bytes(PATH+suffix) if FileAccess.file_exists(PATH+suffix) else PackedByteArray()
func _initialize():call_deferred("run")
func run():
 clean()
 var prefs=Preferences.new()
 var normalized=prefs.normalize({"music":false,"effects":true,"text_speed":99,"text_scale":0.25,"control_scale":NAN,"reduced_motion":"yes","existing_host_key":"kept"})
 check(normalized.music==0 and normalized.sfx==1,"legacy boolean music/effect volumes normalize")
 check(normalized.text_speed==2 and normalized.text_scale==1 and normalized.control_scale==1,"invalid numbers clamp or fall back safely")
 check(not normalized.reduced_motion and normalized.existing_host_key=="kept","malformed bool defaults without dropping host settings")
 check(prefs.normalize({"music":0.35,"sfx":0.7}).music==0.35,"numeric legacy volumes retain their value")
 check(not prefs.read("").ok and not prefs.save("",{}).ok,"missing profile path is rejected")
 check(prefs.read(PATH).ok and prefs.read(PATH).new and not FileAccess.file_exists(PATH),"reading missing settings does not create a file")
 check(prefs.save(PATH,{"music":0.25,"left_handed":true}).ok,"settings can be saved before a new journey starts")
 var data=Store.new().load_progress(PATH).data
 check(data.chapter_id=="B00" and data.quest_flags.is_empty(),"first preference save starts a fresh tutorial journey without invented progress")
 clean()
 var store=Store.new()
 data=store.fresh();data.quest_flags=[Quest.ACCEPTED];data.collectibles=["b01.mote.2"];data.settings={"music":false,"existing_host_key":"preserved"}
 check(store.save(PATH,data),"existing journey fixture saves")
 var opened=prefs.read(PATH)
 var latest=store.load_progress(PATH).data
 latest.quest_flags.append(Quest.LIGHTS[0]);latest.collectibles.append("b01.mote.4");latest.settings.text_scale=1.3
 check(store.save(PATH,latest),"journey changes while preferences are open")
 check(prefs.save(PATH,{"music":0.75,"unsupported_personal_data":"ignored"}).ok,"preference change merges into the latest journey")
 var saved=store.load_progress(PATH).data
 var expected=latest.duplicate(true);expected.settings=saved.settings.duplicate(true)
 check(saved==expected and saved.settings.text_scale==1.3,"settings update preserves current flags, collectibles, checkpoint and other preferences")
 check(saved.settings.existing_host_key=="preserved" and not saved.settings.has("unsupported_personal_data"),"host-owned settings survive and unsupported new keys are ignored")
 var original=bytes()
 prefs.store.fault="write"
 check(not prefs.save(PATH,{"sfx":0.1}).ok and bytes()==original,"failed settings write preserves the primary bytes")
 prefs.store.fault="rename"
 check(not prefs.save(PATH,{"sfx":0.1}).ok and bytes()==original,"failed atomic commit preserves the primary bytes")
 prefs.store.fault=""
 clean()
 var corrupt=FileAccess.open(PATH,FileAccess.WRITE);corrupt.store_string("{damaged canonical journey}");corrupt.close()
 original=bytes()
 check(not prefs.read(PATH).ok and not prefs.save(PATH,{"music":1}).ok and bytes()==original,"corrupt journey without backup is never overwritten by preferences")
 check(not FileAccess.file_exists(PATH+".pending"),"rejected corrupt source creates no pending save")
 check(store.write_text(PATH+".bak",store.encode(saved)),"valid backup fixture written beside corrupt primary")
 var backup=bytes(".bak")
 check(prefs.read(PATH).recovered and prefs.save(PATH,{"sfx":0.5}).ok,"valid backup can recover a settings update")
 check(bytes(".bak")==backup and store.load_progress(PATH).data.quest_flags==saved.quest_flags,"backup recovery preserves the backup and all task progress")
 var applied=prefs.apply({"music":false,"reduced_motion":true})
 check(applied.music==0 and root.get_meta("catpat_preferences").reduced_motion,"apply exposes normalized preferences without requiring an audio singleton")
 clean()
 print("PREFERENCES CONTRACT: %d checks, %d failures"%[checks,failures])
 quit(1 if failures else 0)
