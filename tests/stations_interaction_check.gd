extends SceneTree

const WG = preload("res://scripts/world_gen.gd")
const Fixtures = preload("res://tests/tool_progression_check.gd")
var fixtures = Fixtures.new()
var failures := 0


func _initialize() -> void:
	call_deferred("run_check")


func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		printerr(message)


func reset(game) -> void:
	game.interactions.close()
	fixtures.fixture(game)
	game.world["ground_life"] = []
	game.world["ground_life_version"] = 1
	game.world["ground_cover_version"] = 1
	game.world["surface_rocks_version"] = 1
	game.ground_life.reset(game)
	game.hotbar.clear()
	game._select_hotbar_slot(0)
	game.world["chest_contents"] = {}


func mouse(game, point: Vector2, button: int, pressed: bool) -> void:
	var event := InputEventMouseButton.new()
	event.position = point
	event.button_index = button
	event.pressed = pressed
	game._input(event)


func place(game, item: String, tile: Vector2i) -> void:
	game._equip_inventory_item(item)
	var point: Vector2 = Vector2(tile * 16) + Vector2(8, 8) - game.camera_pos
	mouse(game, point, MOUSE_BUTTON_RIGHT, true)
	mouse(game, point, MOUSE_BUTTON_RIGHT, false)


func aim(game, tile: Vector2i) -> void:
	game._set_mouse_world_target(Vector2(tile * 16) + Vector2(8, 8))


