extends "res://tests/housing_check.gd"
const C=preload("res://scripts/power_catalog.gd")
class Review:
	extends Node2D
	var art:Dictionary={}
	func _ready() -> void:
		for item:String in C.ITEMS:art[item]=C.texture(item)
	func _draw() -> void:
		draw_rect(Rect2(0,0,1260,1000),Color("17242e"));var font:=ThemeDB.fallback_font
		draw_string(font,Vector2(24,34),"GALAXIS / ASEPRITE POWER AND LOGIC",HORIZONTAL_ALIGNMENT_LEFT,-1,24,Color("ead4a8"))
		for i in range(C.ITEMS.size()):
			var item:String=C.ITEMS[i];var at:=Vector2(20+(i%6)*206,58+int(i/6)*155)
			draw_rect(Rect2(at,Vector2(196,143)),Color("26373e"))
			var size:=Vector2(C.size(item)*16);var scale:=minf(2.0,96.0/size.y)
			draw_texture_rect_region(art[item],Rect2(at+Vector2(98,107)-Vector2(size.x*0.5,size.y)*scale,size*scale),Rect2(Vector2(size.x if C.has_device(item) else 0,0),size))
			draw_string(font,at+Vector2(10,131),item,HORIZONTAL_ALIGNMENT_LEFT,-1,14,Color("e2d1aa"))
func capture(g,name: String) -> void:
	g.queue_redraw();await process_frame;await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://tests/"+name+".png")
func add(g,item: String,x: int) -> String:
	g.power.place(item,Vector2i(x,99));return "%d,99" % x
func link(g,a: String,ap: String,b: String,bp: String,wire: String="Wire") -> void:
	assert(g.power.connect_ports({"node":a,"pin":ap},{"node":b,"pin":bp},wire),"Demo cable did not connect")
