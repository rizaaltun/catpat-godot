extends SceneTree
const SettingsPanel=preload("res://scripts/ui/settings_panel.gd")
const Store=preload("res://scripts/core/save_service.gd")
const PATH="user://settings-panel-test.json"
var checks=0
var failures=0
func check(ok:bool,label:String):
 checks+=1
 if not ok:failures+=1
 print("PASS " if ok else "FAIL ",label)
func clean():
 for suffix in ["", ".bak", ".pending", ".bak.pending", ".legacy"]:DirAccess.remove_absolute(PATH+suffix)
func _initialize():call_deferred("run")
func run():
 clean()
 var store=Store.new();var data=store.fresh();data.settings={"music":0.5,"host_setting":"keep"}
 check(store.save(PATH,data),"settings UI fixture saves")
 var closed=[0];var applied=[{}]
 var panel=SettingsPanel.new();root.add_child(panel)
 panel.setup(PATH,func():closed[0]+=1,func(settings):applied[0]=settings)
 await process_frame;await process_frame
 check(panel.save_path==PATH and panel.setting_buttons.size()==8,"panel presents eight preferences for the supplied journey")
 var safe=Rect2(0,0,1280,720)
 check(panel.buttons.all(func(button):return safe.encloses(button.get_global_rect()) and button.size.y>=112),"every image button fits the narrow-layout logical canvas with a generous target")
 var all_art=true
 for button in panel.buttons:
  for state in ["normal","hover","pressed","focus"]:
   var skin=button.get_theme_stylebox(state)
   all_art=all_art and skin is StyleBoxTexture and skin.texture.resource_path.begins_with("res://assets/polish-v3/")
 var separated=true
 for i in panel.buttons.size():
  for j in range(i+1,panel.buttons.size()):separated=separated and not panel.buttons[i].get_global_rect().intersects(panel.buttons[j].get_global_rect())
 check(separated,"expanded font metrics leave all grid/footer buttons separated")
 check(all_art,"all normal, hover, pressed and focus button states use existing image art")
 panel.buttons[0].grab_focus()
 var tab=InputEventKey.new();tab.keycode=KEY_TAB;tab.pressed=true
 panel._input(tab)
 check(root.gui_get_focus_owner()==panel.buttons[1],"Tab advances keyboard focus")
 tab.shift_pressed=true;panel._input(tab)
 check(root.gui_get_focus_owner()==panel.buttons[0],"Shift+Tab reverses keyboard focus")
 var down=InputEventKey.new();down.keycode=KEY_DOWN;down.pressed=true;panel._input(down)
 check(root.gui_get_focus_owner()==panel.buttons[3],"arrow key navigation follows the preference grid")
 panel.setting_buttons.full_text.grab_focus()
 var full_before=panel.draft.full_text
 var enter=InputEventKey.new();enter.keycode=KEY_ENTER;enter.pressed=true
 Input.parse_input_event(enter);await process_frame
 enter.pressed=false;Input.parse_input_event(enter);await process_frame
 check(panel.draft.full_text!=full_before,"Enter activates the focused image button through Godot GUI input")
 panel.setting_buttons.music.pressed.emit()
 check(panel.draft.music==0.75 and store.load_progress(PATH).data.settings.music==0.5,"cycling the live Turkish label changes only the unsaved draft")
 var latest=store.load_progress(PATH).data;latest.settings.text_scale=1.3
 store.save(PATH,latest)
 if "--settings-capture" in OS.get_cmdline_user_args():
  root.size=Vector2i(666,374)
  await process_frame;await RenderingServer.frame_post_draw
  var frame=root.get_texture().get_image()
  check(not frame.is_empty(),"settings panel renders at666x374")
  print("VISUAL_CAPTURE:settings-small:"+Marshalls.raw_to_base64(frame.save_webp_to_buffer(true,0.82)))
 panel.save_and_close()
 var saved=store.load_progress(PATH).data
 check(closed[0]==1 and applied[0].music==0.75,"successful save applies preferences and closes once")
 check(saved.settings.music==0.75 and saved.settings.text_scale==1.3 and saved.settings.host_setting=="keep","modal save merges only changed keys into the newest settings")
 await process_frame
 panel=SettingsPanel.new();root.add_child(panel);panel.setup(PATH,func():closed[0]+=1)
 await process_frame
 var original=FileAccess.get_file_as_bytes(PATH)
 panel.reset_draft();panel.close();await process_frame
 check(closed[0]==2 and FileAccess.get_file_as_bytes(PATH)==original,"cancel after resetting the draft leaves canonical bytes untouched")
 var corrupt=FileAccess.open(PATH,FileAccess.WRITE);corrupt.store_string("{invalid source}");corrupt.close();DirAccess.remove_absolute(PATH+".bak")
 original=FileAccess.get_file_as_bytes(PATH)
 panel=SettingsPanel.new();root.add_child(panel);panel.setup(PATH,func():closed[0]+=1)
 panel.cycle("music");panel.save_and_close()
 check(not panel.is_queued_for_deletion() and panel.status_label.text.contains("kayıt korundu"),"save failure remains in the modal with an actionable Turkish message")
 await process_frame
 check(panel.status_label.get_minimum_size().y<=140 and panel.status_label.get_rect().end.y<=550,"failed-save message fits the reserved status slot")
 check(FileAccess.get_file_as_bytes(PATH)==original,"settings panel never replaces corrupt journey bytes")
 var escape=InputEventKey.new();escape.keycode=KEY_ESCAPE;escape.pressed=true;panel._input(escape)
 await process_frame
 check(closed[0]==3,"Escape closes the failed modal without saving")
 clean()
 var audio=root.get_node_or_null("CatpatAudio")
 if is_instance_valid(audio) and audio.has_method("shutdown"):
  audio.shutdown()
  await create_timer(0.25).timeout
 print("SETTINGS PANEL: %d checks, %d failures"%[checks,failures])
 quit(1 if failures else 0)
