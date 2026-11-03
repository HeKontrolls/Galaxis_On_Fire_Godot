extends SceneTree
var captures: Array[Image] = []
func _initialize() -> void:
	call_deferred("run_preview")
func capture(game) -> void:
	game.queue_redraw()
	await process_frame
	await RenderingServer.frame_post_draw
	captures.append(root.get_texture().get_image())
func run_preview() -> void:
	root.size = Vector2i(1280, 720)
	var g = load("res://main.tscn").instantiate()
	root.add_child(g)
	g.set_process(false)
	await g._open_planet(0)
	# Build a compact review scene from the game's own existing terrain tiles.
	var grid: PackedByteArray = g.world.tiles
	for x in range(558, 640):
		g.world.surface[x] = 96 if x < 592 else 104
		for y in range(72, 130):
			var solid := y >= (96 if x < 592 else 104)
			WG.set_tile(grid, x, y, 2 if solid else 0)
		WG.set_tile(grid, x, int(g.world.surface[x]), 1)
	# Open cave below a substantial natural roof, connected to the cliff face.
	for x in range(568, 609):
		for y in range(99, 104): WG.set_tile(grid, x, y, 0)
	g.world.tiles = grid
	var vines: Array = []
	for x in [571, 574, 576, 581, 585, 588]:
		vines.append({"x": x, "y": 98, "side": 0, "length": 6 + x % 4, "limit": 12, "style": 2 if x % 2 == 0 else 1, "phase": x * 0.7, "alive": true})
	vines.append({"x": 591, "y": 96, "side": 1, "length": 13, "limit": 14, "style": 0, "phase": 0.0, "alive": true})
	g.world.vines = vines; g.world.vines_version = 1
	g.world.torches = {"575,102": true, "584,102": true}
	g.world.creatures = []; g.world.erase("npc")
	g._reset_world_environment()
	g.world_texture = WG.make_texture(grid); g.world_image = g.world_texture.get_image()
	g.player_pos = Vector2(596 * 16, 104 * 16 - 28)
	g._update_camera()
	g.notice = "Hanging vines - cliff edges and cave ceilings"; g.notice_timer = 30
	await capture(g)
	g.player_pos = Vector2(580 * 16, 104 * 16 - 28)
	g._update_camera()
	await capture(g)
	var review := Image.create(1280, 1440, false, Image.FORMAT_RGBA8)
	for i in range(captures.size()): review.blit_rect(captures[i], Rect2i(0, 0, 1280, 720), Vector2i(0, i * 720))
	review.save_png("res://tests/hanging_vines_review.png")
	g.free()
	print("VINE_PREVIEW saved cliff and cave review")
	quit()
const WG = preload("res://scripts/world_gen.gd")
