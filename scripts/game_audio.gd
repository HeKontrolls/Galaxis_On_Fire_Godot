extends Node

signal played(event: String, at: Vector2)

const WG = preload("res://scripts/world_gen.gd")
const Tools = preload("res://scripts/tool_catalog.gd")
const VOICES := 12
const STEP_DISTANCE := 56.0
const FOOTSTEPS_ENABLED := false # Waiting for John's replacement walking sounds.
const BUS_NAMES := ["Galaxis", "Galaxis Effects", "Galaxis Ambience"]
var game
var clips := {}
var voices: Array[AudioStreamPlayer] = []
var rain_player: AudioStreamPlayer
var rain_filter: AudioEffectLowPassFilter
var rain_gain := 0.0
var rain_target := 0.0
var step_distance := 0.0
var last_position := Vector2.ZERO
var walking := false
var enabled_last_frame := false
var voice_cursor := 0
var cooldowns := {}
var last_variants := {}
var rng := RandomNumberGenerator.new()


func _init(owner_game) -> void:
	game = owner_game
	rng.seed = 0x6A1A715


func _ready() -> void:
	for bus in BUS_NAMES:
		if AudioServer.get_bus_index(bus) < 0:
			AudioServer.add_bus()
			AudioServer.set_bus_name(AudioServer.bus_count - 1, bus)
		AudioServer.set_bus_send(AudioServer.get_bus_index(bus), "Master" if bus == "Galaxis" else "Galaxis")
	for material in ["grass", "dirt", "stone", "wood", "snow", "water"]:
		_load_variants("step_" + material)
	for material in ["dirt", "stone", "wood", "leaf"]:
		_load_variants("mine_" + material)
	for event in ["swing_light", "swing_metal", "pickup"]:
		_load_variants(event)
	for _voice in range(VOICES):
		var player := AudioStreamPlayer.new()
		player.bus = "Galaxis Effects"
		add_child(player)
		voices.append(player)
	rain_player = AudioStreamPlayer.new()
	rain_player.bus = "Galaxis Ambience"
	add_child(rain_player)
	var stream := _load_wave("res://assets/audio/rain_loop.wav")
	if stream != null:
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		stream.loop_begin = 0
		stream.loop_end = int(round(stream.get_length() * stream.mix_rate))
		rain_player.stream = stream
	var bus := AudioServer.get_bus_index("Galaxis Ambience")
	if AudioServer.get_bus_effect_count(bus) == 0:
		AudioServer.add_bus_effect(bus, AudioEffectLowPassFilter.new())
	rain_filter = AudioServer.get_bus_effect(bus, 0)
	rain_filter.cutoff_hz = 9000.0


func _load_variants(event: String) -> void:
	var variants: Array[AudioStreamWAV] = []
	for index in range(3):
		var stream := _load_wave("res://assets/audio/%s_%d.wav" % [event, index])
		if stream != null:
			variants.append(stream)
	clips[event] = variants


func _load_wave(path: String) -> AudioStreamWAV:
	# Fresh checkouts can play before the editor imports WAVs. Exported games
	# use Godot's imported resource remaps when original WAV files are absent.
	if FileAccess.file_exists(path):
		return AudioStreamWAV.load_from_file(path)
	return load(path) as AudioStreamWAV


func configure(settings: Dictionary) -> void:
	for pair in [["Galaxis", "master_volume", 0.8], ["Galaxis Effects", "effects_volume", 0.8], ["Galaxis Ambience", "ambience_volume", 0.65]]:
		var bus := AudioServer.get_bus_index(pair[0])
		var gain := clampf(float(settings.get(pair[1], pair[2])), 0.0, 1.0)
		AudioServer.set_bus_mute(bus, gain <= 0.0)
		AudioServer.set_bus_volume_db(bus, linear_to_db(gain) if gain > 0.0 else -80.0)


func _effects_enabled() -> bool:
	return game.scene_name == "planet" and not game.world.is_empty() and not game.paused \
		and not game.inventory_open and not game.crafting_open and not game.dialogue_open and not game.dev_mode


func _play(event: String, at: Vector2, gain: float, pitch: float = 1.0, audition: bool = false) -> void:
	if not audition and not _effects_enabled():
		return
	var category := event.get_slice("_", 0)
	if float(cooldowns.get(category, 0.0)) > 0.0 or not clips.has(event) or clips[event].is_empty():
		return
	cooldowns[category] = 0.07 if category == "pickup" else (0.09 if category == "swing" else 0.04)
	var variants: Array = clips[event]
	var index := rng.randi_range(0, variants.size() - 1)
	if index == int(last_variants.get(event, -1)) and variants.size() > 1:
		index = (index + 1) % variants.size()
	last_variants[event] = index
	var player := voices[voice_cursor]
	for offset in range(VOICES):
		var candidate := voices[(voice_cursor + offset) % VOICES]
		if not candidate.playing:
			player = candidate
			break
	voice_cursor = (voice_cursor + 1) % VOICES
	player.stop()
	player.stream = variants[index]
	player.volume_db = linear_to_db(gain)
	player.pitch_scale = clampf(pitch * rng.randf_range(0.96, 1.04), 0.7, 1.5)
	player.play()
	played.emit(event, at)


