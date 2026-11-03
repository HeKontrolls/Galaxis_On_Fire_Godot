extends SceneTree
const WG = preload("res://scripts/world_gen.gd")
const Cave = preload("res://scripts/underground.gd")
func _initialize() -> void: call_deferred("run_preview")
func run_preview() -> void:
	root.size = Vector2i(1280, 720)
	var g = load("res://main.tscn").instantiate()
	root.add_child(g); g.set_process(false)
	await g._open_planet(0)
	g.dev_invulnerable = true; g.equipped_tool = "Hand"; g.inventory = {}
	var review := Image.create(1280, 1440, false, Image.FORMAT_RGBA8)
	review.fill(Color("111b22"))
	for region in range(7):
		var at := Vector2(600 * 16, (WG.HEIGHT - 25) * 16)
		for entry in g.world.cave_life:
			if region == 6: break # Show the bottom lava sea itself.
			if int(entry.kind) in [0, 4] and Cave.biome(g.world, int(entry.x), int(entry.y)) == region:
				at = Vector2(int(entry.x) * 16 + 8, int(entry.y) * 16); break
		g.player_pos = at + Vector2(40, -16)
		g.camera_pos = (at - Vector2(640, 360)).clamp(Vector2.ZERO, Vector2(WG.WIDTH * 16 - 1280, WG.HEIGHT * 16 - 720))
		g.environment.invalidate()
		g.animation_clock = 0.4
		g.notice = "%s | %d blocks below the surface" % [Cave.NAMES[region], int(at.y / 16) - int(g.world.surface[clampi(int(at.x / 16), 0, WG.WIDTH - 1)])]
		g.notice_timer = 30
		g.queue_redraw()
		await process_frame
		await RenderingServer.frame_post_draw
		var shot: Image = root.get_texture().get_image()
		if region == 3: shot.save_png("res://tests/underground_crystals.png")
		shot.resize(640, 360, Image.INTERPOLATE_NEAREST)
		review.blit_rect(shot, Rect2i(0, 0, 640, 360), Vector2i((region % 2) * 640, int(region / 2) * 360))
	review.save_png("res://tests/underground_review.png")
	print("UNDERGROUND_PREVIEW biomes=7")
	g.free(); quit()
