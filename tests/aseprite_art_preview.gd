extends SceneTree

const WG = preload("res://scripts/world_gen.gd")

class ArtBoard extends Node2D:
	var game
	func label(value: String, at: Vector2, size: int = 16, color: Color = Color("d8e8eb")) -> void:
		draw_string(ThemeDB.fallback_font, at, value, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)
	func _draw() -> void:
		draw_rect(Rect2(0, 0, 1280, 720), Color("101c2b"))
		label("GALAXIS ON FIRE / FRONTIER SPRITE SET", Vector2(28, 40), 26, Color("efc384"))
		label("Designed and exported in Aseprite  /  Layered sources + tagged animation timelines", Vector2(28, 68), 15)
		for card in [Rect2(24, 92, 600, 268), Rect2(644, 92, 612, 268), Rect2(24, 382, 1232, 316)]:
			draw_rect(card, Color("182b3b"))
			draw_rect(card, Color("37596b"), false, 1)
		label("CAPTAIN", Vector2(44, 125), 19, Color("7ec8c2"))
		label("ROBOT R0-VR", Vector2(344, 125), 19, Color("efc384"))
		for index in range(3):
			var action: String = ["idle", "walk", "jump"][index]
			var hero: Texture2D = game.player_frames[action + "_east"][0 if index == 0 else 3]
			draw_texture_rect(hero, Rect2(40 + index * 84, 140, 96, 120), false)
			label(action.capitalize(), Vector2(48 + index * 84, 285), 13)
			var elder: Texture2D = game.elder_frames["idle_east" if index == 0 else "walk_east"][0 if index == 0 else index]
			draw_texture_rect(elder, Rect2(340 + index * 84, 140, 120, 120), false)
			label("Idle" if index == 0 else "Walk", Vector2(348 + index * 84, 285), 13)
		label("38 frames / idle, walk, jump", Vector2(44, 316), 14)
		label("12 frames / blink + walking", Vector2(344, 316), 14)
		label("WORKBENCH", Vector2(670, 125), 18, Color("efc384"))
		label("FURNACE", Vector2(978, 125), 18, Color("efc384"))
		draw_texture_rect(game.station_frames["workbench"][0], Rect2(710, 148, 128, 128), false)
		draw_texture_rect(game.station_frames["furnace"][1], Rect2(1014, 148, 128, 128), false)
		label("Pegboard, vice, saw, work lamp", Vector2(664, 316), 14)
		label("Stone shell, grate, animated fire", Vector2(968, 316), 14)
		var names: Array = game.tool_textures.keys()
		for index in range(names.size()):
			var item: String = names[index]
			var rect := Rect2(32 + (index % 7) * 175, 392 + (index / 7) * 149, 165, 140)
			draw_rect(rect, Color("203648"))
			draw_texture_rect(game.tool_textures[item], Rect2(rect.position + Vector2(50, 12), Vector2(64, 80)), false)
			label(game.Tools.display_name(item), rect.position + Vector2(8, 123), 13)


func _initialize() -> void:
	call_deferred("preview")


func capture(game, name: String) -> void:
	if name == "aseprite_gameplay_swing" and "--all" not in OS.get_cmdline_user_args():
		return
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
	var board := ArtBoard.new()
	board.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	board.game = game
	root.add_child(board)
	await capture(board, "aseprite_art_review")
	board.queue_free()
	await process_frame
	var grid := PackedByteArray()
	grid.resize(WG.WIDTH * WG.HEIGHT)
	for x in range(WG.WIDTH):
		for y in range(80, WG.HEIGHT):
			WG.set_tile(grid, x, y, 1 if y == 80 else 2)
	var surface := PackedInt32Array()
	surface.resize(WG.WIDTH)
	surface.fill(80)
	game.world = {"tiles": grid, "surface": surface, "seed": 713, "climate": 0,
		"spawn": Vector2(600 * 16, 80 * 16 - 28), "crops": {}, "creatures": [], "drops": [],
		"torches": {}, "placed_chests": {}, "forest_density_version": 2,
		"npc": {"x": 605.0 * 16, "y": 80.0 * 16 - 29, "direction": 1, "home_x": 605.0 * 16, "move_timer": 2.0}}
	game._reset_world_environment()
	game.world_texture = WG.make_texture(grid)
	game.world_image = game.world_texture.get_image()
	game.player_pos = game.world["spawn"]
	game.player_grounded = true
	game._update_camera()
	for station in [[609, 34], [613, 35]]:
		game._edit_tile(Vector2i(station[0], 79), station[1])
		game._edit_tile(Vector2i(station[0] + 1, 79), station[1] + 2)
	game.weather = "Clear"
	game.weather_blend.reset("Clear", int(game.world.get("climate", 0)))
	game.time_of_day = 0.25
	game.cloud_cover = 0.3
	game.notice_timer = 0
	game.animation_clock = 0.3
	game.inventory = {"Copper Pickaxe": 1, "Watering Can": 1}
	game._equip_inventory_item("Copper Pickaxe")
	await capture(game, "aseprite_gameplay")
	game._begin_tool_action("mine", game.player_pos + Vector2(40, 20))
	game.tool_action_timer = game.tool_action_duration * 0.5
	await capture(game, "aseprite_gameplay_swing")
	print("RENDERED Aseprite art review and cast/stations in game; --all includes the tool-action screenshot")
	quit(0)
