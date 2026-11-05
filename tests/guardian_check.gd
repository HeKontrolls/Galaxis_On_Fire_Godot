extends "res://tests/ranged_weapons_check.gd"
const Guardian = preload("res://scripts/mining_guardian.gd")
const Danger = preload("res://scripts/planet_danger.gd")
const State = preload("res://scripts/network_state.gd")
var checks := 0
func check(ok: bool, message: String) -> void:
	checks += 1; super.check(ok,message)

func setup(g) -> Dictionary:
	fresh(g); g.equipment.reset(); g.magic.ward=0; g.magic.ward_time=0; g.damage_cooldown=0
	g.dev_travel_unlocked=false; g.sound.clips.clear()
	var c := {"x":9680.0,"y":1582.0,"home_x":9700.0,"hp":90,"max_hp":90,"alive":true,"quest_guardian":true,"direction":-1}
	g.world.creatures=[c]; Guardian.prepare(g.world)
	return c

func danger_checks(g) -> void:
	for climate in range(8):
		fresh(g);g.world.climate=climate
		var c:=enemy(9680,100);c.damage=10;c.hp=50
		Danger.apply(g.world,c)
		var rank:=Danger.level(climate)
		check(rank in [1,2,3] and c.max_hp==100+(rank-1)*25,"Danger HP scale: %d"%climate)
		check(c.damage==10+(rank-1)*2 and c.hp==ceili(c.max_hp*0.5),"Danger damage/injury preservation")
		var saved:=c.duplicate(true);Danger.apply(g.world,c)
		check(c==saved,"Danger compounded on repeat visit")
		check(Danger.loot_count(c)==rank,"Danger material reward multiplier")
		g.ranged.hit_creature(c,1000,Vector2.ZERO)
		check(g.world.drops.size()==1 and int(g.world.drops[0].count)==rank,"Ranged kill did not award danger loot")
		var dead:=enemy(9700,0);dead.alive=false;Danger.apply(g.world,dead)
		check(not dead.alive and dead.hp<=0,"Danger resurrected a corpse")
		check(not Danger.caption(climate).is_empty() and not Danger.survey(climate).is_empty(),"Missing planet description")
	fresh(g);g.world.climate=4;var c:=enemy(g.player_pos.x+28,10);Danger.apply(g.world,c);g.world.creatures=[c]
	select(g,"Faultline Hammer");g._attack(g.player_pos+Vector2(80,11))
	check(not c.alive and g.world.drops.size()==1 and g.world.drops[0].count==3,"Melee did not award extreme loot")

