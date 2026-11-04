extends RefCounted

const WG = preload("res://scripts/world_gen.gd")
const Slots = preload("res://scripts/station_slots.gd")
const Tools = preload("res://scripts/tool_catalog.gd")
const SIZE := Vector2(720, 440)
const CELL := 52.0
var g
var kind := ""
var key := ""
var source := {}
var page := 0

func _init(game) -> void:
	g = game

func is_open() -> bool:
	return not kind.is_empty() and g.scene_name == "planet"

func open(selected: Dictionary) -> void:
	g.magic.codex_open=false
	g.alchemy.close(false)
	g.power_ui.close(false)
	g.interactions.close(false)
	close(false)
	kind = str(selected["name"]).to_lower()
	key = "%d,%d" % [selected["tile"].x, selected["tile"].y]
	g.inventory_open = true
	g.crafting_open = false
	g.dialogue_open = false
	g._stop_held_actions()
	g.tool_action_timer = 0
	page = 0
	if not g.window_positions.has(kind):
		g.window_positions[kind] = Vector2(20, 160)
	var box := Rect2(Vector2(g.window_positions[kind]), SIZE)
	if box.intersects(Rect2(Vector2(g.window_positions["inventory"]), Vector2(466, 382))):
		g.window_positions["inventory"] = Vector2(790, 190)
		if box.intersects(Rect2(Vector2(g.window_positions["inventory"]), Vector2(466, 382))):
			g.window_positions[kind] = Vector2(20, 160)
	if kind == "furnace":
		g.furnaces.focus_key = key
	state()

func close(close_pack: bool = true) -> void:
	kind = ""
	key = ""
	source.clear()
	g._cancel_inventory_drag()
	if close_pack:
		g.inventory_open = false
	g.dragged_window = ""

func state() -> Dictionary:
	if kind == "furnace":
		return g.furnaces.state(key)
	if not g.world.has("workbenches"):
		g.world["workbenches"] = {}
	if not g.world["workbenches"].has(key):
		g.world["workbenches"][key] = {"inputs": Slots.create(9), "output": {}, "recipe": 0}
	return g.world["workbenches"][key]

func input_slots() -> Array:
	return state()["inputs"]

func recipes() -> Array:
	var result := []
	for index in range(g.RECIPES.size()):
		if str(g.RECIPES[index].get("station", "")) != "Furnace":
			result.append(index)
	return result

func selected_recipe() -> int:
	var index := int(state().get("recipe", 0))
	return index if index in recipes() else 0

func ready(recipe: Dictionary) -> bool:
	var output: Dictionary = state()["output"]
	return (output.has(recipe["out"]) or output.size() < 4) and Slots.ready(input_slots(), recipe["needs"])

func craft(index: int = -1) -> bool:
	if not is_open() or kind != "workbench":
		return false
	if index < 0:
		index = selected_recipe()
	if index not in recipes():
		return false
	var recipe: Dictionary = g.RECIPES[index]
	if not ready(recipe):
		g._show_notice("Put the recipe's ingredients in this workbench and leave room in its output")
		return false
	Slots.consume(input_slots(), recipe["needs"])
	var output: Dictionary = state()["output"]
	output[recipe["out"]] = int(output.get(recipe["out"], 0)) + int(recipe["count"])
	g._show_notice("Crafted " + str(recipe["name"]) + " - take it from the output slots")
	return true

func fuel_item(item: String) -> bool:
	return item in ["Coal Ore", "Wood"]

func material_item(item: String) -> bool:
	for recipe: Dictionary in g.RECIPES:
		if str(recipe.get("station", "")) == "Furnace" and recipe["needs"].has(item) and not fuel_item(item):
			return true
	return false

func _valid_destination(item: String, zone: String) -> bool:
	if zone == "output" or zone == "result":
		return false
	return kind == "workbench" or (fuel_item(item) if zone == "fuel" else material_item(item))

