extends SceneTree
const Save=preload("res://scripts/core/save_service.gd")
const Quest=preload("res://scripts/core/quest_state.gd")
const Festival=preload("res://scripts/chapters/festival_main.gd")
const PATH="user://festival-contract-test.json"
var checks=0
var failures=0
func check(ok:bool,label:String):
 checks+=1
 if not ok:failures+=1
 print("PASS " if ok else "FAIL ",label)
func clean():
 for suffix in ["",".bak",".pending",".bak.pending",".legacy"]:DirAccess.remove_absolute(PATH+suffix)
func _initialize():call_deferred("run")
func walk_to(world, target_x:float, limit:int=240) -> bool:
 for frame in limit:
  var dx=target_x-world.actor.position.x
  world.right_pressed=dx>7.0
  world.left_pressed=dx< -7.0
  await physics_frame
  if absf(target_x-world.actor.position.x)<8.0 and world.actor.is_on_floor():
   world.right_pressed=false;world.left_pressed=false
   return true
 world.right_pressed=false;world.left_pressed=false
 return false
func jump_and_land(world, move_frames:int) -> bool:
 if not world.actor.is_on_floor():return false
 world.jump_pressed=true;world.right_pressed=true
 await physics_frame
 world.jump_pressed=false
 for frame in range(move_frames-1):await physics_frame
 world.right_pressed=false
 for frame in 60:
  await physics_frame
  if world.actor.is_on_floor():return true
 return false
