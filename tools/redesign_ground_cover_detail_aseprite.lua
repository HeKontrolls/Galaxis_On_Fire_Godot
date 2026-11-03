-- Detailed original pixel-art revision, performed inside Aseprite.
-- Existing canvas sizes, pivots, tags, durations and frame counts are kept.
local root=assert(app.params.root)
local function C(s) return app.pixelColor.rgba(tonumber(s:sub(1,2),16),tonumber(s:sub(3,4),16),tonumber(s:sub(5,6),16),255) end
local function px(im,x,y,c) x=math.floor(x); y=math.floor(y); if x>=0 and y>=0 and x<im.width and y<im.height then im:drawPixel(x,y,c) end end
local function line(im,x,y,xx,yy,c,w)
 x=math.floor(x); y=math.floor(y); xx=math.floor(xx); yy=math.floor(yy)
 local dx=math.abs(xx-x); local sx=x<xx and 1 or -1; local dy=-math.abs(yy-y); local sy=y<yy and 1 or -1; local e=dx+dy
 while true do local n=w or 1; for oy=0,n-1 do for ox=0,n-1 do px(im,x+ox-math.floor(n/2),y+oy-math.floor(n/2),c) end end
  if x==xx and y==yy then break end; local e2=2*e; if e2>=dy then e=e+dy; x=x+sx end; if e2<=dx then e=e+dx; y=y+sy end end
end
local function oval(im,x,y,rx,ry,c)
 for yy=math.floor(y-ry),math.ceil(y+ry) do for xx=math.floor(x-rx),math.ceil(x+rx) do if ((xx-x)/rx)^2+((yy-y)/ry)^2<=1 then px(im,xx,yy,c) end end end