func deposit(item: String, count: int = -1, zone: String = "", index: int = -1) -> bool:
	if not is_open():
		return false
	if zone.is_empty():
		zone = "fuel" if kind == "furnace" and fuel_item(item) else "input"
	if not _valid_destination(item, zone):
		g._show_notice("That item does not belong in this station slot")
		return false
	var slots: Array = state()["fuel"] if zone == "fuel" else input_slots()
	if index < 0:
		index = Slots.free_slot(slots, item)
	var amount := int(g.inventory.get(item, 0))
	if count >= 0:
		amount = mini(amount, count)
	if amount <= 0 or not Slots.accepts(slots, index, item):
		g._show_notice("This station has no matching empty slot")
		return false
	var wear: Array = g.tool_wear.take(item, amount, g.inventory)
	Slots.put(slots, index, item, amount, wear)
	g.inventory[item] = int(g.inventory[item]) - amount
	g._refresh_hotbar()
	return true

func stack_at(zone: String, index: int) -> Dictionary:
	if zone == "output":
		var names: Array = state()["output"].keys()
		names.sort()
		return {"item": names[index], "count": int(state()["output"][names[index]])} if index < names.size() else {}
	var slots: Array = state()["fuel"] if zone == "fuel" else input_slots()
	return slots[index] if index >= 0 and index < slots.size() else {}

func take(zone: String, index: int, count: int = -1) -> Dictionary:
	if zone != "output":
		return Slots.take(state()["fuel"] if zone == "fuel" else input_slots(), index, count)
	var stack := stack_at(zone, index)
	if stack.is_empty():
		return {}
	var amount := int(stack["count"]) if count < 0 else mini(count, int(stack["count"]))
	var output: Dictionary = state()["output"]
	output[stack["item"]] = int(stack["count"]) - amount
	if int(output[stack["item"]]) <= 0:
		output.erase(stack["item"])
	return {"item": stack["item"], "count": amount, "wear": []}

func withdraw(zone: String, index: int, count: int = -1) -> String:
	var stack := take(zone, index, count)
	if stack.is_empty():
		return ""
	g._add_item(str(stack["item"]), int(stack["count"]), stack.get("wear", []))
	return str(stack["item"])

func slot_rect(zone: String, index: int) -> Rect2:
	var at: Vector2 = g.window_positions[kind]
	if kind == "workbench":
		if zone == "input":
			return Rect2(at + Vector2(24 + index % 3 * 58, 94 + (index / 3) * 58), Vector2.ONE * CELL)
		if zone == "output":
			return Rect2(at + Vector2(256 + index % 2 * 58, 110 + (index / 2) * 58), Vector2.ONE * CELL)
		return Rect2(at + Vector2(284, 282), Vector2.ONE * CELL)
	if zone == "input":
		return Rect2(at + Vector2(24 + index % 3 * 58, 94 + (index / 3) * 58), Vector2.ONE * CELL)
	if zone == "fuel":
		return Rect2(at + Vector2(245, 108), Vector2.ONE * CELL)
	return Rect2(at + Vector2(442 + index % 3 * 58, 94 + (index / 3) * 58), Vector2.ONE * CELL)

func slot_at(point: Vector2) -> Dictionary:
	for zone in ["input", "fuel", "output", "result"]:
		var count := (9 if kind == "workbench" else 6) if zone == "input" else ((4 if kind == "workbench" else 6) if zone == "output" else (1 if (zone == "fuel" and kind == "furnace") or (zone == "result" and kind == "workbench") else 0))
		for index in range(count):
			if slot_rect(zone, index).has_point(point):
				return {"zone": zone, "index": index}
	return {}

func accepts_drag(point: Vector2, item: String) -> bool:
	if not is_open() or not Rect2(Vector2(g.window_positions[kind]), SIZE).has_point(point):
		return false
	var target := slot_at(point)
	if not target.is_empty() and str(target["zone"]) in ["input", "fuel"]:
		deposit(item, -1, str(target["zone"]), int(target["index"]))
	return true

