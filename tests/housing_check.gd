extends SceneTree
const WG=preload("res://scripts/world_gen.gd")
var failures:=0
func check(ok: bool,message: String) -> void:
	if not ok:failures+=1;printerr(message)
func _initialize() -> void:call_deferred("run")
func fixture(g) -> void:
	var grid:=PackedByteArray();grid.resize(WG.WIDTH*WG.HEIGHT)
	var surface:=PackedInt32Array();surface.resize(WG.WIDTH);surface.fill(80)
	for x in range(WG.WIDTH):WG.set_tile(grid,x,100,3)
	g.world={"tiles":grid,"surface":surface,"seed":712,"climate":0,"spawn":Vector2(600*16,1600-28),"creatures":[],"ground_life":[],"background_ores":[],
		"background_ore_version":1,"cave_life_version":1,"underground_version":1,"underworld_structures_version":1,"forest_density_version":2,
		"ground_life_version":1,"ground_cover_version":1,"surface_rocks_version":1,"desert_flora_version":1,"vines_version":1,"wildlife_version":1,"flyers_version":1}
	g.worlds.clear();g.worlds[g._world_key()]=g.world;g._reset_world_environment()
	g.world_texture=WG.make_texture(grid);g.world_image=g.world_texture.get_image()
	g.player_pos=g.world.spawn;g.player_velocity=Vector2.ZERO;g.player_grounded=true;g._update_camera()
	g.scene_name="planet";g.paused=false;g.dev_mode=false;g.dev_invulnerable=false;g.inventory_open=false;g.crafting_open=false;g.dialogue_open=false;g.stations.close()
	g.inventory={};g.health=100;g.mining_cooldown=0;g.hotbar.clear();g.place_items=g.hotbar.slots
func select(g,item: String,count:=1) -> void:
	g.inventory[item]=count
	var slot:int=g.hotbar.add(item,g.inventory);g._select_hotbar_slot(slot)
func place(g,item: String,cell: Vector2i,count:=1) -> void:
	select(g,item,count);g._place(Vector2(cell*16)+Vector2(8,8)-g.camera_pos)
