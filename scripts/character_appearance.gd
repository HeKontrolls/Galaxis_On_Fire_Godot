extends RefCounted

const Art = preload("res://scripts/sprite_art.gd")
const Pose = preload("res://scripts/player_pose.gd")
const ROOT := "res://assets/sprites/characters/"
const DEFAULT := {"model": "male", "skin": 0, "hair_style": 0, "hair_color": 0, "eye_color": 1,
	"shirt_style": 0, "shirt_color": 0, "pants_style": 1, "pants_color": 1, "shoes_style": 0, "shoes_color": 11}
static var metadata: Dictionary = {}
static var texture_cache := {}
static var cache_order: Array[String] = []
var appearance := {}
var layers: Array = []
var arms := {}


static func info() -> Dictionary:
	if metadata.is_empty():
		metadata = JSON.parse_string(FileAccess.get_file_as_string(ROOT + "avatar.json"))
	return metadata


static func catalog() -> Dictionary:
	return info()["catalog"]


static func normalize(value: Variant) -> Dictionary:
	var result := DEFAULT.duplicate()
	if not value is Dictionary:
		return result
	if value.get("model", "male") in catalog()["models"]:
		result["model"] = value.get("model", "male")
	for key: String in DEFAULT:
		if key == "model":
			continue
		var count := option_count(key)
		var raw: Variant = value.get(key, DEFAULT[key])
		if raw is int or raw is float:
			result[key] = clampi(int(raw), 0, count - 1)
	return result


static func option_count(key: String) -> int:
	if key.ends_with("_style"):
		return catalog()[key.trim_suffix("_style") + "_styles"].size()
	var palette := "clothing" if key in ["shirt_color", "pants_color", "shoes_color"] else key.trim_suffix("_color")
	if key == "eye_color":
		palette = "eyes"
	return catalog()["palettes"][palette].size()


static func sheet(path: String) -> Texture2D:
	if not texture_cache.has(path):
		texture_cache[path] = Art.texture(path)
		cache_order.append(path)
		if cache_order.size() > 64:
			texture_cache.erase(cache_order.pop_front())
	return texture_cache[path]


func configure(value: Dictionary) -> void:
	var cleaned := normalize(value)
	if cleaned == appearance and not layers.is_empty():
		return
	appearance = cleaned
	layers.clear()
	var hair: String = catalog()["hair_styles"][int(appearance["hair_style"])][0]
	var components := [["hair_" + hair + "_back", appearance["hair_color"]], ["skin", appearance["skin"]],
		["pants_" + str(catalog()["pants_styles"][int(appearance["pants_style"])][0]), appearance["pants_color"]],
		["shoes_" + str(catalog()["shoes_styles"][int(appearance["shoes_style"])][0]), appearance["shoes_color"]],
		["shirt_" + str(catalog()["shirt_styles"][int(appearance["shirt_style"])][0]), appearance["shirt_color"]],
		["eyes", appearance["eye_color"]], ["hair_" + hair + "_front", appearance["hair_color"]]]
	for component: Array in components:
		layers.append(sheet(ROOT + "%s/%s_%02d.png" % [appearance["model"], component[0], int(component[1])]))
	var row := (4 if appearance["model"] == "female" else 0) + int(appearance["shirt_style"])
	var solid := AtlasTexture.new()
	solid.atlas = sheet(ROOT + "solid_arms/skin_%02d_cloth_%02d.png" % [int(appearance["skin"]), int(appearance["shirt_color"])])
	solid.region = Rect2(0, row * 20, 8, 20)
	arms = {"solid_arm": solid}


static func animation(name: String) -> Dictionary:
	for entry: Dictionary in info()["animations"]:
		if str(entry["name"]) == name:
			return entry
	return info()["animations"][0]


static func frame_index(name: String, clock: float) -> int:
	var times: Array = animation(name)["durations"]
	var total := 0.0
	for seconds in times:
		total += float(seconds)
	var phase := fposmod(clock, total)
	for index in range(times.size()):
		phase -= float(times[index])
		if phase < 0:
			return index
	return 0


static func region(name: String, frame: int) -> Rect2:
	var data := animation(name)
	var index := int(data["first"]) + clampi(frame, 0, int(data["count"]) - 1)
	return Rect2((index % 10) * 32, (index / 10) * 40, 32, 40)


func draw_body(canvas: CanvasItem, at: Vector2, name: String, frame: int, tint: Color = Color.WHITE) -> void:
	var source := region(name, frame)
	for texture: Texture2D in layers:
		canvas.draw_texture_rect_region(texture, Rect2(at, Vector2(32, 40)), source, tint)


func draw_preview(canvas: CanvasItem, at: Vector2, scale: float, action: String, clock: float, facing: int = 1) -> void:
	var name := action + ("_east" if facing > 0 else "_west")
	var frame := frame_index(name, clock)
	var base := Transform2D(0, Vector2(scale, scale), 0, at)
	canvas.draw_set_transform_matrix(base)
	draw_body(canvas, Vector2.ZERO, name, frame)
	var shoulder := Vector2(19, 19)
	var hand := Vector2(24, 33)
	if facing < 0:
		shoulder.x = 32 - shoulder.x
		hand.x = 32 - hand.x
	canvas.draw_set_transform_matrix(base * Pose.arm_transform(shoulder, hand, facing))
	canvas.draw_texture(arms["solid_arm"], Vector2(-4, -1))
	canvas.draw_set_transform_matrix(Transform2D.IDENTITY)
