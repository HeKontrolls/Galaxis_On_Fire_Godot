extends SceneTree

const WG = preload("res://scripts/world_gen.gd")
const Effects = preload("res://scripts/surface_effects.gd")
var failures := 0


func _initialize() -> void:
	call_deferred("run_check")


func check(ok: bool, label: String) -> void:
	if not ok:
		failures += 1
		printerr(label)


func check_systems(game: Node2D) -> void:
	var stars := 0
	for seed_value in [125891, 42, 981]:
		game.galaxy_seed = seed_value
		game._make_galaxy()
		for star in range(game.star_points.size()):
			game.star_index = star
			game._make_system()
			stars += 1
			var rng := RandomNumberGenerator.new()
			rng.seed = seed_value + star * 104729 + 12345
			var inner: float = game.system_hab_inner
			var outer: float = game.system_hab_outer
			var inner_radius: float = game._system_radius_for_au(inner)
			var outer_radius: float = game._system_radius_for_au(outer)
			var warm := 0
			for i in range(8):
				var info: Dictionary = game.system_planets[i]
				var climate := int(info["climate"])
				var au := float(info["au"])
				if climate in [0, 1, 2]:
					warm += 1
					check(au >= inner and au <= outer and info["habitable"], "Temperate land and liquid-water worlds must orbit within their star's habitable zone")
					check(info["radius"] > inner_radius and info["radius"] < outer_radius, "The rendered green zone must contain every temperate orbit")
				elif climate in [3, 4]:
					check(au < inner and info["radius"] < inner_radius, "Hot worlds must appear inside the inner zone edge")
				else:
					check(au > outer and info["radius"] > outer_radius, "Cold worlds must appear beyond the outer zone edge")
				check(not info["life"] or info["habitable"], "Life indicators must not advertise worlds outside the zone")
				check(game._planet_seed(i) == seed_value + star * 104729 + i * 19001 + climate * 331, "Orbit corrections must preserve existing terrain seeds")
				# Replay the old cosmetic RNG to protect moons/rings on saved planets.
				var old_au := 0.35 + i * 0.42
				if old_au >= inner and old_au <= outer and climate in [0, 1, 2]:
					rng.randf()
				var size := rng.randi_range(7, 13) + (2 if climate in [1, 2] else 0)
				rng.randf_range(0, TAU)
				rng.randf_range(0.05, 0.18)
				var moons := rng.randi_range(0, 4 if i >= 4 else 3)
				var rings := rng.randf() < (0.25 if climate in [1, 2, 6, 7] else 0.17)
				check(info["size"] == size and info["moons"] == moons and info["rings"] == rings, "Orbit corrections must preserve seeded planet sizes, moons, and rings")
			check(warm == 3, "Each system must retain its existing three temperate planet identities")
	# Rare spectral types need explicit coverage even if a seed has no O stars.
	game.star_index = 0
	for spectral in ["O", "B", "A", "F", "G", "K", "M"]:
		game.star_types[0] = spectral
		game._make_system()
		for info in game.system_planets:
			if info["climate"] in [0, 1, 2]:
				check(info["au"] >= game.system_hab_inner and info["au"] <= game.system_hab_outer,
					"Temperate worlds must remain in-zone for spectral type " + spectral)
	print("HABITABLE_ZONES systems=", stars, " planets=", stars * 8, " spectral_types=7")
	game.galaxy_seed = 125891
	game.star_index = 0
	game._make_galaxy()
	game._make_system()


func fixture(game: Node2D) -> void:
	var grid := PackedByteArray()
	grid.resize(WG.WIDTH * WG.HEIGHT)
	var surface := PackedInt32Array()
	surface.resize(WG.WIDTH)
	surface.fill(80)
	for x in range(WG.WIDTH):
		WG.set_tile(grid, x, 80, 1)
	var rng := RandomNumberGenerator.new()
	rng.seed = 31529
	WG._plant_tree(grid, 589, 80, rng)
	WG._plant_tree(grid, 615, 80, rng)
	WG.set_tile(grid, 598, 80, 12)
	WG.set_tile(grid, 601, 80, 12)
	WG.set_tile(grid, 601, 79, 14)
	WG.set_tile(grid, 602, 80, 12)
	game.world["tiles"] = grid
	game.world["surface"] = surface
	game.world["drops"] = []
	game.world["creatures"] = []
	game.world["torches"] = {}
	game.world.erase("water")
	game.world.erase("rain_water")
	game._reset_world_environment()
	game.world_texture = WG.make_texture(grid)
	game.world_image = game.world_texture.get_image()
	game.foliage.reset()
	game.player_pos = Vector2(600 * 16, 80 * 16 - 29)
	game.player_grounded = true
	game._update_camera()
	game.inventory = {"Watering Can": 1, "Hoe": 1, "Crop Seeds": 3}
	game.equipped_tool = "Watering Can"
	game.use_hoe = false
	game.use_pickaxe = false
	game.weather = "Clear"
	game.weather_blend.reset("Clear", int(game.world.get("climate", 0)))


