extends RefCounted
## Stable climate-based danger; never compound bonuses when loading a save.
const LEVELS := [1, 1, 2, 2, 3, 3, 3, 2]
const LABELS := ["", "Frontier", "Hazardous", "Extreme"]
const COLORS := [Color.WHITE, Color("9cd4ad"), Color("edc477"), Color("ef9582")]

static func level(climate: int) -> int:
	return LEVELS[clampi(climate, 0, 7)]

static func caption(climate: int) -> String:
	var rank := level(climate)
	return "Danger %d / 3 - %s" % [rank, LABELS[rank]]

static func apply(world: Dictionary, c: Dictionary) -> void:
	if c.get("quest_guardian", false) or c.has("danger_rank"): return
	var rank := level(int(world.get("climate", 0)))
	c["danger_rank"] = rank
	var old_max := maxi(1, int(c.get("max_hp", c.get("hp", 30))))
	var new_max := roundi(old_max * (1.0 + (rank - 1) * 0.25))
	c["max_hp"] = new_max
	# Preserve health fraction, death, and prior injuries when migrating saves.
	c["hp"] = maxi(1, ceili(float(c.get("hp", old_max)) / old_max * new_max)) if c.get("alive", false) else mini(0, int(c.get("hp", 0)))
	c["damage"] = roundi(int(c.get("damage", 8)) * (1.0 + (rank - 1) * 0.20))

static func loot_count(c: Dictionary) -> int:
	return clampi(int(c.get("danger_rank", 1)), 1, 3)

static func survey(climate: int) -> String:
	# Broad geological forecast, not a claim about exact ore quantities.
	return ["Copper / iron; forest supplies", "Copper / iron; coastal resources", "Iron / gold; flooded cave routes",
		"Copper / gold; dry cave routes", "Obsidian / deep ores; lava hazards", "Stone / deep ores; sparse vegetation",
		"Iron / crystals; frozen cave routes", "Copper / iron; cold grasslands"][clampi(climate, 0, 7)]
