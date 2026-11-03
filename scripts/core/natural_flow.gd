extends RefCounted
## Shipping story pacing. Quest mutations still go through each chapter's save gate.
const Quest=preload("res://scripts/core/quest_state.gd")
var owner_id=0
var beat=""
var seconds=0.0
var visual_seconds=0.0
var attempted_transition=""
func value(node,key:String,fallback=null):
 if not is_instance_valid(node):return fallback
 for row in node.get_property_list():
  if row.name==key:return node.get(key)
 return fallback
func enabled(scene)->bool:
 return is_instance_valid(scene) and not scene.get_tree().get_meta("manual_story_flow",false) and not bool(value(scene,"automated",false))
func ready(key:String,delta:float,delay:float)->bool:
 if beat!=key:beat=key;seconds=0
 seconds+=minf(delta,0.1)
 return seconds>=delay
func tick(scene,delta:float,focus_lost:bool,modal_open:bool):
 if not enabled(scene):return
 if owner_id!=scene.get_instance_id():owner_id=scene.get_instance_id();beat="";seconds=0;attempted_transition=""
 var path=scene.get_script().resource_path.get_file()
 if focus_lost or modal_open:return
 var mode=str(value(scene,"mode",""))
 var screen=value(scene,"screen")
 if is_instance_valid(screen) and screen.get_meta("natural_completion_hidden",false) and mode!="complete":screen.show()
 var dialogue_active=bool(value(scene,"dialogue_active",false))
 var paused=bool(value(scene,"paused",false))
 var paused_panel=value(scene,"pause_root")
 if mode in ["pause","save_error","transition_error","error"] or (paused and not dialogue_active and path!="home_main.gd"):return
 if is_instance_valid(paused_panel) and paused_panel.visible:return
 _background(scene)
 _idle(scene,delta)
 _short_ui(scene)
 var runner=value(scene,"runner")
 if mode=="dialogue" and runner!=null and runner.active:
  var line=runner.current
  runner.revealed=true
  if ready("line:"+str(line.id),delta,clampf(str(line.text).length()*0.025,1.0,2.4)):
   beat="";seconds=0
   if scene.has_method("advance_dialogue"):scene.advance_dialogue()
   else:scene.advance()
  return
 if dialogue_active:
  var index=int(value(scene,"dialogue_index",0))
  if ready("summit:"+str(value(scene,"dialogue_target",""))+":"+str(index),delta,1.6):
   beat="";seconds=0;scene.advance_dialogue()
  return
 if mode=="complete":
  if attempted_transition==path:
   if is_instance_valid(screen):screen.show()
   return
  if is_instance_valid(screen):screen.set_meta("natural_completion_hidden",true);screen.hide()
  if ready("next:"+path,delta,0.7):
   attempted_transition=path
   # A rejected navigation switches to its chapter's explicit recovery screen.
   if path=="polish_world.gd":scene.go_river()
   elif path=="river_world.gd":scene.go_garden()
   elif path=="garden_world.gd":scene.go_summit()
  return
 if path=="home_main.gd":
  if not scene.state.has(Quest.INVITATION):
   if scene.error_message.is_empty() and ready("invitation",delta,1.0):scene.accept_invitation()
  elif not paused and scene.error_message.is_empty() and scene.available_action()=="Patikaya ilerle":scene.enter_patika()
  return
 if paused:return
 var player=value(scene,"player",value(scene,"actor"))
 if not is_instance_valid(player):return
 if path=="polish_world.gd" and mode=="play":
  for i in 3:
   if not scene.lit[i] and scene.can_light(i):scene.light_lantern(i);return
  if scene.joined and not scene.completed and player.is_on_floor() and absf(player.position.x-3860)<120:scene.open_dialogue("badger_exit")
 elif path=="river_world.gd" and mode=="play":
  if not scene.state.has(Quest.RIVER_ACCEPTED) and player.is_on_floor() and absf(player.position.x-scene.monkey.position.x)<165:scene.dialogue("river_meet")
  else:scene.action=true
 elif path=="garden_world.gd" and mode=="play":
  if not scene.state.has(Quest.GARDEN_ACCEPTED) and player.is_on_floor() and absf(player.position.x-scene.rabbit.position.x)<165:scene.dialogue("garden_meet")
  else:scene.action=true
 elif path=="summit_main.gd":
  var action=scene.available_action()
  if action.is_empty() and scene.has_meta("natural_story_cancelled"):scene.remove_meta("natural_story_cancelled")
  elif str(scene.quest_error).is_empty() and not action.is_empty() and not scene.get_meta("natural_story_cancelled",false):scene.interact()
 elif path=="festival_main.gd" and not _has_error(scene.status) and Quest.FESTIVAL_COMPLETE not in scene.save_data.quest_flags and scene.can_interact():scene.interact()
