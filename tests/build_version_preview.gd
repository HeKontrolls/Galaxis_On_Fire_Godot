extends SceneTree
func _initialize()->void:call_deferred("run")
func run()->void:
	var g=load("res://main.tscn").instantiate();root.add_child(g);g.set_process(false);await process_frame
	g.scene_name="menu";g.notice_timer=0;g.queue_redraw()
	await process_frame;await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://tests/build_version_menu.png")
	print("BUILD_PREVIEW title=",g.get_window().title)
	quit()
