extends Node
## Host-side preferences and modal lifecycle; chapters keep their own story/save logic.
const Preferences=preload("res://scripts/core/preferences.gd")
const SettingsPanel=preload("res://scripts/ui/settings_panel.gd")
const ChapterSelect=preload("res://scripts/ui/chapter_select_panel.gd")
const Replay=preload("res://scripts/core/replay_service.gd")
const UI=preload("res://scripts/polish_ui.gd")
var auto_observe=true
var preferences=Preferences.new()
var settings={}
var scene_id=0
var applied_signature=""
var entry_layer:CanvasLayer
var settings_entry:Button
var chapters_entry:Button
var modal_layer:CanvasLayer
var active_modal:Control
var modal_host:Node
var modal_snapshot={}
var reader_layer:CanvasLayer
var reader_panel:TextureRect
var reader_text:Label
var reader_source:Label
var limitations:Array[String]=[]
var hud_layer:CanvasLayer
var hud_cards={}
var hud_copies={}
var control_footer_shift=-1.0
var application_focus_lost=false
var hidden_hud_nodes={}
var text_measure_cache={}
func _notification(what):
 if what not in [NOTIFICATION_WM_WINDOW_FOCUS_OUT,NOTIFICATION_WM_WINDOW_FOCUS_IN,NOTIFICATION_APPLICATION_FOCUS_OUT,NOTIFICATION_APPLICATION_FOCUS_IN]:return
 if not is_inside_tree() or is_queued_for_deletion():return
 if what==NOTIFICATION_APPLICATION_FOCUS_OUT:
  application_focus_lost=true;return
 if what==NOTIFICATION_APPLICATION_FOCUS_IN:
  application_focus_lost=false;return
 var lost=what==NOTIFICATION_WM_WINDOW_FOCUS_OUT
 if lost==application_focus_lost:return
 application_focus_lost=lost
 var audio=get_tree().root.get_node_or_null("CatpatAudio")
 if is_instance_valid(audio):audio.notification(NOTIFICATION_APPLICATION_FOCUS_OUT if lost else NOTIFICATION_APPLICATION_FOCUS_IN)
 # Web canvas.blur reports WINDOW focus; existing chapters implement APPLICATION
 # focus loss. Forward the loss once, but never resume a chapter on focus gain.
 if lost:
  var scene=get_tree().current_scene
  if is_instance_valid(scene) and not scene.is_queued_for_deletion():scene.notification(NOTIFICATION_APPLICATION_FOCUS_OUT)
func _ready():
 process_priority=60
 process_physics_priority=60
func has_property(object,key:String)->bool:
 if not is_instance_valid(object):return false
 for property in object.get_property_list():
  if property.name==key:return true
 return false
func value(object,key:String,fallback=null):
 return object.get(key) if has_property(object,key) else fallback
func current_scene(candidate=null):
 return candidate if is_instance_valid(candidate) else get_tree().current_scene
func buttons_under(node:Node)->Array:
 return node.find_children("*","Button",true,false) if is_instance_valid(node) else []
func actual_main_menu(scene)->bool:
 if not is_instance_valid(scene) or value(scene,"mode","")!="menu":return false
 var script=scene.get_script()
 if script==null or not script.resource_path.ends_with("polish_world.gd"):return false
 for button in buttons_under(value(scene,"screen")):
  if button.text in ["Yola çık","Yolculuğa dön"]:return true
 return false
func actual_pause_menu(scene)->bool:
 if not is_instance_valid(scene):return false
 for property in ["pause_panel","pause_root"]:
  var panel=value(scene,property)
  if is_instance_valid(panel):return panel.visible and not (is_instance_valid(value(scene,"final_panel")) and scene.final_panel.visible) and not (is_instance_valid(value(scene,"help_panel")) and scene.help_panel.visible)
 if value(scene,"mode","")=="pause":return true
 var modal=value(scene,"modal")
 if value(scene,"paused",false) and is_instance_valid(modal) and modal.visible:
  for button in buttons_under(modal):
   if button.text=="Devam et":return true
 return false
func path_for(scene)->String:
 return str(value(scene,"save_path",get_tree().get_meta("journey_save_path","user://festival_v3.json")))
