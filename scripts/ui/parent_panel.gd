extends Control
## Adult transition, evidence context, local profiles and explicit portable transfers.
const UI=preload("res://scripts/polish_ui.gd")
const Store=preload("res://scripts/core/save_service.gd")
const Report=preload("res://scripts/core/parent_report.gd")
signal closed(profile_changed:bool)
var host:Node
var profiles:Node
var observations:Node
var journey_path=""
var active={}
var model={}
var report_data={}
var body:Control
var scroll:ScrollContainer
var gate_button:Button
var gate_label:Label
var gate_elapsed=0.0
var gate_down=false
var unlocked=false
var profile_changed=false
var tab="journey"
var content_y=0.0
var text_scale=1.0
var import_pending={}
var transfer_text:TextEdit
var web_callback
var status=""
var layout_items=[]
var layout_passes=0
var chrome_title:Label
var chrome_profile:Label
var chrome_tabs=[]
var history_page=0
var confirmation_mode=false
const MAX_TRANSFER_BYTES=2097152
func build(owner:Node,profile_host:Node,observation_host:Node):
 host=owner;profiles=profile_host;observations=observation_host
 journey_path=str(owner.get("save_path"))
 var prefs=owner.get("settings")
 if prefs is Dictionary:text_scale=clampf(float(prefs.get("text_scale",1.0)),1.0,1.3)
 size=Vector2(1280,720)
 _gate()
func _clear():
 confirmation_mode=false
 gate_button=null;gate_label=null;scroll=null;body=null;transfer_text=null
 layout_items.clear();chrome_tabs.clear();chrome_title=null;chrome_profile=null;layout_passes=6
 for child in get_children():remove_child(child);child.queue_free()
func _background():
 UI.texture("res://assets/chapter-v5/menu.webp",Rect2(0,0,1280,720),self)
 UI.texture("res://assets/polish-v3/panel.webp",Rect2(44,26,1192,668),self)
func _gate():
 _clear();_background();unlocked=false;gate_down=false;gate_elapsed=0
 UI.label("Ebeveyn alanı",Rect2(192,115,896,72),40,self,Color("efc97b"))
 UI.label("Bir yetişkinle birlikte açın.\nYolculukları ayırabilir, kayıtları inceleyebilir ve bu cihazdaki verileri yönetebilirsiniz.",Rect2(192,220,896,160),roundi(25*text_scale),self)
 gate_label=UI.label("Açmak için düğmeyi iki saniye basılı tutun.",Rect2(192,400,896,64),roundi(22*text_scale),self)
 gate_button=UI.button("Basılı tutarak aç",Rect2(366,494,548,88),self,func():pass,true)
 gate_button.button_down.connect(func():gate_down=true;gate_elapsed=0)
 gate_button.button_up.connect(func():gate_down=false;gate_elapsed=0)
 UI.button("Ana menüye dön",Rect2(442,600,396,65),self,close)
func _process(delta):
 if unlocked and layout_passes>0:
  _reflow();layout_passes-=1
 if unlocked or not gate_down or not is_instance_valid(gate_button):return
 gate_elapsed+=delta
 if is_instance_valid(gate_label):gate_label.text="Basılı tutun… %d"%maxi(1,ceili(2.0-gate_elapsed))
 if gate_elapsed>=2.0:open_report()
func _notification(what):
 if what in [NOTIFICATION_APPLICATION_FOCUS_OUT,NOTIFICATION_WM_WINDOW_FOCUS_OUT]:
  gate_down=false;gate_elapsed=0
  if is_instance_valid(gate_label):gate_label.text="Açmak için düğmeyi iki saniye basılı tutun."
func open_report():
 unlocked=true;gate_down=false;_refresh_model();show_tab("journey")
func _profile_for_path()->Dictionary:
 if is_instance_valid(profiles) and profiles.has_method("profile_for_path"):return profiles.profile_for_path(journey_path)
 return {}
