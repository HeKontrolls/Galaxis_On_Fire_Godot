extends RefCounted

const WG = preload("res://scripts/world_gen.gd")
const PAD := 18
var components := {}
var cell_components := {}
var drop_textures := {}
var leaf_icon: ImageTexture
var trunk_images := {}
var trunk_textures := {}
var tuft_images := {}


func invalidate() -> void:
	components.clear()
	cell_components.clear()
	trunk_images.clear()
	trunk_textures.clear()


func reset() -> void:
	invalidate()
	drop_textures.clear()


func _hash(x: int, y: int, seed_value: int) -> int:
	return posmod((x * 73856093) ^ (y * 19349663) ^ (seed_value * 83492791), 2147483647)


func _crown_cell(grid: PackedByteArray, cell: Vector2i) -> bool:
	var id := WG.tile_at(grid, cell.x, cell.y)
	if id == 8:
		return true
	# Cover the upper trunk where leaves surround it, so the crown has no shaft
	# shaped gap down its center. Trunk and leaf gameplay tiles stay separate.
	return id == 7 and WG.tile_at(grid, cell.x - 1, cell.y) == 8 and WG.tile_at(grid, cell.x + 1, cell.y) == 8


func component(grid: PackedByteArray, start: Vector2i, seed_value: int) -> Dictionary:
	if cell_components.has(start):
		return components[cell_components[start]]
	if not _crown_cell(grid, start):
		return {}
	var cells := {}
	var pending: Array[Vector2i] = [start]
	cells[start] = true
	var lo := start
	var hi := start
	var cursor := 0
	while cursor < pending.size():
		var cell := pending[cursor]
		cursor += 1
		lo = Vector2i(mini(lo.x, cell.x), mini(lo.y, cell.y))
		hi = Vector2i(maxi(hi.x, cell.x), maxi(hi.y, cell.y))
		for offset in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN,
			Vector2i(-1, -1), Vector2i(1, -1), Vector2i(-1, 1), Vector2i(1, 1)]:
			var neighbor: Vector2i = cell + offset
			if neighbor.x < 1 or neighbor.y < 1 or neighbor.x >= WG.WIDTH - 1 or neighbor.y >= WG.HEIGHT - 1:
				continue
			if not cells.has(neighbor) and _crown_cell(grid, neighbor):
				cells[neighbor] = true
				pending.append(neighbor)
	var origin := lo * WG.TILE - Vector2i(PAD, PAD)
	var size := (hi - lo + Vector2i.ONE) * WG.TILE + Vector2i(PAD * 2, PAD * 2)
	var image := _make_image(cells, origin, size, seed_value, grid)
	var id := start
	var result := {"origin": Vector2(origin), "image": image, "texture": ImageTexture.create_from_image(image),
		"id": id, "phase": float(_hash(start.x, start.y, seed_value) % 100) * 0.13}
	components[id] = result
	for cell in cells:
		cell_components[cell] = id
	return result


func _pixel(image: Image, point: Vector2i, color: Color) -> void:
	if point.x >= 0 and point.y >= 0 and point.x < image.get_width() and point.y < image.get_height():
		image.set_pixelv(point, color)


func _stroke(image: Image, start: Vector2, end: Vector2, color: Color, width: int = 1) -> void:
	var length := maxi(1, int(ceil(start.distance_to(end))))
	for step in range(length + 1):
		var point := Vector2i(start.lerp(end, float(step) / length).round())
		for y in range(-int(width / 2), width - int(width / 2)):
			for x in range(-int(width / 2), width - int(width / 2)):
				_pixel(image, point + Vector2i(x, y), color)


func _polygon(image: Image, points: PackedVector2Array, color: Color) -> void:
	var low := image.get_height()
	var high := 0
	for point in points:
		low = mini(low, int(floor(point.y)))
		high = maxi(high, int(ceil(point.y)))
	for y in range(maxi(0, low), mini(image.get_height(), high + 1)):
		var hits: Array[float] = []
		for i in range(points.size()):
			var a := points[i]
			var b := points[(i + 1) % points.size()]
			if (a.y <= y and b.y > y) or (b.y <= y and a.y > y):
				hits.append(a.x + (y - a.y) * (b.x - a.x) / (b.y - a.y))
		hits.sort()
		for hit in range(0, hits.size() - 1, 2):
			for x in range(maxi(0, int(ceil(hits[hit]))), mini(image.get_width(), int(floor(hits[hit + 1])) + 1)):
				image.set_pixel(x, y, color)


