extends RefCounted

const WG = preload("res://scripts/world_gen.gd")
const Art = preload("res://scripts/sprite_art.gd")
const ROOT := "res://assets/sprites/ground_life/"
const DESERT := ["opuntia", "joshua_tree", "golden_barrel", "saguaro", "brittlebush", "ghost_plant", "foxtail_agave", "tumbleweed", "desert_marigold", "desert_lily", "jade_plant", "aloe_vera", "chaste_tree", "cane_cholla", "mexican_fencepost"]
const SPECIES := ["meadow_grass", "wildflower", "fern", "berry_shrub", "reeds", "broadleaf", "dry_grass", "cactus", "frost_grass", "moss", "lichen", "crystal_bloom", "ice_coral", "ember_frond", "beetle", "butterfly", "snail", "sand_hopper", "snow_moth", "ember_mite", "hare", "ground_bird",
	"leafy_bush", "forest_thicket", "flowering_bush", "frost_bush", "pebble_cluster", "granite_boulder", "mossy_boulder", "sandstone_rock", "basalt_rock", "woodland_mushrooms"] + DESERT
const ITEMS := ["Meadow Grass", "Wildflower", "Woodland Fern", "Berry Shrub", "Reeds", "Broadleaf Plant", "Dry Grass", "Desert Cactus", "Frost Grass", "Moss", "Lichen", "Crystal Bloom", "Ice Coral", "Ember Frond", "Beetle", "Butterfly", "Snail", "Sand Hopper", "Snow Moth", "Ember Mite", "Burrow Hare", "Ground Bird",
	"Leafy Bush", "Forest Thicket", "Flowering Bush", "Frost Bush", "Pebble Cluster", "Granite Boulder", "Mossy Boulder", "Sandstone Rock", "Basalt Rock", "Woodland Mushrooms",
	"Opuntia Cactus", "Joshua Tree", "Golden Barrel Cactus", "Saguaro Cactus", "Brittlebush", "Ghost Plant", "Fox Tail Agave", "Tumbleweed", "Desert Marigold", "Desert Lily", "Jade Plant", "Aloe Vera", "Chaste Tree", "Cane Cholla", "Mexican Fencepost Cactus"]
const HEIGHTS := [19, 23, 25, 21, 28, 23, 19, 26, 19, 8, 8, 25, 19, 25, 8, 15, 9, 10, 15, 8, 18, 16,
	28, 31, 33, 28, 12, 14, 29, 14, 14, 27, 61, 87, 32, 84, 40, 20, 73, 38, 42, 58, 40, 30, 84, 74, 83]
const ROCKS := ["pebble_cluster", "granite_boulder", "mossy_boulder", "sandstone_rock", "basalt_rock"]
const COVER := ["leafy_bush", "forest_thicket", "flowering_bush", "frost_bush", "pebble_cluster", "granite_boulder", "mossy_boulder", "sandstone_rock", "basalt_rock", "woodland_mushrooms"]
const FLYING := ["butterfly", "snow_moth"]
const MAX_ENTRIES := 1600
const CHUNK_PIXELS := 512.0
const TUMBLE_RADIUS := 19.0
const PLANTS := [
	[["meadow_grass", "wildflower", "berry_shrub"], ["fern", "moss", "wildflower"], ["fern", "broadleaf", "berry_shrub", "moss"], ["lichen", "dry_grass", "crystal_bloom"]],
	[["dry_grass", "reeds"], ["meadow_grass", "broadleaf", "wildflower"], ["broadleaf", "fern", "berry_shrub"], ["reeds", "moss"]],
	[["meadow_grass", "wildflower"], ["fern", "berry_shrub", "broadleaf"], ["lichen", "dry_grass"], ["reeds", "dry_grass"]],
	[["dry_grass", "cactus"], ["cactus", "lichen"], ["reeds", "broadleaf", "wildflower", "berry_shrub"], ["dry_grass", "cactus", "lichen"]],
	[["lichen", "ember_frond"], ["ember_frond", "crystal_bloom"], ["crystal_bloom", "lichen"], ["lichen", "ember_frond"]],
	[["lichen"], ["lichen", "crystal_bloom"], ["dry_grass", "lichen"], ["crystal_bloom", "lichen"]],
	[["frost_grass", "ice_coral"], ["ice_coral", "lichen"], ["ice_coral", "frost_grass"], ["ice_coral"]],
	[["frost_grass", "moss"], ["frost_grass", "moss", "berry_shrub"], ["lichen", "frost_grass"], ["frost_grass", "ice_coral"]]
]
const ANIMALS := [["beetle", "butterfly", "snail", "hare", "ground_bird"], ["beetle", "butterfly", "snail", "ground_bird"], ["beetle", "butterfly", "snail", "hare", "ground_bird"], ["sand_hopper", "beetle"], ["ember_mite"], ["ember_mite"], ["snow_moth"], ["snow_moth", "hare", "ground_bird"]]
const DENSITY := [[0.57, 0.52, 0.58, 0.26], [0.28, 0.50, 0.60, 0.36], [0.54, 0.55, 0.25, 0.28], [0.22, 0.17, 0.55, 0.18], [0.16, 0.12, 0.17, 0.11], [0.08, 0.12, 0.09, 0.12], [0.16, 0.10, 0.20, 0.05], [0.30, 0.45, 0.15, 0.27]]

