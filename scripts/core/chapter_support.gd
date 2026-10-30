extends RefCounted
## Contextual help and transactional current-chapter restart; never resolves to a replay's primary slot.
const Save=preload("res://scripts/core/save_service.gd")
const Quest=preload("res://scripts/core/quest_state.gd")
const Replay=preload("res://scripts/core/replay_service.gd")
const SCRIPT_CHAPTERS={"home_main.gd":"B00","polish_world.gd":"B01","river_world.gd":"B02","garden_world.gd":"B03","summit_main.gd":"B04","festival_main.gd":"B05"}
var store=Save.new()
var observations_override:Node
func tree()->SceneTree:return Engine.get_main_loop() as SceneTree
func property(object,key:String,fallback=null):
 if not is_instance_valid(object):return fallback
 for row in object.get_property_list():
  if row.name==key:return object.get(key)
 return fallback
func chapter_for(scene)->String:
 if not is_instance_valid(scene) or scene.get_script()==null:return ""
 return str(SCRIPT_CHAPTERS.get(scene.get_script().resource_path.get_file(),""))
func context(scene)->Dictionary:
 var chapter=chapter_for(scene)
 var path=str(property(scene,"save_path",""))
 if chapter.is_empty() or path.is_empty():return {"ok":false,"reason":"unknown_scene"}
 var loaded=store.load_progress(path)
 if not loaded.ok or loaded.get("new",false):return {"ok":false,"reason":"no_current_journey"}
 if loaded.data.chapter_id!=chapter:return {"ok":false,"reason":"scene_save_mismatch"}
 return {"ok":true,"chapter":chapter,"path":path,"data":loaded.data,"title":Replay.TITLES[chapter]}
func _event_chapter(event:String)->String:
 if event in Quest.HOME_EVENTS:return "B00"
 if event in Quest.RIVER_EVENTS:return "B02"
 if event in Quest.GARDEN_EVENTS:return "B03"
 if event==Quest.SUMMIT_COMPLETE:return "B04"
 if event in Quest.FESTIVAL_EVENTS:return "B05"
 return "B01"
func prepare_restart(scene)->Dictionary:
 var source=context(scene)
 if not source.ok:return source
 var chapter:String=source.chapter
 var index=Replay.CHAPTERS.find(chapter)
 var data:Dictionary=source.data.duplicate(true)
 var state=Quest.new()
 for event in data.quest_flags:
  if Replay.CHAPTERS.find(_event_chapter(event))<index:state.apply(event)
 data.quest_flags=state.flags.duplicate();data.party_ids=state.party_ids()
 data.collectibles=data.collectibles.filter(func(id):return (0 if id=="b00.ribbon" else 1)<index)
 data.geometry=Replay.ENTRIES[chapter][0];data.checkpoint_id=Replay.ENTRIES[chapter][1]
 data.summit=Save.Summit.fresh() if chapter=="B04" else {}
 data.ending_seen=false
 if not store.valid(data):return {"ok":false,"reason":"invalid_restart_snapshot"}
 return {"ok":true,"chapter":chapter,"path":source.path,"data":data,"scene_path":Replay.ENTRIES[chapter][2]}
func _observer():
 return observations_override if is_instance_valid(observations_override) else tree().root.get_node_or_null("CatpatObservations")
func _suspend(observer,path:String):
 if is_instance_valid(observer) and observer.has_method("suspend_path"):observer.suspend_path(path)
func _resume(observer,path:String):
 if is_instance_valid(observer) and observer.has_method("resume_path"):observer.resume_path(path)
