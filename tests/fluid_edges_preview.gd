extends SceneTree
const WG=preload("res://scripts/world_gen.gd")
const Cave=preload("res://scripts/underground.gd")
var failures:=0
func _initialize() -> void:call_deferred("run")
func fixture(g, flows:=false) -> void:
	var grid:=PackedByteArray();grid.resize(WG.WIDTH*WG.HEIGHT);grid.fill(3)
	for x in range(579,651):
		for y in range(388,425 if flows else 411):WG.set_tile(grid,x,y,0)
	var pools:=[]
	if not flows:
		for spec in [[593,9,4],[626,11,11]]:
			var cx:int=spec[0];var radius:int=spec[1];var fluid:int=spec[2]
			for dx in range(-radius,radius+1):
				var bottom:=410+maxi(1,ceili(4*(1-pow(float(dx)/radius,2))))
				for y in range(405,bottom+2):WG.set_tile(grid,cx+dx,y,3 if absi(dx)==radius or y>=bottom else (fluid if y>=410 else 0))
			pools.append({"x":cx,"y":410,"radius":radius,"depth":4,"fluid":fluid})
	else:
		for x in range(579,594):
			WG.set_tile(grid,x,395,3);WG.set_tile(grid,x,396,3)
			if x>=582:WG.set_tile(grid,x,394,11)
		for x: int in [594,595,596]:
			for y in range(394,425):WG.set_tile(grid,x,y,11)
	var surface:=PackedInt32Array();surface.resize(WG.WIDTH);surface.fill(80)
	g.world={"tiles":grid,"surface":surface,"seed":713,"climate":0,"spawn":Vector2(610*16,410*16-28),"underground_pools":pools,
		"creatures":[],"ground_life":[],"background_ores":[],"torches":{"583,407":true,"608,406":true,"638,407":true},
		"ground_life_version":1,"ground_cover_version":1,"surface_rocks_version":1,"desert_flora_version":1,"cave_life_version":1,"vines_version":1,"background_ore_version":1}
	Cave.clean_pool_rims(g.world);g._reset_world_environment()
	if flows:
		for x: int in [594,595,596]:
			for y in range(394,425):
				var index:=y*WG.WIDTH+x;g.lava_sim.amounts[index]=96;g.lava_sim.previous_amounts[index]=96
	g.world_texture=WG.make_texture(g.world.tiles);g.world_image=g.world_texture.get_image()
	g.player_pos=g.world.spawn;g.camera_pos=Vector2(579*16,380*16);g.scene_name="planet";g.weather="Clear";g.weather_blend.reset("Clear",0);g.notice_timer=0
	g.animation_clock=0;g.environment.invalidate();g.terrain_cache.reset(g)
func run() -> void:
	root.size=Vector2i(1280,720)
	var g=load("res://main.tscn").instantiate();root.add_child(g);g.set_process(false);await g._open_planet(0)
	fixture(g);g.queue_redraw();await process_frame;await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://tests/pool_rims_preview.png")
	fixture(g,true);g.queue_redraw();await process_frame;await RenderingServer.frame_post_draw
	var picture:=root.get_texture().get_image();picture.save_png("res://tests/joined_lava_preview.png")
	# Sample the actual rendered flow across both internal column borders.
	for boundary in [595,596]:
		var sx: int=(boundary-579)*16
		for y in [402,406,410,414]:
			var sy: int=(y-380)*16+8
			var left:=picture.get_pixel(sx-1,sy);var right:=picture.get_pixel(sx,sy)
			if left.r<0.5 or right.r<0.5 or absf(left.r-right.r)+absf(left.g-right.g)+absf(left.b-right.b)>0.06:
				failures+=1;printerr("Visible gap/stroke inside joined flow at ",boundary,",",y," ",left," ",right)
	print("FLUID_EDGES_PREVIEW failures=",failures)
	g.free();quit(0 if failures==0 else 1)
