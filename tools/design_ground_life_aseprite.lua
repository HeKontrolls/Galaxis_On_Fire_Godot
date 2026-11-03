-- All raster artwork is drawn and animated by Aseprite's native Lua API.
local root=assert(app.params.root)
local function color(hex) return app.pixelColor.rgba(tonumber(hex:sub(1,2),16),tonumber(hex:sub(3,4),16),tonumber(hex:sub(5,6),16),255) end
local p={}
for k,v in pairs({ink="233c37",stem="466941",leaf="739947",light="b7cf76",shade="375c44",gold="e8c66d",pink="df8296",cream="f6ebc7",red="a74668",brown="78513d",bark="473b35",sand="b49960",dry="ccb67e",blue="6b9eae",ice="b7dce0",white="e4f5e8",violet="996ca9",aqua="87d6c9",ember="ce704b",hot="f4c478"}) do p[k]=color(v) end
local function px(im,x,y,c) x=math.floor(x); y=math.floor(y); if x>=0 and x<24 and y>=0 and y<32 then im:drawPixel(x,y,c) end end
local function rect(im,x,y,w,h,c) for yy=y,y+h-1 do for xx=x,x+w-1 do px(im,xx,yy,c) end end end
local function line(im,x,y,xx,yy,c,w)
  x=math.floor(x); y=math.floor(y); xx=math.floor(xx); yy=math.floor(yy)
  local dx=math.abs(xx-x); local sx=x<xx and 1 or -1; local dy=-math.abs(yy-y); local sy=y<yy and 1 or -1; local e=dx+dy
  while true do local n=w or 1; rect(im,x-math.floor(n/2),y-math.floor(n/2),n,n,c); if x==xx and y==yy then break end
    local e2=2*e; if e2>=dy then e=e+dy; x=x+sx end; if e2<=dx then e=e+dx; y=y+sy end end
end
local function oval(im,cx,cy,rx,ry,c)
  for y=math.floor(cy-ry),math.ceil(cy+ry) do for x=math.floor(cx-rx),math.ceil(cx+rx) do
    if ((x-cx)/rx)^2+((y-cy)/ry)^2<=1 then px(im,x,y,c) end end end
end
local function leaf(im,x,y,side,size,base,hi)
  line(im,x,y,x+side*size,y-math.floor(size/2),p.ink,3)
  line(im,x,y-1,x+side*size,y-math.floor(size/2)-1,base or p.leaf,2)
  line(im,x+side,y-2,x+side*(size-1),y-math.floor(size/2)-2,hi or p.light)
end
local function flower(im,x,y,tint)
  oval(im,x,y,3,3,p.ink)
  for _,d in ipairs({{-2,0},{2,0},{0,-2},{0,2}}) do rect(im,x+d[1]-1,y+d[2]-1,2,2,tint) end
  rect(im,x-1,y-1,2,2,p.gold); px(im,x-1,y-1,p.cream)
