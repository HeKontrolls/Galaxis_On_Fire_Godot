extends RefCounted
const C=preload("res://scripts/power_catalog.gd")
const Grid=preload("res://scripts/power_grid.gd")
const WG=preload("res://scripts/world_gen.gd")
const MAX_NODES:=256
const MAX_LINKS:=512
const RANGE:=256.0
var g
var data:Dictionary={}
var occupied:Dictionary={}
var pending:Dictionary={}
var textures:Dictionary={}
var icons:Dictionary={}
var sample_clock:=0.0
func bind(game) -> void:
	g=game;data=g.world.get("power",{});g.world["power"]=data;Grid.prepare(data)
	occupied.clear();pending.clear();sample_clock=0
	for name:String in data.nodes:
		_index(name,data.nodes[name])
	recompute()
static func key(cell: Vector2i) -> String:return "%d,%d" % [cell.x,cell.y]
func bounds(n: Dictionary) -> Rect2i:
	var size:=C.size(str(n.item));return Rect2i(Vector2i(int(n.x),int(n.y))-Vector2i(0,size.y-1),size)
func world_rect(n: Dictionary) -> Rect2:
	var box:=bounds(n);return Rect2(Vector2(box.position*16),Vector2(box.size*16))
func _index(name: String,n: Dictionary) -> void:
	var box:=bounds(n)
	for y in range(box.position.y,box.end.y):
		for x in range(box.position.x,box.end.x):occupied[Vector2i(x,y)]=name
func at(cell: Vector2i) -> Dictionary:return data.get("nodes",{}).get(occupied.get(cell,""),{})
func port_position(name: String,pin: String) -> Vector2:
	var n:Dictionary=data.nodes[name]
	return world_rect(n).position+Vector2(C.pins(str(n.item)).get(pin,Vector2.ZERO))
func port_access_position(name: String,pin: String) -> Vector2:
	if data.nodes[name].item=="Wood Power Pole" and pin=="P":return world_rect(data.nodes[name]).position+Vector2(8,112)
	return port_position(name,pin)
func icon(item: String) -> Texture2D:
	if not icons.has(item):
		var texture:=AtlasTexture.new();texture.atlas=C.texture(item);texture.region=Rect2(0,0,C.size(item).x*16,C.size(item).y*16)
		icons[item]=texture
	return icons[item]
func supported(n: Dictionary) -> bool:
	var box:=bounds(n);var item:=str(n.item);var cell:=Vector2i(int(n.x),int(n.y))
	if C.wall_mount(item) and g.furnishings.wall_at(cell):return true
	if item=="Ceiling Light":
		for x in range(box.position.x,box.end.x):
			if not WG.is_solid(WG.tile_at(g.world.tiles,x,box.position.y-1)):return false
		return true
	if item in ["Wall Light","Wall Switch","Push Button","Red Signal Lamp"]:
		return WG.is_solid(WG.tile_at(g.world.tiles,cell.x-1,cell.y)) or WG.is_solid(WG.tile_at(g.world.tiles,cell.x+1,cell.y))
	if item in ["Power Connector","Electric Lamp"]:
		for offset:Vector2i in [Vector2i.UP,Vector2i.DOWN,Vector2i.LEFT,Vector2i.RIGHT]:
			if WG.is_solid(WG.tile_at(g.world.tiles,cell.x+offset.x,cell.y+offset.y)):return true
	for x in range(box.position.x,box.end.x):
		if not WG.is_solid(WG.tile_at(g.world.tiles,x,box.end.y)):return false
	return true
