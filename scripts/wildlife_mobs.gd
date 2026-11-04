extends RefCounted
const WG = preload("res://scripts/world_gen.gd")
const Cave = preload("res://scripts/underground.gd")
const Art = preload("res://scripts/sprite_art.gd")
const Flyers = preload("res://scripts/flying_monsters.gd")
const NAMES := ["Meadow slime", "Brine slime", "Dune slime", "Rime slime", "Cinder slime", "Prism slime", "Cave scarab", "Pale scuttler", "Cave screecher"]
const HEALTH := [18, 22, 24, 28, 38, 32, 42, 30, 26]
const DAMAGE := [4, 5, 6, 7, 10, 8, 10, 8, 7]
var sheets := {}

static func fits(world: Dictionary, at: Vector2) -> bool:
	return Flyers.fits(world, at)

static func creature(family: int, at: Vector2, rng: RandomNumberGenerator) -> Dictionary:
	var c := {"wildlife": true, "wildlife_family": family, "monster_morph": rng.randi_range(0, 1), "monster_phase": rng.randf_range(0, 5),
		"x": at.x, "y": at.y, "home_x": at.x, "home_y": at.y, "hp": HEALTH[family], "max_hp": HEALTH[family], "alive": true,
		"direction": 1 if rng.randf() > 0.5 else -1, "damage": DAMAGE[family], "state": "rest", "timer": rng.randf_range(0.3, 1.5),
		"vx": 0.0, "vy": 0.0, "speed": rng.randf_range(46, 68), "moving": false}
	if family == 8:
		c.merge({"monster_family": 7, "species_name": NAMES[8], "flight_phase": 0.0, "flight_timer": 1.0, "flight_state": "roam"})
	return c

static func prepare(world: Dictionary) -> void:
	if int(world.get("wildlife_version", 0)) >= 1: return
	var rng := RandomNumberGenerator.new(); rng.seed = int(world["seed"]) ^ 0x511E
	var creatures: Array = world.get("creatures", [])
	var occupied := {}
	var climate := int(world["climate"])
	var surface_family: int = [0, 1, 1, 2, 4, 2, 3, 3][clampi(climate, 0, 7)]
	var surface_count := 0
	for attempt in range(1400):
		if surface_count >= 16: break
		var x := rng.randi_range(12, WG.WIDTH - 14)
		if absf(x * 16 - world["spawn"].x) < 320: continue
		for y in range(2, int(world["surface"][x]) + 4):
			var id := WG.tile_at(world["tiles"], x, y)
			if id in [4, 11]: break
			if not WG.is_solid(id): continue
			var at := Vector2(x * 16, y * 16 - 18)
			var cell := Vector2i(x / 12, y / 8)
			if fits(world, at) and not occupied.has(cell):
				creatures.append(creature(surface_family, at, rng)); occupied[cell] = true; surface_count += 1
			break
	# Quotas in each depth band keep the expanded world populated throughout.
	var bands := [[160, 359], [360, 599], [600, 839], [840, 1079], [1080, 1314], [1315, WG.HEIGHT - 20]]
	for band in bands:
		var count := 0
		for attempt in range(3200):
			if count >= 32: break
			var x := rng.randi_range(12, WG.WIDTH - 14)
			var y := rng.randi_range(int(band[0]), int(band[1]))
			if y < int(world["surface"][x]) + 36: continue
			var region := Cave.biome(world, x, y)
			var choices: Array = [[0, 6, 7, 8], [5, 6, 7, 8], [1, 1, 7, 8], [5, 5, 6, 8], [0, 1, 7, 8], [4, 6, 7, 8], [4, 4, 6, 8]][region]
			var family: int = choices[rng.randi_range(0, choices.size() - 1)]
			if family != 8:
				var found := false
				for floor_y in range(y, mini(y + 22, WG.HEIGHT - 4)):
					if WG.is_solid(WG.tile_at(world["tiles"], x, floor_y)):
						y = floor_y; found = true; break
				if not found: continue
			var at := Vector2(x * 16, y * 16 - 18)
			var cell := Vector2i(x / 8, y / 8)
			if not fits(world, at) or occupied.has(cell): continue
			creatures.append(creature(family, at, rng)); occupied[cell] = true; count += 1
	# Fortresses have local inhabitants even when nearby random caves are sparse.
	for fort in world.get("underworld_forts", []):
		for offset in [15, int(fort.width) - 15]:
			var at := Vector2((int(fort.x) + offset) * 16, (WG.HEIGHT - 32) * 16 - 18)
			if fits(world, at): creatures.append(creature(6 if offset == 15 else 7, at, rng))
	world["creatures"] = creatures
	world["wildlife_version"] = 1

static func loot(c: Dictionary) -> String:
	return "Crystal" if int(c.wildlife_family) == 5 else ("Obsidian" if int(c.wildlife_family) == 4 else ("Stone" if int(c.wildlife_family) == 6 else "Alien Fiber"))