func restart(scene,navigation:Callable=Callable())->Dictionary:
 # Re-read at confirmation time, not when the confirmation panel was opened.
 var prepared=prepare_restart(scene)
 if not prepared.ok:return prepared
 if not load(prepared.scene_path) is PackedScene:return {"ok":false,"reason":"missing_scene"}
 var replay=Replay.new()
 var previous_files=replay.slot_snapshot(prepared.path)
 var previous_metadata=replay.metadata_snapshot()
 var observer=_observer()
 _suspend(observer,prepared.path)
 if not store.save(prepared.path,prepared.data):
  var restored=replay.restore_slot(prepared.path,previous_files)
  _resume(observer,prepared.path)
  return {"ok":false,"reason":"restart_save_failed","rollback_ok":restored}
 tree().set_meta("journey_save_path",prepared.path)
 if prepared.chapter=="B01":
  tree().set_meta("journey_autostart",true)
  if tree().has_meta("replay_primary_path"):tree().set_meta("replay_autostart",true)
 else:
  if tree().has_meta("journey_autostart"):tree().remove_meta("journey_autostart")
  if tree().has_meta("replay_autostart"):tree().set_meta("replay_autostart",false)
 var result=navigation.call(prepared.scene_path) if navigation.is_valid() else tree().change_scene_to_file(prepared.scene_path)
 var error=int(result) if typeof(result)==TYPE_INT else ERR_INVALID_DATA
 if error!=OK:
  var restored=replay.restore_slot(prepared.path,previous_files)
  replay.restore_metadata(previous_metadata)
  _resume(observer,prepared.path)
  return {"ok":false,"reason":"restart_navigation_failed","error":error,"rollback_ok":restored}
 _resume(observer,prepared.path)
 var attempt={"ok":true,"recorded":0,"reason":"observations_unavailable"}
 if is_instance_valid(observer) and observer.has_method("begin_attempt"):attempt=observer.begin_attempt(prepared.path,prepared.chapter)
 return {"ok":true,"chapter":prepared.chapter,"path":prepared.path,"attempt":attempt}
