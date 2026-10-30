extends SceneTree
const Save=preload("res://scripts/core/save_service.gd")
const Quest=preload("res://scripts/core/quest_state.gd")
const Profile=preload("res://scripts/core/movement_profile.gd")
const PATH="user://festival-movement-test.json"
var game
var checks=0
var failures=0
func check(ok:bool,label:String):
 checks+=1
 if not ok:failures+=1
 print("PASS " if ok else "FAIL ",label)
func ticks(count:int):
 for frame in count:await physics_frame
func key(pressed:bool):
 var event=InputEventKey.new();event.keycode=KEY_SPACE;event.pressed=pressed
 game._input(event)
func touch(pressed:bool):
 var event=InputEventScreenTouch.new();event.index=71;event.position=game.input_router.regions.jump.get_center();event.pressed=pressed
 game._input(event)
func place_ground():
 game.set_game_paused(false)
 game.actor.position=Vector2(400,570)
 await ticks(20)
func measure_jump(use_touch:bool,hold_frames:int)->float:
 await place_ground()
 var start=game.actor.position.y
 if use_touch:touch(true)
 else:key(true)
 var highest=start
 var launches=0
 var previous_y=game.actor.velocity.y
 for frame in 110:
  if frame==hold_frames:
   if use_touch:touch(false)
   else:key(false)
  await physics_frame
  highest=minf(highest,game.actor.position.y)
  if previous_y>=0 and game.actor.velocity.y<0:launches+=1
  previous_y=game.actor.velocity.y
 if use_touch:touch(false)
 else:key(false)
 check(launches==1,("touch" if use_touch else "keyboard")+" held jump produces one launch before a fresh edge")
 return start-highest
func _initialize():call_deferred("run")
func run():
 var quest=Quest.new()
 for id in Quest.EVENTS:
  if id in Quest.FESTIVAL_EVENTS:continue
  quest.apply(id)
 var data=Save.new().fresh();data.chapter_id="B05";data.geometry="festival-v1";data.checkpoint_id="b05.entry";data.quest_flags=quest.flags;data.party_ids=quest.party_ids();data.summit={}
 check(Save.new().save(PATH,data),"isolated B05 movement fixture stored")
 set_meta("journey_save_path",PATH)
 game=load("res://scenes/festival.tscn").instantiate();root.add_child(game)
 await ticks(30)
 check(game.actor.get_script().resource_path.ends_with("festival_actor.gd") and game.actor.anim is AnimatedSprite2D,"B05 uses the common animated actor adapter")
 var capsule:CollisionShape2D
 for child in game.actor.get_children():
  if child is CollisionShape2D:capsule=child
 check(capsule.position==Vector2.ZERO and capsule.shape.height==64.0,"adapter preserves centered64 capsule and save-anchor coordinates")
 var short_key=await measure_jump(false,2)
 var long_key=await measure_jump(false,100)
 var short_touch=await measure_jump(true,2)
 var long_touch=await measure_jump(true,100)
 check(long_key>short_key+40.0,"holding jump increases height: short %.1f / long %.1f"%[short_key,long_key])
 check(absf(short_key-short_touch)<2.0 and absf(long_key-long_touch)<2.0,"keyboard/touch have equal short and long jump heights")
 check(long_key>140 and long_key<180,"full jump uses the shared measured reach profile")
 await place_ground()
 key(true);key(false)
 await ticks(3)
 check(game.actor.velocity.y<0,"keyboard tap released before the next physics tick still queues a jump edge")
 await place_ground()
 touch(true);touch(false)
 await ticks(3)
 check(game.actor.velocity.y<0,"touch tap released before the next physics tick still queues a jump edge")
 await place_ground()
 game.right_pressed=true
 await ticks(20)
 check(absf(game.actor.velocity.x-Profile.RUN_SPEED)<1.0 and game.actor.anim.animation=="run","shared run speed and animation are active")
 var facing_right=game.actor.anim.flip_h
 game.right_pressed=false;game.left_pressed=true
 await ticks(30)
 check(game.actor.velocity.x<0 and game.actor.anim.flip_h!=facing_right,"left/right movement changes the animated facing")
 game.set_game_paused(true)
 var paused_position=game.actor.position
 await ticks(20)
 check(game.actor.frozen and game.actor.position==paused_position and game.actor.jump_buffer==0,"pause freezes animated actor and clears buffered input")
 game.set_game_paused(false)
 await ticks(4)
 check(not game.actor.frozen and game.actor.input_axis==0 and not game.actor.jump_held,"resume clears held controls")
 # Land with a recently pressed jump still in the common input buffer.
 game.control_display.touch_mode=false;game.control_display.refresh()
 await place_ground()
 game.actor.position=Vector2(400,544);game.actor.velocity=Vector2(0,600)
 await ticks(2)
 game.actor.coyote=0.0
 key(true)
 var buffered=false
 for frame in 15:
  await physics_frame
  if game.actor.velocity.y< -400:buffered=true;break
 key(false)
 check(buffered,"jump pressed just before landing is buffered into the next takeoff")
 # Leave the final raised platform physically, then press within the coyote window.
 await place_ground()
 game.actor.position=Vector2(3960,442);game.actor.velocity=Vector2.ZERO
 await ticks(12)
 game.left_pressed=true
 var left_edge=false
 for frame in 40:
  await physics_frame
  if not game.actor.is_on_floor():left_edge=true;break
 await ticks(2)
 key(true)
 await ticks(3)
 check(left_edge and game.actor.velocity.y< -400,"jump shortly after leaving the platform uses coyote time")
 key(false)
 game._notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
 check(game.paused and game.actor.frozen and game.input_router.owners.is_empty() and game.actor.input_axis==0,"focus loss pauses and releases real actor input")
 game.queue_free();await process_frame
 for suffix in ["", ".bak", ".pending", ".bak.pending", ".legacy"]:DirAccess.remove_absolute(PATH+suffix)
 set_meta("journey_save_path","user://festival_v3.json")
 print("FESTIVAL MOVEMENT: %d checks, %d failures"%[checks,failures])
 quit(1 if failures else 0)
