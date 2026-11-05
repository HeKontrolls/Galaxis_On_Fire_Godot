extends RefCounted
## Combat-only equipment. Native Aseprite frames share the existing (16,32) grip.
const Art = preload("res://scripts/sprite_art.gd")
const WEAPONS := {
	"Wood Spear": {"damage":16, "cooldown":0.65, "reach":92.0, "width":16.0, "push":12.0, "hits":1, "motion":"thrust"},
	"Copper Spear": {"damage":25, "cooldown":0.65, "reach":96.0, "width":16.0, "push":16.0, "hits":1, "motion":"thrust"},
	"Iron Spear": {"damage":34, "cooldown":0.65, "reach":100.0, "width":17.0, "push":20.0, "hits":1, "motion":"thrust"},
	"Iron Dagger": {"damage":19, "cooldown":0.26, "reach":43.0, "width":19.0, "push":5.0, "hits":1, "motion":"thrust"},
	"Iron Warhammer": {"damage":52, "cooldown":0.95, "reach":68.0, "width":39.0, "push":32.0, "hits":3, "motion":"swing"},
	"Crystal Blade": {"damage":43, "cooldown":0.48, "reach":78.0, "width":32.0, "push":18.0, "hits":2, "motion":"swing"},
}
const RECIPES := [
	{"name":"Wood Spear", "out":"Wood Spear", "count":1, "needs":{"Planks":3,"Stick":4}},
	{"name":"Copper Spear", "out":"Copper Spear", "count":1, "needs":{"Wood Spear":1,"Copper Ingot":3}, "station":"Workbench"},
	{"name":"Iron Spear", "out":"Iron Spear", "count":1, "needs":{"Copper Spear":1,"Iron Ingot":4}, "station":"Workbench"},
	{"name":"Iron Dagger", "out":"Iron Dagger", "count":1, "needs":{"Iron Ingot":3,"Stick":1,"Alien Fiber":1}, "station":"Workbench"},
	{"name":"Iron Warhammer", "out":"Iron Warhammer", "count":1, "needs":{"Iron Ingot":8,"Planks":4,"Alien Fiber":2}, "station":"Workbench"},
	{"name":"Crystal Blade", "out":"Crystal Blade", "count":1, "needs":{"Iron Sword":1,"Crystal":5,"Gold Ingot":2}, "station":"Workbench"},
]

static func has_weapon(item: String) -> bool: return WEAPONS.has(item)

static func texture(item: String) -> Texture2D:
	return Art.texture("res://assets/sprites/weapons/" + item.to_lower().replace(" ", "_") + ".png")

static func summary(item: String) -> String:
	var spec: Dictionary = WEAPONS[item]
	return "%d damage | %.2fs | %.1f blocks | %s" % [spec.damage, spec.cooldown, float(spec.reach)/16.0,
		"Hits up to %d foes" % spec.hits if int(spec.hits)>1 else "Aimed thrust"]

static func hits(item: String, origin: Vector2, aim: Vector2, box: Rect2) -> bool:
	var spec: Dictionary = WEAPONS[item]
	var offset := box.get_center() - origin
	var along := offset.dot(aim)
	return along >= 0 and along <= float(spec.reach) and absf(offset.cross(aim)) <= float(spec.width)

static func pose(at: Vector2, aim: Vector2, facing: int, active: bool, progress: float) -> Transform2D:
	var extension := sin(progress * PI) if active else 0.0
	var hand := at + Vector2(8 + facing * 3, 7) + aim * (12.0 + extension * 10.0)
	return Transform2D(aim.angle() + PI * 0.5, Vector2(0.82, 0.82), 0.0, hand)

static func draw_rect(item: String) -> Rect2:
	return Rect2(-16,-56,32,64) if item.ends_with(" Spear") else Rect2(-16,-32,32,40)
