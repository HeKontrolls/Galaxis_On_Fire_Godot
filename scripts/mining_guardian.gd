extends RefCounted
## One host-simulated state machine, shared through the existing creature record.
const WG = preload("res://scripts/world_gen.gd")
const SIZE := Vector2(48, 48)
const HEALTH := 360

static func box(c: Dictionary) -> Rect2:
	return Rect2(Vector2(float(c.x), float(c.y)), SIZE)

static func fits(world: Dictionary, at: Vector2) -> bool:
	for y in range(floori(at.y / 16), floori((at.y + 47) / 16) + 1):
		for x in range(floori(at.x / 16), floori((at.x + 47) / 16) + 1):
			if x < 0 or x >= WG.WIDTH or y < 0 or y >= WG.HEIGHT or WG.is_solid(WG.tile_at(world.tiles, x, y)): return false
	return true

static func prepare(world: Dictionary) -> void:
	for c: Dictionary in world.get("creatures", []):
		if not c.get("quest_guardian", false) or c.get("mining_guardian", false) or not c.get("alive", false): continue
		var at := Vector2(float(c.x) - 12, float(c.y) - 30)
		# Do not carve through a player's construction in an older save.
		if not fits(world, at): continue
		var fraction := clampf(float(c.hp) / maxi(1, int(c.get("max_hp", 90))), 0.0, 1.0)
		c.merge({"mining_guardian": true, "x": at.x, "y": at.y, "hp": maxi(1, ceili(HEALTH * fraction)), "max_hp": HEALTH,
			"damage": 18, "boss_state": "idle", "boss_timer": 1.2, "boss_cycle": 0, "boss_vy": 0.0,
			"arena_left": float(c.get("arena_left", float(c.home_x) - 112)),
			"arena_right": float(c.get("arena_right", float(c.home_x) + 112))}, true)

static func observers(g) -> Array:
	var host = g.network_owner.g if g.network_actor and g.network_owner != null else g
	var result: Array = [host]
	if host.network != null and host.network.role == "host":
		for actor in host.network.actors.values():
			if actor.scene_name == "planet" and actor._world_key() == host._world_key(): result.append(actor)
	return result

static func move(g, c: Dictionary, offset: Vector2) -> bool:
	var steps := maxi(1, ceili(offset.length() / 3.0))
	var step := offset / steps
	for i in range(steps):
		var next := box(c).position + step
		if not fits(g.world, next): return false
		if offset.x != 0 and (next.x < float(c.arena_left) or next.x + SIZE.x > float(c.arena_right)): return false
		c.x = next.x; c.y = next.y
	return true

static func hurt(g, c: Dictionary, area: Rect2, amount: int) -> void:
	for actor in observers(g):
		if actor.dev_invulnerable or actor.damage_cooldown > 0: continue
		if not area.intersects(Rect2(actor.player_pos, Vector2(16, 28))): continue
		if not actor.interactions._visible(box(c).get_center(), Rect2(actor.player_pos, Vector2(16, 28))): continue
		actor.health -= actor.equipment.absorb(amount, box(c).get_center())
		actor.damage_cooldown = 1.2
		actor._show_notice("Mining guardian hit - jump the slam or block the drill")
		if actor.health <= 0:
			actor.health = 100; actor.player_pos = actor.world.spawn; actor.magic.respawn()
			actor._show_notice("Respawned")

static func slam_area(c: Dictionary) -> Rect2:
	return Rect2(float(c.x) - 88, float(c.y) + 28, 224, 24)

