extends "res://tests/tool_progression_check.gd"

var game
var mode := ""
var test_port := 24560
var output := ""
var checks := 0

func _process(delta: float) -> bool:
	if mode == "host" and game != null and game.scene_name == "planet": game._update_drops(delta)
	return false

func assert_check(ok: bool, label: String) -> void:
	checks += 1
	check(ok, label)
	print("CHECK ", label, " = ", ok)

func wait_until(predicate: Callable, seconds := 60.0) -> bool:
	var deadline := Time.get_ticks_msec() + int(seconds * 1000)
	while Time.get_ticks_msec() < deadline:
		if predicate.call(): return true
		await process_frame
	return false

func key(code: Key) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.pressed = true
	game._input(event)

func press(at: Vector2, button: int, down: bool) -> void:
	var event := InputEventMouseButton.new()
	event.position = at
	event.button_index = button
	event.pressed = down
	game._input(event)

func run_check() -> void:
	var args := OS.get_cmdline_user_args()
	mode = args[0] if args.size() > 0 else "host"
	test_port = int(args[1]) if args.size() > 1 else 24560
	output = args[2] if args.size() > 2 else "user://multiplayer_test"
	game = load("res://scripts/game.gd").new()
	game.name = "GalaxisOnFire"
	game.settings_path = output + "-settings.json"
	game.save_path = output + "-save.json"
	root.add_child(game)
	game.network.browser_config_path = output + "-browser.cfg"
	game.network.bookmarks.clear()
	game.network.status_changed.connect(func(message): print("SESSION ", message))
	game.set_process(false)
	if mode == "host": await host_checks()
	else: await client_checks()
	var file := FileAccess.open(output + "-" + mode + ".json", FileAccess.WRITE)
	file.store_string(JSON.stringify({"failures": failures, "checks": checks}))
	file.close()
	game.network.stop()
	game.queue_free()
	await process_frame
	print("MULTIPLAYER_", mode.to_upper(), " checks=", checks, " failures=", failures)
	quit(1 if failures else 0)

