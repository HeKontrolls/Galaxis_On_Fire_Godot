extends RefCounted
const WG = preload("res://scripts/world_gen.gd")
const Art = preload("res://scripts/sprite_art.gd")
const ITEMS := ["Wooden Chair", "Wooden Table", "Wooden Ladder", "Fireplace", "Wooden Wall", "Wooden Door"]
const ART := {"Wooden Chair":"chair", "Wooden Table":"table", "Wooden Ladder":"ladder", "Fireplace":"fireplace", "Wooden Wall":"wood_background", "Wooden Door":"door"}
const SIZES := {"Wooden Chair":Vector2i(1,2), "Wooden Table":Vector2i(3,2), "Wooden Ladder":Vector2i(1,1), "Fireplace":Vector2i(3,3), "Wooden Door":Vector2i(1,3)}
var entries := {}
var walls := {}
var occupied := {}
var textures := {}
var wall_images := {}
var climbing := false
var jump_lock := 0.0
var wet_clock := 0.0
var door_motion := {}

static func key(cell: Vector2i) -> String: return "%d,%d" % [cell.x,cell.y]
static func has_item(item: String) -> bool: return item in ITEMS
static func description(item: String) -> String:
	if item=="Wooden Door":return "F: open/close | Blocks passage when closed"
	if item=="Wooden Ladder":return "W/S: climb | Space: jump off"
	if item=="Wooden Wall":return "Background wall | Hammer/Mattock to remove"
	if item=="Fireplace":return "F: light/extinguish | Water puts out the fire"
	return "Passable furnishing | Place on solid ground"
func texture(item: String) -> Texture2D:
	if not textures.has(item): textures[item] = Art.texture("res://assets/sprites/housing/" + ART[item] + ".png")
	return textures[item]
func size(item: String) -> Vector2i: return SIZES.get(item,Vector2i.ONE)
func rect(item: String, cell: Vector2i) -> Rect2i:
	var shape := size(item)
	return Rect2i(cell-Vector2i(0,shape.y-1),shape)
func entry_rect(entry: Dictionary) -> Rect2:
	var bounds:=rect(str(entry.item),Vector2i(int(entry.x),int(entry.y)))
	return Rect2(Vector2(bounds.position*16),Vector2(bounds.size*16))
func _index(origin: String, entry: Dictionary) -> void:
	var bounds:=rect(str(entry.item),Vector2i(int(entry.x),int(entry.y)))
	for y in range(bounds.position.y,bounds.end.y):
		for x in range(bounds.position.x,bounds.end.x): occupied[Vector2i(x,y)]=origin
func reset(game) -> void:
	entries=game.world.get("furniture",{});walls=game.world.get("wood_background",{})
	game.world["furniture"]=entries;game.world["wood_background"]=walls
	occupied.clear();door_motion.clear();climbing=false;jump_lock=0;wet_clock=0
	for origin: String in entries: _index(origin,entries[origin])
	refresh_lights(game)
func wall_at(cell: Vector2i) -> bool: return walls.has(key(cell))
func wall_image(cell: Vector2i) -> Image:
	var variant:=posmod(cell.x*7+cell.y*13,4)
	if not wall_images.has(variant): wall_images[variant]=texture("Wooden Wall").get_image().get_region(Rect2i(variant*16,0,16,16))
	return wall_images[variant]
func at(cell: Vector2i) -> Dictionary: return entries.get(occupied.get(cell,""),{})
func _supported(game,item: String,cell: Vector2i) -> bool:
	if item=="Wooden Ladder": return true
	for x in range(cell.x,cell.x+size(item).x):
		if not WG.is_solid(WG.tile_at(game.world.tiles,x,cell.y+1)): return false
	return true
func can_place(game,item: String,cell: Vector2i) -> bool:
	if cell.x<1 or cell.y<1 or cell.x>=WG.WIDTH-1 or cell.y>=WG.HEIGHT-1: return false
	if item=="Wooden Wall": return not wall_at(cell)
	var bounds:=rect(item,cell)
	if bounds.position.x<1 or bounds.position.y<1 or bounds.end.x>=WG.WIDTH-1 or bounds.end.y>=WG.HEIGHT-1: return false
	for y in range(bounds.position.y,bounds.end.y):
		for x in range(bounds.position.x,bounds.end.x):
			var tile:=Vector2i(x,y)
			if WG.tile_at(game.world.tiles,x,y) not in [0,4] or occupied.has(tile) or game.world.get("torches",{}).has(key(tile)): return false
	if item=="Wooden Ladder":
		if wall_at(cell): return true
		for offset: Vector2i in [Vector2i.UP,Vector2i.DOWN,Vector2i.LEFT,Vector2i.RIGHT]:
			if WG.is_solid(WG.tile_at(game.world.tiles,cell.x+offset.x,cell.y+offset.y)) or str(at(cell+offset).get("item",""))=="Wooden Ladder": return true
		return false
	if item=="Wooden Door" and not _door_clear(game,Rect2(Vector2(bounds.position*16),Vector2(bounds.size*16))):return false
	return _supported(game,item,cell)
