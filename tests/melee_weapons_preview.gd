extends "res://tests/housing_check.gd"
const Melee=preload("res://scripts/melee_weapons.gd")
class Review:
	extends Node2D
	var g
	func _draw() -> void:
		draw_rect(Rect2(0,0,1280,720),Color("14232d"))
		var font:=ThemeDB.fallback_font
		draw_string(font,Vector2(24,34),"GALAXIS ON FIRE / NEW WEAPONS / ASEPRITE",HORIZONTAL_ALIGNMENT_LEFT,-1,23,Color("ead4a8"))
		var index:=0
		for item:String in Melee.WEAPONS:
			var cell:=Vector2(18+(index%3)*422,54+(index/3)*327)
			draw_rect(Rect2(cell,Vector2(410,312)),Color("253a43"))
			draw_string(font,cell+Vector2(16,30),item,HORIZONTAL_ALIGNMENT_LEFT,-1,22,Color("e3d3ad"))
			draw_string(font,cell+Vector2(16,56),"%d damage / %.2fs between attacks" % [Melee.WEAPONS[item].damage,Melee.WEAPONS[item].cooldown],HORIZONTAL_ALIGNMENT_LEFT,-1,16,Color("abc4ca"))
			for sample in range(2):
				var facing:=1 if sample==0 else -1
				var at:=cell+Vector2(60+sample*255,173)
				var base:=Transform2D(0,Vector2(2,2),0,at)
				var pose:Transform2D=g.PlayerPose.tool(Vector2.ZERO,Vector2(facing,0),facing,true,0.5,item,false)
				draw_set_transform_matrix(base)
				g.character_avatar.draw_body(self,Vector2(-8,-12),"idle_east" if facing==1 else "idle_west",0)
				draw_set_transform_matrix(base*pose)
				draw_texture_rect(g.tool_textures[item],Melee.draw_rect(item),false)
				draw_set_transform_matrix(base*g.PlayerPose.arm_transform(g.PlayerPose.shoulder(Vector2.ZERO,facing),pose.origin,facing))
				draw_texture(g.arm_textures.solid_arm,Vector2(-4,-1))
				draw_set_transform_matrix(Transform2D.IDENTITY)
			draw_string(font,cell+Vector2(16,282),"Aimed thrust" if Melee.WEAPONS[item].motion=="thrust" else "Sweeping strike / up to %d enemies" % Melee.WEAPONS[item].hits,HORIZONTAL_ALIGNMENT_LEFT,-1,16,Color("abc4ca"))
			index+=1

func run() -> void:
	var g=load("res://main.tscn").instantiate();root.add_child(g);g.set_process(false);g.hide();await process_frame
	var view:=SubViewport.new();view.size=Vector2i(1280,720);view.render_target_update_mode=SubViewport.UPDATE_ALWAYS;root.add_child(view)
	var review:=Review.new();review.g=g;review.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST;view.add_child(review)
	await process_frame;await RenderingServer.frame_post_draw
	view.get_texture().get_image().save_png("res://.godot/melee_pose_preview.png")
	print("MELEE_POSE_PREVIEW six weapons both facings rendered")
	view.queue_free()
	await g._open_planet(0)
	g.world.creatures=[];g.expedition.data.clear();g.dev_invulnerable=true
	g.time_of_day=0.75;g.weather="Clear";g.weather_blend.reset("Clear",int(g.world.climate));g.notice_timer=0
	for item:String in Melee.WEAPONS:select(g,item)
	g._equip_inventory_item("Iron Spear")
	for tick in range(1200):
		g.animation_clock+=0.05
		g.NightPopulation.update(g,0.05)
		g._update_population(0.05)
	g.show();g.queue_redraw()
	await process_frame;await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://.godot/night_encounters_preview.png")
	print("NIGHT_GAMEPLAY_PREVIEW creatures=",g.world.creatures.size())
	quit()
