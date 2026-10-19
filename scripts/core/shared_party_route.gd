extends RefCounted
## AI owns only companion inputs. Player motion always belongs to the player.
var leader
var members=[]
var carriers=[]
var banks=[]
var edges=[]
var states=[]
var reservations=[-1,-1]
var destination_bank=0
var travel_direction=1
var paused=false
var time=0.0
var events=[]
var recovery_owners=[-1,-1,-1]
var recovery_entry_sides=[0,0,0]
static func recovery_points(bank:Vector2,index:int) -> Array:
	# The jump arc stays outside the upper parking bank until the final landing.
	var edge=bank.x+bank.y if index==0 else bank.x
	var outside=1.0 if index==0 else -1.0
	return [Vector2(edge+outside*120,790),Vector2(edge-outside*20,705),Vector2(edge+outside*100,620),Vector2(edge-outside*70,540)]
func configure(player,companions:Array,surfaces:Array,land:Array,gaps:Array):
	leader=player;members=companions;carriers=surfaces;banks=land;edges=gaps
	for a in members:
		a.controlled=true;a.recruited=false
		states.append({"phase":"bank","surface":-1,"side":1,"bank":0,"seat":90.0,"recover_bank":0,"step":-1,"cooldown":0.0})
func bank_of(a) -> int:
	if not a.is_on_floor() or absf(a.position.y-540)>5:return -1
	for i in banks.size():
		if a.position.x>=banks[i].x+20 and a.position.x<=banks[i].x+banks[i].y-20:return i
	return -1
func steer(a,target:float):
	a.input_axis=clampf((target-a.position.x)/35.0,-1,1) if absf(target-a.position.x)>3 else 0.0
	# Brake before another companion; ordering must never be fixed by walking through them.
	for other in members:
		if other==a or absf(other.position.y-a.position.y)>65:continue
		var dx=other.position.x-a.position.x
		if dx*a.input_axis>0 and absf(dx)<160:
			a.input_axis=signf(a.input_axis)*minf(absf(a.input_axis),clampf((absf(dx)-120)/40.0,0,1))
func release_recovery(i:int):
	for b in recovery_owners.size():
		if recovery_owners[b]==i:recovery_owners[b]=-1
func release(i:int):
	for k in reservations.size():
		if reservations[k]==i:reservations[k]=-1
	states[i].surface=-1
func set_paused(value:bool):
	paused=value
	for a in members:a.input_axis=0;a.jump_request=false;a.jump_held=false;a.jump_buffer=0
func update(delta:float):
	if paused:return
	time+=delta
	var goal=bank_of(leader)
	if goal>=0 and goal!=destination_bank:
		travel_direction=signi(goal-destination_bank);destination_bank=goal;events.append({"t":time,"event":"goal","bank":goal})
	for k in carriers.size():
		var s=carriers[k]
		if s.dwell<=0 or s.is_riding(leader) or members.any(func(a):return s.is_riding(a)):continue
		var dock=k if s.fraction<0.001 else k+1
		var demand=absf(leader.position.x-s.position.x)<280 and leader.position.y<620
		for a in members:
			if bank_of(a)==dock and ((destination_bank>dock and k==dock) or (destination_bank<dock and k==dock-1)):demand=true
		if not demand:s.dwell=minf(s.dwell,0.18)
	for i in members.size():
		var a=members[i];var st=states[i]
		a.input_axis=0;a.jump_request=false;a.jump_held=false;st.cooldown=maxf(0,st.cooldown-delta)
		var aboard=-1
		for k in carriers.size():
			if carriers[k].is_riding(a):aboard=k;break
		if aboard>=0 and st.phase not in ["board","ride","exit"]:
			if reservations[aboard] in [-1,i]:reservations[aboard]=i;st.surface=aboard;st.phase="ride"
		if st.phase in ["board","ride","exit"]:
			update_crossing(i,aboard)
			continue
		var b=bank_of(a)
		if b>=0:
			release_recovery(i)
			st.phase="bank";st.bank=b
			if b==destination_bank:park_on_bank(i,b)
			else:approach_crossing(i,b)
		elif a.position.y>560 or st.phase=="recover":recover(i)
func indices_on_bank(b:int) -> Array:
	var found=[]
	for i in members.size():
		if bank_of(members[i])==b and states[i].phase=="bank":found.append(i)
	found.sort_custom(func(a,b):return members[a].position.x<members[b].position.x)
	return found
func park_on_bank(i:int,b:int):
	var indices=indices_on_bank(b);var candidates=[]
	var keep_exit_clear=states.any(func(st):return st.phase=="recover" and st.recover_bank==b)
	var stair_exit=recovery_points(banks[b],b)[3].x
	var incoming_left=members.any(func(a):return bank_of(a)!=b and a.position.x<banks[b].x)
	var incoming_right=members.any(func(a):return bank_of(a)!=b and a.position.x>banks[b].x+banks[b].y)
	var x=banks[b].x+35
	while x<=banks[b].x+banks[b].y-35:
		var landing_clear=(not incoming_left or x>=banks[b].x+185) and (not incoming_right or x<=banks[b].x+banks[b].y-185)
		if landing_clear and (not keep_exit_clear or absf(x-stair_exit)>=135) and (bank_of(leader)!=b or absf(x-leader.position.x)>=155):candidates.append(x)
		x+=5
	# Pack in physical order, leaving room for the actual player position.
	# Both directions use the same silhouette gaps; choose the shorter walk.
	var options=[]
	for reverse in [false,true]:
		var ordered=candidates.duplicate()
		if reverse:ordered.reverse()
		var picked=[]
		for value in ordered:
			if picked.is_empty() or absf(value-picked[-1])>=160:picked.append(value)
			if picked.size()==indices.size():break
		if picked.size()==indices.size():
			picked.sort();options.append(picked)
	if options.is_empty():return
	var chosen=options[0];var best=INF
	for option in options:
		var cost=0.0
		for slot in indices.size():cost+=absf(members[indices[slot]].position.x-option[slot])
		if cost<best:best=cost;chosen=option
	var rank=indices.find(i)
	if rank>=0:steer(members[i],chosen[rank])
