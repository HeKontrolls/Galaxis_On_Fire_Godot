-- All sprite pixels are authored by Aseprite's native Image/Sprite APIs.
local root=assert(app.params.root)
local integrity=dofile(root .. "/tools/biome_background_integrity.lua")
local src=root .. "/assets/sprites/source/backgrounds/"
local out=root .. "/assets/sprites/backgrounds/"
app.fs.makeAllDirectories(src); app.fs.makeAllDirectories(out)
local W,H=640,256
local function color(hex,a) return app.pixelColor.rgba(tonumber(hex:sub(1,2),16),tonumber(hex:sub(3,4),16),tonumber(hex:sub(5,6),16),a or 255) end
local function pixel(im,x,y,c) x=math.floor(x)%im.width; y=math.floor(y); if y>=0 and y<im.height then im:drawPixel(x,y,c) end end
local function line(im,x,y,xx,yy,c,r)
 local n=math.max(math.abs(xx-x),math.abs(yy-y)); for i=0,n do local t=n==0 and 0 or i/n
  for dx=-(r or 0),(r or 0) do for dy=-(r or 0),(r or 0) do pixel(im,x+(xx-x)*t+dx,y+(yy-y)*t+dy,c) end end
 end
end
local function ellipse(im,cx,cy,rx,ry,c)
 for y=math.floor(cy-ry),math.ceil(cy+ry) do for x=math.floor(cx-rx),math.ceil(cx+rx) do
  if ((x-cx)/rx)^2+((y-cy)/ry)^2<=1 then pixel(im,x,y,c) end
 end end
