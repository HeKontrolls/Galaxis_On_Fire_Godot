extends RefCounted
const C=preload("res://scripts/spellcraft_catalog.gd")
const Slots=preload("res://scripts/station_slots.gd")
const SIZE:=Vector2(760,520)
var g
var active_key:=""
var editing:=false
var selected_all:=false
var textures:Dictionary={}
func _init(game)->void:g=game
func is_open()->bool:return not active_key.is_empty() and g.scene_name=="planet" and g.inventory_open and g.world.get("alchemy",{}).has(active_key)
static func prepare(state:Dictionary)->void:
	if not state.has("inputs"):state.inputs=Slots.create(9)
	if not state.has("output"):state.output={}
	if not state.has("job"):state.job={}
	if not state.has("draft"):state.draft=C.draft()
	if not state.has("recipe"):state.recipe=0
	if not state.has("page"):state.page=0
func state()->Dictionary:return g.world.get("alchemy",{}).get(active_key,{})
func kind()->String:return str(state().get("item",""))
func open(entry:Dictionary)->void:
	g.stations.close(false);g.power_ui.close(false);g.interactions.close(false);g.magic.codex_open=false;g._stop_held_actions()
	active_key="%d,%d" % [int(entry.x),int(entry.y)]
	if not g.world.has("alchemy"):g.world.alchemy={}
	if not g.world.alchemy.has(active_key):g.world.alchemy[active_key]={"item":entry.item}
	prepare(g.world.alchemy[active_key]);editing=false
	g.inventory_open=true;g.crafting_open=false;g.dialogue_open=false
	if not g.window_positions.has("alchemy"):g.window_positions.alchemy=Vector2(20,105)
	g.window_positions.inventory=Vector2(790,190)
func close(close_pack:=true)->void:
	active_key="";editing=false;g._cancel_inventory_drag();g.dragged_window=""
	if close_pack:g.inventory_open=false
func slot_rect(zone:String,index:int)->Rect2:
	var at:Vector2=g.window_positions.alchemy
	return Rect2(at+Vector2(24+(index%3)*58,94+int(index/3)*58),Vector2(52,52)) if zone=="input" else Rect2(at+Vector2(24+(index%2)*58,370+int(index/2)*58),Vector2(52,52))
func deposit(item:String,count:=-1,index:=-1)->bool:
	if not is_open():return false
	var inputs:Array=state().inputs
	if index<0:index=Slots.free_slot(inputs,item)
	var amount:=int(g.inventory.get(item,0))
	if count>=0:amount=mini(amount,count)
	if amount<=0 or not Slots.accepts(inputs,index,item):return false
	var wear:Array=g.tool_wear.take(item,amount,g.inventory);Slots.put(inputs,index,item,amount,wear);g.inventory[item]=int(g.inventory[item])-amount;g._refresh_hotbar();return true
func withdraw(zone:String,index:int,one:=false)->bool:
	var s:=state()
	if zone=="input":
		var value:=Slots.take(s.inputs,index,1 if one else -1)
		if value.is_empty():return false
		g._add_item(str(value.item),int(value.count),value.get("wear",[]));return true
	var names:Array=s.output.keys();names.sort()
	if index>=names.size():return false
	var item:=str(names[index]);var count:=1 if one else int(s.output[item]);g._add_item(item,count);s.output[item]=int(s.output[item])-count
	if int(s.output[item])<=0:s.output.erase(item)
	return true
func accepts_drag(point:Vector2,item:String)->bool:
	if not is_open() or not Rect2(Vector2(g.window_positions.alchemy),SIZE).has_point(point):return false
	for i in range(9):
		if slot_rect("input",i).has_point(point):deposit(item,-1,i);return true
	return true
