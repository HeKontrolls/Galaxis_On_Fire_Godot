extends SceneTree

const WG = preload("res://scripts/world_gen.gd")
const Water = preload("res://scripts/water_sim.gd")
const CaveEnvironment = preload("res://scripts/world_environment.gd")
var failures := 0


func _initialize() -> void:
	call_deferred("run_check")


func check(condition: bool, label: String) -> void:
	if not condition:
		failures += 1
		printerr(label)


func total(values: PackedByteArray) -> int:
	var result := 0
	for value in values:
		result += value
	return result


func check_water() -> void:
	var grid := PackedByteArray()
	grid.resize(WG.WIDTH * WG.HEIGHT)
	for x in range(100, 113):
		WG.set_tile(grid, x, 110, 3)
	for y in range(100, 111):
		WG.set_tile(grid, 100, y, 3)
		WG.set_tile(grid, 112, y, 3)
	for y in range(101, 104):
		WG.set_tile(grid, 102, y, 4)
	var data := {"tiles": grid}
	var water := Water.new()
	water.bind_world(data)
	check(total(water.amounts) == 3 * 255, "Legacy water tiles must migrate to full cells")
	water.update(0.08)
	check(water.amount_at(Vector2i(102, 104)) > 0, "Unsupported water must fall")
	for _step in range(200):
		water.update(0.08)
	check(total(water.amounts) == 3 * 255, "Falling and spreading must conserve water exactly")
	var minimum := 255
	var maximum := 0
	var basin_before := 0
	for x in range(101, 112):
		var amount := water.amount_at(Vector2i(x, 109))
		minimum = mini(minimum, amount)
		maximum = maxi(maximum, amount)
		basin_before += amount
	check(minimum > 0 and float(maximum - minimum) * 16.0 / 255.0 < 1.0,
		"A settled pool must level to within one pixel at the game's tile scale: %d..%d" % [minimum, maximum])
	grid = data["tiles"]
	WG.set_tile(grid, 106, 110, 0)
	data["tiles"] = grid
	water.terrain_changed(Vector2i(106, 110), 0)
	for _step in range(100):
		water.update(0.08)
	var basin_after := 0
	for x in range(101, 112):
		basin_after += water.amount_at(Vector2i(x, 109))
	check(basin_after < basin_before / 3, "Opening a basin floor must drain its water")
	check(total(water.amounts) == 3 * 255, "Draining must not delete water")
	var target := Vector2i(-1, -1)
	for index in range(water.amounts.size()):
		if water.amounts[index] > 0:
			target = Vector2i(index % WG.WIDTH, int(index / WG.WIDTH))
			break
	check(water.displace(target), "A placed block must displace water into connected free space")
	check(water.amount_at(target) == 0 and total(water.amounts) == 3 * 255, "Displacement must conserve water")
	var sealed_grid := PackedByteArray()
	sealed_grid.resize(WG.WIDTH * WG.HEIGHT)
	sealed_grid.fill(3)
	WG.set_tile(sealed_grid, 100, 100, 4)
	var sealed := Water.new()
	sealed.bind_world({"tiles": sealed_grid})
	check(not sealed.displace(Vector2i(100, 100)) and sealed.amount_at(Vector2i(100, 100)) == 255,
		"Placement in a sealed full cell must be rejected without destroying water")
	print("WATER conservation, gravity, leveling, drainage and displacement checked")


func sandbox() -> Dictionary:
	var grid := PackedByteArray()
	grid.resize(WG.WIDTH * WG.HEIGHT)
	grid.fill(3)
	for y in range(80):
		for x in range(WG.WIDTH):
			WG.set_tile(grid, x, y, 0)
	for y in range(110, 123):
		for x in range(580, 625):
			WG.set_tile(grid, x, y, 0)
	for y in range(108, 126):
		for x in range(608, 612):
			WG.set_tile(grid, x, y, 3)
	var surface := PackedInt32Array()
	surface.resize(WG.WIDTH)
	surface.fill(80)
	return {"tiles": grid, "surface": surface, "seed": 11591, "climate": 0,
		"spawn": Vector2(600 * 16, 80 * 16 - 29), "creatures": [], "torches": {}, "drops": [], "crops": {}, "placed_chests": {}}


func check_generated_water() -> void:
	for climate in [0, 1, 2, 6]:
		var data: Dictionary = WG.generate(531209, climate)
		var water := Water.new()
		water.bind_world(data)
		var before := total(water.amounts)
		var start := Time.get_ticks_msec()
		for _tick in range(16):
			water.update(0.08)
		check(total(water.amounts) == before, "Generated planet must conserve its water: climate %d" % climate)
		print("WATER_WORLD climate=", climate, " units=", before, " active=", water.active.size(),
			" 16_ticks_ms=", Time.get_ticks_msec() - start)