end
local function plant(kind,n)
  local rootim,body,detail=Image(24,32),Image(24,32),Image(24,32)
  local sway=({0,1,0,-1})[n+1]
  line(rootim,9,31,15,31,p.ink); line(rootim,10,30,14,30,p.stem)
  if kind=="meadow_grass" or kind=="dry_grass" or kind=="frost_grass" then
    local base=kind=="dry_grass" and p.sand or (kind=="frost_grass" and p.blue or p.leaf)
    local hi=kind=="dry_grass" and p.dry or (kind=="frost_grass" and p.ice or p.light)
    for i=0,6 do local tip=4+i*2+sway; local y=({21,16,20,13,18,16,22})[i+1]
      line(body,10+i%4,30,tip,y,p.ink,2); line(detail,11+i%3,29,tip,y,base); px(detail,tip,y,hi)
      if kind=="dry_grass" and i%2==0 then line(detail,tip-1,y,tip+1,y-2,hi) end
    end
  elseif kind=="wildflower" then
    for _,v in ipairs({{7,19},{14,12},{18,22}}) do
      local x=v[1]+sway; line(body,12,30,x,v[2],p.ink,2); line(detail,12,29,x,v[2],p.stem)
      flower(detail,x,v[2],v[2]==12 and p.pink or p.cream)
    end
    leaf(detail,12,27,-1,4); leaf(detail,13,25,1,4)
  elseif kind=="fern" or kind=="ember_frond" then
    local base=kind=="fern" and p.leaf or p.ember; local hi=kind=="fern" and p.light or p.hot
    line(body,12,30,12+sway,8,p.ink,3); line(detail,12,29,12+sway,8,base)
    for y=12,28,4 do local size=math.min(8,math.floor((y-6)/2)); local x=12+sway*(30-y)/22
      leaf(detail,x,y,-1,size,base,hi); leaf(detail,x,y,1,size,base,hi) end
    px(detail,12+sway,7,hi)
  elseif kind=="berry_shrub" then
    line(body,12,31,11,17,p.bark,3); line(body,12,27,5+sway,19,p.bark,2); line(body,12,25,19+sway,17,p.bark,2)
    for _,v in ipairs({{6,22,5},{12,17,6},{18,22,5}}) do
      oval(body,v[1]+sway,v[2],v[3],5,p.ink); oval(detail,v[1]+sway,v[2]-1,v[3]-1,3,p.leaf)
      line(detail,v[1]-2+sway,v[2]-3,v[1]+1+sway,v[2]-3,p.light)
    end
    for _,v in ipairs({{7,22},{13,17},{17,22},{11,24}}) do rect(detail,v[1]+sway,v[2],2,2,p.red); px(detail,v[1]+sway,v[2],p.pink) end
  elseif kind=="reeds" then
    for _,v in ipairs({{7,12},{12,6},{17,14}}) do
      line(body,v[1],31,v[1]+sway,v[2],p.ink,2); line(detail,v[1],30,v[1]+sway,v[2],p.stem)
      rect(detail,v[1]+sway-1,v[2],3,6,p.brown); line(detail,v[1]+sway,v[2]+1,v[1]+sway,v[2]+3,p.dry)
      leaf(detail,v[1],26,v[1]<12 and -1 or 1,4)
    end
  elseif kind=="broadleaf" then
    line(body,12,31,12+sway,12,p.ink,3)
    for _,v in ipairs({{23,-1,7},{25,1,8},{17,-1,6},{15,1,6},{11,1,4}}) do leaf(detail,12+sway*(30-v[1])/20,v[1],v[2],v[3],p.shade,p.leaf) end
    line(detail,12,30,12+sway,13,p.light)
  elseif kind=="cactus" then
    oval(body,12+sway,13,4,5,p.ink); rect(body,8+sway,13,9,18,p.ink)
    rect(detail,10+sway,12,5,18,p.leaf); line(detail,11+sway,11,11+sway,28,p.light)
    line(body,9,23,4+sway,23,p.ink,4); line(body,4+sway,23,4+sway,17,p.ink,4)
    line(detail,9,22,4+sway,22,p.leaf,2); line(detail,4+sway,22,4+sway,17,p.leaf,2)
    line(body,15,20,20+sway,20,p.ink,4); line(body,20+sway,20,20+sway,14,p.ink,4)
    line(detail,15,19,20+sway,19,p.leaf,2); line(detail,20+sway,19,20+sway,14,p.leaf,2)
    for y=14,27,4 do px(detail,14+sway,y,p.cream); px(detail,9+sway,y+1,p.shade) end
    if n%2==0 then flower(detail,12+sway,9,p.pink) else flower(detail,12+sway,8,p.pink) end
  elseif kind=="moss" or kind=="lichen" then
    local base=kind=="moss" and p.shade or p.sand; local hi=kind=="moss" and p.leaf or p.cream
    for i=0,6 do local x=4+i*2; local h=({3,5,4,6,4,5,2})[i+1]
      line(body,x,30,x+sway,31-h,p.ink,3); line(detail,x,30,x+sway,31-h,base,2); px(detail,x+sway,30-h,hi) end
  elseif kind=="crystal_bloom" then
    for _,v in ipairs({{6,22},{12,12},{18,20}}) do local x=v[1]+sway
      line(body,12,31,x,v[2],p.ink,3); line(detail,12,30,x,v[2],p.blue)
      line(body,x,v[2]-5,x,v[2]+3,p.ink,5); line(detail,x,v[2]-4,x,v[2]+2,p.violet,3)
      line(detail,x-1,v[2]-2,x-1,v[2]+1,p.aqua); px(detail,x,v[2]-4,p.white)
    end
  elseif kind=="ice_coral" then
    for side=-1,1 do
      line(body,12,31,12+side*7+sway,15+math.abs(side)*4,p.ink,3)
      line(detail,12,30,12+side*7+sway,15+math.abs(side)*4,p.blue,2)
      for y=20,27,4 do line(detail,12+side*math.floor((30-y)/2),y,12+side*8+sway,y-4,p.ice,2) end
      px(detail,12+side*7+sway,14+math.abs(side)*4,p.white)
    end
  end
  return {rootim,body,detail}
