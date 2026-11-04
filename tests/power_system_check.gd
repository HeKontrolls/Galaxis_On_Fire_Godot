extends "res://tests/housing_check.gd"
const C=preload("res://scripts/power_catalog.gd")
const Logic=preload("res://scripts/power_logic.gd")
const Grid=preload("res://scripts/power_grid.gd")
const Slots=preload("res://scripts/station_slots.gd")
func logic_checks() -> void:
	var truth:={"NOT Gate":[true,true,false,false],"AND Gate":[false,false,false,true],"OR Gate":[false,true,true,true],"XOR Gate":[false,true,true,false],"NAND Gate":[true,true,true,false],"NOR Gate":[true,false,false,false]}
	for item:String in truth:
		for i in range(4):
			var n:={"item":item,"powered":true};Logic.step(n,{"A":i>=2,"B":i%2==1})
			check(bool(n.q)==bool(truth[item][i]),"Truth table failed: %s row %d" % [item,i])
	for item in ["RS NOR Latch","RS NAND Latch"]:
		var low:bool=item=="RS NAND Latch";var n:={"item":item,"powered":true,"state":false}
		Logic.step(n,{"S":not low,"R":low});check(bool(n.q) and not bool(n.qb),"Latch set failed: "+item)
		Logic.step(n,{"S":low,"R":low});check(bool(n.q),"Latch failed to hold: "+item)
		Logic.step(n,{"S":low,"R":not low});check(not bool(n.q) and bool(n.qb),"Latch reset failed: "+item)
		Logic.step(n,{"S":not low,"R":not low});check(bool(n.fault) and bool(n.q)==low and bool(n.qb)==low,"Latch forbidden input was not exposed: "+item)
		Logic.step(n,{"S":low,"R":low});check(not bool(n.fault) and not bool(n.q),"Latch deterministic recovery failed: "+item)
	var t:={"item":"T Flip-Flop","powered":true,"state":false,"prev_clk":false}
	Logic.step(t,{"T":true,"CLK":true});check(bool(t.q),"T flip-flop did not toggle on rising CLK")
	for i in range(10):Logic.step(t,{"T":true,"CLK":true})
	check(bool(t.q),"T flip-flop toggled repeatedly on a held clock")
	Logic.step(t,{"T":true,"CLK":false});Logic.step(t,{"T":true,"CLK":true});check(not bool(t.q),"Second rising edge did not toggle T flip-flop")
	Logic.step(t,{"T":false,"CLK":false});Logic.step(t,{"T":false,"CLK":true});check(not bool(t.q),"T LOW did not inhibit toggling")
	t.powered=false;Logic.step(t,{"T":true,"CLK":true});check(not bool(t.q) and not bool(t.qb),"Unpowered logic emitted a signal")
	var saved:Dictionary=JSON.parse_string(JSON.stringify(t));saved.powered=true;Logic.step(saved,{"T":true,"CLK":true});check(not bool(saved.q),"Loading a held clock created a false edge")
	print("POWER_LOGIC all truth tables, latch states, invalid inputs and edge-triggered T flip-flop checked")
