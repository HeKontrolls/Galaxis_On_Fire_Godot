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
	await game._open_planet(0)
	game.set_process(false)
	game.world["creatures"] = []
	game.world["drops"] = []
	game.world["torches"] = {}
	game.world.erase("npc")
	game.notice_timer = 0.0
	game.time_of_day = 0.25
	game.weather = "Rain"
	game.animation_clock = 16.0
	game.cloud_cover = 0.93
	var grid: PackedByteArray = game.world["tiles"]
	var surface: PackedInt32Array = game.world["surface"]
	for x in range(540, 661):
		surface[x] = 80
		for y in range(1, 115):
			WG.set_tile(grid, x, y, 0 if y < 80 else (1 if y == 80 else (2 if y < 94 else 3)))
	for x in range(578, 603):
		WG.set_tile(grid, x, 80, 13 if x % 2 else 12)
		if x % 3 != 0:
			WG.set_tile(grid, x, 79, 14 + (int((x - 578) / 8) % 3))
	for x in range(612, 630):
		for y in range(80, 83):
			WG.set_tile(grid, x, y, 0)
	for ore in range(5):
		for x in range(583 + ore * 5, 586 + ore * 5):
			WG.set_tile(grid, x, 86, 20 + ore)
	game.world["tiles"] = grid
	game.world["surface"] = surface
	game.world.erase("water")
	game.world.erase("rain_water")
	game._reset_world_environment()
	game.world_texture = WG.make_texture(grid)
	game.world_image = game.world_texture.get_image()
	game.foliage.reset()
	game.grass_pending.clear()
	game.player_pos = Vector2(606 * 16, 80 * 16 - 29)
	game._update_camera()
	game.equipped_tool = "Watering Can"
	game.use_pickaxe = false
	game.inventory = {"Hoe": 1, "Watering Can": 1, "Crop Seeds": 18, "Corn": 8,
		"Coal Ore": 12, "Copper Ore": 12, "Iron Ore": 12, "Gold Ore": 12, "Crystal": 4}
	game._equip_inventory_item("Crop Seeds")
	for _tick in range(125):
		game._update_water(0.2)
	# Show the labeled underground ore strip without changing gameplay lighting.
	for ore in range(5):
		game.world["torches"]["%d,85" % (584 + ore * 5)] = true
	game.environment.invalidate()
	await capture(game, "rain_farming_ore_surface")
	game.inventory_open = true
	await capture(game, "rain_farming_ore_backpack")
	game.inventory_open = false
	game.weather = "Clear"
	game.weather_blend.reset("Clear", int(game.world.get("climate", 0)))
	game.cloud_cover = 0.15
	for _second in range(300):
		game._update_water(1.0)
	await capture(game, "rain_farming_ore_dry")
	print("RENDERED farming stages, soil, rain puddles, dry weather and periodic ore badges")
	quit(0)
