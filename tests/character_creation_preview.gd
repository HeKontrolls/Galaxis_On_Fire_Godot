extends "res://tests/ground_life_preview.gd"

const Appearance = preload("res://scripts/character_appearance.gd")

class WardrobeBoard extends Node2D:
	var avatars: Array = []
	func _ready() -> void:
		texture_filter = TEXTURE_FILTER_NEAREST
		for model in ["male", "female"]:
			for index in range(8):
				var avatar := Appearance.new()
				avatar.configure({"model": model, "hair_style": index, "hair_color": index, "eye_color": index,
					"skin": index % 6, "shirt_style": index % 4, "shirt_color": (index + 2) % 12,
					"pants_style": (index + 1) % 4, "pants_color": 8, "shoes_style": index % 4, "shoes_color": 11})
				avatars.append(avatar)
	func label(value: String, at: Vector2, size := 15, color := Color("dce8e7")) -> void:
		draw_string(ThemeDB.fallback_font, at, value, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)
	func _draw() -> void:
		draw_rect(Rect2(0, 0, 1280, 720), Color("101e2b"))
		label("GALAXIS ON FIRE / CHARACTER WARDROBE", Vector2(24, 38), 27, Color("efc384"))
		label("Two models / eight hairstyles / four styles each for shirts, pants and shoes / native Aseprite art", Vector2(24, 68), 15)
		for row in range(2):
			label("MALE" if row == 0 else "FEMALE", Vector2(24, 105 + row * 281), 16, Color("efc384"))
			for index in range(8):
				var at := Vector2(24 + index * 155, 117 + row * 281)
				draw_rect(Rect2(at, Vector2(145, 244)), Color("1e3543"))
				avatars[row * 8 + index].draw_preview(self, at + Vector2(8, 15), 4, "idle", 0.0, 1)
				label(Appearance.catalog()["hair_styles"][index][1], at + Vector2(9, 193), 15)
				label(Appearance.catalog()["shirt_styles"][index % 4][1], at + Vector2(9, 216), 12)
				label(Appearance.catalog()["pants_styles"][(index + 1) % 4][1], at + Vector2(9, 233), 12)
		label("Editable sources: avatar_male.aseprite, avatar_female.aseprite and avatar_arms.aseprite", Vector2(24, 698), 14)


func preview() -> void:
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.set_process(false)
	game._menu_key(KEY_ENTER)
	game.notice_timer = 0
	game.new_game_name = "John"
	game.seed_text = "New Horizons"
	await capture(game, "character_creation_male_preview")
	game.character_creator.appearance = Appearance.normalize({"model": "female", "hair_style": 5, "hair_color": 1,
		"eye_color": 2, "skin": 2, "shirt_style": 2, "shirt_color": 2, "pants_style": 2, "pants_color": 0,
		"shoes_style": 2, "shoes_color": 11})
	game.character_creator.dirty = true
	await capture(game, "character_creation_preview")
	var board := WardrobeBoard.new()
	root.add_child(board)
	await capture(board, "character_wardrobe_preview")
	board.queue_free()
	await process_frame
	game._apply_character_appearance(game.character_creator.appearance)
	await show_world(game, 0, 1, "character_gameplay_preview")
	game.equipped_tool = "Pickaxe"
	game.mouse_aim_direction = Vector2(1, -0.3)
	game.mouse_aim_valid = true
	game.tool_action_duration = 0.35
	game.tool_action_timer = 0.14
	game.player_grounded = true
	await capture(game, "character_gameplay_preview")
	print("CHARACTER_PREVIEW creation male/female, 16 wardrobe combinations and custom gameplay rendered")
	quit()
