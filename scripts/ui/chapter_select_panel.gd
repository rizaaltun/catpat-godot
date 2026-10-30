extends Control
## Completed-only chapter selection; image artwork, live text, isolated replay state.
const Replay=preload("res://scripts/core/replay_service.gd")
const UI=preload("res://scripts/polish_ui.gd")
var service=Replay.new()
var save_path=""
var on_close:Callable
var navigation:Callable
var buttons:Array[Button]=[]
var status_label:Label
func setup(path:String,close_callback:Callable,navigation_callback:Callable=Callable()):
 save_path=service.primary_path(path);on_close=close_callback;navigation=navigation_callback
 build()
 if not buttons.is_empty():buttons[0].call_deferred("grab_focus")
func build():
 for child in get_children():remove_child(child);child.queue_free()
 buttons.clear();name="ChapterSelectPanel";size=Vector2(1280,720);mouse_filter=Control.MOUSE_FILTER_STOP
 var shade=UI.texture("res://assets/polish-v3/panel.webp",Rect2(0,0,1280,720),self)
 shade.modulate=Color(0.12,0.19,0.17,0.95)
 UI.texture("res://assets/polish-v3/panel.webp",Rect2(50,20,1180,680),self)
 UI.label("Tamamladığın bölümler",Rect2(100,50,1080,58),40,self)
 UI.label("Tekrar oynama, ana yolculuğunu değiştirmez.",Rect2(100,112,1080,40),26,self)
 var available=service.completed_chapters(save_path)
 for i in available.size():
  var chapter:String=available[i]
  var rect=Rect2(100+(i%2)*580,170+(i/2)*124,500,112)
  var button=UI.button(chapter+" · "+Replay.TITLES[chapter],rect,self,start_chapter.bind(chapter),true)
  button.name="Replay_"+chapter;button.add_theme_font_size_override("font_size",28);buttons.append(button)
 status_label=UI.label("",Rect2(100,540,1080,40),24,self)
 if available.is_empty():
  UI.label("Tamamladığın bölümler burada açılır.\nAna menüden yolculuğuna devam edebilirsin.",Rect2(150,260,980,160),32,self)
 buttons.append(UI.button("Geri dön",Rect2(420,586,440,84),self,close))
 for button in buttons:button.focus_mode=Control.FOCUS_ALL
func start_chapter(chapter:String):
 var result=service.start(chapter,save_path,navigation)
 if not result.ok:
  status_label.text="Bölümü açamadık. Ana yolculuğun korundu; yeniden deneyebilirsin."
  return
 queue_free()
func close():
 if on_close.is_valid():on_close.call()
 queue_free()
func _input(event):
 if not visible or not event is InputEventKey or not event.pressed or event.echo:return
 if event.keycode==KEY_ESCAPE:get_viewport().set_input_as_handled();close();return
 var step=0
 if event.keycode==KEY_LEFT:step=-1
 elif event.keycode==KEY_RIGHT:step=1
 elif event.keycode==KEY_UP:step=-2
 elif event.keycode==KEY_DOWN:step=2
 if step==0 or buttons.is_empty():return
 var index=0
 for i in buttons.size():
  if buttons[i].has_focus():index=i;break
 buttons[posmod(index+step,buttons.size())].grab_focus();get_viewport().set_input_as_handled()
