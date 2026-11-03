extends RefCounted

const PER_PAGE := 9
const PAGES := 6
const SIZE := PER_PAGE * PAGES
var slots: Array[String] = []


func _init() -> void:
	clear()


func clear() -> void:
	slots.resize(SIZE)
	slots.fill("")


func add(item: String, inventory: Dictionary) -> int:
	if item.is_empty() or int(inventory.get(item, 0)) <= 0:
		return -1
	var existing := slots.find(item)
	if existing >= 0:
		return existing
	var free := slots.find("")
	if free >= 0:
		slots[free] = item
	return free


func assign(item: String, target: int, inventory: Dictionary) -> bool:
	if target < 0 or target >= SIZE or item.is_empty() or int(inventory.get(item, 0)) <= 0:
		return false
	var source := slots.find(item)
	if source >= 0 and source != target:
		slots[source] = slots[target]
	slots[target] = item
	return true


func remove(index: int) -> void:
	if index >= 0 and index < SIZE:
		slots[index] = ""


func prune(inventory: Dictionary) -> void:
	for index in range(SIZE):
		if int(inventory.get(slots[index], 0)) <= 0:
			slots[index] = ""


func restore(value: Variant, inventory: Dictionary) -> void:
	clear()
	if not value is Array:
		return
	for index in range(mini(SIZE, value.size())):
		var item: Variant = value[index]
		if not item is String:
			continue
		if item == "Corn Seed":
			item = "Crop Seeds"
		if not item.is_empty() and int(inventory.get(item, 0)) > 0 and not slots.has(item):
			slots[index] = item
