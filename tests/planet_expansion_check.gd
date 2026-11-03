extends "res://tests/tool_progression_check.gd"

const Life = preload("res://scripts/ground_life.gd")
const Water = preload("res://scripts/water_sim.gd")

func roof_for(world: Dictionary) -> PackedInt32Array:
	var roof := PackedInt32Array()
	roof.resize(WG.WIDTH)
	for x in range(WG.WIDTH):
		for y in range(WG.HEIGHT):
			if WG.is_solid(WG.tile_at(world["tiles"], x, y)):
				roof[x] = y
				break
	return roof

func run_check() -> void:
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	await game._open_planet(0)
	game.set_process(false)
	for climate in range(8):
		var world := WG.generate(741927, climate)
		for path: Array in world["cave_entrances"]:
			check(absi(path[-1][0] - path[0][0]) >= 20 and path[-1][1] > path[0][1], "Angled mouth climate " + str(climate))
		if climate == 3:
			var before: PackedByteArray = world["tiles"].duplicate()
			Life.populate(world, roof_for(world))
			var seen := {}
			for entry: Dictionary in world["ground_life"]:
				seen[entry["species"]] = true
			for species: String in Life.DESERT:
				check(seen.has(species), "Desert contains " + species)
				check(game.ground_life.frames[species].size() == 4, "Four native frames for " + species)
				check(absf(Life.wind_bend(species, 0.5, 2.0, 15)) > 0.01, "Wind-responsive " + species)
			check(before == world["tiles"], "Desert plants remain passable scenery")
			var count: int = world["ground_life"].size()
			Life.populate(world, roof_for(world))
			check(world["ground_life"].size() == count, "Desert migration runs once")
		if climate == 6:
			check(world["ice_pillars"].size() > 10, "Frozen sea has clustered ice spires")
			for pillar: Dictionary in world["ice_pillars"]:
				check(int(pillar["height"]) >= 13 and absi(int(pillar["x"]) - 600) > 40, "Tall ice spires preserve landing area")
		if climate in [1, 2]:
			check(world["ocean_fill_version"] == 2, "Ocean loading check marked complete")
			var before: PackedByteArray = world["tiles"].duplicate()
			check(WG.settle_oceans(world) == 0 and world["tiles"] == before, "Existing ocean terrain never refilled")
		print("PLANET climate=", climate, " generated and checked")
	var grid := PackedByteArray()
	grid.resize(WG.WIDTH * WG.HEIGHT)
	grid.fill(3)
	for y in range(95, 111):
		WG.set_tile(grid, 100, y, 0)
	WG.set_tile(grid, 100, 98, 4)
	for x in range(100, 111):
		WG.set_tile(grid, x, 110, 0)
	WG.set_tile(grid, 120, 110, 0)
	var ocean := {"tiles": grid, "climate": 2, "seed": 919}
	check(WG.settle_oceans(ocean) == 22, "Connected cave fills to sea level")
	check(WG.tile_at(ocean["tiles"], 100, 97) == 0 and WG.tile_at(ocean["tiles"], 120, 110) == 0, "Above-sea-level and sealed cavities stay dry")
	var water := Water.new()
	water.bind_world(ocean)
	water.set_active_region(Vector2(100 * 16, 105 * 16))
	for _tick in range(40):
		water.update(0.1)
	check(water.amount_at(Vector2i(100, 98)) == 255, "Initialized ocean does not drain during simulation")
	fixture(game)
	game.world["climate"] = 4
	for weather in ["Rain", "Storm", "Snow"]:
		game.weather = weather
		for _tick in range(20):
			game._update_water(0.1)
		check(not game._is_raining() and game.weather in ["Ashfall", "Ember Storm"], "Volcanic precipitation maps " + weather)
		check(game.water_sim.amounts.count(0) == game.water_sim.amounts.size(), "No volcanic rain water")
		check(game.snowfall.cells.is_empty(), "No volcanic snow melt")
	print("PLANET_EXPANSION failures=", failures)
	quit(0 if failures == 0 else 1)
