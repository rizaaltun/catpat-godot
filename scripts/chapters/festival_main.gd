extends Node2D
## B05 playable chapter on the canonical journey save; no separate save or HTML game.
const Store=preload("res://scripts/core/save_service.gd")
const Quest=preload("res://scripts/core/quest_state.gd")
const UI=preload("res://scripts/polish_ui.gd")
const PLATFORM_ART="res://assets/chapter-v5/platform.webp"
const FOREST_ART="res://assets/polish-v3/forest.webp"
const DAISY_ART="res://assets/chapter-v13/daisies.webp"
const SIGN_ART="res://assets/chapter-v20/festival-arrow.webp"
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
var action_button:Button
var control_display=preload("res://scripts/core/control_display.gd").new()
var input_router=preload("res://scripts/core/input_router.gd").new()
var paused=false
var blocked=false
var left_pressed=false
var right_pressed=false
var jump_pressed=false
var action_pressed=false
var near_task=-1
var status=""
var final_panel:Control
var partner_sprites:Array=[]
var flower_sprites:Array=[]
var all_on_stage=false
var gathering_partners=false
var arrived_partners=0
var companion_walk_clock=0.0
var companion_walk_frame=0
func _ready():
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
 var visual=Polygon2D.new();visual.polygon=PackedVector2Array([Vector2(-width/2,-36),Vector2(width/2,-36),Vector2(width/2,36),Vector2(-width/2,36)]);visual.color=Color("71885b");body.add_child(visual)
 var trim=Polygon2D.new();trim.polygon=PackedVector2Array([Vector2(-width/2,-36),Vector2(width/2,-36),Vector2(width/2,-23),Vector2(-width/2,-23)]);trim.color=Color("b8bf73");body.add_child(trim)
 var art=Sprite2D.new();art.texture=load(PLATFORM_ART);art.name="MossyPlatformArt"
 var scale_factor=width/maxf(1.0,art.texture.get_width());art.scale=Vector2.ONE*scale_factor
 var visible_top=190.0*scale_factor;var drawn_height=art.texture.get_height()*scale_factor
 art.position=Vector2(0,drawn_height/2.0-visible_top-36.0);art.z_index=1;body.add_child(art)
func add_forest_backdrop():
 var parallax=Parallax2D.new();parallax.name="FestivalForestBackdrop"
 var backdrop=Sprite2D.new();backdrop.texture=load(FOREST_ART);backdrop.centered=false
 var scale_factor=720.0/maxf(1.0,backdrop.texture.get_height());backdrop.scale=Vector2.ONE*scale_factor
 parallax.repeat_size=Vector2(backdrop.texture.get_width()*scale_factor,720.0);parallax.repeat_times=8
 parallax.scroll_scale=Vector2(0.12,0.0);parallax.add_child(backdrop);add_child(parallax)
func add_festival_camp_art():
 var art=Sprite2D.new();art.texture=load("res://assets/world/forest.webp");art.name="FestivalCampArt";art.centered=false
 art.scale=Vector2.ONE*(720.0/maxf(1.0,art.texture.get_height()));art.position=Vector2(3300.0,0);art.z_index=0;add_child(art)
func add_bunting(x:float,y:float):
 var cord=Line2D.new();cord.points=PackedVector2Array([Vector2(x,y),Vector2(x+300,y+25)]);cord.width=3;cord.default_color=Color("f3dfaa");cord.z_index=4;add_child(cord)
 var colors=[Color("d97f64"),Color("ebcb7d"),Color("7fa5b2"),Color("a3bf81")]
 for i in 7:
  var flag=Polygon2D.new();flag.polygon=PackedVector2Array([Vector2.ZERO,Vector2(28,2),Vector2(14,32)])
  flag.position=Vector2(x+i*44.0,y+i*3.7);flag.color=colors[i%colors.size()];flag.z_index=4;add_child(flag)
