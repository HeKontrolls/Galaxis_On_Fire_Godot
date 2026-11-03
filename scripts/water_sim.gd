extends RefCounted

const WG = preload("res://scripts/world_gen.gd")
const CAPACITY := 255
const STEP := 0.08
const BUDGET := 1800
var fluid_id := 4
var storage_key := "water"
var blocked_id := 11
var step_seconds := STEP
var vertical_limit := CAPACITY
var vertical_fraction := 1.0
var lateral_limit := 96
var tick_budget := BUDGET
var tick_time_us := 2200
var amounts := PackedByteArray()
var active := {}
var changed := {}
var falling := {}
var accumulator := 0.0
var tick := 0
var world := {}
var region := Rect2i()
var resume_index := -1
var rain_amounts := PackedByteArray()
var rain_cells := {}
var has_fluid := false
var previous_amounts := PackedByteArray()
var previous_falling := {}
var visual_revision := 0
var pressure_sources := {}
var pressure_cursor := 0
var pressure_retry := {}


func set_active_region(center: Vector2) -> void:
	var tile := Vector2i(floor(center / WG.TILE))
	region = Rect2i(tile - Vector2i(72, 52), Vector2i(145, 105))


func bind_world(data: Dictionary) -> void:
	visual_revision += 1
	world = data
	amounts = world.get(storage_key, PackedByteArray())
	var grid: PackedByteArray = world["tiles"]
	if amounts.size() != WG.WIDTH * WG.HEIGHT:
		amounts.resize(WG.WIDTH * WG.HEIGHT)
		amounts.fill(0)
		for index in range(grid.size()):
			if grid[index] == fluid_id:
				amounts[index] = CAPACITY
	world[storage_key] = amounts
	rain_amounts = world.get("rain_water", PackedByteArray()) if fluid_id == 4 else PackedByteArray()
	if rain_amounts.size() != amounts.size():
		rain_amounts.resize(amounts.size())
		rain_amounts.fill(0)
	rain_cells.clear()
	for index in range(amounts.size()):
		rain_amounts[index] = mini(rain_amounts[index], amounts[index])
		if rain_amounts[index] > 0:
			rain_cells[index] = true
	if fluid_id == 4:
		world["rain_water"] = rain_amounts
	for index in range(grid.size()):
		if grid[index] in [0, fluid_id]:
			grid[index] = fluid_id if amounts[index] > 0 else 0
	world["tiles"] = grid
	active.clear()
	changed.clear()
	falling.clear()
	accumulator = 0.0
	region = Rect2i()
	resume_index = -1
	has_fluid = false
	pressure_sources.clear()
	pressure_cursor = 0
	pressure_retry.clear()
	for index in range(amounts.size()):
		if amounts[index] > 0:
			has_fluid = true
			if fluid_id == 4 and index >= WG.WIDTH and amounts[index - WG.WIDTH] == 0:
				pressure_sources[index] = true
			if _can_move(grid, index):
				active[index] = true
	previous_amounts = amounts.duplicate()
	previous_falling.clear()


func _inside(x: int, y: int) -> bool:
	return x >= 0 and x < WG.WIDTH and y >= 0 and y < WG.HEIGHT


func _open(grid: PackedByteArray, index: int) -> bool:
	if index < 0 or index >= grid.size() or not WG.fluid_passable(grid[index], blocked_id):
		return false
	# All scenery, including chests/stations, can share fluid cells. Keep
	# water and lava separate there, just as in ordinary air/fluid cells.
	if grid[index] not in [0, fluid_id]:
		var other: PackedByteArray = world.get("lava" if fluid_id == 4 else "water", PackedByteArray())
		return other.is_empty() or other[index] == 0
	return true


func _can_move(grid: PackedByteArray, index: int) -> bool:
	var x := index % WG.WIDTH
	var y := int(index / WG.WIDTH)
	if y + 1 < WG.HEIGHT and _open(grid, index + WG.WIDTH) and amounts[index + WG.WIDTH] < CAPACITY:
		return true
	for direction in [-1, 1]:
		if x + direction >= 0 and x + direction < WG.WIDTH and _open(grid, index + direction) and int(amounts[index]) - int(amounts[index + direction]) >= 2:
			return true
	return false


func _wake_index(index: int) -> void:
	var x := index % WG.WIDTH
	var y := int(index / WG.WIDTH)
	if amounts[index] > 0:
		active[index] = true
	if x > 0 and amounts[index - 1] > 0:
		active[index - 1] = true
	if x + 1 < WG.WIDTH and amounts[index + 1] > 0:
		active[index + 1] = true
	if y > 0 and amounts[index - WG.WIDTH] > 0:
		active[index - WG.WIDTH] = true
	if y + 1 < WG.HEIGHT and amounts[index + WG.WIDTH] > 0:
		active[index + WG.WIDTH] = true
	if fluid_id == 4:
		for candidate in [index, index - WG.WIDTH, index + WG.WIDTH]:
			if candidate >= WG.WIDTH and candidate < amounts.size():
				if amounts[candidate] > 0 and amounts[candidate - WG.WIDTH] == 0:
					pressure_sources[candidate] = true
				else:
					pressure_sources.erase(candidate)
					pressure_retry.erase(candidate)


