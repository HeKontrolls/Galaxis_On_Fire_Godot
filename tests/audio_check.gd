extends SceneTree

const WG = preload("res://scripts/world_gen.gd")
var failures := 0
var events: Array[String] = []


func _initialize() -> void:
	Engine.max_fps = 60
	call_deferred("run_check")


func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		printerr(message)


func count_prefix(prefix: String) -> int:
	var result := 0
	for event in events:
		if event.begins_with(prefix):
			result += 1
	return result


func fixture(game, floor_id: int = 1) -> void:
	var grid := PackedByteArray()
	grid.resize(WG.WIDTH * WG.HEIGHT)
	for x in range(WG.WIDTH):
		WG.set_tile(grid, x, 80, floor_id)
	var surface := PackedInt32Array()
	surface.resize(WG.WIDTH)
	surface.fill(80)
	game.world = {"tiles": grid, "surface": surface, "seed": 713, "climate": 0,
		"spawn": Vector2(600 * 16, 80 * 16 - 28), "crops": {}, "creatures": [],
		"drops": [], "torches": {}, "placed_chests": {}, "forest_density_version": 2}
	game.worlds[game._world_key()] = game.world
	game._reset_world_environment()
	game.world_texture = WG.make_texture(game.world["tiles"])
	game.world_image = game.world_texture.get_image()
	game.player_pos = game.world["spawn"]
	game.player_velocity = Vector2.ZERO
	game.player_grounded = true
	game._update_camera()
	game.scene_name = "planet"
	game.weather = "Clear"
	game.weather_blend.reset("Clear", int(game.world.get("climate", 0)))
	game.time_of_day = 0.25
	game.paused = false
	game.crafting_open = false
	game.inventory_open = false
	game.dialogue_open = false
	game.dev_mode = false
	game.dev_free_flight = false
	game.inventory = {"Pickaxe": 1, "Sword": 1}
	game.equipped_tool = "Pickaxe"
	game.use_pickaxe = true
	game.use_hoe = false
	game.mining_cooldown = 0.0
	game.attack_cooldown = 0.0
	game._stop_held_actions()
	game.sound.update(0.0)
	events.clear()


func key(code: Key, pressed: bool) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.pressed = pressed
	Input.parse_input_event(event)
	Input.flush_buffered_events()


func check_assets(game) -> void:
	check(game.sound.clips.size() == 13 and game.sound.voices.size() == 12,
		"All effect categories must load into a fixed voice pool")
	for event in game.sound.clips:
		var variants: Array = game.sound.clips[event]
		check(variants.size() == 3, "Every effect needs three variants: " + event)
		for clip: AudioStreamWAV in variants:
			check(clip.get_length() >= 0.15 and clip.get_length() <= 0.25
				and clip.mix_rate == 44100 and clip.format == AudioStreamWAV.FORMAT_16_BITS,
				"Effects must contain real short PCM audio: " + event)
			var peak := 0
			for byte in range(0, clip.data.size(), 2):
				peak = maxi(peak, absi(clip.data.decode_s16(byte)))
			check(peak > 1000 and peak < 32000, "Effect samples must be audible and unclipped: " + event)
		check(variants[0].data != variants[1].data, "Variants must contain distinct sound samples")
	var rain: AudioStreamWAV = game.sound.rain_player.stream
	check(rain != null and rain.stereo and is_equal_approx(rain.get_length(), 8.0)
		and rain.loop_mode == AudioStreamWAV.LOOP_FORWARD and rain.loop_end == 352800,
		"Rain must load as an eight-second stereo loop with correct sample boundaries")
	print("ASSETS 39 varied effects + stereo rain loop, PCM data and headroom checked")


func walk(game, seconds: float, fps: int) -> void:
	for _frame in range(roundi(seconds * fps)):
		game.player_pos.x += game.SPEED / fps
		game.sound.update(1.0 / fps)