func place(item: String,cell: Vector2i) -> bool:
	if not C.has_device(item) or data.nodes.size()>=MAX_NODES:return false
	if WG.is_solid(WG.tile_at(g.world.tiles,cell.x,cell.y)):cell+=Vector2i.UP
	var n:Dictionary={"item":item,"x":cell.x,"y":cell.y};var box:=bounds(n)
	if box.position.x<1 or box.position.y<1 or box.end.x>=WG.WIDTH-1 or box.end.y>=WG.HEIGHT-1:return false
	for y in range(box.position.y,box.end.y):
		for x in range(box.position.x,box.end.x):
			var point:=Vector2i(x,y)
			if WG.tile_at(g.world.tiles,x,y) not in [0,4] or occupied.has(point) or not g.furnishings.at(point).is_empty() or g.world.get("torches",{}).has(key(point)):
				g._show_notice("Choose clear space for "+item);return false
	if not supported(n):g._show_notice("Needs solid support or a built background wall");return false
	data.nodes[key(cell)]=n;Grid.prepare(data);_index(key(cell),n);recompute();g._show_notice("Placed "+item);return true
func wet(n: Dictionary) -> bool:
	var box:=bounds(n)
	for y in range(box.position.y,box.end.y):
		for x in range(box.position.x,box.end.x):
			if g.water_sim.amount_at(Vector2i(x,y))>96 or g.lava_sim.amount_at(Vector2i(x,y))>0:return true
	return false
func recompute() -> void:
	for n:Dictionary in data.nodes.values():n.wet=wet(n)
	sample_inputs(g.world,true);Grid.tick(data,0);refresh_lights()
static func light_values(state: Dictionary) -> Array:
	var lights:Array=[]
	for n:Dictionary in state.get("nodes",{}).values():
		if C.LIGHTS.has(str(n.item)) and bool(n.get("powered",false)):
			var spec:Dictionary=C.LIGHTS[str(n.item)];var size:=C.size(str(n.item))
			lights.append({"x":int(n.x)+int(size.x/2),"y":int(n.y)-int(size.y/2),"strength":float(spec.strength),"grow_radius":int(spec.grow_radius)})
	return lights
func sample_inputs(world: Dictionary,active: bool) -> void:
	for n:Dictionary in world.get("power",{}).get("nodes",{}).values():
		if n.item=="Daylight Sensor":
			var exposed:=true
			for y in range(int(n.y)):
				if WG.is_solid(WG.tile_at(world.tiles,int(n.x),y)):exposed=false;break
			# Separate on/off thresholds avoid flicker around sunrise and sunset.
			var daylight:=maxf(0,sin(g.time_of_day*TAU))
			n.sensed=exposed and daylight>(0.12 if bool(n.get("sensed",false)) else 0.18)
		elif n.item=="Pressure Plate":
			n.sensed=false
			if not active:continue
			var plate:=Rect2(Vector2(int(n.x)*16,int(n.y)*16+8),Vector2(32,9))
			if plate.intersects(Rect2(g.player_pos,Vector2(16,28))):n.sensed=true
			var robot:Dictionary=world.get("npc",{})
			if not robot.is_empty() and plate.intersects(Rect2(Vector2(float(robot.x),float(robot.y)),Vector2(16,29))):n.sensed=true
			for mob:Dictionary in world.get("creatures",[]):
				if not bool(mob.get("alive",true)) or float(mob.get("hp",1))<=0:continue
				if plate.intersects(Rect2(Vector2(float(mob.x),float(mob.y)),Vector2(20,18))):n.sensed=true;break
func refresh_lights() -> void:
	var lights:=light_values(data)
	if g.world.get("power_lights",[])!=lights:g.world["power_lights"]=lights;g.environment.invalidate()
func update(delta: float) -> void:
	if g==null or g.world.is_empty():return
	if not pending.is_empty() and g.place_items[g.selected_slot]!=str(pending.item):pending.clear()
	sample_clock+=delta
	var sample_due:=sample_clock>=0.1
	if sample_due:
		sample_clock=fmod(sample_clock,0.1)
		for n:Dictionary in data.nodes.values():n.wet=wet(n)
	for world:Dictionary in g.worlds.values():
		if world.has("power"):
			if sample_due:sample_inputs(world,is_same(world,g.world))
			Grid.advance(world.power,delta)
			if not is_same(world,g.world):world["power_lights"]=light_values(world.power)
	refresh_lights()
