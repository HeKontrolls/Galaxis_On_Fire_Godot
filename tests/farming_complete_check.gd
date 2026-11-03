extends "res://tests/housing_check.gd"
const Farm = preload("res://scripts/farming.gd")
const Crops = preload("res://scripts/crop_catalog.gd")
const Furnace = preload("res://scripts/furnace_system.gd")
const Slots = preload("res://scripts/station_slots.gd")

func field(g) -> void:
	fixture(g)
	g.expedition.data.clear()
	g.world["drops"]=[]
	g.world["torches"]={}
	g.farms.clear()
	g.farms[g._world_key()] = g.farming
	g.equipped_tool = "Hand"
	g.time_of_day = 0.25
	g.weather = "Clear"
	g.weather_blend.reset("Clear",0)
	for x in range(560,641): g._edit_tile(Vector2i(x,100),2,false)
	g.world_texture.update(g.world_image)

func at(g,cell: Vector2i) -> Vector2:
	return Vector2(cell*16)+Vector2(8,8)-g.camera_pos

func sow(g,cell: Vector2i,seed: String) -> void:
	g.player_pos = Vector2((cell.x-1)*16,100*16-28)
	g._update_camera()
	select(g,"Hoe")
	g._mine(at(g,cell+Vector2i.DOWN))
	select(g,"Watering Can")
	g._mine(at(g,cell+Vector2i.DOWN))
	select(g,seed,2)
	g._place(at(g,cell))

func core_checks(g) -> void:
	field(g)
	var i := 0
	for crop: String in Crops.CROPS:
		var cell := Vector2i(598+i*2,99)
		var seed := Crops.seed_for(crop)
		sow(g,cell,seed)
		check(WG.tile_at(g.world.tiles,cell.x,cell.y)==14 and g.farming.crop_at(cell)==crop and g.inventory[seed]==1,"Hotbar planting failed: "+crop)
		# A persistent channel irrigates the whole row within four tiles.
		g.water_sim.add_rain(Vector2i(cell.x+1,99),128)
		i+=1
	var plants: Dictionary = g.farming.plants.duplicate(true)
	# Plants are intentionally far outside the active player region now.
	g.player_pos=Vector2(900*16,1600-28)
	g._update_crops(60.0)
	for point: String in plants:
		check(float(g.farming.plants[point].progress)>0.3,"Offscreen crop failed to grow: "+point)
	g._update_crops(100.0)
	i=0
	for crop: String in Crops.CROPS:
		var cell:=Vector2i(598+i*2,99)
		check(WG.tile_at(g.world.tiles,cell.x,cell.y)==16,"Irrigated crop did not ripen: "+crop)
		g.player_pos=Vector2((cell.x-1)*16,1600-28);g._update_camera()
		select(g,"Watering Can")
		g._mine(at(g,cell))
		check(WG.tile_at(g.world.tiles,cell.x,cell.y)==16 and g.tool_action_timer>0,"Watering a mature plant should water its soil, not harvest it")
		select(g,"Hoe");g._mine(at(g,cell))
		check(WG.tile_at(g.world.tiles,cell.x,cell.y)==0,"Mature plant cannot be harvested: "+crop)
		var found:={}
		for drop:Dictionary in g.world.drops: found[str(drop.item)]=int(found.get(str(drop.item),0))+int(drop.count)
		check(int(found.get(crop,0))>=2 and int(found.get(Crops.seed_for(crop),0))>=1,"Harvest must return produce and renewable planting stock: "+crop)
		i+=1
	field(g)
	var cell:=Vector2i(601,99)
	g._edit_tile(cell+Vector2i.DOWN,12)
	g._farm_interaction(cell,"Hand","Carrot Seeds")
	check(not g.farming.plants.has(Farm.key(cell)) and WG.tile_at(g.world.tiles,601,99)==0,"No seeds created crop metadata")
	g.inventory["Carrot Seeds"]=1
	g._edit_tile(cell+Vector2i.UP,3)
	g._farm_interaction(cell,"Hand","Carrot Seeds")
	check(g.inventory["Carrot Seeds"]==1 and not g.farming.plants.has(Farm.key(cell)),"Cramped planting consumed seeds")
	g._edit_tile(cell+Vector2i.UP,0)
	g._farm_interaction(cell,"Hand","Carrot Seeds")
	g._farm_interaction(cell,"Hoe","")
	check(g.world.drops.size()==1 and g.world.drops[0].item=="Carrot Seeds","Uprooting immature plant should return one seed")
	g.inventory["Carrot Seeds"]=1;g._farm_interaction(cell,"Hand","Carrot Seeds")
	g.world.drops.clear();g._edit_tile(cell+Vector2i.DOWN,0)
	check(WG.tile_at(g.world.tiles,601,99)==0 and g.world.drops.size()==1 and g.world.drops[0].item=="Carrot Seeds","Removing soil left floating crops or duplicated seeds")
	check(not g._farm_interaction(Vector2i(700,100),"Hoe","") and WG.tile_at(g.world.tiles,700,100)==3,"Farming must obey the four-block action reach")
	# Rewatering an already-wet tile refreshes its tracked moisture.
	g._edit_tile(cell+Vector2i.DOWN,13);g.farming.moisture["601,100"]=0.25
	g._farm_interaction(cell+Vector2i.DOWN,"Watering Can","")
	check(float(g.farming.moisture["601,100"])==1.0,"Repeated watering failed to refresh wet soil")