func model() -> void:
	var d:={"nodes":{"gen":{"item":"Biomass Generator","fuel_seconds":35.0}},"links":[],"signals":[]}
	for i in range(12):
		var name:="lamp%d" % i;d.nodes[name]={"item":"Electric Lamp"};d.links.append({"a":"gen","ap":"P","b":name,"bp":"P"})
	Grid.tick(d,1.0)
	var lit:=0
	for n:Dictionary in d.nodes.values():
		if n.item=="Electric Lamp" and bool(n.powered):lit+=1
	check(lit==10 and absf(float(d.nodes.gen.fuel_seconds)-34)<0.00001,"Overload allocation or full-load fuel accounting failed")
	d.nodes.coal={"item":"Coal Generator","fuel_seconds":120.0};d.links.append({"a":"gen","ap":"P","b":"coal","bp":"P"});d.nodes.gen.fuel_seconds=0.03
	var before:float=float(d.nodes.gen.fuel_seconds)*100+float(d.nodes.coal.fuel_seconds)*300
	Grid.tick(d,1.0)
	var after:float=float(d.nodes.gen.fuel_seconds)*100+float(d.nodes.coal.fuel_seconds)*300
	check(absf(before-after-120)<0.001,"Mixed generators created or lost energy near fuel depletion")
	var idle:={"nodes":{"gen":{"item":"Biomass Generator","fuel":[{"item":"Raw Biomass","count":2},{},{},{}]}},"links":[],"signals":[]}
	Grid.advance(idle,30)
	check(float(idle.nodes.gen.fuel_seconds)==0 and int(idle.nodes.gen.fuel[0].count)==2,"Idle generator consumed queued fuel")
	var a:Dictionary=d.duplicate(true);var b:Dictionary=d.duplicate(true)
	Grid.advance(a,5)
	for frame in range(300):Grid.advance(b,1.0/60)
	check(absf(float(a.nodes.coal.fuel_seconds)-float(b.nodes.coal.fuel_seconds))<0.00001,"Power generation depends on frame rate")
	var relay:={"nodes":{"g":{"item":"Biomass Generator","fuel_seconds":35.0},"i":{"item":"Logic Input","manual":false},"r":{"item":"Logic Output"},"l":{"item":"Electric Lamp"}},"links":[{"a":"g","ap":"P","b":"i","bp":"P"},{"a":"g","ap":"P","b":"r","bp":"P"},{"a":"r","ap":"L","b":"l","bp":"P"}],"signals":[{"a":"i","ap":"Q","b":"r","bp":"IN"}]}
	Grid.advance(relay,0.4);check(not bool(relay.nodes.l.powered),"LOW signal did not isolate an output relay")
	relay.nodes.i.manual=true;Grid.advance(relay,0.4);check(bool(relay.nodes.l.powered),"HIGH signal did not close the P-to-L relay")
	relay.nodes.i.manual=false;Grid.advance(relay,0.4);check(not bool(relay.nodes.l.powered),"Output relay did not reopen")
	var flip:={"nodes":{"g":{"item":"Biomass Generator","fuel_seconds":35.0},"i":{"item":"Logic Input","manual":true},"t":{"item":"T Flip-Flop"}},"links":[{"a":"g","ap":"P","b":"i","bp":"P"},{"a":"g","ap":"P","b":"t","bp":"P"}],"signals":[{"a":"i","ap":"Q","b":"t","bp":"CLK"}]}
	Grid.advance(flip,0.5);check(bool(flip.nodes.t.state),"Powered clock network did not trigger the T flip-flop")
	var restored:Dictionary=JSON.parse_string(JSON.stringify(flip));Grid.tick(restored,0);Grid.advance(restored,1)
	check(bool(restored.nodes.t.state),"Reloading a powered clock network created a false toggle")

	var feedback:={"nodes":{"g":{"item":"Biomass Generator","fuel_seconds":35.0},"a":{"item":"NOT Gate"},"b":{"item":"NOT Gate"}},"links":[{"a":"g","ap":"P","b":"a","bp":"P"},{"a":"g","ap":"P","b":"b","bp":"P"}],"signals":[{"a":"a","ap":"Q","b":"b","bp":"A"},{"a":"b","ap":"Q","b":"a","bp":"A"}]}
	Grid.advance(feedback,2)
	check(bool(feedback.nodes.a.q)==bool(feedback.nodes.b.q) and absf(float(feedback.nodes.g.fuel_seconds)-34.96)<0.00001,"Combinational feedback did not remain bounded and synchronous")
	print("POWER_GRID overload, load sharing, exact fuel energy, idle conservation and frame rates checked")
func fresh(g) -> void:
	fixture(g);g.expedition.data.clear();g.world["drops"]=[];g.world["torches"]={};g.equipped_tool="Hand"
	g.inventory["Wire"]=128;g.inventory["Logic Wire"]=128