func target() -> String:
	var player:Vector2=g.player_pos+Vector2(8,14);var pointer:Vector2=g.mouse_aim_screen+g.camera_pos
	var best:="";var score:=INF
	for name:String in data.nodes:
		var box:=world_rect(data.nodes[name]);var distance:=player.distance_to(box.get_center())
		if distance>g.DIG_REACH or not g.interactions._visible(player,box):continue
		var value:=distance-(128.0 if box.grow(4).has_point(pointer) else 0.0)
		if value<score:score=value;best=name
	return best
func aimed() -> bool:
	var name:=target();return not name.is_empty() and world_rect(data.nodes[name]).grow(4).has_point(g.mouse_aim_screen+g.camera_pos)
func interact() -> bool:
	var name:=target()
	if name.is_empty():return false
	var n:Dictionary=data.nodes[name]
	g._stop_held_actions()
	if str(n.item) in C.SWITCHES:n.enabled=not bool(n.enabled);recompute();g._show_notice(str(n.item)+(" ON" if n.enabled else " OFF"))
	elif n.item=="Push Button":n.pulse=0.5;recompute();g._show_notice("Button pressed: pulse HIGH for 0.5s")
	elif n.item=="Daylight Sensor":n.inverted=not bool(n.inverted);recompute();g._show_notice("Sensor: "+("NIGHT mode" if n.inverted else "DAY mode"))
	elif n.item=="Logic Input":n.manual=not bool(n.manual);recompute();g._show_notice("Logic Input "+("HIGH" if n.manual else "LOW"))
	else:g.power_ui.open(name)
	return true
func nearest_port(point: Vector2,mode: String) -> Dictionary:
	var best:Dictionary={};var distance:=10.0
	for name:String in data.nodes:
		var n:Dictionary=data.nodes[name]
		for pin:String in C.pins(str(n.item)):
			var is_power:=pin in C.power_pins(str(n.item))
			if is_power!=(mode=="Wire"):continue
			for pos:Vector2 in [port_position(name,pin),port_access_position(name,pin)]:
				var d:=pos.distance_to(point)
				if d<distance and pos.distance_to(g.player_pos+Vector2(8,14))<=g.DIG_REACH and g.interactions._visible(g.player_pos+Vector2(8,14),Rect2(pos-Vector2(2,2),Vector2(4,4))):distance=d;best={"node":name,"pin":pin}
	return best
func connect_ports(a: Dictionary,b: Dictionary,item: String) -> bool:
	var kind:="links" if item=="Wire" else "signals"
	if not data.nodes.has(str(a.node)) or not data.nodes.has(str(b.node)) or a.node==b.node:g._show_notice("Choose terminals on two different devices");return false
	if port_position(str(a.node),str(a.pin)).distance_to(port_position(str(b.node),str(b.pin)))>RANGE:g._show_notice("Maximum cable span is 16 blocks; add a pole or connector");return false
	var first:Dictionary=data.nodes[str(a.node)];var second:Dictionary=data.nodes[str(b.node)]
	if item=="Wire":
		if str(a.pin) not in C.power_pins(str(first.item)) or str(b.pin) not in C.power_pins(str(second.item)):return false
	else:
		if str(a.pin) not in C.outputs(str(first.item)) or str(b.pin) not in C.inputs(str(second.item)):g._show_notice("Signal wire: choose an output first, then an input");return false
	var wires:Array=data[kind]
	for i in range(wires.size()):
		var wire:Dictionary=wires[i]
		var direct:bool=wire.a==a.node and wire.ap==a.pin and wire.b==b.node and wire.bp==b.pin
		var reverse:bool=item=="Wire" and wire.a==b.node and wire.ap==b.pin and wire.b==a.node and wire.bp==a.pin
		if direct or reverse:wires.remove_at(i);g._add_item(item,1);recompute();g._show_notice("Cable recovered");return true
	if item=="Logic Wire":
		for wire:Dictionary in wires:
			if wire.b==b.node and wire.bp==b.pin:g._show_notice("This input already has a driver. Remove its existing wire first");return false
	if data.links.size()+data.signals.size()>=MAX_LINKS:g._show_notice("Cable limit reached");return false
	if int(g.inventory.get(item,0))<=0:g._show_notice("No "+item+" in your backpack");return false
	g.inventory[item]=int(g.inventory[item])-1
	wires.append({"a":a.node,"ap":a.pin,"b":b.node,"bp":b.pin});recompute();g._show_notice("Connected "+item);return true
