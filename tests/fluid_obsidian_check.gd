extends SceneTree

const WG = preload("res://scripts/world_gen.gd")
const Water = preload("res://scripts/water_sim.gd")
const Lava = preload("res://scripts/lava_sim.gd")
var failures := 0


func _initialize() -> void:
	call_deferred("run_check")


func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		printerr(message)


func total(values: PackedByteArray) -> int:
	var result := 0
	for value in values:
		result += value
	return result


func fixture(game) -> void:
	var grid := PackedByteArray()
	grid.resize(WG.WIDTH * WG.HEIGHT)
	for x in range(WG.WIDTH):
		WG.set_tile(grid, x, 80, 3)
	var surface := PackedInt32Array()
	surface.resize(WG.WIDTH)
	surface.fill(80)
	game.world = {"tiles": grid, "surface": surface, "seed": 713, "climate": 0,
		"spawn": Vector2(620 * 16, 80 * 16 - 28), "crops": {}, "creatures": [],
		"drops": [], "torches": {}, "placed_chests": {}, "forest_density_version": 2,
		"ground_life": [], "ground_life_version": 1, "ground_cover_version": 1, "surface_rocks_version": 1}
	game.worlds[game._world_key()] = game.world
	game._reset_world_environment()
	game.world_texture = WG.make_texture(game.world["tiles"])
	game.world_image = game.world_texture.get_image()
	game.player_pos = game.world["spawn"]
	game.player_velocity = Vector2.ZERO
	game._update_camera()
	game.weather = "Clear"
	game.weather_blend.reset("Clear", int(game.world.get("climate", 0)))
	game.time_of_day = 0.25
	game.inventory = {"Pickaxe": 1}
	game.equipped_tool = "Pickaxe"
	game.use_pickaxe = true
	game.use_hoe = false


func react(game, at: Vector2i) -> PackedInt32Array:
	return game.fluid_reactions.update(game, 0.1, PackedInt32Array([at.y * WG.WIDTH + at.x]))


func check_contact(game) -> void:
	var at := Vector2i(600, 79)
	for direction in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
		fixture(game)
		game._edit_tile(at, 11)
		game._edit_tile(at + direction, 4)
		var changed := react(game, at)
		check(changed.size() == 1 and WG.tile_at(game.world["tiles"], at.x, at.y) == 17,
			"Water must solidify adjacent lava into obsidian in direction " + str(direction))
		check(game.lava_sim.amount_at(at) == 0 and WG.is_solid(17), "Obsidian must replace lava with solid terrain")
		check(total(game.water_sim.amounts) == 191, "One full lava block must use 64 water units as steam")
		check(not game.fluid_reactions.steam.is_empty(), "Quenching must emit steam")
	fixture(game)
	game._edit_tile(at, 11)
	game._edit_tile(at + Vector2i(1, -1), 4)
	check(react(game, at).is_empty(), "A diagonal gap must not count as water contact")
	game._edit_tile(at + Vector2i.LEFT, 0)
	game.water_sim.add_rain(at + Vector2i.LEFT, 24)
	check(react(game, at).size() == 1 and total(game.water_sim.rain_amounts) == 0,
		"Reaction steam must consume weather tags along with the water used")
	fixture(game)
	game._edit_tile(Vector2i(0, 79), 11)
	game._edit_tile(Vector2i(WG.WIDTH - 1, 78), 4)
	check(react(game, Vector2i(0, 79)).is_empty(), "Contact must not wrap around world rows")
	game._edit_tile(Vector2i(1, 79), 4)
	check(react(game, Vector2i(0, 79)).size() == 1, "Contact at the world boundary must still work")
	fixture(game)
	game._edit_tile(Vector2i(600, 120), 11)
	game._edit_tile(Vector2i(601, 120), 4)
	check(react(game, Vector2i(600, 120)).size() == 1, "Underground contact must form obsidian too")
	print("CONTACT four directions, diagonal gaps, boundaries, caves, steam and tagged water checked")


