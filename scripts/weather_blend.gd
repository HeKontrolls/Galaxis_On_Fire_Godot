extends RefCounted

const Wind = preload("res://scripts/wind.gd")
const DURATION := 12.0
const COVER := {"Clear": 0.30, "Cloudy": 0.78, "Rain": 1.0, "Storm": 1.0, "Fog": 0.72,
	"Snow": 0.86, "Ashfall": 0.96, "Ember Storm": 1.0, "Volcanic Haze": 0.78}
var weights := {"Clear": 1.0}
var start := {"Clear": 1.0}
var target := "Clear"
var elapsed := DURATION
var climate := 0

static func climate_weather(value: String, planet: int) -> String:
	if planet == 4:
		return str({"Rain": "Ashfall", "Storm": "Ember Storm", "Snow": "Ashfall", "Fog": "Volcanic Haze"}.get(value, value))
	return str({"Ashfall": "Cloudy", "Ember Storm": "Storm", "Volcanic Haze": "Fog"}.get(value, value))

func reset(value: String, planet: int) -> void:
	climate = planet
	target = climate_weather(value, planet)
	if not COVER.has(target):
		target = "Clear"
	weights = {target: 1.0}
	start = weights.duplicate()
	elapsed = DURATION

func update(value: String, delta: float, planet: int) -> void:
	if planet != climate:
		var remapped := {}
		for name: String in weights:
			var mapped := climate_weather(name, planet)
			remapped[mapped] = float(remapped.get(mapped, 0.0)) + float(weights[name])
		weights = remapped
		start = weights.duplicate()
		climate = planet
		elapsed = DURATION
	var next := climate_weather(value, planet)
	if not COVER.has(next):
		next = "Clear"
	if next != target:
		start = weights.duplicate()
		target = next
		elapsed = 0.0
	elapsed = minf(DURATION, elapsed + maxf(0.0, delta))
	var t := smoothstep(0.0, DURATION, elapsed)
	weights.clear()
	for name: String in start:
		weights[name] = float(start[name]) * (1.0 - t)
	weights[target] = float(weights.get(target, 0.0)) + t

func amount(name: String) -> float:
	return float(weights.get(name, 0.0))

func rain() -> float:
	return 0.0 if climate == 4 else amount("Rain") + amount("Storm")

func snow() -> float:
	return 0.0 if climate == 4 else amount("Snow")

func coverage() -> float:
	var total := 0.0
	for name: String in weights:
		total += float(weights[name]) * float(COVER.get(name, 0.3))
	return total

func darkness() -> float:
	return amount("Storm") * 0.72 + amount("Rain") * 0.58 + (amount("Cloudy") + amount("Fog") + amount("Snow")) * 0.32 + amount("Ashfall") * 0.44 + amount("Ember Storm") * 0.65 + amount("Volcanic Haze") * 0.40

func cloud_tint() -> Color:
	return Color("e8f0f2").lerp(Color("68788b"), rain()).lerp(Color("a99b99"), amount("Ashfall") + amount("Ember Storm") + amount("Volcanic Haze"))

func wind(seed_value: int, clock: float) -> Dictionary:
	var speed := 0.0
	var gust := 0.0
	for name: String in weights:
		var state := Wind.sample(seed_value, clock, "Storm" if name == "Ember Storm" else ("Rain" if name == "Ashfall" else name))
		speed += float(state["speed"]) * float(weights[name])
		gust += float(state["gust"]) * float(weights[name])
	return {"speed": speed, "gust": gust, "gusting": gust > 0.18}

static func rain_velocity(wind_speed: float) -> Vector2:
	return Vector2(clampf(wind_speed * 4.5, -460.0, 460.0), 320.0)

func snapshot() -> Dictionary:
	return {"weights": weights.duplicate(), "start": start.duplicate(), "target": target, "elapsed": elapsed, "climate": climate}

func restore(data: Variant, value: String, planet: int) -> void:
	reset(value, planet)
	if not data is Dictionary or not data.get("weights") is Dictionary or not data.get("start") is Dictionary:
		return
	if str(data.get("target", "")) != target or int(data.get("climate", -1)) != planet:
		return
	for field in ["weights", "start"]:
		var clean := {}
		var total := 0.0
		for name: String in data[field]:
			if COVER.has(name):
				var weight := clampf(float(data[field][name]), 0.0, 1.0)
				clean[climate_weather(name, planet)] = float(clean.get(climate_weather(name, planet), 0.0)) + weight
				total += weight
		if total < 0.001:
			return
		for name: String in clean:
			clean[name] = float(clean[name]) / total
		if field == "weights":
			weights = clean
		else:
			start = clean
	elapsed = clampf(float(data.get("elapsed", DURATION)), 0.0, DURATION)
