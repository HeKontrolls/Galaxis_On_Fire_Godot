extends RefCounted
const C=preload("res://scripts/spellcraft_catalog.gd")
const R=preload("res://scripts/ranged_weapons.gd")
var g
var minions:Array[Dictionary]=[]
var pending:Dictionary={}
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
	return minions.size()<limit() and not corpse.is_empty() and g.FlyingMonsters.fits(g.world,Vector2(float(corpse.x),float(corpse.y)-8))
func raise_dead(target:Vector2,duration:float,damage:int,style:String)->bool:
	if minions.size()>=limit():return false
	var corpse:=corpse_at(target)
	if corpse.is_empty():return false
	var at:=Vector2(float(corpse.x),float(corpse.y)-8)
	if not g.FlyingMonsters.fits(g.world,at):return false
	corpse.raised=true
	minions.append({"x":at.x,"y":at.y,"life":minf(60,duration),"damage":damage,"attack":0.0,"style":style})
	g.magic.earn("Necromancy",8);g._show_notice("A fallen creature answers your call");return true
func update(delta:float)->void:
	for i in range(minions.size()-1,-1,-1):
		var m:Dictionary=minions[i];m.life=float(m.life)-delta;m.attack=maxf(0,float(m.attack)-delta)
		if float(m.life)<=0:minions.remove_at(i);continue
		var at:=Vector2(float(m.x),float(m.y));var chosen:Dictionary={};var distance:=257.0
		for enemy:Dictionary in g.world.get("creatures",[]):
			if not bool(enemy.get("alive",false)):continue
			var end:=R.hit_box(enemy).get_center();var reach:=at.distance_to(end)
			if reach<distance and g.ranged.terrain_hit(at+Vector2(12,9),end)>1:distance=reach;chosen=enemy
		var end:Vector2=g.player_pos+Vector2(-g.facing*28,-8) if chosen.is_empty() else R.hit_box(chosen).get_center()-Vector2(12,9)
		if not chosen.is_empty() and distance<38 and float(m.attack)<=0:
			g.spellcraft.damage(chosen,int(m.damage),Vector2.ZERO,"Necromancy");m.attack=0.9
		elif at.distance_to(end)>22:
			var moved:Vector2=g.flying_monsters.move_clear(g.world,at,(end-at).limit_length(95*delta));m.x=moved.x;m.y=moved.y
		if at.distance_to(g.player_pos)>480:
			for offset:Vector2 in [Vector2(-28,-16),Vector2(28,-16),Vector2(0,-40)]:
				var recall:Vector2=g.player_pos+offset
				if g.FlyingMonsters.fits(g.world,recall):m.x=recall.x;m.y=recall.y;break
func draw()->void:
	if g.spellcraft.knows("soul"):
		for corpse:Dictionary in g.world.get("creatures",[]):
			if bool(corpse.get("alive",false)) or bool(corpse.get("raised",false)):continue
			var at:Vector2=Vector2(float(corpse.x)+12,float(corpse.y)+9)-g.camera_pos
			if not Rect2(-32,-32,1344,784).has_point(at):continue
			g.draw_texture_rect_region(g.magic.texture("bone_fragment"),Rect2(at-Vector2(7,7),Vector2(14,14)),Rect2(0,0,16,16))
			if (g.mouse_aim_screen-at).length()<28:g._button_text(Rect2(at+Vector2(-62,-25),Vector2(124,18)),"Fallen: aim Raise Dead",10,Color("c7d6b6"),true,Vector2.ZERO)
	for m:Dictionary in minions:
		var at:Vector2=Vector2(float(m.x),float(m.y))-g.camera_pos
		var style:="bone_servitor" if str(m.style)=="Tome" else ("grave_wraith" if str(m.style)=="Wand" else "bone_hound")
		var frame:=posmod(int(g.animation_clock*7),4)
		g.draw_texture_rect_region(g.magic.texture(style),Rect2(at-Vector2(3,13),Vector2(32,32)),Rect2(frame*32,0,32,32))
		g._button_text(Rect2(at+Vector2(-14,-27),Vector2(60,14)),"Ally %.0fs" % float(m.life),9,Color("b7d5af"),true,Vector2.ZERO)

func snapshot()->Dictionary:return {"world":g._world_key(),"minions":minions.duplicate(true)}
func restore(value:Variant)->void:
	pending=value.duplicate(true) if value is Dictionary else {}
func restore_pending()->void:
	if pending.is_empty():return
	if str(pending.get("world",""))==g._world_key() and pending.get("minions",[]) is Array:
		for value in pending.minions:
			if minions.size()>=limit():break
			if not value is Dictionary:continue
			var at:=Vector2(float(value.get("x",0)),float(value.get("y",0)))
			var remaining:=clampf(float(value.get("life",0)),0,60)
			if remaining<=0 or not g.FlyingMonsters.fits(g.world,at):continue
			minions.append({"x":at.x,"y":at.y,"life":remaining,"damage":clampi(int(value.get("damage",9)),1,40),"attack":clampf(float(value.get("attack",0)),0,0.9),"style":str(value.get("style","Tome")) if str(value.get("style","Tome")) in ["Wand","Staff","Tome"] else "Tome"})
	pending.clear()
