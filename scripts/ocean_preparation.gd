extends RefCounted

const WG = preload("res://scripts/world_gen.gd")
const VERSION := 2
const CAPACITY := 255
var world: Dictionary
var grid: PackedByteArray
var reference: PackedByteArray
var amounts: PackedByteArray
var lava: PackedByteArray
var visited := PackedByteArray()
var queue := PackedInt32Array()
var cursor := 0
var filled_cells := 0
var added_units := 0
var sea_level := 98
var done := false


func _init(data: Dictionary, natural_grid: PackedByteArray = PackedByteArray()) -> void:
	world = data
	grid = world["tiles"]
	sea_level = clampi(int(world.get("sea_level", 98)), 0, WG.HEIGHT - 1)
	reference = natural_grid if natural_grid.size() == grid.size() else PackedByteArray()
	amounts = world.get("water", PackedByteArray())
	lava = world.get("lava", PackedByteArray())
	if int(world.get("climate", -1)) not in [1, 2] or int(world.get("ocean_fill_version", 0)) >= VERSION:
		done = true
		return
	if amounts.size() != grid.size():
		amounts.resize(grid.size())
		amounts.fill(0)
		for index in range(grid.size()):
			if grid[index] == 4:
				amounts[index] = CAPACITY
	visited.resize(grid.size())
	for x in range(WG.WIDTH):
		var index := sea_level * WG.WIDTH + x
		# During a one-time save upgrade, seed only original sea water. Never
		# use a player's new tunnels or artificial ponds to expand the repair.
		var source := grid[index] == 4 if reference.is_empty() else reference[index] == 4
		if source and _passable(index):
			visited[index] = 1
			queue.append(index)


func _passable(index: int) -> bool:
	if not WG.fluid_passable(grid[index], 11):
		return false
	if lava.size() == grid.size() and lava[index] > 0:
		return false
	return reference.is_empty() or WG.fluid_passable(reference[index], 11)


func _visit(index: int) -> void:
	if visited[index] == 0 and _passable(index):
		visited[index] = 1
		queue.append(index)


func step(budget: int = 4096) -> bool:
	if done:
		return true
	# New entries can be discovered below; process at most this many cells.
	var processed := 0
	while cursor < queue.size() and processed < maxi(1, budget):
		var index := queue[cursor]
		cursor += 1
		processed += 1
		if amounts[index] < CAPACITY:
			added_units += CAPACITY - int(amounts[index])
			amounts[index] = CAPACITY
			filled_cells += 1
		# Scenery and containers can share water. Their tile IDs must survive.
		if grid[index] == 0:
			grid[index] = 4
		var x := index % WG.WIDTH
		var y := int(index / WG.WIDTH)
		if x > 0:
			_visit(index - 1)
		if x + 1 < WG.WIDTH:
			_visit(index + 1)
		if y > sea_level:
			_visit(index - WG.WIDTH)
		if y + 1 < WG.HEIGHT:
			_visit(index + WG.WIDTH)
	if cursor >= queue.size():
		world["tiles"] = grid
		world["water"] = amounts
		world["sea_level"] = sea_level
		world["ocean_fill_version"] = VERSION
		world["ocean_filled_cells"] = int(world.get("ocean_filled_cells", 0)) + filled_cells
		world["ocean_preparation"] = {"visited_cells": cursor, "filled_cells": filled_cells,
			"added_units": added_units, "guarded_upgrade": not reference.is_empty()}
		done = true
	return done
