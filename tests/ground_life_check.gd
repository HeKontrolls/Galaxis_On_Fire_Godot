extends SceneTree

const WG = preload("res://scripts/world_gen.gd")
const Life = preload("res://scripts/ground_life.gd")
const AtmosphereLighting = preload("res://scripts/world_environment.gd")
const Fixtures = preload("res://tests/tool_progression_check.gd")
var fixtures = Fixtures.new()
var failures := 0


func _initialize() -> void:
	call_deferred("run_check")


func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		printerr(message)


func fixture(game) -> void:
	fixtures.fixture(game)
	game.world["ground_life"] = []
	game.world["ground_life_version"] = 1
	game.world["ground_cover_version"] = 1
	game.ground_life.reset(game)
	game.player_grounded = true
	game.inventory = {"Pickaxe": 1}
	game._equip_inventory_item("Pickaxe")


func key(code: Key, pressed: bool) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.pressed = pressed
	Input.parse_input_event(event)
	Input.flush_buffered_events()


func generation_checks() -> void:
	for climate in range(8):
		var world := WG.generate(713, climate)
		var duplicate: Dictionary = world.duplicate(true)
		var original: PackedByteArray = world["tiles"].duplicate()
		var environment := AtmosphereLighting.new()
		environment.reset(world)
		Life.populate(world, environment.roof)
		Life.populate(duplicate, environment.roof)
		check(JSON.stringify(world["ground_life"]) == JSON.stringify(duplicate["ground_life"]), "Population must be deterministic for the terrain and seed")
		check(world["tiles"] == original, "Plants and wildlife must never introduce collision tiles")
		var flora := 0
		var fauna := 0
		for entry: Dictionary in world["ground_life"]:
			if Life.animal(str(entry["species"])):
				fauna += 1
			else:
				flora += 1
			var x := floori(float(entry["x"]) / 16)
			var y := roundi(float(entry["y"]) / 16)
			check(WG.is_solid(WG.tile_at(original, x, y)) and WG.tile_at(original, x, y - 1) not in [4, 11], "Life must spawn on supported dry ground")
		check(flora > 20 and fauna > 0 and world["ground_life"].size() < 800, "Each climate must get a bounded plant and wildlife population")
		var total: int = world["ground_life"].size()
		world["ground_life"][0]["alive"] = false
		Life.populate(world, environment.roof)
		check(world["ground_life"].size() == total and not world["ground_life"][0]["alive"], "Harvested specimens must never regenerate when a planet is revisited")
		print("ECOLOGY climate=", climate, " flora=", flora, " fauna=", fauna)


func movement_checks(game) -> void:
	fixture(game)
	var original: PackedByteArray = game.world["tiles"].duplicate()
	check(game.ground_life.place(game, "Woodland Fern", Vector2i(602, 79)), "A collected plant must be replantable")
	var plant: Dictionary = game.ground_life.entries.back()
	var largest := 0.0
	var start: Vector2 = game.player_pos
	key(KEY_D, true)
	for _frame in range(60):
		game.animation_clock += 1.0 / 60
		game._update_player(1.0 / 60)
		game.ground_life.update(game, 1.0 / 60)
		largest = maxf(largest, absf(float(game.ground_life.state[int(plant["id"])]["bend"])))
	key(KEY_D, false)
	check(absf(game.player_pos.x - start.x - game.SPEED) < 1.0 and game.world["tiles"] == original,
		"Actual player movement must walk through plants without changing terrain or speed")
	check(largest > 0.4, "Walking through a plant must visibly bend it")
	for _frame in range(180):
		game.ground_life.update(game, 1.0 / 60)
	check(absf(float(game.ground_life.state[int(plant["id"])]["bend"])) < 0.01, "Displaced plants must spring back after the player passes")
	game.player_pos = Vector2(float(plant["x"]) - 8, float(plant["y"]) - 40)
	game.ground_life.last_player = game.player_pos - Vector2(0, 4)
	game.ground_life.update(game, 1.0 / 60)
	check(absf(float(game.ground_life.state[int(plant["id"])]["bend"])) > 0.01, "Landing on a plant must also disturb it")
	for species: String in Life.SPECIES:
		var east := Life.wind_bend(species, 0.6, 2.5, 40)
		var west := Life.wind_bend(species, 0.6, 2.5, -40)
		if species in Life.ROCKS:
			check(east == 0 and west == 0, "Rocks must remain rigid in wind")
			continue
		check(east > 0 and west < 0, "Every plant and critter must respond to wind direction: " + species)
		check(Life.deformation_y(32, east) == 0 and Life.deformation_y(0, east) != 0, "Wind deformation must retain the ground pivot")
	print("REACTIONS real player pass-through, contact bend, vertical contact, settling, vegetation wind response and rigid rocks checked")