var frames := {}
var durations := {}
var entries: Array = []
var buckets := {}
var state := {}
var last_player := Vector2.ZERO
var next_id := 1


static func has_item(item: String) -> bool:
	return item in ITEMS


static func animal(species: String) -> bool:
	return species in ["beetle", "butterfly", "snail", "sand_hopper", "snow_moth", "ember_mite", "hare", "ground_bird"]


func load_art() -> void:
	for source: String in [ROOT + "ground_life.json", "res://assets/sprites/ground_cover/ground_cover.json", "res://assets/sprites/expansion/desert_life/atlas.json"]:
		var metadata: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(source))
		for animation: Dictionary in metadata["animations"]:
			var name: String = animation["name"]
			var textures: Array[Texture2D] = []
			for index in range(int(animation["count"])):
				textures.append(Art.texture(source.get_base_dir() + "/" + name + "_%02d.png" % index))
			frames[name] = textures
			durations[name] = animation["durations"]


func icon(item: String) -> Texture2D:
	var index := ITEMS.find(item)
	return frames[SPECIES[index]][0] if index >= 0 else null


static func _clear_ground(world: Dictionary, column: int, y: int, natural_only: bool = true) -> bool:
	var crash: Array = world.get("crash_site_bounds", [])
	if natural_only and crash.size() == 3 and column >= int(crash[0]) + 5 and column <= int(crash[1]) - 5:
		return false
	if column < 2 or column >= WG.WIDTH - 2 or y < 3 or y >= WG.HEIGHT - 2:
		return false
	var grid: PackedByteArray = world["tiles"]
	var ground := WG.tile_at(grid, column, y)
	if ground in [12, 13]:
		return false
	if not WG.is_solid(ground) or (natural_only and ground not in [1, 2, 3, 5, 6, 17]):
		return false
	if WG.tile_at(grid, column, y - 1) not in [0, 7, 8]:
		return false
	if natural_only and world.get("torches", {}).has("%d,%d" % [column, y - 1]):
		return false
	if not natural_only:
		return true
	for x in range(column - 2, column + 3):
		for yy in range(y - 3, y + 2):
			if WG.tile_at(grid, x, yy) in [9, 12, 13, 14, 15, 16, 30, 33, 34, 35, 36, 37] and natural_only:
				return false
	return true


static func populate(world: Dictionary, roof: PackedInt32Array) -> void:
	if int(world.get("ground_life_version", 0)) >= 1:
		populate_cover(world, roof)
		populate_surface_rocks(world, roof)
		populate_desert_flora(world, roof)
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = int(world["seed"]) ^ 0xEC0106
	var climate := clampi(int(world["climate"]), 0, 7)
	var columns: PackedByteArray = world.get("biomes", PackedByteArray())
	var population: Array = []
	var origin: Vector2 = world.get("player_pos", world.get("spawn", Vector2(-10000, 0)))
	for x in range(3, WG.WIDTH - 3):
		var biome := int(columns[x]) if columns.size() == WG.WIDTH else 0
		var y := int(roof[x])
		var roll := rng.randf()
		# One-time legacy seeding avoids the landing/building area and excavations.
		if columns.is_empty() and absf(x * WG.TILE - origin.x) < 14 * WG.TILE:
			continue
		if y > int(world["surface"][x]) + 1 or not _clear_ground(world, x, y):
			continue
		var choices: Array = PLANTS[climate][biome]
		var name: String = choices[rng.randi_range(0, choices.size() - 1)]
		if roll < 0.035 * (0.35 if climate in [4, 5, 6] else 1.0):
			var wildlife: Array = ANIMALS[climate]
			name = wildlife[rng.randi_range(0, wildlife.size() - 1)]
		elif roll > float(DENSITY[climate][biome]):
			continue
		population.append({"id": population.size() + 1, "species": name, "x": float(x * WG.TILE + 8),
			"y": float(y * WG.TILE), "home_x": float(x * WG.TILE + 8), "phase": rng.randf() * TAU,
			"direction": -1 if rng.randf() < 0.5 else 1, "alive": true})
	world["ground_life"] = population
	world["ground_life_version"] = 1
	populate_cover(world, roof)
	populate_surface_rocks(world, roof)
	populate_desert_flora(world, roof)


