extends SceneTree

const WG = preload("res://scripts/world_gen.gd")
const Life = preload("res://scripts/ground_life.gd")
const EcologyChecks = preload("res://tests/ground_life_check.gd")
const Lighting = preload("res://scripts/world_environment.gd")
var fixtures = EcologyChecks.new()
var failures := 0


func _initialize() -> void:
	call_deferred("run_check")


func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		printerr(message)


func run_check() -> void:
	var data := WG.generate(713, 0)
	var original: PackedByteArray = data["tiles"].duplicate()
	var environment := Lighting.new()
	environment.reset(data)
	Life.populate(data, environment.roof)
	var bushes := 0
	var rocks := 0
	for entry: Dictionary in data["ground_life"]:
		bushes += 1 if entry["species"] in ["leafy_bush", "forest_thicket", "flowering_bush"] else 0
		rocks += 1 if entry["species"] in Life.ROCKS else 0
	check(bushes > 20 and rocks > 5 and data["tiles"] == original, "Full bushes and rocks must populate terrain without adding solid collision tiles")
	var legacy: Dictionary = data.duplicate(true)
	legacy["ground_life"] = legacy["ground_life"].filter(func(entry): return entry["species"] not in Life.COVER)
	legacy["ground_life"][0]["alive"] = false
	legacy["ground_cover_version"] = 0
	var before: Array = legacy["ground_life"].duplicate(true)
	var cleared_column := floori(float(before[0]["x"]) / 16)
	Life.populate(legacy, environment.roof)
	for index in range(before.size()):
		check(legacy["ground_life"][index] == before[index], "Cover upgrade must preserve existing life and harvested state")
	for entry: Dictionary in legacy["ground_life"]:
		if entry["species"] in Life.COVER:
			check(absi(floori(float(entry["x"]) / 16) - cleared_column) > 2, "The upgrade must respect previously cleared plant patches")
	var count: int = legacy["ground_life"].size()
	Life.populate(legacy, environment.roof)
	check(legacy["ground_life"].size() == count, "Returning to a planet must not add the same bushes and rocks repeatedly")
	print("GROUND_COVER population bushes=", bushes, " rocks=", rocks, " safe one-time upgrade checked")
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	await game._open_planet(0)
	game.set_process(false)
	fixtures.fixture(game)
	for name: String in Life.COVER:
		check(game.ground_life.frames[name][0].get_size() == Vector2(48, 40), "Wider cover must use the native 48x40 Aseprite canvas")
	check(not Life.animal("leafy_bush") and not Life.animal("granite_boulder"), "New cover must not be classified as roaming fauna")
	var berry: Image = game.ground_life.frames["berry_shrub"][0].get_image()
	var pixels := 0
	for y in range(12, 32):
		for x in range(24):
			pixels += 1 if berry.get_pixel(x, y).a > 0 else 0
	var center_pixels := 0
	for y in range(20, 30):
		for x in range(6, 19):
			center_pixels += 1 if berry.get_pixel(x, y).a > 0 else 0
	check(pixels > 200 and center_pixels > 110, "The existing berry shrub must have a continuous leafy center rather than separated tufts")
	check(game.ground_life.place(game, "Leafy Bush", Vector2i(601, 79)), "Wide bushes must remain placeable")
	var bush: Dictionary = game.ground_life.entries.back()
	game._mine(Vector2(float(bush["x"]), float(bush["y"]) - 15) - game.camera_pos)
	check(not bush["alive"] and game.world["drops"].back()["item"] == "Leafy Bush", "Full bushes must be mineable and retain their own collectible")
	game.world["drops"].clear()
	for tool in ["Pickaxe", "Stone Pickaxe", "Copper Pickaxe", "Iron Pickaxe"]:
		fixtures.fixture(game)
		game.inventory[tool] = 1
		game._equip_inventory_item(tool)
		check(game.ground_life.place(game, "Granite Boulder", Vector2i(601, 79)), "Boulders must be placeable as passable objects")
		var rock: Dictionary = game.ground_life.entries.back()
		var point: Vector2 = Vector2(float(rock["x"]), float(rock["y"]) - 12) - game.camera_pos
		var hits: int = 6 - game.Tools.tier(tool)
		for step in range(hits):
			game.mining_cooldown = 0
			game._mine(point)
			check(bool(rock["alive"]) == (step < hits - 1), "Boulder harvesting must respect pickaxe material and repeated hits")
		check(game.world["drops"].size() == 1 and game.world["drops"][0]["item"] == "Granite Boulder", "A broken boulder must drop once")
	fixtures.fixture(game)
	game.ground_life.place(game, "Granite Boulder", Vector2i(601, 79))
	var rock: Dictionary = game.ground_life.entries.back()
	game.equipped_tool = "Hand"
	game._mine(Vector2(float(rock["x"]), float(rock["y"]) - 12) - game.camera_pos)
	check(rock["alive"] and game.notice.contains("pickaxe"), "Ground rocks must require a pickaxe")
	var start: Vector2 = game.player_pos
	fixtures.key(KEY_D, true)
	for _frame in range(30):
		game._update_player(1.0 / 60)
		game.ground_life.update(game, 1.0 / 60)
	fixtures.key(KEY_D, false)
	check(game.player_pos.x > start.x + 100, "The player must walk through broad rocks without collision")
	check(Life.wind_bend("granite_boulder", 1, 3, 100) == 0, "Rock geometry must stay rigid during wind gusts")
	game.inventory["Basalt Rock"] = 1
	game.hotbar.assign("Basalt Rock", 50, game.inventory)
	game._equip_inventory_item("Basalt Rock")
	check(game.hotbar_page == 5, "New cover collectibles must be reachable on the sixth hotbar page")
	game.save_path = "user://galaxis_ground_cover_check.json"
	game._save_game()
	game._load_game()
	await process_frame
	await process_frame
	check(game.world["ground_cover_version"] == 1 and game.hotbar_page == 5 and game.world["ground_life"].size() == 1,
		"Cover state and sixth-page selection must survive save/load without repopulating")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(game.save_path))
	fixtures.fixtures.free()
	fixtures.free()
	print("GROUND_COVER native dimensions, fuller berry art, harvesting, tool tiers, passability, rigid rocks and saves: failures=", failures)
	quit(0 if failures == 0 else 1)
