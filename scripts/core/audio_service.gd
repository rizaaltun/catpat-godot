extends Node
## Original procedural score/sound layer. No identity, analytics, microphone or network.
## Browser-safe: ready/scene changes never start audio before a real user gesture.
const BASE="res://assets/runtime/audio/"
const EFFECT_NAMES=["ui_press","ui_back","ui_open","ui_toggle","step_grass","step_wood","jump","land","interact","light_on","rope_tie","item_pickup","item_place","bridge_build","water_return","checkpoint","task_complete","companion_join","finale","pause","resume","page_turn","error_soft","flower"]
const MUSIC_BUS="CatpatMusic"
const AMBIENCE_BUS="CatpatAmbience"
const EFFECT_BUS="CatpatEffects"
var auto_observe=true
var unlocked=false
var music_level=0.6
var sfx_level=0.8
var explicit_paused=false
var explicit_dialogue=false
var backgrounded=false
var observed_paused=false
var observed_dialogue=false
var current_chapter="B01"
var music_key="path"
var ambience_key="lantern"
var music_players:Array[AudioStreamPlayer]=[]
var ambience_player:AudioStreamPlayer
var voices:Array[AudioStreamPlayer]=[]
var music_slot=0
var music_tween:Tween
var cached_streams={}
var last_event={}
var observer_clock=0.0
var tracked_scene_id=0
var tracked_properties={}
var last_flags:Array=[]
var last_checkpoint=""
var last_rescues=0
var tracked_actor_id=0
var last_actor_x=0.0
var last_grounded=false
var last_vertical=0.0
var step_distance=0.0
var expected_music_path=""
var expected_ambience_path=""

func _ready():
	process_mode=Node.PROCESS_MODE_ALWAYS
	for bus_name in [MUSIC_BUS,AMBIENCE_BUS,EFFECT_BUS]:
		if AudioServer.get_bus_index(bus_name)<0:
			AudioServer.add_bus();AudioServer.set_bus_name(AudioServer.bus_count-1,bus_name)
	for i in 2:
		var player=AudioStreamPlayer.new();player.bus=MUSIC_BUS;player.name="Music%d"%i;add_child(player);music_players.append(player)
	ambience_player=AudioStreamPlayer.new();ambience_player.bus=AMBIENCE_BUS;ambience_player.name="Ambience";add_child(ambience_player)
	for i in 8:
		var player=AudioStreamPlayer.new();player.bus=EFFECT_BUS;player.name="Effect%d"%i;add_child(player);voices.append(player)
	get_tree().node_added.connect(_on_node_added)
	for node in get_tree().root.find_children("*","Button",true,false):_register_button(node)
	var initial=get_tree().root.get_meta("catpat_preferences",{})
	apply_settings(initial if initial is Dictionary else {})
	select_chapter(current_chapter)

func _has(object:Object,key:String)->bool:
	if not is_instance_valid(object):return false
	for property in object.get_property_list():
		if property.name==key:return true
	return false

func _level(value,fallback:float)->float:
	if value is bool:return 1.0 if value else 0.0
	if typeof(value) in [TYPE_INT,TYPE_FLOAT] and is_finite(float(value)):return clampf(float(value),0.0,1.0)
	return fallback

func apply_settings(settings:Dictionary):
	music_level=_level(settings.get("music",0.6),0.6)
	sfx_level=_level(settings.get("sfx",settings.get("effects",0.8)),0.8)
	for name in [MUSIC_BUS,AMBIENCE_BUS,EFFECT_BUS]:
		var index=AudioServer.get_bus_index(name)
		if index>=0:AudioServer.set_bus_mute(index,(music_level if name==MUSIC_BUS else sfx_level)<=0.0)
	_update_levels(1.0)