static func populate_desert_flora(world: Dictionary, roof: PackedInt32Array) -> void:
	if int(world.get("climate", -1)) != 3 or int(world.get("desert_flora_version", 0)) >= 1:
		return
	var population: Array = world.get("ground_life", [])
	var occupied := {}
	var next := 1
	for entry: Dictionary in population:
		next = maxi(next, int(entry["id"]) + 1)
		if not bool(entry.get("alive", true)) or str(entry["species"]) in ROCKS + COVER + DESERT:
			for x in range(floori(float(entry["x"]) / 16) - 2, floori(float(entry["x"]) / 16) + 3):
				occupied[x] = true
	var rng := RandomNumberGenerator.new()
	rng.seed = int(world["seed"]) ^ 0xDE5E47
	var columns: PackedByteArray = world.get("biomes", PackedByteArray())
	var origin: Vector2 = world.get("player_pos", world.get("spawn", Vector2(-10000, 0)))
	var groups := [[0, 2, 3, 4, 7, 8, 13, 14], [1, 2, 5, 6, 10, 11, 13], [4, 6, 8, 9, 10, 11, 12], [0, 1, 3, 5, 7, 9, 13, 14]]
	var seen := {}
	for pass_index in range(2):
		for x in range(8, WG.WIDTH - 8, 2):
			if occupied.has(x) or population.size() >= MAX_ENTRIES or absf(x * 16 - origin.x) < 14 * 16:
				continue
			if pass_index == 0 and rng.randf() > 0.4:
				continue
			var y := int(roof[x])
			if y != int(world["surface"][x]) or not _clear_ground(world, x, y):
				continue
			if absi(int(roof[x - 1]) - y) > 1 or absi(int(roof[x + 1]) - y) > 1:
				continue
			var choices: Array = groups[columns[x] if columns.size() == WG.WIDTH else 0]
			var chosen: int = choices[rng.randi_range(0, choices.size() - 1)]
			if pass_index == 1:
				chosen = -1
				for missing in range(DESERT.size()):
					if not seen.has(missing):
						chosen = missing
						break
				if chosen < 0:
					break
			var height: int = HEIGHTS[32 + chosen]
			var clear := true
			for yy in range(y - ceili(height / 16.0), y):
				for xx in range(x - 1, x + 2):
					if WG.tile_at(world["tiles"], xx, yy) != 0:
						clear = false
			if not clear:
				continue
			population.append({"id": next, "species": DESERT[chosen], "x": float(x * 16 + 8), "y": float(y * 16), "home_x": float(x * 16 + 8), "phase": rng.randf() * TAU, "direction": 1, "alive": true})
			seen[chosen] = true
			next += 1
			for blocked in range(x - (5 if height > 60 else 3), x + (6 if height > 60 else 4)):
				occupied[blocked] = true
	world["ground_life"] = population
	world["desert_flora_version"] = 1


static func rock_choices(climate: int) -> Array:
	# Geology changes the mix; every surface biome can have rocks and boulders.
	match climate:
		0, 1, 2: return ["granite_boulder", "mossy_boulder", "pebble_cluster", "granite_boulder"]
		3: return ["sandstone_rock", "granite_boulder", "pebble_cluster"]
		4: return ["basalt_rock", "basalt_rock", "pebble_cluster"]
		5: return ["granite_boulder", "basalt_rock", "sandstone_rock", "pebble_cluster"]
	return ["granite_boulder", "pebble_cluster", "mossy_boulder"]