end
local function polygon(im,points,c)
 local low,high=H,0; for _,p in ipairs(points) do low=math.min(low,p[2]); high=math.max(high,p[2]) end
 for y=math.max(0,math.floor(low)),math.min(im.height-1,math.ceil(high)) do
  local hits={}; for i,a in ipairs(points) do local b=points[i%#points+1]
   if (a[2]<=y and b[2]>y) or (b[2]<=y and a[2]>y) then hits[#hits+1]=a[1]+(y-a[2])/(b[2]-a[2])*(b[1]-a[1]) end
  end
  table.sort(hits); for i=1,#hits-1,2 do for x=math.ceil(hits[i]),math.floor(hits[i+1]) do pixel(im,x,y,c) end end
 end
end
local function rng(seed)
 local state=seed
 return function(a,b) state=(state*48271)%2147483647; return a+state%(b-a+1) end
end
local function grain(x,y) return (x*83+y*137+math.floor(x/3)*math.floor(y/2)*17)%251 end
local function mix(a,b,t)
 local pc=app.pixelColor
 return pc.rgba(math.floor(pc.rgbaR(a)*(1-t)+pc.rgbaR(b)*t),math.floor(pc.rgbaG(a)*(1-t)+pc.rgbaG(b)*t),math.floor(pc.rgbaB(a)*(1-t)+pc.rgbaB(b)*t),255)
end
local palettes={
 forest={{"91b2ae","829f9f","acc4b5","c3d0b7"},{"598f7c","44796d","78a18a","9bbb8e"},{"396f57","2d584a","55865c","87a96c"}},
 coast={{"8caeb3","7399a5","adc5c2","d5d3b1"},{"5b9990","437f82","8cb7a1","d4cb9d"},{"397b70","2c6566","75a488","d9cc9c"}},
 desert={{"c9a7a0","b39396","dfb9a1","efd0aa"},{"bd927a","9b7570","d6ac85","e8c494"},{"aa795e","855f57","c69c72","dfb882"}},
 lava={{"9b868e","806f7e","ae9999","d6a195"},{"786675","5b5365","9a7d85","cf8b7b"},{"514d60","3c3c50","756475","d59276"}},
 barren={{"b1a6ab","918b9b","c6b9b4","d6c6ba"},{"91858c","746d7c","b1a09e","c8b1a4"},{"746b79","575665","95848c","b9a193"}},
 ice={{"b6d7df","95bacf","d7e9e8","ecf4ec"},{"8dbdcf","709dbd","bce1e4","e5f3ed"},{"65a1bc","5185a8","a6d4df","dfefec"}},
 snow={{"a3bec9","8ca6b9","c5d7dc","e5e9dd"},{"789eaa","5e8095","aec6c9","dce8df"},{"527f88","41616f","91b3b9","d7e8df"}}
}
local specifications={
 {"meadow","Meadow","forest","meadow",7}, {"woodland","Woodland","forest","forest",30}, {"dense_forest","Dense forest","forest","forest",56}, {"rocky_uplands","Rocky uplands","forest","cliffs",8},
 {"sandy_shore","Sandy shore","coast","coast",5}, {"coastal_grove","Coastal grove","coast","coast",24}, {"island_jungle","Island jungle","coast","jungle",43}, {"tidal_banks","Tidal banks","coast","stacks",8},
 {"coastal_grassland","Coastal grassland","coast","coast",8}, {"continental_forest","Continental forest","forest","waterfall",39}, {"rocky_coast","Rocky coast","coast","stacks",5}, {"sandbars","Sandbars","coast","sandbars",4},
 {"dune_sea","Dune sea","desert","dunes",9}, {"rocky_badlands","Rocky badlands","desert","mesas",4}, {"oasis","Oasis","desert","oasis",22}, {"stony_desert","Stony desert","desert","badlands",10},
 {"basalt_plains","Basalt plains","lava","basalt",0}, {"lava_fields","Lava fields","lava","volcano",0}, {"obsidian_flats","Obsidian flats","lava","shards",0}, {"volcanic_ridges","Volcanic ridges","lava","volcano",0},
 {"crater_basins","Crater basins","barren","craters",0}, {"rocky_highlands","Rocky highlands","barren","mesas",0}, {"dust_plains","Dust plains","barren","dust",0}, {"shattered_ridges","Shattered ridges","barren","arches",0},
 {"pack_ice","Pack ice","ice","ice",0}, {"fractured_ice","Fractured ice","ice","floes",0}, {"glacial_shelf","Glacial shelf","ice","glacier",0}, {"open_leads","Open leads","ice","floes",0},
 {"snowfields","Snowfields","snow","snow",5}, {"boreal_woodland","Boreal woodland","snow","pines",39}, {"exposed_rock","Exposed rock","snow","cliffs",5}, {"glacial_valleys","Glacial valleys","snow","glacier",9}
}
local manifest={version=1,width=W,height=H,planes={"far","middle","near"},scenes={}}

local function crown(im,cx,cy,rx,ry,p)
 for y=-ry,ry do for x=-rx,rx do
  if (x/rx)^2+(y/ry)^2 < 1+.11*math.sin(x*1.8+y*2.7) then
   local patch=grain(math.floor((cx+x)/3),math.floor((cy+y)/2))
   local c=(x+y*.7>rx*.5) and p[2] or (patch<86 and p[3] or p[1])
   if x+y< -rx*.65 and patch<45 then c=p[4] end
   pixel(im,cx+x,cy+y,c)
  end
 end end
end
local function tree(im,x,base,height,p,kind,random)
 local top=base-height; local width=math.max(1,math.floor(height/25))
 if kind=="pines" or kind=="snow" then
  line(im,x,top,x,base,p[2],width-1)
  for j=0,4 do local y=top+j*height*.16; local r=(j+1)*height*.07
   polygon(im,{{x,top+j*height*.115},{x-r,y+height*.31},{x-r*.5,y+height*.27},{x+r,y+height*.3}},p[2])
   polygon(im,{{x-1,top+j*height*.115},{x-r,y+height*.29},{x+r*.25,y+height*.28}},p[1])
   line(im,x-r*.8,y+height*.28,x-1,top+j*height*.115,p[4])
  end
 elseif kind=="palm" then
  local bend=height*.15
  line(im,x,base,x-bend*.4,top+height*.45,p[2],width)
  line(im,x-bend*.4,top+height*.45,x+bend,top,p[2],width-1)
  for dy=4,height-6,6 do pixel(im,x-bend*.4*(1-dy/height)-1,base-dy,p[3]) end
  for j=0,5 do local a=math.pi*(.12+j*.16); local dx=math.cos(a)*height*.4; local yy=math.sin(a)*height*.16
   polygon(im,{{x+bend,top},{x+bend+dx*.65,top-yy-2},{x+bend+dx,top+yy*.7},{x+bend+dx*.45,top-yy+3}},p[j%2==0 and 3 or 1])
  end
 else
  line(im,x,base,x,top+height*.22,p[2],width)
  line(im,x-width,base-2,x-width,top+height*.23,p[3])
  for j=-1,1 do line(im,x,top+height*.59,x+j*height*.2,top+height*.24+math.abs(j)*height*.08,p[2],width-1) end
  for j=1,6 do local cx=x+random(-height*.23//1,height*.23//1); local cy=top+random(0,height*.27//1)
   crown(im,cx,cy,math.max(3,height*.20//1),math.max(3,height*.14//1),p)
  end
 end
end

for index,spec in ipairs(specifications) do
 local id,label,family,kind,density=table.unpack(spec)
 local random=rng(17431+index*7919)
 local s=Sprite(W,H,ColorMode.RGB)
 local names={"Far landforms","Far facets and details","Middle landforms","Middle details and vegetation","Near landforms","Near details and vegetation"}
 for i,name in ipairs(names) do local l=i==1 and s.layers[1] or s:newLayer(); l.name=name end
 local images={Image(W,H),Image(W,H),Image(W,H),Image(W,H),Image(W,H),Image(W,H)}
 local phase=random(0,628)/100
 local smoke,falls={},{}
 for plane=1,3 do
  local shape,detail=images[plane*2-1],images[plane*2]
  local p={}; for i,hex in ipairs(palettes[family][plane]) do p[i]=color(hex) end
  local grain_dark,grain_light=mix(p[1],p[2],.38),mix(p[1],p[3],.32)
  local ridge={}; local amplitude=plane==1 and 29 or (plane==2 and 19 or 11)
  local base=plane==1 and 133 or (plane==2 and 163 or 186)
  local water=family=="coast" or family=="ice" or kind=="oasis"
  for x=0,W-1 do
   local a=x/W*math.pi*2
   local height=base+math.sin(a*3+phase)*amplitude+math.sin(a*7+phase*.6)*amplitude*.28+math.sin(a*13+phase)*2
   if kind=="dunes" or kind=="dust" then height=base+math.sin(a*2+phase)*amplitude+math.sin(a*4+phase)*5 end
   if kind=="cliffs" or kind=="mesas" or kind=="badlands" or kind=="basalt" or kind=="arches" then height=base-math.floor((.5+.5*math.sin(a*4+phase))*5)*8+math.sin(a*19)*2 end
   if family=="snow" or family=="ice" then height=base-math.abs(math.sin(a*3+phase))^3*(plane==1 and 64 or 27)+math.sin(a*11)*5 end
   if water then height=base+18+math.sin(a*3+phase)*4 end
   ridge[x]=math.floor(height)
   for y=ridge[x],H-1 do
    local c=p[1]; local g=grain(x//2,y//2)
    if g<3 and y>ridge[x]+5 then c=grain_dark elseif g>248 and y>ridge[x]+3 then c=grain_light end
    pixel(shape,x,y,c)
   end
   if not water then pixel(detail,x,ridge[x],p[3]) end
  end
  -- Deliberately spaced landmark compositions, rather than repeated triangles.
  if plane<3 and not (kind=="dunes" or kind=="dust" or kind=="meadow") then
   for j=0,5 do
    local x=j*111+random(-20,30); local floor=ridge[x%W]+random(12,32)
    local height=random(35,75)+(plane==1 and 10 or 0); local radius=random(35,68)
    local peak=x+random(-15,20); local top=floor-height
    if kind=="mesas" or kind=="basalt" or kind=="badlands" or kind=="cliffs" then
     polygon(shape,{{x-radius,floor},{x-radius*.5,top+5},{x+radius*.4,top},{x+radius,floor}},p[1])
     polygon(detail,{{x+radius*.15,top+2},{x+radius*.4,top},{x+radius,floor},{x+radius*.4,floor}},p[2])
     for yy=top+8,floor,7 do line(detail,x-radius*.4,yy,x+radius*.35,yy+random(-1,1),p[3]) end
    else
     if family=="coast" or kind=="oasis" then
      polygon(shape,{{x-radius,floor},{x-radius*.75,top+height*.62},{x-radius*.52,top+height*.42},{peak-17,top+11},{peak,top+5},{peak+17,top+10},{x+radius*.55,top+height*.45},{x+radius*.82,top+height*.69},{x+radius,floor}},p[1])
      polygon(detail,{{peak+3,top+7},{x+radius*.55,top+height*.45},{x+radius,floor},{peak+9,floor}},p[2])
      for k=-1,1 do tree(detail,peak+k*13,top+12+math.abs(k)*8,random(9,17),p,"forest",random) end
     else
      polygon(shape,{{x-radius,floor},{x-radius*.72,top+height*.65},{peak-radius*.4,top+height*.46},{peak-10,top+12},{peak,top},{peak+11,top+8},{peak+radius*.4,top+height*.5},{x+radius*.8,top+height*.71},{x+radius,floor}},p[1])
      polygon(detail,{{peak,top},{peak+11,top+8},{peak+radius*.4,top+height*.5},{x+radius,floor},{peak-6,floor}},p[2])
      polygon(detail,{{peak-10,top+15},{peak-radius*.4,top+height*.46},{x-radius,floor},{peak-21,top+height*.65}},p[3])
     end
     if family=="snow" or family=="ice" or (family=="forest" and plane==1) then
      polygon(detail,{{peak-10,top+12},{peak,top},{peak+11,top+8},{peak+22,top+31},{peak+7,top+25},{peak+2,top+33},{peak-7,top+23},{peak-22,top+38}},p[4])
     else line(detail,peak,top,peak-17,floor-8,p[3]) end
    end
   end
  end
  if water then
   local horizon=plane==1 and 151 or (plane==2 and 184 or 217)
   -- Native painted water highlights leave the far islands above the sea.
   local sea=family=="ice" and {"9abfce","7aa9bd","bfdce1"} or {"78a9af","4f929d","a6c9bf"}
   for y=horizon,H-1 do for x=0,W-1 do
    local c=color(sea[2]); if (y-horizon)%13==0 and grain(x//12,y)<105 then c=color(sea[3]) elseif (y-horizon)%7==0 then c=color(sea[1]) end
    pixel(shape,x,y,c); pixel(detail,x,y,0)
   end end
   for j=0,plane==1 and 3 or 2 do
    local x=37+j*193+random(-22,22); local width=random(25,65); local top=horizon-random(5,plane==1 and 21 or 15)
    if family=="ice" then
     polygon(shape,{{x-width,horizon+3},{x-width*.8,top},{x,top-5},{x+width*.85,top+1},{x+width,horizon+4}},p[3])
     line(detail,x-width*.8,top,x+width*.85,top+1,p[4]); line(detail,x-width,horizon+3,x+width,horizon+4,p[2])
     if kind=="glacier" or kind=="ice" then
      local peak=top-random(25,plane==1 and 65 or 45)
      polygon(shape,{{x-17,top},{x-5,peak+8},{x,peak},{x+15,top}},p[3])
      polygon(detail,{{x,peak},{x+15,top},{x+3,top}},p[1]); line(detail,x,peak,x-17,top,p[4])
     end
    else
     polygon(shape,{{x-width,horizon+3},{x-width*.65,top+2},{x,top},{x+width*.7,top+2},{x+width,horizon+3}},p[1])
     line(detail,x-width*.8,horizon+1,x+width*.8,horizon+1,p[4])
     if density>5 or kind=="oasis" then
      for k=-1,1 do tree(detail,x+k*13,top+3,random(17,plane==3 and 47 or 29),p,(kind=="jungle" and k==0) and "forest" or "palm",random) end
     end
    end
   end
  end
  if family=="forest" or family=="snow" or kind=="jungle" then
   local count=math.floor(density*(plane==1 and .55 or (plane==2 and .8 or 1)))
   for j=1,count do
    local x=random(0,W-1); local y=ridge[x]+2
    if not water then tree(detail,x,y,random(plane==3 and 39 or 17,plane==3 and 84 or 47),p,(family=="snow" or j%7==0) and "pines" or "forest",random) end
   end
   if kind=="meadow" and plane==3 then
    for j=1,95 do local x=random(0,W-1); local y=ridge[x]+random(0,14)
     line(detail,x,y,x+1,y-3,p[2]); pixel(detail,x,y-4,color(j%3==0 and "d4b48e" or "a4b9aa"))
    end
   end
   if (kind=="waterfall" or kind=="cliffs" or kind=="glacier") and plane==2 then
    for _,x in ipairs({163,479}) do local top=ridge[x]-12
     falls[#falls+1]={x=x,y=top+1}
     polygon(shape,{{x-42,top-6},{x+41,top},{x+50,235},{x-40,235}},p[2])
     for dx=-28,29,9 do line(detail,x+dx,top+9,x+dx+random(-3,3),232,p[1]) end
     for dx=-4,4 do line(detail,x+dx,top+1,x+dx+2,220,color(dx<0 and "a6cbd0" or "81b6c4")) end
     for yy=top+7,218,13 do line(detail,x-3,yy,x+5,yy+1,color("d0e4dc")) end
     tree(detail,x-18,top,34,p,"forest",random); tree(detail,x+22,top,29,p,"forest",random)
    end
   end
  end
  if family=="desert" and kind~="oasis" and plane>1 then
   for j=1,density do local x=random(0,W-1); local y=ridge[x]; local height=random(10,30)
    line(detail,x,y,x,y-height,p[2],1); line(detail,x-7,y-height*.5,x-7,y-height*.85,p[2],1)
    line(detail,x-7,y-height*.5,x,y-height*.5,p[2],1); line(detail,x+6,y-height*.3,x+6,y-height*.63,p[2],1)
    line(detail,x+6,y-height*.3,x,y-height*.3,p[2],1); line(detail,x-1,y-2,x-1,y-height+1,p[3])
   end
  end
  if family=="lava" then
   for j=0,3 do local x=j*180+random(-18,18); local base_y=ridge[x%W]+13
    if kind=="volcano" or plane==1 then
     local top=base_y-random(52,86)
     if kind=="volcano" and plane<3 then smoke[#smoke+1]={x=x,y=top,plane=plane-1} end
     polygon(shape,{{x-67,base_y},{x-12,top},{x+11,top+2},{x+72,base_y}},p[2])
     polygon(detail,{{x+11,top+2},{x+72,base_y},{x+20,base_y}},p[1])
     line(detail,x-10,top+1,x+10,top+2,color("e5ad8a"),1)
     line(detail,x+5,top+6,x-4,top+23,color("d6957c"),1); line(detail,x-4,top+23,x+17,top+43,color("ce8574"))
    elseif kind=="shards" or kind=="basalt" then
     for k=0,7 do local cx=x+k*9; local top=base_y-random(12,39)
      polygon(shape,{{cx-5,base_y},{cx-3,top+4},{cx,top},{cx+4,top+5},{cx+6,base_y}},p[2]); line(detail,cx,top,cx+2,base_y,p[3])
     end
    end
   end
  end
  if family=="barren" then
   for j=0,5 do local x=j*113+random(-10,10); local y=ridge[x%W]+random(8,29)
    if kind=="craters" then
     ellipse(detail,x,y,random(20,34),7,p[3]); ellipse(detail,x+2,y+2,21,5,p[2]); line(detail,x-18,y+1,x+15,y+2,p[1])
    elseif kind=="arches" and plane>1 then
     for k=0,80 do local a=k/80*math.pi; local px=x+math.cos(a)*34; local py=y-14-math.sin(a)*36
      ellipse(detail,px,py,6,10,p[2]); pixel(detail,px-3,py-5,p[3])
     end
    else for k=1,9 do line(detail,x-20,y+k*3,x+random(8,31),y+k*3-1,k%3==0 and p[3] or p[2]) end end
   end
  end
  integrity.repair(shape,detail)
 end
 for i,image in ipairs(images) do s:newCel(s.layers[i],1,image,Point(0,0)) end
 s:newTag(1,1).name=id; s:saveAs(src .. id .. ".aseprite"); s:close()
 local wildlife=(family=="coast" and "gull" or ((family=="forest" or kind=="oasis" or kind=="pines") and "songbird" or "none"))
 manifest.scenes[#manifest.scenes+1]={id=id,label=label,climate=(index-1)//4,biome=(index-1)%4,family=family,kind=kind,wildlife=wildlife,smoke=smoke,falls=falls,fireflies=(kind=="forest" or kind=="jungle" or kind=="waterfall" or kind=="oasis")}
end

local life=Sprite(16,12,ColorMode.RGB)
life.layers[1].name="Flight silhouettes"; local highlights=life:newLayer(); highlights.name="Wing and body highlights"
for frame=1,12 do
 if frame>1 then life:newEmptyFrame(frame) end
 local im,detail=Image(16,12),Image(16,12); local pose=(frame-1)%3
 if frame<=6 then
  local c=color(frame<=3 and "344f62" or "c4d8dc"); local wing=pose==0 and 2 or (pose==1 and 6 or 9)
  line(im,2,wing,6,5,c); line(im,6,5,8,6,c); line(im,8,6,11,4,c); line(im,11,4,14,wing-1,c)
  line(im,7,6,9,6,c,0); pixel(detail,10,5,color(frame<=3 and "819da2" or "7196ac"))
 elseif frame<=9 then
  ellipse(im,8,6,3,3,color("c9db8f",25+pose*12)); pixel(detail,8,6,color("e7f5c0",160+pose*45)); pixel(detail,8,5,color("c9e79f",140)); pixel(detail,9,6,color("a6d6a0",90))
 else
  line(im,7,1+pose,7,7+pose,color("cee5e3",155)); line(detail,9,3,9,6,color("ecf4e9",185)); pixel(detail,6,9,color("a8d4dc",120))
 end
 life:newCel(life.layers[1],frame,im,Point(0,0)); life:newCel(life.layers[2],frame,detail,Point(0,0))
end
for i,name in ipairs({"songbird","gull","firefly","waterfall"}) do life:newTag((i-1)*3+1,i*3).name=name end
life:saveAs(src .. "background_life.aseprite"); life:close()

local air=Sprite(128,96,ColorMode.RGB)
air.layers[1].name="Atmospheric color"; local al=air:newLayer(); al.name="Ribbons and vapor highlights"
for frame=1,6 do
 if frame>1 then air:newEmptyFrame(frame) end
 local im,hi=Image(128,96),Image(128,96); local phase=(frame-1)%3*.5
 if frame<=3 then
  for x=0,127 do local top=23+math.sin(x/128*math.pi*4+phase)*10+math.sin(x/128*math.pi*2)*8
   for y=0,74 do local delta=y-top; local strength=math.max(0,1-math.abs(delta-13)/25)
    strength=strength*(.65+.35*math.sin(x*.24+phase))
    if strength>0 then pixel(im,x,y,color(delta<9 and "79c9b5" or "759cbd",math.floor(strength*125))) end
    if delta>=0 and delta<2 then pixel(hi,x,y,color("a2e1c5",100)) end
   end
  end
 else
  for puff=0,6 do local x=61+math.sin(puff*.9+phase)*9-puff*2; local y=86-puff*10
   ellipse(im,x,y,8+puff*2,10,color("817c88",34-puff*3)); ellipse(hi,x-3,y-3,5+puff,6,color("aaa0a1",12))
  end
 end
 air:newCel(air.layers[1],frame,im,Point(0,0)); air:newCel(air.layers[2],frame,hi,Point(0,0))
end
air:newTag(1,3).name="aurora"; air:newTag(4,6).name="smoke"
air:saveAs(src .. "background_atmosphere.aseprite"); air:close()
local f=assert(io.open(out .. "catalog.json","w")); f:write(json.encode(manifest)); f:close()
dofile(root .. "/tools/export_biome_backgrounds_aseprite.lua")
