extends SceneTree
const Store=preload("res://scripts/core/save_service.gd")
const Quest=preload("res://scripts/core/quest_state.gd")
const Replay=preload("res://scripts/core/replay_service.gd")
const Experience=preload("res://scripts/core/experience_service.gd")
const PATH="user://legacy-framing-contract.json"
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
  if is_instance_valid(game):service._refresh_expanded_hud(game)
func body_rect()->Rect2:return game.player.get_global_transform_with_canvas()*Rect2(-65,-150,130,150)
func unobscured()->bool:
 var body=body_rect()
 var viewport=Rect2(0,0,1280,720)
 if not viewport.encloses(body):return false
 for button in service.controls_for(game):
  if button.is_visible_in_tree() and body.intersects(button.get_global_transform_with_canvas()*Rect2(Vector2.ZERO,button.size)):return false
 for card in service.hud_cards.values():
  if is_instance_valid(card) and card.is_visible_in_tree() and body.intersects(card.get_global_transform_with_canvas()*Rect2(Vector2.ZERO,card.size)):return false
 return true
func capture(tag:String):
 if "--legacy-framing-capture" not in OS.get_cmdline_user_args():return
 await process_frame;await RenderingServer.frame_post_draw
 var frame=root.get_texture().get_image()
 check(not frame.is_empty(),tag+" native frame renders")
 print("VISUAL_CAPTURE:"+tag+":"+Marshalls.raw_to_base64(frame.save_webp_to_buffer(true,0.82)))
