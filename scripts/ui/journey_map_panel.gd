extends Control
## Painted world + live accessible controls. Locked regions are previews, never navigation.
const Map=preload("res://scripts/core/journey_map.gd")
const Replay=preload("res://scripts/core/replay_service.gd")
const UI=preload("res://scripts/polish_ui.gd")
const ART="res://assets/journey-map/forest-journey-v1.webp"
var model=Map.new()
var save_path=""
var on_close:Callable
var navigation:Callable
var resume_current:Callable
var selected=""
var snapshot={}
var nodes:Array[Button]=[]
var scroll:ScrollContainer
var canvas:Control
var title_label:Label
var state_label:Label
var description:Label
var status_label:Label
var primary_button:Button
var replay_button:Button
var back_button:Button
var text_scale=1.0
var compact=false
var touch_id=-1
var touch_origin=Vector2.ZERO
var touch_scroll=Vector2.ZERO
var touch_button:Button
var touch_scrolling=false
var touch_moved=false
func setup(path:String,close_callback:Callable,navigation_callback:Callable=Callable(),resume_callback:Callable=Callable()):
 save_path=path;on_close=close_callback;navigation=navigation_callback;resume_current=resume_callback
 var prefs=get_tree().root.get_meta("catpat_preferences",{})
 text_scale=clampf(float(prefs.get("text_scale",1.0)),1.0,1.3)
 compact=get_tree().root.size.x<900
 snapshot=model.snapshot(save_path);selected=snapshot.current if snapshot.ok else "B00"
 build();select_region(selected)
 nodes[Replay.CHAPTERS.find(selected)].call_deferred("grab_focus")
func build():
 name="JourneyMapPanel";size=Vector2(1280,720);mouse_filter=Control.MOUSE_FILTER_STOP
 var background=UI.texture(ART,Rect2(0,0,1280,720),self);background.modulate=Color(0.30,0.42,0.38)
 UI.texture("res://assets/polish-v3/panel.webp",Rect2(16,14,1248,78),self)
 UI.label("Festival yolu",Rect2(42,25,500,58),40,self)
 UI.label("Bir bölgeye dokun",Rect2(560,33,400,46),26,self,Color("d4e2cf"))
 back_button=UI.button("Geri dön",Rect2(1030,14,230,78),self,close)
 scroll=ScrollContainer.new();scroll.position=Vector2(24,102);scroll.size=Vector2(842,560)
 scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_AUTO;scroll.vertical_scroll_mode=ScrollContainer.SCROLL_MODE_AUTO
 add_child(scroll)
 canvas=Control.new();canvas.custom_minimum_size=Vector2(1230,820) if compact else Vector2(840,560)
 scroll.add_child(canvas)
 UI.texture(ART,Rect2(Vector2.ZERO,canvas.custom_minimum_size),canvas)
 for i in Replay.CHAPTERS.size():
  var chapter:String=Replay.CHAPTERS[i]
  var point:Vector2=Map.POINTS[i]*canvas.custom_minimum_size
  var node=UI.button(str(i+1),Rect2(point-Vector2(48,44),Vector2(96,88)),canvas,select_region.bind(chapter),true)
  node.name="Map_"+chapter;node.tooltip_text=Map.TITLES[chapter]
  node.add_theme_font_size_override("font_size",32)
  nodes.append(node)
  node.focus_entered.connect(select_region.bind(chapter,false))
 UI.texture("res://assets/polish-v3/panel.webp",Rect2(884,102,372,560),self)
 title_label=UI.label("",Rect2(910,122,320,108),int(34*text_scale),self)
 state_label=UI.label("",Rect2(910,240,320,50),int(25*text_scale),self,Color("edc778"))
 description=UI.label("",Rect2(910,300,320,170),int(24*text_scale),self)
 primary_button=UI.button("",Rect2(908,478,324,80),self,activate,true)
 primary_button.add_theme_font_size_override("font_size",int(23*text_scale))
 replay_button=UI.button("Yeniden oyna",Rect2(908,568,324,78),self,replay_selected)
 replay_button.add_theme_font_size_override("font_size",int(23*text_scale))
 status_label=UI.label("",Rect2(30,668,1220,48),24,self)