func check_footsteps(game) -> void:
	var counts := []
	for fps in [30, 60, 144]:
		fixture(game)
		walk(game, 3.0, fps)
		counts.append(count_prefix("step_"))
	check(counts == [0, 0, 0], "Walking must remain silent at every frame rate until replacement sounds are supplied: " + str(counts))
	for pair in [[1, "grass"], [2, "dirt"], [3, "stone"], [9, "wood"], [6, "snow"]]:
		fixture(game, pair[0])
		walk(game, 0.5, 60)
		check(count_prefix("step_") == 0, "Walking sounds must be disabled on every floor material: " + pair[1])
	fixture(game)
	for x in range(599, 610):
		game._edit_tile(Vector2i(x, 79), 4)
	walk(game, 0.5, 60)
	check(count_prefix("step_") == 0, "Walking through shallow water must also remain silent")
	fixture(game)
	game.sound.update(2.0)
	check(count_prefix("step_") == 0, "Standing still must be silent")
	game.player_grounded = false
	walk(game, 1.0, 60)
	check(count_prefix("step_") == 0, "Airborne movement must not make footsteps")
	game.player_grounded = true
	game.player_pos.x += 500
	game.sound.update(0.016)
	check(count_prefix("step_") == 0, "Teleporting must not emit a burst of footsteps")
	fixture(game)
	for y in range(77, 80):
		game._edit_tile(Vector2i(601, y), 3)
	var start: Vector2 = game.player_pos
	key(KEY_D, true)
	for _frame in range(30):
		game._update_player(1.0 / 60)
		game.sound.update(1.0 / 60)
	key(KEY_D, false)
	check(game.player_pos.x == start.x and count_prefix("step_") == 0,
		"Holding movement against a wall must stay silent")
	fixture(game)
	key(KEY_D, true)
	key(KEY_SPACE, true)
	for _frame in range(15):
		game._update_player(1.0 / 60)
		game.sound.update(1.0 / 60)
	key(KEY_D, false)
	key(KEY_SPACE, false)
	check(not game.player_grounded and game.player_pos.x > start.x and count_prefix("step_") == 0,
		"Actual walking/jump input must suppress footsteps while airborne")
	print("FOOTSTEPS fps=30/60/144 counts=", counts, " surfaces, water, idle, walls, jumping and teleport checked")


func check_actions(game) -> void:
	fixture(game)
	var first: Vector2 = Vector2(601 * 16 + 8, 80 * 16 + 8) - game.camera_pos
	game._mine(first)
	check(events.has("swing_light") and events.has("mine_dirt") and game.mining_feedback_progress > 0,
		"A real dirt-mining hit must produce its swing, impact and partial progress")
	var before := events.size()
	game._mine(Vector2(602 * 16 + 8, 80 * 16 + 8) - game.camera_pos)
	check(events.size() == before, "Recovery-blocked mining must not spam sounds")
	game.sound.update(0.4)
	game.mining_cooldown = 0
	game._edit_tile(Vector2i(602, 80), 22)
	game.inventory["Stone Pickaxe"] = 1
	game._equip_inventory_item("Stone Pickaxe")
	game._mine(Vector2(602 * 16 + 8, 80 * 16 + 8) - game.camera_pos)
	check(events.has("mine_stone"), "Ore mining must make a stone impact")
	game.sound.update(0.4)
	game.mining_cooldown = 0
	var impacts := count_prefix("mine_")
	game._mine(Vector2(620 * 16 + 8, 80 * 16 + 8) - game.camera_pos)
	check(count_prefix("mine_") == impacts, "An out-of-reach swing must not invent a mining impact")
	fixture(game)
	for y in range(77, 80):
		game._edit_tile(Vector2i(601, y), 7)
	game.inventory["Axe"] = 1
	game._equip_inventory_item("Axe")
	for _hit in range(game.Tools.mining_hits("Axe", 7)):
		game.mining_cooldown = 0
		game._mine(Vector2(601 * 16 + 8, 79 * 16 + 8) - game.camera_pos)
		game.sound.update(0.4)
	check(count_prefix("mine_wood") == 8 and game.world["drops"].size() == 3,
		"Chopping must produce one impact per real hit, with no extra impacts per detached block")
	fixture(game)
	game._equip_inventory_item("Sword")
	game._attack()
	game._attack()
	check(count_prefix("swing_") == 1 and events.has("swing_metal"),
		"Attacks must produce a whoosh once, respecting combat recovery")
	fixture(game)
	game._drop_item("Stone", 3, Vector2i(600, 78))
	game._update_drops(0.1)
	check(count_prefix("pickup") == 0, "A drop must not chime before its pickup delay ends")
	game._update_drops(0.2)
	check(game.inventory.get("Stone", 0) == 3 and count_prefix("pickup") == 1,
		"A magnetic pickup must add the stack and play a collection sound")
	game._add_item("Stone", 4)
	check(count_prefix("pickup") == 1, "Crafting and developer item grants must not pretend to be pickups")
	for _drop in range(30):
		game.sound.pickup(game.player_pos)
	check(count_prefix("pickup") == 1, "Simultaneous pickups must be grouped to prevent excessive volume")
	game.sound.update(0.08)
	game.sound.pickup(game.player_pos)
	check(count_prefix("pickup") == 2 and game.sound.get_child_count() == 13,
		"Pickup feedback must recover quickly without creating unbounded audio players")
	for blocked in ["paused", "inventory_open", "crafting_open", "dialogue_open", "dev_mode"]:
		game.set(blocked, true)
		game.sound.update(0.2)
		before = events.size()
		game.sound.pickup(game.player_pos)
		game.sound.swing("Iron Pickaxe", game.player_pos)
		check(events.size() == before, "Paused/menu gameplay effects must be silent: " + blocked)
		game.set(blocked, false)
	print("ACTIONS actual mining, ore, trees, swings, pickups, spam limits and modal suppression checked")


