extends RefCounted

const WG = preload("res://scripts/world_gen.gd")
const Art = preload("res://scripts/sprite_art.gd")
const ROOT := "res://assets/sprites/backgrounds/"
const SPEEDS := [0.035, 0.085, 0.18]
const VERTICAL := [0.08, 0.16, 0.27]
const TOP := [36.0, 64.0, 80.0]
const BLEND_TILES := 18.0
var catalog: Dictionary = {}
var climate := 0
var seed_value := 0
var datum := 0.0
var columns := PackedByteArray()
var boundaries: Array[int] = []
var textures := {}
var life: Texture2D
var atmosphere: Texture2D
var diagnostic := {"planes": 0, "ambient": 0}


func reset(world: Dictionary) -> void:
	if catalog.is_empty():
		catalog = JSON.parse_string(FileAccess.get_file_as_string(ROOT + "catalog.json"))
		life = Art.texture(ROOT + "background_life.png")
		var canvas := CanvasTexture.new()
		canvas.diffuse_texture = Art.texture(ROOT + "background_atmosphere.png")
		canvas.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		atmosphere = canvas
	climate = clampi(int(world.get("climate", 0)), 0, 7)
	seed_value = int(world.get("seed", 0))
	columns = world.get("biomes", PackedByteArray())
	if columns.size() != WG.WIDTH:
		columns = WG.Biomes.generate(seed_value, climate)
	boundaries.clear()
	for x in range(1, columns.size()):
		if columns[x] != columns[x - 1]:
			boundaries.append(x)
	var levels: Array[int] = []
	for value in world.get("surface", PackedInt32Array([125])):
		levels.append(int(value))
	levels.sort()
	datum = float(levels[levels.size() / 2] if not levels.is_empty() else 125) * WG.TILE
	if climate in [1, 2, 6]:
		datum = minf(datum, float(world.get("sea_level", 98)) * WG.TILE)
	textures.clear()
	# Load four regions during planet loading. Drawing never reads files or tiles.
	for biome in range(4):
		var scene: Dictionary = catalog["scenes"][climate * 4 + biome]
		var planes: Array[Texture2D] = []
		for name: String in catalog["planes"]:
			planes.append(Art.texture(ROOT + str(scene["id"]) + "/" + name + ".png"))
		textures[biome] = planes


func scene_for(biome: int) -> Dictionary:
	return catalog["scenes"][climate * 4 + clampi(biome, 0, 3)]


func weights_at(column: float) -> Array[Dictionary]:
	var at := clampi(floori(column), 0, WG.WIDTH - 1)
	for boundary in boundaries:
		if absf(column - boundary) <= BLEND_TILES:
			var mix := smoothstep(-BLEND_TILES, BLEND_TILES, column - boundary)
			return [{"biome": int(columns[boundary - 1]), "weight": 1.0 - mix}, {"biome": int(columns[boundary]), "weight": mix}]
	return [{"biome": int(columns[at]), "weight": 1.0}]


func plane_origin(camera: Vector2, plane: int) -> Vector2:
	var x := -fposmod(camera.x * SPEEDS[plane] + posmod(seed_value, 640) * 2, 1280.0)
	var y: float = TOP[plane] - (camera.y + 374.0 - datum) * VERTICAL[plane]
	return Vector2(x, roundf(y))


func surface_visibility(game) -> float:
	var column := clampi(floori((game.player_pos.x + 8) / WG.TILE), 0, WG.WIDTH - 1)
	var surface: PackedInt32Array = game.world.get("surface", PackedInt32Array())
	var ceiling := float(surface[column]) * WG.TILE if surface.size() == WG.WIDTH else datum
	if climate in [1, 2, 6]:
		ceiling = minf(ceiling, float(game.world.get("sea_level", 98)) * WG.TILE)
	return 1.0 - smoothstep(24.0, 160.0, game.player_pos.y + 28.0 - ceiling)


func footing_rect(origin: Vector2, screen_height: float) -> Rect2:
	var top := maxf(0.0, origin.y + 512.0)
	return Rect2(origin.x, top, 1280.0, maxf(0.0, screen_height - top))


func daylight_tint(daylight: float, darkness: float, star: Color) -> Color:
	var tint := Color("354663").lerp(Color.WHITE, daylight)
	tint = tint.lerp(Color(tint.r * star.r, tint.g * star.g, tint.b * star.b), 0.07 * daylight)
	return tint.lerp(tint * Color("9fadb9"), clampf(darkness, 0.0, 1.0))


func draw_sky(game) -> void:
	if textures.is_empty() or climate not in [6, 7]:
		return
	var daylight := clampf(sin(game.time_of_day * TAU), 0.0, 1.0)
	if daylight < 0.45:
		_draw_aurora(game, (1.0 - daylight / 0.45) * surface_visibility(game) * (1.0 - game.cloud_cover))


