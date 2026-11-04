extends "res://tests/power_system_check.gd"
func mount(g,item: String,x: int,y:=99) -> String:
	if C.wall_mount(item) and not g.furnishings.wall_at(Vector2i(x,y)):check(g.furnishings.place(g,"Wooden Wall",Vector2i(x,y)),"Could not build backing wall for "+item)
	if item=="Ceiling Light":
		g._edit_tile(Vector2i(x,y-1),3);g._edit_tile(Vector2i(x+1,y-1),3)
	return device(g,item,x,y)
func cable(g,a: String,ap: String,b: String,bp: String,kind:="Wire") -> void:
	check(g.power.connect_ports({"node":a,"pin":ap},{"node":b,"pin":bp},kind),"Failed connection: %s %s -> %s %s" % [a,ap,b,bp])
func feed(g,name: String) -> void:
	g.power.data.nodes[name].fuel[0]={"item":"Raw Biomass","count":8};g.power.recompute()
func lights_and_switches(g) -> void:
	fresh(g)
	for item in ["Wall Light","Wall Switch","Push Button","Red Signal Lamp","Ceiling Light"]:
		check(not g.power.place(item,Vector2i(580,96)),"Unsupported fixture accepted: "+item)
	var gen:=device(g,"Biomass Generator",590);var sw:=mount(g,"Wall Switch",595)
	var names:Array[String]=[];var x:=599
	for item in ["Wall Light","Ceiling Light","Floodlight","Red Signal Lamp"]:
		names.append(mount(g,item,x));x+=4
	cable(g,gen,"P",sw,"P");var last:=sw
	for name in names:cable(g,last,"L" if last==sw else "P",name,"P");last=name
	feed(g,gen);g.power.update(0.1)
	for name in names:check(bool(g.power.data.nodes[name].powered) and g.power.device_frame(g.power.data.nodes[name]) in [1,2],"Fixture not lit: "+name)
	var grid:Dictionary=g.power.data.grids[int(g.power.data.nodes[gen].grid)]
	check(float(grid.demand)==41.0 and float(grid.served)==41.0,"Fixture loads did not add up to 41W")
	check(g.world.power_lights.size()==4,"New lights did not enter underground light map")
	var strengths:Array=[]
	for light:Dictionary in g.world.power_lights:strengths.append(float(light.strength))
	check(strengths.has(1.5) and strengths.has(0.45),"Floodlight/indicator light strength missing")
	var before:float=g.power.data.nodes[gen].fuel_seconds;g.power.update(10)
	check(absf(float(g.power.data.nodes[gen].fuel_seconds)-(before-4.1))<0.001,"New fixtures bypassed fuel accounting")
	press_f(g,sw)
	for name in names:check(not bool(g.power.data.nodes[name].powered) and g.power.device_frame(g.power.data.nodes[name])==0,"Off fixture retained its light/sprite: "+name)
	check(g.world.power_lights.is_empty(),"Wall switch left stale underground illumination")
	press_f(g,sw);check(g.world.power_lights.size()==4,"Wall switch failed to restore lights")
	g.water_sim.add_rain(Vector2i(595,99),200);g.power.recompute()
	check(g.world.power_lights.is_empty(),"Flooded wall switch still conducted power")
	g.water_sim.remove_units(99*WG.WIDTH+595,255);g.power.recompute()
	check(g.world.power_lights.size()==4,"Drained wall switch did not recover")
	g.player_pos=Vector2(599*16,1600-28);check(not g._collides(g.player_pos),"Wall fixture blocks player movement")
	# A ceiling fixture must fall if either of its two anchors is removed.
	g.world.drops.clear();g._edit_tile(Vector2i(603,98),0)
	check(not g.power.data.nodes.has(names[1]),"Ceiling light stayed suspended after losing its anchor")
	check(g.world.drops.filter(func(d):return d.item=="Ceiling Light").size()==1,"Ceiling light was duplicated/lost on support removal")
