extends RefCounted

const COOLDOWN := 3.0
const FOODS := {"Corn": 15, "Roasted Corn": 30}
var textures := {}


func edible(item: String) -> bool:
	return FOODS.has(item)


func has_icon(item: String) -> bool:
	return edible(item) or item in ["Crop Seeds", "Corn Seed"]


func description(item: String) -> String:
	if edible(item):
		return "%s · Restores %d HP" % [item, int(FOODS[item])]
	return "Crop Seeds · Plant in tilled soil"


func best_food(inventory: Dictionary, selected: String) -> String:
	if edible(selected) and int(inventory.get(selected, 0)) > 0:
		return selected
	for item in ["Roasted Corn", "Corn"]:
		if int(inventory.get(item, 0)) > 0:
			return item
	return ""


func _ellipse(image: Image, rect: Rect2i, color: Color) -> void:
	var center := Vector2(rect.position) + Vector2(rect.size) * 0.5
	var radius := Vector2(rect.size) * 0.5
	for y in range(maxi(0, rect.position.y), mini(32, rect.end.y)):
		for x in range(maxi(0, rect.position.x), mini(32, rect.end.x)):
			var offset := (Vector2(x + 0.5, y + 0.5) - center) / radius
			if offset.length_squared() <= 1.0:
				image.set_pixel(x, y, color)


func _husk(image: Image, points: PackedVector2Array, color: Color) -> void:
	for y in range(32):
		for x in range(32):
			if Geometry2D.is_point_in_polygon(Vector2(x + 0.5, y + 0.5), points):
				image.set_pixel(x, y, color)


func texture_for(item: String) -> Texture2D:
	if textures.has(item):
		return textures[item]
	var image := Image.create(32, 32, false, Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	if item in ["Crop Seeds", "Corn Seed"]:
		# Match the Python icon's four separate golden kernels.
		for at in [Vector2i(8, 9), Vector2i(18, 7), Vector2i(12, 19), Vector2i(22, 20)]:
			_ellipse(image, Rect2i(at, Vector2i(6, 8)), Color("80552a"))
			_ellipse(image, Rect2i(at, Vector2i(5, 7)), Color("e8b83a"))
			_ellipse(image, Rect2i(at + Vector2i(1, 1), Vector2i(2, 4)), Color("ffe290"))
	else:
		var roasted := item == "Roasted Corn"
		_ellipse(image, Rect2i(9, 2, 14, 26), Color("68402b") if roasted else Color("70562c"))
		_ellipse(image, Rect2i(10, 3, 12, 24), Color("c67c35") if roasted else Color("e8b83a"))
		_ellipse(image, Rect2i(11, 4, 9, 21), Color("e7b252") if roasted else Color("f4c436"))
		for row in range(6):
			for col in range(3):
				var at := Vector2i(11 + col * 3, 6 + row * 3)
				image.fill_rect(Rect2i(at, Vector2i(2, 2)), Color("f6cf70") if roasted else Color("ffe468"))
				if roasted and (row * 3 + col) % 4 == 0:
					image.fill_rect(Rect2i(at, Vector2i(2, 2)), Color("74472d"))
		_husk(image, PackedVector2Array([Vector2(15, 29), Vector2(4, 14), Vector2(7, 26), Vector2(13, 31)]), Color("285d38"))
		_husk(image, PackedVector2Array([Vector2(16, 28), Vector2(3, 12), Vector2(9, 26)]), Color("48963a"))
		_husk(image, PackedVector2Array([Vector2(17, 30), Vector2(28, 14), Vector2(25, 27), Vector2(19, 31)]), Color("285d38"))
		_husk(image, PackedVector2Array([Vector2(18, 28), Vector2(28, 12), Vector2(23, 26)]), Color("70b54b"))
	textures[item] = ImageTexture.create_from_image(image)
	return textures[item]
