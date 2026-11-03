extends "res://tests/tool_progression_check.gd"


func run_check() -> void:
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	await game._open_planet(0)
	game.set_process(false)
	var names := ["Pickaxe", "Gold Pickaxe", "Stone Pickaxe", "Copper Pickaxe", "Iron Pickaxe", "Diamond Pickaxe", "Netherite Pickaxe"]
	var levels := [0, 0, 1, 1, 2, 3, 4]
	var lives := [59, 32, 131, 191, 250, 1561, 2031]
	var speeds := [2, 12, 4, 5, 6, 8, 9]
	var bonuses := [0, 0, 1, 1, 2, 3, 4]
	var tile_levels := {3: 0, 20: 0, 21: 1, 22: 1, 23: 2, 24: 2, 25: 2, 17: 3, 26: 3}
	for i in range(names.size()):
		var item: String = names[i]
		check(Tools.mining_level(item) == levels[i] and Tools.max_durability(item) == lives[i]
			and is_equal_approx(Tools.mining_interval(item), Tools.MINING_SWING) and is_equal_approx(Tools.mining_damage(item, 3), speeds[i] * 4.0) and Tools.damage(item) == 7 + bonuses[i], "Exact table: " + item)
		for id: int in tile_levels:
			fixture(game)
			game.tool_wear.uses.clear()
			game.inventory = {item: 1}
			game._equip_inventory_item(item)
			var at := Vector2i(601, 80)
			game._edit_tile(at, id)
			for hit in range(Tools.mining_hits(item, id)):
				game.mining_cooldown = 0
				game._mine(Vector2(at * 16) + Vector2(8, 8) - game.camera_pos)
			var allowed: bool = levels[i] >= tile_levels[id]
			check((WG.tile_at(game.world["tiles"], at.x, at.y) == 0) == allowed, "Harvest gate: %s / %d" % [item, id])
			check(game.world["drops"].size() == (1 if allowed else 0), "No forbidden drops: " + item)
			check(game.tool_wear.remaining(item, game.inventory) == lives[i] - (1 if allowed else 0), "Wear only on successful harvest: " + item)
		fixture(game)
		game.tool_wear.uses.clear()
		game.inventory = {item: 2}
		game._equip_inventory_item(item)
		for use in range(lives[i]):
			game._wear_pickaxe(item)
			check(int(game.inventory[item]) == (1 if use == lives[i] - 1 else 2), "Exact break count: " + item)
		check(game.tool_wear.remaining(item, game.inventory) == lives[i], "Next stacked tool starts fresh")
	check(Tools.best_owned({"Gold Pickaxe": 1, "Stone Pickaxe": 1}, "Pickaxe") == "Stone Pickaxe", "Gold cannot supersede a higher harvest level")
	check(not Tools.can_harvest("Iron Axe", 22) and not Tools.can_harvest("Hand", 3), "Correct tool family required")
	fixture(game)
	game.tool_wear.uses.clear()
	game.inventory = {"Diamond Pickaxe": 1}
	game._equip_inventory_item("Diamond Pickaxe")
	game._wear_pickaxe("Diamond Pickaxe", 81)
	game._stage_trash("Diamond Pickaxe")
	game._return_trash()
	check(game.tool_wear.remaining("Diamond Pickaxe", game.inventory) == 1480, "Trash cannot repair tools")
	game._edit_tile(Vector2i(602, 79), 30)
	game.world["placed_chests"]["602,79"] = true
	game.interactions.interact()
	check(game.interactions.deposit("Diamond Pickaxe"), "Deposit worn tool")
	game.save_path = "user://galaxis_mining_levels_check.json"
	game._save_game()
	game._load_game()
	while game.scene_name == "loading": await process_frame
	game.interactions.chest_key = "602,79"
	game.inventory_open = true
	game.interactions.withdraw("Diamond Pickaxe")
	check(game.tool_wear.remaining("Diamond Pickaxe", game.inventory) == 1480, "Chest save/load preserves wear")
	game.interactions.deposit("Diamond Pickaxe")
	game.interactions.close()
	game.inventory["Pickaxe"] = 1
	game._equip_inventory_item("Pickaxe")
	var at := Vector2i(602, 79)
	for hit in range(Tools.mining_hits("Pickaxe", 30)):
		game.mining_cooldown = 0
		game._mine(Vector2(at * 16) + Vector2(8, 8) - game.camera_pos)
	for drop: Dictionary in game.world["drops"].duplicate():
		if drop["item"] == "Diamond Pickaxe":
			game._collect_drop(drop)
	check(game.tool_wear.remaining("Diamond Pickaxe", game.inventory) == 1480, "Mining chest and pickup preserve wear")
	game._equip_inventory_item("Diamond Pickaxe")
	game._save_game()
	game._load_game()
	while game.scene_name == "loading": await process_frame
	check(game.tool_wear.remaining("Diamond Pickaxe", game.inventory) == 1480, "Carried tool saves preserve wear")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(game.save_path))
	for output: String in ["Gold Pickaxe", "Diamond Pickaxe", "Netherite Scrap", "Netherite Ingot", "Netherite Pickaxe"]:
		fixture(game)
		game._edit_tile(Vector2i(603, 79), 34)
		game._edit_tile(Vector2i(597, 79), 35)
		game.recipe_index = recipe(game, output)
		var needs: Dictionary = game.RECIPES[game.recipe_index]["needs"]
		game.inventory = needs.duplicate()
		craft_at_station(game, output)
		check(game.inventory.get(output, 0) == 1, "Obtainable recipe: " + output)
		for ingredient in needs:
			check(game.inventory.get(ingredient, 0) == 0, "Recipe consumes " + ingredient)
	for climate in [0, 4, 5]:
		var world := WG.generate(741927, climate)
		var counts := {25: 0, 26: 0}
		for id: int in world["tiles"]:
			if counts.has(id):
				counts[id] += 1
		check(counts[25] > 0 and (counts[26] > 0 if climate in [4, 5] else counts[26] == 0), "Obtainable deep minerals climate " + str(climate))
	print("MINING_LEVELS seven profiles, 63 harvest cases, exact break counts, chest/trash/drop/save durability, advanced recipes and resource generation; failures=", failures)
	quit(0 if failures == 0 else 1)
