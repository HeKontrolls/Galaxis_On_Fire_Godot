extends Node2D

const WG = preload("res://scripts/world_gen.gd")
const Furnishings = preload("res://scripts/furnishings.gd")
var furnishings := Furnishings.new()
const BackgroundOres = preload("res://scripts/background_ores.gd")
var background_ores := BackgroundOres.new()
const SandGravity = preload("res://scripts/sand_gravity.gd")
var sand_gravity := SandGravity.new()
const UIText = preload("res://scripts/ui_text.gd")
const WaterRipples = preload("res://scripts/water_ripples.gd")
var water_ripples := WaterRipples.new()
const WildlifeMobs = preload("res://scripts/wildlife_mobs.gd")
var wildlife_mobs := WildlifeMobs.new()
const Underground = preload("res://scripts/underground.gd")
var underground := Underground.new()
const FlyingMonsters = preload("res://scripts/flying_monsters.gd")
var flying_monsters := FlyingMonsters.new()
const HangingVines = preload("res://scripts/hanging_vines.gd")
var hanging_vines := HangingVines.new()
const PlanetMonsters = preload("res://scripts/planet_monsters.gd")
var planet_monsters := PlanetMonsters.new()
const DevControls = preload("res://scripts/dev_controls.gd")
const FoliageRenderer = preload("res://scripts/foliage.gd")
const FoodCatalog = preload("res://scripts/food.gd")
const CropCatalog = preload("res://scripts/crop_catalog.gd")
const Farming = preload("res://scripts/farming.gd")
const Precipitation = preload("res://scripts/precipitation.gd")
const WaterSimulation = preload("res://scripts/water_sim.gd")
const LavaSimulation = preload("res://scripts/lava_sim.gd")
const Snowfall = preload("res://scripts/snowfall.gd")
const WindModel = preload("res://scripts/wind.gd")
const AtmosphereLighting = preload("res://scripts/world_environment.gd")
const OreCatalog = preload("res://scripts/ore_catalog.gd")
const TerrainCache = preload("res://scripts/terrain_cache.gd")
const BiomeBackgrounds = preload("res://scripts/biome_backgrounds.gd")
const SurfaceEffects = preload("res://scripts/surface_effects.gd")
const FluidRenderer = preload("res://scripts/fluid_renderer.gd")
const FluidReactions = preload("res://scripts/fluid_reactions.gd")
const Materials = preload("res://scripts/materials.gd")
const Tools = preload("res://scripts/tool_catalog.gd")
const GameAudio = preload("res://scripts/game_audio.gd")
const SpriteArt = preload("res://scripts/sprite_art.gd")
const PlayerPose = preload("res://scripts/player_pose.gd")
const GroundLife = preload("res://scripts/ground_life.gd")
const CharacterAppearance = preload("res://scripts/character_appearance.gd")
const CharacterCreator = preload("res://scripts/character_creator.gd")
const Hotbar = preload("res://scripts/hotbar.gd")
const WorldInteractions = preload("res://scripts/world_interactions.gd")
const ToolWear = preload("res://scripts/tool_wear.gd")
const FurnaceSystem = preload("res://scripts/furnace_system.gd")
const StationWindows = preload("res://scripts/station_windows.gd")
const Expedition = preload("res://scripts/expedition.gd")
const WeatherBlend = preload("res://scripts/weather_blend.gd")
const OceanPreparation = preload("res://scripts/ocean_preparation.gd")
const ITEM_CATALOG = ["Dirt", "Stone", "Wood", "Sand", "Snow", "Grass", "Planks", "Cobblestone", "Workbench", "Furnace", "Torch", "Chest", "Leaves", "Crop Seeds", "Corn", "Roasted Corn", "Obsidian", "Gravel"] + GroundLife.ITEMS + Furnishings.ITEMS + CropCatalog.NEW_ITEMS
const SCREEN := Vector2(1280, 720)
const SAVE_PATH := "user://galaxis_save.json"
const SETTINGS_PATH := "user://galaxis_settings.json"
const MAIN_MENU_ITEMS := ["New Game", "Load Game", "Settings", "How to Play", "Host Game", "Join Game", "Quit"]
const SETTINGS_TABS := ["Gameplay", "Video", "Audio", "Controls"]
const RECIPE_TABS := ["Basic", "Workbench", "Furnace"]
const RECIPE_GROUPS := [[0, 1, 2, 3, 4, 5], [0, 1, 2, 3, 4, 5, 6, 7, 8, 12, 13, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49], [9, 10, 11, 14, 25, 26, 50, 51, 52, 53]]
const RECIPE_PAGE_SIZE := 6
const HOTBAR_X := 400.0
const HOTBAR_Y := 650.0
const HOTBAR_STEP := 54.0
const HOTBAR_SIZE := 48.0
const HUD_PACK_RECT := Rect2(16, 81, 42, 40)
const HUD_CRAFT_RECT := Rect2(66, 81, 42, 40)
const HUD_PAGE_RECTS := [Rect2(543, 700, 27, 14), Rect2(576, 700, 27, 14), Rect2(609, 700, 27, 14), Rect2(642, 700, 27, 14), Rect2(675, 700, 27, 14), Rect2(708, 700, 27, 14)]
const SPEED := 235.0
const GRAVITY := 1100.0
const JUMP_SPEED := -430.0
const REACH := 112.0
const DIG_REACH := 4.0 * WG.TILE
const ITEM_FOR_TILE := {
	1: "Grass", 2: "Dirt", 3: "Stone", 5: "Sand", 6: "Snow", 7: "Wood", 12: "Dirt", 13: "Dirt",
	9: "Wood", 10: "Cobblestone", 17: "Obsidian", 33: "Planks", 20: "Coal Ore", 21: "Copper Ore",
	22: "Iron Ore", 23: "Gold Ore", 24: "Crystal", 30: "Chest",
	25: "Diamond", 26: "Ancient Debris", 27: "Glacial Ice",
	45: "Gravel",
}
const TILE_FOR_ITEM := {
	"Grass": 1, "Dirt": 2, "Stone": 3, "Sand": 5, "Snow": 6,
	"Wood": 9, "Planks": 33, "Cobblestone": 10, "Chest": 30,
	"Leaves": 8, "Obsidian": 17,
	"Glacial Ice": 27,
	"Gravel": 45,
}
const RECIPES := [
	{"name": "Planks x4", "out": "Planks", "count": 4, "needs": {"Wood": 1}},
	{"name": "Sticks x4", "out": "Stick", "count": 4, "needs": {"Planks": 1}},
	{"name": "Torch x4", "out": "Torch", "count": 4, "needs": {"Stick": 1, "Coal Ore": 1}},
	{"name": "Cobblestone", "out": "Cobblestone", "count": 1, "needs": {"Stone": 1}},
	{"name": "Workbench", "out": "Workbench", "count": 1, "needs": {"Planks": 8}},
	{"name": "Chest", "out": "Chest", "count": 1, "needs": {"Planks": 8, "Stick": 2}},
	{"name": "Furnace", "out": "Furnace", "count": 1, "needs": {"Cobblestone": 12}, "station": "Workbench"},
	{"name": "Wood Pickaxe", "out": "Pickaxe", "count": 1, "needs": {"Planks": 6, "Stick": 3}, "station": "Workbench"},
	{"name": "Wood Sword", "out": "Sword", "count": 1, "needs": {"Planks": 6, "Stick": 3}, "station": "Workbench"},
	{"name": "Copper Ingot", "out": "Copper Ingot", "count": 1, "needs": {"Copper Ore": 1, "Coal Ore": 1}, "station": "Furnace"},
	{"name": "Iron Ingot", "out": "Iron Ingot", "count": 1, "needs": {"Iron Ore": 1, "Coal Ore": 1}, "station": "Furnace"},
	{"name": "Gold Ingot", "out": "Gold Ingot", "count": 1, "needs": {"Gold Ore": 1, "Coal Ore": 1}, "station": "Furnace"},
	{"name": "Wood Hoe", "out": "Hoe", "count": 1, "needs": {"Planks": 4, "Stick": 2}, "station": "Workbench"},
	{"name": "Copper Watering Can", "out": "Watering Can", "count": 1, "needs": {"Copper Ingot": 3, "Planks": 2}, "station": "Workbench"},
	{"name": "Roasted Corn (+30 HP)", "out": "Roasted Corn", "count": 1, "needs": {"Corn": 1, "Wood": 1}, "station": "Furnace"},
	{"name": "Wood Axe", "out": "Axe", "count": 1, "needs": {"Planks": 6, "Stick": 3}, "station": "Workbench"},
	{"name": "Copper Pickaxe", "out": "Copper Pickaxe", "count": 1, "needs": {"Stone Pickaxe": 1, "Copper Ingot": 6, "Stick": 3}, "station": "Workbench"},
	{"name": "Copper Sword", "out": "Copper Sword", "count": 1, "needs": {"Sword": 1, "Copper Ingot": 6, "Stick": 3}, "station": "Workbench"},
	{"name": "Copper Axe", "out": "Copper Axe", "count": 1, "needs": {"Axe": 1, "Copper Ingot": 6, "Stick": 3}, "station": "Workbench"},
	{"name": "Iron Pickaxe", "out": "Iron Pickaxe", "count": 1, "needs": {"Copper Pickaxe": 1, "Iron Ingot": 8, "Stick": 4}, "station": "Workbench"},
	{"name": "Iron Sword", "out": "Iron Sword", "count": 1, "needs": {"Copper Sword": 1, "Iron Ingot": 8, "Stick": 4}, "station": "Workbench"},
	{"name": "Iron Axe", "out": "Iron Axe", "count": 1, "needs": {"Copper Axe": 1, "Iron Ingot": 8, "Stick": 4}, "station": "Workbench"},
	{"name": "Stone Pickaxe", "out": "Stone Pickaxe", "count": 1, "needs": {"Pickaxe": 1, "Cobblestone": 6, "Stick": 2}, "station": "Workbench"},
	{"name": "Gold Pickaxe", "out": "Gold Pickaxe", "count": 1, "needs": {"Pickaxe": 1, "Gold Ingot": 3, "Stick": 3}, "station": "Workbench"},
	{"name": "Diamond Pickaxe", "out": "Diamond Pickaxe", "count": 1, "needs": {"Iron Pickaxe": 1, "Diamond": 3, "Stick": 3}, "station": "Workbench"},
	{"name": "Netherite Scrap", "out": "Netherite Scrap", "count": 1, "needs": {"Ancient Debris": 1, "Coal Ore": 1}, "station": "Furnace"},
	{"name": "Netherite Ingot", "out": "Netherite Ingot", "count": 1, "needs": {"Netherite Scrap": 4, "Gold Ingot": 4, "Coal Ore": 1}, "station": "Furnace"},
	{"name": "Netherite Pickaxe", "out": "Netherite Pickaxe", "count": 1, "needs": {"Diamond Pickaxe": 1, "Netherite Ingot": 1}, "station": "Workbench"},
	{"name": "Wood Shovel", "out": "Shovel", "count": 1, "needs": {"Planks": 3, "Stick": 2}, "station": "Workbench"},
	{"name": "Stone Shovel", "out": "Stone Shovel", "count": 1, "needs": {"Shovel": 1, "Cobblestone": 3, "Stick": 2}, "station": "Workbench"},
	{"name": "Copper Shovel", "out": "Copper Shovel", "count": 1, "needs": {"Stone Shovel": 1, "Copper Ingot": 3, "Stick": 2}, "station": "Workbench"},
	{"name": "Iron Shovel", "out": "Iron Shovel", "count": 1, "needs": {"Copper Shovel": 1, "Iron Ingot": 4, "Stick": 2}, "station": "Workbench"},
	{"name": "Gold Shovel", "out": "Gold Shovel", "count": 1, "needs": {"Shovel": 1, "Gold Ingot": 3, "Stick": 2}, "station": "Workbench"},
	{"name": "Diamond Shovel", "out": "Diamond Shovel", "count": 1, "needs": {"Iron Shovel": 1, "Diamond": 2, "Stick": 2}, "station": "Workbench"},
	{"name": "Netherite Shovel", "out": "Netherite Shovel", "count": 1, "needs": {"Diamond Shovel": 1, "Netherite Ingot": 1}, "station": "Workbench"},
	{"name": "Hull Plate", "out": "Hull Plate", "count": 1, "needs": {"Iron Ingot": 4, "Planks": 8}, "station": "Workbench"},
	{"name": "Drive Coil", "out": "Drive Coil", "count": 1, "needs": {"Copper Ingot": 4, "Iron Ingot": 4, "Crystal": 2}, "station": "Workbench"},
	{"name": "Mattock", "out": "Mattock", "count": 1, "needs": {"Iron Ingot": 4, "Stick": 2}, "station": "Workbench"},
	{"name": "Hammer", "out": "Hammer", "count": 1, "needs": {"Cobblestone": 4, "Iron Ingot": 2, "Stick": 2}, "station": "Workbench"},
	{"name": "Wooden Chair", "out": "Wooden Chair", "count": 1, "needs": {"Planks": 4, "Stick": 2}, "station": "Workbench"},
	{"name": "Wooden Table", "out": "Wooden Table", "count": 1, "needs": {"Planks": 8, "Stick": 4}, "station": "Workbench"},
	{"name": "Wooden Ladder x4", "out": "Wooden Ladder", "count": 4, "needs": {"Planks": 2, "Stick": 4}, "station": "Workbench"},
	{"name": "Fireplace", "out": "Fireplace", "count": 1, "needs": {"Cobblestone": 12, "Wood": 4, "Torch": 1}, "station": "Workbench"},
	{"name": "Wooden Wall x4", "out": "Wooden Wall", "count": 4, "needs": {"Planks": 1}, "station": "Workbench"},
	{"name": "Wooden Door", "out": "Wooden Door", "count": 1, "needs": {"Planks": 6, "Stick": 2}, "station": "Workbench"},
	{"name": "Crop Seeds x3", "out": "Crop Seeds", "count": 3, "needs": {"Corn": 1}, "station": "Workbench"},
	{"name": "Carrot Seeds x3", "out": "Carrot Seeds", "count": 3, "needs": {"Carrot": 1}, "station": "Workbench"},
	{"name": "Seed Potatoes x2", "out": "Seed Potato", "count": 2, "needs": {"Potato": 1}, "station": "Workbench"},
	{"name": "Tomato Seeds x3", "out": "Tomato Seeds", "count": 3, "needs": {"Tomato": 1}, "station": "Workbench"},
	{"name": "Wheat Seeds x3", "out": "Wheat Seeds", "count": 3, "needs": {"Wheat": 1}, "station": "Workbench"},
	{"name": "Baked Potato (+25 HP)", "out": "Baked Potato", "count": 1, "needs": {"Potato": 1, "Wood": 1}, "station": "Furnace"},
	{"name": "Tomato Soup (+35 HP)", "out": "Tomato Soup", "count": 1, "needs": {"Tomato": 2, "Wood": 1}, "station": "Furnace"},
	{"name": "Bread (+30 HP)", "out": "Bread", "count": 1, "needs": {"Wheat": 3, "Wood": 1}, "station": "Furnace"},
	{"name": "Vegetable Stew (+50 HP)", "out": "Vegetable Stew", "count": 1, "needs": {"Carrot": 1, "Potato": 1, "Tomato": 1, "Wood": 1}, "station": "Furnace"},
]

var scene_name := "menu"
var save_path := SAVE_PATH
var settings_path := SETTINGS_PATH
var settings_data := {"day_length": 480.0, "night_dark": 0.40, "fullscreen": false,
	"master_volume": 0.8, "effects_volume": 0.8, "ambience_volume": 0.65}
var sound
var settings_return := "menu"
var load_return := "menu"
var settings_tab := "Gameplay"
var load_summary := {}
var confirm_return := "menu"
var confirm_action := ""
var player_name := "Enter Name"
var new_game_name := "Enter Name"
var character_appearance := {}
var character_avatar := CharacterAppearance.new()
var character_creator := CharacterCreator.new()
var seed_text := ""
var text_focus := "name"
var galaxy_seed := 12589134
var star_points: Array[Vector2] = []
var star_names: Array[String] = []
var star_types: Array[String] = []
var star_index := 0
var planet_index := 0
var selected_planet_index := -1
var system_planets: Array[Dictionary] = []
var system_hab_inner := 0.9
var system_hab_outer := 1.7
var worlds := {}
var world := {}
var grass_pending := {}
var foliage := FoliageRenderer.new()
var water_sim := WaterSimulation.new()
var lava_sim := LavaSimulation.new()
var snowfall := Snowfall.new()
var wind_cache := {}
var wind_cache_clock := -1.0
var wind_cache_seed := -1
var wind_cache_weather := ""
var wind_drift := 0.0
var lava_hurt_timer := 0.0
var lava_flash := 0.0
var farming := Farming.new()
var farms := {}
var crop_sheet: Texture2D
var food := FoodCatalog.new()
var food_cooldown := 0.0
var eat_visual := 0.0
var food_feedback_timer := 0.0
var last_food := "Corn"
var last_heal := 0
var precipitation := Precipitation.new()
var environment := AtmosphereLighting.new()
var ores := OreCatalog.new()
var terrain_cache := TerrainCache.new()
var biome_backgrounds := BiomeBackgrounds.new()
var surface_effects := SurfaceEffects.new()
var ground_life := GroundLife.new()
var fluid_renderer := FluidRenderer.new()
var fluid_reactions := FluidReactions.new()
var primary_held := false
var secondary_held := false
var primary_repeat := 0.0
var secondary_repeat := 0.0
var aim_screen := Vector2.ZERO
var mouse_aim_screen := Vector2.ZERO
var mouse_aim_valid := false
var mouse_aim_direction := Vector2.RIGHT
var mining_feedback_tile := Vector2i(-1, -1)
var mining_feedback_progress := 0.0
var mining_feedback_timer := 0.0
var world_texture: ImageTexture
var world_image: Image
var logo: Texture2D
var explorer_sprite: Texture2D
var cloud_texture: ImageTexture
var cloud_textures: Array[ImageTexture] = []
var clouds: Array[Dictionary] = []
var cloud_rng := RandomNumberGenerator.new()
var tool_textures := {}
var terrain_sheets := {}
var player_frames := {}
var elder_frames := {}
var sprite_art := SpriteArt.new()
var station_frames := {}
var arm_textures := {}
var animation_clock := 0.0
var player_pos := Vector2.ZERO
var player_velocity := Vector2.ZERO
var player_grounded := false
var facing := 1
var health := 100
var damage_cooldown := 0.0
var attack_cooldown := 0.0
var mining_cooldown := 0.0
var attack_visual := 0.0
var tool_action_timer := 0.0
var tool_action_duration := 0.32
var tool_action_kind := ""
var tool_action_target := Vector2.ZERO
var equipped_tool := "Hand"
var dev_mode := false
var dev_travel_unlocked := false
var dev_invulnerable := false
var dev_free_flight := false
var dev_controls: RefCounted
var inventory := {}
var selected_slot := 0
var hotbar_page := 0
var hotbar := Hotbar.new()
var tool_wear := ToolWear.new()
var furnaces := FurnaceSystem.new(self)
var stations := StationWindows.new(self)
var expedition := Expedition.new(self)
var inventory_order: Array[String] = []
var weather_blend := WeatherBlend.new()
var pending_weather_blend: Dictionary = {}
var place_items: Array[String]:
	get:
		return hotbar.slots
var use_pickaxe := false
var use_hoe := false
var crafting_open := false
var inventory_open := false
var inventory_trash := {}
var inventory_drag_item := ""
var inventory_drag_start := Vector2.ZERO
var inventory_dragging := false
var inventory_drag_slot := -1
var inventory_page := 0
var interactions: RefCounted
var recipe_tab := 0
var dialogue_open := false
var recipe_index := 0
var paused := false
var time_of_day := 0.25
var day_count := 1
var weather_timer := 0.0
var weather_cycle := 0
var weather := "Clear"
var cloud_cover := 0.30
var window_positions := {"inventory": Vector2(407, 205), "crafting": Vector2(360, 105),
	"dialogue": Vector2(225, 445), "dev": Vector2(20, 80), "pause": Vector2(405, 145)}
var dragged_window := ""
var drag_offset := Vector2.ZERO
var camera_pos := Vector2.ZERO
var notice := ""
var notice_timer := 0.0
var load_progress := ""
var profile_enabled := false
var profile_stats := {}
var ring_mesh: ArrayMesh
var ring_mesh_key := -1


func _ready() -> void:
	dev_controls = DevControls.new(self)
	interactions = WorldInteractions.new(self)
	window_positions["chest"] = Vector2(660, 205)
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_load_settings()
	sound = GameAudio.new(self)
	add_child(sound)
	sound.configure(settings_data)
	logo = load("res://assets/galaxis_on_fire_logo.png")
	explorer_sprite = load("res://assets/old_explorer.png")
	for variant in range(10):
		cloud_textures.append(_make_cloud_texture(variant))
	cloud_texture = cloud_textures[0]
	tool_textures = Tools.make_textures()
	ground_life.load_art()
	station_frames = sprite_art.stations()
	character_avatar.configure(CharacterAppearance.DEFAULT)
	arm_textures = character_avatar.arms.duplicate()
	for material in ["grass", "dirt", "stone", "sand", "snow"]:
		terrain_sheets[material] = load("res://assets/sprites/terrain/%s_autotile.png" % material)
	terrain_sheets["wood"] = load("res://assets/sprites/terrain/placed_wood_block.png")
	terrain_sheets["planks"] = load("res://assets/sprites/terrain/wood_wall_block.png")
	terrain_sheets["tree"] = load("res://assets/sprites/terrain/tree_tiles_18x18.png")
	terrain_sheets["ore"] = load("res://assets/sprites/terrain/ore_overlays.png")
	terrain_sheets["glacial_ice"] = SpriteArt.texture("res://assets/sprites/glacial_spires/glacial_body.png")
	terrain_sheets["glacial_edges"] = SpriteArt.texture("res://assets/sprites/glacial_spires/glacial_edges.png")
	terrain_sheets["chest"] = load("res://assets/sprites/terrain/chest.png")
	terrain_sheets["torch"] = load("res://assets/sprites/terrain/torch.png")
	terrain_sheets["obsidian"] = Materials.obsidian_atlas()
	terrain_sheets["gravel"] = SpriteArt.texture("res://assets/sprites/terrain/gravel.png")
	player_frames = sprite_art.actor("captain")
	elder_frames = sprite_art.actor("robot_guide")
	explorer_sprite = elder_frames["idle_east"][0]
	_make_galaxy()
	queue_redraw()


func _load_settings() -> void:
	if not FileAccess.file_exists(settings_path):
		return
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(settings_path))
	if not parsed is Dictionary:
		return
	settings_data["day_length"] = clampf(float(parsed.get("day_length", 480.0)), 60.0, 1800.0)
	settings_data["night_dark"] = clampf(float(parsed.get("night_dark", 0.40)), 0.0, 0.90)
	settings_data["fullscreen"] = bool(parsed.get("fullscreen", false))
	for key in ["master_volume", "effects_volume", "ambience_volume"]:
		settings_data[key] = clampf(float(parsed.get(key, settings_data[key])), 0.0, 1.0)
	player_name = str(parsed.get("player_name", "Captain")).substr(0, 24)
	new_game_name = player_name
	if settings_data["fullscreen"]:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	if sound != null:
		sound.configure(settings_data)


func _save_settings() -> void:
	var data := settings_data.duplicate()
	data["player_name"] = player_name
	var file := FileAccess.open(settings_path, FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(data))
		file.close()


func _seed_from_text(value: String) -> int:
	var clean := value.strip_edges()
	if clean.is_valid_int():
		return maxi(1, abs(int(clean)) % 2147483647)
	var result := 2166136261
	for byte in clean.to_utf8_buffer():
		result = ((result ^ int(byte)) * 16777619) & 0x7fffffff
	return maxi(1, result)


func _start_new_game() -> void:
	var clean_name := new_game_name.strip_edges()
	if clean_name.is_empty():
		_show_notice("Enter a captain name")
		return
	player_name = clean_name.substr(0, 24)
	_apply_character_appearance(character_creator.appearance)
	_save_settings()
	if seed_text.strip_edges().is_empty():
		var random_seed := RandomNumberGenerator.new()
		random_seed.randomize()
		galaxy_seed = random_seed.randi_range(1, 2147483646)
	else:
		galaxy_seed = _seed_from_text(seed_text)
	worlds.clear()
	farms.clear()
	expedition.start()
	stations.close(false)
	inventory_order.clear()
	furnaces.focus_key = ""
	pending_weather_blend.clear()
	interactions.close(false)
	_stop_held_actions()
	world = {}
	star_index = 0
	planet_index = 0
	selected_planet_index = -1
	health = 100
	food_cooldown = 0.0
	eat_visual = 0.0
	food_feedback_timer = 0.0
	inventory = {}
	hotbar.clear()
	tool_wear.uses.clear()
	selected_slot = 0
	hotbar_page = 0
	equipped_tool = "Hand"
	use_pickaxe = false
	use_hoe = false
	mining_cooldown = 0.0
	attack_cooldown = 0.0
	tool_action_timer = 0.0
	dev_mode = false
	dev_travel_unlocked = false
	dev_invulnerable = false
	dev_free_flight = false
	inventory_trash.clear()
	inventory_drag_item = ""
	inventory_dragging = false
	inventory_drag_slot = -1
	inventory_page = 0
	crafting_open = false
	inventory_open = false
	recipe_tab = 0
	time_of_day = 0.25
	day_count = 1
	weather = "Clear"
	weather_blend.reset("Clear", 0)
	weather_timer = 0.0
	weather_cycle = 0
	cloud_cover = 0.30
	paused = false
	_make_galaxy()
	scene_name = "galaxy"
	_show_notice("New expedition ready: seed %d" % galaxy_seed)
	queue_redraw()


func _apply_character_appearance(value: Dictionary) -> void:
	if value.is_empty():
		character_appearance = {}
		character_avatar.configure(CharacterAppearance.DEFAULT)
		arm_textures = character_avatar.arms.duplicate()
		return
	character_appearance = CharacterAppearance.normalize(value)
	character_avatar.configure(character_appearance)
	arm_textures = character_avatar.arms.duplicate()


func _open_load(from_scene: String) -> void:
	load_return = from_scene
	_refresh_save_summary()
	scene_name = "load"


func _refresh_save_summary() -> void:
	load_summary = {}
	if not FileAccess.file_exists(save_path):
		return
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(save_path))
	if parsed is Dictionary and int(parsed.get("schema", -1)) in [1, 2]:
		load_summary = {
			"name": str(parsed.get("player_name", "Captain")),
			"seed": int(parsed.get("galaxy_seed", 0)),
			"worlds": parsed.get("worlds", {}).size(),
			"star": int(parsed.get("star_index", 0)) + 1,
			"planet": int(parsed.get("planet_index", 0)) + 1,
		}


func _open_settings(from_scene: String) -> void:
	settings_return = from_scene
	settings_tab = "Gameplay"
	scene_name = "settings"


func _menu_back() -> void:
	match scene_name:
		"new_game", "help": scene_name = "menu"
		"load": scene_name = load_return
		"settings": scene_name = settings_return
		"confirm": scene_name = confirm_return
	queue_redraw()


func _confirm_yes() -> void:
	if confirm_action == "quit":
		get_tree().quit()
	elif confirm_action == "delete_save":
		if FileAccess.file_exists(save_path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(save_path))
		_refresh_save_summary()
		scene_name = "load"
		_show_notice("Save deleted")


func _edit_new_game_text(event: InputEventKey) -> bool:
	if scene_name != "new_game":
		return false
	if event.keycode == KEY_BACKSPACE:
		if text_focus == "name" and not new_game_name.is_empty():
			new_game_name = new_game_name.substr(0, new_game_name.length() - 1)
		elif text_focus == "seed" and not seed_text.is_empty():
			seed_text = seed_text.substr(0, seed_text.length() - 1)
		queue_redraw()
		return true
	if event.unicode >= 32 and event.unicode < 0x110000 and not event.ctrl_pressed and not event.alt_pressed:
		var typed := char(event.unicode)
		if text_focus == "name" and new_game_name.length() < 24:
			new_game_name += typed
		elif text_focus == "seed" and seed_text.length() < 48:
			seed_text += typed
		queue_redraw()
		return true
	return false


func _menu_key(key: Key) -> void:
	if key == KEY_ESCAPE:
		_menu_back()
		return
	if scene_name == "menu" and key == KEY_ENTER:
		scene_name = "new_game"
		character_creator.reset(character_appearance)
		new_game_name = player_name
		seed_text = ""
		text_focus = "name"
	elif scene_name == "new_game":
		if key == KEY_TAB:
			text_focus = "seed" if text_focus == "name" else "name"
		elif key == KEY_ENTER:
			_start_new_game()
	elif scene_name == "load" and key == KEY_ENTER and not load_summary.is_empty():
		_load_game()
	elif scene_name == "confirm" and key == KEY_ENTER:
		_confirm_yes()


