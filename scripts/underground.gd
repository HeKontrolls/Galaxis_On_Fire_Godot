extends RefCounted
const Art = preload("res://scripts/sprite_art.gd")
const WIDTH := 1200
const HEIGHT := 1440
const OLD_HEIGHT := 360
const NAMES := ["Root caverns", "Limestone halls", "Sunken aquifer", "Prism caverns", "Fungal hollows", "Basalt depths", "Molten underworld"]
const GLOW := [Color("72caff"), Color("be8bff"), Color("7de5a0"), Color("ffc376"), Color("f591c6")]
var entries: Array = []
var buckets := {}
var textures := {}
var tiles_image: Image
var tile_cache := {}

static func tile(grid: PackedByteArray, x: int, y: int) -> int:
	return 3 if x < 0 or x >= WIDTH or y < 0 or y >= HEIGHT else int(grid[y * WIDTH + x])

static func biome(world: Dictionary, x: int, y: int) -> int:
	x = clampi(x, 0, WIDTH - 1)
	var depth := y - int(world["surface"][x])
	if y >= HEIGHT - 125: return 6
	if y >= 1080: return 5
	if depth < 75: return 0 if int(world["climate"]) in [0, 1, 2, 7] else 1
	var patch := posmod(int(x / 110) * 17 + int(y / 100) * 7 + int(world["seed"]) % 997, 9)
	if depth < 230: return 2 if patch < 3 and int(world["climate"]) not in [3, 4, 5] else 1
	if y < 720: return 2 if patch < 2 else 3
	return 4 if patch < 6 and int(world["climate"]) in [0, 1, 2, 7] else (3 if patch < 4 else 5)

static func extend(world: Dictionary, old_height: int = OLD_HEIGHT) -> void:
	if int(world.get("underground_version", 0)) >= 1 and world["tiles"].size() == WIDTH * HEIGHT: return
	var grid: PackedByteArray = world["tiles"]
	grid.resize(WIDTH * HEIGHT)
	var cave := FastNoiseLite.new(); cave.seed = int(world["seed"]) ^ 0xCA7E; cave.frequency = 0.036; cave.fractal_octaves = 3
	var broad := FastNoiseLite.new(); broad.seed = cave.seed + 97; broad.frequency = 0.011; broad.fractal_octaves = 2
	for y in range(old_height, HEIGHT):
		for x in range(WIDTH):
			var id := 3
			if x > 3 and x < WIDTH - 4 and y < HEIGHT - 3:
				var region := biome(world, x, y)
				var n := cave.get_noise_2d(x, y)
				var threshold := 0.12 if region in [2, 3, 4] else 0.23
				if n > threshold or absf(broad.get_noise_2d(x, y)) < 0.065: id = 0
				# Several winding trunk passages link the deep layers vertically.
				var shaft := fposmod(x + sin(y * 0.019 + int(world["seed"]) % 29) * 24, 235.0)
				if shaft > 112 and shaft < 120: id = 0
				if region == 6:
					if y > HEIGHT - 80 and y < HEIGHT - 18: id = 0
					if y >= HEIGHT - 18: id = 11
			if y >= HEIGHT - 3: id = 17
			grid[y * WIDTH + x] = id
	var rng := RandomNumberGenerator.new(); rng.seed = int(world["seed"]) ^ 0xDEEF
	# Deposits in the new layers use a separate stream; the original world is untouched.
	for vein in range(1550):
		var x := rng.randi_range(6, WIDTH - 7); var y := rng.randi_range(old_height + 8, HEIGHT - 100)
		var id: int = [20, 21, 22, 22, 23, 24, 25][rng.randi_range(0, 6)]
		if y > 980 and int(world["climate"]) in [4, 5] and vein % 5 == 0: id = 26
		for dy in range(-2, 3):
			for dx in range(-3, 4):
				if dx * dx + dy * dy <= 10 and tile(grid, x + dx, y + dy) == 3: grid[(y + dy) * WIDTH + x + dx] = id
	# More frequent, varied-depth sealed basins. Avoid overlapping earlier pools
	# so a later chamber cannot cut a drain through an already-filled lake.
	var pools: Array = []
	for pool in range(320):
		var x := rng.randi_range(20, WIDTH - 21)
		var y := rng.randi_range(old_height + 18, HEIGHT - 145)
		var region := biome(world, x, y)
		var fluid := 11 if region == 5 or int(world["climate"]) == 4 else 4
		var radius := rng.randi_range(5, 14)
		var depth := rng.randi_range(2, 6)
		var overlap := false
		for previous: Dictionary in pools:
			if absi(int(previous.x) - x) < int(previous.radius) + radius + 3 and absi(int(previous.y) - y) < 16:
				overlap = true; break
		if overlap: continue
		for dx in range(-radius, radius + 1):
			var floor_y := y + maxi(1, ceili(depth * (1.0 - pow(float(dx) / radius, 2))))
			for yy in range(y - 5, floor_y + 2):
				var id := 3 if (abs(dx) == radius and yy >= y) or yy >= floor_y else (fluid if yy >= y else 0)
				grid[yy * WIDTH + x + dx] = id
		pools.append({"x": x, "y": y, "radius": radius, "depth": depth, "fluid": fluid, "rim_version": 2})
	world["underground_pools"] = pools
	world["tiles"] = grid
	for field in ["water", "rain_water", "lava", "lava_cooling", "snow"]:
		var amounts: PackedByteArray = world.get(field, PackedByteArray())
		if amounts.is_empty(): continue
		var original_size := amounts.size()
		amounts.resize(WIDTH * HEIGHT)
		if field in ["water", "lava"]:
			var fluid_id := 4 if field == "water" else 11
			for i in range(mini(original_size, old_height * WIDTH), amounts.size()):
				amounts[i] = 255 if grid[i] == fluid_id else 0
		world[field] = amounts
	world["underground_version"] = 1
	world["world_height"] = HEIGHT
	load("res://scripts/underworld_structures.gd").apply(world, false)


