extends SceneTree

const WG = preload("res://scripts/world_gen.gd")
const Life = preload("res://scripts/ground_life.gd")
const Water = preload("res://scripts/water_sim.gd")
var failures := 0


func _initialize() -> void:
	call_deferred("run_check")


func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		printerr(message)


func check_basins(data: Dictionary) -> void:
	for basin: Dictionary in data["surface_basins"]:
		var left := int(basin["left"])
		var right := int(basin["right"])
		var line := int(basin["waterline"])
		var water := 0
		var ice := 0
		for x in range(left + 1, right):
			var floor_y: int = data["surface"][x]
			for y in range(line, floor_y):
				var tile := WG.tile_at(data["tiles"], x, y)
				water += 1 if tile == 4 else 0
				ice += 1 if tile == 6 else 0
				if basin["kind"] != "dry_basin":
					check(tile in [4, 6], "Natural pond must fill to a single level without holes")
			for y in range(floor_y, floor_y + 8):
				check(WG.is_solid(WG.tile_at(data["tiles"], x, y)), "Pond and dry-basin floors need sealed natural support")
		check(WG.is_solid(WG.tile_at(data["tiles"], left, line)) and WG.is_solid(WG.tile_at(data["tiles"], right, line)),
			"Both banks must contain water at the waterline")
		check(right < WG.WIDTH / 2 - 55 or left > WG.WIDTH / 2 + 55, "Basins must preserve the landing area")
		check(water > 0 if basin["kind"] != "dry_basin" else water == 0, "Wet basins need water; dry lake beds must start empty")
		if basin["kind"] == "frozen_pond":
			check(ice > 0, "Tundra ponds need an ice lid")


func check_rock_regions() -> void:
	# Identical natural support in all four regions isolates distribution from slopes.
	for climate in range(8):
		var grid := PackedByteArray()
		grid.resize(WG.WIDTH * WG.HEIGHT)
		var surface := PackedInt32Array()
		surface.resize(WG.WIDTH)
		surface.fill(80)
		var biomes := PackedByteArray()
		biomes.resize(WG.WIDTH)
		for x in range(WG.WIDTH):
			WG.set_tile(grid, x, 80, 3)
			biomes[x] = x / (WG.WIDTH / 4)
		var data := {"tiles": grid, "surface": surface, "climate": climate, "seed": 713,
			"biomes": biomes, "ground_life": [], "spawn": Vector2(600 * 16, 80 * 16 - 28)}
		var tile_before := grid.duplicate()
		Life.populate_surface_rocks(data, surface)
		var counts := [0, 0, 0, 0]
		for rock: Dictionary in data["ground_life"]:
			var x := floori(float(rock["x"]) / 16)
			counts[biomes[x]] += 1
			check(rock["species"] in Life.ROCKS and absi(x - 600) >= 14, "Rock pass must choose rocks and protect the player area")
		for count: int in counts:
			check(count > 3, "Every climate and surface biome must be eligible for scattered rocks")
		var original: Array = data["ground_life"].duplicate(true)
		data["ground_life"][0]["alive"] = false
		Life.populate_surface_rocks(data, surface)
		check(data["ground_life"].size() == original.size() and not data["ground_life"][0]["alive"] and grid == tile_before,
			"Rock visits must preserve harvested rocks without respawning or modifying terrain")
		if climate == 0:
			# Simulate a pre-update save, a stone roof and a one-block excavation.
			data["surface_rocks_version"] = 0
			var roof := surface.duplicate()
			for x in range(100, 141):
				WG.set_tile(grid, x, 70, 3)
				roof[x] = 70
			for x in range(150, 191):
				WG.set_tile(grid, x, 80, 0)
				WG.set_tile(grid, x, 81, 3)
				roof[x] = 81
			data["tiles"] = grid
			var before_upgrade: Array = data["ground_life"].duplicate(true)
			var cleared := floori(float(before_upgrade[0]["x"]) / 16)
			Life.populate_surface_rocks(data, roof)
			for index in range(before_upgrade.size()):
				check(before_upgrade[index] == data["ground_life"][index], "One-time upgrades must preserve all existing and harvested entries")
			for index in range(before_upgrade.size(), data["ground_life"].size()):
				var x := floori(float(data["ground_life"][index]["x"]) / 16)
				check(not (x >= 100 and x <= 140) and not (x >= 150 and x <= 190) and absi(x - cleared) > 3,
					"Rock upgrades must avoid stone roofs, shallow excavations and harvested patches")
		print("SURFACE_ROCKS climate=", climate, " biome_counts=", counts)


