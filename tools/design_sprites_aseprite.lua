-- Galaxis frontier art set. Run inside Aseprite with --batch --script.
-- All pixels, layered documents, animation tags, sheets and PNG exports are
-- authored by Aseprite's native sprite/image API. Re-running replaces this set.
local root = app.params.root or app.fs.filePath(app.fs.filePath(app.scriptPath))
local output = root .. "/assets/sprites/redesigned"
local sources = root .. "/assets/sprites/source/frontier"
app.fs.makeAllDirectories(output)
app.fs.makeAllDirectories(sources)
local pc = app.pixelColor
local function C(hex)
  return pc.rgba(tonumber(hex:sub(1,2),16),tonumber(hex:sub(3,4),16),tonumber(hex:sub(5,6),16),255)
end
local P = {}
for k,v in pairs({ink="182330", shade="26394a", blue="354d63", bluehi="536e81",
  teal="397f89", tealhi="76b9b4", tealdark="285661", skin="e5b087", skinhi="f6d2a4",
  skindark="af785d", wood="93603d", woodhi="d1a269", wooddark="593e30",
  copper="bc7b4b", copperhi="f4bd7c", copperdark="75452f", iron="9caeb7",
  ironhi="e5eee7", irondark="536c79", cream="e8dfbb", white="fff1cc",
  hair="cdd1c4", hairdark="879e9c", coal="302d35", red="bd563f", amber="edb85c"}) do P[k]=C(v) end
local function px(im,x,y,c)
  x=math.floor(x); y=math.floor(y)
  if x>=0 and y>=0 and x<im.width and y<im.height then im:drawPixel(x,y,c) end
end
local function box(im,x,y,w,h,c)
  for yy=y,y+h-1 do for xx=x,x+w-1 do px(im,xx,yy,c) end end
end
local function line(im,x0,y0,x1,y1,c,width)
  local dx=math.abs(x1-x0); local sx=x0<x1 and 1 or -1
  local dy=-math.abs(y1-y0); local sy=y0<y1 and 1 or -1; local e=dx+dy
  while true do
    local w=width or 1; box(im,x0-math.floor(w/2),y0-math.floor(w/2),w,w,c)
    if x0==x1 and y0==y1 then break end
    local ee=e*2; if ee>=dy then e=e+dy; x0=x0+sx end; if ee<=dx then e=e+dx; y0=y0+sy end
  end
