extends RefCounted
const C=preload("res://scripts/spellcraft_catalog.gd")
var g
func _init(game)->void:g=game
func text(rect:Rect2,label:String,size:=13,color:=Color("c8d5da"))->void:g._button_text(Rect2(Vector2(g.window_positions.magic)+rect.position,rect.size),label,size,color,false,Vector2(5,2))
func button(rect:Rect2,label:String,fill:=Color("293a50"))->void:
	g._rounded_box(Rect2(Vector2(g.window_positions.magic)+rect.position,rect.size),fill,Color("8497af"),5,1);text(rect,label,14,Color("ead9b7"))
func node_rect(index:int)->Rect2:
	var school:String=C.NODES[C.NODES.keys()[index]].school;var column:int=g.MagicCatalog.SCHOOLS.find(school);var row:=0
	for i in range(index):
		if str(C.NODES[C.NODES.keys()[i]].school)==school:row+=1
	return Rect2(16+column*148,133+row*79,138,69)
func click(point:Vector2,button_index:int)->bool:
	if not g.magic.codex_open or not g.inventory_open:return false
	var at:Vector2=g.window_positions.magic
	if not Rect2(at,g.magic.CODEX_SIZE).has_point(point):return false
	if button_index!=MOUSE_BUTTON_LEFT:return true
	var local:=point-at
	if Rect2(720,6,30,28).has_point(local):g.magic.close_codex();return true
	if Rect2(0,0,714,36).has_point(local):g._start_window_drag("magic",point);return true
	for tab in range(3):
		if Rect2(16+tab*174,43,164,30).has_point(local):g.spellcraft.codex_tab=tab;g.spellcraft.codex_page=0;return true
	for direction in [-1,1]:
		if Rect2(646 if direction<0 else 702,43,32,30).has_point(local):g.spellcraft.codex_page=maxi(0,g.spellcraft.codex_page+direction);return true
	if g.spellcraft.codex_tab==0:
		for i in range(C.NODES.size()):
			if node_rect(i).has_point(local):g.spellcraft.learn(str(C.NODES.keys()[i]));return true
	return true