func wire_click(item: String,point: Vector2) -> void:
	var port:=nearest_port(point,item)
	if port.is_empty():g._show_notice("Aim at a gold power terminal" if item=="Wire" else "Aim at a labeled signal input/output");return
	if pending.is_empty():
		if item=="Logic Wire" and str(port.pin) not in C.outputs(str(data.nodes[str(port.node)].item)):g._show_notice("Choose green output Q/QB first");return
		pending={"node":port.node,"pin":port.pin,"item":item};g._show_notice("Cable start selected. Choose the destination; Esc cancels");return
	var start:=pending.duplicate();pending.clear();connect_ports(start,port,item)
func remove_node(name: String) -> void:
	if not data.nodes.has(name):return
	var n:Dictionary=data.nodes[name];var cell:=Vector2i(int(n.x),int(n.y));var box:=bounds(n)
	for y in range(box.position.y,box.end.y):
		for x in range(box.position.x,box.end.x):occupied.erase(Vector2i(x,y))
	for kind:String in ["links","signals"]:
		var wires:Array=data[kind]
		for i in range(wires.size()-1,-1,-1):
			if wires[i].a==name or wires[i].b==name:g._drop_item("Wire" if kind=="links" else "Logic Wire",1,cell);wires.remove_at(i)
	for slot:Dictionary in n.fuel:
		if not slot.is_empty():g._drop_item(str(slot.item),int(slot.count),cell)
	data.nodes.erase(name);g._drop_item(str(n.item),1,cell)
	if str(pending.get("node",""))==name:pending.clear()
	if g.power_ui.node_key==name:g.power_ui.close()
	recompute()
func terrain_changed(cell: Vector2i) -> void:
	for name:String in data.get("nodes",{}).keys():
		var n:Dictionary=data.nodes[name]
		if (bounds(n).has_point(cell) and WG.is_solid(WG.tile_at(g.world.tiles,cell.x,cell.y))) or not supported(n):remove_node(name)
func curve(wire: Dictionary) -> PackedVector2Array:
	var a:=port_position(str(wire.a),str(wire.ap));var b:=port_position(str(wire.b),str(wire.bp));var points:=PackedVector2Array()
	for i in range(17):
		var t:=i/16.0;points.append((a.lerp(b,t)+Vector2(0,sin(t*PI)*minf(10,a.distance_to(b)*0.06))).floor())
	return points
func harvest(cell: Vector2i) -> bool:
	var n:=at(cell)
	if not n.is_empty():
		if g.mining_cooldown>0:return true
		g.mining_cooldown=g.Tools.MINING_SWING
		n.work=float(n.work)+g.Tools.mining_damage(g.equipped_tool,9 if n.item=="Wood Power Pole" else 3)/24.0
		if float(n.work)>=0.99999:remove_node(str(occupied[cell]))
		return true
	if g.equipped_tool not in ["Hammer","Mattock"]:return false
	var point:Vector2=g.aim_screen+g.camera_pos
	for kind:String in ["links","signals"]:
		var wires:Array=data.get(kind,[])
		for i in range(wires.size()):
			var points:=curve(wires[i])
			for j in range(points.size()-1):
				if Geometry2D.get_closest_point_to_segment(point,points[j],points[j+1]).distance_to(point)<5:
					if g.mining_cooldown>0:return true
					g.mining_cooldown=g.Tools.MINING_SWING;wires.remove_at(i);g._drop_item("Wire" if kind=="links" else "Logic Wire",1,cell);recompute();return true
	return false
