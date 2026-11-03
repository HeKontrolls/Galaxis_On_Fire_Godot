extends "res://tests/housing_check.gd"

func key(g,code: Key) -> void:
	var event:=InputEventKey.new();event.keycode=code;event.pressed=true;g._input(event)
func click(g,local: Vector2) -> void:
	var event:=InputEventMouseButton.new();event.button_index=MOUSE_BUTTON_LEFT;event.pressed=true;event.position=Vector2(g.window_positions.dev)+local;g._input(event)

func cached_planets(g) -> void:
	var template:Dictionary=g.world.duplicate(true)
	for index in range(8):
		var data:Dictionary=template.duplicate(true)
		data.climate=g._planet_climate(index);data.seed=g._planet_seed(index)
		data.ocean_fill_version=g.OceanPreparation.VERSION;data.ice_spires_version=2
		g.worlds["%d_%d" % [g.star_index,index]]=data

func run() -> void:
	var g=load("res://main.tscn").instantiate();root.add_child(g);g.set_process(false);await process_frame
	g.save_path="user://dev_travel_check.json";g.settings_path="user://dev_travel_settings.json"
	g.new_game_name="Developer travel test";g.seed_text="711629";g._start_new_game()
	check(not g.dev_travel_unlocked and not g.expedition.can_land(3),"New games must retain first-landing restrictions")
	var before:Dictionary=g.expedition.data.duplicate(true)
	key(g,KEY_F3)
	check(g.dev_mode and g.dev_travel_unlocked and g.dev_controls.active_tab=="travel","F3 did not open Travel from galaxy")
	# An overlay click must not select the star behind it.
	var star_before:int=g.star_index
	click(g,Vector2(555,380))
	check(g.star_index==star_before and g.scene_name=="galaxy","Developer clicks leaked into galaxy selection")
	key(g,KEY_ESCAPE)
	check(not g.dev_mode and g.scene_name=="galaxy" and g.dev_travel_unlocked,"Escape should close the window while retaining free travel")
	key(g,KEY_F3);click(g,Vector2(400,98))
	check(g.scene_name=="system" and not g.dev_mode,"Galaxy Browse This System failed")
	key(g,KEY_F3);key(g,KEY_F3)
	check(g.scene_name=="system" and not g.dev_mode,"F3 toggle failed in solar system")
	# All eight buttons must map the selected star's rotated climate order correctly.
	fixture(g);g.star_index=3;g._make_system();cached_planets(g);g.scene_name="system"
	g.expedition.data=before.duplicate(true)
	for climate in range(8):
		var fit:Dictionary=g.UIText.layout(g.dev_controls.font,g.WG.NAMES[climate],g.dev_controls.travel_rect(climate),18,false,Vector2(8,3))
		check(fit.text==g.WG.NAMES[climate] and float(fit.width)<=fit.area.size.x,"Planet type label does not fit its button")
		key(g,KEY_F3)
		click(g,g.dev_controls.travel_rect(climate).get_center())
		while g.scene_name=="loading":await process_frame
		check(g.scene_name=="planet" and int(g.world.climate)==climate and not g.dev_mode,"Wrong developer landing for climate %d" % climate)
		check(g.expedition.data==before,"Developer landing modified expedition state")
		check(g.expedition.can_launch(),"Developer surface visit cannot return to orbit")
		key(g,KEY_G)
		check(g.scene_name=="system" and not g.paused,"G cannot leave developer surface visit")
	# Existing campaign home and current objective survive testing.
	g.expedition.data.home="0_0";g.expedition.data.stage=3
	var campaign:Dictionary=g.expedition.data.duplicate(true)
	await g._dev_visit_climate(4)
	g.expedition.gathered("Wood",20);g.expedition.record_item("Iron Pickaxe");g.expedition.placed("Planks",Vector2i(600,99));g.expedition.update(1);g.expedition.talk()
	check(g.expedition.data==campaign,"Developer actions advanced or rewrote campaign progress")
	# Direct harvest credit also remains paused on the original home world.
	g.expedition.data.home=g._world_key()
	g.player_pos=Vector2(600*16,1600-28);g._update_camera();g.equipped_tool="Hand"
	g._edit_tile(Vector2i(601,100),12);g._edit_tile(Vector2i(601,99),16)
	g._farm_interaction(Vector2i(601,99),"Hand","")
	check(not bool(g.expedition.data.harvested),"Developer corn harvest completed the campaign food objective")
	g.expedition.data.home="0_0"
	# Switching types from a surface must save that surface's player position.
	g.player_pos+=Vector2(32,0)
	var prior_key:String=g._world_key();var prior_pos:Vector2=g.player_pos
	key(g,KEY_F3)
	click(g,g.dev_controls.tab_rect(5).get_center())
	click(g,g.dev_controls.travel_rect(6).get_center())
	while g.scene_name=="loading":await process_frame
	check(g.worlds[prior_key].player_pos==prior_pos and int(g.world.climate)==6,"Surface-to-surface developer travel lost position or chose wrong type")
	key(g,KEY_F3);click(g,g.dev_controls.tab_rect(5).get_center());click(g,Vector2(100,98))
	check(not g.dev_travel_unlocked and g.scene_name=="system","Disabling travel stranded the player on a locked test planet")
	key(g,KEY_F3);click(g,g.dev_controls.travel_rect(6).get_center())
	while g.scene_name=="loading":await process_frame
	g._save_game();g.dev_travel_unlocked=false;g._load_game()
	while g.scene_name=="loading":await process_frame
	check(g.dev_travel_unlocked and g.scene_name=="planet" and int(g.world.climate)==6,"Developer save reload got trapped by expedition landing restrictions")
	check(g.expedition.data==JSON.parse_string(JSON.stringify(campaign)),"Reloading developer travel changed campaign")
	key(g,KEY_F3);click(g,g.dev_controls.tab_rect(5).get_center());click(g,Vector2(400,98))
	check(g.scene_name=="system" and not g.dev_mode,"Return to Orbit control failed")
	key(g,KEY_F3);click(g,Vector2(100,98))
	check(not g.dev_travel_unlocked and not g.expedition.can_land(g.selected_planet_index) and not g.expedition.can_launch(),"Turning free travel off did not restore campaign restrictions")
	key(g,KEY_ESCAPE)
	# Normal campaign eligibility is unchanged; old saves default to no bypass.
	g.star_index=0;check(g.expedition.can_land(0),"Campaign home became inaccessible")
	var parsed:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(g.save_path));parsed.erase("dev_travel_unlocked");parsed.scene="system"
	var file:=FileAccess.open(g.save_path,FileAccess.WRITE);file.store_string(JSON.stringify(parsed));file.close()
	g.dev_travel_unlocked=true;g._load_game()
	check(not g.dev_travel_unlocked,"Old saves inherited a developer bypass")
	g.dev_travel_unlocked=true;g._start_new_game()
	check(not g.dev_travel_unlocked and g.expedition.stage()==0,"New Game inherited developer travel")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(g.save_path));DirAccess.remove_absolute(ProjectSettings.globalize_path(g.settings_path))
	print("DEV_TRAVEL galaxy/system F3, eight climates, orbit, isolated input, campaign preservation, saves and reset failures=",failures)
	quit(0 if failures==0 else 1)

