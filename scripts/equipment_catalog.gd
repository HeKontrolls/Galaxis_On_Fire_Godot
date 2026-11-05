extends RefCounted
const Art=preload("res://scripts/sprite_art.gd")
const ITEMS := {
	"Fiber Hood":{"slot":"head","defense":1,"weight":0.0,"material":"fiber","needs":{"Alien Fiber":4}},
	"Fiber Vest":{"slot":"chest","defense":2,"weight":0.0,"material":"fiber","needs":{"Alien Fiber":8}},
	"Fiber Boots":{"slot":"boots","defense":1,"weight":0.0,"material":"fiber","needs":{"Alien Fiber":4}},
	"Copper Helmet":{"slot":"head","defense":2,"weight":0.01,"material":"copper","needs":{"Copper Ingot":3,"Alien Fiber":2}},
	"Copper Cuirass":{"slot":"chest","defense":4,"weight":0.03,"material":"copper","needs":{"Copper Ingot":6,"Alien Fiber":4}},
	"Copper Boots":{"slot":"boots","defense":2,"weight":0.01,"material":"copper","needs":{"Copper Ingot":3,"Alien Fiber":2}},
	"Iron Helmet":{"slot":"head","defense":3,"weight":0.02,"material":"iron","needs":{"Iron Ingot":4,"Alien Fiber":2}},
	"Iron Cuirass":{"slot":"chest","defense":6,"weight":0.06,"material":"iron","needs":{"Iron Ingot":8,"Alien Fiber":4}},
	"Iron Boots":{"slot":"boots","defense":3,"weight":0.02,"material":"iron","needs":{"Iron Ingot":4,"Alien Fiber":2}},
	"Wood Shield":{"slot":"shield","block":0.65,"needs":{"Planks":6,"Alien Fiber":2}},
	"Copper Shield":{"slot":"shield","block":0.75,"needs":{"Wood Shield":1,"Copper Ingot":4}},
	"Iron Shield":{"slot":"shield","block":0.85,"needs":{"Copper Shield":1,"Iron Ingot":6}},
	"Scout Charm":{"slot":"accessory","speed":0.08,"needs":{"Alien Fiber":8,"Crystal":1}},
	"Bone Ward":{"slot":"accessory","defense":2,"needs":{"Bone Fragment":6,"Alien Fiber":4}},
}
const RECIPES := [
	{"name":"Fiber Hood","out":"Fiber Hood","count":1,"needs":{"Alien Fiber":4},"station":"Workbench"},
	{"name":"Fiber Vest","out":"Fiber Vest","count":1,"needs":{"Alien Fiber":8},"station":"Workbench"},
	{"name":"Fiber Boots","out":"Fiber Boots","count":1,"needs":{"Alien Fiber":4},"station":"Workbench"},
	{"name":"Copper Helmet","out":"Copper Helmet","count":1,"needs":{"Copper Ingot":3,"Alien Fiber":2},"station":"Workbench"},
	{"name":"Copper Cuirass","out":"Copper Cuirass","count":1,"needs":{"Copper Ingot":6,"Alien Fiber":4},"station":"Workbench"},
	{"name":"Copper Boots","out":"Copper Boots","count":1,"needs":{"Copper Ingot":3,"Alien Fiber":2},"station":"Workbench"},
	{"name":"Iron Helmet","out":"Iron Helmet","count":1,"needs":{"Iron Ingot":4,"Alien Fiber":2},"station":"Workbench"},
	{"name":"Iron Cuirass","out":"Iron Cuirass","count":1,"needs":{"Iron Ingot":8,"Alien Fiber":4},"station":"Workbench"},
	{"name":"Iron Boots","out":"Iron Boots","count":1,"needs":{"Iron Ingot":4,"Alien Fiber":2},"station":"Workbench"},
	{"name":"Wood Shield","out":"Wood Shield","count":1,"needs":{"Planks":6,"Alien Fiber":2},"station":"Workbench"},
	{"name":"Copper Shield","out":"Copper Shield","count":1,"needs":{"Wood Shield":1,"Copper Ingot":4},"station":"Workbench"},
	{"name":"Iron Shield","out":"Iron Shield","count":1,"needs":{"Copper Shield":1,"Iron Ingot":6},"station":"Workbench"},
	{"name":"Scout Charm","out":"Scout Charm","count":1,"needs":{"Alien Fiber":8,"Crystal":1},"station":"Workbench"},
	{"name":"Bone Ward","out":"Bone Ward","count":1,"needs":{"Bone Fragment":6,"Alien Fiber":4},"station":"Workbench"},
]
static var cache := {}
static func texture(name: String) -> Texture2D:
	if not cache.has(name):cache[name]=Art.texture("res://assets/sprites/equipment/"+name+".png")
	return cache[name]
static func icon(item: String) -> Texture2D: return texture(item.to_lower().replace(" ","_"))
static func summary(item: String) -> String:
	var spec:Dictionary=ITEMS[item]
	if spec.slot=="shield":return "Blocks %d%% from the front | Hold RMB with melee/empty hand" % roundi(float(spec.block)*100)
	if spec.has("speed"):return "+8% movement | One of each accessory may be equipped"
	return "%d defense | %d%% movement penalty | Equip from backpack" % [spec.get("defense",0),roundi(float(spec.get("weight",0))*100)]