func draw()->void:
	if not g.magic.codex_open or not g.inventory_open:return
	var at:Vector2=g.window_positions.magic;var craft=g.spellcraft
	g._rounded_box(Rect2(at,g.magic.CODEX_SIZE),Color("141f31"),Color("b4a6c6"),9,1)
	text(Rect2(16,3,696,32),"Arcane studies [K / Esc] | Skill points: %d" % craft.points(),19,Color("ecddb9"));button(Rect2(720,6,30,28),"X")
	for tab in range(3):button(Rect2(16+tab*174,43,164,30),["Skill tree","Spell guide","My creations"][tab],Color("3d5264") if tab==craft.codex_tab else Color("293a50"))
	button(Rect2(646,43,32,30),"<");button(Rect2(702,43,32,30),">")
	if craft.codex_tab==0:
		for i in range(g.MagicCatalog.SCHOOLS.size()):
			var school:String=g.MagicCatalog.SCHOOLS[i];text(Rect2(16+i*148,81,138,23),school+" "+str(g.magic.rank(school))+"/5",13,Color("e1c994"))
			text(Rect2(16+i*148,105,138,20),"%.0f XP" % float(g.magic.xp.get(school,0)),11)
		for i in range(C.NODES.size()):
			var node:=str(C.NODES.keys()[i]);var definition:Dictionary=C.NODES[node];var box:=node_rect(i)
			for parent:String in definition.needs:
				var parent_box:=node_rect(C.NODES.keys().find(parent))
				var route:=PackedVector2Array([at+Vector2(parent_box.position.x,parent_box.get_center().y),at+Vector2(box.position.x-5,parent_box.get_center().y),at+Vector2(box.position.x-5,box.get_center().y),at+Vector2(box.position.x,box.get_center().y)])
				g.draw_polyline(route,Color("718a89"),1,false)
		for i in range(C.NODES.size()):
			var node:=str(C.NODES.keys()[i]);var definition:Dictionary=C.NODES[node];var box:=node_rect(i)
			g._rounded_box(Rect2(at+box.position,box.size),Color("304e45") if craft.knows(node) else (Color("33435d") if craft.can_learn(node) else Color("202c3f")),Color("a0c3a0") if craft.knows(node) else Color("65788b"),5,1)
			text(Rect2(box.position+Vector2(3,2),Vector2(132,23)),str(definition.name),12,Color("e5d7ba"))
			text(Rect2(box.position+Vector2(3,24),Vector2(132,20)),"Learned" if craft.knows(node) else "Rank %d | 1 point" % definition.rank,11,Color("b6cfb6"))
			text(Rect2(box.position+Vector2(3,44),Vector2(132,21)),str(definition.detail),10)
		text(Rect2(16,461,728,24),"Click a connected node to learn. Three initial points; each school rank grants one more.",12)
		text(Rect2(16,487,728,22),"Brew essences, inscribe spells and use magic to grow mastery. Skill choices and unique designs are saved.",11)
	elif craft.codex_tab==1:
		var names:Array=g.MagicCatalog.SPELLS.keys();var pages:=ceili(names.size()/8.0);craft.codex_page=clampi(craft.codex_page,0,maxi(0,pages-1))
		text(Rect2(16,82,728,26),"Original focuses | Page %d/%d | Craft at a Workbench" % [craft.codex_page+1,pages],13)
		for row in range(8):
			var index:int=craft.codex_page*8+row
			if index>=names.size():break
			var item:=str(names[index]);var spec:Dictionary=g.MagicCatalog.SPELLS[item];var box:=Rect2(16+(row%2)*372,118+int(row/2)*84,360,76)
			g._rounded_box(Rect2(at+box.position,box.size),Color("23374b"),Color("607c8f"),5,1)
			g._draw_item_icon(item,Rect2(at+box.position+Vector2(7,8),Vector2(30,52)))
			text(Rect2(box.position+Vector2(44,3),Vector2(310,24)),item,14,Color("ead7af"))
			text(Rect2(box.position+Vector2(44,28),Vector2(310,19)),"%.0f MP | %s" % [spec.mana,spec.school],12)
			text(Rect2(box.position+Vector2(44,48),Vector2(310,23)),str(spec.detail),11)
		text(Rect2(16,472,728,34),"Alchemy Desk: name and inscribe your own spells. Cauldron: brew essences, ink and tonics.",13)
	else:
		var names:Array=craft.spells.keys();var pages:=maxi(1,ceili(names.size()/5.0));craft.codex_page=clampi(craft.codex_page,0,pages-1)
		text(Rect2(16,82,728,26),"Saved designs %d / 64 | Page %d/%d" % [names.size(),craft.codex_page+1,pages],14)
		for row in range(5):
			var index:int=craft.codex_page*5+row
			if index>=names.size():break
			var item:=str(names[index]);var box:=Rect2(16,118+row*66,728,60)
			g._rounded_box(Rect2(at+box.position,box.size),Color("263b4c"),Color("6f829b"),5,1)
			g._draw_item_icon(item,Rect2(at+box.position+Vector2(8,5),Vector2(28,48)))
			text(Rect2(box.position+Vector2(44,3),Vector2(678,25)),g.Tools.display_name(item),15,Color("ead8b5"))
			text(Rect2(box.position+Vector2(44,29),Vector2(678,24)),craft.summary(item),13)
		if names.is_empty():text(Rect2(24,180,704,70),"Learn an effect, brew its essence, then use an Alchemy Desk to inscribe your first unique focus.",17)
		text(Rect2(16,472,728,34),"Every inscribed focus has its own identity, hotbar slot, mana cost and recovery.",13)

func draw_tooltip()->void:
	if not g.magic.codex_open or not g.inventory_open or g.spellcraft.codex_tab!=0:return
	var mouse:Vector2=g.get_viewport().get_mouse_position();var local:Vector2=mouse-Vector2(g.window_positions.magic)
	for i in range(C.NODES.size()):
		if node_rect(i).has_point(local):
			var node:Dictionary=C.NODES[C.NODES.keys()[i]];var parents:PackedStringArray=[]
			for parent:String in node.needs:parents.append(str(C.NODES[parent].name))
			g._draw_item_tooltip(mouse,[str(node.name),str(node.detail),"Requires: "+(", ".join(parents) if not parents.is_empty() else "school rank and one point")]);return
