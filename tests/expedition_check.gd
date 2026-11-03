extends SceneTree

const WG = preload("res://scripts/world_gen.gd")
var failures := 0
var captures: Array[Image] = []

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		printerr(message)

func talk(g) -> void:
	g.stations.close()
	g.player_pos = Vector2(g.world["npc"]["x"], g.world["npc"]["y"])
	g.dialogue_open = false
	g._talk_to_explorer()
	g._talk_to_explorer()

func snapshot(g) -> void:
	if "--preview" not in OS.get_cmdline_user_args():
		return
	g._update_camera()
	g.notice_timer = 0
	g.queue_redraw()
	await process_frame
	await RenderingServer.frame_post_draw
	captures.append(root.get_texture().get_image())

func workshop_craft(g, tile: Vector2i, item: String) -> void:
	g.stations.open({"name": "Workbench", "tile": tile})
	var recipe_index := -1
	for i in range(g.RECIPES.size()):
		if g.RECIPES[i]["out"] == item:
			recipe_index = i
			break
	check(recipe_index >= 0, "Recipe missing: " + item)
	var recipe: Dictionary = g.RECIPES[recipe_index]
	for ingredient: String in recipe["needs"]:
		g._add_item(ingredient, int(recipe["needs"][ingredient]))
		check(g.stations.deposit(ingredient, int(recipe["needs"][ingredient])), "Recipe ingredient deposit failed")
	check(g.stations.craft(recipe_index), "Workbench must craft " + item)
	var output: Dictionary = g.stations.state()["output"]
	g._add_item(item, int(output[item]))
	output.erase(item)
	g.stations.close()

