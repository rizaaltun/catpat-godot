extends SceneTree
const Save = preload("res://scripts/core/save_service.gd")
const PATH = "user://festival-recovery-test.json"
const SUFFIXES = ["", ".bak", ".pending", ".bak.pending", ".legacy"]
var checks = 0
var failures = 0
func check(ok: bool, label: String):
 checks += 1
 if not ok: failures += 1
 print("PASS " if ok else "FAIL ", label)
func clean():
 for suffix in SUFFIXES: DirAccess.remove_absolute(PATH + suffix)
func snapshot() -> Dictionary:
 var result = {}
 for suffix in SUFFIXES:
  if FileAccess.file_exists(PATH + suffix): result[suffix] = FileAccess.get_file_as_bytes(PATH + suffix)
 return result
func _initialize(): call_deferred("run")
func run():
 for scenario in ["missing", "invalid", "wrong-chapter"]:
  clean()
  if scenario == "invalid":
   var file = FileAccess.open(PATH, FileAccess.WRITE)
   file.store_string("{damaged festival source — preserve exactly}")
   file.close()
  elif scenario == "wrong-chapter":
   check(Save.new().save(PATH, Save.new().fresh()), "valid B01 source fixture is stored")
  var original = snapshot()
  set_meta("journey_save_path", PATH)
  var game = load("res://scenes/festival.tscn").instantiate()
  root.add_child(game)
  await process_frame
  check(game.blocked and game.save_data.is_empty(), scenario + " shows the rejected-load screen without a B05 snapshot")
  var menu_button: Button
  for button in game.find_children("*", "Button", true, false):
   if button.text == "Ana menü": menu_button = button
  check(is_instance_valid(menu_button) and menu_button.pressed.is_connected(game.go_menu), scenario + " recovery button uses the menu route")
  var navigations = [0]
  game.go_menu(func(): navigations[0] += 1; return OK)
  check(navigations[0] == 1, scenario + " rejected load can navigate to the menu")
  check(get_meta("journey_save_path") == PATH, scenario + " menu keeps the same journey save path")
  check(snapshot() == original, scenario + " menu recovery preserves all source bytes and creates no save")
  game.go_menu(func(): return ERR_CANT_OPEN)
  check(snapshot() == original and game.blocked, scenario + " failed menu navigation also preserves the source")
  game.queue_free()
  await process_frame
 clean()
 set_meta("journey_save_path", "user://festival_v3.json")
 print("FESTIVAL RECOVERY: %d checks, %d failures" % [checks, failures])
 quit(1 if failures else 0)