static func populate_surface_rocks(world: Dictionary, roof: PackedInt32Array) -> void:
	if int(world.get("surface_rocks_version", 0)) >= 1:
		return
	var population: Array = world.get("ground_life", [])
	var occupied := {}
	var next := 1
	for entry: Dictionary in population:
		next = maxi(next, int(entry["id"]) + 1)
		if str(entry["species"]) in ROCKS or not bool(entry.get("alive", true)):
			for column in range(floori(float(entry["x"]) / 16) - 3, floori(float(entry["x"]) / 16) + 4):
				occupied[column] = true
	var rng := RandomNumberGenerator.new()
	rng.seed = int(world["seed"]) ^ 0xB01D312
	var climate := clampi(int(world["climate"]), 0, 7)
	var choices := rock_choices(climate)
	var origin: Vector2 = world.get("player_pos", world.get("spawn", Vector2(-10000, 0)))
	for x in range(6, WG.WIDTH - 6):
		if rng.randf() > 0.13 or occupied.has(x) or population.size() >= MAX_ENTRIES:
			continue
		if absf(x * 16 - origin.x) < 14 * 16:
			continue
		var y := int(roof[x])
		var natural_y := int(world["surface"][x])
		var sea_ice := climate == 6 and y < natural_y and WG.tile_at(world["tiles"], x, y) == 6
		if y != natural_y and not sea_ice:
			continue
		if int(roof[x - 1]) != y or int(roof[x + 1]) != y:
			continue
		var clear := true
		for support in range(x - 1, x + 2):
			clear = clear and _clear_ground(world, support, y)
		if not clear:
			continue
		var species: String = choices[rng.randi_range(0, choices.size() - 1)]
		population.append({"id": next, "species": species, "x": float(x * 16 + 8), "y": float(y * 16),
			"home_x": float(x * 16 + 8), "phase": rng.randf() * TAU, "direction": 1, "alive": true})
		for column in range(x - 3, x + 4):
			occupied[column] = true
		next += 1
	world["ground_life"] = population
	world["surface_rocks_version"] = 1


static func cover_choices(climate: int, biome: int) -> Array:
	match climate:
		0:
			return [["leafy_bush", "flowering_bush", "pebble_cluster"], ["forest_thicket", "leafy_bush", "mossy_boulder", "woodland_mushrooms"],
				["forest_thicket", "forest_thicket", "mossy_boulder", "woodland_mushrooms"], ["granite_boulder", "pebble_cluster", "leafy_bush"]][biome]
		1:
			return ["leafy_bush", "flowering_bush", "mossy_boulder"] if biome in [1, 2] else ["pebble_cluster", "sandstone_rock", "leafy_bush"]
		2:
			return [["leafy_bush", "flowering_bush", "pebble_cluster"], ["forest_thicket", "leafy_bush", "mossy_boulder", "woodland_mushrooms"],
				["granite_boulder", "pebble_cluster", "leafy_bush"], ["sandstone_rock", "pebble_cluster"]][biome]
		3:
			return ["leafy_bush", "flowering_bush", "pebble_cluster"] if biome == 2 else ["sandstone_rock", "sandstone_rock", "pebble_cluster"]
		4: return ["basalt_rock", "basalt_rock", "pebble_cluster"]
		5: return ["granite_boulder", "sandstone_rock", "pebble_cluster"]
		6: return ["frost_bush", "granite_boulder", "pebble_cluster"]
	return ["frost_bush", "frost_bush", "mossy_boulder" if biome == 1 else "granite_boulder"]


static func populate_cover(world: Dictionary, roof: PackedInt32Array) -> void:
	if int(world.get("ground_cover_version", 0)) >= 1:
		return
	var population: Array = world.get("ground_life", [])
	var columns: PackedByteArray = world.get("biomes", PackedByteArray())
	var climate := clampi(int(world["climate"]), 0, 7)
	var rng := RandomNumberGenerator.new()
	rng.seed = int(world["seed"]) ^ 0xC0BE12
	var next := 1
	var cleared := {}
	for entry: Dictionary in population:
		next = maxi(next, int(entry["id"]) + 1)
		if not bool(entry.get("alive", true)):
			for x in range(floori(float(entry["x"]) / 16) - 2, floori(float(entry["x"]) / 16) + 3):
				cleared[x] = true
	var origin: Vector2 = world.get("player_pos", world.get("spawn", Vector2(-10000, 0)))
	for x in range(6, WG.WIDTH - 6, 3):
		var chance := 0.62 if climate in [0, 1, 2, 7] else 0.38
		if rng.randf() > chance or cleared.has(x) or population.size() >= MAX_ENTRIES:
			continue
		if columns.is_empty() and absf(x * 16 - origin.x) < 14 * 16:
			continue
		var y := int(roof[x])
		if y > int(world["surface"][x]) + 1 or not _clear_ground(world, x, y):
			continue
		var biome := int(columns[x]) if columns.size() == WG.WIDTH else 0
		var choices := cover_choices(climate, biome)
		var species: String = choices[rng.randi_range(0, choices.size() - 1)]
		# Broad bases need level support; shrubs can overhang a gentle step.
		var tolerance := 0 if species in ROCKS else 1
		if absi(int(roof[x - 1]) - y) > tolerance or absi(int(roof[x + 1]) - y) > tolerance:
			continue
		population.append({"id": next, "species": species, "x": float(x * 16 + 8), "y": float(y * 16),
			"home_x": float(x * 16 + 8), "phase": rng.randf() * TAU, "direction": 1, "alive": true})
		next += 1
	world["ground_life"] = population
	world["ground_cover_version"] = 1


