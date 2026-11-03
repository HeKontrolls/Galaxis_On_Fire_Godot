extends SceneTree
const WG = preload("res://scripts/world_gen.gd")
const Water = preload("res://scripts/water_sim.gd")
var failures := 0
func check(ok: bool, message: String) -> void:
	if not ok: failures += 1; printerr(message)
func _initialize() -> void: call_deferred("run")
func total(values: PackedByteArray) -> int:
	var n := 0
	for value in values: n += value
	return n
func pressure_fixture(sealed := false) -> Dictionary:
	var grid := PackedByteArray(); grid.resize(WG.WIDTH * WG.HEIGHT); grid.fill(3)
	for y in range(66, 79):
		WG.set_tile(grid, 600, y, 4 if y >= 70 else 0)
		WG.set_tile(grid, 604, y, 0)
	for x in range(601, 605): WG.set_tile(grid, x, 78, 4)
	if sealed: WG.set_tile(grid, 602, 78, 3)
	return {"tiles": grid}
func fixture(g) -> void:
	var grid := PackedByteArray(); grid.resize(WG.WIDTH * WG.HEIGHT)
	var surface := PackedInt32Array(); surface.resize(WG.WIDTH); surface.fill(100)
	for x in range(WG.WIDTH): WG.set_tile(grid, x, 100, 3)
	g.world = {"tiles": grid, "surface": surface, "seed": 17, "climate": 0,
		"spawn": Vector2(620 * 16, 1572), "creatures": [], "ground_life": [], "ground_life_version": 1,
		"ground_cover_version": 1, "surface_rocks_version": 1, "desert_flora_version": 1,
		"forest_density_version": 2, "underground_version": 1, "underworld_structures_version": 1,
		"cave_life_version": 1, "vines_version": 1, "wildlife_version": 1, "flyers_version": 1}
	g.worlds.clear(); g.worlds[g._world_key()] = g.world
	g._reset_world_environment()
	g.world_texture = WG.make_texture(grid); g.world_image = g.world_texture.get_image()
	g.player_pos = g.world.spawn; g.player_velocity = Vector2.ZERO
	g._update_camera(); g.scene_name = "planet"
func advance(g, seconds: float, fps := 60) -> void:
	for i in range(roundi(seconds * fps)): g.sand_gravity.update(g, 1.0 / fps)
