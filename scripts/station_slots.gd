extends RefCounted

const Tools = preload("res://scripts/tool_catalog.gd")

static func create(size: int) -> Array:
	var result := []
	for _index in range(size):
		result.append({})
	return result

static func counts(slots: Array) -> Dictionary:
	var result := {}
	for stack: Dictionary in slots:
		if not stack.is_empty():
			var item := str(stack["item"])
			result[item] = int(result.get(item, 0)) + int(stack["count"])
	return result

static func free_slot(slots: Array, item: String) -> int:
	for index in range(slots.size()):
		if str(slots[index].get("item", "")) == item:
			return index
	for index in range(slots.size()):
		if slots[index].is_empty():
			return index
	return -1

static func accepts(slots: Array, index: int, item: String) -> bool:
	return index >= 0 and index < slots.size() and (slots[index].is_empty() or str(slots[index]["item"]) == item)

static func put(slots: Array, index: int, item: String, count: int, wear: Array = []) -> bool:
	if count <= 0 or not accepts(slots, index, item):
		return false
	if slots[index].is_empty():
		slots[index] = {"item": item, "count": 0, "wear": []}
	var stack: Dictionary = slots[index]
	stack["count"] = int(stack["count"]) + count
	if Tools.max_durability(item) > 0:
		var values: Array = stack.get("wear", [])
		for offset in range(count):
			values.append(clampi(int(wear[offset]), 1, Tools.max_durability(item)) if offset < wear.size() else Tools.max_durability(item))
		stack["wear"] = values
	return true

static func take(slots: Array, index: int, count: int = -1) -> Dictionary:
	if index < 0 or index >= slots.size() or slots[index].is_empty():
		return {}
	var stack: Dictionary = slots[index]
	var amount := int(stack["count"]) if count < 0 else mini(count, int(stack["count"]))
	if amount <= 0:
		return {}
	var result := {"item": str(stack["item"]), "count": amount, "wear": []}
	var values: Array = stack.get("wear", [])
	for _index in range(mini(amount, values.size())):
		result["wear"].append(values.pop_front())
	stack["count"] = int(stack["count"]) - amount
	if int(stack["count"]) <= 0:
		slots[index] = {}
	return result

static func ready(slots: Array, needs: Dictionary) -> bool:
	var available := counts(slots)
	for item in needs:
		if int(available.get(item, 0)) < int(needs[item]):
			return false
	return true

static func consume(slots: Array, needs: Dictionary) -> bool:
	if not ready(slots, needs):
		return false
	for item in needs:
		var remaining := int(needs[item])
		for index in range(slots.size()):
			if str(slots[index].get("item", "")) != item:
				continue
			var taken := take(slots, index, remaining)
			remaining -= int(taken.get("count", 0))
			if remaining == 0:
				break
	return true
