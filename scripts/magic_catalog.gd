extends RefCounted
const Craft=preload("res://scripts/spellcraft_catalog.gd")
const Art=preload("res://scripts/sprite_art.gd")
const SCHOOLS:=["Destruction","Restoration","Warding","Illumination","Necromancy"]
const THRESHOLDS:=[0.0,30.0,90.0,180.0,300.0]
const BASE_SPELLS:={
	"Ember Wand":{"school":"Destruction","kind":"ember","mana":7.0,"cooldown":0.45,"damage":15,"speed":560.0,"hits":1,"detail":"Ember bolt; burns for 3s"},
	"Frost Wand":{"school":"Destruction","kind":"frost","mana":10.0,"cooldown":0.65,"damage":18,"speed":620.0,"hits":1,"detail":"Ice shard; slows for 3s"},
	"Storm Staff":{"school":"Destruction","kind":"storm","mana":24.0,"cooldown":1.35,"damage":28,"detail":"Lightning chains to 3 visible foes"},
	"Crystal Staff":{"school":"Destruction","kind":"crystal","mana":14.0,"cooldown":0.8,"damage":25,"speed":740.0,"hits":2,"detail":"Crystal lance pierces 2 foes"},
	"Mending Tome":{"school":"Restoration","kind":"mend","mana":25.0,"cooldown":5.0,"heal":24,"detail":"Restores health; no cast at full HP"},
	"Ward Book":{"school":"Warding","kind":"ward","mana":25.0,"cooldown":10.0,"shield":40,"duration":8.0,"detail":"Absorbs creature damage for 8s"},
	"Greater Ward Book":{"school":"Warding","kind":"ward","mana":40.0,"cooldown":16.0,"shield":80,"duration":10.0,"detail":"Stronger barrier; replaces lesser ward"},
	"Lumen Tome":{"school":"Illumination","kind":"lumen","mana":12.0,"cooldown":1.0,"duration":60.0,"detail":"60s following cave light; no crop light"}}
const NECROMANCY_SPELLS:={"Soul Wand":{"school":"Necromancy","kind":"drain","mana":12.0,"cooldown":0.8,"damage":14,"speed":620.0,"hits":1,"detail":"Soul drain | Requires Soul study"},"Grave Tome":{"school":"Necromancy","kind":"raise","mana":28.0,"cooldown":8.0,"detail":"Raise a fallen ally | Requires Grave calling"}}
const SPELLS:={
"Ember Wand":BASE_SPELLS["Ember Wand"],
"Frost Wand":BASE_SPELLS["Frost Wand"],
"Storm Staff":BASE_SPELLS["Storm Staff"],
"Crystal Staff":BASE_SPELLS["Crystal Staff"],
"Mending Tome":BASE_SPELLS["Mending Tome"],
"Ward Book":BASE_SPELLS["Ward Book"],
"Greater Ward Book":BASE_SPELLS["Greater Ward Book"],
"Lumen Tome":BASE_SPELLS["Lumen Tome"],
"Soul Wand":NECROMANCY_SPELLS["Soul Wand"],"Grave Tome":NECROMANCY_SPELLS["Grave Tome"]}
const ITEMS:=["Ember Wand","Frost Wand","Storm Staff","Crystal Staff","Mending Tome","Ward Book","Greater Ward Book","Lumen Tome","Mana Tonic","Soul Wand","Grave Tome"]
static func has_item(item:String)->bool:return item in ITEMS or Craft.is_spell(item)
static func has_focus(item:String)->bool:return SPELLS.has(item) or Craft.is_spell(item)
static func filename(item:String)->String:return Craft.filename(item) if Craft.is_spell(item) else item.to_lower().replace(" ","_")
static func sheet(name:String)->Texture2D:
	if name in ["soul_wand","grave_tome","crafted_wand","crafted_staff","crafted_tome","soul_bolt","blight_bolt","bone_servitor","grave_wraith","bone_hound","blight_status","bone_fragment"]:return Craft.sheet(name)
	return Art.texture("res://assets/sprites/magic/"+name+".png")
static func icon(item:String)->Texture2D:
	var result:=AtlasTexture.new();result.atlas=sheet(filename(item));result.region=Rect2(0,0,24,40) if has_focus(item) else Rect2(0,0,16,24);return result
static func summary(item:String)->String:
	if Craft.is_spell(item):return "Inscribed spell | K: saved design and skills"
	if item=="Mana Tonic":return "Right-click: restore 50 mana | 8s recovery"
	if not has_focus(item):return ""
	var spec:Dictionary=SPELLS[item]
	return "%.0f MP | %.2fs | %s" % [spec.mana,spec.cooldown,spec.detail]
