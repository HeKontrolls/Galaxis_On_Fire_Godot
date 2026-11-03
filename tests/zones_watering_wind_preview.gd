extends SceneTree

const WG = preload("res://scripts/world_gen.gd")


func _initialize() -> void:
	call_deferred("preview")


func capture(game: Node2D, name: String) -> void:
	game.queue_redraw()
	await process_frame
	await process_frame
	root.get_texture().get_image().save_png("res://tests/%s.png" % name)


func preview() -> void:
	var game: Node2D = load("res://main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.set_process(false)
	game.animation_clock = 12.0
	for spectral in ["O", "M"]:
		game.galaxy_seed = 125891
		game._make_galaxy()
		# An 80-star galaxy can legitimately contain no very rare O-type star.
		while game.star_types.find(spectral) < 0:
			game.galaxy_seed += 1
			game._make_galaxy()
		game.star_index = game.star_types.find(spectral)
		game._make_system()
		game.scene_name = "system"
		for i in range(8):
			if game.system_planets[i]["climate"] == 0:
				game.selected_planet_index = i
		await capture(game, "habitable_zone_%s_preview" % spectral)
	game.star_index = 0
	game._make_system()
	await game._open_planet(0)
	game.world["creatures"] = []
	game.world["drops"] = []
	game.world["torches"] = {}
	game.world.erase("npc")
	game.notice_timer = 0.0
	game.time_of_day = 0.25
	game.weather = "Clear"
	game.weather_blend.reset("Clear", int(game.world.get("climate", 0)))
	game.cloud_cover = 0.25
	var grid: PackedByteArray = game.world["tiles"]
	var surface: PackedInt32Array = game.world["surface"]
	for x in range(540, 661):
		surface[x] = 80
		for y in range(1, 125):
			WG.set_tile(grid, x, y, 0 if y < 80 else (1 if y == 80 else (2 if y < 95 else 3)))
	var rng := RandomNumberGenerator.new()
	rng.seed = 31529
	for x in [574, 584, 618, 632]:
		WG._plant_tree(grid, x, 80, rng)
	for x in range(595, 607):
		WG.set_tile(grid, x, 80, 12)
		if x % 3 != 0:
			WG.set_tile(grid, x, 79, 14 + int((x - 595) / 4))
	game.world["tiles"] = grid
	game.world["surface"] = surface
	game.world.erase("water")
	game.world.erase("rain_water")
	game._reset_world_environment()
	game.world_texture = WG.make_texture(grid)
	game.world_image = game.world_texture.get_image()
	game.foliage.reset()
	game.grass_pending.clear()
	game.player_pos = Vector2(600 * 16, 80 * 16 - 29)
	game.player_grounded = true
	game._update_camera()
	game.inventory = {"Watering Can": 1, "Crop Seeds": 18, "Corn": 4}
	game._equip_inventory_item("Crop Seeds")
	game.equipped_tool = "Watering Can"
	game.use_hoe = false
	game.use_pickaxe = false
	for _frame in range(100):
		game.animation_clock += 0.1
		game.surface_effects.update(game, 0.1)
	game._farm_interaction(Vector2i(603, 80), "Watering Can", "")
	for _frame in range(23):
		game.tool_action_timer -= 1.0 / 60
		game.surface_effects.update(game, 1.0 / 60)
	game.notice_timer = 0.0
	await capture(game, "watering_wind_right_preview")
	game.tool_action_timer = 0.0
	game.surface_effects.droplets.clear()
	game._farm_interaction(Vector2i(597, 80), "Watering Can", "")
	for _frame in range(23):
		game.tool_action_timer -= 1.0 / 60
		game.surface_effects.update(game, 1.0 / 60)
	game.notice_timer = 0.0
	await capture(game, "watering_wind_left_preview")
	print("RENDERED O/M habitable zones, mirrored pouring streams and wind-blown leaves")
	quit(0)
