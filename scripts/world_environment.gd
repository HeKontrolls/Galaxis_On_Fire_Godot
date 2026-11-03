extends RefCounted

const WG = preload("res://scripts/world_gen.gd")
const MARGIN := 16
var roof := PackedInt32Array()
var fog_floor := PackedInt32Array()
var fog_anchor := PackedInt32Array()
var world := {}
var dirty := true
var bounds := Rect2i()
var light := PackedFloat32Array()
var warmth := PackedFloat32Array()
var shadow_mesh: ArrayMesh
var warm_mesh: ArrayMesh
var crystal_mesh: ArrayMesh
var crystal_colors := PackedColorArray()
var last_update := -100.0
var last_sun := -1.0
var last_night := -1.0
var last_held_torch := false
var fog_textures: Array[CanvasTexture] = []
var fog_profiles := {}
var fog_profile_version := -1
var active_fog_layers: Array[Dictionary] = []
var base_light := PackedFloat32Array()
var base_warmth := PackedFloat32Array()
var last_player_tile := Vector2i(-1, -1)
var had_dynamic_light := false
var mesh_vertices := PackedVector2Array()
var mesh_indices := PackedInt32Array()
var mesh_bounds := Rect2i()
var geometry_version := 0
var fog_cache_version := -1
var fog_cache_x := -999999
var fog_cache_clock := -100.0
var attenuation := PackedFloat32Array()


func reset(data: Dictionary) -> void:
	world = data
	roof.resize(WG.WIDTH)
	fog_floor.resize(WG.WIDTH)
	fog_anchor.resize(WG.WIDTH)
	for x in range(WG.WIDTH):
		refresh_column(x)
	dirty = true
	last_update = -100.0


func invalidate() -> void:
	dirty = true


func refresh_water_column(column: int, highest_changed_y: int) -> void:
	# Deep water cannot change either a solid roof or the exterior fog line.
	if highest_changed_y <= fog_anchor[column]:
		refresh_column(column)


func refresh_column(column: int) -> void:
	if column < 0 or column >= WG.WIDTH or world.is_empty():
		return
	var grid: PackedByteArray = world["tiles"]
	var first_roof := WG.HEIGHT - 1
	var anchor := int(world["surface"][column])
	var exterior_limit := anchor
	var found_roof := false
	for y in range(WG.HEIGHT):
		var tile_id: int = grid[y * WG.WIDTH + column]
		if tile_id in [4, 6, 11]:
			anchor = mini(anchor, y)
			exterior_limit = mini(exterior_limit, y)
		if WG.is_solid(tile_id):
			first_roof = y
			exterior_limit = mini(exterior_limit, y)
			found_roof = true
			break
	if not found_roof:
		first_roof = WG.HEIGHT - 1
	if roof[column] != first_roof:
		dirty = true
	if roof[column] != first_roof or fog_floor[column] != exterior_limit or fog_anchor[column] != anchor:
		geometry_version += 1
	roof[column] = first_roof
	fog_floor[column] = exterior_limit
	fog_anchor[column] = anchor


func outside(point: Vector2) -> bool:
	if fog_floor.size() != WG.WIDTH:
		return false
	var x := clampi(int(floor(point.x / WG.TILE)), 0, WG.WIDTH - 1)
	return point.y < float(fog_floor[x] * WG.TILE)


func _seed(values: PackedFloat32Array, tile: Vector2i, value: float, pending: Array[int]) -> void:
	if not bounds.has_point(tile):
		return
	var index := (tile.y - bounds.position.y) * bounds.size.x + tile.x - bounds.position.x
	if value > values[index]:
		values[index] = value
		pending.append(index)


func _propagate(values: PackedFloat32Array, pending: Array[int], grid: PackedByteArray) -> void:
	var cursor := 0
	while cursor < pending.size():
		var index := pending[cursor]
		cursor += 1
		var x := index % bounds.size.x
		var y := int(index / bounds.size.x)
		for oy in range(-1, 2):
			for ox in range(-1, 2):
				if ox == 0 and oy == 0:
					continue
				var nx := x + ox
				var ny := y + oy
				if nx < 0 or ny < 0 or nx >= bounds.size.x or ny >= bounds.size.y:
					continue
				var next := ny * bounds.size.x + nx
				var distance := 1.414214 if ox != 0 and oy != 0 else 1.0
				var loss := attenuation[next] * distance
				var value := values[index] - loss
				if value > 0.005 and value > values[next] + 0.004:
					values[next] = value
					pending.append(next)