func _process(delta):
 if not auto_observe:return
 var scene=current_scene()
 if not is_instance_valid(scene):return
 if is_instance_valid(modal_layer) and scene!=modal_host:_close_modal(false)
 guard_replay_return(scene)
 if scene.get_instance_id()!=scene_id:
  scene_id=scene.get_instance_id();applied_signature=""
  var read=preferences.read(path_for(scene));settings=preferences.apply(read.settings)
  limitations.clear()
  if application_focus_lost:scene.notification(NOTIFICATION_APPLICATION_FOCUS_OUT)
 _update_entries(scene)
 var signature=_ui_signature(scene)+str(settings.hash())
 if signature!=applied_signature:
  apply_to_scene(scene,settings);applied_signature=signature
 _refresh_expanded_hud(scene)
 _apply_dialogue(scene,delta)
 _apply_reduced_decorations(scene)
func guard_replay_return(scene)->bool:
 if not get_tree().has_meta("replay_primary_path"):return false
 var initial=bool(get_tree().get_meta("replay_autostart",false))
 if initial:
  # B01's first autostart opens a dialogue, not necessarily a play frame.
  if value(scene,"mode","")!="menu":get_tree().remove_meta("replay_autostart")
  return false
 if not actual_main_menu(scene):return false
 var primary=str(get_tree().get_meta("replay_primary_path"))
 var result=Replay.new().return_to_primary(func(_path):
  scene.save_path=primary;scene.show_menu();return OK)
 if result.ok:
  applied_signature="";scene_id=0
 return result.ok
func _update_entries(scene):
 if not is_instance_valid(entry_layer) or entry_layer.get_parent()!=scene:
  entry_layer=CanvasLayer.new();entry_layer.name="ExperienceEntries";entry_layer.layer=90;scene.add_child(entry_layer)
  settings_entry=UI.button("Ayarlar",Rect2(1010,24,230,86),entry_layer,open_settings.bind(scene),true)
  settings_entry.name="ExperienceSettings"
  chapters_entry=UI.button("Bölümler",Rect2(760,24,230,86),entry_layer,open_chapters.bind(scene),true)
  chapters_entry.name="ExperienceChapters"
 var menu=actual_main_menu(scene)
 var pause=actual_pause_menu(scene)
 settings_entry.visible=(menu or pause) and not is_instance_valid(active_modal)
 chapters_entry.visible=menu and not is_instance_valid(active_modal)
 settings_entry.position=Vector2(1010,24) if menu else Vector2(24,250)
 settings_entry.size=Vector2(230,86) if menu else Vector2(210,100)
func _begin_modal(scene)->bool:
 if not is_instance_valid(scene) or is_instance_valid(active_modal):return false
 modal_host=scene
 modal_snapshot={"main_menu":actual_main_menu(scene),"paused":value(scene,"paused",false),"mode":value(scene,"mode",""),"input":scene.is_processing_input(),"unhandled":scene.is_processing_unhandled_input()}
 if not modal_snapshot.main_menu and not actual_pause_menu(scene):
  if scene.has_method("set_game_paused"):scene.set_game_paused(true)
  elif scene.has_method("set_pause"):scene.set_pause(true)
  elif scene.has_method("pause_game"):scene.pause_game()
 scene.set_process_input(false);scene.set_process_unhandled_input(false)
 modal_layer=CanvasLayer.new();modal_layer.name="ExperienceModal";modal_layer.layer=100;add_child(modal_layer)
 return true
func open_settings(candidate=null):
 var scene=current_scene(candidate)
 if not _begin_modal(scene):return
 active_modal=SettingsPanel.new();modal_layer.add_child(active_modal)
 active_modal.setup(path_for(scene),func():_close_modal(),func(applied):
  settings=applied.duplicate(true);apply_to_scene(scene,settings);applied_signature="")
 _update_entries(scene)
func open_chapters(candidate=null):
 var scene=current_scene(candidate)
 if not actual_main_menu(scene) or not _begin_modal(scene):return
 active_modal=ChapterSelect.new();modal_layer.add_child(active_modal)
 active_modal.setup(path_for(scene),func():_close_modal())
 _update_entries(scene)