end
local function fauna(kind,n)
  local rear,body,detail=Image(24,32),Image(24,32),Image(24,32)
  local stride=({-1,0,1,0})[n+1]
  if kind=="butterfly" or kind=="snow_moth" then
    local spread=({6,4,1,4})[n+1]; local tint=kind=="butterfly" and p.gold or p.ice
    for side=-1,1,2 do
      oval(rear,12+side*spread/2,24,spread/2+1,6,p.ink); oval(body,12+side*spread/2,23,math.max(1,spread/2),4,tint)
      oval(detail,12+side*spread/2,27,math.max(1,spread/2-1),2,kind=="butterfly" and p.ember or p.blue)
      px(detail,12+side*spread/2,21,p.cream)
    end
    line(detail,12,22,12,30,p.bark,2); line(detail,12,23,9,20,p.ink); line(detail,12,23,15,20,p.ink)
  elseif kind=="snail" then
    oval(rear,12,30,8,1,p.shade); oval(body,10,26,5,5,p.ink); oval(detail,10,26,4,4,p.sand)
    oval(detail,10,26,2,2,p.brown); line(detail,9,24,11,24,p.dry); px(detail,10,26,p.gold)
    line(body,15,30,19+stride,28,p.leaf,2); line(detail,18+stride,28,18+stride,25,p.shade); px(detail,18+stride,24,p.cream)
  elseif kind=="hare" then
    local bob=n==1 and -1 or 0
    oval(rear,6,27+bob,3,3,p.cream); oval(body,12,27+bob,7,4,p.bark); oval(detail,12,26+bob,6,3,p.sand)
    oval(body,18,24+bob,4,4,p.bark); oval(detail,18,24+bob,3,3,p.dry)
    line(body,16,22+bob,15+stride,15+bob,p.bark,3); line(body,19,22+bob,20+stride,16+bob,p.bark,3)
    line(detail,16,21+bob,15+stride,16+bob,p.pink); line(detail,19,21+bob,20+stride,17+bob,p.pink)
    px(detail,20,23+bob,p.ink); px(detail,21,25+bob,p.pink)
    line(rear,8,29,7-stride,31,p.bark,2); line(detail,16,29,17+stride,31,p.dry,2)
  elseif kind=="ground_bird" then
    line(rear,10,27,9+stride,31,p.brown); line(rear,15,27,16-stride,31,p.brown)
    line(rear,8,26,3,23+stride,p.ink,3); oval(body,12,25,6,4,p.ink); oval(detail,12,25,5,3,p.blue)
    oval(body,17,21,4,4,p.ink); oval(detail,17,21,3,3,p.gold); rect(detail,20,21,3,1,p.ember)
    px(detail,18,20,p.ink); line(detail,9,24,14,26+stride,p.shade,2); px(detail,11,23,p.ice)
  else
    local tint=kind=="ember_mite" and p.ember or (kind=="sand_hopper" and p.sand or p.leaf)
    for side=-1,1,2 do for leg=0,2 do line(rear,8+leg*3,28,7+leg*3+side*(2+stride),31,p.bark) end end
    oval(body,12,27,6,4,p.ink); oval(detail,11,26,4,3,tint); oval(body,17,28,2,2,p.bark)
    line(detail,11,24,11+stride,29,p.shade); px(detail,9,25,p.gold); px(detail,18,27,p.cream)
    if kind=="sand_hopper" then line(rear,9,28,6-stride,24,p.brown,2); line(rear,6-stride,24,4,31,p.sand) end
    line(detail,18,27,20+stride,25,p.ink)
  end
  return {rear,body,detail}
end
local names={"meadow_grass","wildflower","fern","berry_shrub","reeds","broadleaf","dry_grass","cactus","frost_grass","moss","lichen","crystal_bloom","ice_coral","ember_frond","beetle","butterfly","snail","sand_hopper","snow_moth","ember_mite","hare","ground_bird"}
local s=Sprite(24,32,ColorMode.RGB)
s.layers[1].name="Roots and rear silhouettes"
s:newLayer().name="Stems, bodies and wings"; s:newLayer().name="Leaves, faces and highlights"
local ranges={}; local index=0
for species,name in ipairs(names) do
  local first=index+1
  for n=0,3 do
    index=index+1; if index>1 then s:newEmptyFrame(index) end
    s.frames[index].duration=species<=14 and 0.22 or 0.14
    local images=species<=14 and plant(name,n) or fauna(name,n)
    for layer,im in ipairs(images) do
      local old=s.layers[layer]:cel(index)
      if old then old.image=im else s:newCel(s.layers[layer],index,im,Point(0,0)) end
    end
  end
  table.insert(ranges,{name=name,first=first,last=index})
end
-- Create tags only after the timeline exists, avoiding adjacent-tag expansion.
for _,r in ipairs(ranges) do s:newTag(r.first,r.last).name=r.name end
s.data=json.encode({pivot={12,32},canvas={24,32},species=22,plants=14,fauna=8})
local folder=root .. "/assets/sprites/source/ecology/"; app.fs.makeAllDirectories(folder)
s:saveAs(folder .. "ground_life.aseprite"); s:close()
dofile(root .. "/tools/export_ground_life_aseprite.lua")
