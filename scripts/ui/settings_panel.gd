extends Control
## Image-backed modal. Its host owns pause/resume and the current journey path.
const Preferences=preload("res://scripts/core/preferences.gd")
const UI=preload("res://scripts/polish_ui.gd")
const OPTIONS=[
 {"key":"music","label":"Müzik","values":[0.0,0.25,0.5,0.75,1.0]},
 {"key":"sfx","label":"Oyun sesleri","values":[0.0,0.25,0.5,0.75,1.0]},
 {"key":"text_speed","label":"Yazı hızı","values":[0.75,1.0,1.5]},
 {"key":"full_text","label":"Yazıyı hemen göster","values":[false,true]},
 {"key":"text_scale","label":"Yazı boyutu","values":[1.0,1.15,1.3]},
 {"key":"reduced_motion","label":"Daha az hareket","values":[false,true]},
 {"key":"control_scale","label":"Düğme boyutu","values":[1.0,1.15,1.3]},
 {"key":"left_handed","label":"Sol el düzeni","values":[false,true]}
]
var preferences=Preferences.new()
var save_path=""
var draft={}
var baseline={}
var on_close:Callable
var on_applied:Callable
var buttons:Array[Button]=[]
var setting_buttons={}
var status_label:Label
var saved=false
func setup(path:String,close_callback:Callable,applied_callback:Callable=Callable()):
 save_path=path;on_close=close_callback;on_applied=applied_callback
 var result=preferences.read(path)
 draft=result.settings.duplicate(true);baseline=draft.duplicate(true)
 build()
 if not result.ok:status_label.text="Kayıt açılamadı. Ayarları kaydetmeden geri dönebilirsin."
 buttons[0].call_deferred("grab_focus")
func build():
 for child in get_children():remove_child(child);child.queue_free()
 buttons.clear();setting_buttons.clear()
 name="SettingsPanel";size=Vector2(1280,720);mouse_filter=Control.MOUSE_FILTER_STOP
 var shade=UI.texture("res://assets/polish-v3/panel.webp",Rect2(0,0,1280,720),self)
 shade.modulate=Color(0.12,0.19,0.17,0.94)
 UI.texture("res://assets/polish-v3/panel.webp",Rect2(52,18,1176,682),self)
 UI.label("Oyun ayarları",Rect2(110,40,700,64),32,self)
 UI.label("Bir düğmeye dokunarak seçeneği değiştir.",Rect2(110,105,1050,45),22,self)
 for i in OPTIONS.size():
  var option=OPTIONS[i]
  var rect=Rect2(100+(i%3)*368,158+(i/3)*124,344,112)
  var button=UI.button("",rect,self,cycle.bind(option.key),true)
  button.name="Setting_"+option.key
  button.add_theme_font_size_override("font_size",24)
  setting_buttons[option.key]=button;buttons.append(button)
 # Ninth grid slot keeps the read-only status visible beside the last two settings.
 status_label=UI.label("Ayarlar bu yolculukla birlikte saklanır.",Rect2(842,410,330,140),20,self)
 var save_button=UI.button("Kaydet ve dön",Rect2(100,560,344,112),self,save_and_close,true)
 save_button.name="SavePreferences";buttons.append(save_button)
 buttons.append(UI.button("Varsayılanlar",Rect2(468,560,344,112),self,reset_draft))
 buttons.append(UI.button("Vazgeç",Rect2(836,560,344,112),self,close))
 for button in buttons:
  button.focus_mode=Control.FOCUS_ALL
 refresh()
func display_value(key:String)->String:
 var value=draft[key]
 if key in ["music","sfx"]:return "Kapalı" if value==0 else "%%%d"%roundi(value*100)
 if value is bool:return "Açık" if value else "Kapalı"
 if key=="text_speed":return "Sakin" if value<1 else "Normal" if value==1 else "Hızlı"
 return "Normal" if value<=1 else "Büyük" if value<1.3 else "En büyük"
func refresh():
 for option in OPTIONS:setting_buttons[option.key].text=option.label+": "+display_value(option.key)
func cycle(key:String):
 for option in OPTIONS:
  if option.key!=key:continue
  var values:Array=option.values
  var next=0
  for i in values.size():
   if values[i]==draft[key]:next=(i+1)%values.size();break
   if not values[i] is bool and float(values[i])>float(draft[key]):next=i;break
  draft[key]=values[next]
  break
 status_label.text="Değişiklikleri saklamak için Kaydet ve dön."
 refresh()
func reset_draft():
 # Retain host-owned setting keys, such as onboarding provenance.
 for key in Preferences.DEFAULTS:draft[key]=Preferences.DEFAULTS[key]
 status_label.text="Varsayılanlar seçildi. Saklamak için Kaydet ve dön."
 refresh()
func save_and_close():
 var changes={}
 for key in Preferences.DEFAULTS:
  if draft[key]!=baseline.get(key):changes[key]=draft[key]
 var result=preferences.save(save_path,changes)
 if not result.ok:
  status_label.text="Kaydedemedik; kayıt korundu.\nTekrar dene veya Vazgeç."
  return
 saved=true;draft=preferences.apply(result.settings)
 if on_applied.is_valid():on_applied.call(draft.duplicate(true))
 close()
func close():
 if on_close.is_valid():on_close.call()
 queue_free()
func _input(event):
 if not visible or not event is InputEventKey or not event.pressed or event.echo:return
 if event.keycode==KEY_ESCAPE:
  get_viewport().set_input_as_handled();close();return
 var step=0
 if event.keycode==KEY_TAB:step=-1 if event.shift_pressed else 1
 elif event.keycode==KEY_LEFT:step=-1
 elif event.keycode==KEY_RIGHT:step=1
 elif event.keycode==KEY_UP:step=-3
 elif event.keycode==KEY_DOWN:step=3
 if step==0:return
 var index=buttons.find(get_viewport().gui_get_focus_owner())
 buttons[posmod(maxi(0,index)+step,buttons.size())].grab_focus()
 get_viewport().set_input_as_handled()
