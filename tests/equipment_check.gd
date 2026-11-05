extends "res://tests/ranged_weapons_check.gd"
const Gear=preload("res://scripts/equipment_catalog.gd")
const Equipment=preload("res://scripts/player_equipment.gd")
const State=preload("res://scripts/network_state.gd")
var checks:=0
func check(ok: bool,message: String) -> void:
	checks+=1;super.check(ok,message)
func setup(g) -> void:
	fresh(g);g.equipment.reset();g.magic.ward=0;g.magic.ward_time=0;g.magic.codex_open=false
	g._stop_held_actions();g.sound.clips.clear();g.character_appearance=g.CharacterAppearance.DEFAULT.duplicate()
func give_equip(g,item: String,key: String="") -> void:
	g.inventory[item]=int(g.inventory.get(item,0))+1
	check(g.equipment.equip(item,key),"Cannot equip "+item)
func set_armor(g,material: String) -> void:
	for item:String in Gear.ITEMS:
		if str(Gear.ITEMS[item].get("material",""))==material:give_equip(g,item)
func inventory_checks(g) -> void:
	setup(g);give_equip(g,"Fiber Hood")
	check(g.inventory["Fiber Hood"]==0 and g.equipment.slots.head=="Fiber Hood","Equipped armor must be removed from backpack")
	g.inventory["Iron Helmet"]=1
	check(not g.equipment.equip("Iron Helmet","boots") and g.inventory["Iron Helmet"]==1,"Wrong slot consumed helmet")
	check(g.equipment.equip("Iron Helmet") and g.inventory["Fiber Hood"]==1 and g.inventory["Iron Helmet"]==0,"Swap lost old armor")
	check(g.equipment.unequip("head") and not g.equipment.unequip("head") and g.inventory["Iron Helmet"]==1,"Unequipping duplicated gear")
	check(not g.equipment.equip("Copper Helmet"),"Equipped an unowned item")
	g.inventory["Iron Boots"]=2;g.equipment.equip("Iron Boots");g._stage_trash("Iron Boots");g._destroy_trash()
	check(g.equipment.slots.boots=="Iron Boots" and g.inventory["Iron Boots"]==0,"Trash affected equipped armor")
	check(g.equipment.unequip("boots") and g.inventory["Iron Boots"]==1,"Trashing spare armor lost equipped copy")
	give_equip(g,"Scout Charm");give_equip(g,"Bone Ward")
	g.inventory["Scout Charm"]=1
	check(not g.equipment.equip("Scout Charm") and g.inventory["Scout Charm"]==1,"Duplicate accessory stacked")
	check(g.equipment.defense()==2 and is_equal_approx(g.equipment.movement(),1.08),"Accessory stats incorrect")
	# Backpack click equips, Ctrl click stays a hotbar shortcut, gear cards unequip.
	setup(g);g.inventory={"Copper Helmet":1};g.inventory_open=true
	var at:Vector2=g.window_positions.inventory
	var item_point:=at+Vector2(42,66)
	g._gameplay_ui_click(item_point,MOUSE_BUTTON_LEFT,true)
	check("Copper Helmet" in g.hotbar.slots and g.equipment.slots.head=="","Ctrl-click no longer adds gear shortcut")
	g._gameplay_ui_click(item_point,MOUSE_BUTTON_RIGHT)
	check(g.equipment.slots.head=="Copper Helmet" and not "Copper Helmet" in g.hotbar.slots,"Right-click did not equip/prune empty shortcut")
	g._gameplay_ui_click(at+Vector2(170,18),MOUSE_BUTTON_LEFT)
	check(g.equipment.gear_open,"Gear tab did not open")
	var slot:Rect2=g.equipment.slot_rect(0)
	g._gameplay_ui_click(slot.get_center(),MOUSE_BUTTON_LEFT)
	check(g.equipment.slots.head=="" and g.inventory["Copper Helmet"]==1,"Gear card did not return item")
	g.inventory_drag_item="Copper Helmet";g.inventory_dragging=true;g.inventory_drag_slot=-1
	g._finish_inventory_drag(slot.get_center())
	check(g.equipment.slots.head=="Copper Helmet" and g.inventory_drag_item.is_empty(),"Dragging to gear card failed")
	# Shared window coordinates keep dragging/closing and sorting available.
	g._gameplay_ui_click(at+Vector2(445,18),MOUSE_BUTTON_LEFT)
	check(not g.inventory_open,"Gear tab cannot close backpack")
	g.inventory_open=true;g.equipment.gear_open=false;g.inventory={"Fiber Vest":1}
	g._equip_inventory_item("Fiber Vest")
	check(g.equipment.slots.chest=="Fiber Vest" and g.inventory_open,"Backpack equip did not retain window")
