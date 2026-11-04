extends RefCounted
const Art=preload("res://scripts/sprite_art.gd")
const STATIONS:=["Alchemy Desk","Cauldron"]
const BLANKS:=["Blank Wand","Blank Staff","Blank Tome"]
const ESSENCES:=["Fire Essence","Frost Essence","Storm Essence","Life Essence","Spirit Essence"]
const ITEMS:=STATIONS+BLANKS+ESSENCES+["Arcane Ink","Bone Fragment"]
const FORMS:=["Bolt","Self","Burst","Chain"]
const EFFECTS:={
	"Ember":{"school":"Destruction","node":"ember","essence":"Fire Essence","damage":12.0,"mana":6.0},
	"Frost":{"school":"Destruction","node":"frost","essence":"Frost Essence","damage":14.0,"mana":8.0},
	"Storm":{"school":"Destruction","node":"storm","essence":"Storm Essence","damage":18.0,"mana":12.0},
	"Crystal":{"school":"Destruction","node":"crystal","essence":"Storm Essence","damage":20.0,"mana":10.0},
	"Mending":{"school":"Restoration","node":"mending","essence":"Life Essence","heal":18.0,"mana":18.0},
	"Regeneration":{"school":"Restoration","node":"regeneration","essence":"Life Essence","mana":18.0},
	"Ward":{"school":"Warding","node":"ward","essence":"Storm Essence","mana":20.0},
	"Light":{"school":"Illumination","node":"lumen","essence":"Fire Essence","mana":10.0},
	"Drain":{"school":"Necromancy","node":"soul","essence":"Spirit Essence","damage":14.0,"mana":12.0},
	"Blight":{"school":"Necromancy","node":"blight","essence":"Spirit Essence","damage":8.0,"mana":12.0},
	"Raise Dead":{"school":"Necromancy","node":"raise","essence":"Spirit Essence","mana":28.0}}
const NODES:={
	"ember":{"name":"Ember shaping","school":"Destruction","rank":1,"needs":[],"detail":"Unlock Ember effect"},
	"frost":{"name":"Frost shaping","school":"Destruction","rank":1,"needs":[],"detail":"Unlock Frost effect"},
	"storm":{"name":"Storm shaping","school":"Destruction","rank":2,"needs":["ember"],"detail":"Unlock Storm effect"},
	"crystal":{"name":"Crystal shaping","school":"Destruction","rank":3,"needs":["frost"],"detail":"Unlock piercing crystal"},
	"mending":{"name":"Life binding","school":"Restoration","rank":1,"needs":[],"detail":"Unlock Mending effect"},
	"regeneration":{"name":"Regeneration","school":"Restoration","rank":2,"needs":["mending"],"detail":"Unlock timed healing"},
	"vitality":{"name":"Vitality","school":"Restoration","rank":3,"needs":["regeneration"],"detail":"Crafted healing +15%"},
	"renewal":{"name":"Renewal","school":"Restoration","rank":4,"needs":["vitality"],"detail":"Crafted healing cost -20%"},
	"ward":{"name":"Ward shaping","school":"Warding","rank":1,"needs":[],"detail":"Unlock Ward effect"},
	"aegis":{"name":"Aegis","school":"Warding","rank":2,"needs":["ward"],"detail":"15% stronger crafted wards"},
	"wardweave":{"name":"Ward weaving","school":"Warding","rank":3,"needs":["aegis"],"detail":"Crafted wards last 20% longer"},
	"bulwark":{"name":"Bulwark","school":"Warding","rank":4,"needs":["wardweave"],"detail":"25% stronger crafted wards"},
	"lumen":{"name":"Light shaping","school":"Illumination","rank":1,"needs":[],"detail":"Unlock Light effect"},
	"dual":{"name":"Dual weaving","school":"Illumination","rank":2,"needs":["lumen"],"detail":"Combine two effects"},
	"burst":{"name":"Expanding sigils","school":"Illumination","rank":2,"needs":["lumen"],"detail":"Unlock Burst delivery"},
	"chain":{"name":"Linked sigils","school":"Illumination","rank":3,"needs":["burst"],"detail":"Unlock Chain delivery"},
	"soul":{"name":"Soul study","school":"Necromancy","rank":1,"needs":[],"detail":"Drain; enemies drop bones"},
	"blight":{"name":"Blight","school":"Necromancy","rank":2,"needs":["soul"],"detail":"Unlock decay over time"},
	"raise":{"name":"Grave calling","school":"Necromancy","rank":2,"needs":["soul"],"detail":"Raise one fallen ally"},
	"legion":{"name":"Spectral legion","school":"Necromancy","rank":4,"needs":["raise"],"detail":"Up to three raised allies"}}
const BREWS:=[
	{"out":"Fire Essence","count":2,"needs":{"Coal Ore":2,"Crystal":1,"Wood":1},"time":8.0,"school":"Destruction"},
	{"out":"Frost Essence","count":2,"needs":{"Glacial Ice":3,"Crystal":1,"Wood":1},"time":8.0,"school":"Destruction"},
	{"out":"Storm Essence","count":2,"needs":{"Copper Ingot":1,"Crystal":2,"Wood":1},"time":10.0,"school":"Warding"},
	{"out":"Life Essence","count":2,"needs":{"Wildflower":3,"Corn":1,"Crystal":1,"Wood":1},"time":8.0,"school":"Restoration"},
	{"out":"Spirit Essence","count":2,"needs":{"Alien Fiber":2,"Crystal":1,"Wood":1},"time":10.0,"school":"Necromancy"},
	{"out":"Arcane Ink","count":2,"needs":{"Alien Fiber":2,"Coal Ore":1,"Crystal":1,"Wood":1},"time":8.0,"school":"Illumination"},
	{"out":"Mana Tonic","count":2,"needs":{"Life Essence":1,"Storm Essence":1,"Corn":2,"Wood":1},"time":12.0,"school":"Restoration"}]
static func is_spell(item:String)->bool:return item.begins_with("Wand #") or item.begins_with("Staff #") or item.begins_with("Tome #")
static func focus(item:String)->String:return "Wand" if item.begins_with("Wand #") else ("Staff" if item.begins_with("Staff #") else "Tome")
static func filename(item:String)->String:return "crafted_"+focus(item).to_lower() if is_spell(item) else item.to_lower().replace(" ","_")
static func has_item(item:String)->bool:return item in ITEMS
static func sheet(name:String)->Texture2D:return Art.texture("res://assets/sprites/alchemy/"+name+".png")
static func icon(item:String)->Texture2D:
	var result:=AtlasTexture.new();result.atlas=sheet(filename(item))
	result.region=Rect2(0,0,48,32) if item in STATIONS else (Rect2(0,0,24,40) if item in BLANKS or is_spell(item) else Rect2(0,0,16,16))
	return result
static func draft()->Dictionary:return {"name":"New Spell","focus":"Wand","form":"Bolt","first":"Ember","second":"None","power":1,"duration":1,"area":1}
static func offensive(effect:String)->bool:return EFFECTS.has(effect) and EFFECTS[effect].has("damage")
static func description(item:String)->String:
	if item in STATIONS:return "Place on solid ground | F: open its own reagent storage"
	if item in BLANKS:return "Put in Alchemy Desk with ink and essences to inscribe a unique spell"
	return "Alchemy reagent | Used in the cauldron and spell inscriptions"

static func timed_effect(effect:String)->bool:return effect in ["Ember","Frost","Blight","Regeneration","Ward","Light","Raise Dead"]
