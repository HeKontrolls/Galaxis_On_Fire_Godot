extends RefCounted
const C=preload("res://scripts/magic_catalog.gd")
const Ranged=preload("res://scripts/ranged_weapons.gd")
const STEP:=1.0/120.0
const MAX_PROJECTILES:=48
var g
var mana:=100.0
var xp:Dictionary={}
var cooldowns:Dictionary={}
var regen_wait:=0.0
var ward:=0.0
var ward_time:=0.0
var lumen:=0.0
var flash:=0.0
var budget:=0.0
var projectiles:Array[Dictionary]=[]
var arcs:Array[Dictionary]=[]
var textures:Dictionary={}
var codex_open:=false
const CODEX_SIZE:=Vector2(760,520)
func bind(game)->void:g=game
func rank(school:String)->int:
	var result:=1
	for value in C.THRESHOLDS.slice(1):
		if float(xp.get(school,0))>=float(value):result+=1
	return result
func scale_for(school:String)->float:return 1.0+(rank(school)-1)*0.08
func max_mana()->float:
	var result:=100.0
	for school:String in C.SCHOOLS:result+=(rank(school)-1)*5
	return result
func earn(school:String,amount:float)->void:
	var before:=rank(school);xp[school]=minf(300,float(xp.get(school,0))+maxf(0,amount))
	if rank(school)>before:g._show_notice("%s mastery %d!" % [school,rank(school)])
func clear_world()->void:
	projectiles.clear();arcs.clear();budget=0;codex_open=false
	if g!=null:g.necromancy.minions.clear()
func new_character()->void:
	clear_world();mana=100;xp.clear();cooldowns.clear();regen_wait=0;ward=0;ward_time=0;lumen=0;flash=0
	if g!=null:g.spellcraft.reset();g.necromancy.pending.clear()
func respawn()->void:
	clear_world();ward=0;ward_time=0;mana=max_mana();regen_wait=0
func snapshot()->Dictionary:return {"mana":mana,"xp":xp.duplicate(),"cooldowns":cooldowns.duplicate(),"regen_wait":regen_wait,"ward":ward,"ward_time":ward_time,"lumen":lumen,"spellcraft":g.spellcraft.snapshot(),"necromancy":g.necromancy.snapshot()}
func restore(value:Variant)->void:
	new_character()
	if not value is Dictionary:return
	if value.has("xp") and value.get("xp",{}) is Dictionary:
		for school:String in C.SCHOOLS:xp[school]=clampf(float(value.get("xp",{}).get(school,0)),0,300)
	g.spellcraft.restore(value.get("spellcraft",{}))
	g.necromancy.restore(value.get("necromancy",{}))
	mana=clampf(float(value.get("mana",max_mana())),0,max_mana());regen_wait=clampf(float(value.get("regen_wait",0)),0,2)
	ward=clampf(float(value.get("ward",0)),0,400);ward_time=clampf(float(value.get("ward_time",0)),0,60);lumen=clampf(float(value.get("lumen",0)),0,180)
	if ward_time<=0:ward=0
	if value.has("cooldowns") and value.get("cooldowns",{}) is Dictionary:
		for item:String in C.ITEMS+g.spellcraft.spells.keys():cooldowns[item]=clampf(float(value.get("cooldowns",{}).get(item,0)),0,60)
func allowed()->bool:return g!=null and g.scene_name=="planet" and not g.paused and not g.dev_mode and not g.inventory_open and not g.crafting_open and not g.dialogue_open and not g.stations.is_open()
func drink()->bool:
	if not allowed() or int(g.inventory.get("Mana Tonic",0))<=0 or mana>=max_mana() or float(cooldowns.get("Mana Tonic",0))>0:return false
	g.inventory["Mana Tonic"]-=1;mana=minf(max_mana(),mana+50);cooldowns["Mana Tonic"]=8.0;g._show_notice("Mana restored +50");return true
