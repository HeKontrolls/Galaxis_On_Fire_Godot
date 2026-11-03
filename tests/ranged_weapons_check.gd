extends "res://tests/housing_check.gd"
const Ranged=preload("res://scripts/ranged_weapons.gd")
const Slots=preload("res://scripts/station_slots.gd")

func fresh(g) -> void:
	fixture(g);g.expedition.data.clear();g.world["drops"]=[];g.world["torches"]={}
	g.ranged.reset();g.ranged.selected_ammo="Stone Arrow";g.attack_cooldown=0
	g.mouse_aim_direction=Vector2.RIGHT;g.mouse_aim_valid=true;g.aim_screen=Vector2(850,350)
func mouse(g,point: Vector2,button: MouseButton,pressed: bool) -> void:
	var event:=InputEventMouseButton.new();event.position=point;event.button_index=button;event.pressed=pressed;g._input(event)
func target(g,dx:=116.0) -> Vector2:
	return g.player_pos+Vector2(8+dx,5)-g.camera_pos
func shot(g,bow: String,arrow: String,hold:=0.75) -> void:
	select(g,bow);g.inventory[arrow]=20;g.ranged.selected_ammo=arrow;g.attack_cooldown=0
	mouse(g,target(g),MOUSE_BUTTON_LEFT,true)
	g.ranged.update(hold)
	mouse(g,target(g),MOUSE_BUTTON_LEFT,false)
func advance(g,seconds: float,fps:=60) -> void:
	for tick in range(roundi(seconds*fps)):
		g.attack_cooldown=maxf(0,g.attack_cooldown-1.0/fps)
		g.ranged.update(1.0/fps)
func enemy(x: float,hp:=100) -> Dictionary:
	return {"x":x,"y":1570.0,"home_x":x,"hp":hp,"max_hp":hp,"alive":true,"direction":-1}

func controls(g) -> void:
	fresh(g);select(g,"Wood Bow");g.inventory["Stone Arrow"]=3
	var point:=target(g)
	mouse(g,point,MOUSE_BUTTON_LEFT,true)
	check(g.ranged.charging and g.ranged.projectiles.is_empty() and g.inventory["Stone Arrow"]==3,"Press should start a draw without spending ammo")
	g.ranged.update(0.70)
	check(g.ranged.charge()>=0.99,"Bow did not reach full draw")
	mouse(g,point,MOUSE_BUTTON_LEFT,false)
	check(not g.ranged.charging and g.ranged.projectiles.size()==1 and g.inventory["Stone Arrow"]==2,"Release must fire exactly one arrow")
	var full:Dictionary=g.ranged.projectiles[0].duplicate(true)
	g.ranged.reset();g.attack_cooldown=0
	mouse(g,point,MOUSE_BUTTON_LEFT,true);mouse(g,point,MOUSE_BUTTON_LEFT,false)
	check(g.ranged.projectiles.size()==1 and int(g.ranged.projectiles[0].damage)<int(full.damage) and Vector2(g.ranged.projectiles[0].vel).length()<Vector2(full.vel).length(),"Quick shots need less speed and damage than charged shots")
	g.ranged.reset();g.attack_cooldown=0;g.inventory["Stone Arrow"]=0
	mouse(g,point,MOUSE_BUTTON_LEFT,true);mouse(g,point,MOUSE_BUTTON_LEFT,false)
	check(g.ranged.projectiles.is_empty() and not g.ranged.charging,"Empty quiver fired a free arrow")
	g.inventory["Stone Arrow"]=10;g.inventory["Iron Arrow"]=4
	mouse(g,point,MOUSE_BUTTON_RIGHT,true);mouse(g,point,MOUSE_BUTTON_RIGHT,false)
	check(g.ranged.selected_ammo=="Iron Arrow" and g.inventory["Iron Arrow"]==4,"Right-click should select ammo without spending it")
	g.attack_cooldown=0;mouse(g,point,MOUSE_BUTTON_LEFT,true)
	g.inventory_open=true;g._process(0.01);g.inventory_open=false;mouse(g,point,MOUSE_BUTTON_LEFT,false)
	check(not g.ranged.charging and g.ranged.projectiles.is_empty() and g.inventory["Iron Arrow"]==4,"Opening inventory fired or spent a drawn arrow")
	g.attack_cooldown=0;mouse(g,point,MOUSE_BUTTON_LEFT,true);select(g,"Pickaxe");mouse(g,point,MOUSE_BUTTON_LEFT,false)
	check(g.ranged.projectiles.is_empty(),"Switching tools released an old bow shot")
	select(g,"Wood Bow");g.attack_cooldown=0;mouse(g,point,MOUSE_BUTTON_LEFT,true)
	g._notification(g.NOTIFICATION_WM_WINDOW_FOCUS_OUT);mouse(g,point,MOUSE_BUTTON_LEFT,false)
	check(g.ranged.projectiles.is_empty(),"Focus loss fired an arrow")
	var grid:PackedByteArray=g.world.tiles.duplicate();g._mine(Vector2(601*16+8,100*16+8)-g.camera_pos)
	check(grid==g.world.tiles,"Bow mined terrain")
	for bow:String in Ranged.WEAPONS:
		check(g.Tools.has_item(bow) and not g.Tools.can_harvest(bow,2) and g.Tools.mining_damage(bow,2)==0 and g.tool_textures.has(bow),"Ranged equipment catalog or mining rejection failed: "+bow)
	fresh(g);shot(g,"Iron Crossbow","Stone Arrow",0)
	check(g.ranged.projectiles.size()==1 and g.inventory["Stone Arrow"]==19 and g.attack_cooldown>1,"Crossbow did not fire immediately with a reload delay")
	mouse(g,target(g),MOUSE_BUTTON_LEFT,true);mouse(g,target(g),MOUSE_BUTTON_LEFT,false)
	check(g.ranged.projectiles.size()==1 and g.inventory["Stone Arrow"]==19,"Crossbow bypassed reload")
	g.ranged.reset();g.attack_cooldown=0;g.inventory["Stone Arrow"]=0;g.inventory["Copper Arrow"]=2;g.ranged.selected_ammo="Stone Arrow"
	check(g.ranged.ammo()=="Copper Arrow","Empty selected ammo did not fall back to another owned arrow")