func holding_inputs(world: Dictionary, station_key: String) -> bool:
	return is_open() and kind == "furnace" and key == station_key and is_same(world, g.world) and not source.is_empty() and str(source["zone"]) != "output"

func finish_drag(point: Vector2) -> bool:
	if source.is_empty():
		return false
	if not is_open():
		source.clear()
		return true
	var zone := str(source["zone"])
	var index := int(source["index"])
	if zone == "output":
		var names: Array = state()["output"].keys()
		names.sort()
		index = names.find(str(source["item"]))
		if index < 0:
			source.clear()
			return true
	var stack := stack_at(zone, index)
	if stack.is_empty():
		source.clear()
		return true
	var destination := slot_at(point)
	if g.inventory_dragging and not destination.is_empty() and str(destination["zone"]) in ["input", "fuel"]:
		var dest_zone := str(destination["zone"])
		var dest_index := int(destination["index"])
		if not (zone == dest_zone and index == dest_index) and _valid_destination(str(stack["item"]), dest_zone):
			var dest: Array = state()["fuel"] if dest_zone == "fuel" else input_slots()
			if Slots.accepts(dest, dest_index, str(stack["item"])):
				var moved := take(zone, index)
				Slots.put(dest, dest_index, str(moved["item"]), int(moved["count"]), moved.get("wear", []))
			elif zone != "output" and not dest[dest_index].is_empty() and _valid_destination(str(dest[dest_index]["item"]), zone):
				var other := Slots.take(dest, dest_index)
				var moved := take(zone, index)
				Slots.put(dest, dest_index, str(moved["item"]), int(moved["count"]), moved.get("wear", []))
				Slots.put(state()["fuel"] if zone == "fuel" else input_slots(), index, str(other["item"]), int(other["count"]), other.get("wear", []))
	elif not g.inventory_dragging or Rect2(Vector2(g.window_positions["inventory"]), Vector2(466, 382)).has_point(point) or g._hotbar_slot_at(point) >= 0:
		var item := withdraw(zone, index)
		if g.inventory_dragging and g._hotbar_slot_at(point) >= 0 and not Rect2(Vector2(g.window_positions["inventory"]), Vector2(466, 382)).has_point(point):
			g.hotbar.assign(item, g._hotbar_slot_at(point), g.inventory)
			g._refresh_hotbar()
	source.clear()
	return true

func click(point: Vector2, button: int, control: bool = false) -> bool:
	if not is_open() or not Rect2(Vector2(g.window_positions[kind]), SIZE).has_point(point):
		return false
	var at: Vector2 = g.window_positions[kind]
	if button == MOUSE_BUTTON_LEFT and Rect2(at + Vector2(682, 6), Vector2(28, 28)).has_point(point):
		close(false)
		return true
	if button == MOUSE_BUTTON_LEFT and Rect2(at, Vector2(680, 37)).has_point(point):
		g._start_window_drag(kind, point)
		return true
	if kind == "workbench":
		var choices := recipes()
		var pages := ceili(choices.size() / 5.0)
		if button in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN]:
			page = posmod(page + (-1 if button == MOUSE_BUTTON_WHEEL_UP else 1), pages)
		elif button == MOUSE_BUTTON_LEFT:
			for direction in [-1, 1]:
				if Rect2(at + Vector2(574 if direction < 0 else 658, 45), Vector2(36, 29)).has_point(point):
					page = posmod(page + direction, pages)
			for row in range(5):
				if page * 5 + row < choices.size() and Rect2(at + Vector2(410, 86 + row * 48), Vector2(284, 44)).has_point(point):
					state()["recipe"] = choices[page * 5 + row]
	var hit := slot_at(point)
	if hit.is_empty():
		return true
	var zone := str(hit["zone"])
	var index := int(hit["index"])
	if zone == "result":
		if button == MOUSE_BUTTON_LEFT:
			craft()
		return true
	var stack := stack_at(zone, index)
	if not stack.is_empty():
		if button == MOUSE_BUTTON_RIGHT:
			withdraw(zone, index, 1)
		elif button == MOUSE_BUTTON_LEFT:
			if control:
				var item := withdraw(zone, index)
				g._add_to_hotbar(item)
			else:
				source = {"zone": zone, "index": index, "item": str(stack["item"])}
				g.inventory_drag_item = str(stack["item"])
				g.inventory_drag_start = point
				g.inventory_dragging = false
				g.inventory_drag_slot = -1
	return true

