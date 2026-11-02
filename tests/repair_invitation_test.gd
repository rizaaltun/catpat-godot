extends SceneTree
const Store=preload("res://scripts/core/save_service.gd")
const Quest=preload("res://scripts/core/quest_state.gd")
const Replay=preload("res://scripts/core/replay_service.gd")
const PATH="user://repair-invitation-test.json"
var checks=0
var failures=0
func check(ok:bool,label:String):
 checks+=1
 if not ok:failures+=1
 print("PASS " if ok else "FAIL ",label)
func _initialize():call_deferred("run")
func run():
 var previous=Replay.new().metadata_snapshot()
 var experience=root.get_node_or_null("CatpatExperience")
 if experience:experience.auto_observe=false
 for suffix in Replay.SLOT_SUFFIXES:DirAccess.remove_absolute(PATH+suffix)
 for chapter in ["river","garden"]:
  await check_chapter(chapter)
 Replay.new().restore_metadata(previous)
 if experience:experience.auto_observe=true
 print("REPAIR INVITATIONS: %d checks, %d failures"%[checks,failures])
 quit(1 if failures else 0)
func check_chapter(chapter:String):
 var garden=chapter=="garden"
 var events=Quest.GARDEN_EVENTS if garden else Quest.RIVER_EVENTS
 var supplied=Quest.GARDEN_SUPPLIED if garden else Quest.SUPPLIED
 var ready=Quest.PROTECTED if garden else Quest.READY
 var joined=Quest.RABBIT if garden else Quest.MONKEY
 var party=["badger","monkey","rabbit"] if garden else ["badger","monkey"]
 var dialogue=chapter+"_join"
 var world=load("res://scenes/"+chapter+".tscn").instantiate()
 var data=world.fixture();var state=Quest.new();state.read(data)
 for event in events:
  state.apply(event)
  if event==supplied:break
 data.quest_flags=state.flags;data.party_ids=state.party_ids();data.checkpoint_id="b03.hub" if garden else "b02.hub"
 var store=Store.new()
 check(store.save(PATH,data),chapter+" supplied repair fixture persists")
 set_meta("journey_save_path",PATH)
 root.add_child(world);current_scene=world
 for frame in 5:await physics_frame
 check(world.mode=="building" and not world.state.has(ready),chapter+" reopening a supplied checkpoint resumes unfinished repair")
 world.mode="building";world.freeze(true)
 var before=FileAccess.get_file_as_bytes(PATH)
 world.saves.fault="rename";world.finish_build()
 check(world.mode=="save_error" and not world.runner.active and not world.state.has(ready),"failed repair save cannot start an invitation or open the bridge")
 check(FileAccess.get_file_as_bytes(PATH)==before and not world.state.has(joined),"failed repair preserves previous main bytes and party")
 world.saves.fault="";world.retry_save()
 check(world.mode=="dialogue" and world.runner.active and world.runner.current.id==dialogue+"_0","successful retry opens the invitation without another E press")
 check(store.load_progress(PATH).data.quest_flags.has(ready) and not store.load_progress(PATH).data.quest_flags.has(joined),"repair is durable before invitation and joining remains an actual story event")
 var line=world.runner.current.id
 world.finish_build()
 check(world.runner.current.id==line and world.mode=="dialogue","repeated repair callback cannot restart the active invitation")
 world.test_finish_dialogue()
 check(world.mode in ["play","gathering"] and store.load_progress(PATH).data.party_ids==party,"finishing the invitation durably recruits the companion once")
 # Historical ready-but-not-yet-joined saves keep their existing invitation path.
 data.quest_flags.append(ready);store.save(PATH,data);world.apply_data(data)
 world.mode="play";world.dialogue(dialogue)
 check(world.runner.active and world.runner.current.id==dialogue+"_0","older ready save can still play its unfinished invitation")
 world.test_finish_dialogue()
 check(store.load_progress(PATH).data.party_ids==party,"older save joins through the same persisted story event")
 world.queue_free();await process_frame
 for suffix in Replay.SLOT_SUFFIXES:DirAccess.remove_absolute(PATH+suffix)
