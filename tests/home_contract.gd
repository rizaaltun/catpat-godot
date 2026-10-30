extends SceneTree
const Save=preload("res://scripts/core/save_service.gd")
const Quest=preload("res://scripts/core/quest_state.gd")
const PATH="user://home-contract-test.json"
var checks=0
var failures=0
var home
var experience
func _initialize():call_deferred("run")
func check(ok:bool,label:String):
 checks+=1
 if not ok:failures+=1
 print("PASS " if ok else "FAIL ",label)
func ticks(n:int):
 for i in n:await physics_frame
func clean():
 for suffix in ["",".bak",".pending",".bak.pending",".legacy",".onboarding-v1.original",".onboarding-v1.original.pending"]:DirAccess.remove_absolute(PATH+suffix)
func key(code:int,pressed:bool):
 var event=InputEventKey.new();event.keycode=code;event.pressed=pressed;home._input(event)
func walk_to(target:float,limit:int=700)->bool:
 for i in limit:
  var dx=target-home.player.position.x
  home.keys[KEY_D]=dx>7;home.keys[KEY_A]=dx< -7
  await physics_frame
  if absf(dx)<8 and home.player.is_on_floor():
   home.keys[KEY_D]=false;home.keys[KEY_A]=false;await ticks(12);return true
 home.keys.clear();return false
func jump_right(held_frames:int,move_frames:int):
 key(KEY_D,true);key(KEY_SPACE,true);await ticks(held_frames);key(KEY_SPACE,false)
 await ticks(maxi(0,move_frames-held_frames));key(KEY_D,false)
 for i in 100:
  await physics_frame
  if home.player.is_on_floor():break
 await ticks(3)
func verify_actor_controls(tag:String):
 var previous=home.data.settings.duplicate(true)
 var old_touch=home.control_display.touch_mode
 var old_size=root.size
 home.control_display.touch_mode=true
 for viewport in [Vector2i(1280,720),Vector2i(666,374)]:
  root.size=viewport
  for profile in [{"name":"normal"},{"name":"max-right","text_scale":1.3,"control_scale":1.3},{"name":"max-left","text_scale":1.3,"control_scale":1.3,"left_handed":true}]:
   experience.apply_to_scene(home,profile)
   home.control_display.refresh();home.update_hud()
   await ticks(40)
   # A conservative body envelope, projected to the same viewport canvas as UI.
   var actor_bounds=home.player.get_global_transform_with_canvas()*Rect2(-65,-150,130,150)
   var clear=true
   var overlapping=[]
   for button in home.control_display.buttons+[home.action_button]:
    if button.is_visible_in_tree() and actor_bounds.intersects(button.get_global_transform_with_canvas()*Rect2(Vector2.ZERO,button.size)):
     clear=false;overlapping.append(button.text)
   check(clear,"B00 "+tag+" "+profile.name+" "+str(viewport)+" actor clears visible touch controls "+str(overlapping)+" actor="+str(actor_bounds))
   if viewport.x==666 and profile.name!="normal" and "--home-capture" in OS.get_cmdline_user_args():
    await process_frame
    await RenderingServer.frame_post_draw
    var image=root.get_texture().get_image()
    check(not image.is_empty(),"B00 "+tag+" "+profile.name+" narrow real frame renders")
    print("VISUAL_CAPTURE:B00-small-"+tag+"-"+profile.name+":"+Marshalls.raw_to_base64(image.save_webp_to_buffer(true,0.82)))
 root.size=old_size
 experience.apply_to_scene(home,previous)
 home.control_display.touch_mode=old_touch;home.control_display.refresh();home.update_hud()
 await ticks(20)
