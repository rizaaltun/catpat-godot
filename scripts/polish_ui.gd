extends RefCounted
const BASE = "res://assets/polish-v3/"
static func font() -> FontVariation:
	var f=FontVariation.new();f.base_font=load("res://assets/fonts/Fredoka.ttf");f.fallbacks=[load("res://assets/fonts/Baloo2.ttf")];f.variation_opentype={2003265652:450.0}
	return f
static func texture(path: String, rect: Rect2, parent: Node) -> TextureRect:
	var t = TextureRect.new()
	t.texture = load(path)
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = TextureRect.STRETCH_SCALE
	t.position = rect.position
	t.size = rect.size
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(t)
	return t
static func label(text: String, rect: Rect2, font_size: int, parent: Node, color: Color=Color("fff5dd")) -> Label:
	var l = Label.new()
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.text = text
	l.add_theme_font_override("font",font())
	l.position = rect.position
	l.size = rect.size
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.add_theme_font_size_override("font_size",font_size)
	l.add_theme_color_override("font_color",color)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(l)
	return l
static func skin(amber: bool) -> StyleBoxTexture:
	var s = StyleBoxTexture.new()
	s.texture = load(BASE+ ("button.webp" if amber else "panel.webp"))
	# Art-only transparent padding excluded at runtime; original file remains intact.
	s.region_rect = Rect2(40,125,1970,490) if amber else Rect2(Vector2.ZERO,s.texture.get_size())
	for side in [SIDE_LEFT,SIDE_RIGHT]:
		s.set_texture_margin(side,0)
		s.set_content_margin(side,12)
	for side in [SIDE_TOP,SIDE_BOTTOM]:
		s.set_texture_margin(side,0)
		s.set_content_margin(side,10)
	return s
static func button(text: String, rect: Rect2, parent: Node, callback: Callable, amber:=false) -> Button:
	var b = Button.new()
	b.text = text
	b.add_theme_font_override("font",font())
	b.position = rect.position
	b.size = rect.size
	b.add_theme_font_size_override("font_size",23)
	for state in ["normal","hover","pressed","focus"]:
		var s=skin(amber)
		if state=="hover" or state=="focus": s.modulate_color=Color(1.12,1.12,1.06)
		if state=="pressed": s.modulate_color=Color(0.86,0.91,0.91)
		b.add_theme_stylebox_override(state,s)
	b.add_theme_color_override("font_color",Color("183d35") if amber else Color("fff5dd"))
	b.add_theme_color_override("font_hover_color",Color("183d35") if amber else Color.WHITE)
	b.add_theme_color_override("font_focus_color",Color("183d35") if amber else Color.WHITE)
	b.add_theme_color_override("font_pressed_color",Color("183d35") if amber else Color.WHITE)
	b.pressed.connect(callback)
	parent.add_child(b)
	return b