func _close_modal(resume_host=true):
 var host=modal_host
 var snapshot=modal_snapshot.duplicate()
 if is_instance_valid(modal_layer):modal_layer.queue_free()
 active_modal=null;modal_layer=null;modal_host=null;modal_snapshot={}
 if not is_instance_valid(host):return
 host.set_process_input(snapshot.get("input",true));host.set_process_unhandled_input(snapshot.get("unhandled",true))
 if resume_host and not snapshot.get("main_menu",false) and not snapshot.get("paused",false) and snapshot.get("mode","")!="pause":
  if host.has_method("set_game_paused"):host.set_game_paused(false)
  elif host.has_method("set_pause"):host.set_pause(false)
  elif host.has_method("resume"):host.resume()
  else:
   for button in buttons_under(host):
    if button.text=="Devam et" and button.is_visible_in_tree():button.pressed.emit();break
 applied_signature=""
func _sync_settings(scene,_prefs:Dictionary):
 # Visual defaults are not new persisted facts. Keep chapter snapshots aligned with
 # the latest saved settings, especially after a settings modal saves independently.
 var latest=preferences.store.load_progress(path_for(scene))
 if not latest.ok:return
 var prefs:Dictionary=latest.data.settings
 if has_property(scene,"settings"):scene.settings=prefs.duplicate(true)
 for property in ["data","save_data"]:
  var data=value(scene,property)
  if data is Dictionary and data.has("settings"):data.settings=prefs.duplicate(true)
 var adapter=value(scene,"save_service")
 if has_property(adapter,"main_data") and adapter.main_data is Dictionary:adapter.main_data.settings=prefs.duplicate(true)
func controls_for(scene)->Array:
 var display=value(scene,"control_display")
 var controls=value(display,"buttons",[])
 return controls if not controls.is_empty() else value(scene,"touch_buttons",[])
func _ui_signature(scene)->String:
 var ids=[]
 for button in controls_for(scene):
  if is_instance_valid(button):ids.append(button.get_instance_id())
 for key in ["quest","hint","counter","hud","line_text","active_line","comic","dialogue"]:
  var item=value(scene,key)
  if is_instance_valid(item):ids.append(item.get_instance_id())
 return str(ids)
func apply_to_scene(candidate=null,raw={}):
 var scene=current_scene(candidate)
 if not is_instance_valid(scene):return
 if raw.is_empty():raw=preferences.read(path_for(scene)).settings
 settings=preferences.apply(raw)
 _sync_settings(scene,settings)
 _apply_controls(scene)
 _apply_text_fields(scene)
 _refresh_expanded_hud(scene)
 var camera=value(scene,"camera")
 if is_instance_valid(camera) and camera is Camera2D:
  if not camera.has_meta("experience_smoothing"):camera.set_meta("experience_smoothing",camera.position_smoothing_enabled)
  camera.position_smoothing_enabled=false if settings.reduced_motion else camera.get_meta("experience_smoothing")
  if settings.reduced_motion:camera.reset_smoothing()
 scene.set_meta("experience_preferences",settings.duplicate(true))
 scene.set_meta("experience_limitations",limitations.duplicate())
func _reset_controls(scene):
 for method in ["clear_gameplay_inputs","reset_controls","reset_input"]:
  if scene.has_method(method):scene.call(method);return
