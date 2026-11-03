extends SceneTree

const WG = preload("res://scripts/world_gen.gd")
const Tools = preload("res://scripts/tool_catalog.gd")
const Fixtures = preload("res://tests/tool_progression_check.gd")
var failures := 0
var fixtures = Fixtures.new()


func _initialize() -> void:
	call_deferred("run_check")


func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		printerr(message)


func tree_fixture(game, item: String) -> Vector2:
	fixtures.fixture(game)
	game.inventory[item] = 1
	game._equip_inventory_item(item)
	for y in range(68, 80):
		game._edit_tile(Vector2i(601, y), 7)
	game._edit_tile(Vector2i(602, 69), 8)
	return Vector2(601 * 16 + 8, 79 * 16 + 8) - game.camera_pos


func check_chopping(game) -> void:
	for item in ["Axe", "Copper Axe", "Iron Axe", "Pickaxe", "Stone Pickaxe", "Copper Pickaxe", "Iron Pickaxe"]:
		var point := tree_fixture(game, item)
		var hits := Tools.mining_hits(item, 7)
		for index in range(hits):
			game.mining_cooldown = 0
			game._mine(point)
			if index < hits - 1:
				check(WG.tile_at(game.world["tiles"], 601, 79) == 7 and game.world["drops"].is_empty(),
					"Tree and inventory must remain intact until the final hit: " + item)
			else:
				check(WG.tile_at(game.world["tiles"], 601, 79) == 0 and game.world["drops"].size() == 13,
					"Final trunk hit must release every trunk and leaf block: " + item)
		print("CHOP ", Tools.display_name(item), " hits=", hits, " earliest_seconds=", (hits - 1) * Tools.mining_interval(item, 7))
	var point := tree_fixture(game, "Axe")
	game._mine(point)
	var partial: Dictionary = game.world["mining_damage"].duplicate(true)
	for _spam in range(20):
		game._mine(point)
	check(game.world["mining_damage"] == partial, "Repeated clicks during recovery must not add trunk damage")
	game.mining_cooldown = 0
	game._mine(point - Vector2(0, 16))
	check(game.world["mining_damage"].size() == 1 and game.world["mining_damage"]["601,79"]["work"] == 0.25,
		"Changing the struck trunk section must retain one tree's accumulated damage")
	for item in ["Axe", "Copper Axe", "Iron Axe"]:
		fixtures.fixture(game)
		game.inventory[item] = 1
		game._equip_inventory_item(item)
		game._edit_tile(Vector2i(601, 80), 2)
		var dirt: Vector2 = Vector2(601 * 16 + 8, 80 * 16 + 8) - game.camera_pos
		for index in range(Tools.mining_hits(item, 2)):
			game.mining_cooldown = 0
			game._mine(dirt)
			check((WG.tile_at(game.world["tiles"], 601, 80) == 0) == (index == Tools.mining_hits(item, 2) - 1),
				"Axes must take multiple real hits to dig dirt: " + item)
	point = tree_fixture(game, "Iron Pickaxe")
	game._mine(Vector2(602 * 16 + 8, 69 * 16 + 8) - game.camera_pos)
	check(WG.tile_at(game.world["tiles"], 601, 79) == 7, "Mining leaves must not bypass trunk health and fell the tree")
	game.player_pos = Vector2(601 * 16, 71 * 16)
	game._update_camera()
	game.mining_cooldown = 0
	game._mine(Vector2(602 * 16 + 8, 69 * 16 + 8) - game.camera_pos)
	check(WG.tile_at(game.world["tiles"], 602, 69) == 0 and WG.tile_at(game.world["tiles"], 601, 69) == 7,
		"Clearing a reachable leaf must drop only that leaf and preserve the trunk")
	for fps in [30, 60, 144]:
		point = tree_fixture(game, "Axe")
		var event := InputEventMouseButton.new()
		event.position = point
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = true
		game._input(event)
		var elapsed := 0.0
		while WG.tile_at(game.world["tiles"], 601, 79) == 7 and elapsed < 5:
			game._update_held_actions(1.0 / fps)
			elapsed += 1.0 / fps
		check(elapsed >= 2.66 and elapsed < 2.95, "Held chopping must take real time across FPS: " + str(elapsed))
		game._stop_held_actions()
	print("CHOPPING cooldowns, shared trunk health, leaf safety, axe dirt and held-input timing checked")


