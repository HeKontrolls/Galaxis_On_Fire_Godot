extends SceneTree
const WG = preload("res://scripts/world_gen.gd")
const Structures = preload("res://scripts/underworld_structures.gd")
var failures := 0
func check(ok: bool, message: String) -> void:
	if not ok: failures += 1; printerr(message)
func _initialize() -> void: call_deferred("run")
func legacy_fixture(seed_value: int) -> Dictionary:
	var grid := PackedByteArray(); grid.resize(WG.WIDTH * WG.HEIGHT)
	var lava := PackedByteArray(); lava.resize(grid.size())
	for y in range(WG.HEIGHT - 18, WG.HEIGHT):
		for x in range(4, WG.WIDTH - 4): grid[y * WG.WIDTH + x] = 17 if y >= WG.HEIGHT - 3 else 11
	for start in range(65, WG.WIDTH - 8, 137):
		for x in range(start, start + 8):
			for y in range(WG.HEIGHT - 57, WG.HEIGHT - 3):
				if y > WG.HEIGHT - 57 + absi(posmod(x, 137) - 69) * 2: grid[y * WG.WIDTH + x] = 17
	for i in range(grid.size()):
		if grid[i] == 11: lava[i] = 255
	return {"seed": seed_value, "tiles": grid, "lava": lava}
func run() -> void:
	for seed_value in [713, 741927, 531209]:
		var world := WG.generate(seed_value, 0, false)
		check(world.underworld_forts.size() == 5, "Missing fortresses")
		for x in range(12, WG.WIDTH - 12):
			check(world.tiles[Structures.DECK * WG.WIDTH + x] in [3, 17], "Broken bridge route at %d" % x)
		for fort in world.underworld_forts:
			check(world.tiles[(Structures.DECK - 2) * WG.WIDTH + int(fort.x)] == 0, "Fortress entrance blocked")
		check(world.chest_contents.size() == 5, "Missing fortress loot")
		var before: PackedByteArray = world.tiles.duplicate()
		world.tiles[Structures.DECK * WG.WIDTH + 50] = 0
		Structures.apply(world)
		check(world.tiles[Structures.DECK * WG.WIDTH + 50] == 0, "Mined bridge regenerated")
		var old := legacy_fixture(seed_value)
		Structures.apply(old)
		check(old.underworld_forts == world.underworld_forts, "Legacy layouts differ from new worlds")
		check(old.tiles[1386 * WG.WIDTH + 69] == 0, "Old tall pillar remains")
		for i in range((WG.HEIGHT - 60) * WG.WIDTH, before.size()):
			check(old.lava[i] == (255 if old.tiles[i] == 11 else 0), "Lava array does not match bridge terrain")
	var protected := legacy_fixture(713)
	protected.tiles[1371 * WG.WIDTH + 8] = 3
	protected.cave_life = [{"x": 8, "y": 1370, "kind": 0, "alive": true}, {"x": 69, "y": 1383, "kind": 0, "alive": true}]
	protected.tiles[1400 * WG.WIDTH + 69] = 33
	protected.tiles[1407 * WG.WIDTH + 119] = 30
	protected.chest_contents = {"119,1407": {"Gold Ore": 99}}
	Structures.apply(protected)
	check(protected.tiles[1400 * WG.WIDTH + 69] == 33 and protected.tiles[1386 * WG.WIDTH + 69] == 17, "Modified pillar or build overwritten")
	check(protected.tiles[1407 * WG.WIDTH + 119] == 30 and protected.chest_contents["119,1407"]["Gold Ore"] == 99, "Saved chest overwritten")
	check(protected.cave_life[0].alive, "Unaffected cave crystal removed")
	var g = load("res://main.tscn").instantiate()
	root.add_child(g); g.set_process(false)
	g.save_path = "user://underworld_structures_check.json"
	await g._open_planet(0)
	var fort: Dictionary = g.world.underworld_forts[2]
	var chest := Vector2i(int(fort.x) + int(fort.width) / 2, Structures.DECK - 1)
	var chest_key := "%d,%d" % [chest.x, chest.y]
	g.player_pos = Vector2(chest.x * 16 - 24, Structures.DECK * 16 - 28)
	g._key_pressed(KEY_F)
	check(g.interactions.is_open() and g.interactions.chest_key == chest_key, "Fortress chest cannot be opened with F")
	var gold := int(g.interactions.contents().get("Gold Ore", 0))
	g.interactions.withdraw("Gold Ore")
	check(gold > 0 and int(g.inventory.get("Gold Ore", 0)) >= gold, "Fortress loot could not be collected")
	g.interactions.close()
	g._edit_tile(Vector2i(50, Structures.DECK), 0)
	var forts: Array = g.world.underworld_forts.duplicate(true)
	g._save_game(); g._load_game()
	while g.scene_name == "loading": await process_frame
	check(g.world.underworld_forts.size() == forts.size(), "Save/load lost fortresses")
	for i in range(mini(g.world.underworld_forts.size(), forts.size())):
		for field in ["x", "width", "roof"]:
			check(int(g.world.underworld_forts[i][field]) == int(forts[i][field]), "Save/load changed fortress " + field)
	check(g.world.tiles[Structures.DECK * WG.WIDTH + 50] == 0, "Save/load rebuilt mined bridge")
	check(not g.world.chest_contents[chest_key].has("Gold Ore"), "Reload replenished looted fortress chest")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(g.save_path))
	print("UNDERWORLD_STRUCTURES failures=", failures)
	g.free(); quit(0 if failures == 0 else 1)
