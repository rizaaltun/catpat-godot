extends Node2D
## B01 image-art projections only. No collision, collection or progress writes.
const GLOW_PATH="res://assets/runtime/effects/catpat_b05_lantern_glow_v001.png"
const SHADOW_PATH="res://assets/runtime/effects/catpat_shared_ground_shadow_v001.png"
var effect_time=0.0
var mote_sprites:Array[Sprite2D]=[]
var firefly_sprites:Array[Sprite2D]=[]
var shadow_sprites:Array[Sprite2D]=[]
var lantern_glows:Array[Sprite2D]=[]
var exit_glow:Sprite2D
var mote_origins:Array=[]
var firefly_origins:Array=[]
func sprite(path:String,width:float,id:String,depth:int)->Sprite2D:
 var image=Sprite2D.new();image.name=id;image.texture=load(path)
 image.scale=Vector2.ONE*width/maxf(1.0,image.texture.get_width())
 image.z_index=depth;add_child(image);return image
func configure(motes:Array,fireflies:Array):
 mote_origins=motes.duplicate();firefly_origins=fireflies.duplicate()
 for i in motes.size():mote_sprites.append(sprite(GLOW_PATH,40.0,"B01Mote%d"%i,-1))
 for i in fireflies.size():firefly_sprites.append(sprite(GLOW_PATH,6.0,"B01Firefly%d"%i,-1))
 for i in 2:
  var shadow=sprite(SHADOW_PATH,58.0,"B01GroundShadow%d"%i,-2)
  shadow.modulate.a=0.42;shadow_sprites.append(shadow)
 for i in 3:
  var glow=sprite(GLOW_PATH,310.0,"B01LanternGlow%d"%i,-2)
  glow.modulate.a=0.24;lantern_glows.append(glow)
 exit_glow=sprite(GLOW_PATH,340.0,"B01ExitGlow",-2)
 exit_glow.position=Vector2(3669,472);exit_glow.modulate.a=0.26
func update_projection(lit:Array,gathered:Array,lanterns:Array,completed:bool,actors:Array,active:bool,reduced_motion:bool,delta:float):
 if active and not reduced_motion:effect_time+=delta
 for i in mote_sprites.size():
  var mote=mote_sprites[i]
  mote.visible=i<gathered.size() and not gathered[i]
  mote.position=mote_origins[i]+Vector2(0,0 if reduced_motion else sin(effect_time*2.0+i)*5.0)
 for i in shadow_sprites.size():
  var shadow=shadow_sprites[i]
  var actor=actors[i] if i<actors.size() else null
  shadow.visible=is_instance_valid(actor) and actor.is_on_floor()
  if is_instance_valid(actor):shadow.position=actor.position+Vector2(0,3)
 for i in firefly_sprites.size():
  var firefly=firefly_sprites[i]
  firefly.visible=not reduced_motion
  firefly.position=firefly_origins[i]+Vector2(sin(effect_time*0.45+i)*14.0,cos(effect_time*0.6+i)*10.0)
  firefly.modulate.a=0.25+0.23*sin(effect_time+i)
 for i in lantern_glows.size():
  lantern_glows[i].visible=i<lit.size() and lit[i]
  if i<lanterns.size():lantern_glows[i].position=lanterns[i].glow
 exit_glow.visible=completed
