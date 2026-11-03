extends RefCounted


static func sample(seed_value: int, clock: float, weather: String) -> Dictionary:
	var phase := float(posmod(seed_value, 628)) * 0.01
	var flow := sin(clock * 0.011 + phase) * 0.8 + cos(clock * 0.023 + phase * 0.7) * 0.2
	var strength := 2.6 if weather == "Storm" else (1.5 if weather in ["Rain", "Snow"] else 1.0)
	var period := 22.0 + posmod(seed_value, 11)
	var shifted := clock + posmod(seed_value, 97)
	var cycle := int(floor(shifted / period))
	var hash_value := posmod((seed_value * 73856093) ^ (cycle * 19349663), 2147483647)
	var duration := 4.5 + float(hash_value % 35) * 0.1
	var start := 3.0 + float((hash_value / 37) % 55) * 0.1
	var progress := (fposmod(shifted, period) - start) / duration
	var gust := smoothstep(0.0, 0.22, progress) * (1.0 - smoothstep(0.62, 1.0, progress))
	var midpoint := cycle * period - posmod(seed_value, 97) + start + duration * 0.5
	var prevailing := sin(midpoint * 0.011 + phase) * 0.8 + cos(midpoint * 0.023 + phase * 0.7) * 0.2
	var direction := signf(prevailing) if absf(prevailing) > 0.03 else (1.0 if seed_value % 2 == 0 else -1.0)
	var peak := 22.0 + float((hash_value / 97) % 24)
	var speed := flow * 28.0 * strength + direction * peak * gust * (1.8 if weather == "Storm" else 1.0)
	return {"speed": speed, "gust": gust, "gusting": gust > 0.18}