end
local function poly(im,p,c)
 for y=0,im.height-1 do local xs={}
  for i,a in ipairs(p) do local b=p[i%#p+1]; if (a[2]<=y and b[2]>y) or (b[2]<=y and a[2]>y) then table.insert(xs,a[1]+(y-a[2])*(b[1]-a[1])/(b[2]-a[2])) end end
  table.sort(xs); for i=1,#xs-1,2 do for x=math.ceil(xs[i]),math.floor(xs[i+1]) do px(im,x,y,c) end end
 end
 for i,a in ipairs(p) do local b=p[i%#p+1]; line(im,a[1],a[2],b[1],b[2],c) end
end
local function layers() return {Image(48,40),Image(48,40),Image(48,40),Image(48,40)} end
local green={C("142e2c"),C("204735"),C("306742"),C("50894e"),C("83ae60"),C("b6ca7b")}
local forest={C("142b2d"),C("1b4038"),C("275e47"),C("3e805a"),C("6aa273"),C("9ac38a")}
local winter={C("263c4c"),C("365866"),C("4d7a83"),C("79a5a5"),C("b5d4cd"),C("e7eee0")}
local bark={C("382d2d"),C("66533b"),C("ad8b54")}
local function blade(im,x,y,side,length,p,light)
 -- Overlapping lance-shaped leaves with a shadow rim and a lit vein.
 poly(im,{{x,y+1},{x+side*2,y-2},{x+side*(length-1),y-3},{x+side*length,y-2},{x+side*(length-1),y},{x+side*2,y+2}},p[1])
 line(im,x+side,y,x+side*(length-1),y-2,p[light and 4 or 3],2)
 line(im,x+side*2,y-1,x+side*(length-1),y-2,p[light and 5 or 4])
 if light and length>4 then px(im,x+side*3,y-2,p[6]) end
end
local function tuft(im,cx,cy,rx,ry,p,index,offset)
 oval(im[1],cx+offset,cy,rx,ry,p[1])
 oval(im[2],cx+offset-1,cy-1,rx-1,ry-1,p[index%3==0 and 3 or 2])
 -- Leaf sprays are arranged around individual branches, rather than a grid.
 local sprays={{{-4,0,-1,4},{-1,-3,-1,5},{1,-2,1,5},{-1,2,-1,5},{3,2,1,4}},
  {{-3,-2,-1,5},{1,-4,1,4},{3,-1,1,5},{-2,2,-1,4},{1,3,1,5}},
  {{-4,1,-1,3},{-2,-2,-1,4},{2,-3,1,5},{3,1,1,4},{-1,3,1,4}}}
 for k,v in ipairs(sprays[index%3+1]) do blade(im[3],cx+v[1]+offset,cy+v[2],v[3],v[4],p,k<4) end
end
local function berry(im,x,y)
 oval(im,x,y,2,2,C("482d49")); px(im,x-1,y-1,C("cf6784")); px(im,x,y-1,C("f5b3a6")); px(im,x+1,y,C("9e4866"))
end
local function blossom(im,x,y,size)
 for _,v in ipairs({{-2,-1},{1,-2},{2,1},{-1,2}}) do oval(im,x+v[1],y+v[2],size,size-1,C("663956")); oval(im,x+v[1],y+v[2]-1,size-1,size-1,C("d9839c")) end
 px(im,x-2,y-2,C("f2c2bd")); px(im,x+2,y-2,C("f7d7c6")); line(im,x-1,y,x+1,y,C("f0ca73")); px(im,x,y+1,C("bc814b"))
end
local function shrub(kind,n)
 local im=layers(); local p=kind=="frost_bush" and winter or (kind=="forest_thicket" and forest or green)
 local sw=({0,1,0,-1})[n+1]
 -- Low interlocking volume, with overhanging leaf sprays and visible forks.
 local volume={{4,37},{4,32},{9,25},{17,19},{29,19},{38,25},{44,34},{42,38}}
 if kind=="forest_thicket" then volume={{3,37},{2,30},{10,25},{12,19},{24,20},{33,15},{42,24},{45,35},{40,38}} end
 if kind=="flowering_bush" then volume={{5,38},{5,31},{12,25},{17,23},{26,24},{33,21},{42,30},{43,38}} end
 if kind=="frost_bush" then volume={{5,38},{4,30},{12,26},{16,20},{24,24},{35,22},{43,31},{42,38}} end
 poly(im[1],volume,p[1]); oval(im[2],24,32,18,6,p[2])
 for _,v in ipairs({{24,38,16,24},{24,36,32,22},{18,32,8,30},{31,32,40,29}}) do
  line(im[2],v[1],v[2],v[3]+sw,v[4],bark[1],3); line(im[2],v[1],v[2]-1,v[3]+sw,v[4],bark[2])
 end
 local groups={{10,29,8,7},{18,22,9,8},{29,24,10,8},{38,31,8,6},{24,32,10,6}}
 if kind=="forest_thicket" then groups={{6,31,5,5},{14,25,8,7},{18,19,7,6},{28,24,9,7},{36,18,8,7},{40,29,7,7},{21,32,9,6}} end
 if kind=="flowering_bush" then groups={{10,31,6,6},{18,28,8,7},{28,29,8,7},{37,29,7,7},{28,20,6,5}} end
 if kind=="frost_bush" then groups={{10,31,7,6},{18,25,7,7},{29,29,8,7},{37,24,7,7},{24,34,10,5}} end
 for i,v in ipairs(groups) do tuft(im,v[1],v[2],v[3],v[4],p,i,math.floor(sw*(39-v[2])/17)) end
 -- Small overlapping leaves bridge the larger sprays and add depth below them.
 for i,v in ipairs({{9,34,-1},{14,29,1},{18,34,-1},{22,26,1},{26,34,1},{32,30,-1},{36,34,1},{29,21,-1}}) do
  blade(im[3],v[1],v[2],v[3],3+(i%2),p,i%3==0)
 end
 -- A few low fronds break up the base and hide the central "lollipop" stem.
 blade(im[4],15,37,-1,6,p,false); blade(im[4],29,37,1,6,p,false); blade(im[4],24,38,-1,5,p,false)
 if kind=="leafy_bush" then
  line(im[4],35,32,44,28,p[2]); line(im[4],44,28,45,25,p[3]); blade(im[4],40,29,1,4,p,true)
  berry(im[4],13+sw,27); berry(im[4],30+sw,29)
 elseif kind=="forest_thicket" then
  line(im[4],9,33,5,38,p[3]); line(im[4],37,30,42,37,p[3])
  for _,v in ipairs({{15,26},{28,22},{35,29}}) do px(im[4],v[1]+sw,v[2],C("789eaf")); px(im[4],v[1]+sw+1,v[2]+1,C("416e89")) end
 elseif kind=="flowering_bush" then
  for _,v in ipairs({{10,23,2},{20,15,3},{32,19,2},{39,26,2}}) do
   line(im[4],v[1],v[2]+7,v[1]+sw,v[2],p[2],2); blossom(im[4],v[1]+sw,v[2],v[3])
  end
  line(im[4],19,22,16,18,p[4]); px(im[4],16,17,C("d9839c"))
 else
  for _,v in ipairs({{10,28,7,22},{18,20,16,13},{30,25,33,15},{36,25,43,20}}) do
   line(im[4],v[1],v[2],v[3]+sw,v[4],C("a2babc")); px(im[4],v[3]+sw,v[4]-1,p[6])
  end
  for _,v in ipairs({{13,23},{22,22},{36,24},{30,32}}) do line(im[4],v[1]+sw-2,v[2],v[1]+sw+2,v[2]-1,p[6]); px(im[4],v[1]+sw,v[2]-2,C("f7f1d8")) end
  berry(im[4],24+sw,27); berry(im[4],38+sw,30)
 end
 -- Tapered, broken lower edges avoid a flat rectangular silhouette at ground.
 for x=0,47 do
  local edge=38-math.floor(math.abs(x-24)/10)-((x*7)%5==1 and 1 or 0)
  if x>=22 and x<=25 then edge=39 end
  for y=edge+1,39 do for layer=1,4 do px(im[layer],x,y,0) end end
 end
 return im
end
local stone={C("293744"),C("46545d"),C("687779"),C("8b9890"),C("bdc3aa"),C("e0d8b8")}
local sand={C("574247"),C("80604e"),C("a77b55"),C("ca9e69"),C("e9c28a"),C("f5dbae")}
local basalt={C("242638"),C("3d3d50"),C("555769"),C("797b88"),C("a6a7ad"),C("c0b9b1")}
local function mineral(im,mask,p,seed)
 -- Sparse clustered grains and tiny fractures follow existing opaque stone.
 for y=13,38 do for x=3,45 do
  if app.pixelColor.rgbaA(mask:getPixel(x,y))>0 then
   local q=(x*17+y*31+seed*13)%71
   if q==0 or q==1 then px(im,x,y,p[4]); if q==0 then px(im,x+1,y,p[5]) end
   elseif q==15 then px(im,x,y,p[2]) end
  end
 end end
end
local function rock(kind,n)
 local im=layers(); local p=kind=="sandstone_rock" and sand or (kind=="basalt_rock" and basalt or stone)
 if kind=="pebble_cluster" then
  local shapes={{{3,38},{2,35},{6,31},{11,32},{14,36},{12,39}},{{13,38},{15,29},{21,26},{28,27},{32,33},{30,39}},{{31,39},{30,35},{35,31},{41,32},{45,37},{42,39}}}
  for i,s in ipairs(shapes) do
   poly(im[1],s,p[1]); local cx=({8,23,38})[i]; local cy=({35,32,35})[i]
   oval(im[2],cx,cy,({5,8,6})[i],({3,5,3})[i],p[3]); line(im[3],cx-3,cy-2,cx+1,cy-3,p[5]); line(im[3],cx+2,cy-1,cx+3,cy+1,p[2])
   px(im[4],cx-1,cy-2,p[6]); px(im[4],cx+3,cy+2,p[4])
  end
  line(im[4],15,38,19,38,C("7d7657")); px(im[4],34,30,C("a7ab77"))
 elseif kind=="granite_boulder" then
  poly(im[1],{{3,38},{2,32},{6,26},{12,23},{14,18},{22,15},{30,17},{34,22},{41,25},{45,32},{43,38},{32,39},{14,39}},p[1])
  poly(im[2],{{4,34},{7,27},{14,25},{16,20},{23,17},{30,20},{34,25},{41,28},{43,35},{39,37},{13,38}},p[3])
  poly(im[3],{{7,28},{15,24},{17,20},{22,18},{28,19},{30,22},{23,24},{19,28},{12,30}},p[4])
  poly(im[3],{{22,27},{31,24},{39,29},{42,34},{37,36},{24,35},{18,32}},p[2])
  line(im[4],8,28,13,26,p[5]); line(im[4],17,21,22,19,p[5]); line(im[4],24,24,21,28,p[1]); line(im[4],21,28,26,31,p[1]); line(im[4],21,28,15,29,p[2])
  line(im[4],28,20,30,23,p[5]); line(im[4],29,33,35,34,p[4]); mineral(im[4],im[2],p,2)
 elseif kind=="mossy_boulder" then
  poly(im[1],{{6,39},{3,34},{6,24},{10,23},{13,12},{23,10},{29,15},{30,23},{39,24},{44,32},{41,39}},p[1])
  poly(im[2],{{6,33},{8,25},{14,24},{15,14},{22,12},{27,16},{27,25},{37,26},{41,33},{38,37},{10,38}},p[3])
  poly(im[3],{{15,15},{21,13},{25,16},{22,24},{17,29},{11,30},{13,24}},p[4])
  poly(im[3],{{25,19},{27,18},{27,26},{37,28},{39,33},{34,36},{21,36},{20,29}},p[2])
  line(im[4],23,14,20,21,p[1]); line(im[4],20,21,23,25,p[1]); line(im[4],23,25,19,30,p[1]); mineral(im[4],im[2],p,4)
  local sw=({0,1,0,-1})[n+1]
  for i,v in ipairs({{15,14},{20,12},{25,16},{13,24},{11,28},{29,26},{34,28},{37,31}}) do
   oval(im[4],v[1],v[2],3,2,green[2]); line(im[4],v[1]-2,v[2]-1,v[1]+1,v[2]-2,green[4]); px(im[4],v[1]+sw,v[2]-2,green[5])
  end
  line(im[4],11,27,8,35,green[2]); blade(im[4],9,31,-1,4,green,true); blade(im[4],32,29,1,4,green,false)
  line(im[4],19,13,17+sw,6,green[3]); blade(im[4],18+sw,10,-1,4,green,true); blade(im[4],17+sw,7,1,3,green,true)
 elseif kind=="sandstone_rock" then
  poly(im[1],{{3,39},{3,34},{7,32},{6,28},{11,26},{13,20},{21,18},{31,19},{33,24},{39,25},{42,30},{40,34},{45,36},{43,39}},p[1])
  poly(im[2],{{5,36},{9,32},{8,29},{15,27},{15,22},{22,20},{30,21},{32,25},{37,27},{39,31},{36,34},{42,37},{22,38}},p[3])
  poly(im[3],{{15,22},{23,20},{29,21},{30,23},{24,25},{14,26}},p[5]); poly(im[3],{{9,29},{17,27},{28,28},{34,27},{37,30},{29,32},{12,32}},p[4])
  line(im[4],14,26,24,25,p[2]); line(im[4],24,25,32,26,p[1]); line(im[4],8,33,21,33,p[1]); line(im[4],21,33,30,32,p[2]); line(im[4],30,32,37,33,p[1])
  line(im[4],9,29,17,28,p[6]); line(im[4],12,36,23,36,p[4]); line(im[4],32,28,29,31,p[2]); mineral(im[4],im[2],p,3)
 elseif kind=="basalt_rock" then
  local columns={{{5,37},{5,26},{10,22},{16,24},{16,38}},{{15,38},{14,16},{21,12},{28,15},{28,38}},{{27,38},{27,21},{34,16},{41,20},{43,37}}}
  for i,v in ipairs(columns) do
   poly(im[1],v,p[1]); local x=({6,16,29})[i]; local top=({25,15,20})[i]
   poly(im[2],{{x,top+2},{x+4,top},{x+8,top+2},{x+8,37},{x,37}},p[3]); poly(im[3],{{x+4,top+3},{x+8,top+2},{x+8,37},{x+4,37}},p[2])
   line(im[4],x,top+2,x+4,top,p[5]); line(im[4],x+1,top+9,x+6,top+8,p[1]); line(im[4],x+1,top+16,x+6,top+17,p[1])
   px(im[4],x+2,top+5,p[4])
  end
  line(im[4],25,23,24,28,C("88554f")); line(im[4],24,28,26,32,C("b77657")); px(im[4],24,27,C("dfac74")); mineral(im[4],im[2],p,7)
 end
 return im
end
local function fungi(n)
 local im=layers(); local sw=({0,1,0,-1})[n+1]
 local groups={{10,29,6,1},{24,22,8,-1},{38,28,6,-1},{29,34,3,1}}
 for i,v in ipairs(groups) do local x,y,r,side=v[1]+sw,v[2],v[3],v[4]
  line(im[1],v[1]-side*2,39,x+side,y+2,C("3c3441"),4); line(im[2],v[1]-side*2,38,x+side,y+2,C("baad8c"),2)
  line(im[3],v[1]-side*2-1,37,x+side-1,y+3,C("eed9aa"));
  poly(im[1],{{x-r-1,y+2},{x-r,y-2},{x-3,y-r+2},{x+2,y-r+1},{x+r-1,y-2},{x+r,y+2},{x+3,y+4},{x-3,y+4}},C("51313b"))
  poly(im[2],{{x-r,y+1},{x-r+2,y-3},{x-2,y-r+3},{x+2,y-r+2},{x+r-2,y-2},{x+r-1,y+1},{x+2,y+2},{x-3,y+2}},i==3 and C("9c6947") or C("bd6740"))
  line(im[3],x-r+2,y-1,x-2,y-r+4,C("e6a653"),2); line(im[3],x-2,y-r+4,x+2,y-r+3,C("f4c36e"))
  line(im[4],x-r+1,y+2,x+r-2,y+2,C("dfb18a"));
  for dx=-r+3,r-3,3 do line(im[4],x+dx,y+2,x+math.floor(dx/2),y+4,C("8a5f64")) end
  for _,p in ipairs({{-3,-2},{1,-4},{3,-1}}) do px(im[4],x+p[1],y+p[2],C("f3d7aa")); px(im[4],x+p[1]+1,y+p[2],C("d99b68")) end
 end
 line(im[4],5,39,7,35,green[3]); blade(im[4],40,38,1,4,green,true)
 return im
end
local source=root .. "/assets/sprites/source/ecology/"
local s=assert(app.open(source .. "ground_cover.aseprite"))
for i,name in ipairs({"Occlusion and silhouettes","Branches and volumes","Leaves and stone strata","Blooms, mineral glints and surface growth"}) do s.layers[i].name=name end
for _,tag in ipairs(s.tags) do for index=tag.fromFrame.frameNumber,tag.toFrame.frameNumber do
 local n=index-tag.fromFrame.frameNumber; local name=tag.name
 local images=name=="woodland_mushrooms" and fungi(n) or ((name:find("bush") or name=="forest_thicket") and shrub(name,n) or rock(name,n))
 for layer,im in ipairs(images) do s.layers[layer]:cel(index).image=im end
end end
s:saveAs(source .. "ground_cover.aseprite"); s:close()
local original=assert(app.open(source .. "ground_life.aseprite"))
for _,tag in ipairs(original.tags) do if tag.name=="berry_shrub" then for index=tag.fromFrame.frameNumber,tag.toFrame.frameNumber do
 local im=shrub("leafy_bush",index-tag.fromFrame.frameNumber); im[3]:drawImage(im[4],Point(0,0))
 for layer=1,3 do local small=Image(24,32)
  for y=0,19 do for x=0,23 do px(small,x,y+12,im[layer]:getPixel(x*2,y*2)) end end
  if layer==3 then berry(small,9,24); berry(small,15,25) end
  original.layers[layer]:cel(index).image=small
 end
end end end
original:saveAs(source .. "ground_life.aseprite"); original:close()
dofile(root .. "/tools/export_ground_life_aseprite.lua")
dofile(root .. "/tools/export_ground_cover_aseprite.lua")
print("ASEPRITE_DETAIL_REVISION completed: distinct silhouettes, leaf sprays, weathered stone and gilled fungi")
dofile(root .. "/tools/redesign_ground_rocks_reference_aseprite.lua")