func build_world():
 add_forest_backdrop()
 add_festival_camp_art()
 # Safe ground is broken into short zones; paired low platforms form the route to each task.
 for data in [[0.0,850.0,616.0],[930.0,870.0,616.0],[1880.0,820.0,616.0],[2780.0,820.0,616.0],[3670.0,730.0,616.0]]:
  make_ground(data[0],data[1],data[2])
 for data in [[780.0,190.0,522.0],[1000.0,170.0,446.0],[1790.0,155.0,528.0],[2010.0,155.0,465.0],[2200.0,220.0,465.0],[2840.0,205.0,524.0],[3090.0,175.0,454.0],[3280.0,180.0,454.0],[3650.0,210.0,538.0],[3910.0,390.0,474.0]]:
  make_ground(data[0],data[1],data[2])
 for x in [3800.0,3930.0,4060.0,4190.0]:
  add_world_sprite("res://assets/polish-v3/lantern.webp",Vector2(x,540),74.0,2)
 for x in [590.0,1650.0,2700.0,3520.0]:
  add_world_sprite(SIGN_ART,Vector2(x,530),38.0,3)
 for x in [300.0,1390.0,2470.0,3590.0]:add_bunting(x,170.0)
 actor=CharacterBody2D.new();actor.name="Catpat";actor.position=Store.new().director.anchor(save_data.checkpoint_id);add_child(actor)
 var collision=CollisionShape2D.new();var body_shape=CapsuleShape2D.new();body_shape.radius=19;body_shape.height=64;collision.shape=body_shape;actor.add_child(collision)
 var sprite=Sprite2D.new();sprite.texture=load("res://assets/review-v2/catpat-idle-r2.webp");sprite.scale=Vector2.ONE*minf(0.19,66.0/maxf(1.0,sprite.texture.get_height()));actor.add_child(sprite)
 camera=Camera2D.new();camera.position_smoothing_enabled=true;camera.position_smoothing_speed=6;camera.limit_left=0;camera.limit_right=int(WORLD_WIDTH);camera.limit_top=0;camera.limit_bottom=720;actor.add_child(camera);camera.make_current()
 for i in TASKS.size():
  var point=TASKS[i]
  var marker=Node2D.new();marker.position=Vector2(point.x,point.platform_y);marker.name="Station%d"%i;add_child(marker)
  add_partner(i)
  var post=Polygon2D.new();post.polygon=PackedVector2Array([Vector2(-6,0),Vector2(6,0),Vector2(6,-110),Vector2(-6,-110)]);post.color=Color("786046");marker.add_child(post)
  var flag=Polygon2D.new();flag.polygon=PackedVector2Array([Vector2(7,-108),Vector2(68,-86),Vector2(7,-67)]);flag.color=Color("eed38c") if point.id in save_data.quest_flags else Color("ad8466");marker.add_child(flag)
  var text=Label.new();text.text=point.character.to_upper();text.position=Vector2(-55,-156);text.add_theme_font_override("font",UI.font());text.add_theme_font_size_override("font_size",26);text.add_theme_color_override("font_color",Color("fff5dd"));marker.add_child(text)
 for x in [3180.0,3285.0,3390.0]:
  var flowers=Sprite2D.new();flowers.texture=load(DAISY_ART);flowers.scale=Vector2.ONE*0.055
  flowers.position=Vector2(x,575);flowers.z_index=3;flowers.visible=Quest.FESTIVAL_FLOWERS in save_data.quest_flags
  flowers.name="FestivalDaisy";add_child(flowers);flower_sprites.append(flowers)
 var stage=Polygon2D.new();stage.polygon=PackedVector2Array([Vector2(3630,610),Vector2(4300,610),Vector2(4200,570),Vector2(3720,570)]);stage.color=Color("b99364");stage.z_index=0;add_child(stage)
 var stage_trim=Polygon2D.new();stage_trim.polygon=PackedVector2Array([Vector2(3720,575),Vector2(4200,575),Vector2(4170,588),Vector2(3750,588)]);stage_trim.color=Color("ecd39a");stage_trim.z_index=1;add_child(stage_trim)
 queue_redraw()
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
 tween.tween_property(art,"position:y",base_y-26.0,0.20).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
 tween.tween_property(art,"position:y",base_y,0.20).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
 tween.tween_callback(restore_partner.bind(index))
