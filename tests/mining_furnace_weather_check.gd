extends "res://tests/tool_progression_check.gd"

const Blend = preload("res://scripts/weather_blend.gd")
const Furnaces = preload("res://scripts/furnace_system.gd")

func fresh(game) -> void:
	fixture(game)
	game.tool_wear.uses.clear()
	game.weather_blend.reset("Clear", 0)
	game.furnaces.focus_key = ""
	game.interactions.close()

func target(game, tile: Vector2i) -> Vector2:
	return Vector2(tile * 16) + Vector2(8, 8) - game.camera_pos

func sword_checks(game) -> void:
	fresh(game)
	game.inventory = {"Sword": 1, "Iron Sword": 1}
	for item in ["Sword", "Copper Sword", "Iron Sword"]:
		game.inventory[item] = 1
		game._equip_inventory_item(item)
		for id in [1, 2, 3, 5, 6, 7, 8, 9, 12, 13, 16, 17, 20, 21, 22, 23, 24, 25, 26, 27, 30, 33, 34, 35]:
			var tile := Vector2i(601, 79)
			game._edit_tile(tile, id)
			game.mining_cooldown = 0
			game._mine(target(game, tile))
			check(WG.tile_at(game.world["tiles"], tile.x, tile.y) == id and game.world["drops"].is_empty(), "Sword cannot mine tile %d: %s" % [id, item])
	game.world["torches"]["601,79"] = true
	game._mine(target(game, Vector2i(601, 79)))
	check(game.world["torches"].has("601,79"), "Sword cannot recover a torch")
	game._edit_tile(Vector2i(601, 79), 2)
	game.attack_cooldown = 0
	game._primary_action(target(game, Vector2i(601, 79)))
	check(game.tool_action_kind == "attack" and WG.tile_at(game.world["tiles"], 601, 79) == 2, "Sword clicks swing without digging")
	# Combat must have line of sight; the previous mining-refusal fixture left
	# a full dirt block between the player and this combat target.
	game._edit_tile(Vector2i(601, 79), 0)
	game.attack_cooldown = 0
	game.world["creatures"] = [{"alive": true, "hp": 100, "x": game.player_pos.x + 35, "y": game.player_pos.y + 11}]
	game._primary_action(target(game, Vector2i(602, 79)))
	check(game.world["creatures"][0]["hp"] == 64, "Iron sword still deals combat damage")
	print("SWORDS all terrain, scenery tiles, torches and actual combat checked")

func soil_seconds(game, item: String, fps: int) -> float:
	fresh(game)
	game.inventory = {item: 1}
	game._equip_inventory_item(item)
	var tile := Vector2i(601, 80)
	game._edit_tile(tile, 2)
	var point := target(game, tile)
	mouse(game, point, true)
	check((WG.tile_at(game.world["tiles"], 601, 80) == 0 if Tools.mining_hits(item, 2) == 1 else WG.tile_at(game.world["tiles"], 601, 80) == 2 and game.mining_feedback_progress > 0), "Soil starts with visible partial progress: " + item)
	var frames := 0
	while WG.tile_at(game.world["tiles"], 601, 80) != 0 and frames < fps * 6:
		game._update_held_actions(1.0 / fps)
		frames += 1
	mouse(game, point, false)
	check(game.world["drops"].size() == 1, "One dirt drop after completed digging: " + item)
	return frames / float(fps)

