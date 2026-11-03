extends RefCounted

const WG = preload("res://scripts/world_gen.gd")
const Slots = preload("res://scripts/station_slots.gd")
const TIMES := {"Copper Ingot": 8.0, "Iron Ingot": 11.0, "Gold Ingot": 9.0,
	"Netherite Scrap": 16.0, "Netherite Ingot": 18.0}
const HEAT_SECONDS := 5.0
var g
var focus_key := ""

func _init(game) -> void:
	g = game

static func timed(recipe: Dictionary) -> bool:
	return TIMES.has(recipe["out"])

func state(key: String) -> Dictionary:
	if not g.world.has("furnaces"):
		g.world["furnaces"] = {}
	if not g.world["furnaces"].has(key):
		g.world["furnaces"][key] = {"heat": 0.0, "jobs": [], "output": {}}
	prepare(g.world["furnaces"][key])
	return g.world["furnaces"][key]

static func prepare(machine: Dictionary) -> void:
	if not machine.has("inputs"):
		machine["inputs"] = Slots.create(6)
	if not machine.has("fuel"):
		machine["fuel"] = Slots.create(1)
	if not machine.has("heat"):
		machine["heat"] = 0.0
	if not machine.has("jobs"):
		machine["jobs"] = []
	if not machine.has("output"):
		machine["output"] = {}

func update(delta: float) -> void:
	for world: Dictionary in g.worlds.values():
		for station_key: String in world.get("furnaces", {}):
			advance(world["furnaces"][station_key], delta, g.RECIPES, not g.stations.holding_inputs(world, station_key))

static func auto_queue(machine: Dictionary, recipes: Array) -> bool:
	prepare(machine)
	if not machine["jobs"].is_empty():
		return false
	for recipe: Dictionary in recipes:
		if str(recipe.get("station", "")) != "Furnace" or (not timed(recipe) and str(recipe["out"]) != "Roasted Corn"):
			continue
		if not machine["output"].has(recipe["out"]) and machine["output"].size() >= 6:
			continue
		var materials := {}
		var fuel := {}
		for item: String in recipe["needs"]:
			if item in ["Coal Ore", "Wood"]:
				fuel[item] = recipe["needs"][item]
			else:
				materials[item] = recipe["needs"][item]
		if not Slots.ready(machine["inputs"], materials) or not Slots.ready(machine["fuel"], fuel):
			continue
		Slots.consume(machine["inputs"], materials)
		Slots.consume(machine["fuel"], fuel)
		machine["jobs"].append({"out": recipe["out"], "count": recipe["count"], "needs": recipe["needs"].duplicate(),
			"elapsed": 0.0, "duration": float(TIMES.get(recipe["out"], 6.0))})
		return true
	return false

static func advance(machine: Dictionary, delta: float, recipes: Array = [], allow_feed: bool = true) -> void:
	prepare(machine)
	var time := maxf(0.0, delta)
	var jobs: Array = machine.get("jobs", [])
	var heat := clampf(float(machine.get("heat", 0.0)), 0.0, 1.0)
	for _iteration in range(128):
		if jobs.is_empty() and allow_feed:
			auto_queue(machine, recipes)
		if jobs.is_empty():
			heat = maxf(0.0, heat - time * 0.04)
			break
		var warming := minf(time, (1.0 - heat) * HEAT_SECONDS)
		heat = minf(1.0, heat + warming / HEAT_SECONDS)
		time -= warming
		if time <= 0.000001:
			break
		var job: Dictionary = jobs[0]
		var duration := maxf(0.1, float(job["duration"]))
		var spent := minf(time, maxf(0.0, duration - float(job["elapsed"])))
		job["elapsed"] = float(job["elapsed"]) + spent
		time -= spent
		if float(job["elapsed"]) < duration - 0.000001:
			break
		var output: Dictionary = machine["output"]
		output[job["out"]] = int(output.get(job["out"], 0)) + int(job["count"])
		jobs.pop_front()
	machine["heat"] = heat

func remove(tile: Vector2i) -> Dictionary:
	var key := "%d,%d" % [tile.x, tile.y]
	var machines: Dictionary = g.world.get("furnaces", {})
	var machine: Dictionary = machines.get(key, {})
	var drops: Dictionary = machine.get("output", {}).duplicate()
	for stack: Dictionary in machine.get("inputs", []) + machine.get("fuel", []):
		if not stack.is_empty():
			drops[stack["item"]] = int(drops.get(stack["item"], 0)) + int(stack["count"])
	for job: Dictionary in machine.get("jobs", []):
		for item: String in job["needs"]:
			drops[item] = int(drops.get(item, 0)) + int(job["needs"][item])
	machines.erase(key)
	if focus_key == key:
		focus_key = ""
	return drops
