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
	game.time_of_day = 0.25
	game.weather = "Clear"
	game.weather_blend.reset("Clear", int(game.world.get("climate", 0)))
	game.animation_clock = 14.0
	game.cloud_cover = 0.25
	var grid: PackedByteArray = game.world["tiles"]
	var surface: PackedInt32Array = game.world["surface"]
	for x in range(540, 661):
		surface[x] = 80
		for y in range(1, 125):
			WG.set_tile(grid, x, y, 0 if y < 80 else (1 if y == 80 else (2 if y < 95 else 3)))
	for x in range(585, 603):
		WG.set_tile(grid, x, 80, 13 if x % 2 else 12)
		if x % 3 != 0:
			WG.set_tile(grid, x, 79, 14 + int((x - 585) / 6))
	var rng := RandomNumberGenerator.new()
	rng.seed = 31529
	WG._plant_tree(grid, 573, 80, rng)
	WG._plant_tree(grid, 633, 80, rng)
	WG.set_tile(grid, 611, 79, 35)
	WG.set_tile(grid, 612, 79, 37)
	WG.set_tile(grid, 615, 79, 34)
	WG.set_tile(grid, 616, 79, 36)
	game.world["tiles"] = grid
	game.world["surface"] = surface
	game.world.erase("water")
	game.world.erase("rain_water")
	game._reset_world_environment()
	game.world_texture = WG.make_texture(grid)
	game.world_image = game.world_texture.get_image()
	game.foliage.reset()
	game.grass_pending.clear()
	game.player_pos = Vector2(607 * 16, 80 * 16 - 29)
	game.player_grounded = true
	game._update_camera()
	game.equipped_tool = "Hoe"
	game.use_hoe = true
	game.use_pickaxe = false
	game.inventory = {"Hoe": 1, "Watering Can": 1, "Crop Seeds": 18, "Corn": 12, "Roasted Corn": 3, "Wood": 16, "Torch": 4}
	game._equip_inventory_item("Corn")
	game.health = 40
	game._eat_food("Corn")
	game._update_food_feedback(0.25)
	await capture(game, "farming_food_eating_preview")
	game._update_food_feedback(3.0)
	game.notice_timer = 0.0
	game.inventory_open = true
	await capture(game, "farming_food_backpack_preview")
	game.inventory_open = false
	game.crafting_open = true
	game._set_recipe_tab(2)
	game.recipe_index = 14
	await capture(game, "farming_food_cooking_preview")
	print("RENDERED edible crops, food icons, eating feedback, backpack and furnace cooking")
	quit(0)