func _refresh_model():
 active=_profile_for_path()
 var loaded=Store.new().load_progress(journey_path)
 report_data=loaded.data if loaded.get("ok",false) else {}
 var observed={"ok":true,"events":[]}
 if not active.is_empty() and is_instance_valid(observations):observed=observations.report_for(str(active.get("profile_id","")))
 model=Report.build(report_data,observed)
 if not loaded.get("ok",false):status="Yolculuk kaydı okunamadı. Mevcut dosyalar değiştirilmedi."
func _shell(title:String):
 _clear();_background()
 chrome_title=UI.label(title,Rect2(94,48,820,80),roundi(32*text_scale),self,Color("efc97b"))
 var close_button=UI.button("Ana menüye dön",Rect2(952,48,242,80),self,close)
 close_button.add_theme_font_size_override("font_size",roundi(20*text_scale))
 var label=str(active.get("label","Bu yolculuk"))
 chrome_profile=UI.label(label+" · Yalnız bu cihazdaki kayıtlar",Rect2(96,142,1088,56),roundi(18*text_scale),self,Color("b6dfcf"))
 var names={"journey":"Yolculuk","observations":"Gözlemler","profiles":"Profiller","data":"Veriler"}
 var x=96.0
 for key in names:
  var button=UI.button(names[key],Rect2(x,208,260,68),self,show_tab.bind(key),key==tab)
  button.add_theme_font_size_override("font_size",roundi(22*text_scale));chrome_tabs.append(button)
  x+=276
 scroll=ScrollContainer.new();scroll.position=Vector2(96,270);scroll.size=Vector2(1088,326)
 scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;scroll.vertical_scroll_mode=ScrollContainer.SCROLL_MODE_SHOW_NEVER
 scroll.follow_focus=true;add_child(scroll)
 body=Control.new();body.custom_minimum_size=Vector2(1060,326);scroll.add_child(body);content_y=0
 UI.label("Kaydırarak devam edin",Rect2(98,605,610,64),roundi(18*text_scale),self,Color("b6dfcf"))
 var up=UI.button("↑",Rect2(902,598,128,90),self,func():scroll.scroll_vertical=maxi(0,scroll.scroll_vertical-220))
 up.add_theme_font_size_override("font_size",roundi(18*text_scale))
 var down=UI.button("↓",Rect2(1048,598,128,90),self,func():scroll.scroll_vertical+=220)
 down.add_theme_font_size_override("font_size",roundi(18*text_scale))
func _height(text:String,size:int,width=1020.0)->float:
 var font=UI.font();var lines=0
 for paragraph in text.split("\n"):
  var line="";lines+=1
  for word in paragraph.split(" "):
   var candidate=word if line.is_empty() else line+" "+word
   if not line.is_empty() and font.get_string_size(candidate,HORIZONTAL_ALIGNMENT_LEFT,-1,size).x>width:lines+=1;line=word
   else:line=candidate
 return font.get_height(size)*lines+maxi(0,lines-1)*4+8
func _reflow():
 if not is_instance_valid(body) or not is_instance_valid(scroll):return
 if is_instance_valid(chrome_title) and is_instance_valid(chrome_profile):
  var title_height=maxf(UI.font().get_height(chrome_title.get_theme_font_size("font_size")),chrome_title.get_minimum_size().y)
  chrome_title.size.y=title_height
  chrome_profile.position.y=chrome_title.position.y+title_height+8
  chrome_profile.size.y=maxf(UI.font().get_height(chrome_profile.get_theme_font_size("font_size")),chrome_profile.get_minimum_size().y)
  var top=chrome_profile.position.y+chrome_profile.size.y+8
  var bottom=top
  for button in chrome_tabs:
   button.position.y=top;button.size.y=maxf(68,button.get_minimum_size().y);bottom=maxf(bottom,top+button.size.y)
  scroll.position.y=bottom+16;scroll.size.y=maxf(100,(480 if confirmation_mode else 580)-scroll.position.y)
 var y=0.0
 for item in layout_items:
  var node=item.node
  if not is_instance_valid(node):continue
  node.position.y=y
  var height=maxf(_height(item.text,item.size),node.get_minimum_size().y) if item.kind=="text" else maxf(150 if item.kind=="input" else 80,node.get_minimum_size().y)
  node.size.y=height;y+=height+16
 body.custom_minimum_size.y=maxf(scroll.size.y,y)
