extends SceneTree

const WG = preload("res://scripts/world_gen.gd")
const Crash = preload("res://scripts/crash_site.gd")
const Life = preload("res://scripts/ground_life.gd")
var failures := 0

class Field:
	extends RefCounted
	var world: Dictionary
	func _walkable_y(x: int) -> int:
		for y in range(4, WG.HEIGHT - 3):
			if WG.is_solid(WG.tile_at(world["tiles"], x, y)) and (WG.tile_at(world["tiles"], x, y - 1) == 0 or WG.is_flora(WG.tile_at(world["tiles"], x, y - 1))):
				return y * 16
		return -1

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		printerr(message)

func _initialize() -> void:
	for seed_value in [741927, 713, 19001]:
		var field := Field.new()
		field.world = WG.generate(seed_value, 0, false)
		field.world["torches"] = {}
		var spawn: Vector2 = field.world["spawn"]
		var center := int(spawn.x / 16) - 20
		var build := Vector2i(center, int(field.world["surface"][center]) - 1)
		WG.set_tile(field.world["tiles"], build.x, build.y, 33)
		field.world["torches"]["%d,%d" % [build.x, build.y - 1]] = true
		var original: PackedByteArray = field.world["tiles"].duplicate()
		var progress := {"ship": [center * 16 + 8, build.y * 16], "stage": 5, "core": true}
		check(Crash.prepare(field, progress, false), "No safe crash site found for seed " + str(seed_value))
		if not progress.has("crash_site_bounds"):
			continue
		var bounds: Array = progress["crash_site_bounds"]
		var cx := (int(bounds[0]) + int(bounds[1])) / 2
		var floor_y := int(bounds[2])
		check(WG.tile_at(field.world["tiles"], build.x, build.y) == 33, "Existing player structure was changed")
		check(progress["stage"] == 5 and progress["core"], "Layout migration changed quest progress")
		for x in range(cx - 6, cx + 7):
			check(field._walkable_y(x) == floor_y * 16, "Pod floor must be flat across its whole width")
			for y in range(floor_y, floor_y + 6):
				check(WG.is_solid(WG.tile_at(field.world["tiles"], x, y)), "Impact floor must have solid support")
		check(int(field.world["surface"][cx - 9]) < floor_y - 1 and int(field.world["surface"][cx + 9]) < floor_y - 1, "Displaced blocks must rise on both sides")
		check(not Life._clear_ground(field.world, cx, floor_y), "Natural plants must not spawn through the pod")
		check(Life._clear_ground(field.world, cx, floor_y, false), "Player placement must remain possible at the impact site")
		var unexpected := 0
		for i in range(original.size()):
			if original[i] != field.world["tiles"][i] and (i % WG.WIDTH < int(bounds[0]) or i % WG.WIDTH > int(bounds[1])):
				unexpected += 1
		check(unexpected == 0, "Crash preparation modified terrain outside the chosen site")
		WG.set_tile(field.world["tiles"], cx, floor_y, 0)
		var edited: PackedByteArray = field.world["tiles"].duplicate()
		check(Crash.prepare(field, progress), "Prepared site should restore metadata")
		check(field.world["tiles"] == edited, "Reloading regenerated a mined impact block")
		print("CRASH_SITE seed=", seed_value, " center=", cx, " flat_floor=", floor_y, " protected_build=", build)
	print("CRASH_SITE_CHECK failures=", failures)
	quit(0 if failures == 0 else 1)
