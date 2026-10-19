extends Node2D
## B05 playable chapter on the canonical journey save; no separate save or HTML game.
const Store=preload("res://scripts/core/save_service.gd")
const Quest=preload("res://scripts/core/quest_state.gd")
const UI=preload("res://scripts/polish_ui.gd")
const TASKS=[{"id":Quest.FESTIVAL_LIGHT,"x":1150.0,"name":"Porsuk ile sahne ışıkları"},{"id":Quest.FESTIVAL_FLAGS,"x":2250.0,"name":"Maymun ile flamalar"},{"id":Quest.FESTIVAL_FLOWERS,"x":3310.0,"name":"Pıtpıt ile çiçekler"}]
const WORLD_WIDTH=4400.0
var save_path="user://festival_v3.json"
var save_data:Dictionary={}
var actor:CharacterBody2D
var camera:Camera2D
var hud:Label
var action_button:Button
var paused=false
var blocked=false
var left_pressed=false
var right_pressed=false
var jump_pressed=false
var action_pressed=false
var near_task=-1
var status=""
var final_panel:Control
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
func build_world():
 # Continuous safety floor below every jump: mistakes return to the route instead of losing progress.
 make_ground(0,WORLD_WIDTH,616)
 for data in [[780.0,190.0,522.0],[1000.0,170.0,446.0],[1790.0,155.0,528.0],[2010.0,155.0,465.0],[2840.0,205.0,524.0],[3090.0,175.0,454.0],[3650.0,210.0,538.0],[3910.0,210.0,474.0]]:
  make_ground(data[0],data[1],data[2])
 actor=CharacterBody2D.new();actor.name="Catpat";actor.position=Store.new().director.anchor(save_data.checkpoint_id);add_child(actor)
 var collision=CollisionShape2D.new();var body_shape=CapsuleShape2D.new();body_shape.radius=19;body_shape.height=64;collision.shape=body_shape;actor.add_child(collision)
 var sprite=Sprite2D.new();sprite.texture=load("res://assets/review-v2/catpat-idle-r2.webp");sprite.scale=Vector2.ONE*minf(0.19,66.0/maxf(1.0,sprite.texture.get_height()));actor.add_child(sprite)
 camera=Camera2D.new();camera.position_smoothing_enabled=true;camera.position_smoothing_speed=6;camera.limit_left=0;camera.limit_right=int(WORLD_WIDTH);camera.limit_top=0;camera.limit_bottom=720;actor.add_child(camera);camera.make_current()
 for i in TASKS.size():
  var point=TASKS[i]
  var marker=Node2D.new();marker.position=Vector2(point.x,568);marker.name="Station%d"%i;add_child(marker)
  var post=Polygon2D.new();post.polygon=PackedVector2Array([Vector2(-6,0),Vector2(6,0),Vector2(6,-110),Vector2(-6,-110)]);post.color=Color("786046");marker.add_child(post)
  var flag=Polygon2D.new();flag.polygon=PackedVector2Array([Vector2(7,-108),Vector2(68,-86),Vector2(7,-67)]);flag.color=Color("eed38c") if point.id in save_data.quest_flags else Color("ad8466");marker.add_child(flag)
  var text=Label.new();text.text=["PORSUK","MAYMUN","PITPIT"][i];text.position=Vector2(-55,-156);text.add_theme_font_override("font",UI.font());text.add_theme_font_size_override("font_size",26);text.add_theme_color_override("font_color",Color("fff5dd"));marker.add_child(text)
 var stage=Polygon2D.new();stage.polygon=PackedVector2Array([Vector2(3630,610),Vector2(4300,610),Vector2(4200,570),Vector2(3720,570)]);stage.color=Color("b99364");stage.z_index=0;add_child(stage)
 queue_redraw()
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
 UI.button("◀",Rect2(40,594,120,92),layer,func():left_pressed=true).button_up.connect(func():left_pressed=false)
 UI.button("▶",Rect2(175,594,120,92),layer,func():right_pressed=true).button_up.connect(func():right_pressed=false)
 UI.button("Zıpla",Rect2(1030,626,200,74),layer,func():jump_pressed=true,true)
 UI.button("Duraklat",Rect2(1008,24,230,73),layer,toggle_pause)
 final_panel=Control.new();final_panel.visible=false;layer.add_child(final_panel)
 var shade=ColorRect.new();shade.color=Color(0.03,0.1,0.08,0.82);shade.size=Vector2(1280,720);final_panel.add_child(shade)
 UI.texture("res://assets/polish-v3/panel.webp",Rect2(185,126,910,490),final_panel)
 UI.label("Hep birlikte geldik!",Rect2(330,205,665,66),43,final_panel)
 UI.label("Porsuk'un ışığı, Maymun'un flamaları ve Pıtpıt'ın çiçekleriyle festival hazır.",Rect2(325,300,650,135),26,final_panel)
 UI.button("Festivalde dolaş",Rect2(270,494,340,88),final_panel,func():final_panel.hide();paused=false,true)
 UI.button("Kaydet ve ana menü",Rect2(646,494,370,88),final_panel,go_menu)
 if Quest.FESTIVAL_COMPLETE in save_data.quest_flags:show_final()
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
  if absf(actor.position.x-TASKS[i].x)<100 and actor.is_on_floor():nearest=i
 if nearest!=near_task:near_task=nearest;update_hud()
func _unhandled_input(event):
 if blocked:return
 if event is InputEventKey and event.pressed and not event.echo:
  if event.keycode==KEY_E:interact()
  elif event.keycode==KEY_ESCAPE:toggle_pause()
func toggle_pause():
 if blocked:return
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
 if near_task>=0 and TASKS[near_task].id not in save_data.quest_flags:next="E: "+TASKS[near_task].name+" hazırlığını tamamla"
 elif remaining.is_empty() and absf(actor.position.x-4080)<150:next="E: Hep birlikte festival ışığını aç"
 hud.text="FESTİVAL ALANI · "+next+ ("\n"+status if status!="" else "")
 action_button.disabled=not can_interact()
func can_interact()->bool:
 if blocked or paused:return false
 if near_task>=0 and TASKS[near_task].id not in save_data.quest_flags:return true
 return TASKS.all(func(task):return task.id in save_data.quest_flags) and absf(actor.position.x-4080)<150 and Quest.FESTIVAL_COMPLETE not in save_data.quest_flags
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
  status="Arkadaşına yardım ettin; hazırlık kaydedildi."
  build_station_state()
 update_hud()
func build_station_state():
 for i in TASKS.size():
  var flag=get_node_or_null("Station%d/Polygon2D2"%i)
  if flag:flag.color=Color("eed38c") if TASKS[i].id in save_data.quest_flags else Color("ad8466")
func show_final():
 paused=true
 if is_instance_valid(final_panel):final_panel.show()
func go_menu():
 get_tree().set_meta("journey_save_path",save_path)
 var err=get_tree().change_scene_to_file("res://scenes/polish_v3.tscn")
 if err!=OK:status="Ana menü açılamadı; kayıt korunuyor.";update_hud()