func check_biomes() -> void:
	for climate in range(8):
		var first := WG.generate(713, climate)
		var second := WG.generate(713, climate)
		check(first["tiles"] == second["tiles"] and first["biomes"] == second["biomes"], "Terrain and biome regions must repeat exactly from a seed")
		var columns: PackedByteArray = first["biomes"]
		var variety := {}
		var tree_counts := [0, 0, 0, 0]
		var materials := {}
		var surface_water := 0
		var surface_lava := 0
		var ice_by_region := [0, 0, 0, 0]
		for x in range(WG.WIDTH):
			var region := int(columns[x])
			variety[region] = true
			materials[WG.tile_at(first["tiles"], x, first["surface"][x])] = true
			for y in range(maxi(0, first["surface"][x] - 23), first["surface"][x]):
				var id := WG.tile_at(first["tiles"], x, y)
				if id == 7 and WG.tile_at(first["tiles"], x, y + 1) != 7:
					tree_counts[region] += 1
				if id == 4:
					surface_water += 1
				if id == 11:
					surface_lava += 1
			if climate == 6 and abs(x - WG.WIDTH / 2) > 30:
				for y in range(88, 103):
					if WG.tile_at(first["tiles"], x, y) == 6:
						ice_by_region[region] += 1
		check(variety.size() == 4, "Every planet type must contain all four of its biome regions")
		check(columns != WG.Biomes.generate(531209, climate), "Different seeds must change biome boundaries")
		var spawn: Vector2 = first["spawn"]
		var feet := Vector2i(floor((spawn + Vector2(8, 29)) / WG.TILE))
		check(WG.is_solid(WG.tile_at(first["tiles"], feet.x, feet.y)), "Every biome world needs a solid safe landing")
		if climate == 0:
			check(tree_counts[0] == 0 and tree_counts[3] == 0 and tree_counts[1] > 5 and tree_counts[2] > 5,
				"Forest worlds must have treeless meadows/uplands and distinct wooded clusters")
			check(materials.has(1) and materials.has(3), "Forest biomes must change surface materials as well as labels")
		if climate == 3:
			check(surface_water > 0 and materials.has(1) and materials.has(3) and materials.has(5), "Desert regions need actual oases, dunes and rocky ground")
		if climate == 4:
			check(surface_lava > 0 and materials.has(17), "Volcanic regions need actual lava fields and obsidian flats")
		if climate == 6:
			check(ice_by_region[0] > 0 and ice_by_region[2] > ice_by_region[0] and ice_by_region[3] == 0,
				"Frozen seas must vary ice thickness and retain open-water leads")
		print("BIOMES climate=", climate, " profiles=", variety.size(), " trees_by_region=", tree_counts, " surface_materials=", materials.keys())
	var legacy := {"climate": 0, "forest_density_version": 0}
	check(WG.enrich_forest(legacy) == 0, "Legacy worlds must not receive blanket tree enrichment")


func check_saves(game) -> void:
	var point := tree_fixture(game, "Axe")
	game.world["biomes"] = WG.Biomes.generate(713, 0)
	game.world["biome_version"] = 1
	game._mine(point)
	var damage: Dictionary = game.world["mining_damage"].duplicate(true)
	var columns: PackedByteArray = game.world["biomes"].duplicate()
	game.save_path = "user://galaxis_chopping_biomes_check.json"
	game._save_game()
	game._load_game()
	await process_frame
	await process_frame
	check(game.world.get("biomes", PackedByteArray()) == columns, "Biome regions must survive saving and loading")
	var restored: Dictionary = game.world.get("mining_damage", {})
	print("SAVE_DAMAGE expected=", damage, " restored=", restored)
	check(restored.has("601,79") and is_equal_approx(float(restored["601,79"]["work"]), float(damage["601,79"]["work"]))
		and int(restored["601,79"]["id"]) == 7, "Partial chopping must survive saving and loading")
	check(game.world.get("biome_version", 0) == 1, "The biome generation marker must survive saving")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(game.save_path))


func run_check() -> void:
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	await game._open_planet(0)
	game.set_process(false)
	check_chopping(game)
	check_biomes()
	await check_saves(game)
	fixtures.free()
	print("CHOPPING_BIOMES failures=", failures)
	quit(0 if failures == 0 else 1)