func terrain_changed(tile: Vector2i, new_id: int) -> void:
	if amounts.size() != WG.WIDTH * WG.HEIGHT or not _inside(tile.x, tile.y):
		return
	var index := tile.y * WG.WIDTH + tile.x
	pressure_retry.clear()
	visual_revision += 1
	if new_id == fluid_id and amounts[index] == 0:
		amounts[index] = CAPACITY
		has_fluid = true
	elif new_id == 0 or WG.is_solid(new_id) or new_id == blocked_id:
		amounts[index] = 0
		rain_amounts[index] = 0
		rain_cells.erase(index)
	world[storage_key] = amounts
	if fluid_id == 4:
		world["rain_water"] = rain_amounts
	_wake_index(index)
	if previous_amounts.size() == amounts.size():
		previous_amounts[index] = amounts[index]
	previous_falling.erase(index)
	falling.erase(index)


func amount_at(tile: Vector2i) -> int:
	if not _inside(tile.x, tile.y) or amounts.is_empty():
		return 0
	return int(amounts[tile.y * WG.WIDTH + tile.x])


func submerged(point: Vector2) -> bool:
	var tile := Vector2i(floor(point / WG.TILE))
	var amount := amount_at(tile)
	return amount > 0 and point.y >= float((tile.y + 1) * WG.TILE) - float(amount) / CAPACITY * WG.TILE


func intersects(rect: Rect2) -> bool:
	for y in range(maxi(0, int(floor(rect.position.y / WG.TILE))), mini(WG.HEIGHT, int(ceil(rect.end.y / WG.TILE)))):
		for x in range(maxi(0, int(floor(rect.position.x / WG.TILE))), mini(WG.WIDTH, int(ceil(rect.end.x / WG.TILE)))):
			var amount := amount_at(Vector2i(x, y))
			var surface := float((y + 1) * WG.TILE) - float(amount) / CAPACITY * WG.TILE
			if amount > 0 and rect.end.y > surface + 0.01:
				return true
	return false


func _transfer(source: int, target: int, units: int) -> void:
	if units <= 0:
		return
	visual_revision += 1
	var tagged := mini(units, roundi(float(rain_amounts[source]) * units / amounts[source]))
	rain_amounts[source] -= tagged
	rain_amounts[target] += tagged
	for index in [source, target]:
		if rain_amounts[index] > 0:
			rain_cells[index] = true
		else:
			rain_cells.erase(index)
	amounts[source] = int(amounts[source]) - units
	amounts[target] = int(amounts[target]) + units
	changed[source] = true
	changed[target] = true
	_wake_index(source)
	_wake_index(target)


func remove_units(index: int, units: int) -> int:
	if index < 0 or index >= amounts.size():
		return 0
	var removed := mini(maxi(units, 0), int(amounts[index]))
	if removed == 0:
		return 0
	visual_revision += 1
	var tagged := mini(int(rain_amounts[index]), roundi(float(rain_amounts[index]) * removed / amounts[index]))
	amounts[index] -= removed
	rain_amounts[index] -= tagged
	if rain_amounts[index] == 0:
		rain_cells.erase(index)
	changed[index] = true
	_wake_index(index)
	world[storage_key] = amounts
	if fluid_id == 4:
		world["rain_water"] = rain_amounts
	return removed


func add_rain(tile: Vector2i, units: int) -> int:
	if not _inside(tile.x, tile.y):
		return 0
	var index := tile.y * WG.WIDTH + tile.x
	if not _open(world["tiles"], index):
		return 0
	var added := mini(maxi(0, units), CAPACITY - amounts[index])
	if added == 0:
		return 0
	visual_revision += 1
	amounts[index] += added
	has_fluid = true
	rain_amounts[index] += added
	rain_cells[index] = true
	changed[index] = true
	_wake_index(index)
	world[storage_key] = amounts
	if fluid_id == 4:
		world["rain_water"] = rain_amounts
	return added


func evaporate(roof: PackedInt32Array, units: int) -> int:
	var removed := 0
	for index in rain_cells.keys():
		var x: int = index % WG.WIDTH
		var y := int(index / WG.WIDTH)
		# Only the exposed surface evaporates; a buried aquifer stays underground.
		if y >= roof[x] or (y > 0 and amounts[index - WG.WIDTH] > 0):
			continue
		var loss := mini(maxi(0, units), rain_amounts[index])
		amounts[index] -= loss
		rain_amounts[index] -= loss
		removed += loss
		if rain_amounts[index] == 0:
			rain_cells.erase(index)
		changed[index] = true
		_wake_index(index)
	world[storage_key] = amounts
	if removed > 0:
		visual_revision += 1
	if fluid_id == 4:
		world["rain_water"] = rain_amounts
	return removed


