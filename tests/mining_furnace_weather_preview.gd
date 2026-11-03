extends SceneTree
const WG = preload("res://scripts/world_gen.gd")

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
	game.galaxy_seed = 741927
	await game._open_planet(0)
	game.world["creatures"] = []
	game.world.erase("npc")
	game.time_of_day = 0.25
	game.weather = "Clear"
	game.weather_blend.reset("Clear", 0)
	game.cloud_cover = 0.3
	game.inventory = {"Iron Shovel": 1, "Iron Pickaxe": 1, "Copper Ore": 3, "Iron Ore": 4, "Coal Ore": 7}
	game._equip_inventory_item("Iron Pickaxe")
	game._equip_inventory_item("Iron Shovel")
	var x := floori(game.player_pos.x / 16)
	var ground := int(game.world["surface"][x])
	for column in range(x - 4, x + 7):
		for y in range(ground - 3, ground + 3):
			game._edit_tile(Vector2i(column, y), 0 if y < ground else (1 if y == ground else 2), false)
	game.world_texture.update(game.world_image)
	game.player_pos = Vector2(x * 16, ground * 16 - 28)
	game._edit_tile(Vector2i(x + 3, ground - 1), 35)
	game._edit_tile(Vector2i(x + 4, ground - 1), 37)
	game._update_camera()
	game.window_positions["crafting"] = Vector2(360, 90)
	game.recipe_tab = 2
	game.recipe_index = 10
	game._craft()
	game._craft()
	game.recipe_index = 9
	game._craft()
	game.recipe_index = 10
	game.crafting_open = true
	game.furnaces.update(2.5)
	game.notice_timer = 0
	await capture(game, "furnace_heating_preview")
	game.furnaces.update(6.5)
	await capture(game, "furnace_smelting_preview")
	game.furnaces.update(7.0)
	await capture(game, "furnace_ready_preview")
	game.crafting_open = false
	var soil := Vector2i(x + 1, ground)
	game._mine(Vector2(soil * 16) + Vector2(8, 8) - game.camera_pos)
	game.mining_cooldown = 0
	game._mine(Vector2(soil * 16) + Vector2(8, 8) - game.camera_pos)
	game.tool_action_timer = game.tool_action_duration * 0.5
	await capture(game, "shovel_digging_preview")
	game.tool_action_timer = 0
	game.mining_feedback_timer = 0
	game.weather = "Rain"
	for phase in [0.0, 6.0, 12.0]:
		game.weather_blend.reset("Clear", 0)
		game.weather_blend.update("Rain", phase, 0)
		game.cloud_cover = game.weather_blend.coverage()
		game.animation_clock = 42.0
		game.wind_cache_clock = -1
		game.wind_drift = 20
		await capture(game, "weather_transition_%02d_preview" % int(phase))
	for direction in [-1, 1]:
		for clock in range(0, 4000, 3):
			game.animation_clock = float(clock)
			game.wind_cache_clock = -1
			if game._wind_speed() * direction > 40:
				break
		await capture(game, "wind_rain_left_preview" if direction < 0 else "wind_rain_right_preview")
	print("RENDERED furnace heating/smelting/output, shovel digging, weather fade and both rain directions")
	quit()
