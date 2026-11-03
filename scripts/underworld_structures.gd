extends RefCounted
# Real, mineable terrain assembled from the existing Aseprite block set.
const W := 1200
const H := 1440
const DECK := H - 32
const SEA := H - 18

static func apply(world: Dictionary, legacy: bool = true) -> void:
	if int(world.get("underworld_structures_version", 0)) >= 1: return
	var grid: PackedByteArray = world["tiles"]
	if grid.size() != W * H: return
	var changed := {}
	if legacy:
		# Only remove a whole old pillar when its entire footprint is untouched.
		for start in range(65, W - 8, 137):
			var pristine := true
			for key in world.get("torches", {}):
				var parts: PackedStringArray = key.split(",")
				if Rect2i(start - 2, H - 59, 12, 59).has_point(Vector2i(int(parts[0]), int(parts[1]))): pristine = false
			for x in range(start, start + 8):
				for y in range(H - 57, H - 3):
					var expected := 17 if y > H - 57 + absi(posmod(x, 137) - 69) * 2 else (11 if y >= SEA else 0)
					if grid[y * W + x] != expected: pristine = false
			if not pristine: continue
			for x in range(start, start + 8):
				for y in range(H - 57, H - 3):
					if grid[y * W + x] == 17: put(grid, changed, x, y, 11 if y >= SEA else 0)
	var rng := RandomNumberGenerator.new(); rng.seed = int(world["seed"]) ^ 0xF047
	var forts: Array = []
	if not world.has("torches"): world["torches"] = {}
	if not world.has("chest_contents"): world["chest_contents"] = {}
	# Reserve footprints first, so bridges never obstruct fortress placement.
	for sector in range(5):
		var center := 120 + sector * 235 + rng.randi_range(-22, 22)
		var width := rng.randi_range(44, 60)
		var height := rng.randi_range(14, 18)
		var bounds := Rect2i(center - width / 2, DECK - height - 2, width, H - 3 - (DECK - height - 2))
		if clear_site(world, bounds, changed): forts.append({"x": bounds.position.x, "width": width, "roof": DECK - height})
	# Segmented spans let migration skip edited areas without destroying builds.
	for x in range(12, W - 12, 28):
		var width := mini(28, W - 12 - x)
		if not clear_site(world, Rect2i(x, DECK - 4, width, H - 3 - (DECK - 4)), changed): continue
		for dx in range(width):
			put(grid, changed, x + dx, DECK, 17)
			put(grid, changed, x + dx, DECK + 1, 3)
			# Short arch haunches rise toward the piers, leaving open lava below.
			var edge := mini(dx, width - 1 - dx)
			for dy in range(maxi(0, 6 - edge)):
				put(grid, changed, x + dx, DECK + 2 + dy, 17)
			if dx < 2:
				for y in range(DECK + 2, H - 3): put(grid, changed, x + dx, y, 17)
		world["torches"]["%d,%d" % [x + width / 2, DECK - 1]] = true
	for fort: Dictionary in forts:
		var left := int(fort.x); var width := int(fort.width); var roof := int(fort.roof)
		var upper := roof + 8
		for dx in range(width):
			var x := left + dx
			for y in range(roof, DECK + 2):
				var shell := y in [roof, roof + 1, DECK, DECK + 1] or dx < 2 or dx >= width - 2
				var floor_here := y == upper and dx >= 10 and dx < width - 10
				var door := (dx < 2 or dx >= width - 2) and y >= DECK - 4 and y < DECK
				put(grid, changed, x, y, (17 if y == roof or y == DECK or dx < 2 or dx >= width - 2 else 3) if (shell or floor_here) and not door else 0)
			# Low broken battlements, rather than tall towers.
			if posmod(dx, 6) < 3:
				put(grid, changed, x, roof - 1, 17)
				if rng.randf() > 0.28: put(grid, changed, x, roof - 2, 17)
			if dx < 3 or dx >= width - 3:
				for y in range(DECK + 2, H - 3): put(grid, changed, x, y, 17)
		# Stair flights connect the entrance hall to the upper gallery.
		for step in range(DECK - upper):
			for y in range(DECK - step - 1, DECK):
				put(grid, changed, left + 3 + step, y, 3)
				put(grid, changed, left + width - 4 - step, y, 3)
		for dx in range(12, width - 10, 9):
			world["torches"]["%d,%d" % [left + dx, DECK - 1]] = true
			world["torches"]["%d,%d" % [left + dx, upper - 1]] = true
		var chest := Vector2i(left + width / 2, DECK - 1)
		put(grid, changed, chest.x, chest.y, 30)
		world["chest_contents"]["%d,%d" % [chest.x, chest.y]] = {"Iron Ore": rng.randi_range(5, 10), "Gold Ore": rng.randi_range(3, 7), "Crystal": rng.randi_range(1, 3)}
	# Packed arrays are synchronized before the fluid solvers bind this world.
	for field in ["water", "rain_water", "lava", "lava_cooling", "snow"]:
		var amounts: PackedByteArray = world.get(field, PackedByteArray())
		if amounts.size() != grid.size(): continue
		for index in changed:
			amounts[index] = 255 if field == "lava" and grid[index] == 11 else 0
		world[field] = amounts
	for entry: Dictionary in world.get("cave_life", []):
		if int(entry.y) < H - 80: continue
		var index := int(entry.y) * W + int(entry.x)
		var direction := -1 if int(entry.kind) in [0, 1, 4] else 1
		if grid[index] != 0 or grid[index - direction * W] not in [2, 3, 5, 6, 17]: entry.alive = false
	# Torches obscured by a generated wall/stair no longer belong in the scene.
	for key in world["torches"].keys():
		var parts: PackedStringArray = key.split(",")
		var index := int(parts[1]) * W + int(parts[0])
		if changed.has(index) and grid[index] != 0: world["torches"].erase(key)
	world["tiles"] = grid
	world["underworld_forts"] = forts
	world["underworld_structures_version"] = 1

static func clear_site(world: Dictionary, rect: Rect2i, restored: Dictionary) -> bool:
	var grid: PackedByteArray = world["tiles"]
	var lava: PackedByteArray = world.get("lava", PackedByteArray())
	for y in range(rect.position.y, rect.end.y):
		for x in range(rect.position.x, rect.end.x):
			var index := y * W + x
			if grid[index] != (11 if y >= SEA else 0): return false
			if lava.size() == grid.size() and y >= SEA and lava[index] != 255 and not restored.has(index): return false
	for key in world.get("torches", {}):
		var parts: PackedStringArray = key.split(",")
		if rect.has_point(Vector2i(int(parts[0]), int(parts[1]))): return false
	return true

static func put(grid: PackedByteArray, changed: Dictionary, x: int, y: int, id: int) -> void:
	var index := y * W + x
	grid[index] = id
	changed[index] = true