func _draw():
 draw_rect(Rect2(0,0,WORLD_WIDTH,720),Color("94c6a8"),true)
 for i in 18:
  var x=float(i)*265.0
  draw_circle(Vector2(x+125,180+(i%4)*17),90,Color("d7dfaa",0.3))
 for x in [550,1630,2700,3780]:
  draw_line(Vector2(x,170),Vector2(x+170,160),Color("f8ecc4"),5)
  for j in 5:
   draw_colored_polygon(PackedVector2Array([Vector2(x+j*34,166),Vector2(x+j*34+26,165),Vector2(x+j*34+13,190)]),[Color("d97f64"),Color("ebcb7d"),Color("7fa5b2")][j%3])
func build_ui():
 var layer=CanvasLayer.new();add_child(layer)
 UI.texture("res://assets/polish-v3/panel.webp",Rect2(18,15,935,133),layer)
 hud=UI.label("",Rect2(62,31,850,112),24,layer)
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
 final_panel=Control.new();final_panel.visible=false;layer.add_child(final_panel)
 var shade=ColorRect.new();shade.color=Color(0.03,0.1,0.08,0.82);shade.size=Vector2(1280,720);final_panel.add_child(shade)
 UI.texture("res://assets/polish-v3/panel.webp",Rect2(185,126,910,490),final_panel)
 UI.label("Hep birlikte geldik!",Rect2(330,205,665,66),43,final_panel)
 UI.label("Yolumu göremediğimde yanımdaydın.\nKöprüyü birlikte tamamladık.\nHazırladığım süsleri de kurtardık.\nFestival şimdi daha güzel.\nÇünkü hepimiz buradayız.",Rect2(275,270,730,145),19,final_panel)
 for i in TASKS.size():
  var portrait=Sprite2D.new();portrait.texture=load(TASKS[i].idle)
  portrait.scale=Vector2.ONE*84.0/maxf(1.0,portrait.texture.get_height());portrait.position=Vector2([390.0,640.0,890.0][i],415);final_panel.add_child(portrait)
  UI.label(TASKS[i].character,Rect2([320.0,570.0,820.0][i],453,140,34),20,final_panel)
 UI.button("Festivalde dolaş",Rect2(270,526,340,72),final_panel,func():final_panel.hide();paused=false,true)
 UI.button("Kaydet ve ana menü",Rect2(646,526,370,72),final_panel,go_menu)
 if Quest.FESTIVAL_COMPLETE in save_data.quest_flags:show_final()
func _process(delta):
 if blocked or paused or not gathering_partners:return
 companion_walk_clock+=delta
 if companion_walk_clock<0.18:return
 companion_walk_clock=0.0
 companion_walk_frame=1-companion_walk_frame
 for i in partner_sprites.size():
  var art:Sprite2D=partner_sprites[i]
  art.texture=load(TASKS[i].walk[companion_walk_frame])
func _physics_process(delta):
 if blocked or paused:return
 actor.velocity.y=minf(actor.velocity.y+1350*delta,950)
 var axis=float(int(Input.is_action_pressed("ui_right") or Input.is_key_pressed(KEY_D) or right_pressed)-int(Input.is_action_pressed("ui_left") or Input.is_key_pressed(KEY_A) or left_pressed))
 actor.velocity.x=axis*265
 if (Input.is_action_just_pressed("ui_accept") or Input.is_key_pressed(KEY_SPACE) or jump_pressed) and actor.is_on_floor():actor.velocity.y=-535
 jump_pressed=false
 actor.move_and_slide()
 actor.position.x=clampf(actor.position.x,35,WORLD_WIDTH-35)
 if actor.position.y>820:actor.position=Store.new().director.anchor(save_data.checkpoint_id);actor.velocity=Vector2.ZERO
 var nearest=-1
 for i in TASKS.size():
  var task=TASKS[i];var standing_y=task.platform_y-32.0
  if absf(actor.position.x-task.x)<100 and absf(actor.position.y-standing_y)<74 and actor.is_on_floor():nearest=i
 if nearest!=near_task:near_task=nearest;update_hud()