func start_brew()->bool:
	if not is_open() or kind()!="Cauldron":return false
	var s:=state();var recipe:Dictionary=C.BREWS[clampi(int(s.recipe),0,C.BREWS.size()-1)]
	if not s.job.is_empty():return false
	if (s.output.size()>=4 and not s.output.has(recipe.out)) or not Slots.ready(s.inputs,recipe.needs):g._show_notice("Put reagents and firewood in this cauldron; leave output space");return false
	Slots.consume(s.inputs,recipe.needs);s.job={"out":recipe.out,"count":recipe.count,"school":recipe.school,"needs":recipe.needs.duplicate(),"remaining":float(recipe.time)+3,"total":float(recipe.time)+3}
	return true
func update(delta:float)->void:
	for world:Dictionary in g.worlds.values():
		for key:String in world.get("alchemy",{}):
			var s:Dictionary=world.alchemy[key];prepare(s)
			if s.job.is_empty():continue
			var point:=Vector2i(int(key.get_slice(",",0)),int(key.get_slice(",",1)))
			var flooded:=false
			var water:PackedByteArray=world.get("water",PackedByteArray());var lava:PackedByteArray=world.get("lava",PackedByteArray())
			for y in range(point.y-1,point.y+1):
				for x in range(point.x,point.x+3):
					var index:int=y*g.WG.WIDTH+x
					if (index<water.size() and water[index]>96) or (index<lava.size() and lava[index]>0):flooded=true
			if flooded:continue
			s.job.remaining=maxf(0,float(s.job.remaining)-delta)
			if float(s.job.remaining)>0:continue
			var item:=str(s.job.out)
			if s.output.size()>=4 and not s.output.has(item):continue
			s.output[item]=int(s.output.get(item,0))+int(s.job.count);g.magic.earn(str(s.job.school),2);s.job={}
func remove_station(key:String)->void:
	var s:Dictionary=g.world.get("alchemy",{}).get(key,{})
	if s.is_empty():return
	var point:=Vector2i(int(key.get_slice(",",0)),int(key.get_slice(",",1)))
	for stack:Dictionary in s.get("inputs",[]):
		if not stack.is_empty():g._drop_item(str(stack.item),int(stack.count),point,stack.get("wear",[]))
	for item:String in s.get("output",{}):g._drop_item(item,int(s.output[item]),point)
	for item:String in s.get("job",{}).get("needs",{}):g._drop_item(item,int(s.job.needs[item]),point)
	g.world.alchemy.erase(key)
	if active_key==key:close()
func handle_input(event:InputEvent)->bool:
	if not is_open() or not editing or not event is InputEventKey or not event.pressed:return false
	if event.ctrl_pressed and event.keycode==KEY_A:selected_all=true;return true
	if event.keycode in [KEY_ESCAPE,KEY_ENTER,KEY_KP_ENTER]:editing=false;return true
	var draft:Dictionary=state().draft
	if event.keycode==KEY_BACKSPACE:draft.name="" if selected_all else str(draft.name).left(maxi(0,str(draft.name).length()-1));selected_all=false
	elif event.unicode>=32 and not event.ctrl_pressed:draft.name=(("" if selected_all else str(draft.name))+String.chr(event.unicode)).left(32);selected_all=false
	return true
func cycle_setting(key:String,options:Array)->void:
	if options.is_empty():g._show_notice("Learn an effect in the skill tree first (K)");return
	var draft:Dictionary=state().draft;draft[key]=options[posmod(options.find(draft.get(key,""))+1,options.size())]
