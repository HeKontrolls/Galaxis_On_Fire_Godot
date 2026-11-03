extends "res://tests/tool_progression_check.gd"

func fresh(game) -> void:
	game.stations.close()
	game.interactions.close()
	fixture(game)
	game.inventory_order.clear()
	game.tool_wear.uses.clear()
	game.hotbar.clear()
	game._select_hotbar_slot(0)
	game.world["ground_life"] = []
	game.world["ground_life_version"] = 1
	game.world["ground_cover_version"] = 1
	game.world["surface_rocks_version"] = 1
	game.ground_life.reset(game)

func station(game, name: String, x: int) -> void:
	var id := 34 if name == "Workbench" else 35
	game._edit_tile(Vector2i(x, 79), id)
	game._edit_tile(Vector2i(x + 1, 79), id + 2)

func open_at(game, x: int, half: int = 0) -> void:
	game._set_mouse_world_target(Vector2((x + half) * 16 + 8, 79 * 16 + 8))
	game._key_pressed(KEY_F)

func click(game, point: Vector2, button: int = MOUSE_BUTTON_LEFT, control: bool = false) -> void:
	var event := InputEventMouseButton.new()
	event.position = point
	event.button_index = button
	event.ctrl_pressed = control
	event.pressed = true
	game._input(event)
	event.pressed = false
	game._input(event)

func drag(game, from: Vector2, to: Vector2) -> void:
	var event := InputEventMouseButton.new()
	event.position = from
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	game._input(event)
	var movement := InputEventMouseMotion.new()
	movement.position = to
	game._input(movement)
	event.position = to
	event.pressed = false
	game._input(event)

func bag_point(game, item: String) -> Vector2:
	var index: int = game._inventory_items().find(item)
	game.inventory_page = index / 32
	index %= 32
	return game.window_positions["inventory"] + Vector2(44 + index % 8 * 54, 69 + (index / 8) * 54)

