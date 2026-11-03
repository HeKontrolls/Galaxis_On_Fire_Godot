extends RefCounted
const WG = preload("res://scripts/world_gen.gd")
const Catalog = preload("res://scripts/crop_catalog.gd")
const FARM_IDS := [12,13,14,15,16]
const DRY_SECONDS := 180.0
var world := {}
var columns := {}
var plants := {}
var moisture := {}
var budget := 0.0
var rng := RandomNumberGenerator.new()
var sky_cache := {}

static func key(tile: Vector2i) -> String:return "%d,%d" % [tile.x,tile.y]
func bind_world(data: Dictionary) -> void:
	world=data;columns.clear();sky_cache.clear();world["crops"]={}
	plants=world.get("farm_plants",{});moisture=world.get("farm_moisture",{})
	world["farm_plants"]=plants;world["farm_moisture"]=moisture
	var grid:PackedByteArray=world.tiles
	for index in range(grid.size()):
		if grid[index] in FARM_IDS:track(Vector2i(index%WG.WIDTH,int(index/WG.WIDTH)),grid[index])
	for point:String in plants.keys():
		var pair:=point.split(",");var tile:=Vector2i(int(pair[0]),int(pair[1]))
		if WG.tile_at(grid,tile.x,tile.y) not in [14,15,16]:plants.erase(point)
	for point:String in moisture.keys():
		var pair:=point.split(",");var tile:=Vector2i(int(pair[0]),int(pair[1]))
		if WG.tile_at(grid,tile.x,tile.y) not in [12,13]:moisture.erase(point)
	rng.seed=int(world.seed)^0xFA11DE
	if str(world.get("farm_rng_state","")).is_valid_int():rng.state=int(world.farm_rng_state)
	budget=clampf(float(world.get("farm_budget",0.0)),0,1)
func track(tile: Vector2i,id: int) -> void:
	var cells:Array=columns.get(tile.x,[])
	if id in FARM_IDS:
		if not cells.has(tile.y):cells.append(tile.y);cells.sort()
		columns[tile.x]=cells
	else:
		cells.erase(tile.y)
		if cells.is_empty():columns.erase(tile.x)
	var point:=key(tile)
	if id in [14,15,16]:
		world.crops[point]=id
		if not plants.has(point):plants[point]={"crop":"Corn","progress":0.0 if id==14 else (0.5 if id==15 else 1.0),"stage":id,"status":"Growing","rate":1.0}
		var plant:Dictionary=plants[point]
		if id==16:plant.progress=1.0
		elif id==15:plant.progress=maxf(float(plant.progress),0.4)
		elif int(plant.get("stage",14))>14:plant.progress=0.0
		plant.stage=id
	else:
		world.crops.erase(point);plants.erase(point)
	if id in [12,13]:
		if not moisture.has(point):moisture[point]=1.0 if id==13 else 0.0
		elif id==13 and float(moisture[point])<=0.2:moisture[point]=1.0
	else:moisture.erase(point)
	sky_cache.erase(tile.x)
func geometry_changed(tile: Vector2i) -> void:sky_cache.erase(tile.x)
func plant_target(tile: Vector2i) -> Vector2i:
	var grid:PackedByteArray=world.tiles
	var id:=WG.tile_at(grid,tile.x,tile.y)
	if id in [12,13] and WG.tile_at(grid,tile.x,tile.y-1) in [14,15,16]:return tile+Vector2i.UP
	if id not in [0,14,15,16]:return Vector2i(-1,-1)
	for dy in range(3):
		var at:=tile+Vector2i(0,dy);var here:=WG.tile_at(grid,at.x,at.y)
		if here in [14,15,16]:return at
		if here!=0:break
	return Vector2i(-1,-1)
func crop_at(tile: Vector2i) -> String:return str(plants.get(key(tile),{}).get("crop","Corn"))
func commit(result: Dictionary) -> void:
	var planting:Dictionary=result.get("plant",{})
	if not planting.is_empty():
		plants[str(planting.key)]={"crop":str(planting.crop),"progress":0.0,"stage":14,"status":"Growing","rate":1.0}
	var watered:String=str(result.get("watered",""))
	if not watered.is_empty():moisture[watered]=1.0