func reset(game) -> void:
	populate(game.world, game.environment.roof)
	entries = game.world.get("ground_life", [])
	buckets.clear()
	state.clear()
	next_id = 1
	last_player = game.player_pos
	for entry: Dictionary in entries:
		next_id = maxi(next_id, int(entry["id"]) + 1)
		if bool(entry.get("alive", true)) and str(entry["species"]) in SPECIES:
			_index(entry)


func _index(entry: Dictionary) -> void:
	var chunk := floori(float(entry["x"]) / CHUNK_PIXELS)
	if not buckets.has(chunk):
		buckets[chunk] = []
	buckets[chunk].append(entry)
	state[int(entry["id"])] = {"bend": 0.0, "velocity": 0.0, "alert": 0.0, "chunk": chunk, "lift": 0.0, "moving": false}


func visible(game) -> Array:
	var result: Array = []
	for chunk in range(floori((game.camera_pos.x - 48) / CHUNK_PIXELS), floori((game.camera_pos.x + 1328) / CHUNK_PIXELS) + 1):
		for entry: Dictionary in buckets.get(chunk, []):
			if bool(entry.get("alive", false)) and float(entry["x"]) >= game.camera_pos.x - 32 \
				and float(entry["x"]) <= game.camera_pos.x + 1312 and float(entry["y"]) >= game.camera_pos.y - 32 and float(entry["y"]) <= game.camera_pos.y + 768:
				result.append(entry)
	return result


func position(entry: Dictionary) -> Vector2:
	var runtime: Dictionary = state.get(int(entry["id"]), {})
	return Vector2(float(entry["x"]), float(entry["y"]) - float(runtime.get("lift", 0)))


static func wind_bend(species: String, phase: float, clock: float, wind: float) -> float:
	if species in ROCKS:
		return 0.0
	var height := float(HEIGHTS[SPECIES.find(species)]) / 28.0
	return (wind * 0.035 + sin(clock * 1.8 + phase) * minf(1.3, absf(wind) * 0.035)) * height


static func deformation_y(y: float, bend: float) -> float:
	return bend * pow(1.0 - y / 32.0, 2)


func update(game, delta: float) -> void:
	var travel: Vector2 = game.player_pos - last_player
	last_player = game.player_pos
	var speed := travel.x / maxf(delta, 0.001) if travel.length() < 64 else 0.0
	var feet: Vector2 = game.player_pos + Vector2(8, 28)
	var wind: float = game._wind_speed()
	for entry: Dictionary in visible(game):
		var runtime: Dictionary = state[int(entry["id"])]
		var dx := float(entry["x"]) - feet.x
		var dy := float(entry["y"]) - feet.y
		var contact := absf(dx) < 25 and absf(dy) < 30 and (absf(speed) > 2 or (travel.length() > 0.1 and travel.length() < 64))
		if str(entry["species"]) in ROCKS:
			contact = false
		var target := clampf(speed / 45.0, -7, 7) * (1.0 - absf(dx) / 25.0) if contact else 0.0
		if contact and absf(target) < 0.1:
			target = (1.0 if dx >= 0 else -1.0) * 6.0
		var remaining := minf(delta, 0.2)
		while remaining > 0.0001:
			var step := minf(remaining, 1.0 / 60)
			runtime["velocity"] = float(runtime["velocity"]) + ((target - float(runtime["bend"])) * 65 - float(runtime["velocity"]) * 12) * step
			runtime["bend"] = clampf(float(runtime["bend"]) + float(runtime["velocity"]) * step, -9, 9)
			remaining -= step
		var species: String = entry["species"]
		if species == "tumbleweed":
			_update_tumbleweed(game, entry, runtime, wind, delta)
		elif animal(species):
			_update_animal(game, entry, runtime, feet, wind, delta)
		elif not _supported(game, entry):
			_harvest(game, entry)


