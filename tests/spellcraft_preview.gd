extends "res://tests/spellcraft_check.gd"
class Review:
	extends Node2D
	var textures:Dictionary={}
	var names:Array=["alchemy_desk","cauldron","blank_wand","blank_staff","blank_tome","fire_essence","frost_essence","storm_essence","life_essence","spirit_essence","arcane_ink","bone_fragment","soul_wand","grave_tome","crafted_wand","crafted_staff","crafted_tome","soul_bolt","blight_bolt","blight_status","bone_servitor","grave_wraith","bone_hound"]
	func _ready()->void:
		for name:String in names:textures[name]=C.sheet(name)
	func _draw()->void:
		draw_rect(Rect2(0,0,1260,850),Color("182a35"));var font:=ThemeDB.fallback_font
		draw_string(font,Vector2(24,35),"GALAXIS / ASEPRITE ALCHEMY, SPELLCRAFT AND NECROMANCY",HORIZONTAL_ALIGNMENT_LEFT,-1,22,Color("e8d5b2"))
		for i in range(names.size()):
			var name:String=names[i];var art:Texture2D=textures[name];var frame_count:=1 if i>=5 and i<=11 else (3 if i<=16 else 4)
			var shape:=Vector2(art.get_width()/frame_count,art.get_height());var scale:=minf(2,94/shape.y);var at:=Vector2(20+(i%6)*206,58+int(i/6)*185)
			draw_rect(Rect2(at,Vector2(196,174)),Color("293e49"));draw_texture_rect_region(art,Rect2(at+Vector2(98,122)-Vector2(shape.x/2,shape.y)*scale,shape*scale),Rect2(Vector2.ZERO,shape))
			draw_string(font,at+Vector2(10,157),name.replace("_"," ").capitalize(),HORIZONTAL_ALIGNMENT_LEFT,-1,14,Color("e6d5b9"))
func capture(g,name:String)->void:
	g.notice_timer=0;g.queue_redraw();await process_frame;await RenderingServer.frame_post_draw;root.get_texture().get_image().save_png("res://tests/"+name+".png")
func run()->void:
	var viewport:=SubViewport.new();viewport.size=Vector2i(1260,850);viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS;root.add_child(viewport)
	var review:=Review.new();review.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST;viewport.add_child(review)
	await process_frame;await RenderingServer.frame_post_draw;viewport.get_texture().get_image().save_png("res://tests/spellcraft_art_review.png");viewport.free()
	var g=load("res://main.tscn").instantiate();root.add_child(g);g.set_process(false);await process_frame;fresh(g);unlock_all(g)
	var grid:PackedByteArray=g.world.tiles
	for x in range(555,655):
		for y in range(100,125):WG.set_tile(grid,x,y,1 if y==100 else 2)
	var surface:PackedInt32Array=g.world.surface;surface.fill(100);g.world.surface=surface
	g.world.tiles=grid;g._reset_world_environment();g.world_texture=WG.make_texture(grid);g.world_image=g.world_texture.get_image()
	g.time_of_day=0.25;g.weather="Clear";g.weather_blend.reset("Clear",0);g.animation_clock=4.2
	g.furnishings.place(g,"Alchemy Desk",Vector2i(590,99));g.furnishings.place(g,"Cauldron",Vector2i(598,99))
	g.alchemy.open(g.world.furniture["598,99"]);g.alchemy.state().recipe=4;g.alchemy.state().page=1;materials(g,C.BREWS[4].needs);g.alchemy.start_brew();g.alchemy.update(4)
	await capture(g,"cauldron_brewing")
	g.alchemy.close();g.alchemy.open(g.world.furniture["590,99"])
	var draft:=C.draft();draft.name="Winterflame Lance";draft.focus="Staff";draft.first="Ember";draft.second="Frost";draft.power=2;draft.duration=2
	g.alchemy.state().draft=draft;materials(g,g.spellcraft.needs(draft));var item:String=g.spellcraft.inscribe(draft,g.alchemy.state().inputs,g.alchemy.state().output)
	g.alchemy.withdraw("output",0);materials(g,g.spellcraft.needs(draft))
	await capture(g,"alchemy_spell_builder")
	g.alchemy.close();g.magic.xp={"Destruction":180,"Restoration":30,"Warding":30,"Illumination":90,"Necromancy":30}
	g.spellcraft.learned.assign(["ember","frost","mending","ward","lumen","dual","burst","soul","blight","raise"])
	g.magic.open_codex();await capture(g,"magic_skill_tree")
	g.spellcraft.codex_tab=2;await capture(g,"custom_spell_library")
	g.magic.close_codex();g.hotbar.clear();g.place_items=g.hotbar.slots
	for focus:String in [item,"Soul Wand","Grave Tome","Alchemy Desk","Cauldron"]:g.inventory[focus]=1;g.hotbar.add(focus,g.inventory)
	g._equip_inventory_item(item);g.player_pos=Vector2(604*16,1572);g._update_camera()
	var corpse:=enemy(609*16.0);corpse.alive=false;var target:=enemy(617*16.0,200);g.world.creatures=[corpse,target]
	g.necromancy.raise_dead(Ranged.hit_box(corpse).get_center(),25,10,"Tome");g.magic.mana=g.magic.max_mana();g.attack_cooldown=0;g.aim_screen=Ranged.hit_box(target).get_center()-g.camera_pos
	g.magic.cast(Ranged.hit_box(target).get_center());g.magic.update(0.08)
	await capture(g,"spellcraft_necromancy_gameplay")
	print("SPELLCRAFT_PREVIEW native artwork, desk, cauldron, skill tree, unique library and raised ally rendered")
	quit()
