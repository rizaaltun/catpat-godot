extends SceneTree
## Native B03 entry/comic/protected-party visual evidence. Existing v21 exit/pause
## captures remain separate. Fixtures are explicitly saved visual states, not a
## replacement for the full natural B03 gameplay regression.
const Store=preload("res://scripts/core/save_service.gd")
const Quest=preload("res://scripts/core/quest_state.gd")
const PATH="user://b03-visual-capture-v23.json"
var failures=0
var checks=0
var captures=0
var states=0
var game:Node
var check_only=false
func _initialize():
 check_only="--garden-capture-check" in OS.get_cmdline_user_args()
 call_deferred("run")
func check(ok:bool,label:String):
 checks+=1
 if not ok:
  failures+=1;push_error("FAIL "+label)
 else:print("PASS "+label)
func ticks(count:int):
 for i in count:await physics_frame
func clean():
 for suffix in ["",".bak",".pending",".bak.pending",".legacy"]:
  var path=ProjectSettings.globalize_path(PATH+suffix)
  if FileAccess.file_exists(path):DirAccess.remove_absolute(path)
func fixture(protected:bool)->Dictionary:
 var state=Quest.new()
 var prerequisites=[Quest.ACCEPTED]+Quest.LIGHTS+[Quest.JOINED,Quest.COMPLETE]+Quest.RIVER_EVENTS
 if protected:prerequisites += [Quest.GARDEN_ACCEPTED,Quest.TIE,Quest.RELEASED,Quest.LOWERED,Quest.BASKET,Quest.GARDEN_SUPPLIED,Quest.PROTECTED]
 for id in prerequisites:
  if not state.apply(id):check(false,"visual fixture prerequisite "+id);return {}
 var data=Store.new().fresh()
 data.chapter_id="B03";data.geometry="garden-v12";data.checkpoint_id="b03.hub" if protected else "b03.entry"
 data.quest_flags=state.flags.duplicate();data.party_ids=state.party_ids();data.settings={"music":false,"sfx":false}
 return data
func open_fixture(protected:bool)->bool:
 if is_instance_valid(game):
  current_scene=null;game.queue_free();await process_frame
 clean()
 var data=fixture(protected)
 var valid=Store.new().valid(data)
 check(valid,"B03 "+("protected" if protected else "entry")+" visual fixture validates as a real canonical save")
 if not valid:return false
 var saved=Store.new().save(PATH,data)
 check(saved,"B03 visual fixture writes only isolated user data")
 if not saved:return false
 set_meta("journey_save_path",PATH)
 game=load("res://scenes/garden.tscn").instantiate();root.add_child(game);current_scene=game
 await ticks(40)
 var ready=game.mode=="play" and is_instance_valid(game.player) and game.player.is_on_floor()
 check(ready,"B03 opens through its normal saved-scene gate and settles on the ground")
 return ready
func capture(tag:String,small:bool,comic:bool=false):
 var expected=Vector2i(666,374) if small else Vector2i(1280,720)
 root.size=expected
 if not comic:
  game.control_display.touch_mode=small;game.control_display.refresh()
 await process_frame
 check(root.size==expected,tag+" has expected logical window dimensions")
 if comic:
  check(game.mode=="dialogue" and is_instance_valid(game.comic) and is_instance_valid(game.active_line),tag+" has a real active garden comic")
  check(not game.active_line.text.is_empty() and game.active_line.visible_characters==-1,tag+" shows the full current dialogue text")
 else:
  check(game.mode=="play" and is_instance_valid(game.quest) and not game.quest.text.is_empty(),tag+" shows the active objective HUD")
  if small:
   var safe=Rect2(0,0,1280,720)
   check(game.control_display.buttons.all(func(button):return is_instance_valid(button) and button.visible and safe.encloses(button.get_global_rect())),tag+" touch controls fit in the scaled game canvas")
 states+=1
 if check_only:
  print("B03_CAPTURE_FIXTURE_ONLY:"+tag+":no native frame requested")
  return
 await RenderingServer.frame_post_draw
 var frame=root.get_texture().get_image()
 print("CAPTURE_DIMENSIONS:B03-"+tag+":image="+str(frame.get_size())+":window="+str(DisplayServer.window_get_size())+":root="+str(root.size))
 check(not frame.is_empty(),tag+" native viewport image exists")
 if frame.is_empty():return
 var encoded=Marshalls.raw_to_base64(frame.save_webp_to_buffer(true,0.82))
 check(not encoded.is_empty(),tag+" native viewport encodes to WebP")
 captures+=1
 print("VISUAL_CAPTURE:B03-"+tag+":"+encoded)
func capture_pair(tag:String,comic:bool=false):
 await capture(tag,false,comic)
 await capture(tag+"-touch-small",true,comic)
 root.size=Vector2i(1280,720)
 if not comic:game.control_display.touch_mode=false;game.control_display.refresh()
 await process_frame
func finish_dialogue():
 for i in 12:
  if game.mode!="dialogue":break
  game.runner.revealed=true;game.runner.input_cooldown=0.0;game.advance()
  await process_frame
func run():
 root.size=Vector2i(1280,720)
 if not await open_fixture(false):await finish();return
 check(game.state.has(Quest.RIVER_COMPLETE) and not game.state.has(Quest.GARDEN_ACCEPTED),"entry fixture retains earlier chapters without pretending the garden was played")
 await capture_pair("entry-active")
 check(await game.walk_to(730),"visual route physically walks to Pıtpıt")
 await game.use_action()
 check(game.mode=="dialogue" and game.runner.current.id=="garden_meet_0","proximity interaction opens the actual first Pıtpıt comic")
 if game.mode!="dialogue":await finish();return
 game.runner.revealed=true
 await process_frame
 await capture_pair("meet-comic",true)
 if not await open_fixture(true):await finish();return
 check(game.state.has(Quest.PROTECTED) and not game.state.has(Quest.RABBIT) and game.level.ready_bridge and game.delivered_basket.visible,"explicit protected fixture restores the windscreen, basket and safe walkway before recruitment")
 await game.use_action()
 check(game.mode=="dialogue" and game.runner.current.id=="garden_join_0","protected Pıtpıt is recruited through the real contextual dialogue")
 if game.mode!="dialogue":await finish();return
 await finish_dialogue()
 for i in 300:
  if game.mode=="play":break
  await physics_frame
 check(game.mode=="play" and game.state.has(Quest.RABBIT) and game.data.party_ids==["badger","monkey","rabbit"],"recruitment commits and the four-character party naturally gathers")
 var loaded=Store.new().load_progress(PATH)
 check(loaded.ok and Quest.RABBIT in loaded.data.quest_flags,"recruitment screenshot is backed by the actual saved event")
 await capture_pair("protected-party")
 await finish()
func finish():
 if is_instance_valid(game):current_scene=null;game.queue_free();await process_frame
 clean()
 var audio=root.get_node_or_null("CatpatAudio")
 if audio and audio.has_method("shutdown"):audio.shutdown();await create_timer(0.2).timeout
 print("B03 VISUAL CAPTURE: %d frames, %d states, %d checks, %d failures%s"%[captures,states,checks,failures,"; headless fixture/layout check only" if check_only else ""])
 quit(1 if failures or states!=6 or (not check_only and captures!=6) else 0)
