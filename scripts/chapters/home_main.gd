extends Node2D
## B00: real movement practice on the existing image-art and physics systems.
const Save=preload("res://scripts/core/save_service.gd")
const Quest=preload("res://scripts/core/quest_state.gd")
const Actor=preload("res://scripts/polish_actor.gd")
const UI=preload("res://scripts/polish_ui.gd")
const Router=preload("res://scripts/core/input_router.gd")
const Display=preload("res://scripts/core/control_display.gd")
const WIDTH=2260.0
const EXIT_POINT=Vector2(2100,620)
const RIBBON_POINT=Vector2(1740,500)
var saves=Save.new()
var state=Quest.new()
var save_path="user://festival_v3.json"
var data:Dictionary={}
var player
var camera:Camera2D
var router=Router.new()
var control_display=Display.new()
var keys={}
var last_jump=false
var paused=false
var blocked=false
var walked=0.0
var last_position=Vector2.ZERO
var airborne=false
var takeoff=Vector2.ZERO
var apex_y=0.0
var error_message=""
var hud:Label
var hud_panel:TextureRect
var hint:Label
var action_button:Button
var modal:Control
var ribbon:Sprite2D
var transition_change:Callable
func _ready():
 save_path=str(get_tree().get_meta("journey_save_path",save_path))
 var loaded=saves.load_progress(save_path)
 if not loaded.ok or loaded.data.chapter_id!="B00":
  blocked=true
  var layer=CanvasLayer.new();add_child(layer)
  UI.texture("res://assets/chapter-v5/menu.webp",Rect2(0,0,1280,720),layer)
  UI.texture("res://assets/polish-v3/panel.webp",Rect2(280,180,720,360),layer)
  UI.label("Davet yolu kaydı açılamadı",Rect2(355,245,580,70),32,layer)
  UI.label("İlerlemen değiştirilmedi. Ana menüden yeniden deneyebilirsin.",Rect2(355,330,570,80),25,layer)
  UI.button("Ana menü",Rect2(440,440,400,70),layer,go_menu,true)
  return
 data=loaded.data.duplicate(true);state.read(data)
 build_world();build_ui()
 last_position=player.position
 if not state.has(Quest.INVITATION):show_invitation()
 update_hud()
func add_surface(x:float,width:float,top:float):
 var body=StaticBody2D.new();body.position=Vector2(x,top);add_child(body)
 var collider=CollisionShape2D.new();var shape=RectangleShape2D.new();shape.size=Vector2(width,45)
 collider.shape=shape;collider.position=Vector2(width/2,22.5);body.add_child(collider)
 var offset=0.0
 while offset<width:
  var length=minf(width-offset,560.0)
  var art=Sprite2D.new();var atlas=AtlasTexture.new();atlas.atlas=load("res://assets/chapter-v5/platform.webp")
  atlas.region=Rect2(100,235,length/0.3,480);art.texture=atlas;art.centered=false;art.scale=Vector2.ONE*0.3
  art.position=Vector2(offset,-3);body.add_child(art);offset+=length
func build_world():
 var background=Parallax2D.new();background.scroll_scale=Vector2(0.14,0);background.repeat_size=Vector2(1280,720);background.repeat_times=5
 var image=Sprite2D.new();image.texture=load("res://assets/chapter-v6/panorama.webp");image.centered=false
 image.scale=Vector2.ONE*720.0/image.texture.get_height();background.repeat_size.x=image.texture.get_width()*image.scale.x
 background.add_child(image);add_child(background)
 # Original game-adaptation art; this cottage is not asserted to be a book scene.
 var home_art=Sprite2D.new();home_art.name="HomeExteriorArt";home_art.texture=load("res://assets/runtime/environments/catpat_b00_home_v001.webp")
 home_art.centered=false;home_art.scale=Vector2.ONE*0.42;home_art.position=Vector2(-180,200);add_child(home_art)
 add_surface(0,1040,620);add_surface(1160,1100,620)
 # The little hollow is recoverable by the two low steps; there is no death pit.
 add_surface(1010,70,665);add_surface(1070,110,710);add_surface(1170,90,665)
 add_surface(600,120,580)
 var branch=StaticBody2D.new();add_child(branch)
 var col=CollisionShape2D.new();var shape=RectangleShape2D.new();shape.size=Vector2(280,18);col.shape=shape;col.position=Vector2(1740,509);col.one_way_collision=true;branch.add_child(col)
 var branch_art=Sprite2D.new();branch_art.texture=load("res://assets/chapter-v6/branch.webp");branch_art.scale=Vector2.ONE*0.145;branch_art.position=Vector2(1740,516.24);branch.add_child(branch_art)
 ribbon=Sprite2D.new();var crop=AtlasTexture.new();crop.atlas=load("res://assets/world/props.webp");crop.region=Rect2(1024,540,512,430)
 ribbon.texture=crop;ribbon.scale=Vector2.ONE*0.28;ribbon.position=Vector2(1740,424);ribbon.visible="b00.ribbon" not in data.collectibles;add_child(ribbon)
 var sign=Sprite2D.new();sign.texture=load("res://assets/chapter-v20/festival-arrow.webp");sign.scale=Vector2.ONE*0.08;sign.position=Vector2(2145,530);add_child(sign)
 player=Actor.new();player.controlled=true;player.position=saves.director.anchor(data.checkpoint_id)-Vector2(0,1);player.checkpoint=player.position;add_child(player)
 camera=preload("res://scripts/core/camera_rig.gd").new();camera.configure(WIDTH);player.add_child(camera);camera.make_current()
