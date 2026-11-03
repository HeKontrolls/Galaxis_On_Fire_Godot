extends SceneTree

const WG = preload("res://scripts/world_gen.gd")
const Tools = preload("res://scripts/tool_catalog.gd")
var failures := 0


func _initialize() -> void:
	call_deferred("run_check")


func check(ok: bool, label: String) -> void:
	if not ok:
		failures += 1
		printerr(label)


func fixture(game) -> void:
	game.stations.close()
	var grid := PackedByteArray()
	grid.resize(WG.WIDTH * WG.HEIGHT)
	for x in range(WG.WIDTH):
		WG.set_tile(grid, x, 80, 3)
	var surface := PackedInt32Array()
	surface.resize(WG.WIDTH)
	surface.fill(80)
	game.world = {"tiles": grid, "surface": surface, "seed": 713, "climate": 0,
		"spawn": Vector2(600 * 16, 80 * 16 - 28), "crops": {}, "creatures": [],
		"drops": [], "torches": {}, "placed_chests": {}, "forest_density_version": 2,
		"background_ore_version": 1, "background_ores": [], "cave_life_version": 1,
		"ground_life_version": 1, "ground_cover_version": 1, "surface_rocks_version": 1,
		"vines_version": 1, "underground_version": 1, "underworld_structures_version": 1}
	game.worlds[game._world_key()] = game.world
	game._reset_world_environment()
	game.world_texture = WG.make_texture(game.world["tiles"])
	game.world_image = game.world_texture.get_image()
	game.player_pos = game.world["spawn"]
	game.player_velocity = Vector2.ZERO
	game._update_camera()
	game.weather = "Clear"
	game.weather_blend.reset("Clear", int(game.world.get("climate", 0)))
	game.time_of_day = 0.25
	game.paused = false
	game.crafting_open = false
	game.inventory_open = false
	game.dialogue_open = false
	game.dev_mode = false
	game.inventory = {}
	game.inventory_trash.clear()
	game.equipped_tool = "Hand"
	game.use_pickaxe = false
	game.use_hoe = false
	game.mining_cooldown = 0
	game.attack_cooldown = 0
	game.tool_action_timer = 0
	game._stop_held_actions()


func recipe(game, output: String) -> int:
	for index in range(game.RECIPES.size()):
		if game.RECIPES[index]["out"] == output:
			return index
	return -1


func mouse(game, at: Vector2, pressed: bool) -> void:
	var event := InputEventMouseButton.new()
	event.position = at
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = pressed
	game._input(event)


func craft_at_station(game, output: String) -> bool:
	var index := recipe(game, output)
	var definition: Dictionary = game.RECIPES[index]
	game.recipe_index = index
	if not definition.has("station"):
		game._craft()
		return true
	for item in definition["needs"]:
		if int(game.inventory.get(item, 0)) < int(definition["needs"][item]):
			return false
	var selected: Dictionary = game.interactions.target(str(definition["station"]))
	if selected.is_empty():
		return false
	game.stations.open(selected)
	for item in definition["needs"]:
		game.stations.deposit(str(item), int(definition["needs"][item]))
	var made := true
	if definition["station"] == "Furnace":
		game.furnaces.update(5.0 + float(game.FurnaceSystem.TIMES.get(output, 6.0)))
	else:
		made = game.stations.craft(index)
	while not game.stations.state()["output"].is_empty():
		game.stations.withdraw("output", 0)
	for slot in range(game.stations.input_slots().size()):
		game.stations.withdraw("input", slot)
	if game.stations.kind == "furnace":
		game.stations.withdraw("fuel", 0)
	game.stations.close()
	if Tools.has_item(output) and int(game.inventory.get(output, 0)) > 0:
		game._equip_inventory_item(output)
	return made