func _text(text:String,base=23,color=Color("fff5dd")):
 var size=roundi(base*text_scale);var height=_height(text,size)
 var label=UI.label(text,Rect2(8,content_y,1020,height),size,body,color)
 layout_items.append({"node":label,"text":text,"size":size,"kind":"text"})
 content_y+=height+14;body.custom_minimum_size.y=maxf(326,content_y)
 return label
func _button(text:String,callback:Callable,amber=false):
 var button=UI.button(text,Rect2(8,content_y,1008,80),body,callback,amber)
 button.add_theme_font_size_override("font_size",roundi(23*text_scale))
 layout_items.append({"node":button,"kind":"button"})
 content_y+=button.size.y+18;body.custom_minimum_size.y=maxf(326,content_y)
 return button
func show_tab(which:String):
 if not unlocked:return
 tab=which;_shell("Ebeveyn alanı")
 if not status.is_empty():_text(status,22,Color("efc97b"));status=""
 match tab:
  "journey":_journey()
  "observations":_observations()
  "profiles":_profiles()
  "data":_data()
func _journey():
 _text("Ne oynandı?",27,Color("efc97b"))
 if report_data.is_empty():_text("Henüz okunabilir bir yolculuk kaydı yok.");return
 _text("Aşağıdaki durumlar kaydedilmiş oyun ilerlemesidir. Ayrıntılı gözlemler ayrı sekmede gösterilir.",21,Color("b6dfcf"))
 for chapter in model.chapters:
  _text(chapter.title,25,Color("efc97b"))
  _text(chapter.detail,22)
  _text("Etkinliğin tasarım amacı: "+chapter.purpose+". Bu amaç bir beceri ölçüm sonucu değildir.",21)
  _text("Ekran dışında birlikte: "+chapter.support,21,Color("b6dfcf"))
 _text(model.limit+" "+model.no_trend,21,Color("b6dfcf"))
func _observations():
 _text("Oyunda hangi gözlem var?",27,Color("efc97b"))
 _text("Kayıtlar bu sürümden itibaren, başarılı görev kaydı ve açılan yardım ekranı gibi belirli oyun eylemlerinden oluşur. Önceki ilerlemeden geçmiş olay üretilmez.",21,Color("b6dfcf"))
 if not model.observation_ok:
  _text("Gözlem kaydı şu anda okunamadı. Yolculuk kaydı korunuyor.");return
 if model.events.is_empty():_text("Henüz yeterli gözlem yok. Bir bölümün oynanmamış olması o alanda güçlük olduğu anlamına gelmez.")
 else:
  _text("%d kayıtlı olay · Yardım ekranı %d kez açıldı."%[model.events.size(),model.help_count],24)
  if model.truncated:_text("Bu cihazda yalnız son kayıtlar tutuluyor; görünen liste bütün geçmiş değildir.",21,Color("b6dfcf"))
  var end=maxi(0,model.events.size()-history_page*20)
  var begin=maxi(0,end-20)
  _text("Görünen kayıtlar: %d–%d / %d"%[begin+1,end,model.events.size()],21,Color("b6dfcf"))
  for index in range(end-1,begin-1,-1):
   var event:Dictionary=model.events[index]
   var when=str(event.get("timestamp_utc",event.get("timestamp",""))).replace("T"," ").trim_suffix("Z")
   _text(str(event.get("chapter_id",""))+" · "+when,23,Color("efc97b"))
   var action="Yardım ekranı açıldı" if event.get("action","")=="help_opened" else "Görev adımı başarıyla kaydedildi"
   _text(action+". Etkinlik: "+Report.activity_label(event),21)
   _text("Bağlam: "+("Tekrar oynama" if event.get("replay_context",{}).get("is_replay",false) else "Yolculuk")+" · Sonuç: "+("kaydedildi" if event.get("result","")=="saved" else "gösterildi")+" · Yardım: "+("bu olayda açıldı" if event.get("action","")=="help_opened" else "bu olaydan belirlenemez"),20,Color("b6dfcf"))
   _text(Report.event_context(event,model.events)+" · İçerik sürümü: "+str(event.get("content_version","")),19,Color("b6dfcf"))
  if end<model.events.size():_button("Daha yeni kayıtlar",func():history_page=maxi(0,history_page-1);show_tab("observations"))
  if begin>0:_button("Daha eski kayıtlar",func():history_page+=1;show_tab("observations"))
 _text(model.limit+" "+model.no_trend,21,Color("b6dfcf"))
 _text("Tasarım alanları proje içi aday eşlemelerdir; ortak katalog kimlikleri onaylanmış veya çocukta ölçülmüş beceriler olarak sunulmaz.",20,Color("b6dfcf"))