func _leaf(image: Image, base: Vector2, tip: Vector2, width: float, palette: Array[Color]) -> void:
	var axis := tip - base
	var side := axis.normalized().orthogonal() * width
	var blade := PackedVector2Array([base, base + axis * 0.22 + side * 0.39,
		base + axis * 0.49 + side * 0.56, base + axis * 0.75 + side * 0.48,
		base + axis * 0.93 + side * 0.22, tip,
		base + axis * 0.90 - side * 0.25, base + axis * 0.62 - side * 0.51,
		base + axis * 0.24 - side * 0.39])
	_polygon(image, blade, palette[1])
	_polygon(image, PackedVector2Array([base + axis * 0.15, base + axis * 0.3 + side * 0.33,
		base + axis * 0.65 + side * 0.27, tip - axis.normalized() * 2, base + axis * 0.5]), palette[3])
	for i in range(blade.size()):
		_stroke(image, blade[i], blade[(i + 1) % blade.size()], palette[0])
	_stroke(image, base + axis * 0.25, base + axis * 0.74, palette[2])
	_stroke(image, base + axis * 0.42 + side * 0.2, base + axis * 0.66 + side * 0.13, palette[4])


func _tuft(image: Image, center: Vector2, hash_value: int, scale: float, palette: Array[Color]) -> void:
	var key := Vector2i(hash_value % 16, roundi(scale * 100))
	if not tuft_images.has(key):
		var tuft := Image.create(64, 64, false, Image.FORMAT_RGBA8)
		tuft.fill(Color.TRANSPARENT)
		_paint_tuft(tuft, Vector2(32, 32), key.x * 193 + 751, scale, palette)
		tuft_images[key] = tuft
	image.blend_rect(tuft_images[key], Rect2i(0, 0, 64, 64), Vector2i(center.round()) - Vector2i(32, 32))


func _paint_tuft(image: Image, center: Vector2, hash_value: int, scale: float, palette: Array[Color]) -> void:
	# Interlocking pointed leaves give each tuft a dark underside, visible ribs,
	# and crisp sunlit faces. No soft alpha or repeated round tile outlines.
	var base := center + Vector2(0, 8 * scale)
	for leaf in range(5):
		var angle := -PI + 0.15 + float(leaf) * (PI - 0.30) / 4.0
		var length := (16.0 + float((hash_value >> (leaf * 2)) % 5)) * scale
		var tip := base + Vector2.from_angle(angle) * length
		tip.y += absf(float(leaf - 2)) * 2.1 * scale
		_leaf(image, base, tip, (9.0 + float((hash_value + leaf) % 3)) * scale, palette)


func _branch(image: Image, start: Vector2, end: Vector2) -> void:
	var bend := start.lerp(end, 0.58) + Vector2(0, 3)
	for section in [[start, bend], [bend, end]]:
		_stroke(image, section[0], section[1], Color("382a21"), 5)
		_stroke(image, section[0] - Vector2(0, 1), section[1] - Vector2(0, 1), Color("8a6141"), 3)
		_stroke(image, section[0] - Vector2(0, 2), section[1] - Vector2(0, 2), Color("bf935c"))


