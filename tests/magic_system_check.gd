extends "res://tests/ranged_weapons_check.gd"
const M=preload("res://scripts/magic_catalog.gd")
func fresh(g)->void:
	super.fresh(g);g.magic.new_character();g.world["creatures"]=[]
func cast_at(g,item:String,point:Vector2=Vector2.ZERO)->bool:
	select(g,item);g.attack_cooldown=0
	var destination:Vector2=g.player_pos+Vector2(160,5) if point==Vector2.ZERO else point
	g.aim_screen=destination-g.camera_pos;g._set_mouse_world_target(destination)
	return g.magic.cast(destination)
func advance_magic(g,seconds:float,fps:=60)->void:
	for i in range(roundi(seconds*fps)):
		g.attack_cooldown=maxf(0,g.attack_cooldown-1.0/fps);g.magic.update(1.0/fps)
func controls_magic(g)->void:
	fresh(g);select(g,"Ember Wand");var destination:Vector2=g.player_pos+Vector2(160,5)
	mouse(g,destination-g.camera_pos,MOUSE_BUTTON_LEFT,true);mouse(g,destination-g.camera_pos,MOUSE_BUTTON_LEFT,false)
	check(g.magic.projectiles.size()==1 and absf(g.magic.mana-93)<0.001,"Hotbar left-click did not cast exactly one mana-funded bolt")
	check(int(g.inventory["Ember Wand"])==1,"Casting consumed reusable wand")
	check(not g.magic.cast(destination) and g.magic.projectiles.size()==1,"Global recovery could be bypassed")
	g.magic.mana=0;g.attack_cooldown=0;g.magic.cooldowns.clear()
	check(not g.magic.cast(destination) and g.magic.projectiles.size()==1,"Empty mana created a free spell")
	var grid:PackedByteArray=g.world.tiles.duplicate();g._mine(target(g));check(g.world.tiles==grid,"Magic focus mined terrain")
	for item:String in M.ITEMS:check(g.Tools.has_item(item) and not g.Tools.can_harvest(item,2) and g.Tools.mining_damage(item,2)==0,"Magic item can harvest terrain: "+item)
	g.magic.new_character();g.magic.mana=40;g.magic.regen_wait=2
	advance_magic(g,1);check(absf(g.magic.mana-40)<0.001,"Mana regenerated during cast delay")
	advance_magic(g,2);check(absf(g.magic.mana-46)<0.001,"Mana regeneration did not resume at 6/s")
	var mana:float=g.magic.mana;g.paused=true;g.magic.update(10);g.paused=false
	check(g.magic.mana==mana,"Paused game advanced mana or spells")
	g._key_pressed(KEY_K);check(g.magic.codex_open and g.inventory_open,"K did not open magic skill guide")
	g._key_pressed(KEY_ESCAPE);check(not g.magic.codex_open and not g.inventory_open and not g.paused,"Esc failed to close magic guide before pausing")
	g.magic.mana=40;select(g,"Mana Tonic",3);g.magic.drink()
	check(g.magic.mana==90 and int(g.inventory["Mana Tonic"])==2,"Mana tonic did not restore mana exactly once")
	check(not g.magic.drink() and int(g.inventory["Mana Tonic"])==2,"Mana tonic bypassed its recovery")
