extends Node2D
## B05 playable chapter on the canonical journey save; no separate save or HTML game.
const Store=preload("res://scripts/core/save_service.gd")
const Quest=preload("res://scripts/core/quest_state.gd")
const UI=preload("res://scripts/polish_ui.gd")
const PLATFORM_ART="res://assets/chapter-v5/platform.webp"
const FOREST_ART="res://assets/polish-v3/forest.webp"
const DAISY_ART="res://assets/chapter-v13/daisies.webp"
const SIGN_ART="res://assets/chapter-v20/festival-arrow.webp"
const STAGE_ART="res://assets/runtime/environments/catpat_b05_stage_v001.webp"
const BUNTING_ART="res://assets/runtime/objects/catpat_b05_bunting_v001.webp"
const MARKER_ART="res://assets/runtime/objects/catpat_b05_station_banner_v001.webp"
const GLOW_ART="res://assets/runtime/effects/catpat_b05_lantern_glow_v001.png"
const TASKS=[
 {"id":Quest.FESTIVAL_LIGHT,"x":1150.0,"platform_y":446.0,"name":"Porsuk ile sahne ışıkları","character":"Porsuk","idle":"res://assets/review-v2/badger-idle-r2.webp","action":"res://assets/polish-v3/badger-pass.webp","walk":["res://assets/review-v2/badger-idle.webp","res://assets/review-v2/badger-idle-r2.webp"],"line":"Işıklar hazır; sahne artık parlıyor."},
 {"id":Quest.FESTIVAL_FLAGS,"x":2250.0,"platform_y":465.0,"name":"Maymun ile flamalar","character":"Maymun","idle":"res://assets/chapter-v10/monkey-idle.webp","action":"res://assets/chapter-v10/monkey-step-a.webp","walk":["res://assets/chapter-v10/monkey-step-a.webp","res://assets/chapter-v10/monkey-step-b.webp"],"line":"Flamalar sağlam; rüzgârda dans ediyor."},
 {"id":Quest.FESTIVAL_FLOWERS,"x":3310.0,"platform_y":454.0,"name":"Pıtpıt ile çiçekler","character":"Pıtpıt","idle":"res://assets/chapter-v12/rabbit-idle.webp","action":"res://assets/chapter-v12/rabbit-step-a.webp","walk":["res://assets/chapter-v12/rabbit-step-a.webp","res://assets/chapter-v12/rabbit-step-b.webp"],"line":"Çiçekler yerini buldu; festival rengârenk."}
]
const WORLD_WIDTH=4400.0
const FINAL_ANCHOR_X=4230.0
const STAGE_ANCHORS=[Vector2(3960.0,416.0),Vector2(4050.0,416.0),Vector2(4140.0,416.0)]
var save_path="user://festival_v3.json"
var save_data:Dictionary={}
var actor:CharacterBody2D
var camera:Camera2D
var hud:Label
var controls_hint:Label
var action_button:Button
var control_display=preload("res://scripts/core/control_display.gd").new()
var input_router=preload("res://scripts/core/input_router.gd").new()
var paused=false
var blocked=false
var left_pressed=false
var right_pressed=false
# Compatibility pulse for deterministic route fixtures; real inputs retain held state.
var jump_pressed=false
var pointer_jump_held=false
var last_jump_held=false
var jump_edge_pending=false
var keyboard_buttons={}
var action_pressed=false
var near_task=-1
var status=""
var pause_panel:Control
var pause_card:TextureRect
var final_panel:Control
var help_panel:Control
var help_text:Label
var status_seconds=0.0
var partner_sprites:Array=[]
var partner_tweens:Array[Tween]=[]
var contribution_tweens:Array[Tween]=[]
var flower_sprites:Array=[]
var station_markers:Array[Sprite2D]=[]
var festival_lanterns:Array[Sprite2D]=[]
var lantern_glows:Array[Sprite2D]=[]
var festival_bunting:Array[Sprite2D]=[]
var stage_glow:Sprite2D
var final_replay=false
var all_on_stage=false
var gathering_partners=false
var arrived_partners=0
var companion_walk_clock=0.0
var companion_walk_frame=0
func _ready():
 process_physics_priority=-20
 save_path=str(get_tree().get_meta("journey_save_path",save_path))
 var loaded=Store.new().load_progress(save_path)
 if not loaded.ok or loaded.data.chapter_id!="B05" or not Quest.SUMMIT_COMPLETE in loaded.data.quest_flags or loaded.data.party_ids!=["badger","monkey","rabbit"]:
  blocked=true
  make_block_screen()
  return
 save_data=loaded.data.duplicate(true)
 build_world()
 build_ui()
 restore_party_stage()
 update_hud()
