extends RefCounted

const WG = preload("res://scripts/world_gen.gd")
var rain_budget := 0.0
var maintenance_budget := 0.0
var rng := RandomNumberGenerator.new()


func reset(seed_value: int) -> void:
	rain_budget = 0.0
	maintenance_budget = 0.0
	rng.seed = seed_value ^ 0xBADC10D


func update(center_x: int, delta: float, raining: bool, storm: bool, sun: float, roof: PackedInt32Array, water, lava = null, intensity: float = 1.0) -> void:
	if raining:
		rain_budget = minf(rain_budget + maxf(0.0, delta) * clampf(intensity, 0.0, 1.0), 1.0)
		while rain_budget >= 0.5:
			rain_budget -= 0.5
			for _drop in range(8):
				var x := rng.randi_range(maxi(1, center_x - 45), mini(WG.WIDTH - 2, center_x + 45))
				var y := roof[x] - 1
				if lava != null and lava.has_fluid:
					for surface_y in range(roof[x]):
						var at := Vector2i(x, surface_y)
						if water.amount_at(at) > 0:
							y = surface_y - 1 if water.amount_at(at) == 255 else surface_y
							break
						if lava.amount_at(at) > 0:
							lava.cool_from_rain(at, 6 if storm else 3)
							y = -1
							break
				if y > 0 and y < WG.HEIGHT - 1:
					var tile := Vector2i(x, y)
					var space := maxi(0, (48 if storm else 32) - water.amount_at(tile))
					water.add_rain(tile, mini(space, 6 if storm else 3))
	else:
		rain_budget = 0.0
	# Source-cell caps alone cannot limit runoff: an empty source keeps
	# refilling while a downstream basin rises. Drain excess rain in every
	# affected column, including old saved floods, even during continuous rain.
	maintenance_budget = minf(maintenance_budget + maxf(0.0, delta), 2.0)
	while maintenance_budget >= 1.0:
		maintenance_budget -= 1.0
		water.drain_rain(roof, 64 if storm and raining else 48)
		if not raining:
			water.evaporate(roof, 2 if sun > 0.25 else 1)
