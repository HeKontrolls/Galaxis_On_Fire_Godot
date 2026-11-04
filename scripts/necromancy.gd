extends RefCounted
const C=preload("res://scripts/spellcraft_catalog.gd")
const R=preload("res://scripts/ranged_weapons.gd")
var g
var minions:Array[Dictionary]=[]
var pending:Dictionary={}
const BODY_SIZE := Vector2(32, 32)
const BODY_PADDING := 2.0

func _allies() -> Array:
	var result: Array = minions.duplicate()
	var session = g.network_owner if g.network_actor else g.network
	if session == null or session.role != "host": return result
	var contexts: Array = [session.g] + session.actors.values()
	for context in contexts:
		if context != g and context._world_key() == g._world_key(): result.append_array(context.necromancy.minions)
	return result

func _position_clear(at: Vector2, ignore: Dictionary = {}) -> bool:
	if not g.FlyingMonsters.fits(g.world, at): return false
	var body := Rect2(at - Vector2(3, 13), BODY_SIZE).grow(BODY_PADDING)
	for ally: Dictionary in _allies():
		if is_same(ally, ignore): continue
		if body.intersects(Rect2(Vector2(float(ally.x), float(ally.y)) - Vector2(3, 13), BODY_SIZE).grow(BODY_PADDING)):
			return false
	return true

func _free_near(origin: Vector2, ignore: Dictionary = {}) -> Vector2:
	if _position_clear(origin, ignore): return origin
	# Test nearby open positions in a stable order; never force a summon into a crowd.
	for radius in range(8, 129, 8):
		for direction: Vector2 in [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN,
			Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1), Vector2(1, 1)]:
			var candidate := origin + direction * radius
			if not _position_clear(candidate, ignore): continue
			if g.ranged.terrain_hit(origin + Vector2(12, 9), candidate + Vector2(12, 9)) > 1:
				return candidate
	return Vector2.INF

func _move_spaced(start: Vector2, motion: Vector2, ally: Dictionary) -> Vector2:
	var position := start
	var steps := maxi(1, ceili(motion.length() / 3.0))
	var step := motion / steps
	for _i in range(steps):
		var next := position + Vector2(step.x, 0)
		if _position_clear(next, ally): position = next
		next = position + Vector2(0, step.y)
		if _position_clear(next, ally): position = next
	return position

func _follow_position(index: int) -> Vector2:
	var side: int = -g.facing if index % 2 == 0 else g.facing
	return g.player_pos + Vector2(side * (48 + (index / 2) * 48), -8)
func bind(game)->void:g=game
func limit()->int:return 3 if g.spellcraft.knows("legion") else 1
func corpse_at(target:Vector2)->Dictionary:
	var best:Dictionary={};var score:=INF;var origin:Vector2=g.player_pos+Vector2(8,14)
	for c:Dictionary in g.world.get("creatures",[]):
		if bool(c.get("alive",false)) or bool(c.get("raised",false)):continue
		var at:=R.hit_box(c).get_center()
		if at.distance_to(origin)>192 or g.ranged.terrain_hit(origin,at)<=1:continue
		var distance:=at.distance_to(target)
		if distance<64 and distance<score:score=distance;best=c
	return best
func can_raise(target:Vector2)->bool:
	var corpse:=corpse_at(target)
	return minions.size()<limit() and not corpse.is_empty() and _free_near(Vector2(float(corpse.x),float(corpse.y)-8)).is_finite()
func raise_dead(target:Vector2,duration:float,damage:int,style:String)->bool:
	if minions.size()>=limit():return false
	var corpse:=corpse_at(target)
	if corpse.is_empty():return false
	var at := _free_near(Vector2(float(corpse.x), float(corpse.y)-8))
	if not at.is_finite():
		g._show_notice("No room for another ally here")
		return false
	corpse.raised=true
	minions.append({"x":at.x,"y":at.y,"life":minf(60,duration),"damage":damage,"attack":0.0,"style":style})
	g.magic.earn("Necromancy",8);g._show_notice("A fallen creature answers your call");return true
