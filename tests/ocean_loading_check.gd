extends SceneTree

const WG = preload("res://scripts/world_gen.gd")
const Water = preload("res://scripts/water_sim.gd")
const Preparation = preload("res://scripts/ocean_preparation.gd")
var failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		printerr(message)

func total(amounts: PackedByteArray) -> int:
	var result := 0
	for amount in amounts:
		result += amount
	return result

func chamber() -> Dictionary:
	var grid := PackedByteArray()
	grid.resize(WG.WIDTH * WG.HEIGHT)
	grid.fill(3)
	for y in range(98, 111):
		for x in range(100, 141):
			WG.set_tile(grid, x, y, 4)
	WG.set_tile(grid, 120, 111, 30) # A passable chest is the only cave entrance.
	for y in range(112, 151):
		for x in range(110, 136):
			WG.set_tile(grid, x, y, 0)
	return {"tiles": grid, "seed": 713, "climate": 2, "sea_level": 98,
		"chest_contents": {"120,111": {"Gold Ore": 7}}}

func prop_checks() -> void:
	for id in [30, 7, 8, 14, 34, 35, 36, 37]:
		var data := chamber()
		WG.set_tile(data["tiles"], 120, 111, id)
		var job := Preparation.new(data)
		var ticks := 0
		while not job.done:
			var before := job.cursor
			job.step(7)
			check(job.cursor - before <= 7, "Loading work stays inside its frame budget")
			ticks += 1
		check(ticks > 1 and job.filled_cells == 1015, "Entire cavern fills through passable scenery: " + str(id))
		check(WG.tile_at(data["tiles"], 120, 111) == id and data["water"][111 * WG.WIDTH + 120] == 255, "Scenery remains intact while sharing a full water cell")
		check(data["chest_contents"]["120,111"]["Gold Ore"] == 7, "Flood preparation preserves container contents")
		var solver := Water.new()
		solver.bind_world(data)
		var amount_before := total(solver.amounts)
		check(solver.active.is_empty(), "No unfilled cave remains downstream of scenery")
		for _step in range(200):
			solver.step()
		for x in range(100, 141):
			check(solver.amount_at(Vector2i(x, 98)) == 255, "Ocean surface stays full after real fluid simulation")
		check(total(solver.amounts) == amount_before, "Preparation produces conserved finite water")
		check(WG.settle_oceans(data) == 0, "Prepared planets never get refilled on repeat visits")
	print("OCEAN_PROPS eight scenery types; cavern fill, saved water, bounded work, 200-step level stability")

func boundary_checks() -> void:
	var grid := PackedByteArray()
	grid.resize(WG.WIDTH * WG.HEIGHT)
	grid.fill(3)
	for y in range(98, WG.HEIGHT):
		for x in range(3):
			WG.set_tile(grid, x, y, 4 if y == 98 else 0)
	WG.set_tile(grid, 0, 97, 0)
	WG.set_tile(grid, WG.WIDTH - 1, 100, 0)
	var data := {"tiles": grid, "climate": 2, "seed": 713}
	WG.settle_oceans(data)
	check(data["water"][(WG.HEIGHT - 1) * WG.WIDTH] == 255, "Boundary columns and bottom row fill correctly")
	check(WG.tile_at(data["tiles"], 0, 97) == 0 and WG.tile_at(data["tiles"], WG.WIDTH - 1, 100) == 0, "No above-sea-level flooding or horizontal row wrapping")
	var source := chamber()
	var baseline: PackedByteArray = source["tiles"].duplicate()
	source["ocean_fill_version"] = 1
	var current: PackedByteArray = source["tiles"]
	# A player-created excavation outside the original natural cave.
	for x in range(136, 146):
		WG.set_tile(current, x, 140, 0)
	# A constructed dry room inside the original natural cavern.
	for y in range(120, 129):
		for x in range(115, 123):
			if y in [120, 128] or x in [115, 122]:
				WG.set_tile(current, x, y, 33)
	source["tiles"] = current
	WG.settle_oceans(source, baseline)
	check(source["water"][140 * WG.WIDTH + 140] == 0 and WG.tile_at(source["tiles"], 140, 140) == 0, "One-time repair preserves player-created excavations")
	check(source["water"][124 * WG.WIDTH + 119] == 0 and WG.tile_at(source["tiles"], 115, 120) == 33, "Constructed walls and sealed rooms are preserved")
	check(source["ocean_preparation"]["guarded_upgrade"], "Saved-planet repairs record their guarded migration")
	# An existing byte array must be updated, not just the visible tile grid.
	var saved := chamber()
	var water := Water.new()
	water.bind_world(saved)
	var tags := PackedByteArray()
	tags.resize(grid.size())
	tags[98 * WG.WIDTH + 100] = 30
	saved["rain_water"] = tags
	WG.settle_oceans(saved)
	water.bind_world(saved)
	check(water.amount_at(Vector2i(120, 140)) == 255 and tags[98 * WG.WIDTH + 100] == 30, "Saved water amounts are synchronized while rain tags remain intact")
	print("OCEAN_BOUNDARIES edge/bottom cells, sealed rooms, player edits, existing amount arrays and rain tags")