func collision_checks(g) -> void:
	fresh(g);var first:=enemy(607*16.0);g.world.creatures=[first]
	check(Ranged.hit_box(first).has_point(Vector2(float(first.x)+12,float(first.y)-6)),"Arrow hit box must include the visible head above the movement collider")
	shot(g,"Wood Bow","Stone Arrow");advance(g,0.7)
	check(int(first.hp)==86,"Charged Wood Bow should deal 14 damage at range")
	for kind in ["flying","wildlife","guardian"]:
		fresh(g);var c:=enemy(607*16.0,12)
		if kind=="flying":c["flight_state"]="roam"
		elif kind=="wildlife":c["wildlife"]=true;c["wildlife_family"]=0
		else:c["quest_guardian"]=true
		g.world.creatures=[c];shot(g,"Iron Bow","Iron Arrow");advance(g,1)
		check(not bool(c.alive) and g.world.drops.size()==1,"Ranged kill/loot failed for "+kind)
	fresh(g);var a:=enemy(607*16.0);var b:=enemy(609*16.0);g.world.creatures=[a,b]
	shot(g,"Iron Bow","Crystal Arrow");advance(g,1)
	check(int(a.hp)==63 and int(b.hp)==63 and g.ranged.projectiles.is_empty(),"Crystal arrow must hit two enemies once each")
	fresh(g);a=enemy(607*16.0);b=enemy(609*16.0);g.world.creatures=[a,b]
	shot(g,"Iron Bow","Stone Arrow");advance(g,1)
	check(int(a.hp)==72 and int(b.hp)==100,"Ordinary arrows should stop at the first enemy")
	for tile in [3,46]:
		fresh(g);var behind:=enemy(607*16.0);g.world.creatures=[behind]
		for y in range(94,100):g._edit_tile(Vector2i(604,y),tile,false)
		shot(g,"Iron Crossbow","Stone Arrow",0);advance(g,0.5,30)
		check(int(behind.hp)==100 and g.ranged.projectiles.is_empty(),"Arrow tunneled through terrain or a closed door")
		check(g.world.drops.size()==1 and g.world.drops[0].item=="Stone Arrow","Terrain impact did not return one ordinary arrow")
	fresh(g);var blocked:=enemy(607*16.0);g.world.creatures=[blocked]
	for y in range(94,100):g._edit_tile(Vector2i(601,y),3,false)
	shot(g,"Iron Crossbow","Crystal Arrow",0);advance(g,0.5)
	check(blocked.hp==100 and g.world.drops.is_empty() and g.ranged.projectiles.is_empty(),"Muzzle bypassed an adjacent wall or crystal tips failed to shatter")
	# Fixed stepping yields the same trajectory at different rendering rates.
	var end_points:Array[Vector2]=[]
	for fps in [30,60,120]:
		fresh(g);shot(g,"Iron Bow","Stone Arrow");advance(g,0.1,fps)
		check(g.ranged.projectiles.size()==1,"Trajectory fixture hit terrain too early")
		if not g.ranged.projectiles.is_empty():end_points.append(g.ranged.projectiles[0].pos)
	check(end_points.size()==3 and end_points[0].distance_to(end_points[2])<0.01,"Arrow trajectories depend on frame rate")
	fresh(g);shot(g,"Wood Bow","Stone Arrow")
	var arrow:Dictionary=g.ranged.projectiles[0]
	var speed:float=Vector2(arrow.vel).length();var cell:=Vector2i(floor(Vector2(arrow.pos)/16))
	g.water_sim.add_rain(cell,255);advance(g,0.05)
	check(not g.ranged.projectiles.is_empty() and Vector2(g.ranged.projectiles[0].vel).length()<speed,"Water should slow an arrow")
	g.lava_sim.add_rain(Vector2i(floor(Vector2(arrow.pos)/16)),255);advance(g,0.01)
	check(g.ranged.projectiles.is_empty(),"Lava did not consume the arrow")