func make_block_screen():
 var canvas=CanvasLayer.new();add_child(canvas)
 UI.texture("res://assets/chapter-v5/menu.webp",Rect2(0,0,1280,720),canvas)
 UI.texture("res://assets/polish-v3/panel.webp",Rect2(240,160,800,390),canvas)
 UI.label("Festival kaydı açılamadı",Rect2(325,240,670,65),36,canvas)
 UI.label("İlerlemen değiştirilmedi. Ana menüden yeniden deneyebilirsin.",Rect2(325,325,650,100),25,canvas)
 UI.button("Ana menü",Rect2(450,455,380,75),canvas,go_menu,true)
func make_ground(x:float,width:float,top:float):
 var body=StaticBody2D.new();body.position=Vector2(x+width/2.0,top+36);add_child(body)
 var collision=CollisionShape2D.new();var shape=RectangleShape2D.new();shape.size=Vector2(width,72);collision.shape=shape;body.add_child(collision)
 # The finale deck is dressed by its separate stage image; collision is unchanged.
 if x==3910.0:return
 var offset=0.0
 while offset<width:
  var span=minf(450.0,width-offset)
  var art=Sprite2D.new();var crop=AtlasTexture.new();crop.atlas=load(PLATFORM_ART)
  crop.region=Rect2(64,235,span/0.35,450);art.texture=crop;art.centered=false
  art.name="MossyPlatformArt";art.scale=Vector2.ONE*0.35
  art.position=Vector2(-width/2.0+offset,-42.0);body.add_child(art)
  offset+=span
func add_forest_backdrop():
 var parallax=Parallax2D.new();parallax.name="FestivalForestBackdrop";parallax.z_index=-30
 var backdrop=Sprite2D.new();backdrop.texture=load(FOREST_ART);backdrop.centered=false
 var scale_factor=720.0/maxf(1.0,backdrop.texture.get_height());backdrop.scale=Vector2.ONE*scale_factor
 parallax.repeat_size=Vector2(backdrop.texture.get_width()*scale_factor,720.0);parallax.repeat_times=8
 parallax.scroll_scale=Vector2(0.12,0.0);parallax.add_child(backdrop);add_child(parallax)
func add_festival_camp_art():
 var art=Sprite2D.new();art.texture=load(STAGE_ART);art.name="FestivalCampArt";art.centered=false
 art.scale=Vector2.ONE*(390.0/1449.0);art.position=Vector2(3910.0-49.0*art.scale.x,474.0-775.0*art.scale.y);art.z_index=1;add_child(art)
 stage_glow=Sprite2D.new();stage_glow.texture=load(GLOW_ART);stage_glow.scale=Vector2(0.70,0.38)
 stage_glow.position=Vector2(4020,340);stage_glow.z_index=0;stage_glow.modulate.a=0.28
 stage_glow.name="FestivalFinalLight";add_child(stage_glow)
func add_bunting(x:float,y:float):
 var art=Sprite2D.new();art.texture=load(BUNTING_ART);art.centered=false
 art.scale=Vector2.ONE*0.16;art.position=Vector2(x,y-22);art.z_index=3
 art.name="FestivalBunting";add_child(art);festival_bunting.append(art)