func build_ui():
 var layer=CanvasLayer.new();add_child(layer)
 hud_panel=UI.texture("res://assets/polish-v3/panel.webp",Rect2(20,18,925,122),layer)
 hud=UI.label("DAVET VE EV ÖNÜ",Rect2(60,38,840,82),27,layer)
 UI.button("Mola",Rect2(1010,25,230,82),layer,pause_game)
 UI.texture("res://assets/polish-v3/panel.webp",Rect2(275,150,730,78),layer)
 hint=UI.label("",Rect2(300,164,680,48),26,layer);hint.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
 var left=UI.button("‹",Rect2(24,570,112,112),layer,func():pass,true)
 var right=UI.button("›",Rect2(152,570,112,112),layer,func():pass,true)
 var jump=UI.button("Zıpla",Rect2(1130,570,126,112),layer,func():pass,true)
 action_button=UI.button("",Rect2(970,470,270,84),layer,interact,true)
 for b in [left,right,jump]:
  b.mouse_filter=Control.MOUSE_FILTER_IGNORE
  for visual in ["normal","hover","pressed","focus"]:
   var skin=StyleBoxTexture.new();skin.texture=load("res://assets/polish-v3/jump-button.webp");skin.region_rect=Rect2(130,130,1000,1000)
   b.add_theme_stylebox_override(visual,skin)
 control_display.bind([left,right,jump])
 router.bind_controls(left.get_rect(),right.get_rect(),jump.get_rect(),Rect2())
 modal=Control.new();modal.visible=false;layer.add_child(modal)
func reset_input():
 keys.clear();router.reset();last_jump=false
 if is_instance_valid(player):player.input_axis=0;player.jump_request=false;player.jump_held=false;player.jump_buffer=0;player.velocity=Vector2.ZERO
func clear_modal():
 for child in modal.get_children():modal.remove_child(child);child.queue_free()
 modal.show()
func modal_card(title:String,body:String):
 clear_modal()
 UI.texture("res://assets/polish-v3/panel.webp",Rect2(250,145,780,455),modal)
 UI.label(title,Rect2(330,215,630,65),34,modal)
 UI.label(body,Rect2(330,297,620,160),26,modal)
func show_invitation(message:String=""):
 paused=true;player.frozen=true;camera.process_mode=Node.PROCESS_MODE_DISABLED;reset_input()
 modal_card("Festival bugün!" if message.is_empty() else "Davetini kaydedemedik","Davetimi de yanıma alayım.\nIşıklar ağaçların ötesinde görünüyor.\nPatikadan gidersem oraya ulaşabilirim." if message.is_empty() else message+"\nDavetini yeniden alabilirsin.")
 UI.button("Davetimi al" if message.is_empty() else "Yeniden dene",Rect2(430,485,420,76),modal,accept_invitation,true).grab_focus()
func accept_invitation():
 if blocked or state.has(Quest.INVITATION):return
 if commit_events([Quest.INVITATION],"b00.entry"):
  paused=false;player.frozen=false;camera.process_mode=Node.PROCESS_MODE_INHERIT;modal.hide();reset_input();last_position=player.position
 else:show_invitation(error_message)
func commit_events(events:Array,checkpoint:String) -> bool:
 var next=state.copy()
 for event in events:
  if not next.apply(event):return false
 var proposed=data.duplicate(true);proposed.quest_flags=next.flags.duplicate();proposed.checkpoint_id=checkpoint
 if not saves.save(save_path,proposed):
  error_message="Kayıt yapılamadı. Son ilerlemen korunuyor; aynı adımı tekrar dene.";update_hud();return false
 data=proposed;state=next;error_message="";update_hud();return true