func _background(scene):
 var background=value(scene,"bg",value(scene,"backdrop"))
 if not is_instance_valid(background):return
 var layer=scene.get_node_or_null("StableScenery")
 if not is_instance_valid(layer):
  layer=CanvasLayer.new();layer.name="StableScenery";layer.layer=-50;scene.add_child(layer)
  background.reparent(layer,false)
 var player=value(scene,"player")
 # One final owner in viewport space: no vertical camera/render feedback loop.
 background.position=Vector2(-clampf(player.position.x-640,0,3400)*0.12 if is_instance_valid(player) else 0,0)
func _idle(scene,delta:float):
 visual_seconds+=minf(delta,0.1)
 var actors=[]
 for key in ["friend","badger","monkey","rabbit"]:
  var actor=value(scene,key)
  if is_instance_valid(actor) and actor not in actors:actors.append(actor)
 var team=value(scene,"team",[])
 for actor in team:
  if is_instance_valid(actor) and actor!=value(scene,"player") and actor not in actors:actors.append(actor)
 for i in actors.size():
  var actor=actors[i];var anim=value(actor,"anim")
  if not is_instance_valid(anim):continue
  if value(actor,"recruited",false):actor.locomotion_scale=1.5 if actor.position.distance_to(value(scene,"player",actor).position)>500 else 1.0
  if not value(actor,"recruited",false) and not actor.has_meta("natural_greeted") and str(value(scene,"mode","play"))=="play":
   actor.set_meta("natural_greeted",true)
   if actor.has_method("set_performance"):actor.set_performance("help",actor,0.8,"greeting")
  var prefs=scene.get_tree().root.get_meta("catpat_preferences",{})
  var reduced=bool(prefs.get("reduced_motion",false))
  anim.rotation=0 if reduced or anim.animation!="idle" else sin(visual_seconds*1.8+i)*0.018
  if not reduced and anim.animation=="idle":
   anim.offset=Vector2(0,-(sin(visual_seconds*2.5+i)+1)*1.6/maxf(absf(anim.scale.y),0.01));actor.set_meta("natural_idle_bob",true)
  elif reduced or actor.get_meta("natural_idle_bob",false):
   anim.offset=Vector2.ZERO;actor.set_meta("natural_idle_bob",false)
func _short_ui(scene):
 # One short objective plus one action hint; optional detailed help stays in Mola.
 for key in ["subtitle","controls_hint","chapter_note"]:
  var extra=value(scene,key)
  if is_instance_valid(extra) and extra is CanvasItem:extra.hide()
 var display=value(scene,"control_display")
 for button in value(display,"buttons",[]):
  if is_instance_valid(button) and button is Button and button.text=="E":button.hide()
 var action_button=value(scene,"action_button")
 var save=value(scene,"save_data",{})
 if is_instance_valid(action_button) and not _has_error(str(value(scene,"status",""))) and str(value(scene,"quest_error","")).is_empty() and Quest.FESTIVAL_COMPLETE not in save.get("quest_flags",[]):
  if scene.has_method("can_interact") or scene.has_method("enter_festival"):action_button.hide()
 var hud=value(scene,"hud")
 if is_instance_valid(hud) and hud is Label and str(hud.text).begins_with("DAVET VE EV ÖNÜ · "):hud.text=str(hud.text).replace("DAVET VE EV ÖNÜ · ","")
 var hint=value(scene,"hint")
 if is_instance_valid(hint) and hint is Label:hint.text=str(hint.text).replace("E · ","")
 var comic=value(scene,"comic",value(scene,"dialogue"))
 var runner=value(scene,"runner")
 if is_instance_valid(comic) and bool(value(scene,"dialogue_active",false)):
  var active_line=scene.dialogue_lines[scene.dialogue_index]
  var left=str(active_line.side)=="left"
  comic.left_line.visible=left;comic.right_line.visible=not left;comic.balloon_left.visible=left;comic.balloon_right.visible=not left
  comic.advance_button.hide()
 if is_instance_valid(comic) and runner!=null and runner.active and is_instance_valid(value(comic,"left_line")):
  var left=str(runner.current.side)=="left"
  comic.left_line.visible=left;comic.right_line.visible=not left
  comic.balloon_left.visible=left;comic.balloon_right.visible=not left
  for child in comic.get_children():
   if child is Button and child.text=="Devam":child.hide()

func _has_error(status:String)->bool:
 var text=status.to_lower()
 return "yapılamadı" in text or "açılamadı" in text or "kaydedilemedi" in text