func check_rain(game) -> void:
	fixture(game)
	var at := Vector2i(600, 79)
	game._edit_tile(at, 11)
	game.weather = "Rain"
	game.lava_sim.cool_from_rain(at, 3)
	check(react(game, at).is_empty() and game.lava_sim.cooling_fraction(79 * WG.WIDTH + 600) < 0.1,
		"One rain hit must cool a full lava block gradually rather than instantly solidifying it")
	for _hit in range(9):
		game.lava_sim.cool_from_rain(at, 3)
	check(react(game, at).is_empty(), "A lava block must stay molten until it has cooled completely")
	game.lava_sim.cool_from_rain(at, 3)
	check(react(game, at).size() == 1, "Sustained rain alone must eventually create obsidian")
	fixture(game)
	var covered := Vector2i(610, 79)
	for tile in [at, covered]:
		game._edit_tile(tile, 11)
		game._edit_tile(tile + Vector2i.LEFT, 3)
		game._edit_tile(tile + Vector2i.RIGHT, 3)
	game._edit_tile(Vector2i(610, 70), 9)
	for _tick in range(400):
		game.precipitation.update(600, 0.5, true, false, 1.0, game.environment.roof, game.water_sim, game.lava_sim)
	check(game.lava_sim.cooling_fraction(79 * WG.WIDTH + 600) == 1.0,
		"The real rain collector must cool exposed lava after enough rain")
	check(game.lava_sim.cooling_fraction(79 * WG.WIDTH + 610) == 0.0,
		"A roof must protect covered lava from rain cooling")
	check(game.water_sim.amount_at(at) == 0 and game.water_sim.amount_at(covered) == 0,
		"Rain landing on lava must cool it without spawning overlapping fluid")
	game.weather = "Rain"
	react(game, at)
	check(WG.tile_at(game.world["tiles"], 600, 79) == 17 and WG.tile_at(game.world["tiles"], 610, 79) == 11,
		"Rain must solidify the exposed pool while leaving the covered pool molten")
	check(game.fluid_reactions.steam.size() <= 64, "Steam particles must stay bounded")
	print("RAIN sustained cooling, real precipitation, roof protection and bounded steam checked")


func check_transport() -> void:
	var grid := PackedByteArray()
	grid.resize(WG.WIDTH * WG.HEIGHT)
	WG.set_tile(grid, 600, 70, 11)
	var data := {"tiles": grid}
	var lava := Lava.new()
	lava.bind_world(data)
	lava.cool_from_rain(Vector2i(600, 70), 12)
	var before := total(lava.rain_amounts)
	lava.update(0.28)
	check(total(lava.amounts) == 255 and total(lava.rain_amounts) == before,
		"Flow must conserve lava volume and its accumulated cooling")
	check(lava.rain_amounts[71 * WG.WIDTH + 600] > 0,
		"Cooling must travel with falling lava rather than remain suspended at the old location")
	check(lava.amount_at(Vector2i(599, 70)) == 0 and lava.amount_at(Vector2i(601, 70)) == 0,
		"Unsupported lava must fall before spreading sideways in midair")
	lava.reheat(1.0, true)
	check(total(lava.rain_amounts) == before, "Sustained rain must retain accumulated cooling")
	lava.reheat(1.0, false)
	check(total(lava.rain_amounts) < before, "Partially cooled lava must slowly reheat after rain stops")
	var loaded := Lava.new()
	loaded.bind_world(data)
	check(loaded.rain_amounts == lava.rain_amounts, "Rebinding a world must preserve advected lava cooling")
	print("TRANSPORT viscosity, gravity, volume, cooling advection and reheating checked")


