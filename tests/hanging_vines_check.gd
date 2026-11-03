extends SceneTree
const WG = preload("res://scripts/world_gen.gd")
const Vines = preload("res://scripts/hanging_vines.gd")
var failures := 0
func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		printerr(message)
func _initialize() -> void:
	call_deferred("run_check")
func run_check() -> void:
	var vines := Vines.new()
	for climate in [0, 1, 2, 4, 7]:
		var world := WG.generate(741927, climate, false)
		var original: PackedByteArray = world.tiles.duplicate()
		vines.generate(world)
		var first: String = JSON.stringify(world.vines)
		vines.generate(world)
		check(first == JSON.stringify(world.vines), "Vines must be deterministic")
		check(original == world.tiles, "Vines must not replace terrain or affect collisions")
		check(world.vines.is_empty() if climate == 4 else not world.vines.is_empty(), "Climate ecology mismatch")
		var ceilings := 0
		var ledges := 0
		for v in world.vines:
			check(vines.capacity(world, v) >= int(v.length), "Generated vine intersects terrain/liquid")
			if int(v.side) == 0: ceilings += 1
			else: ledges += 1
		print("VINES climate=%d ledges=%d ceilings=%d" % [climate, ledges, ceilings])
		if climate == 0:
			check(ledges > 0 and ceilings > 0, "Forest needs both trailing edge vines and cave vines")
	var g = load("res://main.tscn").instantiate()
	g.save_path = "user://galaxis_vines_check.json"
	root.add_child(g)
	g.set_process(false)
	await g._open_planet(0)
	for x in range(596, 610):
		for y in range(54, 70): WG.set_tile(g.world.tiles, x, y, 0)
	WG.set_tile(g.world.tiles, 600, 55, 3)
	WG.set_tile(g.world.tiles, 600, 62, 3)
	var v := {"x": 600, "y": 55, "side": 0, "length": 8, "limit": 14, "style": 2, "phase": 1.0, "alive": true}
	g.world["vines"] = [v]; g.world["vines_version"] = 1
	g.hanging_vines.reset(g)
	check(g.hanging_vines.capacity(g.world, v) == 12, "Vines must stop above the floor")
	WG.set_tile(g.world.tiles, 600, 60, 4)
	check(g.hanging_vines.capacity(g.world, v) == 8, "Vines must stop at water")
	WG.set_tile(g.world.tiles, 600, 60, 0)
	g.hanging_vines.update(g, 30)
	check(v.length == 9, "Vines must grow over time")
	var at: Vector2 = g.hanging_vines.origin(v)
	g.player_pos = at + Vector2(-8, 20)
	g.hanging_vines.last_player = g.player_pos - Vector2(4, 0)
	g.hanging_vines.update(g, 0.1)
	check(float(g.hanging_vines.bends.get(0, 0.0)) > 0.0, "Passing through a vine must bend it")
	g.player_pos = at + Vector2(-24, 20)
	g.equipped_tool = "Hand"; g.mining_cooldown = 0
	g._mine(at + Vector2(0, 28) - g.camera_pos)
	check(v.length == 3 and v.alive, "Mining must cut the clicked segment and everything below it")
	g.hanging_vines.update(g, 30)
	check(v.length == 4, "Remaining rooted vine must regrow")
	g.mining_cooldown = 0
	g._mine(at + Vector2(0, 2) - g.camera_pos)
	check(not v.alive, "Cutting the root must remove the whole vine")
	var drops: int = g.world.drops.size()
	g.hanging_vines.harvest_at(g, at + Vector2(0, 2))
	check(g.world.drops.size() == drops, "Dead vines must not duplicate drops")
	g._save_game()
	g._load_game()
	while g.scene_name == "loading": await process_frame
	check(g.world.vines.size() == 1 and not g.world.vines[0].alive, "Reload regenerated a cut vine")
	g.world.vines[0].alive = true; g.world.vines[0].length = 4
	g.hanging_vines.reset(g)
	g._edit_tile(Vector2i(600, 55), 0)
	check(not g.world.vines[0].alive, "Removing support must remove hanging vines")
	# Underground vines do not respond to exterior wind or the animation clock.
	var underground := {"x": 601, "y": int(g.world.surface[601]) + 10, "side": 0, "length": 6, "limit": 10, "style": 2, "phase": 0.5, "alive": true}
	g.hanging_vines.bends.clear()
	g.animation_clock = 0
	var still: Vector2 = g.hanging_vines.segment_position(g, underground, 0, 5)
	g.animation_clock = 4
	check(still == g.hanging_vines.segment_position(g, underground, 0, 5), "Cave vines must not sway in outdoor wind")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(g.save_path))
	print("HANGING_VINES_CHECK failures=%d" % failures)
	g.free()
	quit(0 if failures == 0 else 1)
