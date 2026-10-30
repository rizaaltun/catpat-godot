extends SceneTree
const Service=preload("res://scripts/core/audio_service.gd")
class PresentationFixture extends Node:
 var paused=true
 var dialogue_active=false
 var save_data={"quest_flags":[],"settings":{},"checkpoint_id":""}
 var final_panel=Control.new()
 var pause_panel=Control.new()
 var pause_root:Control
 func _ready():
  add_child(final_panel);add_child(pause_panel);pause_root=pause_panel;pause_panel.hide()
var checks=0
var failures=0
func _initialize():call_deferred("run")
func check(ok:bool,label:String):
 checks+=1
 if not ok:failures+=1
 print("PASS " if ok else "FAIL ",label)
func run():
 var service=root.get_node_or_null("CatpatAudio")
 if not is_instance_valid(service):
  service=Service.new();service.name="TestAudio";service.auto_observe=false;root.add_child(service)
 service.auto_observe=false
 await process_frame
 check(not service.unlocked and service.music_players.all(func(p):return not p.playing) and not service.ambience_player.playing,"startup and scene selection do not autoplay")
 var manifest=JSON.parse_string(FileAccess.get_file_as_string("res://assets/runtime/audio/manifest.json"))
 check(manifest.assets.size()==34,"complete audio scope has six ambience loops, four score variants and24 effects")
 var family_counts={"ambience":0,"music":0,"sfx":0}
 for asset in manifest.assets:
  family_counts[asset.id.get_slice(".",0)]+=1
  var stream=service._stream("res://"+asset.path,asset.loop)
  check(stream is AudioStream and stream.get_length()>0.05,"runtime audio imports "+asset.id)
  if asset.loop:check(stream is AudioStreamOggVorbis and stream.loop,"continuous loop enabled "+asset.id)
 check(family_counts=={"ambience":6,"music":4,"sfx":24},"audio families meet the planned production coverage")
 service.select_chapter("B02")
 check(service.ambience_key=="river" and service.music_key=="friends" and not service.ambience_player.playing,"chapter routing remains silent before gesture")
 var synthetic=InputEventMouseButton.new();synthetic.pressed=true;synthetic.device=InputEvent.DEVICE_ID_EMULATION
 service._input(synthetic)
 check(not service.unlocked,"emulated pointer cannot autonomously unlock audio")
 service.apply_settings({"music":false,"effects":false})
 check(service.music_level==0 and service.sfx_level==0 and AudioServer.is_bus_mute(AudioServer.get_bus_index(service.MUSIC_BUS)),"legacy boolean and effects preference disables sound")
 var gesture=InputEventKey.new();gesture.keycode=KEY_SPACE;gesture.pressed=true
 service._input(gesture)
 await process_frame
 check(service.unlocked and service.music_players.any(func(p):return p.playing) and service.ambience_player.playing,"a genuine input gesture unlocks selected score and ambience")
 check(not service.event("jump"),"muted effects do not consume a voice")
 service.apply_settings({"music":0.35,"sfx":0.45})
 check(is_equal_approx(service.music_level,0.35) and is_equal_approx(service.sfx_level,0.45),"normalized persisted preference volumes are honored")
 check(service.event("jump") and not service.event("jump"),"rapid repeated interaction is rate limited")
 check(not service.event("not_an_audio_event"),"unknown events fail quietly")
 service.set_paused(true)
 check(service.music_players.filter(func(p):return p.playing).all(func(p):return p.stream_paused) and service.ambience_player.stream_paused,"pause freezes score and ambience instead of restarting tracks")
 check(service.voices.filter(func(p):return p.playing).all(func(p):return p.stream_paused),"gameplay effects also pause")
 check(not service.event("item_pickup") and service.event("ui_open"),"paused gameplay sounds are blocked while menu feedback remains available")
 service._notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
 check(service.voices.filter(func(p):return p.playing).all(func(p):return p.stream_paused),"backgrounding pauses every effect voice including menu feedback")
 service._notification(Node.NOTIFICATION_APPLICATION_FOCUS_IN)
 check(service.music_players.filter(func(p):return p.playing).all(func(p):return p.stream_paused),"focus return does not undo an explicit game pause")
 service.set_paused(false)
 check(service.music_players.all(func(p):return not p.stream_paused) and not service.ambience_player.stream_paused,"resume continues frozen tracks")
 service.set_dialogue(true);service._update_levels(1.0)
 var ducked=AudioServer.get_bus_volume_db(AudioServer.get_bus_index(service.MUSIC_BUS))
 service.set_dialogue(false);service._update_levels(1.0)
 var normal=AudioServer.get_bus_volume_db(AudioServer.get_bus_index(service.MUSIC_BUS))
 check(is_equal_approx(normal-ducked,10.0),"dialogue ducks music by10dB without changing the preference")
 service.select_chapter("B05",true)
 check(service.music_key=="finale" and service.ambience_key=="festival","completed festival selects the final score variation")
 service.select_chapter("B00")
 check(service.ambience_key=="home" and service.music_key=="path","new invitation scene has a distinct ambience")
 var fixture=PresentationFixture.new();root.add_child(fixture);current_scene=fixture
 service._observe_scene(0.12)
 check(not service.observed_paused,"finale physics freeze keeps presentation music running")
 fixture.final_panel.hide();fixture.pause_panel.show();service._observe_scene(0.12)
 check(service.observed_paused,"real pause overlay still pauses final presentation")
 fixture.pause_panel.hide();fixture.dialogue_active=true;service._observe_scene(0.12)
 check(service.observed_dialogue and not service.observed_paused,"B04 dialogue physics freeze ducks rather than pauses music")
 current_scene=null;fixture.queue_free();await process_frame
 service.shutdown()
 check(service.music_players.all(func(p):return p.stream==null) and service.voices.all(func(p):return p.stream==null) and service.ambience_player.stream==null,"shutdown releases every stream and active playback")
 await create_timer(0.2).timeout
 print("AUDIO SERVICE: %d checks, %d failures"%[checks,failures])
 quit(1 if failures else 0)
