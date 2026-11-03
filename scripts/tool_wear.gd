extends RefCounted

const Tools = preload("res://scripts/tool_catalog.gd")
var uses := {}


func sync(inventory: Dictionary) -> void:
	for key in uses.keys():
		if int(inventory.get(key, 0)) <= 0 or Tools.max_durability(str(key)) == 0:
			uses.erase(key)
	for key in inventory:
		var item := str(key)
		var maximum := Tools.max_durability(item)
		var count := maxi(0, int(inventory[key]))
		if maximum == 0 or count == 0:
			continue
		var values: Array = uses.get(item, [])
		while values.size() > count:
			values.pop_front()
		while values.size() < count:
			values.append(maximum)
		uses[item] = values


func remaining(item: String, inventory: Dictionary) -> int:
	sync(inventory)
	return int(uses[item][0]) if uses.has(item) and not uses[item].is_empty() else 0


func take(item: String, count: int, inventory: Dictionary) -> Array:
	sync(inventory)
	var result := []
	if uses.has(item):
		for _index in range(mini(count, uses[item].size())):
			result.append(uses[item].pop_front())
	return result


func receive(item: String, count: int, values: Array, inventory: Dictionary) -> void:
	var maximum := Tools.max_durability(item)
	if maximum <= 0:
		return
	var current: Array = uses.get(item, [])
	for index in range(count):
		var value: Variant = values[index] if index < values.size() else maximum
		current.append(clampi(int(value) if value is float or value is int else maximum, 1, maximum))
	uses[item] = current
	sync(inventory)


func spend(item: String, inventory: Dictionary, cost := 1) -> bool:
	sync(inventory)
	if not uses.has(item):
		return false
	uses[item][0] = int(uses[item][0]) - cost
	if int(uses[item][0]) > 0:
		return false
	uses[item].pop_front()
	inventory[item] = maxi(0, int(inventory[item]) - 1)
	return true


func restore(value: Variant, inventory: Dictionary) -> void:
	uses.clear()
	if value is Dictionary:
		for key in value:
			var item := str(key)
			if value[key] is Array and Tools.max_durability(item) > 0:
				var maximum := Tools.max_durability(item)
				var values := []
				for raw in value[key]:
					values.append(clampi(int(raw) if raw is float or raw is int else maximum, 1, maximum))
				uses[item] = values
	sync(inventory)
