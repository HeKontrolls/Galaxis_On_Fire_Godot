extends SceneTree

const WG = preload("res://scripts/world_gen.gd")
const Env = preload("res://scripts/world_environment.gd")
var failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		printerr(message)

func generation_checks() -> void:
	for seed_value in [713, 531209, 741927, 125891, 98765]:
		var data := WG.generate(seed_value, 6)
		var same := WG.generate(seed_value, 6)
		check(data["tiles"] == same["tiles"] and data["ice_pillars"] == same["ice_pillars"], "Seed reproduces ice fields exactly")
		var tallest := 0
		var heights := {}
		var leanings := {}
		var fields := {}
		for spire: Dictionary in data["ice_pillars"]:
			var x := int(spire["x"])
			var y := int(spire["y"])
			var height := int(spire["height"])
			tallest = maxi(tallest, height)
			heights[height] = true
			leanings[int(spire["lean"])] = true
			fields[int(spire["field"])] = true
			check(absi(x - 600) >= 70 and height >= 16 and height <= 58, "Towering needles preserve a clear landing area")
			check(WG.tile_at(data["tiles"], x, y + 1) == 27, "Ice spires are anchored into a floe")
			check(WG.tile_at(data["tiles"], int(spire["tip_x"]), int(spire["top_y"])) == 27, "Each spire terminates at a mineable tip")
			var top_width := 0
			for ox in range(-1, 2):
				if WG.tile_at(data["tiles"], int(spire["tip_x"]) + ox, int(spire["top_y"])) == 27:
					top_width += 1
			check(top_width == 1, "Ice narrows to a single-block needle point")
			var connected := {}
			var pending: Array[Vector2i] = [Vector2i(x, y + 1)]
			while not pending.is_empty():
				var cell: Vector2i = pending.pop_back()
				if connected.has(cell) or WG.tile_at(data["tiles"], cell.x, cell.y) != 27:
					continue
				connected[cell] = true
				for offset in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
					pending.append(cell + offset)
			check(connected.has(Vector2i(int(spire["tip_x"]), int(spire["top_y"]))), "Leaning needle tips stay connected to their roots")
		check(tallest >= 40 and data["ice_pillars"].size() > 10, "Frozen oceans contain large tall ice fields")
		check(heights.size() > 8 and leanings.size() > 3 and fields.size() > 5, "Height, lean and field placement vary naturally")
		var spawn: Vector2 = data["spawn"]
		check(not WG.is_solid(WG.tile_at(data["tiles"], floori((spawn.x + 8) / 16), floori((spawn.y + 14) / 16))), "Player spawns clear of solid ice")
		print("GLACIAL seed=", seed_value, " spires=", data["ice_pillars"].size(), " tallest_blocks=", tallest, " distinct_heights=", heights.size(), " fields=", fields.size())
	for climate in [0, 1, 2, 3, 4, 5, 7]:
		var data := {"climate": climate}
		check(WG.enrich_ice_spires(data) == 0, "Ice enrichment is restricted to frozen oceans")

func legacy_checks() -> void:
	var data := WG.generate(713, 6)
	data["ice_spires_version"] = 0
	for x in range(WG.WIDTH):
		var floor_y := WG._ice_surface(data, x)
		for y in range(20, 102):
			if WG.tile_at(data["tiles"], x, y) == 27:
				WG.set_tile(data["tiles"], x, y, 6 if y >= floor_y else 0)
	data["ice_pillars"] = [{"x": 120, "y": 98, "height": 22}]
	for x in range(118, 123):
		for y in range(76, 98):
			WG.set_tile(data["tiles"], x, y, 27)
	# Remove one old documented tower: the upgrade must not regrow it.
	var original: Dictionary = data["ice_pillars"][0].duplicate()
	var left := int(original["x"]) - 13
	var right := int(original["x"]) + 13
	for x in range(left, right + 1):
		for y in range(20, int(original["y"])):
			if WG.tile_at(data["tiles"], x, y) == 27:
				WG.set_tile(data["tiles"], x, y, 0)
	var old_footprint: PackedByteArray = data["tiles"].duplicate()
	# Mark player construction away from landing, plus a harvested plant patch.
	WG.set_tile(data["tiles"], 300, 95, 33)
	data["player_pos"] = Vector2(380 * 16, 98 * 16 - 28)
	data["ground_life"] = [{"x": 220.0 * 16 + 8, "y": 98.0 * 16, "alive": false, "species": "frost_grass"}]
	var old_count: int = data["ice_pillars"].size()
	var added := WG.enrich_ice_spires(data)
	check(added > 0, "Older worlds gain new spires in untouched areas")
	for x in range(left, right + 1):
		for y in range(20, int(original["y"])):
			check(WG.tile_at(data["tiles"], x, y) == WG.tile_at(old_footprint, x, y), "One-time upgrade preserves mined old spire footprints")
	check(WG.tile_at(data["tiles"], 300, 95) == 33, "Ice upgrade preserves construction")
	for i in range(old_count, data["ice_pillars"].size()):
		var spire: Dictionary = data["ice_pillars"][i]
		check(absf(int(spire["x"]) - 380) >= 24, "Upgrade preserves player vicinity")
		check(absi(int(spire["x"]) - 220) > int(spire["radius"]) + 1, "Upgrade preserves harvested ground-life patches")
	var once: PackedByteArray = data["tiles"].duplicate()
	check(WG.enrich_ice_spires(data) == 0 and data["tiles"] == once and data["ice_spires_version"] == 2, "Revisits never respawn mined spires")
	print("GLACIAL_LEGACY old towers/builds/player/harvested patches preserved; additions=", added)

