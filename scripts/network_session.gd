extends Node
## Host owns the world and runs a separate authoritative player context for each guest.
## Guests send input, never inventory, terrain edits, positions, or arbitrary method names.
const State = preload("res://scripts/network_state.gd")
const BUILD = preload("res://scripts/build_info.gd")
const WG = preload("res://scripts/world_gen.gd")
const PROTOCOL := 1
const DEFAULT_PORT := 24560
const MAX_PLAYERS := 8
const CHUNK := 24000
const TILE_BLOCK := 4096
const MAX_COMPRESSED := 8 * 1024 * 1024
const MAX_RAW := 64 * 1024 * 1024
signal status_changed(message: String)
signal browser_changed
var g
var role := ""
var ready_for_play := false
var server_name := ""
var port := DEFAULT_PORT
var status := ""
var actors := {}
var identities := {}
var saved_profiles := {}
var connected_tokens := {}
var remote_players := {}
var avatar_cache := {}
var servers := {}
var bookmarks: Array = []
var discovery: PacketPeerUDP
var browser: PacketPeerUDP
var scan_clock := 0.0
var snapshot_clock := 0.0
var actor_clock := 0.0
var input_clock := 0.0
var connection_clock := 0.0
var outgoing := {}
var field_hashes := {}
var tile_hashes := {}
var incoming := {}
var transfer_serial := 0
var last_world_key := ""
var world_epoch := 0
var client_epoch := -1
var joined_name := "Captain"
var joined_appearance := {}
var identity_path := "user://multiplayer_identity.txt"
var browser_config_path := "user://multiplayer.cfg"
var identity_token := ""
var input_rate := {}
var pending_peers := {}
var waiting_clock := 0.0
var original_save_path := ""
var cache_signature := 0
var last_motion_sent := 0

func bind(game) -> void:
	g = game
	multiplayer.peer_disconnected.connect(_peer_left)
	multiplayer.peer_connected.connect(_peer_connected)
	multiplayer.connected_to_server.connect(_connected)
	multiplayer.connection_failed.connect(func(): _connection_lost("Connection failed. Check address, port, and host firewall."))
	multiplayer.server_disconnected.connect(func(): _connection_lost("Host disconnected. Your local single-player save was not changed."))
	var cfg := ConfigFile.new()
	if cfg.load(browser_config_path) == OK: bookmarks = cfg.get_value("browser", "addresses", [])

func set_status(message: String) -> void:
	status = message
	status_changed.emit(message)
	if g != null: g._show_notice(message)

func active() -> bool: return not role.is_empty()
func is_client() -> bool: return role == "client"

func host_game(title: String, game_port: int) -> Error:
	if active(): return ERR_ALREADY_IN_USE
	var peer := ENetMultiplayerPeer.new()
	var result := peer.create_server(game_port, MAX_PLAYERS - 1, 3)
	if result != OK:
		set_status("Could not host on UDP %d: %s" % [game_port, error_string(result)])
		return result
	role = "host"
	original_save_path = g.save_path
	port = game_port
	server_name = title.strip_edges().substr(0, 48)
	if server_name.is_empty(): server_name = g.player_name + "'s expedition"
	multiplayer.multiplayer_peer = peer
	discovery = PacketPeerUDP.new()
	var discovery_error := discovery.bind(port + 1, "0.0.0.0")
	if discovery_error != OK: set_status("Hosting; LAN discovery port is busy. Guests can join directly by IP.")
	else: set_status("Hosting %s on UDP %d" % [server_name, port])
	last_world_key = ""
	return OK

func join_game(address: String, game_port: int, captain: String, appearance: Dictionary) -> Error:
	if active(): return ERR_ALREADY_IN_USE
	var peer := ENetMultiplayerPeer.new()
	var result := peer.create_client(address.strip_edges(), game_port, 3)
	if result != OK:
		set_status("Could not connect: " + error_string(result))
		return result
	joined_name = captain.strip_edges().substr(0, 24)
	if joined_name.is_empty(): joined_name = "Captain"
	joined_appearance = g.CharacterAppearance.normalize(appearance)
	role = "client"
	ready_for_play = false
	connection_clock = 0
	client_epoch = -1
	multiplayer.multiplayer_peer = peer
	set_status("Connecting to %s:%d..." % [address, game_port])
	return OK