static func clean_pool_rims(world: Dictionary) -> int:
	# Older basins had five-block posts above their waterline. Only remove
	# an intact generated post, checking its air on the basin side and its
	# stone foot. Each side is considered once; edited columns are preserved.
	var grid: PackedByteArray = world["tiles"]
	var removed := 0
	var cleared := {}
	for pool: Dictionary in world.get("underground_pools", []):
		if int(pool.get("rim_version", 1)) >= 2: continue
		var x := int(pool["x"])
		var y := int(pool["y"])
		var radius := int(pool["radius"])
		if x - radius < 1 or x + radius >= WIDTH - 1 or y < 6 or y + 2 >= HEIGHT:
			continue
		for side: int in [-1, 1]:
			var col := x + side * radius
			var intact := tile(grid, col, y) == 3 and tile(grid, col, y + 1) == 3
			for yy in range(y - 5, y):
				if tile(grid, col, yy) != 3 or tile(grid, col - side, yy) != 0:
					intact = false
				for field in ["torches", "placed_chests", "chest_contents", "workbenches", "furnaces", "crops", "mining_damage"]:
					if world.get(field, {}).has("%d,%d" % [col, yy]): intact = false
			if not intact: continue
			for yy in range(y - 5, y):
				grid[yy * WIDTH + col] = 0
				cleared[Vector2i(col, yy)] = true
				removed += 1
		pool["rim_version"] = 2
	world["tiles"] = grid
	for feature: Dictionary in world.get("cave_life", []):
		var support := Vector2i(int(feature["x"]), int(feature["y"]) + (1 if int(feature["kind"]) in [0, 1, 4] else -1))
		if cleared.has(support): feature["alive"] = false
	return removed

static func populate(world: Dictionary) -> void:
	if int(world.get("cave_life_version", 0)) >= 1: return
	world["cave_life_version"] = 1
	var result: Array = []
	world["cave_life"] = result
	var rng := RandomNumberGenerator.new(); rng.seed = int(world["seed"]) ^ 0xC1257
	var grid: PackedByteArray = world["tiles"]
	for col in range(298):
		var x := 4 + posmod(col * 113, 298) * 4
		for y in range(int(world["surface"][x]) + 24, HEIGHT - 24):
			if tile(grid, x, y) != 0: continue
			var floor_here := tile(grid, x, y + 1) in [2, 3, 5, 6, 17]
			var roof_here := tile(grid, x, y - 1) in [2, 3, 5, 6, 17]
			if not floor_here and not roof_here: continue
			if rng.randf() > 0.23: continue
			var region := biome(world, x, y)
			var kind := 0 if floor_here and rng.randf() < (0.8 if region == 3 else 0.45) else (1 if floor_here else 2)
			if roof_here and region in [0, 1, 2, 4] and rng.randf() < 0.6: kind = 3
			if floor_here and region == 4 and rng.randf() < 0.65: kind = 4
			var direction := -1 if floor_here else 1
			if tile(grid, x, y + direction) != 0 or tile(grid, x, y + direction * 2) != 0: continue
			var color := rng.randi_range(0, 4)
			if region == 4 or region == 0: color = 2
			if region >= 5: color = 3
			result.append({"x": x, "y": y, "kind": kind, "color": color, "variant": rng.randi_range(0, 1), "phase": rng.randf_range(0, 5), "alive": true})
			if result.size() >= 2400: return

func reset(game) -> void:
	populate(game.world)
	entries = game.world.get("cave_life", [])
	buckets.clear()
	for entry: Dictionary in entries:
		var key := Vector2i(int(entry["x"]) / 32, int(entry["y"]) / 32)
		if not buckets.has(key): buckets[key] = []
		buckets[key].append(entry)
	refresh_lights(game.world)

