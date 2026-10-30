extends Control
const UI=preload("res://scripts/polish_ui.gd")
var on_close:Callable
var on_confirm:Callable
var buttons:Array[Button]=[]
var title_label:Label
var body_label:Label
var message_label:Label
var mode="help"
func build(title:String,body:String):
 size=Vector2(1280,720);mouse_filter=Control.MOUSE_FILTER_STOP
 UI.texture("res://assets/polish-v3/panel.webp",Rect2(0,0,1280,720),self).modulate=Color(0.12,0.19,0.17,0.95)
 UI.texture("res://assets/polish-v3/panel.webp",Rect2(180,70,920,580),self)
 title_label=UI.label(title,Rect2(245,120,790,105),34,self)
 body_label=UI.label(body,Rect2(245,235,790,240),25,self)
 message_label=UI.label("",Rect2(245,440,790,70),20,self)
func setup_help(context:Dictionary,close_callback:Callable):
 mode="help";on_close=close_callback
 build("Birlikte deneyelim · "+context.title,context.text)
 buttons.append(UI.button("Molaya dön",Rect2(430,520,420,100),self,close,true))
 buttons[0].call_deferred("grab_focus")
func setup_restart(context:Dictionary,confirm_callback:Callable,close_callback:Callable):
 mode="restart";on_close=close_callback;on_confirm=confirm_callback
 build("Bu bölümü yeniden başlatalım mı?","Yalnız mevcut bölüm yeniden başlar; önceki bölümler korunur.\nBu bölümün görevleri ve topladıkların sıfırlanır.")
 body_label.size.y=180
 buttons.append(UI.button("Yeniden başlat",Rect2(260,520,350,100),self,confirm,true))
 buttons.append(UI.button("Molaya dön",Rect2(670,520,350,100),self,close))
 buttons[1].call_deferred("grab_focus")
func show_error(restored=true):
 message_label.text="Kaydı değiştirmedik. Yeniden dene veya Molaya dön." if restored else "Kaydı geri yükleyemedik. Yeni deneme başlatmadan bir büyüğünden yardım iste."
func confirm():
 if on_confirm.is_valid():on_confirm.call()
func close():
 if on_close.is_valid():on_close.call()
 queue_free()
func _input(event):
 if not visible or not event is InputEventKey or not event.pressed or event.echo:return
 if event.keycode==KEY_ESCAPE:get_viewport().set_input_as_handled();close();return
 if event.keycode not in [KEY_TAB,KEY_LEFT,KEY_RIGHT,KEY_UP,KEY_DOWN]:return
 var step=-1 if event.keycode in [KEY_LEFT,KEY_UP] or (event.keycode==KEY_TAB and event.shift_pressed) else 1
 var index=buttons.find(get_viewport().gui_get_focus_owner())
 buttons[posmod(index+step,buttons.size())].grab_focus();get_viewport().set_input_as_handled()