func interaction(tile: Vector2i,tool: String,selected: String) -> Dictionary:
	var result:={"handled":false,"edits":[],"consume":"","drops":{}}
	if tile.x<0 or tile.x>=WG.WIDTH or tile.y<1 or tile.y>=WG.HEIGHT-1:return result
	var grid:PackedByteArray=world.tiles;var id:=WG.tile_at(grid,tile.x,tile.y)
	if id==16:
		var crop:=crop_at(tile);var definition:Dictionary=Catalog.CROPS[crop]
		result.handled=true;result.edits=[Vector3i(tile.x,tile.y,0)]
		result.drops={crop:rng.randi_range(int(definition.yield_min),int(definition.yield_max)),str(definition.seed):rng.randi_range(1,3)}
	elif id in [14,15] and tool=="Hoe":
		result.handled=true;result.edits=[Vector3i(tile.x,tile.y,0)];result.drops={Catalog.seed_for(crop_at(tile)):1}
	elif tool=="Hoe" and id in [1,2]:
		result.handled=true
		if WG.tile_at(grid,tile.x,tile.y-1)==0:result.edits=[Vector3i(tile.x,tile.y,12)]
	elif tool=="Watering Can" and id in [12,13]:
		result.handled=true;result.watered=key(tile)
		if id==12:result.edits=[Vector3i(tile.x,tile.y,13)]
	elif Catalog.SEEDS.has(selected):
		result.handled=true
		var py:=tile.y-1 if id in [12,13] else tile.y
		if py>0 and WG.tile_at(grid,tile.x,py)==0 and WG.tile_at(grid,tile.x,py+1) in [12,13]:
			result.consume=selected;result.edits=[Vector3i(tile.x,py,14)];result.plant={"key":key(Vector2i(tile.x,py)),"crop":Catalog.SEEDS[selected]}
	world.farm_rng_state=str(rng.state)
	return result
func unsupported(tile: Vector2i,new_id: int) -> Dictionary:
	if new_id in [12,13] or tile.y<1:return {}
	var above:=tile+Vector2i.UP
	if WG.tile_at(world.tiles,above.x,above.y) in [14,15,16]:return {"tile":above,"seed":Catalog.seed_for(crop_at(above))}
	return {}
func _roof(x: int,roof: PackedInt32Array) -> int:
	if roof.size()==WG.WIDTH:return roof[x]
	if not sky_cache.has(x):
		var top:=WG.HEIGHT-1
		for y in range(WG.HEIGHT):
			if WG.is_solid(WG.tile_at(world.tiles,x,y)):top=y;break
		sky_cache[x]=top
	return int(sky_cache[x])
func irrigated(tile: Vector2i,water: PackedByteArray) -> bool:
	if water.size()!=WG.WIDTH*WG.HEIGHT:return false
	for direction in [-1,1]:
		for step in range(5):
			var x:int=tile.x+direction*step
			if x<0 or x>=WG.WIDTH:break
			for y in [tile.y-1,tile.y]:
				if water[y*WG.WIDTH+x]>=48:return true
			if step>0 and WG.tile_at(world.tiles,x,tile.y) in [3,9,10,17,27,33,46]:break
	return false
func _lamp(tile: Vector2i) -> bool:
	for point:String in world.get("torches",{}):
		var pair:=point.split(",");var at:=Vector2i(int(pair[0]),int(pair[1]))
		if (at-tile).length()<=6 and _light_path(tile,at):return true
	for entry:Dictionary in world.get("furniture",{}).values():
		if str(entry.get("item",""))!="Fireplace" or not bool(entry.get("lit",false)):continue
		var at:=Vector2i(int(entry.x)+1,int(entry.y)-1)
		if (at-tile).length()<=6 and _light_path(tile,at):return true
	return false
func _light_path(a: Vector2i,b: Vector2i) -> bool:
	var steps:=maxi(absi(b.x-a.x),absi(b.y-a.y))
	for i in range(1,steps):
		var at:=Vector2i(Vector2(a).lerp(Vector2(b),float(i)/steps).round())
		if WG.is_solid(WG.tile_at(world.tiles,at.x,at.y)):return false
	return true