func combat(g) -> void:
	var front:Vector2
	for material in ["fiber","copper","iron"]:
		setup(g);set_armor(g,material);front=g.player_pos+Vector2(80,11)
		var expected:int={"fiber":4,"copper":8,"iron":12}[material]
		check(g.equipment.defense()==expected,"Set defense incorrect: "+material)
		check(g.equipment.absorb(20,front)==20-expected/2,"Armor damage reduction incorrect")
		check(g.equipment.absorb(1,front)==1,"Armor grants total immunity")
		var speed:float={"fiber":1.0,"copper":0.95,"iron":0.90}[material]
		check(is_equal_approx(g.equipment.movement(),speed),"Armor movement penalty incorrect")
		var start:Vector2=g.player_pos
		g._update_player_motion(0.1,1,false)
		check(absf(g.player_pos.x-start.x-g.SPEED*speed*0.1)<0.1,"Armor penalty not applied to player motion")
	for shield:String in ["Wood Shield","Copper Shield","Iron Shield"]:
		setup(g);give_equip(g,shield);select(g,"Iron Sword");g.attack_cooldown=0
		front=g.player_pos+Vector2(80,11)
		g.secondary_held=true;g.equipment.begin_block(front)
		check(g.equipment.blocking,"Shield did not raise with melee weapon")
		var expected:=ceili(20*(1-float(Gear.ITEMS[shield].block)))
		check(g.equipment.absorb(20,front)==expected and is_equal_approx(g.equipment.guard,60),"Front shield reduction/guard cost incorrect")
		check(g.equipment.absorb(20,g.player_pos-Vector2(80,0))==20 and is_equal_approx(g.equipment.guard,60),"Shield protected rear hit")
		var target_mob:=enemy(g.player_pos.x+25,100);g.world.creatures=[target_mob]
		g._attack(front)
		check(target_mob.hp==100,"Attacked while blocking")
		g.equipment.guard=5
		check(g.equipment.absorb(20,front)==20 and not g.equipment.blocking and g.equipment.broken_time>1,"Guard did not break")
		g.equipment.update(2)
		check(g.equipment.guard==0,"Raised broken shield regenerated guard")
		g.secondary_held=false;g.equipment.update(4)
		check(g.equipment.guard==100,"Lowered guard failed to recover")
		g.secondary_held=true;g.equipment.begin_block(front)
		mouse(g,front-g.camera_pos,MOUSE_BUTTON_RIGHT,false)
		check(not g.equipment.blocking and not g.secondary_held,"Right-click release kept shield raised")
		for item in ["Pickaxe","Wood Bow","Ember Wand","Dirt"]:
			select(g,item);g.attack_cooldown=0;g.secondary_held=true
			check(not g.equipment.begin_block(front),"Shield stole right-click from "+item)
		select(g,"Iron Sword");g.attack_cooldown=0;g.secondary_held=true;g.equipment.begin_block(front)
		g._notification(g.NOTIFICATION_WM_WINDOW_FOCUS_OUT)
		check(not g.equipment.blocking,"Focus loss kept shield active")
	setup(g);set_armor(g,"iron");give_equip(g,"Iron Shield");select(g,"Sword");g.attack_cooldown=0
	front=g.player_pos+Vector2(80,11);g.secondary_held=true;g.equipment.begin_block(front)
	g.magic.ward=10;g.magic.ward_time=20
	check(g.equipment.absorb(20,front)==0 and g.magic.ward==7,"Armor/shield/ward order is wrong")
	# Incoming directions above/below follow mouse aim rather than horizontal facing.
	g.magic.ward=0;g.magic.ward_time=0;g.equipment.guard=100
	var overhead:Vector2=g.player_pos+Vector2(8,-80)
	g.equipment.begin_block(overhead)
	check(g.equipment.absorb(20,overhead)==3,"Overhead aimed shield did not block")
	g.inventory_open=true;g.equipment.update(0.1)
	check(not g.equipment.blocking,"Inventory allowed shield blocking")
	# Actual ground-monster and host contact routes must use equipment mitigation.
	setup(g);set_armor(g,"iron");var c:=enemy(g.player_pos.x,100);c.damage=20
	g.damage_cooldown=0;g._update_creature(c,0)
	check(g.health==86,"Ground creature bypassed armor")
	g.health=100;g.damage_cooldown=0;g.world.creatures=[c];g.network._contact_damage(g,0)
	check(g.health==86,"Host guest-contact route bypassed armor")
	# Lava remains an environmental hazard, not a blockable creature strike.
	g.health=100;g.damage_cooldown=0;g.lava_hurt_timer=0
	g.lava_sim.add_rain(Vector2i(floor((g.player_pos+Vector2(8,14))/16)),255);g._update_lava_damage(0.1)
	check(g.health==80,"Armor unexpectedly protected against lava")
