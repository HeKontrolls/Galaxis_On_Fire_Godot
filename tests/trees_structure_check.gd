extends SceneTree

const WG = preload("res://scripts/world_gen.gd")
var failures := 0


func _initialize() -> void:
	call_deferred("run_check")


func check(ok: bool, label: String) -> void:
	if not ok:
		failures += 1
		printerr(label)


func run_check() -> void:
	var game: Node2D = load("res://main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	await game._open_planet(0)
	game.set_process(false)
	game.save_path = "user://galaxis_trees_structure_check.json"
	game.world["seed"] = 531209
	game.world["drops"] = []
	var grid := PackedByteArray()
	grid.resize(WG.WIDTH * WG.HEIGHT)
	var surface := PackedInt32Array()
	surface.resize(WG.WIDTH)
	surface.fill(130)
	for x in range(WG.WIDTH):
		WG.set_tile(grid, x, 130, 1)
	var rng := RandomNumberGenerator.new()
	rng.seed = 31529
	check(WG._plant_tree(grid, 588, 130, rng), "A tree must grow on a clear grass surface")
	check(WG._plant_tree(grid, 600, 130, rng), "A neighboring tree must grow independently")
	var repeat_grid := PackedByteArray()
	repeat_grid.resize(grid.size())
	for x in range(WG.WIDTH):
		WG.set_tile(repeat_grid, x, 130, 1)
	rng.seed = 31529
	WG._plant_tree(repeat_grid, 588, 130, rng)
	WG._plant_tree(repeat_grid, 600, 130, rng)
	check(grid == repeat_grid, "Tree layouts must repeat for the same generation seed")
	game.world["tiles"] = grid
	game.world["surface"] = surface
	game.world.erase("water")
	game.world.erase("rain_water")
	game._reset_world_environment()
	game.world_texture = WG.make_texture(grid)
	game.world_image = game.world_texture.get_image()
	game.foliage.reset()
	var top := 129
	while WG.tile_at(grid, 588, top - 1) == 7:
		top -= 1
	var branch_cells := 0
	var original := {}
	for y in range(top - 5, 130):
		for x in range(584, 593):
			var id := WG.tile_at(grid, x, y)
			if id in [7, 8]:
				original[Vector2i(x, y)] = id
			if id == 8 and y > top + 2:
				branch_cells += 1
	check(branch_cells > 0, "New trees must have separate leafy side branches below the crown")
	check(not game._collides(Vector2(588 * 16, 130 * 16 - 29)), "The player must be able to walk through a natural trunk")
	var branch_patch := PackedByteArray()
	for cell: Vector2i in original:
		if original[cell] == 7:
			var image: Image = game.foliage.trunk_patch(grid, cell, int(game.world["seed"]))
			check(image.get_pixel(0, 1).a == 0.0 and image.get_pixel(8, 8).a == 1.0, "Bark art must preserve transparent surroundings and an opaque trunk")
		else:
			var image: Image = game.foliage.patch(grid, cell, int(game.world["seed"]))
			var visible := false
			for y in range(16):
				for x in range(16):
					var alpha := image.get_pixel(x, y).a
					visible = visible or alpha > 0.99
					check(alpha == 0.0 or alpha == 1.0, "Leaf art must have crisp pixels without colored semi-transparent halos")
			check(visible, "Every collectible leaf tile must retain visible pixels")
			if cell.y > top + 2:
				branch_patch = image.get_data()
	game._fell_tree(Vector2i(588, 129))
	var removed := 0
	for cell: Vector2i in original:
		if WG.tile_at(game.world["tiles"], cell.x, cell.y) == 0:
			removed += 1
	check(removed == original.size(), "Chopping must remove the entire crown, trunk, and all lower branches without floating leftovers")
	check(game.world["drops"].size() == original.size(), "Every tree tile must fall as one separate physical pickup")
	check(WG.tile_at(game.world["tiles"], 600, 129) == 7, "Cutting one tree must preserve a nearby tree")
	var saw_branch := false
	for drop in game.world["drops"]:
		var tile := Vector2i(roundi((drop["x"] - 8) / 16), roundi((drop["y"] - 8) / 16))
		check(original.has(tile), "Falling blocks must start in their original tree positions")
		var encoded := str(drop["wood_pixels"] if int(drop["block_id"]) == 7 else drop["leaf_pixels"])
		check(Marshalls.base64_to_raw(encoded).size() == 1024, "Both wood and leaf drops must retain their rendered pixels")
		if int(drop["block_id"]) == 8 and Marshalls.base64_to_raw(encoded) == branch_patch:
			saw_branch = true
	check(saw_branch, "Side branches must preserve their actual leaf-and-wood artwork when falling")
	var saved_pixels := []
	for drop in game.world["drops"]:
		saved_pixels.append(str(drop.get("wood_pixels", "")) + str(drop.get("leaf_pixels", "")))
	game._save_game()
	game._load_game()
	await process_frame
	var loaded_pixels := []
	for drop in game.world["drops"]:
		loaded_pixels.append(str(drop.get("wood_pixels", "")) + str(drop.get("leaf_pixels", "")))
	check(saved_pixels == loaded_pixels, "Saved falling wood and leaf art must survive loading unchanged")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(game.save_path))
	print("TREES_STRUCTURE branches=", branch_cells, " fallen_blocks=", original.size(), " failures=", failures)
	quit(0 if failures == 0 else 1)