func remove_workbench(tile: Vector2i) -> Array:
	var station_key := "%d,%d" % [tile.x, tile.y]
	var store: Dictionary = g.world.get("workbenches", {}).get(station_key, {})
	var recovered: Array = []
	for stack: Dictionary in store.get("inputs", []):
		if not stack.is_empty():
			recovered.append(stack.duplicate(true))
	for item: String in store.get("output", {}):
		recovered.append({"item": item, "count": int(store["output"][item]), "wear": []})
	g.world.get("workbenches", {}).erase(station_key)
	return recovered

func _draw_slot(zone: String, index: int) -> void:
	var box := slot_rect(zone, index)
	var mouse: Vector2 = g.get_viewport().get_mouse_position()
	g._rounded_box(box, Color("1d2c38"), Color("e9cd84") if box.has_point(mouse) else Color("617887"), 6, 1)
	var stack := stack_at(zone, index)
	if stack.is_empty():
		return
	g._draw_item_icon(str(stack["item"]), Rect2(box.position + Vector2(8, 6), Vector2(36, 36)))
	g._text(str(int(stack["count"])), box.position + Vector2(29, 46), 12)

func tooltip_at(point: Vector2) -> String:
	if not is_open() or not g.inventory_drag_item.is_empty():return ""
	var hit:=slot_at(point)
	if hit.is_empty() or str(hit.zone)=="result":return ""
	var stack:=stack_at(str(hit.zone),int(hit.index))
	return "" if stack.is_empty() else Tools.display_name(str(stack.item))+" x%d" % int(stack.count)

func draw_tooltip() -> void:
	var mouse:Vector2=g.get_viewport().get_mouse_position()
	var label:=tooltip_at(mouse)
	if not label.is_empty():g._draw_item_tooltip(mouse,[label])

