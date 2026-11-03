extends SceneTree
const WG = preload("res://scripts/world_gen.gd")
const Mobs = preload("res://scripts/wildlife_mobs.gd")
var failures := 0
func check(ok: bool, message: String) -> void:
	if not ok: failures += 1; printerr(message)
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var families := {}
	for climate in range(8):
		var world := WG.generate(741927 + climate, climate, false)
		world.creatures = []
		var original: PackedByteArray = world.tiles.duplicate()
		Mobs.prepare(world)
		var bands := {}
		for c in world.creatures:
			families[int(c.wildlife_family)] = true
			check(Mobs.fits(world, Vector2(c.x, c.y)), "Mob spawned in terrain/liquid")
			if c.y / 16 > int(world.surface[int(c.x / 16)]) + 30: bands[int(c.y / 16 / 240)] = true
		check(world.creatures.size() >= 200 and bands.size() >= 5, "Missing surface or deep-cave population")
		check(world.tiles == original, "Spawning modified terrain")
		var expected := JSON.stringify(world.creatures)
		Mobs.prepare(world)
		check(JSON.stringify(world.creatures) == expected, "Repeated prepare duplicated wildlife")
		world.wildlife_version = 0; world.creatures = []; Mobs.prepare(world)
		check(JSON.stringify(world.creatures) == expected, "Wildlife generation is not deterministic")
		print("WILDLIFE climate=%d count=%d" % [climate, world.creatures.size()])
	check(families.size() == 9, "Missing wildlife family")
	var g = load("res://main.tscn").instantiate()
	g.save_path = "user://wildlife_mobs_check.json"
	root.add_child(g); g.set_process(false)
	await g._open_planet(0)
	var mobs: Array = g.world.creatures.filter(func(c): return bool(c.get("wildlife", false)))
	mobs[0].alive = false; mobs[0].hp = -1
	var expected := JSON.stringify(mobs)
	g._save_game(); g._load_game()
	while g.scene_name == "loading": await process_frame
	mobs = g.world.creatures.filter(func(c): return bool(c.get("wildlife", false)))
	check(JSON.stringify(JSON.parse_string(expected)) == JSON.stringify(mobs), "Save/load revived or changed wildlife")
	g.hide()
	g.sound.clips.clear() # This collision/combat fixture does not exercise audio playback.
	var grid := PackedByteArray(); grid.resize(WG.WIDTH * WG.HEIGHT)
	for x in range(10, 100): WG.set_tile(grid, x, 80, 3)
	var rng := RandomNumberGenerator.new(); rng.seed = 17
	var c := Mobs.creature(0, Vector2(400, 1262), rng)
	g.world = {"tiles": grid, "creatures": [c], "spawn": Vector2(300, 1200), "drops": []}
	g.player_pos = Vector2(450, 1252); g.health = 100; g.damage_cooldown = 0; c.timer = 0
	g.wildlife_mobs.update(g, c, 0.01)
	check(c.state == "windup" and g.health == 100, "Slime needs a harmless windup")
	for i in range(3): g.wildlife_mobs.update(g, c, 0.1)
	check(c.state == "hop" and c.y < 1262, "Slime does not jump")
	c.x = g.player_pos.x; c.y = g.player_pos.y; c.state = "hop"; c.vx = 0; c.vy = 0
	g.wildlife_mobs.update(g, c, 0.01)
	check(g.health == 100 - int(c.damage), "Slime contact attack missing")
	var hp: int = g.health
	c.state = "hop"; g.wildlife_mobs.update(g, c, 0.01)
	check(g.health == hp, "Contact ignored damage cooldown")
	g.dev_invulnerable = true; g.damage_cooldown = 0; c.state = "hop"; g.wildlife_mobs.update(g, c, 0.01)
	check(g.health == hp, "Wildlife ignores invulnerability")
	g.dev_invulnerable = false
	c = Mobs.creature(6, Vector2(400, 1262), rng); c.timer = 0
	g.wildlife_mobs.update(g, c, 0.01)
	check(c.state == "windup", "Scarab needs a warning before charging")
	for i in range(5): g.wildlife_mobs.update(g, c, 0.1)
	check(c.state == "charge", "Scarab does not charge")
	c = Mobs.creature(8, Vector2(400, 1200), rng); c.flight_timer = 0
	g.wildlife_mobs.update(g, c, 0.01)
	check(c.flight_state == "warn", "Cave flyer needs a dive warning")
	c.x = g.player_pos.x - 4; c.y = g.player_pos.y + 4; c.dive_x = c.x; c.dive_y = c.y
	c.flight_state = "dive"; c.flight_timer = 0.5; g.damage_cooldown = 0; g.health = 100
	g.wildlife_mobs.update(g, c, 0.01)
	check(g.health == 100 - int(c.damage) and g.notice.begins_with("Cave screecher"), "Cave flyer damage/name is incorrect")
	for y in range(70, 80): WG.set_tile(grid, 30, y, 3)
	for x in range(20, 30): WG.set_tile(grid, x, 75, 3)
	var stopped: Vector2 = g.flying_monsters.move_clear(g.world, Vector2(440, 1262), Vector2(200, 0))
	check(stopped.x + 23 < 480 and Mobs.fits(g.world, stopped), "Wildlife crossed a solid wall")
	stopped = g.flying_monsters.move_clear(g.world, Vector2(440, 1262), Vector2(0, -300))
	check(stopped.y >= 1216 and Mobs.fits(g.world, stopped), "Wildlife crossed a roof")
	g.world.tiles.fill(0)
	c = Mobs.creature(5, Vector2(440, 300), rng); c.hp = 1
	g.world.creatures = [c]; g.player_pos = Vector2(400, 300)
	g.equipped_tool = "Copper Sword"; g.inventory["Copper Sword"] = 1; g.attack_cooldown = 0
	g._attack(Vector2(452, 309))
	check(not c.alive and g.world.drops.size() == 1, "Wildlife cannot be killed for loot")
	check(g.world.drops[0].item == "Crystal", "Prism slime has the wrong loot")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(g.save_path))
	g.sound.reset_world(); await process_frame
	g.queue_free(); await process_frame; await process_frame
	print("WILDLIFE_CHECK failures=", failures)
	quit(0 if failures == 0 else 1)
