extends SceneTree

const WG = preload("res://scripts/world_gen.gd")
const Life = preload("res://scripts/ground_life.gd")

class LifeBoard extends Node2D:
	var life
	func text(value: String, at: Vector2, size := 14, color := Color("d9e9eb")) -> void:
		draw_string(ThemeDB.fallback_font, at, value, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)
	func _draw() -> void:
		draw_rect(Rect2(0, 0, 1280, 720), Color("101e2b"))
		text("GALAXIS ON FIRE / FLORA + FAUNA", Vector2(24, 39), 27, Color("efc384"))
		text("Designed in Aseprite / 32 species and objects / 116 native frames / wind sway and player reactions", Vector2(24, 69), 15)
		for index in range(Life.SPECIES.size()):
			var origin := Vector2(24 + (index % 8) * 155, 92 + (index / 8) * 150)
			draw_rect(Rect2(origin, Vector2(145, 142)), Color("1e3543"))
			var name: String = Life.SPECIES[index]
			text(Life.ITEMS[index], origin + Vector2(5, 22), 12, Color("efc384") if Life.animal(name) or name in Life.ROCKS else Color("a6d39a"))
			text("Fauna" if Life.animal(name) else ("Rock" if name in Life.ROCKS else "Flora"), origin + Vector2(5, 39), 10)
			var canvas := Transform2D(0.0, Vector2(2, 2), 0, origin + Vector2(72, 118))
			draw_set_transform_matrix(canvas)
			Life.draw_sprite(self, life.frames[name][0], Vector2.ZERO, 0 if name in Life.ROCKS else 2.5)
			draw_set_transform_matrix(Transform2D.IDENTITY)
			text("%d frames" % life.frames[name].size(), origin + Vector2(5, 135), 10)
		text("Passable / harvest to collect / replant or release / biome-specific population / saved harvested state", Vector2(24, 702), 14)


func _initialize() -> void:
	call_deferred("preview")


func capture(node: Node2D, name: String) -> void:
	node.queue_redraw()
	await process_frame
	await process_frame
	root.get_texture().get_image().save_png("res://tests/" + name + ".png")


func show_world(game, climate: int, biome: int, name: String) -> void:
	await game._open_planet(climate)
	game.set_process(false)
	game.world = WG.generate(713, climate)
	game.world["creatures"] = []
	game.world["drops"] = []
	game.world["torches"] = {}
	game.world["crops"] = {}
	game.world["placed_chests"] = {}
	game._reset_world_environment()
	game.world_texture = WG.make_texture(game.world["tiles"])
	game.world_image = game.world_texture.get_image()
	game.foliage.reset()
	var selected := 200
	for x in range(100, 1100):
		var y: int = game.world["surface"][x]
		if int(game.world["biomes"][x]) == biome and WG.is_solid(WG.tile_at(game.world["tiles"], x, y)) \
			and absi(game.world["surface"][x - 2] - y) < 3:
			selected = x + 12
			break
	game.player_pos = Vector2(selected * 16, game.world["surface"][selected] * 16 - 28)
	game.player_grounded = true
	game._update_camera()
	game.weather = "Clear"
	game.weather_blend.reset("Clear", int(game.world.get("climate", 0)))
	game.time_of_day = 0.25
	game.animation_clock = 3.0
	game.notice_timer = 0.0
	game.equipped_tool = "Hand"
	game.tool_action_timer = 0.0
	game.ground_life.update(game, 1.0 / 60)
	await capture(game, name)


func preview() -> void:
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.set_process(false)
	var board := LifeBoard.new()
	board.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	board.life = game.ground_life
	root.add_child(board)
	await capture(board, "ground_life_art_review")
	board.queue_free()
	await process_frame
	await show_world(game, 0, 0, "ground_life_meadow_preview")
	await show_world(game, 3, 2, "ground_life_desert_preview")
	print("GROUND_LIFE_PREVIEW Aseprite species board, populated meadow and desert/oasis rendered")
	quit()
