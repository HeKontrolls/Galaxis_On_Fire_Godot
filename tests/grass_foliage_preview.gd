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
	game.time_of_day = 0.25
	game.notice_timer = 0.0
	game.world["creatures"] = []
	game.world.erase("npc")
	game.world["seed"] = 531209
	var grid := PackedByteArray()
	grid.resize(WG.WIDTH * WG.HEIGHT)
	var surface := PackedInt32Array()
	surface.resize(WG.WIDTH)
	surface.fill(130)
	for x in range(WG.WIDTH):
		for y in range(130, WG.HEIGHT):
			WG.set_tile(grid, x, y, 1 if y == 130 else (2 if y < 138 else 3))
	var rng := RandomNumberGenerator.new()
	rng.seed = 31529
	for x in [580, 588, 609, 625]:
		WG._plant_tree(grid, x, 130, rng)
	game.world["tiles"] = grid
	game.world["surface"] = surface
	game.world.erase("water")
	game._reset_world_environment()
	game.world_texture = WG.make_texture(grid)
	game.world_image = game.world_texture.get_image()
	game.foliage.reset()
	game.grass_pending.clear()
	game.player_pos = Vector2(600 * 16, 130 * 16 - 29)
	game._update_camera()
	for x in range(596, 599):
		game._edit_tile(Vector2i(x, 130), 0)
		game._edit_tile(Vector2i(x, 131), 0)
	await capture(game, "grass_before_preview")
	game._update_grass(6.0)
	var day := await capture(game, "grass_after_preview")
	day.save_png("res://tests/trees_pixel_preview.png")
	game.time_of_day = 0.48
	var dusk := await capture(game, "foliage_dusk_preview")
	var probe_tile := Vector2i(588, 128)
	var probe := Vector2i(Vector2(probe_tile * 16) - game.camera_pos + Vector2(0, 1))
	game._edit_tile(probe_tile, 0)
	game.queue_redraw()
	await process_frame
	await process_frame
	var without_tree := root.get_texture().get_image()
	var before := dusk.get_pixelv(probe)
	var after := without_tree.get_pixelv(probe)
	var error := absf(before.r - after.r) + absf(before.g - after.g) + absf(before.b - after.b)
	if error > 0.01:
		printerr("Transparent part of trunk still draws a lighting box: ", error)
		quit(1)
		return
	game._edit_tile(probe_tile, 7)
	game.time_of_day = 0.25
	game._fell_tree(Vector2i(609, 129))
	for _step in range(8):
		game._update_drops(0.1)
	await capture(game, "trees_falling_preview")
	print("RENDERED grass before/after and dusk foliage; transparent trunk pixel matches sky")
	quit(0)