func _tumble_blocked(grid: PackedByteArray, feet: Vector2) -> bool:
	var center := feet - Vector2(0, TUMBLE_RADIUS)
	if center.x < TUMBLE_RADIUS or center.x > WG.WIDTH * WG.TILE - TUMBLE_RADIUS or feet.y > WG.HEIGHT * WG.TILE:
		return true
	for y in range(floori((center.y - TUMBLE_RADIUS) / WG.TILE), floori(feet.y / WG.TILE) + 1):
		for x in range(floori((center.x - TUMBLE_RADIUS) / WG.TILE), floori((center.x + TUMBLE_RADIUS) / WG.TILE) + 1):
			if WG.is_solid(WG.tile_at(grid, x, y)):
				var nearest := Vector2(clampf(center.x, x * WG.TILE, (x + 1) * WG.TILE), clampf(center.y, y * WG.TILE, (y + 1) * WG.TILE))
				if center.distance_squared_to(nearest) < TUMBLE_RADIUS * TUMBLE_RADIUS - 0.01:
					return true
	return false


func _update_tumbleweed(game, entry: Dictionary, runtime: Dictionary, wind: float, delta: float) -> void:
	var grid: PackedByteArray = game.world["tiles"]
	var at := Vector2(float(entry["x"]), float(entry["y"]))
	var vx := float(entry.get("roll_vx", 0.0))
	var vy := float(entry.get("roll_vy", 0.0))
	var angle := float(entry.get("roll_angle", 0.0))
	# Older stationary plants could overhang a step; lift those onto the surface.
	if _tumble_blocked(grid, at):
		for rise in range(1, WG.TILE * 2 + 1):
			if not _tumble_blocked(grid, at - Vector2(0, rise)):
				at.y -= rise
				break
	var remaining := minf(delta, 0.2)
	while remaining > 0.0001:
		var step := minf(remaining, 1.0 / 120.0)
		remaining -= step
		var grounded := _tumble_blocked(grid, at + Vector2(0, 0.7))
		vx = move_toward(vx, clampf(wind * 0.85, -110.0, 110.0), step * 85.0)
		var next := at + Vector2(vx * step, 0)
		if _tumble_blocked(grid, next):
			# Wind lifts the loose ball over one-block ledges, but not walls.
			if grounded and absf(vx) > 1.0 and not _tumble_blocked(grid, next - Vector2(0, WG.TILE)):
				vy = -150.0
			vx = 0.0
		else:
			angle += (next.x - at.x) / TUMBLE_RADIUS
			at.x = next.x
		vy = minf(vy + 400.0 * step, 260.0)
		next = at + Vector2(0, vy * step)
		if _tumble_blocked(grid, next):
			# Resolve to the surface without sinking or tunnelling through blocks.
			var low := 0.0
			var high := 1.0
			for iteration in range(8):
				var middle := (low + high) * 0.5
				if _tumble_blocked(grid, at.lerp(next, middle)):
					high = middle
				else:
					low = middle
			at = at.lerp(next, low)
			vy = 0.0
		else:
			at = next
	entry["x"] = at.x
	entry["y"] = at.y
	entry["roll_vx"] = vx
	entry["roll_vy"] = vy
	entry["roll_angle"] = fposmod(angle, TAU)
	runtime["moving"] = absf(vx) > 0.5 or absf(vy) > 0.5
	_reindex_moving(entry, runtime)
	if game.lava_sim.amount_at(Vector2i(floor((at - Vector2(0, 8)) / WG.TILE))) > 0:
		_harvest(game, entry)


func _supported(game, entry: Dictionary) -> bool:
	var tile := Vector2i(floor(Vector2(float(entry["x"]), float(entry["y"])) / WG.TILE))
	return WG.is_solid(WG.tile_at(game.world["tiles"], tile.x, tile.y)) \
		and game.lava_sim.amount_at(tile - Vector2i(0, 1)) == 0


func _ground(game, x: float, old_y: float) -> float:
	var column := floori(x / WG.TILE)
	var row := roundi(old_y / WG.TILE)
	for y in range(maxi(2, row - 1), mini(WG.HEIGHT - 2, row + 4)):
		if _clear_ground(game.world, column, y, false) and game.lava_sim.amount_at(Vector2i(column, y - 1)) == 0:
			return float(y * WG.TILE)
	return -1.0


