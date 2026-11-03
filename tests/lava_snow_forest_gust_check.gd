extends SceneTree

const WG = preload("res://scripts/world_gen.gd")
const Water = preload("res://scripts/water_sim.gd")
const Lava = preload("res://scripts/lava_sim.gd")
const Wind = preload("res://scripts/wind.gd")
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


func basin(id: int) -> Dictionary:
	var grid := PackedByteArray()
	grid.resize(WG.WIDTH * WG.HEIGHT)
	for x in range(590, 611):
		WG.set_tile(grid, x, 90, 3)
	for y in range(65, 91):
		WG.set_tile(grid, 590, y, 3)
		WG.set_tile(grid, 610, y, 3)
	WG.set_tile(grid, 600, 70, id)
	WG.set_tile(grid, 600, 71, id)
	return {"tiles": grid}


func center_y(values: PackedByteArray) -> float:
	var weighted := 0.0
	var volume := 0
	for index in range(values.size()):
		if values[index] > 0:
			weighted += int(index / WG.WIDTH) * values[index]
			volume += values[index]
	return weighted / maxf(1, volume)


func check_lava_flow() -> void:
	var wet := basin(4)
	var molten := basin(11)
	var water := Water.new()
	var lava := Lava.new()
	water.bind_world(wet)
	lava.bind_world(molten)
	check(total(lava.amounts) == 510, "Legacy lava tiles must migrate to full finite volumes")
	for _frame in range(100):
		water.update(0.02)
		lava.update(0.02)
	check(center_y(water.amounts) > center_y(lava.amounts) + 5, "Lava must descend substantially slower than water over the same elapsed time")
	for _tick in range(600):
		lava.update(0.28)
	check(total(lava.amounts) == 510, "Lava falling and lateral spreading must conserve volume exactly")
	var low := 255
	var high := 0
	for x in range(591, 610):
		low = mini(low, lava.amount_at(Vector2i(x, 89)))
		high = maxi(high, lava.amount_at(Vector2i(x, 89)))
	check(low > 0 and high - low < 16, "Lava must spread sideways and settle into a level shallow pool")
	var before := total(lava.amounts)
	check(lava.displace(Vector2i(600, 89)) and total(lava.amounts) == before and lava.amount_at(Vector2i(600, 89)) == 0,
		"Placing terrain in lava must displace it without losing volume")
	var mixed := basin(11)
	var grid: PackedByteArray = mixed["tiles"]
	WG.set_tile(grid, 601, 70, 4)
	mixed["tiles"] = grid
	water.bind_world(mixed)
	lava.bind_world(mixed)
	for _tick in range(80):
		water.update(0.08)
		lava.update(0.28)
	var overlap := false
	for index in range(lava.amounts.size()):
		overlap = overlap or (lava.amounts[index] > 0 and water.amounts[index] > 0)
	check(not overlap and total(water.amounts) == 255 and total(lava.amounts) == 510, "Water and lava must remain separate without destroying either fluid")
	print("LAVA_FLOW conservation, viscosity, leveling, displacement and fluid separation checked")


func fixture(game: Node2D) -> void:
	var grid := PackedByteArray()
	grid.resize(WG.WIDTH * WG.HEIGHT)
	for x in range(WG.WIDTH):
		for y in range(80, WG.HEIGHT):
			WG.set_tile(grid, x, y, 1 if y == 80 else 3)
	var surface := PackedInt32Array()
	surface.resize(WG.WIDTH)
	surface.fill(80)
	game.world = {"tiles": grid, "surface": surface, "seed": 713, "climate": 0,
		"spawn": Vector2(620 * 16, 80 * 16 - 29), "crops": {}, "creatures": [], "drops": [],
		"torches": {}, "placed_chests": {}, "forest_density_version": 2}
	game.worlds[game._world_key()] = game.world
	game._reset_world_environment()
	game.world_texture = WG.make_texture(grid)
	game.world_image = game.world_texture.get_image()
	game.player_pos = Vector2(600 * 16, 80 * 16 - 28)
	game.player_velocity = Vector2.ZERO
	game._update_camera()
	game.time_of_day = 0.25
	game.weather = "Clear"
	game.weather_blend.reset("Clear", int(game.world.get("climate", 0)))
	game.health = 100
	game.dev_invulnerable = false


