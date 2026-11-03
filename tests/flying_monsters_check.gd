extends SceneTree
const WG = preload("res://scripts/world_gen.gd")
const Flyers = preload("res://scripts/flying_monsters.gd")
var failures := 0
func check(ok: bool, label: String) -> void:
	if not ok: failures += 1; printerr(label)
func _initialize() -> void: call_deferred("run_check")
func run_check() -> void:
	for climate in range(8):
		var w := WG.generate(741927 + climate, climate, false)
		w["creatures"] = []
		Flyers.prepare(w)
		check(w.creatures.size() == 6, "Missing flyers on climate %d" % climate)
		for c in w.creatures: check(Flyers.fits(w, Vector2(c.x, c.y)) and c.monster_family == climate, "Invalid flyer placement")
		var expected := JSON.stringify(w.creatures)
		Flyers.prepare(w)
		check(expected == JSON.stringify(w.creatures), "Repeated preparation duplicated flyers")
		w.flyers_version = 0; w.creatures = []
		Flyers.prepare(w)
		check(expected == JSON.stringify(w.creatures), "Flyer generation is not deterministic")
		print("FLYERS climate=%d count=%d" % [climate, w.creatures.size()])
	var g = load("res://main.tscn").instantiate()
	g.save_path = "user://galaxis_flyers_check.json"
	root.add_child(g); g.set_process(false)
	await g._open_planet(0)
	var birds: Array = g.world.creatures.filter(func(c): return bool(c.get("flying", false)))
	check(birds.size() == 6, "Real planet load missing flyers")
	birds[0].alive = false; birds[0].hp = -1
	var genes := JSON.stringify(birds)
	g._save_game(); g._load_game()
	while g.scene_name == "loading": await process_frame
	birds = g.world.creatures.filter(func(c): return bool(c.get("flying", false)))
	check(birds.size() == 6 and not birds[0].alive and birds[0].hp == -1, "Save/load resurrected or duplicated a flyer")
	check(JSON.stringify(JSON.parse_string(genes)) == JSON.stringify(birds), "Save/load changed flyer genes")
	g.hide() # Remaining checks use a minimal collision fixture, not a renderable world.
	var c: Dictionary = birds[1].duplicate(true)
	var grid := PackedByteArray(); grid.resize(WG.WIDTH * WG.HEIGHT)
	g.world = {"tiles": grid, "spawn": Vector2(300, 300), "creatures": [c]}
	c.x = 400.0; c.y = 300.0; c.home_x = 400.0; c.home_y = 300.0
	c.flight_state = "roam"; c.flight_timer = 0; g.player_pos = Vector2(460, 340)
	g.health = 100; g.dev_invulnerable = false; g.damage_cooldown = 0
	g.flying_monsters.update(g, c, 0.01)
	check(c.flight_state == "warn" and g.health == 100, "Flight attack needs a harmless warning")
	var locked_target := Vector2(c.dive_x, c.dive_y)
	g.player_pos += Vector2(100, 0)
	for i in range(4): g.flying_monsters.update(g, c, 0.2)
	check(c.flight_state == "dive" and locked_target == Vector2(c.dive_x, c.dive_y), "Dive should target the warned position")
	c.x = g.player_pos.x - 4; c.y = g.player_pos.y + 4; c.dive_x = c.x; c.dive_y = c.y
	c.flight_state = "dive"; c.flight_timer = 0.5
	g.flying_monsters.update(g, c, 0.01)
	check(g.health == 100 - int(c.damage) and c.flight_state == "recover", "Dive hit needs damage and recovery")
	# A high-speed dive cannot tunnel across a one-tile wall or ceiling.
	for y in range(10, 35): WG.set_tile(grid, 40, y, 3)
	for x in range(25, 41): WG.set_tile(grid, x, 12, 3)
	g.world.tiles = grid
	var stopped: Vector2 = g.flying_monsters.move_clear(g.world, Vector2(600, 300), Vector2(200, 0))
	check(stopped.x + 23 < 640 and Flyers.fits(g.world, stopped), "Flyer crossed solid wall")
	stopped = g.flying_monsters.move_clear(g.world, Vector2(600, 300), Vector2(0, -200))
	check(stopped.y >= 208 and Flyers.fits(g.world, stopped), "Flyer crossed solid roof")
	# The shared sword/loot path must work for airborne targets.
	g.world.tiles.fill(0); g.world.drops = []
	g.player_pos = Vector2(400, 300); c.x = 440.0; c.y = 300.0; c.hp = 1; c.alive = true
	g.inventory["Copper Sword"] = 1; g.equipped_tool = "Copper Sword"; g.attack_cooldown = 0
	g._attack(Vector2(452, 309))
	check(not c.alive and g.world.drops.size() == 1, "Airborne enemy must be killable and drop loot")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(g.save_path))
	print("FLYING_MONSTERS_CHECK failures=%d" % failures)
	g.sound.reset_world()
	await process_frame
	g.queue_free()
	await process_frame
	await process_frame
	quit(0 if failures == 0 else 1)