func stop(message := "Disconnected") -> void:
	for id in actors.keys(): _save_profile(id)
	if role == "host" and not original_save_path.is_empty(): g.save_path = original_save_path
	role = ""
	ready_for_play = false
	if multiplayer.multiplayer_peer != null: multiplayer.multiplayer_peer.close()
	multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
	if discovery != null: discovery.close(); discovery = null
	for actor in actors.values(): actor.queue_free()
	actors.clear()
	identities.clear()
	connected_tokens.clear()
	remote_players.clear()
	avatar_cache.clear()
	outgoing.clear()
	field_hashes.clear()
	tile_hashes.clear()
	incoming.clear()
	pending_peers.clear()
	input_rate.clear()
	set_status(message)

func _connection_lost(message: String) -> void:
	if role != "client": return
	stop(message)
	g._stop_held_actions()
	g.scene_name = "menu"
	g.paused = false
	if g.network_menu != null: g.network_menu.connection_ended(message)

func _connected() -> void:
	if role != "client": return
	if identity_token.is_empty():
		if FileAccess.file_exists(identity_path): identity_token = FileAccess.get_file_as_string(identity_path).strip_edges()
		if identity_token.length() != 64:
			identity_token = Crypto.new().generate_random_bytes(32).hex_encode()
			var file := FileAccess.open(identity_path, FileAccess.WRITE)
			if file != null: file.store_string(identity_token)
	_hello.rpc_id(1, PROTOCOL, BUILD.full_version(), identity_token, joined_name, joined_appearance)
	set_status("Connected. Waiting for the host world...")

func _peer_connected(id: int) -> void:
	if role == "host": pending_peers[id] = Time.get_ticks_msec()

@rpc("any_peer", "call_remote", "reliable", 0)
func _hello(protocol: int, build: String, token: String, captain: String, appearance: Dictionary) -> void:
	if role != "host": return
	var id := multiplayer.get_remote_sender_id()
	if not pending_peers.has(id) or actors.has(id): return
	if protocol != PROTOCOL or build != BUILD.full_version():
		_rejected.rpc_id(id, "Different game version. Host uses " + BUILD.full_version())
		return
	if token.length() != 64 or not token.is_valid_hex_number(false) or connected_tokens.has(token):
		_rejected.rpc_id(id, "This player identity is invalid or already connected.")
		return
	identities[id] = {"token": token, "name": captain.strip_edges().substr(0, 24), "appearance": g.CharacterAppearance.normalize(appearance)}
	connected_tokens[token] = id
	# Actor creation waits until a planet is fully loaded.
	set_status("%s joined the expedition" % identities[id].name)

@rpc("authority", "call_remote", "reliable", 0)
func _rejected(message: String) -> void:
	if role == "client": _connection_lost(message)

func _peer_left(id: int) -> void:
	if role != "host": return
	_save_profile(id)
	if actors.has(id): actors[id].queue_free(); actors.erase(id)
	if identities.has(id):
		connected_tokens.erase(identities[id].token)
		set_status(identities[id].name + " disconnected")
	identities.erase(id)
	field_hashes.erase(id)
	tile_hashes.erase(id)
	outgoing.erase(id)
	input_rate.erase(id)
	pending_peers.erase(id)

func _save_profile(id: int) -> void:
	if not actors.has(id) or not identities.has(id): return
	var actor = actors[id]
	# Return staged trash to inventory so it cannot disappear on reconnect.
	actor._return_trash()
	saved_profiles[identities[id].token] = {"personal": State.personal(actor), "world_key": actor._world_key(), "name": actor.player_name, "appearance": actor.character_appearance}

func profiles_for_save() -> Dictionary:
	for id in actors: _save_profile(id)
	return saved_profiles.duplicate(true)