func _apply_controls(scene):
 var display=value(scene,"control_display")
 var controls=controls_for(scene)
 var router=value(scene,"input_router",value(scene,"router"))
 if not is_instance_valid(router) or not has_property(router,"regions") or controls.is_empty():return
 var roles={}
 for button in controls:
  if not is_instance_valid(button):continue
  if not button.has_meta("experience_role"):
   for role in router.regions:
    if router.regions[role].size!=Vector2.ZERO and router.regions[role].position.is_equal_approx(button.position):button.set_meta("experience_role",role);break
  if button.has_meta("experience_role"):
   var role=button.get_meta("experience_role");roles[role]=button
   if not button.has_meta("experience_rect"):button.set_meta("experience_rect",button.get_rect())
 if not roles.has_all(["left","right","jump"]):return
 var scale_factor=float(settings.control_scale)
 if scale_factor==1.0 and not settings.left_handed:
  for role in roles:
   var original:Rect2=roles[role].get_meta("experience_rect")
   roles[role].position=original.position;roles[role].size=original.size
  router.bind_controls(roles.left.get_rect(),roles.right.get_rect(),roles.jump.get_rect(),roles.action.get_rect() if roles.has("action") else Rect2())
  var native_action=value(scene,"action_button")
  if not roles.has("action") and is_instance_valid(native_action) and native_action.has_meta("experience_rect"):
   var original:Rect2=native_action.get_meta("experience_rect");native_action.position=original.position;native_action.size=original.size
  _cache_control_positions(scene,roles)
  _reset_controls(scene)
  for field in ["hint","controls_hint"]:
   var label=value(scene,field)
   if is_instance_valid(label) and label is Label and label.has_meta("experience_rect"):
    var original:Rect2=label.get_meta("experience_rect");label.position=original.position;label.size=original.size
    var backing=_hint_backing(label)
    if is_instance_valid(backing) and backing.has_meta("experience_background_rect"):
     var original_background:Rect2=backing.get_meta("experience_background_rect")
     backing.position=original_background.position;backing.size=original_background.size
  return
 var right_stacked=false
 if roles.has("action"):
  var base_jump:Rect2=roles.jump.get_meta("experience_rect")
  var base_action:Rect2=roles.action.get_meta("experience_rect")
  right_stacked=base_action.end.y<=base_jump.position.y
 for role in roles:
  var button:Button=roles[role]
  var original:Rect2=button.get_meta("experience_rect")
  button.size=original.size*scale_factor
  button.position.y=original.end.y-button.size.y
 roles.left.position.x=24
 roles.right.position.x=24+roles.left.size.x+16
 roles.jump.position.x=1256-roles.jump.size.x
 if roles.has("action"):
  if right_stacked:
   roles.action.position.x=1256-roles.action.size.x
   roles.action.position.y=minf(roles.action.position.y,roles.jump.position.y-16-roles.action.size.y)
  else:roles.action.position.x=roles.jump.position.x-16-roles.action.size.x
 elif has_property(scene,"action_button") and is_instance_valid(scene.action_button):
  var action:Button=scene.action_button
  if not action.has_meta("experience_rect"):action.set_meta("experience_rect",action.get_rect())
  var original:Rect2=action.get_meta("experience_rect")
  action.size=original.size*scale_factor
  action.position=Vector2(minf(original.position.x,roles.jump.position.x-16-action.size.x),original.end.y-action.size.y)
 if settings.left_handed:
  for role in roles:roles[role].position.x=1280-roles[role].position.x-roles[role].size.x
  if not roles.has("action") and is_instance_valid(value(scene,"action_button")):
   scene.action_button.position.x=1280-scene.action_button.position.x-scene.action_button.size.x
  var left_x=roles.left.position.x;roles.left.position.x=roles.right.position.x;roles.right.position.x=left_x
 var action_rect=roles.action.get_rect() if roles.has("action") else Rect2()
 router.bind_controls(roles.left.get_rect(),roles.right.get_rect(),roles.jump.get_rect(),action_rect)
 _cache_control_positions(scene,roles)
 _reset_controls(scene)
 # Reflow the central hint and its image backing away from larger touch controls.
 var left_end=maxf(roles.left.get_rect().end.x,roles.right.get_rect().end.x)
 var right_start=roles.jump.position.x
 if roles.has("action"):right_start=minf(right_start,roles.action.position.x)
 if settings.left_handed:
  left_end=roles.jump.get_rect().end.x
  if roles.has("action"):left_end=maxf(left_end,roles.action.get_rect().end.x)
  right_start=minf(roles.left.position.x,roles.right.position.x)
 for field in ["hint","controls_hint"]:
  var label=value(scene,field)
  if not is_instance_valid(label) or not label is Label or label.position.y<550:continue
  if not label.has_meta("experience_rect"):label.set_meta("experience_rect",label.get_rect())
  var base:Rect2=label.get_meta("experience_rect")
  label.position.x=maxf(base.position.x,left_end+16)
  label.size.x=maxf(100,right_start-16-label.position.x)
  var backing=_hint_backing(label)
  if is_instance_valid(backing):
   if not backing.has_meta("experience_background_rect"):backing.set_meta("experience_background_rect",backing.get_rect())
   var original_background:Rect2=backing.get_meta("experience_background_rect")
   backing.position=Vector2(label.position.x-8,minf(original_background.position.y,label.position.y-8))
   backing.size=Vector2(label.size.x+16,maxf(original_background.size.y,label.size.y+16))
   backing.position.y=minf(backing.position.y,720-backing.size.y)
