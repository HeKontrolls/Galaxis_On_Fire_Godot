extends RefCounted
const C=preload("res://scripts/spellcraft_catalog.gd")
const R=preload("res://scripts/ranged_weapons.gd")
var g
var learned:Array[String]=[]
var spells:Dictionary={}
var next_id:=1
var regen_time:=0.0
var regen_rate:=0
var regen_tick:=0.0
var codex_tab:=0
var codex_page:=0
var ui
func bind(game)->void:
	g=game;ui=load("res://scripts/spellcraft_ui.gd").new(game)
func reset()->void:
	learned.clear();spells.clear();next_id=1;regen_time=0;regen_tick=0;regen_rate=0;codex_tab=0;codex_page=0
func knows(node:String)->bool:return node in learned
func total_points()->int:
	var total:=3
	for school:String in g.MagicCatalog.SCHOOLS:total+=g.magic.rank(school)-1
	return total
func points()->int:return maxi(0,total_points()-learned.size())
func can_learn(node:String)->bool:
	if not C.NODES.has(node) or knows(node) or points()<=0:return false
	var spec:Dictionary=C.NODES[node]
	if g.magic.rank(str(spec.school))<int(spec.rank):return false
	for parent:String in spec.needs:
		if not knows(parent):return false
	return true
func learn(node:String)->bool:
	if not can_learn(node):g._show_notice("Needs a skill point, school rank and connected prerequisites");return false
	learned.append(node);g._show_notice("Learned "+str(C.NODES[node].name));return true
func effects()->Array[String]:
	var result:Array[String]=[]
	for name:String in C.EFFECTS:
		if knows(str(C.EFFECTS[name].node)):result.append(name)
	return result
func forms()->Array[String]:
	var result:Array[String]=["Bolt","Self"]
	if knows("burst"):result.append("Burst")
	if knows("chain"):result.append("Chain")
	return result
func validate(draft:Dictionary)->String:
	if str(draft.get("focus","")) not in ["Wand","Staff","Tome"]:return "Choose a wand, staff or tome"
	var first:=str(draft.get("first",""));var second:=str(draft.get("second","None"));var form:=str(draft.get("form",""))
	if first not in effects():return "Learn the primary effect in the skill tree (K)"
	if second!="None" and (not knows("dual") or second not in effects()):return "Learn Dual weaving and the second effect"
	if first==second:return "Choose two different effects"
	if form not in forms():return "Learn this delivery form in the skill tree"
	if not C.offensive(first) and not C.offensive(second) and form!="Self":return "Support-only spells use Self delivery"
	for setting in ["power","duration","area"]:
		var value:=int(draft.get(setting,1))
		if value<1 or value>3:return "Tuning must stay between 1 and 3"
	var limit:=mini(3,g.magic.rank(str(C.EFFECTS[first].school)))
	if int(draft.get("power",1))>limit:return "Higher strength needs school rank "+str(draft.power)
	return ""
func needs(draft:Dictionary)->Dictionary:
	var result:={"Blank "+str(draft.get("focus","Wand")):1,"Arcane Ink":1}
	for effect in [str(draft.get("first","")),str(draft.get("second","None"))]:
		if not C.EFFECTS.has(effect):continue
		var reagent:=str(C.EFFECTS[effect].essence);result[reagent]=int(result.get(reagent,0))+int(draft.get("power",1))
		if effect=="Raise Dead":result["Bone Fragment"]=2
	return result
func compile(draft:Dictionary)->Dictionary:
	var result:=draft.duplicate(true);var effects_list:Array[String]=[str(result.first)]
	if str(result.get("second","None"))!="None":effects_list.append(str(result.second))
	result.effects=effects_list;result.school=C.EFFECTS[str(result.first)].school
	var timed:=false
	for effect:String in effects_list:
		if C.timed_effect(effect):timed=true
	if not timed:result.duration=1
	if str(result.form) not in ["Burst","Chain"]:result.area=1
	var mana:=0.0
	for name:String in effects_list:mana+=float(C.EFFECTS[name].mana)
	mana*=(1+(int(result.power)-1)*0.4)*(1+(int(result.duration)-1)*0.2)
	if str(result.form) in ["Burst","Chain"]:mana*=1.3+(int(result.area)-1)*0.2
	if knows("renewal") and ("Mending" in effects_list or "Regeneration" in effects_list):mana*=0.8
	result.mana=clampf(ceilf(mana),4,190);result.cooldown=0.6+int(result.power)*0.2
	if "Ward" in effects_list or "Regeneration" in effects_list:result.cooldown=maxf(5,result.cooldown)
	if "Raise Dead" in effects_list:result.cooldown=maxf(8,result.cooldown)
	if str(result.form) in ["Burst","Chain"]:result.cooldown+=0.5
	return result