func check_crafting(game) -> void:
	for base in ["Pickaxe", "Sword", "Axe"]:
		fixture(game)
		game._edit_tile(Vector2i(603, 79), 34)
		game._edit_tile(Vector2i(604, 79), 36)
		game.inventory = {"Planks": 6, "Stick": 12 if base == "Pickaxe" else 10,
			"Stone": 6, "Copper Ore": 6, "Iron Ore": 8, "Coal Ore": 14}
		game.recipe_index = recipe(game, base)
		craft_at_station(game, str(game.RECIPES[game.recipe_index]["out"]))
		check(game.inventory[base] == 1 and game.inventory["Planks"] == 0,
			"The base " + base + " must be craftable at a workbench")
		game._equip_inventory_item(base)
		var before: Dictionary = game.inventory.duplicate()
		game.recipe_index = recipe(game, "Copper " + base)
		craft_at_station(game, str(game.RECIPES[game.recipe_index]["out"]))
		check(before == game.inventory, "Missing upgrade ingots must not consume materials")
		game._edit_tile(Vector2i(597, 79), 35)
		game._edit_tile(Vector2i(598, 79), 37)
		game.recipe_index = recipe(game, "Copper Ingot")
		for _ingot in range(6):
			craft_at_station(game, str(game.RECIPES[game.recipe_index]["out"]))
		game.recipe_index = recipe(game, "Iron Ingot")
		for _ingot in range(8):
			craft_at_station(game, str(game.RECIPES[game.recipe_index]["out"]))
		check(game.inventory["Coal Ore"] == 0 and game.inventory["Copper Ore"] == 0
			and game.inventory["Iron Ore"] == 0, "Smelting upgrades must consume actual ore and coal")
		game.recipe_index = recipe(game, "Iron " + base)
		before = game.inventory.duplicate()
		craft_at_station(game, str(game.RECIPES[game.recipe_index]["out"]))
		check(before == game.inventory, "Iron upgrades must require the copper predecessor")
		var previous: String = base
		if base == "Pickaxe":
			game.recipe_index = recipe(game, "Copper Pickaxe")
			before = game.inventory.duplicate()
			craft_at_station(game, str(game.RECIPES[game.recipe_index]["out"]))
			check(before == game.inventory, "Copper pickaxes must require stone; wood cannot skip the stone tier")
			game.recipe_index = recipe(game, "Cobblestone")
			for _block in range(6):
				craft_at_station(game, str(game.RECIPES[game.recipe_index]["out"]))
			game.recipe_index = recipe(game, "Stone Pickaxe")
			craft_at_station(game, str(game.RECIPES[game.recipe_index]["out"]))
			check(game.inventory["Pickaxe"] == 0 and game.inventory.get("Stone Pickaxe", 0) == 1
				and game.inventory["Cobblestone"] == 0 and game.inventory["Stick"] == 7,
				"Stone must consume the wood pickaxe, six cobblestone and two sticks")
			check(game.equipped_tool == "Stone Pickaxe" and game.use_pickaxe,
				"Upgrading wood to stone must equip a working stone pickaxe")
			previous = "Stone Pickaxe"
		game.recipe_index = recipe(game, "Copper " + base)
		craft_at_station(game, str(game.RECIPES[game.recipe_index]["out"]))
		check(game.inventory[previous] == 0 and game.inventory["Copper " + base] == 1
			and game.inventory["Copper Ingot"] == 0 and game.inventory["Stick"] == 4,
			"Copper upgrades must consume their predecessor, six ingots and three sticks")
		check(game.equipped_tool == "Copper " + base, "The tool taken from output must be equippable")
		game.recipe_index = recipe(game, "Iron " + base)
		craft_at_station(game, str(game.RECIPES[game.recipe_index]["out"]))
		check(game.inventory["Copper " + base] == 0 and game.inventory["Iron " + base] == 1
			and game.inventory["Iron Ingot"] == 0 and game.inventory["Stick"] == 0,
			"Iron upgrades must consume the copper tool, eight ingots and four sticks")
		check(game.notice.contains("Iron " + base) and Tools.summary("Iron " + base).contains("damage"),
			"Crafting feedback must identify the upgraded tool and its improved stats")
		check(game.equipped_tool == "Iron " + base and game.use_pickaxe == (base == "Pickaxe"),
			"Every upgraded tool must retain its family behavior")
		before = game.inventory.duplicate()
		craft_at_station(game, str(game.RECIPES[game.recipe_index]["out"]))
		check(before == game.inventory, "Repeated unavailable upgrades must not duplicate items")
	print("CRAFTING wood -> stone -> copper -> iron pickaxes; wood -> copper -> iron swords/axes; costs and stations checked")


func mining_run(game, item: String, fps: int, tile_id: int) -> int:
	fixture(game)
	game.inventory[item] = 1
	game._equip_inventory_item(item)
	var at := Vector2i(601, 80)
	game._edit_tile(at, tile_id)
	var point: Vector2 = Vector2(at * 16) + Vector2(8, 8) - game.camera_pos
	mouse(game, point, true)
	var mined := 0
	for _frame in range(fps * 3):
		if WG.tile_at(game.world["tiles"], at.x, at.y) == 0:
			mined += 1
			game._edit_tile(at, tile_id)
		game._process(1.0 / fps)
	mouse(game, point, false)
	return mined