func advance_farm(farm,seconds: float,water:=PackedByteArray(),sun:=1.0,rain:=false) -> void:
	var edits:Array=farm.advance(0,seconds,rain,PackedInt32Array(),water,1.0,sun)
	var grid:PackedByteArray=farm.world.tiles
	for edit:Vector3i in edits:
		WG.set_tile(grid,edit.x,edit.y,edit.z);farm.track(Vector2i(edit.x,edit.y),edit.z)
	farm.world.tiles=grid

func model(g) -> void:
	field(g);sow(g,Vector2i(601,99),"Carrot Seeds")
	var data:Dictionary=g.world.duplicate(true)
	var farm:=Farm.new();farm.bind_world(data)
	advance_farm(farm,60.0,PackedByteArray(),0)
	check(float(farm.plants["601,99"].progress)==0,"Outdoor crops grew in the dark")
	advance_farm(farm,120.0)
	check(WG.tile_at(data.tiles,601,100)==12 and float(farm.plants["601,99"].progress)>0.5,"Soil drying or dry growth failed")
	for climate in [4,5,6]:
		data=g.world.duplicate(true);data.climate=climate;farm=Farm.new();farm.bind_world(data)
		advance_farm(farm,30)
		check(float(farm.plants["601,99"].progress)==0,"Harsh climate allowed an exposed crop")
		WG.set_tile(data.tiles,601,95,33);farm.geometry_changed(Vector2i(601,95))
		advance_farm(farm,30)
		check(float(farm.plants["601,99"].progress)==0,"Roof alone provided light")
		data.torches["600,98"]=true
		advance_farm(farm,30,PackedByteArray(),0)
		check(float(farm.plants["601,99"].progress)>0,"Lit growing area failed in harsh climate")
		data.torches.clear()
		data["furniture"]={"602,99":{"item":"Fireplace","x":602,"y":99,"lit":true}}
		check(float(farm.growth_rate(Vector2i(601,99),PackedInt32Array(),0).rate)==1.0,"Stored fireplace did not light crops")
		data.furniture["602,99"].lit=false
		check(float(farm.growth_rate(Vector2i(601,99),PackedInt32Array(),0).rate)==0.0,"Extinguished fireplace still lit crops")
	# Frame subdivision has no effect on crop progress or moisture.
	var a:=Farm.new();a.bind_world(g.world.duplicate(true))
	var b:=Farm.new();b.bind_world(g.world.duplicate(true))
	advance_farm(a,160)
	for tick in range(160*30):advance_farm(b,1.0/30)
	check(absf(float(a.plants["601,99"].progress)-float(b.plants["601,99"].progress))<0.01 and absf(float(a.moisture["601,100"])-float(b.moisture["601,100"]))<0.01,"Growth depends on frame rate")
	# Irrigation stops at solid non-soil barriers; rain respects roofs.
	var channel:=PackedByteArray();channel.resize(WG.WIDTH*WG.HEIGHT);channel[100*WG.WIDTH+604]=128
	check(g.farming.irrigated(Vector2i(601,100),channel),"Nearby channel did not irrigate row")
	g._edit_tile(Vector2i(602,100),3)
	check(not g.farming.irrigated(Vector2i(601,100),channel),"Irrigation passed through stone")