func draw() -> void:
	for kind:String in ["links","signals"]:
		for wire:Dictionary in data.get(kind,[]):
			if not data.nodes.has(str(wire.a)) or not data.nodes.has(str(wire.b)):continue
			var points:=curve(wire)
			for i in range(points.size()):points[i]-=g.camera_pos
			var on:=bool(data.get("live",{}).get(Grid.vertex(str(wire.a),str(wire.ap)),false)) if kind=="links" else bool(data.nodes[str(wire.a)].get("q" if wire.ap=="Q" else "qb",false))
			g.draw_polyline(points,Color("d8b56a") if kind=="links" and on else (Color("7be0c2") if on else Color("605b72")),1.0,false)
	for name:String in data.get("nodes",{}):
		var n:Dictionary=data.nodes[name];var rect:=world_rect(n);rect.position-=g.camera_pos
		if not rect.intersects(Rect2(-64,-64,1408,848)):continue
		var frame:=device_frame(n)
		if not textures.has(str(n.item)):textures[str(n.item)]=C.texture(str(n.item))
		g.draw_texture_rect_region(textures[str(n.item)],rect,Rect2(frame*rect.size.x,0,rect.size.x,rect.size.y))
		if g.place_items[g.selected_slot] in ["Wire","Logic Wire"] or g.dev_mode or g.power_ui.node_key==name:
			for pin:String in C.pins(str(n.item)):
				var point:Vector2=port_position(name,pin)-g.camera_pos
				g.draw_rect(Rect2(point-Vector2(2,2),Vector2(4,4)),Color("e5bd76") if pin in C.power_pins(str(n.item)) else (Color("79e4b4") if pin in C.outputs(str(n.item)) else Color("bfa4e2")))
				g._text(pin,point+Vector2(3,-3),9,Color("eff6f4"))
			if n.item=="Wood Power Pole":
				var access:Vector2=port_access_position(name,"P")-g.camera_pos
				g.draw_rect(Rect2(access-Vector2(2,2),Vector2(4,4)),Color("e5bd76"))
				g._text("P",access+Vector2(4,-3),9,Color("eff6f4"))
	if not pending.is_empty() and data.nodes.has(str(pending.node)):
		g.draw_line(port_position(str(pending.node),str(pending.pin))-g.camera_pos,g.aim_screen,Color("e3cf98"),1.0)
func device_frame(n: Dictionary) -> int:
	var item:=str(n.item)
	if bool(n.get("fault",false)) or bool(n.get("wet",false)):return 3
	var online:=bool(n.get("active",false)) if C.GENERATORS.has(item) else (bool(n.get("q",false)) if C.is_logic(item) else has_power(n))
	if item in C.SWITCHES:online=online and bool(n.enabled)
	return 1+posmod(int(g.animation_clock*5),2) if online else 0
func has_power(n: Dictionary) -> bool:
	if C.cost(str(n.item))==0 and not C.GENERATORS.has(str(n.item)):
		return bool(data.get("live",{}).get(Grid.vertex(key(Vector2i(int(n.x),int(n.y))),"P"),false))
	return bool(n.get("powered",false))
func draw_hint() -> void:
	if g.inventory_open or g.dev_mode:return
	var name:=target()
	if name.is_empty():return
	var n:Dictionary=data.nodes[name];var caption:="%s [F]  |  %s" % [n.item,"Wet - shut down" if bool(n.wet) else ("Powered" if has_power(n) else "No power / idle")]
	g._button_text(Rect2(300,575,680,27),caption,14,Color("d9d1ad"),true)
