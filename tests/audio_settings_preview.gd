extends SceneTree


func _initialize() -> void:
	call_deferred("preview")


func preview() -> void:
	var game: Node2D = load("res://main.tscn").instantiate()
	game.settings_path = "user://galaxis_audio_preview_settings.json"
	root.add_child(game)
	await process_frame
	game.set_process(false)
	game.scene_name = "settings"
	game.settings_tab = "Audio"
	game.queue_redraw()
	await process_frame
	await process_frame
	root.get_texture().get_image().save_png("res://tests/audio_settings_preview.png")
	print("RENDERED saved master/effects/ambience volume controls and audition button")
	quit(0)