func select_region(chapter:String,focus=true):
 if chapter not in Replay.CHAPTERS:return
 selected=chapter
 snapshot=model.snapshot(save_path)
 var index=Replay.CHAPTERS.find(chapter)
 var row:Dictionary=snapshot.rows[index]
 title_label.text=row.title
 state_label.text="Buradasın" if row.current else "Tamamlandı" if row.completed else "Keşfedilecek"
 description.text=row.preview
 primary_button.visible=row.current or row.completed
 primary_button.text="Kaldığın yerden" if row.current else "Yeniden oyna"
 replay_button.visible=row.current and row.completed
 status_label.text="Haritayı kaydırabilirsin. Seçili bölge: "+row.title if compact else "Seçili bölge: "+row.title
 if not snapshot.ok:status_label.text="Yolculuk kaydı açılamadı. Ana menüden başlayabilir veya kaydını yeniden açabilirsin."
 elif snapshot.recovered:status_label.text="Yolculuğun güvenli yedekten açılacak."
 for i in nodes.size():
  var region:Dictionary=snapshot.rows[i]
  var marker="●" if region.current else "✓" if region.completed else "·"
  nodes[i].text=str(i+1)+" "+marker
  nodes[i].tooltip_text=region.title+" · "+("Buradasın" if region.current else "Tamamlandı" if region.completed else "Keşfedilecek")
  nodes[i].modulate=Color.WHITE if i==index else Color(0.78,0.85,0.80) if region.state!="locked" else Color(0.60,0.70,0.66)
 if focus:nodes[index].grab_focus()
 scroll.call_deferred("ensure_control_visible",nodes[index])
func can_act()->bool:
 if not is_visible_in_tree() or is_queued_for_deletion():return false
 var host=get_tree().root.get_node_or_null("CatpatExperience")
 return not is_instance_valid(host) or not host.application_focus_lost
func activate():
 if not can_act():return
 var fresh=model.snapshot(save_path)
 var row:Dictionary=fresh.rows[Replay.CHAPTERS.find(selected)]
 var old:Dictionary=snapshot.rows[Replay.CHAPTERS.find(selected)]
 if row.state!=old.state or fresh.primary_path!=snapshot.primary_path:
  select_region(selected);status_label.text="Yolculuk güncellendi. Gitmek istediğin bölgeyi yeniden seç.";return
 if not row.current:
  if row.completed:replay_selected()
  else:select_region(selected)
  return
 # A pause map can return to its existing world without reloading or writing it.
 if resume_current.is_valid() and resume_current.call(fresh.primary_path,selected):return
 var result=model.continue_primary(save_path,navigation)
 if result.ok:queue_free()
 else:status_label.text="Yolculuk açılamadı. Kaydın korundu; yeniden deneyebilirsin."
func replay_selected():
 if not can_act():return
 var result=model.replay.start(selected,save_path,navigation)
 if result.ok:queue_free()
 else:status_label.text="Bölüm açılamadı. Ana yolculuğun korundu; yeniden deneyebilirsin."
func close():
 if on_close.is_valid():on_close.call()
 queue_free()
func _input(event):
 if not can_act():
  touch_id=-1;touch_button=null;return
 if event is InputEventMouseButton and event.device==InputEvent.DEVICE_ID_EMULATION:
  get_viewport().set_input_as_handled();return
 if event is InputEventScreenTouch:
  if event.pressed and not event.canceled and touch_id==-1:
   touch_id=event.index;touch_origin=event.position;touch_moved=false
   touch_scrolling=scroll.get_global_rect().has_point(event.position)
   touch_scroll=Vector2(scroll.scroll_horizontal,scroll.scroll_vertical);touch_button=null
   for button in nodes+[primary_button,replay_button,back_button]:
    if button.is_visible_in_tree() and not button.disabled and button.get_global_rect().has_point(event.position) and (button not in nodes or touch_scrolling):touch_button=button;break
  elif event.index==touch_id and (not event.pressed or event.canceled):
   var target=touch_button
   var activate_touch=not event.canceled and not touch_moved and touch_origin.distance_to(event.position)<18
   touch_id=-1;touch_button=null
   if activate_touch and is_instance_valid(target) and target.is_visible_in_tree() and not target.disabled and target.get_global_rect().has_point(event.position):target.pressed.emit()
  get_viewport().set_input_as_handled();return
 if event is InputEventScreenDrag:
  if event.index==touch_id:
   if touch_origin.distance_to(event.position)>18:touch_moved=true
   if touch_scrolling and touch_moved:
    var offset=touch_scroll+touch_origin-event.position
    scroll.scroll_horizontal=int(offset.x);scroll.scroll_vertical=int(offset.y)
  get_viewport().set_input_as_handled();return
 if not event is InputEventKey or not event.pressed or event.echo:return
 if event.keycode==KEY_ESCAPE:get_viewport().set_input_as_handled();close();return
 var step=-1 if event.keycode in [KEY_LEFT,KEY_UP] else 1 if event.keycode in [KEY_RIGHT,KEY_DOWN] else 0
 if step!=0 and nodes.any(func(b):return b.has_focus()):
  select_region(Replay.CHAPTERS[posmod(Replay.CHAPTERS.find(selected)+step,6)])
  get_viewport().set_input_as_handled()