func offensive(g)->void:
	for fps in [30,60,120]:
		fresh(g);var c:=enemy(607*16.0,100);g.world.creatures=[c]
		check(cast_at(g,"Ember Wand"),"Ember spell rejected")
		advance_magic(g,1.2,fps)
		check(int(c.hp)==79 and float(c.get("magic_burn",0))>0,"Ember impact/burn damage wrong at %d FPS" % fps)
		advance_magic(g,2.2,fps);check(int(c.hp)==67,"Burn duration/damage changed across frame rates")
	fresh(g);var c:=enemy(607*16.0);g.world.creatures=[c]
	cast_at(g,"Frost Wand");advance_magic(g,0.3)
	check(int(c.hp)==82 and g.magic.creature_scale(c)==0.55,"Frost failed to damage and slow")
	advance_magic(g,3.2);check(g.magic.creature_scale(c)==1.0,"Frost slow did not expire")
	fresh(g);g.world.creatures=[enemy(606*16.0),enemy(610*16.0),enemy(614*16.0)]
	cast_at(g,"Crystal Staff");advance_magic(g,0.8)
	check(int(g.world.creatures[0].hp)==75 and int(g.world.creatures[1].hp)==75 and int(g.world.creatures[2].hp)==100,"Crystal bolt piercing count incorrect")
	fresh(g);g.world.creatures=[enemy(607*16.0),enemy(611*16.0),enemy(615*16.0)]
	check(cast_at(g,"Storm Staff",Ranged.hit_box(g.world.creatures[0]).get_center()),"Storm failed to acquire visible target")
	check(int(g.world.creatures[0].hp)==72 and int(g.world.creatures[1].hp)==79 and int(g.world.creatures[2].hp)==84,"Lightning chain damage/falloff incorrect")
	fresh(g);c=enemy(607*16.0);g.world.creatures=[c]
	for y in range(94,100):g._edit_tile(Vector2i(604,y),3)
	check(not cast_at(g,"Storm Staff",Ranged.hit_box(c).get_center()) and g.magic.mana==100,"Lightning cast through a wall or spent mana without a target")
	cast_at(g,"Ember Wand");advance_magic(g,0.6);check(int(c.hp)==100,"Projectile crossed solid terrain")
	fresh(g);c=enemy(607*16.0);g.world.creatures=[c]
	for y in range(97,100):g._edit_tile(Vector2i(603,y),3)
	g.player_pos=Vector2(603*16-17,1572);cast_at(g,"Crystal Staff");advance_magic(g,0.5)
	check(int(c.hp)==100,"Wand muzzle spawned a bolt on the far side of a wall")
	fresh(g);c=enemy(607*16.0);g.world.creatures=[c]
	g.water_sim.add_rain(Vector2i(603,98),255);g.water_sim.add_rain(Vector2i(603,99),255)
	cast_at(g,"Ember Wand");advance_magic(g,0.6)
	check(int(c.hp)==100,"Ember bolt did not extinguish in water")
	c.magic_burn=3.0;c.magic_burn_tick=0
	var wet_cell:=Vector2i(floor(Ranged.hit_box(c).get_center()/16));g.water_sim.add_rain(wet_cell,255);advance_magic(g,0.2)
	check(float(c.magic_burn)==0 and int(c.hp)==100,"Water did not extinguish burning enemy")
	fresh(g);c=enemy(607*16.0,5);g.world.creatures=[c]
	cast_at(g,"Ember Wand");advance_magic(g,4)
	check(not bool(c.alive) and g.world.drops.size()==1,"Magic kills/burning duplicated creature loot")
func support(g)->void:
	fresh(g);g.health=50
	check(cast_at(g,"Mending Tome") and g.health==74 and g.magic.mana==75,"Mending did not restore 24HP for 25MP")
	g.magic.cooldowns.clear();g.health=100;g.attack_cooldown=0
	check(not g.magic.cast(g.player_pos+Vector2(150,5)) and g.magic.mana==75,"Full-health healing wasted mana")
	fresh(g);check(cast_at(g,"Ward Book"),"Ward book could not raise barrier")
	check(g.magic.absorb(25)==0 and g.magic.ward==15,"Ward failed to absorb incoming creature damage")
	check(g.magic.absorb(30)==15 and g.magic.ward==0,"Broken ward did not pass remaining damage to health")
	check(float(g.magic.xp.Warding)>0,"Absorbed damage did not earn ward mastery")
	fresh(g);cast_at(g,"Greater Ward Book");g.health=100
	g.lava_sim.add_rain(Vector2i(600,99),255);g.player_pos=Vector2(600*16,1572);g._update_lava_damage(0.01)
	check(g.health==80 and g.magic.ward==80,"Lava incorrectly consumed or was blocked by ward")
	fresh(g);cast_at(g,"Ward Book");advance_magic(g,8.1)
	check(g.magic.ward==0 and g.magic.ward_time==0,"Expired ward kept protecting player")
	fresh(g);check(cast_at(g,"Lumen Tome") and g.magic.lumen>59,"Lumen spell failed to start cave light")
	for x in range(592,610):g._edit_tile(Vector2i(x,95),3)
	g.environment.prepare(Vector2(595*16,88*16),g.player_pos,0,1,0,false,1.05)
	var bright:float=g.environment.brightness_at(g.player_pos+Vector2(8,14))
	g.environment.prepare(Vector2(595*16,88*16),g.player_pos,0,1,1,false,0)
	check(bright>0.95 and g.environment.brightness_at(g.player_pos+Vector2(8,14))<bright-0.4,"Lumen did not illuminate underground independently of held torches")
	check(float(g.farming.growth_rate(Vector2i(601,99),PackedInt32Array(),0).rate)==0,"Lumen incorrectly grew crops as a permanent lamp")
	fresh(g);g.magic.earn("Destruction",300)
	check(g.magic.rank("Destruction")==5 and g.magic.max_mana()==120,"Magic mastery did not increase rank/capacity")
	var c:=enemy(607*16.0);g.world.creatures=[c];cast_at(g,"Crystal Staff");advance_magic(g,0.4)
	check(int(c.hp)==67,"Destruction mastery failed to improve spell damage")
