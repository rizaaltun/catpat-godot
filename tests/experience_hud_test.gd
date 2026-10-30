extends SceneTree
const Experience=preload("res://scripts/core/experience_service.gd")
const Store=preload("res://scripts/core/save_service.gd")
const Quest=preload("res://scripts/core/quest_state.gd")
const Replay=preload("res://scripts/core/replay_service.gd")
const PATH="user://experience-hud-contract.json"
var checks=0
var failures=0
func check(ok:bool,label:String):
 checks+=1
 if not ok:failures+=1
 print("PASS " if ok else "FAIL ",label)
func ticks(count:int):
 for frame in count:await physics_frame
func _initialize():call_deferred("run")
func run():
 var autoload=root.get_node_or_null("CatpatExperience")
 if autoload:autoload.auto_observe=false
 var service=Experience.new();service.auto_observe=false;root.add_child(service)
 var state=Quest.new()
 for event in Quest.HOME_EVENTS+Quest.EVENTS:state.apply(event)
 var store=Store.new();var data=store.fresh();data.chapter_id="B05";data.geometry="festival-v1";data.checkpoint_id="b05.stage";data.quest_flags=state.flags;data.party_ids=state.party_ids();data.ending_seen=true
 check(store.save(PATH,data),"fully completed isolated source for all chapter HUDs")
 var fixtures={}
 for chapter in Replay.CHAPTERS:fixtures[chapter]=Replay.new().prepare(chapter,PATH)
 var safe=Rect2(0,0,1280,720)
 for chapter in Replay.CHAPTERS:
  var fixture=fixtures[chapter]
  check(fixture.ok and store.save(PATH,fixture.data),chapter+" valid HUD fixture saves")
  set_meta("journey_save_path",PATH)
  var scene=load(fixture.scene_path).instantiate();root.add_child(scene);current_scene=scene
  await ticks(20)
  if chapter=="B00":scene.accept_invitation()
  if chapter=="B01":scene.begin_game();await ticks(2);scene.test_dialogue_finish()
  await ticks(3)
  var display=service.value(scene,"control_display")
  if is_instance_valid(display):
   display.touch_mode=true;display.refresh()
   if scene.has_method("update_controls_hint"):scene.update_controls_hint()
  var prefs=service.preferences.normalize({"text_scale":1.3,"control_scale":1.3,"left_handed":true})
  service.apply_to_scene(scene,prefs)
  await process_frame;service._refresh_expanded_hud(scene);await process_frame
  check(is_instance_valid(service.hud_layer) and service.hud_layer.visible,chapter+" expanded HUD is active during play")
  var hidden_sources=service.hidden_hud_nodes.values().duplicate()
  check(not hidden_sources.is_empty() and hidden_sources.all(func(item):return not is_instance_valid(item.node.get_ref()) or not item.node.get_ref().visible),chapter+" original HUD plates and anonymous headings are suppressed")
  if chapter=="B00":check(not service.hud_cards.bottom.visible and service.control_footer_shift==0,chapter+" top hint creates no footer reserve or control shift")
  if chapter=="B05":
   var footer=service.hud_copies.controls_hint
   var line_height=footer.label.get_theme_font("font").get_height(footer.label.get_theme_font_size("font_size"))
   check(service.hud_cards.bottom.size.y<=line_height+24,chapter+" footer reserves one actual font line plus padding")
  var text_fits=true
  var full_scale=true
  for property in service.hud_copies:
   var item=service.hud_copies[property]
   if not item.label.visible:continue
   full_scale=full_scale and item.label.get_theme_font_size("font_size")==roundi(int(item.source.get_meta("experience_font"))*1.3)
   text_fits=text_fits and item.label.get_minimum_size().y<=item.label.size.y and safe.encloses(item.label.get_rect())
   var card=service.hud_cards[item.group]
   text_fits=text_fits and card.get_rect().encloses(item.label.get_rect())
  check(full_scale,chapter+" every known visible HUD field uses the full1.3 text scale")
  check(text_fits,chapter+" expanded live HUD text fits its image cards and viewport")
  var controls=service.controls_for(scene).duplicate()
  var action=service.value(scene,"action_button")
  if is_instance_valid(action) and action not in controls:controls.append(action)
  var no_overlap=true
  var cards=[]
  for card in service.hud_cards.values():
   if card.visible:cards.append(card)
  for i in cards.size():
   for j in range(i+1,cards.size()):no_overlap=no_overlap and not cards[i].get_rect().intersects(cards[j].get_rect())
   for control in controls:
    if is_instance_valid(control):no_overlap=no_overlap and not cards[i].get_rect().intersects(control.get_rect())
  check(no_overlap,chapter+" expanded cards do not overlap other cards or controls")
  check(controls.all(func(button):return is_instance_valid(button) and safe.encloses(button.get_rect())),chapter+" largest left-handed controls remain within viewport")
  if "--experience-capture" in OS.get_cmdline_user_args() and chapter in ["B01","B04","B05"]:
   root.size=Vector2i(666,374)
   await process_frame;await RenderingServer.frame_post_draw
   var frame=root.get_texture().get_image()
   print("VISUAL_CAPTURE:"+chapter+"-scaled-hud:"+Marshalls.raw_to_base64(frame.save_webp_to_buffer(true,0.82)))
   root.size=Vector2i(1280,720)
  service.apply_to_scene(scene,service.preferences.normalize())
  var restored=not service.hud_layer.visible
  for item in service.hud_copies.values():
   if is_instance_valid(item.source):restored=restored and item.source.modulate.a==float(item.source.get_meta("experience_text_alpha",1.0))
  check(restored,chapter+" normal text setting restores the original chapter HUD")
  check(hidden_sources.all(func(item):return not is_instance_valid(item.node.get_ref()) or item.node.get_ref().visible==item.visible),chapter+" normal text setting restores original image plates and headings")
  scene.queue_free();await process_frame
 service.queue_free();await process_frame
 for suffix in ["", ".bak", ".pending", ".bak.pending", ".legacy"]:DirAccess.remove_absolute(PATH+suffix)
 set_meta("journey_save_path","user://festival_v3.json")
 if autoload:autoload.auto_observe=true
 print("EXPERIENCE HUD: %d checks, %d failures"%[checks,failures])
 quit(1 if failures else 0)
