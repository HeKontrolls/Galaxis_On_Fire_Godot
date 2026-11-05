extends RefCounted
const C=preload("res://scripts/equipment_catalog.gd")
const Avatar=preload("res://scripts/character_appearance.gd")
const Pose=preload("res://scripts/player_pose.gd")
const KEYS := ["head","chest","boots","shield","accessory1","accessory2"]
const LABELS := ["Helmet","Chest armor","Boots","Shield","Accessory 1","Accessory 2"]
var g
var slots := {}
var gear_open := false
var blocking := false
var guard := 100.0
var guard_wait := 0.0
var broken_time := 0.0

func bind(game) -> void:g=game;reset()
func reset() -> void:
	slots.clear()
	for key in KEYS:slots[key]=""
	guard=100;guard_wait=0;broken_time=0;blocking=false;gear_open=false
func snapshot() -> Dictionary:
	return {"slots":slots.duplicate(),"guard":guard,"guard_wait":guard_wait,"broken_time":broken_time}
func restore(value: Variant) -> void:
	reset()
	if not value is Dictionary:return
	var saved:Variant=value.get("slots",{})
	if saved is Dictionary:
		for key in KEYS:
			var item:=str(saved.get(key,""))
			if accepts(key,item) and (not key.begins_with("accessory") or item not in slots.values()):slots[key]=item
	guard=clampf(float(value.get("guard",100)),0,100)
	guard_wait=clampf(float(value.get("guard_wait",0)),0,2)
	broken_time=clampf(float(value.get("broken_time",0)),0,2)
static func accepts(key: String,item: String) -> bool:
	return key in KEYS and C.ITEMS.has(item) and (str(C.ITEMS[item].slot)==key or (key.begins_with("accessory") and C.ITEMS[item].slot=="accessory"))
func equip(item: String,key := "") -> bool:
	if not C.ITEMS.has(item) or int(g.inventory.get(item,0))<=0:return false
	if key.is_empty():
		key=str(C.ITEMS[item].slot)
		if key=="accessory":key="accessory1" if str(slots.get("accessory1","")).is_empty() else "accessory2"
	if not accepts(key,item):g._show_notice("That item does not fit this equipment slot");return false
	if key.begins_with("accessory") and item in slots.values():g._show_notice("Only one of each accessory can be worn");return false
	var old:=str(slots.get(key,""))
	if old==item:return false
	g.inventory[item]=int(g.inventory[item])-1
	slots[key]=item
	if not old.is_empty():g._add_item(old,1)
	blocking=false;g._refresh_hotbar();g._show_notice("Equipped "+item)
	return true
func unequip(key: String) -> bool:
	var item:=str(slots.get(key,""))
	if item.is_empty():return false
	slots[key]="";g._add_item(item,1);blocking=false;g._show_notice("Returned "+item+" to backpack")
	return true
func defense() -> int:
	var total:=0
	for item in slots.values():total+=int(C.ITEMS.get(item,{}).get("defense",0))
	return total
func movement() -> float:
	var value:=1.0
	for item in slots.values():
		value-=float(C.ITEMS.get(item,{}).get("weight",0));value+=float(C.ITEMS.get(item,{}).get("speed",0))
	return clampf(value,0.7,1.2)*(0.55 if blocking else 1.0)
func can_block() -> bool:
	var selected:String=g.place_items[g.selected_slot]
	return not str(slots.get("shield","")).is_empty() and (selected.is_empty() or g.Tools.family(g.equipped_tool)=="Sword") and not g._world_input_blocked(g.aim_screen) and not g.magic.codex_open
func begin_block(target: Vector2) -> bool:
	if not can_block():return false
	g._set_mouse_world_target(target)
	blocking=guard>0 and broken_time<=0 and g.attack_cooldown<=0
	return true
func update(delta: float) -> void:
	broken_time=maxf(0,broken_time-delta)
	blocking=g.secondary_held and can_block() and guard>0 and broken_time<=0 and g.attack_cooldown<=0
	var waited:=guard_wait
	guard_wait=maxf(0,guard_wait-delta)
	if not blocking and not g.secondary_held:guard=minf(100,guard+maxf(0,delta-waited)*25.0)
func absorb(damage: int, source: Vector2) -> int:
	if damage<=0:return 0
	var result:=maxi(1,damage-floori(defense()*0.5))
	var incoming:Vector2=source-(g.player_pos+Vector2(8,11))
	var aim:Vector2=g.mouse_aim_direction if g.mouse_aim_valid else Vector2(g.facing,0)
	if blocking and can_block() and incoming.length_squared()>0.01 and incoming.normalized().dot(aim.normalized())>=0.5:
		var cost:=maxf(8,damage*2.0)
		if guard>=cost:
			guard-=cost;guard_wait=0.8
			result=ceili(result*(1-float(C.ITEMS[slots.shield].block)))
			g._show_notice("Shield blocked the hit")
		else:
			guard=0;guard_wait=1.5;broken_time=1.5;blocking=false;g._show_notice("Guard broken! Lower your shield to recover")
	return g.magic.absorb(result)

static func draw_armor(canvas: CanvasItem, at: Vector2, animation: String, frame: int, model: String, worn: Dictionary) -> void:
	for key in ["boots","chest","head"]:
		var item:=str(worn.get(key,""))
		if not C.ITEMS.has(item):continue
		var material:=str(C.ITEMS[item].material)
		canvas.draw_texture_rect_region(C.texture(material+"_"+model+"_"+key),Rect2(at,Vector2(32,40)),Avatar.region(animation,frame))
