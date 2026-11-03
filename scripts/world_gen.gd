extends RefCounted

const Biomes = preload("res://scripts/planet_biomes.gd")

# This port keeps the original tile scale and tile IDs. It uses only local,
# seeded RNG state, so weather and player actions cannot alter a future planet.
const WIDTH := 1200
const LEGACY_HEIGHT := 360
const HEIGHT := 1440
const TILE := 16
const NAMES := [
	"Temperate forest & grasslands",
	"Scattered islands & shallow sea",
	"Mixed oceans & continents",
	"Hot desert & dunes",
	"Rocky inner world & lava plains",
	"Outer rocky barren / cratered",
	"Frozen ocean & ice floes",
	"Tundra & permafrost",
]
const PALETTE := [
	Color("081425"), Color("53bd6a"), Color("9d704b"), Color("777d8c"),
	Color("3378cb"), Color("d0b77e"), Color("c3dced"), Color("765134"),
	Color("4f9e68"), Color("765134"), Color("777d8c"), Color("f06934"),
	Color("775a3b"), Color("60503d"), Color("83c45a"), Color("c6b36a"),
	Color("e1bf55"), Color("292234"), Color("101827"), Color("101827"),
	Color("363640"), Color("c6814a"), Color("b5b9c9"), Color("e0bf51"),
	Color("8865d2"), Color("65dbdc"), Color("78534f"), Color("75bedb"),
	Color("101827"), Color("101827"), Color("ab783d"),
	Color("101827"), Color("101827"), Color("aa754a"), Color("80532f"),
	Color("797b80"), Color("80532f"), Color("797b80"), Color("101827"), Color("101827"),
	Color("101827"), Color("53634c"), Color("765134"), Color("5b554d"), Color("eed680"), Color("92909a"),
]
# Natural vegetation lives in the scenery layer; placed wood remains terrain.
const FLORA := [7, 8, 14, 15, 16]
const SOLIDS := [1, 2, 3, 5, 6, 9, 10, 12, 13, 17, 20, 21, 22, 23, 24, 25, 26, 27, 33, 45]


static func tile_at(data: PackedByteArray, x: int, y: int) -> int:
	if x < 0 or y < 0 or x >= WIDTH or y >= HEIGHT:
		return 3
	return data[y * WIDTH + x]


static func set_tile(data: PackedByteArray, x: int, y: int, tile_id: int) -> void:
	if x >= 0 and x < WIDTH and y >= 0 and y < HEIGHT:
		data[y * WIDTH + x] = tile_id


static func is_solid(tile_id: int) -> bool:
	return tile_id in SOLIDS


static func fluid_passable(tile_id: int, blocked_id: int) -> bool:
	return tile_id != blocked_id and not is_solid(tile_id)


static func is_flora(tile_id: int) -> bool:
	return tile_id in FLORA


static func color_for(tile_id: int) -> Color:
	return PALETTE[mini(tile_id, PALETTE.size() - 1)]


static func _noise(seed_value: int, frequency: float, fractal: bool = true) -> FastNoiseLite:
	var noise := FastNoiseLite.new()
	noise.seed = seed_value
	noise.frequency = frequency
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	if fractal:
		noise.fractal_type = FastNoiseLite.FRACTAL_FBM
		noise.fractal_octaves = 4
		noise.fractal_gain = 0.5
	return noise


static func _blob(data: PackedByteArray, cx: int, cy: int, rx: int, ry: int, replacement: int, can_replace: Array) -> void:
	for y in range(maxi(2, cy - ry), mini(HEIGHT - 2, cy + ry + 1)):
		for x in range(maxi(2, cx - rx), mini(WIDTH - 2, cx + rx + 1)):
			var dx: float = float(x - cx) / float(maxi(1, rx))
			var dy: float = float(y - cy) / float(maxi(1, ry))
			if dx * dx + dy * dy < 1.0 and tile_at(data, x, y) in can_replace:
				set_tile(data, x, y, replacement)


