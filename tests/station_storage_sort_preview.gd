extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func capture(game, name: String) -> void:
	game.notice_timer = 0
	game.queue_redraw()
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://tests/" + name + ".png")

func run() -> void:
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.set_process(false)
	game.galaxy_seed = 741927
	await game._open_planet(0)
	game.world["creatures"] = []
	game.world.erase("npc")
	game.weather = "Clear"
	game.weather_blend.reset("Clear", 0)
	game.time_of_day = 0.25
	game.inventory = {"Corn": 4, "Wood": 20, "Copper Ore": 12, "Iron Ore": 6, "Coal Ore": 24,
		"Gold Ore": 4, "Planks": 24, "Stick": 30, "Stone": 12, "Iron Pickaxe": 1, "Copper Pickaxe": 2,
		"Iron Ingot": 16, "Gold Ingot": 8, "Netherite Scrap": 8}
	game.hotbar.clear()
	game._equip_inventory_item("Iron Pickaxe")
	game._wear_pickaxe("Iron Pickaxe", 63)
	var x := floori(game.player_pos.x / 16)
	var y := int(game.world["surface"][x]) - 1
	game._edit_tile(Vector2i(x + 2, y), 34)
	game._edit_tile(Vector2i(x + 3, y), 36)
	game._edit_tile(Vector2i(x - 3, y), 35)
	game._edit_tile(Vector2i(x - 2, y), 37)
	game.stations.open({"name": "Workbench", "tile": Vector2i(x + 2, y)})
	for entry in [["Wood", 6, 0], ["Planks", 12, 1], ["Stick", 20, 2], ["Iron Pickaxe", 1, 3], ["Copper Pickaxe", 2, 4], ["Iron Ingot", 16, 5]]:
		game.stations.deposit(str(entry[0]), int(entry[1]), "input", int(entry[2]))
	game.stations.craft(19)
	game.stations.state()["recipe"] = 19
	game.stations.page = game.stations.recipes().find(19) / 5
	await capture(game, "workbench_slots_preview")
	game.stations.open({"name": "Furnace", "tile": Vector2i(x - 3, y)})
	for item: String in ["Copper Ore", "Iron Ore", "Gold Ore", "Corn", "Netherite Scrap", "Gold Ingot", "Coal Ore"]:
		game.stations.deposit(item)
	game.furnaces.update(17.0)
	await capture(game, "furnace_slots_preview")
	game.stations.close(false)
	game.inventory["Iron Sword"] = 1
	game.inventory["Wood Shovel"] = 0
	game.inventory["Iron Shovel"] = 1
	game.inventory["Corn"] = 3
	game.inventory["Coal Ore"] = 8
	game.inventory["Copper Ore"] = 2
	game.inventory["Wildflower"] = 3
	game._sort_inventory()
	await capture(game, "inventory_sort_preview")
	print("RENDERED separate workbench/furnace slot windows and sorted backpack")
	quit()