func _make_actor(id: int) -> void:
	var actor = g.get_script().new()
	actor.network_actor = true
	actor.network_owner = self
	actor.network_peer_id = id
	actor.name = "Guest%d" % id
	g.add_child(actor)
	actor.hide()
	actor.set_process(false)
	actor.set_process_input(false)
	actor.player_name = identities[id].name
	actor._apply_character_appearance(identities[id].appearance)
	State.install_world(actor, State.shared(g))
	actor.world_image = g.world_image
	actor.world_texture = g.world_texture
	actor.water_sim = g.water_sim
	actor.lava_sim = g.lava_sim
	actor.inventory = {}
	actor.hotbar.clear()
	actor.health = 100
	actor.player_pos = g.world.spawn
	var profile: Dictionary = saved_profiles.get(identities[id].token, {})
	if not profile.is_empty():
		State.apply_personal(actor, profile.personal)
		if str(profile.get("world_key", "")) != g._world_key(): actor.player_pos = g.world.spawn
	actor.paused = false
	actor.inventory_open = false
	actor.crafting_open = false
	actor.stations.close(false)
	actor.interactions.close(false)
	actor.alchemy.close(false)
	actor.power_ui.close(false)
	actor._stop_held_actions()
	actor.player_velocity = Vector2.ZERO
	actor.necromancy.restore_pending()
	actor._update_camera()
	actors[id] = actor
	pending_peers.erase(id)

func _process(delta: float) -> void:
	_poll_discovery()
	_poll_browser(delta)
	if role == "client":
		connection_clock += delta
		if not ready_for_play and connection_clock > 60: _connection_lost("Connection timed out while waiting for the host world."); return
		if ready_for_play:
			input_clock -= delta
			if input_clock <= 0:
				input_clock = 0.05
				var keys := PackedInt32Array()
				for key in [KEY_A, KEY_D, KEY_W, KEY_S, KEY_LEFT, KEY_RIGHT, KEY_UP, KEY_DOWN, KEY_SPACE]:
					if Input.is_key_pressed(key): keys.append(key)
				_movement.rpc_id(1, keys)
		return
	if role != "host": return
	if g.scene_name == "menu":
		stop("Hosted session ended")
		return
	if g.scene_name != "planet":
		waiting_clock -= delta
		if waiting_clock <= 0:
			waiting_clock = 2
			for id in identities: _host_waiting.rpc_id(id)
	for id in pending_peers.keys():
		if Time.get_ticks_msec() - int(pending_peers[id]) > 60000:
			multiplayer.multiplayer_peer.disconnect_peer(id)
	if g.scene_name == "planet" and not g.world.is_empty():
		_sync_shared_caches()
		if last_world_key != g._world_key():
			world_epoch += 1
			last_world_key = g._world_key()
			for id in actors.keys(): _save_profile(id); actors[id].queue_free()
			actors.clear()
			field_hashes.clear()
			tile_hashes.clear()
			outgoing.clear()
		for id in identities:
			if not actors.has(id): _make_actor(id)
			State.apply_shared(actors[id], State.shared(g))
			actors[id].expedition.data = g.expedition.data
			actors[id]._network_player_step(minf(delta, 0.05))
			_contact_damage(actors[id], delta)
			if not field_hashes.has(id) and not outgoing.has(id): _queue_world(id, true)
		actor_clock -= delta
		if actor_clock <= 0:
			actor_clock = 0.10
			var poses := _poses()
			for id in actors:
				if field_hashes.has(id):
					var raw := var_to_bytes({"personal": State.personal(actors[id]), "poses": poses})
					_player_frame.rpc_id(id, world_epoch, raw.size(), raw.compress(FileAccess.COMPRESSION_DEFLATE))
		snapshot_clock -= delta
		if snapshot_clock <= 0:
			snapshot_clock = 0.35
			for id in actors:
				if field_hashes.has(id) and not outgoing.has(id): _queue_world(id, false)
	_flush_transfers()

