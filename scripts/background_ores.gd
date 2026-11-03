extends RefCounted
const WG = preload("res://scripts/world_gen.gd")
const Art = preload("res://scripts/sprite_art.gd")
var entries: Array = []
var buckets := {}
var by_cell := {}
var sheet: Texture2D

static func prepare(world: Dictionary) -> void:
	if int(world.get("background_ore_version", 0)) >= 1: return
	var deposits: Array = []
	var used := {}
	var rng := RandomNumberGenerator.new(); rng.seed = int(world.seed) ^ 0xBA60E
	for vein in range(2600):
		var x := rng.randi_range(8, WG.WIDTH - 9)
		var y := rng.randi_range(int(world.surface[x]) + 28, WG.HEIGHT - 140)
		var choices := [20, 20, 21, 22]
		if y > 320: choices.append_array([23, 24])
		if y > 650: choices.append(25)
		var id: int = choices[rng.randi_range(0, choices.size() - 1)]
		for part in range(rng.randi_range(3, 7)):
			var cell := Vector2i(x + rng.randi_range(-2, 2), y + rng.randi_range(-1, 1))
			if used.has(cell) or WG.tile_at(world.tiles, cell.x, cell.y) not in [0, 4]: continue
			if cell.y < int(world.surface[cell.x]) + 24: continue
			used[cell] = true
			deposits.append({"x": cell.x, "y": cell.y, "id": id, "variant": rng.randi_range(0, 2), "work": 0.0, "alive": true})
	world.background_ores = deposits
	world.background_ore_version = 1

func reset(game) -> void:
	prepare(game.world)
	entries = game.world.get("background_ores", [])
	buckets.clear(); by_cell.clear()
	for ore: Dictionary in entries:
		var cell := Vector2i(int(ore.x), int(ore.y))
		var key := Vector2i(cell.x / 32, cell.y / 32)
		if not buckets.has(key): buckets[key] = []
		buckets[key].append(ore); by_cell[cell] = ore
	if sheet == null: sheet = Art.texture("res://assets/sprites/underground/background_ores.png")

func exposed(game, cell: Vector2i) -> bool:
	return WG.tile_at(game.world.tiles, cell.x, cell.y) in [0, 4, 11] and not game.world.get("torches", {}).has("%d,%d" % [cell.x,cell.y])

func harvest(game, cell: Vector2i) -> bool:
	var ore: Dictionary = by_cell.get(cell, {})
	if ore.is_empty() or not bool(ore.get("alive", false)) or not exposed(game, cell): return false
	if game.mining_cooldown > 0: return true
	var item: String = game.equipped_tool
	if item not in ["Hammer", "Mattock"]:
		game._show_notice("Background ore: use a Hammer or Mattock")
		return true
	var bounds := Rect2(Vector2(cell * 16), Vector2(16, 16))
	if not game._in_dig_reach(cell) or not game.interactions._visible(game.player_pos + Vector2(8, 14), bounds): return true
	var level := 1 if item == "Hammer" else 2
	if level < int(game.Tools.REQUIRED_LEVEL.get(int(ore.id), 0)):
		game._show_notice("This deep seam needs a Mattock")
		return true
	game.mining_cooldown = game.Tools.MINING_SWING
	var hardness: float = game.Tools.block_hardness(int(ore.id))
	ore.work = float(ore.get("work", 0.0)) + (8.0 if item == "Hammer" else 16.0) / hardness
	if game.sound != null: game.sound.impact(3, bounds.get_center())
	if float(ore.work) >= 0.99999:
		ore.alive = false; ore.work = 1.0
		game._drop_item(game.ITEM_FOR_TILE[int(ore.id)], 1, cell)
		game._show_notice("Recovered " + game.ITEM_FOR_TILE[int(ore.id)] + " from the cave wall")
	return true

func draw(game) -> void:
	var first := Vector2i(floor(game.camera_pos / 512))
	for by in range(first.y, first.y + 3):
		for bx in range(first.x, first.x + 4):
			for ore: Dictionary in buckets.get(Vector2i(bx, by), []):
				var cell := Vector2i(int(ore.x), int(ore.y))
				if not bool(ore.get("alive", false)) or not exposed(game, cell): continue
				var at: Vector2 = Vector2(cell * 16) - game.camera_pos
				game.draw_texture_rect_region(sheet, Rect2(at, Vector2(16,16)), Rect2(int(ore.variant) * 16, (int(ore.id) - 20) * 16, 16, 16))
				if float(ore.get("work", 0.0)) > 0:
					game.draw_rect(Rect2(at + Vector2(2, 14), Vector2(12 * float(ore.work), 1)), Color("f3cd89"))