func place(game,item: String,cell: Vector2i) -> bool:
	if not has_item(item): return false
	if not can_place(game,item,cell):
		game._show_notice("Choose clear space and solid ground" if item!="Wooden Ladder" else "Attach the ladder to a wall, ground or another ladder")
		return false
	if item=="Wooden Wall":
		walls[key(cell)]=true;game.terrain_cache.invalidate(cell)
	else:
		var entry: Dictionary={"item":item,"x":cell.x,"y":cell.y,"facing":game.facing,"lit":item=="Fireplace","work":0.0}
		entries[key(cell)]=entry;_index(key(cell),entry)
		if item=="Fireplace" and _wet(game,entry): entry.lit=false
		if item=="Wooden Door":
			entry["open"]=true
			if not set_door_open(game,entry,false,false):
				for y in range(rect(item,cell).position.y,cell.y+1):occupied.erase(Vector2i(cell.x,y))
				entries.erase(key(cell));return false
	refresh_lights(game)
	game._show_notice("Placed "+item)
	return true
func _remove(game,origin: String) -> void:
	if not entries.has(origin): return
	var entry: Dictionary=entries[origin]
	var bounds:=rect(str(entry.item),Vector2i(int(entry.x),int(entry.y)))
	for y in range(bounds.position.y,bounds.end.y):
		for x in range(bounds.position.x,bounds.end.x):occupied.erase(Vector2i(x,y))
	entries.erase(origin)
	door_motion.erase(origin)
	if entry.item=="Wooden Door":
		for y in range(bounds.position.y,bounds.end.y):
			if WG.tile_at(game.world.tiles,bounds.position.x,y)==46:game._edit_tile(Vector2i(bounds.position.x,y),0,false)
		game.world_texture.update(game.world_image)
	game._drop_item(str(entry.item),1,Vector2i(int(entry.x),int(entry.y)))
	refresh_lights(game)
func harvest(game,cell: Vector2i) -> bool:
	if WG.tile_at(game.world.tiles,cell.x,cell.y) not in [0,4,11,46]: return false
	var entry:=at(cell)
	var wall:bool=wall_at(cell) and game.equipped_tool in ["Hammer","Mattock"]
	if entry.is_empty() and not wall: return false
	if game.mining_cooldown>0: return true
	if not game.interactions._visible(game.player_pos+Vector2(8,14),Rect2(Vector2(cell*16),Vector2(16,16))): return true
	game.mining_cooldown=game.Tools.MINING_SWING
	if wall and entry.is_empty():
		walls.erase(key(cell));game.terrain_cache.invalidate(cell);game._drop_item("Wooden Wall",1,cell)
	else:
		var material:=3 if entry.item=="Fireplace" else 9
		var power:float=game.Tools.mining_damage(game.equipped_tool,material)
		entry.work=float(entry.get("work",0.0))+power/game.Tools.block_hardness(material)
		if entry.work>=0.99999: _remove(game,str(occupied[cell]))
	if game.sound!=null: game.sound.impact(3 if str(entry.get("item",""))=="Fireplace" else 9,Vector2(cell*16)+Vector2(8,8))
	return true
func terrain_changed(game,cell: Vector2i) -> void:
	for origin: String in entries.keys():
		var entry:Dictionary=entries[origin]
		var pos:=Vector2i(int(entry.x),int(entry.y))
		var bounds:=rect(str(entry.item),pos)
		if bounds.has_point(cell) and WG.is_solid(WG.tile_at(game.world.tiles,cell.x,cell.y)) and not (entry.item=="Wooden Door" and WG.tile_at(game.world.tiles,cell.x,cell.y)==46):
			_remove(game,origin)
		elif cell.y==pos.y+1 and cell.x>=pos.x and cell.x<bounds.end.x and not _supported(game,str(entry.item),pos):
			_remove(game,origin)