func _contact_damage(actor, delta: float) -> void:
	actor.damage_cooldown = maxf(0, actor.damage_cooldown - delta)
	if actor.damage_cooldown > 0: return
	for creature in g.world.get("creatures", []):
		if creature.get("mining_guardian", false): continue # Guardian attacks damage all players in its host state machine.
		if bool(creature.get("alive", false)) and not bool(creature.get("wildlife", false)) and Vector2(float(creature.x), float(creature.y)).distance_to(actor.player_pos) < 23:
			actor.health -= actor.equipment.absorb(int(creature.get("damage", 8)), Vector2(float(creature.x)+12,float(creature.y)+9))
			actor.damage_cooldown = 1.2
			if actor.health <= 0:
				actor.health = 100; actor.player_pos = g.world.spawn; actor.magic.respawn()
			return

func pickup_owner(at: Vector2):
	var nearest = g
	var distance: float = at.distance_squared_to(g.player_pos + Vector2(8, 13))
	for actor in actors.values():
		var d: float = at.distance_squared_to(actor.player_pos + Vector2(8, 13))
		if d < distance: nearest = actor; distance = d
	return nearest

func tile_changed(source, tile: Vector2i) -> void:
	var contexts: Array = [g] + actors.values()
	for context in contexts:
		if context == source: continue
		context.terrain_cache.invalidate(tile)
		context.foliage.invalidate()
		context.environment.refresh_column(tile.x)
		context.environment.invalidate()
		context.farming.track(tile, WG.tile_at(g.world.tiles, tile.x, tile.y))
		context.farming.sky_cache.clear()
	if source != g:
		g.sand_gravity.terrain_changed(tile)
		g._queue_grass_column(tile.x)

func _poses() -> Dictionary:
	var result := {1: _pose(g)}
	for id in actors: result[id] = _pose(actors[id])
	return result

func _pose(actor) -> Dictionary:
	return {"position": actor.player_pos, "velocity": actor.player_velocity, "grounded": actor.player_grounded,
		"facing": actor.facing, "name": actor.player_name, "appearance": actor.character_appearance,
		"tool": actor.equipped_tool, "aim": actor.mouse_aim_direction, "action": actor.tool_action_kind,
		"timer": actor.tool_action_timer, "duration": actor.tool_action_duration,
		"equipment": actor.equipment.slots, "blocking": actor.equipment.blocking,
		"arrows": actor.ranged.projectiles, "spells": actor.magic.projectiles, "arcs": actor.magic.arcs, "minions": actor.necromancy.minions}

func forward_event(event: InputEvent) -> void:
	if role != "client" or not ready_for_play: return
	if event is InputEventMouseMotion:
		if Time.get_ticks_msec() - last_motion_sent < 33: return
		last_motion_sent = Time.get_ticks_msec()
	var data := State.event_data(event)
	if not data.is_empty(): _input_event.rpc_id(1, data)

func release_controls() -> void:
	if role == "client" and ready_for_play: _release_controls.rpc_id(1)

@rpc("any_peer", "call_remote", "reliable", 0)
func _release_controls() -> void:
	if role != "host": return
	var id := multiplayer.get_remote_sender_id()
	if actors.has(id):
		actors[id].network_keys.clear()
		actors[id]._stop_held_actions()

@rpc("any_peer", "call_remote", "unreliable_ordered", 1)
func _movement(keys: PackedInt32Array) -> void:
	if role != "host" or keys.size() > 9: return
	var id := multiplayer.get_remote_sender_id()
	if not actors.has(id): return
	actors[id].network_keys.clear()
	for key in keys:
		if key in [KEY_A, KEY_D, KEY_W, KEY_S, KEY_LEFT, KEY_RIGHT, KEY_UP, KEY_DOWN, KEY_SPACE]: actors[id].network_keys[key] = true
	actors[id].network_last_input = Time.get_ticks_msec()

@rpc("any_peer", "call_remote", "reliable", 0)
func _input_event(data: Dictionary) -> void:
	if role != "host" or var_to_bytes(data).size() > 2048: return
	var id := multiplayer.get_remote_sender_id()
	if not actors.has(id) or g.scene_name != "planet": return
	var bucket: Dictionary = input_rate.get(id, {"time": Time.get_ticks_msec(), "count": 0})
	if Time.get_ticks_msec() - int(bucket.time) > 1000: bucket = {"time": Time.get_ticks_msec(), "count": 0}
	bucket.count += 1
	input_rate[id] = bucket
	if bucket.count > 180: return
	var event := State.input_event(data)
	if event == null: return
	actors[id]._input(event)