func _physics_process(_delta):
 if blocked or paused:return
 var floor_now=player.is_on_floor()
 var previous=last_position
 player.input_axis=clampf(float(keys.get(KEY_RIGHT,false) or keys.get(KEY_D,false))-float(keys.get(KEY_LEFT,false) or keys.get(KEY_A,false))+router.axis,-1,1)
 camera.desired_axis=player.input_axis
 var jumping=keys.get(KEY_SPACE,false) or keys.get(KEY_UP,false) or keys.get(KEY_W,false) or router.jump_held
 player.jump_request=jumping and not last_jump;player.jump_held=jumping;last_jump=jumping
 player.position.x=clampf(player.position.x,25,WIDTH-25)
 if state.has(Quest.INVITATION) and not state.has(Quest.WALK):
  if floor_now:walked+=minf(absf(player.position.x-previous.x),12.0)
  if walked>=100.0:commit_events([Quest.WALK],"b00.walk")
 if not floor_now:
  if not airborne:airborne=true;takeoff=previous;apex_y=player.position.y
  apex_y=minf(apex_y,player.position.y)
 elif airborne:
  airborne=false
  var rise=takeoff.y-apex_y
  if state.has(Quest.WALK) and not state.has(Quest.SHORT_JUMP) and takeoff.x>=480 and takeoff.x<=720 and player.position.x>=600 and player.position.x<=950 and player.position.y<=625 and rise>=35:
   commit_events([Quest.SHORT_JUMP],"b00.short")
  elif state.has(Quest.SHORT_JUMP) and not state.has(Quest.LONG_JUMP) and takeoff.x>=880 and takeoff.x<=1050 and player.position.x>=1160 and player.position.x<=1420 and player.position.y<=625 and player.position.x-takeoff.x>=120 and rise>=100:
   commit_events([Quest.LONG_JUMP,Quest.TUTORIAL_JUMP],"b00.long")
 last_position=player.position
 if player.position.y>800:
  player.position=saves.director.anchor(data.checkpoint_id);player.checkpoint=player.position;reset_input();camera.reset_smoothing();last_position=player.position;airborne=false
 update_hud()
func update_hud():
 if not is_instance_valid(hud):return
 var objective="Davetini al" if not state.has(Quest.INVITATION) else "Yola çıkmak için biraz yürü" if not state.has(Quest.WALK) else "Küçük kökün üstüne zıpla" if not state.has(Quest.SHORT_JUMP) else "Açıklığı zıplayarak geç" if not state.has(Quest.LONG_JUMP) else "Patika girişine ilerle"
 hud.text="DAVET VE EV ÖNÜ · "+objective+("\n"+error_message if not error_message.is_empty() else "")
 hud_panel.size.y=216 if not error_message.is_empty() else 122
 hud.size.y=176 if not error_message.is_empty() else 82
 hint.text="Oklarla yürü" if control_display.touch_mode else "A / D veya ← / → ile yürü"
 if state.has(Quest.WALK) and not state.has(Quest.SHORT_JUMP):hint.text="Zıpla'ya kısaca dokun" if control_display.touch_mode else "Boşluğa kısaca basarak kökü aş"
 elif state.has(Quest.SHORT_JUMP) and not state.has(Quest.LONG_JUMP):hint.text="Açıklıkta Zıpla'yı biraz basılı tut" if control_display.touch_mode else "Açıklıkta Boşluğu biraz basılı tut"
 elif state.has(Quest.TUTORIAL_JUMP):hint.text="Üst daldaki süs isteğe bağlı · Patika sağda"
 var action=available_action();action_button.text=action;action_button.visible=not paused and not action.is_empty()
func available_action() -> String:
 if blocked or paused or not player.is_on_floor():return ""
 if "b00.ribbon" not in data.collectibles and player.position.distance_to(RIBBON_POINT)<85:return "Festival süsünü al"
 if state.has(Quest.TUTORIAL_JUMP) and player.position.distance_to(EXIT_POINT)<100:return "Patikaya ilerle"
 return ""
func interact():
 var action=available_action()
 if action=="Festival süsünü al":
  var proposed=data.duplicate(true);proposed.collectibles.append("b00.ribbon")
  if saves.save(save_path,proposed):data=proposed;state.read(data);ribbon.hide();error_message="";update_hud()
  else:error_message="Süs kaydedilemedi; yeniden dokunabilirsin.";update_hud()
 elif action=="Patikaya ilerle":enter_patika()
