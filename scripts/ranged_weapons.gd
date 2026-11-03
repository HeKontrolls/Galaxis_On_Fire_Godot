extends RefCounted

const WG = preload("res://scripts/world_gen.gd")
const Art = preload("res://scripts/sprite_art.gd")
const WEAPONS := {
	"Wood Bow": {"damage":14,"speed":640.0,"draw":0.70,"cooldown":0.24,"row":0},
	"Copper Bow": {"damage":20,"speed":720.0,"draw":0.65,"cooldown":0.24,"row":1},
	"Iron Bow": {"damage":28,"speed":800.0,"draw":0.60,"cooldown":0.24,"row":2},
	"Iron Crossbow": {"damage":36,"speed":960.0,"draw":0.0,"cooldown":1.10,"row":3}}
const AMMO := {
	"Stone Arrow": {"bonus":0,"hits":1,"row":0},
	"Copper Arrow": {"bonus":3,"hits":1,"row":1},
	"Iron Arrow": {"bonus":6,"hits":1,"row":2},
	"Crystal Arrow": {"bonus":9,"hits":2,"row":3}}
const ITEMS := ["Wood Bow","Copper Bow","Iron Bow","Iron Crossbow","Stone Arrow","Copper Arrow","Iron Arrow","Crystal Arrow"]
const FIXED_STEP := 1.0 / 120.0
const MAX_ARROWS := 64
var g
var projectiles: Array[Dictionary] = []
var selected_ammo := "Stone Arrow"
var charging := false
var drawn_weapon := ""
var draw_time := 0.0
var recoil := 0.0
var budget := 0.0
var textures := {}

static func has_weapon(item: String) -> bool: return WEAPONS.has(item)
static func has_item(item: String) -> bool: return has_weapon(item) or AMMO.has(item)
static func summary(item: String) -> String:
	if WEAPONS.has(item):
		var spec:Dictionary=WEAPONS[item]
		return "%d base damage | %s" % [spec.damage,"Click to fire; 1.1s reload" if float(spec.draw)==0 else "Hold to draw; release to fire"]
	if AMMO.has(item):
		return "+%d damage | %s" % [AMMO[item].bonus,"Pierces two enemies" if int(AMMO[item].hits)==2 else "Recover misses from terrain"]
	return ""
static func icon(item: String) -> Texture2D:
	var result:=AtlasTexture.new()
	if WEAPONS.has(item):
		result.atlas=Art.texture("res://assets/sprites/weapons/bows.png")
		result.region=Rect2(0,int(WEAPONS[item].row)*40,32,40)
	else:
		result.atlas=Art.texture("res://assets/sprites/weapons/arrow_icons.png")
		result.region=Rect2(0,int(AMMO.get(item,AMMO["Stone Arrow"]).row)*32,32,32)
	return result
func texture(item: String) -> Texture2D:
	if not textures.has(item): textures[item]=icon(item)
	return textures[item]
func bind(game) -> void: g=game
func reset() -> void:
	projectiles.clear();cancel();recoil=0;budget=0
func cancel() -> void:
	charging=false;draw_time=0;drawn_weapon=""
func allowed() -> bool:
	return g!=null and g.scene_name=="planet" and not g.paused and not g.dev_mode and not g.inventory_open and not g.crafting_open and not g.dialogue_open and not g.stations.is_open()
func ammo() -> String:
	if AMMO.has(selected_ammo) and int(g.inventory.get(selected_ammo,0))>0: return selected_ammo
	for item:String in AMMO:
		if int(g.inventory.get(item,0))>0:return item
	return ""
func cycle_ammo() -> void:
	cancel()
	var available:Array[String]=[]
	for item:String in AMMO:
		if int(g.inventory.get(item,0))>0: available.append(item)
	if available.is_empty():g._show_notice("No arrows - craft Stone Arrows from sticks and stone");return
	selected_ammo=available[posmod(available.find(ammo())+1,available.size())]
	g._show_notice("Ammunition: %s x%d" % [selected_ammo,g.inventory[selected_ammo]])
func begin(target: Vector2) -> bool:
	if not allowed() or not WEAPONS.has(g.equipped_tool) or g.attack_cooldown>0 or int(g.inventory.get(g.equipped_tool,0))<=0:return false
	g._set_mouse_world_target(target)
	if charging:return true
	if ammo().is_empty():
		g._show_notice("No arrows - craft Stone Arrows from sticks and stone");g.attack_cooldown=0.25;return false
	if projectiles.size()>=MAX_ARROWS:return false
	if float(WEAPONS[g.equipped_tool].draw)==0:return fire(1.0)
	charging=true;drawn_weapon=g.equipped_tool;draw_time=0
	return true
func charge() -> float:
	return clampf(draw_time/maxf(0.01,float(WEAPONS.get(drawn_weapon,WEAPONS["Wood Bow"]).draw)),0,1) if charging else 0.0