func _menu_click(point: Vector2) -> void:
	match scene_name:
		"menu":
			for i in range(MAIN_MENU_ITEMS.size()):
				if not Rect2(52, 228 + i * 61, 268, 51).has_point(point):
					continue
				match MAIN_MENU_ITEMS[i]:
					"New Game":
						scene_name = "new_game"
						character_creator.reset(character_appearance)
						new_game_name = player_name
						seed_text = ""
						text_focus = "name"
					"Load Game": _open_load("menu")
					"Settings": _open_settings("menu")
					"How to Play": scene_name = "help"
					"Host Game", "Join Game": _show_notice("Multiplayer is not in the Godot build yet")
					"Quit":
						confirm_action = "quit"
						confirm_return = "menu"
						scene_name = "confirm"
				return
		"new_game":
			character_creator.click(self, point)
		"load":
			if Rect2(330, 520, 190, 50).has_point(point) and not load_summary.is_empty(): _load_game()
			elif Rect2(540, 520, 190, 50).has_point(point) and not load_summary.is_empty():
				confirm_action = "delete_save"
				confirm_return = "load"
				scene_name = "confirm"
			elif Rect2(750, 520, 200, 50).has_point(point): _menu_back()
		"settings":
			for i in range(SETTINGS_TABS.size()):
				if Rect2(280 + i * 180, 160, 165, 42).has_point(point):
					settings_tab = SETTINGS_TABS[i]
					return
			if settings_tab == "Gameplay":
				if Rect2(735, 260, 60, 48).has_point(point): settings_data["day_length"] = maxf(120.0, float(settings_data["day_length"]) - 60.0)
				elif Rect2(815, 260, 60, 48).has_point(point): settings_data["day_length"] = minf(1200.0, float(settings_data["day_length"]) + 60.0)
				elif Rect2(735, 350, 60, 48).has_point(point): settings_data["night_dark"] = maxf(0.0, float(settings_data["night_dark"]) - 0.05)
				elif Rect2(815, 350, 60, 48).has_point(point): settings_data["night_dark"] = minf(0.85, float(settings_data["night_dark"]) + 0.05)
				_save_settings()
			elif settings_tab == "Video" and Rect2(620, 260, 270, 50).has_point(point):
				settings_data["fullscreen"] = not bool(settings_data["fullscreen"])
				DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if settings_data["fullscreen"] else DisplayServer.WINDOW_MODE_WINDOWED)
				_save_settings()
			elif settings_tab == "Audio":
				for row in range(3):
					var key: String = ["master_volume", "effects_volume", "ambience_volume"][row]
					for direction in [-1, 1]:
						var button := Rect2(735 if direction < 0 else 815, 260 + row * 80, 60, 44)
						if button.has_point(point):
							settings_data[key] = clampf(snappedf(float(settings_data[key]) + direction * 0.1, 0.05), 0.0, 1.0)
							sound.configure(settings_data)
							_save_settings()
				if Rect2(300, 500, 215, 42).has_point(point):
					sound.audition()
			if Rect2(790, 550, 190, 48).has_point(point): _menu_back()
		"help":
			if Rect2(790, 550, 190, 48).has_point(point): _menu_back()
		"confirm":
			if Rect2(420, 410, 190, 50).has_point(point): _confirm_yes()
			elif Rect2(670, 410, 190, 50).has_point(point): _menu_back()


func _pause_click(point: Vector2) -> void:
	var at: Vector2 = window_positions["pause"]
	if Rect2(at + Vector2(428, 15), Vector2(30, 30)).has_point(point):
		paused = false
		dragged_window = ""
		return
	if Rect2(at, Vector2(470, 66)).has_point(point):
		_start_window_drag("pause", point)
		return
	var labels := ["Resume", "Save Game", "Load Game", "Settings", "Save & Main Menu", "Save & Quit"]
	for i in range(labels.size()):
		if not Rect2(at + Vector2(35, 73 + i * 58), Vector2(400, 46)).has_point(point):
			continue
		match labels[i]:
			"Resume": paused = false
			"Save Game": _save_game()
			"Load Game": _open_load("planet")
			"Settings": _open_settings("planet")
			"Save & Main Menu":
				_save_game()
				paused = false
				scene_name = "menu"
			"Save & Quit":
				_save_game()
				confirm_action = "quit"
				confirm_return = "planet"
				scene_name = "confirm"
		return


func _make_galaxy() -> void:
	star_points.clear()
	star_names.clear()
	star_types.clear()
	var rng := RandomNumberGenerator.new()
	rng.seed = galaxy_seed
	var type_rng := RandomNumberGenerator.new()
	type_rng.seed = galaxy_seed ^ 0x51A7E
	var greek := ["Alpha", "Beta", "Gamma", "Delta", "Epsilon", "Zeta", "Theta", "Lambda"]
	var constellations := ["Cygnus", "Orionis", "Draconis", "Pegasi", "Lyrae", "Ceti", "Andromedae"]
	for i in range(80):
		star_points.append(Vector2(rng.randi_range(65, 1215), rng.randi_range(130, 635)))
		star_names.append("%s %s-%03d" % [greek[i % greek.size()], constellations[rng.randi_range(0, constellations.size() - 1)], rng.randi_range(1, 999)])
		var spectral_roll := type_rng.randi_range(0, 82)
		var spectral := "M"
		for type_data in [["O", 1], ["B", 2], ["A", 4], ["F", 8], ["G", 16], ["K", 22], ["M", 30]]:
			spectral_roll -= int(type_data[1])
			if spectral_roll < 0:
				spectral = type_data[0]
				break
		star_types.append(spectral)


func _open_system(index: int) -> void:
	star_index = index
	selected_planet_index = -1
	_make_system()
	scene_name = "system"


func _make_system() -> void:
	system_planets.clear()
	var hz: Dictionary = {
		"O": [4.0, 10.0], "B": [3.0, 7.0], "A": [2.2, 4.5],
		"F": [1.3, 2.4], "G": [0.9, 1.7], "K": [0.5, 1.0], "M": [0.2, 0.5],
	}
	system_hab_inner = hz[star_types[star_index]][0]
	system_hab_outer = hz[star_types[star_index]][1]
	var rng := RandomNumberGenerator.new()
	rng.seed = galaxy_seed + star_index * 104729 + 12345
	for i in range(8):
		var climate := _planet_climate(i)
		var au := _orbit_au(i, climate)
		var in_hab := au >= system_hab_inner and au <= system_hab_outer
		# Keep the old RNG sequence for planet size, moons, and rings.
		var old_au := 0.35 + float(i) * 0.42
		var old_life_roll := rng.randf() if old_au >= system_hab_inner and old_au <= system_hab_outer and climate in [0, 1, 2] else 1.0
		var life_rng := RandomNumberGenerator.new()
		life_rng.seed = _planet_seed(i) ^ 0x11FE
		var life := in_hab and climate in [0, 1, 2] and (old_life_roll < 0.65 or (old_life_roll == 1.0 and life_rng.randf() < 0.65))
		system_planets.append({
			"name": "%s %s" % [star_names[star_index], char(98 + i)],
			"climate": climate, "au": au, "radius": 43.0 + float(i) * 29.0,
			"size": rng.randi_range(7, 13) + (2 if climate in [1, 2] else 0),
			"angle": rng.randf_range(0.0, TAU),
			"speed": rng.randf_range(0.05, 0.18) / (1.0 + float(i) * 0.3),
			"moons": rng.randi_range(0, 4 if i >= 4 else 3),
			"rings": rng.randf() < (0.25 if climate in [1, 2, 6, 7] else 0.17),
			"life": life, "habitable": in_hab,
		})
	var order := system_planets.duplicate()
	order.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a["au"] < b["au"])
	for rank in range(order.size()):
		order[rank]["radius"] = 43.0 + rank * 29.0


func _orbit_au(index: int, climate: int) -> float:
	var width := system_hab_outer - system_hab_inner
	var jitter := (float(posmod(_planet_seed(index), 101)) / 100.0 - 0.5) * width * 0.05
	if climate in [0, 1, 2]:
		return system_hab_inner + width * (0.2 + climate * 0.3) + jitter
	match climate:
		4: return system_hab_inner * 0.35
		3: return system_hab_inner * 0.72
		5: return system_hab_outer * 1.25
		7: return system_hab_outer * 1.65
		6: return system_hab_outer * 2.2
	return system_hab_outer * 1.25


func _system_radius_for_au(au: float) -> float:
	var order := system_planets.duplicate()
	order.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a["au"] < b["au"])
	for i in range(1, order.size()):
		if au <= float(order[i]["au"]):
			var weight := inverse_lerp(float(order[i - 1]["au"]), float(order[i]["au"]), au)
			return lerpf(float(order[i - 1]["radius"]), float(order[i]["radius"]), weight)
	return float(order.back()["radius"])


func _system_planet_position(index: int) -> Vector2:
	var info: Dictionary = system_planets[index]
	var angle: float = info["angle"] + animation_clock * info["speed"]
	return Vector2(640, 320) + Vector2(cos(angle), sin(angle)) * float(info["radius"])


func _planet_visual_color(climate: int) -> Color:
	return [Color("68be71"), Color("4e9fdb"), Color("3682c6"), Color("ddb16c"),
		Color("d16d48"), Color("9296a2"), Color("b9e7f6"), Color("cbdde1")][climate]


func _star_light_color() -> Color:
	return {"O": Color("b4dcff"), "B": Color("b4d2ff"), "A": Color("bedcff"),
		"F": Color("fff3ce"), "G": Color("ffe1a6"), "K": Color("ffc276"),
		"M": Color("f09172")}.get(star_types[star_index], Color("ffe1a6"))


func _begin_tool_action(kind: String, target: Vector2) -> void:
	_set_mouse_world_target(target)
	tool_action_kind = kind
	tool_action_target = target
	tool_action_duration = Tools.action_duration(equipped_tool, kind == "attack")
	tool_action_timer = tool_action_duration
	if sound != null:
		sound.swing(equipped_tool, player_pos + Vector2(8 + facing * 16, 14))


func _start_watering(tile: Vector2i) -> void:
	if int(inventory.get("Watering Can", 0)) <= 0:
		return
	equipped_tool = "Watering Can"
	use_hoe = false
	use_pickaxe = false
	tool_action_target = Vector2(tile * WG.TILE) + Vector2(8, 0)
	_set_mouse_world_target(tool_action_target)
	if tool_action_kind == "water" and tool_action_timer > 0.20:
		return
	tool_action_kind = "water"
	tool_action_duration = 0.9
	tool_action_timer = tool_action_duration


func _is_pouring() -> bool:
	if equipped_tool != "Watering Can" or tool_action_kind != "water" or tool_action_timer <= 0.0:
		return false
	var progress := 1.0 - tool_action_timer / tool_action_duration
	return progress >= 0.18 and progress <= 0.78


func _watering_spout_world() -> Vector2:
	# Rose center in the can SVG, relative to its shared sprite grip.
	return _held_tool_pose(player_pos) * Vector2(13, -14)


func _planet_sky_info() -> Dictionary:
	if planet_index >= 0 and planet_index < system_planets.size():
		return system_planets[planet_index]
	return {"rings": false, "moons": 0}


func _next_weather() -> String:
	var forecast_rng := RandomNumberGenerator.new()
	forecast_rng.seed = _planet_seed(planet_index) + (weather_cycle + 1) * 7919
	var roll := forecast_rng.randf()
	var cumulative := 0.0
	var profile: Dictionary = dev_controls.weather_profile()
	for value in ["Clear", "Cloudy", "Rain", "Storm", "Fog", "Snow"]:
		cumulative += float(profile[value])
		if roll <= cumulative:
			return _climate_weather(value)
	return "Clear"


func _climate_weather(value: String) -> String:
	return WeatherBlend.climate_weather(value, int(world.get("climate", -1)))


func _is_raining() -> bool:
	return _rain_strength() > 0.001


func _rain_strength() -> float:
	return 0.0 if int(world.get("climate", -1)) == 4 else weather_blend.rain()


func _cloud_target() -> float:
	return weather_blend.coverage()


func _make_cloud_texture(variant: int) -> ImageTexture:
	var image := Image.create(256, 96, false, Image.FORMAT_RGBA8)
	var shape_rng := RandomNumberGenerator.new()
	shape_rng.seed = 4196 + variant * 10007
	var noise := FastNoiseLite.new()
	noise.seed = int(shape_rng.randi())
	noise.frequency = shape_rng.randf_range(0.026, 0.053)
	noise.fractal_type = FastNoiseLite.FRACTAL_FBM
	noise.fractal_octaves = 4
	var lobes: Array[Vector4] = []
	var family := 0 if variant < 3 else (1 if variant < 8 else 2)
	var count := 3 + variant % 4 if family == 0 else (4 + variant % 4 if family == 1 else 5 + variant % 3)
	for j in range(count):
		var u := 0.17 + (float(j) + 0.5) / float(count) * 0.66 + shape_rng.randf_range(-0.045, 0.045)
		var v := shape_rng.randf_range(0.43, 0.60)
		var radius_x := shape_rng.randf_range(0.14, 0.21)
		var radius_y := shape_rng.randf_range(0.11, 0.17)
		if family == 1:
			v = shape_rng.randf_range(0.40, 0.63)
			radius_x = shape_rng.randf_range(0.14, 0.21)
			radius_y = shape_rng.randf_range(0.22, 0.32)
		elif family == 2:
			v = shape_rng.randf_range(0.38, 0.62)
			radius_x = shape_rng.randf_range(0.17, 0.22)
			radius_y = shape_rng.randf_range(0.27, 0.37)
		lobes.append(Vector4(u, v, radius_x, radius_y))
	for y in range(96):
		for x in range(256):
			var u := float(x) / 256.0
			var v := float(y) / 96.0
			var envelope := 0.0
			for lobe in lobes:
				var dx: float = (u - lobe.x) / lobe.z
				var dy: float = (v - lobe.y) / lobe.w
				envelope = maxf(envelope, 1.0 - dx * dx - dy * dy)
			var detail: float = noise.get_noise_2d(float(x), float(y)) * 0.27
			var alpha := smoothstep(0.20, 0.66, envelope + detail) * (0.72 if family == 0 else 0.90)
			var edge_fade := smoothstep(0.0, 0.11, u) * (1.0 - smoothstep(0.89, 1.0, u))
			edge_fade *= smoothstep(0.0, 0.10, v) * (1.0 - smoothstep(0.84, 0.99, v))
			alpha *= edge_fade
			var shade := clampf(0.60 + (1.0 - v) * 0.37 + detail * 0.17, 0.0, 1.0)
			image.set_pixel(x, y, Color(shade, shade, shade, alpha))
	return ImageTexture.create_from_image(image)


func _next_cloud_shape(shape: int) -> int:
	if shape < 3:
		return posmod(shape + 1 + cloud_rng.randi_range(0, 1), 3)
	if shape < 8:
		return 3 + posmod(shape - 3 + 1 + cloud_rng.randi_range(0, 3), 5)
	return 9 if shape == 8 else 8


func _init_clouds() -> void:
	clouds.clear()
	cloud_rng.seed = _planet_seed(planet_index) ^ 0xC10DD5
	for i in range(30):
		var depth := cloud_rng.randi_range(0, 2)
		var shape := posmod(i * 7 + cloud_rng.randi_range(0, 3), cloud_textures.size())
		var family := 0 if shape < 3 else (1 if shape < 8 else 2)
		var width := cloud_rng.randf_range(245.0, 380.0) if family == 0 else (cloud_rng.randf_range(130.0, 255.0) if family == 1 else cloud_rng.randf_range(225.0, 360.0))
		var aspect := cloud_rng.randf_range(0.17, 0.26) if family == 0 else (cloud_rng.randf_range(0.40, 0.58) if family == 1 else cloud_rng.randf_range(0.52, 0.69))
		clouds.append({
			"x": cloud_rng.randf_range(-330.0, SCREEN.x + 220.0),
			"y": cloud_rng.randf_range(34.0, 225.0),
			"width": width, "height": width * aspect,
			"speed": cloud_rng.randf_range(2.0, 11.0),
			"depth": depth, "shape": shape,
			"next_shape": _next_cloud_shape(shape),
			"phase": cloud_rng.randf_range(0.0, TAU),
			"age": cloud_rng.randf_range(15.0, 90.0),
			"life": cloud_rng.randf_range(105.0, 180.0),
			"threshold": (float(i) + cloud_rng.randf()) / 30.0,
		})


func _wind_speed() -> float:
	return float(_wind_state()["speed"])


func _wind_state() -> Dictionary:
	var seed_value := _planet_seed(planet_index)
	if wind_cache_clock != animation_clock or wind_cache_seed != seed_value or wind_cache_weather != weather:
		wind_cache = weather_blend.wind(seed_value, animation_clock)
		wind_cache_clock = animation_clock
		wind_cache_seed = seed_value
		wind_cache_weather = weather
	return wind_cache


func _update_clouds(delta: float) -> void:
	var wind := _wind_speed()
	wind_drift += wind * delta
	var direction := 1.0 if wind >= 0.0 else -1.0
	for cloud in clouds:
		cloud["x"] = float(cloud["x"]) + (wind * 0.23 + direction * float(cloud["speed"])) * delta
		cloud["age"] = float(cloud["age"]) + delta
		if float(cloud["x"]) > SCREEN.x + float(cloud["width"]) + 80.0 or float(cloud["x"]) < -float(cloud["width"]) - 180.0 or float(cloud["age"]) >= float(cloud["life"]):
			cloud["x"] = -float(cloud["width"]) - cloud_rng.randf_range(0.0, 150.0) if direction > 0 else SCREEN.x + cloud_rng.randf_range(40, 180)
			cloud["y"] = cloud_rng.randf_range(28.0, 230.0)
			cloud["shape"] = cloud_rng.randi_range(0, cloud_textures.size() - 1)
			cloud["next_shape"] = _next_cloud_shape(int(cloud["shape"]))
			var family := 0 if int(cloud["shape"]) < 3 else (1 if int(cloud["shape"]) < 8 else 2)
			cloud["width"] = cloud_rng.randf_range(245.0, 380.0) if family == 0 else (cloud_rng.randf_range(130.0, 255.0) if family == 1 else cloud_rng.randf_range(225.0, 360.0))
			cloud["height"] = float(cloud["width"]) * (cloud_rng.randf_range(0.17, 0.26) if family == 0 else (cloud_rng.randf_range(0.40, 0.58) if family == 1 else cloud_rng.randf_range(0.52, 0.69)))
			cloud["speed"] = cloud_rng.randf_range(2.0, 11.0)
			cloud["age"] = 0.0
			cloud["life"] = cloud_rng.randf_range(105.0, 180.0)


func _world_key() -> String:
	return "%d_%d" % [star_index, planet_index]


func _planet_climate(index: int) -> int:
	# Keep planet identities stable; _orbit_au puts their climates in the
	# correct temperature zones around each spectral type.
	return posmod(index + star_index * 3, WG.NAMES.size())


func _planet_seed(index: int) -> int:
	return galaxy_seed + star_index * 104729 + index * 19001 + _planet_climate(index) * 331


func _open_planet(index: int) -> void:
	if not expedition.can_land(index):
		return
	stations.close(false)
	interactions.close(false)
	_stop_held_actions()
	if system_planets.is_empty():
		_make_system()
	dragged_window = ""
	planet_index = index
	_init_clouds()
	scene_name = "loading"
	load_progress = "Generating " + WG.NAMES[_planet_climate(index)] + "..."
	queue_redraw()
	await get_tree().process_frame
	var key := _world_key()
	var existing := worlds.has(key)
	if existing:
		world = worlds[key]
	else:
		world = WG.generate(_planet_seed(index), _planet_climate(index), false)
		worlds[key] = world
	if int(world.get("underground_version", 0)) < 1:
		load_progress = "Expanding deep caves beneath the saved world..."
		queue_redraw()
		await get_tree().process_frame
		Underground.extend(world, WG.LEGACY_HEIGHT)
	Underground.clean_pool_rims(world)
	load("res://scripts/underworld_structures.gd").apply(world)
	if int(world["climate"]) in [1, 2] and int(world.get("ocean_fill_version", 0)) < OceanPreparation.VERSION:
		load_progress = "Checking ocean basins and connected caves..."
		queue_redraw()
		await get_tree().process_frame
		var natural := PackedByteArray()
		if existing:
			# Repair original cave connections once, preserving player excavations
			# and buildings rather than refilling every open space on each visit.
			var original: Dictionary = WG.generate(int(world["seed"]), int(world["climate"]), false)
			natural = original["tiles"]
		var ocean := OceanPreparation.new(world, natural)
		while not ocean.done:
			ocean.step(4096)
			load_progress = "Filling ocean-connected caves... %s cells checked" % String.num_int64(ocean.cursor)
			queue_redraw()
			await get_tree().process_frame
	WG.enrich_forest(world)
	if int(world["climate"]) == 6 and int(world.get("ice_spires_version", 0)) < 2:
		load_progress = "Shaping towering ice spires on untouched floes..."
		queue_redraw()
		await get_tree().process_frame
		WG.enrich_ice_spires(world)
	weather = _climate_weather(weather)
	if not world.has("creatures") or (int(world["climate"]) == 5 and world["creatures"].is_empty()):
		_make_population()
	PlanetMonsters.prepare(world)
	FlyingMonsters.prepare(world)
	if not world.has("crops"):
		world["crops"] = {}
	if not world.has("torches"):
		world["torches"] = {}
	if not world.has("placed_chests"):
		world["placed_chests"] = {}
	if not world.has("drops"):
		world["drops"] = []
	expedition.prepare()
	WildlifeMobs.prepare(world)
	_reset_world_environment()
	if not pending_weather_blend.is_empty():
		weather_blend.restore(pending_weather_blend, weather, int(world["climate"]))
		pending_weather_blend.clear()
	world_texture = WG.make_texture(world["tiles"])
	world_image = world_texture.get_image()
	foliage.reset()
	grass_pending.clear()
	for column in range(WG.WIDTH):
		_queue_grass_column(column)
	player_pos = world.get("player_pos", world["spawn"])
	player_velocity = Vector2.ZERO
	player_grounded = false
	_update_camera()
	paused = false
	crafting_open = false
	inventory_open = false
	dialogue_open = false
	scene_name = "planet"
	_show_notice("Landed on " + WG.NAMES[_planet_climate(index)])
	if expedition.home() and expedition.stage() == 0:
		_show_notice("Escape pod crashed. Find robot R0-VR [E / F] to begin repairs")
	queue_redraw()


func _leave_planet() -> void:
	if not expedition.can_launch():
		return
	dev_mode = false
	stations.close(false)
	_stop_held_actions()
	dragged_window = ""
	if not world.is_empty():
		world["player_pos"] = player_pos
		worlds[_world_key()] = world
	scene_name = "system"
	selected_planet_index = planet_index
	_make_system()
	if expedition.active():
		_show_notice("Returned to your ship in orbit")
	paused = false
	dialogue_open = false
	queue_redraw()


func _dev_visit_climate(climate: int) -> void:
	if climate < 0 or climate >= WG.NAMES.size(): return
	dev_travel_unlocked = true
	if scene_name == "planet": _leave_planet()
	dev_mode = false
	dragged_window = ""
	for index in range(8):
		if _planet_climate(index) == climate:
			selected_planet_index = index
			await _open_planet(index)
			return


func _show_notice(text_value: String) -> void:
	notice = text_value
	notice_timer = 3.5


func _walkable_y(tx: int) -> int:
	var grid: PackedByteArray = world["tiles"]
	for y in range(4, WG.HEIGHT - 3):
		if WG.is_solid(WG.tile_at(grid, tx, y)) and (WG.tile_at(grid, tx, y - 1) == 0 or WG.is_flora(WG.tile_at(grid, tx, y - 1))):
			return y * WG.TILE
	return -1


func _make_population() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = int(world["seed"]) ^ 0xB4180
	var climate: int = world["climate"]
	var count: int = PlanetMonsters.COUNTS[clampi(climate, 0, 7)]
	var creatures := []
	for i in range(count * 16):
		if creatures.size() >= count:
			break
		var tx := rng.randi_range(12, WG.WIDTH - 13)
		var sy := _walkable_y(tx)
		if sy > 0 and sy <= (int(world["surface"][tx]) + 8) * WG.TILE and absf(tx * WG.TILE - world["spawn"].x) > 192.0 and WG.tile_at(world["tiles"], tx, int(sy / WG.TILE) - 1) not in [4, 11] and expedition.guardian_fits(Vector2(tx * WG.TILE, sy - 18)):
			creatures.append({"x": float(tx * WG.TILE), "y": float(sy - 18),
				"home_x": float(tx * WG.TILE), "direction": -1 if i % 2 == 0 else 1,
				"hp": 30, "alive": true})
			PlanetMonsters.decorate(world, creatures[-1], creatures.size() - 1, true)
	world["creatures"] = creatures
	world["quest_done"] = world.get("quest_done", false)
	if climate in [0, 1, 2]:
		var npc_tx: int = clampi(int(world["spawn"].x / WG.TILE) + 10, 2, WG.WIDTH - 3)
		var npc_y := _walkable_y(npc_tx)
		if npc_y > 0:
			world["npc"] = {"x": float(npc_tx * WG.TILE), "y": float(npc_y - 29),
				"home_x": float(npc_tx * WG.TILE), "direction": -1, "move_timer": 1.0}


func _update_elder(delta: float) -> void:
	if dialogue_open:
		return
	if not world.has("npc"):
		return
	var npc: Dictionary = world["npc"]
	npc["home_x"] = float(npc.get("home_x", npc["x"]))
	npc["direction"] = int(npc.get("direction", -1))
	npc["move_timer"] = float(npc.get("move_timer", 0.0)) - delta
	if float(npc["move_timer"]) <= 0.0:
		var rng := RandomNumberGenerator.new()
		rng.seed = int(world["seed"]) + int(animation_clock * 10.0) * 919
		npc["move_timer"] = rng.randf_range(1.2, 3.4)
		if absf(float(npc["x"]) - float(npc["home_x"])) > 150.0:
			npc["direction"] = -1 if float(npc["x"]) > float(npc["home_x"]) else 1
		else:
			npc["direction"] = rng.randi_range(-1, 1)
	if int(npc["direction"]) == 0:
		return
	var target_x: float = clampf(float(npc["x"]) + int(npc["direction"]) * 23.0 * delta, 32.0, WG.WIDTH * WG.TILE - 32.0)
	if absf(target_x - float(npc["home_x"])) > 190.0:
		npc["direction"] = -int(npc["direction"])
		return
	var ground_y := _walkable_y(int(target_x / WG.TILE))
	if ground_y <= 0 or absf(float(ground_y - 29) - float(npc["y"])) > 17.0:
		npc["direction"] = -int(npc["direction"])
		npc["move_timer"] = 1.5
		return
	npc["x"] = target_x
	npc["y"] = float(ground_y - 29)


func _update_population(delta: float) -> void:
	damage_cooldown = maxf(0.0, damage_cooldown - delta)
	for creature in world.get("creatures", []):
		creature["hit_flash"] = maxf(0.0, float(creature.get("hit_flash", 0.0)) - delta)
		creature["moving"] = false
		if not creature["alive"]:
			continue
		if absf(creature["x"] - player_pos.x) > SCREEN.x:
			continue
		if bool(creature.get("wildlife", false)):
			wildlife_mobs.update(self, creature, delta)
			continue
		if bool(creature.get("flying", false)):
			flying_monsters.update(self, creature, delta)
			continue
		var guardian := bool(creature.get("quest_guardian", false))
		if guardian and absf(player_pos.y - float(creature["y"])) < 80 and absf(player_pos.x - float(creature["home_x"])) < 100:
			creature["direction"] = 1 if player_pos.x > float(creature["x"]) else -1
		var alerted := false
		if not guardian and absf(player_pos.y - float(creature["y"])) < 48.0 and absf(player_pos.x - float(creature["x"])) < float(creature.get("alert_radius", 80.0)):
			alerted = interactions._visible(Vector2(float(creature["x"]) + 12, float(creature["y"]) + 9), Rect2(player_pos, Vector2(16, 28)))
			if alerted:
				creature["direction"] = 1 if player_pos.x > float(creature["x"]) else -1
		var speed := 42.0 if guardian else float(creature.get("speed", 28.0)) * (1.35 if alerted else 1.0)
		var target_x: float = creature["x"] + float(creature["direction"]) * speed * delta
		var radius := 72.0 if guardian else float(creature.get("patrol_radius", 96.0)) * (2.0 if alerted else 1.0)
		if absf(target_x - creature["home_x"]) > radius:
			creature["direction"] = -creature["direction"]
		elif target_x >= 0.0 and target_x < WG.WIDTH * WG.TILE:
			var ground_y := expedition.guardian_ground(creature, target_x) if guardian else _walkable_y(int(target_x / WG.TILE))
			if ground_y > 0 and absf(float(ground_y - 18) - float(creature["y"])) < 24.0 and expedition.guardian_fits(Vector2(target_x, ground_y - 18)):
				creature["x"] = target_x
				creature["y"] = float(ground_y - 18)
				creature["moving"] = true
			else:
				creature["direction"] = -creature["direction"]
				if guardian and ground_y < 0:
					creature["y"] = minf(WG.HEIGHT * WG.TILE - 34, float(creature["y"]) + 120.0 * delta)
		if Vector2(creature["x"], creature["y"]).distance_to(player_pos) < 23.0 and damage_cooldown <= 0.0 and not dev_invulnerable:
			health -= int(creature.get("damage", 8))
			damage_cooldown = 1.2
			_show_notice("A creature hit you")
			if health <= 0:
				health = 100
				player_pos = world["spawn"]
				_show_notice("Respawned")