func _profiles():
 _text("Yolculukları birbirinden ayırın",27,Color("efc97b"))
 _text("Her yolcunun ilerlemesi ve gözlem kaydı ayrıdır. Ad, yaş veya iletişim bilgisi istenmez. Profili bir yetişkin seçsin; aynı çocuğun farklı cihazlardaki kayıtları kendiliğinden birleşmez.",21)
 if not is_instance_valid(profiles) or active.is_empty():_text("Bu yolculuk için profil yönetimi kullanılamıyor.");return
 for profile in profiles.list_profiles():
  var id=str(profile.get("id",profile.get("profile_id","")))
  var selected=id==str(active.get("id",active.get("profile_id","")))
  _button(str(profile.label)+(" · Etkin" if selected else " · Bu yolcuyu seç"),_activate.bind(id),selected).disabled=selected
  _button(str(profile.label)+" verilerini sil",_confirm_delete.bind(id))
 _button("Yeni yolcu oluştur",_create_profile,true).disabled=profiles.list_profiles().size()>=6
 _button("Yarım kalan veri temizliğini yeniden dene",_retry_cleanup)
func _create_profile():
 var result=profiles.create_profile()
 if not result.get("ok",false):status="Yeni yolcu oluşturulamadı. Mevcut kayıtlar korunuyor.";show_tab("profiles");return
 var profile:Dictionary=result.get("profile",{})
 if not profile.is_empty():_activate(str(profile.get("id",profile.get("profile_id",""))))
 else:_refresh_model();show_tab("profiles")
func _activate(id:String):
 var result=profiles.activate_profile(id)
 if not result.get("ok",false):status="Yolcu değiştirilemedi. Mevcut yolculuk korunuyor.";show_tab("profiles");return
 var profile=profiles.active_profile();journey_path=str(profile.get("journey_path",""))
 profile_changed=true;_refresh_model();status="Etkin yolcu değişti. Oynamaya ana menüden devam edebilirsiniz.";show_tab("journey")
func _confirm_delete(id:String):
 _confirmation("Bu yolcunun verileri silinsin mi?","Seçilen yolcunun bu cihazdaki yolculuğu ve gözlem kayıtları silinir. Bu işlem geri alınamaz. Önce bir aktarım dosyası alabilirsiniz.",_delete_profile.bind(id),"Verileri sil")
func _delete_profile(id:String):
 var result=profiles.delete_profile(id)
 if not result.get("ok",false):status="Veriler silinemedi. Mevcut kayıtlar korunuyor.";show_tab("profiles");return
 var profile=profiles.active_profile();journey_path=str(profile.get("journey_path",""));profile_changed=true
 _refresh_model();status="Profil kaldırıldı; bazı yerel dosyalar temizlenemedi. Yeniden deneyin." if result.get("cleanup_pending",false) else "Seçilen yolcunun bu cihazdaki verileri silindi.";show_tab("profiles")