func check_rain(game) -> void:
	fixture(game)
	game.weather = "Rain"
	game.weather_blend.reset(game.weather, int(game.world.get("climate", 0)))
	game.sound.update(0.25)
	check(game.sound.rain_gain > 0 and game.sound.rain_gain < game.sound.rain_target
		and game.sound.rain_player.playing, "Rain must start quietly and fade toward its target")
	game.sound.update(2.0)
	check(is_equal_approx(game.sound.rain_gain, 0.7), "Normal outdoor rain must reach its intended ambience level")
	game.weather = "Storm"
	game.weather_blend.reset(game.weather, int(game.world.get("climate", 0)))
	game.sound.update(1.0)
	check(game.sound.rain_target > 0.7, "Storm ambience must be stronger than ordinary rain")
	game._edit_tile(Vector2i(600, 70), 9)
	game.sound.update(2.0)
	check(game.sound.rain_gain <= 0.101 and game.sound.rain_filter.cutoff_hz < 1500,
		"Covered and underground rain must be quiet and muffled")
	game.player_pos.x = 640 * 16
	game.sound.update(2.0)
	check(game.sound.rain_gain > 0.7 and game.sound.rain_filter.cutoff_hz > 8500,
		"Leaving shelter must restore outdoor rain")
	game.weather = "Clear"
	game.weather_blend.reset("Clear", int(game.world.get("climate", 0)))
	game.sound.update(0.2)
	check(game.sound.rain_gain > 0 and game.sound.rain_target == 0, "Clearing weather must fade out instead of cutting abruptly")
	game.sound.update(2.0)
	check(not game.sound.rain_player.playing, "The loop must stop after the fade completes")
	game.weather = "Snow"
	game.weather_blend.reset(game.weather, int(game.world.get("climate", 0)))
	game.sound.update(2.0)
	check(not game.sound.rain_player.playing, "Snowfall must not play a rain loop")
	game.weather = "Rain"
	game.weather_blend.reset(game.weather, int(game.world.get("climate", 0)))
	game.sound.update(2.0)
	game._leave_planet()
	game.sound.update(2.0)
	check(not game.sound.rain_player.playing, "Leaving a planet must stop its weather ambience")
	print("RAIN fade-in/out, storms, roofs, cave muffling, snow and orbit transitions checked")


