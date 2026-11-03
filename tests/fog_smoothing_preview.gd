extends SceneTree

const WG = preload("res://scripts/world_gen.gd")


func _initialize() -> void:
	call_deferred("preview")


func preview() -> void:
	var game: Node2D = load("res://main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	await game._open_planet(0)
	game.set_process(false)
	game.world["creatures"] = []
	game.world["drops"] = []
	game.world["torches"] = {}
	game.world.erase("npc")
	game.notice_timer = 0.0
	game.time_of_day = 0.32
	game.weather = "Fog"
	game.animation_clock = 19.0
	game.cloud_cover = 0.32
	var grid: PackedByteArray = game.world["tiles"]
	var surface: PackedInt32Array = game.world["surface"]
	for x in range(540, 661):
		var y_surface := 96 + roundi(sin((x - 570) * 0.09) * 5 + sin((x - 570) * 0.22) * 2)
		surface[x] = y_surface
		for y in range(1, 145):
			WG.set_tile(grid, x, y, 0 if y < y_surface else (1 if y == y_surface else (2 if y < y_surface + 15 else 3)))
	# A deep shaft must remain clear of fog even though it is open to the sky.
	for x in range(579, 582):
		for y in range(surface[x], 142):
			WG.set_tile(grid, x, y, 0)
	game.world["tiles"] = grid
	game.world["surface"] = surface
	game.world.erase("water")
	game.world.erase("rain_water")
	game._reset_world_environment()
	game.world_texture = WG.make_texture(grid)
	game.world_image = game.world_texture.get_image()
	game.foliage.reset()
	game.grass_pending.clear()
	game.player_pos = Vector2(603 * 16, surface[603] * 16 - 29)
	game._update_camera()
	game.queue_redraw()
	await process_frame
	await process_frame
	var args := OS.get_cmdline_user_args()
	var name := args[0] if not args.is_empty() else "fog_smooth_preview"
	root.get_texture().get_image().save_png("res://tests/%s.png" % name)
	print("FOG_PREVIEW ", name)
	quit(0)
