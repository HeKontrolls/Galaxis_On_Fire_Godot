extends SceneTree
const WG = preload("res://scripts/world_gen.gd")
class Labels:
	extends Node2D
	func _draw() -> void:
		var f := ThemeDB.fallback_font
		draw_string(f, Vector2(75, 205), "SAND + GRAVEL", HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color("fff0c9"))
		draw_string(f, Vector2(75, 230), "Unsupported blocks fall and settle", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("e6edf1"))
		draw_string(f, Vector2(535, 175), "CONNECTED WATER PRESSURE", HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color("c4edff"))
		draw_string(f, Vector2(535, 200), "Water rises up the return shaft", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("e6edf1"))
func _initialize() -> void: call_deferred("run")
func run() -> void:
	root.size = Vector2i(1280, 720)
	var g = load("res://main.tscn").instantiate()
	root.add_child(g); g.set_process(false); await g._open_planet(0)
	var grid := PackedByteArray(); grid.resize(WG.WIDTH * WG.HEIGHT)
	var surface := PackedInt32Array(); surface.resize(WG.WIDTH); surface.fill(100)
	for x in range(WG.WIDTH):
		for y in range(100, 110): WG.set_tile(grid, x, y, 3 if y == 100 else 2)
	for y in range(80, 100):
		for x in [609, 615, 625, 631]:
			if x in [609, 631] or y < 98: WG.set_tile(grid, x, y, 3)
		for x in range(610, 615):
			if y >= 82: WG.set_tile(grid, x, y, 4)
	for x in range(610, 631):
		for y in range(98, 100): WG.set_tile(grid, x, y, 4)
	for x in [586, 587, 592, 593]:
		for y in range(87, 90): WG.set_tile(grid, x, y, 5 if x < 590 else 45)
		WG.set_tile(grid, x, 90, 3)
	g.world = {"tiles": grid, "surface": surface, "seed": 17, "climate": 0, "spawn": Vector2(600 * 16, 1572),
		"creatures": [], "ground_life": [], "ground_life_version": 1, "ground_cover_version": 1,
		"surface_rocks_version": 1, "desert_flora_version": 1, "cave_life_version": 1, "vines_version": 1}
	g._reset_world_environment(); g.world_texture = WG.make_texture(grid); g.world_image = g.world_texture.get_image()
	g.player_pos = g.world.spawn; g.camera_pos = Vector2(576 * 16, 68 * 16)
	g.scene_name = "planet"; g.notice_timer = 0; g.time_of_day = 0.25; g.weather = "Clear"; g.weather_blend.reset("Clear", 0)
	g.water_sim.set_active_region(Vector2(621 * 16, 90 * 16))
	for i in range(450): g.water_sim.update(0.08)
	for x in [586, 587, 592, 593]: g._edit_tile(Vector2i(x, 90), 0)
	for i in range(30): g.sand_gravity.update(g, 1.0 / 60)
	g.environment.reset(g.world); g.environment.invalidate(); g.terrain_cache.reset(g)
	var labels := Labels.new(); root.add_child(labels)
	g.queue_redraw(); await process_frame; await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://tests/terrain_mechanics_preview.png")
	print("TERRAIN_PREVIEW falling=", g.sand_gravity.pieces.size(), " return_water=", g.water_sim.amount_at(Vector2i(628, 94)))
	labels.free(); g.free(); quit()