func run() -> void:
	# A sealed U-shaped passage must equalize by pushing water uphill.
	var world := pressure_fixture()
	var water := Water.new(); water.bind_world(world)
	water.rain_amounts[70 * WG.WIDTH + 600] = 100; water.rain_cells[70 * WG.WIDTH + 600] = true
	var original := total(water.amounts)
	water.set_active_region(Vector2(602 * 16, 73 * 16))
	for tick in range(350): water.update(0.08)
	check(water.amount_at(Vector2i(604, 74)) > 0, "Pressure cannot climb the return shaft")
	check(water.amount_at(Vector2i(604, 69)) == 0, "Pressure rose above source head")
	check(total(water.amounts) == original and total(water.rain_amounts) == 100, "Pressure lost/created natural or rain water")
	print("PRESSURE return74=", water.amount_at(Vector2i(604, 74)), " conserved=", original)
	world = pressure_fixture(true); water.bind_world(world)
	for tick in range(200): water.update(0.08)
	check(water.amount_at(Vector2i(604, 77)) == 0, "Pressure passed through a sealed wall")
	# Broad connected chambers exposed a starvation bug: tiny nearby surface
	# differences must not consume all pressure transfers ahead of lower outlets.
	var broad_grid := PackedByteArray(); broad_grid.resize(WG.WIDTH * WG.HEIGHT); broad_grid.fill(3)
	for y in range(70, 90):
		for x in range(580, 610):
			if x not in [585, 599] or y >= 88:
				WG.set_tile(broad_grid, x, y, 4 if (x < 585 and y >= 72) or y >= 88 else 0)
	world = {"tiles": broad_grid}; water.bind_world(world)
	water.set_active_region(Vector2(595 * 16, 80 * 16)); original = total(water.amounts)
	for i in range(650): water.update(0.08)
	var left_level := 0.0; var right_level := 0.0
	for y in range(70, 90):
		if water.amount_at(Vector2i(582, y)) > 0 and left_level == 0: left_level = y + 1.0 - water.amount_at(Vector2i(582, y)) / 255.0
		if water.amount_at(Vector2i(605, y)) > 0 and right_level == 0: right_level = y + 1.0 - water.amount_at(Vector2i(605, y)) / 255.0
	check(left_level > 0 and right_level > 0 and absf(left_level - right_level) < 0.03, "Broad chambers failed to equalize their partial surface levels")
	check(total(water.amounts) == original, "Broad pressure test changed total water")
	var g = load("res://main.tscn").instantiate()
	root.add_child(g); g.set_process(false); await g._open_planet(0); g.hide(); g.sound.clips.clear()
	g.save_path = "user://terrain_mechanics_check.json"
	for fps in [30, 60, 120]:
		fixture(g)
		for y in range(90, 93): g._edit_tile(Vector2i(600, y), 45 if y == 91 else 5)
		g._edit_tile(Vector2i(600, 93), 3)
		advance(g, 0.4, fps)
		check(g.sand_gravity.pieces.is_empty(), "Supported sand fell")
		g._edit_tile(Vector2i(600, 93), 0)
		advance(g, 3, fps)
		check(g.sand_gravity.pieces.is_empty(), "Falling column did not settle at %d FPS" % fps)
		check(WG.tile_at(g.world.tiles, 600, 99) == 5 and WG.tile_at(g.world.tiles, 600, 98) == 45 and WG.tile_at(g.world.tiles, 600, 97) == 5, "Column lost blocks or changed material/order")
		check(WG.tile_at(g.world.tiles, 600, 90) == 0, "Source block duplicated")
	# Characters must not be entombed by settling material.
	fixture(g); g.player_pos = Vector2(600 * 16, 100 * 16 - 28)
	g._edit_tile(Vector2i(600, 90), 5); advance(g, 3)
	check(g.sand_gravity.pieces.size() == 1 and not g._collides(g.player_pos), "Falling sand buried player")
	g.player_pos.x += 32; advance(g, 2)
	check(g.sand_gravity.pieces.is_empty() and WG.tile_at(g.world.tiles, 600, 99) == 5, "Sand did not resume after player moved")
	# Submerged settling pushes water into connected free space, preserving tags.
	fixture(g)
	for y in range(95, 100): g._edit_tile(Vector2i(600, y), 4)
	g.water_sim.rain_amounts[99 * WG.WIDTH + 600] = 90; g.water_sim.rain_cells[99 * WG.WIDTH + 600] = true
	original = total(g.water_sim.amounts)
	g._edit_tile(Vector2i(600, 90), 45); advance(g, 5)
	check(g.sand_gravity.pieces.is_empty() and WG.tile_at(g.world.tiles, 600, 99) == 45, "Gravel cannot settle underwater")
	check(total(g.water_sim.amounts) == original and total(g.water_sim.rain_amounts) == 90, "Settling deleted water")
	check(g.water_sim.amount_at(Vector2i(600, 99)) == 0, "Water trapped inside gravel")
	# Scenery counts as support, despite being passable to characters.
	fixture(g); g._edit_tile(Vector2i(600, 99), 30); g.world.chest_contents = {"600,99": {"Gold Ore": 7}}
	g._edit_tile(Vector2i(600, 90), 5); advance(g, 3)
	check(WG.tile_at(g.world.tiles, 600, 99) == 30 and g.world.chest_contents["600,99"]["Gold Ore"] == 7, "Falling sand overwrote chest")
	check(WG.tile_at(g.world.tiles, 600, 98) == 5, "Sand did not rest above scenery")
	# Real mine operation returns gravel, and shovels retain their speed advantage.
	fixture(g); g._edit_tile(Vector2i(600, 99), 45)
	g.player_pos = Vector2(598 * 16, 100 * 16 - 28); g.inventory = {"Shovel": 1}; g.equipped_tool = "Shovel"
	for hit in range(g.Tools.mining_hits("Shovel", 45)):
		g.mining_cooldown = 0; g._mine(Vector2(600 * 16 + 8, 99 * 16 + 8) - g.camera_pos)
	check(WG.tile_at(g.world.tiles, 600, 99) == 0 and g.world.get("drops", []).size() == 1 and g.world.drops[0].item == "Gravel", "Settled gravel mining/drop failed")
	check(g.Tools.mining_damage("Shovel", 45) > g.Tools.mining_damage("Pickaxe", 45), "Gravel lost shovel progression")
	g.inventory["Gravel"] = 1
	var gravel_slot: int = g.hotbar.add("Gravel", g.inventory)
	g._select_hotbar_slot(gravel_slot)
	g._place(Vector2(600 * 16 + 8, 97 * 16 + 8) - g.camera_pos)
	check(WG.tile_at(g.world.tiles, 600, 97) == 45 and g.inventory.Gravel == 0, "Hotbar gravel placement failed")
	advance(g, 2)
	check(WG.tile_at(g.world.tiles, 600, 99) == 45, "Player-placed gravel does not fall")
	check(g.dev_controls.resolve_item("gravel") == "Gravel", "Developer gravel command not recognized")
	# Actual save/load while a block is airborne, with no material duplication.
	fixture(g); g._edit_tile(Vector2i(600, 90), 45); advance(g, 0.25)
	check(g.sand_gravity.pieces.size() == 1, "Missing airborne save fixture")
	var old_y: float = g.sand_gravity.pieces[0].y
	g._save_game(); g._load_game()
	while g.scene_name == "loading": await process_frame
	check(g.sand_gravity.pieces.size() == 1 and is_equal_approx(float(g.sand_gravity.pieces[0].y), old_y), "Reload lost falling state")
	advance(g, 3)
	check(g.sand_gravity.pieces.is_empty() and WG.tile_at(g.world.tiles, 600, 99) == 45 and WG.tile_at(g.world.tiles, 600, 90) == 0, "Reload duplicated/lost gravel")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(g.save_path))
	var generated := WG.generate(67134, 3, false)
	check(generated.tiles.count(45) > 100, "New worlds have no gravel deposits")
	var generated_again := WG.generate(67134, 3, false)
	check(generated.tiles == generated_again.tiles, "Gravel generation is not deterministic")
	print("TERRAIN_MECHANICS_CHECK failures=", failures)
	g.free(); quit(0 if failures == 0 else 1)
