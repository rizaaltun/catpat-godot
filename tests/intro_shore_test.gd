extends SceneTree
## Actual production B04: shore action, durable unlock, continuous first crossing.
const Store=preload("res://scripts/core/save_service.gd")
const Quest=preload("res://scripts/core/quest_state.gd")
const Replay=preload("res://scripts/core/replay_service.gd")
const Route=preload("res://scripts/chapters/summit_main.gd")
const PATH="user://intro-shore-contract.json"
var checks=0
var failures=0
var route
func _initialize():call_deferred("run")
func check(ok:bool,label:String):
 checks+=1
 if not ok:failures+=1
 print("PASS " if ok else "FAIL ",label)
func ticks(count:int):
 for frame in count:await physics_frame
func clean():
 for suffix in Replay.SLOT_SUFFIXES:DirAccess.remove_absolute(PATH+suffix)
func tap_dialogue():
 await ticks(20)
 if route.dialogue_active:route.advance_dialogue()
 await ticks(20)
func capture(tag:String):
 if "--intro-capture" not in OS.get_cmdline_user_args():return
 DirAccess.make_dir_recursive_absolute("res://build/intro-shore")
 await RenderingServer.frame_post_draw
 check(root.get_texture().get_image().save_png("res://build/intro-shore/"+tag+".png")==OK,tag+" native production frame captures")
func run():
 clean()
 var previous=Replay.new().metadata_snapshot()
 var manual_before=get_meta("manual_story_flow",false)
 set_meta("manual_story_flow",true)
 var experience=root.get_node_or_null("CatpatExperience")
 var observed=experience.auto_observe if experience else false
 if experience:experience.auto_observe=false
 var q=Quest.new()
 for event in Quest.EVENTS:
  if event==Quest.SUMMIT_COMPLETE:break
  q.apply(event)
 var data=Store.new().fresh();data.chapter_id="B04";data.geometry="shared-v16";data.checkpoint_id="b04.bank.0"
 data.quest_flags=q.flags;data.party_ids=q.party_ids();data.summit=Store.Summit.fresh()
 check(Store.new().save(PATH,data),"real B04 entry passes canonical save gate")
 set_meta("journey_save_path",PATH)
 route=Route.new();root.add_child(route);current_scene=route;route.driver=true
 await ticks(35)
 check(route.player.position.x<route.team[2].position.x and route.player.position.x<route.LANTERN_POINT.x and not route.at_lantern(),"fresh player meets Porsuk ahead and must move forward for the lid")
 check(route.LANTERN_POINT==Vector2(560,540) and route.lamp.position.y<540,"first lantern is on the safe main shore")
 check(route.intro_bridge.collision_layer==0 and not route.intro_bridge.visible,"first crossing waits for the actual lantern task")
 check(not route.carriers[0].enabled and route.carriers[0].collision_layer==0,"intro has no timed moving-platform collision")
 await route.walk_to(route.team[2].position.x-165);await ticks(25);route.interact();await tap_dialogue()
 await capture("B04-intro-shore-before-lid")
 check(route.lantern_stage=="accepted","short Porsuk introduction preserves quest progression")
 check(await route.walk_to(560) and route.at_lantern(),"player reaches lid by walking on the same safe shore")
 var before=FileAccess.get_file_as_bytes(PATH)
 route.save_service.fault="write";route.interact();await ticks(25)
 check(route.lantern_stage=="accepted" and not route.dialogue_active and FileAccess.get_file_as_bytes(PATH)==before,"rejected lid save cannot unlock a bridge or start success dialogue")
 route.save_service.fault="";route.interact();await ticks(25)
 check(route.lantern_stage=="prepared" and route.dialogue_active,"successful lid action immediately brings Porsuk's help without a return")
 check(route.intro_bridge.collision_layer==0,"prepared lid alone cannot open the crossing")
 route.cancel_dialogue();route.set_pause(true);route.reload_checkpoint();await ticks(30)
 check(route.lantern_stage=="prepared" and route.intro_bridge.collision_layer==0,"historical/mid-task prepared save reloads without fake completion")
 await route.walk_to(560);await ticks(25);route.interact();await tap_dialogue()
 check(route.lantern_stage=="lit" and route.intro_bridge.visible and route.intro_bridge.collision_layer==1,"finishing Porsuk's story durably opens the permanent bridge")
 check(route.intro_bridge_art.texture.resource_path=="res://assets/chapter-v11/bridge.webp" and route.party.walkable_first_gap,"production bridge uses existing artwork and physical walking AI")
 check(not route.carriers[1].enabled and route.rope_stage=="loose","later rope repair and second carrier challenge remain locked")
 check(await route.walk_to(900,600),"player walks onto the broad firstbridge without a jump")
 await capture("B04-first-bridge-open")
 check(await route.walk_to(1700,900),"player walks across first gap without jump or carrier timing")
 check(await route.wait_for_team(1,1500),"all three companions physically follow onto the middle shore")
 check(route.party.reservations[0]==-1 and not route.party.events.any(func(event):return event.get("event","")=="reserve" and event.get("surface",-1)==0),"first crossing does not reserve an invisible carrier")
 check(route.saved_bank==1 and Store.new().load_progress(PATH).data.summit.lantern=="lit","middle shore checkpoint retains durable lantern unlock")
 var recovering=route.party.members[0]
 recovering.position=Vector2(900,539);recovering.velocity=Vector2.ZERO
 route.party.states[0].phase="bank"
 check(await route.wait_for_team(1,1500),"a friend caught early on the new bridge resumes physical walking instead of waiting forever")
 check(await route.walk_to(400,900) and await route.wait_for_team(0,1500),"whole party can walk back over the permanent bridge")
 check(await route.walk_to(1700,900) and await route.wait_for_team(1,1500),"first bridge remains usable in both directions")
 route.set_pause(true);route.reload_checkpoint();await ticks(30)
 check(route.saved_bank==1 and route.party.walkable_first_gap and route.intro_bridge.collision_layer==1 and route.team.all(func(actor):return route.party.bank_of(actor)==1),"old bank anchors reconstruct the open bridge and reunited party")
 var legacy=Store.new().load_progress(PATH).data
 legacy.summit.lantern="prepared";legacy.summit.rope="loose";legacy.summit.waymark="loose"
 check(Store.new().save(PATH,legacy),"historical unfinished-lantern middle-shore save remains readable")
 route.set_pause(true);route.reload_checkpoint();await ticks(30)
 check(route.intro_return_access and route.intro_bridge.collision_layer==1 and route.lantern_stage=="prepared","old offshore save gets safe return access without fake lantern completion")
 check(await route.walk_to(560,900) and route.at_lantern(),"old unfinished save can walk back to its real lantern task")
 route.queue_free();await process_frame
 Replay.new().restore_metadata(previous)
 set_meta("manual_story_flow",manual_before)
 if experience:experience.auto_observe=observed
 clean()
 print("INTRO SHORE: %d checks, %d failures"%[checks,failures])
 quit(1 if failures else 0)
