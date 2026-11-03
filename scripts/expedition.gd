extends RefCounted

const WG = preload("res://scripts/world_gen.gd")
const Art = preload("res://scripts/sprite_art.gd")
const CrashSite = preload("res://scripts/crash_site.gd")
const TITLES := ["Meet the robot", "Gather supplies", "Set up a workshop", "Shelter and food", "Copper equipment", "The buried signal", "Repair the escape pod", "A new horizon", "Expedition complete"]
const ADVICE := [
	["I am R0-VR. Our escape pod crashed; the main ship is still in orbit.", "Repair the pod's ascent drive so we can return to the ship."],
	["Gather 20 Wood. Use C for planks, sticks and a workbench.", "Place it, press F and craft a Wood Pickaxe; then mine 12 Stone."],
	["Place a workbench and furnace. Craft a Stone Pickaxe and Sword.", "Press F at a station; put ingredients into its own slots."],
	["Build a lit shelter and harvest your first corn crop.", "Use the hoe, plant seeds on tilled soil, then water it."],
	["Smelt copper with fuel; take the ingots from the furnace.", "Craft a Copper Pickaxe and Copper Sword at your workbench."],
	["An old drive core lies below us. A sentinel is guarding it.", "Bring an Iron Pickaxe, a sword, food and torches. Follow the signal."],
	["Craft 2 Hull Plates and 1 Drive Coil at your workbench.", "Return to the crashed pod and press F to install the parts."],
	["The pod is ready. Press G, or F beside it, to return to our ship.", "Choose another planet and land to begin your next expedition."],
	["You reached the orbiting ship. The galaxy is open to us now.", "Explore other climates for rarer ores and stronger equipment."]]
const PARTS := {"Hull Plate": 2, "Drive Coil": 1}
var g
var data: Dictionary = {}
var textures := {}
var folded := false
var budget := 0.0

func _init(game) -> void:
	g = game

func start() -> void:
	data = {"version": 1, "stage": 0, "home": "", "seen": {}, "gathered": {}, "placed": {}, "builds": {}, "shelter": false, "harvested": false, "core": false}
	folded = false

func active() -> bool:
	return not data.is_empty()

func stage() -> int:
	return clampi(int(data.get("stage", 0)), 0, 8)

func home() -> bool:
	return active() and str(data.get("home", "")) == g._world_key()

func can_land(index: int) -> bool:
	if g.dev_travel_unlocked or not active():
		return true
	if str(data.get("home", "")).is_empty():
		if g._planet_climate(index) != 0:
			g._show_notice("Begin on a Temperate forest planet: it has the supplies needed to repair the escape pod")
			return false
	elif stage() < 7 and "%d_%d" % [g.star_index, index] != str(data["home"]):
		g._show_notice("Repair the escape pod before travelling to another planet")
		return false
	return true

func can_launch() -> bool:
	if not g.dev_travel_unlocked and active() and stage() < 7:
		g._show_notice("Escape pod damaged - follow R0-VR's repair objectives")
		return false
	return true

func prepare() -> void:
	if g.dev_travel_unlocked or not active():
		return
	if not str(data.get("home", "")).is_empty():
		if home():
			prepare_pod()
			CrashSite.prepare(g, data)
		if stage() >= 7:
			data["carrier_world"] = g._world_key()
		if not home() and stage() == 7:
			data["stage"] = 8
		return
	data["home"] = g._world_key()
	var spawn: Vector2 = g.world["spawn"]
	var sx := clampi(int(spawn.x / 16) - 4, 8, WG.WIDTH - 9)
	data["ship"] = [sx * 16 + 8, g._walkable_y(sx)]
	data["carrier_world"] = data["home"]
	prepare_pod()
	CrashSite.prepare(g, data, true)
	spawn = g.world["spawn"]
	var cx := clampi(int(spawn.x / 16) + 76, 30, WG.WIDTH - 30)
	var floor_y := 0
	for x in range(cx - 9, cx + 10):
		floor_y = maxi(floor_y, int(g.world["surface"][x]) + 48)
	floor_y = mini(floor_y, WG.HEIGHT - 16)
	var grid: PackedByteArray = g.world["tiles"]
	# This room is only authored on the untouched first world of a new expedition.
	for y in range(floor_y - 8, floor_y + 2):
		for x in range(cx - 9, cx + 10):
			WG.set_tile(grid, x, y, 0 if y > floor_y - 8 and y < floor_y and x > cx - 9 and x < cx + 9 else 3)
			for fluid: String in ["water", "lava"]:
				if g.world.get(fluid, PackedByteArray()).size() == grid.size():
					g.world[fluid][y * WG.WIDTH + x] = 0
	g.world["tiles"] = grid
	data["site"] = [cx * 16 + 8, floor_y * 16]
	g.world["creatures"].append({"x": float(cx * 16 - 40), "y": float(floor_y * 16 - 18), "home_x": float(cx * 16), "direction": -1, "hp": 90, "max_hp": 90, "damage": 14, "alive": true, "quest_guardian": true})
	for x in [cx - 6, cx + 6]:
		g.world["torches"]["%d,%d" % [x, floor_y - 3]] = true

