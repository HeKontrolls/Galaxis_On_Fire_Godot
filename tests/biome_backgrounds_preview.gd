extends SceneTree

const WG = preload("res://scripts/world_gen.gd")

func _initialize() -> void:
	call_deferred("run")

func locate(game, biome: int) -> void:
	var columns: PackedByteArray = game.world["biomes"]
	var x := 600
	for candidate in range(80, 1120):
		if columns[candidate] == biome and columns[candidate - 24] == biome and columns[candidate + 24] == biome:
			x = candidate + 24
			break
	var y := 1
	while y < WG.HEIGHT - 2 and not WG.is_solid(WG.tile_at(game.world["tiles"], x, y)):
		y += 1
	game.player_pos = Vector2(x * 16, y * 16 - 28)
	game._update_camera()

func capture(game, name: String) -> Image:
	game.queue_redraw()
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	# Keep only the current documentation images; other frames feed the overview.
	if name in ["biome_background_forest", "biome_background_forest_night", "biome_background_frozen_night"] or "--all" in OS.get_cmdline_user_args():
		image.save_png("res://tests/" + name + ".png")
	return image

func run() -> void:
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.set_process(false)
	game.galaxy_seed = 741927
	game._make_system()
	var review := Image.create(1280, 1440, false, Image.FORMAT_RGBA8)
	var names := ["forest", "islands", "continents", "desert", "volcanic", "barren", "frozen", "tundra"]
	var biomes := [2, 1, 1, 2, 3, 3, 2, 1]
	for climate in range(8):
		await game._open_planet(climate)
		game.world["creatures"] = []
		game.world.erase("npc")
		game.weather = "Clear"
		game.weather_blend.reset("Clear", climate)
		game.time_of_day = 0.25
		game.cloud_cover = 0.26
		game.animation_clock = 42
		game.notice_timer = 0
		locate(game, biomes[climate])
		var image: Image = await capture(game, "biome_background_" + names[climate])
		image.resize(640, 360, Image.INTERPOLATE_NEAREST)
		review.blit_rect(image, Rect2i(0, 0, 640, 360), Vector2i(climate % 2 * 640, climate / 2 * 360))
		if climate in [0, 6]:
			game.time_of_day = 0.75
			await capture(game, "biome_background_" + names[climate] + "_night")
	review.save_png("res://tests/biome_backgrounds_overview.png")
	game.queue_free()
	await process_frame
	print("BIOME_BACKGROUNDS_PREVIEW eight climates plus forest/frozen nights")
	quit()