static func _plant_tree(data: PackedByteArray, x: int, ground_y: int, rng: RandomNumberGenerator, dense: bool = false) -> bool:
	if x < 5 or x >= WIDTH - 5 or ground_y < 20:
		return false
	if tile_at(data, x, ground_y) not in [1, 5, 6]:
		return false
	if not dense:
		for ox in range(-2, 3):
			if tile_at(data, x + ox, ground_y) not in [1, 2, 5, 6]:
				return false
	else:
		for nx in range(maxi(0, x - 6), mini(WIDTH, x + 7)):
			for y in range(maxi(0, ground_y - 23), mini(HEIGHT, ground_y + 12)):
				if tile_at(data, nx, y) == 7:
					return false
	var height: int = rng.randi_range(9, 15)
	for y in range(ground_y - height - 5, ground_y):
		for ox in range(-3, 4):
			if dense and ox != 0 and y > ground_y - height + 3:
				continue
			if tile_at(data, x + ox, y) != 0:
				return false
	for y in range(ground_y - height, ground_y):
		set_tile(data, x, y, 7)
	# Compact crowns leave the trunk and separate side branches visible.
	var top := ground_y - height
	var widths := [1, 2, 2, 2, 1]
	for row in range(widths.size()):
		var y := top - 3 + row
		for ox in range(-widths[row], widths[row] + 1):
			if tile_at(data, x + ox, y) == 0:
				set_tile(data, x + ox, y, 8)
	var side := -1 if rng.randf() < 0.5 else 1
	for y in range(top + 4, ground_y - 2, 3):
		if rng.randf() < 0.85:
			if tile_at(data, x + side, y) == 0:
				set_tile(data, x + side, y, 8)
			if rng.randf() < 0.45 and tile_at(data, x + side * 2, y - 1) == 0:
				set_tile(data, x + side * 2, y - 1, 8)
		side *= -1
	return true


static func enrich_forest(data: Dictionary, protect_settlement: bool = true) -> int:
	# Legacy saves retain their trees and builds. Never run blanket enrichment.
	var biomes: PackedByteArray = data.get("biomes", PackedByteArray())
	if int(data.get("climate", -1)) != 0 or biomes.size() != WIDTH or int(data.get("forest_density_version", 0)) >= 3:
		return 0
	var grid: PackedByteArray = data["tiles"]
	var surface: PackedInt32Array = data["surface"]
	var rng := RandomNumberGenerator.new()
	rng.seed = int(data["seed"]) ^ 0xF0E57
	var player: Vector2 = data.get("player_pos", data.get("spawn", Vector2(-1000, 0)))
	var added := 0
	for x in range(8, WIDTH - 8, 2):
		var y := surface[x]
		if protect_settlement and absf(x * TILE - player.x) < 14 * TILE:
			continue
		var chance := float(Biomes.profile(0, biomes[x])["trees"])
		if tile_at(grid, x, y) != 1 or rng.randf() > chance or chance <= 0:
			continue
		var built := false
		for nx in range(x - 4, x + 5):
			for ny in range(maxi(0, y - 7), mini(HEIGHT, y + 3)):
				if tile_at(grid, nx, ny) in [9, 10, 12, 13, 14, 15, 16, 30, 33, 34, 35, 36, 37] or data.get("torches", {}).has("%d,%d" % [nx, ny]):
					built = true
		if not built and _plant_tree(grid, x, y, rng, true):
			added += 1
	data["tiles"] = grid
	data["forest_density_version"] = 3
	return added