func cast(target:Vector2)->bool:
	var item:String=g.equipped_tool
	if C.Craft.is_spell(item) or item in ["Soul Wand","Grave Tome"]:return g.spellcraft.cast_spell(item,target)
	if not allowed() or not C.has_focus(item) or int(g.inventory.get(item,0))<=0 or g.attack_cooldown>0 or g._world_input_blocked(target-g.camera_pos):return false
	var spec:Dictionary=C.SPELLS[item]
	if float(cooldowns.get(item,0))>0:return false
	if mana+0.00001<float(spec.mana):g._show_notice("Not enough mana: need %.0f MP" % spec.mana);return false
	if spec.kind=="mend" and g.health>=100:return false
	var strength:=scale_for(str(spec.school))
	if spec.kind=="ward" and ward_time>0 and ward>=float(spec.shield)*strength:return false
	if spec.kind=="lumen" and lumen>10:return false
	if spec.has("speed") and projectiles.size()>=MAX_PROJECTILES:return false
	g._set_mouse_world_target(target)
	var aim:Vector2=g.mouse_aim_direction if g.mouse_aim_valid else Vector2(g.facing,0)
	var origin:Vector2=g.PlayerPose.shoulder(g.player_pos,g.facing)
	var chain:Array=chain_targets(origin,target) if spec.kind=="storm" else []
	if spec.kind=="storm" and chain.is_empty():g._show_notice("Aim lightning at a visible creature within 16 blocks");return false
	mana-=float(spec.mana);regen_wait=2.0;cooldowns[item]=float(spec.cooldown);g.attack_cooldown=0.25;flash=0.24
	if spec.has("speed"):
		var muzzle:=origin+aim*26;var obstruction:float=g.ranged.terrain_hit(origin,muzzle)
		if obstruction<=1:muzzle=origin.lerp(muzzle,maxf(0,obstruction-0.001))
		projectiles.append({"pos":muzzle,"vel":aim*float(spec.speed),"damage":roundi(float(spec.damage)*strength),"kind":spec.kind,"left":spec.hits,"hit":[],"life":2.5})
	elif spec.kind=="storm":
		var start:=origin;var damage:=float(spec.damage)*strength
		for c:Dictionary in chain:
			var end:=Ranged.hit_box(c).get_center();arcs.append({"a":start,"b":end,"life":0.22});hit(c,roundi(damage),end-start);damage*=0.75;start=end
	elif spec.kind=="mend":
		var healed:=mini(100-g.health,roundi(float(spec.heal)*strength));g.health+=healed;earn("Restoration",healed/3.0);g._show_notice("Mending: +%d HP" % healed)
	elif spec.kind=="ward":ward=float(spec.shield)*strength;ward_time=float(spec.duration);g._show_notice("Ward raised: %.0f protection" % ward)
	elif spec.kind=="lumen":
		var new_light:=lumen<=0;lumen=float(spec.duration)*strength
		if new_light:earn("Illumination",8)
		g.environment.invalidate();g._show_notice("Lumen: cave light for 60 seconds")
	return true
func chain_targets(origin:Vector2,target:Vector2,max_targets:=3,jump_range:=112.0)->Array:
	var result:Array=[];var start:=origin
	for bounce in range(max_targets):
		var best:Dictionary={};var score:=INF
		for c:Dictionary in g.world.get("creatures",[]):
			if not bool(c.get("alive",false)) or c in result:continue
			var at:=Ranged.hit_box(c).get_center()
			if start.distance_to(at)>(256 if bounce==0 else jump_range) or g.ranged.terrain_hit(start,at)<=1:continue
			var distance:=at.distance_to(target) if bounce==0 else at.distance_to(start)
			if bounce==0 and distance>56:continue
			if distance<score:score=distance;best=c
		if best.is_empty():break
		result.append(best);start=Ranged.hit_box(best).get_center()
	return result
func hit(c:Dictionary,damage:int,velocity:Vector2,credit:=true)->void:
	if not bool(c.get("alive",false)):return
	var dealt:=mini(int(c.hp),damage);g.ranged.hit_creature(c,damage,velocity)
	if credit:earn("Destruction",minf(10,dealt/4.0))
	g._show_notice("Spell hit: %d damage" % dealt)
func absorb(damage:int)->int:
	if ward<=0 or ward_time<=0:return damage
	var blocked:=minf(ward,damage);ward-=blocked;earn("Warding",blocked/3.0)
	if ward<=0:ward_time=0;g._show_notice("Ward shattered")
	return ceili(damage-blocked)
