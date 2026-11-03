extends SceneTree
const WG = preload("res://scripts/world_gen.gd")
const Tools = preload("res://scripts/tool_catalog.gd")
const Lava = preload("res://scripts/lava_sim.gd")
const Renderer = preload("res://scripts/fluid_renderer.gd")
const Back = preload("res://scripts/background_ores.gd")
var failures := 0
func check(ok: bool, message: String) -> void:
	if not ok: failures += 1; printerr(message)
func _initialize() -> void: call_deferred("run")
func sum_units(values: PackedByteArray) -> int:
	var result := 0
	for value in values: result += value
	return result
func fixture(g) -> void:
	var grid := PackedByteArray(); grid.resize(WG.WIDTH * WG.HEIGHT)
	var surface := PackedInt32Array(); surface.resize(WG.WIDTH); surface.fill(60)
	for x in range(WG.WIDTH): WG.set_tile(grid, x, 100, 3)
	g.world = {"tiles": grid, "surface": surface, "seed": 721, "climate": 0, "spawn": Vector2(600*16, 1600-28),
		"creatures": [], "ground_life": [], "ground_life_version": 1, "ground_cover_version": 1,
		"surface_rocks_version": 1, "desert_flora_version": 1, "forest_density_version": 2,
		"underground_version": 1, "underworld_structures_version": 1, "cave_life_version": 1,
		"vines_version": 1, "wildlife_version": 1, "flyers_version": 1, "background_ore_version": 1,
		"background_ores": [{"x":602,"y":99,"id":21,"variant":0,"work":0.0,"alive":true}]}
	g.worlds.clear(); g.worlds[g._world_key()] = g.world
	g._reset_world_environment(); g.world_texture = WG.make_texture(grid); g.world_image = g.world_texture.get_image()
	g.player_pos = g.world.spawn; g._update_camera(); g.scene_name = "planet"; g.inventory = {"Hammer":1,"Mattock":1,"Pickaxe":1}
	g.mining_cooldown = 0; g.use_hoe = false
func hit(g, tool: String) -> void:
	g.equipped_tool = tool; g.mining_cooldown = 0
	g._mine(Vector2(602*16+8,99*16+8)-g.camera_pos)
