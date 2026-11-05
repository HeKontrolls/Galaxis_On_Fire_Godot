extends RefCounted

const Tools = preload("res://scripts/tool_catalog.gd")

# Coordinates, text, colors and actions ported from main.py debug helpers and
# systems/planet_render.py's DEBUG CONTROLS panel in the Python project.
const TABS := ["Weather", "Tools", "Farming", "Power", "Seasons", "Travel", "Magic"]
const WEATHER_KEYS := ["sunny", "cloudy", "rainy", "foggy", "snowy", "thunderstorm"]
const WEATHER_LABELS := ["Sunny", "Cloudy", "Rain", "Fog", "Snow", "Storm"]
const WEATHER_VALUES := ["Clear", "Cloudy", "Rain", "Fog", "Snow", "Storm"]
const SEASONS := ["Bloomrise", "Highsun", "Leafturn", "Frostfall"]
const STARTER_MATERIALS := {"Wood": 64, "Planks": 64, "Coal Ore": 64, "Copper Ore": 64,
	"Iron Ore": 64, "Gold Ore": 64, "Crystal": 64, "Chest": 2, "Furnace": 1, "Workbench": 1}
const STARTER_TOOLS := {"Pickaxe": 1, "Sword": 1, "Axe": 1, "Hammer": 1, "Torch": 64, "Wood Bow": 1, "Stone Arrow": 64}
const FARMING_KIT := {"Hoe": 1, "Watering Can": 1, "Crop Seeds": 32, "Carrot Seeds": 16, "Seed Potato": 16, "Tomato Seeds": 16, "Wheat Seeds": 16}
const POWER_KIT := {"Biomass Generator": 2, "Coal Generator": 1, "Fuel Generator": 1, "Wood Power Pole": 8, "Power Connector": 8, "Power Switch": 2, "Electric Lamp": 12, "Logic Input": 4, "Logic Output": 2, "NOT Gate": 2, "AND Gate": 2, "OR Gate": 2, "XOR Gate": 2, "NAND Gate": 2, "NOR Gate": 2, "RS NOR Latch": 2, "RS NAND Latch": 2, "T Flip-Flop": 2, "Wall Light": 6, "Ceiling Light": 6, "Floodlight": 4, "Red Signal Lamp": 4, "Wall Switch": 4, "Push Button": 4, "Pressure Plate": 4, "Daylight Sensor": 4, "Wire": 128, "Logic Wire": 128, "Raw Biomass": 32, "Coal Ore": 16, "Biofuel": 16, "Refined Fuel": 8}
const MAGIC_KIT := {"Ember Wand":1,"Frost Wand":1,"Storm Staff":1,"Crystal Staff":1,"Mending Tome":1,"Ward Book":1,"Greater Ward Book":1,"Lumen Tome":1,"Mana Tonic":8}
const ALCHEMY_KIT := {"Alchemy Desk":1,"Cauldron":1,"Blank Wand":4,"Blank Staff":4,"Blank Tome":4,"Fire Essence":16,"Frost Essence":16,"Storm Essence":16,"Life Essence":16,"Spirit Essence":16,"Arcane Ink":16,"Bone Fragment":16,"Soul Wand":1,"Grave Tome":1}
const YELLOW := Color("ffdc50")
var g
var font := SystemFont.new()
var active_tab := "weather"
var command_input := ""
var feedback := ""
var feedback_timer := 0.0
var slider_drag := ""
var selected_all := false
var item_catalog: Array[String] = []