func update(game, c: Dictionary, delta: float) -> void:
	var at := Vector2(float(c.x), float(c.y))
	if absf(at.y - game.player_pos.y) > 720: return
	if int(c.wildlife_family) == 8:
		game.flying_monsters.update(game, c, delta); return
	delta = minf(delta, 0.1)
	var family := int(c.wildlife_family)
	var grounded := not fits(game.world, at + Vector2(0, 1))
	c.timer = maxf(0, float(c.timer) - delta)
	var sees: bool = at.distance_to(game.player_pos) < 190 and absf(at.x - float(c.home_x)) < 300 and game.interactions._visible(at + Vector2(12, 9), Rect2(game.player_pos, Vector2(16, 28)))
	if absf(at.x - float(c.home_x)) > 180: c.direction = -1 if at.x > float(c.home_x) else 1
	if family < 6:
		if c.state == "rest" and grounded and float(c.timer) <= 0:
			if sees: c.direction = 1 if game.player_pos.x > at.x else -1
			c.state = "windup"; c.timer = 0.28; c.vx = 0.0
		elif c.state == "windup" and float(c.timer) <= 0:
			c.state = "hop"; c.vy = -225.0 if sees else -175.0
			c.vx = int(c.direction) * float(c.speed) * (1.4 if sees else 0.8)
		elif c.state == "hop" and grounded and float(c.vy) >= 0:
			c.state = "land"; c.timer = 0.16; c.vx = 0.0
		elif c.state == "land" and float(c.timer) <= 0:
			c.state = "rest"; c.timer = 0.5 if sees else 1.2
	else:
		if c.state == "rest":
			c.vx = int(c.direction) * 22.0
			if sees and float(c.timer) <= 0:
				c.direction = 1 if game.player_pos.x > at.x else -1
				c.state = "windup"; c.timer = 0.4; c.vx = 0.0
		elif c.state == "windup" and float(c.timer) <= 0:
			c.state = "charge"; c.timer = 0.85; c.vx = int(c.direction) * (95.0 if family == 7 else 76.0)
			if family == 7 and grounded: c.vy = -175.0
		elif c.state == "charge" and float(c.timer) <= 0:
			c.state = "recover"; c.timer = 0.9; c.vx = 0.0
		elif c.state == "recover" and float(c.timer) <= 0: c.state = "rest"; c.timer = 0.4
		if grounded and c.state == "rest":
			var ahead := Vector2i(floor((at + Vector2(12 + int(c.direction) * 21, 23)) / 16))
			if not WG.is_solid(WG.tile_at(game.world.tiles, ahead.x, ahead.y)): c.direction = -int(c.direction); c.vx = -float(c.vx)
	c.vy = minf(330, float(c.vy) + 720.0 * delta)
	var motion := Vector2(float(c.vx), float(c.vy)) * delta
	var moved: Vector2 = game.flying_monsters.move_clear(game.world, at, motion)
	if absf(moved.y - at.y - motion.y) > 0.1: c.vy = 0.0
	if absf(moved.x - at.x - motion.x) > 0.1:
		c.direction = -int(c.direction); c.vx = -float(c.vx)
	c.moving = moved.distance_to(at) > 0.1; c.x = moved.x; c.y = moved.y
	if c.state in ["hop", "charge"] and moved.distance_to(game.player_pos) < 24 and game.damage_cooldown <= 0 and not game.dev_invulnerable and game.interactions._visible(moved + Vector2(12, 9), Rect2(game.player_pos, Vector2(16, 28))):
		game.health -= game.magic.absorb(int(c.damage)); game.damage_cooldown = 1.2
		c.state = "recover" if family >= 6 else "land"; c.timer = 0.8; c.vx = 0.0
		game._show_notice(NAMES[family] + " hit you")
		if game.health <= 0: game.health = 100; game.magic.respawn(); game.player_pos = game.world.spawn; game._show_notice("Respawned")

func draw(game, c: Dictionary, at: Vector2, clock: float) -> void:
	var family := int(c.wildlife_family)
	if not sheets.has(family): sheets[family] = Art.texture("res://assets/sprites/monsters/wildlife_%d.png" % family)
	var frame := 1 if fposmod(clock + float(c.monster_phase), 1.7) > 1.55 else 0
	if family == 8: frame = posmod(int((clock + float(c.monster_phase)) / 0.11), 8)
	elif c.state == "windup": frame = 2
	elif family < 6 and c.state == "hop": frame = 3 if float(c.vy) < 0 else 4
	elif c.state == "land": frame = 5
	elif bool(c.moving): frame = 6 + posmod(int(clock / 0.13), 2)
	game.draw_set_transform((at + Vector2(12, 18)).round(), 0, Vector2(int(c.direction), 1))
	game.draw_texture_rect_region(sheets[family], Rect2(-24, -36, 48, 40), Rect2(frame * 48, int(c.monster_morph) * 40, 48, 40), Color("ffc3b0") if float(c.get("hit_flash", 0)) > 0 else Color.WHITE)
	if c.state == "windup" or (family == 8 and c.get("flight_state", "") == "warn"):
		game.draw_rect(Rect2(-1, -37, 2, 5), Color("eec276")); game.draw_rect(Rect2(-1, -30, 2, 2), Color("eec276"))
	game.draw_set_transform(Vector2.ZERO)