func verify_upper_jump_frame():
 var previous=home.data.settings.duplicate(true)
 var old_size=root.size
 var old_touch=home.control_display.touch_mode
 home.control_display.touch_mode=true;home.control_display.refresh()
 for viewport in [Vector2i(1280,720),Vector2i(666,374)]:
  root.size=viewport
  for profile in [{"name":"normal"},{"name":"max-right","text_scale":1.3,"control_scale":1.3},{"name":"max-left","text_scale":1.3,"control_scale":1.3,"left_handed":true}]:
   experience.apply_to_scene(home,profile);home.update_hud();await ticks(40)
   var contained=true
   var highest=720.0
   var hud_clear=true
   home.keys[KEY_SPACE]=true
   for frame in 85:
    if frame==35:home.keys[KEY_SPACE]=false
    await physics_frame
    experience._refresh_expanded_hud(home)
    var body=home.player.get_global_transform_with_canvas()*Rect2(-65,-150,130,150)
    contained=contained and Rect2(0,0,1280,720).encloses(body)
    highest=minf(highest,body.position.y)
    var cards=[home.hud_panel,home.hint_panel]
    for card in experience.hud_cards.values():cards.append(card)
    for card in cards:
     if is_instance_valid(card) and card.is_visible_in_tree() and body.intersects(card.get_global_transform_with_canvas()*Rect2(Vector2.ZERO,card.size)):
      if hud_clear:print("B00 UPPER OVERLAP ",profile.name," frame=",frame," card=",card.name," cardrect=",card.get_rect()," body=",body)
      hud_clear=false
    if frame==27 and "--home-capture" in OS.get_cmdline_user_args():
     await process_frame
     await RenderingServer.frame_post_draw
     var image=root.get_texture().get_image()
     check(not image.is_empty(),"B00 upper jump "+profile.name+" real apex frame renders")
     print("VISUAL_CAPTURE:B00-upper-jump-"+str(viewport.x)+"-"+profile.name+":"+Marshalls.raw_to_base64(image.save_webp_to_buffer(true,0.82)))
   check(contained and hud_clear,"B00 upper jump "+profile.name+" "+str(viewport)+" stays in viewport and clears visible HUD; bodytop="+str(highest))
   check(home.player.is_on_floor() and absf(home.player.position.y-500)<3,"B00 upper branch "+profile.name+" jump lands back on unchanged platform")
 root.size=old_size
 home.control_display.touch_mode=old_touch;home.control_display.refresh()
 experience.apply_to_scene(home,previous);home.update_hud();await ticks(40)
func capture(tag:String):
 if "--home-capture" not in OS.get_cmdline_user_args():return
 await process_frame
 await RenderingServer.frame_post_draw
 var shot=root.get_texture().get_image()
 check(not shot.is_empty(),"B00 "+tag+" renders a real viewport")
 print("VISUAL_CAPTURE:B00-"+tag+":"+Marshalls.raw_to_base64(shot.save_webp_to_buffer(true,0.82)))
 var old_size=root.size;var old_touch=home.control_display.touch_mode
 root.size=Vector2i(666,374);home.control_display.touch_mode=true;home.control_display.refresh();home.update_hud()
 await process_frame
 await RenderingServer.frame_post_draw
 var small=root.get_texture().get_image()
 var safe=Rect2(0,0,1280,720)
 check(not small.is_empty() and root.size==Vector2i(666,374),"B00 "+tag+" narrow viewport renders")
 check(home.control_display.buttons.all(func(b):return b.visible and safe.encloses(b.get_rect()) and b.size.y*374/720>=56),"B00 "+tag+" touch targets fit and exceed56 viewport pixels")
 print("VISUAL_CAPTURE:B00-small-"+tag+":"+Marshalls.raw_to_base64(small.save_webp_to_buffer(true,0.82)))
 root.size=old_size;home.control_display.touch_mode=old_touch;home.control_display.refresh();home.update_hud();await process_frame