func _init(game) -> void:
	g = game
	font.font_names = PackedStringArray(["Consolas"])
	if FileAccess.file_exists("res://assets/data/dev_item_catalog.json"):
		var parsed = JSON.parse_string(FileAccess.get_file_as_string("res://assets/data/dev_item_catalog.json"))
		if parsed is Array:
			for item in parsed:
				item_catalog.append(str(item))
	if item_catalog.is_empty():
		for item in g.ITEM_CATALOG + STARTER_TOOLS.keys() + STARTER_MATERIALS.keys() + FARMING_KIT.keys() + POWER_KIT.keys():
			if not item_catalog.has(str(item)):
				item_catalog.append(str(item))
		item_catalog.sort()
	for item in ["Corn", "Roasted Corn", "Obsidian", "Diamond", "Ancient Debris", "Netherite Scrap", "Netherite Ingot", "Glacial Ice", "Gravel"] + Tools.BASE_TOOLS + Tools.variants() + g.GroundLife.ITEMS + g.Furnishings.ITEMS + g.CropCatalog.ITEMS + g.Ranged.ITEMS + g.Melee.WEAPONS.keys() + g.EquipmentCatalog.ITEMS.keys() + g.PowerCatalog.ITEMS + g.MagicCatalog.ITEMS + g.SpellcraftCatalog.ITEMS:
		if not item_catalog.has(item):
			item_catalog.append(item)
	item_catalog.sort()


func opened() -> void:
	slider_drag = ""
	if g.dev_mode:
		command_input = ""
		if g.scene_name in ["galaxy", "system"]:
			active_tab = "travel"
			g.dev_travel_unlocked = true
		message("Free travel enabled; expedition paused." if g.dev_travel_unlocked else "Select a debug tab.", 3.0)


func update(delta: float) -> void:
	feedback_timer = maxf(0.0, feedback_timer - delta)


func message(value: String, seconds: float = 5.0) -> void:
	feedback = value
	feedback_timer = seconds


func _rect(local: Rect2) -> Rect2:
	return Rect2(Vector2(g.window_positions["dev"]) + local.position, local.size)


func tab_rect(index: int) -> Rect2:
	var width := 540.0 / TABS.size()
	return Rect2(10 + index * width, 38, width - 4, 30)


func travel_rect(climate: int) -> Rect2:
	return Rect2(10 + (climate % 2) * 274, 146 + int(climate / 2) * 44, 266, 38)


func _text(value: String, local: Vector2, color: Color = Color.WHITE) -> void:
	g.draw_string(font, Vector2(g.window_positions["dev"]) + local + Vector2(0, font.get_ascent(18) + 1),
		value, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, color)


func _center(value: String, rect: Rect2, color: Color = Color.WHITE) -> void:
	var size := font.get_string_size(value, HORIZONTAL_ALIGNMENT_LEFT, -1, 18)
	_text(value, rect.get_center() - Vector2(size.x, font.get_height(18)) * 0.5, color)


func _button(rect: Rect2, label: String, fill: Color, border: Color = Color.WHITE, radius: float = 6.0, centered: bool = false, offset: Vector2 = Vector2(8, 6)) -> void:
	g._rounded_box(_rect(rect), fill, border, radius, 1.0)
	g.UIText.draw(g, font, label, _rect(rect), 18, Color.WHITE, centered, Vector2(minf(offset.x, 10), 3))


func _slider(key: String, title: String, value: float, low: float, high: float, text: String, y: float) -> void:
	_text(title, Vector2(10, y - 8))
	var track := _rect(Rect2(170, y, 280, 10))
	var ratio := clampf((value - low) / (high - low), 0.0, 1.0)
	g._fill_rounded_rect(track, Color("1c2430"), 5.0)
	if ratio > 0.0:
		g._fill_rounded_rect(Rect2(track.position, Vector2(280 * ratio, 10)), Color("509bcd"), 5.0)
	var knob := track.position + Vector2(280 * ratio, 5)
	g.draw_circle(knob, 8, Color.WHITE)
	g.draw_arc(knob, 8, 0, TAU, 32, Color("0c121a"), 1.0)
	g._rounded_box(_rect(Rect2(476, y - 11, 70, 28)), Color("181c24"), Color.WHITE, 5.0, 1.0)
	_text(text, Vector2(482, y - 6))


