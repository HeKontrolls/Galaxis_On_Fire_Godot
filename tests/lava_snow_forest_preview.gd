extends SceneTree

const WG = preload("res://scripts/world_gen.gd")
const Wind = preload("res://scripts/wind.gd")


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
	await game._open_planet(0)
	game.set_process(false)
	game.world["creatures"] = []
	game.world["drops"] = []
	game.world.erase("npc")
	game.notice_timer = 0.0
	game.player_grounded = true
	game.time_of_day = 0.25
	game.weather = "Clear"
	game.weather_blend.reset("Clear", int(game.world.get("climate", 0)))
	game.cloud_cover = 0.25
	await capture(game, "dense_forest_preview")
	game.weather = "Snow"
	game.cloud_cover = 0.8
	for _tick in range(300):
		game._update_water(0.5)
	var best := 0.0
	for step in range(1200):
		var state := Wind.sample(game._planet_seed(0), step * 0.1, "Snow")
		if absf(state["speed"]) > best:
			best = absf(state["speed"])
			game.animation_clock = step * 0.1
	for _frame in range(60):
		game._update_clouds(0.1)
		game.surface_effects.update(game, 0.1)
	await capture(game, "forest_snow_accumulation_preview")
	game.weather = "Clear"
	game.weather_blend.reset("Clear", int(game.world.get("climate", 0)))
	game.cloud_cover = 0.3
	for _second in range(18):
		game._update_water(1.0)
	await capture(game, "forest_snow_melting_preview")
	for _second in range(150):
		game._update_water(1.0)
	await capture(game, "forest_snow_dried_preview")
	await game._open_planet(4)
	game.set_process(false)
	game.world["creatures"] = []
	game.world["drops"] = []
	game.world["torches"] = {}
	game.world.erase("npc")
	game.notice_timer = 0.0
	game.weather = "Clear"
	game.weather_blend.reset("Clear", int(game.world.get("climate", 0)))
	game.time_of_day = 0.75
	var grid: PackedByteArray = game.world["tiles"]
	var surface: PackedInt32Array = game.world["surface"]
	for x in range(540, 661):
		surface[x] = 80
		for y in range(1, 130):
			WG.set_tile(grid, x, y, 0 if y < 80 else 3)
	for x in range(576, 636):
		for y in range(84, 97):
			WG.set_tile(grid, x, y, 0)
	for x in range(584, 601):
		for y in range(90, 97):
			WG.set_tile(grid, x, y, 3)
	for x in range(585, 600):
		for y in range(87, 90):
			WG.set_tile(grid, x, y, 11)
	for y in range(87, 90):
		WG.set_tile(grid, 600, y, 3)
	game.world["tiles"] = grid
	game.world["surface"] = surface
	for field in ["water", "rain_water", "lava", "snow"]:
		game.world.erase(field)
	game._reset_world_environment()
	game.world_texture = WG.make_texture(grid)
	game.world_image = game.world_texture.get_image()
	game.foliage.reset()
	game.grass_pending.clear()
	game.player_pos = Vector2(606 * 16, 97 * 16 - 28)
	game._update_camera()
	game._edit_tile(Vector2i(600, 89), 0)
	for _tick in range(120):
		game._update_water(0.08)
		game.animation_clock += 0.08
	await capture(game, "lava_slow_flow_preview")
	for y in range(84, 96):
		var amount: int = game.lava_sim.amount_at(Vector2i(598, y))
		if amount > 0:
			game.player_pos = Vector2(598 * 16, (y + 1) * 16 - float(amount) * 16 / 255 - 18)
			break
	game._update_lava_damage(0.1)
	game._update_camera()
	await capture(game, "lava_contact_damage_preview")
	print("RENDERED dense forest, snowfall, snowmelt, dried ground, flowing lava and contact damage")
	quit(0)