func _input(input_event):
	var gesture=false
	if input_event is InputEventScreenTouch:gesture=input_event.pressed and not input_event.canceled
	elif input_event is InputEventMouseButton:gesture=input_event.pressed and input_event.device!=InputEvent.DEVICE_ID_EMULATION
	elif input_event is InputEventKey:gesture=input_event.pressed and not input_event.echo
	if gesture:unlock_from_gesture()

func unlock_from_gesture():
	if unlocked:return
	unlocked=true
	_start_selected_tracks()

func select_chapter(chapter:String,completed=false):
	if chapter not in ["B00","B01","B02","B03","B04","B05"]:chapter="B01"
	current_chapter=chapter
	ambience_key={"B00":"home","B01":"lantern","B02":"river","B03":"garden","B04":"summit","B05":"festival"}[chapter]
	music_key="path" if chapter in ["B00","B01"] else "friends" if chapter in ["B02","B03"] else "festival"
	if chapter=="B05" and completed:music_key="finale"
	expected_music_path=BASE+"music_"+music_key+".ogg"
	expected_ambience_path=BASE+"ambience_"+ambience_key+".ogg"
	if unlocked:_start_selected_tracks()

func _stream(path:String,looped:bool):
	if cached_streams.has(path):return cached_streams[path]
	var stream=load(path)
	if stream==null:return null
	if looped and stream is AudioStreamOggVorbis:stream.loop=true
	cached_streams[path]=stream
	return stream

func _start_selected_tracks():
	if music_players.is_empty() or not is_instance_valid(ambience_player):return
	var active=music_players[music_slot]
	if active.stream==null or active.stream.resource_path!=expected_music_path:
		var next_slot=1-music_slot
		var next=music_players[next_slot]
		if is_instance_valid(music_tween):music_tween.kill()
		next.stop();next.stream=_stream(expected_music_path,true);next.volume_db=-60.0
		if next.stream:
			next.play()
			music_tween=create_tween().set_parallel(true)
			music_tween.tween_property(next,"volume_db",0.0,0.6)
			music_tween.tween_property(active,"volume_db",-60.0,0.6)
			music_tween.chain().tween_callback(active.stop)
			music_slot=next_slot
	elif not active.playing:active.play()
	if ambience_player.stream==null or ambience_player.stream.resource_path!=expected_ambience_path:
		ambience_player.stop();ambience_player.stream=_stream(expected_ambience_path,true);ambience_player.volume_db=-10.0
		if ambience_player.stream:ambience_player.play()
	_sync_pause()

func event(name:String)->bool:
	if not unlocked or sfx_level<=0.0 or name not in EFFECT_NAMES:return false
	if _is_paused() and name not in ["ui_press","ui_back","ui_open","ui_toggle","pause","resume","page_turn","error_soft"]:return false
	var now=Time.get_ticks_msec()/1000.0
	var interval=0.25 if name.begins_with("step_") else 0.7 if name in ["task_complete","companion_join","finale","checkpoint","light_on","flower","rope_tie","bridge_build","item_pickup","item_place"] else 0.09
	if now-float(last_event.get(name,-100.0))<interval:return false
	var target:AudioStreamPlayer=null
	for voice in voices:
		if not voice.playing:target=voice;break
	if target==null:return false
	var stream=_stream(BASE+"sfx_"+name+".wav",false)
	if stream==null:return false
	last_event[name]=now;target.stream=stream;target.volume_db=-7.0;target.pitch_scale=1.0;target.set_meta("event_name",name);target.stream_paused=false
	if name.begins_with("step_"):target.pitch_scale=0.96+float(Time.get_ticks_msec()%70)/1000.0
	target.play()
	return true

func set_paused(value:bool):
	explicit_paused=value;_sync_pause()
func set_dialogue(value:bool):
	explicit_dialogue=value