func host_checks() -> void:
	fixture(game)
	game.scene_name = "planet"
	game.player_name = "Host Fixture"
	game.player_pos.x -= 300 # Guest must collect its own drops, not the host.
	game.world.erase("npc")
	game._edit_tile(Vector2i(602, 79), 2)
	game._edit_tile(Vector2i(597, 79), 34)
	game._edit_tile(Vector2i(598, 79), 36)
	assert_check(game.network.host_game("Loopback Expedition", test_port) == OK, "Host binds ENet and discovery")
	# No UI/firewall helpers are invoked by tests.
	var ready := FileAccess.open(output + "-ready", FileAccess.WRITE)
	ready.store_string("ready")
	ready.close()
	assert_check(await wait_until(func(): return not game.network.actors.is_empty()), "Guest completes version handshake")
	if game.network.actors.is_empty(): return
	var id: int = game.network.actors.keys()[0]
	var actor = game.network.actors[id]
	assert_check(actor.inventory.is_empty() and actor.player_name == "Guest Fixture", "Guest starts with separate empty inventory and name")
	assert_check(await wait_until(func(): return game.network.field_hashes.has(id)), "Initial world transfer acknowledged")
	actor.inventory = {"Pickaxe": 1, "Wood": 8, "Stone": 4}
	actor.hotbar.add("Pickaxe", actor.inventory)
	actor.hotbar.add("Wood", actor.inventory)
	actor._select_hotbar_slot(0)
	assert_check(await wait_until(func(): return game.WG.tile_at(game.world.tiles, 602, 79) == 0), "Guest mines host terrain")
	assert_check(await wait_until(func(): return game.WG.tile_at(game.world.tiles, 603, 79) == 9), "Guest places block into shared world")
	assert_check(actor.inventory.get("Wood", 0) == 7 and game.inventory.is_empty(), "Placement consumes guest materials only")
	assert_check(await wait_until(func(): return int(actor.inventory.get("Dirt", 0)) > 0), "Guest receives magnetic terrain pickup")
	assert_check(await wait_until(func(): return actor.inventory.get("Planks", 0) == 8), "Guest crafts using shared workbench slots")
	assert_check(actor.inventory.get("Wood", 0) == 5, "Workbench consumes guest ingredients without duplication")
	actor.inventory["Copper Helmet"] = 1
	actor.inventory["Iron Shield"] = 1
	assert_check(await wait_until(func(): return actor.equipment.slots.head == "Copper Helmet" and actor.equipment.slots.shield == "Iron Shield"), "Guest equips own armor and shield through input RPC")
	assert_check(actor.inventory.get("Copper Helmet", 0) == 0 and game.equipment.defense() == 0, "Equipping transfers guest item without affecting host")
	assert_check(await wait_until(func(): return actor.equipment.blocking), "Host receives guest directional shield hold")
	game.world.creatures.append({"x": actor.player_pos.x, "y": actor.player_pos.y, "alive": true, "wildlife": false, "damage": 7})
	assert_check(await wait_until(func(): return actor.health < 100), "Guest takes authoritative creature contact damage")
	assert_check(game.health == 100, "Guest damage does not affect host health")
	game.world.creatures.clear()
	assert_check(await wait_until(func(): return actor.inventory_open), "Guest opens its backpack through input RPC")
	assert_check(not game.inventory_open, "Guest UI does not open host backpack")
	game._save_game()
	var saved: Variant = JSON.parse_string(FileAccess.get_file_as_string(game.save_path))
	var profiles: Dictionary = game._restore_network_profiles(saved.get("multiplayer_profiles", ""))
	assert_check(profiles.size() == 1 and profiles.values()[0].personal.inventory.get("Dirt", 0) > 0, "Host save retains guest inventory and typed state")
	assert_check(profiles.values()[0].personal.equipment.slots.head == "Copper Helmet", "Host save retains guest equipment slots")
	assert_check(profiles.values()[0].personal.player_pos is Vector2, "Guest position survives save serialization")
	var signal_file := FileAccess.open(output + "-saved", FileAccess.WRITE)
	signal_file.store_string("saved")
	signal_file.close()
	assert_check(await wait_until(func(): return game.network.actors.is_empty()), "Guest disconnect removes its live actor")
	assert_check(game.network.saved_profiles.size() == 1, "Disconnected character progress retained")
	assert_check(await wait_until(func(): return not game.network.actors.is_empty()), "Guest reconnects")
	if not game.network.actors.is_empty():
		var rejoined = game.network.actors.values()[0]
		assert_check(rejoined.inventory.get("Wood", 0) == 5 and rejoined.inventory.get("Planks", 0) == 8, "Reconnect restores guest inventory")
	assert_check(await wait_until(func(): return FileAccess.file_exists(output + "-rejoined")), "Guest confirms reconnect transfer")
	if "preview" in OS.get_cmdline_user_args():
		root.show()
		game.queue_redraw()
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(output + "-host.png")
	# Travel to another shared planet without giving guests host control over travel.
	game.planet_index = 1
	game.world = game.world.duplicate(true)
	game.world.seed = 714
	game.world.spawn = Vector2(610 * 16, 80 * 16 - 28)
	game.worlds[game._world_key()] = game.world
	game._reset_world_environment()
	print("TRAVEL_HOST planet=", game.planet_index, " epoch=", game.network.world_epoch)
	assert_check(await wait_until(func(): return FileAccess.file_exists(output + "-travelled")), "Guest follows host to another planet")
	game.network.stop("Host ended expedition")
	await wait_until(func(): return FileAccess.file_exists(output + "-client.json"))

