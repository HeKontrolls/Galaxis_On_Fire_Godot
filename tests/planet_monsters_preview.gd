extends SceneTree
const Monsters = preload("res://scripts/planet_monsters.gd")
class Review:
	extends Node2D
	var monsters = Monsters.new()
	func _draw() -> void:
		draw_rect(Rect2(0, 0, 960, 858), Color("101b24"))
		var font = ThemeDB.fallback_font
		draw_string(font, Vector2(24, 32), "GALAXIS ON FIRE  /  PLANET MONSTERS", HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Color("e9d9b3"))
		draw_string(font, Vector2(24, 56), "8 native Aseprite families | 24 morphs | idle + walk animations | seeded planet populations", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("a9bdc6"))
		var climates := ["Forest", "Islands", "Ocean & continents", "Desert", "Lava", "Barren rock", "Frozen ocean", "Tundra"]
		for family in range(8):
			var x := 16 + (family % 2) * 472
			var y := 76 + int(family / 2) * 192
			draw_rect(Rect2(x, y, 456, 180), Color("21333c"))
			draw_string(font, Vector2(x + 12, y + 26), climates[family] + "  /  " + Monsters.NAMES[family], HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("dfd7bc"))
			for morph in range(3):
				draw_line(Vector2(x + 12 + morph * 148, y + 150), Vector2(x + 150 + morph * 148, y + 150), Color("55665e"))
				draw_texture_rect_region(monsters.texture_for(family), Rect2(x + 6 + morph * 148, y + 42, 144, 120), Rect2(96, morph * 40, 48, 40))
				draw_string(font, Vector2(x + 24 + morph * 148, y + 172), "Morph %d" % (morph + 1), HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("a9bdc6"))
func _initialize() -> void:
	call_deferred("run_preview")
func run_preview() -> void:
	var review_view := SubViewport.new()
	review_view.size = Vector2i(960, 858)
	review_view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(review_view)
	var canvas := Review.new()
	canvas.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	review_view.add_child(canvas)
	await process_frame
	await RenderingServer.frame_post_draw
	review_view.get_texture().get_image().save_png("res://tests/planet_monsters_review.png")
	review_view.free()
	root.size = Vector2i(1280, 720)
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	await game._open_planet(0)
	var c: Dictionary = game.world["creatures"][0]
	var column := int(c.x / 16) - 3
	game.player_pos = Vector2(column * 16, game._walkable_y(column) - 28)
	game._update_camera()
	c.moving = true
	game.animation_clock = 0.3
	game.queue_redraw()
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://tests/planet_monsters_gameplay.png")
	game.free()
	print("MONSTER_PREVIEW saved review and gameplay")
	quit()
