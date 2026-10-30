extends SceneTree
const Store=preload("res://scripts/core/save_service.gd")
const Quest=preload("res://scripts/core/quest_state.gd")
const Experience=preload("res://scripts/core/experience_service.gd")
const PATH="user://festival-framing-test.json"
var checks=0
var failures=0
var game
var service
func check(ok:bool,label:String):
 checks+=1
 if not ok:failures+=1
 print("PASS " if ok else "FAIL ",label)
func ticks(count:int):
 for frame in count:
  await physics_frame
  if is_instance_valid(game) and is_instance_valid(service) and not service.settings.is_empty():service._refresh_expanded_hud(game)
func body_rect()->Rect2:
 return game.actor.get_global_transform_with_canvas()*Rect2(-65,-118,130,150)
func unobscured()->bool:
 var body=body_rect()
 if not Rect2(0,0,1280,720).encloses(body):return false
 for button in game.control_display.buttons:
  if button.is_visible_in_tree() and body.intersects(button.get_rect()):return false
 for card in service.hud_cards.values():
  if card.is_visible_in_tree() and body.intersects(card.get_rect()):return false
 return true
func controls_clear()->bool:
 var buttons=game.control_display.buttons
 for i in buttons.size():
  if not buttons[i].is_visible_in_tree():continue
  for j in range(i+1,buttons.size()):
   if buttons[j].is_visible_in_tree() and buttons[i].get_rect().intersects(buttons[j].get_rect()):return false
 return true
func capture(tag:String):
 if "--framing-capture" not in OS.get_cmdline_user_args() or root.size.x!=666:return
 await process_frame;await RenderingServer.frame_post_draw
 var frame=root.get_texture().get_image()
 check(not frame.is_empty(),tag+" real frame renders")
 print("VISUAL_CAPTURE:"+tag+":"+Marshalls.raw_to_base64(frame.save_webp_to_buffer(true,0.82)))
func _initialize():call_deferred("run")
func run():
 var autoload=root.get_node_or_null("CatpatExperience")
 if autoload:autoload.auto_observe=false
 service=Experience.new();service.auto_observe=false;root.add_child(service)
 var quest=Quest.new()
 for event in Quest.EVENTS:
  if event not in Quest.FESTIVAL_EVENTS:quest.apply(event)
 var data=Store.new().fresh();data.chapter_id="B05";data.geometry="festival-v1";data.checkpoint_id="b05.entry";data.quest_flags=quest.flags;data.party_ids=quest.party_ids()
 check(Store.new().save(PATH,data),"isolated festival framing fixture saves")
 set_meta("journey_save_path",PATH)
 game=load("res://scenes/festival.tscn").instantiate();root.add_child(game);current_scene=game
 game.control_display.touch_mode=true;game.control_display.refresh()
 var locations={"entry":Vector2(160,584),"task":Vector2(1150,414),"stage":Vector2(4220,442),"far-edge":Vector2(4350,584)}
 for viewport in [Vector2i(1280,720),Vector2i(666,374)]:
  if "--framing-quick" in OS.get_cmdline_user_args() and viewport.x==666:continue
  root.size=viewport
  for profile in [{"name":"normal"},{"name":"max-right","text_scale":1.3,"control_scale":1.3},{"name":"max-left","text_scale":1.3,"control_scale":1.3,"left_handed":true}]:
   if "--framing-quick" in OS.get_cmdline_user_args() and profile.name!="max-right":continue
   game.control_display.touch_mode=true;game.control_display.refresh();game.update_controls_hint()
   service.apply_to_scene(game,profile)
   for location in locations:
    game.actor.position=locations[location];game.actor.velocity=Vector2.ZERO;game.camera.reset_smoothing()
    await ticks(70)
    if not unobscured():
     for button in game.control_display.buttons:print("FRAMING CONTROL ",button.text," ",button.get_rect()," visible ",button.is_visible_in_tree())
     for card in service.hud_cards.values():print("FRAMING CARD ",card.get_rect()," visible ",card.is_visible_in_tree())
    check(unobscured(),"B05 "+profile.name+" "+location+" whole actor clears HUD and touch controls "+str(body_rect()))
    if profile.name=="max-left" and location in ["entry","task"]:await capture("B05-framing-"+location)
   var original_flags=game.save_data.quest_flags.duplicate()
   game.save_data.quest_flags.append_array(Quest.FESTIVAL_EVENTS)
   game.all_on_stage=true
   game.actor.position=locations.stage;game.actor.velocity=Vector2.ZERO;game.camera.reset_smoothing()
   await ticks(70)
   check(game.action_button.visible and unobscured() and controls_clear(),"B05 "+profile.name+" completed-stage replay action clears the actor and other controls")
   if profile.name=="max-left":await capture("B05-framing-replay-action")
   game.save_data.quest_flags=original_flags;game.all_on_stage=false
   for jump_location in ["entry","task"]:
    game.actor.position=locations[jump_location];game.actor.velocity=Vector2.ZERO;game.camera.reset_smoothing();await ticks(65)
    var jump=InputEventScreenTouch.new();jump.index=81;jump.position=game.input_router.regions.jump.get_center();jump.pressed=true;game._input(jump)
    var clear=true
    var highest=720.0
    for frame in 85:
     if frame==35:jump=InputEventScreenTouch.new();jump.index=81;jump.position=game.input_router.regions.jump.get_center();jump.pressed=false;game._input(jump)
     await physics_frame
     service._refresh_expanded_hud(game)
     if clear and not unobscured():
      print("FIRST JUMP OCCLUSION frame ",frame," body ",body_rect())
      for button in game.control_display.buttons:print("JUMP CONTROL ",button.text," ",button.get_rect()," visible ",button.is_visible_in_tree())
      for card in service.hud_cards.values():print("JUMP CARD ",card.get_rect()," visible ",card.is_visible_in_tree())
     clear=clear and unobscured();highest=minf(highest,body_rect().position.y)
     if frame==22 and profile.name=="max-left" and jump_location=="task":await capture("B05-framing-upper-jump")
    if not clear:
     for item in service.hud_copies.values():print("FRAMING TEXT ",item.label.text," ",item.label.get_rect()," font ",item.label.get_theme_font_size("font_size"))
    check(clear,"B05 "+profile.name+" "+jump_location+" held jump clears HUD, controls and viewport throughout; top="+str(highest))
    check(game.actor.is_on_floor() and absf(game.actor.position.y-locations[jump_location].y)<3,"B05 "+profile.name+" "+jump_location+" unchanged platform receives jump landing")
 game.queue_free();service.queue_free();await process_frame
 for suffix in ["", ".bak", ".pending", ".bak.pending", ".legacy"]:DirAccess.remove_absolute(PATH+suffix)
 set_meta("journey_save_path","user://festival_v3.json")
 if autoload:autoload.auto_observe=true
 print("FESTIVAL FRAMING: %d checks, %d failures"%[checks,failures])
 quit(1 if failures else 0)
