extends RefCounted
const WG = preload("res://scripts/world_gen.gd")
const Art = preload("res://scripts/sprite_art.gd")
const LIFE := 0.8
const LIMIT := 64
var tracks := {}
var effects: Array = []
var sheet: Texture2D

func reset() -> void:
	tracks.clear(); effects.clear()

func surface_at(sim, body: Rect2, old: Rect2) -> Vector2:
	var best := Vector2.INF
	var distance := INF
	var first := maxi(0, floori(minf(body.position.y, old.position.y) / 16) - 1)
	var last := mini(WG.HEIGHT - 1, ceili(maxf(body.end.y, old.end.y) / 16) + 2)
	if last - first > 16: return best
	for px in [body.get_center().x, body.position.x + 2, body.end.x - 2]:
		var x := floori(px / 16)
		for y in range(first, last + 1):
			var amount: int = sim.amount_at(Vector2i(x, y))
			if amount < 8 or sim.amount_at(Vector2i(x, y - 1)) > 0: continue
			var height := (y + 1) * 16.0 - amount * 16.0 / 255.0
			var d := absf(height - body.end.y)
			if d < distance:
				distance = d; best = Vector2(px, height)
	return best

func observe(sim, key: String, body: Rect2, delta: float) -> void:
	# Collision-stopped mobs can land a few pixels above the surface.
	var wet: bool = sim.intersects(Rect2(body.position, body.size + Vector2(0, 4)))
	if not tracks.has(key):
		tracks[key] = {"body": body, "wet": wet, "cooldown": 0.0}; return
	var previous: Dictionary = tracks[key]
	var old: Rect2 = previous.body
	var motion := body.position - old.position
	var cooldown := maxf(0, float(previous.cooldown) - delta)
	if motion.length() < 160:
		var at := surface_at(sim, body, old)
		if at.is_finite() and absf(at.y - body.end.y) < body.size.y + 32:
			var crossing := wet != bool(previous.wet)
			if crossing or (wet and motion.length() > 0.2 and cooldown <= 0):
				if effects.size() >= LIMIT: effects.pop_front()
				effects.append({"at": at, "age": 0.0, "splash": crossing, "strength": clampf(0.6 + absf(motion.y) / maxf(delta, 0.001) / 350, 0.6, 1.2)})
				cooldown = 0.18
	tracks[key] = {"body": body, "wet": wet, "cooldown": cooldown}

func update(game, delta: float) -> void:
	for effect in effects: effect.age = float(effect.age) + delta
	effects = effects.filter(func(effect): return float(effect.age) < LIFE)
	var seen := {}
	var actors := {"player": Rect2(game.player_pos, Vector2(16, 28))}
	var npc: Dictionary = game.world.get("npc", {})
	if not npc.is_empty(): actors["npc"] = Rect2(Vector2(float(npc.x), float(npc.y)), Vector2(12, 29))
	var creatures: Array = game.world.get("creatures", [])
	for i in range(creatures.size()):
		var c: Dictionary = creatures[i]
		if bool(c.get("alive", false)): actors["mob_%d" % i] = Rect2(Vector2(float(c.x), float(c.y)), Vector2(24, 18))
	for entry in game.ground_life.visible(game):
		if game.GroundLife.animal(str(entry.species)):
			actors["animal_%s" % entry.id] = Rect2(game.ground_life.position(entry) - Vector2(7, 12), Vector2(14, 12))
	var view := Rect2(game.camera_pos - Vector2(96, 96), Vector2(1472, 912))
	for key in actors:
		if not view.intersects(actors[key]): continue
		observe(game.water_sim, key, actors[key], delta); seen[key] = true
	for key in tracks.keys():
		if not seen.has(key): tracks.erase(key)

func draw(game) -> void:
	if effects.is_empty(): return
	if sheet == null: sheet = Art.texture("res://assets/sprites/underground/water_interactions.png")
	for effect in effects:
		var frame := mini(7, int(float(effect.age) / LIFE * 8))
		var at: Vector2 = effect.at - game.camera_pos
		game.draw_texture_rect_region(sheet, Rect2((at - Vector2(32, 16)).round(), Vector2(64, 24)), Rect2(frame * 64, 24 if effect.splash else 0, 64, 24), Color(1, 1, 1, (1.0 - float(effect.age) / LIFE) * float(effect.strength)))
