extends RefCounted
const C=preload("res://scripts/power_catalog.gd")
const Slots=preload("res://scripts/station_slots.gd")
const Logic=preload("res://scripts/power_logic.gd")
const SIZE:=Vector2(650,412)
var g
var node_key:=""
func _init(game) -> void:g=game
func is_open() -> bool:return not node_key.is_empty() and g.scene_name=="planet" and g.inventory_open and g.power.data.get("nodes",{}).has(node_key)
func close(close_pack:=true) -> void:
	node_key=""
	g._cancel_inventory_drag()
	if close_pack:g.inventory_open=false
	g.dragged_window=""
func node() -> Dictionary:return g.power.data.get("nodes",{}).get(node_key,{})
func open(name: String) -> void:
	g.magic.codex_open=false
	g.alchemy.close(false)
	g.stations.close(false);g.interactions.close(false);g._cancel_inventory_drag();g._stop_held_actions()
	node_key=name;g.inventory_open=true;g.crafting_open=false;g.dialogue_open=false
	if not g.window_positions.has("power"):g.window_positions.power=Vector2(24,178)
	g.window_positions.inventory=Vector2(790,190)
func local_rect(rect: Rect2) -> Rect2:return Rect2(Vector2(g.window_positions.power)+rect.position,rect.size)
func fuel_rect(index: int) -> Rect2:return local_rect(Rect2(24+index*62,118,54,54))
func deposit(item: String,count: int=-1,index: int=-1) -> bool:
	if not is_open() or not C.GENERATORS.has(str(node().item)):return false
	var n:=node()
	if not C.FUELS[str(n.item)].has(item):g._show_notice("This generator accepts: "+", ".join(C.FUELS[str(n.item)].keys()));return false
	var available:=int(g.inventory.get(item,0));var amount:=available if count<0 else mini(available,count)
	if index<0:index=Slots.free_slot(n.fuel,item)
	if amount<=0 or not Slots.accepts(n.fuel,index,item):return false
	Slots.put(n.fuel,index,item,amount);g.inventory[item]=available-amount;g._refresh_hotbar();g.power.recompute();return true
func withdraw(index: int,count: int=-1) -> bool:
	if not is_open() or index<0 or index>=node().fuel.size():return false
	var slot:Dictionary=node().fuel[index]
	if slot.is_empty():return false
	var stack:=Slots.take(node().fuel,index,count)
	if not stack.is_empty():g._add_item(str(stack.item),int(stack.count));return true
	return false
func accepts_drag(point: Vector2,item: String) -> bool:
	if not is_open():return false
	for i in range(4):
		if fuel_rect(i).has_point(point):deposit(item,-1,i);return true
	return false
func click(point: Vector2,button: int) -> bool:
	if not is_open() or not local_rect(Rect2(Vector2.ZERO,SIZE)).has_point(point):return false
	if button==MOUSE_BUTTON_LEFT and local_rect(Rect2(614,6,28,28)).has_point(point):close();return true
	if button==MOUSE_BUTTON_LEFT and local_rect(Rect2(0,0,610,40)).has_point(point):g._start_window_drag("power",point);return true
	var n:=node();var item:=str(n.item)
	if C.GENERATORS.has(item):
		for i in range(4):
			if fuel_rect(i).has_point(point):withdraw(i,1 if button==MOUSE_BUTTON_RIGHT else -1);return true
		if button==MOUSE_BUTTON_LEFT and local_rect(Rect2(24,310,160,34)).has_point(point):n.enabled=not bool(n.enabled);g.power.recompute()
	else:
		if button==MOUSE_BUTTON_LEFT and local_rect(Rect2(24,130,250,34)).has_point(point):
			if item=="Push Button":n.pulse=0.5;g.power.recompute()
			elif item=="Daylight Sensor":n.inverted=not bool(n.inverted);g.power.recompute()
		var pins:=C.inputs(item)
		for i in range(pins.size()):
			if button==MOUSE_BUTTON_LEFT and local_rect(Rect2(24,130+i*44,250,34)).has_point(point):
				var wired:=false
				for wire:Dictionary in g.power.data.signals:
					if wire.b==node_key and wire.bp==pins[i]:wired=true
				if not wired:n.defaults[pins[i]]=not bool(n.defaults.get(pins[i],C.default_input(item,pins[i])));g.power.recompute()
	if button==MOUSE_BUTTON_LEFT and local_rect(Rect2(200,310,190,34)).has_point(point):
		for kind:String in ["links","signals"]:
			var wires:Array=g.power.data[kind]
			for i in range(wires.size()-1,-1,-1):
				if wires[i].a==node_key or wires[i].b==node_key:wires.remove_at(i);g._add_item("Wire" if kind=="links" else "Logic Wire",1)
		g.power.recompute()
	return true
func text(value: String,at: Vector2,size:=15,color:=Color("ccdade")) -> void:g._text(value,Vector2(g.window_positions.power)+at,size,color)
func button(rect: Rect2,label: String,enabled:=true) -> void:
	g._rounded_box(local_rect(rect),Color("26424d") if enabled else Color("192731"),Color("779899"),6,1)
	g._button_text(local_rect(rect),label,16,Color("ead8ac") if enabled else Color("7d909b"),true)