func _input(event):
 if blocked or paused:return
 if control_display.observe(event):clear_gameplay_inputs()
 # A touch emits an emulated mouse event too; route the real finger only.
 if control_display.touch_mode and event is InputEventMouseButton:return
 if control_display.accepts(event) and input_router.consume(event):
  left_pressed=input_router.axis<0.0
  right_pressed=input_router.axis>0.0
  jump_pressed=input_router.jump_held
  if input_router.interact_pressed:interact()
func _notification(what):
 if what==NOTIFICATION_APPLICATION_FOCUS_OUT:
  clear_gameplay_inputs()
  if not blocked and not paused:toggle_pause()
func _unhandled_input(event):
 if blocked:return
 if event is InputEventKey and event.pressed and not event.echo:
  if event.keycode==KEY_E:interact()
  elif event.keycode==KEY_ESCAPE:toggle_pause()
func clear_gameplay_inputs():
 input_router.reset()
 left_pressed=false;right_pressed=false;jump_pressed=false;action_pressed=false
func toggle_pause():
 if blocked:return
 clear_gameplay_inputs()
 paused=not paused
 status="Duraklatıldı. Tekrar basarak devam et." if paused else ""
 update_hud()
func update_hud():
 if not is_instance_valid(hud):return
 var remaining=[]
 for item in TASKS:
  if item.id not in save_data.quest_flags:remaining.append(item.name)
 var next="Son ışığı açmak için sahneye git" if remaining.is_empty() else "Hazırlık: "+", ".join(remaining)
 if Quest.FESTIVAL_COMPLETE in save_data.quest_flags:next="Festival tamamlandı · yeniden dolaşabilirsin"
 elif remaining.is_empty() and not all_on_stage:next="Arkadaşların sahneye geliyor."
 if near_task>=0 and TASKS[near_task].id not in save_data.quest_flags:next="E: "+TASKS[near_task].name+" hazırlığını tamamla"
 elif remaining.is_empty() and all_on_stage and absf(actor.position.x-FINAL_ANCHOR_X)<150 and absf(actor.position.y-442)<90:next="E: Hep birlikte festival ışığını aç"
 hud.text="FESTİVAL ALANI · "+next+ ("\n"+status if status!="" else "")
 action_button.disabled=not can_interact()
func can_interact()->bool:
 if blocked or paused:return false
 if near_task>=0 and TASKS[near_task].id not in save_data.quest_flags:return true
 return tasks_ready() and all_on_stage and absf(actor.position.x-FINAL_ANCHOR_X)<150 and absf(actor.position.y-442)<90 and actor.is_on_floor() and Quest.FESTIVAL_COMPLETE not in save_data.quest_flags
func interact():
 if not can_interact():return
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
 if target==Quest.FESTIVAL_COMPLETE:show_final()
 else:
  status=TASKS[near_task].line
  play_contribution(near_task)
  build_station_state()
  if tasks_ready():gather_partners()
 update_hud()
func build_station_state():
 for i in TASKS.size():
  var flag=get_node_or_null("Station%d/Polygon2D2"%i)
  if flag:flag.color=Color("eed38c") if TASKS[i].id in save_data.quest_flags else Color("ad8466")
 for flower in flower_sprites:flower.visible=Quest.FESTIVAL_FLOWERS in save_data.quest_flags
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
 for i in partner_sprites.size():
  var art:Sprite2D=partner_sprites[i]
  var target:Vector2=STAGE_ANCHORS[i]
  var duration=maxf(0.4,absf(target.x-art.position.x)/800.0)
  var tween=create_tween()
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
func show_final():
 paused=true
 if is_instance_valid(final_panel):final_panel.show()
func go_menu():
 get_tree().set_meta("journey_save_path",save_path)
 var err=get_tree().change_scene_to_file("res://scenes/polish_v3.tscn")
 if err!=OK:status="Ana menü açılamadı; kayıt korunuyor.";update_hud()
