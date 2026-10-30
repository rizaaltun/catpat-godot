extends SceneTree
const Store=preload("res://scripts/core/save_service.gd")
const Quest=preload("res://scripts/core/quest_state.gd")
const Main=preload("res://scripts/polish_world.gd")
const SummitStore=preload("res://scripts/core/summit_progress.gd")
const PATH="user://image-effects-contract.json"
var checks=0
var failures=0
func _initialize():call_deferred("run")
func check(ok:bool,label:String):
 checks+=1
 if not ok:failures+=1
 print("PASS " if ok else "FAIL ",label)
func ticks(count:int):
 for i in count:await physics_frame
func clean():
 for suffix in ["",".bak",".pending",".bak.pending",".legacy"]:DirAccess.remove_absolute(PATH+suffix)
func run():
 clean();set_meta("journey_save_path",PATH)
 var world=Main.new();root.add_child(world);world.automated=true;world.build_world()
 await ticks(40)
 world.update_image_effects(0.0)
 var effects=world.image_effects
 check(is_instance_valid(effects) and effects.name=="ImageWorldEffects","B01 creates a separate image-only world effect projection")
 check(effects.mote_sprites.size()==5 and effects.firefly_sprites.size()==55 and effects.lantern_glows.size()==3 and effects.shadow_sprites.size()==2,"all prior effect families have real image sprites")
 check(effects.get_children().all(func(node):return node is Sprite2D),"effect helper contains no code-drawn geometry or collision objects")
 check(effects.mote_sprites.all(func(node):return node.texture.resource_path.ends_with("catpat_b05_lantern_glow_v001.png")),"all motes derive from the generated glow source")
 check(effects.shadow_sprites.all(func(node):return node.texture.resource_path.ends_with("catpat_shared_ground_shadow_v001.png")),"foot shadows derive from the generated shadow source")
 check(effects.mote_sprites.all(func(node):return node.visible) and effects.lantern_glows.all(func(node):return not node.visible) and not effects.exit_glow.visible,"fresh progress shows uncollected motes and no unearned light")
 check(effects.shadow_sprites[0].visible and effects.shadow_sprites[0].position==world.player.position+Vector2(0,3),"ground shadow follows the player's existing physical foot root")
 var state=Quest.new();state.apply(Quest.ACCEPTED);state.apply(Quest.LIGHTS[0]);state.collect(0)
 var data=Store.new().fresh();data.quest_flags=state.flags.duplicate();data.collectibles=state.collectibles.duplicate()
 world.apply_quest(data);world.update_image_effects(0.0)
 check(not effects.mote_sprites[0].visible and effects.mote_sprites.slice(1).all(func(node):return node.visible),"collected state hides only its matching mote image")
 check(effects.lantern_glows[0].visible and not effects.lantern_glows[1].visible and not effects.lantern_glows[2].visible,"light image visibility projects only committed lantern flags")
 world.lanterns[2].glow=Vector2(2800,290);world.update_image_effects(0.0)
 check(effects.lantern_glows[2].position==Vector2(2800,290),"moving lantern image remains attached to its existing dynamic glow anchor")
 world.mode="play";world.update_image_effects(0.5)
 var active_time=effects.effect_time;var active_mote=effects.mote_sprites[1].position
 check(active_time>0 and active_mote!=world.Level.MOTES[1],"normal active gameplay advances bounded decorative motion")
 world.mode="pause";world.update_image_effects(2.0)
 check(effects.effect_time==active_time and effects.mote_sprites[1].position==active_mote,"pause freezes effect time and visual positions")
 root.set_meta("catpat_preferences",{"reduced_motion":true});world.mode="play";world.update_image_effects(2.0)
 check(effects.effect_time==active_time and effects.firefly_sprites.all(func(node):return not node.visible),"reduced motion suppresses decorative firefly drift and time advancement")
 check(effects.mote_sprites[1].position==world.Level.MOTES[1] and effects.lantern_glows[0].visible,"reduced motion fixes mote bob without hiding earned light feedback")
 for id in Quest.LIGHTS:state.apply(id)
 state.apply(Quest.JOINED);state.apply(Quest.COMPLETE)
 data.quest_flags=state.flags.duplicate();data.party_ids=state.party_ids();world.apply_quest(data);world.update_image_effects(0.0)
 check(effects.exit_glow.visible and effects.exit_glow.position==Vector2(3669,472),"completed B01 projects its exit lantern light at the original anchor")
 check(not FileAccess.file_exists(PATH),"visual projection never creates or writes a journey save")
 world.mode="menu";world.queue_free();await process_frame
 var q=Quest.new()
 for id in Quest.EVENTS:
  if id!=Quest.SUMMIT_COMPLETE and id not in Quest.FESTIVAL_EVENTS:q.apply(id)
 var summit=Store.new().fresh();summit.chapter_id="B04";summit.geometry="shared-v16";summit.checkpoint_id="b04.bank.0";summit.quest_flags=q.flags.duplicate();summit.party_ids=q.party_ids();summit.summit=SummitStore.fresh()
 check(Store.new().save(PATH,summit),"B04 image-halo fixture is a valid existing journey")
 var before=FileAccess.get_file_as_string(PATH)
 var route=load("res://scenes/summit.tscn").instantiate();root.add_child(route);await process_frame
 check(not route.load_blocked and route.halo.texture is Texture2D and not route.halo.texture is GradientTexture2D,"B04 uses a real image glow instead of a procedural gradient")
 check(route.halo.texture.resource_path.ends_with("catpat_b05_lantern_glow_v001.png") and is_equal_approx(route.halo.scale.x,route.halo.scale.y),"B04 halo uses the shared source with undistorted image proportions")
 check(not route.halo.visible,"unlit B04 lantern does not show an unearned halo")
 route.lantern_stage="lit";route.refresh_lantern();route._physics_process(0.016)
 check(route.halo.visible and is_equal_approx(route.halo.modulate.a,0.42) and route.glow_time==0,"lit B04 image halo remains still in reduced motion")
 route.set_pause(true);var alpha=route.halo.modulate.a;route._physics_process(1.0)
 check(route.halo.modulate.a==alpha,"B04 pause also preserves the halo projection")
 check(FileAccess.get_file_as_string(PATH)==before,"B04 halo changes leave canonical saved progress bytes untouched")
 route.queue_free();await process_frame;root.remove_meta("catpat_preferences");clean()
 var audio=root.get_node_or_null("CatpatAudio")
 if audio and audio.has_method("shutdown"):audio.shutdown();await create_timer(0.2).timeout
 print("IMAGE EFFECTS: %d checks, %d failures"%[checks,failures])
 quit(1 if failures else 0)
