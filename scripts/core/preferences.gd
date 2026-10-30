extends RefCounted
## Preferences are a small projection of the current canonical journey, never a second save.
const Store=preload("res://scripts/core/save_service.gd")
const DEFAULTS={"music":0.6,"sfx":0.8,"text_speed":1.0,"full_text":false,"text_scale":1.0,"reduced_motion":false,"control_scale":1.0,"left_handed":false}
var store=Store.new()
func number(value, fallback:float, minimum:float, maximum:float)->float:
 if typeof(value) not in [TYPE_INT,TYPE_FLOAT] or not is_finite(float(value)):return fallback
 return clampf(float(value),minimum,maximum)
func volume(value, fallback:float)->float:
 if value is bool:return 1.0 if value else 0.0
 return number(value,fallback,0.0,1.0)
func normalize(raw={}) -> Dictionary:
 var source:Dictionary=raw if raw is Dictionary else {}
 # Preserve existing settings owned by other systems; this service adds no identity data.
 var settings=source.duplicate(true)
 settings.music=volume(source.get("music",DEFAULTS.music),DEFAULTS.music)
 settings.sfx=volume(source.get("sfx",source.get("effects",DEFAULTS.sfx)),DEFAULTS.sfx)
 settings.text_speed=number(source.get("text_speed"),DEFAULTS.text_speed,0.5,2.0)
 settings.text_scale=number(source.get("text_scale"),DEFAULTS.text_scale,1.0,1.3)
 settings.control_scale=number(source.get("control_scale"),DEFAULTS.control_scale,1.0,1.3)
 for key in ["full_text","reduced_motion","left_handed"]:
  settings[key]=source[key] if source.get(key) is bool else DEFAULTS[key]
 return settings
func read(path:String)->Dictionary:
 if path.is_empty():return {"ok":false,"reason":"missing_path","settings":normalize()}
 var loaded=store.load_progress(path)
 if not loaded.ok:return {"ok":false,"reason":loaded.get("reason","no_valid_save"),"settings":normalize()}
 return {"ok":true,"settings":normalize(loaded.data.settings),"new":loaded.get("new",false),"recovered":loaded.get("recovered",false)}
func save(path:String,changes:Dictionary)->Dictionary:
 if path.is_empty():return {"ok":false,"reason":"missing_path","settings":normalize()}
 # Read immediately before merge: a modal must not restore its older quest snapshot.
 var latest=store.load_progress(path)
 if not latest.ok:return {"ok":false,"reason":latest.get("reason","no_valid_save"),"settings":normalize()}
 var data:Dictionary=latest.data.duplicate(true)
 if latest.get("new",false) and store.has_method("fresh_journey"):data=store.fresh_journey()
 var merged:Dictionary=data.settings.duplicate(true)
 for key in DEFAULTS:
  if changes.has(key):merged[key]=changes[key]
 data.settings=normalize(merged)
 if not store.save(path,data):return {"ok":false,"reason":store.last_error,"settings":normalize(latest.data.settings)}
 return {"ok":true,"settings":data.settings.duplicate(true)}
func apply(raw:Dictionary)->Dictionary:
 var settings=normalize(raw)
 var tree=Engine.get_main_loop()
 if tree is SceneTree:
  tree.root.set_meta("catpat_preferences",settings.duplicate(true))
  var audio=tree.root.get_node_or_null("CatpatAudio")
  if audio and audio.has_method("apply_settings"):audio.apply_settings(settings)
 return settings