func prepare(camera: Vector2, player: Vector2, sun: float, night_dark: float, clock: float, held_torch: bool = false) -> void:
	var start := Vector2i(maxi(0, int(floor(camera.x / 128)) * 8 - MARGIN), maxi(0, int(floor(camera.y / 128)) * 8 - MARGIN))
	var end := Vector2i(mini(WG.WIDTH, int(ceil((camera.x + 1280) / 128)) * 8 + MARGIN), mini(WG.HEIGHT, int(ceil((camera.y + 720) / 128)) * 8 + MARGIN))
	var next_bounds := Rect2i(start, end - start)
	var player_tile := Vector2i(floor((player + Vector2(8, 14)) / WG.TILE))
	var rebuild := dirty or bounds != next_bounds or absf(last_sun - sun) >= 0.02 or not is_equal_approx(last_night, night_dark)
	if not rebuild and player_tile == last_player_tile and last_held_torch == held_torch:
		return
	bounds = next_bounds
	last_update = clock
	last_player_tile = player_tile
	last_held_torch = held_torch
	dirty = false
	var pending: Array[int] = []
	var warm_pending: Array[int] = []
	var grid: PackedByteArray = world["tiles"]
	if rebuild:
		last_sun = sun
		last_night = night_dark
		light.resize(bounds.size.x * bounds.size.y)
		light.fill(0.0)
		warmth.resize(light.size())
		warmth.fill(0.0)
		var lava_sources: Array[Vector2i] = []
		attenuation.resize(light.size())
		for row in range(bounds.size.y):
			for column in range(bounds.size.x):
				var id: int = grid[(bounds.position.y + row) * WG.WIDTH + bounds.position.x + column]
				attenuation[row * bounds.size.x + column] = 0.055 if id == 27 else (0.26 if id in WG.SOLIDS else (0.095 if id == 4 else 0.078))
				if id == 11:
					lava_sources.append(bounds.position + Vector2i(column, row))
		var daylight := maxf(0.045, 1.0 - (1.0 - sun) * night_dark)
		for x in range(bounds.position.x, bounds.end.x):
			# Uniform open sky is already lit. Propagation only needs its
			# boundary with terrain, water, or an excavated surface.
			var edge := mini(roof[x], mini(roof[maxi(0, x - 1)], roof[mini(WG.WIDTH - 1, x + 1)]))
			edge = mini(edge, mini(fog_floor[x], int(world["surface"][x])))
			for y in range(bounds.position.y, mini(bounds.end.y, roof[x] + 1)):
				var depth := maxi(0, y - int(world["surface"][x]))
				var water_depth := maxi(0, y - fog_floor[x]) if grid[y * WG.WIDTH + x] == 4 else 0
				var strength := daylight * pow(0.80, depth) * pow(0.88, water_depth)
				if y == roof[x]:
					strength *= 0.88
				var index := (y - bounds.position.y) * bounds.size.x + x - bounds.position.x
				light[index] = strength
				if y >= edge - 1 and strength > 0.005:
					pending.append(index)
		for tile in lava_sources:
			_seed(light, tile, 1.03, pending)
			_seed(warmth, tile, 1.0, warm_pending)
		for key in world.get("torches", {}):
			var parts := str(key).split(",")
			if parts.size() == 2:
				var tile := Vector2i(int(parts[0]), int(parts[1]))
				_seed(light, tile, 1.08, pending)
				_seed(warmth, tile, 1.0, warm_pending)
		for entry: Dictionary in world.get("cave_lights", []):
			_seed(light, Vector2i(int(entry["x"]), int(entry["y"])), 0.65 if int(entry["kind"]) == 4 else 1.0, pending)
		for hearth: Vector2i in world.get("furniture_lights", []):
			_seed(light, hearth, 1.15, pending)
			_seed(warmth, hearth, 1.0, warm_pending)
		_crystal_glow(grid)
		_propagate(light, pending, grid)
		_propagate(warmth, warm_pending, grid)
		base_light = light.duplicate()
		base_warmth = warmth.duplicate()
		pending.clear()
		warm_pending.clear()
	else:
		light = base_light.duplicate()
		warmth = base_warmth.duplicate()
	_seed(light, player_tile, 1.02 if held_torch else 0.18, pending)
	if held_torch:
		_seed(warmth, player_tile, 0.95, warm_pending)
	var dynamic := not pending.is_empty() or not warm_pending.is_empty()
	if not rebuild and not dynamic and not had_dynamic_light:
		return
	_propagate(light, pending, grid)
	_propagate(warmth, warm_pending, grid)
	had_dynamic_light = dynamic
	_build_light_meshes()