func forage_and_cooking(g) -> void:
	field(g)
	for species:String in Crops.FORAGE:
		var entry:={"id":500,"species":species,"x":9608.0,"y":1600.0,"alive":true}
		g.world.drops.clear();g.ground_life._harvest(g,entry)
		check(g.world.drops.size()==2 and g.world.drops[1].item==Crops.FORAGE[species],"Wild seed source missing: "+species)
		entry.alive=true;entry.cultivated=true;g.world.drops.clear();g.ground_life._harvest(g,entry)
		check(g.world.drops.size()==1,"Decorative replanting duplicates seeds")
	check(g.ground_life.place(g,"Wildflower",Vector2i(601,99)),"Wildflower replanting failed")
	var replanted: Dictionary=g.ground_life.entries[-1]
	check(bool(replanted.get("cultivated",false)),"Placed flora lost its cultivated flag")
	g.world.drops.clear();g.ground_life._harvest(g,replanted)
	check(g.world.drops.size()==1 and g.world.drops[0].item=="Wildflower","Actual decorative replanting duplicates seed drops")
	for index in range(45,50):
		var recipe:Dictionary=g.RECIPES[index]
		g.stations.open({"name":"Workbench","tile":Vector2i(602,99)})
		g.stations.state().inputs=Slots.create(9);g.stations.state().output={}
		for item:String in recipe.needs:
			g.inventory[item]=recipe.needs[item];g.stations.deposit(item,recipe.needs[item])
		check(g.stations.craft(index) and int(g.stations.state().output.get(recipe.out,0))==int(recipe.count),"Workbench seed processing failed: "+str(recipe.out))
		g.stations.close()
	for index in [14,50,51,52,53]:
		var recipe:Dictionary=g.RECIPES[index]
		g.stations.open({"name":"Furnace","tile":Vector2i(603,99)})
		var machine:Dictionary=g.stations.state()
		machine.inputs=Slots.create(6);machine.fuel=Slots.create(1);machine.output={};machine.jobs=[];machine.heat=0
		for item:String in recipe.needs:
			if item=="Wood":continue
			g.inventory[item]=recipe.needs[item];g.stations.deposit(item,recipe.needs[item])
		g.furnaces.update(30)
		check(machine.jobs.is_empty() and machine.output.is_empty(),"Cooking consumed food without fuel")
		g.inventory["Wood"]=1;g.stations.deposit("Wood",1)
		g.furnaces.update(5)
		check(machine.output.is_empty() and machine.jobs.size()==1,"Cooking skipped warm-up or selected the wrong recipe")
		g.furnaces.update(float(Furnace.TIMES[recipe.out])-0.1)
		check(machine.output.is_empty(),"Food finished before its cook time")
		g.furnaces.update(0.11)
		check(int(machine.output.get(recipe.out,0))==1,"Timed furnace meal failed: "+str(recipe.out))
		g.stations.withdraw("output",0);g.stations.close()
		g.health=20;g.food_cooldown=0;select(g,str(recipe.out),1)
		g._place(Vector2(400,300))
		check(g.health==20+int(g.FoodCatalog.FOODS[recipe.out]) and int(g.inventory[recipe.out])==0,"Cooked food hotbar consumption failed: "+str(recipe.out))

func persistence(g) -> void:
	field(g);sow(g,Vector2i(601,99),"Tomato Seeds")
	g._update_crops(40)
	var progress:float=g.farming.plants["601,99"].progress
	var moisture:float=g.farming.moisture["601,100"]
	g._save_game();g._load_game()
	while g.scene_name=="loading": await process_frame
	check(g.farming.crop_at(Vector2i(601,99))=="Tomato" and absf(float(g.farming.plants["601,99"].progress)-progress)<0.001,"Crop species and partial growth changed on load")
	check(absf(float(g.farming.moisture["601,100"])-moisture)<0.001,"Saved moisture changed on load")
	var home:Dictionary=g.world
	var other:Dictionary=home.duplicate(true);other.seed=9123
	g.worlds["away_check"]=other
	g._update_crops(10)
	check(float(other.farm_plants["601,99"].progress)>progress,"Visited planets' crops stop growing while away")
	check(g.farms.size()>=2,"Visited farms did not retain their growth models")
	g.worlds.erase("away_check");g.farms.erase("away_check")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(g.save_path))

func run() -> void:
	var g=load("res://main.tscn").instantiate();root.add_child(g);g.set_process(false);await g._open_planet(0);g.hide();g.sound.clips.clear()
	g.save_path="user://farming_complete_check.json"
	core_checks(g);model(g);forage_and_cooking(g);await persistence(g)
	print("FARMING_COMPLETE five crops, hotbar actions, growth, irrigation, light, forage, recipes, cooking, food, travel and saves failures=",failures)
	quit(0 if failures==0 else 1)
