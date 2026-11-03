extends RefCounted

const WG = preload("res://scripts/world_gen.gd")
const OBSIDIAN := 17
var pending := {}
var poll_budget := 0.1
var steam: Array[Dictionary] = []
var rng := RandomNumberGenerator.new()


func reset(game) -> void:
	pending.clear()
	steam.clear()
	poll_budget = 0.1
	rng.seed = int(game.world["seed"]) ^ 0x0B51D1A
	var lava: PackedByteArray = game.lava_sim.amounts
	for index in range(lava.size()):
		if lava[index] > 0:
			pending[index] = true


func queue_dirty(dirty: PackedInt32Array, lava) -> void:
	for index in dirty:
		if lava.amounts[index] > 0:
			pending[index] = true
		var x: int = index % WG.WIDTH
		var y := int(index / WG.WIDTH)
		for offset in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			var tile: Vector2i = Vector2i(x, y) + offset
			if tile.x < 0 or tile.y < 0 or tile.x >= WG.WIDTH or tile.y >= WG.HEIGHT:
				continue
			var next: int = tile.y * WG.WIDTH + tile.x
			if lava.amounts[next] > 0:
				pending[next] = true


func _puff(at: Vector2, count: int) -> void:
	for _particle in range(count):
		if steam.size() >= 64:
			break
		steam.append({"position": at + Vector2(rng.randf_range(-6, 6), rng.randf_range(-3, 2)),
			"velocity": Vector2(rng.randf_range(-6, 6), rng.randf_range(-27, -16)),
			"age": 0.0, "life": rng.randf_range(0.7, 1.3), "radius": rng.randf_range(2, 4)})


func _escape_position(game, tile: Vector2i) -> Variant:
	var block := Rect2(Vector2(tile * WG.TILE), Vector2(16, 16))
	if not block.intersects(game._player_rect(game.player_pos)):
		return game.player_pos
	for distance in range(4):
		var above := Vector2(game.player_pos.x, tile.y * WG.TILE - 28 - distance * WG.TILE)
		if not game._collides(above):
			return above
	for distance in range(1, 4):
		for side in [-1, 1]:
			var at := Vector2((tile.x + side * distance) * WG.TILE, game.player_pos.y)
			if not block.intersects(game._player_rect(at)) and not game._collides(at):
				return at
	return null


func _solidify(game, index: int) -> bool:
	var tile := Vector2i(index % WG.WIDTH, int(index / WG.WIDTH))
	var escape = _escape_position(game, tile)
	if escape == null:
		pending[index] = true
		return false
	game._edit_tile(tile, OBSIDIAN, false)
	if game.player_pos != escape:
		game.player_pos = escape
		game.player_velocity.y = minf(0, game.player_velocity.y)
	_puff(Vector2(tile * WG.TILE) + Vector2(8, 3), 5)
	return true


func update(game, delta: float, dirty: PackedInt32Array) -> PackedInt32Array:
	var result := PackedInt32Array()
	var wind: float = game._wind_speed()
	for i in range(steam.size() - 1, -1, -1):
		var puff := steam[i]
		puff["age"] += delta
		if puff["age"] >= puff["life"]:
			steam.remove_at(i)
			continue
		puff["position"] += (Vector2(puff["velocity"]) + Vector2(wind * 0.15, 0)) * delta
	queue_dirty(dirty, game.lava_sim)
	game.lava_sim.reheat(delta, game._is_raining())
	poll_budget = minf(poll_budget + delta, 0.2)
	if poll_budget < 0.1:
		return result
	poll_budget = 0.0
	for tile: Vector2i in game.lava_sim.rain_hits:
		_puff(Vector2(tile * WG.TILE) + Vector2(8, 0), 2)
	game.lava_sim.rain_hits.clear()
	for index in game.lava_sim.rain_cells:
		if game.lava_sim.amounts[index] > 0 and game.lava_sim.rain_amounts[index] >= game.lava_sim.amounts[index]:
			pending[index] = true
	var checked := 0
	var formed := 0
	for index in pending.keys():
		if checked >= 256 or formed >= 32:
			break
		pending.erase(index)
		checked += 1
		var amount: int = game.lava_sim.amounts[index]
		if amount == 0:
			continue
		var tile := Vector2i(index % WG.WIDTH, int(index / WG.WIDTH))
		var water_index := -1
		for offset in [Vector2i.UP, Vector2i.LEFT, Vector2i.RIGHT, Vector2i.DOWN]:
			var neighbor: Vector2i = tile + offset
			if game.water_sim.amount_at(neighbor) > 0:
				water_index = neighbor.y * WG.WIDTH + neighbor.x
				break
		if water_index < 0 and game.lava_sim.cooling_fraction(index) < 1.0:
			continue
		if _solidify(game, index):
			formed += 1
			result.append(index)
			if water_index >= 0:
				game.water_sim.remove_units(water_index, maxi(8, int(ceil(amount / 4.0))))
	if formed > 0:
		game.world_texture.update(game.world_image)
	return result


func draw_steam(game) -> void:
	for puff in steam:
		var at: Vector2 = puff["position"] - game.camera_pos
		if at.x < -32 or at.x > 1312 or at.y < -32 or at.y > 752:
			continue
		var progress: float = puff["age"] / puff["life"]
		var radius: float = puff["radius"] + progress * 4.0
		var alpha := sin(progress * PI) * 0.24
		game.draw_circle(at, radius + 2, Color(0.84, 0.90, 0.93, alpha * 0.2))
		game.draw_circle(at, radius, Color(0.84, 0.90, 0.93, alpha * 0.5))
		game.draw_circle(at, radius * 0.65, Color(0.91, 0.95, 0.97, alpha))