func device(g,item: String,x: int,y:=99) -> String:
	g.player_pos=Vector2((x-1)*16,1600-28);g._update_camera();select(g,item)
	g._place(Vector2(x*16+8,y*16+8)-g.camera_pos)
	var name:="%d,%d" % [x,y]
	check(g.power.data.nodes.has(name),"Device placement failed: "+item)
	return name
func wire(g,a: String,ap: String,b: String,bp: String,item: String="Wire") -> void:
	var count:int=g.inventory[item];select(g,item,count)
	for endpoint in [{"node":a,"pin":ap},{"node":b,"pin":bp}]:
		var n:Dictionary=g.power.data.nodes[str(endpoint.node)]
		g.player_pos=Vector2((int(n.x)-1)*16,1600-28);g._update_camera()
		var at:Vector2=g.power.port_access_position(str(endpoint.node),str(endpoint.pin))
		g.aim_screen=at-g.camera_pos;g._set_mouse_world_target(at);g._place(g.aim_screen)
	check(g.power.pending.is_empty(),"Second wire click did not finish the connection")
func press_f(g,name: String) -> void:
	var n:Dictionary=g.power.data.nodes[name]
	g.player_pos=Vector2((int(n.x)-1)*16,1600-28);g._update_camera();g._set_mouse_world_target(g.power.world_rect(n).get_center());g._key_pressed(KEY_F)
func integration(g) -> void:
	fresh(g)
	var gen:=device(g,"Biomass Generator",590);var pole:=device(g,"Wood Power Pole",596);var lamp:=device(g,"Electric Lamp",602)
	wire(g,gen,"P",pole,"P");wire(g,pole,"P",lamp,"P")
	check(g.power.data.links.size()==2 and int(g.inventory.Wire)==126,"Power cables were not consumed exactly once")
	check(g.power.world_rect(g.power.data.nodes[pole]).size.y==128,"Power pole is not eight blocks tall")
	check(g.power.port_position(pole,"P").y<g.power.port_access_position(pole,"P").y-100,"Pole cables no longer attach overhead")
	var far:=device(g,"Wood Power Pole",629)
	check(not g.power.connect_ports({"node":gen,"pin":"P"},{"node":far,"pin":"P"},"Wire") and int(g.inventory.Wire)==126,"Oversized cable span was accepted or consumed an item")
	check(not g._collides(Vector2(590*16,1600-28)),"Electrical machinery blocked walking")
	press_f(g,gen);check(g.power_ui.is_open() and g.inventory_open,"F did not open generator's own fuel window")
	g.inventory["Raw Biomass"]=3;g.inventory["Coal Ore"]=2
	check(not g.power_ui.deposit("Coal Ore",1) and g.inventory["Coal Ore"]==2,"Biomass generator accepted incompatible fuel")
	check(g.power_ui.deposit("Raw Biomass",2),"Fuel could not be stored in generator slots")
	check(bool(g.power.data.nodes[lamp].powered) and g.world.power_lights.size()==1,"Generator did not power its lamp or seed cave lighting")
	g.power.update(10)
	check(absf(float(g.power.data.nodes[gen].fuel_seconds)-34)<0.0001,"Generator did not use fuel in proportion to its 10W load")
	check(g.power_ui.withdraw(0,1) and g.inventory["Raw Biomass"]==2,"Unburnt fuel could not be recovered from storage")
	g._key_pressed(KEY_F);check(not g.power_ui.is_open() and not g.inventory_open,"F did not close generator window")
	var away:Dictionary=g.world.duplicate(true)
	away.power.nodes[gen].fuel_seconds=0;away.power.nodes[gen].fuel=[{},{},{},{}]
	g.worlds["power_away_check"]=away;g.power.update(0.2)
	check(away.get("power_lights",[]).is_empty(),"An away planet retained electric crop light after its fuel ran out")
	g.worlds.erase("power_away_check")
	var start:=float(g.power.data.nodes[gen].fuel_seconds)
	wire(g,pole,"P",lamp,"P")
	check(g.power.data.links.size()==1 and int(g.inventory.Wire)==127,"Reconnecting existing cable should remove it and refund exactly one Wire")
	g.power.update(10);check(absf(float(g.power.data.nodes[gen].fuel_seconds)-start)<0.00001,"Disconnected generator continued burning fuel")
	var sw:=device(g,"Power Switch",599);wire(g,pole,"P",sw,"P");wire(g,sw,"L",lamp,"P")
	check(bool(g.power.data.nodes[lamp].powered),"Closed power switch did not conduct between P and L")
	press_f(g,sw);check(not bool(g.power.data.nodes[lamp].powered) and g.world.power_lights.is_empty(),"Open switch did not isolate its load")
	press_f(g,sw);check(bool(g.power.data.nodes[lamp].powered),"Switch could not restore power")
	g._edit_tile(Vector2i(603,95),33)
	check(float(g.farming.growth_rate(Vector2i(603,99),PackedInt32Array(),0).rate)==1,"Powered lamp did not illuminate an indoor crop area")
	g.water_sim.add_rain(Vector2i(591,98),200);g.power.recompute()
	var reserve:float=g.power.data.nodes[gen].fuel_seconds;g.power.update(1)
	check(not bool(g.power.data.nodes[lamp].powered) and bool(g.power.data.nodes[gen].wet) and absf(float(g.power.data.nodes[gen].fuel_seconds)-reserve)<0.00001,"Flooded generator kept running or burning fuel")
	g.water_sim.remove_units(98*WG.WIDTH+591,255);g.power.recompute()
	check(bool(g.power.data.nodes[lamp].powered),"Drained generator did not resume power")
	press_f(g,sw);check(float(g.farming.growth_rate(Vector2i(603,99),PackedInt32Array(),0).rate)==0,"Unpowered lamp still grew indoor crops")
	# Full device footprint cannot overlap furniture, crops or blocks; unsupported devices return once.
	g.world.drops.clear();g._edit_tile(Vector2i(590,100),0)
	check(not g.power.data.nodes.has(gen) and g.world.drops.filter(func(d):return str(d.item)=="Biomass Generator").size()==1,"Removing generator support did not recover exactly one device")
	check(g.power.data.links.size()==2,"Removing a node did not remove its incident cables")