func help_context(scene)->Dictionary:
 var source=context(scene)
 if not source.ok:return source
 var flags:Array=source.data.quest_flags
 var task="chapter_overview"
 var text="Yavaşça ilerleyebilirsin. Yürümek için okları, atlamak için Zıpla düğmesini kullan. Bir arkadaşına yaklaşınca görev düğmesi açılır."
 match source.chapter:
  "B00":
   if Quest.INVITATION not in flags:task="tutorial.invitation";text="Önce davetini yanına al. Davetimi al düğmesiyle başlayabilirsin."
   elif Quest.WALK not in flags:task="tutorial.walk";text="Sağ oka basılı tutarak evden uzaklaş. Güvenli yolda kendi hızında yürümeyi deneyebilirsin."
   elif Quest.SHORT_JUMP not in flags:task="tutorial.short_jump";text="Zıpla düğmesine kısaca dokun. Alçak kökün üzerinden küçük bir sıçrayışla geçebilirsin."
   elif Quest.LONG_JUMP not in flags:task="tutorial.long_jump";text="Daha yüksek atlamak için Zıpla düğmesini biraz basılı tut. Düşersen alttaki basamaklardan geri çıkabilirsin."
   else:task="tutorial.exit";text="Sağa, festival yolunu gösteren tabelaya ilerle. İstersen üst daldaki kurdeleyi de keşfedebilirsin."
  "B01":
   if Quest.ACCEPTED not in flags:task="lanterns.meet";text="Porsuk başlangıçta seni bekliyor. Yanına yaklaş ve onunla konuşmak için görev düğmesini kullan."
   elif not Quest.LIGHTS.all(func(id):return id in flags):
    task="lanterns.find"
    text="Üç fener farklı yüksekliklerde. İlkine alçak basamaklarla, ikincisine üst dalla, sonuncusuna hareketli daldan ulaşabilirsin."
   elif Quest.JOINED not in flags:task="lanterns.return";text="Fenerler yolu aydınlattı. Açılan alt geçitlerden soldaki Porsuk'a dön ve onu yolculuğa çağır."
   else:task="lanterns.exit";text="Porsuk'la sağdaki çıkışa ilerle. Çıkış fenerine birlikte yaklaşınca yolunuz dereye açılır."
  "B02":
   if Quest.RIVER_ACCEPTED not in flags:task="bridge.meet";text="Maymun dere kıyısında seni bekliyor. Yanına yaklaş ve köprü hazırlığını konuş."
   elif Quest.PLANK not in flags:task="bridge.plank";text="Tahta alt kıyıda. Güvenli basamaklardan aşağı in, tahtanın yanına yaklaş ve görev düğmesini kullan."
   elif Quest.ROPE not in flags:task="bridge.rope";text="Halat üst dallarda. Alçak daldan başlayıp basamaklarla yüksel. Tahtayı ve halatı birlikte taşıyabilirsin."
   elif Quest.READY not in flags:task="bridge.build";text="İki parça hazır. Maymun'un yanına dön ve parçaları teslim et. Köprü kurulurken arkadaşınla kıyıda bekleyebilirsin."
   elif Quest.MONKEY not in flags:task="bridge.join";text="Köprü hazır. Maymun'la yeniden konuş ve onu yolculuğa çağır."
   else:task="bridge.exit";text="Arkadaşlarınla köprüden sağ kıyıya geç. Çıkışta bir araya geldiğinizde bahçe yoluna devam edebilirsin."
  "B03":
   if Quest.GARDEN_ACCEPTED not in flags:task="garden.meet";text="Pıtpıt bahçe girişinde seni bekliyor. Çiçeklere yardım etmek için önce onunla konuş."
   elif Quest.RELEASED not in flags:task="garden.basket_lower";text="Sepet üstteki dala takılmış. Basamaklardan ipin yanına çıkıp görev düğmesini kullan; sepet aşağı iner."
   elif Quest.BASKET not in flags:task="garden.basket";text="İnen sepeti alt patikadan alabilirsin. Görev düğmesi açılana kadar yanına yaklaş."
   elif Quest.TIE not in flags:task="garden.tie";text="Siperin bağ ipi alttaki kayaların yanında. Güvenli basamaklarla ulaş ve ipi al."
   elif Quest.PROTECTED not in flags:task="garden.protect";text="Sepet ve bağ ipi hazır. Pıtpıt'ın yanına dönüp siperi birlikte sabitle."
   elif Quest.RABBIT not in flags:task="garden.join";text="Çiçekler güvende. Pıtpıt'ı yolculuğa çağırmak için onunla yeniden konuş."
   else:task="garden.exit";text="Hep birlikte sağdaki çıkışta buluşun. Arkadaşların yaklaştığında yamaç yoluna devam edebilirsin."
  "B04":
   var summit:Dictionary=source.data.summit
   if summit.lantern!="lit":task="summit.lantern";text="Porsuk'la başlangıç kıyısında konuş. Alt basamaklardaki fenerin kapağını kapat, sonra Porsuk'a dön."
   elif summit.rope!="ready":task="summit.rope";text="Maymun'un halat hazırlığını konuş. Halatı işaretli yere götürüp bağlantıyı birlikte tamamlayın."
   elif summit.waymark!="seen":task="summit.waymark";text="Pıtpıt'ın yön işaretini hazırlamasına yardım et. Sonra arkadaşlarınla sağdaki manzara durağında buluş."
   else:task="summit.exit";text="Üç yardım da tamam. Ekibin sağdaki festival kapısında bir araya gelmesini bekle ve birlikte ilerle."
  "B05":
   if Quest.FESTIVAL_LIGHT not in flags:task="festival.lights";text="Porsuk'un yanına iki alçak basamaktan çık. Aynı platformda durunca görev düğmesine dokunup sahne ışıklarını hazırlayın."
   elif Quest.FESTIVAL_FLAGS not in flags:task="festival.flags";text="Maymun'un flama durağı sağda. Kısa platformlardan yanına çıkıp flamaları birlikte bağlayın."
   elif Quest.FESTIVAL_FLOWERS not in flags:task="festival.flowers";text="Pıtpıt'ın durağına üst basamaklardan ulaş. Süsleri birlikte yerleştirmek için yanında görev düğmesini kullan."
   elif Quest.FESTIVAL_COMPLETE not in flags:task="festival.finale";text="Arkadaşların sahneye varınca en sağdaki üst platforma çık. Son ışığı birlikte açabilirsiniz."
   else:task="festival.roam";text="Festival tamamlandı. Alanda dolaşabilir veya sahneye dönerek finali yeniden izleyebilirsin."
 return {"ok":true,"chapter":source.chapter,"path":source.path,"title":source.title,"task_id":task,"text":text}
func record_help(scene,request_id:String="")->Dictionary:
 var help=help_context(scene)
 if not help.ok:return help
 var observer=_observer()
 if is_instance_valid(observer) and observer.has_method("record_help"):return observer.record_help(scene,help.task_id,"task_hint",request_id)
 return {"ok":true,"recorded":0,"reason":"observations_unavailable"}
