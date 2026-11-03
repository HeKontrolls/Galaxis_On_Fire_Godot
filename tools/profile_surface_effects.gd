extends SceneTree

const Effects = preload("res://scripts/surface_effects.gd")

class QuietEffects extends Effects:
	func update(_game, _delta: float) -> void:
		pass
	func draw_effects(_game) -> void:
		pass


func _initialize() -> void:
	call_deferred("profile")


func profile() -> void:
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	Engine.max_fps = 0
	var game: Node2D = load("res://main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	var report := {}
	for enabled in [false, true, false, true]:
		game.surface_effects = Effects.new() if enabled else QuietEffects.new()
		await game._open_planet(0)
		game.weather = "Clear"
		game.dev_invulnerable = true
		for _frame in range(90):
			await process_frame
		var started := Time.get_ticks_usec()
		for _frame in range(600):
			game.player_pos.x += 1.7
			game._update_camera()
			await process_frame
		var mean := float(Time.get_ticks_usec() - started) / 600 / 1000
		var label := "enabled" if enabled else "disabled"
		var runs: Array = report.get(label, [])
		runs.append(mean)
		report[label] = runs
		print("SURFACE_EFFECTS ", label, " mean_ms=", mean)
	var file := FileAccess.open("res://tests/surface_effects_profile.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "\t"))
	quit(0)
