extends "res://tests/ground_life_preview.gd"


func preview() -> void:
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	await show_world(game, 0, 1, "station_landscape_preview")
	game.set_process(false)
	var x := floori(game.player_pos.x / 16) + 2
	var y := int(game.world["surface"][x]) - 1
	# Make a small supported patch within the real forest for the three props.
	for column in range(x - 4, x + 8):
		for row in range(y - 3, y + 1):
			game._edit_tile(Vector2i(column, row), 0, false)
		game._edit_tile(Vector2i(column, y + 1), 1, false)
	game.world_texture.update(game.world_image)
	game.player_pos = Vector2((x - 2) * 16, (y + 1) * 16 - 28)
	game._update_camera()
	game.inventory = {"Workbench": 1, "Furnace": 1, "Chest": 1, "Wood": 30, "Stone": 24, "Corn": 8,
		"Copper Ore": 12, "Coal Ore": 12, "Planks": 8, "Stick": 4}
	for item in ["Workbench", "Furnace", "Chest"]:
		var tile := Vector2i(x, y)
		game._equip_inventory_item(item)
		game._place(Vector2(tile * 16) + Vector2(8, 8) - game.camera_pos)
		game._refresh_hotbar()
		game._set_mouse_world_target(Vector2(tile * 16) + Vector2(8, 8))
		await capture(game, "interact_" + str(item).to_lower() + "_prompt_preview")
		game._key_pressed(KEY_F)
		if item == "Chest":
			game.interactions.deposit("Wood", 20)
			game.interactions.deposit("Stone", 12)
			game.interactions.deposit("Copper Ore", 6)
		await capture(game, "interact_" + str(item).to_lower() + "_preview")
		game._key_pressed(KEY_F)
		game._edit_tile(tile, 0)
		if item != "Chest":
			game._edit_tile(tile + Vector2i.RIGHT, 0)
	print("STATION_PREVIEW hotbar placement, F prompts, station menus and paired chest/backpack windows rendered")
	quit()