func _door_clear(game,bounds: Rect2) -> bool:
	if bounds.intersects(game._player_rect(game.player_pos)):return false
	var npc:Dictionary=game.world.get("npc",{})
	if npc.has("x") and bounds.intersects(Rect2(float(npc.x),float(npc.y),12,29)):return false
	for creature:Dictionary in game.world.get("creatures",[]):
		if bool(creature.get("alive",false)) and bounds.intersects(Rect2(float(creature.x),float(creature.y),24,18)):return false
	for animal:Dictionary in game.ground_life.visible(game):
		if game.GroundLife.animal(str(animal.species)) and bounds.intersects(Rect2(game.ground_life.position(animal)-Vector2(7,12),Vector2(14,12))):return false
	return true
func set_door_open(game,entry: Dictionary,opened: bool,animate:=true) -> bool:
	if entry.item!="Wooden Door":return false
	if bool(entry.get("open",false))==opened:return true
	var cell:=Vector2i(int(entry.x),int(entry.y))
	var bounds:=rect("Wooden Door",cell)
	if not opened:
		if not _door_clear(game,entry_rect(entry)):
			game._show_notice("The doorway is occupied");return false
		# Reserve the entire doorway before displacing fluid. Otherwise one
		# segment could push water into another segment about to be closed.
		var grid:PackedByteArray=game.world.tiles
		var original:={}
		for y in range(bounds.position.y,bounds.end.y):
			original[y]=WG.tile_at(grid,cell.x,y);WG.set_tile(grid,cell.x,y,46)
		game.world.tiles=grid
		var room:=true
		for y in range(bounds.position.y,bounds.end.y):
			if not game.water_sim.displace(Vector2i(cell.x,y)) or not game.lava_sim.displace(Vector2i(cell.x,y)):
				room=false;break
		if not room:
			grid=game.world.tiles
			for y in original:WG.set_tile(grid,cell.x,int(y),int(original[y]))
			game.world.tiles=grid
			game._update_water(0)
			game._show_notice("The liquid needs room before this door can close")
			return false
	for y in range(bounds.position.y,bounds.end.y):game._edit_tile(Vector2i(cell.x,y),0 if opened else 46,false)
	entry["open"]=opened
	game.world_texture.update(game.world_image)
	game.environment.invalidate()
	game._update_water(0)
	if animate:door_motion[key(cell)]={"start":game.animation_clock,"opening":opened}
	game._show_notice("Door opened" if opened else "Door closed")
	return true
func _door_frame(game,entry: Dictionary) -> int:
	var motion:Dictionary=door_motion.get(key(Vector2i(int(entry.x),int(entry.y))),{})
	if motion.is_empty():return 3 if bool(entry.get("open",false)) else 0
	var elapsed:float=maxf(0,game.animation_clock-float(motion.start))
	if elapsed>=0.18:return 3 if bool(entry.get("open",false)) else 0
	var pose:=mini(2,int(elapsed/0.06))
	return 1+pose if bool(motion.opening) else 2-pose
func _wet(game,entry: Dictionary) -> bool:
	var hearth:=entry_rect(entry).grow(-8)
	return game.water_sim.intersects(hearth) or game.lava_sim.intersects(hearth)
func refresh_lights(game) -> void:
	var lights:=[]
	for entry:Dictionary in entries.values():
		if str(entry.item)=="Fireplace" and bool(entry.get("lit",false)): lights.append(Vector2i(int(entry.x)+1,int(entry.y)-1))
	game.world["furniture_lights"]=lights
	game.environment.invalidate()
func target(game) -> Dictionary:
	var nearest:Dictionary={};var best:=INF
	var mouse:Vector2=game.mouse_aim_screen+game.camera_pos if game.mouse_aim_valid else game.get_viewport().get_mouse_position()+game.camera_pos
	for entry:Dictionary in entries.values():
		if entry.item not in ["Fireplace","Wooden Door"]:continue
		var bounds:=entry_rect(entry)
		var distance:float=(game.player_pos+Vector2(8,14)).distance_to(bounds.get_center())
		var score:float=distance-(128 if bounds.has_point(mouse) else 0)
		if distance<=game.DIG_REACH and score<best and game.interactions._visible(game.player_pos+Vector2(8,14),bounds):nearest=entry;best=score
	return nearest
func aimed(game) -> bool:
	var entry:=target(game)
	var mouse:Vector2=game.mouse_aim_screen+game.camera_pos if game.mouse_aim_valid else game.get_viewport().get_mouse_position()+game.camera_pos
	return not entry.is_empty() and entry_rect(entry).has_point(mouse)
func interact(game) -> bool:
	var entry:=target(game)
	if entry.is_empty():return false
	game._stop_held_actions()
	if entry.item=="Wooden Door":
		set_door_open(game,entry,not bool(entry.get("open",false)))
		return true
	if _wet(game,entry):game._show_notice("The fireplace is wet");return true
	entry.lit=not bool(entry.get("lit",false));refresh_lights(game)
	game._show_notice("Fireplace lit" if entry.lit else "Fireplace extinguished")
	return true
