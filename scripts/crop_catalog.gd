extends RefCounted
const CROPS := {
	"Corn":{"seed":"Crop Seeds","seconds":150.0,"yield_min":2,"yield_max":4,"row":0},
	"Carrot":{"seed":"Carrot Seeds","seconds":90.0,"yield_min":2,"yield_max":4,"row":1},
	"Potato":{"seed":"Seed Potato","seconds":110.0,"yield_min":2,"yield_max":4,"row":2},
	"Tomato":{"seed":"Tomato Seeds","seconds":140.0,"yield_min":2,"yield_max":4,"row":3},
	"Wheat":{"seed":"Wheat Seeds","seconds":120.0,"yield_min":2,"yield_max":4,"row":4}}
const SEEDS := {"Crop Seeds":"Corn","Corn Seed":"Corn","Carrot Seeds":"Carrot","Seed Potato":"Potato","Tomato Seeds":"Tomato","Wheat Seeds":"Wheat"}
const ITEMS := ["Corn","Carrot","Potato","Tomato","Wheat","Crop Seeds","Carrot Seeds","Seed Potato","Tomato Seeds","Wheat Seeds","Roasted Corn","Baked Potato","Tomato Soup","Bread","Vegetable Stew"]
const NEW_ITEMS := ["Carrot", "Potato", "Tomato", "Wheat", "Carrot Seeds", "Seed Potato", "Tomato Seeds", "Wheat Seeds", "Baked Potato", "Tomato Soup", "Bread", "Vegetable Stew"]
const FORAGE := {"meadow_grass":"Crop Seeds","reeds":"Crop Seeds","wildflower":"Carrot Seeds","fern":"Seed Potato","broadleaf":"Seed Potato","berry_shrub":"Tomato Seeds","leafy_bush":"Tomato Seeds","dry_grass":"Wheat Seeds","tumbleweed":"Wheat Seeds"}
static func seed_for(crop: String) -> String:return str(CROPS.get(crop,CROPS.Corn).seed)
