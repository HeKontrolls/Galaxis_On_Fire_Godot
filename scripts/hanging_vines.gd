extends RefCounted
const WG = preload("res://scripts/world_gen.gd")
const Art = preload("res://scripts/sprite_art.gd")
const MAX_VINES := 420
var texture: Texture2D
var entries: Array = []
var growth_clock := 0.0
var bends := {}
var last_player := Vector2.ZERO

func origin(v: Dictionary) -> Vector2:
	var dx := int(v["side"])
	return Vector2((int(v["x"]) + dx) * 16 + (8 if dx == 0 else (2 if dx > 0 else 14)), int(v["y"]) * 16 + (16 if dx == 0 else 4))

func capacity(world: Dictionary, v: Dictionary) -> int:
	if WG.tile_at(world["tiles"], int(v["x"]), int(v["y"])) not in [1, 2, 3, 6]:
		return 0
	var at := origin(v)
	for segment in range(int(v["limit"])):
		for dy in [0, 7]:
			for dx in [-5, 0, 5]:
				# Edge vines cling to the wall. Their wall-facing leaves are
				# naturally hidden by terrain, while the stem stays in open air.
				if (int(v["side"]) > 0 and dx < 0) or (int(v["side"]) < 0 and dx > 0): continue
				var cell := Vector2i(floor((at + Vector2(dx, segment * 8 + dy)) / 16))
				if cell == Vector2i(int(v["x"]), int(v["y"])):
					continue
				if cell.x < 1 or cell.x >= WG.WIDTH - 1 or cell.y >= WG.HEIGHT - 1 or WG.tile_at(world["tiles"], cell.x, cell.y) not in [0, 7, 8]:
					return segment
	return int(v["limit"])

func reset(game) -> void:
	if texture == null:
		texture = Art.texture("res://assets/sprites/ecology/hanging_vines.png")
	bends.clear()
	last_player = game.player_pos
	growth_clock = float(game.world.get("vine_growth_clock", 0.0))
	if int(game.world.get("vines_version", 0)) < 1:
		generate(game.world)
	entries = game.world.get("vines", [])
	revalidate(game)

func generate(world: Dictionary) -> void:
	var result: Array = []
	world["vines"] = result
	world["vines_version"] = 1
	if int(world["climate"]) not in [0, 1, 2, 7]:
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = int(world["seed"]) ^ 0x61A39
	var grid: PackedByteArray = world["tiles"]
	# Sample columns in seeded order so the entry cap cannot favor the map's left edge.
	var start := rng.randi_range(2, WG.WIDTH - 3)
	for offset in range(WG.WIDTH - 4):
		var x := 2 + posmod(start + offset * 397, WG.WIDTH - 4)
		var surface := int(world["surface"][x])
		for y in range(maxi(4, surface - 3), mini(WG.HEIGHT - 8, surface + 100)):
			var id := WG.tile_at(grid, x, y)
			if id not in [1, 2, 3, 6]:
				continue
			var side := 0
			var ledge := y <= surface + 1 and WG.tile_at(grid, x, y - 1) == 0
			if ledge:
				if WG.tile_at(grid, x + 1, y) == 0: side = 1
				elif WG.tile_at(grid, x - 1, y) == 0: side = -1
			if side == 0 and WG.tile_at(grid, x, y + 1) != 0:
				continue
			var chance := 0.72 if side != 0 else (0.13 if y < surface + 36 else 0.055)
			if int(world["climate"]) == 7: chance *= 0.25
			if rng.randf() > chance:
				continue
			var v := {"x": x, "y": y, "side": side, "length": 0, "limit": rng.randi_range(4, 14), "style": rng.randi_range(0, 1) if y <= surface + 3 else 2, "phase": rng.randf_range(0, TAU), "alive": true}
			var room := capacity(world, v)
			if room < 3:
				continue
			v["length"] = rng.randi_range(3, room)
			result.append(v)
			if result.size() >= MAX_VINES:
				return