func generated_checks() -> void:
	for climate in [1, 2]:
		for seed_value in [713, 531209, 741927, 125891, 98765]:
			var start := Time.get_ticks_msec()
			var data := WG.generate(seed_value, climate, false)
			var raw: PackedByteArray = data["tiles"].duplicate()
			var added := WG.settle_oceans(data)
			var solver := Water.new()
			solver.bind_world(data)
			var full_surface: Array[int] = []
			for x in range(WG.WIDTH):
				if raw[98 * WG.WIDTH + x] == 4:
					full_surface.append(x)
			for index in solver.active:
				check(int(index) / WG.WIDTH < 98, "Generated oceans have no downstream empty fluid cells")
			var before := total(solver.amounts)
			for _step in range(100):
				solver.step()
			for x in full_surface:
				check(solver.amount_at(Vector2i(x, 98)) == 255, "Generated sea level remains stable: %d / %d" % [climate, seed_value])
			check(total(solver.amounts) == before, "World-scale simulation conserves initialized water")
			print("OCEAN_WORLD climate=", climate, " seed=", seed_value, " filled_cells=", added, " sea_columns=", full_surface.size(), " milliseconds=", Time.get_ticks_msec() - start)

func wait_for_planet(game) -> void:
	for _frame in range(2000):
		if game.scene_name == "planet":
			return
		await process_frame
	check(false, "Planet loading must complete")

func loading_checks() -> void:
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.set_process(false)
	game.star_index = 0
	game._open_planet(2)
	var stages := {}
	var fill_frames := 0
	while game.scene_name == "loading":
		stages[game.load_progress] = true
		if game.load_progress.begins_with("Filling ocean-connected"):
			fill_frames += 1
		await process_frame
	check(fill_frames > 1 and game.world["ocean_fill_version"] == Preparation.VERSION, "Real loading screen progresses across flood preparation before play")
	check(game.water_sim.active.is_empty(), "Playable ocean starts with fully flooded connections")
	# Simulate an older save whose chest cells were left dry by version one.
	var legacy := WG.generate(713, 2)
	var natural := WG.generate(713, 2, false)
	var saved_water: PackedByteArray = legacy["water"]
	var dry_prop := -1
	for index in range(saved_water.size()):
		if saved_water[index] == 255 and legacy["tiles"][index] == 30:
			dry_prop = index
			saved_water[index] = 0
	check(dry_prop >= 0, "Legacy fixture exercises submerged chest gaps")
	var excavation := -1
	for y in range(180, WG.HEIGHT - 5):
		for x in range(10, WG.WIDTH - 10):
			var at := y * WG.WIDTH + x
			if natural["tiles"][at] == 3:
				excavation = at
				break
		if excavation >= 0:
			break
	legacy["tiles"][excavation] = 0
	legacy["water"][excavation] = 0
	legacy["ocean_fill_version"] = 1
	legacy["chest_contents"] = {"test": {"Gold Ore": 7}}
	game.worlds["0_2"] = legacy
	await game._open_planet(2)
	check(game.water_sim.amounts[dry_prop] == 255 and game.world["tiles"][dry_prop] == 30, "Existing ocean repair fills the missing water while preserving chest tiles")
	check(game.water_sim.amounts[excavation] == 0 and game.world["tiles"][excavation] == 0, "Existing ocean repair does not refill dug terrain")
	check(game.world["chest_contents"]["test"]["Gold Ore"] == 7, "Saved storage metadata survives ocean repair")
	game.water_sim.remove_units(dry_prop, 255)
	game.save_path = "user://galaxis_ocean_loading_check.json"
	game._save_game()
	game._load_game()
	await wait_for_planet(game)
	check(game.world["ocean_fill_version"] == Preparation.VERSION and game.water_sim.amounts[dry_prop] == 0, "Repeat loads preserve subsequent liquid edits rather than refilling the ocean again")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(game.save_path))
	print("OCEAN_LOADING actual frame progress, natural-cave save repair, terrain/storage preservation and repeat-load safety")
	game.queue_free()
	await process_frame

func run() -> void:
	prop_checks()
	boundary_checks()
	generated_checks()
	await loading_checks()
	print("OCEAN_LOADING failures=", failures)
	quit(0 if failures == 0 else 1)