func check_settings(game) -> void:
	game.scene_name = "settings"
	game.settings_tab = "Audio"
	game._menu_click(Vector2(845, 280))
	check(is_equal_approx(db_to_linear(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Galaxis"))), 0.9),
		"The Master volume button must change the real game audio bus")
	for _click in range(8):
		game._menu_click(Vector2(765, 360))
	check(game.settings_data["effects_volume"] == 0 and AudioServer.is_bus_mute(AudioServer.get_bus_index("Galaxis Effects")),
		"Setting effects to zero must mute only their channel")
	game._menu_click(Vector2(845, 440))
	var saved: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(game.settings_path))
	check(is_equal_approx(saved["ambience_volume"], 0.75) and saved["effects_volume"] == 0,
		"Audio settings buttons must save the changed levels")
	var previous := count_prefix("pickup")
	game.sound.update(0.2)
	game._menu_click(Vector2(400, 520))
	check(count_prefix("pickup") == previous + 1, "The test-sound button must audition an effect while in Settings")
	game.settings_data["effects_volume"] = 1.0
	game._load_settings()
	check(game.settings_data["effects_volume"] == 0 and AudioServer.is_bus_mute(AudioServer.get_bus_index("Galaxis Effects")),
		"Saved mute levels must apply immediately when settings reload")
	var file := FileAccess.open(game.settings_path, FileAccess.WRITE)
	file.store_string('{"day_length":480,"night_dark":0.4,"fullscreen":false}')
	file.close()
	var legacy: Node2D = load("res://main.tscn").instantiate()
	legacy.settings_path = game.settings_path
	root.add_child(legacy)
	check(legacy.settings_data["master_volume"] == 0.8 and legacy.settings_data["effects_volume"] == 0.8
		and legacy.settings_data["ambience_volume"] == 0.65, "Older settings files must receive usable audio defaults")
	legacy.queue_free()
	print("SETTINGS live volume buses, channel mute, audition, saved levels and legacy defaults checked")


func check_mix(game) -> void:
	game.settings_data["master_volume"] = 0.8
	game.settings_data["effects_volume"] = 0.8
	game.sound.configure(game.settings_data)
	game.sound.update(0.2)
	game.sound.audition()
	# Check native front-channel meters: an effect recording can capture an
	# unused surround channel on a 7.1 output device and falsely report silence.
	var effects_peak := -200.0
	var master_peak := -200.0
	for _sample in range(6):
		await create_timer(0.025).timeout
		effects_peak = maxf(effects_peak, AudioServer.get_bus_peak_volume_left_db(AudioServer.get_bus_index("Galaxis Effects"), 0))
		master_peak = maxf(master_peak, AudioServer.get_bus_peak_volume_left_db(AudioServer.get_bus_index("Galaxis"), 0))
	check(effects_peak > -60 and master_peak > -60, "The actual effects and master buses must contain audible mixed samples")
	fixture(game)
	game.weather = "Rain"
	game.weather_blend.reset(game.weather, int(game.world.get("climate", 0)))
	game.sound.update(2.0)
	var rain_peak := -200.0
	for _sample in range(6):
		await create_timer(0.05).timeout
		rain_peak = maxf(rain_peak, AudioServer.get_bus_peak_volume_left_db(AudioServer.get_bus_index("Galaxis Ambience"), 0))
	check(rain_peak > -60, "The actual rain ambience bus must contain audible mixed samples")
	game.sound.reset_world()
	print("AUDIO_MIX effects_peak_db=", effects_peak, " master_peak_db=", master_peak, " rain_peak_db=", rain_peak)


func run_check() -> void:
	var game: Node2D = load("res://main.tscn").instantiate()
	game.settings_path = "user://galaxis_audio_check_settings.json"
	root.add_child(game)
	await process_frame
	await game._open_planet(0)
	game.set_process(false)
	game.sound.played.connect(func(event: String, _at: Vector2): events.append(event))
	check_assets(game)
	check_footsteps(game)
	check_actions(game)
	check_rain(game)
	check_settings(game)
	await process_frame
	await check_mix(game)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(game.settings_path))
	print("AUDIO failures=", failures)
	quit(0 if failures == 0 else 1)