func shovel_checks(game) -> void:
	for fps in [30, 60, 144]:
		var times := []
		var pick_times := []
		for item: String in Tools.progression("Shovel"):
			var pick := "Pickaxe" if item == "Shovel" else item.replace("Shovel", "Pickaxe")
			var shovel_time := soil_seconds(game, item, fps)
			var pick_time := soil_seconds(game, pick, fps)
			pick_times.append(pick_time)
			check(shovel_time < pick_time * 0.65, "Matching shovel digs substantially faster at %d FPS: %s" % [fps, item])
			times.append(shovel_time)
		check(times[2] < times[0] and times[4] <= times[2] and times[6] <= times[5], "Shovel material progression changes actual digging speed")
		check(times[0] < float(pick_times.min()), "Even a wood shovel beats every pickaxe on soil")
		print("SOIL fps=", fps, " shovel_seconds=", times)
	for item: String in Tools.progression("Shovel"):
		check(not Tools.can_harvest(item, 3) and not Tools.can_harvest(item, 22), "Shovels cannot harvest pickaxe-tier rock/ore")
		check(game.tool_textures[item].get_image().get_pixel(16, 32).a > 0, "Native shovel retains hand grip")
	fresh(game)
	game.inventory = {"Shovel": 1}
	game._equip_inventory_item("Shovel")
	game._edit_tile(Vector2i(601, 80), 2)
	game._mine(target(game, Vector2i(601, 80)))
	var partial: Dictionary = game.world["mining_damage"].duplicate(true)
	game.save_path = "user://galaxis_mining_furnace_weather_check.json"
	game._save_game()
	game._load_game()
	while game.scene_name == "loading": await process_frame
	check(game.world["mining_damage"].has("601,80") and int(game.world["mining_damage"]["601,80"]["id"]) == int(partial["601,80"]["id"])
		and is_equal_approx(float(game.world["mining_damage"]["601,80"]["work"]), float(partial["601,80"]["work"])), "Partial dirt excavation survives a save")
	for _hit in range(2):
		game.mining_cooldown = 0
		game._mine(target(game, Vector2i(601, 80)))
	check(game.tool_wear.remaining("Shovel", game.inventory) == 58, "One shovel durability spent per completed soil block")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(game.save_path))

func furnace_checks(game) -> void:
	fresh(game)
	game._edit_tile(Vector2i(603, 79), 35)
	game._edit_tile(Vector2i(604, 79), 37)
	game.inventory = {"Copper Ore": 2, "Coal Ore": 2}
	game.stations.open({"name": "Furnace", "tile": Vector2i(603, 79)})
	game.stations.deposit("Copper Ore", 1)
	game.stations.deposit("Coal Ore", 1)
	var machine: Dictionary = game.stations.state()
	check(game.inventory["Copper Ore"] == 1 and game.inventory["Coal Ore"] == 1 and game.inventory.get("Copper Ingot", 0) == 0, "Ore/fuel stored once; no instant ingot")
	game._process(2.5)
	check(is_equal_approx(machine["heat"], 0.5) and machine["jobs"][0]["elapsed"] == 0, "Furnace heats while its slot window is open")
	game._process(2.5)
	game._process(7.9)
	check(machine["output"].is_empty(), "Copper cannot finish before heating plus eight seconds")
	game._process(0.1)
	check(machine["output"].get("Copper Ingot", 0) == 1 and game.inventory.get("Copper Ingot", 0) == 0, "Finished ingot waits at its furnace")
	game._gameplay_ui_click(game.stations.slot_rect("output", 0).get_center(), MOUSE_BUTTON_RIGHT)
	check(game.inventory.get("Copper Ingot", 0) == 1 and machine["output"].is_empty(), "Output slot transfers finished ingot exactly once")
	game.stations.deposit("Copper Ore", 1)
	game.stations.deposit("Coal Ore", 1)
	game._process(3.0)
	game.save_path = "user://galaxis_furnace_timer_check.json"
	game.weather = "Rain"
	game.weather_blend.update("Rain", 4.0, 0)
	var rain_before: float = game.weather_blend.rain()
	game._save_game()
	game._load_game()
	while game.scene_name == "loading": await process_frame
	machine = game.world["furnaces"]["603,79"]
	check(is_equal_approx(machine["jobs"][0]["elapsed"], 3.0), "Smelting progress survives reload")
	check(is_equal_approx(game.weather_blend.rain(), rain_before), "Weather transition survives reload")
	game.stations.open({"name": "Furnace", "tile": Vector2i(603, 79)})
	game.furnaces.update(5.0)
	game.stations.withdraw("output", 0)
	check(game.inventory["Copper Ingot"] == 2, "Reloaded job completes once")
	game.inventory = {"Iron Ore": 1, "Coal Ore": 1, "Pickaxe": 1}
	game.stations.deposit("Iron Ore")
	game.stations.deposit("Coal Ore")
	game.furnaces.update(2.0)
	game.stations.close()
	game._equip_inventory_item("Pickaxe")
	for hit in range(Tools.mining_hits("Pickaxe", 35)):
		game.mining_cooldown = 0
		game._mine(target(game, Vector2i(603, 79)))
	var recovered := {}
	for drop: Dictionary in game.world["drops"]:
		recovered[drop["item"]] = int(recovered.get(drop["item"], 0)) + int(drop["count"])
	check(recovered.get("Iron Ore", 0) == 1 and recovered.get("Coal Ore", 0) == 1 and recovered.get("Furnace", 0) == 1, "Mining furnace returns unfinished ingredients and station")
	check(not game.world["furnaces"].has("603,79"), "Removed furnace cannot finish/refund again")
	game._edit_tile(Vector2i(603, 79), 35)
	game._edit_tile(Vector2i(604, 79), 37)
	game.inventory = {"Copper Ore": 35, "Coal Ore": 35}
	game.stations.open({"name": "Furnace", "tile": Vector2i(603, 79)})
	game.stations.deposit("Copper Ore")
	game.stations.deposit("Coal Ore")
	game.furnaces.update(300.0)
	game.stations.withdraw("output", 0)
	game.stations.withdraw("output", 0)
	check(game.inventory["Copper Ingot"] == 35, "Automatic batches and repeated output clicks cannot duplicate ingots")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(game.save_path))
	print("FURNACE automatic inputs, heat, output slots, saved progress and mining recovery checked")

