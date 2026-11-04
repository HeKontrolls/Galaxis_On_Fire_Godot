extends RefCounted
## Finite sand blocks become moving bodies, then settle back into mineable terrain.
## Sand and gravel fall: structural stone, soil, stations and scenery keep their rules.
const WG = preload("res://scripts/world_gen.gd")
const LIMIT := 64
const SCAN_BUDGET := 768
const START_BUDGET := 8
var pieces: Array = []
var pending := {}
var scan_origin := Vector2i(-10000, -10000)
var scan_cursor := 0
var scan_clock := 0.0
var textures := {}

func reset(game) -> void:
	pieces = game.world.get("falling_sand", [])
	game.world["falling_sand"] = pieces
	pending.clear()
	scan_origin = Vector2i(-10000, -10000)
	scan_cursor = 0
	scan_clock = 0.0
	if textures.is_empty() and game.terrain_sheets.has("sand"):
		var texture := AtlasTexture.new()
		texture.atlas = game.terrain_sheets["sand"]
		# Existing Aseprite sand artwork; same tile scale as settled terrain.
		texture.region = Rect2(18, 18, 16, 16)
		textures[5] = texture
		var gravel := AtlasTexture.new()
		gravel.atlas = game.terrain_sheets["gravel"]
		gravel.region = Rect2(0, 0, 16, 16)
		textures[45] = gravel

func terrain_changed(tile: Vector2i) -> void:
	for at in [tile, tile + Vector2i.UP]:
		if at.x >= 0 and at.x < WG.WIDTH and at.y >= 0 and at.y < WG.HEIGHT - 1:
			pending[at] = true

func _open(game, tile: Vector2i) -> bool:
	if tile.x < 0 or tile.x >= WG.WIDTH or tile.y < 0 or tile.y >= WG.HEIGHT:
		return false
	if not game.furnishings.at(tile).is_empty() or not game.power.at(tile).is_empty(): return false
	# Do not overwrite crops, tree trunks, stations, chests or placed lights.
	return WG.tile_at(game.world.tiles, tile.x, tile.y) in [0, 4, 11] \
		and not game.world.get("torches", {}).has("%d,%d" % [tile.x, tile.y])

func _actor_bounds(game) -> Array[Rect2]:
	var result: Array[Rect2] = [game._player_rect(game.player_pos)]
	var npc: Dictionary = game.world.get("npc", {})
	if npc.has("x"):
		result.append(Rect2(Vector2(float(npc.x), float(npc.y)), Vector2(12, 29)))
	for c in game.world.get("creatures", []):
		if bool(c.get("alive", false)):
			result.append(Rect2(Vector2(float(c.x), float(c.y)), Vector2(24, 18)))
	return result

func _occupied(bounds: Rect2, actors: Array[Rect2], except: Dictionary = {}) -> bool:
	for body in actors:
		if bounds.intersects(body): return true
	for other: Dictionary in pieces:
		if is_same(other, except): continue
		if bounds.intersects(Rect2(float(other.x), float(other.y), 16, 16)):
			return true
	return false

func _scan(game) -> void:
	var center := Vector2i(floor((game.player_pos + Vector2(8, 14)) / 16))
	var origin := Vector2i(clampi(center.x - 48, 0, WG.WIDTH - 97), clampi(center.y - 32, 0, WG.HEIGHT - 65))
	if origin.distance_squared_to(scan_origin) > 64:
		scan_origin = origin
		scan_cursor = 0
	# Incremental local scan also resumes unsupported sand in old saves.
	for i in range(SCAN_BUDGET):
		var cell := scan_origin + Vector2i(scan_cursor % 97, int(scan_cursor / 97))
		scan_cursor = (scan_cursor + 1) % (97 * 65)
		if WG.tile_at(game.world.tiles, cell.x, cell.y) in [5, 45] and _open(game, cell + Vector2i.DOWN):
			pending[cell] = true

func update(game, delta: float) -> void:
	if delta <= 0.0 or game.world.is_empty(): return
	var actors := _actor_bounds(game)
	var changed := false
	var dt := minf(delta, 0.1)
	# Bottom bodies move first, so a falling column keeps its order.
	pieces.sort_custom(func(a, b): return float(a.y) > float(b.y))
	for piece: Dictionary in pieces.duplicate():
		var cell := Vector2i(floor(Vector2(float(piece.x), float(piece.y)) / 16))
		if not _open(game, cell):
			# A player may build into a moving body. Return its exact one block,
			# rather than overwriting the build or silently discarding material.
			game._drop_item("Gravel" if int(piece.get("id", 5)) == 45 else "Sand", 1, cell)
			pieces.erase(piece)
			continue
		var wet: bool = game.water_sim.intersects(Rect2(float(piece.x), float(piece.y), 16, 16))
		var speed := minf(float(piece.get("vy", 0.0)) + (250.0 if wet else 720.0) * dt, 90.0 if wet else 320.0)
		piece["vy"] = speed
		var remaining := speed * dt
		while remaining > 0.0001:
			var distance := minf(remaining, 2.0)
			var next_y := float(piece.y) + distance
			var next_rect := Rect2(float(piece.x), next_y, 16, 16)
			if _occupied(next_rect, actors, piece):
				piece["vy"] = 0.0
				break
			var floor_cell := Vector2i(cell.x, floori((next_y + 15.999) / 16))
			if not _open(game, floor_cell):
				var target := floor_cell + Vector2i.UP
				var resting := Rect2(Vector2(target * 16), Vector2(16, 16))
				if _open(game, target) and not _occupied(resting, actors, piece):
					# Reserve connected space for every unit before replacing fluid.
					if game.water_sim.displace(target) and game.lava_sim.displace(target):
						game._edit_tile(target, int(piece.get("id", 5)), false)
						pieces.erase(piece)
						changed = true
				piece["vy"] = 0.0
				break
			piece["y"] = next_y
			remaining -= distance
	scan_clock += delta
	if scan_clock >= 0.12:
		scan_clock = fmod(scan_clock, 0.12)
		_scan(game)
		var started := 0
		for tile: Vector2i in pending.keys():
			if started >= START_BUDGET or pieces.size() >= LIMIT: break
			pending.erase(tile)
			if absf(tile.x * 16 - game.player_pos.x) > 1000 or absf(tile.y * 16 - game.player_pos.y) > 800:
				continue
			if WG.tile_at(game.world.tiles, tile.x, tile.y) not in [5, 45] or not _open(game, tile + Vector2i.DOWN): continue
			if _occupied(Rect2(Vector2(tile * 16), Vector2(16, 18)), actors):
				pending[tile] = true
				continue
			var material := WG.tile_at(game.world.tiles, tile.x, tile.y)
			game._edit_tile(tile, 0, false)
			pieces.append({"x": float(tile.x * 16), "y": float(tile.y * 16), "vy": 0.0, "id": material})
			started += 1
			changed = true
	if changed:
		game.world_texture.update(game.world_image)

func draw(game) -> void:
	if textures.is_empty(): return
	for piece: Dictionary in pieces:
		var at: Vector2 = Vector2(float(piece.x), float(piece.y)) - game.camera_pos
		if Rect2(-16, -16, 1312, 752).has_point(at):
			game.draw_texture(textures[int(piece.get("id", 5))], at.round())