func _retry_cleanup():
 var result=profiles.retry_cleanup()
 status="Yerel veri temizliği tamamlandı." if result.get("ok",false) and result.get("pending_count",0)==0 else "Bazı dosyalar temizlenemedi. Daha sonra yeniden deneyin."
 show_tab("profiles")
func _data():
 _text("Veriler sizin denetiminizde",27,Color("efc97b"))
 _text("Yolculuk ve gözlemler bu cihazda tutulur. Bu özellik sunucuya veri göndermez. Tarayıcı verilerinin silinmesi yerel kayıtları kaldırabilir; saklamak için aktarım dosyası alın.",21)
 _text("Aktarım yalnız seçtiğiniz yolcuyu içerir. Dosyayı başka cihazda içe almak yeni bir yerel yolcu oluşturur; mevcut yolculukların üzerine yazmaz. Dosyayı paylaşacağınız kişiyi siz seçin.",21,Color("b6dfcf"))
 _button("Bu yolcunun aktarım dosyasını al",_export,true).disabled=active.is_empty()
 _button("Aktarım dosyasından yolcu ekle",_pick_import)
 _button("Aktarım metnini yapıştır",_paste_import)
 _text("Gözlemler bir değerlendirme veya tanı değildir. Ekran süresi, hız ve bölüm sayısı gelişim puanına dönüştürülmez.",21,Color("b6dfcf"))
func _export():
 if active.is_empty():return
 var result=profiles.export_bundle(str(active.get("id",active.get("profile_id",""))))
 if not result.get("ok",false):status="Aktarım hazırlanamadı. Mevcut kayıtlar korunuyor.";show_tab("data");return
 var serialized=JSON.stringify(result.bundle,"  ")
 if OS.has_feature("web"):
  JavaScriptBridge.download_buffer(serialized.to_utf8_buffer(),"catpat-yolculuk.json","application/json")
  status="Aktarım dosyası tarayıcıya verildi. İndirmeler bölümünü kontrol edin.";show_tab("data")
 else:
  var dialog=FileDialog.new();dialog.use_native_dialog=true;dialog.access=FileDialog.ACCESS_FILESYSTEM;dialog.file_mode=FileDialog.FILE_MODE_SAVE_FILE
  dialog.filters=PackedStringArray(["*.json ; Çatpat aktarımı"]);dialog.current_file="catpat-yolculuk.json"
  dialog.file_selected.connect(func(path):
   status="Aktarım dosyası kaydedildi." if save_export(path,serialized) else "Dosya kaydedilemedi. Yolculuk kaydı korunuyor."
   dialog.queue_free();show_tab("data"))
  dialog.canceled.connect(func():dialog.queue_free())
  add_child(dialog);dialog.popup_centered_ratio(0.8)
func save_export(path:String,text:String)->bool:
 var pending=path+".pending"
 var file=FileAccess.open(pending,FileAccess.WRITE)
 if not file:return false
 file.store_string(text);file.flush();var error=file.get_error();file.close()
 if error!=OK or FileAccess.get_file_as_bytes(pending)!=text.to_utf8_buffer():return false
 return DirAccess.rename_absolute(pending,path)==OK