func _attack(target: Variant = null) -> void:
	if attack_cooldown > 0.0:
		return
	attack_cooldown = Tools.attack_interval(equipped_tool)
	attack_visual = 0.24
	var aimed: Vector2 = target if target != null else (mouse_aim_screen + camera_pos if mouse_aim_valid else player_pos + Vector2(8 + facing * 40, 10))
	_begin_tool_action("attack", aimed)
	var origin := player_pos + Vector2(8, 11)
	var hit_center := origin + mouse_aim_direction * 31
	for creature in world.get("creatures", []):
		if creature["alive"] and hit_center.distance_to(Vector2(creature["x"], creature["y"])) < 46.0 \
			and (Vector2(creature["x"], creature["y"]) - origin).dot(mouse_aim_direction) >= 0.0:
			if not interactions._visible(origin, Rect2(Vector2(creature["x"], creature["y"]), Vector2(24, 18))):
				continue
			creature["hp"] -= Tools.damage(equipped_tool)
			creature["hit_flash"] = 0.20
			var pushed_x := clampf(float(creature["x"]) + facing * 15.0, 0.0, WG.WIDTH * WG.TILE - 16.0)
			var can_push := WildlifeMobs.fits(world, Vector2(pushed_x, float(creature["y"]))) if creature.get("wildlife", false) else expedition.guardian_fits(Vector2(pushed_x, float(creature["y"])))
			if can_push:
				creature["x"] = pushed_x
			if creature["hp"] <= 0:
				creature["alive"] = false
				_drop_item(WildlifeMobs.loot(creature) if creature.get("wildlife", false) else "Alien Fiber", 1, Vector2i(int(creature["x"] / WG.TILE), int(creature["y"] / WG.TILE)))
				_show_notice("Creature defeated")
			else:
				_show_notice("Hit %s: %d HP" % [PlanetMonsters.display_name(creature), int(creature["hp"])])
			_wear_pickaxe(equipped_tool, 2)
			return


func _talk_to_explorer() -> void:
	if not world.has("npc"):
		return
	var npc: Dictionary = world["npc"]
	if Vector2(npc["x"], npc["y"]).distance_to(player_pos) > 85.0:
		_show_notice("Move closer to R0-VR")
		return
	if expedition.home():
		expedition.talk()
		return
	if not dialogue_open:
		dialogue_open = true
		return
	dialogue_open = false
	if world.get("quest_done", false):
		return
	if int(inventory.get("Wood", 0)) >= 20:
		inventory["Wood"] -= 20
		_add_item("Crystal", 2)
		world["quest_done"] = true
		_show_notice("Quest complete: Crystal x2")


func _update_crops(delta: float) -> void:
	expedition.update(delta)
	var sun := clampf(sin(time_of_day * TAU), 0.0, 1.0)
	_apply_farm_edits(farming.advance(0, delta, _is_raining(), environment.roof, water_sim.amounts, _rain_strength(), sun))
	# Visited farms keep growing during active planetary play, even across travel.
	for key: String in worlds:
		var data: Dictionary = worlds[key]
		if is_same(data, world): continue
		if data.get("crops", {}).is_empty() and data.get("farm_moisture", {}).is_empty(): continue
		if not farms.has(key):
			var other := Farming.new()
			other.bind_world(data)
			farms[key] = other
		var other = farms[key]
		var changes: Array = other.advance(0, delta, false, PackedInt32Array(), data.get("water", PackedByteArray()), 0, sun)
		var grid: PackedByteArray = data.tiles
		for edit: Vector3i in changes:
			WG.set_tile(grid, edit.x, edit.y, edit.z)
			other.track(Vector2i(edit.x, edit.y), edit.z)
		data.tiles = grid


func _apply_farm_edits(edits: Array) -> void:
	for edit in edits:
		_edit_tile(Vector2i(edit.x, edit.y), edit.z, false)
	if not edits.is_empty():
		world_texture.update(world_image)


func _farm_space_clear(tile: Vector2i) -> bool:
	for dy in range(3):
		var at := tile + Vector2i(0, -dy)
		if WG.tile_at(world.tiles, at.x, at.y) != 0 or not furnishings.at(at).is_empty(): return false
	for entry: Dictionary in ground_life.entries:
		if not bool(entry.get("alive", false)) or GroundLife.animal(str(entry.species)): continue
		var base := Vector2(float(entry.x), float(entry.y))
		if absf(base.x - (tile.x * 16 + 8)) < 12 and absf(base.y - (tile.y + 1) * 16) < 8: return false
	return true


func _farm_interaction(tile: Vector2i, tool: String, selected: String) -> bool:
	if Tools.family(equipped_tool) == "Sword": return false
	var target := farming.plant_target(tile)
	if target.x >= 0:
		tile = target + Vector2i.DOWN if tool == "Watering Can" else target
	if not _in_dig_reach(tile): return false
	var result := farming.interaction(tile, tool, selected)
	if not result.handled: return false
	var consume := str(result.consume)
	if not consume.is_empty():
		if int(inventory.get(consume, 0)) <= 0:
			_show_notice("No " + consume + " in inventory")
			return true
		var edit: Vector3i = result.edits[0]
		if not _farm_space_clear(Vector2i(edit.x, edit.y)):
			_show_notice("Clear the plants or furniture before planting")
			return true
		inventory[consume] -= 1
	farming.commit(result)
	_apply_farm_edits(result.edits)
	if result.has("watered"): _start_watering(tile)
	if not dev_travel_unlocked and expedition.home() and int(result.drops.get("Corn", 0)) > 0: expedition.data.harvested = true
	var yields: PackedStringArray = []
	for item: String in result.drops:
		_drop_item(item, result.drops[item], tile)
		yields.append("%s x%d" % [item, result.drops[item]])
	if not yields.is_empty():
		_show_notice("Harvested " + " and ".join(yields))
	elif not consume.is_empty():
		_show_notice(str(CropCatalog.SEEDS[consume]) + " planted. Water or irrigate the soil")
	elif result.has("watered"):
		_show_notice("Soil watered")
	elif not result.edits.is_empty():
		_show_notice("Soil tilled. Select seeds to plant")
	elif CropCatalog.SEEDS.has(selected):
		_show_notice("Plant seeds in clear tilled soil")
	return true


func _hoe(point: Vector2) -> void:
	_farm_interaction(_mouse_to_tile(point), "Hoe", "")


func _water_soil(point: Vector2) -> void:
	var tile := _mouse_to_tile(point)
	if _in_dig_reach(tile):
		if not _farm_interaction(tile, "Watering Can", ""): _start_watering(tile)


func _plant(tile: Vector2i) -> bool:
	return _farm_interaction(tile, "Hand", place_items[selected_slot])


func _eat_food(item: String) -> bool:
	if scene_name != "planet" or paused or dev_mode or crafting_open or dialogue_open or not food.edible(item):
		return false
	if int(inventory.get(item, 0)) <= 0:
		_show_notice("No " + item + " in your backpack")
		return false
	if health >= 100:
		_show_notice("Health is full - food kept")
		return false
	if food_cooldown > 0.0:
		_show_notice("Eat again in %.1f seconds" % food_cooldown)
		return false
	if not _add_to_hotbar(item, true):
		return false
	last_heal = mini(100 - health, int(FoodCatalog.FOODS[item]))
	health += last_heal
	inventory[item] = int(inventory[item]) - 1
	food_cooldown = FoodCatalog.COOLDOWN
	eat_visual = 0.65
	food_feedback_timer = 1.4
	last_food = item
	tool_action_timer = 0.0
	_stop_held_actions()
	_show_notice("Ate %s: +%d HP" % [item, last_heal])
	queue_redraw()
	return true


func _quick_eat() -> void:
	var item := food.best_food(inventory, place_items[selected_slot])
	if item.is_empty():
		_show_notice("No food in your backpack - harvest corn to eat")
	else:
		_eat_food(item)


func _update_food_feedback(delta: float) -> void:
	if scene_name != "planet" or paused or dev_mode:
		return
	food_cooldown = maxf(0.0, food_cooldown - delta)
	eat_visual = maxf(0.0, eat_visual - delta)
	food_feedback_timer = maxf(0.0, food_feedback_timer - delta)


func _process(delta: float) -> void:
	animation_clock += delta
	_update_food_feedback(delta)
	if dev_controls != null:
		dev_controls.update(delta)
	tool_action_timer = maxf(0.0, tool_action_timer - delta)
	mining_feedback_timer = maxf(0.0, mining_feedback_timer - delta)
	lava_flash = maxf(0.0, lava_flash - delta)
	if scene_name == "planet":
		weather = _climate_weather(weather)
		_refresh_hotbar()
		_update_clouds(delta)
		if not paused and not dev_mode:
			furnaces.update(delta)
			if crafting_open or inventory_open or stations.is_open():
				weather_blend.update(weather, delta, int(world.get("climate", 0)))
				cloud_cover = move_toward(cloud_cover, _cloud_target(), delta * 0.20)
				wind_cache_clock = -1.0
	if notice_timer > 0.0:
		notice_timer -= delta
	if scene_name != "planet" or paused or crafting_open or inventory_open or stations.is_open() or dev_mode:
		_stop_held_actions()
		if sound != null:
			sound.update(delta)
		queue_redraw()
		return
	var next_time: float = time_of_day + delta / float(settings_data["day_length"])
	if next_time >= 1.0:
		day_count += int(floor(next_time))
	time_of_day = fposmod(next_time, 1.0)
	cloud_cover = move_toward(cloud_cover, _cloud_target(), delta * 0.20)
	weather_timer += delta
	while weather_timer >= 80.0:
		weather_timer -= 80.0
		weather = _next_weather()
		weather_cycle += 1
	_update_player(delta)
	attack_cooldown = maxf(0.0, attack_cooldown - delta)
	attack_visual = maxf(0.0, attack_visual - delta)
	_update_elder(delta)
	_update_population(delta)
	_update_crops(delta)
	_update_grass(delta)
	sand_gravity.update(self, delta)
	_update_water(delta)
	_update_drops(delta)
	_update_camera()
	_update_mouse_aim()
	surface_effects.update(self, delta)
	ground_life.update(self, delta)
	furnishings.update(self, delta)
	water_ripples.update(self, delta)
	hanging_vines.update(self, delta)
	_update_held_actions(delta)
	if sound != null:
		sound.update(delta)
	queue_redraw()


func _player_rect(at: Vector2) -> Rect2:
	return Rect2(at, Vector2(16, 28))


func _collides(at: Vector2) -> bool:
	if world.is_empty():
		return false
	var bounds := _player_rect(at)
	var grid: PackedByteArray = world["tiles"]
	for x in range(maxi(0, int(floor(bounds.position.x / WG.TILE))), mini(WG.WIDTH, int(floor((bounds.end.x - 0.1) / WG.TILE)) + 1)):
		for y in range(maxi(0, int(floor(bounds.position.y / WG.TILE))), mini(WG.HEIGHT, int(floor((bounds.end.y - 0.1) / WG.TILE)) + 1)):
			if WG.is_solid(WG.tile_at(grid, x, y)):
				return true
	return false


func _move_axis(distance: float, horizontal: bool) -> bool:
	var moving := absf(distance)
	var direction := signf(distance)
	while moving > 0.0:
		var amount := minf(4.0, moving) * direction
		var candidate := player_pos + (Vector2(amount, 0) if horizontal else Vector2(0, amount))
		if _collides(candidate):
			return true
		player_pos = candidate
		moving -= absf(amount)
	return false


func _update_player(delta: float) -> void:
	if dev_free_flight:
		furnishings.climbing = false
		var flight := Vector2(
			float(Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT)) - float(Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT)),
			float(Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN)) - float(Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP) or Input.is_key_pressed(KEY_SPACE)))
		if flight.x != 0.0:
			facing = int(signf(flight.x))
		player_pos += flight.normalized() * SPEED * 1.8 * delta
		player_pos = player_pos.clamp(Vector2.ZERO, Vector2(WG.WIDTH * WG.TILE - 16, WG.HEIGHT * WG.TILE - 28))
		player_velocity = Vector2.ZERO
		player_grounded = false
		_update_lava_damage(delta)
		return
	var movement := 0.0
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		movement -= 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		movement += 1.0
	var rising := Input.is_key_pressed(KEY_SPACE) or Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP)
	var climbing_up := Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP)
	var climbing_down := Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN)
	if furnishings.climb(self, delta, movement, climbing_up, climbing_down, Input.is_key_pressed(KEY_SPACE)):
		return
	_update_player_motion(delta, movement, rising)


func _try_water_step(horizontal: float) -> bool:
	# Sweep upward before stepping: a low ceiling or a two-block bank still blocks.
	for rise in range(1, 17):
		var raised := player_pos - Vector2(0, rise)
		if _collides(raised): return false
		if not _collides(raised + Vector2(horizontal, 0)):
			player_pos = raised
			_move_axis(horizontal, true)
			return true
	return false


func _update_player_motion(delta: float, movement: float, rising: bool) -> void:
	var in_water := water_sim.submerged(player_pos + Vector2(8, 14))
	var touching_water := water_sim.intersects(_player_rect(player_pos))
	if movement != 0: facing = int(signf(movement))
	var horizontal := movement * SPEED * (0.7 if in_water else 1.0) * delta
	var blocked := _move_axis(horizontal, true)
	if blocked and touching_water and rising and not crafting_open: _try_water_step(horizontal)
	if player_grounded and not in_water and not crafting_open and rising:
		player_velocity.y = JUMP_SPEED
		player_grounded = false
	elif touching_water and rising and not crafting_open:
		player_velocity.y = -245.0
	player_velocity.y = minf(170.0 if in_water else 700.0, player_velocity.y + (260.0 if in_water else GRAVITY) * delta)
	var vertical_hit := _move_axis(player_velocity.y * delta, false)
	if vertical_hit:
		player_grounded = player_velocity.y > 0.0
		player_velocity.y = 0.0
	else:
		player_grounded = _collides(player_pos + Vector2(0, 1))
	player_pos.x = clampf(player_pos.x, 0, WG.WIDTH * WG.TILE - 16)
	player_pos.y = clampf(player_pos.y, 0, WG.HEIGHT * WG.TILE - 28)
	# Check the body's intersection with the actual partial lava surface.
	if water_sim.submerged(player_pos + Vector2(8, 14)):
		player_velocity.y = minf(player_velocity.y, 110.0)
	_update_lava_damage(delta)


func _update_lava_damage(delta: float) -> void:
	if dev_invulnerable or not lava_sim.intersects(_player_rect(player_pos)):
		lava_hurt_timer = 0.0
		return
	lava_hurt_timer -= delta
	var hits := 0
	while lava_hurt_timer <= 0.000001 and hits < 8:
		lava_hurt_timer += 0.5
		hits += 1
		health = maxi(0, health - 20)
		lava_flash = 0.25
		_show_notice("Lava burns! -20 HP")
		if health <= 0:
			health = 100
			player_pos = world["spawn"]
			player_velocity = Vector2.ZERO
			lava_hurt_timer = 0.0
			_show_notice("Respawned after touching lava")
			return


func _update_camera() -> void:
	camera_pos.x = clampf(player_pos.x + 8 - SCREEN.x / 2.0, 0.0, WG.WIDTH * WG.TILE - SCREEN.x)
	camera_pos.y = clampf(player_pos.y + 14 - SCREEN.y / 2.0, 0.0, WG.HEIGHT * WG.TILE - SCREEN.y)


func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		aim_screen = event.position
		_remember_mouse_aim(event.position)
	elif event is InputEventMouseButton:
		aim_screen = event.position
		_remember_mouse_aim(event.position)
		if not event.pressed:
			if event.button_index == MOUSE_BUTTON_LEFT:
				primary_held = false
			elif event.button_index == MOUSE_BUTTON_RIGHT:
				secondary_held = false
	if dev_mode and scene_name in ["planet", "galaxy", "system"] and dev_controls.handle_input(event):
		queue_redraw()
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if scene_name == "planet" and event.keycode == KEY_Q and event.shift_pressed and Input.is_key_pressed(KEY_R):
			_key_pressed(KEY_F3)
			return
		if scene_name == "planet" and event.keycode == KEY_R and event.shift_pressed:
			return
		if _edit_new_game_text(event):
			return
		_key_pressed(event.keycode)
	elif event is InputEventMouseButton:
		if event.pressed:
			_mouse_pressed(event)
		elif event.button_index == MOUSE_BUTTON_LEFT:
			_finish_inventory_drag(event.position)
			dragged_window = ""
	elif event is InputEventMouseMotion and inventory_drag_item != "":
		inventory_dragging = inventory_dragging or event.position.distance_to(inventory_drag_start) >= 5.0
		queue_redraw()
	elif event is InputEventMouseMotion and dragged_window != "":
		var size := _window_size(dragged_window)
		window_positions[dragged_window] = Vector2(
			clampf(event.position.x - drag_offset.x, 0.0, SCREEN.x - size.x),
			clampf(event.position.y - drag_offset.y, 0.0, SCREEN.y - size.y))
		queue_redraw()


func _window_size(kind: String) -> Vector2:
	match kind:
		"inventory": return Vector2(466, 382)
		"chest": return Vector2(466, 382)
		"crafting": return Vector2(560, 510)
		"workbench", "furnace": return StationWindows.SIZE
		"dev": return Vector2(560, 390)
		"pause": return Vector2(470, 445)
	return Vector2(830, 150)


func _start_window_drag(kind: String, point: Vector2) -> void:
	dragged_window = kind
	drag_offset = point - Vector2(window_positions[kind])


func _key_pressed(key: Key) -> void:
	if scene_name in ["menu", "new_game", "load", "settings", "help", "confirm"]:
		_menu_key(key)
		queue_redraw()
		return
	if scene_name == "planet" and paused:
		if key == KEY_ESCAPE:
			paused = false
		elif key == KEY_F5:
			_save_game()
		queue_redraw()
		return
	if scene_name in ["planet", "galaxy", "system"] and key == KEY_F3:
		stations.close(false)
		dev_mode = not dev_mode
		dragged_window = ""
		dev_controls.opened()
		crafting_open = false
		inventory_open = false
		dialogue_open = false
		_stop_held_actions()
		queue_redraw()
		return
	if scene_name in ["planet", "galaxy", "system"] and dev_mode:
		if key == KEY_ESCAPE:
			dev_mode = false
			dragged_window = ""
		elif key == KEY_ENTER:
			dev_controls.run_command()
		elif key == KEY_TAB:
			dev_controls.autocomplete()
		queue_redraw()
		return
	if key == KEY_ESCAPE:
		if scene_name == "planet":
			_cancel_inventory_drag()
			var had_station := stations.is_open()
			stations.close(false)
			interactions.close(false)
			if crafting_open or inventory_open or had_station or dialogue_open:
				crafting_open = false
				inventory_open = false
				dialogue_open = false
			else:
				paused = not paused
		elif scene_name == "system":
			scene_name = "galaxy"
		elif scene_name == "galaxy":
			if not worlds.is_empty():
				_save_game()
			scene_name = "menu"
	elif scene_name == "system":
		if key >= KEY_1 and key <= KEY_8:
			selected_planet_index = key - KEY_1
		elif key in [KEY_E, KEY_ENTER] and selected_planet_index >= 0:
			_open_planet(selected_planet_index)
	elif scene_name == "planet":
		if key == KEY_F and not paused and not dev_mode:
			if dialogue_open:
				_talk_to_explorer()
			elif stations.is_open():
				stations.close()
			elif interactions.is_open():
				interactions.close()
			elif crafting_open:
				crafting_open = false
			elif not inventory_open and not dialogue_open:
				if furnishings.aimed(self):
					furnishings.interact(self)
				elif not interactions.interact() and not furnishings.interact(self) and not expedition.interact():
					_attack()
			queue_redraw()
			return
		if key == KEY_J:
			expedition.folded = not expedition.folded
		elif key == KEY_C:
			_toggle_crafting(0)
		elif key == KEY_M:
			_toggle_crafting(1)
		elif key == KEY_I:
			interactions.close(false)
			inventory_open = not inventory_open
			crafting_open = false
		elif key == KEY_ENTER and stations.is_open() and stations.kind == "workbench":
			stations.craft()
		elif key == KEY_UP and crafting_open:
			_cycle_recipe(-1)
		elif key == KEY_DOWN and crafting_open:
			_cycle_recipe(1)
		elif key == KEY_ENTER and crafting_open:
			_craft()
		elif key == KEY_F5:
			_save_game()
		elif key == KEY_R and not crafting_open:
			_quick_eat()
		elif crafting_open or inventory_open or stations.is_open():
			queue_redraw()
			return
		elif key == KEY_F9:
			_load_game()
		elif key == KEY_G and not paused:
			_leave_planet()
		elif key == KEY_E and not paused:
			_talk_to_explorer()
		elif key == KEY_Q:
			if Tools.family(equipped_tool) == "Pickaxe":
				_select_empty_hand()
			else:
				_equip_inventory_item(Tools.best_owned(inventory, "Pickaxe"))
		elif key == KEY_H:
			if equipped_tool == "Hoe":
				_select_empty_hand()
			else:
				_equip_inventory_item("Hoe")
		elif key == KEY_T:
			var options := ["Hand"]
			for tool in tool_textures:
				if int(inventory.get(tool, 0)) > 0:
					options.append(tool)
			var next: String = options[(options.find(equipped_tool) + 1) % options.size()]
			if next == "Hand":
				_select_empty_hand()
			else:
				_equip_inventory_item(next)
		elif key == KEY_V and not paused:
			if int(inventory.get("Watering Can", 0)) > 0:
				if _equip_inventory_item("Watering Can"):
					_water_soil(get_viewport().get_mouse_position())
			else:
				_show_notice("Craft a Watering Can at a Workbench")
		elif key == KEY_B:
			_select_hotbar_slot(posmod(hotbar_page + 1, Hotbar.PAGES) * 9 + selected_slot % 9)
		elif key == KEY_TAB:
			_scroll_hotbar(1, false)
		elif key >= KEY_1 and key <= KEY_9:
			var slot := hotbar_page * 9 + key - KEY_1
			if slot < place_items.size():
				_select_hotbar_slot(slot)
		if paused and key == KEY_G:
			_leave_planet()
	queue_redraw()


func _mouse_pressed(event: InputEventMouseButton) -> void:
	var point: Vector2 = event.position
	if scene_name in ["menu", "new_game", "load", "settings", "help", "confirm"]:
		if event.button_index == MOUSE_BUTTON_LEFT:
			_menu_click(point)
		queue_redraw()
		return
	if scene_name == "planet" and paused:
		if event.button_index == MOUSE_BUTTON_LEFT:
			_pause_click(point)
		queue_redraw()
		return
	if dev_mode and scene_name in ["planet", "galaxy", "system"]:
		if event.button_index == MOUSE_BUTTON_LEFT:
			_dev_click(point)
		queue_redraw()
		return
	if scene_name == "galaxy":
		if event.button_index != MOUSE_BUTTON_LEFT:
			return
		var nearest := -1
		var distance := 15.0
		for i in range(star_points.size()):
			var d := point.distance_to(star_points[i])
			if d < distance:
				nearest = i
				distance = d
		if nearest >= 0:
			_open_system(nearest)
	elif scene_name == "system":
		if event.button_index != MOUSE_BUTTON_LEFT:
			return
		if Rect2(1055, 615, 205, 58).has_point(point) and selected_planet_index >= 0:
			_open_planet(selected_planet_index)
		elif Rect2(20, 20, 170, 42).has_point(point):
			scene_name = "galaxy"
		else:
			for i in range(system_planets.size()):
				if point.distance_to(_system_planet_position(i)) <= float(system_planets[i]["size"]) + 5.0:
					selected_planet_index = i
					break
	elif scene_name == "planet" and not paused:
		if _gameplay_ui_click(point, event.button_index, event.ctrl_pressed, event.alt_pressed):
			queue_redraw()
			return
		if event.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN]:
			_scroll_hotbar(-1 if event.button_index == MOUSE_BUTTON_WHEEL_UP else 1, event.alt_pressed)
			queue_redraw()
			return
		if event.button_index == MOUSE_BUTTON_LEFT:
			_refresh_hotbar()
			aim_screen = point
			primary_held = true
			_primary_action(point)
			primary_repeat = _primary_interval()
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			_refresh_hotbar()
			aim_screen = point
			secondary_held = true
			secondary_repeat = 0.20
			_place(point)
	queue_redraw()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_WINDOW_FOCUS_OUT:
		_stop_held_actions()
		_cancel_inventory_drag()
		dragged_window = ""


func _stop_held_actions() -> void:
	primary_held = false
	secondary_held = false
	primary_repeat = 0.0
	secondary_repeat = 0.0


func _world_input_blocked(point: Vector2) -> bool:
	if expedition.active() and expedition.hud_rect().has_point(point):
		return true
	if scene_name != "planet" or paused or crafting_open or inventory_open or stations.is_open() or dev_mode or dialogue_open:
		return true
	for rect in [HUD_PACK_RECT, HUD_CRAFT_RECT, Rect2(388, 610, 504, 106), Rect2(16, 16, 244, 55), Rect2(940, 16, 324, 140)]:
		if rect.has_point(point):
			return true
	return false


func _primary_action(point: Vector2) -> void:
	if Tools.family(equipped_tool) == "Sword":
		_attack(point + camera_pos)
		return
	if not _try_attack_at(point):
		_mine(point)


func _set_mouse_world_target(target: Vector2) -> void:
	var direction := target - player_pos - Vector2(8, 10)
	if direction.length_squared() < 9.0:
		return
	mouse_aim_screen = target - camera_pos
	mouse_aim_valid = true
	mouse_aim_direction = direction.normalized()
	if absf(direction.x) > 3.0:
		facing = 1 if direction.x > 0.0 else -1


func _remember_mouse_aim(point: Vector2) -> void:
	if not _world_input_blocked(point):
		_set_mouse_world_target(point + camera_pos)


func _update_mouse_aim() -> void:
	if mouse_aim_valid and not _world_input_blocked(aim_screen):
		_set_mouse_world_target(mouse_aim_screen + camera_pos)


func _primary_interval() -> float:
	if tool_action_kind == "attack" and attack_cooldown > 0.0:
		return attack_cooldown
	return mining_cooldown if mining_cooldown > 0.0 else Tools.mining_interval(equipped_tool)


func _update_held_actions(delta: float) -> void:
	mining_cooldown = maxf(0.0, mining_cooldown - delta)
	if _world_input_blocked(aim_screen):
		return
	primary_repeat = maxf(0.0, primary_repeat - delta)
	secondary_repeat = maxf(0.0, secondary_repeat - delta)
	if primary_held and primary_repeat <= 0.0:
		_primary_action(aim_screen)
		primary_repeat = _primary_interval()
	if secondary_held and secondary_repeat <= 0.0:
		_place(aim_screen)
		secondary_repeat = 0.20


func _reset_world_environment() -> void:
	weather_blend.reset(_climate_weather(weather), int(world.get("climate", 0)))
	mining_feedback_timer = 0.0
	mouse_aim_valid = false
	mouse_aim_direction = Vector2(facing, 0)
	if sound != null:
		sound.reset_world()
	water_sim.bind_world(world)
	water_ripples.reset()
	lava_sim.bind_world(world)
	snowfall.bind_world(world)
	lava_hurt_timer = 0.0
	lava_flash = 0.0
	wind_drift = 0.0
	environment.reset(world)
	underground.reset(self)
	background_ores.reset(self)
	furnishings.reset(self)
	biome_backgrounds.reset(world)
	ground_life.reset(self)
	hanging_vines.reset(self)
	terrain_cache.reset(self)
	sand_gravity.reset(self)
	farming = Farming.new()
	farming.bind_world(world)
	farms[_world_key()] = farming
	precipitation.reset(int(world["seed"]))
	surface_effects.reset(int(world["seed"]))
	fluid_reactions.reset(self)