func _make_image(cells: Dictionary, origin: Vector2i, size: Vector2i, seed_value: int, grid: PackedByteArray = PackedByteArray()) -> Image:
	var image := Image.create(size.x, size.y, false, Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	var palette: Array[Color] = [Color("123c2e"), Color("22643b"), Color("328b43"), Color("50ad50"), Color("91ce69")]
	var ordered: Array = cells.keys()
	ordered.sort_custom(func(a: Vector2i, b: Vector2i) -> bool: return a.y < b.y if a.y != b.y else a.x < b.x)
	if not grid.is_empty():
		for cell: Vector2i in ordered:
			if WG.tile_at(grid, cell.x, cell.y) != 8:
				continue
			for distance in range(1, 4):
				var attached := false
				for side in [-1, 1]:
					var stem := cell + Vector2i(side * distance, 1)
					if WG.tile_at(grid, stem.x, stem.y) == 7:
						var start := Vector2(stem * WG.TILE - origin) + Vector2(8, 12)
						var end := Vector2(cell * WG.TILE - origin) + Vector2(8, 15)
						_branch(image, start, end)
						attached = true
				if attached:
					break
	# Place large fans on a staggered lattice, then fill sparse edge cells with
	# smaller tufts. Every actual leaf tile keeps visible collectible pixels.
	for cell: Vector2i in ordered:
		if posmod(cell.x + int(floor(float(cell.y) / 2)), 2) != 0:
			continue
		var hash_value := _hash(cell.x, cell.y, seed_value)
		var center := Vector2(cell * WG.TILE - origin) + Vector2(8, 7)
		center += Vector2(float(hash_value % 7) - 3, float((hash_value / 7) % 5) - 2)
		var scale := 0.75 if cells.size() <= 3 else 0.95 + float(hash_value % 3) * 0.08
		_tuft(image, center, hash_value, scale, palette)
	for cell: Vector2i in ordered:
		var start := cell * WG.TILE - origin
		var coverage := 0
		for y in range(start.y, start.y + WG.TILE):
			for x in range(start.x, start.x + WG.TILE):
				if image.get_pixel(x, y).a > 0.5:
					coverage += 1
		if coverage < 60:
			var hash_value := _hash(cell.x, cell.y, seed_value)
			_tuft(image, Vector2(start) + Vector2(8, 8), hash_value, 0.75, palette)
	return image


func trunk_patch(grid: PackedByteArray, cell: Vector2i, seed_value: int) -> Image:
	if trunk_images.has(cell):
		return trunk_images[cell]
	var top := cell.y
	var base := cell.y
	while top > 0 and WG.tile_at(grid, cell.x, top - 1) == 7:
		top -= 1
	while base < WG.HEIGHT - 1 and WG.tile_at(grid, cell.x, base + 1) == 7:
		base += 1
	var tree_hash := _hash(cell.x, base, seed_value)
	var image := Image.create(16, 16, false, Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	var bark := [Color("382a21"), Color("63432f"), Color("89613e"), Color("ad8050"), Color("d0a069")]
	for y in range(16):
		var world_y := cell.y * WG.TILE + y
		var age := clampf(float(world_y - top * WG.TILE) / maxf(1, float((base - top + 1) * WG.TILE)), 0, 1)
		var center := 8 + roundi(sin(float(world_y + tree_hash % 83) * 0.035) * 0.65)
		var half := 4 + int(age * 2.0)
		if cell.y == base and y >= 11:
			half = mini(7, half + int((y - 9) / 2))
		for x in range(maxi(0, center - half), mini(16, center + half + 1)):
			var column := x - center + half
			var shade := 2
			if x == center - half or x == center + half:
				shade = 0
			elif column <= 2:
				shade = 3 if column == 2 else 4
			elif x >= center + half - 2:
				shade = 1
			var ridge := _hash(cell.x * 13 + x, int(floor(float(world_y) / 5)), seed_value)
			if column > 2 and x < center + half - 1 and ridge % 9 < 2:
				shade = maxi(1, shade - 1)
			image.set_pixel(x, y, bark[shade])
		if posmod(world_y + tree_hash, 43) in [0, 1, 2]:
			_pixel(image, Vector2i(center, y), bark[0])
			_pixel(image, Vector2i(center - 1, y), bark[1])
	trunk_images[cell] = image
	return image


func trunk_texture(grid: PackedByteArray, cell: Vector2i, seed_value: int) -> Texture2D:
	if not trunk_textures.has(cell):
		trunk_textures[cell] = ImageTexture.create_from_image(trunk_patch(grid, cell, seed_value))
	return trunk_textures[cell]


func patch(grid: PackedByteArray, tile: Vector2i, seed_value: int) -> Image:
	var crown := component(grid, tile, seed_value)
	if crown.is_empty():
		return Image.create(16, 16, false, Image.FORMAT_RGBA8)
	var offset := tile * WG.TILE - Vector2i(crown["origin"])
	var image: Image = crown["image"]
	return image.get_region(Rect2i(offset, Vector2i(16, 16)))


func drop_texture(encoded: String) -> Texture2D:
	if not drop_textures.has(encoded):
		var data := Marshalls.base64_to_raw(encoded)
		if data.size() != 16 * 16 * 4:
			return icon()
		var image := Image.create_from_data(16, 16, false, Image.FORMAT_RGBA8, data)
		drop_textures[encoded] = ImageTexture.create_from_image(image)
	return drop_textures[encoded]


func icon() -> ImageTexture:
	if leaf_icon == null:
		var cells := {Vector2i.ZERO: true}
		var image := _make_image(cells, Vector2i(-PAD, -PAD), Vector2i(16 + PAD * 2, 16 + PAD * 2), 71519)
		leaf_icon = ImageTexture.create_from_image(image)
	return leaf_icon
