extends SceneTree

const BG = preload("res://scripts/biome_backgrounds.gd")
const WG = preload("res://scripts/world_gen.gd")
var failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, label: String) -> void:
	if not ok:
		failures += 1
		printerr(label)

func catalog_checks() -> void:
	var backgrounds := BG.new()
	var hashes := {}
	var ids := {}
	var levels := PackedInt32Array()
	levels.resize(WG.WIDTH)
	levels.fill(125)
	for climate in range(8):
		var columns := WG.Biomes.generate(713, climate)
		var data := {"seed": 713, "climate": climate, "surface": levels, "biomes": columns}
		backgrounds.reset(data)
		check(backgrounds.textures.size() == 4, "Only the current planet's four regions are cached")
		for biome in range(4):
			var scene := backgrounds.scene_for(biome)
			check(scene["label"] == WG.Biomes.profile(climate, biome)["name"], "Every biome selects its own correctly named backdrop")
			ids[scene["id"]] = true
			for plane in range(3):
				var texture: Texture2D = backgrounds.textures[biome][plane]
				check(texture != null, "Every backdrop PNG must load successfully")
				if texture == null:
					continue
				check(texture.get_size() == Vector2(640, 256), "All three scenery planes retain native pixel dimensions")
				var path: String = BG.ROOT + str(scene["id"]) + "/" + str(backgrounds.catalog["planes"][plane]) + ".png"
				hashes[FileAccess.get_md5(path)] = true
		check(data["biomes"] == columns and data.size() == 4, "Backdrop initialization cannot modify gameplay or save data")
		for boundary in backgrounds.boundaries:
			var left := backgrounds.weights_at(boundary - 0.01)
			var right := backgrounds.weights_at(boundary + 0.01)
			check(left.size() == 2 and right.size() == 2, "Biome boundaries blend neighboring scenes")
			check(absf(float(left[1]["weight"]) - float(right[1]["weight"])) < 0.002, "Crossing a biome boundary cannot flash or pop the backdrop")
			check(absf(float(left[0]["weight"]) + float(left[1]["weight"]) - 1) < 0.0001, "Transition weights stay normalized")
		print("BACKGROUND climate=", climate, " scenes=4 boundaries=", backgrounds.boundaries.size())
	check(ids.size() == 32 and hashes.size() == 96, "All 32 biome scenes and their 96 scenery planes are distinct")
	var shifts: Array[float] = []
	for plane in range(3):
		shifts.append(absf(backgrounds.plane_origin(Vector2(200, 100), plane).x - backgrounds.plane_origin(Vector2(100, 100), plane).x))
	check(shifts[0] < shifts[1] and shifts[1] < shifts[2] and shifts[2] < 100, "Distant scenery scrolls more slowly than near scenery and foreground terrain")
	var original := backgrounds.plane_origin(Vector2(200, 100), 1)
	backgrounds.reset({"seed": 713, "climate": 7, "surface": levels})
	check(backgrounds.plane_origin(Vector2(200, 100), 1) == original, "Legacy biome fallback and panorama offsets are deterministic")
	backgrounds.reset({"seed": 714, "climate": 7, "surface": levels})
	check(backgrounds.plane_origin(Vector2(200, 100), 1) != original, "Different planet seeds vary the scenery alignment")
	check(backgrounds.daylight_tint(0, 0, Color.WHITE).get_luminance() < backgrounds.daylight_tint(1, 0, Color.WHITE).get_luminance() * 0.4, "Scenery follows night lighting")
	check(backgrounds.daylight_tint(1, 1, Color.WHITE).get_luminance() < backgrounds.daylight_tint(1, 0, Color.WHITE).get_luminance(), "Storms darken the distant landscape")

func redraw(game) -> void:
	game.queue_redraw()
	await process_frame
	await process_frame

func gameplay_checks() -> void:
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.set_process(false)
	await game._open_planet(0)
	var column := 0
	for x in range(30, WG.WIDTH - 30):
		if game.world["biomes"][x] == 2 and game.world["biomes"][x - 20] == 2 and game.world["biomes"][x + 20] == 2:
			column = x
			break
	check(column > 0, "Forest fixture locates a dense woodland region")
	game.player_pos = Vector2(column * 16, game.world["surface"][column] * 16 - 28)
	game._update_camera()
	game.time_of_day = 0.25
	game.weather = "Clear"
	game.weather_blend.reset("Clear", 0)
	var grid: PackedByteArray = game.world["tiles"].duplicate()
	await redraw(game)
	check(game.biome_backgrounds.diagnostic["planes"] == 6 and game.biome_backgrounds.diagnostic["ambient"] == 9, "Actual gameplay renders three tiled scenery planes and distant bird flocks")
	game.time_of_day = 0.75
	await redraw(game)
	check(game.biome_backgrounds.diagnostic["ambient"] == 12, "Forests replace daytime birds with night fireflies")
	game.time_of_day = 0.25
	game.weather_blend.reset("Storm", 0)
	await redraw(game)
	check(game.biome_backgrounds.diagnostic["ambient"] == 0, "Birds and fireflies shelter during rain and storms")
	game.weather_blend.reset("Clear", 0)
	var boundary: int = game.biome_backgrounds.boundaries[0]
	game.player_pos = Vector2(boundary * 16, game.world["surface"][boundary] * 16 - 28)
	game._update_camera()
	await redraw(game)
	check(game.biome_backgrounds.diagnostic["planes"] == 12 and game.biome_backgrounds.textures.size() == 4, "Boundary drawing stays bounded to two cached biome scenes")
	game.player_pos.y += 12 * 16
	game._update_camera()
	await redraw(game)
	check(game.biome_backgrounds.surface_visibility(game) == 0 and game.biome_backgrounds.diagnostic["planes"] == 0 and game.biome_backgrounds.diagnostic["ambient"] == 0, "Surface scenery and ambient wildlife disappear underground")
	check(game.world["tiles"] == grid, "Rendering scenery cannot change terrain or fluids")
	game.save_path = "user://galaxis_biome_backgrounds_check.json"
	game._save_game()
	var saved_scene: String = game.biome_backgrounds.scene_for(2)["id"]
	var saved_offset: Vector2 = game.biome_backgrounds.plane_origin(Vector2(100, 200), 1)
	game._load_game()
	while game.scene_name != "planet":
		await process_frame
	check(game.biome_backgrounds.scene_for(2)["id"] == saved_scene and game.biome_backgrounds.plane_origin(Vector2(100, 200), 1) == saved_offset, "Loading restores the same biome scenery and panorama alignment")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(game.save_path))
	game.queue_free()
	await process_frame
	print("BACKGROUND_GAMEPLAY daylight/night/storm, cave exclusion, terrain preservation, save/load checked")

func run() -> void:
	catalog_checks()
	await gameplay_checks()
	print("BIOME_BACKGROUNDS failures=", failures)
	quit(0 if failures == 0 else 1)
