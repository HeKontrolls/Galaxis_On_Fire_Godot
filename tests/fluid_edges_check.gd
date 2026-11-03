extends SceneTree
const WG = preload("res://scripts/world_gen.gd")
const Cave = preload("res://scripts/underground.gd")
const Water = preload("res://scripts/water_sim.gd")
const Lava = preload("res://scripts/lava_sim.gd")
const Render = preload("res://scripts/fluid_renderer.gd")
var failures := 0
func check(ok: bool, message: String) -> void:
	if not ok: failures += 1; printerr(message)
func _initialize() -> void: call_deferred("run")
func basin(fluid_id: int) -> Dictionary:
	var grid := PackedByteArray(); grid.resize(WG.WIDTH * WG.HEIGHT)
	var cx := 600; var cy := 410; var radius := 9; var depth := 4
	for dx in range(-radius, radius+1):
		var bottom := cy + maxi(1, ceili(depth*(1-pow(float(dx)/radius,2))))
		for y in range(cy-5, bottom+2):
			WG.set_tile(grid, cx+dx, y, 3 if absi(dx)==radius or y>=bottom else (fluid_id if y>=cy else 0))
	var surface := PackedInt32Array();surface.resize(WG.WIDTH);surface.fill(80)
	return {"tiles":grid,"surface":surface,"seed":713,"climate":0,"spawn":Vector2(600*16,408*16),
		"underground_pools":[{"x":cx,"y":cy,"radius":radius,"depth":depth,"fluid":fluid_id}]}
func run() -> void:
	for fluid_id in [4,11]:
		var world := basin(fluid_id)
		var sim = Water.new() if fluid_id==4 else Lava.new(); sim.bind_world(world)
		var original: PackedByteArray=sim.amounts.duplicate()
		world.cave_life=[{"x":591,"y":404,"kind":1,"alive":true},{"x":600,"y":408,"kind":0,"alive":true}]
		check(Cave.clean_pool_rims(world)==10,"Did not remove both generated posts")
		for x in [591,609]:
			for y in range(405,410): check(WG.tile_at(world.tiles,x,y)==0,"Upper rim remains")
			check(WG.tile_at(world.tiles,x,410)==3 and WG.tile_at(world.tiles,x,411)==3,"Basin foot was removed")
		check(world[sim.storage_key]==original,"Rim repair changed stored fluid")
		check(not world.cave_life[0].alive and world.cave_life[1].alive,"Rim repair left unsupported cave features")
		check(Cave.clean_pool_rims(world)==0,"Rim repair ran twice")
		# A retaining bank keeps a settled basin, but an actual opening must
		# release finite fluid into the cave instead of hiding a visual dam.
		for tick in range(8): sim.update(sim.step_seconds)
		check(sim.amounts==original,"Removing upper posts drained a closed basin")
		for y in [410,411]:
			WG.set_tile(world.tiles,591,y,0);sim.terrain_changed(Vector2i(591,y),0)
		for tick in range(12):sim.update(sim.step_seconds)
		var escaped:=false
		for x in [589,590]:
			for y in range(410,439):
				if sim.amount_at(Vector2i(x,y))>0:escaped=true
		check(escaped,"Open bank did not let fluid flow into the cave")
		var total:=0;var original_total:=0
		for value in sim.amounts:total+=value
		for value in original:original_total+=value
		check(total==original_total,"Open-bank runoff changed the fluid volume")
		# Once repaired, later player construction is never treated as an old post.
		WG.set_tile(world.tiles,591,407,33);Cave.clean_pool_rims(world)
		check(WG.tile_at(world.tiles,591,407)==33,"Repair removed a later build")
	var edited := basin(11); WG.set_tile(edited.tiles,591,407,33)
	check(Cave.clean_pool_rims(edited)==5 and WG.tile_at(edited.tiles,591,406)==3 and WG.tile_at(edited.tiles,591,407)==33,"Edited post not preserved as a whole")
	edited=basin(4);edited.torches={"591,407":true}
	check(Cave.clean_pool_rims(edited)==5 and edited.torches.has("591,407"),"Post with a player torch was removed")
	# New generation has retaining banks only at/below the surface.
	var generated := WG.generate(331927,0,false)
	for pool in generated.underground_pools:
		for side in [-1,1]:
			for y in range(int(pool.y)-5,int(pool.y)):
				check(WG.tile_at(generated.tiles,int(pool.x)+side*int(pool.radius),y)==0,"New pool generated an upper post")
	# Connected partial columns must meet and have matching colors at every
	# horizontal/vertical boundary; an intervening rock must remain a separator.
	for molten in [false,true]:
		var world := basin(11 if molten else 4)
		var sim = Lava.new() if molten else Water.new();sim.bind_world(world)
		var render:=Render.new();render.fluid=sim;render.molten=molten;render.grid=world.tiles
		render.values.resize(WG.WIDTH*WG.HEIGHT);render.values.fill(0)
		for y in range(390,398):
			for x in [600,601]:render.values[y*WG.WIDTH+x]=96
		render._stream(600,393,96,false)
		var left_top: Vector2=render.vertices[5];var left_bottom:Vector2=render.vertices[7]
		render._stream(601,393,96,false)
		check(left_top.is_equal_approx(render.vertices[8]) and left_bottom.is_equal_approx(render.vertices[10]),"Adjacent stream columns have a gap")
		for color in render.colors:check(color.is_equal_approx(render.colors[0]),"Internal flow strip has a different shaded edge")
		render.vertices.clear();render.colors.clear();render.indices.clear()
		render._stream(600,393,96,false);var bottom_left:Vector2=render.vertices[2];var bottom_right:Vector2=render.vertices[7]
		render._stream(600,394,96,false)
		check(bottom_left.is_equal_approx(render.vertices[8]) and bottom_right.is_equal_approx(render.vertices[13]),"Successive flow rows have a seam")
		WG.set_tile(render.grid,601,393,3);WG.set_tile(render.grid,601,392,3)
		check(render._flow_section(600,393,9608,10).y<601*16,"Flow was joined through rock")
	# Actual saved-world migration and persistence without rebuilding the basin.
	var g=load("res://main.tscn").instantiate();root.add_child(g);g.set_process(false);await g._open_planet(0);g.hide()
	g.save_path="user://fluid_edges_check.json";g.world=basin(11)
	for key in ["underground_version","underworld_structures_version","cave_life_version","background_ore_version","ground_life_version","ground_cover_version","surface_rocks_version","desert_flora_version","forest_density_version","vines_version","flyers_version","wildlife_version"]:g.world[key]=2
	g.world.creatures=[];g.world.background_ores=[];g.world.ground_life=[]
	g.worlds.clear();g.worlds[g._world_key()]=g.world;g.scene_name="planet";g.player_pos=g.world.spawn
	g._reset_world_environment();g.world_texture=WG.make_texture(g.world.tiles);g.world_image=g.world_texture.get_image()
	g._save_game();g._load_game();while g.scene_name=="loading":await process_frame
	check(WG.tile_at(g.world.tiles,591,405)==0 and WG.tile_at(g.world.tiles,609,409)==0,"Saved-world pool was not repaired on load")
	g._edit_tile(Vector2i(591,405),33);g._save_game();g._load_game();while g.scene_name=="loading":await process_frame
	check(WG.tile_at(g.world.tiles,591,405)==33,"Reload erased a new build after migration")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(g.save_path))
	g.free();print("FLUID_EDGES_CHECK failures=",failures);quit(0 if failures==0 else 1)
