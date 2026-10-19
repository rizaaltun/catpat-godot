extends RefCounted
## One passenger reservation. Waiting and exit actors walk under normal physics.
var carrier
var actors=[]
var order=[]
var side=1
var index=0
var phase="idle"
var enabled=true
var elapsed=0.0
var arrival_times=[]
var completed=[]
var parked=[]
var error=""
# Injected geometry; defaults retain the exact V14 station positions.
var left_edge=700.0
var right_edge=1040.0
var spacing=140.0
var park_depth=460.0
var left_park_depth=540.0
func set_stations(left:float,right:float,distance_between_members=140.0):
	left_edge=left;right_edge=right;spacing=distance_between_members
	park_depth=40.0+maxi(0,actors.size()-1)*spacing;left_park_depth=park_depth
func waiting_anchor(slot:int) -> float:
	return left_edge-100.0-slot*spacing if side>0 else right_edge+100.0+slot*spacing
func parking_anchor(slot:int) -> float:
	return right_edge+park_depth-slot*spacing if side>0 else left_edge-left_park_depth+slot*spacing
func configure(surface, members: Array):
	carrier=surface;actors=members
	for a in actors:a.controlled=true;a.recruited=false
func begin(travel_side: int) -> bool:
	if phase not in ["idle","done"] or travel_side not in [-1,1]:return false
	if not carrier.at_end(0 if travel_side>0 else 1):return false
	side=travel_side;order=actors.duplicate()
	order.sort_custom(func(a,b):return a.position.x>b.position.x if side>0 else a.position.x<b.position.x)
	index=0;phase="board";elapsed=0;arrival_times.clear();completed.clear();parked.clear();error=""
	return true
func steer(a, x: float):
	a.input_axis=clampf((x-a.position.x)/35.0,-1.0,1.0) if absf(x-a.position.x)>3 else 0.0
	a.jump_held=false;a.jump_request=false
func update(delta: float):
	if not enabled or phase in ["idle","done","error"]:return
	elapsed+=delta
	for a in actors:a.input_axis=0;a.jump_request=false
	for slot in range(index+1,order.size()):
		steer(order[slot],waiting_anchor(slot-index))
	if phase=="return" and index<order.size():steer(order[index],waiting_anchor(0))
	for slot in completed.size():
		var a=completed[slot];var target=parking_anchor(slot)
		steer(a,target)
		if absf(a.position.x-target)<5 and absf(a.velocity.x)<5 and a.is_on_floor() and not a in parked:parked.append(a)
	if index>=order.size():
		if parked.size()==actors.size():
			for member in actors:member.input_axis=0;member.jump_request=false
			phase="done"
		return
	var a=order[index]
	var origin=0 if side>0 else 1
	var destination=1-origin
	if phase=="return":
		if carrier.at_end(origin):phase="board"
		else:return
	if phase=="board":
		if not carrier.at_end(origin):error="carrier_not_at_origin";phase="error";return
		steer(a,carrier.position.x)
		if carrier.is_riding(a) and absf(a.position.x-carrier.position.x)<10 and absf(a.velocity.x)<20:
			a.input_axis=0;phase="ride";carrier.depart()
	elif phase=="ride":
		if carrier.at_end(destination):phase="exit"
	elif phase=="exit":
		steer(a,right_edge+60 if side>0 else left_edge-60)
		if not carrier.is_riding(a) and a.is_on_floor() and ((a.position.x>right_edge+30) if side>0 else (a.position.x<left_edge-30)):
			completed.append(a);arrival_times.append(elapsed);index+=1
			if index<order.size():phase="return";carrier.depart()
			else:phase="parking"
func set_paused(value: bool):
	enabled=not value;carrier.paused=value
	for a in actors:
		a.frozen=value;a.input_axis=0;a.jump_request=false;a.jump_buffer=0