func _pick_import():
 if OS.has_feature("web"):
  web_callback=JavaScriptBridge.create_callback(_web_file_loaded)
  JavaScriptBridge.get_interface("window").__catpatParentImport=web_callback
  JavaScriptBridge.eval("""(()=>{const old=document.getElementById('catpat-parent-file');if(old)old.remove();const input=document.createElement('input');input.id='catpat-parent-file';input.type='file';input.accept='.json,application/json';input.style.display='none';input.onchange=async()=>{const file=input.files[0];if(!file){input.remove();return;}let text='';if(file.size<=2097152)text=await file.text();if(typeof window.__catpatParentImport==='function')window.__catpatParentImport(text);input.remove();};input.oncancel=()=>input.remove();document.body.append(input);input.click();})()""",true)
 else:
  var dialog=FileDialog.new();dialog.use_native_dialog=true;dialog.access=FileDialog.ACCESS_FILESYSTEM;dialog.file_mode=FileDialog.FILE_MODE_OPEN_FILE
  dialog.filters=PackedStringArray(["*.json ; Çatpat aktarımı"])
  dialog.file_selected.connect(func(path):
   var file=FileAccess.open(path,FileAccess.READ)
   var text=file.get_as_text() if file and file.get_length()<=MAX_TRANSFER_BYTES else ""
   dialog.queue_free();_prepare_import(text))
  dialog.canceled.connect(func():dialog.queue_free())
  add_child(dialog);dialog.popup_centered_ratio(0.8)
func _web_file_loaded(arguments:Array):
 _prepare_import(str(arguments[0]) if not arguments.is_empty() else "")
func _paste_import():
 _shell("Aktarım metninden yeni yolcu")
 _text("Yalnız Çatpat aktarım metnini yapıştırın. Mevcut yolculukların üzerine yazılmaz.",21)
 transfer_text=TextEdit.new();transfer_text.position=Vector2(8,content_y);transfer_text.size=Vector2(1008,150)
 transfer_text.add_theme_font_override("font",UI.font());transfer_text.add_theme_font_size_override("font_size",20)
 transfer_text.add_theme_stylebox_override("normal",UI.skin(false));transfer_text.add_theme_stylebox_override("focus",UI.skin(false));transfer_text.wrap_mode=TextEdit.LINE_WRAPPING_BOUNDARY
 transfer_text.placeholder_text="Aktarım metnini buraya yapıştırın";body.add_child(transfer_text)
 layout_items.append({"node":transfer_text,"kind":"input"});content_y+=166
 _button("Dosyayı incele",func():_prepare_import(transfer_text.text),true)
func _prepare_import(text:String):
 var parser=JSON.new()
 var parsed=null
 if text.to_utf8_buffer().size()<=MAX_TRANSFER_BYTES and parser.parse(text)==OK:parsed=parser.data
 if not parsed is Dictionary or not is_instance_valid(profiles) or not profiles.valid_bundle(parsed):status="Aktarım okunamadı. Geçerli bir Çatpat aktarımı seçin.";show_tab("data");return
 import_pending=parsed
 var detail="Dosya: %s · %d kayıtlı gözlem · Aktarım tarihi: %s.\n"%[str(parsed.journey.chapter_id),parsed.journal.records.size(),str(parsed.exported_at).get_slice("T",0)]
 _confirmation("Yeni bir yolcu olarak eklensin mi?",detail+"Yolculuk ve gözlemler ayrı bir yolcuya alınır. Mevcut yolculukların üzerine yazılmaz. Eşleştirmeyi bir yetişkin yapsın.",_commit_import,"Yeni yolcuya aktar")
func _commit_import():
 var result=profiles.import_bundle(import_pending,false);import_pending={}
 if not result.get("ok",false):status="Aktarım doğrulanamadı veya kaydedilemedi. Mevcut yolculuklar korunuyor.";show_tab("data");return
 status="Aktarım ayrı bir yolcuya eklendi. Oynamadan önce Profiller sekmesinden seçin.";show_tab("profiles")
func _confirmation(title:String,message:String,callback:Callable,action:String):
 _shell(title)
 confirmation_mode=true
 _text(message,25)
 UI.button("Vazgeç",Rect2(152,500,440,86),self,show_tab.bind(tab))
 UI.button(action,Rect2(626,500,502,86),self,callback,true)
func close():
 gate_down=false;closed.emit(profile_changed)
func _exit_tree():
 if OS.has_feature("web"):
  JavaScriptBridge.eval("(()=>{const input=document.getElementById('catpat-parent-file');if(input)input.remove();delete window.__catpatParentImport;})()",true)
 web_callback=null