func draw() -> void:
	if not is_open():return
	var n:=node();var item:=str(n.item);var p:Vector2=g.window_positions.power
	g._rounded_box(Rect2(p,SIZE),Color("101e28"),Color("b29e76"),9,1)
	g._draw_item_icon(item,Rect2(p+Vector2(14,5),Vector2(30,30)))
	text(item+"  [F / Esc to close]",Vector2(52,28),18,Color("ead8ac"));button(Rect2(614,6,28,28),"X")
	g._button_text(local_rect(Rect2(22,45,600,36)),C.description(item),14,Color("a9c4cc"),false)
	text("Power: "+("ON" if g.power.has_power(n) else "OFF")+("  |  WET: device shut down" if bool(n.wet) else ""),Vector2(24,100),15)
	if C.GENERATORS.has(item):
		for i in range(4):
			var rect:=fuel_rect(i);g._rounded_box(rect,Color("1c303c"),Color("7f9297"),5,1)
			var slot:Dictionary=n.fuel[i]
			if not slot.is_empty():g._draw_item_icon(str(slot.item),Rect2(rect.position+Vector2(8,5),Vector2(36,36)));g._text(str(slot.count),rect.position+Vector2(32,48),12,Color.WHITE)
		text("Enable: "+("HIGH" if bool(n.get("inputs",{}).get("EN",true)) else "LOW"),Vector2(350,140),14)
		text("Output: "+("ACTIVE" if bool(n.active) else "IDLE"),Vector2(350,168),14)
		text("Fuel reserve: %.1fs at full load" % float(n.fuel_seconds),Vector2(24,202))
		text("Burning: "+str(n.burn_item if not str(n.burn_item).is_empty() else "Nothing"),Vector2(24,230))
		g._button_text(local_rect(Rect2(24,242,600,40)),"Accepts: "+", ".join(C.FUELS[item].keys()),14,Color("a9c4cc"),false)
		button(Rect2(24,310,160,34),"Generator "+("ON" if n.enabled else "OFF"))
	else:
		if item=="Push Button":button(Rect2(24,130,250,34),"Press: 0.5s pulse")
		elif item=="Daylight Sensor":button(Rect2(24,130,250,34),"Mode: "+("NIGHT" if n.inverted else "DAY"))
		elif item=="Pressure Plate":text("Plate: "+("PRESSED" if n.sensed else "RELEASED"),Vector2(24,154),17)
		var pins:=C.inputs(item)
		for i in range(pins.size()):
			var wired:=false
			for wire:Dictionary in g.power.data.signals:
				if wire.b==node_key and wire.bp==pins[i]:wired=true
			var value:bool=bool(n.get("inputs",{}).get(pins[i],C.default_input(item,pins[i])))
			button(Rect2(24,130+i*44,250,34),pins[i]+": "+("HIGH" if value else "LOW")+(" (wired)" if wired else " (test)"),not wired)
		if "QB" in C.outputs(item):text("Q: %d   QB: %d" % [int(bool(n.q)),int(bool(n.qb))],Vector2(24,244),17)
		elif "Q" in C.outputs(item):text("Q: %d" % int(bool(n.q)),Vector2(24,244),17)
		else:text("Bus: "+("energized" if g.power.has_power(n) else "unpowered"),Vector2(24,244),17)
		if bool(n.get("fault",false)):text("INVALID INPUT COMBINATION",Vector2(24,274),15,Color("eb8e79"))
		var truth:PackedStringArray=[]
		if item in ["NOT Gate","AND Gate","OR Gate","XOR Gate","NAND Gate","NOR Gate"]:
			truth.append("A  B  |  Q")
			for a in [false,true]:
				for b in [false,true]:truth.append("%d  %d  |  %d" % [int(a),int(b),int(Logic.evaluate(item,a,b))])
		elif item=="RS NOR Latch":truth=["S R | Action","0 0 | Hold","1 0 | Set","0 1 | Reset","1 1 | Invalid"]
		elif item=="RS NAND Latch":truth=["S R | Action","1 1 | Hold","0 1 | Set","1 0 | Reset","0 0 | Invalid"]
		elif item=="T Flip-Flop":truth=["CLK rising + T HIGH:","Toggle remembered Q","Held CLK: hold","T LOW: hold"]
		elif item=="Push Button":truth=["F: emit one short pulse","Wire Q to CLK / EN","Requires power at P"]
		elif item=="Pressure Plate":truth=["Player / robot / mobs","on plate: Q HIGH","Released: Q LOW"]
		elif item=="Daylight Sensor":truth=["Needs open sky","DAY: HIGH in daylight","NIGHT: inverse of DAY"]
		else:truth=["Gold P/L: electricity","Green Q/QB: outputs","Purple: signal inputs"]
		for i in range(truth.size()):text(truth[i],Vector2(325,136+i*27),15)
	button(Rect2(200,310,190,34),"Disconnect cables")
	var grid:Dictionary={};var index:=int(n.get("grid",-1))
	if index>=0 and index<g.power.data.get("grids",[]).size():grid=g.power.data.grids[index]
	text("Grid: %.0fW capacity | %.0fW demand | %.0fW supplied" % [grid.get("capacity",0),grid.get("demand",0),grid.get("served",0)],Vector2(24,374),14)
	text("Click backpack fuel to store; right-click stores one. Click a slot to withdraw." if C.GENERATORS.has(item) else "Gold P/L: power. Signal inputs can be tested only while unwired.",Vector2(24,399),12,Color("9bb8c2"))
