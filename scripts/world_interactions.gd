extends RefCounted

const WG = preload("res://scripts/world_gen.gd")
const Tools = preload("res://scripts/tool_catalog.gd")
const SIZE := Vector2(466, 382)
const CAPACITY := 32
var g
var chest_key := ""


func _init(game) -> void:
	g = game


func is_open() -> bool:
	return not chest_key.is_empty() and g.inventory_open and g.scene_name == "planet"


func close(close_pack := true) -> void:
	chest_key = ""
	if close_pack:
		g.inventory_open = false
	g._cancel_inventory_drag()
	g.dragged_window = ""


func target(wanted: String = "") -> Dictionary:
	if g.world.is_empty():
		return {}
	var center: Vector2 = g.player_pos + Vector2(8, 14)
	var tile := Vector2i(center / WG.TILE)
	var mouse: Vector2 = g.mouse_aim_screen + g.camera_pos if g.mouse_aim_valid else g.get_viewport().get_mouse_position() + g.camera_pos
	var best := {}
	var best_score := INF
	var seen := {}
	for y in range(maxi(1, tile.y - 5), mini(WG.HEIGHT - 1, tile.y + 6)):
		for x in range(maxi(1, tile.x - 5), mini(WG.WIDTH - 1, tile.x + 6)):
			var id := WG.tile_at(g.world["tiles"], x, y)
			if id not in [30, 34, 35, 36, 37]:
				continue
			var origin := Vector2i(x - (1 if id in [36, 37] else 0), y)
			if seen.has(origin):
				continue
			seen[origin] = true
			var station := id != 30
			var station_name := "Chest" if id == 30 else ("Workbench" if id in [34, 36] else "Furnace")
			if not wanted.is_empty() and station_name != wanted:
				continue
			var rect := Rect2(Vector2(origin * WG.TILE) - Vector2(0, 16 if station else 0), Vector2(32, 32) if station else Vector2(16, 16))
			var distance := center.distance_to(rect.get_center())
			if distance > g.DIG_REACH or not _visible(center, rect):
				continue
			var score := distance - (128.0 if rect.grow(4).has_point(mouse) else 0.0)
			if score < best_score:
				best_score = score
				best = {"tile": origin, "rect": rect, "name": "Chest" if id == 30 else ("Workbench" if id in [34, 36] else "Furnace")}
	return best


func _visible(from: Vector2, rect: Rect2) -> bool:
	var to := rect.get_center()
	var steps := maxi(1, ceili(from.distance_to(to) / 4.0))
	for index in range(1, steps):
		var point := from.lerp(to, float(index) / steps)
		if rect.has_point(point):
			continue
		var tile := Vector2i(floor(point / WG.TILE))
		if WG.is_solid(WG.tile_at(g.world["tiles"], tile.x, tile.y)):
			return false
	return true


func interact() -> bool:
	if is_open():
		close()
		return true
	var selected := target()
	if selected.is_empty():
		return false
	g._stop_held_actions()
	g.tool_action_timer = 0
	g.dialogue_open = false
	if selected["name"] == "Chest":
		g.stations.close(false)
		var tile: Vector2i = selected["tile"]
		chest_key = "%d,%d" % [tile.x, tile.y]
		if not g.world.has("chest_contents"):
			g.world["chest_contents"] = {}
		if not g.world["chest_contents"].has(chest_key):
			g.world["chest_contents"][chest_key] = {} if g.world.get("placed_chests", {}).has(chest_key) else {"Coal Ore": 3, "Copper Ore": 2}
		g.inventory_open = true
		g.crafting_open = false
		var chest_rect := Rect2(Vector2(g.window_positions["chest"]), SIZE)
		if chest_rect.intersects(Rect2(Vector2(g.window_positions["inventory"]), SIZE)):
			var left := chest_rect.position.x - SIZE.x - 20
			g.window_positions["inventory"] = Vector2(left if left >= 0 else minf(chest_rect.end.x + 20, 1280 - SIZE.x), chest_rect.position.y)
	else:
		g.stations.open(selected)
	return true


func contents() -> Dictionary:
	return g.world.get("chest_contents", {}).get(chest_key, {})


func items() -> Array:
	var result: Array = contents().keys()
	result.sort()
	return result


func deposit(item: String, count := -1) -> bool:
	if not is_open():
		return false
	var available := int(g.inventory.get(item, 0))
	var amount := available if count < 0 else mini(available, count)
	if amount <= 0:
		return false
	var store := contents()
	if not store.has(item) and store.size() >= CAPACITY:
		g._show_notice("Chest is full")
		return false
	store[item] = int(store.get(item, 0)) + amount
	if g.Tools.max_durability(item) > 0:
		if not g.world.has("chest_tool_wear"):
			g.world["chest_tool_wear"] = {}
		if not g.world["chest_tool_wear"].has(chest_key):
			g.world["chest_tool_wear"][chest_key] = {}
		var stored_wear: Array = g.world["chest_tool_wear"][chest_key].get(item, [])
		# Older chests have item counts without per-tool wear. Preserve their order.
		while stored_wear.size() < int(store[item]) - amount:
			stored_wear.append(g.Tools.max_durability(item))
		stored_wear.append_array(g.tool_wear.take(item, amount, g.inventory))
		g.world["chest_tool_wear"][chest_key][item] = stored_wear
	g.inventory[item] = available - amount
	g._refresh_hotbar()
	return true