func approach_crossing(i:int,b:int):
	var side=1 if destination_bank>b else -1
	var k=b if side>0 else b-1
	var indices=indices_on_bank(b)
	if side>0:indices.reverse()
	var slot=indices.find(i)
	var waiting=edges[k].x-85-slot*150 if side>0 else edges[k].y+85+slot*150
	steer(members[i],waiting)
	if slot!=0 or reservations[k]!=-1:return
	var s=carriers[k];var origin=0.0 if side>0 else 1.0
	# A stopped carrier with an unfinished repair has no boarding reservation.
	if not s.enabled:return
	if absf(s.fraction-origin)>0.0001 or s.dwell<1.1:return
	# A player near the entry seat gets first use; no invisible player blocker.
	var seat=90.0*side
	if s.is_riding(leader):seat=-90.0 if leader.position.x>s.position.x else 90.0
	if s.is_riding(leader) and absf(s.position.x+seat-leader.position.x)<110:return
	reservations[k]=i;var st=states[i];st.phase="board";st.surface=k;st.side=side;st.seat=seat
	events.append({"t":time,"event":"reserve","actor":i,"surface":k,"side":side})
func update_crossing(i:int,aboard:int):
	var a=members[i];var st=states[i];var k=st.surface
	if k<0:return
	var s=carriers[k];var side=st.side
	var origin=k if side>0 else k+1
	var target=k+1 if side>0 else k
	if st.phase=="board":
		if destination_bank==origin and aboard<0:
			release(i);st.phase="bank";return
		if aboard<0 and absf(s.fraction-(0.0 if side>0 else 1.0))>0.01:
			release(i);st.phase="bank";return
		steer(a,s.position.x+st.seat)
		if aboard==k:st.phase="ride"
	elif st.phase=="ride":
		if aboard<0:
			release(i);st.phase="bank";return
		# Prefer the seat away from a freely boarding player.
		if s.is_riding(leader) and absf(a.position.x-leader.position.x)<115:
			st.seat=-90.0 if leader.position.x>s.position.x else 90.0
		steer(a,s.position.x+st.seat)
		var at_left=s.fraction<0.0001 and s.dwell>0.8
		var at_right=s.fraction>0.9999 and s.dwell>0.8
		# Reversal is resolved at a physical bank, never by actor repositioning.
		if (at_left and target==k) or (at_right and target==k+1):st.phase="exit"
		elif destination_bank==origin and ((at_left and origin==k) or (at_right and origin==k+1)):
			st.side=-side;st.phase="exit"
	elif st.phase=="exit":
		var x=edges[k].y+55 if st.side>0 else edges[k].x-55
		steer(a,x)
		var b=bank_of(a)
		if aboard<0 and b>=0:
			events.append({"t":time,"event":"arrive","actor":i,"bank":b});release(i);st.phase="bank";st.bank=b
		elif aboard<0 and a.position.y>560:
			release(i);st.phase="bank"
func recover(i:int):
	var a=members[i];var st=states[i]
	if st.phase!="recover":
		release(i);st.phase="recover";st.recover_bank=destination_bank;st.step=-1
	var steps=recovery_points(banks[st.recover_bank],st.recover_bank)
	if st.step<0:
		var b=st.recover_bank
		if a.position.y<850:
			# A genuine fall may land on any recovery ledge, not only the bottom.
			if a.is_on_floor() and recovery_owners[b] in [-1,i]:
				for step_index in 3:
					if absf(a.position.y-steps[step_index].y)<5 and absf(a.position.x-steps[step_index].x)<120:
						recovery_owners[b]=i;st.step=step_index+1;return
			# A ledge belonging to another bank must be physically walked off.
			steer(a,a.position.x+(220 if steps[0].x>=a.position.x else -220))
			return
		if recovery_entry_sides[b]==0:recovery_entry_sides[b]=-1 if a.position.x<steps[0].x else 1
		var waiting=[]
		for j in members.size():
			if states[j].phase=="recover" and states[j].recover_bank==b and states[j].step<0:waiting.append(j)
		waiting.sort_custom(func(first,second):return absf(members[first].position.x-steps[0].x)<absf(members[second].position.x-steps[0].x))
		var slot=waiting.find(i)
		if recovery_owners[b]!=i:
			var exit_clear=true
			for other in members:
				if other!=a and bank_of(other)==b and absf(other.position.x-steps[3].x)<130:exit_clear=false
			if recovery_owners[b]==-1 and slot==0 and exit_clear:recovery_owners[b]=i
			else:
				steer(a,steps[0].x+recovery_entry_sides[b]*150*(slot+1))
				return
		steer(a,steps[0].x)
		if a.is_on_floor() and absf(a.position.x-steps[0].x)<6 and absf(a.velocity.x)<15:st.step=0
		return
	var target=steps[st.step]
	steer(a,target.x);a.jump_held=true
	if a.is_on_floor() and absf(a.position.y-target.y)<5:
		st.step+=1;st.cooldown=0.15
		if st.step>=steps.size():st.phase="bank";a.jump_held=false
	elif a.is_on_floor() and st.cooldown<=0:
		a.jump_request=true;st.cooldown=0.25
