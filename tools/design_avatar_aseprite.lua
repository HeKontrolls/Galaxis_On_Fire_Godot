-- Modular player wardrobe drawn, layered, animated and palette-authored in
-- Aseprite. The runtime only selects/composes these precolored atlas layers.
local root=assert(app.params.root)
local catalog=dofile(root .. "/tools/avatar_catalog.lua")
local source=root .. "/assets/sprites/source/characters/"; app.fs.makeAllDirectories(source)
local function C(s) return app.pixelColor.rgba(tonumber(s:sub(1,2),16),tonumber(s:sub(3,4),16),tonumber(s:sub(5,6),16),255) end
local function px(im,x,y,c) x=math.floor(x); y=math.floor(y); if x>=0 and y>=0 and x<im.width and y<im.height then im:drawPixel(x,y,c) end end
local function rect(im,x,y,w,h,c) for yy=y,y+h-1 do for xx=x,x+w-1 do px(im,xx,yy,c) end end end
local function line(im,x,y,xx,yy,c,w)
 x=math.floor(x); y=math.floor(y); xx=math.floor(xx); yy=math.floor(yy)
 local dx=math.abs(xx-x); local sx=x<xx and 1 or -1; local dy=-math.abs(yy-y); local sy=y<yy and 1 or -1; local e=dx+dy
 while true do local n=w or 1; rect(im,x-math.floor(n/2),y-math.floor(n/2),n,n,c); if x==xx and y==yy then break end
  local e2=2*e; if e2>=dy then e=e+dy; x=x+sx end; if e2<=dx then e=e+dx; y=y+sy end end