func signals(g) -> void:
	fresh(g)
	var gen:=device(g,"Biomass Generator",590);var ia:=device(g,"Logic Input",595);var ib:=device(g,"Logic Input",597);var gate:=device(g,"AND Gate",600);var lamp:=device(g,"Electric Lamp",605)
	wire(g,gen,"P",ia,"P");wire(g,ia,"P",ib,"P");wire(g,ib,"P",gate,"P");wire(g,gate,"P",lamp,"P")
	g.power.data.nodes[gen].fuel[0]={"item":"Raw Biomass","count":3};g.power.recompute()
	wire(g,ia,"Q",gate,"A","Logic Wire");wire(g,ib,"Q",gate,"B","Logic Wire");wire(g,gate,"Q",lamp,"EN","Logic Wire")
	g.power.update(0.4);check(not bool(g.power.data.nodes[lamp].powered),"AND output was high with both inputs low")
	press_f(g,ia);g.power.update(0.4);check(not bool(g.power.data.nodes[lamp].powered),"AND output was high with only one input")
	press_f(g,ib);g.power.update(0.4);check(bool(g.power.data.nodes[lamp].powered),"Two high inputs did not enable the lamp through AND")
	press_f(g,ia);g.power.update(0.3)
	check(not bool(g.power.data.nodes[lamp].inputs.EN),"Lamp inspector did not receive the actual wired enable level")
	press_f(g,ia);g.power.update(0.3)
	var count:int=g.inventory["Logic Wire"]
	check(not g.power.connect_ports({"node":ib,"pin":"Q"},{"node":gate,"pin":"A"},"Logic Wire") and int(g.inventory["Logic Wire"])==count,"An input accepted a second driver or spent wire on a failed connection")
	check(not g.power.connect_ports({"node":ia,"pin":"Q"},{"node":gate,"pin":"P"},"Logic Wire"),"Signal wire connected to an electrical power terminal")
	press_f(g,gate);check(g.power_ui.is_open(),"Gate inspector could not be opened with F")
	g._key_pressed(KEY_ESCAPE);check(not g.power_ui.is_open() and not g.paused,"Escape did not close the inspector before pausing")
	g._save_game();var state:Dictionary=g.power.data.duplicate(true);g._load_game()
	while g.scene_name=="loading":await process_frame
	check(g.power.data.nodes.size()==state.nodes.size() and g.power.data.signals==JSON.parse_string(JSON.stringify(state.signals)),"Power nodes or signal cables changed on save/load")
	check(bool(g.power.data.nodes[lamp].powered) and bool(g.power.data.nodes[gate].q),"Loaded circuit did not restore its live output")
	check(absf(float(g.power.data.nodes[gen].fuel_seconds)-float(state.nodes[gen].fuel_seconds))<0.00001,"Fuel reserve changed on save/load")
	g.inventory["Wire"]=20;g.inventory["Logic Wire"]=20
	var id:=device(g,"T Flip-Flop",609);g.power.data.nodes[id].state=true;g.power.data.nodes[id].prev_clk=true
	g._save_game();g._load_game()
	while g.scene_name=="loading":await process_frame
	check(bool(g.power.data.nodes[id].state),"Flip-flop remembered state was lost in a saved world")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(g.save_path))
