extends RefCounted

# Each planet climate has its own four surface regions. Existing tile art is
# reused; material, relief, tree density and liquid/ice cover vary by region.
const PROFILES := [
	[
		{"name": "Meadow", "top": 1, "soil": 2, "height": 3, "trees": 0.0},
		{"name": "Woodland", "top": 1, "soil": 2, "height": -2, "trees": 0.55},
		{"name": "Dense forest", "top": 1, "soil": 2, "height": -5, "trees": 0.94},
		{"name": "Rocky uplands", "top": 3, "soil": 3, "height": -16, "trees": 0.0}],
	[
		{"name": "Sandy shore", "top": 5, "soil": 5, "height": 0, "trees": 0.0},
		{"name": "Coastal grove", "top": 1, "soil": 2, "height": -2, "trees": 0.55},
		{"name": "Island jungle", "top": 1, "soil": 2, "height": -5, "trees": 0.85},
		{"name": "Tidal banks", "top": 5, "soil": 5, "height": 2, "trees": 0.0}],
	[
		{"name": "Coastal grassland", "top": 1, "soil": 2, "height": 0, "trees": 0.0},
		{"name": "Continental forest", "top": 1, "soil": 2, "height": -5, "trees": 0.85},
		{"name": "Rocky coast", "top": 3, "soil": 3, "height": -11, "trees": 0.0},
		{"name": "Sandbars", "top": 5, "soil": 5, "height": 3, "trees": 0.0}],
	[
		{"name": "Dune sea", "top": 5, "soil": 5, "height": 0, "trees": 0.0},
		{"name": "Rocky badlands", "top": 3, "soil": 3, "height": -12, "trees": 0.0},
		{"name": "Oasis", "top": 1, "soil": 2, "height": 5, "trees": 0.45},
		{"name": "Stony desert", "top": 3, "soil": 5, "height": -3, "trees": 0.0}],
	[
		{"name": "Basalt plains", "top": 3, "soil": 3, "height": 0, "trees": 0.0},
		{"name": "Lava fields", "top": 3, "soil": 3, "height": 3, "trees": 0.0},
		{"name": "Obsidian flats", "top": 17, "soil": 3, "height": 0, "trees": 0.0},
		{"name": "Volcanic ridges", "top": 3, "soil": 3, "height": -20, "trees": 0.0}],
	[
		{"name": "Crater basins", "top": 3, "soil": 3, "height": 8, "trees": 0.0},
		{"name": "Rocky highlands", "top": 3, "soil": 3, "height": -18, "trees": 0.0},
		{"name": "Dust plains", "top": 5, "soil": 5, "height": 0, "trees": 0.0},
		{"name": "Shattered ridges", "top": 3, "soil": 3, "height": -7, "trees": 0.0}],
	[
		{"name": "Pack ice", "top": 6, "soil": 6, "height": 0, "trees": 0.0, "ice": 4},
		{"name": "Fractured ice", "top": 6, "soil": 6, "height": 0, "trees": 0.0, "ice": 2},
		{"name": "Glacial shelf", "top": 6, "soil": 6, "height": -10, "trees": 0.0, "ice": 9},
		{"name": "Open leads", "top": 6, "soil": 6, "height": 0, "trees": 0.0, "ice": 0}],
	[
		{"name": "Snowfields", "top": 6, "soil": 6, "height": 0, "trees": 0.0},
		{"name": "Boreal woodland", "top": 6, "soil": 2, "height": -4, "trees": 0.75},
		{"name": "Exposed rock", "top": 3, "soil": 3, "height": -15, "trees": 0.0},
		{"name": "Glacial valleys", "top": 6, "soil": 6, "height": 12, "trees": 0.0}]
]


static func generate(seed_value: int, climate: int, width: int = 1200) -> PackedByteArray:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value ^ (climate * 7919) ^ 0xB10AE
	var order := [0, 1, 2, 3]
	for index in range(3, 0, -1):
		var other := rng.randi_range(0, index)
		var swap: int = order[index]
		order[index] = order[other]
		order[other] = swap
	var result := PackedByteArray()
	result.resize(width)
	var column := 0
	var region := 0
	while column < width:
		var end := mini(width, column + rng.randi_range(138, 210))
		for x in range(column, end):
			result[x] = order[region % order.size()]
		column = end
		region += 1
	return result


static func edge_weights(columns: PackedByteArray) -> PackedFloat32Array:
	var result := PackedFloat32Array()
	result.resize(columns.size())
	var start := 0
	for x in range(1, columns.size() + 1):
		if x == columns.size() or columns[x] != columns[start]:
			for at in range(start, x):
				result[at] = smoothstep(0, 12, mini(at - start, x - 1 - at))
			start = x
	return result


static func profile(climate: int, index: int) -> Dictionary:
	return PROFILES[clampi(climate, 0, 7)][clampi(index, 0, 3)]


static func name_at(world: Dictionary, column: int) -> String:
	var columns: PackedByteArray = world.get("biomes", PackedByteArray())
	if columns.is_empty():
		return ""
	return profile(int(world["climate"]), columns[clampi(column, 0, columns.size() - 1)])["name"]
