local root=assert(app.params.root)
local src=root.."/assets/sprites/source/underground/";local out=root.."/assets/sprites/underground/"
app.fs.makeAllDirectories(src);app.fs.makeAllDirectories(out)
local function rgba(h) return app.pixelColor.rgba(tonumber(h:sub(1,2),16),tonumber(h:sub(3,4),16),tonumber(h:sub(5,6),16),255) end
local function p(im,x,y,c) x=math.floor(x);y=math.floor(y);if x>=0 and y>=0 and x<im.width and y<im.height then im:drawPixel(x,y,rgba(c)) end end
local function poly(im,pts,c)
 for y=0,im.height-1 do local xs={};for i=1,#pts do local a,b=pts[i],pts[i%#pts+1];if (a[2]<=y and b[2]>y) or (b[2]<=y and a[2]>y) then xs[#xs+1]=a[1]+(y-a[2])*(b[1]-a[1])/(b[2]-a[2]) end end;table.sort(xs);for i=1,#xs-1,2 do for x=math.ceil(xs[i]),math.floor(xs[i+1]) do p(im,x,y,c) end end end
end
local palettes={{"244c76","438fc5","8bd9ee","dcf7e9"},{"493167","8452b0","c594ef","efd8f3"},{"285541","50a26e","a2e2a3","e0efba"},{"71432c","bc773e","f0bf6c","ffedb4"},{"652e54","af588a","eb9ac4","f9d9df"}}
local names={"crystal_0","crystal_1","crystal_2","crystal_3","crystal_4","stalagmite_0","stalagmite_1","stalactite_0","stalactite_1","drip","splash","cave_fungus"}
local s=Sprite(32,48,ColorMode.RGB);s.layers[1].name="Formation and silhouette";local detail=s:newLayer();detail.name="Facets, weathering and highlights"
for i,name in ipairs(names) do
 if i>1 then s:newEmptyFrame() end
 local a,b=Image(32,48,ColorMode.RGB),Image(32,48,ColorMode.RGB)
 if i<=5 then
  local c=palettes[i]
  for _,q in ipairs({{7,28,5},{17,11,7},{25,30,4}}) do
   local x,y,w=q[1],q[2],q[3]
   poly(a,{{x-w,y+7},{x,y},{x+w,y+6},{x+w-1,45},{x,47},{x-w+1,43}},c[1])
   poly(b,{{x-w+1,y+8},{x,y+2},{x+1,43},{x-w+2,42}},c[3])
   poly(b,{{x+1,y+3},{x+w-1,y+7},{x+w-2,42},{x+1,45}},c[2])
   for yy=y+7,40,7 do p(b,x-2,yy,c[4]);p(b,x-1,yy+1,c[3]) end
  end
  poly(a,{{3,44},{9,42},{20,43},{29,44},{30,47},{2,47}},c[1])
  for x=4,28,3 do p(b,x,45,c[2]) end
 elseif i<=9 then
  local variant=(i-6)%2;local ceiling=i>=8
  local c={"514c40","8b8165","bbb18a","d1c7a0"}
  for _,q in ipairs({{15,5,8},{6,30,4},{25,25,5}}) do
   local x,y,w=q[1],q[2]+variant*4,q[3]
   poly(a,{{x,y},{x+2,y+8},{x+w,46},{x-w,46},{x-2,y+10}},c[1])
   poly(b,{{x,y+3},{x+1,y+12},{x+2,44},{x-w+2,44}},c[2])
   for yy=y+10,44,4 do for xx=x-2,x+1 do p(b,xx,yy,c[3]);if (xx+yy)%3==0 then p(b,xx,yy+1,c[1]) end end end
   p(b,x,y+5,c[4])
  end
  if ceiling then
   local aa,bb=Image(32,48,ColorMode.RGB),Image(32,48,ColorMode.RGB)
   for y=0,47 do for x=0,31 do aa:drawPixel(x,47-y,a:getPixel(x,y));bb:drawPixel(x,47-y,b:getPixel(x,y)) end end;a,b=aa,bb
  end
 elseif name=="drip" then
  poly(a,{{16,40},{18,44},{17,47},{14,46},{14,44}},"478aa6");p(b,16,44,"a4dce7");p(b,15,45,"c3eced")
 elseif name=="cave_fungus" then
  for _,q in ipairs({{11,18,10},{23,31,7}}) do
   local x,y,w=q[1],q[2],q[3]
   poly(a,{{x-2,y+4},{x+2,y+4},{x+3,47},{x-3,47}},"456b55")
   poly(b,{{x-1,y+6},{x+1,y+6},{x+1,46},{x,44}},"9bbd89")
   poly(a,{{x-w,y+7},{x-w+2,y+2},{x-2,y-3},{x+3,y-2},{x+w,y+4},{x+w,y+8}},"315443")
   poly(b,{{x-w+2,y+5},{x-2,y},{x+3,y},{x+w-2,y+5},{x+4,y+6},{x-5,y+6}},"6b9f68")
   for xx=x-w+3,x+w-2,4 do p(b,xx,y+4,"bee0a3");p(b,xx,y+7,"9acb8a") end
  end
 else
  for x=10,22 do p(a,x,46,"487f96") end
  p(b,10,43,"91c3d5");p(b,12,45,"b3dbe2");p(b,21,43,"91c3d5");p(b,19,45,"b3dbe2")
 end
 if i==1 then s.layers[1]:cel(i).image=a else s:newCel(s.layers[1],i,a,Point(0,0)) end
 s:newCel(detail,i,b,Point(0,0))
end
for i,name in ipairs(names) do s:newTag(i,i).name=name end
s:saveAs(src.."cave_formations.aseprite");s:close()
local terrain={{"363d28","586044","737757"},{"555248","817b68","a29b83"},{"354d57","587781","78949c"},{"47384f","705a7c","9982a3"},{"303f37","4c6751","739069"},{"3d3535","64504a","8a6c59"},{"49312b","784a36","9d6843"}}
local t=Sprite(16,16,ColorMode.RGB);t.layers[1].name="Rock and sediment";local flecks=t:newLayer();flecks.name="Pixel grain and fissures"
for i,c in ipairs(terrain) do
 if i>1 then t:newEmptyFrame() end
 local a,b=Image(16,16,ColorMode.RGB),Image(16,16,ColorMode.RGB)
 for y=0,15 do for x=0,15 do
  p(a,x,y,c[2]);local h=(math.floor(x/2)*17+math.floor(y/2)*31+i*7)%23
  if h<5 then p(b,x,y,c[1]) elseif h<9 and (x+y)%2==0 then p(b,x,y,c[3]) end
  if (x+math.floor(y/4))%13==0 and y%7<4 then p(b,x,y,c[1]) end
 end end
 if i==1 then t.layers[1]:cel(i).image=a else t:newCel(t.layers[1],i,a,Point(0,0)) end;t:newCel(flecks,i,b,Point(0,0))
end
for i=1,7 do t:newTag(i,i).name="biome_"..(i-1) end
t:saveAs(src.."cave_tiles.aseprite");t:close()
dofile(root.."/tools/export_underground_aseprite.lua")