@rpc("authority", "call_remote", "reliable", 1)
func _player_frame(epoch: int, size: int, packed: PackedByteArray) -> void:
	if role != "client" or not ready_for_play or epoch != client_epoch: return
	if size < 1 or size > 4 * 1024 * 1024 or packed.size() > MAX_COMPRESSED: return
	var data: Variant = bytes_to_var(packed.decompress(size, FileAccess.COMPRESSION_DEFLATE))
	if not data is Dictionary: return
	State.apply_personal(g, data.personal, true)
	remote_players = data.poses
	g.queue_redraw()

func _queue_world(id: int, initial: bool) -> void:
	var shared := State.shared(g)
	var changed := {}
	var hashes: Dictionary = field_hashes.get(id, {})
	var next_hashes := {}
	for key in g.world:
		var fingerprint := hash(g.world[key])
		next_hashes[key] = fingerprint
		if initial or not hashes.has(key) or hashes[key] != fingerprint: changed[key] = g.world[key]
	shared.world = changed
	var grid: PackedByteArray = g.world.tiles
	var old_tiles: Dictionary = tile_hashes.get(id, {})
	var next_tiles := {}
	var tile_changes := []
	if initial or changed.has("tiles"):
		for start in range(0, grid.size(), TILE_BLOCK):
			var block := grid.slice(start, mini(start + TILE_BLOCK, grid.size()))
			var fingerprint := hash(block)
			next_tiles[start] = fingerprint
			if not initial and old_tiles.get(start, -1) != fingerprint: tile_changes.append([start, block])
	else: next_tiles = old_tiles
	if not initial: changed.erase("tiles")
	shared["tile_changes"] = tile_changes
	shared["world_keys"] = g.world.keys()
	shared["initial"] = initial
	shared["epoch"] = world_epoch
	shared["personal"] = State.personal(actors[id]) if initial else {}
	shared["poses"] = _poses()
	shared["name"] = actors[id].player_name
	shared["appearance"] = actors[id].character_appearance
	var raw := var_to_bytes(shared)
	if raw.size() > MAX_RAW: set_status("World snapshot exceeds the multiplayer transfer limit."); return
	var packed := raw.compress(FileAccess.COMPRESSION_DEFLATE)
	if packed.size() > MAX_COMPRESSED: set_status("World snapshot is too large to transfer."); return
	transfer_serial += 1
	outgoing[id] = {"id": transfer_serial, "bytes": packed, "raw_size": raw.size(), "offset": 0, "started": false, "hashes": next_hashes, "tile_hashes": next_tiles, "sent": Time.get_ticks_msec()}

func _flush_transfers() -> void:
	for id in outgoing.keys():
		var transfer: Dictionary = outgoing[id]
		if Time.get_ticks_msec() - int(transfer.sent) > 30000:
			multiplayer.multiplayer_peer.disconnect_peer(id); continue
		if not transfer.started:
			_transfer_begin.rpc_id(id, transfer.id, transfer.bytes.size(), transfer.raw_size)
			transfer.started = true
		for packet in range(3):
			if transfer.offset >= transfer.bytes.size(): break
			var end := mini(transfer.offset + CHUNK, transfer.bytes.size())
			_transfer_chunk.rpc_id(id, transfer.id, transfer.bytes.slice(transfer.offset, end))
			transfer.offset = end

@rpc("authority", "call_remote", "reliable", 2)
func _transfer_begin(serial: int, size: int, raw_size: int) -> void:
	if role != "client": return
	if size < 1 or size > MAX_COMPRESSED or raw_size < 1 or raw_size > MAX_RAW:
		_connection_lost("Host sent an invalid world transfer."); return
	incoming = {"id": serial, "size": size, "raw_size": raw_size, "bytes": PackedByteArray()}