func brightness_at(point: Vector2) -> float:
	var tile := Vector2i(floor(point / WG.TILE))
	if not bounds.has_point(tile) or light.is_empty():
		return 0.0
	return clampf(light[(tile.y - bounds.position.y) * bounds.size.x + tile.x - bounds.position.x], 0.0, 1.0)


func _build_light_meshes() -> void:
	var dark_colors := PackedColorArray()
	var warm_colors := PackedColorArray()
	if mesh_bounds.size != bounds.size:
		mesh_vertices.clear()
		mesh_indices.clear()
		for y in range(bounds.size.y):
			for x in range(bounds.size.x):
				var index := y * bounds.size.x + x
				mesh_vertices.append(Vector2(x + 0.5, y + 0.5) * WG.TILE)
				if x + 1 < bounds.size.x and y + 1 < bounds.size.y:
					mesh_indices.append_array(PackedInt32Array([index, index + 1, index + bounds.size.x,
						index + 1, index + bounds.size.x + 1, index + bounds.size.x]))
	mesh_bounds = bounds
	for index in range(light.size()):
		dark_colors.append(Color(0, 0, 0, 1.0 - clampf(light[index], 0.0, 1.0)))
		warm_colors.append(Color(1.0, 0.43, 0.11, clampf(warmth[index], 0.0, 1.0) * 0.14))
	shadow_mesh = _mesh(mesh_vertices, dark_colors, mesh_indices)
	warm_mesh = _mesh(mesh_vertices, warm_colors, mesh_indices)
	if crystal_colors.size() == light.size(): crystal_mesh = _mesh(mesh_vertices, crystal_colors, mesh_indices)

func _crystal_glow(grid: PackedByteArray) -> void:
	var channels: Array[PackedFloat32Array] = []
	for channel in range(3):
		var values := PackedFloat32Array(); values.resize(light.size()); values.fill(0.0)
		var pending: Array[int] = []
		for entry: Dictionary in world.get("cave_lights", []):
			var point := Vector2i(int(entry["x"]), int(entry["y"]))
			if not bounds.has_point(point): continue
			var color: Color = preload("res://scripts/underground.gd").GLOW[int(entry["color"])]
			if int(entry["kind"]) == 4: color *= 0.65
			_seed(values, point, [color.r, color.g, color.b][channel], pending)
		_propagate(values, pending, grid)
		channels.append(values)
	crystal_colors.resize(light.size())
	for index in range(light.size()):
		var value := maxf(channels[0][index], maxf(channels[1][index], channels[2][index]))
		crystal_colors[index] = Color(channels[0][index] / maxf(value, 0.001), channels[1][index] / maxf(value, 0.001), channels[2][index] / maxf(value, 0.001), value * 0.28)


func _mesh(vertices: PackedVector2Array, colors: PackedColorArray, indices: PackedInt32Array, uvs: PackedVector2Array = PackedVector2Array()) -> ArrayMesh:
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_COLOR] = colors
	arrays[Mesh.ARRAY_INDEX] = indices
	if not uvs.is_empty():
		arrays[Mesh.ARRAY_TEX_UV] = uvs
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh


func _periodic_fog_noise(noise: FastNoiseLite, point: Vector2, period: Vector2) -> float:
	var p := Vector2(fposmod(point.x, period.x), fposmod(point.y, period.y))
	var u := smoothstep(0.0, period.x, p.x)
	var v := smoothstep(0.0, period.y, p.y)
	var upper := lerpf(noise.get_noise_2d(p.x, p.y), noise.get_noise_2d(p.x - period.x, p.y), u)
	var lower := lerpf(noise.get_noise_2d(p.x, p.y - period.y), noise.get_noise_2d(p.x - period.x, p.y - period.y), u)
	return lerpf(upper, lower, v)


func _fog_texture(variant: int) -> CanvasTexture:
	var image := Image.create(384, 192, false, Image.FORMAT_RGBA8)
	var broad := FastNoiseLite.new()
	broad.seed = 87153 + variant * 1973
	broad.frequency = 0.006 + variant * 0.001
	broad.fractal_octaves = 4
	var detail := FastNoiseLite.new()
	detail.seed = broad.seed + 137
	detail.frequency = 0.024
	var period := Vector2(1700.0 + variant * 160.0, 480.0 - variant * 40.0)
	for y in range(192):
		for x in range(384):
			var point := Vector2(float(x) / 383.0, float(y) / 191.0) * period
			var density := maxf(0.0, 0.48 + _periodic_fog_noise(broad, point, period) * 0.9 + _periodic_fog_noise(detail, point, period) * 0.15)
			var lit_density := maxf(0.0, 0.48 + _periodic_fog_noise(broad, point - Vector2(24, 20), period) * 0.9)
			var shade := clampf(0.91 - maxf(0.0, density - lit_density) * 0.65 - density * 0.12, 0.52, 1.0)
			var alpha := 1.0 - exp(-density * 2.2)
			image.set_pixel(x, y, Color(shade * 0.88, shade * 0.96, shade, alpha))
	# Override the scene's nearest filtering only for fog. Terrain and sprites
	# retain their pixel art filtering. The noise tile is seamless on both axes.
	var texture := CanvasTexture.new()
	texture.diffuse_texture = ImageTexture.create_from_image(image)
	texture.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	texture.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	return texture


