extends SceneTree
const Save=preload("res://scripts/core/save_service.gd")
const Quest=preload("res://scripts/core/quest_state.gd")
const Replay=preload("res://scripts/core/replay_service.gd")
const PATH="user://softlock-audit.json"
var checks=0
var failures=0
func check(ok:bool,label:String):
 checks+=1
 if not ok:failures+=1
 print("PASS " if ok else "FAIL ",label)
func _initialize():call_deferred("run")
func run():
 var metadata=Replay.new().metadata_snapshot()
 var experience=root.get_node_or_null("CatpatExperience")
 if experience:experience.auto_observe=false
 for chapter in ["river","garden"]:await check_stranded_party(chapter)
 Replay.new().restore_metadata(metadata)
 if experience:experience.auto_observe=true
 print("SOFTLOCK AUDIT: %d checks, %d failures"%[checks,failures])
 quit(1 if failures else 0)
func check_stranded_party(chapter:String):
 for suffix in Replay.SLOT_SUFFIXES:DirAccess.remove_absolute(PATH+suffix)
 var garden=chapter=="garden"
 var world=load("res://scenes/"+chapter+".tscn").instantiate()
 var data=world.fixture();var state=Quest.new();state.read(data)
 for event in (Quest.GARDEN_EVENTS if garden else Quest.RIVER_EVENTS):
  state.apply(event)
  if event==(Quest.RABBIT if garden else Quest.MONKEY):break
 data.quest_flags=state.flags;data.party_ids=state.party_ids()
 check(Save.new().save(PATH,data),chapter+" joined-party fixture is durable")
 set_meta("journey_save_path",PATH);root.add_child(world);current_scene=world
 for frame in 10:await physics_frame
 if garden:
  world.begin_gather()
  check(world.mode=="play" and not world.player.frozen,"garden reunion leaves player in control")
  var x=world.player.position.x;world.axis=1
  for frame in 15:await physics_frame
  check(world.player.position.x>x+5,"garden player can walk while friends catch up")
  world.axis=0
 world.player.position=Vector2(3760,539) if garden else Vector2(3250,519)
 world.player.velocity=Vector2.ZERO
 for companion in ([world.badger,world.monkey,world.rabbit] if garden else [world.badger,world.monkey]):
  companion.position=Vector2(650,539 if garden else 519);companion.frozen=true
 for frame in 10:await physics_frame
 check(world.player.is_on_floor() and not world.party_at_exit(),chapter+" player is safely at exit while companions are stranded")
 world.action=true
 for frame in 4:await process_frame
 check(world.mode=="dialogue" and world.runner.active,chapter+" stranded companion cannot block exit conversation")
 if world.runner.active:world.test_finish_dialogue()
 var flag=Quest.GARDEN_COMPLETE if garden else Quest.RIVER_COMPLETE
 check(world.state.has(flag) and world.mode=="complete",chapter+" exit still requires and completes the story")
 check(flag in Save.new().load_progress(PATH).data.quest_flags,chapter+" completion persists without losing party")
 world.queue_free();await process_frame
 for suffix in Replay.SLOT_SUFFIXES:DirAccess.remove_absolute(PATH+suffix)