func click(point:Vector2,button:int)->bool:
	if not is_open() or not Rect2(Vector2(g.window_positions.alchemy),SIZE).has_point(point):return false
	var local:Vector2=point-Vector2(g.window_positions.alchemy)
	if button==MOUSE_BUTTON_LEFT:
		if Rect2(720,6,30,28).has_point(local):close();return true
		if Rect2(0,0,714,36).has_point(local):g._start_window_drag("alchemy",point);return true
	for zone:String in ["input","output"]:
		for i in range(9 if zone=="input" else 4):
			if slot_rect(zone,i).has_point(point):withdraw(zone,i,button==MOUSE_BUTTON_RIGHT);return true
	if button!=MOUSE_BUTTON_LEFT:return true
	editing=false
	if kind()=="Alchemy Desk":
		if Rect2(230,84,502,30).has_point(local):editing=true;selected_all=true;return true
		for pair in [["focus",Rect2(230,122,244,30)],["form",Rect2(488,122,244,30)],["first",Rect2(230,160,244,30)],["second",Rect2(488,160,244,30)]]:
			if pair[1].has_point(local):
				var options:Array=["Wand","Staff","Tome"] if pair[0]=="focus" else (g.spellcraft.forms() if pair[0]=="form" else (g.spellcraft.effects() if pair[0]=="first" else ["None"]+g.spellcraft.effects()))
				cycle_setting(pair[0],options);return true
		for i in range(3):
			if Rect2(230+i*172,198,158,30).has_point(local):
				var setting:String=["power","duration","area"][i]
				if setting=="area" and str(state().draft.form) not in ["Burst","Chain"]:return true
				if setting=="duration" and not C.timed_effect(str(state().draft.first)) and not C.timed_effect(str(state().draft.second)):return true
				state().draft[setting]=1+int(state().draft[setting])%3;return true
		if Rect2(260,370,220,40).has_point(local):g.spellcraft.inscribe(state().draft,state().inputs,state().output)
	else:
		for direction in [-1,1]:
			if Rect2(646 if direction<0 else 702,48,32,28).has_point(local):state().page=posmod(int(state().page)+direction,ceili(C.BREWS.size()/4.0));return true
		for row in range(4):
			var index:=int(state().page)*4+row
			if index<C.BREWS.size() and Rect2(230,86+row*48,502,43).has_point(local):state().recipe=index;return true
		if Rect2(260,370,220,40).has_point(local):start_brew()
	return true
func text(rect:Rect2,label:String,size:=14,color:=Color("d5dbd4"))->void:g._button_text(Rect2(Vector2(g.window_positions.alchemy)+rect.position,rect.size),label,size,color,false,Vector2(6,2))
func button(rect:Rect2,label:String,enabled:=true)->void:
	g._rounded_box(Rect2(Vector2(g.window_positions.alchemy)+rect.position,rect.size),Color("2b4849") if enabled else Color("26313a"),Color("9eaa8b"),5,1);text(rect,label,14,Color("e6d5ae") if enabled else Color("86969e"))