func recipes_and_art(g) -> void:
	setup(g)
	for recipe:Dictionary in Gear.RECIPES:
		check(g.dev_controls.item_catalog.has(recipe.out),"Gear missing from developer catalog")
		g.stations.open({"name":"Workbench","tile":Vector2i(602,99)})
		var machine:Dictionary=g.stations.state();machine.inputs=Slots.create(9);machine.output={}
		for item:String in recipe.needs:g.inventory[item]=recipe.needs[item];g.stations.deposit(item,recipe.needs[item])
		check(g.stations.craft(g.RECIPES.find(recipe)) and machine.output.get(recipe.out,0)==1,"Recipe failed: "+str(recipe.out))
		g.stations.close()
		var icon:Image=Gear.icon(recipe.out).get_image()
		check(icon.get_size()==Vector2i(32,32) and icon.get_pixel(0,0).a==0,"Invalid icon alpha/size: "+str(recipe.out))
	for material in ["fiber","copper","iron"]:
		for model in ["male","female"]:
			for part in ["head","chest","boots"]:
				check(Gear.texture(material+"_"+model+"_"+part).get_size()==Vector2(320,160),"Armor atlas dimensions mismatch")
func saves(g) -> void:
	setup(g);set_armor(g,"copper");give_equip(g,"Iron Shield");give_equip(g,"Scout Charm")
	g.equipment.guard=37;g.equipment.guard_wait=0.4
	var expected:Dictionary=g.equipment.snapshot()
	g._save_game();g.equipment.reset();g._load_game()
	while g.scene_name=="loading":await process_frame
	check(g.equipment.snapshot()==expected,"Equipment/guard changed on save/load")
	check(g.inventory.get("Copper Helmet",0)==0,"Loading duplicated equipped armor into backpack")
	var personal:Dictionary=bytes_to_var(var_to_bytes(State.personal(g)))
	g.equipment.reset();State.apply_personal(g,personal)
	check(g.equipment.snapshot()==expected,"Network personal snapshot lost equipment")
	var pose:Dictionary=g.network._pose(g)
	check(pose.equipment==expected.slots and pose.has("blocking"),"Remote-player pose missing armor or shield")
	# Old saves have no equipment; loading them must clear previous character gear.
	var data:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(g.save_path));data.erase("equipment")
	var file:=FileAccess.open(g.save_path,FileAccess.WRITE);file.store_string(JSON.stringify(data));file.close()
	g._load_game()
	while g.scene_name=="loading":await process_frame
	check(g.equipment.defense()==0 and g.equipment.slots.shield=="","Legacy save inherited previous equipment")
	g.equipment.restore({"slots":{"head":"Iron Shield","boots":"Invalid","accessory1":"Scout Charm","accessory2":"Scout Charm"},"guard":999})
	check(g.equipment.slots.head=="" and g.equipment.slots.boots=="" and g.equipment.slots.accessory2=="" and g.equipment.guard==100,"Malformed equipment state accepted")
	g.new_game_name="Equipment check";g.seed_text="1729";g._start_new_game()
	check(g.inventory.is_empty() and g.equipment.defense()==0 and g.equipment.slots.accessory1=="","New game inherited equipment")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(g.save_path));DirAccess.remove_absolute(ProjectSettings.globalize_path(g.settings_path))
func run() -> void:
	var g=load("res://main.tscn").instantiate();root.add_child(g);g.set_process(false);await process_frame
	g.save_path="user://equipment_check.json";g.settings_path="user://equipment_check_settings.json"
	inventory_checks(g);combat(g);recipes_and_art(g);await saves(g)
	print("EQUIPMENT checks=",checks," failures=",failures)
	quit(0 if failures==0 else 1)
