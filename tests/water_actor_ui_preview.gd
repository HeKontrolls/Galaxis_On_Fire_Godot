extends SceneTree
const WG = preload("res://scripts/world_gen.gd")
func _initialize() -> void: call_deferred("run")
func run() -> void:
	root.size = Vector2i(1280, 720)
	var g = load("res://main.tscn").instantiate()
	root.add_child(g); g.set_process(false); await g._open_planet(1)
	g.weather = "Clear"; g.time_of_day = 0.25; g.weather_blend.reset("Clear", int(g.world.climate))
	var selected := Vector2i(600, 100)
	var found := false
	for x in range(60, WG.WIDTH - 60):
		if found: break
		for y in range(30, mini(int(g.world.surface[x]), 240)):
			if g.water_sim.amount_at(Vector2i(x, y)) < 220 or g.water_sim.amount_at(Vector2i(x, y - 1)) != 0: continue
			var clear := true
			for offset in [0, 4, 8, 12]:
				if g.water_sim.amount_at(Vector2i(x + offset, y)) < 220: clear = false
			if clear: selected = Vector2i(x, y); found = true; break
	var surface_y: float = (selected.y + 1) * 16.0 - g.water_sim.amount_at(selected) / 255.0 * 16
	var x := selected.x * 16.0
	var rng := RandomNumberGenerator.new(); rng.seed = 17
	g.world.creatures = [g.WildlifeMobs.creature(1, Vector2(x + 128, surface_y - 45), rng)]
	g.world.npc.x = x + 64; g.world.npc.y = surface_y - 50
	g.player_pos = Vector2(x, surface_y - 50)
	g.camera_pos = Vector2(x - 470, surface_y - 365).clamp(Vector2.ZERO, Vector2(WG.WIDTH * 16 - 1280, WG.HEIGHT * 16 - 720))
	g.water_ripples.reset(); g.water_ripples.update(g, 0.1)
	g.player_pos.y = surface_y - 20
	g.world.npc.y = surface_y - 21
	g.world.creatures[0].y = surface_y - 11
	g.water_ripples.update(g, 0.1)
	for effect in g.water_ripples.effects: effect.age = 0.25
	g.environment.invalidate(); g.notice_timer = 0; g.queue_redraw()
	await process_frame; await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://tests/water_ripples_gameplay.png")
	g.dev_mode = true; g.dev_controls.active_tab = "tools"; g.window_positions.dev = Vector2(350, 150)
	g.queue_redraw(); await process_frame; await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://tests/dev_button_fit.png")
	print("WATER_UI_PREVIEW ripples=", g.water_ripples.effects.size())
	g.free(); quit()
