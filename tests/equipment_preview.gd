extends "res://tests/equipment_check.gd"
class Review:
	extends Node2D
	var g
	var avatars:=[]
	func _ready() -> void:
		for model in ["male","female"]:
			var avatar=g.CharacterAppearance.new();var config:Dictionary=g.CharacterAppearance.DEFAULT.duplicate();config.model=model;avatar.configure(config);avatars.append(avatar)
	func _draw() -> void:
		draw_rect(Rect2(0,0,1280,720),Color("14232d"));var font:=ThemeDB.fallback_font
		draw_string(font,Vector2(24,32),"GALAXIS ON FIRE / ARMOR AND SHIELDS / ASEPRITE",HORIZONTAL_ALIGNMENT_LEFT,-1,22,Color("ead4a8"))
		for model in range(2):
			for tier in range(3):
				var names:Array=[["Fiber Hood","Fiber Vest","Fiber Boots","Wood Shield"],["Copper Helmet","Copper Cuirass","Copper Boots","Copper Shield"],["Iron Helmet","Iron Cuirass","Iron Boots","Iron Shield"]][tier]
				var worn:Dictionary={"head":names[0],"chest":names[1],"boots":names[2],"shield":names[3]}
				var cell:=Vector2(18+tier*422,54+model*327)
				draw_rect(Rect2(cell,Vector2(410,310)),Color("253a43"))
				draw_string(font,cell+Vector2(16,30),["Fiber","Copper","Iron"][tier]+" / "+["Male","Female"][model],HORIZONTAL_ALIGNMENT_LEFT,-1,22,Color("e5cba5"))
				for side in range(2):
					var facing:=1 if side==0 else -1
					var animation:="walk_east" if side==0 else "walk_west"
					var base:=Transform2D(0,Vector2(3,3),0,cell+Vector2(75+side*190,95))
					draw_set_transform_matrix(base)
					avatars[model].draw_body(self,Vector2.ZERO,animation,2,Color.WHITE,true)
					Equipment.draw_armor(self,Vector2.ZERO,animation,2,["male","female"][model],worn)
					# Shield drawing resets transforms; draw its source with the same pose at 3x.
					var hand:=Vector2(16+facing*14,22)
					draw_texture_rect(Gear.icon(names[3]),Rect2(hand-Vector2(12,16),Vector2(24,32)),false)
					draw_set_transform_matrix(Transform2D.IDENTITY)
				for i in range(4):draw_texture_rect(Gear.icon(names[i]),Rect2(cell+Vector2(36+i*90,244),Vector2(40,40)),false)
func run() -> void:
	var g=load("res://main.tscn").instantiate();root.add_child(g);g.set_process(false);g.hide();await process_frame
	var view:=SubViewport.new();view.size=Vector2i(1280,720);view.render_target_update_mode=SubViewport.UPDATE_ALWAYS;root.add_child(view)
	var poster:=Review.new();poster.g=g;poster.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST;view.add_child(poster)
	await process_frame;await RenderingServer.frame_post_draw
	view.get_texture().get_image().save_png("res://.godot/equipment_models_preview.png");view.queue_free()
	setup(g);set_armor(g,"iron");give_equip(g,"Iron Shield");give_equip(g,"Scout Charm");give_equip(g,"Bone Ward")
	g.inventory={"Fiber Hood":1,"Fiber Vest":1,"Fiber Boots":1,"Copper Helmet":1,"Copper Cuirass":1,"Copper Boots":1,"Wood Shield":1,"Copper Shield":1}
	g.inventory_open=true;g.equipment.gear_open=true;g.show();g.queue_redraw()
	await process_frame;await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://.godot/equipment_backpack_preview.png")
	g.equipment.gear_open=false;g.queue_redraw()
	await process_frame;await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://.godot/equipment_items_preview.png")
	# Discard the artificial inventory-test terrain before rendering real gameplay.
	g.worlds.clear();g.world={}
	await g._open_planet(0)
	g.inventory_open=false;g.equipment.gear_open=false;g.expedition.folded=true
	select(g,"Iron Sword");g.attack_cooldown=0;g.time_of_day=0.25
	g.aim_screen=g.player_pos+Vector2(80,11)-g.camera_pos;g.secondary_held=true
	g.equipment.begin_block(g.player_pos+Vector2(80,11));g.notice_timer=0;g.queue_redraw()
	await process_frame;await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://.godot/equipment_blocking_preview.png")
	print("EQUIPMENT_PREVIEW three armor tiers on both models plus equipment/items backpack views")
	quit()