static func creature_scale(c:Dictionary)->float:return 0.55 if float(c.get("magic_slow",0))>0 else 1.0
func tick(dt:float)->void:
	var before_wait:=regen_wait;regen_wait=maxf(0,regen_wait-dt)
	mana=minf(max_mana(),mana+maxf(0,dt-before_wait)*6)
	ward_time=maxf(0,ward_time-dt);flash=maxf(0,flash-dt)
	if ward_time<=0:ward=0
	var old_lumen:=lumen;lumen=maxf(0,lumen-dt)
	if old_lumen>0 and lumen<=0:g.environment.invalidate()
	for item:String in cooldowns:cooldowns[item]=maxf(0,float(cooldowns[item])-dt)
	for i in range(arcs.size()-1,-1,-1):
		arcs[i].life=float(arcs[i].life)-dt
		if float(arcs[i].life)<=0:arcs.remove_at(i)
	for c:Dictionary in g.world.get("creatures",[]):
		if not bool(c.get("alive",false)) or (float(c.get("magic_slow",0))<=0 and float(c.get("magic_burn",0))<=0 and float(c.get("magic_rot",0))<=0):continue
		g.spellcraft.tick_status(c,dt)
		if not bool(c.get("alive",false)):continue
		c.magic_slow=maxf(0,float(c.get("magic_slow",0))-dt)
		if g.water_sim.submerged(Ranged.hit_box(c).get_center()):c.magic_burn=0
		var burning:=minf(dt,float(c.get("magic_burn",0)));c.magic_burn=maxf(0,float(c.get("magic_burn",0))-dt)
		if burning>0:
			c.magic_burn_tick=float(c.get("magic_burn_tick",0))+burning
			while float(c.magic_burn_tick)+0.000001>=1 and bool(c.alive):c.magic_burn_tick=float(c.magic_burn_tick)-1;hit(c,6,Vector2.ZERO,false)
	for i in range(projectiles.size()-1,-1,-1):
		if not step(projectiles[i],dt):projectiles.remove_at(i)
func update(delta:float)->void:
	if not allowed():return
	g.spellcraft.tick(maxf(0,delta))
	if projectiles.is_empty() and arcs.is_empty():
		var active_status:=false
		for c:Dictionary in g.world.get("creatures",[]):
			if bool(c.get("alive",false)) and (float(c.get("magic_burn",0))>0 or float(c.get("magic_slow",0))>0 or float(c.get("magic_rot",0))>0):active_status=true;break
		if not active_status:budget=0;tick(maxf(0,delta));return
	budget+=maxf(0,delta)
	while budget+0.000001>=STEP:budget=maxf(0,budget-STEP);tick(STEP)
func step(shot:Dictionary,dt:float)->bool:
	shot.life=float(shot.life)-dt
	if float(shot.life)<=0:return false
	var start:Vector2=shot.pos;var end:Vector2=start+Vector2(shot.vel)*dt
	if shot.kind=="ember" and g.water_sim.submerged(start):return false
	var wall:float=g.ranged.terrain_hit(start,end);var contacts:Array=[]
	for c:Dictionary in g.world.get("creatures",[]):
		if not bool(c.get("alive",false)) or c in shot.hit:continue
		var fraction:=Ranged.segment_hit(start,end,Ranged.hit_box(c))
		if fraction<=1 and fraction<wall:contacts.append({"fraction":fraction,"c":c})
	contacts.sort_custom(func(a:Dictionary,b:Dictionary)->bool:return float(a.fraction)<float(b.fraction))
	for contact:Dictionary in contacts:
		var c:Dictionary=contact.c;shot.hit.append(c)
		if shot.has("crafted"):g.spellcraft.apply_hit(shot.crafted,c,shot.vel)
		else:hit(c,int(shot.damage),shot.vel)
		if not shot.has("crafted"):
			if shot.kind=="ember":c.magic_burn=3.0;c.magic_burn_tick=0.0
			elif shot.kind=="frost":c.magic_slow=3.0
		shot.left=int(shot.left)-1
		if int(shot.left)<=0:return false
	if wall<=1:return false
	shot.pos=end;return true
func texture(name:String)->Texture2D:
	if not textures.has(name):textures[name]=C.sheet(name)
	return textures[name]
func pose(screen_pos:Vector2)->Transform2D:
	var aim:Vector2=g.mouse_aim_direction if g.mouse_aim_valid else Vector2(g.facing,0)
	return Transform2D(aim.angle()+PI*0.5,g.PlayerPose.shoulder(screen_pos,g.facing)+aim*(14+3*sin(flash/0.24*PI)))