func _update_animal(game, entry: Dictionary, runtime: Dictionary, feet: Vector2, wind: float, delta: float) -> void:
	var species: String = entry["species"]
	var distance := Vector2(float(entry["x"]), float(entry["y"])).distance_to(feet)
	runtime["alert"] = maxf(0, float(runtime["alert"]) - delta)
	runtime["turn_lock"] = maxf(0, float(runtime.get("turn_lock", 0)) - delta)
	runtime["blocked_pause"] = maxf(0, float(runtime.get("blocked_pause", 0)) - delta)
	if distance < 55:
		if float(runtime["turn_lock"]) <= 0 and absf(feet.x - float(entry["x"])) > 8:
			entry["direction"] = -1 if feet.x > float(entry["x"]) else 1
		runtime["alert"] = 1.5
	var moving := (float(runtime["alert"]) > 0 or sin(game.animation_clock * 0.6 + float(entry["phase"])) > 0.2) and float(runtime["blocked_pause"]) <= 0
	runtime["moving"] = moving
	var speed := 10.0
	match species:
		"snail": speed = 3.0
		"hare": speed = 23.0
		"ground_bird": speed = 17.0
		"butterfly", "snow_moth": speed = 14.0
	if float(runtime["alert"]) > 0:
		speed *= 2.7
	var old_x := float(entry["x"])
	if absf(old_x - float(entry["home_x"])) > 100 and float(runtime["alert"]) <= 0 and float(runtime["turn_lock"]) <= 0:
		entry["direction"] = -1 if old_x > float(entry["home_x"]) else 1
	var drift := wind * 0.12 if species in FLYING else wind * 0.01
	var next_x := clampf(old_x + ((speed * int(entry["direction"]) if moving else 0.0) + drift) * delta, 40, WG.WIDTH * WG.TILE - 40)
	var ground := _ground(game, next_x, float(entry["y"]))
	if ground >= 0:
		entry["x"] = next_x
		entry["y"] = ground
	else:
		var reverse_ground := _ground(game, old_x - int(entry["direction"]) * maxf(speed * delta, 2), float(entry["y"]))
		if reverse_ground >= 0 and float(runtime["turn_lock"]) <= 0:
			entry["direction"] = -int(entry["direction"])
			runtime["turn_lock"] = 0.7
		else:
			runtime["blocked_pause"] = 0.35
			runtime["turn_lock"] = maxf(float(runtime["turn_lock"]), 0.35)
		runtime["moving"] = false
		if not _supported(game, entry):
			entry["y"] = minf(WG.HEIGHT * WG.TILE - 32, float(entry["y"]) + delta * 75)
	if species in FLYING:
		runtime["lift"] = 12.0 + sin(game.animation_clock * 2.5 + float(entry["phase"])) * 4.0
	elif bool(runtime["moving"]) and species in ["hare", "sand_hopper"]:
		runtime["lift"] = absf(sin(game.animation_clock * (12.0 if float(runtime["alert"]) > 0 else 7.0) + float(entry["phase"]))) * (8 if species == "hare" else 3)
	else:
		runtime["lift"] = 0.0
	_reindex_moving(entry, runtime)


func _reindex_moving(entry: Dictionary, runtime: Dictionary) -> void:
	var chunk := floori(float(entry["x"]) / CHUNK_PIXELS)
	if chunk != int(runtime["chunk"]):
		buckets[int(runtime["chunk"])].erase(entry)
		if not buckets.has(chunk):
			buckets[chunk] = []
		buckets[chunk].append(entry)
		runtime["chunk"] = chunk


func draw_life(game) -> void:
	var wind: float = game._wind_speed()
	var population := visible(game)
	# Bushes/rocks sit behind small plants, with critters visible in front.
	for layer in range(3):
		for entry: Dictionary in population:
			var species: String = entry["species"]
			var order := 2 if animal(species) else (0 if species in COVER or species == "berry_shrub" else 1)
			if order == layer:
				_draw_entry(game, entry, wind)


func _draw_entry(game, entry: Dictionary, wind: float) -> void:
	var species: String = entry["species"]
	var runtime: Dictionary = state[int(entry["id"])]
	if species == "tumbleweed":
		# Rotate the existing Aseprite ball around its painted centre, not the canvas centre.
		var texture: Texture2D = frames[species][0]
		game.draw_set_transform(position(entry) - game.camera_pos - Vector2(0, 19), float(entry.get("roll_angle", 0.0)))
		game.draw_texture(texture, Vector2(-texture.get_width() * 0.5, -texture.get_height() + 19))
		game.draw_set_transform(Vector2.ZERO)
		return
	var duration := float(durations[species][0])
	var animated := not animal(species) or bool(runtime["moving"]) or species in FLYING
	var frame := posmod(floori((game.animation_clock + float(entry["phase"])) / duration), frames[species].size()) if animated else 0
	var bend := wind_bend(species, float(entry["phase"]), game.animation_clock, wind) + float(runtime["bend"])
	draw_sprite(game, frames[species][frame], position(entry) - game.camera_pos, bend, animal(species) and int(entry["direction"]) < 0)