func fuel_crafting(g) -> void:
	fresh(g)
	for item in ["Biomass Generator","Coal Generator","Fuel Generator"]:
		var name:=device(g,item,590)
		g.power_ui.open(name)
		for fuel:String in C.FUELS[item]:g.inventory[fuel]=2;check(g.power_ui.deposit(fuel,1),"Generator rejected its fuel: "+item+" / "+fuel)
		g.power_ui.close();g.power.remove_node(name)
	for index in range(62,g.RECIPES.size()):
		var recipe:Dictionary=g.RECIPES[index]
		if str(recipe.get("station",""))=="Furnace":continue
		g.stations.open({"name":"Workbench","tile":Vector2i(602,99)})
		var machine:Dictionary=g.stations.state();machine.inputs=Slots.create(9);machine.output={}
		for item:String in recipe.needs:g.inventory[item]=recipe.needs[item];g.stations.deposit(item,int(recipe.needs[item]))
		check(g.stations.craft(index) and int(machine.output.get(recipe.out,0))==int(recipe.count),"Electrical crafting recipe failed: "+str(recipe.out))
		g.stations.close()
	for output in ["Biofuel","Refined Fuel"]:
		var recipe:Dictionary={}
		for entry:Dictionary in g.RECIPES:
			if entry.out==output:recipe=entry
		g.stations.open({"name":"Furnace","tile":Vector2i(603,99)})
		var furnace:Dictionary=g.stations.state();furnace.inputs=Slots.create(6);furnace.fuel=Slots.create(1);furnace.output={};furnace.jobs=[];furnace.heat=0
		for item:String in recipe.needs:g.inventory[item]=recipe.needs[item];g.stations.deposit(item,int(recipe.needs[item]))
		g.furnaces.update(5);check(furnace.output.is_empty(),"Fuel refining skipped furnace warmup")
		g.furnaces.update(float(g.FurnaceSystem.TIMES[output]));check(int(furnace.output.get(output,0))==int(recipe.count),"Furnace fuel processing failed: "+output)
		g.stations.close()
func run() -> void:
	logic_checks();model()
	var g=load("res://main.tscn").instantiate();root.add_child(g);g.set_process(false);await process_frame
	g.save_path="user://power_system_check.json";g.settings_path="user://power_system_settings.json"
	integration(g);await signals(g);fuel_crafting(g)
	print("POWER_SYSTEM generation, fuel, physical/signal wiring, switches, lamps, crops, storage, logic, crafting, saves failures=",failures)
	quit(0 if failures==0 else 1)
