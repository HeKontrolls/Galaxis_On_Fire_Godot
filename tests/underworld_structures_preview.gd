extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	root.size = Vector2i(1280, 720)
	var g = load("res://main.tscn").instantiate()
	root.add_child(g); g.set_process(false)
	await g._open_planet(0)
	var fort: Dictionary = g.world.underworld_forts[2]
	g.player_pos = Vector2((int(fort.x) + 16) * 16, (1440 - 32) * 16 - 28)
	g.camera_pos = Vector2((float(fort.x) + float(fort.width) * 0.5) * 16 - 640, (1440 - 32) * 16 - 460)
	g.environment.invalidate(); g.notice_timer = 0; g.queue_redraw()
	await process_frame; await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://tests/underworld_fortress.png")
	print("UNDERWORLD_PREVIEW complete")
	g.free(); quit()