func _apply_slider(key: String, x: float) -> void:
	var pct := clampf((x - float(g.window_positions["dev"].x) - 170.0) / 280.0, 0.0, 1.0)
	if key == "day_length":
		g.settings_data["day_length"] = roundf((60.0 + pct * 1740.0) / 30.0) * 30.0
	else:
		g.settings_data["night_dark"] = roundf(pct * 90.0) / 100.0
	message("Time sliders updated.", 1.0)


func handle_input(event: InputEvent) -> bool:
	if event is InputEventMouseMotion and slider_drag != "":
		_apply_slider(slider_drag, event.position.x)
		return true
	if event is InputEventMouseButton and not event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		slider_drag = ""
	if not event is InputEventKey or not event.pressed or active_tab != "tools":
		return false
	if event.keycode in [KEY_F3, KEY_ESCAPE] or (event.keycode == KEY_Q and event.shift_pressed and Input.is_key_pressed(KEY_R)):
		return false
	if event.ctrl_pressed or event.meta_pressed:
		match event.keycode:
			KEY_A: selected_all = true
			KEY_C: DisplayServer.clipboard_set(command_input)
			KEY_V:
				var paste := DisplayServer.clipboard_get().replace("\n", " ").replace("\r", " ")
				command_input = (("" if selected_all else command_input) + paste).left(120)
				selected_all = false
		return true
	match event.keycode:
		KEY_ENTER, KEY_KP_ENTER: run_command()
		KEY_TAB: autocomplete()
		KEY_BACKSPACE:
			command_input = "" if selected_all else command_input.left(maxi(0, command_input.length() - 1))
			selected_all = false
		_:
			if event.unicode >= 32 and event.unicode != 127:
				command_input = (("" if selected_all else command_input) + String.chr(event.unicode)).left(120)
				selected_all = false
	return true


func grant(bundle: Dictionary) -> void:
	for item in bundle:
		g._add_item(str(item), int(bundle[item]))


func _flat(value: String) -> String:
	return value.to_lower().replace(" ", "").replace("_", "").replace("-", "")


func resolve_item(value: String) -> String:
	var aliases := {"plank": "Planks", "cobble": "Cobblestone", "coal": "Coal Ore", "copper": "Copper Ore",
		"iron": "Iron Ore", "gold": "Gold Ore", "torches": "Torch", "wood pickaxe": "Pickaxe"}
	if aliases.has(value.strip_edges().to_lower()):
		return aliases[value.strip_edges().to_lower()]
	for item in item_catalog:
		if _flat(item) == _flat(value):
			return item
	return value.strip_edges()


func suggestions(limit: int = 7) -> Array[String]:
	var tokens := command_input.strip_edges().split(" ", false)
	var result: Array[String] = []
	if tokens.size() < 2 or tokens[0].to_lower().trim_prefix("/") != "give" or tokens[-1].is_valid_int():
		return result
	var query := " ".join(tokens.slice(1))
	if command_input.ends_with(" ") and item_catalog.has(resolve_item(query)):
		return result
	var starts: Array[String] = []
	var contains: Array[String] = []
	for item in item_catalog:
		if _flat(item).begins_with(_flat(query)):
			starts.append(item)
		elif _flat(item).contains(_flat(query)):
			contains.append(item)
	result = starts + contains
	return result.slice(0, limit)


func autocomplete() -> void:
	var matches := suggestions(1)
	if not matches.is_empty():
		var verb := command_input.strip_edges().get_slice(" ", 0)
		command_input = "%s %s " % [verb, matches[0]]
	selected_all = false