func _hint_backing(label:Label):
 if label.has_meta("experience_backing_id"):
  var stored=instance_from_id(int(label.get_meta("experience_backing_id")))
  return stored if is_instance_valid(stored) else null
 var original:Rect2=label.get_meta("experience_rect",label.get_rect())
 for child in label.get_parent().get_children():
  if child is TextureRect and _image_source(child).ends_with("panel.webp") and child.size.y<180 and child.get_rect().has_point(original.get_center()):
   label.set_meta("experience_backing_id",child.get_instance_id());return child
 return null
func _image_source(node)->String:
 if not is_instance_valid(node):return ""
 if node.has_meta("image_source"):return str(node.get_meta("image_source"))
 var texture=value(node,"texture")
 while texture is AtlasTexture:texture=texture.atlas
 return texture.resource_path if texture is Texture2D else ""
func _source_layer(node):
 var parent=node
 while is_instance_valid(parent):
  if parent is CanvasLayer:return parent
  parent=parent.get_parent()
 return null
func _suppress_hud_node(node):
 node.set_meta("experience_suppress_hud",true)
 if not node.has_meta("experience_visibility_guard"):
  node.visibility_changed.connect(_keep_old_hud_hidden.bind(node.get_instance_id()))
  node.set_meta("experience_visibility_guard",true)
 node.hide()
func _keep_old_hud_hidden(id:int):
 var node=instance_from_id(id)
 if is_instance_valid(node) and node.get_meta("experience_suppress_hud",false) and node.visible:node.hide()
func _hide_old_hud(scene):
 var backings=[]
 for node in scene.find_children("*","TextureRect",true,false):
  var layer=_source_layer(node)
  if not is_instance_valid(layer) or layer==hud_layer or layer.layer>10:continue
  if not _image_source(node).ends_with("panel.webp") or not node.is_visible_in_tree():continue
  var rect=node.get_global_rect()
  if rect.size.y>220 or not Rect2(0,0,1280,720).encloses(rect):continue
  if rect.position.y<300 or rect.position.y>550:backings.append(node)
 for backing in backings:
  var id=backing.get_instance_id()
  if not hidden_hud_nodes.has(id):hidden_hud_nodes[id]={"node":weakref(backing),"visible":backing.visible}
  _suppress_hud_node(backing)
  # Hide the anonymous static chapter/title labels painted on the replaced plate.
  for child in backing.get_parent().get_children():
   if not child is Label or child.has_meta("experience_font"):continue
   if not backing.get_global_rect().has_point(child.get_global_rect().get_center()):continue
   var child_id=child.get_instance_id()
   if not hidden_hud_nodes.has(child_id):hidden_hud_nodes[child_id]={"node":weakref(child),"visible":child.visible}
   _suppress_hud_node(child)
func _restore_old_hud():
 for item in hidden_hud_nodes.values():
  var node=item.node.get_ref()
  if is_instance_valid(node):node.set_meta("experience_suppress_hud",false);node.visible=item.visible
 hidden_hud_nodes.clear()
func _measured_text(font:Font,text:String,width:float,size:int)->float:
 var key=str(font.get_instance_id())+":"+str(width)+":"+str(size)+":"+text
 if text_measure_cache.has(key):return text_measure_cache[key]
 # Width is explicit before shaping. Avoid an initial zero-width Label minimum
 # feeding thousands of pixels back into the card/control layout.
 var lines=1
 var line=""
 for word in text.split(" "):
  var candidate=word if line.is_empty() else line+" "+word
  if not line.is_empty() and font.get_string_size(candidate,HORIZONTAL_ALIGNMENT_LEFT,-1,size).x>width:
   lines+=1;line=word
  else:line=candidate
 var height=font.get_height(size)*lines+maxi(0,lines-1)*3.0+8.0
 text_measure_cache[key]=height
 return height
const HUD_FIELDS=["quest","hint","counter","count_label","mote_label","chapter_note","hud","quest_label","save_notice","subtitle","controls_hint"]
func _apply_text_fields(scene):
 for property in HUD_FIELDS:
  var label=value(scene,property)
  if not is_instance_valid(label) or not label is Label:continue
  if not label.has_meta("experience_font"):
   label.set_meta("experience_font",label.get_theme_font_size("font_size"))
   label.set_meta("experience_text_alpha",label.modulate.a)
   label.set_meta("experience_hud_rect",label.get_rect())
  # The source font stays chapter-owned, including keyboard/touch mode changes.
  # Larger live reading cards use their own explicit reserved area.