func guardian_checks(g) -> void:
	var c:=setup(g)
	check(c.mining_guardian and c.hp==360 and Guardian.fits(g.world,Guardian.box(c).position),"Legacy living guardian did not migrate safely")
	var original:=c.duplicate(true);Guardian.prepare(g.world)
	check(c==original,"Guardian migration repeated/healed boss")
	check(Ranged.hit_box(c)==Guardian.box(c),"Boss projectile hitbox does not match body")
	var before:int=g.health;c.boss_timer=0.01;Guardian.update(g,c,0.02)
	check(c.boss_state=="warn_charge" and g.health==before,"Charge warning caused instant damage")
	var direction:int=c.direction;g.player_pos.x=float(c.x)+100
	Guardian.update(g,c,0.05)
	check(c.direction==direction,"Warning retargeted direction after committing attack")
	# The resting machine has no invisible contact attack, including guest contact code.
	g.player_pos=Guardian.box(c).position;g.network._contact_damage(g,0.1)
	check(g.health==before,"Guardian hurt by ordinary creature contact while warning")
	# Real charge uses the full body collider and cannot tunnel through a placed wall.
	c=setup(g);c.boss_state="charge";c.boss_timer=0.65;c.direction=1
	var wall:=Vector2i(610,98)
	for y in range(94,100):g._edit_tile(Vector2i(wall.x,y),3,false)
	for i in range(20):Guardian.update(g,c,0.05)
	check(Guardian.box(c).end.x<=wall.x*16 and Guardian.fits(g.world,Guardian.box(c).position),"Charge tunneled into a wall")
	check(c.boss_state=="recover","Wall collision did not open a recovery window")
	# Slam is one event, can be jumped and respects solid cover and equipment.
	c=setup(g);g.player_pos=Vector2(float(c.x)-48,1572);c.boss_state="warn_slam";c.boss_timer=0.01
	Guardian.update(g,c,0.02)
	check(g.health==78 and c.boss_state=="slam","Ground slam failed to damage a grounded target once")
	g.damage_cooldown=0;Guardian.update(g,c,0.05)
	check(g.health==78,"Slam dealt repeated per-frame damage")
	c=setup(g);g.player_pos=Vector2(float(c.x)-48,1520);c.boss_state="warn_slam";c.boss_timer=0.01;Guardian.update(g,c,0.02)
	check(g.health==100,"Jumping failed to evade ground slam")
	c=setup(g);g.player_pos=Vector2(float(c.x)-48,1572)
	select(g,"Sword");g.inventory["Iron Shield"]=1;g.equipment.equip("Iron Shield");g.attack_cooldown=0
	g.secondary_held=true;g.equipment.begin_block(Guardian.box(c).get_center())
	Guardian.hurt(g,c,Guardian.slam_area(c),22)
	check(g.health==96 and g.equipment.guard==56,"Boss attack bypassed shield/guard costs")
	c=setup(g);g.player_pos=Vector2(float(c.x)-48,1572)
	for y in range(94,100):g._edit_tile(Vector2i(603,y),3,false)
	Guardian.hurt(g,c,Guardian.slam_area(c),22)
	check(g.health==100,"Ground slam penetrated a wall")
	c=setup(g);g.dev_invulnerable=true;g.player_pos=Vector2(float(c.x)-48,1572);Guardian.hurt(g,c,Guardian.slam_area(c),22)
	check(g.health==100,"Boss ignored developer invulnerability")
	c=setup(g);g.player_pos=Vector2(float(c.x)-48,1572);g.health=1;Guardian.hurt(g,c,Guardian.slam_area(c),22)
	check(g.health==100 and g.player_pos==g.world.spawn,"Boss death did not respawn player")
	c=setup(g);c.boss_state="warn_slam";g.player_pos=Vector2(32,32);Guardian.update(g,c,0.02)
	check(c.boss_state=="idle" and c.hp==360,"Unattended guardian did not stop attacking")
	# Damaged, defeated and obstructed legacy records preserve the player's world.
	c=setup(g);c.erase("mining_guardian");c.x=9680;c.y=1582;c.hp=45;c.max_hp=90;Guardian.prepare(g.world)
	check(c.hp==180,"Migration healed injured guardian")
	c=setup(g);c.erase("mining_guardian");c.alive=false;c.hp=0;Guardian.prepare(g.world)
	check(not c.has("mining_guardian") and not c.alive,"Migration resurrected defeated guardian")
	c=setup(g);c.erase("mining_guardian");c.x=9680;c.y=1582
	g._edit_tile(Vector2i(604,97),3,false);var tiles:PackedByteArray=g.world.tiles.duplicate();Guardian.prepare(g.world)
	check(not c.has("mining_guardian") and tiles==g.world.tiles,"Migration destroyed old construction")
	# Every attack family reaches the new collider; machine resists knockback.
	for weapon in ["Iron Sword","Iron Spear","Faultline Hammer"]:
		c=setup(g);g.player_pos=Vector2(float(c.x)-30,1572);select(g,weapon);g.attack_cooldown=0
		var x:float=c.x;g._attack(Guardian.box(c).get_center())
		check(c.hp<360 and c.x==x,"Melee could not hit boss or pushed it into terrain: "+weapon)
	for side in [-1,1]:
		c=setup(g);g.player_pos=Vector2(float(c.x)+(-30 if side==-1 else 78),1572);select(g,"Iron Sword");g.attack_cooldown=0
		g._attack(Guardian.box(c).get_center())
		check(c.hp<360,"Sword could not strike both sides of the larger guardian")
	c=setup(g);var x:float=c.x;g.ranged.hit_creature(c,20,Vector2.RIGHT)
	check(c.hp==340 and c.x==x,"Projectile damage or boss knockback resistance failed")
	g.spellcraft.damage(c,25,Vector2.RIGHT,"spark")
	check(c.hp==315,"Spell damage did not reach guardian")
	# All guest targets take the same host-authored attack; no client-side simulation.
	c=setup(g);var guest=load("res://main.tscn").instantiate();root.add_child(guest);guest.set_process(false)
	guest.world=g.world;guest.star_index=g.star_index;guest.planet_index=g.planet_index;guest.scene_name="planet"
	guest._reset_world_environment();guest.player_pos=Vector2(float(c.x)-48,1572);guest.health=100;guest.damage_cooldown=0
	g.network.role="host";g.network.actors[999]=guest;g.player_pos=Vector2(float(c.x)+65,1572)
	Guardian.hurt(g,c,Guardian.slam_area(c),22)
	check(g.health==78 and guest.health==78,"Shared guardian attack did not hit both host and guest")
	g.network.actors.clear();g.network.role="offline";guest.queue_free()