func record_item(item: String) -> void:
	if active() and not g.dev_travel_unlocked:
		data["seen"][item] = true

func gathered(item: String, count: int) -> void:
	if active() and not g.dev_travel_unlocked:
		data["gathered"][item] = int(data["gathered"].get(item, 0)) + count

func placed(item: String, tile: Vector2i) -> void:
	if g.dev_travel_unlocked or not home():
		return
	data["placed"][item] = true
	if item in ["Wood", "Planks", "Dirt", "Stone", "Cobblestone"] and not bool(data["shelter"]):
		data["builds"]["%d,%d" % [tile.x, tile.y]] = true

func update(delta: float) -> void:
	if g.dev_travel_unlocked or not active():
		return
	budget -= delta
	if budget > 0:
		return
	budget = 0.4
	for item in g.inventory:
		if int(g.inventory[item]) > 0:
			record_item(str(item))
	if not home() or bool(data["shelter"]) or data["builds"].size() < 12:
		return
	var built := 0
	var roof := false
	var head := Vector2i(floor((g.player_pos + Vector2(8, 0)) / 16))
	for key: String in data["builds"]:
		var xy := key.split(",")
		var tile := Vector2i(int(xy[0]), int(xy[1]))
		if WG.is_solid(WG.tile_at(g.world["tiles"], tile.x, tile.y)) and Vector2(tile).distance_to(Vector2(head)) <= 12:
			built += 1
			if tile.x == head.x and tile.y < head.y and tile.y >= head.y - 6:
				roof = true
	if built < 12 or not roof:
		return
	for key: String in g.world.get("torches", {}):
		var xy := key.split(",")
		if Vector2(int(xy[0]), int(xy[1])).distance_to(Vector2(head)) < 7:
			data["shelter"] = true
			data["builds"].clear()
			break

func seen(item: String) -> bool:
	return bool(data.get("seen", {}).get(item, false))

func goals() -> Array:
	match stage():
		0: return [["Talk to robot R0-VR [E / F]", false]]
		1: return [["Gather Wood %d/20" % mini(20, int(data["gathered"].get("Wood", 0))), int(data["gathered"].get("Wood", 0)) >= 20], ["Gather Stone %d/12" % mini(12, int(data["gathered"].get("Stone", 0))), int(data["gathered"].get("Stone", 0)) >= 12]]
		2: return [["Place a Workbench", data["placed"].get("Workbench", false)], ["Place a Furnace", data["placed"].get("Furnace", false)], ["Craft a Stone Pickaxe", seen("Stone Pickaxe")], ["Craft a Wood Sword", seen("Sword")]]
		3: return [["12 building blocks + roof + torch", data["shelter"]], ["Harvest a mature corn crop", data["harvested"]]]
		4: return [["Craft a Copper Pickaxe", seen("Copper Pickaxe")], ["Craft a Copper Sword", seen("Copper Sword")]]
		5: return [["Craft an Iron Pickaxe", seen("Iron Pickaxe")], ["Defeat the sentinel; recover core [F]", data["core"]]]
		6: return [["Drive core secured", data["core"]], ["Hull Plates %d/2" % mini(2, int(g.inventory.get("Hull Plate", 0))), int(g.inventory.get("Hull Plate", 0)) >= 2], ["Drive Coil %d/1" % mini(1, int(g.inventory.get("Drive Coil", 0))), int(g.inventory.get("Drive Coil", 0)) >= 1]]
		7: return [["Return to orbit [G / pod F], then explore", false]]
	return [["First voyage complete", true]]

func ready() -> bool:
	for goal: Array in goals():
		if not bool(goal[1]):
			return false
	return true