func draw()->void:
	if not is_open():return
	var at:Vector2=g.window_positions.alchemy;var s:=state()
	g._rounded_box(Rect2(at,SIZE),Color("14232b"),Color("a6ac86"),9,1)
	text(Rect2(18,4,690,32),kind()+" [F / Esc to close]",19,Color("e7d6b5"));button(Rect2(720,6,30,28),"X")
	text(Rect2(24,50,182,30),"Stored reagents / blanks",13)
	for zone:String in ["input","output"]:
		var names:Array=s.output.keys();names.sort()
		for i in range(9 if zone=="input" else 4):
			var box:=slot_rect(zone,i);g._rounded_box(box,Color("213541"),Color("71868b"),5,1)
			var stack:Dictionary=s.inputs[i] if zone=="input" else ({"item":names[i],"count":s.output[names[i]]} if i<names.size() else {})
			if not stack.is_empty():g._draw_item_icon(str(stack.item),Rect2(box.position+Vector2(8,5),Vector2(36,36)));g._text(str(stack.count),box.position+Vector2(28,46),12)
	text(Rect2(24,340,180,24),"Take finished items",13,Color("bdd5ad"))
	if kind()=="Alchemy Desk":
		var d:Dictionary=s.draft;button(Rect2(230,84,502,30),("Name: "+str(d.name))+(" |" if editing else ""))
		button(Rect2(230,122,244,30),"Focus: "+str(d.focus));button(Rect2(488,122,244,30),"Form: "+str(d.form))
		button(Rect2(230,160,244,30),"Primary: "+str(d.first));button(Rect2(488,160,244,30),"Secondary: "+str(d.second))
		for i in range(3):
			var key:String=["power","duration","area"][i]
			var enabled:bool=(key!="area" or str(d.form) in ["Burst","Chain"]) and (key!="duration" or C.timed_effect(str(d.first)) or C.timed_effect(str(d.second)))
			button(Rect2(230+i*172,198,158,30),key.capitalize()+": "+(str(d[key]) if enabled else "n/a"),enabled)
		var error:String=g.spellcraft.validate(d)
		if error.is_empty():
			var compiled:Dictionary=g.spellcraft.compile(d);text(Rect2(230,238,502,25),"%.0f mana | %.1fs recovery | %s" % [compiled.mana,compiled.cooldown,compiled.school],14,Color("bdd9ad"))
			text(Rect2(230,266,502,25)," + ".join(compiled.effects),14)
		else:text(Rect2(230,238,502,50),error,14,Color("e0b198"))
		text(Rect2(24,292,708,44),"Needs: "+g._recipe_needs(g.spellcraft.needs(d)),13)
		button(Rect2(260,370,220,40),"Inscribe unique spell",error.is_empty())
		text(Rect2(260,420,472,44),"K: learn effects and delivery forms. Stronger tuning raises mana and reagent costs.",13)
	else:
		button(Rect2(646,48,32,28),"<");button(Rect2(702,48,32,28),">");text(Rect2(230,48,400,28),"Brews | Page %d/%d" % [int(s.page)+1,ceili(C.BREWS.size()/4.0)],14)
		for row in range(4):
			var index:=int(s.page)*4+row
			if index>=C.BREWS.size():break
			var recipe:Dictionary=C.BREWS[index];button(Rect2(230,86+row*48,502,43),("[Selected] " if index==int(s.recipe) else "")+"%s x%d | %.0fs" % [recipe.out,recipe.count,float(recipe.time)+3])
		var selected:Dictionary=C.BREWS[clampi(int(s.recipe),0,C.BREWS.size()-1)]
		text(Rect2(24,292,708,44),"Needs: "+g._recipe_needs(selected.needs),13)
		button(Rect2(260,370,220,40),"Brew selected recipe",s.job.is_empty())
		if not s.job.is_empty():
			var fraction:=1-float(s.job.remaining)/float(s.job.total);g.draw_rect(Rect2(at+Vector2(260,427),Vector2(450,8)),Color("39434c"));g.draw_rect(Rect2(at+Vector2(260,427),Vector2(450*fraction,8)),Color("8ebe91"))
			text(Rect2(260,443,472,25),"Brewing %s | %.1fs left" % [s.job.out,s.job.remaining],13)
		else:text(Rect2(260,423,472,42),"Each batch uses firewood and 3s of warming. Flooding pauses this cauldron.",13)
	text(Rect2(24,490,708,24),"Click backpack: store stack. Right-click: one. Drag into reagent slots. Click stored/output items to recover.",11,Color("9cb9bb"))
func draw_tooltip()->void:
	if not is_open() or not g.inventory_drag_item.is_empty():return
	var mouse:Vector2=g.get_viewport().get_mouse_position();var names:Array=state().output.keys();names.sort()
	for zone:String in ["input","output"]:
		for i in range(9 if zone=="input" else 4):
			if not slot_rect(zone,i).has_point(mouse):continue
			var stack:Dictionary=state().inputs[i] if zone=="input" else ({"item":names[i],"count":state().output[names[i]]} if i<names.size() else {})
			if not stack.is_empty():g._draw_item_tooltip(mouse,[g.Tools.display_name(str(stack.item))+" x%d" % int(stack.count)])
			return