static func _biome_pools(grid: PackedByteArray, surface: PackedInt32Array, columns: PackedByteArray, climate: int) -> void:
	if climate not in [3, 4]:
		return
	var start := 0
	for end in range(1, WIDTH + 1):
		if end < WIDTH and columns[end] == columns[start]:
			continue
		var center := (start + end) / 2
		var wanted := 2 if climate == 3 else 1
		if columns[start] == wanted and end - start > 45:
			var radius := 10 if climate == 3 else 13
			if climate == 4 and absi(center - WIDTH / 2) < 45:
				var left := start + radius + 3
				var right := end - radius - 4
				center = left if absi(left - WIDTH / 2) > absi(right - WIDTH / 2) else right
			var line := 0
			for x in range(center - radius, center + radius + 1):
				line = maxi(line, surface[x])
			for x in range(center - radius, center + radius + 1):
				var depth := roundi(4.0 * (1.0 - pow(float(x - center) / radius, 2)))
				var floor_y := line + depth
				for y in range(mini(surface[x], line), floor_y + 7):
					var id := 5 if climate == 3 else 3
					if y < line:
						id = 0
					elif y < floor_y:
						id = 4 if climate == 3 else 11
					set_tile(grid, x, y, id)
				surface[x] = floor_y
		start = end


static func _surface_basins(grid: PackedByteArray, surface: PackedInt32Array, seed_value: int, climate: int) -> Array:
	# Fresh worlds only. A separate RNG keeps unrelated terrain/content rolls stable.
	if climate == 6:
		return [] # Frozen ocean already has a planet-wide sea and ice sheet.
	var plans: Array = ["pond", "pond", "lake", "lake", "dry_basin"]
	if climate in [1, 2]:
		plans = ["pond", "dry_basin"]
	elif climate == 3:
		plans = ["pond", "dry_basin", "dry_basin"]
	elif climate in [4, 5]:
		plans = ["dry_basin", "dry_basin", "dry_basin"]
	elif climate == 7:
		plans = ["frozen_pond", "frozen_pond", "dry_basin"]
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value ^ 0x1A6EB451
	var basins: Array = []
	for kind: String in plans:
		for _attempt in range(160):
			var radius := rng.randi_range(23, 37) if kind == "lake" else rng.randi_range(9, 15)
			if kind == "dry_basin":
				radius = rng.randi_range(15, 28)
			var center := rng.randi_range(radius + 12, WIDTH - radius - 13)
			if absi(center - WIDTH / 2) < radius + 55:
				continue # Keep the landing area dry and unobstructed.
			var left := center - radius
			var right := center + radius
			var blocked := false
			for existing: Dictionary in basins:
				if left < int(existing["right"]) + 18 and right > int(existing["left"]) - 18:
					blocked = true
			var low := surface[left]
			var high := low
			for x in range(left, right + 1):
				low = mini(low, surface[x])
				high = maxi(high, surface[x])
				if not is_solid(tile_at(grid, x, surface[x])) or tile_at(grid, x, surface[x] - 1) != 0:
					blocked = true # No ocean excavation, cave-mouth sealing or lava replacement.
			if blocked or high - low > 14 or absi(surface[left] - surface[right]) > 4:
				continue
			var edge_left := surface[left]
			var edge_right := surface[right]
			var waterline := maxi(edge_left, edge_right) + 1
			# A diagonal cave can pass just beneath a bank without opening its top.
			# Reject that site instead of creating a leaking lake or sealing a cave.
			for bank in [left, right]:
				for y in range(surface[bank], waterline + 9):
					if not is_solid(tile_at(grid, bank, y)):
						blocked = true
			if blocked:
				continue
			var depth := rng.randi_range(7, 10) if kind == "lake" else rng.randi_range(4, 6)
			var wet := kind != "dry_basin"
			for x in range(left + 1, right):
				var t := float(x - left) / float(right - left)
				var floor_y := roundi(lerpf(edge_left, edge_right, t) + depth * pow(sin(t * PI), 0.75))
				var old_floor := surface[x]
				var top := 5 if wet or climate == 3 else (3 if climate in [4, 5] else (6 if climate == 7 else 1))
				var first_y := mini(mini(old_floor, floor_y), waterline) if wet else mini(old_floor, floor_y)
				for y in range(first_y, maxi(old_floor, floor_y) + 9):
					var tile := 0
					if y >= floor_y:
						tile = top if y == floor_y else (3 if y >= floor_y + 5 or climate in [4, 5] else 2)
					elif wet and y >= waterline:
						tile = 6 if kind == "frozen_pond" and y < waterline + 1 else 4
					set_tile(grid, x, y, tile)
				surface[x] = floor_y
			basins.append({"kind": kind, "left": left, "right": right, "waterline": waterline, "depth": depth})
			break
	return basins


