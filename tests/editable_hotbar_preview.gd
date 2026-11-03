extends "res://tests/ground_life_preview.gd"

const Tools = preload("res://scripts/tool_catalog.gd")


func preview() -> void:
	var game = load("res://main.tscn").instantiate()
	game.settings_path = "user://editable_hotbar_preview_settings.json"
	root.add_child(game)
	await process_frame
	game.set_process(false)
	game.new_game_name = "John"
	game.seed_text = "713"
	game._start_new_game()
	await show_world(game, 0, 1, "empty_hotbar_gameplay_preview")
	game.inventory_open = true
	await capture(game, "empty_inventory_preview")
	for item: String in game.ITEM_CATALOG + game.tool_textures.keys() + ["Hoe", "Watering Can", "Torch", "Coal Ore", "Copper Ore", "Iron Ore", "Gold Ore", "Crystal"]:
		game.inventory[item] = 1 if game.tool_textures.has(item) else 32
	var quick := ["Copper Pickaxe", "Axe", "Sword", "Hoe", "Watering Can", "Torch", "Corn", "Dirt", "Workbench"]
	for index in range(quick.size()):
		game.hotbar.assign(quick[index], index, game.inventory)
	game._select_hotbar_slot(0)
	game.inventory_open = true
	game.inventory_page = 0
	await capture(game, "editable_hotbar_preview")
	game.hotbar.assign("Iron Ore", 18, game.inventory)
	game.hotbar.assign("Mossy Boulder", 19, game.inventory)
	game.hotbar.assign("Wildflower", 20, game.inventory)
	game._scroll_hotbar(2, true)
	game.inventory_page = 1
	await capture(game, "extra_hotbar_preview")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(game.settings_path))
	print("EDITABLE_HOTBAR_PREVIEW empty new game, empty backpack, editable tools/items and extra pages rendered")
	quit()
