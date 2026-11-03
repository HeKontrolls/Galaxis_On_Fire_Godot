extends SceneTree

const WG = preload("res://scripts/world_gen.gd")
const Farm = preload("res://scripts/farming.gd")
const Water = preload("res://scripts/water_sim.gd")
const Rain = preload("res://scripts/precipitation.gd")
const CaveEnvironment = preload("res://scripts/world_environment.gd")
const Ores = preload("res://scripts/ore_catalog.gd")
var failures := 0


func _initialize() -> void:
	call_deferred("run_check")


func check(ok: bool, label: String) -> void:
	if not ok:
		failures += 1
		printerr(label)


func total(values: PackedByteArray) -> int:
	var sum := 0
	for value in values:
		sum += value
	return sum


func sandbox() -> Dictionary:
	var grid := PackedByteArray()
	grid.resize(WG.WIDTH * WG.HEIGHT)
	for x in range(WG.WIDTH):
		WG.set_tile(grid, x, 80, 2)
	var surface := PackedInt32Array()
	surface.resize(WG.WIDTH)
	surface.fill(80)
	return {"tiles": grid, "surface": surface, "seed": 713, "climate": 0,
		"spawn": Vector2(600 * 16, 80 * 16 - 29), "creatures": [], "torches": {},
		"drops": [], "crops": {}, "placed_chests": {}}


func apply_edits(data: Dictionary, farm, edits: Array) -> void:
	var grid: PackedByteArray = data["tiles"]
	for edit in edits:
		WG.set_tile(grid, edit.x, edit.y, edit.z)
		farm.track(Vector2i(edit.x, edit.y), edit.z)
	data["tiles"] = grid


func check_python_parity() -> void:
	var cases: Array = JSON.parse_string(FileAccess.get_file_as_string("res://tests/python_farming_reference.json"))
	for fixture in cases:
		var data := sandbox()
		var grid: PackedByteArray = data["tiles"]
		WG.set_tile(grid, 3, 3, int(fixture["tile"]))
		WG.set_tile(grid, 3, 2, int(fixture["above"]))
		WG.set_tile(grid, 3, 4, int(fixture["below"]))
		data["tiles"] = grid
		var farm := Farm.new()
		farm.bind_world(data)
		var result := farm.interaction(Vector2i(3, 3), fixture["tool"], fixture["selected"])
		check(result["handled"] == fixture["handled"] and result["consume"] == fixture["consume"], "Python farming contract: " + fixture["name"])
		var actual := []
		for edit in result["edits"]:
			actual.append([edit.x, edit.y, edit.z])
		var expected := []
		for edit in fixture["edits"]:
			expected.append([int(edit[0]), int(edit[1]), int(edit[2])])
		check(actual == expected, "Python farming tile changes: " + fixture["name"])
		if not result["drops"].is_empty():
			check(result["drops"]["Corn"] >= 2 and result["drops"]["Corn"] <= 4 and result["drops"]["Crop Seeds"] >= 1 and result["drops"]["Crop Seeds"] <= 3,
				"Harvest must use the original randomized food and seed ranges")
	print("PYTHON_FARMING_PARITY cases=", cases.size())


func growth_score(wet: bool) -> int:
	var data := sandbox()
	var grid: PackedByteArray = data["tiles"]
	for x in range(552, 649):
		WG.set_tile(grid, x, 80, 13 if wet else 12)
		WG.set_tile(grid, x, 79, 14)
	data["tiles"] = grid
	var farm := Farm.new()
	farm.bind_world(data)
	var env := CaveEnvironment.new()
	env.reset(data)
	var water := Water.new()
	water.bind_world(data)
	for _second in range(90):
		apply_edits(data, farm, farm.advance(600, 1.0, false, env.roof, water.amounts))
	var score := 0
	grid = data["tiles"]
	for x in range(552, 649):
		score += WG.tile_at(grid, x, 79) - 14
	return score


func check_rain() -> void:
	var data := sandbox()
	var grid: PackedByteArray = data["tiles"]
	# A roof over a small indoor growing area.
	for x in range(595, 606):
		WG.set_tile(grid, x, 70, 9)
	for y in range(70, 80):
		WG.set_tile(grid, 594, y, 9)
		WG.set_tile(grid, 606, y, 9)
	data["tiles"] = grid
	var env := CaveEnvironment.new()
	env.reset(data)
	var water := Water.new()
	water.bind_world(data)
	var rain := Rain.new()
	rain.reset(713)
	for _tick in range(100):
		rain.update(600, 0.2, true, false, 1.0, env.roof, water)
		water.update(0.08)
	check(total(water.amounts) > 0 and total(water.rain_amounts) == total(water.amounts), "Rain must accumulate actual finite puddle water")
	var indoor := 0
	for x in range(595, 606):
		for y in range(71, 80):
			indoor += water.amount_at(Vector2i(x, y))
	check(indoor == 0 and water.amount_at(Vector2i(600, 69)) > 0, "Rain must land on roofs and keep indoor spaces dry")
	var before := total(water.amounts)
	for _second in range(300):
		rain.update(600, 1.0, false, false, 1.0, env.roof, water)
		water.update(0.08)
	check(total(water.amounts) == 0, "Rain puddles must completely evaporate after dry weather: %d -> %d" % [before, total(water.amounts)])
	var pool := sandbox()
	grid = pool["tiles"]
	WG.set_tile(grid, 600, 79, 4)
	pool["tiles"] = grid
	water.bind_world(pool)
	env.reset(pool)
	water.add_rain(Vector2i(600, 79), 20) # Full water cannot accept more volume.
	water.add_rain(Vector2i(601, 79), 20)
	for _tick in range(40):
		water.update(0.08)
	check(total(water.amounts) == 275 and total(water.rain_amounts) == 20, "Mixing and flowing must conserve natural and rainfall water separately")
	for _second in range(300):
		water.evaporate(env.roof, 2)
		water.update(0.08)
	check(total(water.amounts) == 255 and total(water.rain_amounts) == 0, "Evaporation must preserve all natural lake water")
	print("RAIN puddles, roofs, evaporation and mixed-water conservation checked")


