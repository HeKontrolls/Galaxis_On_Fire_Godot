extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func capture(game, name: String) -> void:
	game.queue_redraw()
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://tests/" + name + ".png")

func run() -> void:
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.set_process(false)
	game.galaxy_seed = 713
	game.star_index = 0
	game._make_system()
	await game._open_planet(6)
	game.world["creatures"] = []
	game.world.erase("npc")
	game.weather = "Clear"
	game.weather_blend.reset("Clear", 6)
	game.time_of_day = 0.25
	game.cloud_cover = 0.35
	game.animation_clock = 42.0
	game.notice_timer = 0.0
	var chosen: Dictionary = {}
	var score := -1
	for spire: Dictionary in game.world["ice_pillars"]:
		var neighbors := 0
		for other: Dictionary in game.world["ice_pillars"]:
			if int(other["field"]) == int(spire["field"]):
				neighbors += 1
		if bool(spire["dominant"]) and int(spire["height"]) <= 41 and neighbors > score and int(spire["x"]) > 80 and int(spire["x"]) < 1120:
			chosen = spire
			score = neighbors
	if chosen.is_empty():
		chosen = game.world["ice_pillars"][0]
	var stand_x := int(chosen["x"]) + 13
	for x in range(stand_x, stand_x + 20):
		if int(game.world["tiles"][int(chosen["y"]) * 1200 + x]) == 6 and int(game.world["tiles"][(int(chosen["y"]) - 1) * 1200 + x]) == 0:
			stand_x = x
			break
	game.player_pos = Vector2(stand_x * 16, int(chosen["y"]) * 16 - 28)
	game._update_camera()
	await capture(game, "glacial_spires_ground_preview")
	game.camera_pos.y = int(chosen["y"]) * 16 - 662
	await capture(game, "frozen_needle_fields_preview")
	print("GLACIAL_PREVIEW x=", chosen["x"], " height=", chosen["height"], " seed=", game.world["seed"])
	game.queue_free()
	await process_frame
	quit()
