extends RefCounted

const WG = preload("res://scripts/world_gen.gd")
const MAX_LEAVES := 72
const MAX_WATER := 96
var leaves: Array[Dictionary] = []
var droplets: Array[Dictionary] = []
var rng := RandomNumberGenerator.new()
var leaf_budget := 0.0
var water_budget := 0.0


func reset(seed_value: int) -> void:
	leaves.clear()
	droplets.clear()
	leaf_budget = 0.0
	water_budget = 0.0
	rng.seed = seed_value ^ 0x1EAFF011


func update(game, delta: float) -> void:
	var wind: float = game._wind_speed()
	update_particles(delta, wind, game.world["tiles"])
	leaf_budget = minf(leaf_budget + delta * (0.8 + absf(wind) * 0.055), 3.0)
	while leaf_budget >= 1.0:
		leaf_budget -= 1.0
		if leaves.size() < MAX_LEAVES:
			_spawn_leaf(game, wind)
	var pouring: bool = game._is_pouring()
	if pouring:
		water_budget = minf(water_budget + delta * 44.0, 8.0)
		while water_budget >= 1.0 and droplets.size() < MAX_WATER:
			water_budget -= 1.0
			var at: Vector2 = game._watering_spout_world()
			var target: Vector2 = game.tool_action_target
			var drop := maxf(3.0, target.y - at.y)
			var flight := maxf(0.12, (-18.0 + sqrt(324.0 + 480.0 * drop)) / 240.0)
			droplets.append({"position": at + Vector2(rng.randf_range(-1.5, 1.5), 0),
				"velocity": Vector2((target.x - at.x) / flight + rng.randf_range(-12, 12), 18 + rng.randf_range(-3, 6)),
				"age": 0.0, "life": 1.0, "splash": false})
	else:
		water_budget = 0.0


func _spawn_leaf(game, wind: float) -> void:
	var candidates: Array = []
	for chunk in game.terrain_cache.visible(game.camera_pos):
		if not chunk["leaves"].is_empty():
			candidates.append(chunk)
	if candidates.is_empty():
		return
	var chunk: Dictionary = candidates[rng.randi_range(0, candidates.size() - 1)]
	var cells: Array = chunk["leaves"]
	var cell: Vector2i = cells[rng.randi_range(0, cells.size() - 1)]
	var crown: Dictionary = game.foliage.component(game.world["tiles"], cell, int(game.world["seed"]))
	if crown.is_empty():
		return
	var image: Image = crown["image"]
	for _attempt in range(12):
		var local := cell * WG.TILE - Vector2i(crown["origin"]) + Vector2i(rng.randi_range(0, 15), rng.randi_range(0, 15))
		var color := image.get_pixelv(local)
		if color.a < 0.9 or color.g < color.r * 1.05:
			continue
		var at := Vector2(local) + Vector2(crown["origin"])
		if not Rect2(game.camera_pos - Vector2(80, 80), Vector2(1440, 880)).has_point(at):
			return
		leaves.append({"position": at, "velocity": Vector2(wind * 0.65, rng.randf_range(12, 22)),
			"age": 0.0, "life": rng.randf_range(9, 14), "phase": rng.randf_range(0, TAU),
			"angle": rng.randf_range(0, TAU), "spin": rng.randf_range(-2, 2),
			"color": color.lightened(0.12), "landed": false})
		return


func update_particles(delta: float, wind: float, grid: PackedByteArray) -> void:
	for i in range(leaves.size() - 1, -1, -1):
		var leaf := leaves[i]
		leaf["age"] += delta
		if leaf["age"] >= leaf["life"]:
			leaves.remove_at(i)
			continue
		if leaf["landed"]:
			continue
		var velocity: Vector2 = leaf["velocity"]
		velocity.x = move_toward(velocity.x, wind + sin(leaf["age"] * 4.0 + leaf["phase"]) * 5.0, delta * 28.0)
		velocity.y = minf(32, velocity.y + delta * 7.0)
		var at: Vector2 = leaf["position"] + velocity * delta
		var tile := Vector2i(floor(at / WG.TILE))
		if WG.is_solid(WG.tile_at(grid, tile.x, tile.y)) or WG.tile_at(grid, tile.x, tile.y) in [4, 11]:
			leaf["landed"] = true
			leaf["life"] = leaf["age"] + 1.5
			at.y = tile.y * WG.TILE - 1.0
		leaf["position"] = at
		leaf["velocity"] = velocity
		leaf["angle"] += (leaf["spin"] + sin(leaf["age"] * 3 + leaf["phase"])) * delta
	for i in range(droplets.size() - 1, -1, -1):
		var drop := droplets[i]
		drop["age"] += delta
		if drop["age"] >= drop["life"]:
			droplets.remove_at(i)
			continue
		if drop["splash"]:
			continue
		var velocity: Vector2 = drop["velocity"]
		velocity.y += 240.0 * delta
		var at: Vector2 = drop["position"] + velocity * delta
		# Sweep the short motion segment so a fast stream cannot tunnel
		# through a one-tile roof or tilled row at low frame rates.
		var previous: Vector2 = drop["position"]
		var steps := maxi(1, int(ceil(previous.distance_to(at) / 4.0)))
		for step in range(1, steps + 1):
			var point := previous.lerp(at, float(step) / steps)
			var tile := Vector2i(floor(point / WG.TILE))
			if WG.is_solid(WG.tile_at(grid, tile.x, tile.y)) or WG.tile_at(grid, tile.x, tile.y) in [4, 11]:
				at = Vector2(point.x, tile.y * WG.TILE - 1)
				drop["splash"] = true
				drop["life"] = drop["age"] + 0.22
				break
		drop["position"] = at
		drop["velocity"] = velocity


func draw_effects(game) -> void:
	for leaf in leaves:
		var at: Vector2 = leaf["position"] - game.camera_pos
		if at.x < -16 or at.x > 1296 or at.y < -16 or at.y > 736:
			continue
		var alpha := minf(1.0, (leaf["life"] - leaf["age"]) / 1.2)
		var color: Color = leaf["color"]
		color.a = alpha
		var points := PackedVector2Array()
		var flutter := 0.4 + absf(cos(leaf["age"] * 5.0 + leaf["phase"])) * 0.6
		for point in [Vector2(-3, 0), Vector2(-1, -1.5), Vector2(2, -1), Vector2(3, 0), Vector2(0, 1.5)]:
			point.y *= flutter
			points.append(at + point.rotated(leaf["angle"]))
		game.draw_colored_polygon(points, color)
		game.draw_line(at - Vector2(2, 0).rotated(leaf["angle"]), at + Vector2(2, 0).rotated(leaf["angle"]), Color(0.62, 0.74, 0.37, alpha), 1.0)
	for drop in droplets:
		var at: Vector2 = drop["position"] - game.camera_pos
		if drop["splash"]:
			var alpha := clampf((drop["life"] - drop["age"]) / 0.22, 0, 1)
			for side in [-1, 1]:
				game.draw_line(at + Vector2(side * 2, -1), at + Vector2(side * 4, -4), Color(0.60, 0.85, 1.0, alpha), 1.0)
		else:
			var velocity: Vector2 = drop["velocity"]
			game.draw_line(at - velocity.normalized() * 3.0, at, Color(0.55, 0.81, 1.0, 0.86), 1.4)
