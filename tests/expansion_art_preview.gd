extends SceneTree

class Board extends Node2D:
	const Tools = preload("res://scripts/tool_catalog.gd")
	const Life = preload("res://scripts/ground_life.gd")
	const Ores = preload("res://scripts/ore_catalog.gd")
	var life := Life.new()
	var ores := Ores.new()
	var textures := Tools.make_textures()
	var mineral_textures: Array[Texture2D] = []
	func _ready() -> void:
		life.load_art()
		for i in range(7):
			mineral_textures.append(ImageTexture.create_from_image(ores.terrain_image_for(20 + i, 0)))
	func label(value: String, at: Vector2, size := 16, tint := Color("ccdbd5")) -> void:
		draw_string(ThemeDB.fallback_font, at, value, HORIZONTAL_ALIGNMENT_LEFT, -1, size, tint)
	func _draw() -> void:
		draw_rect(Rect2(0, 0, 1280, 900), Color("14252c"))
		label("GALAXIS ON FIRE   /   SEVEN MINING TIERS", Vector2(25, 35), 24)
		for i in range(7):
			var item: String = Tools.progression("Pickaxe")[i]
			var x := 25.0 + i * 180.0
			draw_texture_rect(textures[item], Rect2(x + 37, 57, 80, 100), false)
			label(Tools.display_name(item), Vector2(x, 184), 17)
			label("Level %d   /   %.0fx" % [Tools.mining_level(item), Tools.profile(item)["speed"]], Vector2(x, 209), 15)
			label("%d uses   /   +%d DMG" % [Tools.max_durability(item), Tools.profile(item)["bonus"]], Vector2(x, 232), 14)
		label("DESERT FLORA   /   ASEPRITE SOURCES, FOUR FRAMES PER SPECIES", Vector2(25, 283), 20)
		for i in range(15):
			var x := 22 + (i % 5) * 253
			var baseline := 435 + (i / 5) * 165
			var texture: Texture2D = life.frames[Life.DESERT[i]][0]
			var factor := 1.4
			draw_line(Vector2(x, baseline), Vector2(x + 230, baseline), Color("395349"))
			draw_texture_rect(texture, Rect2(Vector2(x + 65, baseline - texture.get_height() * factor), texture.get_size() * factor), false)
			label(Life.ITEMS[32 + i], Vector2(x + 5, baseline + 25), 16)
		label("UNDERGROUND MINERALS", Vector2(25, 835), 18)
		for i in range(7):
			var texture := mineral_textures[i]
			draw_texture_rect(texture, Rect2(380 + i * 110, 804, 48, 48), false)
			label(Ores.NATURAL[20 + i].replace("_", " "), Vector2(370 + i * 110, 878), 13)

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	root.size = Vector2i(1280, 900)
	root.content_scale_size = Vector2i(1280, 900)
	var board := Board.new()
	board.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	root.add_child(board)
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://tests/expansion_art_preview.png")
	quit()
