extends SceneTree
## Targeted art projection/geometry contract; full movement stays in existing suites.
const Save=preload("res://scripts/core/save_service.gd")
const Quest=preload("res://scripts/core/quest_state.gd")
const Shared=preload("res://scripts/core/shared_party_route.gd")
const Route=preload("res://scripts/chapters/summit_main.gd")
const PATH="user://summit-art-contract.json"
var checks=0
var failures=0
func _initialize():call_deferred("run")
func check(ok:bool,label:String):
 checks+=1
 if not ok:failures+=1
 print("PASS " if ok else "FAIL ",label)
func clean():
 for suffix in ["",".bak",".pending",".bak.pending",".legacy"]:
  if FileAccess.file_exists(PATH+suffix):DirAccess.remove_absolute(PATH+suffix)
func run():
 clean()
 var experience=root.get_node_or_null("CatpatExperience")
 if experience:experience.auto_observe=false
 var state=Quest.new()
 for event in Quest.EVENTS:
  if event==Quest.SUMMIT_COMPLETE:break
  state.apply(event)
 var store=Save.new();var data=store.fresh()
 data.chapter_id="B04";data.geometry="shared-v16";data.checkpoint_id="b04.bank.0"
 data.quest_flags=state.flags.duplicate();data.party_ids=state.party_ids();data.summit=Save.Summit.fresh()
 check(store.save(PATH,data),"isolated summit entry fixture passes canonical save gate")
 set_meta("journey_save_path",PATH)
 var route=Route.new();root.add_child(route);current_scene=route;route.driver=true
 await process_frame;await physics_frame
 check(not route.load_blocked and route.team.size()==4,"actual production summit builds its four-person route")
 var expected=[]
 for bank in route.LAND:expected.append(Rect2(bank.x,540,bank.y,20))
 expected.append(Rect2(-100,870,3340,20))
 for index in route.LAND.size():
  for point in Shared.recovery_points(route.LAND[index],index).slice(0,3):expected.append(Rect2(point.x-105,point.y,210,20))
 var actual=[]
 var recovery_art=[]
 var recovery_bodies=0
 for body in route.arena.get_children():
  if not body is StaticBody2D:continue
  for child in body.get_children():
   if child is CollisionShape2D and child.shape is RectangleShape2D and child.shape.size.y==20:
    actual.append(Rect2(body.position+child.position-child.shape.size/2,child.shape.size))
    check(child.one_way_collision and child.one_way_collision_margin==6,"ledge keeps one-way collision and original margin")
  var pieces=body.find_children("RecoveryBranchArt*","Sprite2D",false,false)
  if not pieces.is_empty():recovery_bodies+=1;recovery_art.append_array(pieces)
 check(actual.size()==expected.size() and expected.all(func(rect):return rect in actual),"all13 original bank/recovery collider rectangles are unchanged")
 check(recovery_bodies==10 and recovery_art.size()==15,"nine recovery steps and lower return path receive actual image art")
 check(recovery_art.all(func(art):return art.texture!=null and art.texture.resource_path=="res://assets/chapter-v6/branch.webp" and art.scale.x==art.scale.y),"recovery art reuses calibrated branch image at uniform scale")
 check(route.arena.find_children("*","Polygon2D",true,false).is_empty() and route.arena.find_children("*","Line2D",true,false).is_empty(),"production summit no longer renders technical gray ledge polygons or lines")
 check(route.carriers.size()==2 and route.carriers.all(func(surface):return surface.art.texture.resource_path=="res://assets/chapter-v6/branch.webp" and surface.vines.size()==2 and surface.vines.all(func(vine):return vine.texture.resource_path=="res://assets/chapter-v8/vine.webp")),"moving surfaces already use original image branch and suspension vines")
 check(route.touch_buttons.all(func(button):return button.get_theme_stylebox("normal") is StyleBoxTexture and button.get_theme_stylebox("normal").texture.resource_path=="res://assets/polish-v3/jump-button.webp"),"production summit overrides rehearsal default buttons with actual image control skins")
 for surface in route.carriers:
  var collider=surface.get_child(0)
  check(collider is CollisionShape2D and collider.shape.size==Vector2(300,18) and collider.position==Vector2(0,9) and surface.collision_layer==4,"moving platform keeps300×18 measured carrier collision")
 route.queue_free();await process_frame
 set_meta("journey_save_path","user://festival_v3.json");clean()
 print("SUMMIT ART CONTRACT: %d checks, %d failures"%[checks,failures])
 quit(1 if failures else 0)