func client_checks() -> void:
	# Probe loopback with the real browser socket before joining.
	game.network.add_bookmark("127.0.0.1", test_port)
	game.network.start_browser()
	assert_check(await wait_until(func(): return game.network.servers.values().any(func(entry): return int(entry.port) == test_port)), "LAN browser receives server advertisement")
	var matches: Array = game.network.servers.values().filter(func(entry): return int(entry.port) == test_port)
	if not matches.is_empty():
		var entry: Dictionary = matches[0]
		assert_check(entry.name == "Loopback Expedition" and int(entry.port) == test_port, "Browser shows host name and port")
	game.network.stop_browser()
	game.network.identity_token = "b".repeat(64)
	assert_check(game.network.join_game("127.0.0.1", test_port, "Guest Fixture", {}) == OK, "Direct IP connection starts")
	assert_check(await wait_until(func(): return game.network.ready_for_play), "Client installs shared host world")
	if not game.network.ready_for_play: return
	assert_check(game.scene_name == "planet" and game.world.tiles.size() == WG.WIDTH * WG.HEIGHT, "Full depth terrain received")
	assert_check(await wait_until(func(): return game.inventory.has("Pickaxe")), "Guest receives authoritative inventory")
	key(KEY_1)
	await create_timer(0.3).timeout
	assert_check(game.equipped_tool == "Pickaxe", "Guest equips canonical wood pickaxe")
	var previous_x: float = game.player_pos.x
	game.network.input_clock = 999
	for tick in range(3):
		game.network._movement.rpc_id(1, PackedInt32Array([KEY_D]))
		await create_timer(0.1).timeout
	game.network._movement.rpc_id(1, PackedInt32Array())
	game.network.input_clock = 0
	assert_check(await wait_until(func(): return game.player_pos.x > previous_x + 2), "Host simulates guest movement from keys")
	var target: Vector2 = Vector2(602 * 16 + 8, 79 * 16 + 8) - game.camera_pos
	press(target, MOUSE_BUTTON_LEFT, true)
	assert_check(await wait_until(func(): return game.WG.tile_at(game.world.tiles, 602, 79) == 0), "Mined terrain patch reaches guest")
	press(target, MOUSE_BUTTON_LEFT, false)
	game.inventory["Wood"] = 999 # Client-side edits must not grant real server materials.
	key(KEY_2)
	await create_timer(0.3).timeout
	target = Vector2(603 * 16 + 8, 79 * 16 + 8) - game.camera_pos
	press(target, MOUSE_BUTTON_RIGHT, true)
	press(target, MOUSE_BUTTON_RIGHT, false)
	assert_check(await wait_until(func(): return game.WG.tile_at(game.world.tiles, 603, 79) == 9), "Placed terrain patch reaches guest")
	assert_check(await wait_until(func(): return game.inventory.get("Wood", 0) == 7), "Client cannot forge authoritative inventory counts")
	assert_check(await wait_until(func(): return game.inventory.get("Dirt", 0) > 0), "Pickup inventory reaches guest")
	var motion := InputEventMouseMotion.new()
	motion.position = Vector2(598 * 16 + 8, 79 * 16 + 8) - game.camera_pos
	game._input(motion)
	key(KEY_F)
	assert_check(await wait_until(func(): return game.stations.is_open()), "Guest opens shared workbench with F")
	var index: int = game._inventory_items().find("Wood")
	var bag: Vector2 = game.window_positions.inventory + Vector2(44 + index % 8 * 54, 69 + (index / 8) * 54)
	for hit in range(2):
		press(bag, MOUSE_BUTTON_RIGHT, true)
		press(bag, MOUSE_BUTTON_RIGHT, false)
		await create_timer(0.15).timeout
	assert_check(await wait_until(func(): return game.stations.input_slots()[0].get("count", 0) == 2), "Guest deposits ingredients in station inventory")
	key(KEY_ENTER)
	key(KEY_ENTER)
	assert_check(await wait_until(func(): return game.stations.state().get("output", {}).get("Planks", 0) == 8), "Guest receives craft output in shared workbench")
	var slot: Vector2 = game.stations.slot_rect("output", 0).get_center()
	press(slot, MOUSE_BUTTON_LEFT, true)
	press(slot, MOUSE_BUTTON_LEFT, false)
	assert_check(await wait_until(func(): return game.inventory.get("Planks", 0) == 8), "Guest withdraws crafted output into own inventory")
	assert_check(await wait_until(func(): return game.inventory.get("Copper Helmet",0)==1), "Guest receives armor from host inventory")
	key(KEY_ESCAPE)
	assert_check(await wait_until(func(): return not game.stations.is_open() and not game.inventory_open), "Guest closes workbench before equipping")
	key(KEY_I)
	assert_check(await wait_until(func(): return game.inventory_open), "Guest opens backpack for equipment")
	for item in ["Copper Helmet","Iron Shield"]:
		var gear_index:int=game._inventory_items().find(item)
		var gear_point:Vector2=game.window_positions.inventory+Vector2(44+gear_index%8*54,69+(gear_index/8)*54)
		press(gear_point,MOUSE_BUTTON_RIGHT,true);press(gear_point,MOUSE_BUTTON_RIGHT,false)
		assert_check(await wait_until(func(): return item in game.equipment.slots.values()), "Equipment replicated: "+item)
	key(KEY_I)
	assert_check(await wait_until(func(): return not game.inventory_open), "Guest closes equipment backpack")
	key(KEY_3)
	await create_timer(0.3).timeout
	var shield_target:Vector2=game.player_pos+Vector2(80,11)-game.camera_pos
	press(shield_target,MOUSE_BUTTON_RIGHT,true)
	assert_check(await wait_until(func(): return game.equipment.blocking), "Guest receives authoritative shield pose")
	press(shield_target,MOUSE_BUTTON_RIGHT,false)
	assert_check(await wait_until(func(): return not game.equipment.blocking), "Guest lowers shield on release")
	key(KEY_I)
	assert_check(await wait_until(func(): return game.health < 100), "Guest receives host-authoritative health")
	assert_check(await wait_until(func(): return game.inventory_open), "Backpack UI state replicates")
	assert_check(await wait_until(func(): return FileAccess.file_exists(output + "-saved")), "Host saves connected guest")
	game.network.stop()
	await create_timer(0.6).timeout
	assert_check(game.network.join_game("127.0.0.1", test_port, "Guest Fixture", {}) == OK, "Reconnect starts")
	assert_check(await wait_until(func(): return game.network.ready_for_play), "Reconnect transfers world")
	assert_check(game.inventory.get("Wood", 0) == 5 and game.inventory.get("Planks", 0) == 8, "Guest inventory restored after reconnect")
	assert_check(game.equipment.slots.head=="Copper Helmet" and game.equipment.slots.shield=="Iron Shield", "Guest equipment restored after reconnect")
	assert_check(game.network.remote_players.has(1), "Host avatar is included in remote players")
	if "preview" in OS.get_cmdline_user_args():
		root.show()
		key(KEY_1)
		await create_timer(0.3).timeout
		game.queue_redraw()
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(output + "-client.png")
	var marker := FileAccess.open(output + "-rejoined", FileAccess.WRITE)
	marker.store_string("ready")
	marker.close()
	var travelled: bool = await wait_until(func(): return game.planet_index == 1 and game.network.ready_for_play)
	print("TRAVEL_CLIENT planet=", game.planet_index, " ready=", game.network.ready_for_play, " epoch=", game.network.client_epoch, " receiving=", game.network.incoming.get("id", -1))
	assert_check(travelled, "New host planet replaces guest world")
	assert_check(game.inventory.get("Wood", 0) == 5 and game.player_pos.distance_to(game.world.spawn) < 32, "Travel retains inventory and uses new landing site")
	assert_check(game.equipment.slots.head=="Copper Helmet" and game.equipment.slots.shield=="Iron Shield", "Planet travel retains equipped armor and shield")
	marker = FileAccess.open(output + "-travelled", FileAccess.WRITE)
	marker.store_string("ready")
	marker.close()
	assert_check(await wait_until(func(): return not game.network.active()), "Host shutdown disconnects guest cleanly")
	assert_check(game.scene_name == "menu" and game.network_menu.visible_menu(), "Guest returns to browser after host shutdown")
