extends SceneTree

const WG = preload("res://scripts/world_gen.gd")


func _initialize() -> void:
	var report := {}
	for seed_value in [125891, 531209, 713]:
		var data: Dictionary = WG.generate(seed_value, 0)
		var grid: PackedByteArray = data["tiles"]
		var trees := 0
		for x in range(WG.WIDTH):
			for y in range(maxi(0, data["surface"][x] - 20), mini(WG.HEIGHT - 1, data["surface"][x] + 1)):
				if WG.tile_at(grid, x, y) == 7 and WG.tile_at(grid, x, y + 1) != 7:
					trees += 1
		report[str(seed_value)] = trees
	print("FOREST_DENSITY ", JSON.stringify(report))
	var args := OS.get_cmdline_user_args()
	var path := args[0] if not args.is_empty() else "res://tests/forest_density.json"
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "\t"))
	quit(0)