static func draw_sleeve(canvas: CanvasItem,worn: Dictionary) -> void:
	var item:=str(worn.get("chest",""))
	if C.ITEMS.has(item):canvas.draw_texture(C.texture(str(C.ITEMS[item].material)+"_arm"),Vector2(-4,-1))
static func draw_shield(canvas: CanvasItem, at: Vector2, aim: Vector2, facing: int, raised: bool, worn: Dictionary, arm: Texture2D) -> void:
	var item:=str(worn.get("shield",""))
	if not C.ITEMS.has(item):return
	var direction:=aim.normalized() if raised else Vector2(facing,0)
	var hand:=Pose.shoulder(at,facing)+direction*(17 if raised else 10)+Vector2(0,0 if raised else 10)
	canvas.draw_set_transform_matrix(Pose.arm_transform(Pose.shoulder(at,facing),hand,facing))
	canvas.draw_texture(arm,Vector2(-4,-1));draw_sleeve(canvas,worn)
	canvas.draw_set_transform(hand,direction.angle() if raised else 0)
	canvas.draw_texture_rect(C.icon(item),Rect2(-12,-16,24,32),false)
	canvas.draw_set_transform_matrix(Transform2D.IDENTITY)

func panel() -> Rect2:return Rect2(Vector2(g.window_positions.inventory),Vector2(466,382))
func slot_rect(index: int) -> Rect2:return Rect2(panel().position+Vector2(16+(index%2)*220,88+(index/2)*76),Vector2(214,70))
func slot_at(point: Vector2) -> String:
	if not g.inventory_open or not gear_open:return ""
	for i in range(KEYS.size()):
		if slot_rect(i).has_point(point):return KEYS[i]
	return ""
func click(point: Vector2,button: int) -> bool:
	if not g.inventory_open:return false
	if Rect2(panel().position+Vector2(134,6),Vector2(80,26)).has_point(point):
		if button==MOUSE_BUTTON_LEFT:gear_open=not gear_open;g._cancel_inventory_drag()
		return true
	if not gear_open or not panel().has_point(point):return false
	if point.y<panel().position.y+38:
		return point.x>=panel().position.x+216 and point.x<panel().position.x+427
	var key:=slot_at(point)
	if not key.is_empty() and button in [MOUSE_BUTTON_LEFT,MOUSE_BUTTON_RIGHT]:unequip(key)
	return true
func drag(point: Vector2,item: String) -> bool:
	var key:=slot_at(point)
	if key.is_empty():return false
	equip(item,key);return true
func draw_tab() -> void:
	var rect:=Rect2(panel().position+Vector2(134,6),Vector2(80,26))
	g._rounded_box(rect,Color("2a4148"),Color("9db6b5"),5,1)
	g._button_text(rect,"Items" if gear_open else "Gear",14,Color("e5d6b0"))
func draw_panel() -> void:
	var at:=panel().position
	g.draw_rect(Rect2(at+Vector2(218,3),Vector2(208,31)),Color("08080c"))
	g._text("EQUIPMENT",at+Vector2(242,25),14,Color("d5c6a5"))
	g._text("Defense %d   |   Movement %d%%" % [defense(),roundi(movement()*100)],at+Vector2(18,65),16,Color("e9cf94"))
	for i in range(KEYS.size()):
		var rect:=slot_rect(i);var item:=str(slots.get(KEYS[i],""))
		g._rounded_box(rect,Color("182832"),Color("69828e"),5,1)
		var icon_rect:=Rect2(rect.position+Vector2(8,10),Vector2(46,46))
		g._rounded_box(icon_rect,Color("0d171e"),Color("536975"),4,1)
		if not item.is_empty():g._draw_item_icon(item,icon_rect.grow(-5))
		g._button_text(Rect2(rect.position+Vector2(62,6),Vector2(144,24)),LABELS[i],12,Color("94afb7"),false,Vector2.ZERO)
		g._button_text(Rect2(rect.position+Vector2(62,28),Vector2(144,32)),item if not item.is_empty() else "Empty",13,Color("ead6ae"),false,Vector2.ZERO)
	g._text("Click a slot to return its item to the backpack",at+Vector2(18,332),13,Color("c0ced0"))
	g._text("Hold RMB with melee / empty hand to block",at+Vector2(18,356),13,Color("c0ced0"))
func draw_guard() -> void:
	var has_shield:=not str(slots.get("shield","")).is_empty()
	if not has_shield and defense()==0 and is_equal_approx(movement(),1.0):return
	var at:=Vector2(16,175)
	g._rounded_box(Rect2(at,Vector2(148,32 if has_shield else 22)),Color("101c24"),Color("69828e"),5,1)
	if not has_shield:
		g._text("DEF %d   MOVE %d%%" % [defense(),roundi(movement()*100)],at+Vector2(9,15),10,Color("e7d6a7"))
		return
	g._text("GUARD %d   DEF %d" % [roundi(guard),defense()],at+Vector2(9,14),10,Color("e7d6a7"))
	g.draw_rect(Rect2(at+Vector2(9,22),Vector2(130,4)),Color("3a4249"))
	g.draw_rect(Rect2(at+Vector2(9,22),Vector2(130*guard/100,4)),Color("d67b60") if broken_time>0 else Color("79bdcd"))
