extends Control
## Reusable book-style two-character comic. Caller owns story, quest and save state.
const UI=preload("res://scripts/polish_ui.gd")
var portrait_left: TextureRect
var portrait_right: TextureRect
var balloon_left: TextureRect
var balloon_right: TextureRect
var left_line: Label
var right_line: Label
var speaker_text: Label
var names={"left":"Çatpat","right":"Porsuk"}
func build(heading: String, on_advance: Callable, left_name="Çatpat", right_name="Porsuk", left_portrait="res://assets/review-v2/catpat-idle-r2.png", right_portrait="res://assets/review-v2/badger-idle-r2.png", background_path="res://assets/chapter-v5/forest.png"):
	names={"left":left_name,"right":right_name}
	UI.texture(background_path,Rect2(0,0,1280,720),self)
	var shade=ColorRect.new();shade.color=Color(0.02,0.08,0.08,0.70);shade.size=Vector2(1280,720);add_child(shade)
	portrait_left=UI.texture(left_portrait,Rect2(100,295,390,418),self);portrait_left.flip_h=true
	portrait_right=UI.texture(right_portrait,Rect2(797,342,420,350),self)
	balloon_left=UI.texture("res://assets/polish-v3/balloon.png",Rect2(57,93,537,260),self)
	balloon_right=UI.texture("res://assets/polish-v3/balloon.png",Rect2(686,93,537,260),self);balloon_right.flip_h=true
	left_line=UI.label("",Rect2(104,143,434,136),27,self,Color("173d37"))
	right_line=UI.label("",Rect2(735,143,434,136),27,self,Color("173d37"))
	speaker_text=UI.label("",Rect2(438,438,410,42),22,self,Color("edc778"));speaker_text.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	UI.label(heading,Rect2(370,28,650,38),17,self,Color("b2d0c5"))
	UI.texture("res://assets/polish-v3/panel.png",Rect2(106,601,257,79),self)
	UI.label(left_name,Rect2(154,626,180,35),23,self)
	UI.texture("res://assets/polish-v3/panel.png",Rect2(913,601,257,79),self)
	UI.label(right_name,Rect2(962,626,180,35),23,self)
	UI.button("Devam",Rect2(494,610,293,62),self,on_advance,true)

func present(line: Dictionary) -> Label:
	left_line.visible_characters=-1;right_line.visible_characters=-1
	var active_label=left_line if line.side=="left" else right_line
	active_label.text=line.text;active_label.visible_characters=0
	balloon_left.visible=not left_line.text.is_empty();balloon_right.visible=not right_line.text.is_empty()
	speaker_text.text=names[line.side]
	portrait_left.modulate=Color.WHITE if line.side=="left" else Color(0.67,0.75,0.73)
	portrait_right.modulate=Color.WHITE if line.side=="right" else Color(0.67,0.75,0.73)
	return active_label