func _update_water(delta: float) -> void:
	weather = _climate_weather(weather)
	weather_blend.update(weather, delta, int(world.get("climate", 0)))
	wind_cache_clock = -1.0
	var stamp := _profile_tick()
	water_sim.set_active_region(player_pos + Vector2(8, 14))
	lava_sim.set_active_region(player_pos + Vector2(8, 14))
	precipitation.update(int((player_pos.x + 8.0) / WG.TILE), delta, _rain_strength() > 0.001, weather_blend.amount("Storm") > 0.5, clampf(sin(time_of_day * TAU), 0.0, 1.0), environment.roof, water_sim, lava_sim, _rain_strength())
	snowfall.update(self, delta)
	var dirty := water_sim.update(delta)
	if snowfall.runoff_timer > 0.0 and not dirty.is_empty():
		# Snow can release an entire hillside's meltwater at once. Cap the
		# combined runoff after flow as well as at the precipitation source.
		water_sim.drain_rain(environment.roof, 48, 1024)
		dirty.append_array(water_sim.update(0.0))
	var lava_dirty := lava_sim.update(delta)
	if not lava_dirty.is_empty():
		environment.invalidate()
		dirty.append_array(lava_dirty)
	var solidified := fluid_reactions.update(self, delta, dirty)
	if not solidified.is_empty():
		dirty.append_array(solidified)
		dirty.append_array(water_sim.update(0.0))
		dirty.append_array(lava_sim.update(0.0))
	if dirty.is_empty():
		_profile_end("water_sim", stamp)
		return
	var columns := {}
	for index in dirty:
		var x := index % WG.WIDTH
		var y := int(index / WG.WIDTH)
		columns[x] = mini(int(columns.get(x, WG.HEIGHT)), y)
	for column in columns:
		environment.refresh_water_column(column, columns[column])
		_queue_grass_column(column)
	_profile_end("water_sim", stamp)


func _profile_tick() -> int:
	return Time.get_ticks_usec() if profile_enabled else 0


func _profile_end(section: String, stamp: int) -> int:
	if not profile_enabled:
		return 0
	var now := Time.get_ticks_usec()
	var elapsed := now - stamp
	var entry: Array = profile_stats.get(section, [0, 0, 0])
	entry[0] += elapsed
	entry[1] += 1
	entry[2] = maxi(int(entry[2]), elapsed)
	profile_stats[section] = entry
	return now


func _inventory_items() -> Array[String]:
	var result: Array[String] = []
	for item: String in inventory_order:
		if int(inventory.get(item, 0)) > 0 and item not in result:
			result.append(item)
	for key in inventory:
		if int(inventory[key]) > 0 and str(key) not in result:
			result.append(str(key))
	inventory_order = result.duplicate()
	return result


func _inventory_category(item: String) -> int:
	if Tools.has_item(item):
		return 1 if Tools.family(item) == "Sword" else 0
	if ores.has_item(item):
		return 2
	if TILE_FOR_ITEM.has(item) or Furnishings.has_item(item) or item in ["Workbench", "Furnace", "Torch", "Stick"]:
		return 3
	if GroundLife.has_item(item) or CropCatalog.SEEDS.has(item):
		return 4
	if food.has_icon(item):
		return 5
	return 6


func _sort_inventory() -> void:
	_cancel_inventory_drag()
	var items := _inventory_items()
	items.sort_custom(func(a: String, b: String) -> bool:
		var left := _inventory_category(a)
		var right := _inventory_category(b)
		return left < right if left != right else Tools.display_name(a).naturalnocasecmp_to(Tools.display_name(b)) < 0)
	inventory_order = items
	inventory_page = 0
	_show_notice("Backpack sorted by item type and name")


func _inventory_page_count() -> int:
	return maxi(1, ceili(_inventory_items().size() / 32.0))


func _refresh_hotbar() -> void:
	tool_wear.sync(inventory)
	hotbar.prune(inventory)
	var item: String = place_items[selected_slot]
	var tool := item if tool_textures.has(item) and int(inventory.get(item, 0)) > 0 else "Hand"
	if equipped_tool != tool:
		_stop_held_actions()
		tool_action_timer = 0.0
		equipped_tool = tool
	use_pickaxe = Tools.family(equipped_tool) == "Pickaxe"
	use_hoe = equipped_tool == "Hoe"


func _select_hotbar_slot(slot: int) -> void:
	if slot != selected_slot:
		_stop_held_actions()
		tool_action_timer = 0.0
	selected_slot = clampi(slot, 0, Hotbar.SIZE - 1)
	hotbar_page = selected_slot / 9
	_refresh_hotbar()


func _select_empty_hand() -> void:
	_refresh_hotbar()
	var empty := place_items.find("")
	if empty >= 0:
		_select_hotbar_slot(empty)
	else:
		_show_notice("Remove a hotbar shortcut to free a hand slot")


func _scroll_hotbar(direction: int, extra_page: bool) -> void:
	if extra_page:
		_select_hotbar_slot(posmod(hotbar_page + direction, Hotbar.PAGES) * 9 + selected_slot % 9)
	else:
		_select_hotbar_slot(hotbar_page * 9 + posmod(selected_slot % 9 + direction, 9))


func _hotbar_slot_at(point: Vector2) -> int:
	for index in range(9):
		if Rect2(HOTBAR_X + index * HOTBAR_STEP, HOTBAR_Y, HOTBAR_SIZE, HOTBAR_SIZE).has_point(point):
			return hotbar_page * 9 + index
	return -1


func _add_to_hotbar(item: String, select: bool = false) -> bool:
	hotbar.prune(inventory)
	var slot := hotbar.add(item, inventory)
	if slot < 0:
		if int(inventory.get(item, 0)) > 0:
			_show_notice("Hotbars full. Drag onto a slot to replace its shortcut")
		return false
	if select:
		_select_hotbar_slot(slot)
	else:
		_refresh_hotbar()
		_show_notice("%s: hotbar %d, slot %d" % [Tools.display_name(item), slot / 9 + 1, slot % 9 + 1])
	return true


func _equip_inventory_item(item: String) -> bool:
	if not _add_to_hotbar(item, true):
		return false
	inventory_open = false
	return true


func _hotbar_ui_click(point: Vector2, button: int, control: bool, alternate: bool) -> bool:
	if not Rect2(388, 638, 504, 78).has_point(point):
		return false
	if button in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN]:
		_scroll_hotbar(-1 if button == MOUSE_BUTTON_WHEEL_UP else 1, alternate)
		return true
	if button != MOUSE_BUTTON_LEFT:
		return true
	for page in range(Hotbar.PAGES):
		if HUD_PAGE_RECTS[page].has_point(point):
			_select_hotbar_slot(page * 9 + selected_slot % 9)
			return true
	var slot := _hotbar_slot_at(point)
	if slot >= 0:
		if control:
			hotbar.remove(slot)
			_refresh_hotbar()
		else:
			_select_hotbar_slot(slot)
			if not place_items[slot].is_empty():
				inventory_drag_item = place_items[slot]
				inventory_drag_slot = slot
				inventory_drag_start = point
				inventory_dragging = false
	return true


func _finish_inventory_drag(point: Vector2) -> void:
	if inventory_drag_item.is_empty():
		return
	if stations.finish_drag(point):
		_cancel_inventory_drag()
		queue_redraw()
		return
	if inventory_dragging and stations.accepts_drag(point, inventory_drag_item):
		_cancel_inventory_drag()
		queue_redraw()
		return
	if not inventory_dragging and inventory_drag_slot < 0 and stations.is_open():
		stations.deposit(inventory_drag_item)
		_cancel_inventory_drag()
		queue_redraw()
		return
	if inventory_dragging and interactions.accepts_drag(point, inventory_drag_item):
		_cancel_inventory_drag()
		queue_redraw()
		return
	if not inventory_dragging and inventory_drag_slot < 0 and interactions.is_open():
		interactions.deposit(inventory_drag_item)
		_cancel_inventory_drag()
		queue_redraw()
		return
	var target := _hotbar_slot_at(point)
	var pack_covers_target := inventory_open and Rect2(Vector2(window_positions["inventory"]), _window_size("inventory")).has_point(point)
	if inventory_dragging and target >= 0 and not pack_covers_target:
		hotbar.assign(inventory_drag_item, target, inventory)
		_refresh_hotbar()
	elif inventory_dragging and inventory_drag_slot >= 0:
		hotbar.remove(inventory_drag_slot)
		_refresh_hotbar()
	elif inventory_open and inventory_drag_slot < 0:
		var at: Vector2 = window_positions["inventory"]
		if inventory_dragging and Rect2(at + Vector2(16, 274), Vector2(434, 70)).has_point(point):
			_stage_trash(inventory_drag_item)
		elif not inventory_dragging:
			_equip_inventory_item(inventory_drag_item)
	_cancel_inventory_drag()
	queue_redraw()


func _cancel_inventory_drag() -> void:
	stations.source.clear()
	inventory_drag_item = ""
	inventory_dragging = false
	inventory_drag_slot = -1


func _stage_trash(item: String) -> void:
	var count := int(inventory.get(item, 0))
	if count <= 0:
		return
	_return_trash()
	inventory_trash = {"item": item, "count": count, "tool_wear": tool_wear.take(item, count, inventory)}
	inventory[item] = int(inventory.get(item, 0)) - count
	hotbar.prune(inventory)
	if item == equipped_tool and int(inventory[item]) <= 0:
		equipped_tool = "Hand"
		use_pickaxe = false
		use_hoe = false


func _return_trash() -> void:
	if not inventory_trash.is_empty():
		_add_item(str(inventory_trash["item"]), int(inventory_trash["count"]), inventory_trash.get("tool_wear", []))
		inventory_trash.clear()


func _destroy_trash() -> void:
	if inventory_trash.is_empty():
		return
	_show_notice("Destroyed %s x%d" % [inventory_trash["item"], int(inventory_trash["count"])])
	inventory_trash.clear()


func _gameplay_ui_click(point: Vector2, button: int, control: bool = false, alternate: bool = false) -> bool:
	if stations.click(point, button, control):
		return true
	if interactions.click(point, button):
		return true
	var pack_covers_bar := inventory_open and Rect2(Vector2(window_positions["inventory"]), _window_size("inventory")).has_point(point)
	if not crafting_open and not dialogue_open and not pack_covers_bar and _hotbar_ui_click(point, button, control, alternate):
		return true
	if crafting_open:
		if button in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN]:
			_cycle_recipe(-1 if button == MOUSE_BUTTON_WHEEL_UP else 1)
			return true
		if button != MOUSE_BUTTON_LEFT:
			return true
		var at: Vector2 = window_positions["crafting"]
		if Rect2(at + Vector2(526, 6), Vector2(28, 28)).has_point(point):
			crafting_open = false
			dragged_window = ""
			return true
		if Rect2(at, Vector2(560, 36)).has_point(point):
			_start_window_drag("crafting", point)
			return true
		if Rect2(at + Vector2(418, 88), Vector2(54, 27)).has_point(point):
			_cycle_recipe_page(-1)
			return true
		if Rect2(at + Vector2(486, 88), Vector2(54, 27)).has_point(point):
			_cycle_recipe_page(1)
			return true
		var group := _visible_recipes()
		for row in range(group.size()):
			if Rect2(at + Vector2(14, 139 + row * 51), Vector2(532, 47)).has_point(point):
				recipe_index = group[row]
				if point.x >= at.x + 446:
					_craft()
				return true
		return true
	if inventory_open:
		inventory_page = clampi(inventory_page, 0, _inventory_page_count() - 1)
		if button in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN]:
			if alternate:
				_scroll_hotbar(-1 if button == MOUSE_BUTTON_WHEEL_UP else 1, true)
			else:
				inventory_page = posmod(inventory_page + (-1 if button == MOUSE_BUTTON_WHEEL_UP else 1), _inventory_page_count())
			return true
		if button == MOUSE_BUTTON_RIGHT:
			var items := _inventory_items()
			var at: Vector2 = window_positions["inventory"]
			for cell in range(32):
				var index := inventory_page * 32 + cell
				if index >= items.size():
					break
				var rect := Rect2(at + Vector2(20 + (cell % 8) * 54, 45 + (cell / 8) * 54), Vector2(48, 48))
				if rect.has_point(point):
					if stations.is_open():
						stations.deposit(items[index], 1)
						return true
					if interactions.is_open():
						interactions.deposit(items[index], 1)
					elif food.edible(items[index]):
						_eat_food(items[index])
					break
			return true
		if button != MOUSE_BUTTON_LEFT:
			return true
		var at: Vector2 = window_positions["inventory"]
		if Rect2(at + Vector2(222, 6), Vector2(68, 26)).has_point(point):
			_sort_inventory()
			return true
		if Rect2(at + Vector2(300, 6), Vector2(28, 26)).has_point(point):
			inventory_page = posmod(inventory_page - 1, _inventory_page_count())
			return true
		if Rect2(at + Vector2(385, 6), Vector2(28, 26)).has_point(point):
			inventory_page = posmod(inventory_page + 1, _inventory_page_count())
			return true
		if Rect2(at + Vector2(398, 286), Vector2(32, 32)).has_point(point):
			_destroy_trash()
			return true
		if Rect2(at + Vector2(20, 278), Vector2(48, 48)).has_point(point):
			_return_trash()
			return true
		if Rect2(at + Vector2(433, 6), Vector2(27, 28)).has_point(point):
			interactions.close(false)
			inventory_open = false
			dragged_window = ""
			return true
		if Rect2(at, Vector2(466, 37)).has_point(point):
			_start_window_drag("inventory", point)
			return true
		var items := _inventory_items()
		for row in range(4):
			for col in range(8):
				var index := inventory_page * 32 + row * 8 + col
				if index >= items.size():
					break
				if Rect2(at + Vector2(20 + col * 54, 45 + row * 54), Vector2(48, 48)).has_point(point):
					if control:
						_add_to_hotbar(items[index])
						return true
					inventory_drag_item = items[index]
					inventory_drag_slot = -1
					inventory_drag_start = point
					inventory_dragging = false
					return true
		return true
	if dialogue_open:
		if button == MOUSE_BUTTON_LEFT:
			var at: Vector2 = window_positions["dialogue"]
			if Rect2(at + Vector2(790, 7), Vector2(32, 30)).has_point(point):
				dialogue_open = false
			elif expedition.home() and Rect2(at + Vector2(25, 110), Vector2(280, 30)).has_point(point):
				_talk_to_explorer()
			elif Rect2(at, Vector2(830, 39)).has_point(point):
				_start_window_drag("dialogue", point)
		return true
	if HUD_PACK_RECT.has_point(point):
		if button == MOUSE_BUTTON_LEFT:
			inventory_open = true
		return true
	if HUD_CRAFT_RECT.has_point(point):
		if button == MOUSE_BUTTON_LEFT:
			_toggle_crafting(0)
		return true
	if Rect2(16, 16, 244, 55).has_point(point) or Rect2(940, 16, 324, 140).has_point(point):
		return true
	return false


func _dev_click(point: Vector2) -> void:
	dev_controls.click(point)


func _draw_dev_panel() -> void:
	dev_controls.draw()


func _try_attack_at(point: Vector2) -> bool:
	var aimed := point + camera_pos
	for creature in world.get("creatures", []):
		if not bool(creature["alive"]):
			continue
		var center := Vector2(float(creature["x"]) + 12.0, float(creature["y"]) + 9.0)
		if center.distance_to(aimed) <= 19.0 and center.distance_to(player_pos + Vector2(8, 14)) <= 70.0:
			facing = 1 if center.x >= player_pos.x + 8 else -1
			_attack(aimed)
			return true
	return false


func _mouse_to_tile(point: Vector2) -> Vector2i:
	var world_point: Vector2 = point + camera_pos
	return Vector2i(int(floor(world_point.x / WG.TILE)), int(floor(world_point.y / WG.TILE)))


func _in_reach(tile: Vector2i) -> bool:
	var center := Vector2(tile.x * WG.TILE + 8, tile.y * WG.TILE + 8)
	return center.distance_to(player_pos + Vector2(8, 14)) <= REACH


func _in_dig_reach(tile: Vector2i) -> bool:
	var center := Vector2(tile.x * WG.TILE + 8, tile.y * WG.TILE + 8)
	return center.distance_squared_to(player_pos + Vector2(8, 14)) <= DIG_REACH * DIG_REACH


func _edit_tile(tile: Vector2i, tile_id: int, upload: bool = true) -> void:
	if tile.x < 0 or tile.x >= WG.WIDTH or tile.y < 0 or tile.y >= WG.HEIGHT:
		return
	var grid: PackedByteArray = world["tiles"]
	var old_id := WG.tile_at(grid, tile.x, tile.y)
	var unsupported := farming.unsupported(tile, tile_id) if old_id in [12, 13] else {}
	if old_id != tile_id:
		var damage: Dictionary = world.get("mining_damage", {})
		var origin := _tree_base(tile) if old_id == 7 else tile
		damage.erase("%d,%d" % [origin.x, origin.y])
		if mining_feedback_tile == tile:
			mining_feedback_timer = 0.0
	if tile_id == 0 and old_id != 4 and water_sim.amount_at(tile) > 0:
		tile_id = 4
	if tile_id == 0 and old_id != 11 and lava_sim.amount_at(tile) > 0:
		tile_id = 11
	WG.set_tile(grid, tile.x, tile.y, tile_id)
	world["tiles"] = grid
	var paint: Color = WG.terrain_underlay_color(tile_id)
	world_image.set_pixel(tile.x, tile.y, paint)
	if upload:
		world_texture.update(world_image)
	water_sim.terrain_changed(tile, tile_id)
	lava_sim.terrain_changed(tile, tile_id)
	terrain_cache.invalidate(tile)
	sand_gravity.terrain_changed(tile)
	hanging_vines.terrain_changed(self, tile)
	underground.changed(self, tile)
	furnishings.terrain_changed(self, tile)
	farming.track(tile, tile_id)
	if not unsupported.is_empty():
		_edit_tile(unsupported.tile, 0, upload)
		_drop_item(unsupported.seed, 1, unsupported.tile)
	environment.refresh_column(tile.x)
	if WG.is_solid(old_id) != WG.is_solid(tile_id):
		environment.invalidate()
	if old_id in [7, 8] or tile_id in [7, 8]:
		foliage.invalidate()
	if old_id != tile_id:
		for column in range(tile.x - 1, tile.x + 2):
			_queue_grass_column(column)


func _outdoor_dirt_y(column: int) -> int:
	if world.is_empty() or column < 1 or column >= WG.WIDTH - 1 or _planet_climate(planet_index) not in [0, 1, 2]:
		return -1
	var y: int = environment.roof[column]
	var crash: Array = world.get("crash_site_bounds", [])
	if crash.size() == 3 and column >= int(crash[0]) + 6 and column <= int(crash[1]) - 6 and y == int(crash[2]):
		return -1
	if WG.tile_at(world["tiles"], column, y) != 2 or water_sim.amount_at(Vector2i(column, y - 1)) > 0:
		return -1
	return y


func _queue_grass_column(column: int) -> void:
	var dirt_y := _outdoor_dirt_y(column)
	if dirt_y < 0:
		grass_pending.erase(column)
		return
	if grass_pending.has(column) and int(grass_pending[column]["y"]) == dirt_y:
		return
	var delay := 2.0 + float(posmod(column * 83 + dirt_y * 47 + int(world["seed"]), 25)) * 0.1
	grass_pending[column] = {"y": dirt_y, "remaining": delay}


func _update_grass(delta: float) -> void:
	if grass_pending.is_empty():
		return
	var changed := false
	var grid: PackedByteArray = world["tiles"]
	for column in grass_pending.keys():
		var entry: Dictionary = grass_pending[column]
		entry["remaining"] = float(entry["remaining"]) - delta
		if float(entry["remaining"]) > 0.0:
			continue
		var y := int(entry["y"])
		if _outdoor_dirt_y(column) == y:
			WG.set_tile(grid, column, y, 1)
			world_image.set_pixel(column, y, WG.terrain_underlay_color(1))
			terrain_cache.invalidate(Vector2i(column, y))
			changed = true
		grass_pending.erase(column)
	if changed:
		world["tiles"] = grid
		world_texture.update(world_image)


func _drop_item(item: String, count: int, tile: Vector2i, wear_values: Array = []) -> void:
	if count <= 0:
		return
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var drops: Array = world.get("drops", [])
	drops.append({"item": item, "count": count, "x": float(tile.x * WG.TILE + 8),
		"y": float(tile.y * WG.TILE + 8), "vx": rng.randf_range(-45.0, 45.0),
		"vy": -rng.randf_range(35.0, 75.0), "pickup_delay": 0.22, "life": 45.0, "tool_wear": wear_values})
	world["drops"] = drops


func _drop_tree_block(tile: Vector2i, tile_id: int, source: Rect2, leaf_pixels: String = "", wood_pixels: String = "") -> void:
	var variation := posmod(tile.x * 83 + tile.y * 47, 7)
	var drift := float(posmod(tile.x * 37 + tile.y * 19, 29) - 14) if tile_id == 8 else float(posmod(tile.x * 17 + tile.y * 11, 11) - 5)
	var drops: Array = world.get("drops", [])
	if tile_id == 8 and leaf_pixels.is_empty():
		leaf_pixels = Marshalls.raw_to_base64(foliage.patch(world["tiles"], tile, int(world["seed"])).get_data())
	if tile_id == 7 and wood_pixels.is_empty():
		wood_pixels = Marshalls.raw_to_base64(foliage.trunk_patch(world["tiles"], tile, int(world["seed"])).get_data())
	drops.append({"item": "Wood" if tile_id == 7 else "Leaves", "count": 1,
		"x": float(tile.x * WG.TILE + 8), "y": float(tile.y * WG.TILE + 8), "leaf_pixels": leaf_pixels, "wood_pixels": wood_pixels,
		"vx": drift, "vy": 0.0, "pickup_delay": 0.65, "life": 90.0,
		"fall_gravity": float((58 if tile_id == 8 else 92) + variation * 5),
		"fall_cap": float((82 if tile_id == 8 else 112) + variation * 4),
		"block_id": tile_id, "source_x": int(source.position.x), "source_y": int(source.position.y),
		"landed": false})
	world["drops"] = drops


func _update_drops(delta: float) -> void:
	var drops: Array = world.get("drops", [])
	var grid: PackedByteArray = world["tiles"]
	for i in range(drops.size() - 1, -1, -1):
		var drop: Dictionary = drops[i]
		drop["pickup_delay"] = maxf(0.0, float(drop["pickup_delay"]) - delta)
		drop["life"] = float(drop["life"]) - delta
		if float(drop["life"]) <= 0.0:
			drops.remove_at(i)
			continue
		var tree_block := int(drop.get("block_id", 0)) in [7, 8]
		var pickup_ready := float(drop["pickup_delay"]) <= 0.0 and (not tree_block or bool(drop.get("landed", false)))
		var pull_target := player_pos + Vector2(8, 13)
		var pull_distance := Vector2(float(drop["x"]), float(drop["y"])).distance_to(pull_target)
		if pickup_ready and pull_distance < 112.0:
			var direction: Vector2 = (pull_target - Vector2(float(drop["x"]), float(drop["y"]))).normalized()
			var pull_speed := 95.0 + (112.0 - pull_distance) * 3.0
			drop["x"] = move_toward(float(drop["x"]), pull_target.x, absf(direction.x) * pull_speed * delta)
			drop["y"] = move_toward(float(drop["y"]), pull_target.y, absf(direction.y) * pull_speed * delta)
			drop["vx"] = 0.0
			drop["vy"] = 0.0
			if Vector2(float(drop["x"]), float(drop["y"])).distance_to(pull_target) < 19.0:
				_collect_drop(drop)
				drops.remove_at(i)
			continue
		var vx := float(drop["vx"]) * maxf(0.0, 1.0 - delta * (0.18 if tree_block else 2.0))
		if int(drop.get("block_id", 0)) == 8 and not bool(drop.get("landed", false)):
			vx = move_toward(vx, _wind_speed() * 0.65, delta * 14.0)
		var gravity := float(drop.get("fall_gravity", 95.0)) if tree_block else 480.0
		var speed_cap := float(drop.get("fall_cap", 115.0)) if tree_block else 300.0
		var vy := minf(speed_cap, float(drop["vy"]) + delta * gravity)
		var next_x := clampf(float(drop["x"]) + vx * delta, 2.0, WG.WIDTH * WG.TILE - 2.0)
		var next_y := clampf(float(drop["y"]) + vy * delta, 2.0, WG.HEIGHT * WG.TILE - 2.0)
		var half_size := 8.0 if tree_block else 5.0
		if vy > 0.0 and WG.is_solid(WG.tile_at(grid, int(next_x / WG.TILE), int((next_y + half_size) / WG.TILE))):
			next_y = floor((next_y + half_size) / WG.TILE) * WG.TILE - half_size
			vy = 0.0
			drop["landed"] = true
		drop["x"] = next_x
		drop["y"] = next_y
		drop["vx"] = vx
		drop["vy"] = vy
		if pickup_ready and Vector2(next_x, next_y).distance_to(pull_target) < 19.0:
			_collect_drop(drop)
			drops.remove_at(i)
	world["drops"] = drops


func _fell_tree(tile: Vector2i) -> void:
	var grid: PackedByteArray = world["tiles"]
	var trunk := Vector2i(-1, -1)
	var best := 1000
	for oy in range(-8, 9):
		for ox in range(-4, 5):
			if WG.tile_at(grid, tile.x + ox, tile.y + oy) == 7:
				var score: int = absi(ox) + absi(oy)
				if score < best:
					best = score
					trunk = tile + Vector2i(ox, oy)
	if trunk.x < 0:
		_drop_tree_block(tile, 8, _tree_source(grid, tile.x, tile.y, 8))
		_edit_tile(tile, 0)
		return
	var top := trunk.y
	var base := trunk.y
	while top > 0 and WG.tile_at(grid, trunk.x, top - 1) == 7:
		top -= 1
	while base < WG.HEIGHT - 1 and WG.tile_at(grid, trunk.x, base + 1) == 7:
		base += 1
	var cells := {}
	var pending: Array[Vector2i] = [trunk]
	cells[trunk] = true
	var cursor := 0
	while cursor < pending.size():
		var at := pending[cursor]
		cursor += 1
		for oy in range(-1, 2):
			for ox in range(-1, 2):
				var next := at + Vector2i(ox, oy)
				if cells.has(next) or absi(next.x - trunk.x) > 4 or next.y < top - 5 or next.y > base:
					continue
				var id := WG.tile_at(grid, next.x, next.y)
				if id == 8 or (id == 7 and next.x == trunk.x):
					cells[next] = true
					pending.append(next)
	# A placed leaf beside a tree does not cut a disconnected trunk.
	if not cells.has(tile):
		_drop_tree_block(tile, 8, _tree_source(grid, tile.x, tile.y, 8))
		_edit_tile(tile, 0)
		return
	var pieces: Array[Dictionary] = []
	for at: Vector2i in cells:
		var id := WG.tile_at(grid, at.x, at.y)
		var pixels := Marshalls.raw_to_base64(foliage.patch(grid, at, int(world["seed"])).get_data()) if id == 8 else ""
		var wood_pixels := Marshalls.raw_to_base64(foliage.trunk_patch(grid, at, int(world["seed"])).get_data()) if id == 7 else ""
		pieces.append({"tile": at, "id": id, "source": _tree_source(grid, at.x, at.y, id), "leaf_pixels": pixels, "wood_pixels": wood_pixels})
	var wood := 0
	mining_feedback_timer = 0.0
	for piece in pieces:
		var at: Vector2i = piece["tile"]
		world.get("mining_damage", {}).erase("%d,%d" % [at.x, at.y])
		WG.set_tile(grid, at.x, at.y, 11 if lava_sim.amount_at(at) > 0 else (4 if water_sim.amount_at(at) > 0 else 0))
		terrain_cache.invalidate(at)
		world_image.set_pixel(at.x, at.y, Color.TRANSPARENT)
		_drop_tree_block(at, int(piece["id"]), piece["source"], str(piece.get("leaf_pixels", "")), str(piece.get("wood_pixels", "")))
		if int(piece["id"]) == 7:
			wood += 1
	world["tiles"] = grid
	world_texture.update(world_image)
	foliage.invalidate()
	_queue_grass_column(trunk.x)
	_show_notice("Tree felled: %d blocks falling" % pieces.size())


func _tree_base(tile: Vector2i) -> Vector2i:
	var base := tile
	while base.y < WG.HEIGHT - 1 and WG.tile_at(world["tiles"], base.x, base.y + 1) == 7:
		base.y += 1
	return base


func _mining_hit(tile: Vector2i, tile_id: int) -> bool:
	var hits := Tools.mining_hits(equipped_tool, tile_id)
	if hits <= 1:
		return true
	var origin := _tree_base(tile) if tile_id == 7 else tile
	var key := "%d,%d" % [origin.x, origin.y]
	var damage: Dictionary = world.get("mining_damage", {})
	var previous: Dictionary = damage.get(key, {})
	var old_kind := int(previous.get("id", -1))
	var same_soil := (old_kind in [1, 2] and tile_id in [1, 2]) or (old_kind in [12, 13] and tile_id in [12, 13])
	var progress := float(previous.get("work", 0.0)) if old_kind == tile_id or same_soil else 0.0
	progress += Tools.mining_damage(equipped_tool, tile_id) / Tools.block_hardness(tile_id)
	if progress >= 0.99999:
		damage.erase(key)
		mining_feedback_timer = 0.0
		world["mining_damage"] = damage
		return true
	damage[key] = {"id": tile_id, "work": progress}
	world["mining_damage"] = damage
	mining_feedback_tile = tile
	mining_feedback_progress = progress
	mining_feedback_timer = 1.0
	return false


