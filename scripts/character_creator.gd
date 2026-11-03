extends RefCounted

const Appearance = preload("res://scripts/character_appearance.gd")
const NAME_RECT := Rect2(140, 579, 264, 39)
const SEED_RECT := Rect2(140, 650, 264, 39)
const CREATE_RECT := Rect2(937, 640, 198, 45)
const BACK_RECT := Rect2(728, 640, 190, 45)
const RANDOM_SEED_RECT := Rect2(310, 622, 94, 24)
const ROWS := {"hair": 222.0, "eyes": 292.0, "shirt": 350.0, "pants": 420.0, "shoes": 490.0, "skin": 560.0}
var appearance := Appearance.DEFAULT.duplicate()
var avatar := Appearance.new()
var action := "idle"
var facing := 1
var dirty := true


func reset(value: Dictionary = {}) -> void:
	appearance = Appearance.normalize(value)
	action = "idle"
	facing = 1
	dirty = true


func refresh() -> void:
	if dirty:
		avatar.configure(appearance)
		dirty = false


static func swatch_rect(category: String, index: int) -> Rect2:
	return Rect2(939 + (index % 6) * 31, ROWS[category] + (index / 6) * 27, 24, 23)


func palette(category: String) -> Array:
	var key := "clothing" if category in ["shirt", "pants", "shoes"] else category
	return Appearance.catalog()["palettes"][key]


func cycle(category: String, direction: int) -> void:
	var key := category + "_style"
	appearance[key] = posmod(int(appearance[key]) + direction, Appearance.option_count(key))
	dirty = true


func randomize_look() -> void:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	for key: String in appearance:
		if key == "model":
			appearance[key] = "male" if rng.randi_range(0, 1) == 0 else "female"
		else:
			appearance[key] = rng.randi_range(0, Appearance.option_count(key) - 1)
	dirty = true


func click(game, point: Vector2) -> void:
	if NAME_RECT.has_point(point):
		game.text_focus = "name"
		return
	if SEED_RECT.has_point(point):
		game.text_focus = "seed"
		return
	game.text_focus = ""
	if CREATE_RECT.has_point(point):
		game._start_new_game()
	elif BACK_RECT.has_point(point):
		game._menu_back()
	elif RANDOM_SEED_RECT.has_point(point):
		var rng := RandomNumberGenerator.new()
		rng.randomize()
		game.seed_text = str(rng.randi_range(1, 2147483646))
		game.text_focus = "seed"
	elif Rect2(939, 165, 186, 36).has_point(point):
		randomize_look()
	elif Rect2(527, 165, 140, 36).has_point(point):
		appearance["model"] = "male"
		dirty = true
	elif Rect2(678, 165, 140, 36).has_point(point):
		appearance["model"] = "female"
		dirty = true
	elif Rect2(157, 500, 105, 31).has_point(point):
		facing = -facing
	elif Rect2(273, 500, 113, 31).has_point(point):
		reset()
	else:
		for index in range(3):
			if Rect2(154 + index * 80, 456, 74, 31).has_point(point):
				action = ["idle", "walk", "jump"][index]
				return
		for category: String in ["hair", "shirt", "pants", "shoes"]:
			var y := float(ROWS[category]) + 7
			if Rect2(529, y, 34, 34).has_point(point):
				cycle(category, -1)
				return
			if Rect2(826, y, 34, 34).has_point(point):
				cycle(category, 1)
				return
		for category: String in ROWS:
			for index in range(palette(category).size()):
				if swatch_rect(category, index).has_point(point):
					var key := category + "_color" if category != "skin" else "skin"
					if category == "eyes":
						key = "eye_color"
					appearance[key] = index
					dirty = true
					return


func field(game, rect: Rect2, value: String, hint: String, active: bool) -> void:
	game._rounded_box(rect, Color("0b1728"), Color("ecc074") if active else Color("526e80"), 8.0)
	var shown := value if not value.is_empty() else hint
	while ThemeDB.fallback_font.get_string_size(shown, HORIZONTAL_ALIGNMENT_LEFT, -1, 16).x > rect.size.x - 27:
		shown = shown.substr(1)
	var caret := "|" if active and int(game.animation_clock * 2) % 2 == 0 else ""
	game._text(shown + caret, rect.position + Vector2(11, 26), 16, Color("e6eceb") if not value.is_empty() else Color("79939f"))


