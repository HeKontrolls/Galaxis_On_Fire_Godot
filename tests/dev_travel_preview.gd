extends SceneTree
func _initialize() -> void: call_deferred("run")
func capture(g,name: String) -> void:
	g.queue_redraw()
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://tests/"+name+".png")
func run() -> void:
	var g=load("res://main.tscn").instantiate();root.add_child(g);g.set_process(false);await process_frame
	g.scene_name="galaxy";g.window_positions.dev=Vector2(660,180);g._key_pressed(KEY_F3)
	await capture(g,"dev_travel_galaxy")
	g._open_system(3)
	await capture(g,"dev_travel_system")
	print("DEV_TRAVEL_PREVIEW galaxy and solar system overlays rendered")
	quit()