func build_world():
 add_forest_backdrop()
 add_festival_camp_art()
 # Safe ground is broken into short zones; paired low platforms form the route to each task.
 for data in [[0.0,850.0,616.0],[930.0,870.0,616.0],[1880.0,820.0,616.0],[2780.0,820.0,616.0],[3670.0,730.0,616.0]]:
  make_ground(data[0],data[1],data[2])
 for data in [[780.0,190.0,522.0],[1000.0,170.0,446.0],[1790.0,155.0,528.0],[2010.0,155.0,465.0],[2200.0,220.0,465.0],[2840.0,205.0,524.0],[3090.0,175.0,454.0],[3280.0,180.0,454.0],[3650.0,210.0,538.0],[3910.0,390.0,474.0]]:
  make_ground(data[0],data[1],data[2])
 for x in [1020.0,1220.0,3950.0,4040.0,4130.0,4220.0]:
  var lamp=Sprite2D.new();lamp.texture=load("res://assets/polish-v3/lantern.webp");lamp.scale=Vector2.ONE*0.055
  lamp.position=Vector2(x,365 if x<2000 else 290);lamp.z_index=3;lamp.name="FestivalLantern";add_child(lamp);festival_lanterns.append(lamp)
  var glow=Sprite2D.new();glow.texture=load(GLOW_ART);glow.position=lamp.position;glow.scale=Vector2.ONE*0.16
  glow.z_index=2;glow.modulate.a=0.34;glow.name="FestivalLanternGlow";add_child(glow);lantern_glows.append(glow)
 for x in [590.0,1650.0,2700.0,3520.0]:
  add_world_sprite(SIGN_ART,Vector2(x,530),38.0,3)
 for x in [300.0,1390.0,2470.0,3590.0]:add_bunting(x,170.0)
 actor=preload("res://scripts/chapters/festival_actor.gd").new();actor.name="Catpat"
 actor.controlled=true;actor.position=Store.new().director.anchor(save_data.checkpoint_id)
 actor.checkpoint=actor.position;actor.z_index=5;add_child(actor)
 camera=Camera2D.new();camera.position_smoothing_enabled=true;camera.position_smoothing_speed=6;camera.limit_left=0;camera.limit_right=int(WORLD_WIDTH);camera.limit_top=0;camera.limit_bottom=720;actor.add_child(camera);camera.make_current()
 for i in TASKS.size():
  var point=TASKS[i]
  var marker=Node2D.new();marker.position=Vector2(point.x,point.platform_y);marker.name="Station%d"%i;add_child(marker)
  add_partner(i)
  var flag=Sprite2D.new();flag.texture=load(MARKER_ART);flag.centered=false
  flag.name="CompletionFlag";flag.scale=Vector2.ONE*0.10;flag.position=Vector2(-34,-147);flag.z_index=2
  marker.add_child(flag);station_markers.append(flag)
  UI.texture("res://assets/polish-v3/panel.webp",Rect2(-93,-200,218,46),marker)
  var text=UI.label(point.character,Rect2(-80,-193,190,34),23,marker)
  text.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
 for x in [3180.0,3285.0,3390.0]:
  var flowers=Sprite2D.new();flowers.texture=load(DAISY_ART);flowers.scale=Vector2.ONE*0.055
  flowers.position=Vector2(x,575);flowers.z_index=3;flowers.visible=Quest.FESTIVAL_FLOWERS in save_data.quest_flags
  flowers.name="FestivalDaisy";add_child(flowers);flower_sprites.append(flowers)
 build_station_state()
func add_world_sprite(path:String,point:Vector2,target_height:float,layer:int):
 var art=Sprite2D.new();art.texture=load(path);art.centered=false
 art.scale=Vector2.ONE*target_height/maxf(1.0,art.texture.get_height());art.position=point;art.z_index=layer;add_child(art)
func add_partner(index:int):
 var art=Sprite2D.new();art.texture=load(TASKS[index].idle)
 art.scale=Vector2.ONE*108.0/maxf(1.0,art.texture.get_height())
 art.position=Vector2(TASKS[index].x,TASKS[index].platform_y-58.0)
 art.z_index=4;art.name="FestivalPartner%d"%index;add_child(art);partner_sprites.append(art)
func restore_partner(index:int):
 if index<partner_sprites.size():
  var art:Sprite2D=partner_sprites[index]
  art.texture=load(TASKS[index].idle);art.scale=Vector2.ONE*108.0/maxf(1.0,art.texture.get_height())
func play_contribution(index:int):
 if index>=partner_sprites.size():return
 var art:Sprite2D=partner_sprites[index];var base_y=art.position.y
 art.texture=load(TASKS[index].action);art.scale=Vector2.ONE*108.0/maxf(1.0,art.texture.get_height())
 var tween=create_tween()
 contribution_tweens.append(tween)
 tween.tween_property(art,"position:y",base_y-26.0,0.20).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
 tween.tween_property(art,"position:y",base_y,0.20).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
 tween.tween_callback(restore_partner.bind(index))
