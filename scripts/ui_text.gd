extends RefCounted

static func layout(font: Font, text: String, box: Rect2, preferred: int = 18, centered: bool = true, padding: Vector2 = Vector2(8, 4)) -> Dictionary:
	var area := Rect2(box.position + padding, (box.size - padding * 2).max(Vector2.ONE))
	var size := preferred
	while size > 9 and (font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x > area.size.x or font.get_height(size) > area.size.y): size -= 1
	var shown := text
	while not shown.is_empty() and font.get_string_size(shown, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x > area.size.x:
		shown = shown.left(shown.length() - 1)
	if shown != text:
		while not shown.is_empty() and font.get_string_size(shown + "…", HORIZONTAL_ALIGNMENT_LEFT, -1, size).x > area.size.x: shown = shown.left(shown.length() - 1)
		shown += "…"
	var width := font.get_string_size(shown, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	var at := area.position + Vector2((area.size.x - width) * 0.5 if centered else 0.0, (area.size.y - font.get_height(size)) * 0.5 + font.get_ascent(size))
	return {"text": shown, "size": size, "at": at, "width": width, "area": area}

static func draw(canvas: CanvasItem, font: Font, text: String, box: Rect2, preferred: int = 18, color: Color = Color.WHITE, centered: bool = true, padding: Vector2 = Vector2(8, 4)) -> void:
	var fit := layout(font, text, box, preferred, centered, padding)
	canvas.draw_string(font, fit.at, fit.text, HORIZONTAL_ALIGNMENT_LEFT, -1, fit.size, color)
