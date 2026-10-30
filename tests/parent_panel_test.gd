extends SceneTree
const ParentPanel=preload("res://scripts/ui/parent_panel.gd")
const Profiles=preload("res://scripts/core/profile_service.gd")
const Observations=preload("res://scripts/core/observation_service.gd")
const Store=preload("res://scripts/core/save_service.gd")
const BASE="user://parent-panel-fictional-test"
var checks=0
var failures=0
class Host extends Node:
 var save_path=""
 var settings={"text_scale":1.3}
func _initialize():
 set_meta("journey_save_path",BASE+"/host.json")
 call_deferred("run")
func check(ok:bool,label:String):
 checks+=1
 if not ok:failures+=1
 print("PASS " if ok else "FAIL ",label)
func clean(path:String):
 var directory=DirAccess.open(path)
 if not directory:return
 for file in directory.get_files():DirAccess.remove_absolute(path+"/"+file)
 for name in directory.get_directories():clean(path+"/"+name)
 DirAccess.remove_absolute(path)
func settle():
 for frame in 8:await process_frame
func click(panel,text:String):
 var matches=panel.find_children("*","Button",true,false).filter(func(button):return button.text==text)
 check(matches.size()==1,"unique action: "+text)
 if matches.size()==1:matches[0].pressed.emit()
func capture(panel,tag:String):
 for frame in 8:
  panel._process(0)
  await process_frame
 await settle()
 var tabs_bottom=0.0
 for button in panel.chrome_tabs:tabs_bottom=maxf(tabs_bottom,button.get_rect().end.y)
 check(panel.scroll.position.y>=tabs_bottom+8,"large-text "+tag+" content clears tabs")
 if panel.confirmation_mode:
  check(panel.scroll.get_rect().end.y<=480,"confirmation text stays above fixed visible actions")
  for button in panel.find_children("*","Button",true,false):
   if button.text in ["Vazgeç","Verileri sil","Yeni yolcuya aktar"]:check(button.get_rect().end.y<598 and button.position.y>=500,"confirmation action stays visible above footer")
 for item in panel.layout_items:
  check(item.node.get_rect().end.x<=panel.body.custom_minimum_size.x,"large-text "+tag+" item fits content width")
 if "--parent-capture" in OS.get_cmdline_user_args():
  for window in [Vector2i(1280,720),Vector2i(666,374)]:
   root.size=window
   await process_frame;await RenderingServer.frame_post_draw
   var frame=root.get_texture().get_image()
   check(not frame.is_empty(),tag+" actual native frame renders "+str(window))
   frame.save_png("/workspace/scratch/e028dcf73aa2/tooling/parent-"+tag+"-"+str(window.x)+".png")
  root.size=Vector2i(1280,720)
func run():
 clean(BASE)
 var experience=root.get_node_or_null("CatpatExperience")
 if experience:experience.auto_observe=false
 var profiles=Profiles.new();profiles.configure(BASE+"/profiles",BASE+"/legacy.json");root.add_child(profiles)
 check(profiles.ensure_loaded().ok,"isolated real profile service initializes")
 var observations=Observations.new()
 observations.profile_resolver=profiles.profile_for_path;observations.profile_id_resolver=profiles.profile_by_id
 root.add_child(observations);profiles.observations_resolver=func():return observations
 var first=profiles.active_profile();var original=FileAccess.get_file_as_bytes(first.journey_path)
 var host=Host.new();host.save_path=first.journey_path;root.add_child(host)
 var panel=ParentPanel.new();root.add_child(panel);panel.build(host,profiles,observations)
 panel.set_process(false)
 panel.show_tab("profiles")
 check(not panel.unlocked and profiles.list_profiles().size()==1,"tabs cannot bypass adult transition")
 panel.gate_button.button_down.emit();panel._process(1.0);panel.gate_button.button_up.emit();panel._process(2.1)
 check(not panel.unlocked,"releasing before two seconds cancels adult transition")
 panel.gate_button.button_down.emit();panel._process(1.5);panel.notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT);panel._process(1.0)
 check(not panel.unlocked and panel.gate_elapsed==0,"focus loss cancels held adult transition")
 panel.gate_button.button_down.emit();panel._process(2.1)
 check(panel.unlocked and panel.model.events.is_empty(),"full hold opens real journey without fabricated historical evidence")
 await capture(panel,"journey")
 panel.show_tab("observations");await capture(panel,"observations")
 panel.show_tab("profiles");await capture(panel,"profiles")
 panel._create_profile();var second=profiles.active_profile()
 check(second.profile_id!=first.profile_id and panel.journey_path==second.journey_path and panel.profile_changed,"UI creation activates a separate real B00 profile")
 check(FileAccess.get_file_as_bytes(first.journey_path)==original,"UI creation preserves original journey bytes")
 panel._activate(first.profile_id)
 check(panel.journey_path==first.journey_path,"UI switch resolves original journey path")
 panel._confirm_delete(second.profile_id);await capture(panel,"delete-confirm")
 click(panel,"Vazgeç")
 check(profiles.list_profiles().size()==2 and FileAccess.file_exists(second.journey_path),"cancelling delete preserves selected profile and files")
 panel._confirm_delete(second.profile_id);click(panel,"Verileri sil")
 check(profiles.list_profiles().size()==1 and not FileAccess.file_exists(second.journey_path),"confirmed UI deletion removes only selected profile")
 panel.show_tab("data");await capture(panel,"data")
 panel._paste_import();await capture(panel,"paste-import")
 check(panel.transfer_text.get_parent()==panel.body,"paste editor participates in scroll layout")
 panel.show_tab("data")
 var bundle=profiles.export_bundle(first.profile_id)
 check(bundle.ok,"real profile exports portable fictional bundle")
 var index_before=FileAccess.get_file_as_bytes(profiles.index_path())
 panel._prepare_import("{invalid}")
 check(profiles.list_profiles().size()==1 and FileAccess.get_file_as_bytes(profiles.index_path())==index_before,"invalid UI import cannot mutate profile index")
 panel._prepare_import(JSON.stringify(bundle.bundle));await capture(panel,"import-confirm")
 click(panel,"Vazgeç")
 check(profiles.list_profiles().size()==1,"import preview cancellation creates no profile")
 panel._prepare_import(JSON.stringify(bundle.bundle));click(panel,"Yeni yolcuya aktar")
 check(profiles.list_profiles().size()==2 and profiles.active_profile().profile_id==first.profile_id,"confirmed import creates new profile without switching active journey")
 check(FileAccess.get_file_as_bytes(first.journey_path)==original,"UI transfer preserves exact original journey bytes")
 profiles.fault="index_write"
 panel._create_profile()
 check(profiles.list_profiles().size()==2 and panel.tab=="profiles","failed UI create stays in management and preserves profiles")
 profiles.fault=""
 var returned=[];panel.closed.connect(func(changed):returned.append(changed));panel.close()
 check(returned==[true],"close signals profile change to menu owner")
 panel.queue_free();host.queue_free();observations.queue_free();profiles.queue_free();await process_frame
 clean(BASE)
 print("PARENT PANEL: %d checks, %d failures"%[checks,failures])
 quit(1 if failures else 0)
