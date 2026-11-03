extends SceneTree


func _initialize() -> void:
	call_deferred("run_profile")


func run_profile() -> void:
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	Engine.max_fps = 0
	var game: Node2D = load("res://main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.profile_enabled = true
	var report := {}
	var args := OS.get_cmdline_user_args()
	var frame_count := maxi(90, int(args[1])) if args.size() > 1 else 90
	for scenario in [[0, "Clear"], [0, "Fog"], [2, "Rain"], [0, "Snow"], [4, "Clear"]]:
		await game._open_planet(scenario[0])
		game.weather = scenario[1]
		game.notice_timer = 0.0
		game.health = 100
		game.dev_invulnerable = true
		for _frame in range(18):
			await process_frame
		game.profile_stats.clear()
		var frames: Array[int] = []
		var previous := Time.get_ticks_usec()
		for frame in range(frame_count):
			# Scroll through the scene to include moving-camera cache costs.
			game.player_pos.x += 1.7
			game._update_camera()
			await process_frame
			var now := Time.get_ticks_usec()
			frames.append(now - previous)
			previous = now
		frames.sort()
		var mean := 0.0
		for value in frames:
			mean += float(value) / frames.size()
		var name := "%d_%s" % [scenario[0], scenario[1]]
		var parts := {}
		for section in game.profile_stats:
			var entry: Array = game.profile_stats[section]
			parts[section] = {"mean_ms": float(entry[0]) / maxf(1, entry[1]) / 1000.0, "max_ms": float(entry[2]) / 1000.0}
		report[name] = {"fps": 1000000.0 / mean, "mean_frame_ms": mean / 1000.0,
			"p95_ms": float(frames[int(frames.size() * 0.95)]) / 1000.0, "sections": parts}
		print(name, " ", JSON.stringify(report[name]))
	var output := args[0] if not args.is_empty() else "res://tests/fps_profile.json"
	var file := FileAccess.open(output, FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "\t"))
	quit(0)