func _draw_mining_feedback() -> void:
	if mining_feedback_timer <= 0.0:
		return
	var at := Vector2(mining_feedback_tile * WG.TILE) - camera_pos
	draw_rect(Rect2(at, Vector2(16, 16)), Color(1, 0.88, 0.6, 0.55), false, 1.0)
	draw_rect(Rect2(at + Vector2(-2, -7), Vector2(20, 3)), Color("283740"))
	draw_rect(Rect2(at + Vector2(-2, -7), Vector2(20 * mining_feedback_progress, 3)), Color("e2bb76"))
	_text("%d%%" % roundi(mining_feedback_progress * 100), at + Vector2(-2, -11), 11, Color("fff2ce"))


func _wear_pickaxe(item: String, cost: int = 1) -> void:
	if tool_wear.spend(item, inventory, cost):
		_refresh_hotbar()
		_show_notice.call_deferred(Tools.display_name(item) + " broke")


func _mine(point: Vector2) -> void:
	if Tools.family(equipped_tool) == "Sword":
		_show_notice("Swords are for combat. Equip a digging tool")
		return
	if equipped_tool != "Watering Can" and mining_cooldown <= 0.0:
		_begin_tool_action("hoe" if use_hoe else "mine", point + camera_pos)
	var tile := _mouse_to_tile(point)
	if tile.x < 1 or tile.y < 1 or tile.x >= WG.WIDTH - 1 or tile.y >= WG.HEIGHT - 1 or not _in_dig_reach(tile):
		return
	var crop_target := farming.plant_target(tile)
	if crop_target.x >= 0:
		_farm_interaction(crop_target, equipped_tool, "")
		return
	var torch_key := "%d,%d" % [tile.x, tile.y]
	if world.get("torches", {}).has(torch_key):
		if mining_cooldown > 0.0:
			return
		mining_cooldown = Tools.mining_interval(equipped_tool)
		world["torches"].erase(torch_key)
		environment.invalidate()
		_add_item("Torch", 1)
		if sound != null:
			sound.pickup(Vector2(tile * WG.TILE) + Vector2(8, 8))
		_show_notice("Torch recovered")
		return
	var grid: PackedByteArray = world["tiles"]
	var old_id: int = WG.tile_at(grid, tile.x, tile.y)
	if furnishings.harvest(self, tile):
		return
	if equipped_tool in ["Hammer", "Mattock"] and background_ores.harvest(self, tile):
		return
	if equipped_tool not in ["Watering Can", "Hoe"] and mining_cooldown <= 0.0 and underground.harvest(self, point + camera_pos):
		mining_cooldown = Tools.mining_interval(equipped_tool)
		return
	if equipped_tool not in ["Watering Can", "Hoe"] and mining_cooldown <= 0.0 and hanging_vines.harvest_at(self, point + camera_pos):
		mining_cooldown = Tools.mining_interval(equipped_tool)
		return
	if equipped_tool != "Watering Can" and mining_cooldown <= 0.0 and ground_life.harvest_at(self, point + camera_pos):
		mining_cooldown = Tools.mining_interval(equipped_tool)
		return
	if background_ores.harvest(self, tile):
		return
	if old_id == 16 or equipped_tool in ["Hoe", "Watering Can"]:
		if not _farm_interaction(tile, equipped_tool, "") and equipped_tool == "Watering Can":
			_start_watering(tile)
		return
	if old_id in [14, 15]:
		return
	if old_id == 0 or old_id == 4 or old_id == 11:
		return
	if mining_cooldown > 0.0:
		return
	if not Tools.can_harvest(equipped_tool, old_id):
		_show_notice(Tools.requirement(old_id))
		return
	mining_cooldown = Tools.mining_interval(equipped_tool, old_id)
	if sound != null:
		sound.impact(old_id, Vector2(tile * WG.TILE) + Vector2(8, 8))
	if not _mining_hit(tile, old_id):
		return
	_wear_pickaxe(equipped_tool)
	if old_id == 7:
		_fell_tree(tile)
		return
	if old_id == 8:
		var pixels := Marshalls.raw_to_base64(foliage.patch(grid, tile, int(world["seed"])).get_data())
		_drop_tree_block(tile, 8, _tree_source(grid, tile.x, tile.y, 8), pixels)
		_edit_tile(tile, 0)
		return
	if old_id in [34, 35, 36, 37]:
		var origin_x := tile.x - 1 if old_id in [36, 37] else tile.x
		var station_name := "Workbench" if old_id in [34, 36] else "Furnace"
		if station_name == "Furnace":
			var recovered := furnaces.remove(Vector2i(origin_x, tile.y))
			for item: String in recovered:
				_drop_item(item, int(recovered[item]), tile)
		else:
			for stack: Dictionary in stations.remove_workbench(Vector2i(origin_x, tile.y)):
				_drop_item(str(stack["item"]), int(stack["count"]), tile, stack.get("wear", []))
		if stations.is_open() and stations.key == "%d,%d" % [origin_x, tile.y]:
			stations.close()
		_edit_tile(Vector2i(origin_x, tile.y), 0)
		_edit_tile(Vector2i(origin_x + 1, tile.y), 0)
		_drop_item(station_name, 1, tile)
		_show_notice(station_name + " dropped")
		return
	if old_id == 30:
		var chest_key := "%d,%d" % [tile.x, tile.y]
		var stored: Dictionary = world.get("chest_contents", {}).get(chest_key, {} if world.get("placed_chests", {}).has(chest_key) else {"Coal Ore": 3, "Copper Ore": 2})
		for item: String in stored:
			if int(stored[item]) > 0:
				_drop_item(item, int(stored[item]), tile, world.get("chest_tool_wear", {}).get(chest_key, {}).get(item, []))
		world.get("chest_tool_wear", {}).erase(chest_key)
		world.get("chest_contents", {}).erase(chest_key)
		world.get("placed_chests", {}).erase(chest_key)
		if interactions.chest_key == chest_key:
			interactions.close()
		_drop_item("Chest", 1, tile)
		_show_notice("Chest and stored items dropped")
	else:
		_drop_item(ITEM_FOR_TILE.get(old_id, "Stone"), 1, tile)
	_edit_tile(tile, 0)


func _place(point: Vector2) -> void:
	var selected: String = place_items[selected_slot]
	if food.edible(selected):
		_stop_held_actions()
		_eat_food(selected)
		return
	var tile := _mouse_to_tile(point)
	if tile.x < 1 or tile.y < 1 or tile.x >= WG.WIDTH - 1 or tile.y >= WG.HEIGHT - 1 or not _in_reach(tile):
		return
	if GroundLife.has_item(selected):
		if int(inventory.get(selected, 0)) <= 0:
			_show_notice("No " + selected + " in inventory")
		elif ground_life.place(self, selected, tile):
			inventory[selected] -= 1
			_show_notice(("Released " if GroundLife.animal(GroundLife.SPECIES[GroundLife.ITEMS.find(selected)]) else "Planted ") + selected)
		else:
			_show_notice("Choose clear ground with room for " + selected)
		return
	if _farm_interaction(tile, equipped_tool if equipped_tool in ["Hoe", "Watering Can"] else "Hand", place_items[selected_slot]):
		return
	var grid: PackedByteArray = world["tiles"]
	var item: String = place_items[selected_slot]
	if inventory.get(item, 0) <= 0:
		_show_notice("No " + item + " in inventory")
		return
	if Furnishings.has_item(item):
		if furnishings.place(self, item, tile):
			inventory[item] -= 1
		return
	if not furnishings.at(tile).is_empty():
		_show_notice("Remove the furnishing first")
		return
	if item == "Torch":
		if WG.tile_at(grid, tile.x, tile.y) != 0:
			return
		var torch_key := "%d,%d" % [tile.x, tile.y]
		if world["torches"].has(torch_key):
			return
		world["torches"][torch_key] = true
		expedition.placed(item, tile)
		environment.invalidate()
		inventory[item] -= 1
		_show_notice("Torch placed")
		return
	if item in ["Workbench", "Furnace"]:
		_place_station(tile, item)
		return
	if not TILE_FOR_ITEM.has(item):
		_show_notice(Tools.display_name(item) + " cannot be placed as a block")
		return
	if WG.tile_at(grid, tile.x, tile.y) not in [0, 4, 11]:
		return
	var tile_rect := Rect2(tile.x * WG.TILE, tile.y * WG.TILE, WG.TILE, WG.TILE)
	if tile_rect.intersects(_player_rect(player_pos)):
		return
	if WG.is_solid(int(TILE_FOR_ITEM[item])) and not water_sim.displace(tile):
		_show_notice("The water needs somewhere to move before this block can be placed")
		return
	if WG.is_solid(int(TILE_FOR_ITEM[item])) and not lava_sim.displace(tile):
		_show_notice("The lava needs somewhere to move before this block can be placed")
		return
	inventory[item] -= 1
	_edit_tile(tile, TILE_FOR_ITEM[item])
	expedition.placed(item, tile)
	if item == "Chest":
		world["placed_chests"]["%d,%d" % [tile.x, tile.y]] = true
		if not world.has("chest_contents"):
			world["chest_contents"] = {}
		world["chest_contents"]["%d,%d" % [tile.x, tile.y]] = {}


func _place_station(tile: Vector2i, item: String) -> void:
	if tile.x >= WG.WIDTH - 2 or tile.y >= WG.HEIGHT - 2:
		return
	var grid: PackedByteArray = world["tiles"]
	for dx in range(2):
		if not furnishings.at(tile + Vector2i(dx,0)).is_empty() or not furnishings.at(tile + Vector2i(dx,-1)).is_empty():
			_show_notice("Remove the furnishing first")
			return
		if WG.tile_at(grid, tile.x + dx, tile.y) != 0 or not WG.is_solid(WG.tile_at(grid, tile.x + dx, tile.y + 1)):
			_show_notice("Place the station on two solid blocks")
			return
		var tile_rect := Rect2((tile.x + dx) * WG.TILE, tile.y * WG.TILE, WG.TILE, WG.TILE)
		if tile_rect.intersects(_player_rect(player_pos)):
			return
	var left_id := 34 if item == "Workbench" else 35
	_edit_tile(tile, left_id)
	_edit_tile(tile + Vector2i(1, 0), left_id + 2)
	expedition.placed(item, tile)
	inventory[item] -= 1
	_show_notice(item + " placed")


func _add_item(item: String, amount: int, wear_values: Array = []) -> void:
	if item == "Corn Seed":
		item = "Crop Seeds"
	tool_wear.sync(inventory)
	inventory[item] = int(inventory.get(item, 0)) + amount
	if amount > 0:
		expedition.record_item(item)
	tool_wear.receive(item, amount, wear_values, inventory)


func _collect_drop(drop: Dictionary) -> void:
	expedition.gathered(str(drop["item"]), int(drop["count"]))
	_add_item(str(drop["item"]), int(drop["count"]), drop.get("tool_wear", []))
	if sound != null:
		sound.pickup(Vector2(float(drop["x"]), float(drop["y"])))


func _set_recipe_tab(index: int) -> void:
	recipe_tab = clampi(index, 0, RECIPE_TABS.size() - 1)
	if recipe_index not in RECIPE_GROUPS[recipe_tab]:
		recipe_index = RECIPE_GROUPS[recipe_tab][0]


func _toggle_crafting(index: int) -> void:
	if index > 0:
		var wanted := "Workbench" if index == 1 else "Furnace"
		if stations.is_open() and stations.kind == wanted.to_lower():
			stations.close()
			return
		var selected: Dictionary = interactions.target(wanted)
		if selected.is_empty():
			_show_notice("Use F beside a " + wanted + " to open its slots")
		else:
			stations.open(selected)
		return
	stations.close(false)
	interactions.close(false)
	if crafting_open and recipe_tab == index:
		crafting_open = false
		return
	inventory_open = false
	crafting_open = true
	_set_recipe_tab(index)


func _cycle_recipe(direction: int) -> void:
	var group: Array = RECIPE_GROUPS[recipe_tab]
	var current := group.find(recipe_index)
	recipe_index = group[posmod(current + direction, group.size())]


func _recipe_page() -> int:
	return maxi(0, RECIPE_GROUPS[recipe_tab].find(recipe_index)) / RECIPE_PAGE_SIZE


func _visible_recipes() -> Array:
	var first := _recipe_page() * RECIPE_PAGE_SIZE
	return RECIPE_GROUPS[recipe_tab].slice(first, first + RECIPE_PAGE_SIZE)


func _cycle_recipe_page(direction: int) -> void:
	var group: Array = RECIPE_GROUPS[recipe_tab]
	var pages := int(ceil(float(group.size()) / RECIPE_PAGE_SIZE))
	var page := posmod(_recipe_page() + direction, pages)
	recipe_index = group[page * RECIPE_PAGE_SIZE]


func _craft() -> void:
	var recipe: Dictionary = RECIPES[recipe_index]
	if stations.is_open() and stations.kind == "workbench":
		stations.craft(recipe_index)
		return
	if recipe.has("station"):
		_show_notice("Use this station's own ingredient and output slots")
		return
	for item in recipe["needs"]:
		if int(inventory.get(item, 0)) < int(recipe["needs"][item]):
			_show_notice("Need more " + str(item))
			return
	for item in recipe["needs"]:
		inventory[item] -= int(recipe["needs"][item])
	_add_item(recipe["out"], recipe["count"])
	var output := str(recipe["out"])
	if (Tools.tier(output) > 1 or output in ["Gold Pickaxe", "Shovel", "Gold Shovel"]) and (Tools.family(output) == Tools.family(equipped_tool)
		or int(inventory.get(equipped_tool, 0)) <= 0):
		_equip_inventory_item(output)
	_show_notice(("Cooked " if food.edible(output) else "Crafted ") + recipe["name"]
		+ (" - " + Tools.summary(output) if Tools.has_item(output) and not Tools.summary(output).is_empty() else ""))


func _near_station(station: String) -> bool:
	var grid: PackedByteArray = world["tiles"]
	var id := 34 if station == "Workbench" else 35
	var player_tile := Vector2i(int(player_pos.x / WG.TILE), int(player_pos.y / WG.TILE))
	for y in range(maxi(1, player_tile.y - 6), mini(WG.HEIGHT - 1, player_tile.y + 7)):
		for x in range(maxi(1, player_tile.x - 6), mini(WG.WIDTH - 1, player_tile.x + 7)):
			if WG.tile_at(grid, x, y) == id:
				return true
	return false


func _save_game() -> void:
	_refresh_hotbar()
	if scene_name == "planet":
		_update_water(0.0)
		world["player_pos"] = player_pos
		worlds[_world_key()] = world
	var saved_worlds := {}
	for key in worlds:
		var entry: Dictionary = worlds[key]
		var point: Vector2 = entry.get("player_pos", entry["spawn"])
		var biome_columns: PackedByteArray = entry.get("biomes", PackedByteArray())
		saved_worlds[key] = {
			"tiles": Marshalls.raw_to_base64(entry["tiles"]),
			"world_height": int(entry["tiles"].size() / WG.WIDTH),
			"underground_version": entry.get("underground_version", 0),
			"underworld_structures_version": entry.get("underworld_structures_version", 0),
			"underworld_forts": entry.get("underworld_forts", []),
			"cave_life": entry.get("cave_life", []), "cave_life_version": entry.get("cave_life_version", 0),
			"background_ores": entry.get("background_ores", []), "background_ore_version": entry.get("background_ore_version", 0),
			"furniture": entry.get("furniture", {}), "wood_background": entry.get("wood_background", {}),
			"underground_pools": entry.get("underground_pools", []),
			"surface": Array(entry["surface"]),
			"spawn": [entry["spawn"].x, entry["spawn"].y],
			"player_pos": [point.x, point.y],
			"seed": entry["seed"], "climate": entry["climate"],
			"creatures": entry.get("creatures", []),
			"vines": entry.get("vines", []), "vines_version": entry.get("vines_version", 0),
			"flyers_version": entry.get("flyers_version", 0),
			"wildlife_version": entry.get("wildlife_version", 0),
			"vine_growth_clock": entry.get("vine_growth_clock", 0.0),
			"npc": entry.get("npc", {}),
			"quest_done": entry.get("quest_done", false),
			"crops": entry.get("crops", {}),
			"torches": entry.get("torches", {}),
			"placed_chests": entry.get("placed_chests", {}),
			"chest_contents": entry.get("chest_contents", {}),
			"chest_tool_wear": entry.get("chest_tool_wear", {}),
			"furnaces": entry.get("furnaces", {}),
			"workbenches": entry.get("workbenches", {}),
			"drops": entry.get("drops", []),
			"falling_sand": entry.get("falling_sand", []),
			"water": _pack_water(entry),
			"rain_water": _pack_water(entry, "rain_water"),
			"lava": _pack_water(entry, "lava"),
			"lava_cooling": _pack_water(entry, "lava_cooling"),
			"snow": _pack_water(entry, "snow"),
			"snow_runoff_time": float(entry.get("snow_runoff_time", 0.0)),
			"forest_density_version": int(entry.get("forest_density_version", 0)),
			"biomes": Marshalls.raw_to_base64(biome_columns) if not biome_columns.is_empty() else "",
			"biome_version": int(entry.get("biome_version", 0)),
			"mining_damage": entry.get("mining_damage", {}),
			"ground_life": entry.get("ground_life", []),
			"ground_life_version": int(entry.get("ground_life_version", 0)),
			"ground_cover_version": int(entry.get("ground_cover_version", 0)),
			"surface_rocks_version": int(entry.get("surface_rocks_version", 0)),
			"surface_basins": entry.get("surface_basins", []),
			"desert_flora_version": int(entry.get("desert_flora_version", 0)),
			"ocean_fill_version": int(entry.get("ocean_fill_version", 0)),
			"ocean_filled_cells": int(entry.get("ocean_filled_cells", 0)),
			"ocean_preparation": entry.get("ocean_preparation", {}),
			"sea_level": int(entry.get("sea_level", 98)),
			"ice_pillars": entry.get("ice_pillars", []),
			"ice_spires_version": int(entry.get("ice_spires_version", 0)),
			"cave_entrances": entry.get("cave_entrances", []),
			"farm_rng_state": str(entry.get("farm_rng_state", "")),
			"farm_budget": entry.get("farm_budget", 0.0),
			"farm_plants": entry.get("farm_plants", {}),
			"farm_moisture": entry.get("farm_moisture", {}),
		}
	var data := {
		"schema": 2, "galaxy_seed": galaxy_seed, "star_index": star_index,
		"expedition": expedition.data, "dev_travel_unlocked": dev_travel_unlocked,
		"planet_index": planet_index, "scene": scene_name,
		"inventory": inventory, "health": health, "player_name": player_name,
		"inventory_order": _inventory_items(),
		"character_appearance": character_appearance,
		"food_cooldown": food_cooldown,
		"mining_cooldown": mining_cooldown, "attack_cooldown": attack_cooldown,
		"inventory_trash": inventory_trash,
		"selected_slot": selected_slot, "hotbar_page": hotbar_page,
		"hotbar_slots": place_items,
		"tool_wear": tool_wear.uses,
		"equipped_tool": equipped_tool,
		"time_of_day": time_of_day, "day_count": day_count, "weather": weather,
		"weather_cycle": weather_cycle, "weather_timer": weather_timer,
		"weather_blend": weather_blend.snapshot(),
		"worlds": saved_worlds,
	}
	var file := FileAccess.open(save_path, FileAccess.WRITE)
	if file == null:
		_show_notice("Could not write save file")
		return
	file.store_string(JSON.stringify(data))
	file.close()
	_show_notice("Saved game")


func _load_game() -> void:
	stations.close(false)
	inventory_order.clear()
	if not FileAccess.file_exists(save_path):
		_show_notice("No Godot save exists yet")
		return
	var file := FileAccess.open(save_path, FileAccess.READ)
	if file == null:
		_show_notice("Could not open save file")
		return
	var parsed = JSON.parse_string(file.get_as_text())
	file.close()
	if not parsed is Dictionary or int(parsed.get("schema", -1)) not in [1, 2]:
		_show_notice("Save format is unsupported")
		return
	galaxy_seed = int(parsed.get("galaxy_seed", galaxy_seed))
	expedition.data = parsed.get("expedition", {}) if parsed.get("expedition", {}) is Dictionary else {}
	star_index = int(parsed.get("star_index", 0))
	planet_index = int(parsed.get("planet_index", 0))
	inventory = parsed.get("inventory", {})
	if inventory.has("Corn Seed"):
		inventory["Crop Seeds"] = int(inventory.get("Crop Seeds", 0)) + int(inventory["Corn Seed"])
		inventory.erase("Corn Seed")
	tool_wear.restore(parsed.get("tool_wear", {}), inventory)
	if parsed.get("inventory_order", []) is Array:
		for item in parsed.get("inventory_order", []):
			if item is String and item not in inventory_order:
				inventory_order.append(item)
	inventory_trash = {}
	var saved_trash = parsed.get("inventory_trash", {})
	if saved_trash is Dictionary and not str(saved_trash.get("item", "")).is_empty() and int(saved_trash.get("count", 0)) > 0:
		inventory_trash = {"item": str(saved_trash["item"]), "count": int(saved_trash["count"])}
		inventory_trash["tool_wear"] = saved_trash.get("tool_wear", []) if saved_trash.get("tool_wear", []) is Array else []
		if inventory_trash["item"] == "Corn Seed":
			inventory_trash["item"] = "Crop Seeds"
	inventory_drag_item = ""
	inventory_dragging = false
	inventory_drag_slot = -1
	inventory_page = 0
	equipped_tool = str(parsed.get("equipped_tool", "Hand"))
	if equipped_tool != "Hand" and (not tool_textures.has(equipped_tool) or int(inventory.get(equipped_tool, 0)) <= 0):
		equipped_tool = "Hand"
	use_pickaxe = Tools.family(equipped_tool) == "Pickaxe"
	use_hoe = equipped_tool == "Hoe"
	mining_cooldown = clampf(float(parsed.get("mining_cooldown", 0.0)), 0.0, Tools.MINING_SWING)
	attack_cooldown = clampf(float(parsed.get("attack_cooldown", 0.0)), 0.0, 0.60)
	dev_mode = false
	dev_travel_unlocked = bool(parsed.get("dev_travel_unlocked", false))
	dev_invulnerable = false
	dev_free_flight = false
	selected_slot = clampi(int(parsed.get("selected_slot", 0)), 0, place_items.size() - 1)
	if parsed.has("hotbar_slots"):
		hotbar.restore(parsed["hotbar_slots"], inventory)
	else:
		# Preserve owned legacy catalog positions, then put its separately equipped tool in a slot.
		var legacy: Array = []
		legacy.resize(Hotbar.SIZE)
		legacy.fill("")
		for index in range(mini(ITEM_CATALOG.size(), Hotbar.SIZE)):
			legacy[index] = ITEM_CATALOG[index]
		hotbar.restore(legacy, inventory)
		if equipped_tool != "Hand":
			var tool_slot := hotbar.add(equipped_tool, inventory)
			if tool_slot >= 0:
				selected_slot = tool_slot
	_select_hotbar_slot(selected_slot)
	player_name = str(parsed.get("player_name", player_name)).substr(0, 24)
	var saved_appearance: Variant = parsed.get("character_appearance", {})
	_apply_character_appearance(saved_appearance if saved_appearance is Dictionary else {})
	health = clampi(int(parsed.get("health", 100)), 0, 100)
	food_cooldown = clampf(float(parsed.get("food_cooldown", 0.0)), 0.0, FoodCatalog.COOLDOWN)
	eat_visual = 0.0
	food_feedback_timer = 0.0
	time_of_day = float(parsed.get("time_of_day", 0.25))
	day_count = maxi(1, int(parsed.get("day_count", 1)))
	weather = str(parsed.get("weather", "Clear"))
	pending_weather_blend = parsed.get("weather_blend", {}) if parsed.get("weather_blend", {}) is Dictionary else {}
	weather_cycle = maxi(0, int(parsed.get("weather_cycle", 0)))
	weather_timer = clampf(float(parsed.get("weather_timer", 0.0)), 0.0, 79.999)
	cloud_cover = _cloud_target()
	worlds.clear()
	farms.clear()
	for key in parsed.get("worlds", {}):
		var saved: Dictionary = parsed["worlds"][key]
		var raw := Marshalls.base64_to_raw(saved.get("tiles", ""))
		if raw.size() not in [WG.WIDTH * WG.HEIGHT, WG.WIDTH * WG.LEGACY_HEIGHT]:
			continue
		if int(parsed["schema"]) == 1:
			# The first Godot build used 9 for planks. Natural trunks and
			# hand-placed wood both used 7, so those remain unchanged.
			for tile_index in range(raw.size()):
				if raw[tile_index] == 9:
					raw[tile_index] = 33
		var spawn_data: Array = saved.get("spawn", [WG.WIDTH * 8, 64])
		var pos_data: Array = saved.get("player_pos", spawn_data)
		worlds[key] = {
			"tiles": raw, "surface": PackedInt32Array(saved.get("surface", [])),
			"underground_version": int(saved.get("underground_version", 0)),
			"underworld_structures_version": int(saved.get("underworld_structures_version", 0)),
			"underworld_forts": saved.get("underworld_forts", []),
			"cave_life": saved.get("cave_life", []), "cave_life_version": int(saved.get("cave_life_version", 0)),
			"background_ores": saved.get("background_ores", []), "background_ore_version": int(saved.get("background_ore_version", 0)),
			"furniture": saved.get("furniture", {}), "wood_background": saved.get("wood_background", {}),
			"underground_pools": saved.get("underground_pools", []),
			"spawn": Vector2(float(spawn_data[0]), float(spawn_data[1])),
			"player_pos": Vector2(float(pos_data[0]), float(pos_data[1])),
			"seed": int(saved.get("seed", 0)), "climate": int(saved.get("climate", 0)),
			"creatures": saved.get("creatures", []), "quest_done": bool(saved.get("quest_done", false)),
			"vines": saved.get("vines", []), "vines_version": int(saved.get("vines_version", 0)),
			"flyers_version": int(saved.get("flyers_version", 0)),
			"wildlife_version": int(saved.get("wildlife_version", 0)),
			"vine_growth_clock": float(saved.get("vine_growth_clock", 0.0)),
			"crops": saved.get("crops", {}), "torches": saved.get("torches", {}),
			"placed_chests": saved.get("placed_chests", {}), "drops": saved.get("drops", []),
			"falling_sand": saved.get("falling_sand", []),
			"chest_contents": saved.get("chest_contents", {}),
			"chest_tool_wear": saved.get("chest_tool_wear", {}),
			"furnaces": saved.get("furnaces", {}),
			"workbenches": saved.get("workbenches", {}),
			"water": _unpack_water(str(saved.get("water", ""))),
			"rain_water": _unpack_water(str(saved.get("rain_water", ""))),
			"lava": _unpack_water(str(saved.get("lava", ""))),
			"lava_cooling": _unpack_water(str(saved.get("lava_cooling", ""))),
			"snow": _unpack_water(str(saved.get("snow", ""))),
			"snow_runoff_time": float(saved.get("snow_runoff_time", 0.0)),
			"forest_density_version": int(saved.get("forest_density_version", 0)),
			"biomes": Marshalls.base64_to_raw(str(saved.get("biomes", ""))),
			"biome_version": int(saved.get("biome_version", 0)),
			"mining_damage": saved.get("mining_damage", {}),
			"ground_life": saved.get("ground_life", []),
			"ground_life_version": int(saved.get("ground_life_version", 0)),
			"ground_cover_version": int(saved.get("ground_cover_version", 0)),
			"surface_rocks_version": int(saved.get("surface_rocks_version", 0)),
			"surface_basins": saved.get("surface_basins", []),
			"desert_flora_version": int(saved.get("desert_flora_version", 0)),
			"ocean_fill_version": int(saved.get("ocean_fill_version", 0)),
			"ocean_filled_cells": int(saved.get("ocean_filled_cells", 0)),
			"ocean_preparation": saved.get("ocean_preparation", {}),
			"sea_level": int(saved.get("sea_level", 98)),
			"ice_pillars": saved.get("ice_pillars", []),
			"ice_spires_version": int(saved.get("ice_spires_version", 0)),
			"cave_entrances": saved.get("cave_entrances", []),
			"farm_rng_state": str(saved.get("farm_rng_state", "")),
			"farm_budget": float(saved.get("farm_budget", 0.0)),
			"farm_plants": saved.get("farm_plants", {}),
			"farm_moisture": saved.get("farm_moisture", {}),
		}
		if not saved.get("npc", {}).is_empty():
			worlds[key]["npc"] = saved["npc"]
	_make_galaxy()
	star_index = clampi(star_index, 0, star_points.size() - 1)
	planet_index = clampi(planet_index, 0, 7)
	_make_system()
	selected_planet_index = planet_index
	paused = false
	if parsed.get("scene", "system") == "planet":
		_open_planet(planet_index)
	elif parsed.get("scene", "galaxy") == "system":
		scene_name = "system"
	else:
		scene_name = "galaxy"
	_show_notice("Loaded Godot save")
	queue_redraw()


