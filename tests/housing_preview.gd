extends SceneTree
const WG=preload("res://scripts/world_gen.gd")
const Furnishings=preload("res://scripts/furnishings.gd")
class Review:
	extends Node2D
	var furniture=Furnishings.new()
	var held:Array[Texture2D]=[]
	func _ready() -> void:
		for item:String in Furnishings.ITEMS:held.append(furniture.texture(item))
	func _draw() -> void:
		draw_rect(Rect2(0,0,1040,330),Color("17242e"))
		var font:=ThemeDB.fallback_font
		draw_string(font,Vector2(24,35),"GALAXIS ON FIRE / ASEPRITE HOUSE SET",HORIZONTAL_ALIGNMENT_LEFT,-1,24,Color("ead4a8"))
		draw_string(font,Vector2(24,63),"Layered native sources - matching 16-pixel blocks - passable furnishings",HORIZONTAL_ALIGNMENT_LEFT,-1,15,Color("9db5bf"))
		for index in range(5):
			var item:String=Furnishings.ITEMS[index]
			var pixels:=Vector2(16,16) if item=="Wooden Wall" else Vector2(furniture.size(item)*16)
			var at:=Vector2(20+index*204,90)
			draw_rect(Rect2(at,Vector2(192,198)),Color("26353c"))
			var scale:=minf(3,150/pixels.x)
			var dest:=Rect2(at+Vector2(96,150)-Vector2(pixels.x*0.5,pixels.y)*scale,pixels*scale)
			draw_texture_rect_region(held[index],dest,Rect2(Vector2.ZERO,pixels))
			draw_string(font,at+Vector2(18,181),item,HORIZONTAL_ALIGNMENT_LEFT,-1,15,Color("e5d5b5"))
func _initialize() -> void:call_deferred("run")
func run() -> void:
	var viewport:=SubViewport.new();viewport.size=Vector2i(1040,330);viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS;root.add_child(viewport)
	var review:=Review.new();review.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST;viewport.add_child(review)
	await process_frame;await RenderingServer.frame_post_draw
	viewport.get_texture().get_image().save_png("res://tests/housing_art_review.png");viewport.free()
	root.size=Vector2i(1280,720)
	var g=load("res://main.tscn").instantiate();root.add_child(g);g.set_process(false);await g._open_planet(0)
	var grid:=PackedByteArray();grid.resize(WG.WIDTH*WG.HEIGHT)
	var surface:=PackedInt32Array();surface.resize(WG.WIDTH);surface.fill(100)
	for x in range(WG.WIDTH):
		for y in range(100,120):WG.set_tile(grid,x,y,1 if y==100 else (2 if y<110 else 3))
	for x in range(591,619):WG.set_tile(grid,x,88,33)
	for x in range(592,618):WG.set_tile(grid,x,87,33)
	for y in range(89,100):
		WG.set_tile(grid,592,y,33)
		if y<97:WG.set_tile(grid,617,y,33)
	for x in range(593,604):WG.set_tile(grid,x,94,33)
	g.world={"tiles":grid,"surface":surface,"seed":712,"climate":0,"spawn":Vector2(608*16,1600-28),"creatures":[],"ground_life":[],"background_ores":[],
		"background_ore_version":1,"cave_life_version":1,"underground_version":1,"underworld_structures_version":1,"forest_density_version":2,
		"ground_life_version":1,"ground_cover_version":1,"surface_rocks_version":1,"desert_flora_version":1,"vines_version":1,
		"torches":{"597,96":true,"600,90":true}}
	g._reset_world_environment();g.world_texture=WG.make_texture(grid);g.world_image=g.world_texture.get_image()
	for y in range(89,100):
		for x in range(593,617):
			if x in range(613,616) and y in range(91,94):continue
			g.furnishings.place(g,"Wooden Wall",Vector2i(x,y))
	g.facing=1;g.furnishings.place(g,"Wooden Chair",Vector2i(597,99));g.furnishings.place(g,"Wooden Table",Vector2i(598,99))
	g.facing=-1;g.furnishings.place(g,"Wooden Chair",Vector2i(601,99))
	g.furnishings.place(g,"Fireplace",Vector2i(611,99))
	for y in range(99,89,-1):g.furnishings.place(g,"Wooden Ladder",Vector2i(605,y))
	g.facing=1;g.furnishings.place(g,"Wooden Chair",Vector2i(594,93));g.furnishings.place(g,"Wooden Table",Vector2i(595,93))
	g._edit_tile(Vector2i(608,99),34);g._edit_tile(Vector2i(609,99),36)
	g.scene_name="planet";g.player_pos=Vector2(609*16,1600-28);g.camera_pos=Vector2(565*16,66*16);g.animation_clock=2.24
	g.weather="Clear";g.weather_blend.reset("Clear",0);g.time_of_day=0.70;g.notice_timer=0
	g.inventory={"Wooden Chair":4,"Wooden Table":2,"Wooden Ladder":12,"Fireplace":1,"Wooden Wall":32,"Hammer":1}
	g.hotbar.clear();g.place_items=g.hotbar.slots
	for item:String in Furnishings.ITEMS:g.hotbar.add(item,g.inventory)
	g._select_hotbar_slot(4)
	g.mouse_aim_screen=Vector2(612*16+8,98*16+8)-g.camera_pos;g.mouse_aim_valid=true;g._set_mouse_world_target(g.mouse_aim_screen+g.camera_pos)
	g.terrain_cache.reset(g);g.environment.invalidate();g.queue_redraw();await process_frame;await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://tests/housing_gameplay.png")
	print("HOUSING_PREVIEW furniture=",g.world.furniture.size()," walls=",g.world.wood_background.size())
	g.free();quit()
