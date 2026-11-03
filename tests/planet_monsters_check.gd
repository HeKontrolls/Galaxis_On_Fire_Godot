extends SceneTree
const WG = preload("res://scripts/world_gen.gd")
const Monsters = preload("res://scripts/planet_monsters.gd")
var failures := 0
func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		printerr(message)
func _initialize() -> void:
	call_deferred("run_check")
func run_check() -> void:
	var g = load("res://main.tscn").instantiate()
	root.add_child(g)
	g.set_process(false)
	for climate in range(8):
		g.world = WG.generate(741927 + climate, climate, false)
		g._make_population()
		var first: Array = g.world["creatures"].duplicate(true)
		check(not first.is_empty(), "Missing population climate %d" % climate)
		g._make_population()
		check(first == g.world["creatures"], "Population must be deterministic")
		var morphs := {}
		for c in first:
			check(c.monster_family == climate and c.monster_morph in [0, 1, 2], "Climate-specific genes invalid")
			check(g.expedition.guardian_fits(Vector2(c.x, c.y)), "Monster spawned inside solid terrain")
			check(absf(c.x - g.world.spawn.x) > 192, "Monster spawned beside player")
			morphs[c.monster_morph] = true
		print("MONSTERS climate=%d count=%d morphs=%d" % [climate, first.size(), morphs.size()])
		var saved: Array = JSON.parse_string(JSON.stringify(first))
		var restored_before := JSON.stringify(saved)
		g.world["creatures"] = saved
		Monsters.prepare(g.world)
		check(JSON.stringify(saved) == restored_before, "Save/load changed monster traits")
		for i in range(first.size()):
			check(int(saved[i].monster_morph) == int(first[i].monster_morph) and is_equal_approx(float(saved[i].speed), float(first[i].speed)) and int(saved[i].hp) == int(first[i].hp), "Saved genes or health were lost")
	var legacy := {"x": 300.0, "y": 100.0, "home_x": 300.0, "hp": 9, "alive": true}
	var dead := {"x": 500.0, "y": 100.0, "hp": -2, "alive": false}
	var guardian := {"x": 700.0, "hp": 90, "alive": true, "quest_guardian": true}
	var old_world := {"seed": 27, "climate": 3, "creatures": [legacy, dead, guardian]}
	Monsters.prepare(old_world)
	check(legacy.hp == 9 and not dead.alive and dead.hp == -2 and not guardian.has("monster_family"), "Migration modified saved health/death/guardian")
	var stable := JSON.stringify(old_world)
	Monsters.prepare(old_world)
	check(stable == JSON.stringify(old_world), "Migration must be idempotent")
	var genes := {}
	for seed_value in range(10):
		var c := {"x": 200.0, "hp": 30, "alive": true}
		Monsters.decorate({"seed": seed_value, "climate": 0}, c, 0, true)
		genes[c.monster_morph] = true
	check(genes.size() > 1, "Planet seed must affect morphology")
	# Real movement and contact damage on a controlled surface, including wall blocking.
	var grid := PackedByteArray(); grid.resize(WG.WIDTH * WG.HEIGHT)
	for x in range(10, 90): WG.set_tile(grid, x, 30, 3)
	g.world = {"seed": 7, "climate": 0, "tiles": grid, "spawn": Vector2(400, 452)}
	var actor := {"x": 500.0, "y": 462.0, "home_x": 500.0, "direction": 1, "hp": 30, "alive": true}
	Monsters.decorate(g.world, actor, 0, true)
	g.world["creatures"] = [actor]
	g.player_pos = Vector2(550, 452)
	g._update_population(0.1)
	check(actor.x > 500 and actor.moving, "Monster must animate actual ground movement")
	g.player_pos = Vector2(actor.x, actor.y - 10)
	g.health = 100; g.damage_cooldown = 0; g.dev_invulnerable = false
	g._update_population(0.01)
	check(g.health == 100 - int(actor.damage), "Species contact damage not applied")
	WG.set_tile(grid, 33, 29, 3); WG.set_tile(grid, 33, 28, 3)
	g.world["tiles"] = grid; actor.x = 504.0; actor.direction = 1; g.player_pos = Vector2(560, 452)
	g._update_population(0.1)
	check(actor.x == 504.0 and not actor.moving, "Monster crossed a solid wall")
	g.inventory["Copper Sword"] = 1
	g.equipped_tool = "Copper Sword"
	g.player_pos = Vector2(500, 452); actor.x = 550.0
	var before_hit: int = actor.hp
	g.attack_cooldown = 0
	g._attack(Vector2(actor.x + 12, actor.y + 9))
	check(actor.hp == before_hit, "Sword damage must not pass through the wall")
	WG.set_tile(grid, 33, 29, 0); WG.set_tile(grid, 33, 28, 0)
	g.world["tiles"] = grid
	for hit in range(2):
		g.attack_cooldown = 0
		g._attack(Vector2(actor.x + 12, actor.y + 9))
	check(not actor.alive and g.world.get("drops", []).size() == 1, "Actual sword combat must defeat the monster and drop one reward")
	g.attack_cooldown = 0
	g._attack(Vector2(actor.x + 12, actor.y + 9))
	check(g.world.get("drops", []).size() == 1, "Dead monsters must not duplicate loot")
	print("PLANET_MONSTERS_CHECK failures=%d" % failures)
	g.free()
	quit(0 if failures == 0 else 1)
