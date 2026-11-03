extends SceneTree
const WG = preload("res://scripts/world_gen.gd")
const Cave = preload("res://scripts/underground.gd")
var failures := 0
func check(ok: bool, label: String) -> void:
	if not ok: failures += 1; printerr(label)
func _initialize() -> void: call_deferred("run_check")
func run_check() -> void:
	var start := Time.get_ticks_msec()
	var world := WG.generate(741927, 0, false)
	check(WG.HEIGHT == 1440 and world.tiles.size() == 1200 * 1440, "Four-times world depth missing")
	var regions := {}
	for y in range(150, WG.HEIGHT, 31):
		for x in range(8, WG.WIDTH - 8, 41): regions[Cave.biome(world, x, y)] = true
	check(regions.size() == 7, "Missing underground biomes")
	var lava := 0; var water := 0; var caves := 0; var ores := 0
	for y in range(360, WG.HEIGHT):
		for x in range(WG.WIDTH):
			var id: int = world.tiles[y * WG.WIDTH + x]
			if id == 11: lava += 1
			elif id == 4: water += 1
			elif id == 0: caves += 1
			elif id in [20, 21, 22, 23, 24, 25, 26]: ores += 1
	check(lava > 10000 and water > 0 and caves > 10000 and ores > 1000, "Deep caves/pools/resources missing")
	check(WG.tile_at(world.tiles, 8, WG.HEIGHT - 10) == 11 and WG.tile_at(world.tiles, 600, WG.HEIGHT - 1) == 17, "Bottom lava sea or foundation missing")
	Cave.populate(world)
	var kinds := {}; var colors := {}
	for entry in world.cave_life:
		kinds[entry.kind] = true
		if int(entry.kind) == 0: colors[entry.color] = true
	check(kinds.size() == 5 and colors.size() == 5, "Cave formations or crystal colors missing")
	# Migrate a real legacy-size grid, including player blocks and partial fluids.
	var legacy := world.duplicate(true)
	legacy.tiles = world.tiles.slice(0, WG.WIDTH * WG.LEGACY_HEIGHT)
	legacy.underground_version = 0
	legacy.underworld_structures_version = 0
	legacy.underworld_forts = []
	for field in ["torches", "chest_contents"]:
		for key in legacy.get(field, {}).keys():
			if int(key.split(",")[1]) >= WG.LEGACY_HEIGHT: legacy[field].erase(key)
	legacy.tiles[180 * WG.WIDTH + 590] = 33
	var before: PackedByteArray = legacy.tiles.duplicate()
	var amounts := PackedByteArray(); amounts.resize(before.size()); amounts[200 * WG.WIDTH + 600] = 93
	legacy.water = amounts
	Cave.extend(legacy)
	check(legacy.tiles.slice(0, before.size()) == before, "Migration changed existing terrain/builds")
	check(legacy.water.size() == WG.WIDTH * WG.HEIGHT and legacy.water[200 * WG.WIDTH + 600] == 93, "Migration lost partial fluid")
	check(legacy.tiles.slice(before.size()) == world.tiles.slice(before.size()), "New deep layers must be deterministic")
	legacy.tiles[800 * WG.WIDTH + 600] = 33
	Cave.extend(legacy)
	check(legacy.tiles[800 * WG.WIDTH + 600] == 33, "Reload rebuilt deep player edits")
	print("UNDERGROUND generation_ms=%d caves=%d water=%d lava=%d ores=%d decor=%d" % [Time.get_ticks_msec() - start, caves, water, lava, ores, world.cave_life.size()])
	for climate in range(1, 8):
		var probe := WG.generate(713, climate, false)
		check(probe.tiles.size() == WG.WIDTH * WG.HEIGHT and WG.tile_at(probe.tiles, 8, WG.HEIGHT - 10) == 11, "Deep generation failed for climate %d" % climate)
	var g = load("res://main.tscn").instantiate()
	g.save_path = "user://galaxis_underground_check.json"
	root.add_child(g); g.set_process(false)
	# Exercise old compressed arrays without forcing a resize that discards values.
	var encoded := Marshalls.raw_to_base64(amounts.compress(FileAccess.COMPRESSION_DEFLATE))
	check(g._unpack_water(encoded) == amounts, "Old compressed water data did not decode exactly")
	await g._open_planet(0)
	var crystal: Dictionary = {}
	for entry in g.world.cave_life:
		if int(entry.kind) == 0 and int(entry.y) > 400: crystal = entry; break
	check(not crystal.is_empty(), "No deep crystal to inspect")
	if not crystal.is_empty():
		var at := Vector2(int(crystal.x) * 16 + 8, int(crystal.y) * 16)
		g.camera_pos = at - Vector2(640, 360)
		g.player_pos = at + Vector2(300, 0)
		g.environment.invalidate(); g.environment.prepare(g.camera_pos, g.player_pos, 1.0, 1.0, 0, false)
		var lit: float = g.environment.brightness_at(at)
		check(lit > 0.7 and g.environment.crystal_mesh != null, "Crystal does not illuminate caves")
		g.player_pos = at - Vector2(8, 11)
		g.equipped_tool = "Wood Pickaxe"
		g._mine(at - g.camera_pos)
		check(crystal.alive, "Wood tools must not harvest cave crystals")
		g.equipped_tool = "Iron Pickaxe"; g.inventory["Iron Pickaxe"] = 1
		g.mining_cooldown = 0; g._mine(at - g.camera_pos)
		check(not crystal.alive and not g.world.drops.is_empty(), "Mining a crystal must remove it and create a pickup")
		g.player_pos = at + Vector2(300, 0)
		g.environment.prepare(g.camera_pos, g.player_pos, 1.0, 1.0, 1, false)
		check(g.environment.brightness_at(at) < lit, "Removed crystal still emits light")
		g._save_game(); g._load_game()
		while g.scene_name == "loading": await process_frame
		check(g.world.tiles.size() == WG.WIDTH * WG.HEIGHT, "Expanded save failed to load")
		var saved_dead := false
		for entry in g.world.cave_life:
			if entry.x == crystal.x and entry.y == crystal.y and not entry.alive: saved_dead = true
		check(saved_dead, "Removed cave decoration regenerated on load")
	# Exercise the actual loader on an older 360-row save, not just the helper.
	var saved: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(g.save_path))
	var key: String = g._world_key()
	var old_tiles: PackedByteArray = g.world.tiles.slice(0, WG.WIDTH * WG.LEGACY_HEIGHT)
	old_tiles[250 * WG.WIDTH + 350] = 33
	saved.worlds[key].tiles = Marshalls.raw_to_base64(old_tiles)
	saved.worlds[key].underground_version = 0
	saved.worlds[key].underworld_structures_version = 0
	saved.worlds[key].underworld_forts = []
	for field in ["torches", "chest_contents"]:
		for position in saved.worlds[key].get(field, {}).keys():
			if int(position.split(",")[1]) >= WG.LEGACY_HEIGHT: saved.worlds[key][field].erase(position)
	saved.worlds[key].cave_life_version = 0
	saved.worlds[key].cave_life = []
	for field in ["water", "rain_water", "lava", "lava_cooling", "snow"]:
		var old_amounts: PackedByteArray = g.world.get(field, PackedByteArray()).slice(0, old_tiles.size())
		saved.worlds[key][field] = Marshalls.raw_to_base64(old_amounts.compress(FileAccess.COMPRESSION_DEFLATE)) if not old_amounts.is_empty() else ""
	var file := FileAccess.open(g.save_path, FileAccess.WRITE)
	file.store_string(JSON.stringify(saved)); file.close()
	g._load_game()
	while g.scene_name == "loading": await process_frame
	check(g.world.tiles.slice(0, old_tiles.size()) == old_tiles, "Actual legacy load changed saved terrain or builds")
	check(g.world.tiles.size() == WG.WIDTH * WG.HEIGHT and g.lava_sim.amount_at(Vector2i(8, WG.HEIGHT - 10)) == 255, "Legacy load lost the new bottom lava")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(g.save_path))
	print("UNDERGROUND_CHECK failures=%d" % failures)
	g.free(); quit(0 if failures == 0 else 1)