func workstation_checks(game) -> void:
	fresh(game)
	station(game, "Workbench", 602)
	station(game, "Workbench", 596)
	game.inventory = {"Wood": 10, "Stone": 4, "Iron Pickaxe": 1}
	game._equip_inventory_item("Iron Pickaxe")
	game._wear_pickaxe("Iron Pickaxe", 63)
	open_at(game, 602, 1)
	check(game.stations.is_open() and game.stations.kind == "workbench" and not game.crafting_open and game.inventory_open, "F opens a dedicated workbench and backpack from its second half")
	check(not Rect2(Vector2(game.window_positions["workbench"]), game.StationWindows.SIZE).intersects(Rect2(Vector2(game.window_positions["inventory"]), Vector2(466, 382))), "Station and backpack open without overlapping")
	check(not game.stations.craft(0) and game.inventory["Wood"] == 10, "Workbench cannot consume backpack materials")
	drag(game, bag_point(game, "Wood"), game.stations.slot_rect("input", 4).get_center())
	check(game.inventory["Wood"] == 0 and game.stations.input_slots()[4]["count"] == 10, "Dragging into an exact ingredient slot stores the whole stack")
	click(game, bag_point(game, "Stone"), MOUSE_BUTTON_RIGHT)
	check(game.inventory["Stone"] == 3 and game.stations.input_slots()[0]["item"] == "Stone", "Right-click backpack stores one item")
	drag(game, game.stations.slot_rect("input", 4).get_center(), game.stations.slot_rect("input", 0).get_center())
	check(game.stations.input_slots()[0]["item"] == "Wood" and game.stations.input_slots()[4]["item"] == "Stone", "Occupied ingredient slots swap without losing stacks")
	click(game, game.stations.slot_rect("result", 0).get_center())
	check(game.stations.state()["output"].get("Planks", 0) == 4 and game.stations.input_slots()[0]["count"] == 9 and game.inventory.get("Planks", 0) == 0, "Result slot crafts from stored ingredients into station output")
	click(game, game.stations.slot_rect("output", 0).get_center(), MOUSE_BUTTON_RIGHT)
	check(game.inventory["Planks"] == 1 and game.stations.state()["output"]["Planks"] == 3, "Output right-click takes one")
	drag(game, game.stations.slot_rect("output", 0).get_center(), Vector2(410, 675))
	check(game.inventory["Planks"] == 4 and game.place_items[0] == "Planks", "Dragging output to hotbar withdraws it and assigns the shortcut")
	click(game, bag_point(game, "Iron Pickaxe"))
	check(game.inventory["Iron Pickaxe"] == 0, "Workbench stores tools from backpack")
	var pick_slot := -1
	for i in range(9):
		if game.stations.input_slots()[i].get("item", "") == "Iron Pickaxe":
			pick_slot = i
	check(game.stations.input_slots()[pick_slot]["wear"] == [187], "Station preserves individual tool wear")
	var start: Vector2 = game.window_positions["workbench"]
	drag(game, start + Vector2(150, 19), start + Vector2(170, 49))
	check(game.window_positions["workbench"] == start + Vector2(20, 30), "Workbench window can be dragged")
	click(game, game.window_positions["inventory"] + Vector2(445, 19))
	check(game.stations.is_open() and not game.inventory_open and game._world_input_blocked(Vector2(1000, 400)), "Backpack closes independently while station still blocks world actions")
	game._key_pressed(KEY_I)
	check(game.stations.is_open() and game.inventory_open, "I reopens backpack beside the same station")
	click(game, game.window_positions["workbench"] + Vector2(696, 19))
	check(not game.stations.is_open() and game.inventory_open, "Station X closes independently of backpack")
	game._key_pressed(KEY_I)
	open_at(game, 602)
	game._key_pressed(KEY_F)
	check(not game.stations.is_open() and not game.inventory_open and not game.paused, "F closes the station and backpack")
	open_at(game, 596)
	check(game.stations.state()["inputs"] == game.stations.Slots.create(9), "Another workbench has independent empty slots")
	game._key_pressed(KEY_ESCAPE)
	open_at(game, 602)
	check(game.stations.input_slots()[0]["count"] == 9, "Reopening preserves exact slot contents")
	game.save_path = "user://station_storage_sort_check.json"
	game._save_game()
	game._load_game()
	await process_frame
	open_at(game, 602)
	check(int(game.stations.input_slots()[0]["count"]) == 9 and int(game.stations.input_slots()[pick_slot]["wear"][0]) == 187, "Workbench slot positions and tool wear survive saving")
	click(game, game.stations.slot_rect("input", pick_slot).get_center())
	check(game.tool_wear.remaining("Iron Pickaxe", game.inventory) == 187, "Withdrawing a tool cannot repair it")
	game.stations.deposit("Iron Pickaxe")
	game.stations.close()
	game.inventory["Pickaxe"] = 1
	game._equip_inventory_item("Pickaxe")
	for _hit in range(game.Tools.mining_hits("Pickaxe", 34)):
		game.mining_cooldown = 0
		game._mine(Vector2(602 * 16 + 8, 79 * 16 + 8) - game.camera_pos)
	var recovered := {}
	for drop: Dictionary in game.world["drops"]:
		recovered[drop["item"]] = int(recovered.get(drop["item"], 0)) + int(drop["count"])
		if drop["item"] == "Iron Pickaxe":
			check(int(drop["tool_wear"][0]) == 187, "Mining workbench preserves stored tool wear in its drop")
	check(recovered.get("Wood", 0) == 9 and recovered.get("Stone", 0) == 1 and recovered.get("Workbench", 0) == 1 and recovered.get("Iron Pickaxe", 0) == 1, "Mining workbench recovers every stored item once")
	check(not game.world["workbenches"].has("602,79"), "Workbench metadata removed after mining")
	print("WORKBENCH exact slots, independent instances, crafting/output, drag, wear, saves and recovery checked")

