extends "res://tests/ranged_weapons_check.gd"
const Melee = preload("res://scripts/melee_weapons.gd")
const Night = preload("res://scripts/night_population.gd")
const State = preload("res://scripts/network_state.gd")
var assertions := 0

class Observer:
	extends RefCounted
	var camera_pos := Vector2.ZERO
	var player_pos := Vector2.ZERO
	const SCREEN := Vector2(1280,720)
	var scene_name := "planet"
	var world_key := ""
	func _world_key() -> String: return world_key

func check(ok: bool, message: String) -> void:
	assertions+=1
	super.check(ok,message)

func setup(g) -> void:
	fresh(g)
	g.world.surface.fill(100)
	g.environment.reset(g.world)
	g.day_count=2; g.time_of_day=0.75
	g.sound.clips.clear()

func strike(g,item: String,dx: float) -> Dictionary:
	select(g,item);g.attack_cooldown=0
	var c:=enemy(g.player_pos.x+dx,200)
	g.world.creatures=[c]
	g._attack(g.player_pos+Vector2(200,11))
	return c

func weapons(g) -> void:
	setup(g)
	for item: String in Melee.WEAPONS:
		var c:=strike(g,item,30)
		check(c.hp==200-int(Melee.WEAPONS[item].damage),item+" damage mismatch")
		g._attack(g.player_pos+Vector2(200,11))
		check(c.hp==200-int(Melee.WEAPONS[item].damage),item+" bypassed cooldown")
		check(g.Tools.has_item(item) and g.tool_textures.has(item) and g.dev_controls.item_catalog.has(item),item+" missing from inventory/dev catalog")
		var grid:PackedByteArray=g.world.tiles.duplicate()
		g.mining_cooldown=0;g._mine(Vector2(601*16+8,100*16+8)-g.camera_pos)
		check(grid==g.world.tiles and not g.Tools.can_harvest(item,2) and g.Tools.mining_damage(item,2)==0,item+" mined terrain")
		var image:Image=g.tool_textures[item].get_image()
		check(image.get_pixel(0,0).a==0 and image.get_size()==Vector2i(32,64 if item.ends_with("Spear") else 40),item+" art size or alpha")
		check(FileAccess.file_exists("res://assets/sprites/source/weapons/"+item.to_lower().replace(" ","_")+".aseprite"),item+" missing native artwork")
	setup(g)
	check(strike(g,"Iron Spear",80).hp==166,"Spear cannot reach a distant target")
	check(strike(g,"Iron Dagger",80).hp==200,"Dagger reached too far")
	check(strike(g,"Iron Spear",125).hp==200,"Spear exceeded its reach")
	# A thrust is narrow; a warhammer sweeps multiple enemies once each.
	check(not Melee.hits("Iron Spear",Vector2.ZERO,Vector2.RIGHT,Rect2(30,45,24,18)),"Spear has an excessively broad hit area")
	for item in ["Iron Warhammer","Crystal Blade","Iron Dagger"]:
		setup(g);select(g,item);g.attack_cooldown=0
		var foes: Array=[]
		for dx in [24,32,40,48]: foes.append(enemy(g.player_pos.x+dx,200))
		g.world.creatures=foes;g._attack(g.player_pos+Vector2(200,11))
		var hurt:=0
		for c in foes:
			if c.hp<200:hurt+=1
		check(hurt==int(Melee.WEAPONS[item].hits),item+" cleave count")
	setup(g);select(g,"Iron Spear")
	var blocked:=enemy(g.player_pos.x+80,200);g.world.creatures=[blocked]
	for y in range(94,100):g._edit_tile(Vector2i(603,y),3,false)
	g.attack_cooldown=0;g._attack(g.player_pos+Vector2(200,11))
	check(blocked.hp==200,"Spear attacked through a stone wall")
	setup(g);select(g,"Iron Warhammer")
	var victim:=enemy(g.player_pos.x+30,200);g.world.creatures=[victim]
	for y in range(94,100):g._edit_tile(Vector2i(604,y),3,false)
	g.attack_cooldown=0;g._attack(g.player_pos+Vector2(200,11))
	check(float(victim.x)+23<604*16,"Hammer pushed a creature through a wall")
	setup(g);select(g,"Iron Warhammer")
	var weak:=enemy(g.player_pos.x+30,10);g.world.creatures=[weak]
	g.attack_cooldown=0;g._attack(g.player_pos+Vector2(200,11))
	check(not weak.alive and g.world.drops.size()==1,"Melee kill did not drop loot")
	g.attack_cooldown=0;g._attack(g.player_pos+Vector2(200,11))
	check(g.world.drops.size()==1,"Attacking a corpse duplicated loot")
	# Mouse aim drives the single-piece arm, in either facing direction.
	for direction in [Vector2.RIGHT,Vector2.LEFT,Vector2.UP,Vector2.DOWN]:
		var facing:=1 if direction.x>=0 else -1
		var pose:Transform2D=g.PlayerPose.tool(Vector2.ZERO,direction,facing,true,0.5,"Iron Spear",false)
		check((pose*Vector2(0,-40)-pose.origin).normalized().dot(direction)>0.99,"Thrust does not follow mouse aim")
	setup(g)
	for recipe: Dictionary in Melee.RECIPES:
		var index:int=g.RECIPES.find(recipe)
		check(index>=0,"Recipe missing: "+str(recipe.out))
		if recipe.has("station"):
			g.stations.open({"name":"Workbench","tile":Vector2i(602,99)})
			var machine:Dictionary=g.stations.state();machine.inputs=Slots.create(9);machine.output={}
			for item:String in recipe.needs:
				g.inventory[item]=recipe.needs[item];g.stations.deposit(item,recipe.needs[item])
			check(g.stations.craft(index) and int(machine.output.get(recipe.out,0))==1,"Station recipe failed: "+str(recipe.out))
			g.stations.close()
		else:
			g.inventory=recipe.needs.duplicate();g.recipe_index=index;g.recipe_tab=0;g._craft()
			check(g.inventory.get(recipe.out,0)==1,"Basic spear recipe failed")

