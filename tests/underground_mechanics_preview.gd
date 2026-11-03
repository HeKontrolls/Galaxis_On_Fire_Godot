extends SceneTree
const WG = preload("res://scripts/world_gen.gd")
func _initialize() -> void: call_deferred("run")
func run() -> void:
	root.size=Vector2i(1280,720)
	var g=load("res://main.tscn").instantiate();root.add_child(g);g.set_process(false);await g._open_planet(0)
	var grid:=PackedByteArray();grid.resize(WG.WIDTH*WG.HEIGHT);grid.fill(3)
	var surface:=PackedInt32Array();surface.resize(WG.WIDTH);surface.fill(80)
	for x in range(580,646):
		for y in range(390,418): WG.set_tile(grid,x,y,0)
	for x in range(581,595):
		WG.set_tile(grid,x,396,3)
		for y in range(393,396): WG.set_tile(grid,x,y,11)
	WG.set_tile(grid,580,393,3)
	for x in range(604,623):
		for y in range(416,418): WG.set_tile(grid,x,y,3)
	for x in range(629,641):
		for y in range(413,418): WG.set_tile(grid,x,y,4)
	for y in range(413,418): WG.set_tile(grid,628,y,3);WG.set_tile(grid,641,y,3)
	var ores:=[]
	for kind in range(6):
		for part in range(4): ores.append({"x":606+kind*3+part%2,"y":412+int(part/2),"id":20+kind,"variant":part%3,"work":0.0,"alive":true})
	g.world={"tiles":grid,"surface":surface,"seed":721,"climate":0,"spawn":Vector2(612*16,416*16-28),
		"creatures":[],"ground_life":[],"ground_life_version":1,"ground_cover_version":1,"surface_rocks_version":1,"desert_flora_version":1,
		"cave_life_version":1,"vines_version":1,"background_ore_version":1,"background_ores":ores,
		"torches":{"606,411":true,"616,411":true,"636,411":true}}
	g._reset_world_environment();g.world_texture=WG.make_texture(grid);g.world_image=g.world_texture.get_image()
	g.player_pos=g.world.spawn;g.camera_pos=Vector2(576*16,384*16);g.scene_name="planet"
	g.inventory={"Mattock":1};g._equip_inventory_item("Mattock");g.mouse_aim_direction=Vector2(1,-0.2);g.mouse_aim_valid=true
	g._begin_tool_action("mine",Vector2(615*16,413*16));g.tool_action_timer=0.27
	g.weather="Clear";g.weather_blend.reset("Clear",0);g.notice_timer=0
	g.lava_sim.set_active_region(g.player_pos)
	for i in range(40): g._update_water(0.28)
	g.lava_sim.accumulator=0.14;g.animation_clock=11.3
	g.environment.reset(g.world);g.environment.invalidate();g.terrain_cache.reset(g)
	g.queue_redraw();await process_frame;await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://tests/underground_mechanics_preview.png")
	print("UNDERGROUND_MECHANICS_PREVIEW saved")
	g.free();quit()
