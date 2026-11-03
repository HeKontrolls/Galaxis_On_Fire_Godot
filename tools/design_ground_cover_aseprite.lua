-- Draws the wider ground-cover set inside Aseprite, then revises only the
-- existing berry-shrub tag. No other existing artwork is reconstructed.
local root=assert(app.params.root)
local function c(s) return app.pixelColor.rgba(tonumber(s:sub(1,2),16),tonumber(s:sub(3,4),16),tonumber(s:sub(5,6),16),255) end
local function px(im,x,y,col) x=math.floor(x); y=math.floor(y); if x>=0 and y>=0 and x<im.width and y<im.height then im:drawPixel(x,y,col) end end
local function line(im,x,y,xx,yy,col,w)
 x=math.floor(x); y=math.floor(y); xx=math.floor(xx); yy=math.floor(yy)
 local dx=math.abs(xx-x); local sx=x<xx and 1 or -1; local dy=-math.abs(yy-y); local sy=y<yy and 1 or -1; local e=dx+dy
 while true do local size=w or 1; for oy=0,size-1 do for ox=0,size-1 do px(im,x+ox-math.floor(size/2),y+oy-math.floor(size/2),col) end end
  if x==xx and y==yy then break end; local e2=2*e; if e2>=dy then e=e+dy; x=x+sx end; if e2<=dx then e=e+dx; y=y+sy end end
end
local function oval(im,x,y,rx,ry,col)
 for yy=math.floor(y-ry),math.ceil(y+ry) do for xx=math.floor(x-rx),math.ceil(x+rx) do if ((xx-x)/rx)^2+((yy-y)/ry)^2<=1 then px(im,xx,yy,col) end end end