func talk() -> void:
	if g.dev_travel_unlocked:
		g._show_notice("Developer travel: turn Free Travel off in F3 to resume objectives")
		return
	update(1.0)
	if not g.dialogue_open:
		g.dialogue_open = true
		g._stop_held_actions()
		return
	if stage() == 0 or (stage() < 6 and ready()):
		data["stage"] = stage() + 1
		if stage() == 2:
			g._add_item("Torch", 4)
			g._show_notice("Supplies secured. R0-VR gave you 4 torches")
		elif stage() == 3:
			for item: String in ["Hoe", "Watering Can"]:
				g._add_item(item, 1)
			g._add_item("Crop Seeds", 6)
			for seed: String in ["Carrot Seeds", "Seed Potato", "Tomato Seeds", "Wheat Seeds"]:
				g._add_item(seed, 2)
			g._show_notice("R0-VR gave you farming tools and five seed types")
		else:
			g._show_notice("New objective: " + TITLES[stage()])
		g._refresh_hotbar()
	elif stage() <= 6:
		g._show_notice("Return to the escape pod with the repair parts" if stage() == 6 else "Finish the current objectives, then return to R0-VR")
	g.dialogue_open = false

func guardian_alive() -> bool:
	for creature: Dictionary in g.world.get("creatures", []):
		if bool(creature.get("quest_guardian", false)) and bool(creature["alive"]):
			return true
	return false

func point(key: String) -> Vector2:
	var value: Array = data.get(key, [0, 0])
	return Vector2(float(value[0]), float(value[1]))

func prepare_pod() -> void:
	# Keep the saved site and quest flags; accommodate the larger hull without editing terrain.
	if int(data.get("pod_layout_version", 0)) >= 1:
		return
	var at := point("ship")
	var floor_y := at.y
	for column in range(maxi(2, floori((at.x - 88) / 16)), mini(WG.WIDTH - 2, ceili((at.x + 88) / 16))):
		var ground: int = g._walkable_y(column)
		if ground > 0:
			floor_y = minf(floor_y, ground)
	data["ship"] = [at.x, floor_y]
	data["pod_layout_version"] = 1

func near_pod() -> bool:
	var center: Vector2 = g.player_pos + Vector2(8, 14)
	var bounds := Rect2(point("ship") - Vector2(96, 111), Vector2(192, 111))
	var closest := Vector2(clampf(center.x, bounds.position.x, bounds.end.x), clampf(center.y, bounds.position.y, bounds.end.y))
	return center.distance_to(closest) <= 64 and g.interactions._visible(center, Rect2(closest - Vector2(8, 8), Vector2(16, 16)))

func near(at: Vector2) -> bool:
	var center: Vector2 = g.player_pos + Vector2(8, 14)
	return center.distance_to(at - Vector2(0, 16)) <= 80 and g.interactions._visible(center, Rect2(at - Vector2(12, 30), Vector2(24, 30)))

func interact() -> bool:
	if g.dev_travel_unlocked or not home():
		return false
	if near(point("site")) and not bool(data["core"]):
		if guardian_alive():
			g._show_notice("Defeat the sentinel before recovering the drive core")
		else:
			data["core"] = true
			g._show_notice("Drive core recovered and secured for repairs. Return to R0-VR")
		return true
	if g.world.has("npc"):
		var guide: Dictionary = g.world["npc"]
		if Vector2(guide["x"], guide["y"]).distance_to(g.player_pos) <= 60:
			g._talk_to_explorer()
			return true
	if near_pod():
		if stage() >= 7:
			g._leave_planet()
		elif stage() == 6 and ready():
			for item: String in PARTS:
				g.inventory[item] -= PARTS[item]
			data["stage"] = 7
			g._refresh_hotbar()
			g._show_notice("Escape pod repaired! Press G to return to the ship in orbit")
		else:
			g._show_notice("Escape pod damaged. " + ("Bring 2 Hull Plates and 1 Drive Coil" if stage() == 6 else "Follow R0-VR's objectives"))
		return true
	if g.world.has("npc"):
		var npc: Dictionary = g.world["npc"]
		if Vector2(npc["x"], npc["y"]).distance_to(g.player_pos) <= 85:
			g._talk_to_explorer()
			return true
	return false

func guardian_ground(creature: Dictionary, x: float) -> int:
	var row := floori((float(creature["y"]) + 18) / 16)
	for y in range(maxi(2, row - 1), mini(WG.HEIGHT - 1, row + 4)):
		if WG.is_solid(WG.tile_at(g.world["tiles"], floori(x / 16), y)) and not WG.is_solid(WG.tile_at(g.world["tiles"], floori(x / 16), y - 1)):
			return y * 16
	return -1

func guardian_fits(at: Vector2) -> bool:
	for y in range(floori(at.y / 16), floori((at.y + 17) / 16) + 1):
		for x in range(floori(at.x / 16), floori((at.x + 23) / 16) + 1):
			if WG.is_solid(WG.tile_at(g.world["tiles"], x, y)):
				return false
	return true

func texture(name: String) -> Texture2D:
	if not textures.has(name):
		textures[name] = Art.texture("res://assets/sprites/expedition/" + name + ".png")
	return textures[name]