func run() -> void:
	var viewport:=SubViewport.new();viewport.size=Vector2i(1260,1000);viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS;root.add_child(viewport)
	var review:=Review.new();review.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST;viewport.add_child(review)
	await process_frame;await RenderingServer.frame_post_draw
	viewport.get_texture().get_image().save_png("res://tests/power_art_review.png");viewport.free()
	var g=load("res://main.tscn").instantiate();root.add_child(g);g.set_process(false);await process_frame;fixture(g)
	g.expedition.data.clear();g.world["drops"]=[];g.world["torches"]={}
	var surface:PackedInt32Array=g.world.surface;surface.fill(100);g.world.surface=surface
	var grid:PackedByteArray=g.world.tiles
	for x in range(540,661):
		for y in range(100,120):WG.set_tile(grid,x,y,1 if y==100 else (2 if y<110 else 3))
	g.world.tiles=grid;g._reset_world_environment();g.world_texture=WG.make_texture(grid);g.world_image=g.world_texture.get_image()
	g.inventory={"Wire":128,"Logic Wire":128,"Raw Biomass":12,"Coal Ore":12,"Biofuel":8}
	var gen:=add(g,"Biomass Generator",578);var coal:=add(g,"Coal Generator",584);var fuel:=add(g,"Fuel Generator",590);var pole:=add(g,"Wood Power Pole",596)
	var ia:=add(g,"Logic Input",601);var ib:=add(g,"Logic Input",604);var gate:=add(g,"AND Gate",608);var lamp:=add(g,"Electric Lamp",614);var t:=add(g,"T Flip-Flop",616);var lamp2:=add(g,"Electric Lamp",624)
	for pair in [[gen,coal],[coal,fuel],[fuel,pole],[pole,ia],[ia,ib],[ib,gate],[gate,lamp],[lamp,t],[t,lamp2]]:link(g,pair[0],"P",pair[1],"P")
	link(g,ia,"Q",gate,"A","Logic Wire");link(g,ib,"Q",gate,"B","Logic Wire");link(g,gate,"Q",lamp,"EN","Logic Wire");link(g,ia,"Q",t,"CLK","Logic Wire");link(g,t,"Q",lamp2,"EN","Logic Wire")
	g.power.data.nodes[gen].fuel[0]={"item":"Raw Biomass","count":8};g.power.data.nodes[coal].fuel[0]={"item":"Coal Ore","count":4};g.power.data.nodes[fuel].fuel[0]={"item":"Biofuel","count":4}
	g.power.data.nodes[ia].manual=true;g.power.data.nodes[ib].manual=true;g.power.recompute();g.power.update(1)
	g.scene_name="planet";g.player_pos=Vector2(610*16,1600-28);g.player_grounded=true;g.camera_pos=Vector2(560*16,66*16)
	g.time_of_day=0.25;g.weather="Clear";g.weather_blend.reset("Clear",0);g.notice_timer=0;g.animation_clock=4.2
	g.hotbar.clear();g.place_items=g.hotbar.slots
	for item:String in ["Wire","Logic Wire","Biomass Generator","Wood Power Pole","Logic Input","AND Gate","Electric Lamp","T Flip-Flop"]:
		g.inventory[item]=maxi(1,int(g.inventory.get(item,0)));g.hotbar.add(item,g.inventory)
	g._select_hotbar_slot(1)
	await capture(g,"power_gameplay")
	g.power_ui.open(gen);await capture(g,"power_generator_window")
	g.power_ui.close();g.power_ui.open(t);await capture(g,"power_logic_window")
	# A usable small powered shelter, including automatic and walk-triggered lights.
	g.power_ui.close();fixture(g);g.expedition.data.clear();g.world["drops"]=[]
	g.inventory={"Wire":128,"Logic Wire":128};g.hotbar.clear();g.place_items=g.hotbar.slots
	var ground:PackedByteArray=g.world.tiles
	for x in range(540,661):
		for y in range(100,120):WG.set_tile(ground,x,y,1 if y==100 else 2)
	for x in range(588,613):WG.set_tile(ground,x,91,3)
	g.world.tiles=ground;g._reset_world_environment();g.world_texture=WG.make_texture(ground);g.world_image=g.world_texture.get_image()
	for x in range(588,613):
		for y in range(92,100):g.furnishings.place(g,"Wooden Wall",Vector2i(x,y))
	var source:=add(g,"Biomass Generator",579)
	var porch:=add(g,"Electric Lamp",583);link(g,source,"P",porch,"P")
	g.power.place("Wall Switch",Vector2i(588,96));var control:="588,96"
	g.power.place("Wall Light",Vector2i(593,95));var wall:="593,95"
	g.power.place("Ceiling Light",Vector2i(600,92));var ceiling:="600,92"
	var flood:=add(g,"Floodlight",608)
	g.power.place("Red Signal Lamp",Vector2i(610,95));var red:="610,95"
	g.power.place("Push Button",Vector2i(590,97));var push:="590,97"
	var plate:=add(g,"Pressure Plate",595);var sensor:=add(g,"Daylight Sensor",585)
	link(g,source,"P",control,"P");link(g,control,"L",wall,"P");link(g,wall,"P",ceiling,"P");link(g,ceiling,"P",flood,"P");link(g,flood,"P",red,"P")
	link(g,source,"P",push,"P");link(g,push,"P",plate,"P");link(g,source,"P",sensor,"P")
	link(g,sensor,"Q",wall,"EN","Logic Wire");link(g,plate,"Q",red,"EN","Logic Wire")
	g.power.data.nodes[source].fuel[0]={"item":"Raw Biomass","count":8};g.power.data.nodes[sensor].inverted=true
	g.time_of_day=0.75;g.player_pos=Vector2(595*16,1600-28);g.camera_pos=Vector2(560*16,66*16);g.power.update(0.5)
	g.notice_timer=0;await capture(g,"power_fixtures_gameplay")
	g.power_ui.open(sensor);await capture(g,"power_sensor_window")
	print("POWER_PREVIEW native art, generator network, signal circuit and storage/logic windows rendered")
	quit()
