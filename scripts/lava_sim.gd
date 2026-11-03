extends "res://scripts/water_sim.gd"

var rain_hits: Array[Vector2i] = []
var reheat_budget := 0.0


func _init() -> void:
	fluid_id = 11
	storage_key = "lava"
	blocked_id = 4
	step_seconds = 0.28
	vertical_limit = 96
	vertical_fraction = 0.5
	lateral_limit = 16
	tick_budget = 900
	tick_time_us = 1200


func bind_world(data: Dictionary) -> void:
	super.bind_world(data)
	# The shared transport tags track cooled lava volume here. They advect
	# with the molten material, independently of water's rainfall provenance.
	rain_amounts = world.get("lava_cooling", PackedByteArray())
	if rain_amounts.size() != amounts.size():
		rain_amounts.resize(amounts.size())
		rain_amounts.fill(0)
	rain_cells.clear()
	for index in range(amounts.size()):
		rain_amounts[index] = mini(rain_amounts[index], amounts[index])
		if rain_amounts[index] > 0:
			rain_cells[index] = true
	world["lava_cooling"] = rain_amounts
	rain_hits.clear()
	reheat_budget = 0.0


func cooling_fraction(index: int) -> float:
	return float(rain_amounts[index]) / maxf(1, amounts[index])


func cool_from_rain(tile: Vector2i, units: int) -> int:
	if not _inside(tile.x, tile.y):
		return 0
	var index := tile.y * WG.WIDTH + tile.x
	var added := mini(maxi(units, 0) * 8, int(amounts[index]) - int(rain_amounts[index]))
	if added <= 0:
		return 0
	rain_amounts[index] += added
	visual_revision += 1
	rain_cells[index] = true
	world["lava_cooling"] = rain_amounts
	if rain_hits.size() < 32:
		rain_hits.append(tile)
	return added


func reheat(delta: float, raining: bool) -> void:
	if raining:
		reheat_budget = 0.0
		return
	reheat_budget = minf(2.0, reheat_budget + delta)
	while reheat_budget >= 1.0:
		reheat_budget -= 1.0
		if not rain_cells.is_empty():
			visual_revision += 1
		for index in rain_cells.keys():
			if rain_amounts[index] >= amounts[index]:
				continue
			rain_amounts[index] = maxi(0, int(rain_amounts[index]) - 2)
			if rain_amounts[index] == 0:
				rain_cells.erase(index)
	world["lava_cooling"] = rain_amounts


func step() -> void:
	super.step()
	world["lava_cooling"] = rain_amounts


func terrain_changed(tile: Vector2i, new_id: int) -> void:
	super.terrain_changed(tile, new_id)
	world["lava_cooling"] = rain_amounts


func displace(tile: Vector2i) -> bool:
	var result := super.displace(tile)
	world["lava_cooling"] = rain_amounts
	return result


func intersects(rect: Rect2) -> bool:
	for y in range(maxi(0, int(floor(rect.position.y / WG.TILE))), mini(WG.HEIGHT, int(ceil(rect.end.y / WG.TILE)))):
		for x in range(maxi(0, int(floor(rect.position.x / WG.TILE))), mini(WG.WIDTH, int(ceil(rect.end.x / WG.TILE)))):
			var index := y * WG.WIDTH + x
			if not falling.has(index) or amounts[index] == 0 or amounts[index] >= 250:
				continue
			var width := 3.5 + sqrt(float(amounts[index]) / 255.0) * 11.5
			var at := Vector2(x * WG.TILE + 8 - width * 0.5, y * WG.TILE)
			if Rect2(at, Vector2(width, WG.TILE)).intersects(rect):
				return true
	return super.intersects(rect)
