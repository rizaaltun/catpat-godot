extends "res://scripts/polish_actor.gd"
func _build_frames():
	var frames=SpriteFrames.new();frames.remove_animation("default")
	var textures=[]
	for name in ["idle","step-a","step-b"]:
		var t=load("res://assets/chapter-v10/monkey-"+name+".png")
		var a=AtlasTexture.new();a.atlas=t;a.region=Rect2(Vector2.ZERO,t.get_size())
		# Foot roots verified per full source pose; final model approval remains pending.
		var roots={"idle":Vector2(590,1398),"step-a":Vector2(590,1392),"step-b":Vector2(590,1387)}
		a.margin=Rect2(Vector2(600,1400)-roots[name],Vector2(1400,1800)-t.get_size());textures.append(a)
	for key in ["idle","run","jump","fall","launch","celebrate"]:
		frames.add_animation(key);frames.set_animation_speed(key,7 if key=="run" else 3)
		for index in ([1,0,2,0] if key=="run" else [0]):frames.add_frame(key,textures[index])
	anim.sprite_frames=frames;anim.scale=Vector2.ONE*0.125;anim.position=Vector2(100,-500)*0.125
func _physics_process(delta):
	super._physics_process(delta)
	if absf(velocity.x)>10:anim.flip_h=velocity.x<0