func automation(g) -> void:
	fresh(g)
	var gen:=device(g,"Biomass Generator",590);var button:=mount(g,"Push Button",595);var plate:=device(g,"Pressure Plate",598)
	var sensor:=device(g,"Daylight Sensor",602);var lamp:=device(g,"Floodlight",606);var memory:=device(g,"T Flip-Flop",610)
	var chain:Array[String]=[gen,button,plate,sensor,lamp,memory]
	for i in range(chain.size()-1):cable(g,chain[i],"P",chain[i+1],"P")
	feed(g,gen);cable(g,button,"Q",memory,"CLK","Logic Wire")
	press_f(g,button);g.power.update(0.2)
	check(bool(g.power.data.nodes[button].q) and bool(g.power.data.nodes[memory].q),"Push button did not clock the flip-flop")
	g.power.update(0.4)
	check(not bool(g.power.data.nodes[button].q) and bool(g.power.data.nodes[memory].q),"Button failed to release or double-toggled the clock")
	press_f(g,button);g.power.update(0.7)
	check(not bool(g.power.data.nodes[memory].q),"Second button press did not toggle flip-flop back")
	cable(g,plate,"Q",lamp,"EN","Logic Wire")
	g.player_pos=Vector2(598*16,1600-28);g.power.update(0.3)
	check(bool(g.power.data.nodes[plate].q) and bool(g.power.data.nodes[lamp].powered),"Standing on pressure plate did not enable light")
	g.player_pos.x=590*16;g.power.update(0.3)
	check(not bool(g.power.data.nodes[plate].q) and not bool(g.power.data.nodes[lamp].powered),"Pressure plate did not release")
	g.player_pos=Vector2(598*16,1550);g.power.update(0.3)
	check(not bool(g.power.data.nodes[plate].q),"Jumping above plate incorrectly triggered it")
	g.player_pos.x=590*16;g.world.npc={"x":598*16.0,"y":1571.0};g.power.update(0.3)
	check(bool(g.power.data.nodes[plate].q),"Robot could not trigger plate")
	g.world.erase("npc");g.world.creatures=[{"x":598*16.0,"y":1582.0,"hp":10,"alive":true}];g.power.update(0.3)
	check(bool(g.power.data.nodes[plate].q),"Creature could not trigger plate")
	g.world.creatures[0].alive=false;g.power.update(0.3)
	check(not bool(g.power.data.nodes[plate].q),"Dead creature held the plate down")
	g.world.creatures=[]
	cable(g,plate,"Q",lamp,"EN","Logic Wire") # Recover plate-to-lamp signal cable.
	cable(g,sensor,"Q",lamp,"EN","Logic Wire")
	g.time_of_day=0.25;g.power.update(0.3)
	check(bool(g.power.data.nodes[sensor].q) and bool(g.power.data.nodes[lamp].powered),"Daylight sensor did not detect open sky")
	g.time_of_day=0.75;g.power.update(0.3)
	check(not bool(g.power.data.nodes[sensor].q) and not bool(g.power.data.nodes[lamp].powered),"Daylight sensor stayed HIGH at night")
	press_f(g,sensor);g.power.update(0.3)
	check(bool(g.power.data.nodes[sensor].inverted) and bool(g.power.data.nodes[lamp].powered),"Night mode did not power automatic lighting")
	g.time_of_day=0.25;g.power.update(0.3)
	check(not bool(g.power.data.nodes[lamp].powered),"Night lighting stayed on during daylight")
	press_f(g,sensor);g._edit_tile(Vector2i(602,94),3);g.power.update(0.3)
	check(not bool(g.power.data.nodes[sensor].q),"Daylight sensor detected sunlight through solid roof")
	g._edit_tile(Vector2i(602,94),0)
	# Small light changes near dawn do not flicker the sensor.
	g.time_of_day=asin(0.2)/TAU;g.power.update(0.2)
	g.time_of_day=asin(0.15)/TAU;g.power.update(0.2);check(bool(g.power.data.nodes[sensor].q),"Daylight hysteresis failed on falling brightness")
	g.time_of_day=asin(0.1)/TAU;g.power.update(0.2)
	g.time_of_day=asin(0.15)/TAU;g.power.update(0.2);check(not bool(g.power.data.nodes[sensor].q),"Daylight hysteresis failed on rising brightness")
	# Away planets cannot retain a pressed plate when the player leaves.
	var away:Dictionary=g.world.duplicate(true);away.power.nodes[plate].sensed=true;away.power.nodes[plate].q=true
	g.worlds["fixture_away"]=away;g.power.update(0.3)
	check(not bool(away.power.nodes[plate].q),"Away pressure plate retained a stale actor")
	g.worlds.erase("fixture_away")
	press_f(g,sensor);g.power.update(0.2)
	press_f(g,button);g.power.update(0.2)
	var pulse:float=g.power.data.nodes[button].pulse
	g._save_game();var links:int=g.power.data.links.size();g._load_game()
	while g.scene_name=="loading":await process_frame
	check(g.power.data.links.size()==links and bool(g.power.data.nodes[sensor].inverted),"Fixture wires/night mode did not survive saving")
	check(absf(float(g.power.data.nodes[button].pulse)-pulse)<0.00001,"Button pulse remaining time changed during save/load")
	g.power.update(0.4);check(not bool(g.power.data.nodes[button].q),"Reloaded button pulse did not expire")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(g.save_path))
func crop_light(g) -> void:
	fresh(g)
	var gen:=device(g,"Biomass Generator",590);var lamp:=mount(g,"Red Signal Lamp",595)
	g._edit_tile(Vector2i(596,95),3);cable(g,gen,"P",lamp,"P");feed(g,gen)
	check(float(g.farming.growth_rate(Vector2i(596,99),PackedInt32Array(),0).rate)==0,"Tiny indicator lamp incorrectly grew crops")
	g.power.remove_node(lamp);lamp=mount(g,"Wall Light",595);cable(g,gen,"P",lamp,"P")
	check(float(g.farming.growth_rate(Vector2i(596,99),PackedInt32Array(),0).rate)==1,"Powered wall light did not grow covered crops")
func run() -> void:
	var g=load("res://main.tscn").instantiate();root.add_child(g);g.set_process(false);await process_frame
	g.save_path="user://power_fixtures_check.json";g.settings_path="user://power_fixtures_settings.json"
	lights_and_switches(g);await automation(g);crop_light(g)
	for item:String in C.FIXTURES:
		check(g.DevControls.POWER_KIT.has(item),"Fixture missing from developer kit: "+item)
	print("POWER_FIXTURES mounting, lighting, loads, switch isolation, button pulses, pressure actors, day/night automation, crops and saving failures=",failures)
	quit(0 if failures==0 else 1)