func check_damage(game: Node2D) -> void:
	game._edit_tile(Vector2i(600, 79), 11)
	var index := 79 * WG.WIDTH + 600
	game.lava_sim.amounts[index] = 8
	game.world["lava"] = game.lava_sim.amounts
	check(not game.lava_sim.submerged(game.player_pos + Vector2(8, 14)) and game.lava_sim.intersects(game._player_rect(game.player_pos)),
		"Even a shallow lava layer touching only the feet must count as contact")
	var feet: Vector2 = game.player_pos
	game.player_pos.y -= 14
	check(not game.lava_sim.intersects(game._player_rect(game.player_pos)), "Hovering above a shallow settled pool must be safe")
	game.lava_sim.falling[index] = true
	check(game.lava_sim.intersects(game._player_rect(game.player_pos)), "The visible falling stream must hurt on contact above the settled surface")
	game.lava_sim.falling.clear()
	game.player_pos = feet
	var outcomes := []
	for fps in [30, 120, 300]:
		game.health = 100
		game.lava_hurt_timer = 0.0
		for _frame in range(int(fps * 0.8)):
			game._update_lava_damage(1.0 / fps)
		outcomes.append(game.health)
	check(outcomes == [60, 60, 60], "Lava damage must be independent of FPS: " + str(outcomes))
	game.dev_invulnerable = true
	game._update_lava_damage(1.0)
	check(game.health == 60, "Developer invulnerability must protect against lava")
	game.dev_invulnerable = false
	game.health = 10
	game._update_lava_damage(0.1)
	check(game.health == 100 and game.player_pos == game.world["spawn"] and game.player_velocity == Vector2.ZERO,
		"Lethal lava contact must respawn the player at the saved spawn")
	print("LAVA_DAMAGE fps=30/120/300 health=", outcomes, " feet, God Mode and respawn checked")


func check_snow(game: Node2D) -> void:
	fixture(game)
	for x in range(608, 613):
		game._edit_tile(Vector2i(x, 70), 9)
	game._edit_tile(Vector2i(640, 80), 6)
	game.weather = "Snow"
	for _tick in range(300):
		game._update_water(0.5)
	var covered := 0
	var indoors := 0
	for x in range(608, 613):
		covered += game.snowfall.amounts[69 * WG.WIDTH + x]
		indoors += game.snowfall.amounts[79 * WG.WIDTH + x]
	var snow_before := total(game.snowfall.amounts)
	check(snow_before > 1000 and covered > 0 and indoors == 0, "Snowfall must accumulate outdoors and on roofs while keeping covered ground clear")
	check(total(game.water_sim.amounts) == 0, "Cold snowfall must remain snow until it melts")
	game.weather = "Clear"
	game.weather_blend.reset("Clear", int(game.world.get("climate", 0)))
	var saw_meltwater := false
	var peak_water := 0
	for _second in range(120):
		game._update_water(1.0)
		var volume := total(game.water_sim.amounts)
		peak_water = maxi(peak_water, volume)
		saw_meltwater = saw_meltwater or volume > 0
		check(total(game.water_sim.rain_amounts) == volume, "Every unit of snowmelt must be tagged for later evaporation")
	check(saw_meltwater and total(game.snowfall.amounts) == 0 and total(game.water_sim.amounts) == 0,
		"Settled snow must visibly become water and then completely evaporate")
	check(WG.tile_at(game.world["tiles"], 640, 80) == 6, "Weather snow must not erase permanent generated snow/ice terrain")
	game.weather = "Snow"
	game.snowfall.deposit(600, 40, game.environment.roof, game.water_sim, game.lava_sim)
	game._edit_tile(Vector2i(600, 80), 0)
	game._update_water(1.0)
	check(game.snowfall.amounts[79 * WG.WIDTH + 600] == 0 and game.snowfall.amounts[80 * WG.WIDTH + 600] >= 40,
		"Snow must settle onto the new floor after the player digs its support")
	game.snowfall.deposit(601, 40, game.environment.roof, game.water_sim, game.lava_sim)
	game._edit_tile(Vector2i(600, 80), 11)
	game.snowfall._tick(game, game.environment.roof)
	check(game.snowfall.amounts[79 * WG.WIDTH + 601] < 40 and game.water_sim.amount_at(Vector2i(601, 79)) > 0,
		"Nearby lava must melt a snow layer even during snowfall")
	print("SNOW snow_units=", snow_before, " peak_meltwater=", peak_water, " roofs, melting, evaporation and digging checked")


func count_trees(data: Dictionary) -> int:
	var count := 0
	var grid: PackedByteArray = data["tiles"]
	for x in range(WG.WIDTH):
		for y in range(maxi(0, data["surface"][x] - 20), mini(WG.HEIGHT - 1, data["surface"][x] + 1)):
			if WG.tile_at(grid, x, y) == 7 and WG.tile_at(grid, x, y + 1) != 7:
				count += 1
	return count


func check_snow_runoff(game: Node2D) -> void:
	fixture(game)
	for x in range(598, 603):
		for y in range(80, 96):
			game._edit_tile(Vector2i(x, y), 0, false)
	game.world_texture.update(game.world_image)
	game.weather = "Snow"
	for _tick in range(300):
		game._update_water(0.5)
	game.weather = "Clear"
	game.weather_blend.reset("Clear", int(game.world.get("climate", 0)))
	var peak := 0
	for _tick in range(1200):
		game._update_water(0.08)
		var columns := {}
		for index in game.water_sim.rain_cells:
			var x: int = index % WG.WIDTH
			columns[x] = int(columns.get(x, 0)) + game.water_sim.rain_amounts[index]
			peak = maxi(peak, columns[x])
	check(peak <= 64, "An entire snow-covered hillside melting into a deep pit must not recreate flooding: " + str(peak))
	check(total(game.snowfall.amounts) == 0 and total(game.water_sim.amounts) == 0, "Concentrated snowmelt must drain and evaporate completely")
	print("SNOW_RUNOFF deep_pit_peak_units=", peak, " depth_pixels=", float(peak) * 16 / 255)


