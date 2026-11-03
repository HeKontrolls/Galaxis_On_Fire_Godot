extends RefCounted

const Ranged = preload("res://scripts/ranged_weapons.gd")
const Art = preload("res://scripts/sprite_art.gd")

const FAMILIES := ["Pickaxe", "Sword", "Axe", "Shovel"]
const BASE_TOOLS := ["Pickaxe", "Sword", "Hoe", "Axe", "Hammer", "Watering Can", "Shovel", "Mattock"]
const SOIL := [1, 2, 5, 6, 12, 13, 45]
const MATERIALS := {
	"Wood": {"level": 0, "durability": 59, "speed": 2.0, "bonus": 0, "rank": 1},
	"Gold": {"level": 0, "durability": 32, "speed": 12.0, "bonus": 0, "rank": 1},
	"Stone": {"level": 1, "durability": 131, "speed": 4.0, "bonus": 1, "rank": 2},
	"Copper": {"level": 1, "durability": 191, "speed": 5.0, "bonus": 1, "rank": 3},
	"Iron": {"level": 2, "durability": 250, "speed": 6.0, "bonus": 2, "rank": 4},
	"Diamond": {"level": 3, "durability": 1561, "speed": 8.0, "bonus": 3, "rank": 5},
	"Netherite": {"level": 4, "durability": 2031, "speed": 9.0, "bonus": 4, "rank": 6},
}
const REQUIRED_LEVEL := {3: 0, 10: 0, 20: 0, 35: 0, 37: 0, 27: 0, 21: 1, 22: 1, 23: 2, 24: 2, 25: 2, 17: 3, 26: 3}
const BLOCK_NAMES := {3: "Stone", 10: "Cobblestone", 20: "Coal Ore", 21: "Copper Ore", 22: "Iron Ore", 23: "Gold Ore", 24: "Alien Crystal", 25: "Diamond Ore", 26: "Ancient Debris", 27: "Glacial Ice", 17: "Obsidian", 35: "Furnace", 37: "Furnace"}


static func material(item: String) -> String:
	for name: String in MATERIALS:
		if item.begins_with(name + " "):
			return name
	return "Wood"


static func profile(item: String) -> Dictionary:
	return MATERIALS[material(item)]


static func mining_level(item: String) -> int:
	return int(profile(item)["level"]) if family(item) == "Pickaxe" else -1


static func max_durability(item: String) -> int:
	return int(profile(item)["durability"]) if family(item) in ["Pickaxe", "Shovel"] else 0


static func can_harvest(item: String, tile_id: int) -> bool:
	return not Ranged.has_weapon(item) and family(item) != "Sword" and (not REQUIRED_LEVEL.has(tile_id) or mining_level(item) >= int(REQUIRED_LEVEL[tile_id]))


static func requirement(tile_id: int) -> String:
	var level := int(REQUIRED_LEVEL.get(tile_id, 0))
	return "%s needs %s (mining level %d)" % [BLOCK_NAMES.get(tile_id, "This block"), ["a pickaxe", "Stone or Copper Pickaxe", "Iron Pickaxe or better", "Diamond Pickaxe or better"][level], level]


static func family(item: String) -> String:
	for metal in ["Stone", "Copper", "Iron", "Gold", "Diamond", "Netherite"]:
		var base := item.trim_prefix(metal + " ")
		if base != item and base in FAMILIES and (metal in ["Copper", "Iron"] or base in ["Pickaxe", "Shovel"]):
			return base
	return item


static func tier(item: String) -> int:
	if family(item) in ["Pickaxe", "Shovel"]:
		return int(profile(item)["rank"])
	return maxi(1, progression(family(item)).find(item) + 1)


static func progression(base: String) -> Array[String]:
	if base == "Pickaxe":
		return ["Pickaxe", "Gold Pickaxe", "Stone Pickaxe", "Copper Pickaxe", "Iron Pickaxe", "Diamond Pickaxe", "Netherite Pickaxe"]
	if base == "Shovel":
		return ["Shovel", "Gold Shovel", "Stone Shovel", "Copper Shovel", "Iron Shovel", "Diamond Shovel", "Netherite Shovel"]
	var result: Array[String] = [base]
	if base in FAMILIES:
		result.append("Copper " + base)
		result.append("Iron " + base)
	return result


static func has_item(item: String) -> bool:
	return family(item) in BASE_TOOLS or Ranged.has_weapon(item)


static func variants() -> Array[String]:
	var result: Array[String] = []
	for base in FAMILIES:
		result.append_array(progression(base).slice(1))
	return result


static func display_name(item: String) -> String:
	return "Wood " + item if item in FAMILIES else item


const MINING_SWING := 0.48

static func mining_interval(_item: String, _tile_id: int = -1) -> float:
	return MINING_SWING


