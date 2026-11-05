extends RefCounted
## Only plain Variant data crosses the network; never deserialize Objects.
const WG = preload("res://scripts/world_gen.gd")
const PERSONAL := ["player_pos", "player_velocity", "player_grounded", "facing", "health",
	"inventory", "inventory_order", "inventory_trash", "selected_slot", "hotbar_page", "equipped_tool",
	"use_pickaxe", "use_hoe", "food_cooldown", "attack_cooldown", "mining_cooldown", "damage_cooldown",
	"attack_visual", "tool_action_timer", "tool_action_duration", "tool_action_kind", "tool_action_target",
	"mouse_aim_direction", "mouse_aim_valid", "mining_feedback_tile", "mining_feedback_progress", "mining_feedback_timer",
	"inventory_open", "crafting_open", "dialogue_open", "paused", "recipe_tab", "recipe_index", "inventory_page",
	"window_positions", "dragged_window", "drag_offset", "inventory_drag_item", "inventory_drag_start",
	"inventory_dragging", "inventory_drag_slot", "eat_visual", "last_food", "last_heal", "notice", "notice_timer"]
const COMPONENTS := {
	"equipment": ["slots", "guard", "guard_wait", "broken_time", "blocking", "gear_open"],
	"stations": ["kind", "key", "page", "source"], "interactions": ["chest_key"],
	"alchemy": ["active_key", "editing", "selected_all"], "power_ui": ["node_key"],
	"power": ["pending"],
	"ranged": ["selected_ammo", "charging", "drawn_weapon", "draw_time", "recoil", "projectiles"],
	"magic": ["codex_open", "projectiles", "arcs"], "furnaces": ["focus_key"],
	"spellcraft": ["codex_tab", "codex_page"], "necromancy": ["minions"]}

static func personal(g) -> Dictionary:
	var result := {}
	for key in PERSONAL: result[key] = g.get(key)
	result["hotbar"] = g.hotbar.slots
	result["wear"] = g.tool_wear.uses
	result["magic_save"] = g.magic.snapshot()
	for component in COMPONENTS:
		var values := {}
		for key in COMPONENTS[component]: values[key] = g.get(component).get(key)
		result[component] = values
	return result.duplicate(true)

static func apply_personal(g, data: Dictionary, predict := false) -> void:
	for key in PERSONAL:
		if not data.has(key): continue
		if predict and key == "player_pos":
			var target: Vector2 = data[key]
			g.player_pos = target if g.player_pos.distance_to(target) > 96 else g.player_pos.lerp(target, 0.45)
		else: g.set(key, data[key])
	if data.has("hotbar"): g.hotbar.restore(data.hotbar, g.inventory)
	if data.has("wear"): g.tool_wear.restore(data.wear, g.inventory)
	if data.has("magic_save"): g.magic.restore(data.magic_save)
	for component in COMPONENTS:
		for key in data.get(component, {}):
			if key in COMPONENTS[component]: g.get(component).set(key, data[component][key])
	for item in g.inventory:
		if g.SpellcraftCatalog.is_spell(str(item)) and not g.tool_textures.has(item):
			g.tool_textures[item] = g.MagicCatalog.icon(item)
	g._update_camera()

static func shared(g) -> Dictionary:
	return {"scene": g.scene_name, "galaxy_seed": g.galaxy_seed, "star_index": g.star_index,
		"planet_index": g.planet_index, "world": g.world, "expedition": g.expedition.data,
		"time_of_day": g.time_of_day, "day_count": g.day_count, "weather": g.weather,
		"weather_cycle": g.weather_cycle, "weather_timer": g.weather_timer,
		"water_falling": g.water_sim.falling, "lava_falling": g.lava_sim.falling,
		"weather_blend": g.weather_blend.snapshot()}

static func install_world(g, data: Dictionary) -> void:
	g._stop_held_actions()
	g.galaxy_seed = int(data.galaxy_seed)
	g.star_index = int(data.star_index)
	g.planet_index = int(data.planet_index)
	g.world = data.world
	g.worlds[g._world_key()] = g.world
	g.expedition.data = data.expedition
	g._make_galaxy()
	g._make_system()
	g._init_clouds()
	g._reset_world_environment()
	g.world_texture = WG.make_texture(g.world.tiles)
	g.world_image = g.world_texture.get_image()
	g.foliage.reset()
	g.scene_name = "planet"
	g._update_camera()

static func apply_shared(g, data: Dictionary) -> void:
	for key in ["time_of_day", "day_count", "weather", "weather_cycle", "weather_timer"]:
		if data.has(key): g.set(key, data[key])
	if data.has("expedition"): g.expedition.data = data.expedition
	if data.has("weather_blend"): g.weather_blend.restore(data.weather_blend, g.weather, int(g.world.get("climate", 0)))
	if data.has("water_falling"): g.water_sim.falling = data.water_falling
	if data.has("lava_falling"): g.lava_sim.falling = data.lava_falling

static func event_data(event: InputEvent) -> Dictionary:
	if event is InputEventKey:
		return {"type": "key", "key": int(event.keycode), "unicode": event.unicode,
			"pressed": event.pressed, "echo": event.echo, "ctrl": event.ctrl_pressed, "shift": event.shift_pressed, "alt": event.alt_pressed}
	if event is InputEventMouseButton or event is InputEventMouseMotion:
		var value := {"type": "button" if event is InputEventMouseButton else "motion", "position": event.position}
		if event is InputEventMouseButton:
			value.merge({"button": event.button_index, "pressed": event.pressed, "ctrl": event.ctrl_pressed, "shift": event.shift_pressed, "alt": event.alt_pressed})
		return value
	return {}

static func input_event(data: Dictionary) -> InputEvent:
	var event: InputEvent
	match data.get("type", ""):
		"key":
			event = InputEventKey.new()
			event.keycode = int(data.get("key", 0))
			event.unicode = clampi(int(data.get("unicode", 0)), 0, 0x10ffff)
			event.pressed = bool(data.get("pressed", false))
			event.echo = bool(data.get("echo", false))
		"button", "motion":
			var position: Variant = data.get("position", Vector2.ZERO)
			if not position is Vector2 or not position.is_finite(): return null
			event = InputEventMouseButton.new() if data.type == "button" else InputEventMouseMotion.new()
			event.position = position.clamp(Vector2.ZERO, Vector2(1280, 720))
			if event is InputEventMouseButton:
				event.button_index = clampi(int(data.get("button", 0)), 1, 9)
				event.pressed = bool(data.get("pressed", false))
		_: return null
	if event is InputEventWithModifiers:
		event.ctrl_pressed = bool(data.get("ctrl", false))
		event.shift_pressed = bool(data.get("shift", false))
		event.alt_pressed = bool(data.get("alt", false))
	return event
