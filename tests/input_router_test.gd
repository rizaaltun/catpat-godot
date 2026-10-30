extends SceneTree
const Router = preload("res://scripts/core/input_router.gd")
var failures = 0
var checks = 0
func check(ok: bool, label: String):
 checks += 1
 if not ok: failures += 1
 print("PASS " if ok else "FAIL ", label)
func touch(index: int, point: Vector2, pressed := true) -> InputEventScreenTouch:
 var event = InputEventScreenTouch.new()
 event.index = index; event.position = point; event.pressed = pressed
 return event
func mouse(point: Vector2, emulated := true) -> InputEventMouseButton:
 var event = InputEventMouseButton.new()
 event.device = InputEvent.DEVICE_ID_EMULATION if emulated else 0
 event.button_index = MOUSE_BUTTON_LEFT; event.position = point; event.pressed = true
 return event
func _initialize():
 var router = Router.new()
 router.bind_controls(Rect2(0,0,100,100), Rect2(120,0,100,100), Rect2(240,0,100,100), Rect2(360,0,100,100))
 router.consume(touch(0, Vector2(50,50)))
 check(router.axis == -1, "real left finger owns movement")
 check(not router.consume(mouse(Vector2(50,50))), "emulated mouse is ignored")
 router.consume(touch(1, Vector2(170,50)))
 check(router.axis == 0 and router.owners.size() == 2, "opposing real fingers cancel without a duplicate owner")
 router.consume(touch(0, Vector2(50,50), false))
 check(router.axis == 1, "releasing left preserves the right finger")
 var canceled = touch(1, Vector2(170,50)); canceled.canceled = true
 router.consume(canceled)
 check(router.axis == 0 and router.owners.is_empty(), "canceled finger releases its control")
 router.consume(touch(2, Vector2(410,50)))
 check(router.interact_pressed, "real action touch emits an interaction")
 check(not router.consume(mouse(Vector2(410,50))) and not router.interact_pressed, "emulated click cannot repeat an interaction")
 router.reset()
 check(router.consume(mouse(Vector2(170,50), false)) and router.axis == 1, "real mouse remains usable")
 router.consume(touch(3, Vector2(290,50)))
 check(router.axis == 1 and router.jump_held, "jump finger can accompany another pointer")
 router.reset()
 check(router.owners.is_empty() and router.axis == 0 and not router.jump_held and not router.interact_pressed, "pause reset clears every control")
 print("INPUT ROUTER: %d checks, %d failures" % [checks, failures])
 quit(1 if failures else 0)
