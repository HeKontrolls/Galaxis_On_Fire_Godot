extends RefCounted

const WG = preload("res://scripts/world_gen.gd")
var values := PackedFloat32Array()
var meshes := {}
var stable_views := {}
var vertices := PackedVector2Array()
var colors := PackedColorArray()
var indices := PackedInt32Array()
var grid := PackedByteArray()
var clock := 0.0
var molten := false
var fluid


func _value(x: int, y: int) -> float:
	if x < 0 or y < 0 or x >= WG.WIDTH or y >= WG.HEIGHT:
		return 0.0
	return values[y * WG.WIDTH + x]


func _supported(x: int, y: int) -> bool:
	if x < 0 or x >= WG.WIDTH or y + 1 >= WG.HEIGHT:
		return true
	var below := (y + 1) * WG.WIDTH + x
	return WG.is_solid(grid[below]) or grid[below] == fluid.blocked_id or values[below] >= 254.0


func _body_color(index: int) -> Color:
	if not molten:
		return Color(0.14, 0.40, 0.67, 0.65)
	var cooled: float = fluid.cooling_fraction(index)
	return Color("ef4912").lerp(Color("493342"), cooled * 0.75)


func _quad(a: Vector2, b: Vector2, c: Vector2, d: Vector2, ca: Color, cb: Color, cc: Color, cd: Color) -> void:
	var index := vertices.size()
	vertices.append_array(PackedVector2Array([a, b, c, d]))
	colors.append_array(PackedColorArray([ca, cb, cc, cd]))
	indices.append_array(PackedInt32Array([index, index + 1, index + 2, index + 1, index + 3, index + 2]))


func _edge_height(x: int, y: int, neighbor: int, height: float) -> float:
	var amount := _value(neighbor, y)
	if amount > 0.1 and _supported(neighbor, y):
		return (height + amount * WG.TILE / 255.0) * 0.5
	if amount > 0.01:
		return height
	if WG.is_solid(WG.tile_at(grid, neighbor, y)) or WG.tile_at(grid, neighbor, y) == fluid.blocked_id:
		return height
	return height * 0.55


func _pool(x: int, y: int, amount: float) -> void:
	var index := y * WG.WIDTH + x
	var height := amount * WG.TILE / 255.0
	var hs := [_edge_height(x, y, x - 1, height), height, _edge_height(x, y, x + 1, height)]
	var base := _body_color(index)
	base.a *= clampf(amount / 10.0, 0, 1)
	var surface := base.lightened(0.16 if molten else 0.13)
	var exposed := _value(x, y - 1) < 0.1
	for half in range(2):
		var xa := float(x * WG.TILE + half * 8)
		var xb := xa + 8
		var bottom := float((y + 1) * WG.TILE)
		var wave_a := sin(clock * (0.8 if molten else 1.7) + xa * 0.035) * minf(0.2, hs[half] * 0.04) if exposed else 0.0
		var wave_b := sin(clock * (0.8 if molten else 1.7) + xb * 0.035) * minf(0.2, hs[half + 1] * 0.04) if exposed else 0.0
		var ya: float = bottom - hs[half] + wave_a
		var yb: float = bottom - hs[half + 1] + wave_b
		var band_a := minf(1.8, hs[half] * 0.45) if exposed else 0.0
		var band_b := minf(1.8, hs[half + 1] * 0.45) if exposed else 0.0
		if exposed:
			_quad(Vector2(xa, ya), Vector2(xb, yb), Vector2(xa, ya + band_a), Vector2(xb, yb + band_b), surface, surface, base, base)
		_quad(Vector2(xa, ya + band_a), Vector2(xb, yb + band_b), Vector2(xa, bottom), Vector2(xb, bottom), base, base, base, base)


func _flow_section(x: int, boundary: int, center: float, width: float) -> Vector2:
	var ends := Vector2(center - width * 0.5, center + width * 0.5)
	# Connected columns share the same edge rather than leaving the gap
	# between two independently narrowed ribbons. Both adjoining rows use
	# this section so changes of width cannot leave a seam at a tile border.
	for side: int in [-1, 1]:
		var neighbor := x + side
		var connected := false
		for row in [boundary - 1, boundary]:
			if _value(neighbor, row) > 0.01 and not WG.is_solid(WG.tile_at(grid, neighbor, row)):
				connected = true
		if connected:
			if side < 0: ends.x = x * 16.0
			else: ends.y = (x + 1) * 16.0
	return ends


