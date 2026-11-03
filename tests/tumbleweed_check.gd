extends SceneTree

const Life = preload("res://scripts/ground_life.gd")
const WG = preload("res://scripts/world_gen.gd")

class NoLava:
	extends RefCounted
	func amount_at(_tile: Vector2i) -> int:
		return 0

class Field:
	extends RefCounted
	var world := {}
	var camera_pos := Vector2.ZERO
	var player_pos := Vector2.ZERO
	var animation_clock := 0.0
	var wind := 60.0
	var lava_sim := NoLava.new()
	var sound = null
	var drops := 0
	func _wind_speed() -> float:
		return wind
	func _drop_item(_item, _count, _tile) -> void:
		drops += 1

var failures := 0

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		printerr(message)

func setup(shape: String) -> Array:
	var game := Field.new()
	var grid := PackedByteArray()
	grid.resize(WG.WIDTH * WG.HEIGHT)
	for x in range(WG.WIDTH):
		var top := 40
		if shape == "stairs":
			top -= clampi((x - 32) / 4 + 1, 0, 3) if x >= 32 else 0
		elif shape == "drop" and x >= 32:
			top = 48
		elif shape == "wall" and x >= 32:
			top = 30
		for y in range(top, WG.HEIGHT):
			WG.set_tile(grid, x, y, 5)
	game.world["tiles"] = grid
	var life := Life.new()
	var entry := {"id": 1, "species": "tumbleweed", "x": 440.0, "y": 640.0, "phase": 0.0, "direction": 1, "alive": true}
	life.entries = [entry]
	life._index(entry)
	return [game, life, entry]

func advance(game, life, entry: Dictionary, seconds: float, fps: int = 60) -> void:
	for frame in range(int(seconds * fps)):
		game.camera_pos = Vector2(float(entry["x"]) - 640, float(entry["y"]) - 400)
		game.animation_clock += 1.0 / fps
		life.update(game, 1.0 / fps)
		check(not life._tumble_blocked(game.world["tiles"], Vector2(entry["x"], entry["y"])), "Tumbleweed penetrated terrain")

func _initialize() -> void:
	for shape in ["flat", "stairs", "drop", "wall"]:
		var f := setup(shape)
		advance(f[0], f[1], f[2], 14.0)
		var entry: Dictionary = f[2]
		if shape == "wall":
			check(float(entry["x"]) < 512, "Must stop at tall walls")
		else:
			check(float(entry["x"]) > 680, "Must travel east across " + shape)
			check(absf(float(entry["y"]) - (592 if shape == "stairs" else (768 if shape == "drop" else 640))) < 1, "Must settle on terrain: " + shape)
		check(bool(entry["alive"]) and f[0].drops == 0, "Rolling and falling must not auto-harvest")
		check(f[1].state[1]["chunk"] == floori(float(entry["x"]) / 512), "Moving tumbleweed must remain indexed")
		print("TUMBLEWEED ", shape, " x=", entry["x"], " y=", entry["y"])
	var f := setup("flat")
	var stair := setup("stairs")
	stair[2]["x"] = 520.0
	stair[2]["y"] = 624.0
	advance(stair[0], stair[1], stair[2], 10.0)
	check(float(stair[2]["x"]) > 680, "Legacy plants overhanging steps must become free to roll")
	stair[0].wind = -60.0
	advance(stair[0], stair[1], stair[2], 14.0)
	check(float(stair[2]["x"]) < 500 and absf(float(stair[2]["y"]) - 640) < 1, "Must descend stairs toward the west")
	advance(f[0], f[1], f[2], 3.0)
	var east: float = f[2]["x"]
	f[0].wind = -60.0
	advance(f[0], f[1], f[2], 5.0)
	check(float(f[2]["x"]) < east - 100, "Wind reversal must reverse rolling")
	f[0].wind = 0.0
	advance(f[0], f[1], f[2], 2.0)
	var stopped: float = f[2]["x"]
	advance(f[0], f[1], f[2], 2.0)
	check(absf(float(f[2]["x"]) - stopped) < 0.1, "Calm wind must let tumbleweeds stop")
	var slow := setup("flat")
	var fast := setup("flat")
	advance(slow[0], slow[1], slow[2], 6.0, 30)
	advance(fast[0], fast[1], fast[2], 6.0, 120)
	check(absf(float(slow[2]["x"]) - float(fast[2]["x"])) < 1, "Movement must be independent of frame rate")
	f[1].load_art()
	check(f[1].harvest_at(f[0], Vector2(f[2]["x"], f[2]["y"] - 19)), "Rolling plants must remain harvestable")
	check(f[0].drops == 1 and not f[2]["alive"], "Harvest must produce one item")
	print("TUMBLEWEED_CHECK failures=", failures)
	quit(0 if failures == 0 else 1)
