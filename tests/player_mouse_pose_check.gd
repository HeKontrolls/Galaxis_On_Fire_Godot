extends SceneTree

const WG = preload("res://scripts/world_gen.gd")
const Pose = preload("res://scripts/player_pose.gd")
const Progression = preload("res://tests/tool_progression_check.gd")
var failures := 0


func _initialize() -> void:
	call_deferred("run_check")


func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		printerr(message)


func mouse(game, direction: Vector2) -> void:
	var event := InputEventMouseMotion.new()
	event.position = game.player_pos + Vector2(8, 10) + direction * 140 - game.camera_pos
	game._input(event)


func run_check() -> void:
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	await game._open_planet(0)
	game.set_process(false)
	var fixtures := Progression.new()
	fixtures.fixture(game)
	game.equipped_tool = "Iron Pickaxe"
	game.inventory["Iron Pickaxe"] = 1
	for direction in [Vector2.RIGHT, Vector2(0.4, -0.9).normalized(), Vector2(0.4, 0.9).normalized(), Vector2.LEFT]:
		mouse(game, direction)
		check(game.facing == (1 if direction.x > 0 else -1), "Mouse motion must face the body toward the cursor without clicking")
		var pose: Transform2D = game._held_tool_pose(Vector2.ZERO)
		var arm := pose.origin - Pose.shoulder(Vector2.ZERO, game.facing)
		check(arm.normalized().dot(direction) > 0.999, "Idle hand must follow vertical and horizontal cursor movement")
	var saved: Vector2 = game.mouse_aim_direction
	game.inventory_open = true
	mouse(game, Vector2.RIGHT)
	check(game.mouse_aim_direction.is_equal_approx(saved), "Inventory cursor movement must not redirect the player")
	game.inventory_open = false
	var hud_event := InputEventMouseMotion.new()
	hud_event.position = Vector2(25, 25)
	game._input(hud_event)
	game._update_mouse_aim()
	check(game.mouse_aim_direction.is_equal_approx(saved), "Health and hotbar hover must preserve the last world aim")
	mouse(game, Vector2(1, -0.4).normalized())
	game.tool_action_timer = game.tool_action_duration * 0.6
	var old_hand: Vector2 = game._held_tool_pose(Vector2.ZERO).origin
	mouse(game, Vector2(-1, 0.4).normalized())
	check(game.facing == -1 and game._held_tool_pose(Vector2.ZERO).origin.distance_to(old_hand) > 6,
		"The hand must follow a moving cursor during an unfinished swing")
	for direction in [-1, 1]:
		for angle in [-1.4, -0.7, 0.0, 0.7, 1.4]:
			var aim := Vector2(cos(angle) * direction, sin(angle))
			var shoulder := Pose.shoulder(Vector2.ZERO, direction)
			for step in range(101):
				var pose := Pose.tool(Vector2.ZERO, aim, direction, true, step / 100.0, "Iron Pickaxe", false)
				var arm := Pose.arm_transform(shoulder, pose.origin, direction)
				check((arm * Vector2.ZERO).distance_to(shoulder) < 0.01 and (arm * Vector2(0, 16)).distance_to(pose.origin) < 0.01,
					"The single arm must remain attached at both shoulder and tool grip throughout the aimed swing")
			var settled := Pose.tool(Vector2.ZERO, aim, direction, true, 1.0, "Iron Pickaxe", false)
			var idle := Pose.tool(Vector2.ZERO, aim, direction, false, 1.0, "Iron Pickaxe", false)
			check(settled.is_equal_approx(idle), "Swing recovery must meet the resting pose without a final snap")
	var shoulder := Pose.shoulder(Vector2.ZERO, 1)
	var start := Pose.tool(Vector2.ZERO, Vector2.RIGHT, 1, true, 0.16, "Iron Pickaxe", false).origin - shoulder
	var finish := Pose.tool(Vector2.ZERO, Vector2.RIGHT, 1, true, 0.72, "Iron Pickaxe", false).origin - shoulder
	check(finish.angle() - start.angle() > 2.9, "A swing must sweep the hand around the shoulder instead of rotating a stationary wrist")
	check(Pose.behind_body(Vector2.ZERO, shoulder + start, 1), "The wind-up hand and shaft must pass behind the head")
	check(not Pose.behind_body(Vector2.ZERO, shoulder + finish, 1), "The forward strike must return in front of the body")
	for fraction in [0.0, 0.16, 0.4, 0.72, 1.0]:
		var east := Pose.tool(Vector2.ZERO, Vector2(0.8, -0.6), 1, true, fraction, "Iron Pickaxe", false)
		var west := Pose.tool(Vector2.ZERO, Vector2(-0.8, -0.6), -1, true, fraction, "Iron Pickaxe", false)
		for point in [Vector2.ZERO, Vector2(0, -23), Vector2(8, -25)]:
			check((east * point).is_equal_approx(Vector2(16 - (west * point).x, (west * point).y)),
				"Tool art, grip and arc must mirror about the player's center")
	game.tool_action_timer = 0
	mouse(game, Vector2(0.25, -1).normalized())
	var fixed_aim: Vector2 = game.mouse_aim_direction
	game.world["creatures"] = [{"x": game.player_pos.x + 12, "y": game.player_pos.y - 23,
		"hp": 100, "alive": true, "kind": "Slime", "hit_flash": 0.0}]
	game.equipped_tool = "Iron Sword"
	for _swing in range(4):
		game.attack_cooldown = 0
		game._attack()
		check(game.mouse_aim_direction.is_equal_approx(fixed_aim), "Repeated keyboard attacks must not drift away from the mouse")
	check(game.world["creatures"][0]["hp"] < 100, "Attacks aimed overhead must damage an enemy overhead")
	check(game.world["creatures"][0]["hp"] <= 0, "Mouse aiming must retain iron sword damage across repeated attacks")
	var exported := Image.load_from_file(ProjectSettings.globalize_path("res://assets/sprites/redesigned/captain/idle/east/frame_000.png"))
	var loaded: Image = game.player_frames["idle_east"][0].get_image()
	exported.convert(Image.FORMAT_RGBA8)
	loaded.convert(Image.FORMAT_RGBA8)
	var pixels_match := true
	for y in range(exported.get_height()):
		for x in range(exported.get_width()):
			var source_pixel := exported.get_pixel(x, y)
			var runtime_pixel := loaded.get_pixel(x, y)
			# Godot's alpha-border import fills RGB under transparent pixels.
			if source_pixel.a > 0 or runtime_pixel.a > 0:
				pixels_match = pixels_match and source_pixel.is_equal_approx(runtime_pixel)
	check(pixels_match, "Runtime character must use the latest visible Aseprite pixels")
	game._reset_world_environment()
	check(not game.mouse_aim_valid, "Changing planets must clear the previous planet's cursor aim")
	fixtures.free()
	print("PLAYER_MOUSE_POSE facing, live aim, HUD guards, 1010 arm poses, recovery, mirrored arcs, overhead combat, fresh art: failures=", failures)
	quit(0 if failures == 0 else 1)