func _is_paused()->bool:return explicit_paused or observed_paused or backgrounded
func _sync_pause():
	var value=_is_paused()
	for player in music_players:player.stream_paused=value
	if is_instance_valid(ambience_player):ambience_player.stream_paused=value
	# UI sounds are allowed in a game pause; backgrounding pauses every voice.
	for voice in voices:
		var ui_sound=str(voice.get_meta("event_name","")).begins_with("ui_") or str(voice.get_meta("event_name","")) in ["pause","resume","page_turn","error_soft"]
		voice.stream_paused=backgrounded or (value and not ui_sound)
func _notification(what):
	if what in [NOTIFICATION_APPLICATION_FOCUS_OUT,NOTIFICATION_APPLICATION_PAUSED]:backgrounded=true;_sync_pause()
	elif what in [NOTIFICATION_APPLICATION_FOCUS_IN,NOTIFICATION_APPLICATION_RESUMED]:backgrounded=false;_sync_pause()

func _process(delta):
	_update_levels(minf(delta*7.0,1.0))
	if not auto_observe:return
	observer_clock+=delta
	if observer_clock>=0.12:
		var elapsed=observer_clock;observer_clock=0.0
		_observe_scene(elapsed)

func _update_levels(weight:float):
	var duck=-10.0 if explicit_dialogue or observed_dialogue else 0.0
	for name in [MUSIC_BUS,AMBIENCE_BUS,EFFECT_BUS]:
		var index=AudioServer.get_bus_index(name)
		if index<0:continue
		var level=music_level if name==MUSIC_BUS else sfx_level
		var desired=linear_to_db(maxf(0.0001,level))+(duck if name==MUSIC_BUS else 0.0)
		AudioServer.set_bus_volume_db(index,lerpf(AudioServer.get_bus_volume_db(index),desired,weight))

func _observe_scene(elapsed:float):
	var scene=get_tree().current_scene
	if not is_instance_valid(scene):return
	var changed=tracked_scene_id!=scene.get_instance_id()
	if changed:
		tracked_scene_id=scene.get_instance_id();tracked_properties.clear();tracked_actor_id=0;step_distance=0;last_rescues=0
		explicit_paused=false;explicit_dialogue=false
		for property in scene.get_property_list():tracked_properties[property.name]=true
	var path=scene.get_script().resource_path if scene.get_script() else scene.scene_file_path
	var chapter="B00" if "home_main" in path else "B02" if "river_world" in path else "B03" if "garden_world" in path else "B04" if "summit_main" in path else "B05" if "festival_main" in path else "B01"
	var flags:Array=[]
	var settings:Dictionary={}
	var checkpoint=""
	for key in ["save_data","data"]:
		if tracked_properties.has(key) and scene.get(key) is Dictionary:
			var state:Dictionary=scene.get(key)
			flags=state.get("quest_flags",[]);settings=state.get("settings",{});checkpoint=str(state.get("checkpoint_id",""))
	if tracked_properties.has("quest_state"):
		flags=scene.quest_state.flags
		if tracked_properties.has("settings"):settings=scene.settings
	if chapter=="B04" and tracked_properties.has("save_service"):
		var store=scene.save_service
		if _has(store,"main_data") and store.main_data is Dictionary:
			flags=store.main_data.get("quest_flags",[]);settings=store.main_data.get("settings",{})
	if changed:
		last_flags=flags.duplicate();last_checkpoint=checkpoint
		apply_settings(settings)
		select_chapter(chapter,"chapter.B05.complete" in flags)
	else:
		for flag in flags:
			if flag not in last_flags:_quest_sound(str(flag))
		if checkpoint!="" and checkpoint!=last_checkpoint:event("checkpoint")
		last_flags=flags.duplicate();last_checkpoint=checkpoint
		if chapter=="B05" and "chapter.B05.complete" in flags and music_key!="finale":select_chapter(chapter,true)
	var mode=str(scene.get("mode")) if tracked_properties.has("mode") else ""
	observed_dialogue=mode=="dialogue" or (tracked_properties.has("dialogue_active") and bool(scene.get("dialogue_active")))
	var raw_pause=bool(scene.get("paused")) if tracked_properties.has("paused") else mode=="pause"
	var pause_overlay=scene.get("pause_root") if tracked_properties.has("pause_root") else null
	var explicit_overlay=is_instance_valid(pause_overlay) and pause_overlay is Control and pause_overlay.visible
	var finale=scene.get("final_panel") if tracked_properties.has("final_panel") else null
	var pause_panel=scene.get("pause_panel") if tracked_properties.has("pause_panel") else null
	var finale_presentation=is_instance_valid(finale) and finale is Control and finale.visible and not (is_instance_valid(pause_panel) and pause_panel is Control and pause_panel.visible)
	# Final presentation freezes physics, but the shared celebration score continues.
	observed_paused=raw_pause and not finale_presentation and (not observed_dialogue or explicit_overlay)
	_sync_pause()
	if not _is_paused() and not observed_dialogue:
		var actor=scene.get("actor") if tracked_properties.has("actor") else scene.get("player") if tracked_properties.has("player") else null
		if actor is CharacterBody2D:_observe_actor(actor,elapsed,chapter)
	if tracked_properties.has("rescue_count"):
		var rescues=int(scene.get("rescue_count"))
		if not changed and rescues>last_rescues:event("water_return")
		last_rescues=rescues