func draw_held(screen_pos:Vector2)->void:
	var transform:=pose(screen_pos);g.draw_set_transform_matrix(transform)
	g.draw_texture_rect_region(texture(C.filename(g.equipped_tool)),Rect2(-12,-29,24,40),Rect2((1+mini(1,int((0.24-flash)/0.12)))*24 if flash>0 else 0,0,24,40))
	g.draw_set_transform_matrix(Transform2D.IDENTITY);g._draw_player_arm(screen_pos,transform.origin)
func effect(name:String,at:Vector2,size:Vector2)->void:
	var frame:=posmod(int(g.animation_clock*8),4);var height:=int(texture(name).get_height())
	g.draw_texture_rect_region(texture(name),Rect2(at-size*0.5,size),Rect2(frame*height,0,height,height))
func draw()->void:
	for shot:Dictionary in projectiles:
		var at:Vector2=shot.pos-g.camera_pos;var frame:=posmod(int(g.animation_clock*10),4)
		g.draw_set_transform(at,Vector2(shot.vel).angle());g.draw_texture_rect_region(texture(str(shot.kind)+"_bolt"),Rect2(-18,-8,24,16),Rect2(frame*24,0,24,16));g.draw_set_transform_matrix(Transform2D.IDENTITY)
	for arc:Dictionary in arcs:
		var delta:Vector2=Vector2(arc.b)-Vector2(arc.a);g.draw_set_transform(Vector2(arc.a)-g.camera_pos,delta.angle())
		g.draw_texture_rect_region(texture("lightning"),Rect2(0,-4,delta.length(),8),Rect2(posmod(int(g.animation_clock*12),4)*32,0,32,8));g.draw_set_transform_matrix(Transform2D.IDENTITY)
	g.necromancy.draw()
	if ward_time>0 and ward>0:effect("ward_aura",g.player_pos+Vector2(8,14)-g.camera_pos,Vector2(56,56))
	if lumen>0:effect("lumen_orb",g.player_pos+Vector2(8,-17)-g.camera_pos,Vector2(22,22))
	if flash>0 and g.equipped_tool=="Mending Tome":effect("mend_aura",g.player_pos+Vector2(8,14)-g.camera_pos,Vector2(48,48))
	for c:Dictionary in g.world.get("creatures",[]):
		if not bool(c.get("alive",false)):continue
		if float(c.get("magic_burn",0))>0:effect("burn_status",Vector2(float(c.x)+12,float(c.y)-18)-g.camera_pos,Vector2(12,12))
		if float(c.get("magic_rot",0))>0:effect("blight_status",Vector2(float(c.x)+12,float(c.y)-28)-g.camera_pos,Vector2(12,12))
		if float(c.get("magic_slow",0))>0:effect("frost_status",Vector2(float(c.x)+12,float(c.y)-18)-g.camera_pos,Vector2(12,12))
func draw_hud()->void:
	g._text("MP",Vector2(29,56),12,Color("b4b4ed"))
	g._fill_rounded_rect(Rect2(53,46,120,9),Color("34344c"),4)
	if mana>0:g._fill_rounded_rect(Rect2(53,46,120*clampf(mana/max_mana(),0,1),9),Color("8998df"),4)
	g._text("%d / %d" % [int(mana),int(max_mana())],Vector2(185,56),12,Color("e7def1"))
	var caption:="K: Magic skills and spell guide"
	if ward_time>0:caption="Ward %.0f | %.1fs" % [ward,ward_time]
	elif C.has_focus(g.equipped_tool) and float(cooldowns.get(g.equipped_tool,0))>0:caption="Recovery %.1fs" % cooldowns[g.equipped_tool]
	g._button_text(Rect2(24,88,228,20),caption,11,Color("b9bfd9"),false,Vector2.ZERO)
func open_codex()->void:
	g.alchemy.close(false);g.stations.close(false);g.power_ui.close(false);g.interactions.close(false);g._stop_held_actions();codex_open=true
	g.inventory_open=true;g.crafting_open=false;g.dialogue_open=false
	if not g.window_positions.has("magic"):g.window_positions.magic=Vector2(20,105)
	g.window_positions.inventory=Vector2(790,190)
func close_codex(close_pack:=true)->void:
	codex_open=false;g._cancel_inventory_drag();g.dragged_window=""
	if close_pack:g.inventory_open=false
func codex_click(point:Vector2,button:int)->bool:return g.spellcraft.ui.click(point,button)
func draw_codex()->void:g.spellcraft.ui.draw()