end
local function poly(im,points,c)
  local ymin,ymax=999,-999
  for _,p in ipairs(points) do ymin=math.min(ymin,p[2]); ymax=math.max(ymax,p[2]) end
  for y=ymin,ymax do
    local hits={}
    for i,a in ipairs(points) do
      local b=points[i%#points+1]
      if (a[2]<=y and b[2]>y) or (b[2]<=y and a[2]>y) then
        table.insert(hits,a[1]+(y-a[2])*(b[1]-a[1])/(b[2]-a[2]))
      end
    end
    table.sort(hits)
    for i=1,#hits-1,2 do for x=math.ceil(hits[i]),math.floor(hits[i+1]) do px(im,x,y,c) end end
  end
  for i,a in ipairs(points) do local b=points[i%#points+1]; line(im,a[1],a[2],b[1],b[2],c) end
end
local function rim(im,x,y,w,h,fill)
  box(im,x,y,w,h,P.ink); if w>2 and h>2 then box(im,x+1,y+1,w-2,h-2,fill) end
end
local function make(w,h,names)
  local s=Sprite(w,h,ColorMode.RGB); s.layers[1].name=names[1]
  local layers={s.layers[1]}
  for i=2,#names do local l=s:newLayer(); l.name=names[i]; table.insert(layers,l) end
  return s,layers
end
local function frame(s,index,duration)
  if index>1 then s:newEmptyFrame(index) end
  s.frames[index].duration=duration
end
local function cel(s,l,index,im,west)
  if west then im:flip(FlipType.HORIZONTAL) end
  local old=l:cel(index)
  if old then old.image=im else s:newCel(l,index,im,Point(0,0)) end
end
local function export(s,index,path)
  app.fs.makeAllDirectories(app.fs.filePath(path))
  local im=Image(s.width,s.height,ColorMode.RGB); im:drawSprite(s,index); im:saveAs(path)
end
local function save(s,name,metadata)
  s.data=json.encode(metadata)
  s:saveAs(sources .. "/" .. name .. ".aseprite")
  local cols=math.min(10,#s.frames); local rows=math.ceil(#s.frames/cols)
  local sheet=Image(s.width*cols,s.height*rows,ColorMode.RGB)
  for i=1,#s.frames do sheet:drawSprite(s,i,Point(((i-1)%cols)*s.width,math.floor((i-1)/cols)*s.height)) end
  sheet:saveAs(output .. "/" .. name .. "_sheet.png")
  local f=assert(io.open(output .. "/" .. name .. ".json","w")); f:write(json.encode(metadata)); f:close()
  print(name .. ": " .. #s.frames .. " frames, " .. #s.layers .. " layers, " .. #s.tags .. " tags")
end

local function captain(action,n)
  local gear=Image(32,40); local legs=Image(32,40); local coat=Image(32,40); local head=Image(32,40); local detail=Image(32,40)
  local b=(action=="walk" and ({0,-1,-1,0,-1,-1})[n+1]) or (action=="idle" and n==2 and -1 or 0)
  local stride=action=="walk" and ({-3,-1,2,3,1,-2})[n+1] or 0
  local frontLift=action=="walk" and ({0,2,2,0,0,0})[n+1] or 0
  local backLift=action=="walk" and ({0,0,0,0,2,2})[n+1] or 0
  if action=="jump" then stride=({-1,-2,-3,-3,-2,-1,0,1,1})[n+1]; frontLift=({1,2,3,4,4,3,2,1,0})[n+1]; backLift=frontLift+1 end
  -- Backpack silhouette, rolled blanket, antenna and cyan charge cell.
  poly(gear,{{7,17+b},{11,16+b},{13,19+b},{13,28+b},{7,28+b},{5,25+b},{5,20+b}},P.ink)
  box(gear,6,19+b,5,7,P.wooddark); box(gear,7,19+b,3,2,P.copper); box(gear,7,23+b,3,3,P.wood)
  rim(gear,6,15+b,7,4,P.bluehi); px(gear,7,16+b,P.iron); line(gear,8,15+b,7,11+b,P.shade)
  px(gear,7,11+b,P.tealhi); box(gear,6,23+b,1,3,P.tealhi)
  -- Separate articulated boot silhouettes with fixed floor contact.
  line(legs,14,29,14-stride,36-backLift,P.ink,5); line(legs,14,29,14-stride,35-backLift,P.blue,3)
  rim(legs,11-stride,36-backLift,7,4,P.wooddark); box(legs,12-stride,37-backLift,4,1,P.wood)
  line(legs,19,29,19+stride,36-frontLift,P.ink,5); line(legs,19,29,19+stride,35-frontLift,P.bluehi,3)
  rim(legs,17+stride,36-frontLift,7,4,P.wooddark); box(legs,18+stride,37-frontLift,4,1,P.woodhi)
  -- Fitted jacket, rear arm, high collar, utility belt and copper clasp.
  poly(coat,{{12,17+b},{19,17+b},{23,20+b},{22,30},{11,30},{10,22+b}},P.ink)
  poly(coat,{{13,18+b},{19,18+b},{21,21+b},{20,28},{12,28},{12,21+b}},P.teal)
  box(coat,12,20+b,2,7,P.tealdark); box(coat,15,20+b,3,5,P.tealhi)
  rim(coat,9,20+b,4,8,P.tealdark); box(coat,10,27+b,3,3,P.skindark)
  box(coat,12,28,10,3,P.wooddark); box(coat,17,29,3,1,P.amber)
  rim(coat,18,23+b,4,4,P.tealdark); px(coat,19,24+b,P.copperhi)
  -- Warm face, swept hair, side goggles and a readable nose/chin contour.
  poly(head,{{13,5+b},{20,4+b},{23,7+b},{23,11+b},{25,12+b},{24,14+b},{22,14+b},{21,18+b},{15,18+b},{12,15+b},{11,9+b}},P.ink)
  poly(head,{{14,8+b},{21,7+b},{22,11+b},{24,12+b},{23,13+b},{21,13+b},{20,17+b},{15,16+b},{13,13+b}},P.skin)
  box(head,14,12+b,2,4,P.skindark); px(head,21,15+b,P.skindark); box(head,17,11+b,4,2,P.skinhi)
  poly(head,{{12,7+b},{14,4+b},{19,3+b},{23,5+b},{22,8+b},{18,8+b},{15,10+b},{13,12+b},{11,10+b}},P.shade)
  line(head,14,5+b,20,5+b,P.bluehi); px(head,13,7+b,P.blue)
  line(head,13,8+b,22,8+b,P.wooddark); rim(head,18,6+b,5,4,P.tealdark)
  box(head,19,7+b,3,1,P.tealhi); px(head,20,6+b,P.ironhi)
  box(head,21,11+b,2,1,(action=="idle" and n==3) and P.skindark or P.ink)
  px(head,23,12+b,P.skinhi)
  poly(detail,{{12,17+b},{16,16+b},{20,17+b},{21,19+b},{15,20+b},{12,19+b}},P.copperdark)
  line(detail,13,17+b,19,18+b,P.amber); poly(detail,{{13,19+b},{12,23+b},{9,22+b},{11,19+b}},P.copper)
  px(detail,16,22+b,P.cream); px(detail,16,23+b,P.copperhi)
  return {gear,legs,coat,head,detail}
end

local function elder(action,n)
  local gear=Image(32,40); local legs=Image(32,40); local coat=Image(32,40); local head=Image(32,40); local detail=Image(32,40)
  local b=action=="walk" and ({0,0,-1,-1,0,0,-1,-1})[n+1] or (n==2 and -1 or 0)
  local stride=action=="walk" and ({-2,-1,0,1,2,1,0,-1})[n+1] or 0
  line(legs,13,28,13-stride,36,P.ink,5); line(legs,13,30,13-stride,36,P.blue,3)
  rim(legs,10-stride,36,7,4,P.wooddark); px(legs,11-stride,37,P.woodhi)
  line(legs,18,28,18+stride,36,P.ink,5); line(legs,18,30,18+stride,36,P.bluehi,3)
  rim(legs,16+stride,36,7,4,P.wooddark); box(legs,18+stride,37,3,1,P.wood)
  rim(gear,6,20+b,6,10,P.wooddark); box(gear,7,21+b,4,2,P.woodhi); box(gear,8,26+b,2,2,P.copper)
  -- Slight stoop, broad coat and worn cream shoulder panels.
  poly(coat,{{12,17+b},{18,17+b},{22,20+b},{24,31},{10,33},{9,26},{9,21+b}},P.ink)
  poly(coat,{{12,19+b},{18,18+b},{21,21+b},{22,30},{12,31},{11,25}},P.wood)
  box(coat,12,20+b,3,10,P.woodhi); line(coat,16,22+b,17,30,P.wooddark)
  box(coat,14,25,2,5,P.woodhi)
  rim(coat,10,20+b,4,9,P.copperdark); box(coat,11,21+b,2,3,P.woodhi)
  rim(coat,20,21+b,5,8,P.wooddark); box(coat,21,22+b,3,4,P.copper); box(coat,23,27+b,3,3,P.skin)
  rim(coat,18,27,4,4,P.wooddark); px(coat,19,28,P.copperhi)
  -- Silver hair, overhanging brows, long beard and a small amber spectacle.
  poly(head,{{12,5+b},{19,4+b},{23,7+b},{23,12+b},{25,13+b},{24,15+b},{22,16+b},{21,23+b},{17,25+b},{13,21+b},{10,14+b},{10,8+b}},P.ink)
  box(head,13,9+b,9,8,P.skin); box(head,14,11+b,6,4,P.skinhi)
  poly(head,{{10,8+b},{12,4+b},{18,3+b},{22,5+b},{23,8+b},{20,9+b},{17,7+b},{13,10+b},{12,15+b},{10,13+b}},P.hairdark)
  line(head,12,5+b,19,4+b,P.cream); box(head,11,7+b,3,4,P.hair); px(head,12,12+b,P.hair)
  poly(head,{{13,15+b},{16,16+b},{19,15+b},{22,16+b},{21,21+b},{17,24+b},{14,21+b}},P.hairdark)
  poly(head,{{14,16+b},{17,17+b},{20,16+b},{20,20+b},{17,23+b},{15,20+b}},P.cream)
  line(head,16,18+b,17,21+b,P.white); px(head,20,17+b,P.white)
  line(head,18,10+b,22,10+b,P.hair); rim(head,20,11+b,4,3,P.copper)
  px(head,21,12+b,(action=="idle" and n==3) and P.skindark or P.ink); px(head,23,13+b,P.skinhi)
  line(detail,11,18+b,14,20+b,P.tealhi); line(detail,12,20+b,12,26,P.tealdark)
  -- Staff is a separate editable layer and follows the planted hand.
  local staffX=26+(action=="walk" and math.floor(stride/2) or 0)
  line(detail,staffX,24+b,staffX-1,38,P.ink,3); line(detail,staffX,25+b,staffX-1,38,P.woodhi)
  rim(detail,staffX-2,21+b,5,4,P.copperdark); px(detail,staffX,22+b,P.tealhi)
  px(detail,staffX,23+b,P.ironhi); box(detail,23,27+b,3,2,P.skinhi)
  return {gear,legs,coat,head,detail}
end

local function character(name,draw,actions)
  local s,layers=make(32,40,{"Rear equipment","Legs and boots","Coat and rear arm","Face and hair","Scarf and details"})
  local index=0; local metadata={author="Aseprite",canvas={32,40},feet={16,40},animations={}}
  for _,direction in ipairs({"east","west"}) do
    for _,anim in ipairs(actions) do
      local first=index+1
      for n=0,anim[2]-1 do
        index=index+1; frame(s,index,anim[1]=="idle" and 0.3 or (anim[1]=="walk" and 0.11 or 0.09))
        for j,im in ipairs(draw(anim[1],n)) do cel(s,layers[j],index,im,direction=="west") end
        export(s,index,output .. "/" .. name .. "/" .. anim[1] .. "/" .. direction .. string.format("/frame_%03d.png",n))
      end
      local tag=s:newTag(first,index); tag.name=anim[1] .. "_" .. direction
      table.insert(metadata.animations,{name=tag.name,first=first,last=index,count=anim[2]})
    end
  end
  -- Aseprite extends adjacent tags while inserting frames. Pin the completed
  -- ranges only after the entire timeline exists.
  for _,animation in ipairs(metadata.animations) do
    for _,tag in ipairs(s.tags) do if tag.name==animation.name then tag.toFrame=s.frames[animation.last] end end
  end
  save(s,name,metadata); s:close()
end
character("captain",captain,{{"idle",4},{"walk",6},{"jump",9}})
character("elder",elder,{{"idle",4},{"walk",8}})

local materials={
  wood={P.wood,P.woodhi,P.wooddark}, stone={C("8c9689"),C("c9cbb1"),C("56675e")},
  copper={P.copper,P.copperhi,P.copperdark}, iron={P.iron,P.ironhi,P.irondark}}
local toolNames={"wood_pickaxe","stone_pickaxe","copper_pickaxe","iron_pickaxe","wood_sword","copper_sword","iron_sword","wood_axe","copper_axe","iron_axe","hoe","hammer","watering_can"}
local ts,tl=make(32,40,{"Handles and straps","Tool heads","Edges and details"})
for index,name in ipairs(toolNames) do
  frame(ts,index,0.15)
  local shaft,head,detail=Image(32,40),Image(32,40),Image(32,40)
  local material=name:match("^(%w+)_") or "iron"; local m=materials[material] or materials.iron
  if name~="watering_can" then
    rim(shaft,14,10,5,29,P.wooddark); box(shaft,15,12,2,25,P.wood); line(shaft,15,16,15,34,P.woodhi)
    for y=28,34,3 do line(shaft,14,y,18,y+1,material=="iron" and P.tealdark or P.wooddark) end
    px(detail,16,37,P.copperhi)
  end
  if name:find("pickaxe") then
    poly(head,{{2,17},{5,11},{11,7},{18,6},{25,9},{29,14},{30,18},{24,14},{19,12},{16,14},{12,12},{7,13},{3,18}},P.ink)
    poly(head,{{4,15},{7,11},{12,8},{18,7},{24,10},{27,14},{23,12},{19,11},{16,12},{12,10},{8,12}},m[1])
    line(detail,8,10,13,8,m[2]); line(detail,13,8,18,7,m[2]); line(detail,20,9,24,11,m[2])
    rim(detail,14,10,5,5,m[3]); px(detail,16,11,m[2])
    if material=="stone" then line(detail,10,9,12,11,m[3]); line(detail,21,10,22,12,m[3]); line(detail,13,13,18,15,P.woodhi) end
    if material=="wood" then line(detail,8,12,12,10,m[3]); px(detail,20,10,m[3]) end
  elseif name:find("sword") then
    -- Blade rests above the same (16,32) grip as the mining tools.
    box(shaft,14,10,5,17,0)
    poly(head,{{16,1},{21,7},{20,23},{18,26},{13,26},{11,23},{11,8}},P.ink)
    poly(head,{{16,3},{19,8},{18,23},{16,25},{13,23},{13,9}},m[1])
    line(detail,16,4,14,10,m[2]); line(detail,14,10,14,22,m[2]); line(detail,17,9,17,22,m[3])
    poly(detail,{{8,25},{13,24},{19,24},{24,25},{24,28},{18,27},{18,29},{13,29},{13,27},{8,28}},P.ink)
    line(detail,10,26,22,26,P.copperhi); rim(detail,13,36,7,4,P.copper); px(detail,16,37,m[2])
  elseif name:find("axe") then
    poly(head,{{14,6},{20,4},{27,5},{30,9},{29,17},{25,21},{21,20},{19,16},{14,16}},P.ink)
    poly(head,{{18,7},{22,6},{27,7},{28,10},{27,16},{24,18},{21,16},{20,12},{17,13}},m[1])
    line(detail,27,8,27,14,m[2]); line(detail,27,14,24,18,m[2]); box(detail,14,7,4,8,m[3]); px(detail,15,8,m[2])
  elseif name=="hoe" then
    poly(head,{{4,8},{26,8},{28,11},{26,14},{18,12},{15,14},{11,11},{4,11}},P.ink)
    line(head,5,9,25,9,P.ironhi); line(head,5,10,25,11,P.irondark); rim(detail,13,9,5,5,P.copper)
  elseif name=="hammer" then
    poly(head,{{4,6},{25,6},{28,9},{27,17},{6,17},{3,14}},P.ink)
    box(head,5,8,21,7,P.wood); box(head,6,8,18,2,P.woodhi); box(head,5,13,21,2,P.wooddark)
    rim(detail,8,6,4,12,P.iron); rim(detail,21,6,4,12,P.iron); px(detail,9,8,P.ironhi); px(detail,22,8,P.ironhi)
  else
    -- The rose at (29,18) matches the existing animated pour origin.
    poly(shaft,{{6,26},{5,13},{7,9},{12,7},{19,8},{22,12},{22,22},{19,22},{19,13},{17,11},{12,10},{9,13},{9,26}},P.ink)
    line(shaft,7,24,7,13,P.iron); line(shaft,8,12,11,9,P.ironhi); line(shaft,12,9,18,10,P.iron)
    rim(head,8,22,15,16,P.copper); box(head,10,25,3,10,P.copperhi); box(head,18,26,3,10,P.copperdark)
    box(detail,9,22,13,3,P.tealdark); line(detail,10,23,20,23,P.tealhi)
    poly(head,{{22,26},{27,18},{29,17},{31,19},{27,31},{22,33}},P.ink)
    poly(head,{{23,27},{28,20},{29,20},{26,29},{23,31}},P.copperhi)
    rim(detail,27,16,5,5,P.iron); px(detail,29,17,P.ironhi); px(detail,29,19,P.ink); px(detail,31,18,P.ink)
  end
  cel(ts,tl[1],index,shaft); cel(ts,tl[2],index,head); cel(ts,tl[3],index,detail)
  local tag=ts:newTag(index,index); tag.name=name
  export(ts,index,output .. "/tools/" .. name .. ".png")
end
for index,tag in ipairs(ts.tags) do tag.toFrame=ts.frames[index] end
save(ts,"tools",{author="Aseprite",canvas={32,40},grip={16,32},watering_rose={29,18},items=toolNames}); ts:close()

local arms,al=make(8,12,{"Outline and sleeve","Cuff and highlights"})
for index,name in ipairs({"upper_arm","forearm","hand"}) do
  frame(arms,index,0.1); local a,b=Image(8,12),Image(8,12)
  if name=="hand" then
    rim(a,2,4,4,5,P.skindark); box(b,3,5,2,2,P.skinhi); px(b,5,6,P.skin)
  else
    rim(a,2,0,4,12,P.tealdark); line(b,3,1,3,10,P.tealhi)
    if name=="forearm" then box(a,2,8,4,4,P.ink); box(b,3,9,2,2,P.skin); px(b,4,9,P.skinhi) end
  end
  cel(arms,al[1],index,a); cel(arms,al[2],index,b)
  local tag=arms:newTag(index,index); tag.name=name
  export(arms,index,output .. "/captain/" .. name .. ".png")
end
for index,tag in ipairs(arms.tags) do tag.toFrame=arms.frames[index] end
save(arms,"captain_parts",{author="Aseprite",canvas={8,12},joint_from={4,1},joint_to={4,11}}); arms:close()

local bs,bl=make(32,32,{"Station structure","Surface and tools","Lamps and fire"})
for index=1,8 do
  frame(bs,index,0.18); local body,detail,light=Image(32,32),Image(32,32),Image(32,32)
  local workbench=index<=4; local n=(index-1)%4
  if workbench then
    rim(body,5,7,23,12,P.wooddark); box(detail,7,9,19,8,P.wood)
    for x=8,24,4 do line(detail,x,9,x,16,P.woodhi); px(detail,x+1,11,P.wooddark); px(detail,x+1,14,P.wooddark) end
    rim(body,2,21,5,11,P.wood); rim(body,25,21,5,11,P.wood); rim(body,6,27,20,4,P.wooddark)
    line(detail,7,28,24,28,P.wood); px(detail,4,24,P.iron); px(detail,27,24,P.iron)
    rim(body,0,18,32,5,P.wood); line(detail,1,18,30,18,P.woodhi); line(detail,2,20,28,20,P.copper)
    rim(body,8,23,13,4,P.wooddark); box(detail,13,24,4,1,P.copperhi)
    -- Saw, clamping vice, hanging hammer, and a small cyan work lamp.
    line(detail,9,14,17,17,P.ironhi); line(detail,9,15,17,18,P.iron)
    for x=10,16,2 do px(detail,x,17,P.ink) end
    rim(detail,22,13,7,6,P.irondark); line(detail,23,13,27,13,P.ironhi); line(detail,26,16,31,16,P.iron); px(detail,30,17,P.ironhi)
    line(detail,11,11,11,15,P.wooddark); box(detail,9,10,5,2,P.iron)
    line(light,18,10,18,15,P.ink); rim(light,16,9,5,4,P.tealdark); box(light,17,10,3,1,n==2 and P.cream or P.tealhi)
  else
    rim(body,22,2,7,11,P.irondark); box(detail,23,3,3,8,P.iron); line(detail,22,2,28,2,P.ironhi)
    poly(body,{{5,9},{25,9},{30,14},{30,31},{1,31},{1,14}},P.ink)
    poly(body,{{6,10},{24,10},{28,15},{28,29},{3,29},{3,15}},P.irondark)
    line(detail,7,11,23,11,P.iron); line(detail,4,15,27,15,P.iron)
    line(detail,3,20,28,20,P.shade); line(detail,3,26,28,26,P.shade)
    for _,p in ipairs({{8,16},{23,16},{5,22},{25,22}}) do box(detail,p[1],p[2],2,3,P.iron) end
    rim(body,9,17,15,13,P.shade); box(body,11,19,11,9,P.coal)
    box(light,11,25,11,3,P.red); box(light,13,24,7,4,P.copper)
    local a=({0,2,1,3})[n+1]
    poly(light,{{12,27},{13,23-a},{15,24},{16,20+a},{18,24-a},{21,23},{20,27}},P.amber)
    poly(light,{{14,27},{16,23},{17,25},{19,24},{19,27}},P.white)
    for x=12,20,4 do line(detail,x,26,x,29,P.ink) end
    line(detail,8,17,24,17,P.ironhi); rim(detail,5,13,4,4,P.copperdark); px(light,6,14,P.amber)
    box(detail,4,30,24,1,P.iron); px(detail,5,28,P.copperhi); px(detail,26,28,P.copperhi)
  end
  cel(bs,bl[1],index,body); cel(bs,bl[2],index,detail); cel(bs,bl[3],index,light)
  export(bs,index,output .. "/stations/" .. (workbench and "workbench" or "furnace") .. string.format("_%02d.png",n))
end
bs:newTag(1,4).name="workbench_idle"; bs:newTag(5,8).name="furnace_burn"
save(bs,"stations",{author="Aseprite",canvas={32,32},tile_footprint={2,1},draw_offset={0,-16},frame_seconds=0.18}); bs:close()
print("ASEPRITE_FRONTIER_DESIGN complete")
dofile(root .. "/tools/export_aseprite_art.lua")
