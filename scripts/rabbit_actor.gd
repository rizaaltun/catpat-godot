extends "res://scripts/monkey_actor.gd"
func _build_frames():
	var frames=SpriteFrames.new();frames.remove_animation("default")
	var textures=[]
	var roots={"idle":Vector2(550,1415),"step-a":Vector2(550,1470),"step-b":Vector2(550,1415)}
	for name in ["idle","step-a","step-b"]:
		var t=load("res://assets/chapter-v12/rabbit-"+name+".webp")
		var a=AtlasTexture.new();a.atlas=t;a.region=Rect2(Vector2.ZERO,t.get_size())
		a.margin=Rect2(Vector2(600,1500)-roots[name],Vector2(1400,1800)-t.get_size());textures.append(a)
	for key in ["idle","run","jump","fall","launch","celebrate"]:
		frames.add_animation(key);frames.set_animation_speed(key,7 if key=="run" else 3)
		for i in ([1,0,2,0] if key=="run" else [0]):frames.add_frame(key,textures[i])
	anim.sprite_frames=frames;anim.scale=Vector2.ONE*0.125;anim.position=Vector2(100,-600)*0.125