func growth_rate(tile: Vector2i,roof: PackedInt32Array,sun: float) -> Dictionary:
	var exposed:=_roof(tile.x,roof)>=tile.y+1
	if not exposed:
		if _lamp(tile):return {"rate":1.0,"status":"Lamplit growing area"}
		return {"rate":0.0,"status":"Needs a nearby torch or lit fireplace"}
	if int(world.climate) in [4,5,6]:return {"rate":0.0,"status":"Harsh climate: grow under a lit roof"}
	if sun<=0.05:return {"rate":0.0,"status":"Waiting for daylight"}
	return {"rate":0.65 if int(world.climate)==3 else 1.0,"status":"Growing"}
func advance(_center_x: int,delta: float,raining: bool,roof: PackedInt32Array,water: PackedByteArray,rain_intensity:=1.0,sun:=1.0) -> Array[Vector3i]:
	var edits:Array[Vector3i]=[]
	budget+=maxf(0,delta);world.farm_budget=budget
	if columns.is_empty():budget=0;world.farm_budget=0;return edits
	if budget<1:return edits
	var dt:=budget;budget=0;world.farm_budget=0
	var updates:={};var grid:PackedByteArray=world.tiles
	for x in columns:
		for y:int in columns[x]:
			if WG.tile_at(grid,int(x),y) not in [12,13]:continue
			var cell:=Vector2i(int(x),y);var point:=key(cell)
			var old:=float(moisture.get(point,0.0))
			var wet:=irrigated(cell,water) or (raining and rain_intensity>0.05 and _roof(int(x),roof)==y)
			var current:=1.0 if wet else maxf(0,old-dt/DRY_SECONDS)
			moisture[point]=current
			var soil_id:=13 if current>0.2 else 12
			if grid[y*WG.WIDTH+int(x)]!=soil_id:updates[cell]=soil_id
			var crop_cell:=cell+Vector2i.UP;var crop_key:=key(crop_cell)
			if not plants.has(crop_key) or WG.tile_at(grid,crop_cell.x,crop_cell.y) not in [14,15,16]:continue
			var plant:Dictionary=plants[crop_key]
			if float(plant.progress)>=1:plant.status="Ready to harvest";continue
			var condition:=growth_rate(crop_cell,roof,sun);plant.status=condition.status;plant.rate=condition.rate
			var watered_time:=dt if wet else minf(dt,maxf(0,(old-0.2)*DRY_SECONDS))
			var work:float=(watered_time+(dt-watered_time)*0.25)*float(condition.rate)
			plant.progress=minf(1,float(plant.progress)+work/float(Catalog.CROPS[str(plant.crop)].seconds))
			var stage:=16 if float(plant.progress)>=1 else (15 if float(plant.progress)>=0.4 else 14)
			if stage!=WG.tile_at(grid,crop_cell.x,crop_cell.y):updates[crop_cell]=stage
	for cell:Vector2i in updates:edits.append(Vector3i(cell.x,cell.y,int(updates[cell])))
	return edits
func hint(tile: Vector2i,selected: String) -> PackedStringArray:
	var grid:PackedByteArray=world.tiles;var id:=WG.tile_at(grid,tile.x,tile.y)
	if id in [14,15,16]:
		var plant:Dictionary=plants.get(key(tile),{});var crop:=crop_at(tile)
		if id==16:return [crop+" · Ready to harvest","Click for produce and fresh planting stock"]
		var wet:=WG.tile_at(grid,tile.x,tile.y+1)==13
		var status:=str(plant.get("status","Growing"))
		var rate:=float(plant.get("rate",1.0))*(1.0 if wet else 0.25)
		var remaining:=ceili((1-float(plant.get("progress",0.0)))*float(Catalog.CROPS[crop].seconds)/maxf(rate,0.01))
		var progress:=roundi(float(plant.get("progress",0.0))*100)
		return ["%s · %s · %d%%" % [crop,"Sprout" if id==14 else "Growing",progress],("Watered · " if wet else "Dry · ")+("~%d:%02d remaining" % [remaining/60,remaining%60] if rate>0 else status)]
	if id in [12,13]:return ["Tilled soil · "+("Watered" if id==13 else "Dry"),"Right-click to plant "+str(Catalog.SEEDS[selected]) if Catalog.SEEDS.has(selected) else "Select seeds; water or irrigate the row"]
	if id==0 and Catalog.SEEDS.has(selected) and WG.tile_at(grid,tile.x,tile.y+1) in [12,13]:return ["Plant "+str(Catalog.SEEDS[selected]),"Right-click · Uses one planting item"]
	return []