func nearby(rect: Rect2i) -> Array:
	var found: Array = []
	for y in range(floori(rect.position.y / 32.0), floori(rect.end.y / 32.0) + 1):
		for x in range(floori(rect.position.x / 32.0), floori(rect.end.x / 32.0) + 1):
			found.append_array(buckets.get(Vector2i(x, y), []))
	return found

func refresh_lights(world: Dictionary) -> void:
	var lights: Array = []
	for entry: Dictionary in entries:
		if bool(entry["alive"]) and int(entry["kind"]) in [0, 4]: lights.append(entry)
	world["cave_lights"] = lights

func changed(game, cell: Vector2i) -> void:
	var dirty := false
	for entry: Dictionary in nearby(Rect2i(cell - Vector2i(2, 4), Vector2i(5, 9))):
		if not bool(entry["alive"]): continue
		var x := int(entry["x"]); var y := int(entry["y"])
		var floor_kind := int(entry["kind"]) in [0, 1, 4]
		var support := tile(game.world["tiles"], x, y + (1 if floor_kind else -1))
		if support not in [2, 3, 5, 6, 17] or tile(game.world["tiles"], x, y) != 0:
			entry["alive"] = false; dirty = true
	if dirty: refresh_lights(game.world); game.environment.invalidate()

func texture(name: String) -> Texture2D:
	if not textures.has(name): textures[name] = Art.texture("res://assets/sprites/underground/" + name + ".png")
	return textures[name]

func draw(game) -> void:
	var area := Rect2i(Vector2i(floor(game.camera_pos / 16)) - Vector2i(3, 4), Vector2i(88, 54))
	for entry: Dictionary in nearby(area):
		if not bool(entry["alive"]): continue
		var x := int(entry["x"]); var y := int(entry["y"]); var kind := int(entry["kind"])
		var at: Vector2 = Vector2(x * 16 + 8, y * 16) - game.camera_pos
		if kind == 3:
			var fall := 160.0
			for dy in range(1, 12):
				if tile(game.world["tiles"], x, y + dy) != 0: fall = dy * 16.0; break
			var phase := fposmod(game.animation_clock + float(entry["phase"]), 2.8)
			var travel := phase * phase * 180.0
			if travel < fall: game.draw_texture(texture("drip"), at + Vector2(-16, travel - 42))
			elif phase < sqrt(fall / 180.0) + 0.16: game.draw_texture(texture("splash"), at + Vector2(-16, fall - 48))
			continue
		var name := "crystal_%d" % int(entry["color"]) if kind == 0 else ("stalagmite_%d" if kind == 1 else "stalactite_%d") % int(entry["variant"])
		if kind == 4: name = "cave_fungus"
		game.draw_texture(texture(name), at + Vector2(-16, -32 if kind in [0, 1, 4] else 0))

func harvest(game, point: Vector2) -> bool:
	var cell := Vector2i(floor(point / 16))
	for entry: Dictionary in nearby(Rect2i(cell - Vector2i(2, 3), Vector2i(5, 7))):
		if not bool(entry["alive"]) or int(entry["kind"]) == 3: continue
		var at := Vector2(int(entry["x"]) * 16 - 8, int(entry["y"]) * 16 + (-32 if int(entry["kind"]) in [0, 1, 4] else 0))
		var box := Rect2(at + Vector2(5, 5), Vector2(22, 43))
		if not box.has_point(point) or not game.interactions._visible(game.player_pos + Vector2(8, 11), box): continue
		var crystal := int(entry["kind"]) == 0
		if int(entry["kind"]) != 4 and not game.Tools.can_harvest(game.equipped_tool, 24 if crystal else 3):
			game._show_notice(game.Tools.requirement(24 if crystal else 3)); return true
		entry["alive"] = false
		game._wear_pickaxe(game.equipped_tool)
		game._drop_item("Alien Fiber" if int(entry["kind"]) == 4 else ("Crystal" if crystal else "Stone"), 1, cell)
		refresh_lights(game.world); game.environment.invalidate()
		return true
	return false

func cell_image(original: Image, frame: Vector2i, region: int, background: bool = false) -> Image:
	var key := "%s:%s:%s:%s" % [original.get_instance_id(), frame, region, background]
	if tile_cache.has(key): return tile_cache[key]
	if tiles_image == null: tiles_image = texture("cave_tiles").get_image()
	var result := tiles_image.get_region(Rect2i(region * 16, 0, 16, 16))
	for y in range(16):
		for x in range(16):
			var source := original.get_pixel(frame.x + x, frame.y + y)
			var color := result.get_pixel(x, y)
			var factor := 0.40 if background else clampf(source.get_luminance() * 1.8, 0.38, 1.15)
			color.r *= factor; color.g *= factor; color.b *= factor
			color.a = 1.0 if background else source.a
			result.set_pixel(x, y, color)
	tile_cache[key] = result
	return result
