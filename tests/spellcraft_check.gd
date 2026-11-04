extends "res://tests/magic_system_check.gd"
const C=preload("res://scripts/spellcraft_catalog.gd")
func unlock_all(g)->void:
	for school:String in g.MagicCatalog.SCHOOLS:g.magic.xp[school]=300.0
	for node:String in C.NODES:check(g.spellcraft.learn(node),"Could not learn test node: "+node)
	g.magic.mana=g.magic.max_mana()
func research(g)->void:
	fresh(g)
	check(g.spellcraft.points()==3,"New character should have three research points")
	check(not g.spellcraft.learn("storm"),"Advanced research bypassed prerequisites/rank")
	g._key_pressed(KEY_K)
	var rect:Rect2=g.spellcraft.ui.node_rect(C.NODES.keys().find("ember"))
	g.spellcraft.ui.click(Vector2(g.window_positions.magic)+rect.get_center(),MOUSE_BUTTON_LEFT)
	check(g.spellcraft.knows("ember") and g.spellcraft.points()==2,"Actual tree click did not spend one point")
	check(not g.spellcraft.learn("ember") and g.spellcraft.points()==2,"Duplicate node spent another point")
	g.magic.earn("Destruction",30)
	check(g.spellcraft.points()==3 and g.spellcraft.learn("storm"),"Mastery rank did not grant a point/unlock connected research")
	g.magic.close_codex();var draft:=C.draft();draft.second="Frost"
	check(not g.spellcraft.validate(draft).is_empty(),"Locked dual effects were accepted")
func place_station(g,item:String,x:int)->String:
	g.player_pos=Vector2((x-1)*16,1572);g._update_camera();select(g,item)
	g._place(Vector2(x*16+8,99*16+8)-g.camera_pos)
	var key:="%d,99" % x
	check(g.world.furniture.has(key),"Failed real placement: "+item)
	return key
func open_station(g,key:String)->void:
	var entry:Dictionary=g.world.furniture[key]
	g.player_pos=Vector2((int(entry.x)-1)*16,1572);g._update_camera()
	g._set_mouse_world_target(g.furnishings.entry_rect(entry).get_center());g._key_pressed(KEY_F)
	check(g.alchemy.is_open() and g.alchemy.active_key==key,"F did not open alchemy station independently")
func materials(g,needs:Dictionary)->void:
	for item:String in needs:
		g.inventory[item]=int(g.inventory.get(item,0))+int(needs[item]);check(g.alchemy.deposit(item,int(needs[item])),"Reagent deposit failed: "+item)
