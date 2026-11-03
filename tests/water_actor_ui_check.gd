extends SceneTree
const WG = preload("res://scripts/world_gen.gd")
const UIText = preload("res://scripts/ui_text.gd")
const Ripples = preload("res://scripts/water_ripples.gd")
var failures := 0
func check(ok: bool, message: String) -> void:
	if not ok: failures += 1; printerr(message)
func _initialize() -> void: call_deferred("run")
func fixture(g) -> void:
	var grid := PackedByteArray(); grid.resize(WG.WIDTH * WG.HEIGHT)
	var surface := PackedInt32Array(); surface.resize(WG.WIDTH); surface.fill(84)
	for x in range(570, 630):
		WG.set_tile(grid, x, 84, 3)
		if x in range(580, 590) or x in range(610, 620):
			for y in range(79, 84): WG.set_tile(grid, x, y, 3)
		if x in range(590, 610):
			for y in range(80, 84): WG.set_tile(grid, x, y, 4)
	g.world = {"tiles": grid, "surface": surface, "seed": 17, "climate": 0, "spawn": Vector2(9600, 1260), "creatures": [], "ground_life": [], "ground_life_version": 1, "ground_cover_version": 1}
	g.water_sim.bind_world(g.world); g.lava_sim.bind_world(g.world)
	g.ground_life.entries = []; g.ground_life.buckets.clear(); g.ground_life.state.clear()
	g.water_ripples.reset(); g.player_velocity = Vector2.ZERO; g.player_grounded = false