static func block_hardness(tile_id: int) -> float:
	if tile_id in SOIL: return 12.0
	if tile_id == 7: return 64.0
	if tile_id in [8, 14, 15, 16]: return 4.0
	return float({3: 24, 10: 24, 20: 28, 21: 36, 22: 48, 23: 60, 24: 64, 25: 90, 26: 110, 17: 120, 27: 32}.get(tile_id, 16))


static func mining_damage(item: String, tile_id: int) -> float:
	var base := family(item)
	if Ranged.has_weapon(item) or base == "Sword": return 0.0
	if tile_id in SOIL:
		if base == "Shovel": return float(profile(item).speed) * 4.0
		if base == "Pickaxe": return 2.0 + float(profile(item).bonus) * 0.3
		if base == "Axe": return [2.4, 3.0, 4.0][tier(item) - 1]
		return 2.5 if base == "Mattock" else 1.5
	if tile_id == 7:
		if base == "Axe": return [8.0, 14.0, 22.0][tier(item) - 1]
		if base == "Pickaxe": return 1.6 + float(profile(item).bonus) * 0.4
		return 64.0 / 60.0 if item == "Hand" else 2.0
	if tile_id in [9, 33, 34, 36] and base == "Axe": return [6.0, 9.0, 18.0][tier(item) - 1]
	if base == "Pickaxe": return float(profile(item).speed) * 4.0
	return 4.0 if base in ["Hammer", "Mattock"] else 2.0


static func mining_hits(item: String, tile_id: int) -> int:
	return ceili(block_hardness(tile_id) / maxf(0.01, mining_damage(item, tile_id)))


static func damage(item: String) -> int:
	if Ranged.has_weapon(item): return int(Ranged.WEAPONS[item].damage)
	var level := tier(item) - 1
	match family(item):
		"Sword": return [18, 26, 36][level]
		"Pickaxe": return 7 + int(profile(item)["bonus"])
		"Shovel": return 5 + int(profile(item)["bonus"])
		"Axe": return [10, 15, 22][level]
	return 7


static func attack_interval(item: String) -> float:
	if Ranged.has_weapon(item): return float(Ranged.WEAPONS[item].cooldown)
	if family(item) == "Shovel":
		return 0.65
	if family(item) == "Sword":
		return [0.42, 0.35, 0.28][tier(item) - 1]
	if family(item) == "Pickaxe":
		return [0.60, 0.55, 0.50, 0.42, 0.38, 0.35][tier(item) - 1]
	return [0.60, 0.50, 0.42][tier(item) - 1]


static func action_duration(item: String, attacking: bool) -> float:
	if family(item) in FAMILIES:
		return minf(0.32, attack_interval(item)) if attacking else mining_interval(item)
	return MINING_SWING if not attacking and item != "Watering Can" else 0.25


static func summary(item: String) -> String:
	if Ranged.has_item(item): return Ranged.summary(item)
	if item in ["Hammer", "Mattock"]:
		return "Cave walls | Power %d | Level %d" % [8 if item == "Hammer" else 16, 1 if item == "Hammer" else 2]
	if family(item) not in FAMILIES:
		return ""
	if family(item) == "Sword":
		return "%d damage | %.2f s between attacks" % [damage(item), attack_interval(item)]
	if family(item) == "Axe":
		return "%d tree hits | %d damage | Slow digging" % [mining_hits(item, 7), damage(item)]
	if family(item) == "Shovel":
		return "Soil power %.0f | %d durability | %d damage" % [mining_damage(item, 2), max_durability(item), damage(item)]
	return "Level %d | Mining power %.0f | %d durability | +%d damage" % [mining_level(item), mining_damage(item, 3), max_durability(item), int(profile(item)["bonus"])]


static func best_owned(inventory: Dictionary, base: String) -> String:
	if base in ["Pickaxe", "Shovel"]:
		var best := "Hand"
		var score := -1.0
		for item: String in progression(base):
			var value := (mining_level(item) * 100.0 if base == "Pickaxe" else 0.0) + float(profile(item)["speed"])
			if int(inventory.get(item, 0)) > 0 and value > score:
				best = item
				score = value
		return best
	var choices := progression(base)
	choices.reverse()
	for item in choices:
		if int(inventory.get(item, 0)) > 0:
			return item
	return "Hand"


static func make_textures() -> Dictionary:
	var result := {}
	for base in BASE_TOOLS:
		for item in progression(base):
			var filename := display_name(item).to_lower().replace(" ", "_")
			if base == "Mattock":
				result[item] = Art.texture("res://assets/sprites/underground/mattock.png")
				continue
			if base == "Shovel":
				result[item] = Art.texture("res://assets/sprites/shovels/" + filename + ".png")
				continue
			var advanced := item in ["Gold Pickaxe", "Diamond Pickaxe", "Netherite Pickaxe"]
			result[item] = Art.texture("res://assets/sprites/expansion/tools/" + filename + "_00.png" if advanced else Art.ROOT + "tools/" + filename + ".png")
	for item: String in Ranged.WEAPONS: result[item] = Ranged.icon(item)
	return result