func run_check() -> void:
	var game = load("res://main.tscn").instantiate()
	game.save_path = "user://stations_interaction_check.json"
	root.add_child(game)
	await process_frame
	await game._open_planet(0)
	game.set_process(false)
	for item in ["Workbench", "Furnace"]:
		reset(game)
		game.inventory = {item: 2}
		place(game, item, Vector2i(602, 79))
		var left := 34 if item == "Workbench" else 35
		check(WG.tile_at(game.world["tiles"], 602, 79) == left and WG.tile_at(game.world["tiles"], 603, 79) == left + 2 and game.inventory[item] == 1,
			"Actual hotbar right-click must place both halves of " + item + " and consume one item")
		for half in [602, 603]:
			aim(game, Vector2i(half, 79))
			game._key_pressed(KEY_F)
			check(game.stations.is_open() and game.stations.kind == item.to_lower() and not game.crafting_open and game._near_station(item),
				"F must open the matching usable recipe tab from either station half")
			game._key_pressed(KEY_F)
			check(not game.stations.is_open() and not game.primary_held, "F must close the station without starting a world action")
		place(game, item, Vector2i(602, 79))
		check(game.inventory[item] == 1, "Invalid overlapping placement must not consume a station")
	reset(game)
	game.inventory = {"Workbench": 1}
	game._edit_tile(Vector2i(603, 80), 0)
	place(game, "Workbench", Vector2i(602, 79))
	check(game.inventory["Workbench"] == 1 and WG.tile_at(game.world["tiles"], 602, 79) == 0, "Stations require two supported empty cells")
	reset(game)
	game.inventory = {"Torch": 1, "Chest": 1, "Wood": 10, "Corn": 4}
	place(game, "Torch", Vector2i(602, 78))
	check(game.world["torches"].has("602,78") and game.inventory["Torch"] == 0, "The generic block guard must also allow torch placement")
	place(game, "Chest", Vector2i(602, 79))
	aim(game, Vector2i(602, 79))
	game._key_pressed(KEY_F)
	check(game.interactions.is_open() and game.inventory_open and game.interactions.contents().is_empty(), "F must open an empty player-placed chest")
	var items: Array = game._inventory_items()
	var wood_index := items.find("Wood")
	var pack: Vector2 = game.window_positions["inventory"] + Vector2(44 + wood_index % 8 * 54, 69 + (wood_index / 8) * 54)
	mouse(game, pack, MOUSE_BUTTON_LEFT, true)
	mouse(game, pack, MOUSE_BUTTON_LEFT, false)
	check(game.interactions.contents().get("Wood", 0) == 10 and game.inventory["Wood"] == 0 and game.interactions.is_open(), "Clicking the backpack must deposit a stack without closing the chest")
	var chest: Vector2 = game.window_positions["chest"] + Vector2(44, 69)
	mouse(game, chest, MOUSE_BUTTON_RIGHT, true)
	mouse(game, chest, MOUSE_BUTTON_RIGHT, false)
	check(game.inventory["Wood"] == 1 and game.interactions.contents()["Wood"] == 9, "Right-click chest must withdraw exactly one item")
	game.interactions.deposit("Corn")
	var corn_index: int = game._inventory_items().find("Wood")
	var one_point: Vector2 = game.window_positions["inventory"] + Vector2(44 + corn_index % 8 * 54, 69 + (corn_index / 8) * 54)
	mouse(game, one_point, MOUSE_BUTTON_RIGHT, true)
	mouse(game, one_point, MOUSE_BUTTON_RIGHT, false)
	check(game.inventory["Wood"] == 0 and game.interactions.contents()["Wood"] == 10, "Right-click backpack must store one item without eating or using it")
	game.interactions.withdraw("Wood", 1)
	game._key_pressed(KEY_F)
	check(not game.interactions.is_open() and not game.inventory_open, "F must close both chest panels")
	game._key_pressed(KEY_F)
	check(game.interactions.contents().get("Wood", 0) == 9 and game.interactions.contents().get("Corn", 0) == 4, "Reopening a chest must preserve its stacks")
	# Fill the distinct-stack limit and prove rejected deposits cannot lose items.
	for index in range(30):
		game.inventory["Sample %02d" % index] = 1
		game.interactions.deposit("Sample %02d" % index)
	game.inventory["Stone"] = 7
	check(not game.interactions.deposit("Stone") and game.inventory["Stone"] == 7 and game.interactions.contents().size() == 32, "A full chest must reject new stacks without consuming them")
	game._save_game()
	game._load_game()
	for _frame in range(4):
		await process_frame
	aim(game, Vector2i(602, 79))
	game._key_pressed(KEY_F)
	check(game.interactions.is_open() and game.interactions.contents()["Wood"] == 9 and game.interactions.contents()["Corn"] == 4, "Chest contents must round-trip through a real planet save")
	var take_all: Vector2 = game.window_positions["chest"] + Vector2(80, 300)
	mouse(game, take_all, MOUSE_BUTTON_LEFT, true)
	mouse(game, take_all, MOUSE_BUTTON_LEFT, false)
	check(game.interactions.contents().is_empty() and game.inventory["Wood"] == 10 and game.inventory["Corn"] == 4, "Take All must move every stored stack exactly once")
	game._key_pressed(KEY_ESCAPE)
	check(not game.interactions.is_open() and not game.inventory_open and not game.paused, "Escape must close the chest before pausing")
	reset(game)
	game._edit_tile(Vector2i(602, 79), 30)
	aim(game, Vector2i(602, 79))
	game._key_pressed(KEY_F)
	check(game.interactions.contents() == {"Coal Ore": 3, "Copper Ore": 2}, "A natural chest must expose its original loot")
	game.interactions.withdraw("Coal Ore")
	game.interactions.withdraw("Copper Ore")
	game._key_pressed(KEY_F)
	game._key_pressed(KEY_F)
	check(game.interactions.contents().is_empty() and game.inventory["Coal Ore"] == 3, "Reopening a looted natural chest must not recreate loot")
	game.inventory["Wood"] = 6
	game.interactions.deposit("Wood")
	game._key_pressed(KEY_F)
	game.mining_cooldown = 0
	game._mine(Vector2(602 * 16 + 8, 79 * 16 + 8) - game.camera_pos)
	var drops := {}
	for drop: Dictionary in game.world["drops"]:
		drops[drop["item"]] = int(drops.get(drop["item"], 0)) + int(drop["count"])
	check(drops.get("Wood", 0) == 6 and drops.get("Chest", 0) == 1 and drops.get("Coal Ore", 0) == 0 and not game.world["chest_contents"].has("602,79"),
		"Mining a stored chest must recover its contents and block without replaying original loot")
	reset(game)
	game._edit_tile(Vector2i(602, 79), 34)
	game._edit_tile(Vector2i(603, 79), 36)
	game._edit_tile(Vector2i(601, 79), 3)
	aim(game, Vector2i(602, 79))
	game._key_pressed(KEY_F)
	check(not game.stations.is_open(), "A solid wall must block F interaction")
	game._edit_tile(Vector2i(601, 79), 0)
	game.player_pos.x -= 200
	game._key_pressed(KEY_F)
	check(not game.stations.is_open(), "F must not access out-of-range stations")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(game.save_path))
	fixtures.free()
	print("STATION_INTERACTION hotbar placement, paired stations, F menus, chest transfers, capacity, persistence, mining, range and walls: failures=", failures)
	quit(1 if failures else 0)
