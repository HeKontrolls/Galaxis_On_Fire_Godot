extends SceneTree

const WG = preload("res://scripts/world_gen.gd")
var failures := 0


func _initialize() -> void:
	call_deferred("run_check")


func check(ok: bool, label: String) -> void:
	if not ok:
		failures += 1
		printerr(label)


func mouse(game: Node2D, point: Vector2, button: int, pressed: bool) -> void:
	var event := InputEventMouseButton.new()
	event.position = point
	event.button_index = button
	event.pressed = pressed
	game._input(event)


func run_check() -> void:
	var game: Node2D = load("res://main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	await game._open_planet(0)
	game.set_process(false)
	game.save_path = "user://galaxis_food_farming_check.json"
	var grid := PackedByteArray()
	grid.resize(WG.WIDTH * WG.HEIGHT)
	var surface := PackedInt32Array()
	surface.resize(WG.WIDTH)
	surface.fill(80)
	for x in range(WG.WIDTH):
		WG.set_tile(grid, x, 80, 1)
	game.world["tiles"] = grid
	game.world["surface"] = surface
	game.world["drops"] = []
	game.world["creatures"] = []
	game.world["torches"] = {}
	game.world.erase("water")
	game.world.erase("rain_water")
	game._reset_world_environment()
	game.world_texture = WG.make_texture(grid)
	game.world_image = game.world_texture.get_image()
	game.player_pos = Vector2(600 * 16, 80 * 16 - 29)
	game._update_camera()
	game.inventory = {"Crop Seeds": 3, "Hoe": 1, "Watering Can": 1}
	game._farm_interaction(Vector2i(601, 80), "Hoe", "")
	game._farm_interaction(Vector2i(601, 80), "Watering Can", "")
	game._farm_interaction(Vector2i(601, 80), "Hand", "Crop Seeds")
	check(game._farm_hint_text(Vector2i(601, 79))[0].contains("Sprout") and game._farm_hint_text(Vector2i(601, 79))[1].contains("Watered"), "Crop hints must identify the stage and watered soil")
	check(int(game.inventory["Crop Seeds"]) == 2, "Planting must consume one seed")
	game._edit_tile(Vector2i(601, 79), 16)
	check(game._farm_hint_text(Vector2i(601, 79))[0].contains("Ready"), "Mature corn must advertise that it can be harvested")
	game._farm_interaction(Vector2i(601, 79), "Hoe", "")
	check(game.notice.contains("Corn x") and game.notice.contains("Crop Seeds x"), "Harvest feedback must show actual food and seed yields")
	for _tick in range(20):
		game._update_drops(0.1)
	check(int(game.inventory.get("Corn", 0)) in [2, 3, 4] and int(game.inventory["Crop Seeds"]) >= 3, "Harvested food and seeds must enter inventory through physical pickups")
	game.health = 42
	game.hotbar.assign("Corn", 10, game.inventory)
	game._equip_inventory_item("Corn")
	var corn_before := int(game.inventory["Corn"])
	check(game.hotbar_page == 1, "Food assigned to the second hotbar page must be selectable")
	# Eating is a player action, independent of cursor distance from the player.
	mouse(game, Vector2(1000, 300), MOUSE_BUTTON_RIGHT, true)
	mouse(game, Vector2(1000, 300), MOUSE_BUTTON_RIGHT, false)
	check(game.health == 57 and int(game.inventory["Corn"]) == corn_before - 1, "Hotbar right-click must consume one corn and restore 15 HP")
	check(game.eat_visual > 0.0 and game.last_heal == 15 and not game.secondary_held, "Eating must animate, show healing, and stop held placement")
	check(not game._eat_food("Corn") and game.health == 57 and int(game.inventory["Corn"]) == corn_before - 1, "Rapid repeated eating must respect the cooldown")
	game._update_food_feedback(3.1)
	game.inventory["Corn"] = 5
	game.health = 100
	check(not game._eat_food("Corn") and game.inventory["Corn"] == 5, "Full health must never waste food")
	game.health = 94
	game._key_pressed(KEY_R)
	check(game.health == 100 and game.last_heal == 6 and game.inventory["Corn"] == 4, "Quick eating must clamp healing to max health and report the actual amount")
	game.recipe_index = 14
	game.inventory["Wood"] = 2
	game._craft()
	check(game.inventory["Corn"] == 4 and game.inventory["Wood"] == 2 and int(game.inventory.get("Roasted Corn", 0)) == 0, "Roasting must require a nearby furnace without consuming ingredients early")
	game._edit_tile(Vector2i(603, 79), 35)
	game._edit_tile(Vector2i(604, 79), 37)
	game.stations.open({"name": "Furnace", "tile": Vector2i(603, 79)})
	game.stations.deposit("Corn", 1)
	game.stations.deposit("Wood", 1)
	game.furnaces.update(11.0)
	game.stations.withdraw("output", 0)
	check(game.inventory["Corn"] == 3 and game.inventory["Wood"] == 1 and game.inventory["Roasted Corn"] == 1, "Furnace slots cook one corn with one wood into one stored meal")
	game.inventory["Wood"] = 0
	game.stations.deposit("Corn", 1)
	game.furnaces.update(20.0)
	check(game.stations.input_slots()[0]["count"] == 1 and game.inventory["Roasted Corn"] == 1, "Missing fuel leaves the stored corn unconsumed")
	game.stations.withdraw("input", 0)
	game.stations.close()

	game.inventory_open = true
	game.health = 35
	game.food_cooldown = 0.0
	var items: Array[String] = game._inventory_items()
	var index: int = items.find("Roasted Corn")
	var point: Vector2 = game.window_positions["inventory"] + Vector2(44 + (index % 8) * 54, 69 + (index / 8) * 54)
	var before_tiles: PackedByteArray = game.world["tiles"].duplicate()
	mouse(game, point, MOUSE_BUTTON_RIGHT, true)
	mouse(game, point, MOUSE_BUTTON_RIGHT, false)
	check(game.health == 65 and game.inventory["Roasted Corn"] == 0 and game.inventory_open, "Backpack right-click must eat one cooked meal for 30 HP while leaving the backpack open")
	check(before_tiles == game.world["tiles"] and not game.secondary_held, "Backpack eating must never build, farm, or change world tiles")
	game._update_food_feedback(3.1)
	check(game.food_cooldown == 0.0, "Eating cooldown must expire while the backpack is open")
	items = game._inventory_items()
	index = items.find("Corn")
	point = game.window_positions["inventory"] + Vector2(44 + (index % 8) * 54, 69 + (index / 8) * 54)
	mouse(game, point, MOUSE_BUTTON_LEFT, true)
	mouse(game, point, MOUSE_BUTTON_LEFT, false)
	check(not game.inventory_open and game.health == 65 and game.inventory["Corn"] == 3 and game.place_items[game.selected_slot] == "Corn", "Left-click food must equip it without eating")
	game._stage_trash("Corn")
	game._quick_eat()
	check(game.health == 65 and game.inventory_trash["count"] == 3, "Food staged in trash must not be consumable")
	game._return_trash()
	game.paused = true
	game._key_pressed(KEY_R)
	check(game.health == 65 and game.inventory["Corn"] == 3, "Pause menu input must not consume food")
	game.paused = false
	game._quick_eat()
	var saved_health: int = game.health
	var saved_corn: int = game.inventory["Corn"]
	game._save_game()
	game._load_game()
	await process_frame
	check(game.health == saved_health and game.inventory["Corn"] == saved_corn and game.food_cooldown > 2.9, "Food stacks, healed health, and eating cooldown must survive saving")
	check(not game._eat_food("Corn") and game.inventory["Corn"] == saved_corn, "Reloading must not bypass the eating cooldown")
	var saved: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(game.save_path))
	saved.erase("food_cooldown")
	var file := FileAccess.open(game.save_path, FileAccess.WRITE)
	file.store_string(JSON.stringify(saved))
	file.close()
	game._load_game()
	await process_frame
	check(game.food_cooldown == 0.0, "Older saves without food state must still load")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(game.save_path))
	print("FOOD_FARMING harvest, hotbar, backpack, cooking, cooldown, trash and saves failures=", failures)
	quit(0 if failures == 0 else 1)
