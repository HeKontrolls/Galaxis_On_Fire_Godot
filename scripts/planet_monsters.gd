extends RefCounted

const Art = preload("res://scripts/sprite_art.gd")
const FAMILIES := ["moss_prowler", "tide_crab", "reef_stalker", "dune_scorpion", "ember_crawler", "shale_scavenger", "ice_walker", "tundra_beast"]
const NAMES := ["Torchcrest", "Crown conch", "Coraljaw", "Veilrunner", "Kiln beetle", "Hammerhorn", "Ruby tusker", "Plume strider"]
const SPEEDS := [34.0, 23.0, 39.0, 37.0, 20.0, 18.0, 31.0, 29.0]
const HEALTH := [28, 34, 30, 32, 42, 46, 36, 38]
const DAMAGE := [7, 7, 8, 9, 11, 9, 9, 10]
const ALERT := [128.0, 56.0, 112.0, 144.0, 72.0, 48.0, 120.0, 96.0]
const COUNTS := [14, 12, 10, 9, 7, 6, 8, 10]
var sheets := {}

static func decorate(world: Dictionary, creature: Dictionary, index: int, fresh := false) -> void:
	if creature.get("quest_guardian", false) or creature.get("wildlife", false) or creature.has("monster_family"):
		return
	var family := clampi(int(world["climate"]), 0, 7)
	var rng := RandomNumberGenerator.new()
	# Planet-wide morph preference plus individual genes, independent of movement/time.
	rng.seed = int(world["seed"]) ^ 0x71F39
	var preferred := rng.randi_range(0, 2)
	rng.seed = int(world["seed"]) ^ (index * 104729) ^ (int(creature.get("home_x", creature["x"])) * 31)
	var morph := preferred if rng.randf() < 0.60 else rng.randi_range(0, 2)
	creature["monster_family"] = family
	creature["monster_morph"] = morph
	creature["monster_phase"] = rng.randf_range(0.0, 4.0)
	creature["speed"] = SPEEDS[family] * rng.randf_range(0.88, 1.12)
	creature["patrol_radius"] = rng.randf_range(72.0, 128.0)
	creature["alert_radius"] = ALERT[family] * rng.randf_range(0.9, 1.1)
	creature["damage"] = DAMAGE[family] + (1 if morph == 2 else 0)
	creature["max_hp"] = HEALTH[family] + morph * 3
	if fresh:
		creature["hp"] = creature["max_hp"]
	else:
		# Do not heal injured saves or resurrect defeated creatures during migration.
		creature["max_hp"] = maxi(int(creature["max_hp"]), int(creature.get("hp", 30)))

static func prepare(world: Dictionary) -> void:
	var creatures: Array = world.get("creatures", [])
	for i in range(creatures.size()):
		decorate(world, creatures[i], i)

static func display_name(creature: Dictionary) -> String:
	if creature.get("wildlife", false): return preload("res://scripts/wildlife_mobs.gd").NAMES[int(creature.wildlife_family)]
	if bool(creature.get("flying", false)):
		return preload("res://scripts/flying_monsters.gd").NAMES[clampi(int(creature.get("monster_family", 0)), 0, 7)]
	return "Ruined mining guardian" if creature.get("quest_guardian", false) else NAMES[clampi(int(creature.get("monster_family", 0)), 0, 7)]

func texture_for(family: int) -> Texture2D:
	family = clampi(family, 0, 7)
	if not sheets.has(family):
		sheets[family] = Art.texture("res://assets/sprites/monsters/" + FAMILIES[family] + ".png")
	return sheets[family]

func draw(game: Node2D, creature: Dictionary, at: Vector2, clock: float) -> void:
	var moving := bool(creature.get("moving", false))
	var time := clock + float(creature.get("monster_phase", 0.0))
	var frame := 2 + posmod(int(time / 0.14), 4) if moving else (1 if fposmod(time, 1.22) >= 1.1 else 0)
	var morph := clampi(int(creature.get("monster_morph", 0)), 0, 2)
	var tint := Color("ffc3b0") if float(creature.get("hit_flash", 0.0)) > 0.0 else Color.WHITE
	game.draw_set_transform((at + Vector2(12, 18)).round(), 0.0, Vector2(-1 if int(creature.get("direction", 1)) < 0 else 1, 1))
	game.draw_texture_rect_region(texture_for(int(creature.get("monster_family", 0))), Rect2(-24, -36, 48, 40), Rect2(frame * 48, morph * 40, 48, 40), tint)
	game.draw_set_transform(Vector2.ZERO)
