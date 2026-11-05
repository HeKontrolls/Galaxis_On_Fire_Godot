-- All artwork is authored as native Aseprite layers/frames, then exported here.
local root=assert(app.params.root)
local src=root.."/assets/sprites/source/equipment/"
local out=root.."/assets/sprites/equipment/"
app.fs.makeAllDirectories(src);app.fs.makeAllDirectories(out)
local palettes={fiber={"414d3d","71815a","b6bf85","d9c795"},copper={"663e38","b26d48","ebae70","f7d298"},iron={"354653","728d9a","b9cfce","e8e7ce"}}
local function col(h)return app.pixelColor.rgba(tonumber(h:sub(1,2),16),tonumber(h:sub(3,4),16),tonumber(h:sub(5,6),16),255) end
local function brush(im)
 local function p(x,y,c)x=math.floor(x+.5);y=math.floor(y+.5);if x>=0 and y>=0 and x<im.width and y<im.height then im:drawPixel(x,y,col(c)) end end
 local function box(x,y,w,h,c)for yy=y,y+h-1 do for xx=x,x+w-1 do p(xx,yy,c) end end end
 local function line(x,y,xx,yy,c)local n=math.max(math.abs(xx-x),math.abs(yy-y));for i=0,n do local t=n==0 and 0 or i/n;p(x+(xx-x)*t,y+(yy-y)*t,c) end end
 local function poly(v,c)
  for y=0,im.height-1 do local xs={}
   for i,a in ipairs(v) do local b=v[i%#v+1];if (a[2]<=y and b[2]>y) or (b[2]<=y and a[2]>y) then table.insert(xs,a[1]+(y-a[2])*(b[1]-a[1])/(b[2]-a[2])) end end
   table.sort(xs);for i=1,#xs-1,2 do for x=math.ceil(xs[i]),math.floor(xs[i+1]) do p(x,y,c) end end
  end
  for i,a in ipairs(v) do local b=v[i%#v+1];line(a[1],a[2],b[1],b[2],c) end
 end
 return p,box,line,poly
end
local function pose(action,n,female)
 local bob=action=="walk" and ({0,-1,-1,0,-1,-1})[n+1] or (action=="idle" and n==2 and -1 or 0)
 local step=action=="walk" and ({-3,-1,2,3,1,-2})[n+1] or 0
 local front=action=="walk" and ({0,2,3,0,0,0})[n+1] or 0
 local rear=action=="walk" and ({0,0,0,0,2,3})[n+1] or 0
 if action=="jump" then step=({-1,-2,-3,-3,-2,-1,0,1,1})[n+1];front=({1,2,3,4,4,3,2,1,0})[n+1];rear=front+1 end
 return {bob=bob,step=step,front=front,rear=rear,lx=female and 14 or 13,rx=female and 18 or 19,arm=math.floor(-step/2)}
end
local function armor(part,p,female,material,detail)
 local im=Image(32,40,ColorMode.RGB);local px,box,line,poly=brush(im)
 local c=palettes[material];local b=p.bob;local cloth=material=="fiber"
 if part=="head" then
  if not detail then
   poly({{10,5+b},{13,2+b},{19,2+b},{23,5+b},{24,9+b},{12,9+b},{12,15+b},{9,14+b}},c[1])
   poly({{12,5+b},{14,3+b},{19,3+b},{22,6+b},{22,8+b},{11,8+b}},c[2])
   box(10,9+b,3,5,c[2]);line(10,5+b,13,3+b,c[3]);line(13,3+b,19,3+b,c[3])
  else
   line(12,8+b,23,8+b,c[3]);px(11,10+b,c[4]);line(10,13+b,12,14+b,c[3])
   if cloth then line(14,4+b,12,6+b,c[4]);line(18,4+b,16,6+b,c[3]);px(20,5+b,c[4])
   else box(16,3+b,2,5,c[3]);px(17,3+b,c[4]);box(13,6+b,2,1,c[1]);px(22,7+b,c[4]);box(10,14+b,3,2,c[1]) end
  end
 elseif part=="chest" then
  local left=female and 10 or 9;local right=female and 22 or 23
  if not detail then
   poly({{12,17+b},{19,17+b},{right,20+b},{right-1,29},{left+1,29},{left,20+b}},c[1])
   poly({{12,18+b},{19,18+b},{right-2,21+b},{right-2,27},{left+2,27},{left+1,21+b}},c[2])
   box((female and 9 or 8)+p.arm,19+b,4,6,c[1]);line((female and 10 or 9)+p.arm,19+b,(female and 10 or 9)+p.arm,23+b,c[3])
   line(12,18+b,15,19+b,c[3]);line(19,18+b,20,20+b,c[3]);box(11,28,11,2,"675040")
  else
   if cloth then
    for y=21+b,26,2 do line(12,y,20,y,c[3]) end
    line(12,19+b,20,26,"c0b584");line(13,20+b,21,27,"a18e64")
   else
    poly({{13,20+b},{16,21+b},{20,20+b},{19,25},{16,27},{13,25}},c[3])
    line(16,22+b,16,26,c[4]);line(12,26,20,26,c[1]);px(11,21+b,c[4]);px(21,21+b,c[4])
   end
   box(16,28,3,2,c[4]);px(17,29,"7a6248")
  end
 else
  for _,v in ipairs({{p.lx-p.step,p.rear},{p.rx+p.step,p.front}}) do
   local x,y=v[1]-3,v[2]
   if not detail then box(x,34-y,6,5,c[1]);box(x+1,35-y,4,3,c[2]);box(x,38-y,8,2,c[1]);line(x+1,38-y,x+6,38-y,c[2])
   else line(x+1,34-y,x+4,34-y,c[3]);line(x+1,36-y,x+4,36-y,c[3]);px(x+5,38-y,c[4]);if cloth then px(x+2,35-y,c[4]) else box(x+1,35-y,3,2,c[3]) end end
  end
 end
 return im
end
local function flip(im)local result=Image(im.width,im.height,ColorMode.RGB);for y=0,im.height-1 do for x=0,im.width-1 do result:drawPixel(im.width-1-x,y,im:getPixel(x,y)) end end;return result end
local metadata={columns=10,canvas={32,40},frames=38,animations={}}
for material,_ in pairs(palettes) do for _,model in ipairs({"male","female"}) do
 local s=Sprite(32,40,ColorMode.RGB);local parts={"head","chest","boots"}
 for i=1,6 do if i>1 then s:newLayer() end;s.layers[i].name=parts[math.ceil(i/2)]..(i%2==1 and " silhouette" or " fittings and highlights") end
 local sheets={head=Image(320,160,ColorMode.RGB),chest=Image(320,160,ColorMode.RGB),boots=Image(320,160,ColorMode.RGB)}
 local frame=0
 for _,direction in ipairs({"east","west"}) do for _,anim in ipairs({{"idle",4,.3},{"walk",6,.11},{"jump",9,.1}}) do
  local first=frame+1
  for n=0,anim[2]-1 do
   frame=frame+1;if frame>1 then s:newEmptyFrame() end;s.frames[frame].duration=anim[3]
   local p=pose(anim[1],n,model=="female")
   for i,part in ipairs(parts) do
    local flat=Image(32,40,ColorMode.RGB)
    for detail=0,1 do local im=armor(part,p,model=="female",material,detail==1);if direction=="west" then im=flip(im) end
     local layer=(i-1)*2+detail+1
     if frame==1 and layer==1 then s.layers[1]:cel(1).image=im else s:newCel(s.layers[layer],frame,im,Point(0,0)) end
     flat:drawImage(im)
    end
    sheets[part]:drawImage(flat,Point((frame-1)%10*32,math.floor((frame-1)/10)*40))
   end
  end
  s:newTag(first,frame).name=anim[1].."_"..direction
 end end
 s.data=json.encode(metadata);s:saveAs(src..material.."_"..model..".aseprite")
 for part,sheet in pairs(sheets) do sheet:saveAs(out..material.."_"..model.."_"..part..".png") end
 s:close()
end end
local names={"fiber_hood","fiber_vest","fiber_boots","copper_helmet","copper_cuirass","copper_boots","iron_helmet","iron_cuirass","iron_boots","wood_shield","copper_shield","iron_shield","scout_charm","bone_ward"}
local review=Image(14*40,40,ColorMode.RGB)
for index,name in ipairs(names) do
 local material=index<=3 and "fiber" or (index<=6 and "copper" or "iron")
 if index==10 then material="fiber" elseif index==11 then material="copper" end
 local c=palettes[material];local s=Sprite(32,32,ColorMode.RGB)
 s.layers[1].name="Silhouette and material";s:newLayer().name="Facets and seams";s:newLayer().name="Trim, rivets and stitching"
 for layer=1,3 do
  local im=Image(32,32,ColorMode.RGB);local p,box,line,poly=brush(im)
  local part=(index-1)%3
  if index<=9 then
   if part==0 then
    if layer==1 then poly({{5,12},{9,5},{20,4},{26,10},{27,18},{11,18},{11,26},{5,23}},c[1]);poly({{7,12},{10,7},{20,6},{24,11},{24,16},{8,16}},c[2]);box(6,17,4,6,c[2])
    elseif layer==2 then line(8,11,11,7,c[3]);line(11,7,20,7,c[3]);box(16,7,3,10,c[3]);line(9,17,26,17,c[3])
    else p(8,20,c[4]);p(24,15,c[4]);line(7,23,10,24,c[3]);if material=="fiber" then line(10,10,13,13,c[4]);line(11,13,15,9,c[3]) end end
   elseif part==1 then
    if layer==1 then poly({{10,5},{21,5},{27,9},{28,16},{24,18},{23,28},{8,28},{7,18},{3,16},{4,9}},c[1]);poly({{10,7},{21,7},{24,11},{21,15},{22,25},{9,25},{10,15},{7,11}},c[2])
    elseif layer==2 then line(10,7,15,10,c[3]);line(21,7,16,10,c[3]);poly({{12,12},{16,14},{20,12},{20,21},{16,24},{12,21}},c[3]);line(16,15,16,23,c[4]);box(8,26,16,2,"765640")
    else box(15,26,4,2,c[4]);p(6,10,c[4]);p(24,10,c[4]);if material=="fiber" then for y=15,21,3 do line(10,y,21,y,c[1]) end end end
   else
    for _,x in ipairs({5,18}) do
     if layer==1 then box(x,6,8,18,c[1]);poly({{x,21},{x+7,21},{x+10,25},{x+10,28},{x,28}},c[1]);box(x+1,8,6,15,c[2]);box(x+1,24,8,2,c[2])
     elseif layer==2 then line(x+1,7,x+6,7,c[3]);box(x+2,10,3,10,c[3]);line(x+1,25,x+8,25,c[3])
     else line(x+1,13,x+6,13,c[1]);p(x+5,13,c[4]);p(x+8,25,c[4]) end
    end
   end
  elseif index<=12 then
   if layer==1 then poly({{7,3},{24,3},{27,8},{25,23},{16,30},{6,23},{4,8}},c[1]);poly({{8,5},{23,5},{25,9},{23,22},{16,27},{8,22},{6,9}},c[2])
   elseif layer==2 then line(8,5,23,5,c[3]);line(6,9,8,21,c[3]);line(8,22,16,27,c[3]);line(12,6,12,24,c[1]);line(20,6,20,23,c[1]);poly({{16,10},{21,15},{16,20},{11,15}},c[3])
   else box(15,13,3,4,c[4]);for _,v in ipairs({{8,7},{23,7},{9,21},{22,21},{16,26}}) do p(v[1],v[2],c[4]) end end
  elseif index==13 then
   if layer==1 then line(7,3,9,15,"8a6a43");line(24,3,22,15,"8a6a43");poly({{16,11},{24,20},{16,30},{8,20}},"34565e")
   elseif layer==2 then poly({{16,13},{21,20},{16,27},{11,20}},"72c4bf");line(16,14,16,25,"dcf3d9")
   else p(12,20,"eddeb1");p(20,20,"eddeb1");line(10,6,12,12,"c5b37f");line(21,6,19,12,"c5b37f") end
  else
   if layer==1 then line(8,4,14,14,"867055");line(24,4,18,14,"867055");poly({{10,15},{13,11},{20,11},{23,15},{23,21},{19,25},{13,25},{9,21}},"696a5e");box(13,24,7,5,"696a5e")
   elseif layer==2 then poly({{11,15},{14,12},{19,12},{21,15},{21,20},{18,24},{13,23},{11,20}},"d5cc9e");box(14,25,5,3,"d5cc9e")
   else box(12,16,3,3,"515c59");box(18,16,3,3,"515c59");p(16,21,"515c59");line(13,13,18,13,"f1e6bd");p(15,26,"736c5a");p(18,26,"736c5a") end
  end
  if layer==1 then s.layers[1]:cel(1).image=im else s:newCel(s.layers[layer],1,im,Point(0,0)) end
 end
 s:newTag(1,1).name="inventory";s:saveAs(src..name..".aseprite")
 local im=Image(32,32,ColorMode.RGB);im:drawSprite(s,1);im:saveAs(out..name..".png");review:drawImage(im,Point((index-1)*40+4,4));s:close()
end
for material,c in pairs(palettes) do
 local s=Sprite(8,20,ColorMode.RGB);s.layers[1].name="Arm armor";s:newLayer().name="Cuff and shoulder trim"
 for layer=1,2 do local im=Image(8,20,ColorMode.RGB);local p,box,line=brush(im)
  if layer==1 then box(1,1,6,11,c[1]);box(2,2,4,9,c[2]);line(2,2,2,9,c[3])
  else line(2,1,5,1,c[4]);line(1,10,6,10,c[3]);p(5,4,c[4]) end
  if layer==1 then s.layers[1]:cel(1).image=im else s:newCel(s.layers[layer],1,im,Point(0,0)) end
 end
 s:newTag(1,1).name="solid_sleeve";s:saveAs(src..material.."_arm.aseprite")
 local im=Image(8,20,ColorMode.RGB);im:drawSprite(s,1);im:saveAs(out..material.."_arm.png");s:close()
end
local f=assert(io.open(out.."equipment.json","w"));f:write(json.encode({armor_frames=38,columns=10,frame_size={32,40},models={"male","female"},materials={"fiber","copper","iron"},animations={{name="idle_east",from=0,to=3},{name="walk_east",from=4,to=9},{name="jump_east",from=10,to=18},{name="idle_west",from=19,to=22},{name="walk_west",from=23,to=28},{name="jump_west",from=29,to=37}},arm_pivot={4,1},icons=names}));f:close()
review:resize(1120,80);review:saveAs(root.."/.godot/equipment_art_review.png")
print("EQUIPMENT_AUTHORED 6 animated armor sources, 14 icons, 3 sleeve sources")
