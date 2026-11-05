extends "res://tests/guardian_check.gd"

func capture(g, filename: String) -> void:
	g.notice_timer=0;g.queue_redraw();await process_frame;await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://.godot/"+filename+".png")

func run() -> void:
	var g=load("res://main.tscn").instantiate();root.add_child(g);g.set_process(false);await process_frame
	g.settings_path="user://guardian_preview_settings.json";g.expedition.start()
	g.galaxy_seed=1729;g.star_index=0;g._make_galaxy();g._make_system();await g._open_planet(0)
	var guardian:Dictionary={}
	for c:Dictionary in g.world.creatures:
		if c.get("mining_guardian",false):guardian=c;break
	check(not guardian.is_empty(),"Actual new expedition did not create mining guardian")
	if guardian.is_empty():quit(1);return
	check(Guardian.fits(g.world,Guardian.box(guardian).position),"Generated guardian clips room")
	check(guardian.arena_right-guardian.arena_left>=500,"Generated chamber too small")
	g.expedition.data.stage=5;g.expedition.folded=true;g.time_of_day=.35;g.notice_timer=0
	g.player_pos=Vector2(float(guardian.x)-100,float(guardian.y)+20);g._update_camera()
	select(g,"Iron Sword");g.inventory["Iron Shield"]=1;g.equipment.equip("Iron Shield")
	for item in ["Iron Helmet","Iron Cuirass","Iron Boots"]:g.inventory[item]=1;g.equipment.equip(item)
	g.mouse_aim_direction=Vector2.RIGHT;g.mouse_aim_valid=true
	guardian.boss_state="warn_charge";guardian.boss_timer=.8;guardian.direction=-1
	await capture(g,"guardian_charge_preview")
	guardian.boss_state="warn_slam";guardian.boss_timer=.8
	await capture(g,"guardian_slam_preview")
	guardian.boss_state="recover";guardian.boss_timer=1.2;guardian.hp=160
	select(g,"Faultline Hammer");g.attack_cooldown=0;g._begin_tool_action("attack",Guardian.box(guardian).get_center())
	await capture(g,"guardian_reward_preview")
	g.scene_name="system";g.expedition.data.survey_array=true;g.selected_planet_index=4
	await capture(g,"guardian_system_preview")
	print("GUARDIAN_PREVIEW checks=",checks," failures=",failures)
	quit(0 if failures==0 else 1)