func revalidate(game) -> void:
	for v: Dictionary in entries:
		_validate(game, v)

func _validate(game, v: Dictionary) -> void:
	if not bool(v["alive"]): return
	var room := capacity(game.world, v)
	v["length"] = mini(int(v["length"]), room)
	if int(v["length"]) == 0: v["alive"] = false

func terrain_changed(game, tile: Vector2i) -> void:
	# Digging only needs to check nearby strands, not every vine on the planet.
	for v: Dictionary in entries:
		if abs(tile.x - int(v["x"])) <= 2 and tile.y >= int(v["y"]) and tile.y <= int(v["y"]) + ceili(int(v["length"]) / 2.0) + 1:
			_validate(game, v)

func update(game, delta: float) -> void:
	var travel: Vector2 = game.player_pos - last_player
	last_player = game.player_pos
	for i in range(entries.size()):
		var v: Dictionary = entries[i]
		if not bool(v["alive"]): continue
		var at := origin(v)
		if absf(at.x - game.player_pos.x) > 800: continue
		var touching: bool = absf(at.x - game.player_pos.x - 8) < 20 and game.player_pos.y + 28 > at.y and game.player_pos.y < at.y + int(v["length"]) * 8
		var target := clampf(travel.x * 2, -7, 7) if touching and travel.length() < 64 else 0.0
		bends[i] = move_toward(float(bends.get(i, 0.0)), target, delta * 20.0)
	growth_clock += delta
	if growth_clock >= 30.0:
		growth_clock = fmod(growth_clock, 30.0)
		revalidate(game)
		for v: Dictionary in entries:
			if bool(v["alive"]):
				v["length"] = mini(int(v["length"]) + 1, capacity(game.world, v))
	game.world["vine_growth_clock"] = growth_clock

func segment_position(game, v: Dictionary, index: int, segment: int) -> Vector2:
	var at := origin(v)
	var surface := int(game.world["surface"][int(v["x"])])
	var wind: float = clampf(game._wind_speed() / 60.0, -1.5, 1.5) if int(v["y"]) <= surface + 1 else 0.0
	var weight := minf(segment / 8.0, 1.0)
	var sway := (sin(game.animation_clock * 1.6 + float(v["phase"]) - segment * 0.18) * wind + wind + float(bends.get(index, 0.0))) * weight
	return at + Vector2(roundf(sway), segment * 8)

func draw(game) -> void:
	for i in range(entries.size()):
		var v: Dictionary = entries[i]
		if not bool(v["alive"]): continue
		var screen: Vector2 = origin(v) - game.camera_pos
		if screen.x < -24 or screen.x > 1304 or screen.y > 740 or screen.y + int(v["length"]) * 8 < -20: continue
		for segment in range(int(v["length"])):
			var row := 0 if segment == 0 else (2 if segment == int(v["length"]) - 1 else 1)
			game.draw_texture_rect_region(texture, Rect2(segment_position(game, v, i, segment) - game.camera_pos - Vector2(8, 0), Vector2(16, 8)), Rect2(int(v["style"]) * 16, row * 8, 16, 8))

func harvest_at(game, point: Vector2) -> bool:
	for i in range(entries.size()):
		var v: Dictionary = entries[i]
		if not bool(v["alive"]): continue
		var segment := floori((point.y - origin(v).y) / 8)
		if segment < 0 or segment >= int(v["length"]): continue
		var at := segment_position(game, v, i, segment)
		if absf(point.x - at.x) > 9: continue
		if not game.interactions._visible(game.player_pos + Vector2(8, 11), Rect2(at - Vector2(6, 0), Vector2(12, 8))): continue
		var removed := int(v["length"]) - segment
		v["length"] = segment
		if segment == 0: v["alive"] = false
		game._drop_item("Alien Fiber", maxi(1, ceili(removed / 4.0)), Vector2i(floor(point / 16)))
		game._show_notice("Vine cut - Alien Fiber")
		return true
	return false
