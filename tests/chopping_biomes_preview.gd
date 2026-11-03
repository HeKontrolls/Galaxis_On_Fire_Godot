extends SceneTree

const WG = preload("res://scripts/world_gen.gd")

class BiomeBoard extends Node2D:
	var worlds: Array = []
	var textures: Array[Texture2D] = []
	func label(value: String, at: Vector2, size := 14, color := Color("deebef")) -> void:
		draw_string(ThemeDB.fallback_font, at, value, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)
	func _draw() -> void:
		draw_rect(Rect2(0, 0, 1280, 720), Color("101e2b"))
		label("GALAXIS ON FIRE / PLANET BIOME REGIONS", Vector2(24, 36), 25, Color("efc384"))
		label("Actual generated terrain / seed 713 / wooded clusters, clearings, different ground and fluid cover", Vector2(24, 63), 15)
		var names := ["Temperate", "Islands", "Ocean", "Desert", "Volcanic", "Barren", "Frozen sea", "Tundra"]
		var colors := [Color("517a77"), Color("736d56"), Color("536b88"), Color("755e77")]
		for climate in range(8):
			var y := 92 + climate * 73
			label(names[climate], Vector2(24, y + 28), 17, Color("efc384"))
			var columns: PackedByteArray = worlds[climate]["biomes"]
			var start := 0
			for end in range(1, WG.WIDTH + 1):
				if end < WG.WIDTH and columns[end] == columns[start]:
					continue
				var band := Rect2(164 + start * 0.9, y, (end - start) * 0.9, 18)
				draw_rect(band, colors[columns[start]])
				var name: String = WG.Biomes.profile(climate, columns[start])["name"]
				if ThemeDB.fallback_font.get_string_size(name, HORIZONTAL_ALIGNMENT_LEFT, -1, 11).x < band.size.x - 5:
					label(name, band.position + Vector2(3, 13), 11)
				start = end
			draw_texture_rect(textures[climate], Rect2(164, y + 18, 1080, 47), false)
		label("Tree removal requires repeated trunk hits. Leaves clear independently. Previous worlds retain their terrain.", Vector2(24, 706), 14)


func _initialize() -> void:
	call_deferred("preview")


func capture(node: Node2D, name: String) -> void:
	node.queue_redraw()
	await process_frame
	await process_frame
	root.get_texture().get_image().save_png("res://tests/" + name + ".png")


func preview() -> void:
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	await game._open_planet(0)
	game.set_process(false)
	var board := BiomeBoard.new()
	board.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	for climate in range(8):
		var data := WG.generate(713, climate)
		board.worlds.append(data)
		var overview := Image.create(WG.WIDTH, 130, false, Image.FORMAT_RGBA8)
		for x in range(WG.WIDTH):
			for row in range(130):
				var id := WG.tile_at(data["tiles"], x, row + 65)
				var empty := Color("649dcb") if row + 65 < data["surface"][x] else Color("0b121c")
				overview.set_pixel(x, row, empty if id == 0 else WG.color_for(id))
		board.textures.append(ImageTexture.create_from_image(overview))
	root.add_child(board)
	await capture(board, "planet_biomes_preview")
	game.world = board.worlds[0]
	board.queue_free()
	await process_frame
	game.world["creatures"] = []
	game.world["drops"] = []
	game.world["crops"] = {}
	game.world["torches"] = {}
	game.world["placed_chests"] = {}
	game._reset_world_environment()
	game.world_texture = WG.make_texture(game.world["tiles"])
	game.world_image = game.world_texture.get_image()
	game.foliage.reset()
	var trunk := Vector2i(-1, -1)
	for x in range(400, 900):
		var y: int = game.world["surface"][x] - 1
		if WG.tile_at(game.world["tiles"], x, y) == 7 and absi(game.world["surface"][x - 2] - y - 1) <= 2:
			trunk = Vector2i(x, y)
			break
	assert(trunk.x >= 0)
	game.player_pos = Vector2((trunk.x - 2) * WG.TILE, game.world["surface"][trunk.x - 2] * WG.TILE - 28)
	game.player_grounded = true
	game._update_camera()
	game.weather = "Clear"
	game.weather_blend.reset("Clear", int(game.world.get("climate", 0)))
	game.time_of_day = 0.25
	game.cloud_cover = 0.3
	game.notice_timer = 0.0
	game.inventory = {"Axe": 1}
	game._equip_inventory_item("Axe")
	for _hit in range(3):
		game.mining_cooldown = 0
		game._mine(Vector2(trunk * WG.TILE) + Vector2(8, 8) - game.camera_pos)
	game.tool_action_timer = game.tool_action_duration * 0.5
	await capture(game, "chopping_gameplay_preview")
	print("BIOME_PREVIEW eight real terrain strips and in-game chopping progress rendered")
	quit()
