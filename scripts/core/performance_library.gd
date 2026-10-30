extends RefCounted
## Reuse existing image poses only: no new drawing, mouth shape, viseme or rig.
const STATES=["talk","listen","help","celebrate","turn","land"]
static func character_id(label:String)->String:
 var key=label.to_lower().strip_edges()
 if key in ["çatpat","catpat"]:return "catpat"
 if key in ["porsuk","badger"]:return "badger"
 if key in ["maymun","monkey"]:return "monkey"
 if key in ["pıtpıt","pitpit","rabbit"]:return "rabbit"
 if key in ["narrator","anlatıcı","anlatici"]:return "narrator"
 return ""
static func speaker(line:Dictionary,names:Dictionary)->String:
 if line.has("speaker"):return character_id(str(line.speaker))
 return character_id(str(names.get(str(line.get("side","left")),"")))
static func source_path(texture:Texture2D)->String:
 var source=texture
 while source is AtlasTexture:source=source.atlas
 return source.resource_path if source else ""
static func action_path(id:String,_role:String="")->String:
 match id:
  "badger":return "res://assets/polish-v3/badger-pass.webp"
  "monkey":return "res://assets/chapter-v10/monkey-step-a.webp"
  "rabbit":return "res://assets/chapter-v12/rabbit-step-a.webp"
  "catpat":return "res://assets/polish-v3/catpat-pass.webp"
 return ""
static func find_source(frames:SpriteFrames,path:String,fallback:Texture2D)->Texture2D:
 for animation in frames.get_animation_names():
  for index in frames.get_frame_count(animation):
   var texture=frames.get_frame_texture(animation,index)
   if source_path(texture)==path:return texture
 return fallback
static func install(frames:SpriteFrames,id:String):
 if not frames.has_animation("idle") or frames.get_frame_count("idle")==0:return
 var idle=frames.get_frame_texture("idle",0)
 var action=find_source(frames,action_path(id),idle)
 # Only Porsuk has a supplied open-mouth/reaching image. Other talk states use
 # the neutral image and restrained attention motion; no lip animation is claimed.
 var talk=action if id=="badger" else idle
 for state in ["talk","listen","help","turn","land"]:
  if frames.has_animation(state):continue
  frames.add_animation(state)
  frames.set_animation_speed(state,5.0 if state=="help" else 3.0)
  frames.set_animation_loop(state,state in ["talk","listen"])
  var textures=[idle,action,idle] if state=="help" else [talk] if state=="talk" else [idle]
  for texture in textures:frames.add_frame(state,texture)
static func dialogue_texture(id:String,state:String,original:Texture2D)->Texture2D:
 # Canvas dimensions match within this existing family. No crop, resampling or
 # character synthesis occurs; custom/reference portraits retain their source.
 if id=="badger" and state=="talk" and source_path(original)=="res://assets/review-v2/badger-idle-r2.webp":
  return load(action_path(id,"talk"))
 return original
