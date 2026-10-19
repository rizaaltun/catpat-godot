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
 playable.actor.position=Vector2(1150.0,584.0);playable.actor.velocity=Vector2.ZERO
 await physics_frame
 check(not playable.can_interact(),"walking below a station does not complete its task")
 playable.actor.position=Vector2(1150.0,414.0);playable.actor.velocity=Vector2.ZERO
 await physics_frame
 check(playable.near_task==0 and playable.can_interact(),"Porsuk station is reachable from its raised platform")
 playable.interact()
 check(Quest.FESTIVAL_LIGHT in playable.save_data.quest_flags,"station interaction records the light contribution")
 var station_save=service.load_progress(PATH)
 check(station_save.ok and station_save.data.checkpoint_id=="b05.lights","station contribution persists its checkpoint")
 playable.actor.position=Vector2(3310.0,422.0);playable.actor.velocity=Vector2.ZERO
 await physics_frame
 check(playable.near_task==2 and playable.can_interact(),"Pıtpıt station is reachable from its raised platform")
 playable.interact()
 check(Quest.FESTIVAL_FLOWERS in playable.save_data.quest_flags and playable.flower_sprites.all(func(flower):return flower.visible),"flower contribution persists and appears in the world")
 var flower_save=service.load_progress(PATH)
 check(flower_save.ok and flower_save.data.checkpoint_id=="b05.flowers","flower contribution persists its checkpoint")
 playable.queue_free();await process_frame
 set_meta("journey_save_path","user://festival_v3.json")
 clean()
 print("FESTIVAL CONTRACT: %d checks, %d failures"%[checks,failures])
 quit(1 if failures else 0)
