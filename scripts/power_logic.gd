extends RefCounted
const C=preload("res://scripts/power_catalog.gd")
static func evaluate(item: String,a: bool,b: bool) -> bool:
	match item:
		"NOT Gate":return not a
		"AND Gate":return a and b
		"OR Gate":return a or b
		"XOR Gate":return a!=b
		"NAND Gate":return not (a and b)
		"NOR Gate":return not (a or b)
	return a
static func step(node: Dictionary,inputs: Dictionary) -> void:
	var item:=str(node.item)
	var a:=bool(inputs.get("A",false));var b:=bool(inputs.get("B",false))
	var powered:=bool(node.get("powered",false))
	node["inputs"]=inputs;node["fault"]=false
	if not powered:
		node.q=false;node.qb=false
		if item=="T Flip-Flop":node.prev_clk=bool(inputs.get("CLK",false))
		return
	if item in ["RS NOR Latch","RS NAND Latch"]:
		var s:=bool(inputs.get("S",false));var r:=bool(inputs.get("R",false));var active_low:=item=="RS NAND Latch"
		var set_bit:=not s if active_low else s;var reset_bit:=not r if active_low else r
		if set_bit and reset_bit:
			node.fault=true;node.q=active_low;node.qb=active_low;return
		if set_bit:node.state=true
		elif reset_bit:node.state=false
		node.q=bool(node.get("state",false));node.qb=not bool(node.q)
	elif item=="T Flip-Flop":
		var clk:=bool(inputs.get("CLK",false))
		if clk and not bool(node.get("prev_clk",false)) and bool(inputs.get("T",true)):node.state=not bool(node.get("state",false))
		node.prev_clk=clk;node.q=bool(node.get("state",false));node.qb=not bool(node.q)
	elif item=="Push Button":node.q=float(node.get("pulse",0))>0.000001
	elif item in ["Pressure Plate","Daylight Sensor"]:node.q=bool(node.get("sensed",false))!=bool(node.get("inverted",false))
	elif item=="Logic Input":node.q=bool(node.get("manual",false))
	elif item=="Logic Output":node.q=bool(inputs.get("IN",false))
	elif item in C.GATES:node.q=evaluate(item,a,b)

	if item not in ["RS NOR Latch","RS NAND Latch","T Flip-Flop"]:node.qb=not bool(node.q)