func release() -> bool:
	if not charging:return false
	var power:=charge()
	var valid:bool=drawn_weapon==g.equipped_tool
	cancel()
	if not valid:return false
	return fire(power)
func fire(power: float) -> bool:
	if not allowed() or not WEAPONS.has(g.equipped_tool) or g.attack_cooldown>0 or int(g.inventory.get(g.equipped_tool,0))<=0 or g._world_input_blocked(g.aim_screen):return false
	var arrow:=ammo()
	if arrow.is_empty() or projectiles.size()>=MAX_ARROWS:return false
	var spec:Dictionary=WEAPONS[g.equipped_tool]
	var aim:Vector2=g.mouse_aim_direction.normalized() if g.mouse_aim_valid else Vector2(g.facing,0)
	var origin:Vector2=g.PlayerPose.shoulder(g.player_pos,g.facing)
	var muzzle:=origin+aim*(36 if g.equipped_tool=="Iron Crossbow" else 28)
	# A bow next to a wall must not spawn an arrow on its far side.
	var obstruction:=terrain_hit(origin,muzzle)
	if obstruction<=1:muzzle=origin.lerp(muzzle,maxf(0,obstruction-0.001))
	g.inventory[arrow]=int(g.inventory[arrow])-1
	var strength:=lerpf(0.45,1.0,clampf(power,0,1))
	projectiles.append({"pos":muzzle,"vel":aim*float(spec.speed)*lerpf(0.48,1.0,power),"ammo":arrow,"damage":maxi(1,roundi(float(spec.damage)*strength)+int(AMMO[arrow].bonus)),"left":int(AMMO[arrow].hits),"hit":[],"life":5.0})
	g.attack_cooldown=float(spec.cooldown);recoil=0.16
	if g.sound!=null:g.sound.bow_shot(origin,g.equipped_tool=="Iron Crossbow")
	return true
func update(delta: float) -> void:
	if charging:
		if not allowed() or g.equipped_tool!=drawn_weapon or int(g.inventory.get(drawn_weapon,0))<=0:cancel()
		else:draw_time=minf(draw_time+delta,1.0)
	recoil=maxf(0,recoil-delta)
	budget+=minf(maxf(0,delta),0.5)
	while budget+0.000001>=FIXED_STEP:
		budget-=FIXED_STEP
		for i in range(projectiles.size()-1,-1,-1):
			if not step(projectiles[i],FIXED_STEP):projectiles.remove_at(i)

# Slab intersection returns entry fraction; INF means the segment misses.
static func segment_hit(start: Vector2,finish: Vector2,box: Rect2) -> float:
	var delta:=finish-start;var low:=0.0;var high:=1.0
	for axis in range(2):
		if absf(delta[axis])<0.000001:
			if start[axis]<box.position[axis] or start[axis]>box.end[axis]:return INF
		else:
			var a:float=(box.position[axis]-start[axis])/delta[axis]
			var b:float=(box.end[axis]-start[axis])/delta[axis]
			low=maxf(low,minf(a,b));high=minf(high,maxf(a,b))
			if low>high:return INF
	return low
func terrain_hit(start: Vector2,finish: Vector2) -> float:
	var delta:=finish-start;var cell:=Vector2i(floor(start/16))
	var move:=Vector2i(signf(delta.x),signf(delta.y))
	var stride:=Vector2(INF if move.x==0 else 16/absf(delta.x),INF if move.y==0 else 16/absf(delta.y))
	var next:=Vector2(INF,INF)
	if move.x!=0:next.x=((cell.x+(1 if move.x>0 else 0))*16-start.x)/delta.x
	if move.y!=0:next.y=((cell.y+(1 if move.y>0 else 0))*16-start.y)/delta.y
	var entered:=0.0
	for _cell in range(128):
		if cell.x<0 or cell.x>=WG.WIDTH or cell.y<0 or cell.y>=WG.HEIGHT:return entered
		if WG.is_solid(WG.tile_at(g.world.tiles,cell.x,cell.y)):return entered
		if next.x<next.y:entered=next.x;next.x+=stride.x;cell.x+=move.x
		else:entered=next.y;next.y+=stride.y;cell.y+=move.y
		if entered>1:break
	return INF
static func hit_box(creature: Dictionary) -> Rect2:
	var at:=Vector2(float(creature.x),float(creature.y))
	if bool(creature.get("flying",false)) or creature.has("flight_state"):
		return Rect2(at+Vector2(-10,-10),Vector2(44,30))
	if bool(creature.get("quest_guardian",false)):
		return Rect2(at+Vector2(-8,-20),Vector2(40,38))
	return Rect2(at+Vector2(-4,-12),Vector2(32,30))