func workshop(g)->void:
	fresh(g);unlock_all(g)
	var desk:=place_station(g,"Alchemy Desk",600);var cauldron:=place_station(g,"Cauldron",606);var other:=place_station(g,"Alchemy Desk",612)
	check(not g._collides(Vector2(600*16,1572)),"Alchemy furniture blocks walking")
	open_station(g,desk)
	g.alchemy.click(Vector2(g.window_positions.alchemy)+Vector2(300,100),MOUSE_BUTTON_LEFT)
	for pair in [[KEY_W,87],[KEY_I,105]]:
		var letter:=InputEventKey.new();letter.keycode=pair[0];letter.unicode=pair[1];letter.pressed=true;g._input(letter)
	check(g.alchemy.is_open() and g.alchemy.state().draft.name=="Wi","Typing a spell name triggered gameplay hotkeys")
	var enter:=InputEventKey.new();enter.keycode=KEY_ENTER;enter.pressed=true;g._input(enter)
	check(not g.alchemy.editing,"Enter did not finish editing the spell name")
	g.inventory["Arcane Ink"]=4;g.alchemy.deposit("Arcane Ink",2)
	g.alchemy.close();open_station(g,other)
	check(g.alchemy.state().inputs.filter(func(s):return not s.is_empty()).is_empty(),"Alchemy desks share ingredient storage")
	g.alchemy.close();open_station(g,cauldron)
	for i in range(C.BREWS.size()):
		var recipe:Dictionary=C.BREWS[i];g.alchemy.state().inputs=Slots.create(9);g.alchemy.state().output={};g.alchemy.state().recipe=i
		materials(g,recipe.needs)
		check(g.alchemy.start_brew(),"Could not start cauldron recipe: "+str(recipe.out))
		check(not g.alchemy.start_brew(),"Duplicate brew consumed ingredients again")
		g.alchemy.update(3);check(g.alchemy.state().output.is_empty(),"Cauldron skipped warming/brewing time")
		g.alchemy.update(float(recipe.time));check(int(g.alchemy.state().output.get(recipe.out,0))==int(recipe.count),"Cauldron recipe failed: "+str(recipe.out))
		check(g.alchemy.withdraw("output",0),"Finished brew could not be recovered")
	g.alchemy.state().recipe=0;materials(g,C.BREWS[0].needs);g.alchemy.start_brew()
	var remaining:float=g.alchemy.state().job.remaining;g.water_sim.add_rain(Vector2i(606,99),200);g.alchemy.update(4)
	check(g.alchemy.state().job.remaining==remaining,"Flooded cauldron kept brewing")
	g.water_sim.remove_units(99*WG.WIDTH+606,255)
	g.alchemy.close();open_station(g,desk);g.alchemy.state().inputs=Slots.create(9);g.alchemy.state().output={}
	var draft:=C.draft();draft.name="Frostfire Lance";draft.first="Ember";draft.second="Frost";draft.power=2;draft.duration=2
	materials(g,g.spellcraft.needs(draft));g.alchemy.state().draft=draft
	var before:Dictionary=g.inventory.duplicate();var item:String=g.spellcraft.inscribe(draft,g.alchemy.state().inputs,g.alchemy.state().output)
	check(not item.is_empty() and g.spellcraft.spells.has(item) and int(g.alchemy.state().output.get(item,0))==1,"Desk did not create a distinct saved spell focus")
	check(g.alchemy.state().inputs.filter(func(s):return not s.is_empty()).is_empty(),"Spell inscription did not consume its station reagents")
	check(g.spellcraft.inscribe(draft,g.alchemy.state().inputs,g.alchemy.state().output).is_empty(),"Inscribe created a free duplicate without materials")
	g.alchemy.withdraw("output",0);g.alchemy.close();g._equip_inventory_item(item)
	check(g.equipped_tool==item and g.tool_textures.has(item),"Unique spell focus could not be equipped from hotbar")
	var c:=enemy(607*16.0,200);g.world.creatures=[c];g.player_pos=Vector2(600*16,1572);g._update_camera();g.magic.mana=200;g.attack_cooldown=0
	var target:Vector2=g.player_pos+Vector2(140,5);g.aim_screen=target-g.camera_pos
	check(g.magic.cast(target),"Custom focus could not cast its saved design");advance_magic(g,0.4)
	check(int(c.hp)==148 and float(c.get("magic_slow",0))>0 and float(c.get("magic_burn",0))>0,"Dual-element projectile did not apply both effects")
	check(absf(g.magic.mana-176)<0.001,"Custom mana cost did not follow tuning")
	# The second item has a different identity even when the display name matches.
	open_station(g,desk);materials(g,g.spellcraft.needs(draft));var twin:String=g.spellcraft.inscribe(draft,g.alchemy.state().inputs,g.alchemy.state().output)
	check(twin!=item and g.spellcraft.spells.size()==2,"Same-name custom spells collided in storage")
	g.alchemy.withdraw("output",0);g.alchemy.close()
	# Saving a partial cauldron batch and custom cooldown must not produce a free refill.
	g._equip_inventory_item(item);g.magic.cooldowns[item]=0.7;g.spellcraft.regen_time=5;g.spellcraft.regen_rate=2
	var points:int=g.spellcraft.points();var time:float=g.world.alchemy[cauldron].job.remaining
	g._save_game();g._load_game()
	while g.scene_name=="loading":await process_frame
	check(g.spellcraft.spells.has(item) and g.spellcraft.spells.has(twin) and int(g.inventory.get(item,0))==1,"Custom spell records/items were lost on load")
	check(g.spellcraft.points()==points and g.spellcraft.learned.size()==20,"Saved tree spent points twice or lost research")
	check(g.equipped_tool==item and g.magic.cooldowns.get(item,0)>0.6,"Custom focus equipment/recovery was reset during loading")
	check(absf(float(g.world.alchemy[cauldron].job.remaining)-time)<0.001 and g.spellcraft.regen_time==5,"Alchemy job or regeneration lost its saved remaining time")
	# Breaking a station refunds stored contents and one unfinished batch, once.
	g.world.drops.clear();g.furnishings._remove(g,cauldron)
	var counts:Dictionary={}
	for drop:Dictionary in g.world.drops:counts[drop.item]=int(counts.get(drop.item,0))+int(drop.count)
	check(counts.get("Cauldron",0)==1 and counts.get("Wood",0)==1 and counts.get("Coal Ore",0)==2,"Dismantling cauldron lost/duplicated its unfinished ingredients")
	g.furnishings._remove(g,desk)
	check(not g.world.alchemy.has(desk) and not g.alchemy.is_open(),"Removed alchemy station retained storage/window")