func build_ui():
 var layer=CanvasLayer.new();add_child(layer)
 UI.texture("res://assets/polish-v3/panel.webp",Rect2(18,15,935,133),layer)
 hud=UI.label("",Rect2(62,31,850,112),24,layer)
 UI.texture("res://assets/polish-v3/panel.webp",Rect2(310,624,660,76),layer)
 controls_hint=UI.label("",Rect2(332,641,616,44),23,layer)
 update_controls_hint()
 action_button=UI.button("Etkileşim",Rect2(1025,532,218,80),layer,interact,true)
 var left_control=UI.button("◀",Rect2(40,594,120,92),layer,func():left_pressed=true)
 var right_control=UI.button("▶",Rect2(175,594,120,92),layer,func():right_pressed=true)
 var jump_control=UI.button("Zıpla",Rect2(1030,626,200,74),layer,func():jump_pressed=true,true)
 control_display.bind([left_control,right_control,jump_control,action_button])
 input_router.bind_controls(left_control.get_rect(),right_control.get_rect(),jump_control.get_rect(),action_button.get_rect())
 # Read pointer ownership directly so held and simultaneous touch controls work.
 for control in [left_control,right_control,jump_control,action_button]:
  control.mouse_filter=Control.MOUSE_FILTER_IGNORE
 UI.button("Duraklat",Rect2(1008,24,230,73),layer,toggle_pause)
 pause_panel=Control.new();pause_panel.name="PausePanel";pause_panel.visible=false;layer.add_child(pause_panel)
 var pause_shade=ColorRect.new();pause_shade.color=Color(0.03,0.1,0.08,0.82);pause_shade.size=Vector2(1280,720);pause_panel.add_child(pause_shade)
 pause_card=UI.texture("res://assets/polish-v3/panel.webp",Rect2(300,130,680,520),pause_panel)
 pause_card.name="PauseCard"
 UI.label("Biraz soluklanalım",Rect2(370,175,550,78),36,pause_panel)
 UI.button("Devam et",Rect2(390,295,500,88),pause_panel,toggle_pause,true)
 UI.button("Görev yardımı",Rect2(390,399,500,88),pause_panel,show_help)
 UI.button("Ana menü",Rect2(390,503,500,88),pause_panel,go_menu)
 help_panel=Control.new();help_panel.name="FestivalHelp";help_panel.visible=false;layer.add_child(help_panel)
 UI.texture("res://assets/polish-v3/panel.webp",Rect2(0,0,1280,720),help_panel).modulate=Color(0.12,0.19,0.17,0.94)
 UI.texture("res://assets/polish-v3/panel.webp",Rect2(185,110,910,510),help_panel)
 UI.label("Birlikte deneyelim",Rect2(285,155,730,72),36,help_panel)
 help_text=UI.label("",Rect2(285,245,720,215),27,help_panel)
 UI.button("Molaya dön",Rect2(430,495,420,88),help_panel,close_help,true)
 final_panel=Control.new();final_panel.visible=false;layer.add_child(final_panel)
 var shade=ColorRect.new();shade.color=Color(0.03,0.1,0.08,0.82);shade.size=Vector2(1280,720);final_panel.add_child(shade)
 UI.texture("res://assets/polish-v3/panel.webp",Rect2(185,50,910,620),final_panel)
 UI.label("Hep birlikte geldik!",Rect2(300,82,740,70),36,final_panel)
 var story_lines=["Yolumu göremediğimde yanımdaydın.","Köprüyü birlikte tamamladık.","Hazırladığım süsleri de kurtardık.","Festival şimdi daha güzel.","Çünkü hepimiz buradayız."]
 for i in story_lines.size():
  var story_line=UI.label(story_lines[i],Rect2(275,168+i*46,730,44),23,final_panel)
  story_line.name="FinalStoryLine%d"%i
  story_line.autowrap_mode=TextServer.AUTOWRAP_OFF
 for i in TASKS.size():
  var portrait=Sprite2D.new();portrait.texture=load(TASKS[i].idle)
  portrait.scale=Vector2.ONE*72.0/maxf(1.0,portrait.texture.get_height());portrait.position=Vector2([390.0,640.0,890.0][i],454);portrait.name="FinalPortrait%d"%i;final_panel.add_child(portrait)
  UI.label(TASKS[i].character,Rect2([320.0,570.0,820.0][i],494,140,44),22,final_panel)
 UI.button("Festivalde dolaş",Rect2(270,558,340,78),final_panel,leave_final,true)
 UI.button("Kaydet ve ana menü",Rect2(646,558,370,78),final_panel,go_menu)
 if Quest.FESTIVAL_COMPLETE in save_data.quest_flags:show_final()