func drain_rain(roof: PackedInt32Array, column_limit: int, drain_rate: int = 96) -> int:
	# Limit rain-derived volume over the entire column, rather than a single
	# source cell. Natural water is never included in the drainage allowance.
	var totals := {}
	var pending := rain_cells.keys()
	for index in pending:
		var x: int = index % WG.WIDTH
		totals[x] = int(totals.get(x, 0)) + rain_amounts[index]
	var excess := {}
	for x in totals:
		excess[x] = mini(maxi(0, int(totals[x]) - column_limit), drain_rate)
	# Drain upper layers first so existing rain floods visibly recede.
	pending.sort()
	var removed := 0
	for index in pending:
		var x: int = index % WG.WIDTH
		var y := int(index / WG.WIDTH)
		var loss := mini(rain_amounts[index], int(excess[x]))
		excess[x] -= loss
		if y >= roof[x]:
			# Rain that seeped below a roof should not become a permanent
			# underground reservoir, even if the surface is still raining.
			loss += mini(2, rain_amounts[index] - loss)
		if loss <= 0:
			continue
		amounts[index] -= loss
		rain_amounts[index] -= loss
		removed += loss
		if rain_amounts[index] == 0:
			rain_cells.erase(index)
		changed[index] = true
		_wake_index(index)
	world[storage_key] = amounts
	if removed > 0:
		visual_revision += 1
	if fluid_id == 4:
		world["rain_water"] = rain_amounts
	return removed


func displace(tile: Vector2i) -> bool:
	# Placing a block pushes its water into connected free space. If there is
	# no capacity, reject placement rather than destroying or duplicating water.
	var units := amount_at(tile)
	if units == 0:
		return true
	var grid: PackedByteArray = world["tiles"]
	var start := tile.y * WG.WIDTH + tile.x
	var candidates := {}
	var pending: Array[Vector2i] = [tile]
	var seen := {tile: true}
	var cursor := 0
	var capacity := 0
	while cursor < pending.size() and cursor < 2048 and capacity < units:
		var at := pending[cursor]
		cursor += 1
		for offset in [Vector2i.UP, Vector2i.LEFT, Vector2i.RIGHT, Vector2i.DOWN]:
			var next: Vector2i = at + offset
			if not _inside(next.x, next.y) or seen.has(next) or absi(next.x - tile.x) + absi(next.y - tile.y) > 24:
				continue
			seen[next] = true
			var index := next.y * WG.WIDTH + next.x
			if not _open(grid, index):
				continue
			pending.append(next)
			var space := CAPACITY - int(amounts[index])
			if space > 0:
				candidates[index] = space
				capacity += space
	if capacity < units:
		return false
	for index in candidates:
		var moved := mini(units, int(candidates[index]))
		_transfer(start, index, moved)
		units -= moved
		if units == 0:
			break
	world[storage_key] = amounts
	if fluid_id == 4:
		world["rain_water"] = rain_amounts
	return true


func _pressure_path(source: int, grid: PackedByteArray) -> bool:
	# A connected, full water column transmits head. Move existing water to
	# a lower free surface, never above the supplying surface or through rock.
	var source_y := int(source / WG.WIDTH)
	var queue: Array[int] = [source]
	var seen := {source: true}
	var cursor := 0
	var level_target := -1
	var level_flow := 0
	var best_head := 0
	while cursor < queue.size() and cursor < 512:
		var index := queue[cursor]
		cursor += 1
		var x := index % WG.WIDTH
		var y := int(index / WG.WIDTH)
		for direction: Vector2i in [Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP]:
			var at := Vector2i(x, y) + direction
			if not _inside(at.x, at.y) or at.y < source_y or (region.size != Vector2i.ZERO and not region.has_point(at)):
				continue
			var target := at.y * WG.WIDTH + at.x
			if seen.has(target) or not _open(grid, target): continue
			if direction == Vector2i.UP and amounts[index] == CAPACITY and amounts[target] < CAPACITY:
				var head := int(amounts[source]) if at.y > source_y else maxi(0, int((int(amounts[source]) - int(amounts[target])) / 2))
				var moved := mini(96, mini(head, CAPACITY - int(amounts[target])))
				var difference := (at.y - source_y) * CAPACITY + int(amounts[source]) - int(amounts[target])
				if moved > 0 and difference > best_head:
					level_target = target
					level_flow = moved
					best_head = difference
			if amounts[target] == CAPACITY and queue.size() < 512:
				seen[target] = true
				queue.append(target)
	if level_target >= 0:
		_transfer(source, level_target, level_flow)
		return true
	return false


