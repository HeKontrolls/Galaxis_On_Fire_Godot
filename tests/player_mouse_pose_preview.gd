extends SceneTree

const Pose = preload("res://scripts/player_pose.gd")

class PoseBoard extends Node2D:
	var game
	func text(value: String, at: Vector2, size := 15, color := Color("d6e6eb")) -> void:
		draw_string(ThemeDB.fallback_font, at, value, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)
	func _draw() -> void:
		draw_rect(Rect2(0, 0, 1280, 720), Color("101c2b"))
		text("GALAXIS ON FIRE / PLAYER + MOUSE AIM", Vector2(26, 38), 25, Color("efc384"))
		text("Original Aseprite character / one-piece arm / shoulder-driven swing / live cursor following", Vector2(26, 67), 15)
		var poses := [
			["Aim up-right", -0.95, 1, -1.0], ["Aim right", 0.0, 1, -1.0],
			["Aim down-right", 0.85, 1, -1.0], ["Aim left", 0.0, -1, -1.0],
			["Wind-up", 0.0, 1, 0.16], ["Shoulder sweep", 0.0, 1, 0.45],
			["Follow-through", 0.0, 1, 0.72], ["Mirrored sweep", 0.0, -1, 0.45]]
		for index in range(poses.size()):
			var data: Array = poses[index]
			var origin := Vector2(24 + (index % 4) * 314, 96 + (index / 4) * 298)
			draw_rect(Rect2(origin, Vector2(292, 280)), Color("1b3040"))
			text(data[0], origin + Vector2(16, 26), 18, Color("7ec8c2"))
			var aim := Vector2(cos(data[1]) * data[2], sin(data[1]))
			var canvas := Transform2D(0.0, Vector2(3, 3), 0.0, origin + Vector2(134, 140))
			var active: bool = data[3] >= 0
			var pose := Pose.tool(Vector2.ZERO, aim, data[2], active, maxf(data[3], 0), "Copper Pickaxe", false)
			var shoulder := Pose.shoulder(Vector2.ZERO, data[2])
			var behind := Pose.behind_body(Vector2.ZERO, pose.origin, data[2])
			var body: Texture2D = game.player_frames["idle_east" if data[2] > 0 else "idle_west"][0]
			draw_set_transform_matrix(canvas)
			draw_line(Vector2(-28, 28), Vector2(28, 28), Color("456474"), 0.6)
			if not behind:
				draw_texture(body, Vector2(-8, -12))
			draw_set_transform_matrix(canvas * pose)
			draw_texture(game.tool_textures["Copper Pickaxe"], Vector2(-16, -32))
			draw_set_transform_matrix(canvas * Pose.arm_transform(shoulder, pose.origin, data[2]))
			draw_texture(game.arm_textures["solid_arm"], Vector2(-4, -1))
			draw_set_transform_matrix(canvas)
			if behind:
				draw_texture(body, Vector2(-8, -12))
			var pointer := shoulder + aim * 42
			draw_line(pointer - Vector2(3, 0), pointer + Vector2(3, 0), Color("efc384"), 0.5)
			draw_line(pointer - Vector2(0, 3), pointer + Vector2(0, 3), Color("efc384"), 0.5)
			draw_set_transform_matrix(Transform2D.IDENTITY)
			text("Cursor aim" if not active else "Swing %d%%" % int(data[3] * 100), origin + Vector2(16, 261), 14)


func _initialize() -> void:
	call_deferred("preview")


func preview() -> void:
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.set_process(false)
	var board := PoseBoard.new()
	board.game = game
	board.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	root.add_child(board)
	await process_frame
	await process_frame
	root.get_texture().get_image().save_png("res://tests/player_mouse_pose_preview.png")
	print("PLAYER_MOUSE_POSE_PREVIEW rendered eight mouse aim and swing poses")
	quit(0)