func _pack_water(entry: Dictionary, field: String = "water") -> String:
	var amounts: PackedByteArray = entry.get(field, PackedByteArray())
	if amounts.size() not in [WG.WIDTH * WG.HEIGHT, WG.WIDTH * WG.LEGACY_HEIGHT]:
		return ""
	return Marshalls.raw_to_base64(amounts.compress(FileAccess.COMPRESSION_DEFLATE))


func _unpack_water(encoded: String) -> PackedByteArray:
	if encoded.is_empty():
		return PackedByteArray()
	return Marshalls.base64_to_raw(encoded).decompress_dynamic(WG.WIDTH * WG.HEIGHT, FileAccess.COMPRESSION_DEFLATE)


func _text(text_value: String, at: Vector2, size: int = 22, color: Color = Color.WHITE) -> void:
	draw_string(ThemeDB.fallback_font, at, text_value, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)


func _fill_rounded_rect(rect: Rect2, color: Color, radius: float) -> void:
	var r := minf(radius, minf(rect.size.x, rect.size.y) * 0.5)
	var points := PackedVector2Array()
	for corner in [[Vector2(rect.size.x - r, r), -PI * 0.5],
		[Vector2(rect.size.x - r, rect.size.y - r), 0.0],
		[Vector2(r, rect.size.y - r), PI * 0.5], [Vector2(r, r), PI]]:
		for step in range(7):
			var angle: float = float(corner[1]) + float(step) * PI / 12.0
			points.append(rect.position + Vector2(corner[0]) + Vector2(cos(angle), sin(angle)) * r)
	draw_colored_polygon(points, color)


func _rounded_box(rect: Rect2, fill: Color, border: Color, radius: float = 14.0, border_width: float = 2.0) -> void:
	_fill_rounded_rect(rect, border, radius)
	_fill_rounded_rect(rect.grow(-border_width), fill, maxf(1.0, radius - border_width))


func _outline_rounded_rect(rect: Rect2, color: Color, radius: float, width: float = 2.0) -> void:
	var r := minf(radius, minf(rect.size.x, rect.size.y) * 0.5)
	draw_line(rect.position + Vector2(r, 0), rect.position + Vector2(rect.size.x - r, 0), color, width)
	draw_line(rect.position + Vector2(r, rect.size.y), rect.end - Vector2(r, 0), color, width)
	draw_line(rect.position + Vector2(0, r), rect.position + Vector2(0, rect.size.y - r), color, width)
	draw_line(rect.position + Vector2(rect.size.x, r), rect.end - Vector2(0, r), color, width)
	for corner in [[Vector2(r, r), PI, PI * 1.5], [Vector2(rect.size.x - r, r), PI * 1.5, TAU],
		[Vector2(r, rect.size.y - r), PI * 0.5, PI], [Vector2(rect.size.x - r, rect.size.y - r), 0.0, PI * 0.5]]:
		draw_arc(rect.position + corner[0], r, float(corner[1]), float(corner[2]), 12, color, width)


func _button(rect: Rect2, label: String) -> void:
	var hover := rect.has_point(get_viewport().get_mouse_position())
	_rounded_box(rect, Color("273d63") if hover else Color("101923"), Color("91b6d4"), 16.0, 2.0)
	_button_text(rect, label, 23, Color.WHITE, false, Vector2(16, 5))


func _button_text(rect: Rect2, label: String, size: int = 18, color: Color = Color.WHITE, centered: bool = true, padding: Vector2 = Vector2(8, 4)) -> void:
	UIText.draw(self, ThemeDB.fallback_font, label, rect, size, color, centered, padding)


func _draw_stars() -> void:
	draw_rect(Rect2(Vector2.ZERO, SCREEN), Color("071020"), true)
	for i in range(145):
		var p := Vector2(20 + posmod(i * 347 + i * i * 11, 1240), 16 + posmod(i * 193 + i * i * 7, 685))
		draw_circle(p, 0.8 if i % 4 else 1.4, Color(0.65, 0.78, 0.95, 0.45))


func _draw_galaxy_view() -> void:
	_text("Galaxy View - click a star to open system", Vector2(20, 40), 27)
	_text("ESC = Menu  |  F3 = Developer travel", Vector2(20, 68), 18, Color("a7b6c6"))
	_text("Green ring = active system  |  Cyan ring = visited system", Vector2(20, 91), 17, Color("a7b6c6"))
	var hover := -1
	var mouse := get_viewport().get_mouse_position()
	for i in range(star_points.size()):
		var p: Vector2 = star_points[i]
		var r := 6.0 + float(i % 5)
		if mouse.distance_to(p) <= r + 5.0:
			hover = i
			draw_circle(p, r + 7.0, Color(1.0, 0.88, 0.42, 0.17))
		var visited := false
		for planet in range(8):
			if worlds.has("%d_%d" % [i, planet]):
				visited = true
				break
		if visited:
			draw_arc(p, r + 4.0, 0, TAU, 28, Color("4cddf3"), 1.5)
		if i == star_index and not worlds.is_empty():
			draw_arc(p, r + 8.0, 0, TAU, 28, Color("78ff78"), 2.0)
		draw_circle(p, r, Color("ffe6a4") if i == hover else Color("f5d66f"))
	if hover >= 0:
		var at := mouse + Vector2(16, -16)
		if at.x > 960: at.x -= 280
		if at.y > 660: at.y -= 26
		draw_rect(Rect2(at - Vector2(7, 22), Vector2(290, 30)), Color(0.04, 0.08, 0.15, 0.94), true)
		_text("%s  |  %s" % [star_names[hover], star_types[hover]], at, 17)
	_text("%d star systems" % star_points.size(), Vector2(20, 693), 18, Color("b3c7d8"))


func _draw_orbital_rings(center: Vector2, radius: float, front: bool) -> void:
	for band in range(3):
		var inner := radius * (1.32 + float(band) * 0.22)
		var outer := inner + radius * (0.13 if band != 1 else 0.08)
		var points := PackedVector2Array()
		for step in range(33):
			var angle := (0.0 if front else PI) + float(step) / 32.0 * PI
			points.append(center + Vector2(cos(angle) * outer, sin(angle) * outer * 0.40).rotated(-0.28))
		for step in range(32, -1, -1):
			var angle := (0.0 if front else PI) + float(step) / 32.0 * PI
			points.append(center + Vector2(cos(angle) * inner, sin(angle) * inner * 0.40).rotated(-0.28))
		var tint: Color = [Color("d5c5a5"), Color("8797a5"), Color("bcb9ae")][band]
		tint.a = 0.88 if front else 0.54
		draw_colored_polygon(points, tint)


func _draw_system_view() -> void:
	var center := Vector2(640, 320)
	_text("Star System View - click a planet, E or button to enter", Vector2(20, 83), 20)
	_text("ESC = Galaxy  |  1-8 = select planet  |  F3 = Developer travel  |  Green band = habitable zone", Vector2(20, 109), 17, Color("aab9c8"))
	if dev_travel_unlocked:
		_text("Developer free travel enabled - expedition objectives paused", Vector2(20, 136), 16, Color("95dfaf"))
	elif expedition.active() and str(expedition.data.get("home", "")).is_empty():
		_text("First landing: choose the Temperate forest planet to begin your expedition", Vector2(20, 136), 16, Color("efca8d"))
	_button(Rect2(20, 20, 170, 42), "Back to Galaxy")
	var inner_r := _system_radius_for_au(system_hab_inner)
	var outer_r := _system_radius_for_au(system_hab_outer)
	draw_arc(center, (inner_r + outer_r) * 0.5, 0, TAU, 128, Color(0.24, 0.68, 0.40, 0.10), outer_r - inner_r)
	for hab_r in [inner_r, outer_r]:
		if hab_r < 280.0:
			draw_arc(center, hab_r, 0, TAU, 96, Color("63c88e"), 1.4)
	for i in range(system_planets.size()):
		var info: Dictionary = system_planets[i]
		draw_arc(center, float(info["radius"]), 0, TAU, 110, Color(0.43, 0.49, 0.58, 0.40), 1.0)
	var star_color := _star_light_color()
	draw_circle(center, 27, Color(star_color.r, star_color.g, star_color.b, 0.13))
	draw_circle(center, 18, star_color)
	for i in range(system_planets.size()):
		var info: Dictionary = system_planets[i]
		var p := _system_planet_position(i)
		var size := float(info["size"])
		var color := _planet_visual_color(int(info["climate"]))
		if bool(info["rings"]):
			_draw_orbital_rings(p, size, false)
		draw_circle(p, size, color)
		if bool(info["rings"]):
			_draw_orbital_rings(p, size, true)
		for moon in range(int(info["moons"])):
			var moon_angle: float = animation_clock * (0.3 + moon * 0.08) + TAU * float(moon) / maxi(1, int(info["moons"]))
			draw_circle(p + Vector2(cos(moon_angle), sin(moon_angle)) * (size + 10.0), 2.3, Color("bdc9d5"))
		if selected_planet_index == i:
			draw_arc(p, size + 4, 0, TAU, 40, Color.WHITE, 1.5)
		if worlds.has("%d_%d" % [star_index, i]):
			draw_arc(p, size + 7, 0, TAU, 40, Color("4cddf3"), 1.5)
		_text(str(i + 1), p + Vector2(size + 5, -size - 3), 15, Color("c6dce9"))
	expedition.draw_orbital_ship()
	draw_rect(Rect2(0, 600, 1280, 120), Color(0.035, 0.05, 0.08, 0.96), true)
	draw_line(Vector2(0, 600), Vector2(1280, 600), Color("8fa8bd"), 1)
	_text("%s  |  Type: %s" % [star_names[star_index], star_types[star_index]], Vector2(20, 621), 18)
	_text("Habitable zone: %.2f - %.2f AU-ish" % [system_hab_inner, system_hab_outer], Vector2(20, 641), 15, Color("abb9c7"))
	if selected_planet_index < 0:
		_text("Click a planet to view details.", Vector2(20, 677), 18, Color("aebdcb"))
	else:
		var selected: Dictionary = system_planets[selected_planet_index]
		var climate := int(selected["climate"])
		var biome_names := PackedStringArray()
		for biome: Dictionary in WG.Biomes.PROFILES[climate]:
			biome_names.append(str(biome["name"]))
		_text("%s  |  %s" % [selected["name"], WG.NAMES[climate]], Vector2(20, 661), 16)
		_text("Orbit %.2f AU  |  %s  |  %s  |  %d moons  |  %s" % [selected["au"], "Habitable" if selected["habitable"] else "Outside zone",
			"Possible life" if selected["life"] else "No detected life", selected["moons"], "Rings" if selected["rings"] else "No rings"], Vector2(20, 682), 15, Color("b8cad7"))
		_text("Biomes: %s  |  Weather: %s" % [", ".join(biome_names), "rain possible" if climate not in [3, 4, 5] else "dry"], Vector2(20, 703), 15, Color("b8cad7"))
	_draw_menu_button(Rect2(1055, 615, 205, 58), "Enter Planet (E)", selected_planet_index >= 0)


func _draw_menu_panel(rect: Rect2, title: String) -> void:
	_rounded_box(rect, Color(0.035, 0.067, 0.11, 0.96), Color("69aee2"), 22.0)
	_fill_rounded_rect(Rect2(rect.position + Vector2(10, 12), Vector2(7, rect.size.y - 24)), Color("ed9651"), 3.0)
	_text(title, rect.position + Vector2(30, 48), 30, Color("f7e5c9"))


func _draw_menu_button(rect: Rect2, label: String, enabled: bool = true) -> void:
	if enabled:
		_button(rect, label)
	else:
		_rounded_box(rect, Color("192331"), Color("4a5664"), 16.0, 1.0)
		_button_text(rect, label, 22, Color("8895a6"), false, Vector2(16, 5))


func _draw_main_showcase() -> void:
	var panel := Rect2(372, 30, 878, 660)
	_rounded_box(panel, Color("121928"), Color("75b5e0"), 24.0, 2.0)
	for band in range(33):
		var color := Color("080e1d").lerp(Color("19132e"), float(band) / 32.0)
		draw_rect(Rect2(panel.position + Vector2(20, band * 20), Vector2(panel.size.x - 40, 20)), color, true)
	for i in range(140):
		var sx := 384.0 + float(posmod(i * 359 + i * i * 37, 850))
		var sy := 42.0 + float(posmod(i * 211 + i * i * 19, 635))
		draw_circle(Vector2(sx, sy), 1.0 if i % 5 else 2.0, Color(0.73, 0.86, 1.0, 0.55 + float(i % 3) * 0.12))
	var center := Vector2(810, 387)
	for orbit in range(4):
		var points := PackedVector2Array()
		var rx := 130.0 + orbit * 78.0
		var ry := 65.0 + orbit * 40.0
		for step in range(73):
			var angle := float(step) / 72.0 * TAU
			points.append(center + Vector2(cos(angle) * rx, sin(angle) * ry))
		draw_polyline(points, Color(0.42, 0.64, 0.85, 0.35), 1.5)
		var travel := animation_clock * (0.16 / (1.0 + orbit * 0.36)) + orbit * 1.5
		var planet_pos := center + Vector2(cos(travel) * rx, sin(travel) * ry)
		var planet_color: Color = [Color("70bbf4"), Color("e2a171"), Color("a1d7b6"), Color("b9b7dc")][orbit]
		if orbit in [1, 3]:
			_draw_orbital_rings(planet_pos, 12.0 + orbit * 2.0, false)
		draw_circle(planet_pos, 12.0 + orbit * 2.0, planet_color)
		if orbit in [1, 3]:
			_draw_orbital_rings(planet_pos, 12.0 + orbit * 2.0, true)
	for glow in range(4, 0, -1):
		draw_circle(center, 62.0 + glow * 20.0, Color(1.0, 0.62, 0.24, 0.035))
	draw_circle(center, 63.0, Color("ffe5a6"))
	_outline_rounded_rect(panel.grow(-2.0), Color("75b5e0"), 22.0, 1.0)
	_text("MAIN MENU", panel.position + Vector2(22, 34), 18, Color("ffb46a"))
	_text("Drifting system feed", panel.position + Vector2(22, 60), 17, Color("a9c6dd"))
	_text("Chart a star system. Land. Survive. Push deeper.", panel.position + Vector2(22, panel.size.y - 28), 18, Color("c5d8e7"))


func _draw_main_menu() -> void:
	_draw_main_showcase()
	var panel := Rect2(26, 24, 320, 672)
	_rounded_box(panel, Color(0.035, 0.06, 0.10, 0.96), Color("68b4ed"), 22.0)
	_fill_rounded_rect(Rect2(39, 38, 7, 644), Color("f4974e"), 3.0)
	if logo != null:
		draw_texture_rect(logo, Rect2(51, 52, 270, 74), false)
	_text("Chart the stars. Land and survive.", Vector2(52, 165), 16, Color("b8d0e1"))
	for i in range(MAIN_MENU_ITEMS.size()):
		_draw_menu_button(Rect2(52, 228 + i * 61, 268, 51), MAIN_MENU_ITEMS[i], MAIN_MENU_ITEMS[i] not in ["Host Game", "Join Game"])
	_text("GALAXIS  /  GODOT BUILD", Vector2(52, 679), 13, Color("91a9bb"))


func _draw_input_field(rect: Rect2, value: String, active: bool, hint: String) -> void:
	_rounded_box(rect, Color("0b1728"), Color("ecc074") if active else Color("729ab4"), 12.0)
	var shown := value if not value.is_empty() else hint
	_text(shown + ("|" if active and int(animation_clock * 2.0) % 2 == 0 else ""), rect.position + Vector2(14, 34), 22, Color.WHITE if not value.is_empty() else Color("8299ad"))


func _draw_new_game_menu() -> void:
	character_creator.draw(self)


func _draw_load_menu() -> void:
	_draw_menu_panel(Rect2(300, 110, 680, 500), "LOAD GAME")
	var slot := Rect2(330, 226, 620, 180)
	draw_rect(slot, Color("10243b"), true)
	draw_rect(slot, Color("689ec2"), false, 2.0)
	if load_summary.is_empty():
		_text("No compatible Godot save found.", Vector2(355, 284), 24)
		_text("Start a new game and press F5 to create one.", Vector2(355, 326), 18, Color("a8c3d5"))
	else:
		_text(str(load_summary["name"]), Vector2(355, 276), 28)
		_text("Galaxy seed %d   |   %d visited worlds" % [load_summary["seed"], load_summary["worlds"]], Vector2(355, 320), 19, Color("c1d4e1"))
		_text("Star %d   |   Planet %d" % [load_summary["star"], load_summary["planet"]], Vector2(355, 356), 19, Color("a8c3d5"))
	_draw_menu_button(Rect2(330, 520, 190, 50), "Load", not load_summary.is_empty())
	_draw_menu_button(Rect2(540, 520, 190, 50), "Delete", not load_summary.is_empty())
	_button(Rect2(750, 520, 200, 50), "Back")


func _draw_settings_menu() -> void:
	_draw_menu_panel(Rect2(250, 80, 780, 560), "SETTINGS")
	for i in range(SETTINGS_TABS.size()):
		var rect := Rect2(280 + i * 180, 160, 165, 42)
		draw_rect(rect, Color("355779") if SETTINGS_TABS[i] == settings_tab else Color("172d49"), true)
		draw_rect(rect, Color("e5bd73") if SETTINGS_TABS[i] == settings_tab else Color("6e9ab8"), false, 2.0)
		_text(SETTINGS_TABS[i], rect.position + Vector2(14, 28), 18)
	match settings_tab:
		"Gameplay":
			_text("Day length", Vector2(300, 289), 23)
			_text("%d seconds" % int(settings_data["day_length"]), Vector2(515, 289), 21, Color("bfdae9"))
			_button(Rect2(735, 260, 60, 48), "-")
			_button(Rect2(815, 260, 60, 48), "+")
			_text("Night darkness", Vector2(300, 380), 23)
			_text("%d%%" % int(float(settings_data["night_dark"]) * 100.0 + 0.5), Vector2(555, 380), 21, Color("bfdae9"))
			_button(Rect2(735, 350, 60, 48), "-")
			_button(Rect2(815, 350, 60, 48), "+")
			_text("Changes apply immediately and save automatically.", Vector2(300, 477), 17, Color("a6c3d5"))
		"Video":
			_text("Display mode", Vector2(300, 290), 23)
			_button(Rect2(620, 260, 270, 50), "Fullscreen: On" if settings_data["fullscreen"] else "Fullscreen: Off")
			_text("The game keeps its 1280 x 720 canvas when resized.", Vector2(300, 385), 18, Color("a6c3d5"))
		"Audio":
			for row in range(3):
				var key: String = ["master_volume", "effects_volume", "ambience_volume"][row]
				_text(["Master volume", "Sound effects", "Rain ambience"][row], Vector2(300, 290 + row * 80), 23)
				_text("%d%%" % roundi(float(settings_data[key]) * 100), Vector2(610, 290 + row * 80), 21, Color("bfdae9"))
				_button(Rect2(735, 260 + row * 80, 60, 44), "-")
				_button(Rect2(815, 260 + row * 80, 60, 44), "+")
			_text("0% mutes a channel. Changes save automatically.", Vector2(300, 475), 16, Color("a6c3d5"))
			_button(Rect2(300, 500, 215, 42), "Test sound")
		"Controls":
			var lines := ["A/D or arrows  Walk     Space/W/Up  Jump or swim", "Mouse left  Attack or mine     Mouse right  Place / Eat", "1-9 / Tab / Wheel  Slot     Alt+Wheel / B  Bar", "I  Backpack    Ctrl+click item  Add to hotbar    Drag  Move", "C  Craft   M  Build   T  Tool   E  Talk   F  Interact   R  Eat", "G  Orbit   F3  Dev   F5  Save   F9  Load   Esc  Close"]
			for i in range(lines.size()):
				_text(lines[i], Vector2(300, 267 + i * 44), 18, Color("c5dbe8"))
	_button(Rect2(790, 550, 190, 48), "Back")


func _draw_help_menu() -> void:
	_draw_menu_panel(Rect2(250, 80, 780, 560), "HOW TO PLAY")
	var lines := ["Choose a star, then one of its eight planets.", "Cut a tree and watch each block fall to the ground.", "Hoe soil, water it, plant seeds, and harvest corn.", "Eat corn with R; roast it at a furnace for more healing.", "C crafts; M builds; I opens your pack; T cycles tools.", "F opens nearby chests and stations; E talks to robot R0-VR.", "F3 opens dev mode; F5 saves; Esc pauses."]
	for i in range(lines.size()):
		_text(lines[i], Vector2(300, 220 + i * 43), 19, Color("c5dbe8"))
	_button(Rect2(790, 550, 190, 48), "Back")


func _draw_confirm_menu() -> void:
	_draw_menu_panel(Rect2(390, 220, 500, 280), "CONFIRM")
	_text("Delete this Godot save?" if confirm_action == "delete_save" else "Quit Galaxis on Fire?", Vector2(420, 329), 23)
	_button(Rect2(420, 410, 190, 50), "Confirm")
	_button(Rect2(670, 410, 190, 50), "Cancel")


func _draw_pause_menu() -> void:
	var at: Vector2 = window_positions["pause"]
	draw_rect(Rect2(Vector2.ZERO, SCREEN), Color(0, 0, 0, 0.62), true)
	_draw_menu_panel(Rect2(at, Vector2(470, 445)), "PAUSED")
	_rounded_box(Rect2(at + Vector2(428, 15), Vector2(30, 30)), Color("743e46"), Color.WHITE, 6.0, 1.0)
	_text("X", at + Vector2(437, 38), 18)
	var labels := ["Resume", "Save Game", "Load Game", "Settings", "Save & Main Menu", "Save & Quit"]
	for i in range(labels.size()):
		_button(Rect2(at + Vector2(35, 73 + i * 58), Vector2(400, 46)), labels[i])


func _draw() -> void:
	if scene_name == "planet":
		_draw_planet()
		return
	var overlay_planet := (scene_name == "load" and load_return == "planet") or (scene_name == "settings" and settings_return == "planet") or (scene_name == "confirm" and confirm_return == "planet")
	if overlay_planet:
		_draw_planet()
		draw_rect(Rect2(Vector2.ZERO, SCREEN), Color(0, 0, 0, 0.55), true)
	else:
		_draw_stars()
	if scene_name == "menu":
		_draw_main_menu()
	elif scene_name == "new_game":
		_draw_new_game_menu()
	elif scene_name == "load":
		_draw_load_menu()
	elif scene_name == "settings":
		_draw_settings_menu()
	elif scene_name == "help":
		_draw_help_menu()
	elif scene_name == "confirm":
		_draw_confirm_menu()
	elif scene_name == "galaxy":
		_draw_galaxy_view()
	elif scene_name == "system":
		_draw_system_view()
	elif scene_name == "loading":
		_text(load_progress, Vector2(280, 340), 32)
		_text("Building terrain, caves, resources and a safe landing area", Vector2(280, 377), 19, Color("a6c1d2"))
	if dev_mode and scene_name in ["galaxy", "system"]:
		_draw_dev_panel()
	if notice_timer > 0.0 and scene_name != "planet":
		_text(notice, Vector2(35, 577) if scene_name == "system" else Vector2(35, 685), 18, Color("f5d78a"))


func _terrain_material(tile_id: int) -> String:
	match tile_id:
		1: return "grass"
		2, 12, 13: return "dirt"
		3, 20, 21, 22, 23, 24, 25, 26: return "stone"
		5: return "sand"
		45: return "gravel"
		6: return "snow"
		10: return "stone"
		17: return "obsidian"
		27: return "glacial_ice"
		9: return "wood"
		33: return "planks"
	return ""


func _terrain_connected(grid: PackedByteArray, x: int, y: int, material: String) -> bool:
	var neighbor := _terrain_material(WG.tile_at(grid, x, y))
	if material == "grass":
		return neighbor == "grass" or neighbor == "dirt"
	return neighbor == material or (material == "dirt" and neighbor == "grass")


func _terrain_frame(grid: PackedByteArray, x: int, y: int, material: String) -> Vector2i:
	# Frame rules from the Pygame terrain atlas: 18-pixel cells contain 16-pixel tiles.
	var up := _terrain_connected(grid, x, y - 1, material)
	var down := _terrain_connected(grid, x, y + 1, material)
	var left := _terrain_connected(grid, x - 1, y, material)
	var right := _terrain_connected(grid, x + 1, y, material)
	var upper_left := _terrain_connected(grid, x - 1, y - 1, material)
	var upper_right := _terrain_connected(grid, x + 1, y - 1, material)
	var lower_left := _terrain_connected(grid, x - 1, y + 1, material)
	var lower_right := _terrain_connected(grid, x + 1, y + 1, material)
	var variation := posmod((x * 73856093) ^ (y * 19349663), 3)
	if up and down and left and right:
		if not upper_left and not upper_right: return Vector2i(108 + 18 * variation, 18)
		if not lower_left and not lower_right: return Vector2i(108 + 18 * variation, 36)
		if not upper_left and not lower_left: return Vector2i(180, 18 * variation)
		if not upper_right and not lower_right: return Vector2i(198, 18 * variation)
		return Vector2i(18 + 18 * variation, 18)
	if not up and down and left and right: return Vector2i(18 + 18 * variation, 0)
	if up and not down and left and right: return Vector2i(18 + 18 * variation, 36)
	if up and down and not left and right: return Vector2i(0, 18 * variation)
	if up and down and left and not right: return Vector2i(72, 18 * variation)
	if not up and down and not left and right: return Vector2i([0, 36, 72][variation], 54)
	if not up and down and left and not right: return Vector2i([18, 54, 90][variation], 54)
	if up and not down and not left and right: return Vector2i([0, 36, 72][variation], 72)
	if up and not down and left and not right: return Vector2i([18, 54, 90][variation], 72)
	if up and down and not left and not right: return Vector2i(90, 18 * variation)
	if not up and not down and left and right: return Vector2i(108 + 18 * variation, 72)
	if not up and down and not left and not right: return Vector2i(108 + 18 * variation, 0)
	if up and not down and not left and not right: return Vector2i(108 + 18 * variation, 54)
	if not up and not down and not left and right: return Vector2i(162, 18 * variation)
	if not up and not down and left and not right: return Vector2i(216, 18 * variation)
	return Vector2i(162 + 18 * variation, 54)


func _draw_terrain_details(x0: int, y0: int, x1: int, y1: int) -> void:
	var grid: PackedByteArray = world["tiles"]
	for chunk in terrain_cache.visible(camera_pos):
		draw_texture(chunk["front"], chunk["position"] - camera_pos)
		for cell: Vector3i in chunk["decor"]:
			if cell.z == 7:
				_draw_tree_tile(grid, cell.x, cell.y, cell.z)
			elif cell.z in [34, 35]:
				_draw_station(cell.x, cell.y, cell.z)
			elif cell.z in [14, 15, 16]:
				_draw_crop(Vector2(cell.x, cell.y) * WG.TILE - camera_pos, cell.z)
			elif cell.z == 30:
				draw_texture_rect(terrain_sheets["chest"], Rect2(Vector2(cell.x, cell.y) * WG.TILE - camera_pos, Vector2(16, 16)), false)


func _draw_crop(at: Vector2, stage: int) -> void:
	if crop_sheet == null: crop_sheet = SpriteArt.texture("res://assets/sprites/farming/crops.png")
	var tile := Vector2i(floor((at + camera_pos) / WG.TILE))
	var row := int(CropCatalog.CROPS[farming.crop_at(tile)].row)
	var bend := clampf(_wind_speed() / 4500.0, -0.06, 0.06) * (0.65 + sin(animation_clock * 2.1 + tile.x * 1.7) * 0.35)
	draw_set_transform(at + Vector2(8, 16), bend)
	draw_texture_rect_region(crop_sheet, Rect2(Vector2(-16, -48), Vector2(32, 48)), Rect2((stage - 14) * 32, row * 48, 32, 48))
	draw_set_transform(Vector2.ZERO)


func _tree_source(grid: PackedByteArray, x: int, y: int, tile_id: int) -> Rect2:
	var col := 1
	var row := 0
	var variation := posmod((x * 73856093) ^ (y * 19349663), 4)
	if tile_id == 7:
		var above_wood := WG.tile_at(grid, x, y - 1) == 7
		var below_wood := WG.tile_at(grid, x, y + 1) == 7
		if below_wood and not above_wood:
			col = 0
		elif above_wood and not below_wood:
			col = 1
		else:
			col = 1 + variation
	else:
		var north := WG.tile_at(grid, x, y - 1) == 8
		var east := WG.tile_at(grid, x + 1, y) == 8
		var south := WG.tile_at(grid, x, y + 1) == 8
		var west := WG.tile_at(grid, x - 1, y) == 8
		if not north and not west: col = 2; row = 1
		elif not north and not east: col = 7; row = 1
		elif not north: col = 3 + variation % 3; row = 1
		elif not south and not west: col = 2; row = 2
		elif not south and not east: col = 7; row = 2
		elif not south: col = 3 + variation % 3; row = 2
		elif not west: col = 2; row = 2
		elif not east: col = 7; row = 2
		else: col = 3 + variation % 2; row = 2
	return Rect2(col * 18 + 1, row * 18 + 1, 16, 16)