func run() -> void:
	for family in ["Pickaxe", "Shovel", "Axe"]:
		for item in Tools.progression(family):
			check(is_equal_approx(Tools.action_duration(item,false),0.48) and is_equal_approx(Tools.mining_interval(item,3),0.48), "Mining cadence differs: " + item)
	check(Tools.mining_damage("Iron Pickaxe",3) > Tools.mining_damage("Copper Pickaxe",3) and Tools.mining_damage("Copper Pickaxe",3) > Tools.mining_damage("Pickaxe",3), "Pickaxe damage progression lost")
	check(Tools.mining_damage("Shovel",2) > Tools.mining_damage("Pickaxe",2), "Shovel soil advantage lost")
	check(Tools.mining_damage("Axe",7) > Tools.mining_damage("Pickaxe",7), "Axe tree advantage lost")
	check(not Tools.can_harvest("Pickaxe",22) and Tools.can_harvest("Stone Pickaxe",22), "Harvest levels changed")
	check(Tools.mining_damage("Sword",3)==0 and not Tools.can_harvest("Sword",3), "Swords can mine")
	# A finite lava parcel leaves an unbroken viscous trail while it descends.
	var grid := PackedByteArray(); grid.resize(WG.WIDTH*WG.HEIGHT)
	for x in range(590,611): WG.set_tile(grid,x,105,3)
	for y in range(70,76): WG.set_tile(grid,600,y,11)
	var lava := Lava.new(); var fluid_world := {"tiles":grid}; lava.bind_world(fluid_world)
	var before := sum_units(lava.amounts)
	for tick in range(14):
		lava.update(0.28)
		var first := -1; var last := -1
		for y in range(70,105):
			if lava.amount_at(Vector2i(600,y)) > 0:
				if first<0: first=y
				last=y
		for y in range(first,last+1): check(lava.amount_at(Vector2i(600,y))>0,"Lava trail has an empty cell")
	check(sum_units(lava.amounts)==before, "Lava continuity created fluid")
	# Neighboring thin stream sections meet at their common tile boundary.
	var render := Renderer.new(); render.fluid=lava; render.molten=true; render.grid=grid
	render.values.resize(grid.size()); render.values.fill(0)
	for y in range(80,84): render.values[y*WG.WIDTH+600]=4.0
	for y in range(81,83): render._stream(600,y,4.0,false)
	check(is_equal_approx(render.vertices[2].y,render.vertices[8].y),"Thin lava segments have a vertical seam")
	var g = load("res://main.tscn").instantiate(); root.add_child(g); g.set_process(false)
	await g._open_planet(0); g.hide(); g.sound.clips.clear(); g.save_path="user://underground_mechanics_check.json"
	fixture(g); hit(g,"Pickaxe")
	check(g.world.background_ores[0].work==0 and g.world.background_ores[0].alive,"Pickaxe mined background ore")
	g._edit_tile(Vector2i(602,99),3); hit(g,"Hammer")
	check(g.world.background_ores[0].work==0,"Background ore mined through foreground rock")
	g._edit_tile(Vector2i(602,99),0); g._edit_tile(Vector2i(601,99),3); g._edit_tile(Vector2i(601,98),3); hit(g,"Hammer")
	check(g.world.background_ores[0].work==0,"Wall mining bypassed a solid obstruction")
	g._edit_tile(Vector2i(601,99),0); g._edit_tile(Vector2i(601,98),0)
	hit(g,"Hammer"); var hammer_work: float=g.world.background_ores[0].work
	check(hammer_work>0 and hammer_work<1,"Hammer did not damage wall ore")
	g._save_game(); g._load_game(); while g.scene_name=="loading": await process_frame
	check(is_equal_approx(float(g.world.background_ores[0].work),hammer_work),"Partial background damage lost on reload")
	check(is_equal_approx(g.mining_cooldown, Tools.MINING_SWING),"Reload shortened the common mining recovery")
	hit(g,"Mattock"); check(float(g.world.background_ores[0].work)-hammer_work > hammer_work,"Mattock lacks stronger wall damage")
	for i in range(8): hit(g,"Mattock")
	check(not g.world.background_ores[0].alive and g.world.drops.size()==1 and g.world.drops[0].item=="Copper Ore","Wall seam failed to drop exactly one ore")
	g._save_game(); g._load_game(); while g.scene_name=="loading": await process_frame
	check(not g.world.background_ores[0].alive and g.world.drops.size()==1,"Mined seam regenerated/duplicated on reload")
	fixture(g); g.world.background_ores[0].id=23; hit(g,"Hammer")
	check(g.world.background_ores[0].work==0,"Hammer bypassed deep ore tier")
	hit(g,"Mattock"); check(g.world.background_ores[0].work>0,"Mattock cannot mine deep ore")
	# Real foreground mining uses power per hit while all swing durations match.
	fixture(g); g.world.background_ores[0].alive=false; g._edit_tile(Vector2i(602,99),3)
	hit(g,"Pickaxe"); check(WG.tile_at(g.world.tiles,602,99)==3,"Wood pickaxe broke rock in one hit")
	hit(g,"Pickaxe"); hit(g,"Pickaxe")
	check(WG.tile_at(g.world.tiles,602,99)==0,"Wood pickaxe damage did not accumulate")
	g._edit_tile(Vector2i(602,99),3); hit(g,"Iron Pickaxe")
	check(WG.tile_at(g.world.tiles,602,99)==0,"Iron pickaxe has no rock damage advantage")
	# Station inventory crafting, native tool texture, and equip support.
	fixture(g); g._edit_tile(Vector2i(599,99),34); g._edit_tile(Vector2i(600,99),36)
	g.player_pos=Vector2(598*16,1600-28)
	g.stations.open(g.interactions.target("Workbench")); g.inventory["Iron Ingot"]=4;g.inventory["Stick"]=2
	g.stations.deposit("Iron Ingot",4);g.stations.deposit("Stick",2)
	var recipe := -1
	for i in range(g.RECIPES.size()):
		if g.RECIPES[i].out=="Mattock": recipe=i
	check(recipe>=0 and g.stations.craft(recipe),"Mattock cannot be crafted at a workbench")
	g.stations.withdraw("output",0); g.stations.close(); g._equip_inventory_item("Mattock")
	check(g.equipped_tool=="Mattock" and g.tool_textures["Mattock"].get_size()==Vector2(32,40),"Mattock not equipped with native art")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(g.save_path))
	for climate in [0,4,7]:
		var generated := WG.generate(331927+climate,climate,false)
		var wet:=0;var hot:=0
		for pool in generated.underground_pools:
			if int(pool.fluid)==4: wet+=1
			else: hot+=1
		check(generated.underground_pools.size()>180,"Too few underground pools")
		check(hot>20 and (wet>100 if climate!=4 else wet==0),"Pool climate/fluid mix incorrect")
		var original: PackedByteArray=generated.tiles.duplicate();Back.prepare(generated)
		check(generated.background_ores.size()>300 and generated.tiles==original,"Background ore absent or changed terrain")
		var seams: Array=generated.background_ores.duplicate(true);Back.prepare(generated)
		check(generated.background_ores==seams,"Background ore migration not idempotent")
		print("UNDERGROUND_ADDITIONS climate=",climate," water_pools=",wet," lava_pools=",hot," wall_ores=",seams.size())
	print("UNDERGROUND_MECHANICS_CHECK failures=",failures)
	g.free();quit(0 if failures==0 else 1)
