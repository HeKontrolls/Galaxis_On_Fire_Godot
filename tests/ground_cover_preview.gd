extends "res://tests/ground_life_preview.gd"

const CoverLife = preload("res://scripts/ground_life.gd")

class CoverBoard extends Node2D:
	var life
	func label(value: String, at: Vector2, size := 15, color := Color("dce8e7")) -> void:
		draw_string(ThemeDB.fallback_font, at, value, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)
	func _draw() -> void:
		draw_rect(Rect2(0, 0, 1280, 720), Color("101e2b"))
		label("GALAXIS ON FIRE / FULL BUSHES + GROUND ROCKS", Vector2(24, 37), 25, Color("efc384"))
		label("Drawn, layered and exported in Aseprite / native 48 x 40 canvas / four editable layers", Vector2(24, 67), 15)
		for index in range(CoverLife.COVER.size()):
			var species: String = CoverLife.COVER[index]
			var origin := Vector2(24 + (index % 5) * 248, 94 + (index / 5) * 298)
			draw_rect(Rect2(origin, Vector2(238, 278)), Color("1e3543"))
			label(CoverLife.ITEMS[CoverLife.SPECIES.find(species)], origin + Vector2(12, 26), 18, Color("efc384") if species in CoverLife.ROCKS else Color("a8d097"))
			var transform := Transform2D(0.0, Vector2(4, 4), 0, origin + Vector2(119, 218))
			draw_set_transform_matrix(transform)
			CoverLife.draw_sprite(self, life.frames[species][0], Vector2.ZERO, 0)
			draw_set_transform_matrix(Transform2D.IDENTITY)
			label("%d native frames" % life.frames[species].size(), origin + Vector2(12, 259), 13)
		label("Passable and collectible / bushes sway and react to passing players / rocks need a pickaxe", Vector2(24, 712), 14)


class RockBoard extends Node2D:
	var game
	func label(value: String, at: Vector2, size := 15, color := Color("dce8e7")) -> void:
		draw_string(ThemeDB.fallback_font, at, value, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)
	func _draw() -> void:
		draw_rect(Rect2(0, 0, 1280, 720), Color("101e2b"))
		label("GALAXIS ON FIRE / SURFACE ROCKS", Vector2(24, 38), 27, Color("efc384"))
		label("Aseprite redraw from the close-up references: overlapping stone chunks, dark seams and bright ground growth", Vector2(24, 68), 15)
		for index in range(CoverLife.ROCKS.size()):
			var species: String = CoverLife.ROCKS[index]
			var origin := Vector2(24 + index * 248, 105)
			draw_rect(Rect2(origin, Vector2(238, 548)), Color("1e3543"))
			label(CoverLife.ITEMS[CoverLife.SPECIES.find(species)], origin + Vector2(12, 32), 18, Color("a8d097"))
			label("4x detail", origin + Vector2(12, 61), 13)
			draw_set_transform_matrix(Transform2D(0, Vector2(4, 4), 0, origin + Vector2(119, 251)))
			CoverLife.draw_sprite(self, game.ground_life.frames[species][0], Vector2.ZERO, 0)
			draw_set_transform_matrix(Transform2D.IDENTITY)
			draw_line(origin + Vector2(12, 301), origin + Vector2(226, 301), Color("3f5a65"), 1)
			label("Actual game size beside player", origin + Vector2(12, 337), 13)
			draw_rect(Rect2(origin + Vector2(12, 379), Vector2(214, 70)), Color("294137"))
			draw_texture(game.player_frames["idle_east"][0], origin + Vector2(47, 389))
			CoverLife.draw_sprite(self, game.ground_life.frames[species][0], origin + Vector2(131, 429), 0)
			draw_line(origin + Vector2(20, 429), origin + Vector2(218, 429), Color("53bd6a"), 1)
		label("All rock artwork is in the editable ground_cover.aseprite document / passable and mineable", Vector2(24, 699), 14)


func preview() -> void:
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.set_process(false)
	var board := CoverBoard.new()
	board.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	board.life = game.ground_life
	root.add_child(board)
	await capture(board, "ground_cover_art_review")
	board.queue_free()
	await process_frame
	var rocks := RockBoard.new()
	rocks.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	rocks.game = game
	root.add_child(rocks)
	await capture(rocks, "ground_rocks_reference_review")
	rocks.queue_free()
	await process_frame
	await show_world(game, 0, 1, "ground_cover_forest_preview")
	for entry: Dictionary in game.ground_life.entries:
		if entry["species"] == "mossy_boulder" and bool(entry["alive"]):
			var column := floori(float(entry["x"]) / 16)
			if int(game.world["biomes"][column]) not in [1, 2]:
				continue
			game.player_pos = Vector2((column - 2) * 16, int(game.world["surface"][column - 2]) * 16 - 28)
			game._update_camera()
			await capture(game, "ground_cover_rocks_preview")
			break
	print("GROUND_COVER_PREVIEW ten Aseprite assets and full forest undergrowth rendered")
	quit()