func run():
 var host_experience=root.get_node_or_null("CatpatExperience")
 if host_experience:host_experience.auto_observe=false
 experience=preload("res://scripts/core/experience_service.gd").new();experience.auto_observe=false;root.add_child(experience)
 clean()
 var service=Save.new()
 var data=service.fresh_journey()
 check(service.valid(data) and data.chapter_id=="B00" and data.quest_flags.is_empty(),"new journey starts in B00 without invented learning")
 var order=Quest.new()
 check(not order.apply(Quest.WALK) and not order.apply(Quest.HOME_EXIT),"tutorial cannot finish before invitation and movement")
 var wrong=data.duplicate(true);wrong.party_ids=["badger"]
 check(not service.valid(wrong),"B00 cannot invent a companion")
 wrong=data.duplicate(true);wrong.checkpoint_id="b00.exit"
 check(not service.valid(wrong),"unlearned tutorial cannot claim the exit checkpoint")
 var old=service.fresh();old.checkpoint_id="b01.island.3";old.collectibles=["b01.mote.2"];old.settings={"music":false}
 var old_copy=old.duplicate(true)
 var migrated=service.migrate_onboarding(old)
 check(migrated.ok and migrated.migrated and old==old_copy,"onboarding migration leaves input snapshot unchanged")
 check(migrated.data.chapter_id==old.chapter_id and migrated.data.checkpoint_id==old.checkpoint_id and migrated.data.collectibles==old.collectibles and migrated.data.settings.music==false,"legacy onboarding bypass preserves route, collectibles and preferences")
 check(migrated.data.settings.onboarding_origin=="legacy-bypass-v1" and Quest.HOME_EXIT in migrated.data.quest_flags,"legacy tutorial flags are explicitly attributed to bypass")
 check(not service.migrate_onboarding(migrated.data).migrated,"onboarding migration is idempotent")
 for route in [
  ["B02","river-v10","b02.hub",Quest.RIVER_ACCEPTED],
  ["B03","garden-v12","b03.hub",Quest.GARDEN_ACCEPTED],
  ["B04","shared-v16","b04.bank.1",Quest.SUMMIT_COMPLETE],
  ["B05","festival-v1","b05.entry",Quest.FESTIVAL_LIGHT]]:
  var prior=Quest.new()
  for event in Quest.EVENTS:
   if event==route[3]:break
   prior.apply(event)
  var existing=service.fresh();existing.chapter_id=route[0];existing.geometry=route[1];existing.checkpoint_id=route[2]
  existing.quest_flags=prior.flags.duplicate();existing.party_ids=prior.party_ids();existing.settings={"music":false};existing.collectibles=["b01.mote.2"]
  if route[0]=="B04":existing.summit=Save.Summit.fresh();existing.summit.bank=1
  var compatibility=service.migrate_onboarding(existing)
  check(compatibility.ok and compatibility.data.chapter_id==existing.chapter_id and compatibility.data.checkpoint_id==existing.checkpoint_id and compatibility.data.party_ids==existing.party_ids and compatibility.data.summit==existing.summit and compatibility.data.collectibles==existing.collectibles,"legacy "+route[0]+" keeps route, friends, chapter tasks and keepsakes when onboarding is added")
 var legacy=service.decode(JSON.stringify({"version":4,"met":true,"lit":[true,false,false],"joined":false,"completed":false,"x":1000}))
 var legacy_compat=service.migrate_onboarding(legacy.data)
 check(legacy.ok and legacy_compat.ok and legacy_compat.data.settings.onboarding_origin=="legacy-bypass-v1" and "light.A" in legacy_compat.data.quest_flags and "light.B" not in legacy_compat.data.quest_flags,"V4 migration preserves actual lights and labels onboarding as bypass")
 check(service.save(PATH,old),"old B01 fixture saves")
 var original=FileAccess.get_file_as_string(PATH)
 service.fault="write"
 check(not service.persist_onboarding_migration(PATH,migrated.data) and FileAccess.get_file_as_string(PATH)==original,"failed onboarding migration preserves old bytes")
 service.fault=""
 check(service.persist_onboarding_migration(PATH,migrated.data) and service.read_file(PATH+".bak").data==old and FileAccess.get_file_as_string(PATH+".onboarding-v1.original")==original,"successful onboarding migration preserves previous snapshot in backup and immutable original")
 var migrated_bytes=FileAccess.get_file_as_string(PATH)
 service.write_text(PATH+".onboarding-v1.original","truncated")
 check(not service.persist_onboarding_migration(PATH,migrated.data) and service.last_error=="onboarding_backup_invalid" and FileAccess.get_file_as_string(PATH)==migrated_bytes,"invalid immutable migration backup blocks writes without overwriting the primary")
 service.write_text(PATH+".onboarding-v1.original",original)
 check(service.save(PATH,data),"isolated fresh B00 journey saves")
 set_meta("journey_save_path",PATH)
 home=load("res://scenes/home.tscn").instantiate();root.add_child(home);current_scene=home
 await ticks(20)
 check(not home.blocked and home.paused and home.modal.visible,"new tutorial begins with the invitation and safely frozen controls")
 check(home.get_node_or_null("HomeExteriorArt")!=null,"B00 uses the generated adaptation home exterior behind its production player")
 await capture("invitation")
 home.saves.fault="write";home.accept_invitation()
 check(home.paused and not home.state.has(Quest.INVITATION) and home.modal.visible and home.modal.find_children("*","Label",true,false).any(func(label):return label.text.contains("Kayıt yapılamadı")) and home.modal.find_children("*","Button",true,false).any(func(button):return button.text=="Yeniden dene") and home.hud_panel.get_rect().encloses(home.hud.get_rect()),"failed invitation save keeps a frontmost retry card and a contained error")
 await capture("invitation-error")
 home.saves.fault=""
 home.accept_invitation();await ticks(20)
 check(home.state.has(Quest.INVITATION) and not home.paused,"invitation completion begins real movement practice")
 await verify_actor_controls("entry")
 await ticks(30)
 check(not home.state.has(Quest.WALK),"waiting still cannot complete walking practice")
 check(await walk_to(550),"walk to the first low root with the production controller")
 check(home.state.has(Quest.WALK) and not home.state.has(Quest.SHORT_JUMP),"100 real grounded movement units unlock the short jump")
 await jump_right(3,28)
 check(home.state.has(Quest.SHORT_JUMP),"short press rises and lands on the low root through physics; pos "+str(home.player.position))
 check(not home.state.has(Quest.LONG_JUMP),"short jump does not complete the long-jump lesson")
 check(await walk_to(930),"walk safely from the root to the small hollow")
 await jump_right(35,58)
 check(home.state.has(Quest.LONG_JUMP) and home.state.has(Quest.TUTORIAL_JUMP),"held jump clears the hollow and commits the observed landing; pos "+str(home.player.position))
 var progress=service.load_progress(PATH)
 check(progress.ok and progress.data.checkpoint_id=="b00.long","jump lesson resumes at a named stable checkpoint")
 await capture("long-jump")
 home.queue_free();await process_frame
 home=load("res://scenes/home.tscn").instantiate();root.add_child(home);current_scene=home;await ticks(20)
 check(not home.paused and home.state.has(Quest.TUTORIAL_JUMP) and absf(home.player.position.x-1320)<2,"reopening B00 restores the learned route at its stable checkpoint without repeating the invitation")
 key(KEY_D,true);await ticks(4);home._notification(NOTIFICATION_APPLICATION_FOCUS_OUT)
 var at_pause=home.player.position
 await ticks(20)
 check(home.paused and home.player.position==at_pause and home.router.owners.is_empty() and home.keys.is_empty(),"focus loss freezes the player and releases every input")
 home.resume();await ticks(20)
 check(not home.paused and absf(home.player.velocity.x)<0.1,"resume requires a fresh movement press")
 check(await walk_to(2100),"normal route reaches the exit without collecting the optional decoration")
 check("b00.ribbon" not in home.data.collectibles and home.available_action()=="Patikaya ilerle","optional decoration never locks the story exit")
 check(await walk_to(1740),"optional decoration route is reachable by returning from the exit")
 key(KEY_SPACE,true);await ticks(35);key(KEY_SPACE,false);await ticks(55)
 check(home.player.is_on_floor() and absf(home.player.position.y-500)<3 and home.available_action()=="Festival süsünü al","a real vertical jump reaches the optional upper branch")
 home.interact()
 check("b00.ribbon" in service.load_progress(PATH).data.collectibles and not home.ribbon.visible,"optional festival decoration is saved exactly once")
 home.interact();check(home.data.collectibles.count("b00.ribbon")==1,"repeating the decoration interaction is idempotent")
 await verify_upper_jump_frame()
 check(await walk_to(2100),"return from the optional branch to the exit")
 await verify_actor_controls("exit")
 var exit_position=home.player.position
 home.player.position.x=2190;await ticks(10)
 await verify_actor_controls("exit-far-edge")
 home.player.position=exit_position;await ticks(40)
 await capture("exit")
 var before=FileAccess.get_file_as_string(PATH)
 home.saves.fault="write";home.enter_patika()
 check(FileAccess.get_file_as_string(PATH)==before and not home.state.has(Quest.HOME_EXIT),"failed exit write leaves B00 progress unchanged")
 home.saves.fault=""
 home.transition_change=func():return ERR_CANT_OPEN
 home.enter_patika()
 check(service.load_progress(PATH).data.chapter_id=="B00" and not home.saves.director.transitioning,"failed scene change restores the safe B00 exit snapshot")
 home.transition_change=Callable();home.enter_patika();await ticks(40)
 check(current_scene.get_script().resource_path.ends_with("polish_world.gd") and current_scene.mode=="dialogue","real B00 exit opens the first B01 encounter without an extra menu")
 var target=service.load_progress(PATH)
 check(target.ok and target.data.chapter_id=="B01" and Quest.HOME_EXIT in target.data.quest_flags and target.data.party_ids.is_empty() and "b00.ribbon" in target.data.collectibles,"B00 handoff preserves real tutorial events and the optional keepsake without inventing friends")
 current_scene.queue_free();await process_frame
 # If transition rollback itself cannot write, do not resume a stale source world.
 var rollback_fixture=target.data.duplicate(true);rollback_fixture.chapter_id="B00";rollback_fixture.geometry="home-v1";rollback_fixture.checkpoint_id="b00.exit"
 check(service.save(PATH,rollback_fixture),"B00 rollback-failure fixture saves")
 home=load("res://scenes/home.tscn").instantiate();root.add_child(home);current_scene=home;await ticks(20)
 home.transition_change=func():home.saves.fault="write";return ERR_CANT_OPEN
 home.enter_patika();var retained_target=service.load_progress(PATH)
 check(retained_target.ok and retained_target.data.chapter_id=="B01" and home.data==retained_target.data and home.blocked and home.paused,"failed scene rollback retains the safe target snapshot and blocks stale source gameplay")
 key(KEY_ESCAPE,true);await ticks(10)
 check(home.blocked and service.load_progress(PATH).data==retained_target.data,"Escape cannot overwrite the safe target after rollback failure")
 home.go_menu();await ticks(15);current_scene.queue_free();await process_frame
 # A committed skip remains B01 even when its scene cannot open.
 check(service.save(PATH,service.fresh_journey()),"fresh skip failure fixture saves")
 home=load("res://scenes/home.tscn").instantiate();root.add_child(home);current_scene=home;await ticks(15)
 home.accept_invitation();home.pause_game()
 var skip_before=FileAccess.get_file_as_string(PATH)
 home.saves.fault="write";home.skip_tutorial()
 check(FileAccess.get_file_as_string(PATH)==skip_before and home.data.chapter_id=="B00" and not home.blocked,"failed skip write preserves B00 and allows retry")
 home.saves.fault=""
 home.transition_change=func():return ERR_CANT_OPEN
 home.skip_tutorial()
 var skipped=service.load_progress(PATH)
 check(skipped.ok and skipped.data.chapter_id=="B01" and skipped.data.settings.onboarding_origin=="user-skipped-v1" and home.data==skipped.data and home.blocked,"failed navigation retains the committed explicit skip snapshot and blocks stale B00 gameplay")
 var frozen_position=home.player.position;key(KEY_ESCAPE,true);await ticks(15)
 check(home.blocked and home.paused and home.player.position==frozen_position and service.load_progress(PATH).data==skipped.data,"Escape cannot resume the old tutorial or overwrite a committed skip")
 home.go_menu();await ticks(15)
 check(current_scene.get_script().resource_path.ends_with("polish_world.gd") and current_scene.mode=="menu" and service.load_progress(PATH).data==skipped.data,"skip navigation recovery returns to a safe menu with the B01 snapshot intact")
 current_scene.queue_free();await process_frame
 # Missing-save main menu routing is a separate production route from generic fresh().
 clean();var menu=load("res://scenes/polish_v3.tscn").instantiate();root.add_child(menu);current_scene=menu;await process_frame
 menu.begin_game();await ticks(20)
 check(current_scene.get_script().resource_path.ends_with("home_main.gd") and current_scene.paused,"first-ever Yola çık routes to B00 instead of bypassing onboarding")
 current_scene.queue_free();await process_frame
 clean();set_meta("journey_save_path","user://festival_v3.json")
 print("HOME CONTRACT: %d checks, %d failures"%[checks,failures])
 quit(1 if failures else 0)