@rpc("authority", "call_remote", "reliable", 2)
func _transfer_chunk(serial: int, chunk: PackedByteArray) -> void:
	if role != "client" or incoming.get("id", -1) != serial: return
	if chunk.size() > CHUNK or incoming.bytes.size() + chunk.size() > int(incoming.size):
		_connection_lost("Invalid world packet."); return
	var bytes: PackedByteArray = incoming.bytes
	bytes.append_array(chunk)
	incoming.bytes = bytes
	if bytes.size() != int(incoming.size): return
	var raw := bytes.decompress(int(incoming.raw_size), FileAccess.COMPRESSION_DEFLATE)
	var data: Variant = bytes_to_var(raw)
	incoming.clear()
	if not data is Dictionary or not data.get("world", {}) is Dictionary:
		_connection_lost("Invalid host world data."); return
	if bool(data.get("initial", false)):
		if data.world.get("tiles", PackedByteArray()).size() != WG.WIDTH * WG.HEIGHT:
			_connection_lost("Host world has an unsupported size."); return
		State.install_world(g, data)
		g.player_name = data.name
		g._apply_character_appearance(data.appearance)
		State.apply_personal(g, data.personal)
		client_epoch = int(data.epoch)
		ready_for_play = true
		connection_clock = 0
		if g.network_menu != null: g.network_menu.hide_menu()
		set_status("Joined " + server_name if not server_name.is_empty() else "Joined host expedition")
	elif int(data.get("epoch", -1)) == client_epoch:
		_apply_patch(data)
	State.apply_shared(g, data)
	remote_players = data.poses
	_transfer_ack.rpc_id(1, serial)

@rpc("any_peer", "call_remote", "reliable", 2)
func _transfer_ack(serial: int) -> void:
	if role != "host": return
	var id := multiplayer.get_remote_sender_id()
	if outgoing.has(id) and outgoing[id].id == serial:
		field_hashes[id] = outgoing[id].hashes
		tile_hashes[id] = outgoing[id].tile_hashes
		outgoing.erase(id)

func _apply_patch(data: Dictionary) -> void:
	for key in g.world.keys():
		if key not in data.world_keys: g.world.erase(key)
	for key in data.world: g.world[key] = data.world[key]
	var changes: Array = data.get("tile_changes", [])
	if not changes.is_empty():
		var grid: PackedByteArray = g.world.tiles
		var columns := {}
		var plants_changed := false
		for block in changes:
			var start: int = block[0]
			var bytes: PackedByteArray = block[1]
			if start < 0 or start + bytes.size() > grid.size(): continue
			for offset in range(bytes.size()):
				var index := start + offset
				if grid[index] == bytes[offset]: continue
				plants_changed = plants_changed or grid[index] in [7, 8] or bytes[offset] in [7, 8]
				grid[index] = bytes[offset]
				var tile := Vector2i(index % WG.WIDTH, index / WG.WIDTH)
				g.world_image.set_pixel(tile.x, tile.y, WG.terrain_underlay_color(grid[index]))
				g.terrain_cache.invalidate(tile)
				columns[tile.x] = true
		g.world.tiles = grid
		g.world_texture.update(g.world_image)
		for column in columns: g.environment.refresh_column(column)
		g.environment.invalidate()
		if plants_changed: g.foliage.invalidate()
	if data.world.has("furniture") or data.world.has("wood_background"): g.furnishings.reset(g)
	if data.world.has("power"): g.power.bind(g)
	if data.world.has("farm_plants") or data.world.has("farm_moisture"): g.farming.bind_world(g.world)
	if data.world.has("ground_life"): g.ground_life.reset(g)
	if data.world.has("vines"): g.hanging_vines.reset(g)
	if data.world.has("background_ores"): g.background_ores.reset(g)
	if data.world.has("cave_life"): g.underground.reset(g)
	if data.world.has("water"):
		g.water_sim.previous_amounts = g.water_sim.amounts
		g.water_sim.amounts = g.world.water
		g.water_sim.visual_revision += 1
	if data.world.has("lava"):
		g.lava_sim.previous_amounts = g.lava_sim.amounts
		g.lava_sim.amounts = g.world.lava
		g.lava_sim.visual_revision += 1
	if data.world.has("snow"): g.snowfall.bind_world(g.world)