func _pressure_step(grid: PackedByteArray) -> void:
	if fluid_id != 4 or pressure_sources.is_empty(): return
	var sources := pressure_sources.keys()
	var probes := 0
	var candidates: Array[int] = []
	# At most two bounded path searches per fluid tick. No whole-world flood fill.
	for scan in range(mini(128, sources.size())):
		pressure_cursor = posmod(pressure_cursor, sources.size())
		var source: int = sources[pressure_cursor]
		pressure_cursor += 1
		if amounts[source] == 0 or amounts[source - WG.WIDTH] > 0 or not _open(grid, source):
			pressure_sources.erase(source)
			continue
		var at := Vector2i(source % WG.WIDTH, int(source / WG.WIDTH))
		if region.size != Vector2i.ZERO and not region.has_point(at): continue
		if at.y + 1 >= WG.HEIGHT or amounts[source + WG.WIDTH] != CAPACITY: continue
		if int(pressure_retry.get(source, 0)) > tick: continue
		candidates.append(source)
	# Prefer the reservoir's head over tiny differences along its own surface.
	candidates.sort_custom(func(a, b): return int(a / WG.WIDTH) * CAPACITY - int(amounts[a]) < int(b / WG.WIDTH) * CAPACITY - int(amounts[b]))
	for source in candidates:
		if not _pressure_path(source, grid): pressure_retry[source] = tick + 12
		probes += 1
		if probes >= 2: break


func step() -> void:
	var grid: PackedByteArray = world["tiles"]
	previous_amounts = amounts.duplicate()
	previous_falling = falling.duplicate()
	var pending := active.keys()
	# Bottom cells move first, so a parcel falls at most one tile per tick.
	pending.sort()
	pending.reverse()
	if resume_index >= 0:
		var offset := pending.find(resume_index)
		if offset > 0:
			pending = pending.slice(offset) + pending.slice(0, offset)
	# Choose a fair batch first, then restore bottom-first order within it.
	# Rotating the processing order itself let parcels jump multiple rows.
	var batch: Array[int] = []
	resume_index = -1
	for index in pending:
		if not region.size == Vector2i.ZERO and not region.has_point(Vector2i(index % WG.WIDTH, int(index / WG.WIDTH))):
			continue
		if batch.size() >= tick_budget:
			resume_index = index
			break
		batch.append(index)
	batch.sort()
	batch.reverse()
	falling.clear()
	var processed := 0
	var started := Time.get_ticks_usec()
	for index in batch:
		if processed > 0 and processed % 32 == 0 and Time.get_ticks_usec() - started > tick_time_us:
			resume_index = index
			break
		processed += 1
		active.erase(index)
		if amounts[index] == 0 or not _open(grid, index):
			continue
		var x: int = index % WG.WIDTH
		var y := int(index / WG.WIDTH)
		if y + 1 < WG.HEIGHT and _open(grid, index + WG.WIDTH):
			var moved := mini(vertical_limit, mini(int(amounts[index]), CAPACITY - int(amounts[index + WG.WIDTH])))
			# Viscous fluids leave a finite trailing column rather than moving
			# each small parcel wholesale and opening gaps between successive cells.
			moved = mini(moved, maxi(1, ceili(float(amounts[index]) * vertical_fraction)))
			_transfer(index, index + WG.WIDTH, moved)
			if moved > 0:
				falling[index + WG.WIDTH] = true
			# Unsupported liquid falls first. Spreading it sideways in midair
			# produced thin, disconnected shelves beside every waterfall.
			if amounts[index + WG.WIDTH] < CAPACITY:
				continue
		for direction in ([-1, 1] if tick % 2 == 0 else [1, -1]):
			if x + direction < 0 or x + direction >= WG.WIDTH or not _open(grid, index + direction):
				continue
			var difference := int(amounts[index]) - int(amounts[index + direction])
			if difference >= 2:
				_transfer(index, index + direction, mini(lateral_limit, int(difference / 2)))
	_pressure_step(grid)
	tick += 1
	world[storage_key] = amounts
	if fluid_id == 4:
		world["rain_water"] = rain_amounts


func update(delta: float) -> PackedInt32Array:
	# Do not run a backlog of expensive physics ticks after a slow frame.
	accumulator = minf(accumulator + delta, step_seconds)
	while accumulator >= step_seconds:
		accumulator -= step_seconds
		step()
	var dirty := PackedInt32Array(changed.keys())
	if not dirty.is_empty():
		var grid: PackedByteArray = world["tiles"]
		for index in dirty:
			if grid[index] in [0, fluid_id]:
				grid[index] = fluid_id if amounts[index] > 0 else 0
		world["tiles"] = grid
		world[storage_key] = amounts
	changed.clear()
	return dirty