func draw() -> void:
	if not is_open():
		return
	var at: Vector2 = g.window_positions[kind]
	g._rounded_box(Rect2(at, SIZE), Color("111b25"), Color("c4b58f"), 10, 2)
	g._draw_item_icon(kind.capitalize(), Rect2(at + Vector2(14, 6), Vector2(28, 28)))
	g._text(kind.capitalize() + "  [F / Esc to close]", at + Vector2(52, 27), 18, Color("ede0c6"))
	g._rounded_box(Rect2(at + Vector2(682, 6), Vector2(28, 28)), Color("78333d"), Color("c5a6a3"), 6, 1)
	g._text("X", at + Vector2(691, 27), 17)
	g._button_text(Rect2(at+Vector2(24,50),Vector2(180,32)), "Ingredients stored here" if kind == "workbench" else "Ore / food ingredients", 14, Color("bed0d7"), false, Vector2.ZERO)
	for index in range(9 if kind == "workbench" else 6):
		_draw_slot("input", index)
	g._text("Output", at + Vector2(256 if kind == "workbench" else 442, 74), 14, Color("c8d8c5"))
	for index in range(4 if kind == "workbench" else 6):
		_draw_slot("output", index)
	if kind == "workbench":
		var choices := recipes()
		g._text("Recipes", at + Vector2(412, 66), 15)
		for x in [574, 658]:
			g._rounded_box(Rect2(at + Vector2(x, 45), Vector2(36, 29)), Color("253848"), Color("657d8d"), 6, 1)
		g._text("<", at + Vector2(587, 66), 16)
		g._text(">", at + Vector2(671, 66), 16)
		g._text("%d/%d" % [page + 1, ceili(choices.size() / 5.0)], at + Vector2(617, 66), 13)
		for row in range(5):
			if page * 5 + row >= choices.size():
				break
			var index: int = choices[page * 5 + row]
			var recipe: Dictionary = g.RECIPES[index]
			var box := Rect2(at + Vector2(410, 86 + row * 48), Vector2(284, 44))
			g._rounded_box(box, Color("2a3e49") if index == selected_recipe() else Color("172632"), Color("dbc48d") if index == selected_recipe() else Color("415866"), 5, 1)
			g._draw_item_icon(str(recipe["out"]), Rect2(box.position + Vector2(5, 5), Vector2(32, 32)))
			g._button_text(Rect2(box.position + Vector2(40, 0), box.size - Vector2(40, 0)), str(recipe["name"]), 14, Color("d6e6d9") if ready(recipe) else Color("98aab5"), false)
		var selected: Dictionary = g.RECIPES[selected_recipe()]
		g._text("Make", at + Vector2(230, 313), 15, Color("dbcb9c"))
		var box := slot_rect("result", 0)
		g._rounded_box(box, Color("2e493c") if ready(selected) else Color("29313b"), Color("c8d99e") if ready(selected) else Color("687983"), 6, 2)
		g._draw_item_icon(str(selected["out"]), Rect2(box.position + Vector2(8, 7), Vector2(36, 36)))
		g._text(str(int(selected["count"])), box.position + Vector2(32, 46), 12)
		g._button_text(Rect2(at+Vector2(24,344),Vector2(670,30)),str(selected["name"]),17,Color("e2d3b0"),false,Vector2.ZERO)
		var needs: String = g._recipe_needs(selected["needs"])
		g._button_text(Rect2(at+Vector2(24,376),Vector2(670,24)),needs,13,Color("b4c8d1"),false,Vector2.ZERO)
	else:
		g._text("Fuel", at + Vector2(247, 92), 14, Color("e0b37f"))
		_draw_slot("fuel", 0)
		var machine := state()
		var heat := float(machine["heat"])
		g.draw_rect(Rect2(at + Vector2(232, 202), Vector2(156, 7)), Color("34434b"))
		g.draw_rect(Rect2(at + Vector2(232, 202), Vector2(156 * heat, 7)), Color("e4a264"))
		g._text("Heat %d%%" % roundi(heat * 100), at + Vector2(232, 228), 14, Color("e4b584"))
		var status := "Add materials and fuel to start automatically"
		if not machine["jobs"].is_empty():
			var job: Dictionary = machine["jobs"][0]
			var progress := float(job["elapsed"]) / float(job["duration"])
			status = ("Heating: " if heat < 0.999 else ("Cooking: " if g.food.edible(str(job["out"])) else "Smelting: ")) + str(job["out"])
			g.draw_rect(Rect2(at + Vector2(232, 245), Vector2(156, 7)), Color("34434b"))
			g.draw_rect(Rect2(at + Vector2(232, 245), Vector2(156 * progress, 7)), Color("a6c79b"))
			g._text("%d%%" % roundi(progress * 100), at + Vector2(232, 275), 14)
		g._button_text(Rect2(at+Vector2(24,292),Vector2(670,36)),status,17,Color("e4d5b6"),false,Vector2.ZERO)
		g._text("Coal smelts ore and alloys. Wood cooks meals.", at + Vector2(24, 352), 14, Color("bdcbd2"))
		g._text("Each furnace stores and processes its own materials.", at + Vector2(24, 380), 13, Color("90a9b7"))
	g._text("Drag between slots and backpack. Click to take a stack; right-click takes one.", at + Vector2(24, 423), 12, Color("91aab7"))
