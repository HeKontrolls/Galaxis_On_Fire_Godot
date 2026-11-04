extends RefCounted
const WG = preload("res://scripts/world_gen.gd")
const Art = preload("res://scripts/sprite_art.gd")
const NAMES := ["Mosswing", "Reed darter", "Cloud ray", "Sand hornet", "Ash glider", "Shardwing", "Rime moth", "Dusk bat"]
var sheets := {}

static func fits(world: Dictionary, at: Vector2) -> bool:
	if at.x < 16 or at.y < 16 or at.x > WG.WIDTH * 16 - 40 or at.y > WG.HEIGHT * 16 - 34: return false
	for y in range(floori(at.y / 16), floori((at.y + 17) / 16) + 1):
		for x in range(floori(at.x / 16), floori((at.x + 23) / 16) + 1):
			var tile := WG.tile_at(world["tiles"], x, y)
			if WG.is_solid(tile) or tile in [4, 11]: return false
	return true

static func prepare(world: Dictionary) -> void:
	if int(world.get("flyers_version", 0)) >= 1: return
	world["flyers_version"] = 1
	var rng := RandomNumberGenerator.new()
	rng.seed = int(world["seed"]) ^ 0xF17A
	var creatures: Array = world.get("creatures", [])
	var family := clampi(int(world["climate"]), 0, 7)
	var count := 0
	for attempt in range(100):
		if count >= 6: break
		var x := rng.randi_range(20, WG.WIDTH - 20)
		# Surface metadata may describe the seabed beneath frozen oceans.
		# Find the actual topmost obstruction, including water and ice spires.
		var roof := int(world["surface"][x])
		for column in [x, x + 1]:
			for row in range(2, roof + 1):
				var tile := WG.tile_at(world["tiles"], column, row)
				if WG.is_solid(tile) or tile in [4, 11]:
					roof = mini(roof, row)
					break
		var at := Vector2(x * 16, maxi(32, roof * 16 - rng.randi_range(90, 180)))
		if absf(at.x - world["spawn"].x) < 320 or not fits(world, at): continue
		var phase := rng.randf_range(0, TAU)
		creatures.append({"flying": true, "monster_family": family, "monster_morph": rng.randi_range(0, 2),
			"monster_phase": phase, "flight_phase": phase, "x": at.x, "y": at.y, "home_x": at.x, "home_y": at.y,
			"direction": 1, "hp": 24 + family * 2, "max_hp": 24 + family * 2, "damage": 6 + int(family / 2),
			"speed": rng.randf_range(48, 67), "alive": true, "flight_state": "roam", "flight_timer": rng.randf_range(1, 3)})
		count += 1
	world["creatures"] = creatures

func move_clear(world: Dictionary, start: Vector2, motion: Vector2) -> Vector2:
	var position := start
	var steps := maxi(1, ceili(motion.length() / 3.0))
	var step := motion / steps
	for _i in range(steps):
		var next := position + Vector2(step.x, 0)
		if fits(world, next): position = next
		next = position + Vector2(0, step.y)
		if fits(world, next): position = next
	return position

func update(game, c: Dictionary, delta: float) -> void:
	delta = minf(delta, 0.2)
	var at := Vector2(float(c["x"]), float(c["y"]))
	var home := Vector2(float(c["home_x"]), float(c["home_y"]))
	c["flight_phase"] = float(c.get("flight_phase", 0.0)) + delta
	c["flight_timer"] = maxf(0, float(c.get("flight_timer", 0.0)) - delta)
	var state := str(c.get("flight_state", "roam"))
	var player: Vector2 = game.player_pos + Vector2(-4, 4)
	var sees: bool = at.distance_to(player) < 220 and home.distance_to(player) < 310 and game.interactions._visible(at + Vector2(12, 9), Rect2(game.player_pos, Vector2(16, 28)))
	if state == "roam" and sees and float(c["flight_timer"]) <= 0:
		state = "warn"; c["flight_timer"] = 0.6
		c["dive_x"] = player.x; c["dive_y"] = player.y
	elif state == "warn" and float(c["flight_timer"]) <= 0:
		state = "dive"; c["flight_timer"] = 0.65
	elif state == "dive" and float(c["flight_timer"]) <= 0:
		state = "recover"; c["flight_timer"] = 2.2
	elif state == "recover" and float(c["flight_timer"]) <= 0:
		state = "roam"; c["flight_timer"] = 1.0
	c["flight_state"] = state
	var family := int(c["monster_family"])
	var phase := float(c["flight_phase"])
	var width := 95.0 if family in [2, 4, 7] else 55.0
	var target := home + Vector2(sin(phase * 0.65) * width, sin(phase * (1.5 if family in [1, 3] else 0.9)) * 28)
	var speed := float(c["speed"])
	if state == "warn": target = at
	elif state == "dive":
		target = Vector2(float(c["dive_x"]), float(c["dive_y"]))
		speed = 235.0
	elif state == "recover": target = home; speed *= 1.2
	var motion := (target - at).limit_length(speed * delta)
	var moved := move_clear(game.world, at, motion)
	if motion.length() > 0.5 and moved.distance_to(at) < 0.2:
		if state == "dive": c["flight_state"] = "recover"; c["flight_timer"] = 2.2
		else:
			# Try around a local obstruction, without teleporting through it.
			moved = move_clear(game.world, at, Vector2(0, -speed * delta))
			c["flight_phase"] = phase + delta * 2
	c["moving"] = moved.distance_to(at) > 0.01
	if absf(moved.x - at.x) > 0.01: c["direction"] = 1 if moved.x > at.x else -1
	c["x"] = moved.x; c["y"] = moved.y
	if str(c["flight_state"]) == "dive" and moved.distance_to(player) < 24 and game.damage_cooldown <= 0 and not game.dev_invulnerable and game.interactions._visible(moved + Vector2(12, 9), Rect2(game.player_pos, Vector2(16, 28))):
		game.health -= game.magic.absorb(int(c["damage"])); game.damage_cooldown = 1.2
		c["flight_state"] = "recover"; c["flight_timer"] = 2.2
		game._show_notice(str(c.get("species_name", NAMES[family])) + " struck you")
		if game.health <= 0:
			game.health = 100; game.magic.respawn(); game.player_pos = game.world["spawn"]; game._show_notice("Respawned")

func texture_for(family: int) -> Texture2D:
	if not sheets.has(family): sheets[family] = Art.texture("res://assets/sprites/monsters/flying_%d.png" % family)
	return sheets[family]

func draw(game, c: Dictionary, at: Vector2, clock: float) -> void:
	var frame := posmod(int((clock + float(c["monster_phase"])) / 0.12), 6)
	var morph := int(c["monster_morph"])
	game.draw_set_transform((at + Vector2(12, 9)).round(), 0, Vector2(int(c["direction"]), 1))
	game.draw_texture_rect_region(texture_for(int(c["monster_family"])), Rect2(-32, -24, 64, 48), Rect2(frame * 64, morph * 48, 64, 48), Color("ffc3a4") if float(c.get("hit_flash", 0.0)) > 0 else Color.WHITE)
	if str(c.get("flight_state", "roam")) == "warn":
		game.draw_rect(Rect2(-1, -30, 2, 6), Color("eec276"))
		game.draw_rect(Rect2(-1, -22, 2, 2), Color("eec276"))
	game.draw_set_transform(Vector2.ZERO)
