extends "res://tests/spellcraft_check.gd"

class OtherCaptain extends RefCounted:
	var necromancy := {"minions": []}
	var key := ""
	func _world_key() -> String: return key

func separate(allies: Array) -> bool:
	for i in range(allies.size()):
		var a := Rect2(Vector2(float(allies[i].x), float(allies[i].y)) - Vector2(3, 13), Vector2(32, 32)).grow(1.9)
		for j in range(i):
			var b := Rect2(Vector2(float(allies[j].x), float(allies[j].y)) - Vector2(3, 13), Vector2(32, 32)).grow(1.9)
			if a.intersects(b): return false
	return true

func raise_three(g) -> void:
	fresh(g)
	g.spellcraft.learned.append("legion")
	for style: String in ["Tome", "Wand", "Staff"]:
		var corpse := enemy(604 * 16)
		corpse.alive = false
		g.world.creatures.append(corpse)
		check(g.necromancy.raise_dead(Ranged.hit_box(corpse).get_center(), 60, 9, style), "Could not raise a spaced ally from nearby corpses")
		check(separate(g.necromancy.minions), "Summons overlap at spawn")

func spacing_checks(g) -> void:
	for fps in [30, 120]:
		raise_three(g)
		var safe := true
		for tick in range(fps * 6):
			g.player_pos.x += (1 if tick < fps * 3 else -1) * 70.0 / fps
			g.facing = 1 if tick < fps * 3 else -1
			g.necromancy.update(1.0 / fps)
			safe = safe and separate(g.necromancy.minions)
		check(safe and g.necromancy.minions.size() == 3, "Following/turning allies overlap at %d FPS" % fps)
		var foe := enemy(g.player_pos.x + 100, 10000)
		g.world.creatures = [foe]
		for tick in range(fps * 6):
			g.necromancy.update(1.0 / fps)
			safe = safe and separate(g.necromancy.minions)
		check(safe and int(foe.hp) < 10000, "Combat allies overlap or stop attacking at %d FPS" % fps)
		g.world.creatures.clear()
		g.player_pos.x += 1000
		g.necromancy.update(1.0 / fps)
		check(separate(g.necromancy.minions) and g.necromancy.minions.all(func(m): return Vector2(m.x, m.y).distance_to(g.player_pos) < 192), "Recall piles allies into one location")
		var saved: Dictionary = g.necromancy.snapshot()
		var first: Dictionary = saved.minions[0]
		for m in saved.minions: m.x = first.x; m.y = first.y
		g.necromancy.minions.clear()
		g.necromancy.restore(saved)
		g.necromancy.restore_pending()
		check(g.necromancy.minions.size() == 3 and separate(g.necromancy.minions), "Legacy stacked save did not restore three separated allies")
		check(is_equal_approx(g.necromancy.minions[0].life, first.life), "Spacing repair changed summon lifetime")
	# Distinct owners share occupancy in co-op, without requiring sockets or real saves.
	raise_three(g)
	g.necromancy.minions.resize(1)
	var foreign := OtherCaptain.new()
	foreign.key = g._world_key()
	foreign.necromancy.minions.append(g.necromancy.minions[0].duplicate(true))
	g.necromancy.minions.clear()
	g.network.role = "host"
	g.network.actors[999] = foreign
	var corpse := enemy(float(foreign.necromancy.minions[0].x))
	corpse.y = float(foreign.necromancy.minions[0].y) + 8
	corpse.alive = false
	g.world.creatures = [corpse]
	check(g.necromancy.raise_dead(Ranged.hit_box(corpse).get_center(), 60, 9, "Tome"), "Could not raise beside another captain's ally")
	check(separate(g.necromancy._allies()), "Different captains' allies overlap")
	g.network.actors.clear()
	g.network.role = ""
	# A one-ally pocket cannot accept another; leave its corpse available.
	fresh(g)
	g.spellcraft.learned.append("legion")
	g.world.tiles.fill(3)
	for y in range(98, 100):
		for x in range(604, 606): WG.set_tile(g.world.tiles, x, y, 0)
	g.player_pos = Vector2(604 * 16, 98 * 16)
	for attempt in range(2):
		corpse = enemy(604 * 16)
		corpse.y = 98 * 16 + 8
		corpse.alive = false
		g.world.creatures.append(corpse)
		var raised: bool = g.necromancy.raise_dead(Ranged.hit_box(corpse).get_center(), 60, 9, "Tome")
		check(raised == (attempt == 0), "Crowded pocket accepted an overlapping summon")
	check(g.necromancy.minions.size() == 1 and not g.world.creatures[1].get("raised", false), "Rejected summon consumed a corpse")

func run() -> void:
	var game = load("res://main.tscn").instantiate()
	game.settings_path = "user://ally_spacing_check_settings.json"
	root.add_child(game)
	game.set_process(false)
	await process_frame
	spacing_checks(game)
	if "preview" in OS.get_cmdline_user_args():
		raise_three(game)
		game.inventory["Grave Tome"] = 1
		game._equip_inventory_item("Grave Tome")
		game.scene_name = "planet"
		game.notice_timer = 0
		game._update_camera()
		game.queue_redraw()
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://ally_spacing_preview.png")
	game.queue_free()
	await process_frame
	print("ALLY_SPACING spawn, follow, turns, combat, recall, legacy saves, co-op and crowded terrain failures=", failures)
	quit(1 if failures else 0)