func draw_world() -> void:
	if not home():
		return
	var ship: Vector2 = point("ship") - g.camera_pos
	var pod := texture("ship_ready" if stage() >= 7 else "ship_damaged")
	g.draw_texture(pod, ship - Vector2(96, 111))
	if not bool(data["core"]):
		g.draw_texture(texture("drive_core"), point("site") - g.camera_pos - Vector2(16, 31))

func draw_orbital_ship() -> void:
	if not active() or str(data.get("home", "")).is_empty():
		return
	var location := str(data.get("carrier_world", data["home"])).split("_")
	if location.size() != 2 or int(location[0]) != g.star_index:
		return
	var planet := int(location[1])
	if planet < 0 or planet >= g.system_planets.size():
		return
	var center: Vector2 = g._system_planet_position(planet)
	var radius: float = float(g.system_planets[planet]["size"]) + 42.0
	var angle: float = g.animation_clock * 0.16
	var at := center + Vector2(cos(angle) * radius, sin(angle) * radius * 0.6)
	var orbit := PackedVector2Array()
	for i in range(65):
		var theta := TAU * i / 64.0
		orbit.append(center + Vector2(cos(theta) * radius, sin(theta) * radius * 0.6))
	g.draw_polyline(orbit, Color(0.5, 0.85, 0.9, 0.22), 1.0)
	g.draw_texture_rect(texture("orbital_ship"), Rect2(at - Vector2(36, 14), Vector2(72, 28)), false)
	g._text("Your ship - in orbit", at + Vector2(-48, -20), 12, Color("a6dfdf"))

func draw_sky_ship() -> void:
	if not active() or str(data.get("carrier_world", data.get("home", ""))) != g._world_key():
		return
	var visibility: float = g.biome_backgrounds.surface_visibility(g)
	if visibility <= 0:
		return
	var at := Vector2(fposmod(g.animation_clock * 5.0 + 318.0, 1400.0) - 60.0, 110 + sin(g.animation_clock * 0.025) * 24)
	g.draw_texture_rect(texture("orbital_ship"), Rect2(at, Vector2(36, 14)), false, Color(0.8, 0.9, 1.0, visibility * 0.8))

func hud_rect() -> Rect2:
	return Rect2(942, 170, 322, 32 if folded else 206)

func direction_to(at: Vector2) -> String:
	var delta: Vector2 = (at - g.player_pos) / 16
	return "%d blocks %s, %d %s" % [absi(roundi(delta.x)), "east" if delta.x >= 0 else "west", absi(roundi(delta.y)), "down" if delta.y >= 0 else "up"]

func draw_hud() -> void:
	if g.dev_travel_unlocked or not active():
		return
	var at := hud_rect().position
	g._rounded_box(hud_rect(), Color("101d27"), Color("617984"), 9.0, 1.0)
	g._text("EXPEDITION  %d/7" % mini(stage(), 7), at + Vector2(12, 22), 13, Color("e9c282"))
	g._text("J " + ("show" if folded else "hide"), at + Vector2(260, 22), 12, Color("b5c6d0"))
	if folded:
		return
	g._text(TITLES[stage()], at + Vector2(12, 49), 18)
	var row := 0
	for goal: Array in goals():
		g._text(("+ " if bool(goal[1]) else "- ") + str(goal[0]), at + Vector2(12, 74 + row * 22), 13, Color("9fd4a7") if bool(goal[1]) else Color("c6d6df"))
		row += 1
	if stage() == 1:
		g._text("Stone needs a Wood Pickaxe or better", at + Vector2(12, 126), 13, Color("c6d6df"))
	var hint := "Return to R0-VR [E / F]" if ready() and stage() < 6 else "R0-VR [E / F] for guidance"
	if home() and stage() == 5 and not bool(data["core"]):
		hint = direction_to(point("site"))
	elif home() and stage() in [6, 7]:
		hint = direction_to(point("ship"))
	g._text(hint, at + Vector2(12, 182), 13, Color("e9c282"))

func draw_dialogue(at: Vector2) -> void:
	g._text("R0-VR - " + TITLES[stage()], at + Vector2(25, 36), 22)
	for i in range(2):
		g._text(ADVICE[stage()][i], at + Vector2(25, 70 + i * 24), 16)
	var action := "Start expedition" if stage() == 0 else ("Complete objective" if stage() < 6 and ready() else "Close")
	g._rounded_box(Rect2(at + Vector2(25, 110), Vector2(280, 30)), Color("273e4a"), Color("9bb5bd"), 6.0)
	g._text(action + "  [E / F]", at + Vector2(37, 131), 15, Color("efca8d"))
