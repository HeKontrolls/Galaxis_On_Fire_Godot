extends "res://tests/ranged_weapons_check.gd"
const M=preload("res://scripts/magic_catalog.gd")
class Review:
	extends Node2D
	var icons:Dictionary={}
	var sheets:Dictionary={}
	func _ready()->void:
		for item:String in M.ITEMS:icons[item]=M.icon(item)
		for name:String in ["ember_bolt","frost_bolt","crystal_bolt","lightning","ward_aura","mend_aura","lumen_orb","burn_status","frost_status"]:sheets[name]=M.sheet(name)
	func _draw()->void:
		draw_rect(Rect2(0,0,1180,670),Color("182433"));var font:=ThemeDB.fallback_font
		draw_string(font,Vector2(24,34),"GALAXIS / ASEPRITE MAGIC EQUIPMENT AND SPELL EFFECTS",HORIZONTAL_ALIGNMENT_LEFT,-1,22,Color("e7d4b0"))
		for i in range(M.ITEMS.size()):
			var item:String=M.ITEMS[i];var at:=Vector2(22+(i%5)*231,60+int(i/5)*185)
			draw_rect(Rect2(at,Vector2(219,172)),Color("29384a"));var icon:Texture2D=icons[item];var size:=icon.get_size()*2.4
			draw_texture_rect(icon,Rect2(at+Vector2(110,120)-Vector2(size.x/2,size.y),size),false)
			draw_string(font,at+Vector2(10,155),item,HORIZONTAL_ALIGNMENT_LEFT,-1,16,Color("e7d4b0"))
		var names:=["ember_bolt","frost_bolt","crystal_bolt","lightning","ward_aura","mend_aura","lumen_orb","burn_status","frost_status"]
		for i in range(names.size()):
			var x:=25+i*128;var art:Texture2D=sheets[names[i]];var wide:=24 if i<3 else (32 if i==3 else art.get_height())
			draw_texture_rect_region(art,Rect2(x,470,wide*1.5,art.get_height()*1.5),Rect2(wide,0,wide,art.get_height()))
			draw_string(font,Vector2(x,610),names[i].replace("_"," "),HORIZONTAL_ALIGNMENT_LEFT,-1,11,Color("bfcee2"))
func capture(g,name:String)->void:
	g.queue_redraw();await process_frame;await RenderingServer.frame_post_draw;root.get_texture().get_image().save_png("res://tests/"+name+".png")
func run()->void:
	var viewport:=SubViewport.new();viewport.size=Vector2i(1180,670);viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS;root.add_child(viewport)
	var review:=Review.new();review.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST;viewport.add_child(review)
	await process_frame;await RenderingServer.frame_post_draw;viewport.get_texture().get_image().save_png("res://tests/magic_art_review.png");viewport.free()
	var g=load("res://main.tscn").instantiate();root.add_child(g);g.set_process(false);await process_frame;fixture(g)
	g.magic.new_character();g.expedition.data.clear();g.world["drops"]=[]
	var grid:PackedByteArray=g.world.tiles
	for x in range(555,655):
		for y in range(100,124):WG.set_tile(grid,x,y,1 if y==100 else 2)
	var surface:PackedInt32Array=g.world.surface;surface.fill(100);g.world.surface=surface
	g.world.tiles=grid;g._reset_world_environment();g.world_texture=WG.make_texture(grid);g.world_image=g.world_texture.get_image()
	g.time_of_day=0.25;g.weather="Clear";g.weather_blend.reset("Clear",0);g.inventory.clear();g.hotbar.clear();g.place_items=g.hotbar.slots
	for item:String in M.ITEMS:g.inventory[item]=1 if item!="Mana Tonic" else 8;g.hotbar.add(item,g.inventory)
	g._select_hotbar_slot(0);g.player_pos=Vector2(600*16,1572);g._update_camera();g.scene_name="planet";g.animation_clock=2.1
	var rng:=RandomNumberGenerator.new();rng.seed=18
	g.world.creatures=[g.WildlifeMobs.creature(0,Vector2(607*16,1582),rng),g.WildlifeMobs.creature(7,Vector2(612*16,1582),rng),g.WildlifeMobs.creature(6,Vector2(616*16,1582),rng)]
	g.magic.ward=40;g.magic.ward_time=8;g.magic.lumen=60;g.magic.mana=70
	g.magic.cast(g.player_pos+Vector2(170,-8));g.magic.update(0.07);g.notice_timer=0
	await capture(g,"magic_gameplay")
	g.magic.projectiles.clear();g.magic.mana=100;g.magic.cooldowns.clear();g.attack_cooldown=0;g._equip_inventory_item("Storm Staff")
	g.magic.cast(Ranged.hit_box(g.world.creatures[0]).get_center());g.notice_timer=0
	await capture(g,"magic_chain_lightning")
	g.magic.xp={"Destruction":45,"Restoration":18,"Warding":32,"Illumination":8};g.magic.open_codex();g.notice_timer=0
	await capture(g,"magic_skill_guide")
	print("MAGIC_PREVIEW Aseprite equipment, casting, ward, light, lightning and skill guide rendered")
	quit()
