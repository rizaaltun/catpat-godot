extends SceneTree
## Default shipping host: dialogue advances with real taps; no E or chapter-button input.
const Save=preload("res://scripts/core/save_service.gd")
const Quest=preload("res://scripts/core/quest_state.gd")
const Replay=preload("res://scripts/core/replay_service.gd")
var PATH="user://shore-flow-render.json" if "--natural-capture" in OS.get_cmdline_user_args() else "user://shore-flow-audit.json"
var checks=0
var failures=0
var host
var tap_ticks=0
func check(ok:bool,label:String):
 checks+=1
 if not ok:failures+=1
 print("PASS " if ok else "FAIL ",label)
func _initialize():call_deferred("run")
func wait_for(test:Callable,frames=1200)->bool:
 for frame in frames:
  await physics_frame
  if test.call():return true
  tap_ticks+=1
  if tap_ticks>=20 and _story_visible():
   _tap_story();tap_ticks=0
 return false
func _story_visible()->bool:
 var world=current_scene
 if not is_instance_valid(world) or host.application_focus_lost:return false
 var flow=host.natural_flow
 return str(flow.value(world,"mode",""))=="dialogue" or bool(flow.value(world,"dialogue_active",false))
func _tap_story():
 var touch=InputEventScreenTouch.new();touch.index=4;touch.position=Vector2(400,500);touch.pressed=true
 root.push_input(touch,true)
 var release=touch.duplicate();release.pressed=false;root.push_input(release,true)
func fixture(chapter:String,stop:String="")->Dictionary:
 var q=Quest.new()
 for event in Quest.HOME_EVENTS:q.apply(event)
 if chapter!="B00":
  var limit=stop if not stop.is_empty() else {"B01":Quest.ACCEPTED,"B02":Quest.COMPLETE,"B03":Quest.RIVER_COMPLETE,"B04":Quest.GARDEN_COMPLETE,"B05":Quest.SUMMIT_COMPLETE}[chapter]
  for event in Quest.EVENTS:
   q.apply(event)
   if event==limit:break
 var d=Save.new().fresh_journey();d.chapter_id=chapter;d.geometry=Replay.ENTRIES[chapter][0];d.checkpoint_id=Replay.ENTRIES[chapter][1]
 d.quest_flags=q.flags;d.party_ids=q.party_ids();d.settings={"onboarding_origin":"new-journey-v1"}
 if chapter=="B04":d.summit=Save.Summit.fresh()
 return d
func boot(chapter:String,data:Dictionary):
 host.auto_observe=false
 if is_instance_valid(current_scene):current_scene.queue_free();await process_frame
 check(Save.new().save(PATH,data),chapter+" production fixture saves")
 set_meta("journey_save_path",PATH);set_meta("journey_autostart",chapter=="B01")
 check(change_scene_to_file(Replay.ENTRIES[chapter][2])==OK,chapter+" production scene opens")
 await process_frame;await physics_frame
 var scene=current_scene;host.auto_observe=true
 return scene
func place(world,point:Vector2):
 world.player.position=point-Vector2(0,1);world.player.velocity=Vector2.ZERO
 for frame in 10:await physics_frame
func capture(tag:String):
 if "--natural-capture" not in OS.get_cmdline_user_args():return
 var folder="res://build/natural-flow"
 DirAccess.make_dir_recursive_absolute(folder)
 await RenderingServer.frame_post_draw
 check(root.get_texture().get_image().save_png(folder+"/"+tag+".png")==OK,tag+" actual shipping frame captures")
 var old_size=root.size
 var display=current_scene.get("control_display")
 var old_touch=display.touch_mode
 display.touch_mode=true;display.refresh();root.size=Vector2i(666,374)
 await process_frame;await RenderingServer.frame_post_draw
 check(root.get_texture().get_image().save_png(folder+"/"+tag+"-touch.png")==OK,tag+" narrow touch frame captures")
 root.size=old_size;display.touch_mode=old_touch;display.refresh()
 await process_frame