func _sync_shared_caches() -> void:
	var signature := hash([g.world.get("furniture", {}), g.world.get("wood_background", {}), g.world.get("power", {}).get("nodes", {}).keys()])
	if signature == cache_signature: return
	cache_signature = signature
	g.furnishings.reset(g)
	g.power.bind(g)
	for actor in actors.values():
		actor.furnishings.reset(actor)
		actor.power.bind(actor)

@rpc("authority", "call_remote", "reliable", 0)
func _host_waiting() -> void:
	if role != "client": return
	connection_clock = 0
	ready_for_play = false
	set_status("Host is choosing or loading a planet. Waiting to land...")

func start_browser() -> Error:
	if browser != null: browser.close()
	browser = PacketPeerUDP.new()
	var result := browser.bind(0, "0.0.0.0")
	if result != OK: set_status("LAN browser unavailable: " + error_string(result)); return result
	browser.set_broadcast_enabled(true)
	scan_clock = 0
	servers.clear()
	return OK

func stop_browser() -> void:
	if browser != null: browser.close(); browser = null

func add_bookmark(address: String, game_port: int) -> void:
	var value := {"address": address.strip_edges().substr(0, 253), "port": game_port}
	if value not in bookmarks: bookmarks.append(value)
	if bookmarks.size() > 32: bookmarks.pop_front()
	var cfg := ConfigFile.new()
	cfg.set_value("browser", "addresses", bookmarks)
	cfg.save(browser_config_path)
	scan_clock = 0

func _probe(address: String, game_port: int) -> void:
	if browser.set_dest_address(address, game_port + 1) == OK:
		browser.put_packet(JSON.stringify({"galaxis_query": PROTOCOL}).to_utf8_buffer())

func _poll_browser(delta: float) -> void:
	if browser == null or not browser.is_bound(): return
	scan_clock -= delta
	if scan_clock <= 0:
		scan_clock = 2
		_probe("255.255.255.255", DEFAULT_PORT)
		_probe("127.0.0.1", DEFAULT_PORT)
		for entry in bookmarks: _probe(str(entry.address), int(entry.port))
	for packet in range(mini(32, browser.get_available_packet_count())):
		var bytes := browser.get_packet()
		var ip := browser.get_packet_ip()
		if bytes.size() > 2048: continue
		var data: Variant = JSON.parse_string(bytes.get_string_from_utf8())
		if not data is Dictionary or int(data.get("galaxis_server", 0)) != PROTOCOL: continue
		var game_port := int(data.get("port", 0))
		if game_port < 1024 or game_port > 65534: continue
		data.address = ip
		data.name = str(data.get("name", "Expedition")).substr(0, 48)
		data.seen = Time.get_ticks_msec()
		servers[ip + ":" + str(game_port)] = data
		browser_changed.emit()
	for key in servers.keys():
		if Time.get_ticks_msec() - int(servers[key].seen) > 6500:
			servers.erase(key); browser_changed.emit()

func _poll_discovery() -> void:
	if role != "host" or discovery == null or not discovery.is_bound(): return
	for packet in range(mini(16, discovery.get_available_packet_count())):
		var bytes := discovery.get_packet()
		var ip := discovery.get_packet_ip()
		var reply_port := discovery.get_packet_port()
		if bytes.size() > 128: continue
		var query: Variant = JSON.parse_string(bytes.get_string_from_utf8())
		if not query is Dictionary or int(query.get("galaxis_query", 0)) != PROTOCOL: continue
		discovery.set_dest_address(ip, reply_port)
		discovery.put_packet(JSON.stringify({"galaxis_server": PROTOCOL, "name": server_name,
			"port": port, "players": identities.size() + 1, "max": MAX_PLAYERS, "build": BUILD.full_version(),
			"ready": g.scene_name == "planet"}).to_utf8_buffer())