static func _safe_spawn(data: PackedByteArray, surface: PackedInt32Array) -> Vector2:
	# Check the full 16x28 player rectangle, including neighboring columns.
	for radius in range(0, 120):
		for sign_dir in [1, -1]:
			var x: int = WIDTH / 2 + radius * sign_dir
			if x < 2 or x >= WIDTH - 2:
				continue
			var ground: int = surface[x]
			# On frozen oceans the walkable surface is the ice sheet, well above
			# the seabed recorded in the terrain profile.
			for yy in range(2, ground + 1):
				if is_solid(tile_at(data, x, yy)):
					ground = yy
					break
			if not is_solid(tile_at(data, x, ground)):
				continue
			var clear := true
			for ox in [-1, 0]:
				for oy in [-2, -1]:
					if tile_at(data, x + ox, ground + oy) not in [0, 8]:
						clear = false
			if clear:
				return Vector2(x * TILE - 8, ground * TILE - 29)
	return Vector2(WIDTH * TILE / 2.0, 64.0)


static func generate(seed_value: int, climate: int, settle_water: bool = true) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var terrain := _noise(seed_value ^ 0x54A731, 0.007)
	var detail := _noise(seed_value ^ 0x1835CB, 0.025)
	var cave_noise := _noise(seed_value ^ 0x76ED81, 0.048)
	var grid := PackedByteArray()
	grid.resize(WIDTH * HEIGHT)
	var surface := PackedInt32Array()
	surface.resize(WIDTH)
	var sea_level := 98
	var biomes := Biomes.generate(seed_value, climate, WIDTH)
	var edges := Biomes.edge_weights(biomes)

	for x in range(WIDTH):
		var biome := Biomes.profile(climate, biomes[x])
		var broad: float = terrain.get_noise_1d(float(x))
		var small: float = detail.get_noise_1d(float(x))
		var ground := 0
		var ocean_column := false
		if climate == 1:
			var island_shape: float = maxf(0.0, 1.0 - absf(float(x - WIDTH / 2)) / 42.0)
			island_shape = maxf(island_shape, maxf(0.0, broad - 0.04) * 2.0)
			ocean_column = island_shape < 0.16
			ground = sea_level - int(7.0 * island_shape + 3.0 * small) if not ocean_column else sea_level + 32 + int(18.0 * broad + 5.0 * small)
		elif climate == 2:
			var continental: float = broad + 0.4 * small
			continental = maxf(continental, 0.20 if absf(float(x - WIDTH / 2)) < 52.0 else -1.0)
			ocean_column = continental < 0.05
			ground = sea_level - 12 - int(24.0 * continental) if not ocean_column else sea_level + 30 + int(15.0 * absf(continental))
		elif climate == 6:
			ocean_column = true
			ground = sea_level + 83 + int(22.0 * broad + 6.0 * small)
		else:
			ground = 125 + int(22.0 * broad + 6.0 * small)
			if climate == 3:
				ground = 129 + int(9.0 * broad + 9.0 * sin(float(x) * 0.045 + 3.0 * broad))
			elif climate == 4:
				ground = 126 + int(8.0 * broad + 4.0 * small)
			elif climate == 5:
				ground = 128 + int(13.0 * broad + 5.0 * small)
				var crater_offset := absf(fposmod(float(x + seed_value % 101), 210.0) - 105.0)
				if crater_offset < 29.0:
					ground += int(19.0 * (1.0 - pow(crater_offset / 29.0, 2.0)))
			elif climate == 7:
				ground = 121 + int(25.0 * broad + 9.0 * small)
		ground += roundi(float(biome["height"]) * edges[x])
		ground = clampi(ground, 30, LEGACY_HEIGHT - 42)
		surface[x] = ground
		for y in range(ground, LEGACY_HEIGHT):
			var depth := y - ground
			var tile_id := 3
			if ocean_column:
				if depth == 0:
					tile_id = 6 if climate == 6 else 5
				elif depth < 3:
					tile_id = 6 if climate == 6 else 5
				elif depth < 12:
					tile_id = 2
				elif cave_noise.get_noise_2d(float(x), float(y)) > 0.60:
					tile_id = 2
				else:
					tile_id = 3
			else:
				if depth == 0:
					tile_id = int(biome["top"])
				elif depth < 5:
					tile_id = int(biome["soil"])
				elif depth < 18:
					tile_id = 3 if climate in [4, 5] else (5 if climate == 3 and rng.randf() < 0.50 else 2)
				else:
					tile_id = 3 if cave_noise.get_noise_2d(float(x), float(y)) > -0.10 else 2
			grid[y * WIDTH + x] = tile_id
		if ocean_column:
			var ice := int(biome.get("ice", 0)) if climate == 6 else 0
			if climate == 6 and biomes[x] == 1 and posmod(x + seed_value, 19) < 2:
				ice = 0
			if climate == 6 and absi(x - WIDTH / 2) < 28:
				ice = maxi(4, ice)
			var ice_top := sea_level - maxi(0, ice - 4)
			for y in range(ice_top, ground):
				grid[y * WIDTH + x] = 6 if y < ice_top + ice else 4

	# Carve varied caverns with true 2-D noise. Keep ocean caves below seabed.
	for x in range(4, WIDTH - 4):
		for y in range(surface[x] + 14, LEGACY_HEIGHT - 3):
			var n: float = cave_noise.get_noise_2d(float(x), float(y))
			var broad_cave: float = terrain.get_noise_2d(float(x) * 2.0, float(y) * 2.0)
			if n > 0.30 or (n > 0.17 and broad_cave > 0.21):
				grid[y * WIDTH + x] = 0
	# Guaranteed tunnel systems through each world, including ocean planets.
	var tunnel_count: int = 18 if climate in [0, 3, 4, 5, 7] else 11
	for tunnel_i in range(tunnel_count):
		var tx: int = rng.randi_range(30, WIDTH - 31)
		var ty: int = clampi(surface[tx] + rng.randi_range(20, 85), 25, LEGACY_HEIGHT - 20)
		var angle: float = rng.randf_range(-PI, PI)
		for step in range(rng.randi_range(55, 130)):
			if tx < 6 or tx >= WIDTH - 6 or ty < surface[tx] + 8 or ty >= LEGACY_HEIGHT - 8:
				break
			_blob(grid, tx, ty, rng.randi_range(2, 5), rng.randi_range(2, 4), 0, [2, 3, 5, 6])
			angle += rng.randf_range(-0.19, 0.19)
			tx += int(round(cos(angle) * 2.0))
			ty += int(round(sin(angle) * 2.0))
	# Sloping mouths wander into the cave layer, leaving the landing pad intact.
	var cave_entrances: Array = []
	for mouth_i in range(6):
		var mx: int = WIDTH / 2 + (-1 if mouth_i % 2 == 0 else 1) * (34 + mouth_i * 6) if climate in [1, 2] else rng.randi_range(65, WIDTH - 66)
		if absi(mx - WIDTH / 2) < 28:
			mx += 65
		var start_y := sea_level - 1 if climate == 6 else surface[mx] - 1
		var direction := -1 if mx < WIDTH / 2 else 1
		var depth := rng.randi_range(32, 46)
		var path: Array = []
		for step in range(depth):
			var cx := mx + direction * roundi(step * 0.82 + sin(step * 0.16) * 2.0)
			var cy := start_y + step
			_blob(grid, cx, cy, 3, 3, 0, [1, 2, 3, 5, 6, 17])
			path.append([cx, cy])
		cave_entrances.append(path)

	# Ores use local RNG and are biased by depth, never by runtime global state.
	for ore_id in [20, 21, 22, 23, 24]:
		var count: int = 145 if ore_id in [20, 21, 22] else 78
		for _vein in range(count):
			var ox: int = rng.randi_range(5, WIDTH - 6)
			var lower: int = clampi(surface[ox] + (18 if ore_id in [20, 21] else 65), 35, LEGACY_HEIGHT - 8)
			if lower >= LEGACY_HEIGHT - 8:
				continue
			var oy: int = rng.randi_range(lower, LEGACY_HEIGHT - 8)
			_blob(grid, ox, oy, rng.randi_range(2, 5), rng.randi_range(2, 4), ore_id, [2, 3, 5, 6])
	# Separate stream preserves the existing ore distribution and other content rolls.
	var mineral_rng := RandomNumberGenerator.new()
	mineral_rng.seed = seed_value ^ 0xD1A60D
	for ore_id in [25, 26]:
		if ore_id == 26 and climate not in [4, 5]:
			continue
		for _vein in range(95 if ore_id == 25 else 60):
			var x := mineral_rng.randi_range(8, WIDTH - 9)
			var lower := maxi(surface[x] + 100, 185 if ore_id == 25 else 270)
			if lower < LEGACY_HEIGHT - 8:
				_blob(grid, x, mineral_rng.randi_range(lower, LEGACY_HEIGHT - 8), 3 if ore_id == 25 else 2, 2, ore_id, [3])
	if climate == 0:
		for _lake_attempt in range(240):
			var wx := rng.randi_range(8, WIDTH - 9)
			var wy := rng.randi_range(surface[wx] + 25, LEGACY_HEIGHT - 9)
			if tile_at(grid, wx, wy) == 0 and is_solid(tile_at(grid, wx, wy + 1)):
				for nx in range(wx - 3, wx + 4):
					if tile_at(grid, nx, wy) == 0 and is_solid(tile_at(grid, nx, wy + 1)):
						set_tile(grid, nx, wy, 4)

	_biome_pools(grid, surface, biomes, climate)
	var surface_basins := _surface_basins(grid, surface, seed_value, climate)
	for x in range(10, WIDTH - 10, 5):
		var chance := float(Biomes.profile(climate, biomes[x])["trees"])
		if chance > 0 and rng.randf() < chance:
			_plant_tree(grid, x, surface[x], rng, true)
	# Guarantee accessible wood on water starts, which the Python version lacks.
	if climate in [1, 2]:
		var wood_near_spawn := false
		for xx in range(WIDTH / 2 - 48, WIDTH / 2 + 49):
			for yy in range(maxi(0, surface[xx] - 13), surface[xx]):
				if tile_at(grid, xx, yy) == 7:
					wood_near_spawn = true
		if not wood_near_spawn:
			var wx := WIDTH / 2 + 18
			for yy in range(surface[wx] - 10, surface[wx]):
				set_tile(grid, wx, yy, 0)
			for yy in range(surface[wx] - 7, surface[wx]):
				set_tile(grid, wx, yy, 7)
			for xx in range(wx - 2, wx + 3):
				set_tile(grid, xx, surface[wx] - 8, 8)

	if climate in [3, 4]:
		for _pool in range(10):
			var lx := rng.randi_range(10, WIDTH - 11)
			var ly := rng.randi_range(maxi(surface[lx] + 35, 205), LEGACY_HEIGHT - 13)
			_blob(grid, lx, ly, rng.randi_range(4, 8), 2, 11, [0])
	# Chests rest on solid cave floors.
	var placed := 0
	for _attempt in range(320):
		if placed >= 6:
			break
		var cx := rng.randi_range(8, WIDTH - 9)
		var cy := rng.randi_range(mini(surface[cx] + 24, LEGACY_HEIGHT - 8), LEGACY_HEIGHT - 8)
		if tile_at(grid, cx, cy) == 0 and tile_at(grid, cx, cy - 1) == 0 and is_solid(tile_at(grid, cx, cy + 1)):
			set_tile(grid, cx, cy, 30)
			placed += 1

	var data := {"tiles": grid, "surface": surface, "seed": seed_value, "climate": climate,
		"biomes": biomes, "biome_version": 1, "surface_basins": surface_basins, "cave_entrances": cave_entrances, "sea_level": sea_level}
	load("res://scripts/underground.gd").extend(data, LEGACY_HEIGHT)
	_gravel_deposits(data)
	if climate == 6:
		_ice_pillars(data)
	if settle_water:
		settle_oceans(data)
	enrich_forest(data, false)
	data["spawn"] = _safe_spawn(data["tiles"], surface)
	return data


