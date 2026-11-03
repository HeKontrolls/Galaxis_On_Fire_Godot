extends SceneTree
const Mobs = preload("res://scripts/wildlife_mobs.gd")
class Gallery extends Node2D:
	var sheets: Array[Texture2D] = []
	func _ready() -> void:
		for family in range(9): sheets.append(load("res://scripts/sprite_art.gd").texture("res://assets/sprites/monsters/wildlife_%d.png" % family))
	func _draw() -> void:
		draw_rect(Rect2(0, 0, 1280, 720), Color("15242d"))
		for family in range(9):
			var y := 21 + family * 77
			draw_string(ThemeDB.fallback_font, Vector2(18, y + 26), Mobs.NAMES[family], HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("d5d9cb"))
			var tex: Texture2D = sheets[family]
			for morph in range(2):
				for pose in range(4):
					var frame: int = [0, 2, 3, 6][pose]
					draw_texture_rect_region(tex, Rect2(230 + (morph * 4 + pose) * 128, y - 8, 96, 80), Rect2(frame * 48, morph * 40, 48, 40))
func _initialize() -> void: call_deferred("run")
func run() -> void:
	root.size = Vector2i(1280, 720)
	var gallery := Gallery.new(); root.add_child(gallery)
	await process_frame; await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://tests/wildlife_mobs_review.png")
	gallery.queue_free(); await process_frame
	var g = load("res://main.tscn").instantiate()
	root.add_child(g); g.set_process(false); await g._open_planet(0)
	var fort: Dictionary = g.world.underworld_forts[2]
	var left := int(fort.x); var floor_y := (1440 - 32) * 16
	var rng := RandomNumberGenerator.new(); rng.seed = 17
	g.world.creatures = []
	for i in range(4):
		var c := Mobs.creature([4, 5, 6, 7][i], Vector2((left + 16 + i * 6) * 16, floor_y - 18), rng)
		g.world.creatures.append(c)
	var bat := Mobs.creature(8, Vector2((left + 29) * 16, floor_y - 92), rng)
	g.world.creatures.append(bat)
	g.player_pos = Vector2((left + 19) * 16, floor_y - 28)
	g.camera_pos = Vector2((float(fort.x) + float(fort.width) * 0.5) * 16 - 640, floor_y - 460)
	g.environment.invalidate(); g.notice_timer = 0; g.queue_redraw()
	await process_frame; await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://tests/wildlife_mobs_gameplay.png")
	print("WILDLIFE_PREVIEW complete")
	g.free(); quit()