func enter_patika():
 if blocked or paused:return
 if not state.has(Quest.TUTORIAL_JUMP) or not player.is_on_floor() or player.position.distance_to(EXIT_POINT)>=100:return
 if not state.has(Quest.HOME_EXIT) and not commit_events([Quest.HOME_EXIT],"b00.exit"):return
 var prepared=saves.director.prepare_transition("B01","b01.island.0")
 if not prepared.ok:return
 var before=data.duplicate(true);var target=data.duplicate(true)
 target.chapter_id="B01";target.geometry=saves.director.GEOMETRY;target.checkpoint_id="b01.island.0"
 if not saves.save(save_path,target):
  saves.director.finish_transition(false,"B01");error_message="Patika girişi kaydedilemedi. Yeniden deneyebilirsin.";update_hud();return
 blocked=true;player.frozen=true;camera.process_mode=Node.PROCESS_MODE_DISABLED;reset_input()
 get_tree().set_meta("journey_save_path",save_path)
 get_tree().set_meta("journey_autostart",true)
 var err=transition_change.call() if transition_change.is_valid() else get_tree().change_scene_to_packed(prepared.scene)
 saves.director.finish_transition(err==OK,"B01")
 if err!=OK:
  get_tree().remove_meta("journey_autostart")
  if not saves.save(save_path,before):
   data=target;state.read(data);paused=true
   modal_card("Patika açılamadı","Güvenli kaydın patika girişinde duruyor.\nAna menüden devam edebilirsin.")
   UI.button("Ana menü",Rect2(430,485,420,72),modal,go_menu,true)
  else:
   data=before;state.read(data);blocked=false;player.frozen=false;camera.process_mode=Node.PROCESS_MODE_INHERIT;last_position=player.position
   error_message="Patika açılamadı; davet yolu kaydın korundu. Yeniden deneyebilirsin."
  update_hud()
func pause_game():
 if blocked or paused:return
 paused=true;player.frozen=true;camera.process_mode=Node.PROCESS_MODE_DISABLED;reset_input()
 modal_card("Küçük bir mola","Davetin ve tamamladığın denemeler kaydedildi.\nHazır olduğunda kaldığın yerden devam et.")
 UI.button("Devam et",Rect2(420,440,440,64),modal,resume,true)
 UI.button("Kontrolleri biliyorum",Rect2(420,510,440,54),modal,confirm_skip)
 UI.button("Ana menü",Rect2(1030,135,210,65),modal,go_menu)
 update_hud()
func confirm_skip():
 modal_card("Öğreticiyi geçelim mi?","Yürüme ve zıplama açıklamaları ana menüde kalır.\nİstersen patika macerasına doğrudan geçebilirsin.")
 UI.button("Öğrenmeye devam",Rect2(340,485,285,72),modal,pause_menu_back).grab_focus()
 UI.button("Patikaya geç",Rect2(655,485,285,72),modal,skip_tutorial,true)
func pause_menu_back():
 paused=false;pause_game()
func skip_tutorial():
 var proposed=data.duplicate(true)
 for event in Quest.HOME_EVENTS:
  if event not in proposed.quest_flags:proposed.quest_flags.append(event)
 proposed.chapter_id="B01";proposed.geometry=saves.director.GEOMETRY;proposed.checkpoint_id="b01.island.0";proposed.settings.onboarding_origin="user-skipped-v1"
 if not saves.save(save_path,proposed):
  modal_card("Kayıt yapılamadı","Son kaydın korunuyor. İstersen yeniden dene veya öğreticiye devam et.")
  UI.button("Yeniden dene",Rect2(350,485,275,72),modal,skip_tutorial,true)
  UI.button("Geri dön",Rect2(655,485,275,72),modal,pause_menu_back)
  return
 # The requested skip is now durably B01. Never let a failed navigation resume
 # this old B00 world and overwrite that newer target snapshot.
 data=proposed;state.read(data);blocked=true;paused=true;player.frozen=true;reset_input()
 get_tree().set_meta("journey_save_path",save_path)
 get_tree().set_meta("journey_autostart",true)
 var err=transition_change.call() if transition_change.is_valid() else get_tree().change_scene_to_file("res://scenes/polish_v3.tscn")
 if err!=OK:
  get_tree().remove_meta("journey_autostart")
  modal_card("Patika açılamadı","Kaydın korunuyor. Ana menüden devam edebilirsin.");UI.button("Ana menü",Rect2(430,485,420,72),modal,go_menu,true)
func resume():
 if not state.has(Quest.INVITATION):show_invitation();return
 modal.hide();paused=false;player.frozen=false;camera.process_mode=Node.PROCESS_MODE_INHERIT;reset_input();last_position=player.position;update_hud()
func go_menu():
 get_tree().set_meta("journey_save_path",save_path)
 get_tree().change_scene_to_file("res://scenes/polish_v3.tscn")
func _input(event):
 if blocked:return
 if control_display.observe(event):reset_input();update_hud()
 if event is InputEventKey:
  if event.echo:return
  if event.pressed and event.keycode==KEY_ESCAPE:
   if paused and state.has(Quest.INVITATION):resume()
   elif not paused:pause_game()
   return
  if paused:return
  keys[event.keycode]=event.pressed
  if event.pressed and event.keycode==KEY_E:interact()
 elif not paused:router.consume(event)
func _notification(what):
 if what==NOTIFICATION_APPLICATION_FOCUS_OUT and not blocked and is_instance_valid(player):
  reset_input()
  if not paused:pause_game()