func run_check() -> void:
	check_rock_regions()
	for seed_value in [713, 531209, 98765]:
		for climate in [0, 3, 4, 5, 7]:
			var data := WG.generate(seed_value, climate)
			check_basins(data)
			if climate == 0:
				var kinds := {}
				for basin: Dictionary in data["surface_basins"]:
					kinds[basin["kind"]] = true
				check(kinds.has("pond") and kinds.has("lake") and kinds.has("dry_basin"), "Temperate planets need ponds, a lake and a dry collection basin")
			var same := WG.generate(seed_value, climate)
			check(data["tiles"] == same["tiles"] and data["surface_basins"] == same["surface_basins"], "Basin shapes and contents must repeat from a seed")
			print("BASINS seed=", seed_value, " climate=", climate, " features=", data["surface_basins"])
	var game = load("res://main.tscn").instantiate()
	game.save_path = "user://ponds_rocks_check.json"
	root.add_child(game)
	await process_frame
	await game._open_planet(0)
	game.set_process(false)
	game.world = WG.generate(713, 0)
	game._reset_world_environment()
	var before_tiles: PackedByteArray = game.world["tiles"].duplicate()
	var basins: Array = game.world["surface_basins"].duplicate(true)
	var life: Array = game.world["ground_life"].duplicate(true)
	game.world["ground_life"][0]["alive"] = false
	game.worlds[game._world_key()] = game.world
	game._save_game()
	game._load_game()
	for _frame in range(4):
		await process_frame
	check(game.world["surface_basins"] == JSON.parse_string(JSON.stringify(basins)), "Basin geometry and contents must survive saves")
	check(int(game.world["surface_rocks_version"]) == 1, "The one-time rock marker must survive saves")
	check(game.world["ground_life"].size() == life.size() and not game.world["ground_life"][0]["alive"], "Saved rock/plant population and harvested state must survive reload")
	check(game.world["tiles"] == before_tiles, "Loading must not recarve existing terrain or refill lakes")
	# A stable filled natural lake should remain in place with the real water solver.
	var lake_data := WG.generate(713, 0)
	var solver := Water.new()
	solver.bind_world(lake_data)
	for basin: Dictionary in lake_data["surface_basins"]:
		if basin["kind"] == "lake":
			var center := (int(basin["left"]) + int(basin["right"])) / 2
			solver.set_active_region(Vector2(center * 16, int(basin["waterline"]) * 16))
			var water_before := 0
			for x in range(int(basin["left"]), int(basin["right"]) + 1):
				for y in range(int(basin["waterline"]), int(lake_data["surface"][x])):
					water_before += solver.amounts[y * WG.WIDTH + x]
			for _step in range(30):
				solver.step()
			var water_after := 0
			for x in range(int(basin["left"]), int(basin["right"]) + 1):
				for y in range(int(basin["waterline"]), int(lake_data["surface"][x])):
					water_after += solver.amounts[y * WG.WIDTH + x]
			check(water_after == water_before, "A sealed lake must retain its water without draining into caves")
			break
	DirAccess.remove_absolute(ProjectSettings.globalize_path(game.save_path))
	print("PONDS_ROCKS seeded basins, banks, ice, dry beds, all rock regions, save safety, fluid stability: failures=", failures)
	quit(1 if failures else 0)
