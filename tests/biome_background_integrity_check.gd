extends SceneTree

# Run with the normal renderer: this catches gaps in the actual composited
# viewport, including camera positions that ordinary ground-level previews hide.
const WG = preload("res://scripts/world_gen.gd")
var failures := 0
var rendered := 0

class BackdropView extends Node2D:
	const SCREEN := Vector2(1280, 720)
	const BG = preload("res://scripts/biome_backgrounds.gd")
	const Blend = preload("res://scripts/weather_blend.gd")
	const SKY := Color("ed17d0")
	var biome_backgrounds := BG.new()
	var weather_blend := Blend.new()
	var world := {}
	var camera_pos := Vector2.ZERO
	var player_pos := Vector2.ZERO
	var time_of_day := 0.25
	var animation_clock := 42.0
	var cloud_cover := 0.0
	var wind_drift := 0.0
	var caption := ""
	var inspection := false

	func _star_light_color() -> Color:
		return Color.WHITE

	func _rain_strength() -> float:
		return weather_blend.rain()

	func _wind_speed() -> float:
		return 22.0

	func _draw() -> void:
		draw_rect(Rect2(Vector2.ZERO, SCREEN), Color("78a9ca") if inspection else SKY)
		biome_backgrounds.draw_sky(self)
		biome_backgrounds.draw(self, SKY)
		if inspection:
			draw_rect(Rect2(8, 8, 480, 36), Color("172b39"))
			draw_string(ThemeDB.fallback_font, Vector2(18, 34), caption, HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Color.WHITE)

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		printerr(message)

func capture(view: BackdropView) -> Image:
	view.queue_redraw()
	await process_frame
	await RenderingServer.frame_post_draw
	rendered += 1
	return root.get_texture().get_image()

func check_coverage(view: BackdropView, image: Image, label: String, seam: bool) -> void:
	var sky_pixels := 0
	for x in range(1280):
		if image.get_pixel(x, 719).is_equal_approx(BackdropView.SKY):
			sky_pixels += 1
	check(sky_pixels == 0, "%s: exposed sky below landscape (%d pixels)" % [label, sky_pixels])
	if seam:
		var bottom := int(view.biome_backgrounds.plane_origin(view.camera_pos, 2).y) + 512
		if bottom > 0 and bottom < 720:
			var discontinuities := 0
			for x in range(1280):
				if image.get_pixel(x, bottom - 1) != image.get_pixel(x, bottom):
					discontinuities += 1
			check(discontinuities == 0, "%s: horizontal line at panorama footing (%d pixels)" % [label, discontinuities])

func elevated_gameplay_review() -> void:
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.set_process(false)
	game.galaxy_seed = 741927
	game._make_system()
	await game._open_planet(0)
	var columns: PackedByteArray = game.world["biomes"]
	var column := 600
	for candidate in range(90, 1110):
		if columns[candidate] == 3 and columns[candidate - 30] == 3 and columns[candidate + 30] == 3:
			column = candidate
			break
	var ground := 1
	while ground < WG.HEIGHT - 2 and not WG.is_solid(WG.tile_at(game.world["tiles"], column, ground)):
		ground += 1
	# A disposable survey scaffold reproduces the elevated viewpoint in the report.
	for y in range(ground - 18, ground):
		game._edit_tile(Vector2i(column, y), 9)
	game.player_pos = Vector2(column * 16, (ground - 18) * 16 - 28)
	game._update_camera()
	game.time_of_day = 0.25
	game.weather = "Clear"
	game.weather_blend.reset("Clear", 0)
	game.cloud_cover = 0.26
	game.notice_timer = 0
	game.queue_redraw()
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://tests/background_elevated_view_review.png")
	game.queue_free()
	await process_frame

func run() -> void:
	root.size = Vector2i(1280, 720)
	var view := BackdropView.new()
	view.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	root.add_child(view)
	var overview := Image.create(1920, 2160, false, Image.FORMAT_RGBA8)
	var temp := OS.get_environment("TEMP").path_join("GalaxisBackgroundReview")
	DirAccess.make_dir_recursive_absolute(temp)
	for climate in range(8):
		var surface := PackedInt32Array()
		surface.resize(WG.WIDTH)
		surface.fill(125)
		view.world = {"climate": climate, "seed": 741927, "surface": surface}
		view.biome_backgrounds.reset(view.world)
		view.weather_blend.reset("Clear", climate)
		view.player_pos = Vector2(600 * 16, view.biome_backgrounds.datum - 28)
		view.biome_backgrounds.boundaries.clear()
		for biome in range(4):
			view.biome_backgrounds.columns.fill(biome)
			var label: String = view.biome_backgrounds.scene_for(biome)["label"]
			for offset in [-1600, -900, 0, 900]:
				view.camera_pos = Vector2(8361.25 + biome * 349, view.biome_backgrounds.datum - 374 + offset)
				var image := await capture(view)
				check_coverage(view, image, "%s / camera %d" % [label, offset], true)
			view.camera_pos.y = view.biome_backgrounds.datum - 374 - 300
			view.time_of_day = 0.75
			check_coverage(view, await capture(view), label + " / night", true)
			view.time_of_day = 0.25
			view.weather_blend.reset("Storm", climate)
			check_coverage(view, await capture(view), label + " / storm", false)
			view.weather_blend.reset("Clear", climate)
			view.inspection = true
			view.caption = label
			view.camera_pos.y = view.biome_backgrounds.datum - 374
			var image := await capture(view)
			image.resize(480, 270, Image.INTERPOLATE_NEAREST)
			overview.blit_rect(image, Rect2i(0, 0, 480, 270), Vector2i(biome * 480, climate * 270))
			# Full-size contact sheets stay in TEMP, outside the cleaned tests folder.
			if climate in [0, 1, 3, 6]:
				view.camera_pos.y -= 300
				var closeup := await capture(view)
				closeup.save_png(temp.path_join("%d_%d.png" % [climate, biome]))
			view.inspection = false
		view.biome_backgrounds.boundaries.assign([600])
		for left in range(4):
			for right in range(4):
				if left == right:
					continue
				for x in range(WG.WIDTH):
					view.biome_backgrounds.columns[x] = left if x < 600 else right
				view.camera_pos = Vector2(8341.25, view.biome_backgrounds.datum - 374 - 300)
				check_coverage(view, await capture(view), "Climate %d transition %d/%d" % [climate, left, right], false)
		print("BACKGROUND_RENDER_AUDIT climate=", climate, " regions=4 camera_heights=4 directed_transitions=12")
	overview.save_png("res://tests/biome_background_integrity_review.png")
	view.queue_free()
	await process_frame
	await elevated_gameplay_review()
	print("BACKGROUND_RENDER_INTEGRITY rendered=", rendered, " failures=", failures)
	quit(0 if failures == 0 else 1)
