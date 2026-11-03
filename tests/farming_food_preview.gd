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
	for kind in range(5):
		for stage in range(3):
			var x := 579 + kind * 7 + stage * 2
			WG.set_tile(grid, x, 80, 13)
			WG.set_tile(grid, x, 79, 14 + stage)
		var channel := 579 + kind * 7 + 5
		WG.set_tile(grid, channel, 80, 4)
		WG.set_tile(grid, channel, 81, 4)
	var rng := RandomNumberGenerator.new()
	rng.seed = 31529
	WG._plant_tree(grid, 573, 80, rng)
	WG._plant_tree(grid, 633, 80, rng)
	WG.set_tile(grid, 617, 79, 35)
	WG.set_tile(grid, 618, 79, 37)
	WG.set_tile(grid, 621, 79, 34)
	WG.set_tile(grid, 622, 79, 36)
	game.expedition.data.clear()
	game.world["ground_life"] = []
	game.world["ground_life_version"] = 1
	game.world["ground_cover_version"] = 1
	game.world["surface_rocks_version"] = 1
	game.world["vines"] = []
	game.world["vines_version"] = 1
	game.world["tiles"] = grid
	game.world["surface"] = surface
	game.world.erase("water")
	game.world.erase("rain_water")
	game._reset_world_environment()
	var crops := ["Corn","Carrot","Potato","Tomato","Wheat"]
	for kind in range(5):
		for stage in range(3):
			var point := "%d,79" % (579 + kind * 7 + stage * 2)
			game.farming.plants[point].crop = crops[kind]
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
	game.inventory = {"Hoe": 1, "Watering Can": 1, "Crop Seeds": 18, "Corn": 12, "Roasted Corn": 3, "Wood": 16, "Torch": 4, "Carrot Seeds": 12, "Seed Potato": 12, "Tomato Seeds": 12, "Wheat Seeds": 12, "Carrot": 6, "Potato": 6, "Tomato": 6, "Wheat": 6, "Baked Potato": 2, "Tomato Soup": 2, "Bread": 2, "Vegetable Stew": 2}
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
	game.stations.open({"name":"Furnace","tile":Vector2i(617,79)})
	game.stations.deposit("Carrot",1)
	game.stations.deposit("Potato",1)
	game.stations.deposit("Tomato",1)
	game.stations.deposit("Wood",1)
	game.furnaces.update(7)
	await capture(game, "farming_food_cooking_preview")
	print("RENDERED edible crops, food icons, eating feedback, backpack and furnace cooking")
	quit(0)