func run():
 clean()
 check(load("res://scenes/festival.tscn") is PackedScene,"B05 scene and script parse")
 var service=Save.new()
 var state=Quest.new()
 var journey=[Quest.ACCEPTED]+Quest.LIGHTS+[Quest.JOINED,Quest.COMPLETE,Quest.RIVER_ACCEPTED,Quest.PLANK,Quest.ROPE,Quest.SUPPLIED,Quest.READY,Quest.MONKEY,Quest.RIVER_COMPLETE,Quest.GARDEN_ACCEPTED,Quest.TIE,Quest.RELEASED,Quest.LOWERED,Quest.BASKET,Quest.GARDEN_SUPPLIED,Quest.PROTECTED,Quest.RABBIT,Quest.GARDEN_COMPLETE,Quest.SUMMIT_COMPLETE]
 for id in journey:check(state.apply(id),"build prerequisite journey "+id)
 var data=service.fresh();data.chapter_id="B05";data.geometry="festival-v1";data.checkpoint_id="b05.entry"
 data.quest_flags=state.flags.duplicate();data.party_ids=state.party_ids();data.summit={}
 check(service.valid(data),"B04 completion opens B05 with the existing party")
 var premature=data.duplicate(true);premature.quest_flags.append(Quest.FESTIVAL_COMPLETE);premature.ending_seen=true
 check(not service.valid(premature),"final cannot be recorded before all three contributions")
 for id in [Quest.FESTIVAL_FLOWERS,Quest.FESTIVAL_LIGHT,Quest.FESTIVAL_FLAGS]:check(state.apply(id),"task order is independent "+id)
 data.quest_flags=state.flags.duplicate();data.checkpoint_id="b05.flowers"
 check(service.valid(data),"three ready flags produce a valid B05 checkpoint")
 var prior_count=state.flags.size();check(state.apply(Quest.FESTIVAL_LIGHT),"replaying a contribution is safe")
 check(state.flags.size()==prior_count,"replay does not duplicate contribution flags")
 check(state.apply(Quest.FESTIVAL_COMPLETE),"all contributions unlock the shared finale")
 data.quest_flags=state.flags.duplicate();data.ending_seen=true;data.checkpoint_id="b05.stage"
 check(service.valid(data) and service.save(PATH,data),"completed finale saves to the canonical journey file")
 var loaded=service.load_progress(PATH)
 check(loaded.ok and loaded.data==data,"completed B05 state reopens intact")
 var invalid=data.duplicate(true);invalid.checkpoint_id="b05.unknown"
 check(not service.valid(invalid),"unknown B05 checkpoint is rejected")
 var start=service.fresh();start.chapter_id="B05";start.geometry="festival-v1";start.checkpoint_id="b05.entry"
 var before_festival=Quest.new()
 for id in journey:before_festival.apply(id)
 start.quest_flags=before_festival.flags.duplicate();start.party_ids=before_festival.party_ids();start.summit={}
 check(service.save(PATH,start),"valid B04-complete save opens B05")
 set_meta("journey_save_path",PATH)
 var playable=load("res://scenes/festival.tscn").instantiate()
 get_root().add_child(playable)
 await process_frame
 await physics_frame
 check(not playable.blocked and playable.actor!=null,"B05 builds a playable world from the canonical save")
 check(playable.get_node_or_null("FestivalForestBackdrop")!=null,"B05 uses the authored forest backdrop")
 check(playable.get_node_or_null("FestivalCampArt")!=null,"B05 finale uses the shipped festival camp illustration")
 check(playable.find_children("MossyPlatformArt","Sprite2D",true,false).size()>=10,"B05 platforms use the shipped terrain art")
 check(playable.flower_sprites.size()==3,"B05 has three completion flower visuals")
 check(await walk_to(playable,730.0),"B05 walks across the entry bank")
 check(await jump_and_land(playable,32),"B05 jumps from the ground onto the first raised platform")
 check(absf(playable.actor.position.y-490.0)<8.0,"B05 lands on the first raised platform at its collision height")
 check(await walk_to(playable,930.0),"B05 traverses the first raised platform")
 check(await jump_and_land(playable,25),"B05 makes the second jump to the Porsuk station platform")
 check(await walk_to(playable,1150.0),"B05 walks to the Porsuk station under player control")
 check(playable.near_task==0 and playable.can_interact(),"Porsuk station is reachable from the raised platform")
 playable.interact()
 check(Quest.FESTIVAL_LIGHT in playable.save_data.quest_flags,"station interaction records the light contribution")
 var station_save=service.load_progress(PATH)
 check(station_save.ok and station_save.data.checkpoint_id=="b05.lights","station contribution persists its checkpoint")
 playable.actor.position=Vector2(1850.0,720.0);playable.actor.velocity=Vector2(0.0,950.0)
 for frame in 12:await physics_frame
 check(playable.actor.position.distance_to(Vector2(1050.0,570.0))<1.0 and playable.actor.velocity==Vector2.ZERO,"B05 real fall returns to the last saved contribution checkpoint")
 playable.actor.position=Vector2(3310.0,422.0);playable.actor.velocity=Vector2.ZERO
 await physics_frame
 check(playable.near_task==2 and playable.can_interact(),"Pıtpıt station is reachable from its raised platform")
 playable.interact()
 check(Quest.FESTIVAL_FLOWERS in playable.save_data.quest_flags and playable.flower_sprites.all(func(flower):return flower.visible),"flower contribution persists and appears in the world")
 var flower_save=service.load_progress(PATH)
 check(flower_save.ok and flower_save.data.checkpoint_id=="b05.flowers","flower contribution persists its checkpoint")
 playable.actor.position=Vector2(2250.0,433.0);playable.actor.velocity=Vector2.ZERO
 await physics_frame
 check(playable.near_task==1 and playable.can_interact(),"Maymun station is reachable from its raised platform")
 playable.interact()
 check(Quest.FESTIVAL_FLAGS in playable.save_data.quest_flags,"flag contribution persists after a different task order")
 var flag_save=service.load_progress(PATH)
 check(flag_save.ok and flag_save.data.checkpoint_id=="b05.flags","flag contribution persists its checkpoint")
 playable.actor.position=Vector2(Festival.FINAL_ANCHOR_X,442.0);playable.actor.velocity=Vector2.ZERO
 await physics_frame
 check(not playable.all_on_stage and not playable.can_interact(),"final stays locked while friends are traveling")
 await create_timer(5.0).timeout
 await physics_frame
 check(playable.all_on_stage and not playable.gathering_partners,"all three friends reach the stage")
 check(playable.can_interact(),"final switch opens only after every friend is on stage")
 playable.interact()
 check(Quest.FESTIVAL_COMPLETE in playable.save_data.quest_flags and playable.save_data.ending_seen,"final contribution and ending are recorded")
 var ending_save=service.load_progress(PATH)
 check(ending_save.ok and ending_save.data.checkpoint_id=="b05.stage","final checkpoint persists in the canonical save")
 check(playable.final_panel.visible and playable.paused,"shared festival finale is displayed")
 var final_flags=playable.save_data.quest_flags.duplicate()
 playable.interact()
 check(playable.save_data.quest_flags==final_flags,"completed finale cannot be triggered twice")
 playable.queue_free();await process_frame
 var resumed=load("res://scenes/festival.tscn").instantiate()
 get_root().add_child(resumed)
 await process_frame;await physics_frame
 check(not resumed.blocked and resumed.final_panel.visible and resumed.paused,"saved finale resumes intact from the canonical save")
 check(resumed.all_on_stage and resumed.flower_sprites.all(func(flower):return flower.visible),"reopened festival restores the friends and flowers")
 check(resumed.actor.position.distance_to(Vector2(Festival.FINAL_ANCHOR_X,442.0))<1.0,"final checkpoint restores Catpat on the stage")
 resumed.queue_free();await process_frame
 set_meta("journey_save_path","user://festival_v3.json")
 clean()
 print("FESTIVAL CONTRACT: %d checks, %d failures"%[checks,failures])
 quit(1 if failures else 0)
