extends SceneTree
const Store=preload("res://scripts/core/save_service.gd")
const Quest=preload("res://scripts/core/quest_state.gd")
const PATH="user://festival-art-test.json"
var checks=0
var failures=0
func _initialize():call_deferred("run")
func check(ok:bool,label:String):
 checks+=1
 if not ok:failures+=1
 print("PASS " if ok else "FAIL ",label)
func ticks(n:int):
 for i in n:await physics_frame
func clean():
 for suffix in ["",".bak",".pending",".bak.pending",".legacy"]:DirAccess.remove_absolute(PATH+suffix)
func run():
 clean()
 var store=Store.new();var q=Quest.new()
 for event in Quest.EVENTS:
  if event in Quest.FESTIVAL_EVENTS:break
  q.apply(event)
 var data=store.fresh();data.chapter_id="B05";data.geometry="festival-v1";data.checkpoint_id="b05.entry"
 data.quest_flags=q.flags.duplicate();data.party_ids=q.party_ids();data.summit={}
 check(store.save(PATH,data),"isolated festival fixture saved")
 set_meta("journey_save_path",PATH)
 var game=load("res://scenes/festival.tscn").instantiate();root.add_child(game)
 await ticks(4)
 check(not game.blocked,"festival opens its canonical fixture")
 check(game.find_children("*","Polygon2D",true,false).is_empty() and game.find_children("*","Line2D",true,false).is_empty(),"festival scenery uses image art instead of code polygons")
 check(game.stage_glow.texture is Texture2D and game.stage_glow.texture.get_width()>0 and game.station_markers.all(func(m):return m.texture is Texture2D),"generated art loads as real runtime textures")
 check(game.station_markers.size()==3 and game.station_markers.all(func(m):return m.name=="CompletionFlag"),"all station state markers have stable image references")
 check(game.festival_lanterns.size()==6 and game.lantern_glows.all(func(g):return not g.visible),"lights start unlit")
 check(game.festival_bunting.size()==4 and game.festival_bunting.all(func(b):return not b.visible),"flamas await the actual contribution")
 check(game.flower_sprites.all(func(f):return not f.visible) and not game.stage_glow.visible,"flowers and shared final light await their events")
 var frozen_position=game.actor.position
 game.show_help();await ticks(5)
 check(game.help_panel.visible and game.paused and game.help_text.text.contains("Porsuk"),"entry help explains the current actual goal")
 check(game.actor.position.distance_to(frozen_position)<0.01,"help freezes the player")
 game.close_help();game.toggle_pause()
 for index in game.TASKS.size():
  var point=game.TASKS[index]
  game.actor.position=Vector2(point.x,point.platform_y-32);game.actor.velocity=Vector2.ZERO
  await ticks(5)
  check(game.near_task==index and game.can_interact(),"station reached for state projection "+str(index))
  game.interact()
  check(game.station_markers[index].modulate==Color.WHITE,"completed station changes its real image state "+str(index))
 check(game.lantern_glows.all(func(g):return g.visible),"Porsuk lights illuminate the world")
 check(game.festival_bunting.all(func(b):return b.visible),"Maymun flamas appear in the world")
 check(game.flower_sprites.all(func(f):return f.visible),"Pıtpıt flowers appear in the world")
 game.all_on_stage=true
 for i in game.partner_sprites.size():game.partner_sprites[i].position=game.STAGE_ANCHORS[i]
 game.actor.position=Vector2(game.FINAL_ANCHOR_X,442);game.actor.velocity=Vector2.ZERO
 await ticks(5)
 game.interact()
 check(game.final_panel.visible and game.stage_glow.visible and game.paused,"final activation illuminates stage and opens finale")
 var before=FileAccess.get_file_as_bytes(PATH);var flags=game.save_data.quest_flags.duplicate()
 game.leave_final();await ticks(5)
 check(game.can_interact() and game.action_button.text=="Finali tekrar izle","completed stage advertises a reachable read-only replay")
 game.interact()
 check(game.final_replay and game.final_panel.visible and game.paused,"final replay can be opened from the physical stage")
 check(FileAccess.get_file_as_bytes(PATH)==before and game.save_data.quest_flags==flags,"replaying finale preserves exact save bytes and flags")
 game.leave_final();game.show_help()
 check(game.help_text.text.contains("Kaydın değişmez"),"completed help describes the real replay state")
 for i in 5:
  var label:Label=game.final_panel.get_node("FinalStoryLine%d"%i)
  check(label.size.y>=label.get_theme_font("font").get_height(label.get_theme_font_size("font_size")),"final story line fits actual font metrics "+str(i))
 game.queue_free();await process_frame
 clean();set_meta("journey_save_path","user://festival_v3.json")
 print("FESTIVAL ART: %d checks, %d failures"%[checks,failures])
 quit(1 if failures else 0)
