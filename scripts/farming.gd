extends RefCounted

const WG = preload("res://scripts/world_gen.gd")
const FARM_IDS := [12, 13, 14, 15, 16]
var world := {}
var columns := {}
var budget := 0.0
var rng := RandomNumberGenerator.new()


func bind_world(data: Dictionary) -> void:
	world = data
	columns.clear()
	world["crops"] = {}
	var grid: PackedByteArray = world["tiles"]
	for index in range(grid.size()):
		if grid[index] in FARM_IDS:
			var x := index % WG.WIDTH
			var cells: Array = columns.get(x, [])
			cells.append(int(index / WG.WIDTH))
			columns[x] = cells
			if grid[index] in [14, 15, 16]:
				world["crops"]["%d,%d" % [x, int(index / WG.WIDTH)]] = grid[index]
	rng.seed = int(world["seed"]) ^ 0xFA11DE
	if str(world.get("farm_rng_state", "")).is_valid_int():
		rng.state = int(world["farm_rng_state"])
	budget = float(world.get("farm_budget", 0.0))


func track(tile: Vector2i, id: int) -> void:
	var cells: Array = columns.get(tile.x, [])
	if id in FARM_IDS:
		if not cells.has(tile.y):
			cells.append(tile.y)
			cells.sort()
		columns[tile.x] = cells
	else:
		cells.erase(tile.y)
		if cells.is_empty():
			columns.erase(tile.x)
		else:
			columns[tile.x] = cells
	var key := "%d,%d" % [tile.x, tile.y]
	if id in [14, 15, 16]:
		world["crops"][key] = id
	else:
		world["crops"].erase(key)


func interaction(tile: Vector2i, tool: String, selected: String) -> Dictionary:
	var result := {"handled": false, "edits": [], "consume": "", "drops": {}}
	if tile.x < 0 or tile.x >= WG.WIDTH or tile.y < 1 or tile.y >= WG.HEIGHT - 1:
		return result
	var grid: PackedByteArray = world["tiles"]
	var id := WG.tile_at(grid, tile.x, tile.y)
	if id == 16:
		result["handled"] = true
		result["edits"] = [Vector3i(tile.x, tile.y, 0)]
		result["drops"] = {"Corn": rng.randi_range(2, 4), "Crop Seeds": rng.randi_range(1, 3)}
	elif tool == "Hoe" and id in [1, 2]:
		result["handled"] = true
		if WG.tile_at(grid, tile.x, tile.y - 1) == 0:
			result["edits"] = [Vector3i(tile.x, tile.y, 12)]
	elif tool == "Watering Can" and id == 12:
		result["handled"] = true
		result["edits"] = [Vector3i(tile.x, tile.y, 13)]
	elif selected in ["Crop Seeds", "Corn Seed"]:
		result["handled"] = true
		var plant_y := tile.y - 1 if id in [12, 13] else tile.y
		if plant_y > 0 and WG.tile_at(grid, tile.x, plant_y) == 0 and WG.tile_at(grid, tile.x, plant_y + 1) in [12, 13]:
			result["consume"] = selected
			result["edits"] = [Vector3i(tile.x, plant_y, 14)]
	world["farm_rng_state"] = str(rng.state)
	return result


func advance(center_x: int, delta: float, raining: bool, roof: PackedInt32Array, water: PackedByteArray, rain_intensity: float = 1.0) -> Array[Vector3i]:
	var edits: Array[Vector3i] = []
	if columns.is_empty():
		return edits
	budget += maxf(0.0, delta) * 18.0
	var attempts := mini(40, int(budget))
	budget -= attempts
	var grid: PackedByteArray = world["tiles"]
	var updates := {}
	for _attempt in range(attempts):
		var x := rng.randi_range(maxi(0, center_x - 48), mini(WG.WIDTH - 1, center_x + 48))
		var cells: Array = columns.get(x, [])
		if cells.is_empty():
			continue
		var y: int = cells[rng.randi_range(0, cells.size() - 1)]
		var index := y * WG.WIDTH + x
		var id := int(updates.get(index, grid[index]))
		var above := WG.tile_at(grid, x, y - 1)
		var exposed: bool = roof[x] == y
		var wet := water.size() == grid.size() and water[(y - 1) * WG.WIDTH + x] > 0
		var rain_received := raining and (rain_intensity >= 1.0 or rng.randf() < rain_intensity)
		if id in [12, 13]:
			if id == 12 and exposed and (wet or (rain_received and above in [0, 7, 8, 14, 15, 16])):
				updates[index] = 13
			continue
		if id not in [14, 15]:
			continue
		var soil_index := index + WG.WIDTH
		var soil := int(updates.get(soil_index, grid[soil_index]))
		if soil not in [12, 13]:
			continue
		var chance := 0.18 if soil == 13 else 0.045
		if raining and roof[x] == y + 1:
			chance += 0.05 * clampf(rain_intensity, 0.0, 1.0)
		if rng.randf() >= chance:
			continue
		updates[index] = id + 1
		if soil == 13 and rng.randf() < 0.45:
			updates[soil_index] = 12
	for index in updates:
		edits.append(Vector3i(index % WG.WIDTH, int(index / WG.WIDTH), updates[index]))
	world["farm_budget"] = budget
	world["farm_rng_state"] = str(rng.state)
	return edits
