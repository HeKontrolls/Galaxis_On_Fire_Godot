extends SceneTree

const WG = preload("res://scripts/world_gen.gd")


func _initialize() -> void:
	call_deferred("preview")


func capture(game, name: String) -> void:
	game.queue_redraw()
	await process_frame
	await process_frame
	root.get_texture().get_image().save_png("res://tests/%s.png" % name)


func fixture(game, floor_y: int) -> void:
	var grid := PackedByteArray()
	grid.resize(WG.WIDTH * WG.HEIGHT)
	for x in range(WG.WIDTH):
		for y in range(floor_y, WG.HEIGHT):
			WG.set_tile(grid, x, y, 3)
	var surface := PackedInt32Array()
	surface.resize(WG.WIDTH)
	surface.fill(floor_y)
	game.world = {"tiles": grid, "surface": surface, "seed": 713, "climate": 4,
		"spawn": Vector2(603 * 16, floor_y * 16 - 28), "crops": {}, "creatures": [],
		"drops": [], "torches": {}, "placed_chests": {}, "forest_density_version": 2}
	game._reset_world_environment()
	game.world_texture = WG.make_texture(grid)
	game.world_image = game.world_texture.get_image()
	game.player_pos = game.world["spawn"]
	game.weather = "Clear"
	game.weather_blend.reset("Clear", int(game.world.get("climate", 0)))
	game.time_of_day = 0.25
	game.animation_clock = 0.0
	game.notice_timer = 0
	game.cloud_cover = 0.3
	game.health = 100
	game._update_camera()


func rectangle(game, bounds: Rect2i, id: int) -> void:
	for y in range(bounds.position.y, bounds.end.y):
		for x in range(bounds.position.x, bounds.end.x):
			game._edit_tile(Vector2i(x, y), id, false)


func preview() -> void:
	var game: Node2D = load("res://main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	await game._open_planet(4)
	game.set_process(false)
	fixture(game, 94)
	for reservoir in [Rect2i(574, 70, 17, 4), Rect2i(614, 70, 17, 4)]:
		var lava: bool = reservoir.position.x > 600
		rectangle(game, Rect2i(reservoir.position.x - 1, 70, 1, 5), 3)
		rectangle(game, Rect2i(reservoir.position.x, 74, reservoir.size.x, 20), 3)
		rectangle(game, reservoir, 11 if lava else 4)
	rectangle(game, Rect2i(600, 85, 8, 9), 3)
	game.world_texture.update(game.world_image)
	game.player_pos = Vector2(603 * 16, 85 * 16 - 28)
	game._update_camera()
	for _frame in range(235):
		game._update_water(0.04)
		game.animation_clock += 0.04
	await capture(game, "smooth_water_lava_cascades")
	# Water enters a separate lava basin. The two screenshots show the
	# actual solid terrain produced by the gameplay reaction service.
	fixture(game, 85)
	rectangle(game, Rect2i(584, 81, 16, 4), 11)
	rectangle(game, Rect2i(583, 80, 1, 5), 3)
	rectangle(game, Rect2i(600, 80, 1, 5), 3)
	rectangle(game, Rect2i(584, 78, 4, 1), 4)
	game.world_texture.update(game.world_image)
	await capture(game, "water_lava_before_contact")
	for _frame in range(200):
		game._update_water(0.04)
		game.animation_clock += 0.04
	await capture(game, "water_lava_obsidian")
	fixture(game, 85)
	rectangle(game, Rect2i(581, 84, 18, 1), 11)
	rectangle(game, Rect2i(580, 83, 1, 2), 3)
	rectangle(game, Rect2i(599, 83, 1, 2), 3)
	rectangle(game, Rect2i(615, 84, 13, 1), 11)
	rectangle(game, Rect2i(614, 83, 1, 2), 3)
	rectangle(game, Rect2i(628, 83, 1, 2), 3)
	rectangle(game, Rect2i(614, 78, 15, 1), 9)
	game.world_texture.update(game.world_image)
	game.weather = "Rain"
	game.cloud_cover = 0.85
	for _hit in range(6):
		for x in range(581, 599):
			game.lava_sim.cool_from_rain(Vector2i(x, 84), 3)
	game.fluid_reactions.update(game, 0.1, PackedInt32Array())
	game.animation_clock = 10
	await capture(game, "rain_lava_cooling")
	for _hit in range(5):
		for x in range(581, 599):
			game.lava_sim.cool_from_rain(Vector2i(x, 84), 3)
	game.fluid_reactions.update(game, 0.1, PackedInt32Array())
	game.fluid_reactions.update(game, 0.25, PackedInt32Array())
	await capture(game, "rain_lava_obsidian")
	print("RENDERED connected cascades, contact obsidian, rain cooling and roof-protected lava")
	quit(0)
