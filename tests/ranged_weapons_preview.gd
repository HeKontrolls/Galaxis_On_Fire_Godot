extends "res://tests/housing_check.gd"
const Ranged=preload("res://scripts/ranged_weapons.gd")
class Review:
	extends Node2D
	var ranged=Ranged.new()
	var bows:Texture2D
	func _ready() -> void:bows=load("res://assets/sprites/weapons/bows.png")
	func _draw() -> void:
		draw_rect(Rect2(0,0,1180,390),Color("17242e"))
		var font:=ThemeDB.fallback_font
		draw_string(font,Vector2(22,32),"GALAXIS ON FIRE / ASEPRITE RANGED WEAPONS",HORIZONTAL_ALIGNMENT_LEFT,-1,23,Color("ead4a8"))
		for i in range(4):
			var name:String=Ranged.ITEMS[i]
			var at:=Vector2(22+i*290,52)
			draw_rect(Rect2(at,Vector2(270,220)),Color("26353c"))
			for frame in range(3):draw_texture_rect_region(bows,Rect2(at+Vector2(12+frame*84,12),Vector2(64,80)),Rect2(frame*32,i*40,32,40))
			draw_string(font,at+Vector2(14,127),name,HORIZONTAL_ALIGNMENT_LEFT,-1,19,Color("e4d1a6"))
			draw_string(font,at+Vector2(14,153),"%d base damage" % Ranged.WEAPONS[name].damage,HORIZONTAL_ALIGNMENT_LEFT,-1,14,Color("b4c9c8"))
			draw_string(font,at+Vector2(14,180),"Click / reload" if i==3 else "Rest / half draw / full draw",HORIZONTAL_ALIGNMENT_LEFT,-1,14,Color("b4c9c8"))
		for i in range(4):
			var name:String=Ranged.ITEMS[i+4];var at:=Vector2(22+i*290,292)
			draw_texture_rect(ranged.texture(name),Rect2(at,Vector2(64,64)),false)
			draw_string(font,at+Vector2(72,22),name,HORIZONTAL_ALIGNMENT_LEFT,-1,18,Color("ead4a8"))
			draw_string(font,at+Vector2(72,48),"+%d damage / %d target%s" % [Ranged.AMMO[name].bonus,Ranged.AMMO[name].hits,"s" if i==3 else ""],HORIZONTAL_ALIGNMENT_LEFT,-1,14,Color("b4c9c8"))
func capture(g,name: String) -> void:
	g.queue_redraw();await process_frame;await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://tests/"+name+".png")
func run() -> void:
	var viewport:=SubViewport.new();viewport.size=Vector2i(1180,390);viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS;root.add_child(viewport)
	var review:=Review.new();review.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST;viewport.add_child(review)
	await process_frame;await RenderingServer.frame_post_draw
	viewport.get_texture().get_image().save_png("res://tests/ranged_weapons_art.png");viewport.free()
	var g=load("res://main.tscn").instantiate();root.add_child(g);g.set_process(false);await process_frame
	fixture(g);g.expedition.data.clear();g.world["drops"]=[];g.world["torches"]={}
	var grid:PackedByteArray=g.world.tiles
	for x in range(540,661):
		for y in range(100,120):WG.set_tile(grid,x,y,1 if y==100 else (2 if y<110 else 3))
	g.world.tiles=grid
	var surface:PackedInt32Array=g.world.surface;surface.fill(100);g.world.surface=surface
	g._reset_world_environment();g.world_texture=WG.make_texture(grid);g.world_image=g.world_texture.get_image()
	for x in [610,617]:
		var creature:Dictionary={"x":float(x*16),"y":1582.0,"home_x":float(x*16),"hp":30,"alive":true,"direction":-1}
		g.PlanetMonsters.decorate(g.world,creature,x,true);g.world.creatures.append(creature)
	g.camera_pos=Vector2(560*16,66*16);g.player_pos=Vector2(596*16,1600-28);g.player_grounded=true
	g.time_of_day=0.25;g.weather="Clear";g.weather_blend.reset("Clear",0);g.notice_timer=0;g.animation_clock=2
	g.inventory={"Wood Bow":1,"Copper Bow":1,"Iron Bow":1,"Iron Crossbow":1,"Stone Arrow":64,"Copper Arrow":32,"Iron Arrow":32,"Crystal Arrow":16}
	g.hotbar.clear();g.place_items=g.hotbar.slots
	for item:String in Ranged.ITEMS:g.hotbar.add(item,g.inventory)
	g._select_hotbar_slot(2);g.ranged.selected_ammo="Crystal Arrow"
	g.aim_screen=Vector2(812,518);g._set_mouse_world_target(g.aim_screen+g.camera_pos)
	g.ranged.begin(g.aim_screen+g.camera_pos);g.ranged.update(0.6)
	await capture(g,"ranged_weapons_aiming")
	g.ranged.release();g.ranged.update(0.12);g.attack_cooldown=0.12
	await capture(g,"ranged_weapons_firing")
	g.ranged.reset();g._select_hotbar_slot(3);g.attack_cooldown=0;g.inventory_open=true
	await capture(g,"ranged_weapons_backpack")
	print("RANGED_WEAPONS_PREVIEW art, aimed draw, firing and backpack rendered")
	quit()