func _process(delta):
 if blocked or paused:return
 if status_seconds>0:
  status_seconds=maxf(0,status_seconds-delta)
  if status_seconds==0:status="";update_hud()
 if not gathering_partners:return
 companion_walk_clock+=delta
 if companion_walk_clock<0.18:return
 companion_walk_clock=0.0
 companion_walk_frame=1-companion_walk_frame
 for i in partner_sprites.size():
  var art:Sprite2D=partner_sprites[i]
  art.texture=load(TASKS[i].walk[companion_walk_frame])
func update_controls_hint():
 if not is_instance_valid(controls_hint):return
 controls_hint.text="A/D: yürü · Boşluk: zıpla · Etkileşim: E" if not control_display.touch_mode else "Dokunmatik: oklarla yürü · Zıpla düğmesi · Yardım et"
 if is_instance_valid(action_button):update_hud()
func _physics_process(_delta):
 if blocked:return
 actor.frozen=paused
 if paused:return
 var axis=float(int(keyboard_buttons.get(KEY_RIGHT,false) or keyboard_buttons.get(KEY_D,false) or right_pressed)-int(keyboard_buttons.get(KEY_LEFT,false) or keyboard_buttons.get(KEY_A,false) or left_pressed))
 var held=pointer_jump_held or jump_pressed or keyboard_buttons.get(KEY_SPACE,false) or keyboard_buttons.get(KEY_UP,false) or keyboard_buttons.get(KEY_W,false) or keyboard_buttons.get(KEY_ENTER,false)
 actor.input_axis=axis
 actor.jump_held=held
 actor.jump_request=jump_edge_pending or (held and not last_jump_held)
 jump_edge_pending=false
 last_jump_held=held
 jump_pressed=false
 actor.checkpoint=Store.new().director.anchor(save_data.checkpoint_id)
 actor.position.x=clampf(actor.position.x,35,WORLD_WIDTH-35)
 if actor.position.y>820:
  actor.position=actor.checkpoint;actor.velocity=Vector2.ZERO
  clear_gameplay_inputs();camera.reset_smoothing()
 var nearest=-1
 for i in TASKS.size():
  var task=TASKS[i];var standing_y=task.platform_y-32.0
  if absf(actor.position.x-task.x)<100 and absf(actor.position.y-standing_y)<74 and actor.is_on_floor():nearest=i
 if nearest!=near_task:near_task=nearest;update_hud()
func _input(event):
 if blocked or paused:return
 if control_display.observe(event):
  clear_gameplay_inputs()
  update_controls_hint()
 # A touch emits an emulated mouse event too; route the real finger only.
 if control_display.touch_mode and event is InputEventMouseButton:return
 if event is InputEventKey and not event.echo:
  if event.pressed and event.keycode in [KEY_SPACE,KEY_UP,KEY_W,KEY_ENTER] and not keyboard_buttons.get(event.keycode,false):jump_edge_pending=true
  if event.keycode in [KEY_LEFT,KEY_RIGHT,KEY_A,KEY_D,KEY_SPACE,KEY_UP,KEY_W,KEY_ENTER]:keyboard_buttons[event.keycode]=event.pressed
 if control_display.accepts(event) and input_router.consume(event):
  left_pressed=input_router.axis<0.0
  right_pressed=input_router.axis>0.0
  if input_router.jump_held and not pointer_jump_held:jump_edge_pending=true
  pointer_jump_held=input_router.jump_held
  if input_router.interact_pressed:interact()
func _notification(what):
 if what==NOTIFICATION_APPLICATION_FOCUS_OUT:
  clear_gameplay_inputs()
  if not blocked and not paused:toggle_pause()
func _unhandled_input(event):
 if blocked:return
 if event is InputEventKey and event.pressed and not event.echo:
  if event.keycode==KEY_E:interact()
  elif event.keycode==KEY_ESCAPE:
   if is_instance_valid(help_panel) and help_panel.visible:close_help()
   else:toggle_pause()