func update(game,delta: float) -> void:
	wet_clock+=delta
	if wet_clock<0.25:return
	wet_clock=fmod(wet_clock,0.25)
	var changed:=false
	for entry:Dictionary in entries.values():
		if entry.item=="Fireplace" and bool(entry.get("lit",false)) and _wet(game,entry):entry.lit=false;changed=true
	if changed:refresh_lights(game)
func climb(game,delta: float,movement: float,up: bool,down: bool,jump: bool) -> bool:
	jump_lock=maxf(0,jump_lock-delta)
	if jump and climbing:
		climbing=false;jump_lock=0.25;game.player_velocity.y=-330;game.player_grounded=false
		return false
	var body:Rect2=game._player_rect(game.player_pos)
	var ladder:=Vector2i(-1,-1)
	for y in range(floori(body.position.y/16),floori((body.end.y-0.01)/16)+1):
		for x in range(floori(body.position.x/16),floori((body.end.x-0.01)/16)+1):
			if str(at(Vector2i(x,y)).get("item",""))=="Wooden Ladder":ladder=Vector2i(x,y)
	if ladder.x<0 or jump or jump_lock>0 or (not climbing and not up and not down):climbing=false;return false
	climbing=true
	if movement!=0:game.facing=int(signf(movement))
	game._move_axis(movement*game.SPEED*delta,true)
	if movement==0:game._move_axis(move_toward(game.player_pos.x,ladder.x*16.0,120*delta)-game.player_pos.x,true)
	game.player_velocity=Vector2(0,(float(down)-float(up))*105)
	game._move_axis(game.player_velocity.y*delta,false)
	game.player_grounded=false
	game.player_pos=game.player_pos.clamp(Vector2.ZERO,Vector2(WG.WIDTH*16-16,WG.HEIGHT*16-28))
	game._update_lava_damage(delta)
	return true
func draw(game) -> void:
	var view:=Rect2(game.camera_pos-Vector2(48,48),Vector2(1376,816))
	for entry:Dictionary in entries.values():
		var bounds:=entry_rect(entry)
		if not view.intersects(bounds):continue
		var frame:=1+posmod(int(game.animation_clock/0.16),4) if entry.item=="Fireplace" and bool(entry.get("lit",false)) else 0
		var sprite:=texture(str(entry.item))
		var shape:=size(str(entry.item))*16
		var offset:=Vector2.ZERO
		if entry.item=="Wooden Door":
			shape=Vector2i(32,48);offset=Vector2(-8,0);frame=_door_frame(game,entry)
		var dest:=Rect2((bounds.position-game.camera_pos+offset).round(),Vector2(shape))
		if entry.item in ["Wooden Chair","Wooden Door"] and int(entry.get("facing",1))<0:
			game.draw_set_transform(dest.position+Vector2(dest.size.x,0),0,Vector2(-1,1))
			game.draw_texture_rect_region(sprite,Rect2(Vector2.ZERO,dest.size),Rect2(frame*shape.x,0,shape.x,shape.y))
			game.draw_set_transform(Vector2.ZERO)
		else:
			game.draw_texture_rect_region(sprite,dest,Rect2(frame*shape.x,0,shape.x,shape.y))
func draw_icon(game,item: String,bounds: Rect2) -> void:
	var pixels:=Vector2(16,16) if item=="Wooden Wall" else Vector2(size(item)*16)
	if item=="Wooden Door":pixels=Vector2(32,48)
	var scale:=minf(bounds.size.x/pixels.x,bounds.size.y/pixels.y)
	var dest:=Rect2(bounds.get_center()-pixels*scale*0.5,pixels*scale)
	game.draw_texture_rect_region(texture(item),dest,Rect2(Vector2.ZERO,pixels))
func draw_hint(game) -> void:
	if game.paused or game.inventory_open or game.crafting_open or game.dev_mode or game.dialogue_open or game.stations.is_open():return
	if not game.interactions.target().is_empty() and not aimed(game):return
	var entry:=target(game)
	if entry.is_empty():return
	var text:="F: Extinguish fireplace" if bool(entry.get("lit",false)) else "F: Light fireplace"
	if entry.item=="Wooden Door":text="F: Close door" if bool(entry.get("open",false)) else "F: Open door"
	var at:Vector2=entry_rect(entry).position-game.camera_pos+Vector2(-48,-25)
	game._rounded_box(Rect2(at,Vector2(190,24)),Color("14212b"),Color("bda77a"),5)
	game._button_text(Rect2(at,Vector2(190,24)),text,12)