func nights(g) -> void:
	setup(g);g.time_of_day=0.25
	for i in range(60):Night.update(g,1.0)
	check(g.world.creatures.is_empty(),"Extra creatures appeared in daylight")
	check(Night.intensity(0.51)<Night.intensity(0.6) and Night.intensity(0.97)<Night.intensity(0.75),"Night pressure should ramp at dusk/dawn")
	var saw_flyer:=false;var saw_ground:=false;var saw_slime:=false
	for climate in range(8):
		setup(g);g.world.climate=climate
		for i in range(90):Night.update(g,1.0)
		check(not g.world.creatures.is_empty(),"No nocturnal encounters for climate %d" % climate)
		check(g.world.creatures.size()<=Night.LOCAL_CAP,"Local population cap exceeded")
		for c:Dictionary in g.world.creatures:
			var at:=Vector2(float(c.x),float(c.y))
			check(Night.hidden(at,[g]) and g.FlyingMonsters.fits(g.world,at),"Creature appeared on-screen or in terrain")
			if c.get("flying",false): saw_flyer=true;check(int(c.monster_family)==climate,"Wrong planet flyer")
			elif c.get("wildlife",false):saw_slime=true
			else:saw_ground=true;check(int(c.monster_family)==climate,"Wrong planet ground creature")
	check(saw_flyer and saw_ground and saw_slime,"Night encounters lack ground/flyer/slime variety")
	setup(g)
	g.player_pos.y=400*16
	for i in range(30):Night.update(g,1.0)
	check(g.world.creatures.is_empty(),"Surface mobs spawned while player was deep underground")
	setup(g)
	var at:Vector2=g.player_pos+Vector2(850,10)
	var guest:=Observer.new();guest.player_pos=at;guest.camera_pos=at-Vector2(640,360);guest.world_key=g._world_key()
	check(Night.hidden(at,[g]) and not Night.hidden(at,[g,guest]),"Spawn visibility ignored a second player")
	g.network.role="host";g.network.actors[999]=guest
	check(Night.players(g).size()==2,"Host spawn planning ignored guest positions")
	g.network.actors.erase(999);g.network.role=""
	var cell:=Vector2i(floor(at/16))
	g.furnishings.walls[g.furnishings.key(cell)] = true
	check(not Night.valid_site(g,at,[g]),"Spawn accepted a player background wall")
	g.furnishings.walls.clear();g.water_sim.add_rain(cell,255)
	check(not Night.valid_site(g,at,[g]),"Spawn accepted water")
	setup(g);g.lava_sim.add_rain(cell,255)
	check(not Night.valid_site(g,at,[g]),"Spawn accepted lava")
	setup(g);g.network_actor=true
	for i in range(20):Night.update(g,1.0)
	check(g.world.creatures.is_empty(),"Guest simulation spawned creatures")
	g.network_actor=false;g.network.role="client"
	for i in range(20):Night.update(g,1.0)
	check(g.world.creatures.is_empty(),"Client spawned creatures independently")
	g.network.role=""
	setup(g)
	for i in range(100):Night.update(g,1.0)
	var night_count:int=g.world.creatures.size()
	var resident:=enemy(g.player_pos.x+1000);g.world.creatures.append(resident)
	var visible:Dictionary=g.world.creatures[0];visible.x=g.player_pos.x+100;visible.y=g.player_pos.y
	g.time_of_day=0.25;Night.update(g,1.0)
	check(visible.alive and resident.alive,"Dawn removed a visible enemy or daytime resident")
	var retired:=0
	for c:Dictionary in g.world.creatures:
		if c.get("night_retired",false):retired+=1;check(c.raised and not c.alive,"Retreat generated a usable corpse")
	check(retired==night_count-1 and g.world.drops.is_empty(),"Dawn cleanup or loot handling failed")
	# Repeated nights reuse old offscreen slots, preserving existing resident indices.
	g.world.creatures.erase(resident)
	for cycle in range(20):
		g.time_of_day=0.25;Night.update(g,100)
		g.time_of_day=0.75
		for i in range(90):Night.update(g,1.0)
	check(g.world.creatures.size()<=Night.MAX_SLOTS,"Nocturnal records grow without limit")
	var active:=0
	for c:Dictionary in g.world.creatures:
		if c.alive:active+=1
	check(active<=Night.MAX_ACTIVE,"Global nocturnal cap exceeded")

