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
	game.star_index = 0
	game._make_system()
	for climate in [3, 6, 4]:
		await game._open_planet(climate)
		game.world["creatures"] = []
		game.world.erase("npc")
		game.weather = "Ember Storm" if climate == 4 else "Clear"
		game.time_of_day = 0.25
		game.cloud_cover = game._cloud_target()
		game.animation_clock = 42.0
		game.inventory = {"Netherite Pickaxe": 1, "Diamond Pickaxe": 1, "Gold Pickaxe": 1, "Torch": 20}
		game._equip_inventory_item("Netherite Pickaxe")
		game._wear_pickaxe("Netherite Pickaxe", 120)
		if climate == 3:
			for entry: Dictionary in game.world["ground_life"]:
				if entry["species"] == "saguaro":
					game.player_pos = Vector2(float(entry["x"]) + 40, float(entry["y"]) - 28)
					break
		if climate == 6:
			var pillar: Dictionary = game.world["ice_pillars"][int(game.world["ice_pillars"].size() / 2)]
			game.player_pos = Vector2((int(pillar["x"]) + 12) * 16, 98 * 16 - 28)
		game._update_camera()
		game.notice_timer = 0.0
		await capture(game, ["", "", "", "desert_flora_preview", "volcanic_ash_preview", "", "glacial_spires_preview"][climate])
	await game._open_planet(0)
	game.time_of_day = 0.25
	game.weather = "Clear"
	game.weather_blend.reset("Clear", int(game.world.get("climate", 0)))
	var path: Array = game.world["cave_entrances"][0]
	game.player_pos = Vector2(int(path[0][0]) * 16, int(path[0][1]) * 16 - 28)
	game._update_camera()
	game.notice_timer = 0.0
	await capture(game, "angled_cave_preview")
	print("PLANET_EXPANSION_RENDERED desert, ice spires, volcanic ash, angled cave")
	quit()