func rewards(g) -> void:
	var c:=setup(g);g.expedition.start();g.expedition.data.home=g._world_key();g.expedition.data.stage=5
	g.expedition.data.site=[9696,1600];g.expedition.data.ship=[9600,1600];g.player_pos=Vector2(9696,1572)
	g.expedition.interact()
	check(not g.expedition.data.core and not g.inventory.has("Faultline Hammer"),"Salvage claimed before guardian defeat")
	c.alive=false;c.hp=0;g.expedition.interact()
	check(g.expedition.data.core and g.inventory.get("Faultline Hammer",0)==1 and g.inventory.get("Survey Core",0)==1,"Guardian salvage missing")
	g.expedition.claim_guardian_reward();g.expedition.interact()
	check(g.inventory["Faultline Hammer"]==1 and g.inventory["Survey Core"]==1,"Salvage duplicated")
	g.expedition.data.stage=7;g.player_pos=Vector2(9600,1572);g.inventory["Iron Ingot"]=6;g.inventory["Crystal"]=2
	var inv:Dictionary=g.inventory.duplicate()
	check(not g.expedition.install_survey() and inv==g.inventory,"Incomplete upgrade consumed ingredients")
	g.inventory["Crystal"]=3;g.expedition.interact()
	check(g.expedition.data.get("survey_array",false) and g.inventory["Survey Core"]==0 and g.inventory["Iron Ingot"]==0 and g.inventory["Crystal"]==0,"Pod interaction did not install survey array")
	check(g.scene_name=="planet" and not g.expedition.install_survey(),"Installing launched or installed twice")
	var state:Dictionary=bytes_to_var(var_to_bytes(State.shared(g)))
	check(state.expedition.survey_array and state.expedition.guardian_reward,"Shared state lost progression flags")
	check(g.Tools.has_item("Faultline Hammer") and not g.Tools.can_harvest("Faultline Hammer",3),"Reward weapon can mine terrain")
	g.world.creatures[0].hp=0;g._save_game();g._load_game()
	while g.scene_name=="loading":await process_frame
	check(g.expedition.data.survey_array and g.expedition.data.guardian_reward and g.inventory.get("Faultline Hammer",0)==1,"Save/load lost reward or ship upgrade")
	check(not g.expedition.guardian_alive(),"Defeated boss resurrected on load")
	g.expedition.claim_guardian_reward()
	check(g.inventory["Faultline Hammer"]==1,"Save/load allowed duplicate guardian reward")

func run() -> void:
	var g=load("res://main.tscn").instantiate();root.add_child(g);g.set_process(false);await process_frame
	g.save_path="user://guardian_check.json";g.settings_path="user://guardian_check_settings.json"
	danger_checks(g);guardian_checks(g);await rewards(g)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(g.save_path));DirAccess.remove_absolute(ProjectSettings.globalize_path(g.settings_path))
	print("GUARDIAN checks=",checks," failures=",failures)
	quit(0 if failures==0 else 1)