func run_command() -> void:
	var tokens := command_input.strip_edges().split(" ", false)
	command_input = ""
	selected_all = false
	if tokens.is_empty():
		return
	var verb := tokens[0].to_lower().trim_prefix("/")
	if verb in ["help", "?"]:
		message("Commands: give <item> <amount>, give alltools, give all starter", 8.0)
	elif verb != "give":
		message("Unknown command: " + tokens[0], 8.0)
	elif tokens.size() < 2:
		message("Usage: give <item> <amount> | give alltools | give all starter", 8.0)
	elif tokens.size() >= 3 and tokens[1].to_lower() == "all" and tokens[2].to_lower() in ["starter", "start", "materials", "mats"]:
		grant(STARTER_MATERIALS)
		message("Gave starter bundle (10/10 stacks).", 8.0)
	elif tokens[1].to_lower() in ["alltools", "tools", "starter"]:
		grant(STARTER_TOOLS)
		message("Gave starter tools + Torch x64 (4 tools).", 8.0)
	else:
		var count := 1
		if tokens.size() >= 3 and tokens[-1].is_valid_int():
			count = clampi(int(tokens[-1]), 1, 9999)
			tokens.resize(tokens.size() - 1)
		var item := resolve_item(" ".join(tokens.slice(1)))
		g._add_item(item, count)
		message("Gave %s x%d." % [item, count], 8.0)


func calendar() -> Dictionary:
	var day := maxi(1, int(g.day_count))
	var season_index := int((day - 1) / 14) % 4
	var year := int((day - 1) / 56) + 1
	var day_in_season := (day - 1) % 14 + 1
	return {"season_index": season_index, "season": SEASONS[season_index], "year": year,
		"day_in_season": day_in_season, "date_label": "Y%d %s %d" % [year, SEASONS[season_index], day_in_season]}


func weather_profile() -> Dictionary:
	var climate: int = g._planet_climate(g.planet_index)
	var weights := [0.24, 0.26, 0.24, 0.08, 0.08, 0.10]
	if climate == 3:
		weights = [0.58, 0.20, 0.08, 0.03, 0.08, 0.03]
	elif climate in [6, 7]:
		weights = [0.20, 0.20, 0.10, 0.02, 0.18, 0.30]
	elif climate in [1, 2]:
		weights = [0.16, 0.26, 0.30, 0.14, 0.08, 0.06]
	elif climate in [4, 5]:
		weights = [0.36, 0.28, 0.14, 0.06, 0.10, 0.06]
	match int(calendar()["season_index"]):
		0:
			weights[2] *= 1.45
			weights[4] *= 1.20
			weights[0] *= 0.90
			weights[5] = 0.0
		1:
			weights[0] *= 1.55
			weights[3] *= 1.15
			weights[5] = 0.0
			weights[4] *= 0.75
		2:
			weights[1] *= 1.35
			weights[2] *= 1.20
			weights[4] *= 1.25
		3:
			weights[5] *= 1.90
			weights[1] *= 1.20
			weights[2] *= 0.70
			weights[0] *= 0.72
			weights[3] *= 0.55
	var profile := {}
	var keys := ["Clear", "Cloudy", "Rain", "Storm", "Fog", "Snow"]
	var total := 0.0
	for weight in weights:
		total += weight
	for i in range(keys.size()):
		profile[keys[i]] = float(weights[i]) / total
	return profile


