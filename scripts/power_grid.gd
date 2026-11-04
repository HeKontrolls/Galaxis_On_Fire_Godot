extends RefCounted
const C=preload("res://scripts/power_catalog.gd")
const Logic=preload("res://scripts/power_logic.gd")
const STEP:=0.1
static func prepare(data: Dictionary) -> void:
	if not data.has("nodes"):data.nodes={}
	if not data.has("links"):data.links=[]
	if not data.has("signals"):data.signals=[]
	if not data.has("budget"):data.budget=0.0
	for n:Dictionary in data.nodes.values():
		for pair in [["enabled",true],["powered",false],["q",false],["qb",true],["state",false],["prev_clk",false],["manual",false],["fuel_seconds",0.0],["burn_item",""],["work",0.0],["wet",false],["pulse",0.0],["sensed",false],["inverted",false]]:
			if not n.has(pair[0]):n[pair[0]]=pair[1]
		if not n.has("fuel"):n.fuel=[{},{},{},{}]
		if not n.has("defaults"):n.defaults={}
static func vertex(node: String,pin: String) -> String:return node+"|"+pin
static func input_values(data: Dictionary,node: String) -> Dictionary:
	var n:Dictionary=data.nodes[node];var result:={}
	for pin:String in C.inputs(str(n.item)):result[pin]=bool(n.get("defaults",{}).get(pin,C.default_input(str(n.item),pin)))
	for wire:Dictionary in data.signals:
		if str(wire.b)==node and data.nodes.has(str(wire.a)):
			var source:Dictionary=data.nodes[str(wire.a)]
			result[str(wire.bp)]=bool(source.get("q" if str(wire.ap)=="Q" else "qb",false)) and bool(source.get("powered",false))
	return result
static func _take_fuel(n: Dictionary) -> void:
	if float(n.fuel_seconds)>0.000001:return
	var fuels:Dictionary=C.FUELS[str(n.item)]
	for slot:Dictionary in n.fuel:
		if not slot.is_empty() and int(slot.get("count",0))>0 and fuels.has(str(slot.item)):
			n.burn_item=str(slot.item);n.fuel_seconds=float(fuels[str(slot.item)]);slot.count=int(slot.count)-1
			if int(slot.count)<=0:slot.clear()
			return
static func tick(data: Dictionary,dt: float) -> void:
	prepare(data)
	var nodes:Dictionary=data.nodes;var graph:={};var ordered:Array=nodes.keys();ordered.sort()
	var controls:={}
	for name:String in ordered:
		var n:Dictionary=nodes[name];controls[name]=input_values(data,name);n["inputs"]=controls[name]
		for pin:String in C.power_pins(str(n.item)):graph[vertex(name,pin)]=[]
	for wire:Dictionary in data.links:
		var a:=vertex(str(wire.a),str(wire.ap));var b:=vertex(str(wire.b),str(wire.bp))
		if graph.has(a) and graph.has(b):graph[a].append(b);graph[b].append(a)
	for name:String in ordered:
		var n:Dictionary=nodes[name]
		if (str(n.item) in C.SWITCHES and bool(n.enabled) and not bool(n.wet)) or (n.item=="Logic Output" and bool(n.q) and bool(n.powered)):
			var p:=vertex(name,"P");var l:=vertex(name,"L");graph[p].append(l);graph[l].append(p)
		# Reset outputs after the synchronous input snapshot has been read.
	for n:Dictionary in nodes.values():n.powered=false;n.active=false;n.grid=-1
	var seen:={};var grids:Array=[];var live:={}
	for start:String in graph:
		if seen.has(start):continue
		var stack:Array=[start];var members:Array=[];seen[start]=true
		while not stack.is_empty():
			var at:String=str(stack.pop_back());members.append(at)
			for next:String in graph[at]:
				if not seen.has(next):seen[next]=true;stack.append(next)
		var group:Array[String]=[]
		for point:String in members:
			var pieces:=point.split("|")
			if pieces[1]=="P":group.append(pieces[0])
		group.sort()
		var demand:=0.0;var consumers:Array[String]=[];var generators:Array[String]=[];var capacity:=0.0;var capacities:={}
		for name:String in group:
			var n:Dictionary=nodes[name];var item:=str(n.item);n.grid=grids.size()
			var enabled:bool=bool(n.enabled) and not bool(n.wet)
			if enabled and (not C.LIGHTS.has(item) or bool(controls[name].get("EN",true))):
				var watts:=C.cost(item)
				if watts>0:demand+=watts;consumers.append(name)
			if enabled and C.GENERATORS.has(item) and bool(controls[name].get("EN",true)):generators.append(name)
		for name:String in generators:
			var n:Dictionary=nodes[name]
			if demand>0:_take_fuel(n)
			var available:float=float(C.GENERATORS[str(n.item)])
			if dt>0:available*=minf(1.0,float(n.fuel_seconds)/dt)
			elif float(n.fuel_seconds)<=0:available=0
			capacity+=available;capacities[name]=available
		consumers.sort_custom(func(a: String,b: String)->bool:
			var ca:=C.cost(str(nodes[a].item));var cb:=C.cost(str(nodes[b].item))
			return ca<cb if ca!=cb else a<b)
		var supplied:=0.0
		for name:String in consumers:
			var watts:=C.cost(str(nodes[name].item))
			if supplied+watts<=capacity+0.000001:nodes[name].powered=true;supplied+=watts
		var nominal:=0.0
		for name:String in generators:
			if float(nodes[name].fuel_seconds)>0:nominal+=float(C.GENERATORS[str(nodes[name].item)])
		for name:String in generators:
			var n:Dictionary=nodes[name]
			if supplied>0 and nominal>0 and float(n.fuel_seconds)>0:
				n.active=true;n.powered=true;n.fuel_seconds=maxf(0,float(n.fuel_seconds)-dt*supplied/maxf(capacity,0.000001)*float(capacities[name])/float(C.GENERATORS[str(n.item)]))
		for point:String in members:live[point]=capacity>0
		grids.append({"capacity":capacity,"demand":demand,"served":supplied,"nodes":group.size()})
	for name:String in ordered:
		var n:Dictionary=nodes[name]
		if str(n.item)=="Push Button":n.pulse=maxf(0,float(n.pulse)-dt)
		if C.is_logic(str(n.item)):Logic.step(n,controls[name])
	data.grids=grids;data.live=live
static func advance(data: Dictionary,delta: float) -> void:
	prepare(data)
	if data.nodes.is_empty():data.budget=0;return
	data.budget=float(data.budget)+maxf(0,delta)
	while float(data.budget)+0.000001>=STEP:
		data.budget=maxf(0,float(data.budget)-STEP);tick(data,STEP)
