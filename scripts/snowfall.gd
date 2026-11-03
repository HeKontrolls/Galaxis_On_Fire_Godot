extends RefCounted

const WG = preload("res://scripts/world_gen.gd")
const MAX_LAYER := 96
var world := {}
var amounts := PackedByteArray()
var cells := {}
var rng := RandomNumberGenerator.new()
var deposit_budget := 0.0
var maintenance_budget := 0.0
var runoff_timer := 0.0


func bind_world(data: Dictionary) -> void:
	world = data
	amounts = world.get("snow", PackedByteArray())
	if amounts.size() != WG.WIDTH * WG.HEIGHT:
		amounts.resize(WG.WIDTH * WG.HEIGHT)
		amounts.fill(0)
	cells.clear()
	for index in range(amounts.size()):
		if amounts[index] > 0:
			cells[index] = true
	world["snow"] = amounts
	rng.seed = int(world.get("seed", 0)) ^ 0x5A0F411
	deposit_budget = 0.0
	maintenance_budget = 0.0
	runoff_timer = clampf(float(world.get("snow_runoff_time", 0.0)), 0.0, 15.0)


func _set_amount(index: int, units: int) -> void:
	amounts[index] = clampi(units, 0, 255)
	if amounts[index] > 0:
		cells[index] = true
	else:
		cells.erase(index)


func _landing(x: int, roof: PackedInt32Array, water, lava) -> Dictionary:
	var floor_y := roof[x]
	for y in range(floor_y):
		var at := Vector2i(x, y)
		if lava.amount_at(at) > 0:
			return {"row": -1, "water": false}
		if water.amount_at(at) > 0:
			return {"row": y - 1 if water.amount_at(at) == 255 else y, "water": true}
	return {"row": floor_y - 1, "water": false}


func deposit(x: int, units: int, roof: PackedInt32Array, water, lava) -> void:
	if x < 0 or x >= WG.WIDTH:
		return
	var landing := _landing(x, roof, water, lava)
	var y := int(landing["row"])
	if y < 0 or y >= WG.HEIGHT - 1:
		return
	if landing["water"]:
		if water.add_rain(Vector2i(x, y), units) > 0:
			runoff_timer = 15.0
		return
	var index := y * WG.WIDTH + x
	_set_amount(index, mini(MAX_LAYER, int(amounts[index]) + units))
	world["snow"] = amounts


func _near_lava(tile: Vector2i, lava) -> bool:
	for offset in [Vector2i.ZERO, Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT,
		Vector2i(-1, -1), Vector2i(1, -1), Vector2i(-1, 1), Vector2i(1, 1),
		Vector2i(0, 2), Vector2i(0, -2), Vector2i(-2, 0), Vector2i(2, 0)]:
		if lava.amount_at(tile + offset) > 0:
			return true
	return false


func update(game, delta: float) -> void:
	runoff_timer = maxf(0.0, runoff_timer - maxf(0.0, delta))
	var roof: PackedInt32Array = game.environment.roof
	var center := int((game.player_pos.x + 8) / WG.TILE)
	if game.weather_blend.snow() > 0.001 and int(world.get("climate", -1)) != 4:
		deposit_budget = minf(deposit_budget + maxf(0, delta) * game.weather_blend.snow(), 1.0)
		while deposit_budget >= 0.5:
			deposit_budget -= 0.5
			for _flake in range(8):
				deposit(rng.randi_range(maxi(1, center - 45), mini(WG.WIDTH - 2, center + 45)), 4, roof, game.water_sim, game.lava_sim)
	else:
		deposit_budget = 0.0
	maintenance_budget = minf(maintenance_budget + maxf(0, delta), 2.0)
	while maintenance_budget >= 1.0:
		maintenance_budget -= 1.0
		_tick(game, roof)
	world["snow"] = amounts
	world["snow_runoff_time"] = runoff_timer


func _tick(game, roof: PackedInt32Array) -> void:
	var grid: PackedByteArray = world["tiles"]
	var sun := clampf(sin(game.time_of_day * TAU), 0, 1)
	for index in cells.keys():
		var tile := Vector2i(index % WG.WIDTH, int(index / WG.WIDTH))
		var below := WG.tile_at(grid, tile.x, tile.y + 1)
		if WG.is_solid(grid[index]) or (not WG.is_solid(below) and game.water_sim.amount_at(tile + Vector2i.DOWN) == 0 and game.lava_sim.amount_at(tile + Vector2i.DOWN) == 0):
			# A dug floor or a newly constructed roof changes where the snow rests.
			var landing := _landing(tile.x, roof, game.water_sim, game.lava_sim)
			var y := int(landing["row"])
			var units := int(amounts[index])
			_set_amount(index, 0)
			if y >= 0 and y < WG.HEIGHT - 1:
				if landing["water"]:
					game.water_sim.add_rain(Vector2i(tile.x, y), units)
				else:
					var next := y * WG.WIDTH + tile.x
					_set_amount(next, int(amounts[next]) + units)
			continue
		var hot := _near_lava(tile, game.lava_sim)
		if game.weather == "Snow" and not hot:
			continue
		var rate := 8 if hot else (6 if game.weather in ["Rain", "Storm"] else (4 if sun > 0.2 else 2))
		var melted := mini(int(amounts[index]), rate)
		var target := tile
		if game.water_sim.amount_at(target) == 255:
			target += Vector2i.UP
		var added: int = game.water_sim.add_rain(target, melted)
		if added > 0:
			runoff_timer = 15.0
		if hot and game.lava_sim.amount_at(tile) > 0:
			added = melted # Snow touching the molten surface turns to steam.
		_set_amount(index, int(amounts[index]) - added)


func draw_snow(game) -> void:
	for index in cells:
		var tile := Vector2i(index % WG.WIDTH, int(index / WG.WIDTH))
		var at: Vector2 = Vector2(tile * WG.TILE) - game.camera_pos
		if at.x < -16 or at.x > 1296 or at.y < -32 or at.y > 736:
			continue
		var height := maxf(0.35, float(amounts[index]) * WG.TILE / 255.0)
		var left_height := height
		var right_height := height
		if tile.x > 0 and amounts[index - 1] > 0:
			left_height = (height + float(amounts[index - 1]) * WG.TILE / 255.0) * 0.5
		if tile.x < WG.WIDTH - 1 and amounts[index + 1] > 0:
			right_height = (height + float(amounts[index + 1]) * WG.TILE / 255.0) * 0.5
		var bottom: float = at.y + WG.TILE
		game.draw_colored_polygon(PackedVector2Array([Vector2(at.x, bottom - left_height), Vector2(at.x + WG.TILE, bottom - right_height),
			Vector2(at.x + WG.TILE, bottom), Vector2(at.x, bottom)]), Color("eaf3ff"))
		game.draw_line(Vector2(at.x, bottom - left_height), Vector2(at.x + WG.TILE, bottom - right_height), Color("ffffff"), 1.0)
