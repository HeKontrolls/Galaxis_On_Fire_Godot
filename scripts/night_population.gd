extends RefCounted
## Host-only, bounded nocturnal encounters. Reuse retired slots without shifting
## creature indices used by projectiles. Existing daytime/cave populations persist.
const WG = preload("res://scripts/world_gen.gd")
const Monsters = preload("res://scripts/planet_monsters.gd")
const Wildlife = preload("res://scripts/wildlife_mobs.gd")
const Flyers = preload("res://scripts/flying_monsters.gd")
const MAX_ACTIVE := 24
const MAX_SLOTS := 64
const LOCAL_CAP := 8

static func intensity(time: float) -> float:
	# The existing sun sets at 0.5 and rises at 0.0.
	return smoothstep(0.48, 0.56, time) * (1.0-smoothstep(0.94, 1.0, time))

static func players(g) -> Array:
	var result: Array = [g]
	if g.network != null and g.network.role == "host":
		for actor in g.network.actors.values():
			if actor.scene_name == "planet" and actor._world_key() == g._world_key(): result.append(actor)
	return result

static func hidden(at: Vector2, observers: Array) -> bool:
	for actor in observers:
		if Rect2(actor.camera_pos, actor.SCREEN).grow(96).has_point(at): return false
		if at.distance_to(actor.player_pos)<400: return false
	return true

static func valid_site(g, at: Vector2, observers: Array) -> bool:
	if not hidden(at, observers) or not Flyers.fits(g.world, at): return false
	for y in range(floori(at.y/16),floori((at.y+17)/16)+1):
		for x in range(floori(at.x/16),floori((at.x+23)/16)+1):
			var cell := Vector2i(x,y)
			if g.furnishings.wall_at(cell): return false
			if g.water_sim.amount_at(cell)>0 or g.lava_sim.amount_at(cell)>0: return false
	for c: Dictionary in g.world.get("creatures", []):
		if bool(c.get("alive",false)) and at.distance_to(Vector2(float(c.x),float(c.y)))<72: return false
	return true

static func update(g, delta: float) -> void:
	if g.network_actor or (g.network != null and g.network.is_client()): return
	# Encounter planning needs two checks per second, not one per rendered frame.
	var elapsed := float(g.world.get("night_tick",0))+delta
	g.world["night_tick"] = elapsed
	if elapsed<0.5: return
	g.world["night_tick"] = 0.0
	delta=elapsed
	var observers := players(g)
	var strength := intensity(g.time_of_day)
	var creatures: Array = g.world.get("creatures", [])
	var active := 0
	var slots := 0
	var reusable := -1
	for i in range(creatures.size()):
		var c: Dictionary = creatures[i]
		if not bool(c.get("night_spawn",false)): continue
		slots += 1
		var at := Vector2(float(c.x),float(c.y))
		var nearest := INF
		for actor in observers: nearest=minf(nearest,at.distance_to(actor.player_pos))
		if bool(c.get("alive",false)):
			if (strength<=0 or nearest>2000) and hidden(at,observers):
				# Leaving at dawn is not a kill and must not create loot/corpses.
				c.alive=false; c.raised=true; c.night_retired=true; c.night_dead_age=0.0
			else: active+=1
		else:
			c.night_dead_age=float(c.get("night_dead_age",0))+delta
			if float(c.night_dead_age)>90 and hidden(at,observers): reusable=i
	if strength<=0: g.world["night_spawn_wait"]=6.0; return
	var wait := float(g.world.get("night_spawn_wait",6.0))-delta
	g.world["night_spawn_wait"]=wait
	if wait>0: return
	g.world["night_spawn_wait"]=lerpf(16.0,5.0,strength)
	if active>=MAX_ACTIVE or (slots>=MAX_SLOTS and reusable<0): return
	var rng := RandomNumberGenerator.new()
	var serial := int(g.world.get("night_spawn_serial",0))+1
	g.world["night_spawn_serial"]=serial
	rng.seed=int(g.world.seed) ^ (g.day_count*7919) ^ (serial*104729)
	var actor = observers[rng.randi_range(0,observers.size()-1)]
	var px := clampi(floori(actor.player_pos.x/16),2,WG.WIDTH-3)
	# Surface encounters must not follow the player down into deep caves.
	if actor.player_pos.y > (int(g.world.surface[px])+12)*16: return
	var nearby := 0
	for c: Dictionary in creatures:
		if bool(c.get("alive",false)) and Vector2(float(c.x),float(c.y)).distance_to(actor.player_pos)<1400: nearby+=1
	if nearby>=LOCAL_CAP: return
	for attempt in range(20):
		var x := px+rng.randi_range(46,75)*(1 if rng.randf()>0.5 else -1)
		if x<4 or x>=WG.WIDTH-5: continue
		var roof := mini(int(g.environment.roof[x]),int(g.environment.roof[x+1]))
		if roof<4 or roof>int(g.world.surface[x])+12: continue
		var flying := rng.randf()<0.35
		var at := Vector2(x*16, roof*16-(rng.randi_range(80,160) if flying else 18))
		if not valid_site(g,at,observers): continue
		if not flying and Flyers.fits(g.world,at+Vector2(0,2)): continue
		var c: Dictionary
		var climate := clampi(int(g.world.climate),0,7)
		if flying:
			c={"flying":true,"monster_family":climate,"monster_morph":rng.randi_range(0,2),"monster_phase":rng.randf()*TAU,
				"flight_phase":rng.randf()*TAU,"flight_timer":1.0,"flight_state":"roam","speed":60.0,
				"hp":24+climate*2,"max_hp":24+climate*2,"damage":6+int(climate/2)}
		elif rng.randf()<0.4:
			c=Wildlife.creature([0,1,1,2,4,2,3,3][climate],at,rng)
		else:
			c={"x":at.x,"home_x":at.x}
			Monsters.decorate(g.world,c,serial,true)
		c.merge({"x":at.x,"y":at.y,"home_x":at.x,"home_y":at.y,"direction":1 if actor.player_pos.x>at.x else -1,
			"alive":true,"night_spawn":true,"night_dead_age":0.0},true)
		preload("res://scripts/planet_danger.gd").apply(g.world,c)
		if reusable>=0: creatures[reusable]=c
		else: creatures.append(c)
		g.world["creatures"]=creatures
		return