func run() -> void:
	var g=load("res://main.tscn").instantiate();root.add_child(g);g.set_process(false);await g._open_planet(0);g.hide();g.sound.clips.clear()
	g.save_path="user://housing_check.json"
	fixture(g)
	place(g,"Wooden Chair",Vector2i(602,97))
	check(g.world.furniture.is_empty() and g.inventory["Wooden Chair"]==1,"Floating chair placement consumed an item")
	place(g,"Wooden Chair",Vector2i(602,99))
	check(g.world.furniture.size()==1 and g.inventory["Wooden Chair"]==0,"Chair placement failed")
	g._update_player_motion(0.1,1,false)
	check(g.player_pos.x>601*16,"Passable furniture blocks walking")
	g.player_pos=Vector2(604*16,1600-28);place(g,"Wooden Table",Vector2i(606,99))
	check(g.furnishings.at(Vector2i(608,98)).get("item","")=="Wooden Table","Table footprint is incomplete")
	var count:int=g.world.furniture.size();place(g,"Wooden Chair",Vector2i(607,99))
	check(g.world.furniture.size()==count and g.inventory["Wooden Chair"]==1,"Overlapping placement was accepted")
	g._edit_tile(Vector2i(607,100),0)
	check(g.furnishings.at(Vector2i(606,99)).is_empty() and g.world.drops.size()==1 and g.world.drops[0].item=="Wooden Table","Unsupported table did not return exactly one pickup")
	g._edit_tile(Vector2i(607,100),3)
	g.player_pos=Vector2(600*16,1600-28)
	place(g,"Wooden Wall",Vector2i(601,98))
	check(g.furnishings.wall_at(Vector2i(601,98)) and WG.tile_at(g.world.tiles,601,98)==0,"Background wall became a foreground block")
	check(not g._collides(Vector2(601*16,1600-28)),"Wooden background wall blocks the player")
	var image:Image=g.furnishings.wall_image(Vector2i(601,98))
	check(image.get_size()==Vector2i(16,16) and image.get_pixel(8,8).a==1,"Background wall image invalid")
	# Place a wall behind foreground rock, then clear the foreground independently.
	g._edit_tile(Vector2i(599,98),3);place(g,"Wooden Wall",Vector2i(599,98));g._edit_tile(Vector2i(599,98),0)
	check(g.furnishings.wall_at(Vector2i(599,98)),"Digging foreground removed its backing wall")
	g.inventory["Hammer"]=1;g._equip_inventory_item("Hammer");g.mining_cooldown=0
	g._mine(Vector2(599*16+8,98*16+8)-g.camera_pos)
	check(not g.furnishings.wall_at(Vector2i(599,98)) and g.world.drops[-1].item=="Wooden Wall","Hammer could not recover a background wall")
	# Ladders climb, hold, descend, jump off and stop at solid ceilings at several rates.
	for fps in [30,60,120]:
		fixture(g)
		check(not g.furnishings.can_place(g,"Wooden Ladder",Vector2i(600,90)),"Unsupported ladder should need an anchor")
		for y in range(99,91,-1):check(g.furnishings.place(g,"Wooden Ladder",Vector2i(600,y)),"Ladder segments cannot connect")
		var start:float=g.player_pos.y
		for frame in range(fps):check(g.furnishings.climb(g,1.0/fps,0,true,false,false),"Ladder ascent detached early")
		check(absf(g.player_pos.y-(start-105))<0.1,"Frame-dependent ladder speed")
		var held:float=g.player_pos.y
		g.furnishings.climb(g,0.1,0,false,false,false)
		check(is_equal_approx(g.player_pos.y,held),"Player slips while holding a ladder")
		g.furnishings.climb(g,0.2,0,false,true,false)
		check(g.player_pos.y>held,"Ladder descent does not work")
		check(not g.furnishings.climb(g,1.0/fps,0,false,false,true) and g.player_velocity.y<0,"Jump does not detach from ladder")
		g.player_pos=Vector2(600*16,1600-28);g.furnishings.jump_lock=0
		g._edit_tile(Vector2i(600,95),3)
		for frame in range(fps):g.furnishings.climb(g,1.0/fps,0,true,false,false)
		check(not g._collides(g.player_pos) and g.player_pos.y>=96*16,"Ladder climb passed through a ceiling")
	fixture(g);g.player_pos=Vector2(609*16,1600-28)
	for x in range(605,620):g._edit_tile(Vector2i(x,95),3)
	place(g,"Fireplace",Vector2i(611,99))
	check(g.world.furniture.get("611,99",{}).get("lit",false),"Fireplace not lit on dry ground")
	g.environment.prepare(Vector2(595*16,88*16),g.player_pos,0,1,0)
	var at:=Vector2(612*16+8,98*16+8)
	var bright:float=g.environment.brightness_at(at)
	check(bright>0.95,"Fireplace does not light its room")
	# A nearby workbench must not steal F when the mouse points at the hearth.
	g._edit_tile(Vector2i(609,99),34);g._edit_tile(Vector2i(610,99),36)
	g.mouse_aim_screen=at-g.camera_pos;g.mouse_aim_valid=true;g._key_pressed(KEY_F)
	check(not g.world.furniture["611,99"].lit and not g.stations.is_open(),"Fireplace F interaction lost to a nearby station")
	g.environment.prepare(Vector2(595*16,88*16),g.player_pos,0,1,1)
	check(g.environment.brightness_at(at)<bright-0.4,"Extinguished fireplace still emits light")
	g._key_pressed(KEY_F);check(g.world.furniture["611,99"].lit,"Cannot relight fireplace")
	g._edit_tile(Vector2i(612,98),4);g.furnishings.update(g,0.3)
	check(not g.world.furniture["611,99"].lit,"Water does not extinguish fireplace")
	g._key_pressed(KEY_F);check(not g.world.furniture["611,99"].lit,"Wet fireplace can be lit")
	g._edit_tile(Vector2i(612,98),0);g._key_pressed(KEY_F)
	# All five recipes craft through the actual Workbench input/output inventory.
	for item:String in g.Furnishings.ITEMS:
		var index:=-1
		for i in range(g.RECIPES.size()):
			if g.RECIPES[i].out==item:index=i
		check(index>=0,"Missing furnishing recipe")
		var recipe:Dictionary=g.RECIPES[index]
		g.stations.open({"name":"Workbench","tile":Vector2i(609,99)})
		for ingredient:String in recipe.needs:
			g.inventory[ingredient]=int(recipe.needs[ingredient]);g.stations.deposit(ingredient,int(recipe.needs[ingredient]))
		check(g.stations.craft(index),"Workbench cannot craft "+item)
		g.stations.withdraw("output",0);g.stations.close()
		check(g.inventory.get(item,0)>=int(recipe.count),"Furnishing output not collectible")
	# Walls, furniture state and ownership survive actual save/load.
	place(g,"Wooden Wall",Vector2i(608,98));g.furnishings.place(g,"Wooden Ladder",Vector2i(608,98))
	var before_furniture:Dictionary=g.world.furniture.duplicate(true);var before_walls:Dictionary=g.world.wood_background.duplicate(true)
	g._save_game();g._load_game();while g.scene_name=="loading":await process_frame
	check(g.world.furniture.size()==before_furniture.size() and g.world.wood_background==before_walls,"Save/load lost house pieces")
	check(g.world.furniture["611,99"].lit==before_furniture["611,99"].lit,"Fireplace state lost on save")
	check(g.furnishings.at(Vector2i(608,98)).get("item","")=="Wooden Ladder","Ladder index was not restored")
	# Ordinary mining recovers one complete furniture item, independent of size.
	g.player_pos=Vector2(609*16,1600-28);g.inventory["Iron Pickaxe"]=1;g._equip_inventory_item("Iron Pickaxe")
	for hit in range(g.Tools.mining_hits("Iron Pickaxe",3)):
		g.mining_cooldown=0;g._mine(Vector2(611*16+8,99*16+8)-g.camera_pos)
	check(not g.world.furniture.has("611,99") and g.world.drops[-1].item=="Fireplace","Mining fireplace failed to return its item")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(g.save_path))
	print("HOUSING_CHECK failures=",failures)
	g.free();quit(0 if failures==0 else 1)
