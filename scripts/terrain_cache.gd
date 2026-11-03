extends RefCounted

const WG = preload("res://scripts/world_gen.gd")
const CHUNK := 8
var g
var chunks := {}
var atlas := {}
var tinted := {}
var back_cells := {}
var visible_chunks: Array[Dictionary] = []
var visible_key := Rect2i()
var visible_dirty := true


func reset(game) -> void:
	g = game
	chunks.clear()
	visible_chunks.clear()
	visible_dirty = true
	if atlas.is_empty():
		for material in g.terrain_sheets:
			atlas[material] = g.terrain_sheets[material].get_image()


func invalidate(tile: Vector2i) -> void:
	for y in range(maxi(0, tile.y - 1), mini(WG.HEIGHT, tile.y + 2)):
		for x in range(maxi(0, tile.x - 1), mini(WG.WIDTH, tile.x + 2)):
			chunks.erase(Vector2i(int(x / CHUNK), int(y / CHUNK)))
	visible_dirty = true


func _soil(id: int) -> Image:
	if not tinted.has(id):
		var sheet: Image = g.SpriteArt.texture("res://assets/sprites/farming/soil.png").get_image()
		tinted[id] = sheet.get_region(Rect2i((id - 12) * 16, 0, 16, 16))
	return tinted[id]


func _back_cell(material: String, variation: int) -> Image:
	var key := material + str(variation)
	if not back_cells.has(key):
		var cell: Image = atlas[material].get_region(Rect2i(18 + variation * 18, 18, 16, 16))
		for py in range(16):
			for px in range(16):
				cell.set_pixel(px, py, cell.get_pixel(px, py) * Color(0.50, 0.47, 0.45))
		back_cells[key] = cell
	return back_cells[key]


func _build(key: Vector2i) -> Dictionary:
	var size := CHUNK * WG.TILE
	var front := Image.create(size, size, false, Image.FORMAT_RGBA8)
	var back := Image.create(size, size, false, Image.FORMAT_RGBA8)
	front.fill(Color.TRANSPARENT)
	back.fill(Color.TRANSPARENT)
	var decor: Array[Vector3i] = []
	var leaves: Array[Vector2i] = []
	var grid: PackedByteArray = g.world["tiles"]
	var surface: PackedInt32Array = g.world["surface"]
	for oy in range(CHUNK):
		for ox in range(CHUNK):
			var x := key.x * CHUNK + ox
			var y := key.y * CHUNK + oy
			if x >= WG.WIDTH or y >= WG.HEIGHT:
				continue
			var tile := Vector2i(x, y)
			var target := Vector2i(ox, oy) * WG.TILE
			var id: int = grid[y * WG.WIDTH + x]
			var cave_biome: int = g.Underground.biome(g.world, x, y) if y > surface[x] + 24 else -1
			if g.furnishings.wall_at(tile):
				back.blit_rect(g.furnishings.wall_image(tile), Rect2i(0, 0, 16, 16), target)
			elif y >= surface[x] + 4:
				var material := "dirt" if y - surface[x] < 24 else "stone"
				var variation := posmod(x * 83 + y * 47, 3)
				var cell: Image = g.underground.cell_image(atlas[material], Vector2i(18 + variation * 18, 18), cave_biome, true) if cave_biome >= 0 else _back_cell(material, variation)
				back.blit_rect(cell, Rect2i(0, 0, 16, 16), target)
			if id == 8:
				leaves.append(tile)
			elif id in [7, 14, 15, 16, 30, 34, 35]:
				decor.append(Vector3i(x, y, id))
			var material: String = g._terrain_material(id)
			if material.is_empty():
				continue
			# Rounded terrain silhouettes must retain their transparent corners.
			# Placed wooden blocks still need their solid backing under the overlay.
			if material in ["wood", "planks"]:
				front.fill_rect(Rect2i(target, Vector2i(16, 16)), WG.color_for(id))
			if id in [12, 13]:
				front.blit_rect(_soil(id), Rect2i(0, 0, 16, 16), target)
			elif material == "glacial_ice":
				front.blit_rect(atlas[material], Rect2i(posmod(x, 8) * 16, posmod(y, 16) * 16, 16, 16), target)
				var north := WG.tile_at(grid, x, y - 1) == 27
				var west := WG.tile_at(grid, x - 1, y) == 27
				var east := WG.tile_at(grid, x + 1, y) == 27
				if not north:
					var stacked := WG.tile_at(grid, x, y + 1) == 27
					var edge := (0 if not west and not east else (1 if not west else (2 if not east else 3))) if stacked else 3
					if edge != 3:
						front.fill_rect(Rect2i(target, Vector2i(16, 16)), Color.TRANSPARENT)
					front.blend_rect(atlas["glacial_edges"], Rect2i(edge * 16, 0, 16, 16), target)
				else:
					if not west:
						front.blend_rect(atlas["glacial_edges"], Rect2i(64, 0, 16, 16), target)
					if not east:
						front.blend_rect(atlas["glacial_edges"], Rect2i(80, 0, 16, 16), target)
			elif material in ["obsidian", "gravel"]:
				var variant := posmod(x * 83 + y * 47, 4)
				front.blit_rect(atlas[material], Rect2i(variant * 16, 0, 16, 16), target)
			elif material in ["wood", "planks"]:
				front.blend_rect(atlas[material], Rect2i(0, 0, 16, 16), target)
			else:
				var frame: Vector2i = g._terrain_frame(grid, x, y, material)
				if cave_biome >= 0 and material in ["stone", "dirt"]:
					front.blend_rect(g.underground.cell_image(atlas[material], frame, cave_biome), Rect2i(0, 0, 16, 16), target)
				else:
					front.blend_rect(atlas[material], Rect2i(frame, Vector2i(16, 16)), target)
			if id in [20, 21, 22, 23, 24, 25, 26]:
				front.blend_rect(g.ores.terrain_image_for(id, x * 83 + y * 47), Rect2i(0, 0, 16, 16), target)
	var result := {"position": Vector2(key * size), "front": ImageTexture.create_from_image(front),
		"back": ImageTexture.create_from_image(back), "decor": decor, "leaves": leaves}
	chunks[key] = result
	return result


func visible(camera: Vector2) -> Array[Dictionary]:
	var start := Vector2i(maxi(0, int(floor(camera.x / 16)) - 3), maxi(0, int(floor(camera.y / 16)) - 3))
	var finish := Vector2i(mini(WG.WIDTH - 1, start.x + 88), mini(WG.HEIGHT - 1, start.y + 53))
	var first := Vector2i(int(start.x / CHUNK), int(start.y / CHUNK))
	var last := Vector2i(int(finish.x / CHUNK), int(finish.y / CHUNK))
	var key := Rect2i(first, last - first + Vector2i.ONE)
	if not visible_dirty and visible_key == key:
		return visible_chunks
	visible_chunks.clear()
	if chunks.size() > 512:
		for stale in chunks.keys():
			if not key.has_point(stale):
				chunks.erase(stale)
			if chunks.size() <= 384:
				break
	for y in range(first.y, last.y + 1):
		for x in range(first.x, last.x + 1):
			var chunk := Vector2i(x, y)
			visible_chunks.append(chunks[chunk] if chunks.has(chunk) else _build(chunk))
	visible_key = key
	visible_dirty = false
	return visible_chunks