func light_world(material: int) -> Dictionary:
	var grid := PackedByteArray()
	grid.resize(WG.WIDTH * WG.HEIGHT)
	for y in range(110, WG.HEIGHT):
		for x in range(WG.WIDTH):
			WG.set_tile(grid, x, y, 3)
	for y in range(75, 110):
		for x in range(600, 607):
			WG.set_tile(grid, x, y, material)
	var surface := PackedInt32Array()
	surface.resize(WG.WIDTH)
	surface.fill(110)
	return {"tiles": grid, "surface": surface, "seed": 713, "climate": 0, "torches": {}}

func render_and_save_checks() -> void:
	var environment := Env.new()
	var cam := Vector2(570 * 16, 70 * 16)
	environment.reset(light_world(3))
	environment.prepare(cam, Vector2(630 * 16, 105 * 16), 1, 0.4, 0)
	var stone_dark: float = environment.brightness_at(Vector2(603 * 16 + 8, 100 * 16 + 8))
	environment.reset(light_world(27))
	environment.prepare(cam, Vector2(630 * 16, 105 * 16), 1, 0.4, 1)
	check(environment.brightness_at(Vector2(603 * 16 + 8, 100 * 16 + 8)) > stone_dark + 0.2, "Glacial crystal transmits light through its faces")
	check(environment.brightness_at(Vector2(603 * 16 + 8, 125 * 16 + 8)) < 0.01, "Ordinary underground rock stays dark")
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.set_process(false)
	await game._open_planet(6)
	game.save_path = "user://galaxis_glacial_spires_check.json"
	var before: PackedByteArray = game.world["tiles"].duplicate()
	var spires: Array = game.world["ice_pillars"].duplicate(true)
	game._save_game()
	game._load_game()
	while game.scene_name != "planet":
		await process_frame
	check(game.world["tiles"] == before and game.world["ice_spires_version"] == 2 and game.world["ice_pillars"].size() == spires.size(), "Ice geometry and upgrade marker survive saving")
	var pillar: Dictionary = game.world["ice_pillars"][0]
	var tile := Vector2i(int(pillar["tip_x"]), int(pillar["top_y"]))
	var chunk: Dictionary = game.terrain_cache._build(Vector2i(tile.x / 8, tile.y / 8))
	var image: Image = chunk["front"].get_image()
	var at := Vector2i(tile.x % 8, tile.y % 8) * 16
	check(image.get_pixel(at.x, at.y).a == 0 and image.get_pixel(at.x + 8, at.y).a > 0, "Rendered needle has transparent corners and a pointed apex")
	check(game.world_image.get_pixel(tile.x, tile.y).a == 0, "World base layer cannot fill transparent tip corners")
	game.player_pos = Vector2(tile * 16) - Vector2(28, -3)
	game._update_camera()
	game.inventory = {"Pickaxe": 1, "Glacial Ice": 1}
	game._equip_inventory_item("Pickaxe")
	game.mining_cooldown = 0
	game._mine(Vector2(tile * 16) + Vector2(8, 8) - game.camera_pos)
	check(WG.tile_at(game.world["tiles"], tile.x, tile.y) == 0 and game.world["drops"][-1]["item"] == "Glacial Ice", "Needles are actual mineable terrain with glacial drops")
	game._equip_inventory_item("Glacial Ice")
	game._place(Vector2(tile * 16) + Vector2(8, 8) - game.camera_pos)
	check(WG.tile_at(game.world["tiles"], tile.x, tile.y) == 27, "Collected glacial ice remains placeable")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(game.save_path))
	game.queue_free()
	await process_frame
	print("GLACIAL_RENDER light transmission, dark caves, transparent tips, saves, mining and placement checked")

func run() -> void:
	generation_checks()
	legacy_checks()
	await render_and_save_checks()
	print("GLACIAL_SPIRES failures=", failures)
	quit(0 if failures == 0 else 1)