func inscribe(draft:Dictionary,inputs:Array,output:Dictionary)->String:
	var error:=validate(draft)
	if not error.is_empty():g._show_notice(error);return ""
	if spells.size()>=64 or output.size()>=4:g._show_notice("Take an output spell; the character library holds 64 designs");return ""
	var cost:=needs(draft)
	if not g.stations.Slots.ready(inputs,cost):g._show_notice("Place the blank focus, ink and essences into this desk");return ""
	var name:=str(draft.get("name","New Spell")).strip_edges().left(32)
	if name.is_empty():name="Unnamed Spell"
	var item:="%s #%d: %s" % [draft.focus,next_id,name];next_id+=1
	var record:=draft.duplicate(true);record.name=name
	spells[item]=record;g.stations.Slots.consume(inputs,cost);output[item]=1
	g.magic.earn(str(C.EFFECTS[str(draft.first)].school),4);g._show_notice("Inscribed "+name);return item
func resolve(item:String)->Dictionary:
	if spells.has(item):return compile(spells[item])
	if item=="Soul Wand":return compile({"name":"Soul Drain","focus":"Wand","form":"Bolt","first":"Drain","second":"None","power":1,"duration":1,"area":1})
	if item=="Grave Tome":return compile({"name":"Grave Calling","focus":"Tome","form":"Self","first":"Raise Dead","second":"None","power":1,"duration":1,"area":1})
	return {}
func summary(item:String)->String:
	var record:=resolve(item)
	return "Missing spell design" if record.is_empty() else "%s | %s | %.0f MP | %.1fs" % [record.form," + ".join(record.effects),record.mana,record.cooldown]
func snapshot()->Dictionary:return {"learned":learned.duplicate(),"spells":spells.duplicate(true),"next_id":next_id,"regen_time":regen_time,"regen_rate":regen_rate,"regen_tick":regen_tick}
func restore(value:Variant)->void:
	reset()
	if not value is Dictionary:return
	var pending:Array=value.get("learned",[]) if value.get("learned",[]) is Array else []
	for _pass in range(4):
		for node in pending:
			if node is String and can_learn(node):learned.append(node)
	var library:Variant=value.get("spells",{})
	if library is Dictionary:
		for item in library:
			if spells.size()>=64:break
			if item is String and C.is_spell(item) and library[item] is Dictionary and validate(library[item]).is_empty():spells[item]=library[item].duplicate(true)
	next_id=clampi(int(value.get("next_id",1)),1,1000000)
	for item:String in spells:next_id=maxi(next_id,int(item.get_slice("#",1).get_slice(":",0))+1)
	regen_time=clampf(float(value.get("regen_time",0)),0,60);regen_rate=clampi(int(value.get("regen_rate",0)),0,10);regen_tick=clampf(float(value.get("regen_tick",0)),0,1)
func damage(c:Dictionary,amount:int,velocity:Vector2,school:String)->int:
	if not bool(c.get("alive",false)):return 0
	var actual:=mini(int(c.hp),amount);g.ranged.hit_creature(c,amount,velocity);g.magic.earn(school,minf(10,actual/4.0));return actual
func dead_loot(c:Dictionary)->void:
	if knows("soul") and not bool(c.get("bone_loot",false)):
		c.bone_loot=true;g._drop_item("Bone Fragment",1,Vector2i(floor(Vector2(float(c.x),float(c.y))/16)))
func apply_hit(record:Dictionary,c:Dictionary,velocity:Vector2)->void:
	for effect:String in record.effects:
		if not C.offensive(effect) or not bool(c.get("alive",false)):continue
		var school:=str(C.EFFECTS[effect].school);var power:float=(1+(int(record.power)-1)*0.5)*g.magic.scale_for(school)
		var dealt:=damage(c,roundi(float(C.EFFECTS[effect].damage)*power),velocity,school)
		var duration:float=1+(int(record.duration)-1)*0.5
		if effect=="Ember":c.magic_burn=3*duration;c.magic_burn_tick=0
		elif effect=="Frost":c.magic_slow=3*duration
		elif effect=="Drain":
			var heal:=mini(100-g.health,roundi(dealt*0.35));g.health+=heal
		elif effect=="Blight":c.magic_rot=5*duration;c.magic_rot_damage=roundi(4*power);c.magic_rot_tick=0.0
func support(record:Dictionary,target:Vector2)->void:
	var duration:float=1+(int(record.duration)-1)*0.5
	for effect:String in record.effects:
		var spec:Dictionary=C.EFFECTS[effect];var power:float=(1+(int(record.power)-1)*0.5)*g.magic.scale_for(str(spec.school))
		if effect=="Mending":
			var healed:=mini(100-g.health,roundi(18*power*(1.15 if knows("vitality") else 1.0)));g.health+=healed;g.magic.earn("Restoration",healed/3.0)
		elif effect=="Regeneration":regen_time=10*duration;regen_rate=roundi(2*power*(1.15 if knows("vitality") else 1.0));regen_tick=0
		elif effect=="Ward":g.magic.ward=32*power*(1.15 if knows("aegis") else 1.0)*(1.25 if knows("bulwark") else 1.0);g.magic.ward_time=8*duration*(1.2 if knows("wardweave") else 1.0)
		elif effect=="Light":
			var fresh:bool=g.magic.lumen<=0;g.magic.lumen=45*duration*power
			if fresh:g.magic.earn("Illumination",8)
		elif effect=="Raise Dead":g.necromancy.raise_dead(target,25*duration,roundi(9*power),str(record.focus))