func check_forests(game: Node2D) -> void:
	var counts := []
	var seeds := [125891, 531209, 713]
	for i in range(seeds.size()):
		var generated: Dictionary = WG.generate(seeds[i], 0)
		var count := count_trees(generated)
		counts.append(count)
		check(count >= 25 and count < 120, "Forest planets must have wooded clusters with room for open biomes")
		for x in range(WG.WIDTH):
			if int(generated["biomes"][x]) in [0, 3]:
				check(WG.tile_at(generated["tiles"], x, generated["surface"][x] - 1) != 7,
					"Meadows and rocky uplands must remain free of generated trunks")
	fixture(game)
	game.world["forest_density_version"] = 0
	game.world["player_pos"] = game.player_pos
	game._edit_tile(Vector2i(150, 79), 9)
	game._edit_tile(Vector2i(170, 80), 12)
	game._edit_tile(Vector2i(180, 80), 0)
	var grid: PackedByteArray = game.world["tiles"].duplicate()
	var added := WG.enrich_forest(game.world)
	check(added == 0 and game.world["tiles"] == grid, "Legacy worlds must retain their terrain and trees without blanket enrichment")
	var preserved := true
	for index in range(grid.size()):
		if grid[index] != 0:
			preserved = preserved and game.world["tiles"][index] == grid[index]
	check(preserved, "Enrichment must never overwrite existing terrain, construction, or crops")
	check(WG.enrich_forest(game.world) == 0, "Loading an upgraded forest again must not regrow cut trees")
	print("FORESTS clustered=", counts, " legacy additions=", added)


func check_gusts() -> void:
	var peaks := []
	for weather in ["Clear", "Storm"]:
		var previous := 0.0
		var peak := 0.0
		var gusting := 0
		var calm := 0
		var jump := 0.0
		for step in range(1200):
			var state := Wind.sample(713, step * 0.1, weather)
			var speed := float(state["speed"])
			peak = maxf(peak, absf(speed))
			if step > 0:
				jump = maxf(jump, absf(speed - previous))
			previous = speed
			if state["gusting"]:
				gusting += 1
			else:
				calm += 1
			check(state == Wind.sample(713, step * 0.1, weather), "Wind gusts must be deterministic for a planet and time")
		check(gusting > 0 and calm > 0 and jump < 20.0, "Gusts must have distinct calm/strong periods with smooth transitions")
		peaks.append(peak)
	check(peaks[1] > peaks[0] * 1.4, "Storm gusts must be stronger than clear-weather gusts")
	print("GUSTS clear_peak=", peaks[0], " storm_peak=", peaks[1])


func check_saves(game: Node2D) -> void:
	fixture(game)
	game.save_path = "user://galaxis_lava_snow_gust_check.json"
	game._edit_tile(Vector2i(598, 79), 11)
	game.lava_sim.amounts[79 * WG.WIDTH + 598] = 73
	game.world["lava"] = game.lava_sim.amounts
	game.snowfall.deposit(605, 88, game.environment.roof, game.water_sim, game.lava_sim)
	game.snowfall.runoff_timer = 12.0
	game._save_game()
	game._load_game()
	await process_frame
	check(game.lava_sim.amount_at(Vector2i(598, 79)) == 73 and game.snowfall.amounts[79 * WG.WIDTH + 605] == 88,
		"Partial lava and weather snow must survive save/load")
	check(game.world["forest_density_version"] == 2, "Forest upgrade state must persist")
	check(game.snowfall.runoff_timer > 11.9, "Snowmelt flood protection must survive saving")
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(game.save_path))
	for key in data["worlds"]:
		data["worlds"][key].erase("lava")
		data["worlds"][key].erase("snow")
	var file := FileAccess.open(game.save_path, FileAccess.WRITE)
	file.store_string(JSON.stringify(data))
	file.close()
	game._load_game()
	await process_frame
	check(game.lava_sim.amount_at(Vector2i(598, 79)) == 255 and game.snowfall.cells.is_empty(),
		"Older saves must initialize lava volumes and start with no temporary snow")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(game.save_path))


func run_check() -> void:
	check_lava_flow()
	check_gusts()
	var game: Node2D = load("res://main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	await game._open_planet(0)
	game.set_process(false)
	fixture(game)
	check_damage(game)
	check_snow(game)
	check_snow_runoff(game)
	check_forests(game)
	await check_saves(game)
	print("LAVA_SNOW_FOREST_GUST failures=", failures)
	quit(0 if failures == 0 else 1)