func check_watering(game: Node2D) -> void:
	var point: Vector2 = Vector2(602 * 16 + 8, 80 * 16 + 8) - game.camera_pos
	game._mine(point)
	check(WG.tile_at(game.world["tiles"], 602, 80) == 13 and game.tool_action_kind == "water", "Left-click must hydrate soil and start the dedicated pouring pose")
	check(not game._is_pouring(), "The stream must wait until the can tips")
	var upright: Vector2 = game._watering_spout_world()
	for _frame in range(20):
		game.tool_action_timer = maxf(0, game.tool_action_timer - 1.0 / 60)
		game.surface_effects.update(game, 1.0 / 60)
	var right: Vector2 = game._watering_spout_world()
	check(game._is_pouring() and right.distance_to(upright) > 5 and game.surface_effects.droplets.size() > 0, "The tilted can must move its spout and emit visible droplets")
	var before: PackedByteArray = game.water_sim.amounts.duplicate()
	for _frame in range(45):
		game.tool_action_timer = maxf(0, game.tool_action_timer - 1.0 / 60)
		game.surface_effects.update(game, 1.0 / 60)
	check(not game._is_pouring() and game.water_sim.amounts == before, "Pouring must end cleanly and must not introduce floodwater")
	game._mine(Vector2(598 * 16 + 8, 80 * 16 + 8) - game.camera_pos)
	game.tool_action_timer = game.tool_action_duration * 0.5
	var left: Vector2 = game._watering_spout_world()
	check(game.facing == -1 and left.x < game.player_pos.x + 8 and absf(left.y - right.y) < 0.1, "The tilted can and stream origin must mirror correctly when facing left")
	game._mine(Vector2(601 * 16 + 8, 79 * 16 + 8) - game.camera_pos)
	check(WG.tile_at(game.world["tiles"], 601, 80) == 13 and WG.tile_at(game.world["tiles"], 601, 79) == 14, "Watering a growing crop must hydrate its soil without damaging the crop")
	game._equip_inventory_item("Crop Seeds")
	game._place(Vector2(602 * 16 + 8, 80 * 16 + 8) - game.camera_pos)
	check(WG.tile_at(game.world["tiles"], 602, 79) == 14 and game.inventory["Crop Seeds"] == 2 and game.equipped_tool == "Hand", "Selecting seeds must plant wet soil and put the previous watering can away")
	print("WATERING soil, crops, pose, stream, mirroring and flood safety checked")


func test_leaf(at: Vector2) -> Dictionary:
	return {"position": at, "velocity": Vector2(0, 12), "age": 0.0, "life": 100.0,
		"phase": 0.0, "angle": 0.0, "spin": 1.0, "color": Color.GREEN, "landed": false}


func check_wind(game: Node2D) -> void:
	var effects := Effects.new()
	var empty := PackedByteArray()
	empty.resize(WG.WIDTH * WG.HEIGHT)
	var start := Vector2(600 * 16, 60 * 16)
	effects.leaves.append(test_leaf(start))
	for _frame in range(60):
		effects.update_particles(0.05, 28.0, empty)
	var east: Vector2 = effects.leaves[0]["position"]
	check(east.x > start.x + 30 and east.y > start.y, "Leaves must fall and drift east in an eastward wind")
	for _frame in range(60):
		effects.update_particles(0.05, -28.0, empty)
	check(effects.leaves[0]["position"].x < east.x - 30, "Airborne leaves must respond when the wind reverses")
	effects.reset(713)
	effects.leaves.append(test_leaf(Vector2(600 * 16, 80 * 16 - 1)))
	effects.update_particles(0.1, 0, game.world["tiles"])
	check(effects.leaves[0]["landed"], "Leaves must settle on terrain")
	effects.update_particles(2, 0, game.world["tiles"])
	check(effects.leaves.is_empty(), "Settled leaves must fade out instead of accumulating forever")
	game.surface_effects.reset(713)
	var tiles_before: PackedByteArray = game.world["tiles"].duplicate()
	for _frame in range(100):
		game.animation_clock += 0.1
		game.surface_effects.update(game, 0.1)
	check(game.surface_effects.leaves.size() > 0 and game.surface_effects.leaves.size() <= Effects.MAX_LEAVES, "Visible trees must shed a bounded number of decorative leaves")
	check(game.world["tiles"] == tiles_before and int(game.inventory.get("Leaves", 0)) == 0, "Ambient shedding must not remove tree blocks or create free inventory resources")
	game._drop_tree_block(Vector2i(589, 60), 8, Rect2(0, 0, 16, 16))
	game.world["drops"].back()["vx"] = 0.0
	var block_start: float = game.world["drops"].back()["x"]
	var wind: float = game._wind_speed()
	for _frame in range(10):
		game._update_drops(0.1)
	check((game.world["drops"].back()["x"] - block_start) * wind > 0,
		"Chopped leaf blocks must follow the same wind as ambient leaves")
	game.surface_effects.reset(713)
	check(game.surface_effects.leaves.is_empty() and game.surface_effects.droplets.is_empty(), "Changing worlds must clear transient leaf and water effects")
	print("WIND direction reversal, leaf settling, shedding and bounded effects checked")


func run_check() -> void:
	var game: Node2D = load("res://main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.set_process(false)
	check_systems(game)
	await game._open_planet(0)
	fixture(game)
	check_watering(game)
	check_wind(game)
	print("ZONES_WATERING_WIND failures=", failures)
	quit(0 if failures == 0 else 1)