func run() -> void:
	var g = load("res://main.tscn").instantiate()
	g.save_path = "user://expedition_check.json"
	g.settings_path = "user://expedition_check_settings.json"
	root.add_child(g)
	await process_frame
	g.set_process(false)
	g.new_game_name = "Expedition test"
	g.seed_text = "741927"
	g._start_new_game()
	check(g.inventory.is_empty(), "New expedition must still start with empty inventory")
	check(not g.expedition.can_land(3), "Desert must not strand a new captain without basic resources")
	await g._open_planet(0)
	check(g.expedition.home() and g.expedition.stage() == 0, "First landing must initialize the campaign")
	var crash_bounds: Array = g.expedition.data.get("crash_site_bounds", [])
	check(crash_bounds.size() == 3 and not g._collides(g.player_pos), "New expeditions must spawn safely beside the flat crash site")
	if crash_bounds.size() == 3:
		var crash_center := (int(crash_bounds[0]) + int(crash_bounds[1])) / 2
		check(g._outdoor_dirt_y(crash_center) == -1, "Impact floor must stay scraped bare under the pod")
	check(g.expedition.texture("ship_damaged").get_size() == Vector2(192, 112), "Crashed escape pod must use its larger native canvas")
	check(g.elder_frames["idle_east"][0].get_size() == Vector2(48, 48), "Robot guide must replace the elder's runtime artwork")
	var untouched: PackedByteArray = g.world["tiles"].duplicate()
	g.expedition.data.erase("pod_layout_version")
	g.expedition.prepare_pod()
	check(g.world["tiles"] == untouched and g.expedition.stage() == 0, "Pod layout migration must preserve terrain and quest stage")
	g.player_pos = g.expedition.point("ship") + Vector2(125, -28)
	g.player_pos.y = g._walkable_y(floori(g.player_pos.x / 16)) - 28
	check(g.expedition.near_pod(), "The larger pod must be usable from its outer edge")
	g.player_pos = g.expedition.point("ship") - Vector2(60, 28)
	await snapshot(g)
	if not captures.is_empty():
		var crash_image: Image = captures.pop_back()
		crash_image.save_png("res://tests/crash_site_preview.png")
	check(g.expedition.guardian_alive(), "Fresh salvage room must have its sentinel")
	var original_site: Array = g.expedition.data["site"].duplicate()
	var creatures_before: int = g.world["creatures"].size()
	g.expedition.prepare()
	check(g.world["creatures"].size() == creatures_before, "Preparing again must not duplicate sentinel or reset terrain")
	g._leave_planet()
	check(g.scene_name == "planet", "G must not bypass ship repair")
	g.player_pos = Vector2(g.world["npc"]["x"], g.world["npc"]["y"])
	g._talk_to_explorer()
	await snapshot(g)
	g._talk_to_explorer()
	check(g.expedition.stage() == 1, "Elder introduction must begin supplies stage")
	talk(g)
	check(g.expedition.stage() == 1, "Incomplete objectives must not advance")
	for item: String in ["Wood", "Stone"]:
		g._collect_drop({"item": item, "count": 20 if item == "Wood" else 12, "x": 0, "y": 0})
	g.inventory["Wood"] = 0
	check(g.expedition.ready(), "Gathering credit must survive spending wood")
	talk(g)
	check(g.expedition.stage() == 2 and g.inventory.get("Torch", 0) == 4, "Supply reward must arrive once")
	talk(g)
	check(g.inventory.get("Torch", 0) == 4, "Repeated dialogue must not duplicate rewards")
	# Controlled flat workspace, isolated to this test world.
	var sx := int(g.world["spawn"].x / 16) + 24
	var sy := int(g.world["surface"][sx])
	for x in range(sx - 15, sx + 16):
		for y in range(sy - 8, sy + 2):
			g._edit_tile(Vector2i(x, y), 2 if y >= sy else 0)
	g.player_pos = Vector2(sx * 16, sy * 16 - 28)
	var bench := Vector2i(sx + 3, sy - 1)
	for item: String in ["Workbench", "Furnace"]:
		g._add_item(item, 1)
		g._place_station(bench if item == "Workbench" else bench + Vector2i(3, 0), item)
	workshop_craft(g, bench, "Stone Pickaxe")
	workshop_craft(g, bench, "Sword")
	check(g.expedition.ready(), "Placed stations and collected crafted tools must complete workshop stage")
	talk(g)
	check(g.expedition.stage() == 3 and g.inventory.get("Crop Seeds", 0) == 6, "Workshop reward must supply farming equipment and seeds")
	g.player_pos = Vector2(sx * 16, sy * 16 - 28)
	for x in range(sx - 6, sx + 6):
		var tile := Vector2i(x, sy - 5)
		g._edit_tile(tile, 33)
		g.expedition.placed("Planks", tile)
	g.world["torches"]["%d,%d" % [sx + 1, sy - 3]] = true
	g.expedition.update(1.0)
	check(g.expedition.data["shelter"], "Standing under a lit built roof must register shelter")
	var crop := Vector2i(sx - 3, sy - 1)
	g._edit_tile(crop + Vector2i.DOWN, 13)
	g._edit_tile(crop, 16)
	g.equipped_tool = "Hand"
	g._farm_interaction(crop, "Hand", "")
	check(g.expedition.ready(), "Harvesting mature corn must complete food objective")
	talk(g)
	workshop_craft(g, bench, "Copper Pickaxe")
	workshop_craft(g, bench, "Copper Sword")
	talk(g)
	check(g.expedition.stage() == 5, "Copper equipment must unlock deep salvage objective")
	workshop_craft(g, bench, "Iron Pickaxe")
	var site: Vector2 = g.expedition.point("site")
	g.player_pos = site - Vector2(44, 28)
	check(g.expedition.interact() and not g.expedition.data["core"], "Living sentinel must prevent core recovery")
	g.player_pos = site - Vector2(112, 28)
	await snapshot(g)
	g._save_game()
	await g._load_game()
	while g.scene_name == "loading":
		await process_frame
	check(g.expedition.stage() == 5 and g.expedition.guardian_alive() and not g.expedition.can_launch(), "Unfinished expedition and live guardian must survive save/load without unlocking travel")
	var guardian: Dictionary = {}
	for enemy: Dictionary in g.world["creatures"]:
		if enemy.get("quest_guardian", false):
			guardian = enemy
	var old_y := float(guardian["y"])
	g._update_population(0.1)
	check(absf(float(guardian["y"]) - old_y) < 18, "Underground sentinel must not teleport to the surface")
	g.equipped_tool = "Copper Sword"
	for hit in range(16):
		if not guardian["alive"]:
			break
		g.player_pos = Vector2(float(guardian["x"]) - 30, float(guardian["y"]) - 10)
		g.facing = 1
		g.mouse_aim_direction = Vector2.RIGHT
		g.attack_cooldown = 0
		g._attack(Vector2(guardian["x"], guardian["y"]))
	check(not guardian["alive"], "Sentinel must be defeatable through normal attacks")
	g.player_pos = site - Vector2(44, 28)
	g.expedition.interact()
	check(g.expedition.data["core"], "Defeated sentinel must allow core recovery")
	talk(g)
	check(g.expedition.stage() == 6, "Returning core must unlock repair objective")
	g.player_pos = g.expedition.point("ship") - Vector2(0, 28)
	g.expedition.interact()
	check(g.expedition.stage() == 6, "Missing parts must not repair ship")
	for item: String in ["Hull Plate", "Hull Plate", "Drive Coil"]:
		workshop_craft(g, bench, item)
	g.player_pos = g.expedition.point("ship") - Vector2(0, 28)
	check(g.expedition.interact(), "Ship must be interactable")
	check(g.expedition.stage() == 7 and int(g.inventory.get("Hull Plate", 0)) == 0 and int(g.inventory.get("Drive Coil", 0)) == 0, "Repair must consume exact parts and unlock travel")
	await snapshot(g)
	g._save_game()
	await g._load_game()
	while g.scene_name == "loading":
		await process_frame
	print("EXPEDITION_RESTORED stage=", g.expedition.stage(), " core=", g.expedition.data.get("core"), " site=", g.expedition.data.get("site"), " expected=", original_site)
	check(g.expedition.stage() == 7 and g.expedition.data["core"] and g.expedition.point("site") == Vector2(original_site[0], original_site[1]), "Progress, core and site must survive actual save/load")
	check(not g.expedition.guardian_alive(), "Loading must not respawn defeated sentinel")
	g._leave_planet()
	check(g.scene_name == "system", "Repaired ship must launch")
	check(str(g.expedition.data["carrier_world"]) == str(g.expedition.data["home"]), "Ship must orbit the actual visited planet")
	await snapshot(g)
	await g._open_planet(3)
	check(str(g.expedition.data["carrier_world"]) == g._world_key(), "Orbital ship must follow travel to another planet")
	check(g.expedition.stage() == 8, "Landing on another planet must finish first voyage")
	g.expedition.data.clear()
	check(g.expedition.can_launch() and g.expedition.can_land(6), "Legacy saves must retain unrestricted travel")
	if not captures.is_empty():
		var board := Image.create(1280, 720 * captures.size(), false, Image.FORMAT_RGBA8)
		for i in range(captures.size()):
			board.blit_rect(captures[i], Rect2i(0, 0, 1280, 720), Vector2i(0, i * 720))
		board.save_png("res://tests/expedition_preview.png")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(g.save_path))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(g.settings_path))
	g.queue_free()
	await process_frame
	print("EXPEDITION_CHECK stages=9 save_load=checked failures=", failures)
	quit(0 if failures == 0 else 1)
