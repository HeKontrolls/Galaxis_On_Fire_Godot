extends "res://tests/housing_check.gd"
func aim_door(g) -> void:
	g.mouse_aim_valid=true;g.mouse_aim_screen=Vector2(602*16+8,98*16+8)-g.camera_pos
func total(values: PackedByteArray) -> int:
	var n:=0
	for value in values:n+=value
	return n
func run() -> void:
	var g=load("res://main.tscn").instantiate();root.add_child(g);g.set_process(false);await g._open_planet(0);g.hide();g.sound.clips.clear()
	g.save_path="user://doors_check.json"
	fixture(g);g.player_pos=Vector2(602*16,1600-28)
	place(g,"Wooden Door",Vector2i(602,99))
	check(g.inventory["Wooden Door"]==1 and g.world.furniture.is_empty(),"Door placed inside the player")
	g.player_pos=g.world.spawn;place(g,"Wooden Door",Vector2i(602,99))
	check(g.inventory["Wooden Door"]==0 and g.world.furniture.has("602,99"),"Door placement failed")
	for y in range(97,100):check(WG.tile_at(g.world.tiles,602,y)==46,"Closed door missing a collision segment")
	check(not g.world.furniture["602,99"].open,"New door should be closed")
	g._move_axis(48,true)
	check(g.player_pos.x+16<=602*16 and not g._collides(g.player_pos),"Closed door does not stop player movement")
	check(not g.FlyingMonsters.fits(g.world,Vector2(602*16,98*16)),"Closed door does not stop creature movement")
	aim_door(g);g._key_pressed(KEY_F)
	check(g.world.furniture["602,99"].open,"F cannot open door")
	for y in range(97,100):check(WG.tile_at(g.world.tiles,602,y)==0,"Opening door left a solid segment")
	g._move_axis(48,true);check(g.player_pos.x>602*16,"Player cannot walk through open doorway")
	# Closing never embeds a player, NPC, mob or small critter in solid tiles.
	g.player_pos=Vector2(602*16,1600-28);g._key_pressed(KEY_F)
	check(g.world.furniture["602,99"].open,"Door closed on the player")
	g.player_pos=g.world.spawn;g.world.npc={"x":602*16.0,"y":1571.0};g._key_pressed(KEY_F)
	check(g.world.furniture["602,99"].open,"Door closed on robot")
	g.world.erase("npc");g.world.creatures=[{"x":602*16.0,"y":1583.0,"hp":30,"alive":true}];g._key_pressed(KEY_F)
	check(g.world.furniture["602,99"].open,"Door closed on mob")
	g.world.creatures=[]
	var rabbit:={"id":1,"species":"hare","x":602*16.0+8,"y":1600.0,"home_x":602*16.0,"phase":0.0,"direction":1,"alive":true}
	g.ground_life.entries.append(rabbit);g.ground_life._index(rabbit);g._key_pressed(KEY_F)
	check(g.world.furniture["602,99"].open,"Door closed on small fauna")
	g.ground_life.entries.clear();g.ground_life.buckets.clear();g.ground_life.state.clear();g._key_pressed(KEY_F)
	check(not g.world.furniture["602,99"].open,"Clear doorway cannot close")
	g.inventory["Axe"]=1;g._equip_inventory_item("Axe");g.mining_cooldown=0
	g._mine(Vector2(602*16+8,99*16+8)-g.camera_pos)
	var work:float=g.world.furniture["602,99"].work
	check(work>0 and work<1,"Door mining has no damage progress")
	g._save_game();g._load_game();while g.scene_name=="loading":await process_frame
	check(not g.world.furniture["602,99"].open and is_equal_approx(float(g.world.furniture["602,99"].work),work),"Closed state or mining work lost on reload")
	check(g._collides(Vector2(602*16,1600-28)),"Reload lost closed-door collision")
	g.furnishings.set_door_open(g,g.world.furniture["602,99"],true);g._save_game();g._load_game();while g.scene_name=="loading":await process_frame
	check(g.world.furniture["602,99"].open and not g._collides(Vector2(602*16,1600-28)),"Open state lost on reload")
	# Mining any part removes the full door once, including all collision cells.
	g.furnishings.set_door_open(g,g.world.furniture["602,99"],false)
	for hit in range(4):
		g.mining_cooldown=0;g._mine(Vector2(602*16+8,97*16+8)-g.camera_pos)
	check(not g.world.furniture.has("602,99") and g.world.drops.size()==1 and g.world.drops[0].item=="Wooden Door","Door did not recover exactly one item")
	for y in range(97,100):check(WG.tile_at(g.world.tiles,602,y)==0,"Mining door left an invisible collision cell")
	fixture(g);place(g,"Wooden Door",Vector2i(602,99));g._edit_tile(Vector2i(602,100),0)
	check(g.world.furniture.is_empty() and g.world.drops.size()==1,"Unsupported door did not recover once")
	# A closed doorway blocks water/lava; closing pushes actual volume outward.
	for molten in [false,true]:
		fixture(g);place(g,"Wooden Door",Vector2i(602,99))
		var door:Dictionary=g.world.furniture["602,99"]
		g.furnishings.set_door_open(g,door,true)
		var sim=g.lava_sim if molten else g.water_sim
		for y in range(97,100):
			g._edit_tile(Vector2i(602,y),11 if molten else 4)
			var index:=y*WG.WIDTH+602;sim.rain_amounts[index]=40;sim.rain_cells[index]=true
		var volume:=total(sim.amounts)
		check(g.furnishings.set_door_open(g,door,false),"Door cannot displace fluid into free space")
		check(total(sim.amounts)==volume and total(sim.rain_amounts)==120,"Door closing lost volume or transported weather/cooling tags")
		for y in range(97,100):check(sim.amount_at(Vector2i(602,y))==0 and not sim._open(g.world.tiles,y*WG.WIDTH+602),"Closed door leaks fluid")
		g.furnishings.set_door_open(g,door,true)
		check(sim._open(g.world.tiles,98*WG.WIDTH+602),"Open door still blocks fluid")
	fixture(g);place(g,"Wooden Door",Vector2i(602,99));var door:Dictionary=g.world.furniture["602,99"]
	g.furnishings.set_door_open(g,door,true)
	for y in range(97,100):
		g._edit_tile(Vector2i(601,y),3);g._edit_tile(Vector2i(603,y),3);g._edit_tile(Vector2i(602,y),4)
	g._edit_tile(Vector2i(602,96),3)
	var trapped:=total(g.water_sim.amounts)
	check(not g.furnishings.set_door_open(g,door,false) and door.open and total(g.water_sim.amounts)==trapped,"Sealed flooded doorway deleted water while closing")
	# The normal workbench inventory can produce and equip a door hotbar item.
	fixture(g);g._edit_tile(Vector2i(598,99),34);g._edit_tile(Vector2i(599,99),36)
	g.stations.open({"name":"Workbench","tile":Vector2i(598,99)})
	g.inventory={"Planks":6,"Stick":2};g.stations.deposit("Planks",6);g.stations.deposit("Stick",2)
	var recipe:=-1
	for i in range(g.RECIPES.size()):
		if g.RECIPES[i].out=="Wooden Door":recipe=i
	check(recipe>=0 and g.stations.craft(recipe),"Missing/invalid wooden-door recipe")
	g.stations.withdraw("output",0);g.stations.close();g._equip_inventory_item("Wooden Door")
	check(g.inventory.get("Wooden Door",0)==1 and g.place_items[g.selected_slot]=="Wooden Door","Crafted door cannot enter the hotbar")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(g.save_path))
	g.free();print("DOORS_CHECK failures=",failures);quit(0 if failures==0 else 1)