func draw_players() -> void:
	if not active() or g.scene_name != "planet": return
	var poses: Dictionary = _poses() if role == "host" else remote_players
	var local_id := multiplayer.get_unique_id()
	for id in poses:
		if int(id) == local_id: continue
		var pose: Dictionary = poses[id]
		_draw_projectiles(pose)
		var at: Vector2 = pose.position - g.camera_pos
		if not Rect2(-80, -80, 1440, 880).has_point(at): continue
		var appearance: Dictionary = pose.appearance
		var cache_key := str(id) + ":" + str(hash(appearance))
		if not avatar_cache.has(cache_key):
			var avatar = g.CharacterAppearance.new()
			avatar.configure(appearance if not appearance.is_empty() else g.CharacterAppearance.DEFAULT)
			avatar_cache[cache_key] = avatar
		var avatar = avatar_cache[cache_key]
		var action := "jump" if not pose.grounded else ("walk" if absf(pose.velocity.x) > 5 else "idle")
		var animation := action + ("_east" if pose.facing > 0 else "_west")
		var frame: int = g.sprite_art.frame_index("captain", animation, g.animation_clock)
		avatar.draw_body(g, at + Vector2(-8, -12), animation, frame, Color.WHITE, not str(pose.get("equipment",{}).get("head","")).is_empty())
		g.PlayerEquipment.draw_armor(g,at+Vector2(-8,-12),animation,frame,str(avatar.appearance.get("model","male")),pose.get("equipment",{}))
		var tool: String = pose.tool
		if tool != "Hand" and g.tool_textures.has(tool):
			var progress := clampf(1.0 - float(pose.timer) / maxf(0.01, pose.duration), 0, 1)
			var transform: Transform2D = g.PlayerPose.tool(at, pose.aim, pose.facing, pose.timer > 0, progress, tool, pose.action == "water")
			g.draw_set_transform_matrix(g.PlayerPose.arm_transform(g.PlayerPose.shoulder(at, pose.facing), transform.origin, pose.facing))
			g.draw_texture(avatar.arms.solid_arm, Vector2(-4, -1))
			g.PlayerEquipment.draw_sleeve(g,pose.get("equipment",{}))
			g.draw_set_transform_matrix(transform)
			g.draw_texture_rect(g.tool_textures[tool], g.Melee.draw_rect(tool), false)
			g.draw_set_transform_matrix(Transform2D.IDENTITY)
		g.PlayerEquipment.draw_shield(g,at,pose.aim,pose.facing,bool(pose.get("blocking",false)),pose.get("equipment",{}),avatar.arms.solid_arm)
		g._button_text(Rect2(at + Vector2(-70, -34), Vector2(156, 18)), pose.name, 13, Color("e5dcac"), false, Vector2.ZERO)

func _draw_projectiles(pose: Dictionary) -> void:
	for arrow in pose.get("arrows", []):
		var at: Vector2 = arrow.pos - g.camera_pos
		g.draw_set_transform(at, Vector2(arrow.vel).angle())
		g.draw_texture_rect_region(g.ranged.sheet("arrows"), Rect2(-29, -6, 32, 12), Rect2(0, int(g.Ranged.AMMO[str(arrow.ammo)].row) * 12, 32, 12))
		g.draw_set_transform_matrix(Transform2D.IDENTITY)
	for shot in pose.get("spells", []):
		var at: Vector2 = shot.pos - g.camera_pos
		var frame := posmod(int(g.animation_clock * 10), 4)
		g.draw_set_transform(at, Vector2(shot.vel).angle())
		g.draw_texture_rect_region(g.magic.texture(str(shot.kind) + "_bolt"), Rect2(-18, -8, 24, 16), Rect2(frame * 24, 0, 24, 16))
		g.draw_set_transform_matrix(Transform2D.IDENTITY)
	for arc in pose.get("arcs", []):
		var direction: Vector2 = Vector2(arc.b) - Vector2(arc.a)
		g.draw_set_transform(Vector2(arc.a) - g.camera_pos, direction.angle())
		g.draw_texture_rect_region(g.magic.texture("lightning"), Rect2(0, -4, direction.length(), 8), Rect2(posmod(int(g.animation_clock * 12), 4) * 32, 0, 32, 8))
		g.draw_set_transform_matrix(Transform2D.IDENTITY)
	var local_minions = g.necromancy.minions
	g.necromancy.minions = pose.get("minions", [])
	g.necromancy.draw()
	g.necromancy.minions = local_minions
