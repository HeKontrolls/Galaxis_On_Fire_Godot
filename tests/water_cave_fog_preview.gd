extends SceneTree

const WG = preload("res://scripts/world_gen.gd")


func _initialize() -> void:
	call_deferred("render_preview")


func capture(game: Node2D, name: String) -> Image:
	game.queue_redraw()
	await process_frame
	await process_frame
	var image := root.get_texture().get_image()
	image.save_png("res://tests/%s.png" % name)
	return image


func render_preview() -> void:
	var game: Node2D = load("res://main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	await game._open_planet(0)
	game.set_process(false)
	game.notice_timer = 0.0
	game.time_of_day = 0.25
	game.world["creatures"] = []
	game.world["drops"] = []
	game.world["torches"] = {}
	game.world.erase("npc")
	var grid: PackedByteArray = game.world["tiles"]
	var surface: PackedInt32Array = game.world["surface"]
	for x in range(548, 651):
		surface[x] = 90
		for y in range(1, 145):
			WG.set_tile(grid, x, y, 0 if y < 90 else (1 if y == 90 else (2 if y < 102 else 3)))
	var shape := FastNoiseLite.new()
	shape.seed = 19751
	shape.frequency = 0.18
	for x in range(571, 635):
		for y in range(105, 141):
			var radius := pow(float(x - 601) / 28.0, 2.0) + pow(float(y - 123) / 13.0, 2.0)
			if radius + shape.get_noise_2d(x, y) * 0.2 < 1.0:
				WG.set_tile(grid, x, y, 0)
	var rng := RandomNumberGenerator.new()
	rng.seed = 31529
	for x in [571, 583, 633]:
		WG._plant_tree(grid, x, 90, rng)
	# A sealed lake next to a lower excavated basin; opening its wall produces
	# a waterfall and lets the renderer show partial cells and the falling stream.
	for x in range(604, 616):
		for y in range(90, 95):
			WG.set_tile(grid, x, y, 4)
	for x in range(617, 627):
		for y in range(90, 101):
			WG.set_tile(grid, x, y, 0)
	game.world["tiles"] = grid
	game.world["surface"] = surface
	game.world.erase("water")
	game._reset_world_environment()
	game.world_texture = WG.make_texture(grid)
	game.world_image = game.world_texture.get_image()
	game.foliage.reset()
	game.grass_pending.clear()
	game.player_pos = Vector2(600 * 16, 90 * 16 - 29)
	game._update_camera()
	game.weather = "Fog"
	await capture(game, "volumetric_fog_preview")
	game.weather = "Clear"
	game.weather_blend.reset("Clear", int(game.world.get("climate", 0)))
	for y in range(92, 95):
		game._edit_tile(Vector2i(616, y), 0)
	game.world["torches"]["620,97"] = true
	game.environment.invalidate()
	for _step in range(12):
		game._update_water(0.08)
		game.animation_clock += 0.08
	await capture(game, "waterfall_preview")
	for _step in range(160):
		game._update_water(0.08)
		game.animation_clock += 0.08
	await capture(game, "water_settled_preview")
	game._fell_tree(Vector2i(583, 89))
	for _step in range(8):
		game._update_drops(0.1)
	await capture(game, "tree_item_frames_preview")
	game.world["drops"] = []
	game.world["torches"] = {}
	game.notice_timer = 0.0
	grid = game.world["tiles"]
	var floor_y := 135
	for y in range(124, 141):
		if WG.is_solid(WG.tile_at(grid, 598, y)):
			floor_y = y
			break
	game.player_pos = Vector2(598 * 16, floor_y * 16 - 28)
	game._update_camera()
	game.environment.invalidate()
	await capture(game, "cave_dark_preview")
	for at in [Vector2i(586, 120), Vector2i(600, 119), Vector2i(616, 123), Vector2i(598, floor_y - 2)]:
		game._edit_tile(at, 0)
		game.world["torches"]["%d,%d" % [at.x, at.y]] = true
	game.environment.invalidate()
	var clear := await capture(game, "cave_torches_preview")
	game.weather = "Fog"
	var fog := await capture(game, "cave_fog_exclusion_preview")
	var maximum_difference := 0.0
	for y in range(180, 600, 21):
		for x in range(24, 1250, 23):
			var a := clear.get_pixel(x, y)
			var b := fog.get_pixel(x, y)
			var difference := absf(a.r - b.r) + absf(a.g - b.g) + absf(a.b - b.b)
			maximum_difference = maxf(maximum_difference, difference)
	if maximum_difference > 0.01:
		printerr("Surface fog changed an underground pixel: ", maximum_difference)
		quit(1)
		return
	print("RENDERED surface fog, waterfall, settled water, framed tree drops and cave lighting")
	print("FOG_EXCLUSION underground pixels match with fog enabled/disabled")
	quit(0)