func withdraw(item: String, count := -1) -> void:
	if not is_open():
		return
	var store := contents()
	var available := int(store.get(item, 0))
	var amount := available if count < 0 else mini(available, count)
	if amount <= 0:
		return
	var values: Array = g.world.get("chest_tool_wear", {}).get(chest_key, {}).get(item, [])
	var taken := []
	for _index in range(mini(amount, values.size())):
		taken.append(values.pop_front())
	g._add_item(item, amount, taken)
	if amount == available:
		store.erase(item)
	else:
		store[item] = available - amount


func accepts_drag(point: Vector2, item: String) -> bool:
	if not is_open() or not Rect2(Vector2(g.window_positions["chest"]), SIZE).has_point(point):
		return false
	deposit(item)
	return true


func click(point: Vector2, button: int) -> bool:
	if not is_open():
		return false
	var at: Vector2 = g.window_positions["chest"]
	if not Rect2(at, SIZE).has_point(point):
		return false
	if button == MOUSE_BUTTON_LEFT:
		if Rect2(at + Vector2(433, 6), Vector2(27, 28)).has_point(point):
			close()
		elif Rect2(at, Vector2(466, 37)).has_point(point):
			g._start_window_drag("chest", point)
		elif Rect2(at + Vector2(20, 284), Vector2(165, 36)).has_point(point):
			for item: String in items():
				withdraw(item)
	if button in [MOUSE_BUTTON_LEFT, MOUSE_BUTTON_RIGHT] and is_open():
		var stored := items()
		for index in range(stored.size()):
			if Rect2(at + Vector2(20 + index % 8 * 54, 45 + (index / 8) * 54), Vector2(48, 48)).has_point(point):
				withdraw(str(stored[index]), 1 if button == MOUSE_BUTTON_RIGHT else -1)
				break
	return true


func draw_hint() -> void:
	if g.inventory_open or g.crafting_open or g.stations.is_open() or g.paused or g.dev_mode or g.dialogue_open:
		return
	if g.furnishings.aimed(g):return
	var selected := target()
	if selected.is_empty():
		return
	var point: Vector2 = selected["rect"].get_center() - g.camera_pos
	var label := "F  " + str(selected["name"])
	var width := ThemeDB.fallback_font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, 13).x + 20
	var box := Rect2(Vector2(clampf(point.x - width * 0.5, 8, 1272 - width), clampf(point.y - 47, 170, 580)), Vector2(width, 25))
	g._rounded_box(box, Color("132433"), Color("d1b982"), 6, 1)
	g._text(label, box.position + Vector2(10, 18), 13, Color("eadbb9"))


func draw() -> void:
	if not is_open():
		return
	var at: Vector2 = g.window_positions["chest"]
	g._rounded_box(Rect2(at, SIZE), Color("101820"), Color("d2b783"), 8, 2)
	g._text("Chest  [F / Esc to close]", at + Vector2(20, 26), 15, Color("eddbb8"))
	g._rounded_box(Rect2(at + Vector2(433, 6), Vector2(27, 28)), Color("783030"), Color.WHITE, 6, 1)
	g._text("X", at + Vector2(441, 26), 16)
	var stored := items()
	for index in range(CAPACITY):
		var rect := Rect2(at + Vector2(20 + index % 8 * 54, 45 + (index / 8) * 54), Vector2(48, 48))
		g.draw_rect(rect, Color("30343b"))
		g.draw_rect(rect, Color("b9ab86"), false, 1)
		if index < stored.size():
			var item: String = stored[index]
			g._draw_item_icon(item, Rect2(rect.position + Vector2(7, 5), Vector2(33, 33)))
			g._text(str(int(contents()[item])), rect.position + Vector2(27, 43), 12)
	g._rounded_box(Rect2(at + Vector2(20, 284), Vector2(165, 36)), Color("263b49"), Color("b9ab86"), 8, 1)
	g._text("Take all", at + Vector2(64, 308), 16)
	g._text("%d / 32 stacks" % stored.size(), at + Vector2(300, 307), 14, Color("b9ab86"))
	g._text("Click pack to store. Click chest to take.", at + Vector2(20, 348), 13)
	g._text("Right-click: one item  |  Drag into chest: store stack", at + Vector2(20, 368), 12, Color("b9cad4"))
	var mouse: Vector2 = g.get_viewport().get_mouse_position()
	for index in range(stored.size()):
		if Rect2(at + Vector2(20 + index % 8 * 54, 45 + (index / 8) * 54), Vector2(48, 48)).has_point(mouse):
			var text := "%s x%d" % [Tools.display_name(str(stored[index])), int(contents()[stored[index]])]
			var width := ThemeDB.fallback_font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 14).x + 18
			var box := Rect2(Vector2(clampf(mouse.x + 12, 5, 1275 - width), mouse.y - 28), Vector2(width, 28))
			g._rounded_box(box, Color("080c13"), Color("d2b783"), 5, 1)
			g._text(text, box.position + Vector2(9, 20), 14)
			break