func run() -> void:
	var g = load("res://main.tscn").instantiate()
	root.add_child(g); g.set_process(false); await g._open_planet(0); g.hide()
	for fps in [30, 60, 120]:
		for direction in [-1, 1]:
			fixture(g); g.player_pos = Vector2(600 * 16, 82 * 16 - 28)
			var escaped := false
			for frame in range(fps * 3):
				g._update_player_motion(1.0 / fps, direction, true)
				check(not g._collides(g.player_pos), "Swimmer clipped into terrain")
				if (g.player_pos.x >= 610 * 16 if direction == 1 else g.player_pos.x + 16 <= 590 * 16) and g.player_pos.y + 28 <= 79 * 16 + 0.1:
					escaped = true; break
			check(escaped, "Cannot swim out at %d FPS, direction %d" % [fps, direction])
	fixture(g)
	for x in range(608, 614): WG.set_tile(g.world.tiles, x, 77, 3)
	g.player_pos = Vector2(608 * 16, 82 * 16 - 28)
	for frame in range(100): g._update_player_motion(1.0 / 60, 1, true)
	check(g.player_pos.x + 16 <= 610 * 16 + 0.1 and not g._collides(g.player_pos), "Water exit assist bypassed low ceiling")
	fixture(g); g.water_sim.amounts.fill(0)
	g.water_sim.amounts[83 * WG.WIDTH + 602] = 8
	g.player_pos = Vector2(602 * 16, 84 * 16 - 28); g.player_grounded = true
	g._update_player_motion(1.0 / 60, 1, false)
	check(is_equal_approx(g.player_pos.x, 602 * 16 + g.SPEED / 60.0), "Ankle puddle slows normal walking")
	g.player_pos = Vector2(602 * 16, 84 * 16 - 28); g.player_grounded = true
	g._update_player_motion(1.0 / 60, 0, true)
	check(g.player_velocity.y < -400, "Puddle weakens a normal ground jump")
	fixture(g)
	var ripples := Ripples.new()
	var original: PackedByteArray = g.water_sim.amounts.duplicate()
	for key in ["player", "npc", "mob_0", "animal_1"]:
		ripples.observe(g.water_sim, key, Rect2(9600, 1240, 16, 28), 0.1)
		ripples.observe(g.water_sim, key, Rect2(9600, 1260, 16, 28), 0.1)
	check(ripples.effects.size() == 4, "Entry splashes missing for actor types")
	for effect in ripples.effects: check(effect.splash and is_equal_approx(effect.at.y, 1280), "Ripple does not follow water surface")
	ripples.observe(g.water_sim, "player", Rect2(9606, 1260, 16, 28), 0.2)
	check(ripples.effects.size() == 5 and not ripples.effects[-1].splash, "Swimming wake missing")
	ripples.observe(g.water_sim, "player", Rect2(9606, 1240, 16, 28), 0.1)
	check(ripples.effects[-1].splash and ripples.effects.size() == 6, "Exit splash missing")
	ripples.observe(g.water_sim, "mob_bounce", Rect2(9600, 1240, 24, 18), 0.1)
	ripples.observe(g.water_sim, "mob_bounce", Rect2(9600, 1259, 24, 18), 0.1)
	check(ripples.effects.size() == 7 and ripples.effects[-1].splash, "Mob stopped by water collision produces no ripple")
	check(g.water_sim.amounts == original, "Ripples changed liquid volume")
	ripples.reset(); check(ripples.effects.is_empty() and ripples.tracks.is_empty(), "Planet reset retained ripples")
	# A rabbit trapped between a player and a steep ledge must commit to turns.
	g.world.tiles.fill(0)
	for x in range(580, 601): WG.set_tile(g.world.tiles, x, 80, 3)
	var rabbit := {"id": 1, "species": "hare", "x": 600.0 * 16 + 15, "y": 1280.0, "home_x": 600.0 * 16, "phase": 1.0, "direction": 1, "alive": true}
	g.ground_life._index(rabbit)
	var state: Dictionary = g.ground_life.state[1]
	var turns := 0; var direction := 1
	for frame in range(120):
		g.animation_clock += 1.0 / 60
		g.ground_life._update_animal(g, rabbit, state, Vector2(float(rabbit.x) - 20, 1280), 0, 1.0 / 60)
		if int(rabbit.direction) != direction: turns += 1; direction = int(rabbit.direction)
	check(turns <= 5 and float(rabbit.x) < 600 * 16, "Rabbit flips rapidly instead of escaping ledge")
	# No valid direction on a one-block perch: pause instead of jittering.
	g.world.tiles.fill(0); WG.set_tile(g.world.tiles, 600, 80, 3)
	rabbit.x = 600.0 * 16 + 15; rabbit.direction = 1; state.turn_lock = 0; state.blocked_pause = 0
	turns = 0; direction = 1
	for frame in range(120):
		g.animation_clock += 1.0 / 60
		g.ground_life._update_animal(g, rabbit, state, Vector2(float(rabbit.x), 1280), 0, 1.0 / 60)
		if int(rabbit.direction) != direction: turns += 1; direction = int(rabbit.direction)
	check(turns <= 5, "Trapped rabbit alternates direction each frame")
	var fonts: Array[Font] = [ThemeDB.fallback_font, g.dev_controls.font]
	for font in fonts:
		for spec in [["Free Flight: OFF", 140, 30, 18], ["Free Flight: ON", 250, 30, 18], ["Grant Starter Materials", 250, 34, 18], ["Turn", 105, 31, 23], ["Back to Galaxy", 170, 42, 23], ["Randomize", 186, 36, 23], ["Storm", 84, 26, 18], ["Very long recipe name that must stay in its button", 140, 30, 18]]:
			var rect := Rect2(0, 0, spec[1], spec[2]); var fit := UIText.layout(font, spec[0], rect, spec[3])
			check(fit.width <= fit.area.size.x + 0.1 and fit.at.y - font.get_ascent(fit.size) >= 0 and fit.at.y + font.get_descent(fit.size) <= rect.end.y, "Button text escapes: " + spec[0])
		for recipe in g.RECIPES:
			var fit := UIText.layout(font, str(recipe.name), Rect2(0, 0, 244, 44), 14)
			check(fit.width <= fit.area.size.x, "Recipe button text escapes")
	g.dev_mode = true; g.dev_free_flight = false; g.dev_controls.active_tab = "tools"
	g.dev_controls.click(Vector2(g.window_positions.dev) + Vector2(460, 107))
	check(g.dev_free_flight, "Free Flight hitbox does not match enlarged button")
	g.sound.reset_world(); g.queue_free(); await process_frame; await process_frame
	print("WATER_ACTOR_UI_CHECK failures=", failures)
	quit(0 if failures == 0 else 1)