func _draw_tree_tile(grid: PackedByteArray, x: int, y: int, tile_id: int) -> void:
	if tile_id != 7:
		return
	var texture := foliage.trunk_texture(grid, Vector2i(x, y), int(world["seed"]))
	var target := Rect2(Vector2(x, y) * WG.TILE - camera_pos, Vector2(WG.TILE, WG.TILE))
	draw_texture_rect(texture, target, false)


func _flora_tint(tile: Vector2) -> Color:
	# The final light mesh shades visible pixels, including plants and actors.
	return Color.WHITE


func _draw_foliage(x0: int, y0: int, x1: int, y1: int) -> void:
	var grid: PackedByteArray = world["tiles"]
	var drawn := {}
	for chunk in terrain_cache.visible(camera_pos):
		for cell: Vector2i in chunk["leaves"]:
			var crown: Dictionary = foliage.component(grid, cell, int(world["seed"]))
			if crown.is_empty() or drawn.has(crown["id"]):
				continue
			drawn[crown["id"]] = true
			var wind := _wind_speed()
			var sway := wind * 0.015 + sin(animation_clock * 0.65 + float(crown["phase"])) * (0.45 + absf(wind) * 0.015)
			var texture: Texture2D = crown["texture"]
			var at: Vector2 = crown["origin"] - camera_pos + Vector2(sway, 0)
			draw_texture_rect(texture, Rect2(at, texture.get_size()), false, Color.WHITE)


func _draw_station(x: int, y: int, tile_id: int) -> void:
	var p := Vector2(x, y) * WG.TILE - camera_pos
	var frames: Array = station_frames["workbench" if tile_id == 34 else "furnace"]
	var animation := "workbench_idle" if tile_id == 34 else "furnace_burn"
	var hot := tile_id != 35 or float(world.get("furnaces", {}).get("%d,%d" % [x, y], {}).get("heat", 0.0)) > 0.05
	draw_texture(frames[sprite_art.frame_index("stations", animation, animation_clock) if hot else 0], p + Vector2(0, -16), Color.WHITE if hot else Color("aaaebc"))


func _draw_lighting(x0: int, y0: int, x1: int, y1: int, sun: float) -> void:
	var held_torch: bool = place_items[selected_slot] == "Torch" and int(inventory.get("Torch", 0)) > 0
	environment.prepare(camera_pos, player_pos, sun, float(settings_data["night_dark"]), animation_clock, held_torch)
	var transform := Transform2D(0.0, Vector2(environment.bounds.position) * WG.TILE - camera_pos)
	draw_mesh(environment.warm_mesh, null, transform)
	if environment.crystal_mesh != null: draw_mesh(environment.crystal_mesh, null, transform)
	draw_mesh(environment.shadow_mesh, null, transform)


func _draw_torches(x0: int, y0: int, x1: int, y1: int) -> void:
	var sprite: Texture2D = terrain_sheets.get("torch")
	for key in world.get("torches", {}):
		var parts := String(key).split(",")
		if parts.size() != 2:
			continue
		var tx := int(parts[0])
		var ty := int(parts[1])
		if tx < x0 or tx > x1 or ty < y0 or ty > y1:
			continue
		var p := Vector2(tx, ty) * WG.TILE - camera_pos
		if sprite != null:
			draw_texture_rect(sprite, Rect2(p, Vector2(16, 16)), false)


func _draw_player_sprite(screen_pos: Vector2) -> void:
	var action := "idle"
	if not player_grounded:
		action = "jump"
	elif Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_LEFT) or Input.is_key_pressed(KEY_RIGHT):
		action = "walk"
	var direction := "east" if facing >= 0 else "west"
	var frames: Array = player_frames.get("%s_%s" % [action, direction], [])
	if frames.is_empty():
		return
	var frame_index := sprite_art.frame_index("captain", "%s_%s" % [action, direction], animation_clock)
	if action == "jump":
		frame_index = clampi(roundi(remap(player_velocity.y, -430.0, 700.0, 0, frames.size() - 1)), 0, frames.size() - 1)
	var frame: Texture2D = frames[frame_index]
	var selected: String = place_items[selected_slot]
	var showing_food := eat_visual > 0.0 or (tool_action_timer <= 0.0 and food.edible(selected) and int(inventory.get(selected, 0)) > 0)
	var behind := not showing_food and PlayerPose.behind_body(screen_pos, _held_tool_pose(screen_pos).origin, facing)
	if behind:
		_draw_held_tool(screen_pos)
	if not character_appearance.is_empty():
		character_avatar.draw_body(self, screen_pos + Vector2(-8, -12), "%s_%s" % [action, direction], frame_index, Color("ff9977") if lava_flash > 0.0 else Color.WHITE)
	elif frame != null:
		draw_texture(frame, screen_pos + Vector2(-8, -12), Color("ff9977") if lava_flash > 0.0 else Color.WHITE)
	if not behind:
		_draw_held_tool(screen_pos)


func _draw_player_arm(screen_pos: Vector2, hand: Vector2) -> void:
	draw_set_transform_matrix(PlayerPose.arm_transform(PlayerPose.shoulder(screen_pos, facing), hand, facing))
	draw_texture(arm_textures["solid_arm"], Vector2(-4, -1))
	draw_set_transform_matrix(Transform2D.IDENTITY)


func _held_tool_pose(screen_pos: Vector2) -> Transform2D:
	var active := tool_action_timer > 0.0
	var progress := clampf(1.0 - tool_action_timer / tool_action_duration, 0.0, 1.0) if active else 1.0
	return PlayerPose.tool(screen_pos, mouse_aim_direction if mouse_aim_valid else Vector2(facing, 0), facing,
		active, progress, equipped_tool, tool_action_kind == "water")


func _draw_swing_trail(screen_pos: Vector2, progress: float) -> void:
	if progress < 0.2 or progress > 0.78:
		return
	var points := PackedVector2Array()
	for index in range(9):
		var past := maxf(0.16, progress - 0.12 + index * 0.015)
		var pose := PlayerPose.tool(screen_pos, mouse_aim_direction, facing, true, past, equipped_tool, false)
		points.append(pose * Vector2(0, -23))
	draw_polyline(points, Color(0.85, 0.91, 0.89, 0.28), 1.4, true)


func _draw_held_tool(screen_pos: Vector2) -> void:
	var selected: String = place_items[selected_slot]
	if eat_visual > 0.0 or (tool_action_timer <= 0.0 and food.edible(selected) and int(inventory.get(selected, 0)) > 0):
		var eating := eat_visual > 0.0
		var item := last_food if eating else selected
		var lift := sin(clampf((0.65 - eat_visual) / 0.65, 0.0, 1.0) * PI) if eating else 0.0
		var palm := screen_pos + Vector2(8 + facing * lerpf(17.0, 9.0, lift), lerpf(16.0, 5.0, lift))
		draw_texture_rect(food.texture_for(item), Rect2(palm - Vector2(7, 10), Vector2(14, 18)), false)
		_draw_player_arm(screen_pos, palm)
		return
	var pose := _held_tool_pose(screen_pos)
	var hand := pose.origin
	var active := tool_action_timer > 0.0
	if not active and place_items[selected_slot] == "Torch" and int(inventory.get("Torch", 0)) > 0:
		draw_texture_rect(terrain_sheets["torch"], Rect2(hand + Vector2(-5, -14), Vector2(10, 18)), false)
		_draw_player_arm(screen_pos, hand)
		return
	if equipped_tool == "Hand":
		_draw_player_arm(screen_pos, hand)
		return
	var sprite: Texture2D = tool_textures.get(equipped_tool)
	if sprite == null:
		_draw_player_arm(screen_pos, hand)
		return
	# The Aseprite tool frames share the same (16,32) grip and pour origin.
	var progress := 1.0 - tool_action_timer / tool_action_duration if active else 0.0
	if active and tool_action_kind != "water":
		_draw_swing_trail(screen_pos, progress)
	draw_set_transform_matrix(pose)
	draw_texture_rect(sprite, Rect2(Vector2(-16, -32), Vector2(32, 40)), false)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	_draw_player_arm(screen_pos, hand)


func _draw_planet_rings() -> void:
	if not bool(_planet_sky_info().get("rings", false)):
		return
	if ring_mesh == null or ring_mesh_key != _planet_seed(planet_index):
		ring_mesh_key = _planet_seed(planet_index)
		ring_mesh = _make_ring_mesh()
	var daylight := clampf(sin(time_of_day * TAU), 0.0, 1.0)
	var opacity := lerpf(0.72, 1.0, daylight) * lerpf(1.0, 0.38, _rain_strength())
	draw_mesh(ring_mesh, null, Transform2D.IDENTITY, Color(1, 1, 1, opacity))


func _make_ring_mesh() -> ArrayMesh:
	var inclination := -0.28 + float(_planet_seed(planet_index) % 7) * 0.012
	var center := Vector2(150, -650)
	var vertices := PackedVector2Array()
	var colors := PackedColorArray()
	var indices := PackedInt32Array()
	for band in range(30):
		# Gaps and uneven icy/dust bands give the ring depth at planetary scale.
		if band in [10, 11, 22]:
			continue
		var inner := 0.90 + float(band) * 0.006
		var outer := inner + (0.0054 if band % 3 else 0.0038)
		var tint: Color = [Color("c2c9cf"), Color("daceb8"), Color("97a9b9"), Color("e5dac2")][band % 4]
		tint = tint.lerp(_star_light_color(), 0.10)
		tint.a = 0.15 + float(band % 5) * 0.022
		var start := vertices.size()
		for step in range(97):
			var angle := 0.30 + float(step) / 96.0 * 2.65
			var offset := Vector2(cos(angle) * 1640.0, sin(angle) * 850.0).rotated(inclination)
			vertices.append(center + offset * inner)
			vertices.append(center + offset * outer)
			colors.append(tint)
			colors.append(tint)
			if step < 96:
				var index := start + step * 2
				indices.append_array(PackedInt32Array([index, index + 1, index + 2, index + 1, index + 3, index + 2]))
	return environment._mesh(vertices, colors, indices)


func _draw_planet_celestial(sun_strength: float) -> void:
	var star_color := _star_light_color()
	var sun_x := 80.0 + time_of_day * 2240.0
	var sun_y := 470.0 - sin(time_of_day * TAU) * 400.0
	if sun_strength > 0.0 and sun_x > -90.0 and sun_x < SCREEN.x + 90.0:
		var sun_at := Vector2(sun_x, sun_y)
		var clarity := 1.0 - _rain_strength() * 0.58 - (weather_blend.amount("Cloudy") + weather_blend.amount("Fog") + weather_blend.snow()) * 0.35
		for halo in range(4, 0, -1):
			draw_circle(sun_at, 26.0 + halo * 22.0, Color(star_color.r, star_color.g, star_color.b, 0.018 * sun_strength * clarity))
		draw_circle(sun_at, 27.0, Color(star_color.r, star_color.g, star_color.b, 0.88 * clarity))
	var moon_count := int(_planet_sky_info().get("moons", 0))
	for moon in range(moon_count):
		var phase := fposmod(time_of_day + 0.54 + float(moon) / float(maxi(1, moon_count)) * 0.45, 1.0)
		var mx := 80.0 + phase * 1160.0
		var my := 142.0 + sin(phase * TAU + moon * 1.7) * 56.0 + float(moon) * 23.0
		var radius := 13.0 + float((moon * 7 + planet_index * 3) % 12)
		var moon_color := Color("cad7e4") if moon % 2 == 0 else Color("d6c3ad")
		if _planet_climate(planet_index) in [6, 7]:
			moon_color = Color("e3eef6")
		draw_circle(Vector2(mx, my), radius, moon_color)


func _draw_planet_clouds() -> void:
	if cloud_textures.is_empty():
		return
	var coverage := cloud_cover
	if _planet_climate(planet_index) in [4, 5]:
		coverage *= 1.0 - weather_blend.amount("Clear")
	for cloud in clouds:
		var visibility := clampf((coverage - float(cloud["threshold"])) * 6.0, 0.0, 1.0)
		if visibility <= 0.0:
			continue
		var age: float = float(cloud["age"])
		var lifetime: float = float(cloud["life"])
		var forming := minf(1.0, age / 13.0)
		var dissolving := minf(1.0, (lifetime - age) / 17.0)
		var family := 0 if int(cloud["shape"]) < 3 else (1 if int(cloud["shape"]) < 8 else 2)
		var density := 0.54 if family == 0 else (0.85 if family == 1 else lerpf(0.57, 0.94, _rain_strength()))
		var opacity := visibility * forming * dissolving * density * (0.82 + float(cloud["depth"]) * 0.12)
		if opacity <= 0.0:
			continue
		var morph := 0.5 + 0.5 * sin(animation_clock * 0.035 + float(cloud["phase"]))
		var drift_y := sin(animation_clock * 0.09 + float(cloud["phase"])) * 2.5
		var width: float = float(cloud["width"]) * (1.0 + 0.035 * sin(animation_clock * 0.024 + float(cloud["phase"])))
		var x := float(cloud["x"]) - camera_pos.x * (0.012 + float(cloud["depth"]) * 0.01)
		var rect := Rect2(x, float(cloud["y"]) + drift_y, width, float(cloud["height"]))
		var tint := weather_blend.cloud_tint()
		tint.a = opacity * (1.0 - morph * 0.55)
		draw_texture_rect(cloud_textures[int(cloud["shape"])], rect, false, tint)
		tint.a = opacity * morph * 0.55
		draw_texture_rect(cloud_textures[int(cloud["next_shape"])], rect, false, tint)


func _draw_planet_background(sky: Color) -> void:
	_draw_planet_rings()
	_draw_planet_celestial(clampf(sin(time_of_day * TAU), 0.0, 1.0))
	biome_backgrounds.draw_sky(self)
	expedition.draw_sky_ship()
	_draw_planet_clouds()
	biome_backgrounds.draw(self, sky)
	if not world.is_empty():
		for chunk in terrain_cache.visible(camera_pos):
			draw_texture(chunk["back"], chunk["position"] - camera_pos)


func _draw_drops() -> void:
	for drop in world.get("drops", []):
		var p := Vector2(float(drop["x"]), float(drop["y"])) - camera_pos
		if p.x < -16 or p.x > SCREEN.x + 16 or p.y < 92 or p.y > 635:
			continue
		if int(drop.get("block_id", 0)) in [7, 8]:
			var block_rect := Rect2(p - Vector2(8, 8), Vector2(16, 16))
			var frame_rect := block_rect.grow(2.0)
			if int(drop["block_id"]) == 8:
				var encoded := str(drop.get("leaf_pixels", ""))
				var texture: Texture2D = foliage.drop_texture(encoded) if not encoded.is_empty() else foliage.icon()
				draw_texture_rect(texture, block_rect, false, _flora_tint((p + camera_pos) / WG.TILE))
			else:
				var encoded := str(drop.get("wood_pixels", ""))
				if not encoded.is_empty():
					draw_texture_rect(foliage.drop_texture(encoded), block_rect, false)
				else:
					var source := Rect2(float(drop["source_x"]), float(drop["source_y"]), 16, 16)
					draw_texture_rect_region(terrain_sheets["tree"], block_rect, source, _flora_tint((p + camera_pos) / WG.TILE))
			draw_rect(frame_rect, Color("8b9ba4"), false, 1.0)
			continue
		var item := str(drop["item"])
		if GroundLife.has_item(item):
			var icon := ground_life.icon(item)
			var size := icon.get_size() * (16.0 / maxf(icon.get_width(), icon.get_height()))
			draw_texture_rect(icon, Rect2(p - size * 0.5, size), false)
			if int(drop["count"]) > 1:
				_text(str(drop["count"]), p + Vector2(7, 4), 11, Color("fff1bd"))
			continue
		if item in ["Obsidian", "Gravel"] or Furnishings.has_item(item):
			_draw_item_icon(item, Rect2(p - Vector2(8, 8), Vector2(16, 16)))
			if int(drop["count"]) > 1:
				_text(str(drop["count"]), p + Vector2(7, 4), 11, Color("fff1bd"))
			continue
		if food.has_icon(item):
			draw_texture_rect(food.texture_for(item), Rect2(p - Vector2(8, 8), Vector2(16, 16)), false)
			if int(drop["count"]) > 1:
				_text(str(drop["count"]), p + Vector2(7, 4), 11, Color("fff1bd"))
			continue
		if ores.has_item(item):
			draw_texture_rect(ores.texture_for(item), Rect2(p - Vector2(8, 8), Vector2(16, 16)), false)
			continue
		var tint := Color("ccac6e")
		if item.contains("Ore"):
			tint = Color("96b8cb")
		elif item in ["Grass", "Corn", "Corn Seed"]:
			tint = Color("8dcb71")
		elif item in ["Crystal"]:
			tint = Color("ae8cee")
		draw_rect(Rect2(p - Vector2(4, 4), Vector2(8, 8)), tint, true)
		draw_rect(Rect2(p - Vector2(6, 5), Vector2(12, 11)), Color("ecf1e8"), false, 1.0)
		if int(drop["count"]) > 1:
			_text(str(drop["count"]), p + Vector2(7, 4), 11, Color("fff1bd"))


func _draw_water() -> void:
	fluid_renderer.draw_fluid(self, water_sim, false)


func _draw_lava() -> void:
	fluid_renderer.draw_fluid(self, lava_sim, true)


func _draw_surface_flash(strength: float = 1.0) -> void:
	var points := PackedVector2Array([Vector2(-16, -16), Vector2(1296, -16)])
	var lowest := -16.0
	var start := maxi(0, int(floor(camera_pos.x / WG.TILE)))
	var finish := mini(WG.WIDTH - 1, start + 82)
	for x in range(finish, start - 1, -1):
		var y := maxf(-16.0, float(environment.fog_floor[x] * WG.TILE) - camera_pos.y)
		lowest = maxf(lowest, y)
		points.append(Vector2(float((x + 1) * WG.TILE) - camera_pos.x, y))
		points.append(Vector2(float(x * WG.TILE) - camera_pos.x, y))
	if lowest > -16.0:
		draw_colored_polygon(points, Color(0.78, 0.86, 1.0, 0.30 * strength))


func _weather_segment_end(start: Vector2, offset: Vector2) -> Vector2:
	var last := start
	for step in range(7):
		var point := start + offset * (step / 6.0)
		var column := clampi(floori((point.x + camera_pos.x) / WG.TILE), 0, WG.WIDTH - 1)
		if point.y + camera_pos.y >= float(environment.roof[column] * WG.TILE):
			break
		last = point
	return last


func _draw_weather_particles() -> void:
	var wind := _wind_speed()
	var velocity := WeatherBlend.rain_velocity(wind)
	var rain := _rain_strength()
	var snow := weather_blend.snow()
	var ash := weather_blend.amount("Ashfall") + weather_blend.amount("Ember Storm") + weather_blend.amount("Volcanic Haze") * 0.55
	for kind in ["rain", "snow", "ash"]:
		var intensity := rain if kind == "rain" else (snow if kind == "snow" else ash)
		if intensity <= 0.001:
			continue
		var count := 280 if kind == "rain" else 180
		for i in range(count):
			var alpha := clampf((intensity - float(i) / count) * 5.0, 0.0, 1.0)
			if alpha <= 0.001:
				continue
			var speed := velocity.y + i % 5 * 17.0 if kind == "rain" else (38.0 if kind == "snow" else 27.0) + i % 17
			var x := fposmod(i * 977.0 + i * i * 17.0 + wind_drift * (4.5 if kind == "rain" else 0.7), SCREEN.x)
			var y := fposmod(i * 613.0 + i * i * 31.0 + animation_clock * speed, SCREEN.y)
			if kind == "snow":
				x = fposmod(x + sin(animation_clock * 0.8 + i) * 12.0, SCREEN.x)
			var at := Vector2(x, y)
			var column := clampi(floori((x + camera_pos.x) / WG.TILE), 0, WG.WIDTH - 1)
			if y + camera_pos.y >= environment.roof[column] * WG.TILE:
				continue
			if kind == "rain":
				var streak := Vector2(velocity.x, speed).normalized() * (8.0 + minf(absf(wind) * 0.035, 5.0))
				var end := _weather_segment_end(at, streak)
				if end.distance_squared_to(at) > 0.1:
					draw_line(at, end, Color(0.70, 0.82, 1.0, 0.78 * alpha), 1.0)
			elif kind == "snow":
				draw_circle(at, 1.0 + i % 3 * 0.4, Color(0.9, 0.95, 1.0, 0.85 * alpha))
			else:
				var ember := i % 4 == 0 and weather_blend.amount("Ember Storm") > float(i) / count
				draw_rect(Rect2(at, Vector2(2 if ember else 1, 2)), Color(0.94, 0.63, 0.35, alpha) if ember else Color(0.65, 0.60, 0.57, 0.65 * alpha))


func _draw_planet() -> void:
	var stamp := _profile_tick()
	var sun: float = maxf(0.15, clampf(sin(time_of_day * TAU), 0.0, 1.0))
	var sky := Color("12243d").lerp(Color("64a5d9"), sun)
	if _planet_climate(planet_index) in [4, 5]:
		sky = Color("261d32").lerp(Color("ba8065"), sun)
	elif _planet_climate(planet_index) in [6, 7]:
		sky = Color("122d4a").lerp(Color("90b7d0"), sun)
	sky = sky.lerp(Color("35435c"), weather_blend.darkness())
	for band in range(24):
		var amount := float(band) / 23.0
		var horizon := sky.lightened(0.18 * sun).lerp(Color("b9a1a0"), 0.08 * sun)
		draw_rect(Rect2(0, band * 30, SCREEN.x, 31), sky.lerp(horizon, amount * amount), true)
	_draw_planet_background(sky)
	stamp = _profile_end("background", stamp)
	var fog_passes: Array[Dictionary] = []
	var fog_strength := weather_blend.amount("Fog") + weather_blend.amount("Volcanic Haze") * 0.45
	if fog_strength > 0.001:
		fog_passes = environment.fog_layers(camera_pos, animation_clock)
		for layer in fog_passes:
			if int(layer["depth"]) < 2:
				draw_mesh(layer["mesh"], layer["texture"], Transform2D(0.0, -camera_pos), Color(1, 1, 1, fog_strength))
	if world_texture != null:
		var x0 := int(floor(camera_pos.x / WG.TILE))
		var y0 := int(floor(camera_pos.y / WG.TILE))
		var x1 := mini(WG.WIDTH, x0 + 83)
		var y1 := mini(WG.HEIGHT, y0 + 48)
		var source := Rect2(x0, y0, x1 - x0, y1 - y0)
		var dest := Rect2(source.position * WG.TILE - camera_pos, source.size * WG.TILE)
		draw_texture_rect_region(world_texture, dest, source)
		hanging_vines.draw(self)
		underground.draw(self)
		_draw_terrain_details(x0, y0, x1, y1)
		background_ores.draw(self)
		stamp = _profile_end("terrain", stamp)
		_draw_foliage(x0, y0, x1, y1)
		ground_life.draw_life(self)
		furnishings.draw(self)
		_draw_torches(x0, y0, x1, y1)
		_draw_drops()
		stamp = _profile_end("foliage_items", stamp)
	var player_screen := player_pos - camera_pos
	expedition.draw_world()
	for creature in world.get("creatures", []):
		if not creature["alive"]:
			continue
		var critter_pos := Vector2(creature["x"], creature["y"]) - camera_pos
		if critter_pos.x < -48.0 or critter_pos.x > SCREEN.x + 48.0 or critter_pos.y < -48.0 or critter_pos.y > SCREEN.y + 48.0:
			continue
		if bool(creature.get("wildlife", false)):
			wildlife_mobs.draw(self, creature, critter_pos, animation_clock)
		elif bool(creature.get("flying", false)):
			flying_monsters.draw(self, creature, critter_pos, animation_clock)
		elif bool(creature.get("quest_guardian", false)):
			draw_texture(expedition.texture("sentinel"), critter_pos + Vector2(-4, -14), Color("ffb9a1") if float(creature.get("hit_flash", 0.0)) > 0 else Color.WHITE)
		else:
			planet_monsters.draw(self, creature, critter_pos, animation_clock)
		var max_hp := int(creature.get("max_hp", 30))
		if int(creature["hp"]) < max_hp:
			var bar_y := -10 if bool(creature.get("quest_guardian", false)) else -24
			draw_rect(Rect2(critter_pos + Vector2(-4, bar_y), Vector2(32, 3)), Color("422834"), true)
			draw_rect(Rect2(critter_pos + Vector2(-4, bar_y), Vector2(32.0 * maxf(0.0, float(creature["hp"])) / max_hp, 3)), Color("e77877"), true)
	if world.has("npc"):
		var npc: Dictionary = world["npc"]
		var npc_pos := Vector2(npc["x"], npc["y"]) - camera_pos
		if npc_pos.x > -50.0 and npc_pos.x < SCREEN.x + 50.0:
			var action := "walk" if int(npc.get("direction", 0)) != 0 else "idle"
			var direction := "east" if int(npc.get("direction", -1)) >= 0 else "west"
			var frames: Array = elder_frames.get("%s_%s" % [action, direction], [])
			var sprite: Texture2D = frames[sprite_art.frame_index("robot_guide", "%s_%s" % [action, direction], animation_clock)] if not frames.is_empty() else explorer_sprite
			if sprite != null:
				draw_texture(sprite, npc_pos + Vector2(-16, -11))
	_draw_player_sprite(player_screen)
	sand_gravity.draw(self)
	_draw_food_feedback(player_screen)
	_draw_water()
	water_ripples.draw(self)
	_draw_lava()
	fluid_reactions.draw_steam(self)
	snowfall.draw_snow(self)
	surface_effects.draw_effects(self)
	stamp = _profile_end("actors_water", stamp)
	_draw_weather_particles()
	if fog_strength > 0.001:
		for layer in fog_passes:
			if int(layer["depth"]) >= 2:
				draw_mesh(layer["mesh"], layer["texture"], Transform2D(0.0, -camera_pos), Color(1, 1, 1, fog_strength))
	if weather_blend.amount("Storm") > 0.001 and fposmod(animation_clock, 11.0) < 0.12:
		_draw_surface_flash(weather_blend.amount("Storm"))
	_draw_lighting(0, 0, 0, 0, maxf(0.15, sun * (1.0 - weather_blend.darkness() * 0.35)))
	stamp = _profile_end("weather_lighting", stamp)
	_draw_gameplay_hud(sun)
	_draw_mining_feedback()
	if crafting_open:
		_draw_crafting()
	if inventory_open:
		_draw_inventory()
	interactions.draw()
	stations.draw()
	if inventory_dragging and not inventory_drag_item.is_empty():
		var pointer := get_viewport().get_mouse_position()
		var count := int(inventory.get(inventory_drag_item, 0))
		if not stations.source.is_empty():
			if str(stations.source["zone"]) == "output":
				count = int(stations.state()["output"].get(inventory_drag_item, 0))
			else:
				count = int(stations.stack_at(str(stations.source["zone"]), int(stations.source["index"])).get("count", 0))
		_draw_item_icon(inventory_drag_item, Rect2(pointer - Vector2(18, 18), Vector2(36, 36)))
		_text(str(count), pointer + Vector2(12, 22), 13, Color("f5dfaa"))
	if dialogue_open:
		_draw_dialogue()
	if dev_travel_unlocked:
		_text("DEV TRAVEL  |  G: Orbit  |  F3: Controls", Vector2(20, 146), 14, Color("95dfaf"))
	if dev_mode:
		_draw_dev_panel()
	if paused and scene_name == "planet":
		_draw_pause_menu()
	if notice_timer > 0.0:
		_text(notice, Vector2(22, 615), 19, Color("ffdf88"))
	_profile_end("hud", stamp)