func necro(g)->void:
	fresh(g);g.spellcraft.learn("soul");g.health=50
	var foe:=enemy(607*16.0,100);g.world.creatures=[foe]
	check(cast_at(g,"Soul Wand"),"Unlocked soul wand could not cast");advance_magic(g,0.4)
	check(int(foe.hp)==86 and g.health==55 and float(g.magic.xp.get("Necromancy",0))>0,"Life drain did not damage, heal and progress necromancy")
	foe.hp=1;g.magic.cooldowns.clear();g.attack_cooldown=0;cast_at(g,"Soul Wand");advance_magic(g,0.4)
	check(not bool(foe.alive) and g.world.drops.filter(func(d):return d.item=="Bone Fragment").size()==1,"Soul research did not yield exactly one bone fragment")
	g.spellcraft.dead_loot(foe);check(g.world.drops.filter(func(d):return d.item=="Bone Fragment").size()==1,"Repeated death callback duplicated bones")
	g.magic.xp["Necromancy"]=30;check(g.spellcraft.learn("raise"),"Necromancy branch could not unlock Raise Dead")
	select(g,"Grave Tome");g.magic.mana=110;g.magic.cooldowns.clear();g.attack_cooldown=0
	var corpse_pos:=Ranged.hit_box(foe).get_center();g.aim_screen=corpse_pos-g.camera_pos
	check(g.magic.cast(corpse_pos) and bool(foe.raised) and g.necromancy.minions.size()==1,"Raise Dead did not consume a usable fallen creature")
	var saved_mana:float=g.magic.mana;g.attack_cooldown=0;g.magic.cooldowns.clear()
	check(not g.magic.cast(corpse_pos) and g.magic.mana==saved_mana,"Same corpse could be raised twice or charged a failed cast")
	var second:=enemy(605*16.0,100);g.world.creatures.append(second);g.necromancy.update(1);g.necromancy.update(0.5)
	check(int(second.hp)<100 and g.health==55,"Raised ally did not fight enemies safely")
	var unraised:=enemy(608*16.0);unraised.alive=false;g.world.creatures.append(unraised)
	check(not g.necromancy.can_raise(Ranged.hit_box(unraised).get_center()),"Base summon limit was bypassed")
	g.magic.xp["Necromancy"]=180;check(g.spellcraft.learn("legion") and g.necromancy.limit()==3,"Legion branch did not raise summon capacity")
	var blocked:=enemy(612*16.0,100)
	g.world.creatures=[foe,blocked]
	for y in range(93,100):g._edit_tile(Vector2i(610,y),3)
	g.necromancy.update(3)
	check(int(blocked.hp)==100,"Summoned ally attacked through solid terrain")
	var remaining:float=g.necromancy.minions[0].life
	g._save_game();g._load_game()
	while g.scene_name=="loading":await process_frame
	check(g.necromancy.minions.size()==1 and absf(float(g.necromancy.minions[0].life)-remaining)<0.001,"Saved summon lost its remaining life or duplicated on load")
	g.necromancy.update(61);check(g.necromancy.minions.is_empty(),"Raised allies did not expire")
func variants(g)->void:
	fresh(g);unlock_all(g);g.inventory["Wand #80: Test"]=1
	var item:="Wand #80: Test";var draft:=C.draft();draft.first="Blight";draft.form="Burst";draft.area=2
	g.spellcraft.spells[item]=draft;g._equip_inventory_item(item);g.player_pos=Vector2(600*16,1572);g._update_camera()
	var first:=enemy(607*16.0);var second:=enemy(609*16.0);g.world.creatures=[first,second]
	var target:=Ranged.hit_box(first).get_center();g.aim_screen=target-g.camera_pos
	check(g.magic.cast(target),"Crafted burst spell could not cast");advance_magic(g,1.2)
	check(int(first.hp)<89 and int(second.hp)<89,"Blight burst failed to hit area targets and decay over time")
	g.magic.projectiles.clear();g.magic.cooldowns.clear();g.attack_cooldown=0;g.magic.mana=200
	draft.first="Drain";draft.form="Chain";draft.area=2;g.spellcraft.spells[item]=draft;g.health=50
	check(g.magic.cast(target) and g.health>50,"Crafted chain-drain did not combine delivery with life steal")
	g.magic.cooldowns.clear();g.attack_cooldown=0;g.magic.mana=200;draft.first="Ward";draft.second="Regeneration";draft.form="Self";g.spellcraft.spells[item]=draft
	check(g.magic.cast(target) and g.magic.ward>0 and g.spellcraft.regen_time>0,"Custom self spell did not combine ward and regeneration")
	var hp:int=g.health;advance_magic(g,2.1);check(g.health>hp,"Crafted regeneration did not heal over time")
	var count:int=g.spellcraft.spells.size();g.magic.new_character()
	check(g.spellcraft.spells.is_empty() and g.spellcraft.learned.is_empty() and g.spellcraft.points()==3,"New character retained custom spells or purchased skills")
func run()->void:
	var g=load("res://main.tscn").instantiate();root.add_child(g);g.set_process(false);await process_frame
	g.save_path="user://spellcraft_check.json";g.settings_path="user://spellcraft_check_settings.json"
	research(g);await workshop(g);await necro(g);variants(g)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(g.save_path))
	print("SPELLCRAFT tree gates, station storage, timed brewing, inscription, custom casting, necromancy, minions, recipes and persistence failures=",failures)
	quit(0 if failures==0 else 1)