func _stream(x: int, y: int, amount: float, supported: bool) -> void:
	var epsilon := 0.01 if molten else 0.1
	var above := _value(x, y - 1)
	var below := _value(x, y + 1)
	var top_amount := (amount + above) * 0.5 if above > epsilon else amount
	var bottom_amount := (amount + below) * 0.5 if below > epsilon and not supported else amount
	var wa := 3.5 + sqrt(clampf(top_amount / 255.0, 0, 1)) * 11.5
	var wb := 3.5 + sqrt(clampf(bottom_amount / 255.0, 0, 1)) * 11.5
	var ya := float(y * WG.TILE)
	var yb := float((y + 1) * WG.TILE) - (amount * WG.TILE / 255.0 if supported else 0.0)
	if above <= epsilon:
		# A ledge-fed stream starts at its pool's surface, rather than at
		# the top of an almost-empty tile above it.
		var feed := amount
		for neighbor in [x - 1, x + 1]:
			if _supported(neighbor, y):
				feed = maxf(feed, _value(neighbor, y))
		ya = maxf(ya, float((y + 1) * WG.TILE) - feed * WG.TILE / 255.0)
	var ca := x * WG.TILE + 8.0 + sin(ya * 0.08 - clock * (0.8 if molten else 2.8)) * 0.3
	var cb := x * WG.TILE + 8.0 + sin(yb * 0.08 - clock * (0.8 if molten else 2.8)) * 0.3
	var base := _body_color(y * WG.WIDTH + x)
	var center := base
	var edge := base
	var top := _flow_section(x, y, ca, wa)
	var bottom := _flow_section(x, y + 1, cb, wb)
	var aa := clampf(top_amount / 10.0, 0, 1)
	var ab := clampf(bottom_amount / 10.0, 0, 1)
	if above <= epsilon:
		# Join a ledge pool's lip to the stream, across the half-cell gap.
		# Only real adjacent feed participates; never bridge a rock separator.
		for neighbor in [x - 1, x + 1]:
			if _value(neighbor, y) <= epsilon or not _supported(neighbor, y): continue
			var lip_x := float(x * 16 if neighbor < x else (x + 1) * 16)
			var lip_y := float((y + 1) * 16) - _value(neighbor, y) * 16.0 / 255.0
			var thickness := minf(3.0, _value(neighbor, y) * 16.0 / 255.0)
			var join_x := top.x if neighbor < x else top.y
			if absf(join_x - lip_x) > 0.01:
				_quad(Vector2(lip_x, lip_y), Vector2(join_x, ya), Vector2(lip_x, lip_y + thickness), Vector2(join_x, ya + thickness), base, base, base, base)
	_quad(Vector2(top.x, ya), Vector2(ca, ya), Vector2(bottom.x, yb), Vector2(cb, yb),
		Color(edge, edge.a * aa), Color(center, center.a * aa), Color(edge, edge.a * ab), Color(center, center.a * ab))
	_quad(Vector2(ca, ya), Vector2(top.y, ya), Vector2(cb, yb), Vector2(bottom.y, yb),
		Color(center, center.a * aa), Color(edge, edge.a * aa), Color(center, center.a * ab), Color(edge, edge.a * ab))


func _droplet(x: int, y: int, amount: float, blend: float) -> void:
	var index := y * WG.WIDTH + x
	var incoming: bool = y > 0 and fluid.previous_amounts[index - WG.WIDTH] > 0 and fluid.amounts[index] > fluid.previous_amounts[index]
	var travel := lerpf(2.0, 14.0, blend) if incoming else 13.0
	var size := clampf(sqrt(amount / 255.0) * 12.0, 1.2, 5.0)
	var center := Vector2(x * WG.TILE + 8.0, y * WG.TILE + travel)
	var color := _body_color(index)
	color.a *= clampf(amount / 8.0, 0, 1)
	var index_start := vertices.size()
	for point in [Vector2(0, -1.3), Vector2(0.8, -0.3), Vector2(0.7, 0.6), Vector2(0, 0.9), Vector2(-0.7, 0.6), Vector2(-0.8, -0.3)]:
		vertices.append(center + point * size)
		colors.append(color)
	indices.append_array(PackedInt32Array([index_start, index_start + 1, index_start + 2,
		index_start, index_start + 2, index_start + 3, index_start, index_start + 3, index_start + 4,
		index_start, index_start + 4, index_start + 5]))