func recipes_magic(g)->void:
	fresh(g)
	for item:String in M.ITEMS:
		var index:=-1
		for i in range(g.RECIPES.size()):
			if g.RECIPES[i].out==item:index=i;break
		check(index>=0,"Missing magic recipe: "+item)
		if index<0:continue
		g.stations.open({"name":"Workbench","tile":Vector2i(602,99)});g.stations.state().inputs=Slots.create(9);g.stations.state().output={}
		for material:String in g.RECIPES[index].needs:g.inventory[material]=g.RECIPES[index].needs[material];g.stations.deposit(material)
		check(g.stations.craft(index) and int(g.stations.state().output.get(item,0))==1,"Magic workbench crafting failed: "+item)
		g.stations.close()
func saves_magic(g)->void:
	fresh(g);cast_at(g,"Ward Book");advance_magic(g,0.5);g.magic.earn("Destruction",35);g.magic.lumen=45
	var before:Dictionary=g.magic.snapshot();g._save_game();g._load_game()
	while g.scene_name=="loading":await process_frame
	check(absf(g.magic.mana-float(before.mana))<0.001 and g.magic.rank("Destruction")==2,"Magic mana/mastery changed on saving")
	check(g.magic.ward==float(before.ward) and absf(g.magic.ward_time-float(before.ward_time))<0.001 and g.magic.lumen==45,"Ward/light state was lost on loading")
	check(g.magic.cooldowns["Ward Book"]>9 and g.magic.projectiles.is_empty(),"Save/load reset spell recovery or retained transient projectiles")
	var parsed:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(g.save_path));parsed.erase("magic")
	var f:=FileAccess.open(g.save_path,FileAccess.WRITE);f.store_string(JSON.stringify(parsed));f.close();g._load_game()
	while g.scene_name=="loading":await process_frame
	check(g.magic.mana==100 and g.magic.xp.is_empty(),"Older saves did not get safe magic defaults")
	g.magic.respawn();check(g.magic.ward==0 and g.magic.mana==g.magic.max_mana(),"Respawn retained ward or empty mana")
	g.new_game_name="Magic check";g.seed_text="61723";g._start_new_game()
	check(g.inventory.is_empty() and g.magic.mana==100 and g.magic.xp.is_empty(),"New game gained magic items or retained old mastery")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(g.save_path));DirAccess.remove_absolute(ProjectSettings.globalize_path(g.settings_path))
func run()->void:
	var g=load("res://main.tscn").instantiate();root.add_child(g);g.set_process(false);await process_frame
	g.save_path="user://magic_system_check.json";g.settings_path="user://magic_system_settings.json"
	controls_magic(g);offensive(g);support(g);recipes_magic(g);await saves_magic(g)
	print("MAGIC_SYSTEM casting, mana, effects, collisions, chaining, wards, healing, light, skills, recipes and saves failures=",failures)
	quit(0 if failures==0 else 1)
