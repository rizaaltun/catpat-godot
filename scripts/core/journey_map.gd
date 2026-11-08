extends RefCounted
## Read-only map projection. Continue never writes a checkpoint; replay owns its slot.
const Save=preload("res://scripts/core/save_service.gd")
const Replay=preload("res://scripts/core/replay_service.gd")
const TITLES={"B00":"Ev Önü","B01":"Fenerli Patika","B02":"Dostluk Deresi","B03":"Papatya Bahçesi","B04":"Rüzgârlı Yamaç","B05":"Festival Alanı"}
const PREVIEWS={"B00":"Evden çıkan küçük bir davet, büyük bir yolculuğa dönüşür.","B01":"Porsuk’la karanlık patikanın fenerlerini aydınlat.","B02":"Maymun’la dereyi aşacak köprüyü birlikte hazırla.","B03":"Pıtpıt’ın çiçeklerini rüzgârdan korumaya yardım et.","B04":"Arkadaşlarınla feneri, halatı ve yön işaretini hazırla.","B05":"Işıklar, flamalar ve çiçeklerle festivali birlikte kur."}
const POINTS=[Vector2(0.13,0.82),Vector2(0.34,0.70),Vector2(0.36,0.38),Vector2(0.65,0.57),Vector2(0.71,0.28),Vector2(0.90,0.15)]
var replay=Replay.new()
func snapshot(path:String)->Dictionary:
 var source=replay.read_source(path)
 var rows=[]
 var completed=replay.completed_from(source.data) if source.ok else []
 for chapter in Replay.CHAPTERS:
  var current=source.ok and source.data.chapter_id==chapter
  rows.append({"id":chapter,"title":TITLES[chapter],"preview":PREVIEWS[chapter],"current":current,"completed":chapter in completed,"state":"current" if current else "completed" if chapter in completed else "locked"})
 return {"ok":source.ok,"rows":rows,"primary_path":source.get("primary_path",path),"current":source.data.chapter_id if source.ok else "","recovered":source.get("recovered",false)}
func continue_primary(path:String,navigation:Callable=Callable())->Dictionary:
 # A fresh read prevents a stale map from restoring an old chapter or profile snapshot.
 var source=replay.read_source(path)
 if not source.ok:return source
 var chapter:String=source.data.chapter_id
 var scene_path:String=Replay.ENTRIES[chapter][2]
 if not load(scene_path) is PackedScene:return {"ok":false,"reason":"missing_scene"}
 var before=replay.metadata_snapshot()
 for key in ["replay_primary_path","replay_chapter","replay_autostart","journey_autostart"]:
  if replay.tree().has_meta(key):replay.tree().remove_meta(key)
 replay.tree().set_meta("journey_save_path",source.primary_path)
 if chapter=="B01":replay.tree().set_meta("journey_autostart",true)
 var error=replay.navigate_to(scene_path,navigation)
 if error!=OK:
  replay.restore_metadata(before)
  return {"ok":false,"reason":"continue_navigation_failed","error":error}
 return {"ok":true,"chapter":chapter,"path":source.primary_path,"checkpoint":source.data.checkpoint_id}
