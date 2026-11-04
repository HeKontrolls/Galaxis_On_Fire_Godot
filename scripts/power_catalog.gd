extends RefCounted
const BASE_DEVICES := ["Biomass Generator","Coal Generator","Fuel Generator","Wood Power Pole","Power Connector","Power Switch","Electric Lamp","Logic Input","Logic Output","NOT Gate","AND Gate","OR Gate","XOR Gate","NAND Gate","NOR Gate","RS NOR Latch","RS NAND Latch","T Flip-Flop"]
const MATERIALS := ["Wire","Logic Wire","Raw Biomass","Biofuel","Refined Fuel"]
const FIXTURES := ["Wall Light","Ceiling Light","Floodlight","Red Signal Lamp","Wall Switch","Push Button","Pressure Plate","Daylight Sensor"]
const DEVICES := BASE_DEVICES + FIXTURES
# Append new catalog entries so existing saved hotbar indices retain their meaning.
const ITEMS := BASE_DEVICES + MATERIALS + FIXTURES
const LIGHTS := {"Electric Lamp":{"watts":10.0,"strength":1.15,"grow_radius":6},"Wall Light":{"watts":6.0,"strength":1.05,"grow_radius":6},"Ceiling Light":{"watts":8.0,"strength":1.15,"grow_radius":6},"Floodlight":{"watts":25.0,"strength":1.5,"grow_radius":8},"Red Signal Lamp":{"watts":2.0,"strength":0.45,"grow_radius":0}}
const SWITCHES := ["Power Switch","Wall Switch"]
const SENSORS := ["Push Button","Pressure Plate","Daylight Sensor"]
static func is_logic(item: String) -> bool:return item in GATES or item in SENSORS or item in ["Logic Input","Logic Output"]
static func wall_mount(item: String) -> bool:return item in GATES or item in ["Logic Input","Logic Output","Power Switch","Electric Lamp","Power Connector","Wall Light","Wall Switch","Push Button","Red Signal Lamp"]
const GENERATORS := {"Biomass Generator":100.0,"Coal Generator":300.0,"Fuel Generator":600.0}
const FUELS := {"Biomass Generator":{"Raw Biomass":35.0,"Wood":18.0,"Leaves":8.0},"Coal Generator":{"Coal Ore":120.0},"Fuel Generator":{"Biofuel":240.0,"Refined Fuel":480.0}}
const GATES := ["NOT Gate","AND Gate","OR Gate","XOR Gate","NAND Gate","NOR Gate","RS NOR Latch","RS NAND Latch","T Flip-Flop"]
const ART = preload("res://scripts/sprite_art.gd")
static func has_device(item: String) -> bool:return item in DEVICES
static func has_item(item: String) -> bool:return item in ITEMS
static func size(item: String) -> Vector2i:
	if GENERATORS.has(item):return Vector2i(3,2)
	if item=="Wood Power Pole":return Vector2i(1,8)
	if item=="Electric Lamp":return Vector2i(1,2)
	if item in ["Power Switch","Logic Output","Ceiling Light","Pressure Plate"]:return Vector2i(2,1)
	if item=="Floodlight":return Vector2i(2,2)
	if item in GATES:return Vector2i(2,2)
	return Vector2i.ONE
static func filename(item: String) -> String:return item.to_lower().replace(" ","_").replace("-","_")
static func inputs(item: String) -> Array[String]:
	if item=="NOT Gate":return ["A"]
	if item in ["AND Gate","OR Gate","XOR Gate","NAND Gate","NOR Gate"]:return ["A","B"]
	if item in ["RS NOR Latch","RS NAND Latch"]:return ["S","R"]
	if item=="T Flip-Flop":return ["T","CLK"]
	if item=="Logic Output":return ["IN"]
	if LIGHTS.has(item) or GENERATORS.has(item):return ["EN"]
	return []
static func outputs(item: String) -> Array[String]:
	if item in ["RS NOR Latch","RS NAND Latch","T Flip-Flop"]:return ["Q","QB"]
	if is_logic(item):return ["Q"]
	return []
static func default_input(item: String,pin: String) -> bool:return pin=="EN" or (item=="RS NAND Latch" and pin in ["S","R"]) or (item=="T Flip-Flop" and pin=="T")
static func power_pins(item: String) -> Array[String]:return ["P","L"] if item in SWITCHES or item=="Logic Output" else ["P"]
static func pins(item: String) -> Dictionary:
	var pixels:=Vector2(size(item)*16);var result:={"P":Vector2(pixels.x*0.5,3)}
	if item in SWITCHES or item=="Logic Output":result.P=Vector2(5,3);result.L=Vector2(pixels.x-5,3)
	var ins:=inputs(item);var outs:=outputs(item)
	for i in range(ins.size()):result[ins[i]]=Vector2(3,10+i*14 if pixels.y>=32 else pixels.y-4)
	for i in range(outs.size()):result[outs[i]]=Vector2(pixels.x-3,10+i*14 if pixels.y>=32 else pixels.y-4)
	return result
static func cost(item: String) -> float:
	if LIGHTS.has(item):return float(LIGHTS[item].watts)
	if is_logic(item):return 1.0
	return 0.0
static func description(item: String) -> String:
	if GENERATORS.has(item):return "%.0f W | F: open fuel storage" % GENERATORS[item]
	if item=="Wood Power Pole":return "8-block utility pole | Wire the ground socket; cables attach overhead"
	if item=="Wire":return "Power cable | Right-click P/L terminals | 16-block span"
	if item=="Logic Wire":return "Signal cable | Output first, then input | One driver per input"
	if item in SWITCHES:return "F: isolate/connect P to L"
	if item=="Push Button":return "F: 0.5-second signal pulse | Requires power at P"
	if item=="Pressure Plate":return "Q HIGH while player, robot or creature stands on plate"
	if item=="Daylight Sensor":return "Q HIGH in open daylight | F: invert for automatic night lights"
	if item=="Logic Input":return "F: toggle signal | Requires power at P"
	if item=="Logic Output":return "IN controls Q and the P-to-L power relay"
	if LIGHTS.has(item):return "%.0f W | EN signal | %s" % [cost(item),"Indicator only; no crop light" if item=="Red Signal Lamp" else "Illuminates rooms and crops"]
	if item=="RS NOR Latch":return "S/R active HIGH | 00: hold | 11: invalid"
	if item=="RS NAND Latch":return "S/R active LOW | 11: hold | 00: invalid"
	if item=="T Flip-Flop":return "Rising CLK toggles Q when T is HIGH"
	if item in GATES:return "F: inspect inputs/output | Requires power at P"
	return "Power crafting material"
static func texture(item: String) -> Texture2D:return ART.texture("res://assets/sprites/power/"+filename(item)+".png")