func after_presentation():
 if DisplayServer.get_name()=="headless":await create_timer(0).timeout
 else:await RenderingServer.frame_post_draw
func run():
 var metadata=Replay.new().metadata_snapshot()
 host=root.get_node("CatpatExperience");host.auto_observe=true
 if has_meta("manual_story_flow"):remove_meta("manual_story_flow")
 for suffix in Replay.SLOT_SUFFIXES:DirAccess.remove_absolute(PATH+suffix)
 var home=await boot("B00",Save.new().fresh_journey())
 check(await wait_for(func():return home.state.has(Quest.INVITATION),180),"B00 invitation continues without a click")
 check(not home.paused and not home.player.frozen,"B00 invitation releases movement")
 await capture("B00-grounded-home")
 if "--natural-home-only" in OS.get_cmdline_user_args():
  print("NATURAL FLOW: HOME ",checks," checks, ",failures," failures");quit(1 if failures else 0);return
 var d=fixture("B00");d.checkpoint_id="b00.exit";home=await boot("B00",d)
 await place(home,home.EXIT_POINT)
 check(await wait_for(func():return is_instance_valid(current_scene) and current_scene.scene_file_path==Replay.ENTRIES.B01[2],180),"B00 exit enters B01 without a button")
 d=fixture("B01",Quest.COMPLETE);d.checkpoint_id="b01.island.8"
 var rejected_forest=await boot("B01",d);rejected_forest.director.transitioning=true
 for frame in 90:await physics_frame
 check(current_scene==rejected_forest and rejected_forest.screen.visible,"rejected automatic preparation restores visible recovery controls")
 check(Save.new().load_progress(PATH).data.chapter_id=="B01","rejected automatic preparation leaves journey untouched")
 rejected_forest.director.transitioning=false;rejected_forest.go_river()
 check(await wait_for(func():return is_instance_valid(current_scene) and current_scene.scene_file_path==Replay.ENTRIES.B02[2],180),"explicit retry can recover a rejected automatic preparation")
 d=fixture("B01",Quest.LIGHTS[1]);d.checkpoint_id="b01.island.6"
 var forest=await boot("B01",d)
 check(await wait_for(func():return forest.joined,180),"B01 final lamp lights and recruits Porsuk without E")
 forest.friend.frozen=true;forest.friend.position=Vector2(200,580)
 await place(forest,Vector2(3860,570))
 check(await wait_for(func():return is_instance_valid(current_scene) and current_scene.scene_file_path==Replay.ENTRIES.B02[2],720),"B01 stranded Porsuk cannot block automatic exit and transition")
 var river=current_scene
 for frame in 60:await physics_frame
 check(river.monkey.has_meta("natural_greeted"),"entry NPC greets using existing action image frames")
 check(await wait_for(func():return river.monkey.performance_state.is_empty(),240),"NPC greeting returns to its normal idle")
 await after_presentation()
 var offset=river.monkey.anim.offset
 for frame in 15:await process_frame
 await after_presentation()
 check(river.monkey.anim.offset!=offset,"unrecruited NPC has living idle motion at entry")
 check(river.backdrop.get_parent() is CanvasLayer and river.backdrop.position.y==0,"B02 background has one viewport-space owner")
 await capture("B02-entry")
 var preferences=root.get_meta("catpat_preferences",{}).duplicate(true)
 var reduced=preferences.duplicate(true);reduced.reduced_motion=true;root.set_meta("catpat_preferences",reduced)
 for frame in 10:await physics_frame
 check(river.monkey.anim.offset==Vector2.ZERO and river.monkey.anim.rotation==0,"reduced motion restores NPC anatomical baseline")
 root.set_meta("catpat_preferences",preferences)
 var scenery=river.backdrop.position
 river.pause_game()
 for frame in 30:await physics_frame
 check(river.backdrop.position==scenery,"B02 paused background cannot receive old world-space updates")
 await capture("B02-paused-scenery")
 river.resume()
 await place(river,Vector2(800,520))
 check(river.mode=="dialogue","B02 approaching Maymun starts the story without E")
 await capture("B02-tap-dialogue")
 var line=river.runner.current.id
 for frame in 180:await physics_frame
 check(river.runner.current.id==line and not river.state.has(Quest.RIVER_ACCEPTED),"visible dialogue never advances on a timer")
 var cancelled=InputEventScreenTouch.new();cancelled.position=Vector2(400,500);cancelled.index=7;cancelled.pressed=true;cancelled.canceled=true
 var untouched=FileAccess.get_file_as_bytes(PATH)
 root.push_input(cancelled,true);await physics_frame
 check(river.runner.current.id==line and FileAccess.get_file_as_bytes(PATH)==untouched,"cancelled touch cannot advance story or mutate saved progress")
 _tap_story()
 await physics_frame
 check(river.runner.current.id!=line,"a real screen touch advances dialogue")
 line=river.runner.current.id
 for frame in 20:await physics_frame
 var mouse=InputEventMouseButton.new();mouse.position=Vector2(400,500);mouse.button_index=MOUSE_BUTTON_LEFT;mouse.pressed=true;mouse.device=InputEvent.DEVICE_ID_EMULATION
 root.push_input(mouse,true);await physics_frame
 check(river.runner.current.id==line,"emulated mouse cannot duplicate a touch advance")
 mouse=mouse.duplicate();mouse.device=0;root.push_input(mouse,true)
 mouse=mouse.duplicate();mouse.pressed=false;root.push_input(mouse,true);await physics_frame
 check(river.runner.current.id!=line,"desktop click anywhere also advances once")
 line=river.runner.current.id
 scenery=river.backdrop.position
 host._notification(Node.NOTIFICATION_WM_WINDOW_FOCUS_OUT)
 _tap_story() # A late touch from the covered canvas must also be ignored.
 for frame in 180:await physics_frame
 check(river.runner.current.id==line and not river.state.has(Quest.RIVER_ACCEPTED),"hidden window cannot advance tap dialogue")
 var hidden_key=InputEventKey.new();hidden_key.keycode=KEY_ENTER;hidden_key.pressed=true
 root.push_input(hidden_key,true);await physics_frame
 check(river.runner.current.id==line and FileAccess.get_file_as_bytes(PATH)==untouched,"hidden window cannot advance dialogue through keyboard input")
 check(river.backdrop.position==scenery,"B02 focus loss preserves stable scenery")
 host._notification(Node.NOTIFICATION_WM_WINDOW_FOCUS_IN)
 check(await wait_for(func():return river.state.has(Quest.RIVER_ACCEPTED),720),"B02 dialogue resumes and completes with taps")
 await place(river,Vector2(1100,520))
 river.jump=true
 var stable=true
 for frame in 70:
  if frame==25:river.jump=false
  await physics_frame
  stable=stable and river.backdrop.position.y==0 and river.backdrop.get_parent() is CanvasLayer
 check(stable,"B02 jumping camera cannot move the background vertically")
 await place(river,Vector2(2110,360))
 check(await wait_for(func():return river.state.has(Quest.ROPE),120),"B02 rope pickup requires no E")
 await place(river,Vector2(2250,600))
 check(await wait_for(func():return river.state.has(Quest.MONKEY),900),"B02 planks, repair and invitation complete without repeat interactions")
 await place(river,Vector2(3250,520))
 check(await wait_for(func():return is_instance_valid(current_scene) and current_scene.scene_file_path==Replay.ENTRIES.B03[2],600),"B02 advances to B03 automatically")
 var garden=current_scene
 var before:PackedByteArray
 await place(garden,Vector2(730,540))
 check(await wait_for(func():return garden.state.has(Quest.GARDEN_ACCEPTED),720),"B03 proximity introduction completes with taps")
 await place(garden,Vector2(1740,320))
 check(await wait_for(func():return garden.mode=="lowering",120),"B03 approaching the rope starts basket lowering")
 garden.saves.fault="rename"
 check(await wait_for(func():return garden.mode=="save_error",240),"B03 interrupted lowering exposes a recoverable save error")
 scenery=garden.backdrop.position
 for frame in 90:await physics_frame
 check(garden.backdrop.position==scenery,"B03 save-error screen keeps background stable")
 check(garden.mode=="save_error" and not garden.state.has(Quest.LOWERED),"automatic flow cannot skip failed durable lowering")
 garden.saves.fault="";garden.retry_save()
 check(garden.mode=="play" and garden.state.has(Quest.LOWERED) and is_instance_valid(garden.hint),"B03 lowering retry restores a usable HUD and controls")
 for item in [{"flag":Quest.TIE,"point":Vector2(1960,580),"name":"tie"},{"flag":Quest.BASKET,"point":Vector2(2310,600),"name":"basket"}]:
  garden.saves.fault="rename";before=FileAccess.get_file_as_bytes(PATH)
  await place(garden,item.point)
  check(await wait_for(func():return garden.mode=="save_error",120),"B03 "+item.name+" automatic pickup exposes save rejection")
  check(not garden.state.has(item.flag) and FileAccess.get_file_as_bytes(PATH)==before,"B03 "+item.name+" failed pickup preserves bytes and item")
  garden.saves.fault="";garden.retry_save()
  check(garden.state.has(item.flag) and is_instance_valid(garden.hint),"B03 "+item.name+" retry restores live controls and one durable pickup")
 check(await wait_for(func():return garden.state.has(Quest.RABBIT),900),"B03 delivery, repair and joining require no E")
 check(not garden.player.frozen and garden.mode=="play","B03 reunion never freezes the player")
 check(garden.player.position.x>2100,"B03 repair no longer requires returning to Pıtpıt")
 check(await garden.hop_to(Vector2(2540,540)),"B03 player can jump from basket bank onto the opened path")
 await capture("B03-forward-repair")
 await place(garden,Vector2(3760,540))
 check(await wait_for(func():return is_instance_valid(current_scene) and current_scene.scene_file_path==Replay.ENTRIES.B04[2],600),"B03 automatically enters B04 after its story")
 d=fixture("B04")
 var beginning=await boot("B04",d)
 check(await wait_for(func():return beginning.lantern_stage=="accepted",240),"B04 short welcome waits for genuine touch")
 check(not beginning.save_notice.visible and not beginning.controls_hint_panel.visible and not beginning.status.visible,"B04 shipping HUD hides routine save and technical text")
 beginning.safe_facing=-1 # Change a real checkpoint field; identical writes intentionally bypass disk.
 beginning.save_service.fault="write";before=FileAccess.get_file_as_bytes(PATH)
 check(not beginning.commit_checkpoint(),"B04 checkpoint write fault rejects the save")
 await process_frame
 await process_frame
 check(beginning.save_notice.visible and beginning.save_notice_panel.visible and FileAccess.get_file_as_bytes(PATH)==before,"B04 compact HUD preserves checkpoint warning and last saved bytes")
 beginning.save_service.fault=""
 check(beginning.commit_checkpoint(),"B04 checkpoint can retry after storage recovers")
 await process_frame
 await process_frame
 check(not beginning.save_notice.visible,"B04 routine checkpoint notice hides again after successful retry")
 await capture("B04-safe-starting-shore")
 await place(beginning,beginning.LANTERN_POINT)
 check(await wait_for(func():return beginning.lantern_stage=="lit",300),"B04 lantern completes on the broad shore without returning")
 for frame in 30:await physics_frame
 check(beginning.rope_stage=="loose" and beginning.coil.visible,"B04 next object stays distinct and requires a forward step after lantern")
 await capture("B04-first-bridge-open")
 beginning=await boot("B04",fixture("B04"))
 await place(beginning,Vector2(beginning.team[2].position.x+30,540))
 check(await wait_for(func():return beginning.dialogue_active,180),"B04 approaching Porsuk starts tap dialogue")
 beginning.cancel_dialogue()
 for frame in 90:await physics_frame
 check(not beginning.dialogue_active and not beginning.paused,"cancelling tap dialogue cannot trap the player in a reopen loop")
 d=fixture("B04",Quest.SUMMIT_COMPLETE);d.checkpoint_id="b04.bank.2";d.summit={"bank":2,"facing":1,"lantern":"lit","rope":"ready","waymark":"seen"}
 var summit=await boot("B04",d)
 var rejected=[0]
 summit.festival_change=func(_scene):rejected[0]+=1;return ERR_CANT_OPEN
 before=FileAccess.get_file_as_bytes(PATH)
 await place(summit,summit.LOOKOUT_POINT)
 for frame in 90:await physics_frame
 check(rejected[0]==1 and not summit.quest_error.is_empty(),"failed B04 auto-navigation stops after one attempt")
 check(FileAccess.get_file_as_bytes(PATH)==before,"failed automatic navigation restores exact primary bytes")
 summit.festival_change=Callable();summit.quest_error="";summit.interact()
 check(await wait_for(func():return is_instance_valid(current_scene) and current_scene.scene_file_path==Replay.ENTRIES.B05[2],300),"B04 completed lookout enters festival without E")
 check(Save.new().load_progress(PATH).data.chapter_id=="B05","automatic chapter chain keeps canonical save at the destination")
 var first_festival=current_scene
 await after_presentation()
 var partner_offset=first_festival.partner_sprites[0].offset
 for frame in 15:await process_frame
 await after_presentation()
 check(first_festival.partner_sprites[0].offset!=partner_offset,"festival image partners stay visually alive while waiting")
 await capture("B05-entry-life")
 first_festival.status="Kayıt yapılamadı. Görev tamamlanmadı, yeniden dene."
 first_festival.actor.position=Vector2(1150,445);first_festival.actor.velocity=Vector2.ZERO
 before=FileAccess.get_file_as_bytes(PATH)
 for frame in 90:await physics_frame
 check(first_festival.near_task==0 and Quest.FESTIVAL_LIGHT not in first_festival.save_data.quest_flags,"B05 error state cannot retry its task every frame")
 check(FileAccess.get_file_as_bytes(PATH)==before,"B05 stopped automatic retries preserve save bytes")
 first_festival.interact()
 check(Quest.FESTIVAL_LIGHT in first_festival.save_data.quest_flags,"B05 explicit recovery action still retries successfully")
 d=fixture("B05",Quest.FESTIVAL_COMPLETE);d.checkpoint_id="b05.stage";d.ending_seen=true
 var festival=await boot("B05",d)
 for frame in 10:await physics_frame
 festival.interact()
 check(festival.final_panel.visible,"completed festival can still replay its finale explicitly")
 festival.leave_final()
 for frame in 90:await physics_frame
 check(not festival.final_panel.visible and not festival.paused and not festival.actor.frozen,"leaving completed finale cannot auto-reopen a movement lock")
 if is_instance_valid(current_scene):current_scene.queue_free();await process_frame
 Replay.new().restore_metadata(metadata)
 for suffix in Replay.SLOT_SUFFIXES:DirAccess.remove_absolute(PATH+suffix)
 var audio=root.get_node_or_null("CatpatAudio")
 if is_instance_valid(audio):audio.shutdown()
 # The audio mixer releases stopped Ogg playback on its own thread.
 # Use elapsed time, as eight rendered frames can be <70ms on CI.
 await create_timer(0.35).timeout
 print("NATURAL FLOW: %d checks, %d failures"%[checks,failures])
 quit(1 if failures else 0)