func check_mining_and_safety(game) -> void:
	fixture(game)
	var at := Vector2i(601, 79)
	game._edit_tile(at, 11)
	game._edit_tile(at + Vector2i.RIGHT, 4)
	game.player_pos = Vector2(at * 16) - Vector2(0, 10)
	react(game, at)
	check(WG.tile_at(game.world["tiles"], at.x, at.y) == 17 and not game._collides(game.player_pos),
		"Solidifying lava must move an intersecting player clear of the new block")
	game.player_pos = Vector2(600 * 16, 80 * 16 - 28)
	game._update_camera()
	var point: Vector2 = Vector2(at * 16) + Vector2(8, 8) - game.camera_pos
	game.equipped_tool = "Hand"
	game.use_pickaxe = false
	game._mine(point)
	check(WG.tile_at(game.world["tiles"], at.x, at.y) == 17, "Obsidian must require the pickaxe")
	game.inventory["Diamond Pickaxe"] = 1
	game._equip_inventory_item("Diamond Pickaxe")
	for hit in range(game.Tools.mining_hits("Diamond Pickaxe", 17)):
		game.mining_cooldown = 0
		game._mine(point)
	check(WG.tile_at(game.world["tiles"], at.x, at.y) == 0 and game.world["drops"].size() == 1
		and game.world["drops"][0]["item"] == "Obsidian", "Mining obsidian must drop exactly one reusable obsidian block")
	game.inventory["Obsidian"] = 1
	game._equip_inventory_item("Obsidian")
	game._place(point)
	check(WG.tile_at(game.world["tiles"], at.x, at.y) == 17 and game.inventory["Obsidian"] == 0,
		"Placing obsidian must make solid terrain and consume one block")
	check(not game.water_sim._open(game.world["tiles"], at.y * WG.WIDTH + at.x)
		and not game.lava_sim._open(game.world["tiles"], at.y * WG.WIDTH + at.x), "Obsidian must obstruct both fluids")
	fixture(game)
	for x in range(596, 605):
		for y in range(74, 81):
			game._edit_tile(Vector2i(x, y), 3, false)
	game._edit_tile(Vector2i(600, 78), 0)
	game._edit_tile(Vector2i(600, 79), 11)
	game._edit_tile(Vector2i(601, 79), 4)
	game.player_pos = Vector2(600 * 16, 78 * 16)
	check(not game._collides(game.player_pos), "The sealed safety fixture must initially fit the player")
	check(react(game, Vector2i(600, 79)).is_empty() and game.lava_sim.amount_at(Vector2i(600, 79)) == 255,
		"Solidification must defer if there is no safe position for an intersecting player")
	game._edit_tile(Vector2i(600, 77), 0)
	game._edit_tile(Vector2i(600, 76), 0)
	check(react(game, Vector2i(600, 79)).size() == 1 and not game._collides(game.player_pos),
		"A deferred reaction must resume after an escape space becomes available")
	print("GAMEPLAY player escape, pickaxe requirement, drops, placement and fluid obstruction checked")


func check_saves(game) -> void:
	fixture(game)
	game.save_path = "user://galaxis_fluid_obsidian_check.json"
	game._edit_tile(Vector2i(598, 79), 17)
	game._edit_tile(Vector2i(600, 79), 11)
	game.weather = "Rain"
	game.lava_sim.cool_from_rain(Vector2i(600, 79), 12)
	game.inventory["Obsidian"] = 7
	game._save_game()
	game._load_game()
	while game.scene_name == "loading": await process_frame
	check(WG.tile_at(game.world["tiles"], 598, 79) == 17 and game.inventory["Obsidian"] == 7,
		"Obsidian terrain and inventory must survive saving")
	check(game.lava_sim.amount_at(Vector2i(600, 79)) == 255 and game.lava_sim.rain_amounts[79 * WG.WIDTH + 600] == 96,
		"A partially cooled molten pool must resume its exact cooling state after loading")
	var saved: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(game.save_path))
	for key in saved["worlds"]:
		saved["worlds"][key].erase("lava_cooling")
	var file := FileAccess.open(game.save_path, FileAccess.WRITE)
	file.store_string(JSON.stringify(saved))
	file.close()
	game._load_game()
	while game.scene_name == "loading": await process_frame
	check(total(game.lava_sim.rain_amounts) == 0 and game.lava_sim.amount_at(Vector2i(600, 79)) == 255,
		"Older saves without cooling data must load hot lava normally")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(game.save_path))
	print("SAVES obsidian, inventory, partial cooling and older saves checked")


func run_check() -> void:
	check_transport()
	var game: Node2D = load("res://main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	await game._open_planet(0)
	game.set_process(false)
	check_contact(game)
	check_rain(game)
	check_mining_and_safety(game)
	await check_saves(game)
	print("FLUID_OBSIDIAN failures=", failures)
	quit(0 if failures == 0 else 1)
