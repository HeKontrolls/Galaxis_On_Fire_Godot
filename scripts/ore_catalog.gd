extends RefCounted

const Art = preload("res://scripts/sprite_art.gd")
const NATURAL := {20: "coal", 21: "copper", 22: "iron", 23: "gold", 24: "crystal", 25: "diamond", 26: "ancient_debris"}
const ADVANCED := {"Diamond": "diamond", "Ancient Debris": "ancient_debris", "Netherite Scrap": "netherite_scrap", "Netherite Ingot": "netherite_ingot"}
var terrain_images := {}


func terrain_image_for(id: int, variation: int) -> Image:
	var key := Vector2i(id, posmod(variation, 4))
	if not terrain_images.has(key):
		terrain_images[key] = Art.texture("res://assets/sprites/expansion/ores/%s_%02d.png" % [NATURAL[id], key.y]).get_image()
	return terrain_images[key]

const ELEMENTS := {
	20: {"symbol": "C", "number": "6", "name": "Carbon", "color": Color("59616c")},
	21: {"symbol": "Cu", "number": "29", "name": "Copper", "color": Color("c68b58")},
	22: {"symbol": "Fe", "number": "26", "name": "Iron", "color": Color("aab7c3")},
	23: {"symbol": "Au", "number": "79", "name": "Gold", "color": Color("e0bf55")},
	24: {"symbol": "?", "number": "?", "name": "Alien crystal / unknown element", "color": Color("a785d6")},
}
const ITEMS := {"Coal Ore": 20, "Copper Ore": 21, "Copper Ingot": 21, "Iron Ore": 22,
	"Iron Ingot": 22, "Gold Ore": 23, "Gold Ingot": 23, "Crystal": 24}
const GLYPHS := {
	"0": ["111", "101", "101", "101", "111"], "1": ["010", "110", "010", "010", "111"],
	"2": ["111", "001", "111", "100", "111"], "3": ["111", "001", "111", "001", "111"],
	"4": ["101", "101", "111", "001", "001"], "5": ["111", "100", "111", "001", "111"],
	"6": ["111", "100", "111", "101", "111"], "7": ["111", "001", "010", "010", "010"],
	"8": ["111", "101", "111", "101", "111"], "9": ["111", "101", "111", "001", "111"],
	"C": ["111", "100", "100", "100", "111"], "u": ["000", "000", "101", "101", "111"],
	"F": ["111", "100", "110", "100", "100"], "e": ["000", "111", "101", "110", "111"],
	"A": ["010", "101", "111", "101", "101"], "?": ["111", "001", "010", "000", "010"],
}
var images := {}
var textures := {}


func has_item(item: String) -> bool:
	return ITEMS.has(item) or ADVANCED.has(item)


func description(item: String) -> String:
	if ADVANCED.has(item):
		return "Diamond - Carbon C 6" if item == "Diamond" else item + " - unknown alloy" if item.begins_with("Netherite") else "Ancient Debris - smelt into netherite scrap"
	if not ITEMS.has(item):
		return item
	var info: Dictionary = ELEMENTS[ITEMS[item]]
	return "%s · %s %s" % [item, info["symbol"], info["number"]] if ITEMS[item] != 24 else "Alien Crystal · element unknown"


func _letters(image: Image, value: String, at: Vector2i, scale: int, color: Color) -> void:
	var cursor := at
	for letter in value:
		var rows: Array = GLYPHS.get(letter, GLYPHS["?"])
		for y in range(5):
			for x in range(3):
				if rows[y][x] == "1":
					image.fill_rect(Rect2i(cursor + Vector2i(x, y) * scale, Vector2i.ONE * scale), color)
		cursor.x += 4 * scale


func image_for(id: int, size: int = 16) -> Image:
	var key := Vector2i(id, size)
	if images.has(key):
		return images[key]
	var info: Dictionary = ELEMENTS[id]
	var image := Image.create(size, size, false, Image.FORMAT_RGBA8)
	image.fill(Color("101821"))
	var tint: Color = info["color"]
	image.fill_rect(Rect2i(1, 1, size - 2, size - 2), tint.darkened(0.35))
	image.fill_rect(Rect2i(1, 1, size - 2, 1), tint.lightened(0.25))
	image.fill_rect(Rect2i(1, 1, 1, size - 2), tint)
	if size == 16:
		_letters(image, str(info["number"]), Vector2i(2, 2), 1, tint.lightened(0.55))
		var text: String = info["symbol"]
		_letters(image, text, Vector2i(int((size - (text.length() * 4 - 1)) / 2), 9), 1, Color("fff4da"))
	else:
		_letters(image, str(info["number"]), Vector2i(3, 3), 1, tint.lightened(0.55))
		var text: String = info["symbol"]
		_letters(image, text, Vector2i(int((size - (text.length() * 4 - 1) * 2) / 2), 15), 2, Color("fff4da"))
	images[key] = image
	return image


func texture_for(item: String) -> Texture2D:
	if ADVANCED.has(item):
		if not textures.has(item):
			textures[item] = Art.texture("res://assets/sprites/expansion/materials/%s_00.png" % ADVANCED[item])
		return textures[item]
	var id: int = ITEMS[item]
	if not textures.has(id):
		textures[id] = ImageTexture.create_from_image(image_for(id, 32))
	return textures[id]