func check_farm_weather() -> void:
	var data := sandbox()
	var grid: PackedByteArray = data["tiles"]
	for x in [580, 600, 620]:
		WG.set_tile(grid, x, 80, 12)
	WG.set_tile(grid, 580, 79, 14)
	WG.set_tile(grid, 600, 70, 9)
	data["tiles"] = grid
	var env := CaveEnvironment.new()
	env.reset(data)
	var water := Water.new()
	water.bind_world(data)
	var farm := Farm.new()
	farm.bind_world(data)
	var wet_outdoor := false
	var wet_indoor := false
	for _second in range(300):
		apply_edits(data, farm, farm.advance(600, 1.0, true, env.roof, water.amounts))
		wet_outdoor = wet_outdoor or WG.tile_at(data["tiles"], 580, 80) == 13
		wet_indoor = wet_indoor or WG.tile_at(data["tiles"], 600, 80) == 13
	check(wet_outdoor and not wet_indoor, "Rain must water planted outdoor soil while respecting constructed roofs")
	water.add_rain(Vector2i(620, 79), 50)
	for _second in range(100):
		apply_edits(data, farm, farm.advance(600, 1.0, false, env.roof, water.amounts))
	check(WG.tile_at(data["tiles"], 620, 80) == 13, "Puddles touching exposed tilled soil must water it after the rain ends")


func run_check() -> void:
	check_python_parity()
	var dry := growth_score(false)
	var wet := growth_score(true)
	check(wet > dry * 2, "Watered plants must grow faster: dry=%d wet=%d" % [dry, wet])
	print("GROWTH dry=", dry, " watered=", wet)
	check_rain()
	check_farm_weather()
	var game: Node2D = load("res://main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	await game._open_planet(0)
	game.set_process(false)
	game.save_path = "user://galaxis_rain_farm_check.json"
	game.world = sandbox()
	game.worlds[game._world_key()] = game.world
	game._reset_world_environment()
	game.world_texture = WG.make_texture(game.world["tiles"])
	game.world_image = game.world_texture.get_image()
	game.player_pos = game.world["spawn"]
	game._update_camera()
	game.inventory = {"Hoe": 1, "Watering Can": 1, "Crop Seeds": 2, "Dirt": 2}
	game._farm_interaction(Vector2i(601, 80), "Hoe", "Dirt")
	check(not game._farm_interaction(Vector2i(601, 80), "Hand", "Dirt"), "Planting must require selected seeds")
	game._farm_interaction(Vector2i(601, 80), "Watering Can", "Dirt")
	game._farm_interaction(Vector2i(601, 80), "Hand", "Crop Seeds")
	check(WG.tile_at(game.world["tiles"], 601, 79) == 14 and game.inventory["Crop Seeds"] == 1, "Planting consumes exactly one selected seed")
	game.inventory["Crop Seeds"] = 0
	game._edit_tile(Vector2i(602, 80), 12)
	game._farm_interaction(Vector2i(602, 80), "Hand", "Crop Seeds")
	check(WG.tile_at(game.world["tiles"], 602, 79) == 0, "Empty seed inventory must not create a plant")
	game.water_sim.add_rain(Vector2i(603, 79), 71)
	game.weather = "Clear"
	game.weather_blend.reset("Clear", int(game.world.get("climate", 0)))
	game._update_water(0.0)
	game._update_crops(1.0)
	var rng_state: int = game.farming.rng.state
	var rain_before := total(game.water_sim.rain_amounts)
	game._save_game()
	game._load_game()
	await process_frame
	check(WG.tile_at(game.world["tiles"], 601, 79) in [14, 15, 16] and WG.tile_at(game.world["tiles"], 601, 80) in [12, 13], "Crops and their tilled root must survive saving")
	check(game.farming.rng.state == rng_state and total(game.water_sim.rain_amounts) == rain_before, "Growth RNG and rainwater provenance must survive saving")
	game._edit_tile(Vector2i(601, 79), 16)
	game._farm_interaction(Vector2i(601, 79), "Hoe", "Crop Seeds")
	check(WG.tile_at(game.world["tiles"], 601, 79) == 0 and game.world["drops"].size() == 2, "Harvesting with the hoe must release corn and seeds as physical pickups")
	for id in [20, 21, 22, 23, 24]:
		var badge: Image = game.ores.image_for(id)
		check(badge.get_size() == Vector2i(16, 16), "Ore badge must fit the world tile scale")
	check(Ores.ELEMENTS[24]["symbol"] == "?" and game.ores.description("Crystal").contains("unknown"), "Alien crystal must retain its unknown element identity")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(game.save_path))
	print("RAIN_FARMING_ORE failures=", failures)
	quit(0 if failures == 0 else 1)