func _draw_item_icon(item: String, rect: Rect2) -> void:
	if Furnishings.has_item(item):
		furnishings.draw_icon(self, item, rect)
		return
	if item in ["Hull Plate", "Drive Coil"]:
		var icon := expedition.texture("hull_plate" if item == "Hull Plate" else "drive_coil")
		draw_texture_rect(icon, rect, false)
		return
	if GroundLife.has_item(item):
		var icon := ground_life.icon(item)
		var size := icon.get_size() * minf(rect.size.x / icon.get_width(), rect.size.y / icon.get_height())
		draw_texture_rect(icon, Rect2(rect.get_center() - size * 0.5, size), false)
		return
	if food.has_icon(item):
		draw_texture_rect(food.texture_for(item), rect, false)
		return
	if ores.has_item(item):
		draw_texture_rect(ores.texture_for(item), rect, false)
		return
	if tool_textures.has(item):
		var tool_sprite: Texture2D = tool_textures.get(item)
		if tool_sprite != null:
			var fitted := Vector2(rect.size.y * 0.8, rect.size.y)
			draw_texture_rect(tool_sprite, Rect2(rect.get_center() - fitted * 0.5, fitted), false)
		return
	var material: String = str({"Grass": "grass", "Dirt": "dirt", "Stone": "stone", "Sand": "sand",
		"Snow": "snow", "Cobblestone": "stone", "Wood": "wood", "Planks": "planks", "Obsidian": "obsidian", "Glacial Ice": "glacial_ice", "Gravel": "gravel"}.get(item, ""))
	if material != "":
		var texture: Texture2D = terrain_sheets.get(material)
		if texture != null:
			if material in ["obsidian", "glacial_ice", "gravel"]:
				draw_texture_rect_region(texture, rect, Rect2(0, 0, 16, 16))
			elif material in ["wood", "planks"]:
				draw_texture_rect(texture, rect, false)
			else:
				draw_texture_rect_region(texture, rect, Rect2(18, 18, 16, 16))
			return
	if item == "Leaves":
		draw_texture_rect(foliage.icon(), rect, false)
		return
	if item in ["Chest", "Torch"]:
		draw_texture_rect(terrain_sheets[item.to_lower()], rect, false)
		return
	if item in ["Workbench", "Furnace"]:
		draw_texture_rect(station_frames[item.to_lower()][0], rect, false)
		return
	var tint := Color("b5a77d")
	if item.contains("Ore") or item.contains("Ingot"): tint = Color("91b7d2")
	elif item == "Crystal": tint = Color("a790d9")
	elif item in ["Corn", "Corn Seed", "Crop Seeds"]: tint = Color("8cc45e")
	draw_rect(rect, tint, true)
	_text(item.substr(0, 1), rect.position + Vector2(9, rect.size.y - 9), 18, Color("18263a"))


func _draw_weather_icon(at: Vector2, sun: float) -> void:
	if weather != "Clear":
		for puff in [Vector3(-8, 0, 6), Vector3(0, -4, 8), Vector3(8, 0, 6)]:
			draw_circle(at + Vector2(puff.x, puff.y), puff.z, Color("b6cbd8"))
		_fill_rounded_rect(Rect2(at + Vector2(-12, -1), Vector2(24, 8)), Color("b6cbd8"), 3.0)
		if _is_raining():
			for drop in range(3):
				var start := at + Vector2(-7 + drop * 7, 11)
				draw_line(start, start + Vector2(-2, 5), Color("7bb8dc"), 1.5, true)
		elif weather == "Snow":
			for flake in range(3):
				draw_circle(at + Vector2(-8 + flake * 8, 13), 1.6, Color("eef8ff"))
		elif weather == "Fog":
			for line in range(2):
				draw_line(at + Vector2(-14, 11 + line * 5), at + Vector2(14, 11 + line * 5), Color("b5ccd7"), 1.3, true)
		elif weather in ["Ashfall", "Ember Storm", "Volcanic Haze"]:
			for ash in range(4):
				draw_rect(Rect2(at + Vector2(-10 + ash * 7, 11 + ash % 2 * 4), Vector2(2, 2)), Color("f3aa68") if weather == "Ember Storm" else Color("b7a89a"))
	elif sun < 0.12:
		draw_circle(at, 10.0, Color("d8e2e8"))
	else:
		draw_circle(at, 7.0, Color("f1cb79"))
		for ray in range(8):
			var direction := Vector2.from_angle(float(ray) * TAU / 8.0)
			draw_line(at + direction * 10.0, at + direction * 13.0, Color("e5b966"), 1.4, true)


func _draw_weather_panel(sun: float) -> void:
	var panel := Rect2(940, 16, 324, 140)
	_rounded_box(panel, Color(0.043, 0.070, 0.105, 0.96), Color("637c8b"), 12.0, 1.0)
	draw_line(Vector2(956, 17), Vector2(992, 17), Color("d5b477"), 2.0, true)
	_text("DAY %02d" % day_count, Vector2(956, 36), 11, Color("d4b981"))
	var total_minutes := int(floor(fposmod(time_of_day * 24.0 + 6.0, 24.0) * 60.0))
	_text("%02d:%02d" % [int(total_minutes / 60), total_minutes % 60], Vector2(955, 68), 28, Color("f4e9d6"))
	var labels := {"Clear": "Clear night" if sun < 0.12 else "Clear skies", "Cloudy": "Cloudy", "Rain": "Rainfall", "Storm": "Thunderstorm", "Fog": "Foggy", "Snow": "Snowfall"}
	_text(str(labels.get(weather, weather)), Vector2(1063, 40), 17, Color("e6eaf0"))
	var upcoming := _next_weather()
	var forecast := str({"Clear": "Clear skies", "Cloudy": "Cloudy", "Rain": "Rain", "Storm": "Storm", "Fog": "Fog", "Snow": "Snow"}.get(upcoming, upcoming))
	var changing := weather_blend.elapsed < WeatherBlend.DURATION and weather_blend.target == weather
	_text(("Clearing gradually" if weather == "Clear" else "Weather building") if changing else "Next: " + forecast, Vector2(1063, 64), 12, Color("a7bbc8"))
	_draw_weather_icon(Vector2(1234, 44), sun)
	var wind := _wind_speed()
	var direction := 1.0 if wind >= 0.0 else -1.0
	var arrow := Vector2(1230, 70)
	if bool(_wind_state()["gusting"]):
		_text("GUST", Vector2(1184, 74), 10, Color("e6c38c"))
	var tip := arrow + Vector2(direction * 10, 0)
	draw_line(arrow - Vector2(direction * 10, 0), tip, Color("a7bbc8"), 1.0)
	draw_line(tip, tip + Vector2(-direction * 4, -3), Color("a7bbc8"), 1.0)
	draw_line(tip, tip + Vector2(-direction * 4, 3), Color("a7bbc8"), 1.0)
	draw_line(Vector2(956, 82), Vector2(1248, 82), Color("314454"), 1.0)
	draw_circle(Vector2(960, 102), 3.0, _star_light_color())
	var system_name: String = star_names[star_index]
	while ThemeDB.fallback_font.get_string_size(system_name, HORIZONTAL_ALIGNMENT_LEFT, -1, 14).x > 203.0:
		system_name = system_name.left(system_name.length() - 2) + "…"
	_text(system_name, Vector2(973, 108), 14, Color("e0e7eb"))
	_text("%s STAR" % star_types[star_index], Vector2(1200, 107), 11, Color("92a9b7"))
	var climates := ["Forest", "Islands", "Ocean", "Desert", "Lava", "Barren", "Frozen sea", "Tundra"]
	var sky_info := _planet_sky_info()
	var moons := int(sky_info.get("moons", 0))
	var biome_name := WG.Biomes.name_at(world, floori(player_pos.x / WG.TILE))
	var cave_cell := Vector2i(floor(player_pos / WG.TILE))
	if cave_cell.y > int(world["surface"][clampi(cave_cell.x, 0, WG.WIDTH - 1)]) + 24:
		biome_name = Underground.NAMES[Underground.biome(world, cave_cell.x, cave_cell.y)]
	_text("%s  ·  %d %s  ·  %s" % [biome_name if not biome_name.is_empty() else climates[_planet_climate(planet_index)], moons,
		"moon" if moons == 1 else "moons", "Ringed" if bool(sky_info.get("rings", false)) else "No rings"],
		Vector2(956, 138), 13, Color("a7bbc8"))


func _draw_hud_shortcuts() -> void:
	var mouse := get_viewport().get_mouse_position()
	for rect in [HUD_PACK_RECT, HUD_CRAFT_RECT]:
		_rounded_box(rect, Color("263c4b") if rect.has_point(mouse) else Color("111f2d"),
			Color("d7b67a") if rect.has_point(mouse) else Color("5a7181"), 9.0, 1.0)
	# A backpack and hammer replace the row of large text buttons.
	var at := HUD_PACK_RECT.position
	_outline_rounded_rect(Rect2(at + Vector2(14, 8), Vector2(14, 8)), Color("d4bd91"), 3.0, 1.5)
	_rounded_box(Rect2(at + Vector2(10, 13), Vector2(22, 21)), Color("273d4d"), Color("d4bd91"), 5.0, 1.5)
	_outline_rounded_rect(Rect2(at + Vector2(14, 23), Vector2(14, 8)), Color("d4bd91"), 2.0, 1.0)
	at = HUD_CRAFT_RECT.position
	draw_line(at + Vector2(13, 30), at + Vector2(26, 14), Color("c39965"), 4.0, true)
	var head := PackedVector2Array([at + Vector2(17, 12), at + Vector2(23, 6), at + Vector2(34, 15), at + Vector2(28, 21)])
	draw_colored_polygon(head, Color("c8d9df"))
	_text("I", HUD_PACK_RECT.position + Vector2(32, 36), 10, Color("8da7b9"))
	_text("C", HUD_CRAFT_RECT.position + Vector2(31, 36), 10, Color("8da7b9"))
	var hint := "Backpack  [I]" if HUD_PACK_RECT.has_point(mouse) else ("Crafting  [C]  /  Build  [M]" if HUD_CRAFT_RECT.has_point(mouse) else "")
	if not hint.is_empty():
		var width := ThemeDB.fallback_font.get_string_size(hint, HORIZONTAL_ALIGNMENT_LEFT, -1, 13).x + 20.0
		_rounded_box(Rect2(16, 130, width, 29), Color("111f2d"), Color("5a7181"), 6.0, 1.0)
		_text(hint, Vector2(26, 150), 13, Color("ead9b8"))


func _draw_gameplay_hud(sun: float) -> void:
	_rounded_box(Rect2(16, 16, 244, 55), Color(0.043, 0.070, 0.105, 0.96), Color("637c8b"), 10.0, 1.0)
	_text("HP", Vector2(29, 36), 12, Color("d59a91"))
	_fill_rounded_rect(Rect2(53, 26, 120, 9), Color("3b2830"), 4.0)
	if health > 0:
		_fill_rounded_rect(Rect2(53, 26, 120.0 * clampf(float(health) / 100.0, 0.0, 1.0), 9), Color("77c783") if food_feedback_timer > 0.0 else Color("d96761"), 4.0)
	_text("%d / 100" % health, Vector2(185, 36), 12, Color("e6dcd0"))
	var held := equipped_tool
	if eat_visual > 0.0:
		held = last_food
	elif food.edible(place_items[selected_slot]) and int(inventory.get(place_items[selected_slot], 0)) > 0 and tool_action_timer <= 0.0:
		held = place_items[selected_slot]
	if held != "Hand":
		_draw_item_icon(held, Rect2(28, 44, 16, 20))
	_text(Tools.display_name(held), Vector2(53, 61), 13, Color("b7c9d5"))
	if Tools.family(held) in Tools.FAMILIES:
		var stat := "%d DMG" % Tools.damage(held) if Tools.family(held) == "Sword" else "%.0f PWR" % Tools.mining_damage(held, 2 if Tools.family(held) == "Shovel" else 3)
		if Tools.family(held) == "Axe":
			stat = "%d hits" % Tools.mining_hits(held, 7)
		_text(stat, Vector2(203, 61), 10, Color("e4c68b"))
	_draw_hud_shortcuts()
	_draw_weather_panel(sun)
	expedition.draw_hud()
	_draw_farm_hint()
	interactions.draw_hint()
	furnishings.draw_hint(self)
	_rounded_box(Rect2(388, 638, 504, 78), Color(0.035, 0.057, 0.085, 0.93), Color("536b7e"), 12.0, 1.0)
	for i in range(9):
		var slot := hotbar_page * 9 + i
		var rect := Rect2(HOTBAR_X + i * HOTBAR_STEP, HOTBAR_Y, HOTBAR_SIZE, HOTBAR_SIZE)
		_rounded_box(rect, Color("2e3e49") if slot == selected_slot else Color("172633"),
			Color("e3c181") if slot == selected_slot else Color("506675"), 6.0, 2.0 if slot == selected_slot else 1.0)
		if slot < place_items.size():
			var item: String = place_items[slot]
			if int(inventory.get(item, 0)) > 0:
				_draw_item_icon(item, Rect2(rect.position + Vector2(7, 7), Vector2(34, 34)))
				var count_text := str(inventory[item])
				var count_width := ThemeDB.fallback_font.get_string_size(count_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x
				_text(count_text, rect.position + Vector2(44 - count_width, 43), 12, Color("f4e6cc"))
				if food.edible(item) and food_cooldown > 0.0:
					draw_rect(Rect2(rect.position + Vector2(4, 3), Vector2(40.0 * food_cooldown / FoodCatalog.COOLDOWN, 3)), Color("a0ca80"), true)
				if Tools.max_durability(item) > 0:
					var fraction := float(tool_wear.remaining(item, inventory)) / Tools.max_durability(item)
					draw_rect(Rect2(rect.position + Vector2(5, 45), Vector2(38, 2)), Color("3d3030"))
					draw_rect(Rect2(rect.position + Vector2(5, 45), Vector2(38 * fraction, 2)), Color("db6b56").lerp(Color("84d1a1"), fraction))
		_text(str(i + 1), rect.position + Vector2(4, 43), 11, Color("8196a6"))
	for page in range(HUD_PAGE_RECTS.size()):
		var page_rect: Rect2 = HUD_PAGE_RECTS[page]
		_fill_rounded_rect(Rect2(page_rect.position + Vector2(2, 5), Vector2(23, 3)),
			Color("dec18a") if page == hotbar_page else Color("465e71"), 1.5)
	var selected_item: String = place_items[selected_slot]
	var caption := "%s  ·  %d" % [selected_item, int(inventory.get(selected_item, 0))]
	if selected_item.is_empty():
		caption = "Empty slot  |  Drag an item from your backpack"
	elif Tools.max_durability(selected_item) > 0:
		var specialty := "Soil %.0fx" % float(Tools.profile(selected_item)["speed"]) if Tools.family(selected_item) == "Shovel" else "Level %d" % Tools.mining_level(selected_item)
		caption = "%s | %s | Durability %d / %d" % [Tools.display_name(selected_item), specialty, tool_wear.remaining(selected_item, inventory), Tools.max_durability(selected_item)]
	if food.edible(selected_item):
		caption += "  |  +%d HP  |  " % FoodCatalog.FOODS[selected_item]
		if crafting_open or paused or dev_mode or dialogue_open:
			caption += "Close this window to eat"
		else:
			caption += "Health full" if health >= 100 else ("Eat again in %.1fs" % food_cooldown if food_cooldown > 0.0 else "Right-click / R to eat")
	var caption_width := ThemeDB.fallback_font.get_string_size(caption, HORIZONTAL_ALIGNMENT_LEFT, -1, 14).x
	_rounded_box(Rect2(628 - caption_width * 0.5, 610, caption_width + 24, 25), Color(0.035, 0.057, 0.085, 0.90), Color("536b7e"), 7.0, 1.0)
	_text(caption, Vector2(640 - caption_width * 0.5, 628), 14, Color("e8d2ab"))
	var mouse := get_viewport().get_mouse_position()
	for page_rect: Rect2 in HUD_PAGE_RECTS:
		if page_rect.has_point(mouse):
			_text("Alt + wheel: switch bars  |  Wheel: select slot", Vector2(490, 601), 12, Color("c7d6df"))
			break


func _draw_food_feedback(screen_pos: Vector2) -> void:
	if food_feedback_timer <= 0.0:
		return
	var rise := (1.0 - food_feedback_timer / 1.4) * 22.0
	var at := screen_pos + Vector2(-15, -15 - rise)
	var alpha := minf(1.0, food_feedback_timer * 2.0)
	_text("+%d HP" % last_heal, at + Vector2(1, 1), 15, Color(0.05, 0.12, 0.08, alpha))
	_text("+%d HP" % last_heal, at, 15, Color(0.64, 0.95, 0.55, alpha))


func _farm_hint_text(tile: Vector2i) -> PackedStringArray:
	if world.is_empty() or tile.x < 0 or tile.x >= WG.WIDTH or tile.y < 1 or tile.y >= WG.HEIGHT - 1:
		return []
	var grid: PackedByteArray = world["tiles"]
	var id := WG.tile_at(grid, tile.x, tile.y)
	if id == 11:
		return ["Lava - cooling %d%%" % roundi(lava_sim.cooling_fraction(tile.y * WG.WIDTH + tile.x) * 100), "Water makes obsidian; rain cools gradually"]
	if id == 17:
		return ["Obsidian - volcanic glass", "Requires Diamond Pickaxe or better"]
	var target := farming.plant_target(tile)
	var lines := farming.hint(target if target.x >= 0 else tile, place_items[selected_slot])
	if not lines.is_empty(): return lines
	if id in [1, 2] and equipped_tool == "Hoe":
		return ["Grass" if id == 1 else "Dirt", "Click with the hoe to till soil"]
	return []


func _draw_farm_hint() -> void:
	if inventory_open or crafting_open or paused or dev_mode or dialogue_open:
		return
	var mouse := get_viewport().get_mouse_position()
	var tile := _mouse_to_tile(mouse)
	if _world_input_blocked(mouse) or not _in_reach(tile):
		return
	var lines := _farm_hint_text(tile)
	if lines.is_empty():
		return
	var at := Vector2(clampf(mouse.x + 18, 8, SCREEN.x - 348), clampf(mouse.y - 58, 165, SCREEN.y - 140))
	_rounded_box(Rect2(at, Vector2(340, 51)), Color(0.04, 0.07, 0.09, 0.94), Color("668576"), 7.0, 1.0)
	_text(lines[0], at + Vector2(10, 20), 14, Color("e6dfb7"))
	_text(lines[1], at + Vector2(10, 40), 12, Color("b8cda6"))


func _recipe_ready(recipe: Dictionary) -> bool:
	if recipe.has("station"):
		return stations.is_open() and stations.kind == "workbench" and str(recipe["station"]) == "Workbench" and stations.ready(recipe)
	for item in recipe["needs"]:
		if int(inventory.get(item, 0)) < int(recipe["needs"][item]):
			return false
	return true


func _draw_crafting() -> void:
	var at: Vector2 = window_positions["crafting"]
	var panel := Rect2(at, Vector2(560, 510))
	draw_rect(Rect2(Vector2.ZERO, SCREEN), Color(0, 0, 0, 0.10), true)
	_rounded_box(panel, Color(0.035, 0.039, 0.055, 0.97), Color("edf3fa"), 9.0, 2.0)
	draw_rect(Rect2(at + Vector2(2, 2), Vector2(556, 35)), Color("080c15"), true)
	_text("Hand Crafting [C / Esc to close]", at + Vector2(15, 25), 18)
	_rounded_box(Rect2(at + Vector2(526, 6), Vector2(28, 28)), Color("74333b"), Color.WHITE, 6.0, 1.0)
	_text("X", at + Vector2(534, 27), 18)
	_text("Basic supplies", at + Vector2(16, 68), 20, Color("dcc493"))
	_text("Use F at a workbench or furnace for its stored ingredients.", at + Vector2(16, 105), 14, Color("b6cad5"))
	var pages := int(ceil(float(RECIPE_GROUPS[recipe_tab].size()) / RECIPE_PAGE_SIZE))
	_text("%d/%d" % [_recipe_page() + 1, pages], at + Vector2(368, 108), 13, Color("d6e5ed"))
	for direction in [-1, 1]:
		var button := Rect2(at + Vector2(418 if direction < 0 else 486, 88), Vector2(54, 27))
		_rounded_box(button, Color("1c2938"), Color("bccddb") if pages > 1 else Color("56606b"), 8.0, 1.0)
		_text("<" if direction < 0 else ">", button.position + Vector2(22, 19), 17, Color.WHITE if pages > 1 else Color("68717d"))
	var group := _visible_recipes()
	for row in range(group.size()):
		var index: int = group[row]
		var recipe: Dictionary = RECIPES[index]
		var rect := Rect2(at + Vector2(14, 139 + row * 51), Vector2(532, 47))
		draw_rect(rect, Color("202a37") if index == recipe_index else Color("10151f"), true)
		draw_rect(rect, Color("e7ca70") if index == recipe_index else Color("788693"), false, 1.0)
		_draw_item_icon(str(recipe["out"]), Rect2(rect.position + Vector2(6, 5), Vector2(35, 35)))
		var recipe_label := str(recipe["name"]) + (" - %.0fs" % FurnaceSystem.TIMES[recipe["out"]] if FurnaceSystem.timed(recipe) else "")
		_text(recipe_label, rect.position + Vector2(47, 21), 17)
		_text(_recipe_needs(recipe["needs"]), rect.position + Vector2(47, 40), 13, Color("b9c4cd"))
		var ready := _recipe_ready(recipe)
		_rounded_box(Rect2(rect.position + Vector2(432, 8), Vector2(91, 31)),
			Color("244456") if ready else Color("30343d"), Color("deedf6") if ready else Color("68717d"), 12.0, 2.0)
		_button_text(Rect2(rect.position + Vector2(432, 8), Vector2(91, 31)), "Smelt" if FurnaceSystem.timed(recipe) else ("Cook" if food.edible(recipe["out"]) else "Craft"), 16, Color.WHITE if ready else Color("9ba6b2"))
	var selected: Dictionary = RECIPES[recipe_index]
	_text("%s  |  %s" % [selected["name"], "Ready" if _recipe_ready(selected) else "Needs materials or station"],
		at + Vector2(16, 476), 15, Color("d6e5ed"))
	_text(Tools.summary(str(selected["out"])), at + Vector2(16, 498), 13, Color("e4c68b"))


func _draw_inventory() -> void:
	var at: Vector2 = window_positions["inventory"]
	var panel := Rect2(at, Vector2(466, 382))
	draw_rect(Rect2(Vector2.ZERO, SCREEN), Color(0, 0, 0, 0.10), true)
	_rounded_box(panel, Color(0, 0, 0, 0.84), Color.WHITE, 8.0, 2.0)
	draw_rect(Rect2(at + Vector2(2, 2), Vector2(462, 34)), Color("08080c"), true)
	draw_line(at + Vector2(2, 37), at + Vector2(464, 37), Color("7896be"), 1.0)
	_text("Backpack  [I]", at + Vector2(20, 26), 15)
	_rounded_box(Rect2(at + Vector2(222, 6), Vector2(68, 26)), Color("2a4148"), Color("9db6b5"), 5, 1)
	_text("Sort", at + Vector2(241, 25), 14)
	inventory_page = clampi(inventory_page, 0, _inventory_page_count() - 1)
	for x in [300, 385]:
		_rounded_box(Rect2(at + Vector2(x, 6), Vector2(28, 26)), Color("233442"), Color("7896be"), 5.0, 1)
	_text("<", at + Vector2(308, 25), 16)
	_text(">", at + Vector2(393, 25), 16)
	_text("%d/%d" % [inventory_page + 1, _inventory_page_count()], at + Vector2(339, 25), 14)
	_rounded_box(Rect2(at + Vector2(433, 6), Vector2(27, 28)), Color("783030"), Color.WHITE, 6.0, 1.0)
	_text("X", at + Vector2(441, 26), 16)
	var items := _inventory_items()
	var mouse := get_viewport().get_mouse_position()
	var hovered := ""
	for cell in range(32):
		var index := inventory_page * 32 + cell
		var rect := Rect2(at + Vector2(20 + (cell % 8) * 54, 45 + (cell / 8) * 54), Vector2(48, 48))
		draw_rect(rect, Color("30343b"), true)
		draw_rect(rect, Color("f2df55") if rect.has_point(mouse) else Color.WHITE, false, 2.0)
		if index >= items.size():
			continue
		var item: String = items[index]
		_draw_item_icon(item, Rect2(rect.position + Vector2(7, 5), Vector2(33, 33)))
		_text(str(inventory[item]), rect.position + Vector2(29, 43), 12)
		if rect.has_point(mouse):
			hovered = item
	draw_line(at + Vector2(16, 267), at + Vector2(450, 267), Color("465566"), 1.0)
	_rounded_box(Rect2(at + Vector2(16, 274), Vector2(434, 70)), Color("18191f"), Color("6a4148"), 7.0, 1.0)
	var trash_rect := Rect2(at + Vector2(20, 278), Vector2(48, 48))
	_rounded_box(trash_rect, Color("29272d"), Color("e0a397") if inventory_dragging else Color("8c6868"), 6.0, 2.0)
	if inventory_trash.is_empty():
		var bin := at + Vector2(32, 291)
		_outline_rounded_rect(Rect2(bin, Vector2(22, 24)), Color("9a8586"), 3.0, 1.5)
		draw_line(bin + Vector2(-3, -3), bin + Vector2(25, -3), Color("9a8586"), 2.0)
		draw_line(bin + Vector2(6, -7), bin + Vector2(16, -7), Color("9a8586"), 2.0)
		for line in range(3):
			draw_line(bin + Vector2(5 + line * 6, 5), bin + Vector2(5 + line * 6, 18), Color("9a8586"), 1.0)
		_text("Trash", at + Vector2(80, 297), 16, Color("d7b7b6"))
		_text("Drag a stack here, then press X to destroy", at + Vector2(80, 320), 12, Color("b1a3a8"))
	else:
		_draw_item_icon(str(inventory_trash["item"]), Rect2(trash_rect.position + Vector2(7, 5), Vector2(34, 34)))
		_text(str(inventory_trash["count"]), trash_rect.position + Vector2(25, 43), 12)
		_text("%s x%d" % [inventory_trash["item"], int(inventory_trash["count"])], at + Vector2(80, 297), 15, Color("f1d3cd"))
		_text("Click the slot to return it to your backpack", at + Vector2(80, 320), 12, Color("b1a3a8"))
	_rounded_box(Rect2(at + Vector2(398, 286), Vector2(32, 32)), Color("9c343c") if not inventory_trash.is_empty() else Color("472e34"), Color("de8d8d"), 6.0, 1.0)
	_text("X", at + Vector2(408, 309), 19, Color.WHITE if not inventory_trash.is_empty() else Color("94787c"))
	_text("Click: store stack | Right-click: store one | Ctrl+click: hotbar" if interactions.is_open() or stations.is_open() else "Ctrl+click: add to hotbar | Drag: assign/move | Ctrl+bar: remove", at + Vector2(20, 367), 11, Color("c9d7e3"))
	if hovered != "":
		var description := ores.description(hovered) if ores.has_item(hovered) else (food.description(hovered) if food.has_icon(hovered) else Tools.display_name(hovered))
		var stats := Tools.summary(hovered)
		if Furnishings.has_item(hovered):stats=Furnishings.description(hovered)
		if Tools.max_durability(hovered) > 0:
			stats = "Level %d | %.0fx | Durability %d/%d | +%d damage" % [Tools.mining_level(hovered), float(Tools.profile(hovered)["speed"]), tool_wear.remaining(hovered, inventory), Tools.max_durability(hovered), int(Tools.profile(hovered)["bonus"])]
			if Tools.family(hovered) == "Shovel":
				stats = "Soil %.0fx | Durability %d/%d | %d damage" % [float(Tools.profile(hovered)["speed"]), tool_wear.remaining(hovered, inventory), Tools.max_durability(hovered), Tools.damage(hovered)]
		if GroundLife.has_item(hovered):
			stats = "Select, then right-click clear ground to plant / release"
		var width := maxf(190, maxf(description.length() * 8.0 + 50, stats.length() * 8.0 + 16))
		var tooltip := Rect2(mouse + Vector2(12, -28), Vector2(width, 48 if food.edible(hovered) or not stats.is_empty() else 27))
		tooltip.position.x = minf(tooltip.position.x, SCREEN.x - tooltip.size.x - 5.0)
		_rounded_box(tooltip, Color("080c13"), Color("e5e9ee"), 5.0, 1.0)
		_text("%s x%d" % [description, int(inventory[hovered])], tooltip.position + Vector2(8, 19), 14)
		if food.edible(hovered):
			_text("Right-click to eat | Left-click to equip", tooltip.position + Vector2(8, 39), 12, Color("b7d39b"))
		elif not stats.is_empty():
			_text(stats, tooltip.position + Vector2(8, 39), 12, Color("e4c68b"))


func _recipe_needs(needs: Dictionary) -> String:
	var parts := PackedStringArray()
	for item in needs:
		parts.append("%s %d" % [Tools.display_name(str(item)), needs[item]])
	return ", ".join(parts)


func _draw_dialogue() -> void:
	var at: Vector2 = window_positions["dialogue"]
	_rounded_box(Rect2(at, Vector2(830, 150)), Color("11253d"), Color("94c2dc"), 10.0)
	if not expedition.home():
		_text("Robot R0-VR", at + Vector2(25, 36), 24)
	_rounded_box(Rect2(at + Vector2(790, 7), Vector2(32, 30)), Color("743e46"), Color.WHITE, 6.0, 1.0)
	_text("X", at + Vector2(799, 29), 18)
	if expedition.home():
		expedition.draw_dialogue(at)
		return
	if world.get("quest_done", false):
		_text("You have proved you can survive out here. Keep exploring!", at + Vector2(25, 73), 19)
	else:
		_text("Bring me 20 Wood and I'll trade you 2 Crystal.", at + Vector2(25, 73), 19)
		_text("Wood in pack: %d   |   Press E again to turn it in" % int(inventory.get("Wood", 0)), at + Vector2(25, 106), 17)