func persistence_new(g) -> void:
	setup(g)
	for item:String in Melee.WEAPONS: select(g,item)
	for i in range(30):Night.update(g,1.0)
	var expected_count:int=g.world.creatures.size()
	var serial:int=g.world.night_spawn_serial
	g._save_game();g._load_game()
	while g.scene_name=="loading": await process_frame
	for item:String in Melee.WEAPONS:
		check(g.inventory.get(item,0)==1 and item in g.hotbar.slots,"Save lost weapon/hotbar: "+item)
	check(g.equipped_tool=="Crystal Blade","Save lost equipped weapon")
	var nights_saved:int=g.world.creatures.filter(func(c):return bool(c.get("night_spawn",false))).size()
	check(nights_saved==expected_count and g.world.night_spawn_serial==serial,"Night encounter state lost on save")
	var packet:Dictionary=bytes_to_var(var_to_bytes({"personal":State.personal(g),"shared":State.shared(g)}))
	check(packet.personal.inventory.get("Iron Spear",0)==1 and packet.shared.world.creatures.size()==g.world.creatures.size(),"Network codec lost weapons or night encounters")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(g.save_path))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(g.settings_path))

func run() -> void:
	var g=load("res://main.tscn").instantiate();root.add_child(g);g.set_process(false);await process_frame
	g.save_path="user://weapons_night_check.json";g.settings_path="user://weapons_night_settings.json"
	weapons(g);nights(g);await persistence_new(g)
	print("WEAPONS_AND_NIGHT assertions=",assertions," failures=",failures)
	quit(0 if failures==0 else 1)