func _hud_playing(scene)->bool:
 if bool(value(scene,"paused",false)) or actual_pause_menu(scene):return false
 var mode=str(value(scene,"mode","play"))
 return mode in ["play","building","lowering","gathering","shared","solo"]
func _restore_hud_sources():
 for item in hud_copies.values():
  var source=item.source
  if is_instance_valid(source):source.modulate.a=float(source.get_meta("experience_text_alpha",1.0))
func _legacy_camera_framing(scene):
 var script=scene.get_script()
 var path=script.resource_path if script else ""
 if not (path.ends_with("polish_world.gd") or path.ends_with("river_world.gd") or path.ends_with("garden_world.gd")):return
 var camera=value(scene,"camera")
 if not is_instance_valid(camera) or not camera is Camera2D:return
 var visible_controls=false
 for button in controls_for(scene):
  if is_instance_valid(button) and button.is_visible_in_tree():visible_controls=true;break
 var large=float(settings.get("text_scale",1))>1 or (visible_controls and float(settings.get("control_scale",1))>1)
 var active=large or (path.ends_with("river_world.gd") and visible_controls)
 if not camera.has_meta("experience_camera_baseline"):
  camera.set_meta("experience_camera_baseline",{"y":camera.position.y,"top":camera.limit_top,"bottom":camera.limit_bottom,"speed":camera.position_smoothing_speed})
 var previous=bool(camera.get_meta("experience_camera_active",false))
 if active:
  camera.position.y=-60;camera.limit_top=-144;camera.limit_bottom=940;camera.position_smoothing_speed=12.0
 else:
  var baseline:Dictionary=camera.get_meta("experience_camera_baseline")
  camera.position.y=baseline.y;camera.limit_top=baseline.top;camera.limit_bottom=baseline.bottom;camera.position_smoothing_speed=baseline.speed
 if previous!=active:
  camera.set_meta("experience_camera_active",active);camera.reset_smoothing();camera.force_update_scroll()
 var background=value(scene,"bg",value(scene,"backdrop"))
 if is_instance_valid(background):
  if not background.has_meta("experience_background_y"):background.set_meta("experience_background_y",background.position.y)
  background.position.y=camera.get_screen_center_position().y-360 if active else float(background.get_meta("experience_background_y"))
