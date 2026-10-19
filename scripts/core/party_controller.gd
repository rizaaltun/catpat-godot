extends RefCounted
## One companion prototype: preserved V6 land trail + carrier boarding/ride state.
var trail: Array[Vector2]=[]
var player
var companion
var level
var carrier
var state="follow"
var board_count=0
var ride_count=0
var seat_side=-1.0
var yield_direction=1.0
var yield_count=0
func configure(p,c,l,m):player=p;companion=c;level=l;carrier=m;reset()
func reset():
	trail.clear();state="follow"
	if is_instance_valid(companion):
		trail.append(companion.position);trail.append(player.position)
		companion.route_carrier=false;companion.route_air_direction=0;companion.route_moving=false
func set_state(value: String):
	if value==state:return
	state=value
	if state=="board":board_count+=1
	if state=="ride":ride_count+=1
func update():
	if not companion.recruited:return
	companion.route_walk_only=level.bridges_open
	var player_on=carrier.is_riding(player)
	# A jump for the light above the deck is not an instruction to disembark.
	if state in ["board","ride"] and not player.is_on_floor() and player.position.y<carrier.position.y-2 and absf(player.position.x-carrier.position.x)<130:player_on=true
	var friend_on=carrier.is_riding(companion)
	companion.route_carrier=false
	if player_on and friend_on and state!="yield":
		var dx=companion.position.x-player.position.x
		if absf(dx)<100 and player.velocity.x*dx>0 and absf(player.velocity.x)>30:
			set_state("yield");yield_count+=1;yield_direction=signf(dx)
	if state=="yield":
		if friend_on or not companion.is_on_floor():
			companion.route_carrier=true
			companion.route_target=Vector2(carrier.position.x+yield_direction*135,carrier.position.y)
			companion.route_moving=true;return
		reset()
	if player_on:
		companion.route_carrier=true
		if state not in ["board","ride"]:seat_side=-1.0 if player.position.x>=carrier.position.x else 1.0
		var slot=carrier.position.x+seat_side*62
		if friend_on:
			set_state("ride")
			companion.route_target=Vector2(slot,carrier.position.y)
			companion.route_moving=absf(companion.position.x-slot)>12
		else:
			set_state("board")
			# Lead the slowly moving carrier during the flight, within its safe interior.
			companion.route_target=Vector2(slot+carrier.direction*18,carrier.position.y)
			companion.route_moving=true
		return
	if state in ["board","ride"]:
		# Stop chasing stale elevated waypoints when the leader has left the carrier.
		reset();set_state("disembark")
	if state=="disembark" and companion.is_on_floor() and not friend_on and absf(companion.position.y-level.ground_y(companion.position.x))<3:set_state("follow")
	if trail.is_empty() or player.position.distance_to(trail[-1])>16:trail.append(player.position)
	while trail.size()>1:
		var passed=companion.route_air_direction!=0 and (companion.position.x-trail[0].x)*companion.route_air_direction>0
		if companion.position.distance_to(trail[0])<55 or absf(companion.position.x-trail[0].x)<35 or passed:trail.pop_front()
		else:break
	var length=companion.position.distance_to(trail[0])
	for i in range(trail.size()-1):length+=trail[i].distance_to(trail[i+1])
	companion.route_target=Vector2(trail[0].x,minf(level.ground_y(trail[0].x),companion.position.y))
	companion.route_moving=length>110
	if state=="disembark":companion.route_carrier=true
	if friend_on:
		# Walk to the leader's side and drop onto the fixed safe bank; no edge jump.
		companion.route_carrier=true
		var sign_to_leader=signf(player.position.x-companion.position.x)
		if sign_to_leader==0:sign_to_leader=1
		companion.route_target=Vector2(carrier.position.x+sign_to_leader*125,carrier.position.y)
		companion.route_moving=true
	if trail.size()>500:trail.pop_front()
