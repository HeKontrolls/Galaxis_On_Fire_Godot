extends RefCounted

const WG = preload("res://scripts/world_gen.gd")
const HALF_WIDTH := 12

static func prepare(game, progress: Dictionary, fresh: bool = false) -> bool:
	if int(progress.get("crash_site_version", 0)) >= 1:
		game.world["crash_site_bounds"] = progress.get("crash_site_bounds", [])
		return true
	var world: Dictionary = game.world
	var grid: PackedByteArray = world["tiles"]
	var natural := PackedByteArray()
	if not fresh:
		# Existing saves: only use terrain that still matches untouched generation.
		natural = WG.generate(int(world["seed"]), int(world["climate"]), false)["tiles"]
	var origin := clampi(int(float(progress["ship"][0]) / 16), 20, WG.WIDTH - 21)
	var protected: Array[Vector2] = []
	if not fresh:
		protected.append(world["spawn"])
		protected.append(world.get("player_pos", world["spawn"]))
	if not fresh and world.has("npc"):
		protected.append(Vector2(world["npc"]["x"], world["npc"]["y"]))
	for creature: Dictionary in world.get("creatures", []):
		if bool(creature.get("alive", false)):
			protected.append(Vector2(creature["x"], creature["y"]))
	var selected := -1
	var floor_y := 0
	for distance in range(0, WG.WIDTH, 4):
		for direction in [-1, 1]:
			var center: int = origin + distance * direction
			if center < 20 or center >= WG.WIDTH - 20:
				continue
			var occupied := false
			for point: Vector2 in protected:
				if absf(point.x / 16 - center) < HALF_WIDTH + 4:
					occupied = true
			if occupied:
				continue
			var low := WG.HEIGHT
			var high := 0
			for x in range(center - HALF_WIDTH, center + HALF_WIDTH + 1):
				var ground: int = game._walkable_y(x) / 16
				low = mini(low, ground)
				high = maxi(high, ground)
			if low < 14 or high - low > 4 or high >= WG.HEIGHT - 12:
				continue
			var base := high + 1
			var clear := true
			# Avoid cutting trees, wet basins, crops, objects, or old excavations.
			for x in range(center - HALF_WIDTH - 3, center + HALF_WIDTH + 4):
				for y in range(maxi(0, low - 24), base + 7):
					var id := WG.tile_at(grid, x, y)
					if id not in [0, 1, 2, 3, 5, 6] or world.get("torches", {}).has("%d,%d" % [x, y]):
						clear = false
						break
					if not natural.is_empty() and id != WG.tile_at(natural, x, y):
						clear = false
						break
					for fluid: String in ["water", "lava"]:
						var amounts: PackedByteArray = world.get(fluid, PackedByteArray())
						if amounts.size() == grid.size() and amounts[y * WG.WIDTH + x] > 0:
							clear = false
				if not clear:
					break
			if not clear:
				continue
			selected = center
			floor_y = base
			break
		if selected >= 0:
			break
	if selected < 0:
		return false
	var surface: PackedInt32Array = world["surface"]
	for x in range(selected - HALF_WIDTH, selected + HALF_WIDTH + 1):
		var distance := absi(x - selected)
		var top := floor_y
		if distance > 6:
			var edge := selected + (HALF_WIDTH if x > selected else -HALF_WIDTH)
			var amount := (distance - 6) / 6.0
			top = roundi(lerpf(floor_y, int(surface[edge]), amount)) - int([0, 1, 2, 2, 1, 0, 0][distance - 6])
		for y in range(floor_y - 12, floor_y + 7):
			var material := 0
			if y >= top:
				material = 2
				if y == top and distance in [8, 9, 11]:
					material = 3
			WG.set_tile(grid, x, y, material)
		surface[x] = top
	world["tiles"] = grid
	world["surface"] = surface
	# Old natural ground-cover entries must not float in the newly cleared patch.
	for entry: Dictionary in world.get("ground_life", []):
		if absf(float(entry["x"]) / 16 - selected) <= HALF_WIDTH + 1:
			entry["alive"] = false
	progress["ship"] = [selected * 16 + 8, floor_y * 16]
	progress["pod_layout_version"] = 1
	progress["crash_site_version"] = 1
	progress["crash_site_bounds"] = [selected - HALF_WIDTH, selected + HALF_WIDTH, floor_y]
	world["crash_site_bounds"] = progress["crash_site_bounds"]
	if fresh:
		world["spawn"] = Vector2(selected * 16 - 48, floor_y * 16 - 28)
		world["player_pos"] = world["spawn"]
		if world.has("npc"):
			var npc_x := (selected + 10) * 16
			world["npc"]["x"] = float(npc_x)
			world["npc"]["y"] = float(game._walkable_y(selected + 10) - 29)
			world["npc"]["home_x"] = float(npc_x)
	return true