func furnace_checks(game) -> void:
	fresh(game)
	station(game, "Furnace", 602)
	station(game, "Furnace", 596)
	game.inventory = {"Copper Ore": 3, "Coal Ore": 3, "Wood": 4, "Iron Pickaxe": 1}
	open_at(game, 602)
	check(game.stations.kind == "furnace" and not game.crafting_open, "Furnace has its own slot window")
	check(not game.stations.deposit("Iron Pickaxe") and not game.stations.deposit("Copper Ore", 1, "fuel", 0), "Invalid material/fuel slots reject items without loss")
	drag(game, bag_point(game, "Copper Ore"), game.stations.slot_rect("input", 2).get_center())
	click(game, bag_point(game, "Coal Ore"))
	var machine: Dictionary = game.stations.state()
	check(machine["inputs"][2]["count"] == 3 and machine["fuel"][0]["count"] == 3, "Furnace stores ore and fuel in separate persistent slots")
	game._process(2.5)
	check(is_equal_approx(float(machine["heat"]), 0.5) and machine["jobs"].size() == 1 and machine["output"].is_empty(), "Deposited materials automatically start heating while window is open")
	game._process(10.5)
	check(machine["output"].get("Copper Ingot", 0) == 1 and game.inventory.get("Copper Ingot", 0) == 0, "Smelted ingot remains in the furnace output slot")
	click(game, game.stations.slot_rect("output", 0).get_center())
	check(game.inventory["Copper Ingot"] == 1 and machine["output"].is_empty(), "Furnace output click transfers ingot once")
	game.stations.close()
	open_at(game, 596)
	check(game.stations.state()["jobs"].is_empty() and game.stations.state()["fuel"][0].is_empty(), "Second furnace has independent storage and heat")
	game.stations.close()
	open_at(game, 602)
	game._save_game()
	game._load_game()
	await process_frame
	open_at(game, 602)
	machine = game.stations.state()
	check(int(machine["inputs"][2]["count"]) == 1 and int(machine["fuel"][0]["count"]) == 1 and machine["jobs"].size() == 1, "Saved furnace retains pending inputs, fuel and active smelting")
	# Clicking a material slot reserves it from automatic feeding until release.
	var down := InputEventMouseButton.new()
	down.position = game.stations.slot_rect("input", 2).get_center()
	down.button_index = MOUSE_BUTTON_LEFT
	down.pressed = true
	game._input(down)
	game.furnaces.update(8.0)
	check(int(machine["inputs"][2]["count"]) == 1, "Automatic feed cannot steal a stack being dragged")
	game._notification(Node.NOTIFICATION_WM_WINDOW_FOCUS_OUT)
	game.furnaces.update(0.01)
	check(machine["inputs"][2].is_empty(), "Focus loss cancels the drag and safely resumes feeding")
	game.stations.close()
	game.inventory["Pickaxe"] = 1
	game._equip_inventory_item("Pickaxe")
	game.mining_cooldown = 0
	for hit in range(game.Tools.mining_hits("Pickaxe", 35)):
		game.mining_cooldown = 0
		game._mine(Vector2(602 * 16 + 8, 79 * 16 + 8) - game.camera_pos)
	var dropped := {}
	for drop: Dictionary in game.world["drops"]:
		dropped[drop["item"]] = int(dropped.get(drop["item"], 0)) + int(drop["count"])
	check(dropped.get("Copper Ingot", 0) == 1 and dropped.get("Copper Ore", 0) == 1 and dropped.get("Coal Ore", 0) == 1 and dropped.get("Furnace", 0) == 1, "Mining furnace returns its output and unfinished batch")
	game.world["furnaces"]["596,79"] = {"heat": 0.4, "jobs": [{"out": "Gold Ingot", "count": 1, "duration": 9.0, "elapsed": 4.0, "needs": {"Gold Ore": 1, "Coal Ore": 1}}], "output": {"Iron Ingot": 2}}
	open_at(game, 596)
	check(game.stations.input_slots().size() == 6 and game.stations.state()["fuel"].size() == 1, "Older furnace queues gain empty slots without losing progress or output")
	var press := InputEventMouseButton.new()
	press.position = game.stations.slot_rect("output", 0).get_center()
	press.button_index = MOUSE_BUTTON_LEFT
	press.pressed = true
	game._input(press)
	game.furnaces.update(8.0)
	var motion := InputEventMouseMotion.new()
	motion.position = game.window_positions["inventory"] + Vector2(44, 69)
	game._input(motion)
	press.position = motion.position
	press.pressed = false
	game._input(press)
	check(game.inventory.get("Iron Ingot", 0) == 2 and game.stations.state()["output"].get("Gold Ingot", 0) == 1, "Output drag follows its original item when a smelt finishes and the output order changes")
	print("FURNACE automatic slot feeding, fuel restrictions, timing, instances, saved queues and safe drag/recovery checked")

func sort_checks(game) -> void:
	fresh(game)
	game.inventory = {"Corn": 4, "Wood": 20, "Copper Ore": 6, "Iron Pickaxe": 1, "Sword": 1, "Dirt": 3}
	game._equip_inventory_item("Iron Pickaxe")
	game._wear_pickaxe("Iron Pickaxe", 24)
	game._equip_inventory_item("Wood")
	game.inventory_open = true
	var before: Dictionary = game.inventory.duplicate()
	var bar: Array = game.place_items.duplicate()
	game._inventory_items()
	click(game, game.window_positions["inventory"] + Vector2(250, 19))
	check(game._inventory_items() == ["Iron Pickaxe", "Sword", "Copper Ore", "Dirt", "Wood", "Corn"], "Sort button groups all owned items by type and name")
	check(game.inventory == before and game.place_items == bar and game.tool_wear.remaining("Iron Pickaxe", game.inventory) == 226, "Sorting preserves counts, hotbar assignments and durability")
	var order: Array = game._inventory_items().duplicate()
	game._save_game()
	game._load_game()
	await process_frame
	check(game._inventory_items() == order, "Sorted inventory order survives saves")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(game.save_path))
	print("SORT actual button, categories, quantities, shortcuts, durability and saved order checked")

func run_check() -> void:
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	await game._open_planet(0)
	game.set_process(false)
	await workstation_checks(game)
	await furnace_checks(game)
	await sort_checks(game)
	print("STATION_STORAGE_SORT failures=", failures)
	quit(0 if failures == 0 else 1)