static func draw_sprite(canvas: CanvasItem, texture: Texture2D, at: Vector2, bend: float, mirrored: bool = false) -> void:
	var width := float(texture.get_width())
	var height := float(texture.get_height())
	for strip in range(4):
		var y0 := strip * height / 4.0
		var y1 := y0 + height / 4.0
		var dx0 := bend * pow(1.0 - y0 / height, 2)
		var dx1 := bend * pow(1.0 - y1 / height, 2)
		var points := PackedVector2Array([at + Vector2(-width / 2 + dx0, y0 - height), at + Vector2(width / 2 + dx0, y0 - height), at + Vector2(width / 2 + dx1, y1 - height), at + Vector2(-width / 2 + dx1, y1 - height)])
		var u0 := 1.0 if mirrored else 0.0
		var u1 := 0.0 if mirrored else 1.0
		var uv := PackedVector2Array([Vector2(u0, y0 / height), Vector2(u1, y0 / height), Vector2(u1, y1 / height), Vector2(u0, y1 / height)])
		canvas.draw_polygon(points, PackedColorArray([Color.WHITE, Color.WHITE, Color.WHITE, Color.WHITE]), uv, texture)


func harvest_at(game, point: Vector2) -> bool:
	var closest: Dictionary = {}
	var best := 1000.0
	for entry: Dictionary in visible(game):
		var at := position(entry)
		var height := maxf(12, HEIGHTS[SPECIES.find(str(entry["species"]))])
		var width := float(frames[str(entry["species"])][0].get_width())
		var hitbox := Rect2(at + Vector2(-width / 2, -height - 2), Vector2(width, height + 4))
		if hitbox.has_point(point) and point.distance_squared_to(at - Vector2(0, height * 0.5)) < best:
			closest = entry
			best = point.distance_squared_to(at - Vector2(0, height * 0.5))
	if closest.is_empty():
		return false
	if str(closest["species"]) in ROCKS:
		if game.Tools.family(game.equipped_tool) != "Pickaxe":
			game._show_notice("Equip a pickaxe to break ground rocks")
			return true
		var hits := maxi(1, (2 if str(closest["species"]) == "pebble_cluster" else 5) - game.Tools.tier(game.equipped_tool) + 1)
		closest["work"] = float(closest.get("work", 0)) + 1.0 / hits
		if float(closest["work"]) < 0.99999:
			game.mining_feedback_tile = Vector2i(floor((position(closest) - Vector2(0, 8)) / WG.TILE))
			game.mining_feedback_progress = float(closest["work"])
			game.mining_feedback_timer = 1.0
			if game.sound != null:
				game.sound.impact(3, position(closest))
			return true
		game.mining_feedback_timer = 0.0
		game._wear_pickaxe(game.equipped_tool)
	_harvest(game, closest)
	return true


func _harvest(game, entry: Dictionary) -> void:
	if not bool(entry.get("alive", false)):
		return
	entry["alive"] = false
	var index := SPECIES.find(str(entry["species"]))
	game._drop_item(ITEMS[index], 1, Vector2i(floor(position(entry) / WG.TILE)))
	if state.has(int(entry["id"])):
		buckets[int(state[int(entry["id"])]["chunk"])].erase(entry)
		state.erase(int(entry["id"]))
	if game.sound != null:
		game.sound.impact(3 if str(entry["species"]) in ROCKS else 8, Vector2(float(entry["x"]), float(entry["y"])))


func place(game, item: String, tile: Vector2i) -> bool:
	var index := ITEMS.find(item)
	if entries.size() >= MAX_ENTRIES:
		entries = entries.filter(func(entry): return bool(entry.get("alive", false)))
		game.world["ground_life"] = entries
	if index < 0 or entries.size() >= MAX_ENTRIES:
		return false
	# Both the empty cell and the top of its support tile are valid targets.
	var floor_tile := tile if WG.is_solid(WG.tile_at(game.world["tiles"], tile.x, tile.y)) else tile + Vector2i(0, 1)
	if not _clear_ground(game.world, floor_tile.x, floor_tile.y, false):
		return false
	var at := Vector2(floor_tile * WG.TILE) + Vector2(8, 0)
	for entry: Dictionary in buckets.get(floori(at.x / CHUNK_PIXELS), []):
		if bool(entry.get("alive", false)) and Vector2(float(entry["x"]), float(entry["y"])).distance_to(at) < 12:
			return false
	var entry := {"id": next_id, "species": SPECIES[index], "x": at.x, "y": at.y, "home_x": at.x,
		"phase": fposmod(next_id * 2.39996, TAU), "direction": game.facing, "alive": true}
	next_id += 1
	entries.append(entry)
	_index(entry)
	game.world["ground_life"] = entries
	return true