end
local function poly(im,points,col)
 for y=0,39 do local xs={}
  for i,a in ipairs(points) do local b=points[i%#points+1]; if (a[2]<=y and b[2]>y) or (b[2]<=y and a[2]>y) then table.insert(xs,a[1]+(y-a[2])*(b[1]-a[1])/(b[2]-a[2])) end end
  table.sort(xs); for i=1,#xs-1,2 do for x=math.ceil(xs[i]),math.floor(xs[i+1]) do px(im,x,y,col) end end
 end
 for i,a in ipairs(points) do local b=points[i%#points+1]; line(im,a[1],a[2],b[1],b[2],col) end
end
local function layers() return {Image(48,40),Image(48,40),Image(48,40),Image(48,40)} end
local function bush(kind,n)
 local im=layers(); local ink,shade,base,leaf,hi=c("193c30"),c("245438"),c("326c41"),c("4c8c50"),c("86b663")
 if kind=="forest_thicket" then ink,shade,base,leaf,hi=c("17372e"),c("204b34"),c("2d623d"),c("447d4c"),c("74a25e") end
 if kind=="frost_bush" then ink,shade,base,leaf,hi=c("2b4545"),c("3c6460"),c("588579"),c("84b09d"),c("c9dfcb") end
 local sway=({0,1,0,-1})[n+1]; local tall=kind=="forest_thicket" and 3 or 0
 oval(im[1],24,32,21,7,ink); oval(im[1],13+sway,28,11,10,ink); oval(im[1],25+sway,23-tall,13,12,ink); oval(im[1],36+sway,29,10,9,ink)
 -- A continuous lower volume joins the crown lobes into a full bush.
 for y=10,38 do for x=2,46 do
  if app.pixelColor.rgbaA(im[1]:getPixel(x,y))>0 and x>2 and x<46 and y<38 then
   local tint=y>32 and shade or base
   if y<25 and x<27 then tint=leaf end
   px(im[2],x,y,tint)
  end
 end end
 for row=0,7 do for col=0,10 do
  local x=4+col*4+((row*5+col*3)%3)-1; local y=13+row*3+((row+col*7)%2)
  local shift=math.floor(sway*(39-y)/24); x=x+shift
  if x>3 and x<45 and y<37 and app.pixelColor.rgbaA(im[1]:getPixel(x,y))>0 and app.pixelColor.rgbaA(im[1]:getPixel(x+2,y+1))>0 then
   local bright=(row*13+col*7)%5==0 and hi or leaf
   if y>31 then bright=base end
   line(im[3],x-1,y+1,x+1,y+1,shade); px(im[3],x,y,bright); px(im[3],x+1,y-1,bright); px(im[3],x+2,y,bright)
   if y<29 and (row+col)%3==0 then px(im[3],x+1,y-2,hi) end
  end
 end end
 line(im[4],18,39,29,39,ink); line(im[4],23,38,24,36,c("644d36"),2)
 if kind=="flowering_bush" then
  for _,p in ipairs({{10,28},{21,18},{31,24},{39,30}}) do local x,y=p[1]+sway,p[2]
   oval(im[4],x,y,3,2,c("a75770")); px(im[4],x-2,y-1,c("e69aa3")); px(im[4],x+1,y-1,c("efbdba")); px(im[4],x,y,c("edcd77")) end
 end
 if kind=="frost_bush" then
  for _,p in ipairs({{9,24},{21,13},{29,15},{38,24}}) do line(im[4],p[1]+sway,p[2],p[1]+4+sway,p[2],c("dfebdf")) end
 end
 return im
end
local function rock(kind,n)
 local im=layers(); local ink,base,hi,dark=c("344346"),c("7f8d89"),c("bac1aa"),c("536362")
 local shape={{6,39},{3,32},{9,22},{18,15},{29,17},{37,25},{43,35},{40,39}}
 if kind=="pebble_cluster" then
  for _,p in ipairs({{10,36,7,3},{25,34,9,5},{39,37,5,2}}) do
   oval(im[1],p[1],p[2],p[3],p[4],ink); oval(im[2],p[1],p[2]-1,p[3]-1,p[4]-1,base); line(im[3],p[1]-2,p[2]-p[4]+1,p[1]+2,p[2]-p[4]+1,hi)
  end
  return im
 end
 if kind=="sandstone_rock" then ink,base,hi,dark=c("655044"),c("bc9668"),c("e3c18c"),c("926d50"); shape={{9,39},{5,33},{12,24},{21,21},{33,25},{40,34},{38,39}} end
 if kind=="basalt_rock" then ink,base,hi,dark=c("272e39"),c("515967"),c("8c909c"),c("3b4350"); shape={{7,39},{4,30},{13,20},{22,18},{28,22},{35,20},{42,33},{39,39}} end
 poly(im[1],shape,ink)
 local inset={}; for _,p in ipairs(shape) do table.insert(inset,{24+(p[1]-24)*0.91,39+(p[2]-39)*0.91}) end
 poly(im[2],inset,base)
 poly(im[3],{{7,32},{18,17},{25,21},{20,30},{12,35}},hi)
 poly(im[3],{{24,22},{29,19},{38,29},{39,37},{27,37},{20,31}},dark)
 line(im[4],25,22,22,29,ink); line(im[4],22,29,27,33,ink); line(im[4],22,29,17,29,dark)
 for _,p in ipairs({{12,31},{15,23},{20,20},{32,33},{12,37},{35,35}}) do px(im[4],p[1],p[2],base); px(im[4],p[1]+1,p[2],hi) end
 if kind=="sandstone_rock" then for y=28,35,3 do line(im[4],11,y,34,y+1,dark) end end
 if kind=="mossy_boulder" then
  local sway=({0,1,0,-1})[n+1]
  for _,p in ipairs({{12,23},{18,18},{23,19},{31,23},{35,28}}) do
   oval(im[4],p[1],p[2],4,2,c("41613e")); line(im[4],p[1]-2,p[2]-1,p[1]+2,p[2]-1,c("7c9a55")); px(im[4],p[1]+sway,p[2]-3,c("a5b96a"))
  end
 end
 return im
end
local function mushrooms(n)
 local im=layers(); local sway=({0,1,0,-1})[n+1]
 for _,p in ipairs({{12,31,5},{25,25,7},{36,33,4}}) do local x,y,r=p[1]+sway,p[2],p[3]
  line(im[1],x,39,x,y,c("6e5748"),3); line(im[2],x,38,x,y,c("dfcda4"),2)
  oval(im[1],x,y,r+1,math.max(3,r-2),c("6b4534")); oval(im[2],x,y-1,r,math.max(2,r-3),c("c57639"))
  line(im[3],x-r+2,y-2,x+1,y-3,c("efb956")); px(im[4],x-2,y-2,c("f5d38b")); px(im[4],x+2,y,c("e9be73"))
 end
 return im
end
local names={"leafy_bush","forest_thicket","flowering_bush","frost_bush","pebble_cluster","granite_boulder","mossy_boulder","sandstone_rock","basalt_rock","woodland_mushrooms"}
local s=Sprite(48,40,ColorMode.RGB); s.layers[1].name="Silhouettes and roots"
s:newLayer().name="Foliage and stone volumes"; s:newLayer().name="Leaves and facets"; s:newLayer().name="Flowers, moss and highlights"
local index=0; local tags={}
for i,name in ipairs(names) do
 local count=(i<=4 or name=="mossy_boulder" or name=="woodland_mushrooms") and 4 or 1
 local first=index+1
 for n=0,count-1 do
  index=index+1; if index>1 then s:newEmptyFrame(index) end; s.frames[index].duration=0.22
  local images=i<=4 and bush(name,n) or (name=="woodland_mushrooms" and mushrooms(n) or rock(name,n))
  for layer,im in ipairs(images) do local old=s.layers[layer]:cel(index); if old then old.image=im else s:newCel(s.layers[layer],index,im,Point(0,0)) end end
 end
 table.insert(tags,{name=name,first=first,last=index})
end
for _,tag in ipairs(tags) do s:newTag(tag.first,tag.last).name=tag.name end
s.data=json.encode({pivot={24,40},canvas={48,40},species=10})
local folder=root .. "/assets/sprites/source/ecology/"; app.fs.makeAllDirectories(folder)
s:saveAs(folder .. "ground_cover.aseprite"); s:close()
local original=assert(app.open(folder .. "ground_life.aseprite"))
for _,tag in ipairs(original.tags) do if tag.name=="berry_shrub" then
 for frame=tag.fromFrame.frameNumber,tag.toFrame.frameNumber do
  local n=frame-tag.fromFrame.frameNumber; local images=bush("leafy_bush",n)
  images[3]:drawImage(images[4],Point(0,0))
  for layer=1,3 do
   local small=Image(24,32)
   for y=0,19 do for x=0,23 do px(small,x,y+12,images[layer]:getPixel(x*2,y*2)) end end
   if layer==3 then for _,p in ipairs({{8,24},{13,19},{17,25},{11,27}}) do px(small,p[1],p[2],c("aa4561")); px(small,p[1],p[2]-1,c("e78491")) end end
   original.layers[layer]:cel(frame).image=small
  end
 end
end end
original:saveAs(folder .. "ground_life.aseprite"); original:close()
dofile(root .. "/tools/export_ground_life_aseprite.lua")
dofile(root .. "/tools/export_ground_cover_aseprite.lua")
dofile(root .. "/tools/redesign_ground_cover_detail_aseprite.lua")
