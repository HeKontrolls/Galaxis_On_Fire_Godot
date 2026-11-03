extends SceneTree

const WG = preload("res://scripts/world_gen.gd")
const Foliage = preload("res://scripts/foliage.gd")
var failures := 0


func _initialize() -> void:
	call_deferred("run_check")


func check(condition: bool, label: String) -> void:
	if not condition:
		failures += 1
		printerr(label)


func run_check() -> void:
	var game: Node2D = load("res://main.tscn").instantiate()
	root.add_child(game)
	game.save_path = "user://galaxis_grass_foliage_check.json"
	await process_frame
	await game._open_planet(0)
	game.set_process(false)
	var column := 600
	var y := int(game.world["surface"][column])
	game._edit_tile(Vector2i(column, y), 1)
	game._edit_tile(Vector2i(column, y + 1), 2)
	game.player_pos = Vector2(column * 16, y * 16 - 29)
	game._update_camera()
	for _hit in range(game.Tools.mining_hits(game.equipped_tool, 1)):
		game.mining_cooldown = 0
		game._mine(Vector2(column * 16 + 8, y * 16 + 8) - game.camera_pos)
	check(WG.tile_at(game.world["tiles"], column, y) == 0, "Mining must expose the dirt below")
	game._update_grass(1.0)
	check(WG.tile_at(game.world["tiles"], column, y + 1) == 2, "Grass must grow over time")
	game._update_grass(5.0)
	check(WG.tile_at(game.world["tiles"], column, y + 1) == 1, "Sunlit dirt must regrow grass")
	var grown := Vector2i(column, y + 1)
	var covered := Vector2i(column + 2, int(game.world["surface"][column + 2]))
	game._edit_tile(covered, 2)
	game._edit_tile(covered + Vector2i.UP, 3)
	game._update_grass(6.0)
	check(WG.tile_at(game.world["tiles"], covered.x, covered.y) == 2, "Covered dirt must not grow grass")
	game._edit_tile(covered, 12)
	game._edit_tile(covered + Vector2i.UP, 0)
	game._update_grass(6.0)
	check(WG.tile_at(game.world["tiles"], covered.x, covered.y) == 12, "Grass must not overwrite tilled soil")
	game._edit_tile(covered, 2)
	game._edit_tile(covered + Vector2i.UP, 4)
	game._update_grass(6.0)
	check(WG.tile_at(game.world["tiles"], covered.x, covered.y) == 2, "Submerged dirt must stay dirt")
	game._edit_tile(covered + Vector2i.UP, 0)
	game._edit_tile(covered, 0)
	game._update_grass(6.0)
	check(WG.tile_at(game.world["tiles"], covered.x, covered.y) == 0, "Growth must not refill a dug tile")
	game.planet_index = 4
	game._edit_tile(covered, 2)
	game._update_grass(6.0)
	check(WG.tile_at(game.world["tiles"], covered.x, covered.y) == 2, "Barren worlds must not become grassy")
	game.planet_index = 0
	var grid: PackedByteArray = game.world["tiles"]
	var leaf := Vector2i(-1, -1)
	for x in range(10, 1000):
		for yy in range(maxi(1, int(game.world["surface"][x]) - 18), int(game.world["surface"][x])):
			if WG.tile_at(grid, x, yy) == 8:
				leaf = Vector2i(x, yy)
				break
		if leaf.x >= 0:
			break
	check(leaf.x >= 0, "Need a generated canopy for the foliage checks")
	if leaf.x >= 0:
		var crown: Dictionary = game.foliage.component(grid, leaf, int(game.world["seed"]))
		var image: Image = crown["image"]
		var border_clear := true
		var shades := {}
		for yy in range(image.get_height()):
			for xx in range(image.get_width()):
				var color := image.get_pixel(xx, yy)
				if xx == 0 or yy == 0 or xx == image.get_width() - 1 or yy == image.get_height() - 1:
					border_clear = border_clear and color.a == 0.0
				elif color.a > 0.99:
					shades[color.to_rgba32()] = true
		check(border_clear, "Canopy texture borders must be fully transparent")
		check(shades.size() >= 4, "Canopy must have continuous, varied leaf shading")
		var duplicate := Foliage.new()
		var repeated: Dictionary = duplicate.component(grid, leaf, int(game.world["seed"]))
		check(image.get_data() == repeated["image"].get_data(), "Leaf appearance must be deterministic")
		game._fell_tree(leaf)
		var leaf_drops := 0
		for drop in game.world["drops"]:
			if int(drop.get("block_id", 0)) == 8:
				leaf_drops += 1
				check(Marshalls.base64_to_raw(str(drop.get("leaf_pixels", ""))).size() == 1024,
					"Falling leaf blocks must retain their actual canopy pixels")
		check(leaf_drops > 0, "Cut trees must still produce individual falling leaf blocks")
	game._save_game()
	game._load_game()
	await process_frame
	await process_frame
	check(WG.tile_at(game.world["tiles"], grown.x, grown.y) == 1, "Grown grass must survive save/load")
	var persisted_leaf_pixels := false
	for drop in game.world["drops"]:
		if int(drop.get("block_id", 0)) == 8:
			persisted_leaf_pixels = not str(drop.get("leaf_pixels", "")).is_empty()
			break
	check(persisted_leaf_pixels, "Leaf appearance must survive saving falling blocks")
	if FileAccess.file_exists(game.save_path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(game.save_path))
	print("GRASS_FOLIAGE failures=", failures)
	quit(0 if failures == 0 else 1)