func update(delta:float)->void:
	for i in range(minions.size()-1,-1,-1):
		var m:Dictionary=minions[i];m.life=float(m.life)-delta;m.attack=maxf(0,float(m.attack)-delta)
		if float(m.life)<=0:minions.remove_at(i);continue
		var at:=Vector2(float(m.x),float(m.y));var chosen:Dictionary={};var distance:=257.0
		if not _position_clear(at, m):
			at = _free_near(at, m)
			if not at.is_finite(): minions.remove_at(i); continue
			m.x = at.x; m.y = at.y
		for enemy:Dictionary in g.world.get("creatures",[]):
			if not bool(enemy.get("alive",false)):continue
			var end:=R.hit_box(enemy).get_center();var reach:float=(at+Vector2(12,9)).distance_to(end)
			if reach<distance and g.ranged.terrain_hit(at+Vector2(12,9),end)>1:distance=reach;chosen=enemy
		var end: Vector2 = _follow_position(i)
		if not chosen.is_empty():
			var angle := PI + i * TAU / maxi(3, minions.size())
			end = R.hit_box(chosen).get_center() - Vector2(12, 9) + Vector2.from_angle(angle) * 32
		if not chosen.is_empty() and distance<52 and float(m.attack)<=0:
			g.spellcraft.damage(chosen,int(m.damage),Vector2.ZERO,"Necromancy");m.attack=0.9
		elif at.distance_to(end)>4:
			var motion: Vector2 = (end-at).limit_length(95*delta)
			var moved := _move_spaced(at, motion, m)
			if moved.distance_to(at) < 0.01 and absf(end.x-at.x)>4:
				# Let followers queue or go above a blocked companion instead of crossing it.
				moved = _move_spaced(at, Vector2(0,-minf(95*delta,12)), m)
			m.x=moved.x;m.y=moved.y
		if at.distance_to(g.player_pos)>480:
			var recall := _free_near(_follow_position(i), m)
			if recall.is_finite(): m.x=recall.x; m.y=recall.y
func draw()->void:
	if g.spellcraft.knows("soul"):
		for corpse:Dictionary in g.world.get("creatures",[]):
			if bool(corpse.get("alive",false)) or bool(corpse.get("raised",false)):continue
			var at:Vector2=Vector2(float(corpse.x)+12,float(corpse.y)+9)-g.camera_pos
			if not Rect2(-32,-32,1344,784).has_point(at):continue
			g.draw_texture_rect_region(g.magic.texture("bone_fragment"),Rect2(at-Vector2(7,7),Vector2(14,14)),Rect2(0,0,16,16))
			if (g.mouse_aim_screen-at).length()<28:g._button_text(Rect2(at+Vector2(-62,-25),Vector2(124,18)),"Fallen: aim Raise Dead",10,Color("c7d6b6"),true,Vector2.ZERO)
	var labels: Array[Rect2] = []
	for m:Dictionary in minions:
		var at:Vector2=Vector2(float(m.x),float(m.y))-g.camera_pos
		var style:="bone_servitor" if str(m.style)=="Tome" else ("grave_wraith" if str(m.style)=="Wand" else "bone_hound")
		var frame:=posmod(int(g.animation_clock*7),4)
		g.draw_texture_rect_region(g.magic.texture(style),Rect2(at-Vector2(3,13),Vector2(32,32)),Rect2(frame*32,0,32,32))
		var label := Rect2(at+Vector2(-14,-27),Vector2(60,14))
		while labels.any(func(other: Rect2): return other.intersects(label)):
			label.position.y -= 15
		labels.append(label)
		g._button_text(label,"Ally %.0fs" % float(m.life),9,Color("b7d5af"),true,Vector2.ZERO)

func snapshot()->Dictionary:return {"world":g._world_key(),"minions":minions.duplicate(true)}
func restore(value:Variant)->void:
	pending=value.duplicate(true) if value is Dictionary else {}
func restore_pending()->void:
	if pending.is_empty():return
	if str(pending.get("world",""))==g._world_key() and pending.get("minions",[]) is Array:
		for value in pending.minions:
			if minions.size()>=limit():break
			if not value is Dictionary:continue
			var at := _free_near(Vector2(float(value.get("x",0)),float(value.get("y",0))))
			var remaining:=clampf(float(value.get("life",0)),0,60)
			if remaining<=0 or not at.is_finite():continue
			minions.append({"x":at.x,"y":at.y,"life":remaining,"damage":clampi(int(value.get("damage",9)),1,40),"attack":clampf(float(value.get("attack",0)),0,0.9),"style":str(value.get("style","Tome")) if str(value.get("style","Tome")) in ["Wand","Staff","Tome"] else "Tome"})
	pending.clear()