func draw(game, sky: Color) -> void:
	diagnostic = {"planes": 0, "ambient": 0}
	if textures.is_empty():
		return
	var visibility := surface_visibility(game)
	if visibility <= 0.001:
		return
	var daylight := clampf(sin(game.time_of_day * TAU), 0.0, 1.0)
	var region := weights_at((game.player_pos.x + 8) / WG.TILE)
	var tint := daylight_tint(daylight, game.weather_blend.darkness(), game._star_light_color())
	var weather_haze: float = game.weather_blend.amount("Fog") * 0.45 + game._rain_strength() * 0.20
	for plane in range(3):
		var origin := plane_origin(game.camera_pos, plane)
		for entry: Dictionary in region:
			var weight := float(entry["weight"])
			if weight < 0.001:
				continue
			var color := tint
			color.a = weight * visibility * (1.0 - weather_haze * (0.65 - plane * 0.18))
			var texture: Texture2D = textures[int(entry["biome"])][plane]
			for repeat in range(2):
				var at := origin + Vector2(repeat * 1280, 0)
				game.draw_texture_rect(texture, Rect2(at, Vector2(1280, 512)), false, color)
				var footing := footing_rect(at, game.SCREEN.y)
				if footing.size.y > 0.0:
					# Extend the flat Aseprite footing, never the terrain silhouette.
					game.draw_texture_rect_region(texture, footing, Rect2(0, 255, 640, 1), color)
				diagnostic["planes"] += 1
			_draw_landmarks(game, scene_for(int(entry["biome"])), plane, origin, color)
	_draw_life(game, region, daylight, visibility, tint)


func _draw_aurora(game, strength: float) -> void:
	if strength < 0.01:
		return
	var clock: float = game.animation_clock
	var frame := int(clock / 4.0) % 3
	var next := (frame + 1) % 3
	var mix := fposmod(clock / 4.0, 1.0)
	var x := -fposmod(game.camera_pos.x * 0.012 + seed_value, 1024.0)
	for repeat in range(3):
		var rect := Rect2(x + repeat * 1024, -12 + sin(clock * 0.025) * 8, 1024, 250)
		game.draw_texture_rect_region(atmosphere, rect, Rect2(frame * 128, 0, 128, 96), Color(1, 1, 1, strength * (1.0 - mix)))
		game.draw_texture_rect_region(atmosphere, rect, Rect2(next * 128, 0, 128, 96), Color(1, 1, 1, strength * mix))


func _draw_landmarks(game, scene: Dictionary, plane: int, origin: Vector2, tint: Color) -> void:
	for marker: Dictionary in scene.get("smoke", []):
		if int(marker["plane"]) != plane:
			continue
		var frame := 3 + int(game.animation_clock * 0.6 + float(marker["x"])) % 3
		for repeat in range(2):
			var at := origin + Vector2(float(marker["x"]) * 2 + repeat * 1280, float(marker["y"]) * 2)
			var lean: float = clampf(game._wind_speed() * 0.14, -12, 12)
			game.draw_texture_rect_region(atmosphere, Rect2(at + Vector2(-64 + lean, -90), Vector2(128, 96)), Rect2(frame * 128, 0, 128, 96), tint)
	for fall: Dictionary in scene.get("falls", []):
		if plane != 1:
			continue
		for repeat in range(2):
			for streak in range(4):
				var at := origin + Vector2(float(fall["x"]) * 2 + repeat * 1280, float(fall["y"]) * 2 + fposmod(game.animation_clock * 31 + streak * 23, 82))
				game.draw_texture_rect_region(life, Rect2(at - Vector2(8, 0), Vector2(16, 12)), Rect2((9 + int(game.animation_clock * 5) % 3) * 16, 0, 16, 12), tint)


func _draw_life(game, region: Array[Dictionary], daylight: float, visibility: float, tint: Color) -> void:
	var fair: float = clampf(1.0 - game._rain_strength() - game.weather_blend.snow() - game.weather_blend.amount("Ashfall") - game.weather_blend.amount("Ember Storm"), 0.0, 1.0)
	for entry: Dictionary in region:
		var scene := scene_for(int(entry["biome"]))
		var weight := float(entry["weight"]) * visibility * fair
		if weight < 0.001:
			continue
		if str(scene["wildlife"]) != "none" and daylight > 0.08:
			var base_frame := 3 if scene["wildlife"] == "gull" else 0
			for flock in range(3):
				var speed := 11.0 + posmod(seed_value + flock * 71, 9)
				var x := fposmod(seed_value * 0.7 + flock * 521 + game.animation_clock * speed + game.wind_drift * 0.08 - game.camera_pos.x * 0.05, 1500.0) - 100
				var y := 145.0 + flock * 42 + sin(game.animation_clock * 0.13 + flock) * 14
				for bird in range(3):
					var at := Vector2(x - bird * 15, y + bird * 7)
					var frame := base_frame + int(game.animation_clock * 6 + bird * 0.7) % 3
					var color := tint
					color.a = weight * smoothstep(0.08, 0.25, daylight) * 0.85
					game.draw_texture_rect_region(life, Rect2(at, Vector2(16, 12)), Rect2(frame * 16, 0, 16, 12), color)
					diagnostic["ambient"] += 1
		if bool(scene["fireflies"]) and daylight < 0.30:
			for mote in range(12):
				var x := fposmod(seed_value + mote * 137.0 - game.camera_pos.x * 0.2, 1320.0) - 20 + sin(game.animation_clock * 0.6 + mote) * 9
				var y := 220.0 + posmod(mote * 71, 113) + sin(game.animation_clock * 0.8 + mote * 2) * 8
				var frame := 6 + int(game.animation_clock * 2.7 + mote) % 3
				var pulse := 0.4 + 0.6 * maxf(0.0, sin(game.animation_clock * 1.2 + mote))
				game.draw_texture_rect_region(life, Rect2(x, y, 16, 12), Rect2(frame * 16, 0, 16, 12), Color(1, 1, 1, weight * pulse * (1.0 - daylight / 0.30)))
				diagnostic["ambient"] += 1