end
local function poly(im,p,c)
 for y=0,im.height-1 do local xs={}
  for i,a in ipairs(p) do local b=p[i%#p+1]; if (a[2]<=y and b[2]>y) or (b[2]<=y and a[2]>y) then table.insert(xs,a[1]+(y-a[2])*(b[1]-a[1])/(b[2]-a[2])) end end
  table.sort(xs); for i=1,#xs-1,2 do for x=math.ceil(xs[i]),math.floor(xs[i+1]) do px(im,x,y,c) end end
 end
 for i,a in ipairs(p) do local b=p[i%#p+1]; line(im,a[1],a[2],b[1],b[2],c) end
end
local function oval(im,x,y,rx,ry,c) for yy=math.floor(y-ry),math.ceil(y+ry) do for xx=math.floor(x-rx),math.ceil(x+rx) do if ((xx-x)/rx)^2+((yy-y)/ry)^2<=1 then px(im,xx,yy,c) end end end end
local ink=C("292935"); local cream=C("e2dfc9"); local brass=C("d0ad70"); local leather=C("70503a")
local function colors(category,index)
 local result={}; for i,v in ipairs(catalog.palettes[category][index or 1].ramp) do result[i]=C(v) end; return result
end
local skin,hair,shirt,pants,shoes,eye=colors("skin"),colors("hair"),colors("clothing"),colors("clothing",2),colors("clothing",12),colors("eyes",2)
local function border(im,x,y,w,h,c) rect(im,x,y,w,h,ink); if w>2 and h>2 then rect(im,x+1,y+1,w-2,h-2,c) end end
local function pose(action,n,female)
 local bob=action=="walk" and ({0,-1,-1,0,-1,-1})[n+1] or (action=="idle" and n==2 and -1 or 0)
 local step=action=="walk" and ({-3,-1,2,3,1,-2})[n+1] or 0
 local front=action=="walk" and ({0,2,3,0,0,0})[n+1] or 0
 local rear=action=="walk" and ({0,0,0,0,2,3})[n+1] or 0
 if action=="jump" then step=({-1,-2,-3,-3,-2,-1,0,1,1})[n+1]; front=({1,2,3,4,4,3,2,1,0})[n+1]; rear=front+1 end
 return {bob=bob,step=step,front=front,rear=rear,arm=math.floor(-step/2),lx=female and 14 or 13,rx=female and 18 or 19,action=action,n=n}
end
local function base(p,female)
 local im=Image(32,40); local b=p.bob
 -- Rear arm, neck and legs provide skin under every clothing option.
 border(im,(female and 9 or 8)+p.arm,19+b,female and 4 or 5,11,skin[2])
 line(im,p.lx,28,p.lx-p.step,37-p.rear,ink,5); line(im,p.lx,28,p.lx-p.step,37-p.rear,skin[1],3)
 line(im,p.rx,28,p.rx+p.step,37-p.front,ink,5); line(im,p.rx,28,p.rx+p.step,37-p.front,skin[2],3)
 poly(im,{{12,16+b},{19,16+b},{22,20+b},{21,29},{11,29},{10,21+b}},skin[2])
 local jaw=female and 19 or 20
 poly(im,{{12,5+b},{19,4+b},{22,7+b},{22,11+b},{23,12+b},{22,14+b},{jaw,16+b},{14,16+b},{11,13+b},{10,8+b}},ink)
 poly(im,{{13,6+b},{19,6+b},{21,8+b},{21,11+b},{22,12+b},{21,13+b},{jaw,15+b},{14,15+b},{12,12+b}},skin[2])
 rect(im,12,10+b,2,3,skin[1]); rect(im,15,12+b,4,2,skin[3]); px(im,22,12+b,skin[3]); px(im,20,14+b,skin[1])
 if p.action=="idle" and p.n==3 then line(im,18,11+b,21,11+b,skin[1]) end
 if female then px(im,20,15+b,skin[3]); px(im,12,13+b,skin[1]) end
 return im
end
local function eyes(p,female)
 local im=Image(32,40); if p.action=="idle" and p.n==3 then return im end
 rect(im,18,10+p.bob,3,3,cream); rect(im,19,10+p.bob,2,3,eye[2]); line(im,20,11+p.bob,20,12+p.bob,eye[1]); px(im,19,10+p.bob,eye[3])
 if female then line(im,18,9+p.bob,21,9+p.bob,ink); px(im,22,9+p.bob,ink) end
 return im
end
local function top(style,p,female)
 local im=Image(32,40); local b=p.bob; local left=female and 11 or 9; local right=female and 22 or 23
 poly(im,{{12,17+b},{19,17+b},{right,20+b},{right-1,29},{left+1,29},{left,21+b}},ink)
 poly(im,{{12,18+b},{19,18+b},{right-2,21+b},{right-2,28},{left+3,28},{left+2,21+b}},shirt[2])
 line(im,left+2,21+b,left+2,27,shirt[1]); line(im,17,21+b,17,26,shirt[3])
 local armx=(female and 9 or 8)+p.arm
 border(im,armx,19+b,female and 4 or 5,style=="jacket" and 11 or 6,shirt[1]); line(im,armx+1,20+b,armx+1,23+b,shirt[3])
 if style=="tee" then
  line(im,13,18+b,16,19+b,cream); line(im,16,19+b,19,18+b,cream)
 elseif style=="tunic" then
  line(im,13,18+b,16,21+b,cream); line(im,19,18+b,16,21+b,shirt[1]); rect(im,11,28,11,3,leather); rect(im,16,29,3,1,brass)
 elseif style=="jacket" then
  rect(im,15,20+b,4,8,cream); line(im,13,18+b,15,23+b,shirt[3]); line(im,20,18+b,18,23+b,shirt[1]); rect(im,12,24,3,3,shirt[1]); px(im,13,24,brass); line(im,19,24,19,27,brass)
 else
  line(im,13,18+b,16,20+b,cream); line(im,19,18+b,16,20+b,cream); line(im,16,21+b,16,27,shirt[1]); px(im,17,22+b,brass); px(im,17,25+b,brass); rect(im,19,22+b,2,3,shirt[1]); line(im,armx+1,24+b,armx+2,24+b,cream)
 end
 return im
end
local function trousers(style,p,female)
 local im=Image(32,40); local endpoint=style=="shorts" and 33 or 37
 line(im,p.lx,29,p.lx-p.step,endpoint-p.rear,ink,5); line(im,p.lx,29,p.lx-p.step,endpoint-1-p.rear,pants[1],3)
 line(im,p.rx,29,p.rx+p.step,endpoint-p.front,ink,5); line(im,p.rx,29,p.rx+p.step,endpoint-1-p.front,pants[2],3)
 line(im,p.rx,30,p.rx+p.step,endpoint-2-p.front,pants[3])
 rect(im,11,28,11,3,ink); rect(im,12,29,9,2,pants[2]); line(im,12,29,20,29,leather); px(im,16,29,brass)
 if style=="jeans" then px(im,13,31,brass); px(im,20,31,brass); line(im,p.rx+p.step-1,34-p.front,p.rx+p.step+1,34-p.front,pants[3])
 elseif style=="cargo" then border(im,p.lx-p.step-2,32-p.rear,3,3,pants[2]); border(im,p.rx+p.step,32-p.front,3,3,pants[1]); px(im,p.rx+p.step+1,32-p.front,brass)
 elseif style=="shorts" then line(im,p.rx+p.step-1,33-p.front,p.rx+p.step+1,33-p.front,pants[3]) end
 return im
end
local function footwear(style,p)
 local im=Image(32,40); local tall=style=="boots" or style=="workboots"
 for _,leg in ipairs({{p.lx-p.step,p.rear},{p.rx+p.step,p.front}}) do
  local x,y=leg[1]-3,leg[2]; border(im,x,tall and 35-y or 37-y,7,tall and 5 or 3,shoes[2])
  line(im,x+1,37-y,x+4,37-y,shoes[3]); line(im,x,39-y,x+6,39-y,style=="sneakers" and cream or shoes[1])
  if style=="boots" then px(im,x+2,35-y,brass)
  elseif style=="workboots" then line(im,x+1,36-y,x+4,36-y,cream); px(im,x+5,38-y,shoes[3])
  elseif style=="slipons" then line(im,x+1,37-y,x+4,37-y,shoes[1]) end
 end
 return im
end
local function headhair(style,p,back)
 local im=Image(32,40); local b=p.bob; local sway=p.action=="walk" and math.floor(p.step/2) or 0
 if back then
  if style=="bob" then poly(im,{{10,5+b},{21,4+b},{24,9+b},{24,19+b},{20,21+b},{10,20+b},{8,13+b}},hair[1]); line(im,10,10+b,10,18+b,hair[2])
  elseif style=="long" then poly(im,{{10,7+b},{22,6+b},{24,16+b},{24+sway,28},{20+sway,26},{17,29},{12+sway,28},{8+sway,23},{9,13+b}},hair[1]); line(im,10,13+b,10+sway,24,hair[2]); line(im,22,15+b,22+sway,25,hair[3])
  elseif style=="ponytail" then poly(im,{{11,7+b},{7,7+b},{5,12+b},{7+sway,19+b},{5+sway,24+b},{9+sway,21+b},{11,15+b}},hair[1]); line(im,7,10+b,8+sway,19+b,hair[2]); px(im,8,8+b,brass)
  elseif style=="braids" then for side=0,1 do local x=side==0 and 9 or 23
   for y=12,26,3 do border(im,x+(y%2),y+b,3,4,hair[2]); px(im,x+1+(y%2),y+b,hair[3]) end; px(im,x+1,28+b,brass) end end
  return im
 end
 if style=="curls" then
  for _,v in ipairs({{11,7},{14,4},{18,4},{22,6},{10,11}}) do oval(im,v[1],v[2]+b,4,4,hair[1]); oval(im,v[1],v[2]-1+b,3,2,hair[2]); px(im,v[1]-1,v[2]-2+b,hair[3]) end
 elseif style=="mohawk" then
  poly(im,{{13,7+b},{12,4+b},{14,4+b},{15,1+b},{17,3+b},{18,1+b},{20,4+b},{22,5+b},{21,8+b}},hair[1]); line(im,14,5+b,18,3+b,hair[2]); line(im,17,3+b,20,5+b,hair[3])
 else
  local swept=style=="swept"
  poly(im,{{10,7+b},{11,4+b},{14,4+b},{15,3+b},{18,4+b},{21,3+b},{23,6+b},{22,9+b},{19,8+b},{17,10+b},{15,8+b},{13,9+b},{12,12+b},{10,11+b}},hair[1])
  poly(im,{{12,5+b},{15,5+b},{16,4+b},{19,5+b},{21,5+b},{22,7+b},{19,7+b},{17,swept and 11+b or 8+b},{14,7+b},{12,9+b}},hair[2]); line(im,13,5+b,15,5+b,hair[3]); line(im,18,6+b,20,6+b,hair[3])
  if style=="bob" then line(im,10,10+b,10,18+b,hair[2],2); line(im,22,10+b,22,18+b,hair[3])
  elseif style=="long" then line(im,10,10+b,9,20+b,hair[2]); line(im,22,9+b,23,21+b,hair[3])
  elseif style=="braids" then px(im,11,12+b,brass); px(im,23,12+b,brass) end
 end
 return im
end
local components={{name="skin",category="skin",master=0},{name="eyes",category="eyes",master=1}}
for _,spec in ipairs({{"shirt",catalog.shirt_styles,0},{"pants",catalog.pants_styles,1},{"shoes",catalog.shoes_styles,11}}) do for _,style in ipairs(spec[2]) do table.insert(components,{name=spec[1] .. "_" .. style[1],category="clothing",master=spec[3]}) end end
for _,style in ipairs(catalog.hair_styles) do for _,side in ipairs({"back","front"}) do table.insert(components,{name="hair_" .. style[1] .. "_" .. side,category="hair",master=0}) end end
local function order(component)
 local name=component.name
 if name:match("_back$") then return 0 elseif name=="skin" then return 1 elseif name:match("^pants_") then return 2 elseif name:match("^shoes_") then return 3 elseif name:match("^shirt_") then return 4 elseif name=="eyes" then return 5 else return 6 end
end
table.sort(components,function(a,b) local x,y=order(a),order(b); return x==y and a.name<b.name or x<y end)
for _,model in ipairs(catalog.models) do
 local s=Sprite(32,40,ColorMode.RGB)
 for i,component in ipairs(components) do local layer=i==1 and s.layers[1] or s:newLayer(); layer.name=component.name end
 local index=0; local tags={}
 for _,direction in ipairs({"east","west"}) do for _,anim in ipairs({{"idle",4,0.3},{"walk",6,0.11},{"jump",9,0.1}}) do
  local first=index+1
  for n=0,anim[2]-1 do
   index=index+1; if index>1 then s:newEmptyFrame(index) end; s.frames[index].duration=anim[3]
   local p=pose(anim[1],n,model=="female")
   for layer,component in ipairs(components) do
    local name=component.name; local image
    if name=="skin" then image=base(p,model=="female") elseif name=="eyes" then image=eyes(p,model=="female")
    elseif name:sub(1,6)=="shirt_" then image=top(name:sub(7),p,model=="female")
    elseif name:sub(1,6)=="pants_" then image=trousers(name:sub(7),p,model=="female")
    elseif name:sub(1,6)=="shoes_" then image=footwear(name:sub(7),p)
    else local style,side=name:match("^hair_(%w+)_(%w+)$"); image=headhair(style,p,side=="back") end
    if direction=="west" then image:flip(FlipType.HORIZONTAL) end
    local old=s.layers[layer]:cel(index); if old then old.image=image else s:newCel(s.layers[layer],index,image,Point(0,0)) end
   end
  end
  table.insert(tags,{name=anim[1] .. "_" .. direction,first=first,last=index})
 end end
 for _,tag in ipairs(tags) do s:newTag(tag.first,tag.last).name=tag.name end
 local visible={skin=true,eyes=true,shirt_tee=true,pants_jeans=true,shoes_boots=true,hair_cropped_front=true}
 for _,layer in ipairs(s.layers) do layer.isVisible=visible[layer.name] or false end
 -- Store every selectable color ramp as native palette swatches and metadata.
 local palette=Palette(256); local slot=0
 for _,key in ipairs({"skin","hair","clothing","eyes"}) do for _,entry in ipairs(catalog.palettes[key]) do for _,hex in ipairs(entry.ramp) do palette:setColor(slot,Color{r=tonumber(hex:sub(1,2),16),g=tonumber(hex:sub(3,4),16),b=tonumber(hex:sub(5,6),16)}); slot=slot+1 end end end
 s:setPalette(palette)
 s.data=json.encode({version=1,model=model,catalog=catalog,components=components,canvas={32,40},pivot={16,40}})
 s:saveAs(source .. "avatar_" .. model .. ".aseprite"); s:close()
end
local arms=Sprite(8,12,ColorMode.RGB); arms.layers[1].name="Skin and outlines"; arms:newLayer().name="Sleeves"; arms:newLayer().name="Cuffs and highlights"
local index=0; local arm_tags={}
for _,model in ipairs(catalog.models) do for _,style in ipairs(catalog.shirt_styles) do for _,part in ipairs({"upper_arm","forearm","hand"}) do
 index=index+1; if index>1 then arms:newEmptyFrame(index) end
 local body,sleeve,detail=Image(8,12),Image(8,12),Image(8,12); local width=model=="female" and 3 or 4; local x=model=="female" and 3 or 2
 if part=="hand" then border(body,x,4,width,5,skin[1]); rect(detail,x+1,5,1,2,skin[3])
 else
  border(body,x,0,width,12,skin[2]); line(detail,x+1,1,x+1,8,skin[3])
  if part=="upper_arm" or style[1]=="jacket" then
   border(sleeve,x,0,width,style[1]=="jacket" and 12 or 7,shirt[2]); line(detail,x+1,1,x+1,5,shirt[3])
   if style[1]=="workshirt" then line(detail,x,6,x+width-1,6,cream) end
  end
 end
 for layer,im in ipairs({body,sleeve,detail}) do local old=arms.layers[layer]:cel(index); if old then old.image=im else arms:newCel(arms.layers[layer],index,im,Point(0,0)) end end
 table.insert(arm_tags,{name=model .. "_" .. style[1] .. "_" .. part,index=index})
end end end
for _,tag in ipairs(arm_tags) do arms:newTag(tag.index,tag.index).name=tag.name end
arms.data=json.encode({version=1,catalog=catalog,canvas={8,12},joint_from={4,1},joint_to={4,11}})
arms:saveAs(source .. "avatar_arms.aseprite"); arms:close()
dofile(root .. "/tools/export_avatar_aseprite.lua")
print("ASEPRITE_AVATAR_DESIGN models=2 body_frames=76 wardrobe_layers=30 arm_frames=24")