func check_environment(data: Dictionary) -> void:
	var env := CaveEnvironment.new()
	env.reset(data)
	var player := Vector2(600 * 16, 115 * 16)
	var camera := player - Vector2(640, 360)
	env.prepare(camera, player, 1.0, 0.4, 0.0)
	check(env.brightness_at(Vector2(620 * 16, 115 * 16)) < 0.01, "Unlit underground areas must be black")
	check(env.brightness_at(player + Vector2(8, 14)) <= 0.20, "Player awareness must not illuminate an entire cave")
	data["torches"]["600,115"] = true
	env.invalidate()
	env.prepare(camera, player, 1.0, 0.4, 1.0)
	check(env.brightness_at(Vector2(600 * 16, 115 * 16)) > 0.95, "A torch must illuminate its immediate area")
	check(env.brightness_at(Vector2(604 * 16, 115 * 16)) > 0.5, "Torch light must spread through nearby air")
	check(env.brightness_at(Vector2(613 * 16, 115 * 16)) < 0.1, "Thick rock must obstruct torch light")
	check(env.outside(Vector2(600 * 16, 79 * 16)) and not env.outside(Vector2(600 * 16, 82 * 16)),
		"Weather must be confined to the exterior")
	var grid: PackedByteArray = data["tiles"]
	WG.set_tile(grid, 590, 75, 9)
	data["tiles"] = grid
	env.refresh_column(590)
	check(not env.outside(Vector2(590 * 16, 76 * 16)), "Fog must not enter below a constructed roof")
	for y in range(80, 90):
		WG.set_tile(grid, 620, y, 0)
	data["tiles"] = grid
	env.refresh_column(620)
	check(not env.outside(Vector2(620 * 16, 84 * 16)), "Fog must not descend into an open mine shaft")
	var layers := env.fog_layers(Vector2(580 * 16, 80 * 16 - 500), 12.0)
	check(layers.size() >= 3, "Fog must have several independent density layers")
	for layer in layers:
		var mesh: ArrayMesh = layer["mesh"]
		var arrays := mesh.surface_get_arrays(0)
		var vertices: PackedVector2Array = arrays[Mesh.ARRAY_VERTEX]
		for point in vertices:
			var column := clampi(int((point.x + 0.01) / 16), 0, WG.WIDTH - 1)
			check(point.y <= env.fog_floor[column] * 16 + 0.01,
				"Fog geometry must stop at the exterior surface")
	print("LIGHTING darkness, torch falloff, rock occlusion and exterior fog checked")


func mouse(game: Node2D, point: Vector2, button: int, pressed: bool) -> void:
	var event := InputEventMouseButton.new()
	event.position = point
	event.button_index = button
	event.pressed = pressed
	game._input(event)


func aim(game: Node2D, point: Vector2) -> void:
	var event := InputEventMouseMotion.new()
	event.position = point
	game._input(event)


func run_check() -> void:
	check_water()
	check_generated_water()
	check_environment(sandbox())
	var game: Node2D = load("res://main.tscn").instantiate()
	root.add_child(game)
	game.save_path = "user://galaxis_water_light_input_check.json"
	await process_frame
	await game._open_planet(0)
	game.set_process(false)
	game.world = sandbox()
	game.worlds[game._world_key()] = game.world
	game._reset_world_environment()
	game.world_texture = WG.make_texture(game.world["tiles"])
	game.world_image = game.world_texture.get_image()
	game.player_pos = game.world["spawn"]
	game._update_camera()
	var first: Vector2 = Vector2(601 * 16 + 8, 80 * 16 + 8) - game.camera_pos
	var second: Vector2 = Vector2(602 * 16 + 8, 80 * 16 + 8) - game.camera_pos
	var third: Vector2 = Vector2(603 * 16 + 8, 80 * 16 + 8) - game.camera_pos
	game.inventory["Pickaxe"] = 1
	game._equip_inventory_item("Pickaxe")
	mouse(game, first, MOUSE_BUTTON_LEFT, true)
	for hit in range(1, game.Tools.mining_hits("Pickaxe", 3)):
		game._update_held_actions(game.Tools.MINING_SWING + 0.01)
	aim(game, second)
	for hit in range(game.Tools.mining_hits("Pickaxe", 3)):
		game._update_held_actions(game.Tools.MINING_SWING + 0.01)
	check(WG.tile_at(game.world["tiles"], 601, 80) == 0 and WG.tile_at(game.world["tiles"], 602, 80) == 0,
		"Holding left click while moving aim must keep mining")
	mouse(game, second, MOUSE_BUTTON_LEFT, false)
	aim(game, third)
	game._update_held_actions(0.8)
	check(WG.tile_at(game.world["tiles"], 603, 80) == 3, "Releasing the mouse must stop mining")
	game.inventory["Dirt"] = 4
	game._equip_inventory_item("Dirt")
	first.y -= 16
	second.y -= 16
	mouse(game, first, MOUSE_BUTTON_RIGHT, true)
	aim(game, second)
	game._update_held_actions(0.21)
	mouse(game, second, MOUSE_BUTTON_RIGHT, false)
	check(WG.tile_at(game.world["tiles"], 601, 79) == 2 and WG.tile_at(game.world["tiles"], 602, 79) == 2
		and int(game.inventory["Dirt"]) == 2, "Holding right click must place blocks and consume exactly their cost")
	mouse(game, Vector2(37, 101), MOUSE_BUTTON_LEFT, true)
	check(game.inventory_open and not game.primary_held, "Backpack clicks must not begin mining")
	mouse(game, Vector2(37, 101), MOUSE_BUTTON_LEFT, false)
	game._key_pressed(KEY_ESCAPE)
	mouse(game, third, MOUSE_BUTTON_LEFT, true)
	game._key_pressed(KEY_I)
	game._process(0.0)
	check(not game.primary_held, "Opening a modal window must cancel a held action")
	game._key_pressed(KEY_ESCAPE)
	var partial := Vector2i(590, 79)
	game._edit_tile(partial, 4)
	game.water_sim.amounts[partial.y * WG.WIDTH + partial.x] = 91
	game.world["water"] = game.water_sim.amounts
	game._save_game()
	game._load_game()
	await process_frame
	await process_frame
	check(game.water_sim.amount_at(partial) == 91, "Partial water volume must survive a save/load round trip")
	check(game.world_image.get_pixel(partial.x, partial.y).a == 0.0, "Partial water must use its fluid renderer, not an opaque tile")
	if FileAccess.file_exists(game.save_path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(game.save_path))
	print("WATER_LIGHTING_INPUT failures=", failures)
	quit(0 if failures == 0 else 1)
