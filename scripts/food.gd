extends RefCounted
const Catalog = preload("res://scripts/crop_catalog.gd")
const Art = preload("res://scripts/sprite_art.gd")
const COOLDOWN := 3.0
const FOODS := {"Corn":15,"Carrot":8,"Potato":5,"Tomato":10,"Roasted Corn":30,"Baked Potato":25,"Tomato Soup":35,"Bread":30,"Vegetable Stew":50}
var textures := {}
var sheet: Texture2D
func edible(item: String) -> bool: return FOODS.has(item)
func has_icon(item: String) -> bool: return item in Catalog.ITEMS or item == "Corn Seed"
func description(item: String) -> String:
	if edible(item): return "%s ? Restores %d HP" % [item, int(FOODS[item])]
	if Catalog.SEEDS.has(item): return item + " ? Plant in tilled soil"
	return "Wheat ? Cook into bread at a furnace"
func best_food(inventory: Dictionary, selected: String) -> String:
	if edible(selected) and int(inventory.get(selected,0))>0: return selected
	var best := ""
	for item: String in FOODS:
		if int(inventory.get(item,0))>0 and (best.is_empty() or int(FOODS[item])>int(FOODS[best])): best=item
	return best
func texture_for(item: String) -> Texture2D:
	if textures.has(item): return textures[item]
	if sheet == null: sheet=Art.texture("res://assets/sprites/farming/farm_items.png")
	var index := Catalog.ITEMS.find("Crop Seeds" if item == "Corn Seed" else item)
	var texture := AtlasTexture.new()
	texture.atlas=sheet
	texture.region=Rect2(maxi(0,index)*32,0,32,32)
	textures[item]=texture
	return texture