func weather_checks(game) -> void:
	var blend := Blend.new()
	blend.reset("Clear", 0)
	blend.update("Rain", 0, 0)
	check(blend.rain() == 0 and blend.coverage() == 0.3, "No instant rain/cloud jump")
	blend.update("Rain", 6, 0)
	check(is_equal_approx(blend.rain(), 0.5) and blend.coverage() > 0.3 and blend.coverage() < 1, "Rain, clouds and darkness build gradually")
	var midway: Dictionary = blend.weights.duplicate()
	blend.update("Snow", 0, 0)
	for condition: String in Blend.COVER:
		check(is_equal_approx(blend.amount(condition), float(midway.get(condition, 0.0))), "Interrupted transition stays continuous: " + condition)
	blend.update("Snow", 12, 0)
	check(blend.snow() == 1 and blend.rain() == 0, "Rain transitions fully into snow")
	blend.update("Clear", 6, 0)
	check(is_equal_approx(blend.snow(), 0.5), "Weather fades out gradually")
	for fps in [30, 60, 144]:
		blend.reset("Clear", 0)
		for _frame in range(fps * 6):
			blend.update("Storm", 1.0 / fps, 0)
		check(absf(blend.rain() - 0.5) < 0.0001, "Frame-rate-independent weather transition")
	var calm := Blend.rain_velocity(0)
	var light := Blend.rain_velocity(12)
	var strong := Blend.rain_velocity(70)
	check(calm.x == 0 and light.x > 0 and strong.x > light.x and Blend.rain_velocity(-70).x < 0, "Rain follows both wind directions and strength")
	blend.reset("Rain", 0)
	blend.update("Rain", 1, 4)
	check(blend.rain() == 0 and blend.snow() == 0 and blend.amount("Ashfall") > 0, "Volcanic transition never carries liquid precipitation")
	fresh(game)
	game.weather = "Rain"
	game._update_water(0.0)
	check(game._rain_strength() == 0, "Real weather starts dry")
	game._update_water(6.0)
	check(is_equal_approx(game._rain_strength(), 0.5), "Real precipitation uses transitional intensity")
	game.weather = "Clear"
	game._update_water(0.0)
	check(is_equal_approx(game._rain_strength(), 0.5), "Clearing does not switch rain off immediately")
	game._update_water(12.0)
	check(game._rain_strength() == 0, "Rain finishes clearing")
	for id in range(20, 27):
		var image: Image = game.ores.terrain_image_for(id, 0)
		check(image.get_pixel(0, 0).a == 0, "Ore terrain has transparent native mineral overlay")
	print("WEATHER transition continuity, intensity, wind direction/strength, climate safety and natural ores checked")

func run_check() -> void:
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	await game._open_planet(0)
	game.set_process(false)
	sword_checks(game)
	await shovel_checks(game)
	await furnace_checks(game)
	weather_checks(game)
	print("MINING_FURNACE_WEATHER failures=", failures)
	quit(0 if failures == 0 else 1)