static func _gravel_deposits(data: Dictionary) -> void:
	# Separate seed stream; new planets only. Never replace a saved player's build.
	var rng := RandomNumberGenerator.new()
	rng.seed = int(data.seed) ^ 0x67A9E1
	var grid: PackedByteArray = data.tiles
	for deposit in range(180):
		var x := rng.randi_range(12, WIDTH - 13)
		var y := rng.randi_range(int(data.surface[x]) + 7, HEIGHT - 100)
		_blob(grid, x, y, rng.randi_range(2, 5), rng.randi_range(1, 3), 45, [2, 3, 5])
	data.tiles = grid


static func settle_oceans(data: Dictionary, natural_grid: PackedByteArray = PackedByteArray()) -> int:
	# Synchronous entry point for generators/tests. Gameplay steps this same
	# preparation job between loading-screen frames before binding the solver.
	var preparation = load("res://scripts/ocean_preparation.gd").new(data, natural_grid)
	while not preparation.step(8192):
		pass
	return int(preparation.filled_cells)


static func _ice_surface(data: Dictionary, x: int) -> int:
	var columns: PackedByteArray = data.get("biomes", PackedByteArray())
	var biome := int(columns[x]) if columns.size() == WIDTH else 0
	var ice := int(Biomes.profile(6, biome).get("ice", 0))
	if biome == 1 and posmod(x + int(data["seed"]), 19) < 2:
		ice = 0
	return int(data.get("sea_level", 98)) - maxi(0, ice - 4) if ice > 0 else -1