static func update(g, c: Dictionary, delta: float) -> void:
	if g.network != null and g.network.is_client(): return
	delta = minf(delta, 0.05)
	c.boss_vy = minf(480, float(c.get("boss_vy", 0)) + 600 * delta)
	if not move(g, c, Vector2(0, float(c.boss_vy) * delta)): c.boss_vy = 0.0
	var target = null
	var distance := INF
	for actor in observers(g):
		var d: float = box(c).get_center().distance_to(actor.player_pos + Vector2(8, 14))
		if d < distance: target = actor; distance = d
	if target == null or distance > 360:
		c.boss_state = "idle"; c.boss_timer = 1.2
		return
	c.boss_timer = float(c.boss_timer) - delta
	var state := str(c.boss_state)
	if state == "charge":
		c.moving = true
		if not move(g, c, Vector2(int(c.direction) * 230 * delta, 0)): c.boss_timer = 0.0
		hurt(g, c, box(c).grow(5), 18)
	if float(c.boss_timer) > 0: return
	match state:
		"idle", "recover":
			if not target.interactions._visible(box(c).get_center(), Rect2(target.player_pos, Vector2(16, 28))):
				c.boss_timer = 0.5; return
			c.direction = 1 if target.player_pos.x + 8 > box(c).get_center().x else -1
			c.boss_cycle = int(c.boss_cycle) + 1
			c.boss_state = "warn_charge" if int(c.boss_cycle) % 2 == 1 else "warn_slam"
			c.boss_timer = 1.1 if c.boss_state == "warn_charge" else 1.0
		"warn_charge": c.boss_state = "charge"; c.boss_timer = 0.65
		"warn_slam":
			c.boss_state = "slam"; c.boss_timer = 0.25
			hurt(g, c, slam_area(c), 22)
			if g.sound != null: g.sound.impact(3, box(c).get_center())
		_: c.boss_state = "recover"; c.boss_timer = 1.4

static func draw(g, c: Dictionary, at: Vector2) -> void:
	var state := str(c.get("boss_state", "idle"))
	var frame := 0
	if state == "warn_charge": frame = 2
	elif state == "charge": frame = 3 + posmod(int(g.animation_clock * 14), 2)
	elif state == "warn_slam": frame = 5
	elif state == "slam": frame = 6
	elif state == "recover": frame = 7
	else: frame = posmod(int(g.animation_clock * 3), 2)
	g.draw_set_transform((at + Vector2(24, 48)).round(), 0, Vector2(int(c.direction), 1))
	g.draw_texture_rect_region(g.expedition.texture("mining_guardian"), Rect2(-32,-64,64,64), Rect2(frame*64,0,64,64), Color("ffb9a1") if float(c.get("hit_flash",0))>0 else Color.WHITE)
	g.draw_set_transform(Vector2.ZERO)
	# Pixel bars projected on the floor warn without painting over solid walls.
	if state in ["warn_slam", "slam", "warn_charge"]:
		var area := slam_area(c) if state != "warn_charge" else Rect2(float(c.x) + (48 if int(c.direction)>0 else -150), float(c.y)+44,150,4)
		for x in range(floori(area.position.x / 8), ceili(area.end.x / 8)):
			var pos := Vector2(x*8, float(c.y)+45)
			if WG.is_solid(WG.tile_at(g.world.tiles, floori(pos.x/16), floori(pos.y/16))): continue
			g.draw_rect(Rect2(pos-g.camera_pos,Vector2(6,2)),Color("ffdb8a") if state=="slam" else Color("ed944c"))

static func draw_hud(g) -> void:
	for c: Dictionary in g.world.get("creatures", []):
		if not c.get("mining_guardian", false) or not c.get("alive", false): continue
		if box(c).get_center().distance_to(g.player_pos) > 400: continue
		g._rounded_box(Rect2(384,18,512,76),Color("14212b"),Color("be995a"),8.0)
		g._text("RUINED MINING GUARDIAN",Vector2(400,40),16,Color("eacb8e"))
		g._text("%d / %d" % [maxi(0,int(c.hp)),int(c.max_hp)],Vector2(788,40),14)
		g.draw_rect(Rect2(400,49,480,7),Color("412e35"))
		g.draw_rect(Rect2(400,49,480*clampf(float(c.hp)/int(c.max_hp),0,1),7),Color("db9062"))
		var hint := "Recovering - attack now"
		match str(c.get("boss_state", "idle")):
			"warn_charge", "charge": hint = "DRILL CHARGE - jump clear or face it with a shield"
			"warn_slam", "slam": hint = "GROUND SLAM - jump or move beyond the marked floor"
			"idle": hint = "Watch the drill; attacks follow an amber warning"
		g._text(hint,Vector2(400,78),13,Color("e4cba5"))
		return