func _refresh_expanded_hud(scene):
 _legacy_camera_framing(scene)
 if float(settings.get("text_scale",1.0))<=1:
  _restore_hud_sources();_restore_old_hud()
  if is_instance_valid(hud_layer):hud_layer.visible=false
  return
 if not is_instance_valid(hud_layer) or hud_layer.get_parent()!=scene:
  _restore_hud_sources();_restore_old_hud();hud_copies.clear();hud_cards.clear()
  hud_layer=CanvasLayer.new();hud_layer.name="ExpandedHUD";hud_layer.layer=85;scene.add_child(hud_layer)
  for group in ["primary","secondary","bottom"]:
   hud_cards[group]=UI.texture("res://assets/polish-v3/panel.webp",Rect2(),hud_layer)
 hud_layer.visible=_hud_playing(scene) and not is_instance_valid(active_modal)
 if hud_layer.visible:_hide_old_hud(scene)
 else:_restore_old_hud()
 var groups={"primary":[],"secondary":[],"bottom":[]}
 var bottom_reserve=0.0
 var bottom_fields=0
 for property in HUD_FIELDS:
  var source=value(scene,property)
  if not is_instance_valid(source) or not source is Label:continue
  if not source.has_meta("experience_font"):
   source.set_meta("experience_font",source.get_theme_font_size("font_size"));source.set_meta("experience_text_alpha",source.modulate.a)
  if source.get_theme_font_size("font_size")!=int(source.get_meta("experience_font")):
   source.set_meta("experience_font",source.get_theme_font_size("font_size"))
  if not source.has_meta("experience_hud_rect"):source.set_meta("experience_hud_rect",source.get_rect())
  var base=int(source.get_meta("experience_font"))
  var size=roundi(base*float(settings.text_scale))
  var original_rect:Rect2=source.get_meta("experience_hud_rect")
  var bottom=property in ["hint","subtitle","controls_hint"] and original_rect.position.y>=500
  var group="bottom" if bottom else "secondary" if property in ["counter","count_label","mote_label"] else "primary"
  var width=1184.0 if group=="bottom" else 208.0 if group=="secondary" else 808.0
  var text=source.text.replace("\n"," · ")
  var font=source.get_theme_font("font")
  var height=_measured_text(font,text,width,size)
  if group=="bottom":bottom_reserve=maxf(bottom_reserve,height);bottom_fields+=1
  if not hud_copies.has(property):
   var copy=UI.label("",Rect2(0,0,width,height),size,hud_layer,source.get_theme_color("font_color"))
   copy.name="Expanded_"+property;hud_copies[property]={"source":source,"label":copy,"group":group,"property":property,"height":height}
  var item=hud_copies[property]
  if is_instance_valid(item.source) and item.source!=source:item.source.modulate.a=float(item.source.get_meta("experience_text_alpha",1.0))
  item.source=source;item.group=group;item.height=height
  var copy:Label=item.label
  copy.size.x=width
  copy.text=text;copy.add_theme_font_size_override("font_size",size)
  copy.add_theme_color_override("font_color",source.get_theme_color("font_color"))
  copy.size=Vector2(width,height)
  copy.visible=source.is_visible_in_tree() and not source.text.is_empty()
  source.modulate.a=0.0
  if copy.visible:groups[group].append(item)
 groups.primary.sort_custom(func(a,b):return ["hud","quest","quest_label","chapter_note","save_notice","hint"].find(a.property)<["hud","quest","quest_label","chapter_note","save_notice","hint"].find(b.property))
 var y=34.0
 for item in groups.primary:
  item.label.position=Vector2(48,y);y+=item.height+8
 hud_cards.primary.position=Vector2(24,18);hud_cards.primary.size=Vector2(856,maxf(80,y-18+8));hud_cards.primary.visible=not groups.primary.is_empty()
 y=34.0
 for item in groups.secondary:
  item.label.position=Vector2(916,y);y+=item.height+8
 hud_cards.secondary.position=Vector2(900,18);hud_cards.secondary.size=Vector2(240,maxf(80,y-18+8));hud_cards.secondary.visible=not groups.secondary.is_empty()
 var reserve_key=float(scene.get_meta("experience_footer_scale",0.0))
 if not is_equal_approx(reserve_key,float(settings.text_scale)):
  scene.set_meta("experience_footer_reserve",0.0);scene.set_meta("experience_footer_scale",float(settings.text_scale))
 bottom_reserve=maxf(bottom_reserve,float(scene.get_meta("experience_footer_reserve",0.0)))
 scene.set_meta("experience_footer_reserve",bottom_reserve)
 var footer_height=bottom_reserve+16 if bottom_fields>0 else 0.0
 var footer_top=712-footer_height if bottom_fields>0 else 720.0
 y=footer_top+8
 for item in groups.bottom:
  item.label.position=Vector2(48,y);y+=item.height+8
 hud_cards.bottom.position=Vector2(24,footer_top);hud_cards.bottom.size=Vector2(1232,footer_height);hud_cards.bottom.visible=not groups.bottom.is_empty()
 # Reserve the footer even while its current hint is empty, so held controls do not
 # move repeatedly when the player enters/leaves a proximity hint.
 _shift_controls_for_footer(scene,footer_top-8 if bottom_fields>0 else 720.0)
 for property in hud_copies:
  if not is_instance_valid(value(scene,property)):hud_copies[property].label.hide()
func _cache_control_positions(scene,roles:Dictionary):
 for button in roles.values():button.set_meta("experience_control_position",button.position)
 var action=value(scene,"action_button")
 if is_instance_valid(action) and action not in roles.values():action.set_meta("experience_control_position",action.position)
 control_footer_shift=-1.0
func _shift_controls_for_footer(scene,maximum_bottom:float):
 var display=value(scene,"control_display")
 var controls=controls_for(scene).duplicate()
 var action=value(scene,"action_button")
 if is_instance_valid(action) and action not in controls:controls.append(action)
 var bottom=0.0
 for button in controls:
  if not is_instance_valid(button):continue
  var base:Vector2=button.get_meta("experience_control_position",button.position)
  bottom=maxf(bottom,base.y+button.size.y)
 var shift=maxf(0,bottom-maximum_bottom)
 if is_equal_approx(shift,control_footer_shift):return
 control_footer_shift=shift
 var router=value(scene,"input_router",value(scene,"router"))
 if not is_instance_valid(router):return
 var regions={"left":Rect2(),"right":Rect2(),"jump":Rect2(),"action":Rect2()}
 for button in controls:
  if not is_instance_valid(button):continue
  var base:Vector2=button.get_meta("experience_control_position",button.position)
  button.position=base-Vector2(0,shift)
  var role=str(button.get_meta("experience_role",""))
  if not role.is_empty():regions[role]=button.get_rect()
 router.bind_controls(regions.left,regions.right,regions.jump,regions.action)
 _reset_controls(scene)
