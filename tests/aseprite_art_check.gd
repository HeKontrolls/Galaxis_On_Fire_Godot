extends SceneTree

const WG = preload("res://scripts/world_gen.gd")
var failures := 0


func _initialize() -> void:
	call_deferred("run_check")


func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		printerr(message)


func run_check() -> void:
	var game: Node2D = load("res://main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	await game._open_planet(0)
	game.set_process(false)
	var count := 0
	for pair in [[game.player_frames, 38, Vector2i(32, 40)], [game.elder_frames, 12, Vector2i(48, 48)]]:
		var total := 0
		for key in pair[0]:
			var frames: Array = pair[0][key]
			total += frames.size()
			var unique := {}
			for texture: Texture2D in frames:
				var image := texture.get_image()
				check(image.get_size() == pair[2], "Actors must retain their native captain/robot canvases")
				check(not image.is_invisible(), "Every animation frame must have visible art")
				unique[hash(image.get_data())] = true
				if not str(key).begins_with("jump"):
					var ground := false
					for x in range(image.get_width()):
						ground = ground or image.get_pixel(x, 39).a > 0
					check(ground, "Standing and walking frames must keep a boot on the common floor")
			check(unique.size() >= mini(3, frames.size()), "Animation poses must actually change: " + str(key))
		check(total == pair[1], "All exported character animations must be loaded")
		count += total
	check(game.player_frames["idle_east"].size() == 4 and game.player_frames["walk_east"].size() == 6
		and game.player_frames["jump_east"].size() == 9, "Captain idle/walk/jump counts must match Aseprite tags")
	check(game.tool_textures.size() == 23, "All base tools and seven pickaxe/shovel tiers must use Aseprite art")
	for item in game.tool_textures:
		var image: Image = game.tool_textures[item].get_image()
		check(image.get_size() == Vector2i(32, 40) and image.get_pixel(16, 32).a > 0,
			"Every tool must retain an occupied (16,32) grip: " + str(item))
	for station in game.station_frames:
		var frames: Array = game.station_frames[station]
		check(frames.size() == 4 and frames[0].get_size() == Vector2(32, 32), "Station exports must retain the two-tile footprint")
		check(frames[0].get_image().get_data() != frames[2].get_image().get_data(), "Work lamps and furnace flames must animate")
	check(game.sprite_art.frame_index("captain", "idle_east", 0.0) == 0
		and game.sprite_art.frame_index("captain", "idle_east", 0.31) == 1,
		"Playback must honor Aseprite's exported frame durations")
	var maximum_overlap := 0
	for direction in [-1, 1]:
		game.facing = direction
		game.equipped_tool = "Iron Pickaxe"
		game._begin_tool_action("mine", game.player_pos + Vector2(direction * 40, 0))
		for step in range(21):
			game.tool_action_timer = game.tool_action_duration * (1.0 - step / 20.0)
			var pose: Transform2D = game._held_tool_pose(Vector2.ZERO)
			var face := Rect2(3, -9, 15, 15) if direction > 0 else Rect2(-2, -9, 15, 15)
			var image: Image = game.tool_textures["Iron Pickaxe"].get_image()
			var overlap := 0
			for y in range(20):
				for x in range(32):
					if image.get_pixel(x, y).a > 0 and face.has_point(pose * Vector2(x - 16, y - 32)):
						overlap += 1
			maximum_overlap = maxi(maximum_overlap, overlap)
	check(maximum_overlap <= 3, "The redesigned pickaxe head must stay clear of the face during its swing")
	var can: Image = game.tool_textures["Watering Can"].get_image()
	check(can.get_pixel(29, 18).a > 0, "The can's rose must remain at the actual water emission point")
	game.equipped_tool = "Watering Can"
	game.inventory["Watering Can"] = 1
	game._start_watering(Vector2i(game.player_pos / 16) + Vector2i(2, 0))
	game.tool_action_timer = game.tool_action_duration * 0.5
	check(game._is_pouring() and game._watering_spout_world().distance_to(game.player_pos) > 15,
		"The redesigned watering can must retain its pouring animation")
	print("ASEPRITE_ART actors=", count, " tools=23 stations=2 maximum_face_overlap=", maximum_overlap, " failures=", failures)
	game.queue_free()
	await process_frame
	quit(0 if failures == 0 else 1)
