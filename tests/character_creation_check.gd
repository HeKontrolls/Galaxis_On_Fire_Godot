extends SceneTree

const Appearance = preload("res://scripts/character_appearance.gd")
const Creator = preload("res://scripts/character_creator.gd")
var failures := 0


func _initialize() -> void:
	call_deferred("run_check")


func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		printerr(message)


func body(avatar, name: String, frame: int) -> Image:
	var image := Image.create(32, 40, false, Image.FORMAT_RGBA8)
	for texture: Texture2D in avatar.layers:
		image.blend_rect(texture.get_image(), Appearance.region(name, frame), Vector2i.ZERO)
	return image


func check_art() -> void:
	var signatures := {}
	for model in ["male", "female"]:
		var avatar := Appearance.new()
		avatar.configure({"model": model})
		signatures[model] = hash(body(avatar, "idle_east", 0).get_data())
		for action in ["idle", "walk", "jump"]:
			for frame in range(int(Appearance.animation(action + "_east")["count"])):
				var east := body(avatar, action + "_east", frame)
				var west := body(avatar, action + "_west", frame)
				for y in range(40):
					for x in range(32):
						var a := east.get_pixel(x, y)
						var b := west.get_pixel(31 - x, y)
						check((a.a == 0 and b.a == 0) or a.is_equal_approx(b), "Avatar mirrors must match at every animation pixel")
				if action != "jump":
					var grounded := false
					for x in range(32):
						grounded = grounded or east.get_pixel(x, 39).a > 0
					check(grounded, "Idle and walk frames must keep a boot on the existing ground pivot")
	check(signatures["male"] != signatures["female"], "The models must have visibly different body shapes")
	for category in ["hair", "shirt", "pants", "shoes"]:
		var looks := {}
		for index in range(Appearance.option_count(category + "_style")):
			var avatar := Appearance.new()
			avatar.configure({category + "_style": index})
			looks[hash(body(avatar, "idle_east", 0).get_data())] = true
		check(looks.size() == Appearance.option_count(category + "_style"), category + " styles must each change visible sprite pixels")
	var colors := {}
	for index in range(8):
		var avatar := Appearance.new()
		avatar.configure({"eye_color": index})
		colors[hash(body(avatar, "idle_east", 0).get_data())] = true
	check(colors.size() == 8, "All eight eye colors must be visible in the composed sprite")
	check(Appearance.frame_index("walk_east", 0.12) == 1, "Preview animation must honor native Aseprite durations")
	var invalid := Appearance.normalize({"model": "alien", "hair_style": -8, "shirt_color": 999, "skin": "oops", "pants_style": null})
	check(invalid["model"] == "male" and invalid["hair_style"] == 0 and invalid["shirt_color"] == 11 and invalid["skin"] == 0,
		"Invalid saved choices must normalize safely")


func run_check() -> void:
	check_art()
	var game = load("res://main.tscn").instantiate()
	game.save_path = "user://character_creation_check.json"
	game.settings_path = "user://character_creation_settings_check.json"
	root.add_child(game)
	await process_frame
	game.set_process(false)
	check(game.character_appearance.is_empty(), "A legacy session must retain its original character")
	game._menu_click(Vector2(150, 250))
	check(game.scene_name == "new_game", "New Game must open character creation")
	var creator = game.character_creator
	for category: String in ["hair", "shirt", "pants", "shoes"]:
		var key := category + "_style"
		for _index in range(Appearance.option_count(key)):
			var before := int(creator.appearance[key])
			game._menu_click(Vector2(842, float(Creator.ROWS[category]) + 24))
			check(creator.appearance[key] == (before + 1) % Appearance.option_count(key), "Style arrows must cycle " + category)
	for category: String in Creator.ROWS:
		var key := "skin" if category == "skin" else ("eye_color" if category == "eyes" else category + "_color")
		for index in range(creator.palette(category).size()):
			game._menu_click(Creator.swatch_rect(category, index).get_center())
			creator.refresh()
			check(creator.appearance[key] == index and creator.avatar.appearance[key] == index, "Color selection must update preview: " + key)
	game._menu_click(Vector2(724, 181))
	check(creator.appearance["model"] == "female", "Female model button must change the draft")
	game._menu_click(Vector2(834, 663))
	check(game.scene_name == "menu" and game.character_appearance.is_empty(), "Cancel must leave the active character unchanged")
	game._menu_key(KEY_ENTER)
	game._menu_click(Vector2(1024, 183))
	check(Appearance.normalize(creator.appearance) == creator.appearance, "Randomize must produce a valid full outfit")
	game._menu_click(Vector2(324, 515))
	check(creator.appearance == Appearance.DEFAULT, "Reset must restore all default appearance choices")
	game._menu_click(Creator.NAME_RECT.get_center())
	check(game.text_focus == "name", "Name field must receive keyboard focus")
	game._menu_key(KEY_TAB)
	check(game.text_focus == "seed", "Tab must move to the seed field")
	game._menu_click(Creator.RANDOM_SEED_RECT.get_center())
	check(game.seed_text.is_valid_int() and int(game.seed_text) > 0, "Random Seed button must populate a usable numeric seed")
	creator.appearance = Appearance.normalize({"model": "female", "hair_style": 6, "hair_color": 3, "skin": 4,
		"eye_color": 2, "shirt_style": 2, "shirt_color": 4, "pants_style": 2, "pants_color": 8, "shoes_style": 2, "shoes_color": 11})
	creator.dirty = true
	game.new_game_name = "   "
	game._menu_click(Creator.CREATE_RECT.get_center())
	check(game.scene_name == "new_game" and game.character_appearance.is_empty(), "Empty name must block creation without committing appearance")
	game.new_game_name = "  Nova  "
	game.seed_text = "character test"
	game._menu_click(Creator.CREATE_RECT.get_center())
	var chosen: Dictionary = creator.appearance.duplicate()
	check(game.scene_name == "galaxy" and game.player_name == "Nova" and game.galaxy_seed == game._seed_from_text("character test"),
		"Create must retain name trimming and deterministic text seeds")
	check(game.character_appearance == chosen and game.arm_textures.size() == 1 and game.arm_textures["solid_arm"] == game.character_avatar.arms["solid_arm"],
		"Selected body and articulated arm must both enter gameplay")
	await game._open_planet(0)
	game.set_process(false)
	game._save_game()
	game._apply_character_appearance({"model": "male"})
	game._load_game()
	for _frame in range(4):
		await process_frame
	check(game.character_appearance == chosen and game.player_name == "Nova", "Appearance and name must round-trip through an actual planet save")
	game.scene_name = "menu"
	game._menu_key(KEY_ENTER)
	game._menu_click(Vector2(585, 181))
	game._menu_click(Creator.BACK_RECT.get_center())
	check(game.character_appearance == chosen and game.character_avatar.appearance == chosen, "Discarding a new draft must preserve the active custom body and arms")
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(game.save_path))
	data.erase("character_appearance")
	var file := FileAccess.open(game.save_path, FileAccess.WRITE)
	file.store_string(JSON.stringify(data))
	file.close()
	game._load_game()
	for _frame in range(4):
		await process_frame
	check(game.character_appearance.is_empty() and not game.arm_textures.is_empty(), "Loading an old save must restore the legacy body and arm")
	for path: String in [game.save_path, game.settings_path]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	print("CHARACTER_CREATION models, unique styles, colors, all animation mirrors, UI, cancel, validation, seeded creation, arms, save/load, old saves: failures=", failures)
	quit(1 if failures else 0)