func arrow(game, rect: Rect2, label: String) -> void:
	game._rounded_box(rect, Color("182f3e"), Color("91b6d4"), 10.0)
	game._button_text(rect, label, 20)


func draw(game) -> void:
	refresh()
	game._draw_menu_panel(Rect2(118, 81, 1044, 623), "CREATE YOUR CAPTAIN")
	game._text("Choose your look, then chart a new galaxy.", Vector2(143, 142), 15, Color("abc2cd"))
	game._rounded_box(Rect2(140, 158, 264, 390), Color("122535"), Color("3d6171"), 13.0)
	game._text("APPEARANCE", Vector2(162, 190), 15, Color("b7d0d7"))
	game.draw_line(Vector2(160, 426), Vector2(384, 426), Color("517768"), 2)
	avatar.draw_preview(game, Vector2(190, 226), 5, action, game.animation_clock, facing)
	game._text("Preview", Vector2(162, 447), 13, Color("9cb4bc"))
	for index in range(3):
		var name: String = ["idle", "walk", "jump"][index]
		var rect := Rect2(154 + index * 80, 456, 74, 31)
		game._rounded_box(rect, Color("34535d") if action == name else Color("172e3c"), Color("d4b67e") if action == name else Color("466775"), 8.0)
		game._button_text(rect, name.capitalize(), 13)
	game._draw_menu_button(Rect2(157, 500, 105, 31), "Turn", true)
	game._draw_menu_button(Rect2(273, 500, 113, 31), "Reset", true)
	game._text("Name", Vector2(144, 568), 15, Color("bdd0d8"))
	field(game, NAME_RECT, game.new_game_name, "Captain name", game.text_focus == "name")
	game._text("Galaxy seed", Vector2(144, 639), 15, Color("bdd0d8"))
	game._rounded_box(RANDOM_SEED_RECT, Color("1b3545"), Color("638798"), 7.0, 1)
	game._button_text(RANDOM_SEED_RECT, "Random", 13)
	field(game, SEED_RECT, game.seed_text, "Blank = random galaxy", game.text_focus == "seed")
	game._text("Model", Vector2(442, 190), 16, Color("d3dfe1"))
	for index in range(2):
		var rect := Rect2(527 + index * 151, 165, 140, 36)
		var selected: bool = appearance["model"] == ["male", "female"][index]
		game._rounded_box(rect, Color("35545e") if selected else Color("162b3a"), Color("d4b67e") if selected else Color("476373"), 9.0)
		game._button_text(rect, ["Male", "Female"][index], 16)
	game._draw_menu_button(Rect2(939, 165, 186, 36), "Randomize", true)
	for category: String in ["hair", "eyes", "shirt", "pants", "shoes", "skin"]:
		var y := float(ROWS[category])
		game._text(category.capitalize(), Vector2(442, y + 30), 16, Color("cbdce0"))
		if category in ["hair", "shirt", "pants", "shoes"]:
			var styles: Array = Appearance.catalog()[category + "_styles"]
			arrow(game, Rect2(529, y + 7, 34, 34), "<")
			arrow(game, Rect2(826, y + 7, 34, 34), ">")
			var name: String = styles[int(appearance[category + "_style"])][1]
			game._text(name, Vector2(584, y + 30), 17, Color("ece6d5"))
			game._text(str(palette(category)[int(appearance[category + "_color"])]["name"]), Vector2(584, y + 50), 12, Color("98b4c0"))
		else:
			var choice := int(appearance["eye_color" if category == "eyes" else "skin"])
			game._text(str(palette(category)[choice]["name"]), Vector2(584, y + 30), 17, Color("ece6d5"))
		for index in range(palette(category).size()):
			var rect := swatch_rect(category, index)
			var key := category + "_color" if category != "skin" else "skin"
			if category == "eyes":
				key = "eye_color"
			var selected := int(appearance[key]) == index
			game._rounded_box(rect, Color(palette(category)[index]["color"]), Color("f5d286") if selected else Color("526876"), 5.0, 2.0 if selected else 1.0)
	game._text("Colors and styles are available for both models.", Vector2(442, 617), 13, Color("9cb6c2"))
	game._draw_menu_button(BACK_RECT, "Back", true)
	game._draw_menu_button(CREATE_RECT, "Create Galaxy", true)