func clear_gameplay_inputs():
 input_router.reset()
 left_pressed=false;right_pressed=false;jump_pressed=false;action_pressed=false
 pointer_jump_held=false;last_jump_held=false;jump_edge_pending=false;keyboard_buttons.clear()
 if is_instance_valid(actor):
  actor.input_axis=0;actor.jump_request=false;actor.jump_held=false
  actor.jump_buffer=0.0;actor.coyote=0.0;actor.velocity=Vector2.ZERO
func set_game_paused(value:bool):
 clear_gameplay_inputs()
 paused=value
 if is_instance_valid(actor):actor.frozen=value
 set_partner_tweens_paused(value)
func toggle_pause():
 if blocked:return
 if is_instance_valid(final_panel) and final_panel.visible:return
 set_game_paused(not paused)
 if is_instance_valid(pause_panel):pause_panel.visible=paused
 status="Duraklatıldı. Tekrar basarak devam et." if paused else ""
 update_hud()
func update_hud():
 if not is_instance_valid(hud):return
 var remaining=[]
 for i in TASKS.size():
  if TASKS[i].id not in save_data.quest_flags:remaining.append(i)
 var completed=Quest.FESTIVAL_COMPLETE in save_data.quest_flags
 var next="Sahneye ulaş ve ortak ışığı aç."
 if completed:next="Festival tamamlandı. Sahneye gelerek finali tekrar izleyebilirsin."
 elif not remaining.is_empty():
  var index=near_task if near_task in remaining else remaining[0]
  next=TASKS[index].name+" · Arkadaşının yanındaki platforma ulaş."
  if near_task==index:next="Birlikte hazırlamak için "+("Yardım et'e dokun." if control_display.touch_mode else "E'ye bas.")
 elif not all_on_stage:next="Arkadaşların sahneye geliyor. Son platforma ilerle."
 if status_seconds>0 or status.contains("yapılamadı") or status.contains("açılamadı"):next=status
 hud.text="FESTİVAL ALANI  ·  Hazırlık %d / 3\n%s"%[3-remaining.size(),next]
 action_button.text="Finali tekrar izle" if completed else "Yardım et" if near_task>=0 else "Işığı aç"
 action_button.disabled=not can_interact()
 action_button.visible=control_display.touch_mode and not action_button.disabled
func at_final_stage()->bool:
 return all_on_stage and absf(actor.position.x-FINAL_ANCHOR_X)<150 and absf(actor.position.y-442)<90 and actor.is_on_floor()
func can_interact()->bool:
 if blocked or paused:return false
 if Quest.FESTIVAL_COMPLETE in save_data.quest_flags:return at_final_stage()
 if near_task>=0 and TASKS[near_task].id not in save_data.quest_flags:return true
 return tasks_ready() and at_final_stage()
func interact():
 if not can_interact():return
 if Quest.FESTIVAL_COMPLETE in save_data.quest_flags:
  final_replay=true;show_final();return
 var target=Quest.FESTIVAL_COMPLETE
 var checkpoint="b05.stage"
 if near_task>=0 and TASKS[near_task].id not in save_data.quest_flags:
  target=TASKS[near_task].id
  checkpoint=["b05.lights","b05.flags","b05.flowers"][near_task]
 var proposed=save_data.duplicate(true)
 if target not in proposed.quest_flags:proposed.quest_flags.append(target)
 proposed.checkpoint_id=checkpoint
 if target==Quest.FESTIVAL_COMPLETE:proposed.ending_seen=true
 if not Store.new().save(save_path,proposed):
  status="Kayıt yapılamadı. Görev tamamlanmadı, yeniden dene.";update_hud();return
 save_data=proposed
 build_station_state()
 if target==Quest.FESTIVAL_COMPLETE:show_final()
 else:
  status=TASKS[near_task].line;status_seconds=2.8
  play_contribution(near_task)
  build_station_state()
  if tasks_ready():gather_partners()
 update_hud()
func build_station_state():
 for i in station_markers.size():
  var done=TASKS[i].id in save_data.quest_flags
  station_markers[i].modulate=Color.WHITE if done else Color(0.48,0.52,0.48,0.72)
 var lights_ready=Quest.FESTIVAL_LIGHT in save_data.quest_flags
 for lamp in festival_lanterns:lamp.modulate=Color.WHITE if lights_ready else Color(0.24,0.30,0.28)
 for glow in lantern_glows:glow.visible=lights_ready
 for bunting in festival_bunting:bunting.visible=Quest.FESTIVAL_FLAGS in save_data.quest_flags
 for flower in flower_sprites:flower.visible=Quest.FESTIVAL_FLOWERS in save_data.quest_flags
 if is_instance_valid(stage_glow):stage_glow.visible=Quest.FESTIVAL_COMPLETE in save_data.quest_flags