func click(point: Vector2) -> void:
	if _rect(Rect2(530, 6, 22, 22)).has_point(point):
		g.dev_mode = false
		g.dragged_window = ""
		slider_drag = ""
		return
	for i in range(TABS.size()):
		if _rect(tab_rect(i)).has_point(point):
			active_tab = TABS[i].to_lower()
			return
	if _rect(Rect2(2, 2, 522, 32)).has_point(point):
		g._start_window_drag("dev", point)
		return
	match active_tab:
		"travel":
			if _rect(Rect2(10, 82, 260, 32)).has_point(point):
				var enabled: bool = not g.dev_travel_unlocked
				# Exit a test landing before restoring locks on an unfinished campaign.
				if not enabled and g.scene_name == "planet" and g.expedition.active() and g.expedition.stage() < 7 and not g.expedition.home():
					g._leave_planet()
				g.dev_travel_unlocked = enabled
				message("Free travel enabled; expedition paused." if g.dev_travel_unlocked else "Expedition travel rules restored.")
				return
			if _rect(Rect2(284, 82, 266, 32)).has_point(point):
				g.dev_travel_unlocked = true
				g.dev_mode = false
				g.dragged_window = ""
				if g.scene_name == "planet": g._leave_planet()
				elif g.scene_name == "galaxy": g._open_system(g.star_index)
				return
			for climate in range(g.WG.NAMES.size()):
				if _rect(travel_rect(climate)).has_point(point):
					g._dev_visit_climate(climate)
					return
		"weather":
			for entry in [["day_length", 94], ["night_dark", 132]]:
				if _rect(Rect2(159, int(entry[1]) - 13, 302, 36)).has_point(point):
					slider_drag = entry[0]
					_apply_slider(slider_drag, point.x)
					return
			for i in range(6):
				if _rect(Rect2(10 + (i % 3) * 92, 182 + int(i / 3) * 34, 84, 26)).has_point(point):
					g.weather = WEATHER_VALUES[i]
					g.weather_timer = 0.0
					message("Weather set to %s." % WEATHER_LABELS[i], 3.0)
					return
		"tools":
			if _rect(Rect2(10, 92, 210, 30)).has_point(point):
				g.dev_invulnerable = not g.dev_invulnerable
				if g.dev_invulnerable:
					g.health = 100
				message("God Mode %s." % ("enabled" if g.dev_invulnerable else "disabled"), 3.0)
			elif _rect(Rect2(230, 92, 250, 30)).has_point(point):
				g.dev_free_flight = not g.dev_free_flight
				message("Free Flight %s." % ("enabled" if g.dev_free_flight else "disabled"), 3.0)
			elif _rect(Rect2(10, 138, 210, 34)).has_point(point):
				grant(STARTER_TOOLS)
				message("Granted starter tools (%d stacks)." % STARTER_TOOLS.size())
			elif _rect(Rect2(230, 138, 250, 34)).has_point(point):
				grant(STARTER_MATERIALS)
				message("Granted starter materials (10/10 stacks).")
		"farming":
			if _rect(Rect2(10, 100, 330, 36)).has_point(point):
				grant(FARMING_KIT)
				message("Farming kit ready (3/3 stacks).")
		"magic":
			if _rect(Rect2(10,100,330,36)).has_point(point):
				grant(MAGIC_KIT);grant(ALCHEMY_KIT);g.magic.mana=g.magic.max_mana();message("Magic and alchemy kit ready. K opens the skill tree.")
			elif _rect(Rect2(10,230,330,36)).has_point(point):
				for school:String in g.MagicCatalog.SCHOOLS:g.magic.xp[school]=300.0
				for node:String in g.SpellcraftCatalog.NODES:
					if g.spellcraft.can_learn(node):g.spellcraft.learn(node)
				g.magic.mana=g.magic.max_mana();message("All research unlocked for testing.")
		"power":
			if _rect(Rect2(10, 100, 330, 36)).has_point(point):
				grant(POWER_KIT)
				message("Power and logic kit ready (%d stacks)." % POWER_KIT.size())
		"seasons":
			for i in range(4):
				if _rect(Rect2(10 + i * 132, 112, 122, 36)).has_point(point):
					var cal := calendar()
					g.day_count = (int(cal["year"]) - 1) * 56 + i * 14 + int(cal["day_in_season"])
					g.weather_timer = 0.0
					message("Season changed to %s." % SEASONS[i], 4.0)
					return
			for i in range(2):
				if _rect(Rect2(10 + i * 160, 168, 150, 34)).has_point(point):
					g.day_count = maxi(1, int(g.day_count) + (-1 if i == 0 else 1))
					g.weather_timer = 0.0
					message("Calendar day set to %d." % int(g.day_count), 4.0)