func harvest_checks(game) -> void:
	fixture(game)
	check(game.ground_life.place(game, "Wildflower", Vector2i(601, 79)), "Flower placement must find the support tile")
	var flower: Dictionary = game.ground_life.entries.back()
	var point: Vector2 = Vector2(float(flower["x"]), float(flower["y"]) - 12) - game.camera_pos
	game._mine(point)
	check(not flower["alive"] and game.world["drops"].size() == 1 and game.world["drops"][0]["item"] == "Wildflower", "Mining must produce one real collectible specimen")
	game._mine(point)
	check(game.world["drops"].size() == 1, "Holding or spamming a harvested plant must not duplicate its item")
	game._update_drops(0.5)
	check(int(game.inventory.get("Wildflower", 0)) == 1, "Harvested plants must use magnetic pickups and inventory")
	game._equip_inventory_item("Wildflower")
	game.equipped_tool = "Hoe"
	game.use_hoe = true
	game._place(Vector2(603 * 16 + 8, 79 * 16 + 8) - game.camera_pos)
	check(game.inventory["Wildflower"] == 0 and game.ground_life.entries.back()["alive"], "Right click must replant the selected specimen even while a hoe is equipped")
	check(game.hotbar_page == game.place_items.find("Wildflower") / 9, "The inventory must select the correct expanded hotbar page")
	game.hotbar_page = game.HUD_PAGE_RECTS.size() - 1
	game._key_pressed(KEY_B)
	check(game.hotbar_page == 0, "Hotbar cycling must wrap across all flora/fauna pages")
	var replanted: Dictionary = game.ground_life.entries.back()
	game._edit_tile(Vector2i(603, 80), 0)
	game.ground_life.update(game, 0.1)
	check(not replanted["alive"] and game.world["drops"].size() == 1, "Digging a plant's support must release it rather than leave it floating")
	game.world["drops"].clear()
	game.inventory["Wildflower"] = 1
	game._equip_inventory_item("Wildflower")
	game._place(Vector2(609 * 16 + 8, 79 * 16 + 8) - game.camera_pos)
	check(game.inventory["Wildflower"] == 1, "Planting must still respect the player's build reach")
	print("HARVEST actual mining, no duplication, magnetic collection, replanting, hotbar pages, support removal and reach checked")


func fauna_checks(game) -> void:
	fixture(game)
	check(game.ground_life.place(game, "Beetle", Vector2i(602, 79)), "Critters must be releasable onto ground")
	var beetle: Dictionary = game.ground_life.entries.back()
	var start := float(beetle["x"])
	for _frame in range(60):
		game.animation_clock += 1.0 / 60
		game.ground_life.update(game, 1.0 / 60)
	check(float(beetle["x"]) > start + 15 and game.health == 100, "Passable wildlife must flee the nearby player without dealing damage")
	game.player_pos.x = float(beetle["x"]) - 8
	game._update_camera()
	game.mining_cooldown = 0
	game._mine(game.ground_life.position(beetle) - Vector2(0, 4) - game.camera_pos)
	check(not beetle["alive"] and game.world["drops"].back()["item"] == "Beetle", "Fauna must also be mineable/catchable")
	check(game.ground_life.place(game, "Butterfly", Vector2i(605, 79)), "Flying critters must have native sprite placement")
	var butterfly: Dictionary = game.ground_life.entries.back()
	game.ground_life.update(game, 0.1)
	check(game.ground_life.position(butterfly).y < float(butterfly["y"]) - 7, "Flying fauna must hover above the ground")
	for index in range(Life.ITEMS.size()):
		var expected_size := Vector2(48, 40) if Life.SPECIES[index] in Life.COVER else Vector2(24, 32)
		if Life.SPECIES[index] in Life.DESERT:
			expected_size = Vector2(64, Life.HEIGHTS[index])
		var expected_frames := 1 if Life.SPECIES[index] in ["pebble_cluster", "granite_boulder", "sandstone_rock", "basalt_rock"] else 4
		check(game.ground_life.icon(Life.ITEMS[index]).get_size() == expected_size
			and game.ground_life.frames[Life.SPECIES[index]].size() == expected_frames, "All collectible icons and animations must use the Aseprite exports")
	print("FAUNA native frames/icons, fleeing, safe contact, catching and hovering checked")


func save_checks(game) -> void:
	fixture(game)
	game.ground_life.place(game, "Desert Cactus", Vector2i(601, 79))
	game.ground_life.place(game, "Snow Moth", Vector2i(603, 79))
	game._mine(Vector2(601 * 16 + 8, 80 * 16 - 14) - game.camera_pos)
	var alive := 0
	for entry: Dictionary in game.world["ground_life"]:
		alive += 1 if entry["alive"] else 0
	game.inventory["Ground Bird"] = 1
	game.hotbar.assign("Ground Bird", 41, game.inventory)
	game._equip_inventory_item("Ground Bird")
	game.save_path = "user://galaxis_ground_life_check.json"
	game._save_game()
	game._load_game()
	await process_frame
	await process_frame
	var restored := 0
	for entry: Dictionary in game.world["ground_life"]:
		restored += 1 if entry["alive"] else 0
	check(game.world["ground_life_version"] == 1 and game.world["ground_life"].size() == 2 and restored == alive,
		"Saving/loading must preserve live specimens and harvested state without repopulating")
	check(game.ground_life.visible(game).size() == 1, "Reloading must rebuild the spatial index only for live specimens")
	check(game.hotbar_page == 4 and game.place_items[game.selected_slot] == "Ground Bird", "The new inventory items and fifth hotbar page must survive saving")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(game.save_path))


func run_check() -> void:
	generation_checks()
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	await game._open_planet(0)
	game.set_process(false)
	movement_checks(game)
	harvest_checks(game)
	fauna_checks(game)
	await save_checks(game)
	fixtures.free()
	print("GROUND_LIFE failures=", failures)
	quit(0 if failures == 0 else 1)
