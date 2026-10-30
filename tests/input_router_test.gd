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
func drag(index: int, point: Vector2) -> InputEventScreenDrag:
 var event = InputEventScreenDrag.new()
 event.index = index; event.position = point
 return event
func mouse_motion(point: Vector2, emulated := false, held := true) -> InputEventMouseMotion:
 var event = InputEventMouseMotion.new()
 event.device = InputEvent.DEVICE_ID_EMULATION if emulated else 0
 event.position = point; event.button_mask = MOUSE_BUTTON_MASK_LEFT if held else 0
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
 router.consume(touch(10, Vector2(50,50)))
 router.consume(touch(11, Vector2(290,50)))
 router.consume(drag(10, Vector2(124,50)))
 check(router.axis == -1 and router.jump_held, "drag within24 units preserves the original control and another finger")
 router.consume(drag(10, Vector2(125,50)))
 check(router.axis == 0 and router.jump_held, "drag more than24 units outside cancels only that finger")
 router.consume(drag(10, Vector2(170,50)))
 check(router.axis == 0 and not router.owners.has(10), "drag cannot transfer to another control")
 router.consume(drag(10, Vector2(50,50)))
 check(router.axis == 0, "dragging back cannot reacquire a canceled control")
 router.consume(touch(10, Vector2(50,50), false))
 router.consume(touch(10, Vector2(170,50)))
 check(router.axis == 1 and router.jump_held, "fresh touch after release acquires the new control")
 router.consume(touch(12, Vector2(500,50)))
 router.consume(drag(12, Vector2(50,50)))
 check(not router.owners.has(12), "touch begun outside controls cannot acquire by dragging in")
 router.consume(drag(11, Vector2(500,50)))
 check(not router.jump_held and router.axis == 1, "jump drag cancellation preserves independent movement")
 router.consume(touch(13, Vector2(410,50)))
 router.consume(drag(13, Vector2(415,50)))
 check(not router.interact_pressed, "dragging an action finger never repeats the interaction")
 router.reset()
 router.consume(mouse(Vector2(50,50), false))
 router.consume(mouse_motion(Vector2(124,50)))
 check(router.axis == -1, "real mouse drag uses the same24 unit tolerance")
 router.consume(mouse_motion(Vector2(125,50)))
 check(router.axis == 0 and router.owners.is_empty(), "real mouse leaving its original region cancels ownership")
 router.consume(mouse_motion(Vector2(170,50)))
 check(router.axis == 0, "real mouse motion cannot transfer or reacquire")
 router.consume(mouse(Vector2(170,50), false))
 router.consume(mouse_motion(Vector2(500,50), true))
 check(router.axis == 1, "emulated mouse motion cannot cancel a real mouse owner")
 router.consume(mouse_motion(Vector2(170,50), false, false))
 check(router.axis == 0 and router.owners.is_empty(), "mouse motion without a held button releases stale ownership")
 print("INPUT ROUTER: %d checks, %d failures" % [checks, failures])
 quit(1 if failures else 0)