func step(arrow: Dictionary,dt: float) -> bool:
	arrow.life=float(arrow.life)-dt
	if float(arrow.life)<=0:return false
	var start:Vector2=arrow.pos;var velocity:Vector2=arrow.vel
	if g.lava_sim.submerged(start):return false
	if g.water_sim.submerged(start):velocity*=exp(-4.0*dt)
	var acceleration:=Vector2(clampf(g._wind_speed()*0.08,-20,20),300)
	var finish:=start+velocity*dt+acceleration*(0.5*dt*dt)
	arrow.vel=velocity+acceleration*dt
	var wall:=terrain_hit(start,finish)
	var hits:Array[Dictionary]=[]
	var creatures:Array=g.world.get("creatures",[])
	for i in range(creatures.size()):
		var c:Dictionary=creatures[i]
		if not bool(c.get("alive",false)) or i in arrow.hit:continue
		var t:=segment_hit(start,finish,hit_box(c))
		if t<=1 and t<wall:hits.append({"t":t,"index":i})
	hits.sort_custom(func(a: Dictionary,b: Dictionary)->bool:return float(a.t)<float(b.t))
	for impact:Dictionary in hits:
		var c:Dictionary=creatures[int(impact.index)]
		arrow.hit.append(int(impact.index));hit_creature(c,int(arrow.damage),velocity)
		arrow.left=int(arrow.left)-1
		if int(arrow.left)<=0:return false
	if wall<=1:
		var at:=start.lerp(finish,wall)-velocity.normalized()*3
		# Crystal tips shatter; ordinary missed arrows can be picked up again.
		if str(arrow.ammo)!="Crystal Arrow":g._drop_item(str(arrow.ammo),1,Vector2i(floor(at/16)))
		if g.sound!=null:g.sound.impact(3,at)
		return false
	arrow.pos=finish
	return true
func hit_creature(c: Dictionary,damage: int,velocity: Vector2) -> void:
	c.hp=int(c.hp)-damage;c.hit_flash=0.20
	var pushed:=Vector2(float(c.x)+signf(velocity.x)*9,float(c.y))
	if g.FlyingMonsters.fits(g.world,pushed):c.x=pushed.x
	if int(c.hp)<=0:
		c.alive=false
		g._drop_item(g.WildlifeMobs.loot(c) if bool(c.get("wildlife",false)) else "Alien Fiber",1,Vector2i(floor(Vector2(float(c.x),float(c.y))/16)))
		g._show_notice("Creature defeated")
	else:g._show_notice("Arrow hit: %d damage" % damage)
func pose(screen_pos: Vector2) -> Transform2D:
	var aim:Vector2=g.mouse_aim_direction.normalized() if g.mouse_aim_valid else Vector2(g.facing,0)
	var hand:Vector2=g.PlayerPose.shoulder(screen_pos,g.facing)+aim*(16.0-3.0*recoil/0.16)
	return Transform2D(aim.angle(),hand)
func draw_held(screen_pos: Vector2) -> void:
	var item:String=g.equipped_tool;var spec:Dictionary=WEAPONS[item]
	var frame:=mini(2,floori(charge()*2.99)) if charging else 0
	if float(spec.draw)==0 and g.attack_cooldown>0:frame=1 if g.attack_cooldown>0.65 else 2
	var held:=pose(screen_pos)
	g.draw_set_transform_matrix(held)
	g.draw_texture_rect_region(sheet("bows"),Rect2(-19,-20,32,40),Rect2(frame*32,int(spec.row)*40,32,40))
	var current:=ammo()
	if not current.is_empty() and ((charging and charge()>0.05) or (float(spec.draw)==0 and g.attack_cooldown<=0)):
		g.draw_texture_rect_region(sheet("arrows"),Rect2(-11-charge()*8,-6,32,12),Rect2(0,int(AMMO[current].row)*12,32,12))
	g.draw_set_transform_matrix(Transform2D.IDENTITY)
	g._draw_player_arm(screen_pos,held.origin)
	if charging:
		g.draw_rect(Rect2(screen_pos+Vector2(-8,-12),Vector2(32,3)),Color("3e4044"))
		g.draw_rect(Rect2(screen_pos+Vector2(-8,-12),Vector2(32*charge(),3)),Color("ead28c") if charge()>=1 else Color("95c9ac"))
func sheet(name: String) -> Texture2D:
	if not textures.has(name):textures[name]=Art.texture("res://assets/sprites/weapons/"+name+".png")
	return textures[name]
func draw() -> void:
	for arrow:Dictionary in projectiles:
		var at:Vector2=arrow.pos-g.camera_pos
		g.draw_set_transform(at,Vector2(arrow.vel).angle())
		g.draw_texture_rect_region(sheet("arrows"),Rect2(-29,-6,32,12),Rect2(0,int(AMMO[str(arrow.ammo)].row)*12,32,12))
		g.draw_set_transform_matrix(Transform2D.IDENTITY)