func swing(tool: String, at: Vector2) -> void:
	if tool == "Hand" or tool == "Watering Can":
		return
	var metallic := tool.begins_with("Copper ") or tool.begins_with("Iron ") or Tools.family(tool) == "Sword"
	_play("swing_metal" if metallic else "swing_light", at, 0.42, 1.0 + 0.04 * (Tools.tier(tool) - 1))


func impact(tile_id: int, at: Vector2) -> void:
	var material := "dirt"
	if tile_id in [3, 6, 10, 17, 20, 21, 22, 23, 24, 35, 37]:
		material = "stone"
	elif tile_id in [7, 9, 30, 33, 34, 36]:
		material = "wood"
	elif tile_id == 8:
		material = "leaf"
	_play("mine_" + material, at, 0.82)


func pickup(at: Vector2) -> void:
	_play("pickup", at, 0.55)


func audition() -> void:
	_play("pickup", game.player_pos + Vector2(8, 14), 0.55, 1.0, true)


func reset_world() -> void:
	for player in voices:
		player.stop()
	if rain_player != null:
		rain_player.stop()
	rain_gain = 0.0
	rain_target = 0.0
	step_distance = 0.0
	enabled_last_frame = false
	cooldowns.clear()
	last_position = game.player_pos


func _foot_material() -> String:
	var feet: Vector2 = game.player_pos + Vector2(8, 27)
	if game.water_sim.submerged(feet):
		return "water"
	var above := Vector2i(floor(feet / WG.TILE))
	if game.snowfall.amounts.size() > 0 and above.x >= 0 and above.y >= 0 and above.x < WG.WIDTH and above.y < WG.HEIGHT:
		if game.snowfall.amounts[above.y * WG.WIDTH + above.x] > 0:
			return "snow"
	var ground := Vector2i(floor((feet + Vector2(0, 2)) / WG.TILE))
	match WG.tile_at(game.world["tiles"], ground.x, ground.y):
		1: return "grass"
		2, 5, 12, 13: return "dirt"
		6: return "snow"
		7, 9, 33, 34, 36: return "wood"
	return "stone"


func update(delta: float) -> void:
	for category in cooldowns:
		cooldowns[category] = maxf(0.0, float(cooldowns[category]) - delta)
	var enabled := _effects_enabled()
	if enabled_last_frame and not enabled:
		for player in voices:
			player.stop()
	var travel: Vector2 = game.player_pos - last_position
	walking = FOOTSTEPS_ENABLED and enabled and enabled_last_frame and game.player_grounded and not game.dev_free_flight \
		and absf(travel.x) > 0.01 and travel.length() <= maxf(8.0, game.SPEED * delta * 2.0) and absf(travel.y) < 5.0
	if walking:
		step_distance += absf(travel.x)
		if step_distance >= STEP_DISTANCE:
			step_distance = fmod(step_distance, STEP_DISTANCE)
			_play("step_" + _foot_material(), game.player_pos + Vector2(8, 28), 0.7)
	else:
		step_distance = 0.0
	last_position = game.player_pos
	enabled_last_frame = enabled
	_update_rain(delta)


func _update_rain(delta: float) -> void:
	rain_target = 0.0
	var cutoff := 9000.0
	if game.scene_name == "planet" and not game.world.is_empty() and game._is_raining():
		var tile := Vector2i(floor((game.player_pos + Vector2(8, 14)) / WG.TILE))
		var covered: bool = tile.y >= game.environment.roof[clampi(tile.x, 0, WG.WIDTH - 1)]
		rain_target = 0.10 * game._rain_strength() if covered else (0.70 * game.weather_blend.amount("Rain") + 0.95 * game.weather_blend.amount("Storm"))
		cutoff = 1200.0 if covered else 9000.0
		if not _effects_enabled():
			rain_target *= 0.35
	rain_gain = move_toward(rain_gain, rain_target, maxf(0.0, delta) * 0.6)
	rain_filter.cutoff_hz = lerpf(rain_filter.cutoff_hz, cutoff, 1.0 - exp(-delta * 3.0))
	if rain_gain > 0.001 and rain_player.stream != null:
		rain_player.volume_db = linear_to_db(rain_gain)
		if not rain_player.playing:
			rain_player.play()
	else:
		rain_player.stop()
