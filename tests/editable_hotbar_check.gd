extends SceneTree

const Hotbar = preload("res://scripts/hotbar.gd")
var failures := 0


func _initialize() -> void:
	call_deferred("run_check")


func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		printerr(message)


func mouse(game, position: Vector2, down: bool, control := false, alternate := false, button := MOUSE_BUTTON_LEFT) -> void:
	var event := InputEventMouseButton.new()
	event.position = position
	event.button_index = button
	event.pressed = down
	event.ctrl_pressed = control
	event.alt_pressed = alternate
	game._input(event)


func slot_point(game, index: int) -> Vector2:
	return Vector2(game.HOTBAR_X + (index % 9) * game.HOTBAR_STEP + 20, game.HOTBAR_Y + 20)


func pack_point(game, item: String) -> Vector2:
	var index: int = game._inventory_items().find(item)
	game.inventory_page = index / 32
	var cell := index % 32
	return Vector2(game.window_positions["inventory"]) + Vector2(44 + (cell % 8) * 54, 69 + (cell / 8) * 54)


func drag(game, from: Vector2, to: Vector2) -> void:
	mouse(game, from, true)
	var motion := InputEventMouseMotion.new()
	motion.position = to
	game._input(motion)
	mouse(game, to, false)


func run_check() -> void:
	var game = load("res://main.tscn").instantiate()
	game.save_path = "user://editable_hotbar_check.json"
	game.settings_path = "user://editable_hotbar_settings_check.json"
	root.add_child(game)
	await process_frame
	game.set_process(false)
	game.inventory = {"Wood": 99, "Pickaxe": 1}
	game._equip_inventory_item("Pickaxe")
	game.inventory_trash = {"item": "Gold Ore", "count": 10}
	game._menu_key(KEY_ENTER)
	game.new_game_name = "Hotbar check"
	game.seed_text = "hotbar"
	game._start_new_game()
	check(game.inventory.is_empty() and game.place_items.count("") == 54 and game.inventory_trash.is_empty() and game.equipped_tool == "Hand",
		"New Game must clear all starter materials, tools, assignments and staged trash")
	await game._open_planet(0)
	game.set_process(false)
	game.inventory = {"Pickaxe": 1, "Dirt": 20, "Iron Ore": 12, "Corn": 4, "Wood": 5, "Axe": 1}
	game.inventory_open = true
	for item in ["Pickaxe", "Dirt", "Iron Ore"]:
		mouse(game, pack_point(game, item), true, true)
		mouse(game, pack_point(game, item), false, true)
	check(game.place_items.slice(0, 3) == ["Pickaxe", "Dirt", "Iron Ore"] and game.inventory_open,
		"Ctrl-click must fill the next free slots without closing the backpack")
	var original: Dictionary = game.inventory.duplicate()
	mouse(game, pack_point(game, "Dirt"), true, true)
	mouse(game, pack_point(game, "Dirt"), false, true)
	check(game.place_items.count("Dirt") == 1 and game.inventory == original, "Repeated assignments must never duplicate stacks or quantities")
	drag(game, pack_point(game, "Corn"), slot_point(game, 5))
	check(game.place_items[5] == "Corn" and game.inventory == original, "Dragging from the pack must assign the exact requested slot")
	drag(game, slot_point(game, 0), slot_point(game, 5))
	check(game.place_items[0] == "Corn" and game.place_items[5] == "Pickaxe" and game.equipped_tool == "Hand",
		"Dragging occupied hotbar slots must swap their shortcuts and update the selected tool")
	mouse(game, slot_point(game, 5), true)
	mouse(game, slot_point(game, 5), false)
	check(game.equipped_tool == "Pickaxe" and game.use_pickaxe, "Clicking a hotbar tool must equip it")
	drag(game, slot_point(game, 5), Vector2(950, 600))
	check(game.place_items[5].is_empty() and game.inventory["Pickaxe"] == 1 and game.equipped_tool == "Hand", "Dragging out must remove only the shortcut and unequip the tool")
	mouse(game, slot_point(game, 1), true, true)
	mouse(game, slot_point(game, 1), false, true)
	check(game.place_items[1].is_empty() and game.inventory["Dirt"] == 20, "Ctrl-clicking a hotbar slot must remove it without destroying items")
	game._select_hotbar_slot(0)
	game.hotbar.assign("Pickaxe", 0, game.inventory)
	mouse(game, slot_point(game, 0), true)
	var move := InputEventMouseMotion.new()
	move.position = slot_point(game, 0) + Vector2(9, 0)
	game._input(move)
	mouse(game, slot_point(game, 0), true, false, true, MOUSE_BUTTON_WHEEL_DOWN)
	mouse(game, slot_point(game, 9), false)
	check(game.place_items[0].is_empty() and game.place_items[9] == "Pickaxe" and game.inventory["Pickaxe"] == 1,
		"Dragging while Alt-scrolling must move a shortcut between pages without duplicating its stack")
	mouse(game, slot_point(game, 9), true)
	game._input(move)
	game._notification(Node.NOTIFICATION_WM_WINDOW_FOCUS_OUT)
	check(game.inventory_drag_item.is_empty() and not game.inventory_dragging and game.place_items[9] == "Pickaxe", "Losing focus must cancel a drag without removing its item")
	game.inventory_open = false
	game._select_hotbar_slot(8)
	mouse(game, Vector2(900, 400), true, false, false, MOUSE_BUTTON_WHEEL_DOWN)
	check(game.selected_slot == 0 and game.hotbar_page == 0, "Ordinary wheel must wrap within the current bar")
	mouse(game, Vector2(900, 400), true, false, true, MOUSE_BUTTON_WHEEL_DOWN)
	check(game.selected_slot == 9 and game.hotbar_page == 1, "Alt-wheel must switch pages while preserving the selected column")
	game._select_hotbar_slot(53)
	mouse(game, slot_point(game, 53), true, false, true, MOUSE_BUTTON_WHEEL_DOWN)
	check(game.selected_slot == 8 and game.hotbar_page == 0, "Alt-wheel over the hotbar must wrap all six pages")
	game._equip_inventory_item("Iron Ore")
	var ore_before: int = game.inventory["Iron Ore"]
	game._place(game.player_pos + Vector2(45, 10) - game.camera_pos)
	check(game.inventory["Iron Ore"] == ore_before and game.equipped_tool == "Hand", "Non-placeable inventory items must be safe to select and use")
	game._equip_inventory_item("Pickaxe")
	game._stage_trash("Pickaxe")
	check(not game.place_items.has("Pickaxe") and game.equipped_tool == "Hand", "Staged or destroyed tools must disappear from the hotbar")
	game._return_trash()
	check(not game.place_items.has("Pickaxe") and game.inventory["Pickaxe"] == 1, "Returning trash must restore the stack without silently assigning it")
	game.hotbar.clear()
	game.inventory = {}
	for index in range(55):
		game.inventory["Sample %02d" % index] = index + 1
	game.inventory_open = true
	check(game._inventory_page_count() == 2, "Every owned item must be reachable after the first 32 backpack entries")
	mouse(game, pack_point(game, "Sample 40"), true, true)
	mouse(game, pack_point(game, "Sample 40"), false, true)
	check(game.place_items[0] == "Sample 40", "Ctrl-click must work on later backpack pages and arbitrary item types")
	game.hotbar.clear()
	for index in range(54):
		check(game._add_to_hotbar("Sample %02d" % index), "Every hotbar slot must accept an owned item")
	original = game.inventory.duplicate()
	check(not game._add_to_hotbar("Sample 54") and game.inventory == original, "A full hotbar must reject assignment without consuming items")
	drag(game, pack_point(game, "Sample 54"), slot_point(game, game.selected_slot))
	check(game.place_items[game.selected_slot] == "Sample 54" and game.inventory == original, "Dragging onto a full bar must replace only its shortcut")
	game._select_hotbar_slot(44)
	game._save_game()
	var expected: Array = game.place_items.duplicate()
	game.hotbar.clear()
	game._load_game()
	for _frame in range(4):
		await process_frame
	check(game.place_items == expected and game.selected_slot == 44 and game.hotbar_page == 4, "All six editable pages and selection must round-trip through saves")
	var saved: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(game.save_path))
	saved.erase("hotbar_slots")
	saved["inventory"] = {"Wood": 12, "Pickaxe": 1, "Crop Seeds": 3}
	saved["equipped_tool"] = "Pickaxe"
	var file := FileAccess.open(game.save_path, FileAccess.WRITE)
	file.store_string(JSON.stringify(saved))
	file.close()
	game._load_game()
	for _frame in range(4):
		await process_frame
	check(game.inventory["Wood"] == 12 and game.place_items.has("Crop Seeds") and game.place_items[game.selected_slot] == "Pickaxe",
		"Older saves must keep owned inventory and migrate their separate tool into a real hotbar slot")
	var model := Hotbar.new()
	model.restore([null, 42, "Wood", "Wood", "Corn Seed", "Missing"], {"Wood": 2, "Crop Seeds": 1})
	check(model.slots.size() == 54 and model.slots[2] == "Wood" and model.slots[3] == "" and model.slots[4] == "Crop Seeds" and model.slots[5] == "",
		"Malformed, duplicated and unowned saved shortcuts must normalize safely")
	for path: String in [game.save_path, game.settings_path]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	print("EDITABLE_HOTBAR empty start, ctrl-click, drag, swaps, all items, paging, tool sync, quantities, full bars, saves and migration: failures=", failures)
	quit(1 if failures else 0)
