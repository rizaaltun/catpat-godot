extends "res://scripts/core/comic_panel.gd"
## Scoped larger controls; original image assets and other chapters stay intact.
var advance_button: Button
var cancel_button: Button
var finish_caption=""
func setup(on_advance:Callable,on_cancel:Callable):
	build("RÜZGÂRLI YAMAÇ · YOL FENERİ",on_advance)
	for child in get_children():
		if child is Button:
			advance_button=child;child.position=Vector2(457,605);child.size=Vector2(366,88);child.add_theme_font_size_override("font_size",30)
	left_line.add_theme_font_size_override("font_size",30)
	right_line.add_theme_font_size_override("font_size",30)
	speaker_text.hide()
	cancel_button=UI.button("Yola dön",Rect2(985,20,255,88),self,on_cancel)
	cancel_button.add_theme_font_size_override("font_size",28)
	for style in ["normal","hover","pressed","focus"]:cancel_button.get_theme_stylebox(style).region_rect=Rect2(80,105,2010,520)
	# Heading must not share the close button's horizontal area.
	for child in get_children():
		if child is Label and child.text.begins_with("RÜZGÂRLI"):
			child.position=Vector2(90,35);child.size=Vector2(760,42);child.add_theme_font_size_override("font_size",25)
func show_line(line:Dictionary,last:bool):
	var label=present(line);label.visible_characters=-1
	advance_button.text=finish_caption if last and not finish_caption.is_empty() else "Birlikte yakalım" if last and line.get("final",false) else "Yola çıkalım" if last else "Devam"
func set_partner(partner:String,portrait:String,heading:String,caption:String="",mirror:bool=false):
	var previous=names.right;names.right=partner;portrait_right.texture=load(portrait);finish_caption=caption
	portrait_right.flip_h=mirror
	# Portraits are complete, fitted images, never cropped atlas cells.
	portrait_right.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	for child in get_children():
		if child is Label and child.text==previous:child.text=partner
		elif child is Label and child.text.begins_with("RÜZGÂRLI"):child.text=heading
