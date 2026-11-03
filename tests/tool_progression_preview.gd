extends SceneTree

const WG = preload("res://scripts/world_gen.gd")
const Tools = preload("res://scripts/tool_catalog.gd")


func _initialize() -> void:
	call_deferred("preview")


func capture(game, name: String) -> void:
	game.queue_redraw()
	await process_frame
	await process_frame
	root.get_texture().get_image().save_png("res://tests/%s.png" % name)


func preview() -> void:
	var game: Node2D = load("res://main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	await game._open_planet(0)
	game.set_process(false)
	game.world["creatures"] = []
	game.world["drops"] = []
	game.world.erase("npc")
	game.weather = "Clear"
	game.weather_blend.reset("Clear", int(game.world.get("climate", 0)))
	game.time_of_day = 0.25
	game.cloud_cover = 0.3
	game.notice_timer = 0
	game.inventory = {"Pickaxe": 1, "Sword": 1, "Axe": 1, "Copper Ingot": 24,
		"Iron Ingot": 32, "Stick": 40, "Planks": 32, "Cobblestone": 6}
	for item in Tools.variants():
		game.inventory[item] = 1
	game._edit_tile(Vector2i(game.player_pos / 16) + Vector2i(3, 0), 34)
	game._edit_tile(Vector2i(game.player_pos / 16) + Vector2i(4, 0), 36)
	game._edit_tile(Vector2i(game.player_pos / 16) + Vector2i(-3, 0), 35)
	game._edit_tile(Vector2i(game.player_pos / 16) + Vector2i(-2, 0), 37)
	game._equip_inventory_item("Pickaxe")
	game._toggle_crafting(1)
	game.recipe_index = 22
	await capture(game, "tool_progression_stone_crafting")
	game.crafting_open = false
	game._equip_inventory_item("Copper Pickaxe")
	game._toggle_crafting(2)
	game.recipe_index = 16
	await capture(game, "tool_progression_copper_crafting")
	game.recipe_index = 19
	await capture(game, "tool_progression_iron_crafting")
	game.crafting_open = false
	game._equip_inventory_item("Iron Pickaxe")
	game.inventory_open = true
	await capture(game, "tool_progression_backpack")
	game.inventory_open = false
	# A compact comparison uses rendered in-game sprites at the same grip,
	# body position and point in the swing, rather than separate art mockups.
	var sheet := Image.create(1200, 250, false, Image.FORMAT_RGBA8)
	for index in range(4):
		game._equip_inventory_item(["Pickaxe", "Stone Pickaxe", "Copper Pickaxe", "Iron Pickaxe"][index])
		game._begin_tool_action("mine", game.player_pos + Vector2(40, 25))
		game.tool_action_timer = game.tool_action_duration * 0.52
		game._show_notice(Tools.display_name(game.equipped_tool) + " - " + Tools.summary(game.equipped_tool))
		game.queue_redraw()
		await process_frame
		await process_frame
		var screen: Image = root.get_texture().get_image()
		var actor: Vector2 = game.player_pos - game.camera_pos
		sheet.blit_rect(screen, Rect2i(Vector2i(actor) - Vector2i(125, 90), Vector2i(300, 220)), Vector2i(index * 300, 30))
		# Keep the real HUD tier label above each matching in-game pose.
		sheet.blit_rect(screen, Rect2i(16, 43, 244, 26), Vector2i(index * 300 + 28, 2))
	sheet.save_png("res://tests/tool_progression_swings.png")
	print("RENDERED stone/copper/iron crafting pages, backpack and wood/stone/copper/iron mining poses")
	quit(0)