static func _ice_pillars(data: Dictionary, preserve_settlement: bool = false) -> int:
	if int(data.get("climate", -1)) != 6 or int(data.get("ice_spires_version", 0)) >= 2:
		return 0
	var rng := RandomNumberGenerator.new()
	rng.seed = int(data["seed"]) ^ 0x1CE712
	var grid: PackedByteArray = data["tiles"]
	var pillars: Array = data.get("ice_pillars", []).duplicate(true)
	var original_count := pillars.size()
	var columns: PackedByteArray = data.get("biomes", PackedByteArray())
	var protected: Array[Vector2i] = []
	for old: Dictionary in pillars:
		protected.append(Vector2i(int(old["x"]) - 13, int(old["x"]) + 13))
	var player: Vector2 = data.get("player_pos", data.get("spawn", Vector2(WIDTH * TILE / 2.0, 0)))
	for field in range(24, WIDTH - 24, 59):
		var center := field + rng.randi_range(-8, 8)
		if absi(center - WIDTH / 2) < 86 or rng.randf() < 0.13:
			continue
		var biome := int(columns[clampi(center, 0, WIDTH - 1)]) if columns.size() == WIDTH else 0
		var dominant := rng.randi_range(44, 58) if biome == 2 else (rng.randi_range(30, 47) if biome == 0 else rng.randi_range(26, 42))
		var count := rng.randi_range(3, 5)
		var prevailing := rng.randi_range(-6, 6)
		for spike in range(count):
			var side := -1 if spike % 2 == 1 else 1
			var base_x := center if spike == 0 else center + side * ((spike + 1) / 2) * rng.randi_range(9, 13)
			if base_x < 10 or base_x >= WIDTH - 10 or absi(base_x - WIDTH / 2) < 70:
				continue
			var base_y := _ice_surface(data, base_x)
			if base_y < 0:
				continue # Preserve open-water leads; build on actual floes/shelves.
			var height := dominant if spike == 0 else maxi(16, roundi(dominant * rng.randf_range(0.44, 0.80)))
			var radius := rng.randi_range(3, 5) if spike == 0 else rng.randi_range(2, 4)
			var lean := prevailing + rng.randi_range(-2, 2)
			var left := base_x - radius - absi(lean) - 1
			var right := base_x + radius + absi(lean) + 1
			var clear := true
			for band: Vector2i in protected:
				if left <= band.y and right >= band.x:
					clear = false
			if preserve_settlement and absf(base_x * TILE - player.x) < (24 + radius + absi(lean)) * TILE:
				clear = false
			if preserve_settlement:
				for life: Dictionary in data.get("ground_life", []):
					if absf(float(life["x"]) - (base_x * TILE + 8)) <= (radius + 1) * TILE and absf(float(life["y"]) - base_y * TILE) < 3 * TILE:
						clear = false # Do not bury existing or harvested ground life.
			for x in range(base_x - radius, base_x + radius + 1):
				if _ice_surface(data, x) != base_y or tile_at(grid, x, base_y) != 6 or tile_at(grid, x, base_y + 1) != 6:
					clear = false
			for x in range(left, right + 1):
				for y in range(base_y - height - 2, base_y):
					if tile_at(grid, x, y) != 0 or data.get("torches", {}).has("%d,%d" % [x, y]):
						clear = false
			if not clear:
				continue
			var previous_x := base_x
			for rise in range(height):
				var t := float(rise) / (height - 1)
				var x := base_x + roundi(lean * minf(t / 0.9, 1.0))
				var width := floori(radius * pow(1.0 - t, 0.82))
				for ox in range(-width, width + 1):
					set_tile(grid, x + ox, base_y - rise, 27)
				if width == 0 and x != previous_x:
					set_tile(grid, previous_x, base_y - rise, 27)
				previous_x = x
			# Root the prism into the existing ice instead of floating on water.
			for ox in range(-mini(2, radius), mini(2, radius) + 1):
				set_tile(grid, base_x + ox, base_y + 1, 27)
			pillars.append({"x": base_x, "y": base_y, "height": height, "radius": radius,
				"lean": lean, "tip_x": base_x + lean, "top_y": base_y - height + 1,
				"field": field, "dominant": spike == 0, "version": 2})
	data["tiles"] = grid
	data["ice_pillars"] = pillars
	data["ice_spires_version"] = 2
	return pillars.size() - original_count


static func enrich_ice_spires(data: Dictionary) -> int:
	return _ice_pillars(data, true)


static func terrain_underlay_color(tile_id: int) -> Color:
	# Detailed terrain and props draw their own silhouettes; a full-cell fallback
	# behind them would fill transparent corners with bright palette colors.
	if tile_id in [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 20, 21, 22, 23, 24, 25, 26, 27, 33, 34, 35, 36, 37, 45]:
		return Color.TRANSPARENT
	return color_for(tile_id)


static func make_texture(data: PackedByteArray) -> ImageTexture:
	var image := Image.create(WIDTH, HEIGHT, false, Image.FORMAT_RGBA8)
	for y in range(HEIGHT):
		for x in range(WIDTH):
			var tile_id: int = data[y * WIDTH + x]
			image.set_pixel(x, y, terrain_underlay_color(tile_id))
	return ImageTexture.create_from_image(image)