func draw() -> void:
	g.draw_rect(_rect(Rect2(0, 0, 560, 390)), Color.BLACK, true)
	g.draw_rect(_rect(Rect2(1, 1, 558, 388)), Color.WHITE, false, 2.0)
	_text("DEBUG CONTROLS", Vector2(10, 10), YELLOW)
	var mouse: Vector2 = g.get_viewport().get_mouse_position()
	var close := Rect2(530, 6, 22, 22)
	_button(close, "X", Color("963737") if _rect(close).has_point(mouse) else Color("6e2a2a"), Color.WHITE, 5.0, true)
	for i in range(TABS.size()):
		var rect := tab_rect(i)
		var active: bool = active_tab == TABS[i].to_lower()
		_button(rect, TABS[i], Color("28587a") if active else (Color("222a36") if _rect(rect).has_point(mouse) else Color("161a22")),
			Color("a5dcff") if active else Color("6e7887"), 5.0, true)
	match active_tab:
		"travel":
			_button(Rect2(10, 82, 260, 32), "Free Travel: " + ("ON" if g.dev_travel_unlocked else "OFF"), Color("26703e") if g.dev_travel_unlocked else Color("34262a"))
			_button(Rect2(284, 82, 266, 32), "Return to Orbit" if g.scene_name == "planet" else "Browse This System", Color("263e58"))
			g._button_text(_rect(Rect2(10, 118, 540, 25)), "System: " + str(g.star_names[g.star_index]), 16, Color("b8d3e0"), false)
			for climate in range(g.WG.NAMES.size()):
				var rect := travel_rect(climate)
				_button(rect, str(g.WG.NAMES[climate]), Color("28587a") if _rect(rect).has_point(mouse) else Color("172632"))
			g._button_text(_rect(Rect2(10, 325, 540, 22)), "Choose a type to land. Turn free travel off to resume objectives.", 14, Color("b6cabb"), false)
		"weather":
			_slider("day_length", "Day Length", float(g.settings_data["day_length"]), 60, 1800, "%.0fs" % float(g.settings_data["day_length"]), 94)
			_slider("night_dark", "Night Darkness", float(g.settings_data["night_dark"]), 0, 0.9, "%.2f" % float(g.settings_data["night_dark"]), 132)
			var index := WEATHER_VALUES.find(str(g.weather))
			_text("Current weather: " + (WEATHER_KEYS[index] if index >= 0 else str(g.weather).to_lower()), Vector2(10, 158))
			for i in range(6):
				var active: bool = str(g.weather) == WEATHER_VALUES[i]
				_button(Rect2(10 + (i % 3) * 92, 182 + int(i / 3) * 34, 84, 26), WEATHER_LABELS[i],
					Color("225276") if active else Color("161c24"), Color("a5dcff") if active else Color.WHITE, 5.0, false, Vector2(8, 5))
			var biomes := ["forest", "coast", "ocean", "desert", "volcanic", "rocky", "snow", "tundra"]
			_text("Biome: " + biomes[g._planet_climate(g.planet_index)], Vector2(10, 260))
			_text("Next roll: %.1fs | Storm chance: %.0f%%" % [80.0 - float(g.weather_timer), float(weather_profile()["Storm"]) * 100.0], Vector2(10, 282))
		"tools":
			for i in range(2):
				var enabled: bool = g.dev_invulnerable if i == 0 else g.dev_free_flight
				_button(Rect2(10 + i * 220, 92, 210 if i == 0 else 250, 30), "%s: %s" % ["God Mode" if i == 0 else "Free Flight", "ON" if enabled else "OFF"],
					Color("26703e") if enabled else Color("34262a"), Color("96ffaf") if enabled else Color("e19696"))
			_button(Rect2(10, 138, 210, 34), "Grant Starter Tools", Color("263e58"), Color.WHITE, 6.0, false, Vector2(8, 7))
			_button(Rect2(230, 138, 250, 34), "Grant Starter Materials", Color("263e58"), Color.WHITE, 6.0, false, Vector2(8, 7))
			_text("Command: give <item> <amount>", Vector2(10, 190), YELLOW)
			g.draw_rect(_rect(Rect2(10, 212, 540, 26)), Color("0c0c0c"), true)
			g.draw_rect(_rect(Rect2(10, 212, 540, 26)).grow(-0.5), Color.WHITE, false, 1.0)
			var shown := command_input + ("|" if int(g.animation_clock * 2) % 2 == 0 else "")
			while font.get_string_size(shown, HORIZONTAL_ALIGNMENT_LEFT, -1, 18).x > 525:
				shown = shown.substr(1)
			_text(shown, Vector2(16, 216), Color("a5dcff") if selected_all else Color.WHITE)
			var matches := suggestions(5)
			for i in range(matches.size()):
				_text(matches[i], Vector2(16, 243 + i * 19), Color.WHITE if i == 0 else Color("becddc"))
		"farming":
			_text("Farming test setup", Vector2(10, 82), YELLOW)
			_text("Grants farming tools and all five seed types.", Vector2(10, 110))
			var rect := Rect2(10, 100, 330, 36)
			_button(rect, "Grant Farming Test Kit", Color("2a5c36") if _rect(rect).has_point(mouse) else Color("1c3a26"), Color.WHITE, 6.0, false, Vector2(10, 8))
		"magic":
			_text("Magic test setup",Vector2(10,82),YELLOW)
			_button(Rect2(10,100,330,36),"Grant Magic Test Kit",Color("354568"),Color.WHITE,6.0)
			_text("Mana: %.0f / %.0f | K: skill and spell guide" % [g.magic.mana,g.magic.max_mana()],Vector2(10,158))
			_text("K: skill tree | F at desk / cauldron: create spells.",Vector2(10,190))
			_button(Rect2(10,230,330,36),"Unlock magic research (testing)",Color("4a3e5b"))
		"power":
			_text("Power system test setup", Vector2(10, 82), YELLOW)
			var power: Dictionary = g.world.get("power", {})
			_text("Placed nodes: %d | Grids: %d" % [power.get("nodes", {}).size(), power.get("grids", []).size()], Vector2(10, 110))
			var rect := Rect2(10, 100, 330, 36)
			_button(rect, "Grant Power Test Kit", Color("485c7e") if _rect(rect).has_point(mouse) else Color("263248"), Color.WHITE, 6.0, false, Vector2(10, 8))
			_text("Place devices, equip Wire, then right-click two terminals.", Vector2(10, 158), Color("a5bdc9"))
		"seasons":
			var cal := calendar()
			_text("Current: " + str(cal["date_label"]), Vector2(10, 82), YELLOW)
			for i in range(4):
				var active: bool = cal["season"] == SEASONS[i]
				_button(Rect2(10 + i * 132, 112, 122, 36), SEASONS[i], Color("4a5e3a") if active else Color("222a30"),
					Color("cdeba0") if active else Color.WHITE, 6.0, true)
			_button(Rect2(10, 168, 150, 34), "Previous Day", Color("2a3646"), Color.WHITE, 6.0, false, Vector2(10, 7))
			_button(Rect2(170, 168, 150, 34), "Next Day", Color("2a3646"), Color.WHITE, 6.0, false, Vector2(10, 7))
			_text("Changing season updates weather probabilities immediately.", Vector2(10, 224), Color("a5bdc9"))
	if not feedback.is_empty() and feedback_timer > 0.0:
		var shown_feedback := feedback
		while font.get_string_size(shown_feedback, HORIZONTAL_ALIGNMENT_LEFT, -1, 18).x > 540:
			shown_feedback = shown_feedback.left(shown_feedback.length() - 2) + "…"
		_text(shown_feedback, Vector2(10, 356), Color("78ff78"))
