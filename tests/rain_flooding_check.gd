extends SceneTree

const WG = preload("res://scripts/world_gen.gd")
const Water = preload("res://scripts/water_sim.gd")
const Rain = preload("res://scripts/precipitation.gd")
const CaveEnvironment = preload("res://scripts/world_environment.gd")
var failures := 0


func _initialize() -> void:
	call_deferred("run_check")


func check(ok: bool, label: String) -> void:
	if not ok:
		failures += 1
		printerr(label)


func total(values: PackedByteArray) -> int:
	var sum := 0
	for value in values:
		sum += value
	return sum


func basin() -> Dictionary:
	var grid := PackedByteArray()
	grid.resize(WG.WIDTH * WG.HEIGHT)
	var surface := PackedInt32Array()
	surface.resize(WG.WIDTH)
	surface.fill(80)
	for x in range(WG.WIDTH):
		for y in range(80, WG.HEIGHT):
			WG.set_tile(grid, x, y, 2)
	# A ten-block-deep pit catches runoff from both sides of a broad plateau.
	for x in range(594, 607):
		for y in range(80, 90):
			WG.set_tile(grid, x, y, 0)
	return {"tiles": grid, "surface": surface, "seed": 713}


func maximum_rain_column(water) -> int:
	var columns := {}
	var maximum := 0
	for index in water.rain_cells:
		var x: int = index % WG.WIDTH
		columns[x] = int(columns.get(x, 0)) + water.rain_amounts[index]
		maximum = maxi(maximum, columns[x])
	return maximum


func prolonged_storm() -> void:
	var data := basin()
	var water := Water.new()
	water.bind_world(data)
	var env := CaveEnvironment.new()
	env.reset(data)
	var rain := Rain.new()
	rain.reset(713)
	var peak := 0
	for _tick in range(6000):
		rain.update(600, 0.1, true, true, 1.0, env.roof, water)
		water.update(0.1)
		peak = maxi(peak, maximum_rain_column(water))
	check(total(water.rain_amounts) > 0, "A long storm must still leave visible finite puddles")
	check(peak < 128, "Ten minutes of continuous storm runoff must stay shallower than half a tile: %d units" % peak)
	check(water.amount_at(Vector2i(600, 89)) > 0, "The basin must still collect a shallow puddle")
	for _second in range(180):
		rain.update(600, 1.0, false, false, 1.0, env.roof, water)
		water.update(0.08)
	check(total(water.amounts) == 0, "All storm puddles must disappear after dry weather")
	print("PROLONGED_STORM seconds=600 peak_column_units=", peak, " peak_depth_pixels=", float(peak) * 16 / 255)


func existing_flood() -> void:
	var data := basin()
	var water := Water.new()
	water.bind_world(data)
	for x in range(594, 607):
		for y in range(81, 90):
			water.add_rain(Vector2i(x, y), 255)
	# Mix natural water into the old flood, as can happen after rainfall drains
	# into a stream. The new drainage must preserve this exact natural volume.
	var index := 89 * WG.WIDTH + 600
	water.rain_amounts[index] = 128
	data["rain_water"] = water.rain_amounts
	water.update(0.0)
	var flooded := total(water.amounts)
	# Rebind persisted volumes to reproduce loading an existing flooded world.
	water.bind_world(data)
	var env := CaveEnvironment.new()
	env.reset(data)
	var rain := Rain.new()
	rain.reset(713)
	for _tick in range(600):
		rain.update(600, 0.1, true, false, 1.0, env.roof, water)
		water.update(0.1)
	check(maximum_rain_column(water) < 128, "Old saved rain floods must drain down during rain without needing a world reset")
	check(total(water.amounts) - total(water.rain_amounts) == 127, "Draining mixed rain floods must conserve every unit of natural water")
	for _second in range(180):
		rain.update(600, 1.0, false, false, 1.0, env.roof, water)
		water.update(0.08)
	check(total(water.amounts) == 127 and total(water.rain_amounts) == 0, "After drying, the original natural water must remain")
	print("OLD_FLOOD before_units=", flooded, " after_units=", total(water.amounts))


func underground_seepage() -> void:
	var data := basin()
	var grid: PackedByteArray = data["tiles"]
	for x in range(630, 636):
		for y in range(95, 100):
			WG.set_tile(grid, x, y, 0)
	data["tiles"] = grid
	var water := Water.new()
	water.bind_world(data)
	water.add_rain(Vector2i(632, 99), 40)
	var env := CaveEnvironment.new()
	env.reset(data)
	var rain := Rain.new()
	rain.reset(713)
	for _second in range(30):
		rain.update(600, 1.0, true, false, 1.0, env.roof, water)
		water.update(0.08)
	var trapped := 0
	for x in range(630, 636):
		for y in range(95, 100):
			trapped += water.amount_at(Vector2i(x, y))
	check(trapped == 0, "Rain that leaked underground must seep away instead of remaining trapped forever")


func run_check() -> void:
	prolonged_storm()
	existing_flood()
	underground_seepage()
	print("RAIN_FLOODING failures=", failures)
	quit(0 if failures == 0 else 1)