func _apply_dialogue(scene,delta:float):
 var runner=value(scene,"runner")
 var line=value(scene,"line_text",value(scene,"active_line"))
 var chars_key="type_chars" if has_property(scene,"type_chars") else "chars"
 if is_instance_valid(runner) and value(runner,"active",false) and is_instance_valid(line) and line is Label:
  if settings.get("full_text",false):runner.revealed=true;line.visible_characters=-1
  elif has_property(scene,chars_key) and not runner.revealed:
   scene.set(chars_key,maxf(0,float(scene.get(chars_key))+delta*34.0*(float(settings.get("text_speed",1.0))-1.0)))
   if float(scene.get(chars_key))>=runner.current.text.length():runner.revealed=true
   line.visible_characters=-1 if runner.revealed else int(scene.get(chars_key))
  _show_reader(scene,line,runner.current.text)
 else:
  var comic=value(scene,"comic")
  if value(scene,"dialogue_active",false) and is_instance_valid(comic) and comic.is_visible_in_tree() and not actual_pause_menu(scene):
   var lines=value(scene,"dialogue_lines",[])
   var index=int(value(scene,"dialogue_index",0))
   if index>=0 and index<lines.size():line=value(comic,str(lines[index].get("side","left"))+"_line")
   else:
    for property in ["left_line","right_line"]:
     var candidate=value(comic,property)
     if is_instance_valid(candidate) and candidate is Label and not candidate.text.is_empty():line=candidate
   if is_instance_valid(line) and line is Label:_show_reader(scene,line,line.text);return
  _hide_reader()
func _show_reader(scene,line:Label,text:String):
 if float(settings.get("text_scale",1.0))<=1:_hide_reader();return
 if not is_instance_valid(reader_layer) or reader_layer.get_parent()!=scene:
  reader_layer=CanvasLayer.new();reader_layer.name="AccessibleDialogue";reader_layer.layer=80;scene.add_child(reader_layer)
  reader_panel=UI.texture("res://assets/polish-v3/panel.webp",Rect2(58,82,1164,430),reader_layer)
  reader_text=UI.label("",Rect2(115,116,1050,350),35,reader_layer)
 if is_instance_valid(reader_source) and reader_source!=line:reader_source.modulate.a=1.0
 reader_source=line;line.modulate.a=0.0
 reader_panel.show();reader_text.show()
 reader_text.text=text
 reader_text.add_theme_font_size_override("font_size",roundi(line.get_theme_font_size("font_size")*float(settings.text_scale)))
 reader_text.visible_characters=line.visible_characters
func _hide_reader():
 if is_instance_valid(reader_source):reader_source.modulate.a=1.0
 reader_source=null
 if is_instance_valid(reader_panel):reader_panel.hide()
 if is_instance_valid(reader_text):reader_text.hide()
func _apply_reduced_decorations(scene):
 if not settings.get("reduced_motion",false):return
 var effects=value(scene,"contribution_tweens",[])
 for tween in effects:
  if not value(scene,"paused",false) and value(scene,"mode","")!="pause" and is_instance_valid(tween) and tween.is_valid():tween.custom_step(10.0)
 var camera=value(scene,"camera")
 if is_instance_valid(camera) and camera is Camera2D:
  if has_property(camera,"desired_axis"):camera.desired_axis=0.0;camera.position.x=0
  elif camera.has_method("_physics_process") and scene.has_method("update_camera"):scene.update_camera(true)
 for property in ["player","actor","friend","badger","monkey","rabbit"]:
  var actor=value(scene,property)
  if not is_instance_valid(actor):continue
  if has_property(actor,"impact"):actor.impact=0.0
  if has_property(actor,"motion_time"):actor.motion_time=0.0
  var anim=value(actor,"anim")
  if is_instance_valid(anim) and anim is AnimatedSprite2D and actor.get_script().resource_path in ["res://scripts/polish_actor.gd","res://scripts/chapters/festival_actor.gd"]:anim.scale=Vector2.ONE*0.125