func _observe_actor(actor:CharacterBody2D,_elapsed:float,chapter:String):
	if actor.get_instance_id()!=tracked_actor_id:
		tracked_actor_id=actor.get_instance_id();last_actor_x=actor.position.x;last_grounded=actor.is_on_floor();last_vertical=actor.velocity.y;return
	var grounded=actor.is_on_floor()
	if last_grounded and not grounded and actor.velocity.y< -80:event("jump")
	if not last_grounded and grounded and last_vertical>80:event("land")
	if grounded and absf(actor.velocity.x)>40:
		step_distance+=minf(absf(actor.position.x-last_actor_x),60.0)
		if step_distance>=85:
			step_distance=0;event("step_wood" if chapter=="B04" else "step_grass")
	last_actor_x=actor.position.x;last_grounded=grounded;last_vertical=actor.velocity.y

func _quest_sound(flag:String):
	if flag=="chapter.B05.complete":event("finale")
	elif ".joined" in flag:event("companion_join")
	elif flag.begins_with("light.") or flag=="b05.light.ready":event("light_on")
	elif flag=="b05.flowers.ready" or flag=="b03.garden.protected":event("flower")
	elif flag=="b05.flags.ready":event("rope_tie")
	elif ".carried" in flag:event("item_pickup")
	elif flag=="b02.bridge.ready":event("bridge_build")
	elif flag.ends_with(".complete"):event("task_complete")
	elif flag.ends_with(".supplied"):event("item_place")
	elif flag=="invitation.read":event("page_turn")

func _on_node_added(node):
	if node is Button:call_deferred("_register_button",node)
func _register_button(button):
	if not is_instance_valid(button) or button.has_meta("catpat_audio_bound"):return
	button.set_meta("catpat_audio_bound",true)
	button.pressed.connect(_on_button_pressed.bind(weakref(button)))
func _on_button_pressed(reference:WeakRef):
	var button=reference.get_ref()
	if not is_instance_valid(button):return
	var label=button.text.to_lower()
	var sound="ui_back" if "geri" in label or "ana menü" in label else "pause" if "duraklat" in label else "resume" if "devam" in label else "ui_open" if "ayar" in label or "yardım" in label else "ui_press"
	event(sound)

func shutdown():
	# Release live playback objects before the audio server itself exits.
	if is_instance_valid(music_tween):music_tween.kill()
	for player in music_players:
		if is_instance_valid(player):player.stop();player.stream=null
	if is_instance_valid(ambience_player):ambience_player.stop();ambience_player.stream=null
	for voice in voices:
		if is_instance_valid(voice):voice.stop();voice.stream=null
	cached_streams.clear();last_event.clear()
func _exit_tree():shutdown()