func check_mining(game) -> void:
	for fps in [30, 60, 144]:
		var counts := []
		for item in ["Pickaxe", "Stone Pickaxe", "Copper Pickaxe", "Iron Pickaxe"]:
			counts.append(mining_run(game, item, fps, 3))
		check(counts[1] > counts[0] and counts[2] >= counts[0] * 1.4 and counts[3] >= counts[0] * 2.2,
			"Actual held mining must be noticeably faster at each tier: " + str(counts))
		print("MINING fps=", fps, " three_second_ore_blocks=", counts)
	var chops := []
	for item in ["Axe", "Copper Axe", "Iron Axe"]:
		chops.append(mining_run(game, item, 60, 9))
	check(chops[1] > chops[0] and chops[2] > chops[1], "Axe upgrades must also speed up repeated wood mining")
	fixture(game)
	game.inventory = {"Pickaxe": 1, "Iron Pickaxe": 1}
	game._equip_inventory_item("Pickaxe")
	var first: Vector2 = Vector2(601 * 16 + 8, 80 * 16 + 8) - game.camera_pos
	var second: Vector2 = Vector2(602 * 16 + 8, 80 * 16 + 8) - game.camera_pos
	mouse(game, first, true)
	mouse(game, first, false)
	game._equip_inventory_item("Iron Pickaxe")
	for _click in range(20):
		mouse(game, second, true)
		mouse(game, second, false)
	check(WG.tile_at(game.world["tiles"], 601, 80) == 3 and WG.tile_at(game.world["tiles"], 602, 80) == 3,
		"Rapid clicking, releasing, and switching tools must not bypass recovery")
	game._update_held_actions(Tools.MINING_SWING + 0.01)
	mouse(game, second, true)
	mouse(game, second, false)
	check(WG.tile_at(game.world["tiles"], 602, 80) == 0, "Mining must resume when recovery completes")
	var far: Vector2 = Vector2(606 * 16 + 8, 80 * 16 + 8) - game.camera_pos
	game._update_held_actions(0.2)
	mouse(game, far, true)
	mouse(game, far, false)
	check(WG.tile_at(game.world["tiles"], 606, 80) == 3, "Upgraded tools must retain the four-block reach limit")
	print("MINING axes=", chops, " click recovery, tool switching and reach checked")


func check_damage(game) -> void:
	for base in ["Sword", "Pickaxe", "Axe"]:
		var hits := []
		var intervals := []
		for item in Tools.progression(base):
			fixture(game)
			game.inventory[item] = 1
			game._equip_inventory_item(item)
			game.facing = 1
			game.world["creatures"] = [{"alive": true, "hp": 1000, "x": game.player_pos.x + 35,
				"y": game.player_pos.y + 11}]
			game._attack()
			var remaining: int = game.world["creatures"][0]["hp"]
			hits.append(1000 - remaining)
			intervals.append(game.attack_cooldown)
			game._attack()
			check(game.world["creatures"][0]["hp"] == remaining, "Repeated attacks during recovery must not deal extra damage")
		if base == "Pickaxe":
			check(hits == [7, 7, 8, 8, 9, 10, 11], "All seven pickaxes must use the requested damage bonuses")
		else:
			check(hits[-1] >= hits[0] * 2.0, "Iron must at least double starter hit damage for " + base)
			for level in range(1, hits.size()):
				check(hits[level] > hits[level - 1] and intervals[level] < intervals[level - 1],
					"Every material tier must improve combat for " + base)
		print("DAMAGE ", base, " hits=", hits, " cooldowns=", intervals)
	fixture(game)
	game.inventory["Iron Sword"] = 1
	game._equip_inventory_item("Iron Sword")
	game.world["creatures"] = [{"alive": true, "hp": 30, "x": game.player_pos.x + 35, "y": game.player_pos.y + 11}]
	game._attack()
	check(not game.world["creatures"][0]["alive"] and game.world["drops"].size() == 1,
		"An iron sword must defeat a basic creature in one hit and produce its normal loot")