func _initialize():call_deferred("run")
func run():
 var autoload=root.get_node_or_null("CatpatExperience")
 if autoload:autoload.auto_observe=false
 service=Experience.new();service.auto_observe=false;root.add_child(service)
 var state=Quest.new()
 for event in Quest.HOME_EVENTS+Quest.EVENTS:state.apply(event)
 var store=Store.new();var data=store.fresh();data.chapter_id="B05";data.geometry="festival-v1";data.checkpoint_id="b05.stage";data.quest_flags=state.flags;data.party_ids=state.party_ids();data.ending_seen=true
 check(store.save(PATH,data),"isolated completed source for framing fixtures")
 var fixtures={}
 for chapter in ["B01","B02","B03"]:fixtures[chapter]=Replay.new().prepare(chapter,PATH)
 var locations={"B01":{"entry":Vector2(190,579),"upper":Vector2(2000,399),"low":Vector2(3550,569),"edge":Vector2(4120,569)},"B02":{"entry":Vector2(260,519),"upper":Vector2(1800,309),"low":Vector2(1900,649),"edge":Vector2(3520,519)},"B03":{"entry":Vector2(560,539),"upper":Vector2(1740,319),"low":Vector2(1620,639),"edge":Vector2(3920,539)}}
 for chapter in fixtures:
  var fixture=fixtures[chapter];check(fixture.ok and store.save(PATH,fixture.data),chapter+" framing fixture stores unchanged geometry")
  set_meta("journey_save_path",PATH)
  game=load(fixture.scene_path).instantiate();root.add_child(game);current_scene=game
  await ticks(3)
  if chapter=="B01":game.begin_game();await ticks(2);game.test_dialogue_finish()
  await ticks(8)
  var native_capture="--legacy-framing-capture" in OS.get_cmdline_user_args()
  var viewports=[Vector2i(666,374)] if native_capture else [Vector2i(1280,720),Vector2i(666,374)]
  var profiles=[{"name":"max-left","text_scale":1.3,"control_scale":1.3,"left_handed":true}] if native_capture else [{"name":"touch-normal"},{"name":"max-right","text_scale":1.3,"control_scale":1.3},{"name":"max-left","text_scale":1.3,"control_scale":1.3,"left_handed":true}]
  for viewport in viewports:
   root.size=viewport
   for profile in profiles:
    game.control_display.touch_mode=true;game.control_display.refresh();service.apply_to_scene(game,profile)
    for location in locations[chapter]:
     game.player.position=locations[chapter][location];game.player.velocity=Vector2.ZERO;game.reset_input() if game.has_method("reset_input") else game.reset_controls();game.camera.reset_smoothing()
     await ticks(40)
     check(unobscured(),chapter+" "+profile.name+" "+location+" "+str(viewport)+" actor clears viewport/HUD/controls body="+str(body_rect()))
     var background=service.value(game,"bg",service.value(game,"backdrop"))
     var framed=bool(game.camera.get_meta("experience_camera_active",false))
     check(not framed or absf(background.position.y-(game.camera.get_screen_center_position().y-360))<0.1,chapter+" "+location+" background covers shifted vertical view")
     if viewport.x==666 and profile.name=="max-left" and location in ["entry","upper"]:await capture(chapter+"-framing-"+location)
     if location=="entry":
      var entry_jump=InputEventScreenTouch.new();entry_jump.index=74;entry_jump.position=game.router.regions.jump.get_center() if service.has_property(game,"router") else game.input_router.regions.jump.get_center();entry_jump.pressed=true;game._input(entry_jump)
      var entry_clear=true
      for entry_frame in 85:
       if entry_frame==35:entry_jump.pressed=false;game._input(entry_jump)
       await ticks(1)
       var frame_clear=unobscured()
       if entry_clear and not frame_clear:
        print("ENTRY FIRST OVERLAP ",chapter," ",profile.name," viewport=",viewport," frame=",entry_frame," body=",body_rect())
        for button in service.controls_for(game):print("ENTRY CONTROL ",button.text," ",button.get_global_transform_with_canvas()*Rect2(Vector2.ZERO,button.size)," visible=",button.is_visible_in_tree())
        for card in service.hud_cards.values():print("ENTRY CARD ",card.get_global_transform_with_canvas()*Rect2(Vector2.ZERO,card.size)," visible=",card.is_visible_in_tree())
       entry_clear=entry_clear and frame_clear
      check(entry_clear,chapter+" "+profile.name+" entry held jump and landing clear corner controls "+str(viewport))
    game.player.position=locations[chapter].upper;game.player.velocity=Vector2.ZERO;game.camera.reset_smoothing();await ticks(35)
    var jump=InputEventScreenTouch.new();jump.index=73;jump.position=game.router.regions.jump.get_center() if service.has_property(game,"router") else game.input_router.regions.jump.get_center();jump.pressed=true;game._input(jump)
    var clear=true
    var top=720.0
    for frame in 85:
     if frame==35:jump.pressed=false;game._input(jump)
     await ticks(1)
     clear=clear and unobscured();top=minf(top,body_rect().position.y)
     if frame==22 and viewport.x==666 and profile.name=="max-left":await capture(chapter+"-framing-upper-jump")
    check(clear,chapter+" "+profile.name+" held upper-platform jump clears HUD/controls throughout "+str(viewport)+" top="+str(top))
    check(game.player.is_on_floor() and absf(game.player.position.y-locations[chapter].upper.y-1)<3,chapter+" unchanged upper platform receives jump landing")
  root.size=Vector2i(1280,720)
  game.control_display.touch_mode=false;game.control_display.refresh();service.apply_to_scene(game,{"name":"keyboard-normal"})
  await ticks(3)
  check(game.camera.position.y==-220 and game.camera.limit_top==0 and game.camera.limit_bottom==720,chapter+" normal keyboard camera restores its original framing")
  game.queue_free();await process_frame
 service.queue_free();await process_frame
 for suffix in ["", ".bak", ".pending", ".bak.pending", ".legacy"]:DirAccess.remove_absolute(PATH+suffix)
 set_meta("journey_save_path","user://festival_v3.json")
 if autoload:autoload.auto_observe=true
 print("LEGACY FRAMING: %d checks, %d failures"%[checks,failures])
 quit(1 if failures else 0)