func _fog_profile(boundary: int) -> Vector2:
	if fog_profile_version != geometry_version:
		fog_profiles.clear()
		fog_profile_version = geometry_version
	if fog_profiles.has(boundary):
		return fog_profiles[boundary]
	# Smooth a conservative surface envelope. Every contributing minimum
	# includes both adjacent columns, so this curve always stays above roofs,
	# water, and the original ground, including open mine shafts.
	var lower := 0.0
	var weights := [1.0, 3.0, 3.0, 1.0]
	for sample in range(4):
		var lowest := WG.HEIGHT
		var center := boundary + sample - 2
		for offset in range(-4, 5):
			lowest = mini(lowest, fog_floor[clampi(center + offset, 0, WG.WIDTH - 1)])
		lower += lowest * weights[sample] / 8.0
	var anchor := 0.0
	var anchor_weights := [1.0, 2.0, 3.0, 4.0, 4.0, 3.0, 2.0, 1.0]
	for sample in range(8):
		anchor += fog_anchor[clampi(boundary + sample - 4, 0, WG.WIDTH - 1)] * anchor_weights[sample] / 20.0
	var profile := Vector2(anchor, lower) * WG.TILE
	fog_profiles[boundary] = profile
	return profile


func fog_layers(camera: Vector2, clock: float) -> Array[Dictionary]:
	var chunk_x := int(floor(camera.x / 128))
	if chunk_x == fog_cache_x and geometry_version == fog_cache_version and clock >= fog_cache_clock and clock - fog_cache_clock < 0.12:
		return active_fog_layers
	fog_cache_x = chunk_x
	fog_cache_version = geometry_version
	fog_cache_clock = clock
	var fog_left := float(chunk_x * 128 - 128)
	if fog_textures.is_empty():
		for variant in range(3):
			fog_textures.append(_fog_texture(variant))
	var layers: Array[Dictionary] = []
	var sections := [0.0, 0.07, 0.17, 0.32, 0.5, 0.68, 0.83, 0.94, 1.0]
	var fade := [0.0, 0.28, 0.62, 0.9, 1.0, 0.96, 0.73, 0.32, 0.0]
	var first := maxi(0, int(floor(fog_left / WG.TILE)))
	var last := mini(WG.WIDTH, int(ceil((fog_left + 1664) / WG.TILE)))
	for layer in range(3):
		var period := Vector2(1700.0 + layer * 160.0, 480.0 - layer * 40.0)
		var height := 330.0 - layer * 60.0
		var wind := Vector2(clock * (4.0 + layer * 2.7) + layer * 481.0, clock * 0.6 + layer * 173.0)
		var vertices := PackedVector2Array()
		var colors := PackedColorArray()
		var uvs := PackedVector2Array()
		var indices := PackedInt32Array()
		for boundary in range(first, last + 1):
			var profile := _fog_profile(boundary)
			var top := minf(profile.x - height, profile.y - 1.0)
			for row in range(sections.size()):
				var point := Vector2(boundary * WG.TILE, lerpf(top, profile.y, sections[row]))
				vertices.append(point)
				colors.append(Color(1, 1, 1, fade[row] * (0.36 if layer < 2 else 0.28)))
				# Texture coordinates depend only on world position, so the
				# density field cannot restart or stretch at a tile boundary.
				uvs.append((point + wind) / period)
			if boundary < last:
				for row in range(sections.size() - 1):
					var index := (boundary - first) * sections.size() + row
					var next := index + sections.size()
					indices.append_array(PackedInt32Array([index, next, index + 1, next, next + 1, index + 1]))
		if not vertices.is_empty():
			layers.append({"mesh": _mesh(vertices, colors, indices, uvs), "texture": fog_textures[layer], "depth": layer})
	# Canvas drawing stores mesh RIDs; retain resources until the next redraw.
	active_fog_layers = layers
	return active_fog_layers