func crafting(g) -> void:
	fresh(g);g.recipe_tab=0;g.recipe_index=58;g.inventory={"Stick":4,"Stone":2};g._craft()
	check(g.inventory.get("Stone Arrow",0)==16 and g.inventory.Stick==0 and g.inventory.Stone==0,"Basic stone-arrow crafting failed")
	for index in [54,55,56,57,59,60,61]:
		g.stations.open({"name":"Workbench","tile":Vector2i(602,99)})
		var machine:Dictionary=g.stations.state();machine.inputs=Slots.create(9);machine.output={}
		var recipe:Dictionary=g.RECIPES[index]
		for item:String in recipe.needs:
			g.inventory[item]=recipe.needs[item];g.stations.deposit(item,recipe.needs[item])
		check(g.stations.craft(index) and int(machine.output.get(recipe.out,0))==int(recipe.count),"Workbench weapon/ammo recipe failed: "+str(recipe.out))
		g.stations.close()

func persistence(g) -> void:
	fresh(g);shot(g,"Iron Crossbow","Crystal Arrow",0)
	var before:int=g.inventory["Crystal Arrow"]
	g._save_game();g._load_game()
	while g.scene_name=="loading":await process_frame
	check(g.equipped_tool=="Iron Crossbow" and g.ranged.selected_ammo=="Crystal Arrow" and g.inventory["Crystal Arrow"]==before,"Weapon, hotbar or ammunition choice changed on save/load")
	check(g.attack_cooldown>1 and not g.ranged.charging and g.ranged.projectiles.is_empty(),"Reload delay was shortened by saving, or transient shots survived loading")
	var data:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(g.save_path));data.erase("arrow_ammo")
	var f:=FileAccess.open(g.save_path,FileAccess.WRITE);f.store_string(JSON.stringify(data));f.close();g._load_game()
	while g.scene_name=="loading":await process_frame
	check(g.ranged.selected_ammo=="Stone Arrow","Legacy saves need a safe ammo default")
	g.new_game_name="Ranged check";g.seed_text="163927";g._start_new_game()
	check(g.inventory.is_empty() and g.ranged.selected_ammo=="Stone Arrow" and g.ranged.projectiles.is_empty(),"New Game received free equipment or old projectile state")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(g.save_path));DirAccess.remove_absolute(ProjectSettings.globalize_path(g.settings_path))
func run() -> void:
	var g=load("res://main.tscn").instantiate();root.add_child(g);g.set_process(false);await process_frame
	g.save_path="user://ranged_weapons_check.json";g.settings_path="user://ranged_weapons_settings.json"
	controls(g);collision_checks(g);crafting(g);await persistence(g)
	print("RANGED_WEAPONS controls, charge, ammo, damage, piercing, terrain, doors, fluids, frame rates, crafting and saves failures=",failures)
	quit(0 if failures==0 else 1)
