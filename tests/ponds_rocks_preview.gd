extends "res://tests/ground_life_preview.gd"

const Appearance = preload("res://scripts/character_appearance.gd")
const Pose = preload("res://scripts/player_pose.gd")

class ArmBoard extends Node2D:
	var avatars: Array = []
	var tool: Texture2D
	func _ready() -> void:
		texture_filter = TEXTURE_FILTER_NEAREST
		for model in ["male", "female"]:
			for style in range(4):
				var avatar := Appearance.new()
				avatar.configure({"model": model, "shirt_style": style, "shirt_color": style + 1, "hair_style": 5 if model == "female" else 0})
				avatars.append(avatar)
	func label(value: String, at: Vector2, size := 16, color := Color("dce8e7")) -> void:
		draw_string(ThemeDB.fallback_font, at, value, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)
	func held(avatar, base: Transform2D, pose: Transform2D, direction: int) -> void:
		draw_set_transform_matrix(base * pose)
		draw_texture(tool, Vector2(-16, -32))
		draw_set_transform_matrix(base * Pose.arm_transform(Pose.shoulder(Vector2(8, 12), direction), pose.origin, direction))
		draw_texture(avatar.arms["solid_arm"], Vector2(-4, -1))
		draw_set_transform_matrix(Transform2D.IDENTITY)
	func _draw() -> void:
		draw_rect(Rect2(0, 0, 1280, 720), Color("101e2b"))
		label("GALAXIS ON FIRE / ONE-PIECE SWINGING ARM", Vector2(24, 40), 27, Color("efc384"))
		label("A single Aseprite sprite rotates from the shoulder; the fist stays on the tool grip.", Vector2(24, 70), 16)
		for row in range(2):
			for style in range(4):
				var at := Vector2(24 + style * 310, 100 + row * 285)
				draw_rect(Rect2(at, Vector2(298, 270)), Color("1e3543"))
				label(("Male / " if row == 0 else "Female / ") + str(Appearance.catalog()["shirt_styles"][style][1]), at + Vector2(12, 28), 17)
				var avatar = avatars[row * 4 + style]
				var base := Transform2D(0, Vector2(4, 4), 0, at + Vector2(42, 77))
				var pose := Pose.tool(Vector2(8, 12), Vector2(1, -0.3).normalized(), 1, true, 0.50, "Pickaxe", false)
				draw_set_transform_matrix(base)
				avatar.draw_body(self, Vector2.ZERO, "idle_east", 0)
				held(avatar, base, pose, 1)
				label("Continuous sleeve, arm and fist", at + Vector2(12, 249), 14)
		label("Native editable source: avatar_solid_arms.aseprite / two models / four sleeve styles / 72 palette sheets", Vector2(24, 704), 14)


func preview() -> void:
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.set_process(false)
	var board := ArmBoard.new()
	board.tool = game.tool_textures["Pickaxe"]
	root.add_child(board)
	await capture(board, "solid_arm_preview")
	board.queue_free()
	await process_frame
	await game._open_planet(0)
	game.set_process(false)
	game.world = WG.generate(713, 0)
	game.world["creatures"] = []
	game._reset_world_environment()
	game.world_texture = WG.make_texture(game.world["tiles"])
	game.world_image = game.world_texture.get_image()
	game._apply_character_appearance({"model": "female", "hair_style": 5, "shirt_style": 2, "shirt_color": 2})
	game.time_of_day = 0.25
	game.weather = "Clear"
	game.weather_blend.reset("Clear", int(game.world.get("climate", 0)))
	game.notice_timer = 0
	game.animation_clock = 12
	for kind in ["pond", "lake", "dry_basin"]:
		for basin: Dictionary in game.world["surface_basins"]:
			if basin["kind"] != kind:
				continue
			var shore := int(basin["left"]) - 3
			game.player_pos = Vector2(shore * 16, int(game.world["surface"][shore]) * 16 - 28)
			game.player_grounded = true
			game.camera_pos = Vector2((int(basin["left"]) + int(basin["right"])) * 8 - 640, int(basin["waterline"]) * 16 - 350)
			game.mouse_aim_direction = Vector2(1, -0.3).normalized()
			game.mouse_aim_valid = true
			game.tool_action_duration = 0.35
			game.tool_action_timer = 0.175
			game.environment.invalidate()
			await capture(game, "natural_" + kind + "_preview")
			break
	print("PONDS_ROCKS_PREVIEW single-arm wardrobe, pond, lake and dry collection basin rendered")
	quit()
