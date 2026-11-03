extends SceneTree

const WG = preload("res://scripts/world_gen.gd")
var failures := 0

func _initialize() -> void:
	call_deferred("run_check")

func run_check() -> void:
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	var grid := PackedByteArray()
	grid.resize(WG.WIDTH * WG.HEIGHT)
	var surface := PackedInt32Array()
	surface.resize(WG.WIDTH)
	surface.fill(40)
	var corners := 0
	for id in [1, 2, 3, 5, 6]:
		grid.fill(0)
		for cell in [Vector2i(17, 17), Vector2i(18, 17), Vector2i(17, 18), Vector2i(18, 18)]:
			WG.set_tile(grid, cell.x, cell.y, id)
		game.world = {"tiles": grid, "surface": surface}
		game.terrain_cache.reset(game)
		var rendered: Image = game.terrain_cache._build(Vector2i(2, 2))["front"].get_image()
		var material: String = game._terrain_material(id)
		var source: Image = game.terrain_sheets[material].get_image()
		var frame: Vector2i = game._terrain_frame(grid, 17, 17, material)
		for y in range(16):
			for x in range(16):
				var alpha := source.get_pixel(frame.x + x, frame.y + y).a
				if alpha == 0.0:
					corners += 1
				if absf(rendered.get_pixel(16 + x, 16 + y).a - alpha) > 0.01:
					failures += 1
		if WG.make_texture(grid).get_image().get_pixel(17, 17).a != 0.0:
			failures += 1
	if corners == 0:
		failures += 1
	print("TERRAIN_CORNERS transparent_pixels=%d failures=%d" % [corners, failures])
	game.free()
	quit(0 if failures == 0 else 1)