func tasks_ready()->bool:
 return TASKS.all(func(task):return task.id in save_data.quest_flags)
func restore_party_stage():
 if Quest.FESTIVAL_COMPLETE in save_data.quest_flags:
  for i in partner_sprites.size():partner_sprites[i].position=STAGE_ANCHORS[i]
  all_on_stage=true
 elif tasks_ready():gather_partners()
func gather_partners():
 if gathering_partners or all_on_stage or partner_sprites.size()!=STAGE_ANCHORS.size():return
 gathering_partners=true
 arrived_partners=0
 partner_tweens.clear()
 for i in partner_sprites.size():
  var art:Sprite2D=partner_sprites[i]
  var target:Vector2=STAGE_ANCHORS[i]
  var duration=maxf(0.4,absf(target.x-art.position.x)/800.0)
  var tween=create_tween()
  partner_tweens.append(tween)
  tween.tween_property(art,"position:x",target.x,duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
  tween.tween_property(art,"position:y",target.y,0.22)
  tween.tween_callback(partner_arrived.bind(i))
func partner_arrived(index:int):
 restore_partner(index)
 arrived_partners+=1
 if arrived_partners>=partner_sprites.size():
  gathering_partners=false
  all_on_stage=true
  status="Arkadaşlar sahnede. Final ışığını açabilirsin."
  update_hud()
func set_partner_tweens_paused(should_pause:bool):
 pause_tween_list(partner_tweens,should_pause)
 pause_tween_list(contribution_tweens,should_pause)
func pause_tween_list(tweens:Array[Tween],should_pause:bool):
 for tween in tweens:
  if not is_instance_valid(tween) or not tween.is_valid():continue
  if should_pause:tween.pause()
  else:tween.play()
func show_final():
 set_game_paused(true)
 if is_instance_valid(help_panel):help_panel.hide()
 if is_instance_valid(pause_panel):pause_panel.hide()
 if is_instance_valid(final_panel):final_panel.show()
func leave_final():
 final_panel.hide();pause_panel.hide();final_replay=false
 set_game_paused(false);status="";status_seconds=0;update_hud()
func show_help():
 if blocked:return
 set_game_paused(true);pause_panel.hide()
 var text="Festival tamamlandı. Alanda dolaşabilir, sahneye yeniden gelip finali tekrar izleyebilirsin. Kaydın değişmez."
 if Quest.FESTIVAL_COMPLETE not in save_data.quest_flags:
  if Quest.FESTIVAL_LIGHT not in save_data.quest_flags:text="Porsuk'un yanına git. İki alçak basamağı Zıpla ile aş. Aynı platformda durunca Yardım et'e dokun ya da E'ye bas."
  elif Quest.FESTIVAL_FLAGS not in save_data.quest_flags:text="Maymun'un flama durağına ilerle. Kısa platformlar üzerinden yanına çık; sonra birlikte flamaları bağlamak için etkileş."
  elif Quest.FESTIVAL_FLOWERS not in save_data.quest_flags:text="Pıtpıt'ın çiçek durağı sağda. Üst basamaklarla yanına ulaş ve süsleri birlikte yerleştir. Düşersen son görev kaydına dönersin."
  else:text="Üç hazırlık da tamam. Arkadaşların sahneye varınca en sağdaki üst platforma çık ve son ışığı birlikte aç."
 help_text.text=text;help_panel.show()
func close_help():
 help_panel.hide();pause_panel.show()
func prepare_menu_return()->bool:
 # A rejected load has no B05 snapshot to save. Leave its source bytes untouched.
 if not blocked and not Store.new().save(save_path,save_data):
  status="Kayıt yapılamadı; ilerlemen korunuyor.";update_hud();return false
 get_tree().set_meta("journey_save_path",save_path)
 return true
func go_menu(menu_change:Callable=Callable()):
 if not prepare_menu_return():return
 var err=menu_change.call() if menu_change.is_valid() else get_tree().change_scene_to_file("res://scenes/polish_v3.tscn")
 if err!=OK:status="Ana menü açılamadı; kayıt korunuyor.";update_hud()