func draw_fluid(game, simulation, is_lava: bool) -> void:
	if not simulation.has_fluid:
		return
	fluid = simulation
	molten = is_lava
	grid = game.world["tiles"]
	clock = game.animation_clock
	if values.size() != grid.size():
		values.resize(grid.size())
	var camera: Vector2 = game.camera_pos
	var first := Vector2i(maxi(0, int(floor(camera.x / 16)) - 1), maxi(0, int(floor(camera.y / 16)) - 1))
	var end := Vector2i(mini(WG.WIDTH, int(ceil((camera.x + 1280) / 16)) + 1), mini(WG.HEIGHT, int(ceil((camera.y + 720) / 16)) + 1))
	var view_key := [simulation.visual_revision, simulation.tick, Rect2i(first, end - first)]
	# Most forest views contain no visible fluid, and settled ocean interiors
	# need no new geometry between ticks. Keep meshes in world coordinates
	# so scrolling still moves the cached surface smoothly every frame.
	if stable_views.get(simulation.fluid_id, []) == view_key:
		if meshes.get(simulation.fluid_id) != null:
			game.draw_mesh(meshes[simulation.fluid_id], null, Transform2D(0, -camera))
		return
	var blend := clampf(simulation.accumulator / simulation.step_seconds, 0, 1)
	var current: PackedByteArray = simulation.amounts
	var previous: PackedByteArray = simulation.previous_amounts
	var stable := true
	for y in range(maxi(0, first.y - 1), mini(WG.HEIGHT, end.y + 1)):
		for x in range(maxi(0, first.x - 1), mini(WG.WIDTH, end.x + 1)):
			var index := y * WG.WIDTH + x
			values[index] = lerpf(previous[index], current[index], blend)
			if current[index] != previous[index]:
				stable = false
	vertices.clear()
	colors.clear()
	indices.clear()
	for y in range(first.y, end.y):
		var x := first.x
		while x < end.x:
			var index := y * WG.WIDTH + x
			var amount := values[index]
			if amount <= 0.01 or WG.is_solid(grid[index]):
				x += 1
				continue
			var above := values[index - WG.WIDTH] if y > 0 else 0.0
			# Merge full submerged rows instead of emitting thousands of tile
			# rectangles in oceans. Only free surfaces need curved geometry.
			if amount >= 254.0 and above > 0.1:
				var start := x
				var row := y * WG.WIDTH
				while x < end.x and values[row + x] >= 254.0 and values[row - WG.WIDTH + x] > 0.1:
					x += 1
				var color := _body_color(index)
				_quad(Vector2(start * 16, y * 16), Vector2(x * 16, y * 16), Vector2(start * 16, (y + 1) * 16), Vector2(x * 16, (y + 1) * 16), color, color, color, color)
				continue
			var supported := _supported(x, y)
			if supported:
				_pool(x, y, amount)
			var incoming: bool = simulation.falling.has(index) or simulation.previous_falling.has(index) or (molten and above > 0.01 and not _supported(x, y - 1))
			if not supported or (incoming and above > (0.01 if molten else 0.1) and amount < 254):
				if (molten and (above > 0.01 or _value(x, y + 1) > 0.01)) or amount >= 64 or (amount >= 24 and (above >= 8 or _value(x, y + 1) >= 8)):
					_stream(x, y, amount, supported)
				elif not supported:
					_droplet(x, y, amount, blend)
			x += 1
	stable_views[simulation.fluid_id] = view_key if stable else []
	if vertices.is_empty():
		meshes[simulation.fluid_id] = null
		return
	var mesh: ArrayMesh = game.environment._mesh(vertices, colors, indices)
	meshes[simulation.fluid_id] = mesh
	game.draw_mesh(mesh, null, Transform2D(0, -camera))