func cast_spell(item:String,target:Vector2)->bool:
	if not g.magic.allowed() or g.attack_cooldown>0 or int(g.inventory.get(item,0))<=0 or g._world_input_blocked(target-g.camera_pos):return false
	var record:=resolve(item)
	if record.is_empty():g._show_notice("This focus has no saved design");return false
	var error:=validate(record)
	if not error.is_empty():g._show_notice(error);return false
	if float(g.magic.cooldowns.get(item,0))>0:return false
	if float(g.magic.mana)<float(record.mana):g._show_notice("This spell needs %.0f mana" % record.mana);return false
	if "Raise Dead" in record.effects and not g.necromancy.can_raise(target):g._show_notice("Aim at an unraised fallen creature nearby; summon limit %d" % g.necromancy.limit());return false
	var hostile:=false
	for effect:String in record.effects:
		if C.offensive(effect):hostile=true
	if not hostile and record.effects.size()==1:
		if str(record.first)=="Mending" and g.health>=100:return false
		if str(record.first)=="Light" and g.magic.lumen>10:return false
		if str(record.first)=="Regeneration" and regen_time>2:return false
	var origin:Vector2=g.PlayerPose.shoulder(g.player_pos,g.facing)
	var targets:Array=[]
	if record.form=="Chain":
		targets=g.magic.chain_targets(origin,target,1+int(record.area),80+int(record.area)*16)
		if targets.is_empty():return false
	elif record.form=="Burst" and (origin.distance_to(target)>256 or g.ranged.terrain_hit(origin,target)<=1):return false
	if record.form=="Bolt" and hostile and g.magic.projectiles.size()>=g.magic.MAX_PROJECTILES:return false
	g._set_mouse_world_target(target);g.magic.mana-=float(record.mana);g.magic.regen_wait=2;g.magic.cooldowns[item]=float(record.cooldown);g.magic.flash=0.24;g.attack_cooldown=0.25
	support(record,target)
	if record.form=="Bolt" and hostile:
		var aim:Vector2=g.mouse_aim_direction;var end:=origin+aim*26;var obstruction:float=g.ranged.terrain_hit(origin,end)
		if obstruction<=1:end=origin.lerp(end,maxf(0,obstruction-0.001))
		var kind:="soul" if str(record.first) in ["Drain","Raise Dead"] else ("blight" if record.first=="Blight" else ("frost" if record.first=="Frost" else ("ember" if record.first=="Ember" else "crystal")))
		g.magic.projectiles.append({"pos":end,"vel":aim*620,"kind":kind,"left":2 if "Crystal" in record.effects else 1,"hit":[],"life":2.5,"crafted":record.duplicate(true)})
	elif record.form=="Chain":
		var start:=origin
		for c:Dictionary in targets:
			var end:=R.hit_box(c).get_center();g.magic.arcs.append({"a":start,"b":end,"life":0.25});apply_hit(record,c,end-start);start=end
	elif hostile:
		var center:=target if record.form=="Burst" else origin;var radius:=32+int(record.area)*24
		for c:Dictionary in g.world.get("creatures",[]):
			var at:=R.hit_box(c).get_center()
			if bool(c.get("alive",false)) and at.distance_to(center)<=radius and g.ranged.terrain_hit(center,at)>1:apply_hit(record,c,at-center)
		g.magic.arcs.append({"a":center-Vector2(radius,0),"b":center+Vector2(radius,0),"life":0.2})
	g.environment.invalidate();return true
func tick(delta:float)->void:
	var used:=minf(delta,regen_time);regen_time=maxf(0,regen_time-delta);regen_tick+=used
	while regen_tick+0.000001>=1:
		regen_tick=maxf(0,regen_tick-1);var restored:=mini(100-g.health,regen_rate);g.health+=restored
		if restored>0:g.magic.earn("Restoration",restored/3.0)
	g.necromancy.update(delta)
func tick_status(c:Dictionary,delta:float)->void:
	var used:=minf(delta,float(c.get("magic_rot",0)));c.magic_rot=maxf(0,float(c.get("magic_rot",0))-delta)
	if used<=0:return
	c.magic_rot_tick=float(c.get("magic_rot_tick",0))+used
	while float(c.magic_rot_tick)+0.000001>=1 and bool(c.get("alive",false)):
		c.magic_rot_tick=float(c.magic_rot_tick)-1;g.magic.hit(c,int(c.get("magic_rot_damage",4)),Vector2.ZERO,false)