func check_ui(game) -> void:
	fixture(game)
	game._edit_tile(Vector2i(603, 79), 34)
	game._edit_tile(Vector2i(604, 79), 36)
	game.stations.open({"name": "Workbench", "tile": Vector2i(603, 79)})
	var choices: Array = game.stations.recipes()
	check(choices.has(recipe(game, "Iron Pickaxe")) and not choices.has(recipe(game, "Iron Ingot")), "Workbench lists assembly and furnace keeps smelting")
	var initial: int = game.stations.page
	game._gameplay_ui_click(game.window_positions["workbench"] + Vector2(675, 59), MOUSE_BUTTON_LEFT)
	check(game.stations.page == initial + 1, "Dedicated recipe picker has working page controls")
	game.stations.close()
	game.inventory = {"Copper Pickaxe": 1, "Iron Ingot": 8, "Stick": 4}
	check(craft_at_station(game, "Iron Pickaxe") and game.inventory.get("Iron Pickaxe", 0) == 1, "Stored ingredients produce the selected assembled tool")

	game.equipped_tool = "Hand"
	game.use_pickaxe = false
	game.inventory = {"Pickaxe": 1, "Copper Pickaxe": 1, "Iron Pickaxe": 1, "Iron Sword": 1}
	game._key_pressed(KEY_Q)
	check(game.equipped_tool == "Iron Pickaxe" and game.use_pickaxe, "Q must equip the strongest owned pickaxe")
	game._stage_trash("Iron Pickaxe")
	check(game.equipped_tool == "Hand" and not game.use_pickaxe, "Staging an equipped upgrade in trash must unequip it")
	game._key_pressed(KEY_Q)
	check(game.equipped_tool == "Copper Pickaxe", "Q must fall back to the best remaining carried pickaxe")
	game._destroy_trash()
	game._equip_inventory_item("Iron Pickaxe")
	check(game.equipped_tool == "Copper Pickaxe", "Destroyed upgrades must not be equippable")
	game.inventory["Stone Pickaxe"] = 1
	game._stage_trash("Copper Pickaxe")
	game._key_pressed(KEY_Q)
	check(game.equipped_tool == "Stone Pickaxe" and game.use_pickaxe,
		"Q must choose stone above wood when metal pickaxes are unavailable")
	game._return_trash()
	var cycled := {}
	for _step in range(5):
		game._key_pressed(KEY_T)
		cycled[game.equipped_tool] = true
	check(cycled.has("Iron Sword") and not cycled.has("Iron Pickaxe"), "Tool cycling must include owned upgrades only")
	for item in Tools.variants():
		check(game.tool_textures.has(item) and game.dev_controls.resolve_item(item.to_lower()) == item,
			"Upgrade art, backpack equipment and developer give commands must recognize " + item)
	var copper: Image = game.tool_textures["Copper Pickaxe"].get_image()
	var iron: Image = game.tool_textures["Iron Pickaxe"].get_image()
	var wood: Image = game.tool_textures["Pickaxe"].get_image()
	check(copper.get_data() != iron.get_data() and copper.get_data() != wood.get_data(),
		"Material tiers must have visibly distinct tool art")
	print("UI recipe pages, shortcuts, inventory equipment, trash, cycling, developer commands and material art checked")


func check_saves(game) -> void:
	fixture(game)
	game.save_path = "user://galaxis_tool_progression_check.json"
	game.inventory = {"Stone Pickaxe": 1, "Iron Pickaxe": 1, "Iron Sword": 1, "Copper Axe": 1}
	game._equip_inventory_item("Stone Pickaxe")
	game.mining_cooldown = 0.12
	game.attack_cooldown = 0.20
	game._save_game()
	game._load_game()
	await process_frame
	check(game.equipped_tool == "Stone Pickaxe" and game.use_pickaxe and game.inventory["Copper Axe"] == 1,
		"Upgrade inventory and equipped family must survive saving")
	check(is_equal_approx(game.mining_cooldown, 0.12) and is_equal_approx(game.attack_cooldown, 0.20),
		"Saving must preserve recovery so loading cannot bypass it")
	var saved: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(game.save_path))
	saved["inventory"] = {"Pickaxe": 1, "Sword": 1}
	saved["equipped_tool"] = "Pickaxe"
	saved.erase("hotbar_slots")
	saved.erase("mining_cooldown")
	saved.erase("attack_cooldown")
	var file := FileAccess.open(game.save_path, FileAccess.WRITE)
	file.store_string(JSON.stringify(saved))
	file.close()
	game._load_game()
	await process_frame
	check(game.equipped_tool == "Pickaxe" and game.use_pickaxe and game.mining_cooldown == 0,
		"Older saves must retain their usable base tools")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(game.save_path))
	print("SAVES upgrades, equipped family, recovery and legacy base tools checked")


func run_check() -> void:
	var game: Node2D = load("res://main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	await game._open_planet(0)
	game.set_process(false)
	check_crafting(game)
	check_mining(game)
	check_damage(game)
	check_ui(game)
	await check_saves(game)
	print("TOOL_PROGRESSION failures=", failures)
	quit(0 if failures == 0 else 1)
