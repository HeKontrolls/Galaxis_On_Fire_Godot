-- All new pixels are painted by Aseprite's native image API.
local root=assert(app.params.root)
local source=root .. "/assets/sprites/source/expansion/"; app.fs.makeAllDirectories(source)
local function C(h) return app.pixelColor.rgba(tonumber(h:sub(1,2),16),tonumber(h:sub(3,4),16),tonumber(h:sub(5,6),16),255) end
local function p(im,x,y,c) x=math.floor(x); y=math.floor(y); if x>=0 and x<im.width and y>=0 and y<im.height then im:drawPixel(x,y,type(c)=="string" and C(c) or c) end end
local function rect(im,x,y,w,h,c) for yy=y,y+h-1 do for xx=x,x+w-1 do p(im,xx,yy,c) end end end
local function line(im,x,y,xx,yy,c,w)
 x=math.floor(x); y=math.floor(y); xx=math.floor(xx); yy=math.floor(yy)
 local dx=math.abs(xx-x); local sx=x<xx and 1 or -1; local dy=-math.abs(yy-y); local sy=y<yy and 1 or -1; local err=dx+dy
 while true do local n=w or 1; rect(im,x-math.floor(n/2),y-math.floor(n/2),n,n,c); if x==xx and y==yy then break end
  local e=2*err; if e>=dy then err=err+dy; x=x+sx end; if e<=dx then err=err+dx; y=y+sy end
 end
end
local function poly(im,points,c)
 for y=0,im.height-1 do local xs={}; for i,a in ipairs(points) do local b=points[i%#points+1]
  if (a[2]<=y and b[2]>y) or (b[2]<=y and a[2]>y) then table.insert(xs,a[1]+(y-a[2])*(b[1]-a[1])/(b[2]-a[2])) end
 end; table.sort(xs); for i=1,#xs-1,2 do for x=math.ceil(xs[i]),math.floor(xs[i+1]) do p(im,x,y,c) end end end
 for i,a in ipairs(points) do local b=points[i%#points+1]; line(im,a[1],a[2],b[1],b[2],c) end
end
local function oval(im,x,y,rx,ry,c)
 for yy=math.floor(y-ry),math.ceil(y+ry) do for xx=math.floor(x-rx),math.ceil(x+rx) do if ((xx-x)/rx)^2+((yy-y)/ry)^2<=1 then p(im,xx,yy,c) end end end
end
local function document(name,w,h,layers,tags,paint)
 local s=Sprite(w,h,ColorMode.RGB)
 for i,label in ipairs(layers) do local layer=i==1 and s.layers[1] or s:newLayer(); layer.name=label end
 local index=0; local spans={}
 for _,tag in ipairs(tags) do local first=index+1
  for frame=0,(tag.frames or 1)-1 do index=index+1; if index>1 then s:newEmptyFrame(index) end; s.frames[index].duration=0.22
   local images={}; for i=1,#layers do images[i]=Image(w,h,ColorMode.RGB) end
   paint(tag.name,frame,images)
   for i,im in ipairs(images) do s:newCel(s.layers[i],index,im,Point(0,0)) end
  end
  table.insert(spans,{name=tag.name,first=first,last=index,height=tag.height or h})
 end
 for _,span in ipairs(spans) do s:newTag(span.first,span.last).name=span.name end
 local palette=Palette(256); local swatches={"172c2b","284634","376545","528450","77a55e","a8c57b","e0d6ab","70513d","a97851","d0a878","453b50","875e91","c48cb2","b94e53","e28a6c","e8c268","b5d7da","6caebd","537689","343847"}
 for slot,hex in ipairs(swatches) do palette:setColor(slot-1,Color{r=tonumber(hex:sub(1,2),16),g=tonumber(hex:sub(3,4),16),b=tonumber(hex:sub(5,6),16)}) end; s:setPalette(palette)
 s.data=json.encode({version=1,canvas={w,h},runtime_tags=spans,workflow="native_aseprite"})
 s:saveAs(source .. name .. ".aseprite"); s:close()
end
local ore_names={"coal","copper","iron","gold","crystal","diamond","ancient_debris"}; local ore_tags={}
for _,name in ipairs(ore_names) do table.insert(ore_tags,{name=name,frames=4}) end
local ore_colors={{"252a34","46505b","65717c"},{"784b37","bc784a","e4ac73"},{"5f5c5c","a69a91","dbd1bf"},{"886027","c49b43","f2d57a"},{"503865","9167b2","d5a9e0"},{"245b68","4eafb8","b1eeec"},{"3d2c30","745048","b88c6d"}}
document("underground_ores",16,16,{"Mineral shadows","Facets and exposed seams","Mineral highlights"},ore_tags,function(name,frame,images)
 local kind=1; for i,n in ipairs(ore_names) do if name==n then kind=i end end; local col=ore_colors[kind]
 local shapes={{{2,4},{4,3},{6,5},{5,7},{2,7}},{{9,2},{12,1},{14,4},{12,6},{9,5}},{{6,10},{8,8},{11,10},{10,13},{7,14}},{{12,11},{14,10},{15,13},{13,14}}}
 for index,shape in ipairs(shapes) do local shifted={}; for _,v in ipairs(shape) do table.insert(shifted,{v[1]+((frame+index)%3-1),v[2]+(frame%2)}) end
  poly(images[1],shifted,col[1]); local x=shifted[1][1]+1; local y=shifted[1][2]
  rect(images[2],x,y,2,2,col[2]); line(images[3],x,y,x+1,y,col[3]); p(images[2],x+1,y+2,col[2])
 end
 if name=="crystal" or name=="diamond" then poly(images[2],{{7,2+frame%2},{9,5},{8,9},{6,7}},col[2]); line(images[3],7,3+frame%2,7,6,col[3]) end
 if name=="ancient_debris" then line(images[2],1,9,5,11,col[2]); line(images[3],2,9,4,10,col[3]); line(images[2],11,7,14,8,col[2]) end
end)
document("advanced_pickaxes",32,40,{"Handle and bindings","Tool head","Edges and inlays"},{{name="gold_pickaxe"},{name="diamond_pickaxe"},{name="netherite_pickaxe"}},function(name,frame,im)
 line(im[1],13,12,17,36,"302b32",4); line(im[1],14,13,17,35,"88613f",2); line(im[3],14,14,16,33,"c39764")
 local col=name=="gold_pickaxe" and {"65452c","bd8b36","f2d885"} or (name=="diamond_pickaxe" and {"254954","419aa7","a6ece5"} or {"242633","494454","887493"})
 poly(im[2],{{3,15},{6,10},{12,7},{20,8},{26,12},{28,18},{24,15},{19,12},{12,11},{7,13}},col[1])
 poly(im[2],{{5,13},{8,10},{13,8},{19,9},{24,12},{26,15},{20,11},{12,10},{7,12}},col[2])
 line(im[3],8,10,12,8,col[3]); line(im[3],13,8,19,9,col[3]); p(im[3],25,13,col[3])
 rect(im[3],13,12,4,3,"51404a"); line(im[3],14,12,16,12,col[3]); rect(im[3],15,18,2,2,col[1])
 if name=="diamond_pickaxe" then p(im[3],4,13,col[3]); p(im[3],27,16,col[3]); rect(im[3],16,21,1,3,col[2]) end
 if name=="netherite_pickaxe" then line(im[3],7,12,12,10,"b39eac"); rect(im[3],14,14,3,2,"8d6551"); line(im[3],21,11,25,14,"716078") end
end)
document("advanced_materials",32,32,{"Silhouette","Material body","Facets and shine"},{{name="diamond"},{name="ancient_debris"},{name="netherite_scrap"},{name="netherite_ingot"}},function(name,frame,im)
 if name=="diamond" then
  poly(im[1],{{5,10},{11,5},{23,6},{28,12},{17,28}},"244451")
  poly(im[2],{{7,11},{12,7},{22,8},{26,12},{17,25}},"59b9c0")
  poly(im[3],{{12,8},{19,8},{16,23},{10,12}},"c4f7ee"); line(im[3],7,12,25,12,"86ddd9"); line(im[3],20,9,24,12,"e4fff0")
 elseif name=="ancient_debris" then
  poly(im[1],{{4,10},{11,5},{25,7},{28,23},{18,29},{5,25}},"302934"); poly(im[2],{{6,11},{12,7},{23,9},{26,22},{18,26},{7,23}},"785147")
  for y=10,23,4 do line(im[3],8,y,21,y+2,"b68e71"); line(im[3],10,y+1,17,y+2,"442f36") end
 else
  local ingot=name=="netherite_ingot"
  poly(im[1],ingot and {{4,14},{10,8},{24,8},{28,14},{26,23},{6,23}} or {{5,12},{12,7},{20,10},{26,18},{21,26},{7,23}},"242732")
  poly(im[2],ingot and {{6,14},{11,10},{23,10},{26,14},{24,20},{8,20}} or {{7,13},{12,9},{19,12},{23,18},{19,23},{9,21}},"5c5060")
  line(im[3],9,13,22,13,"a4919e"); line(im[3],8,15,23,15,"756474"); line(im[3],10,20,20,21,"8c6753")
 end
end)
document("glacial_facets",64,128,{"Ice body","Long crystal faces","Fractures and glints"},{{name="glacial_facets"}},function(name,frame,im)
 rect(im[1],0,0,64,128,"5687a4")
 for offset=-64,128,32 do
  poly(im[2],{{offset,0},{offset+13,0},{offset-18,128},{offset-32,128}},"72afc6")
  poly(im[2],{{offset+13,0},{offset+22,0},{offset-10,128},{offset-18,128}},"91c8d6")
  line(im[3],offset+14,0,offset-18,127,"b6dfe6")
 end
 for _,seam in ipairs({{9,31,24,37},{37,71,50,64},{13,106,27,112}}) do
  line(im[3],seam[1],seam[2],seam[3],seam[4],"466d8d")
  line(im[3],seam[1],seam[2]-1,seam[3]-2,seam[4]-1,"a0cfdb")
 end
 for _,v in ipairs({{27,16},{7,88},{53,48},{37,119}}) do p(im[3],v[1],v[2],"daeff0"); p(im[3],v[1],v[2]+1,"a5d4df") end
end)
document("glacial_ice",16,16,{"Ice mass","Translucent facets","Edge glints"},{{name="glacial_ice",frames=4}},function(name,frame,im)
 rect(im[1],0,0,16,16,"426d91"); poly(im[2],{{0,0},{10+frame,0},{4,16},{0,16}},"79bdd3"); poly(im[2],{{12,0},{16,0},{16,16},{5+frame,16}},"578fae")
 line(im[3],0,0,14,0,"c6f1f2"); line(im[3],0,1,0,14,"abdde5"); line(im[3],9+frame%3,1,4,14,"aadce5"); line(im[2],13,6,8,15,"365d84"); p(im[3],3,5,"e0ffff")
end)
-- Desert flora uses the forest set's dark green outlines, clustered highlights,
-- woody bark grain and varied flowers rather than flat silhouettes.
local ink="1c342d"; local dark="284735"; local green="4c8151"; local light="82ae69"; local bright="b7cf82"
local desert={
 {"opuntia",52},{"joshua_tree",86},{"golden_barrel",32},{"saguaro",86},{"brittlebush",38},
 {"ghost_plant",24},{"foxtail_agave",76},{"tumbleweed",40},{"desert_marigold",36},{"desert_lily",60},
 {"jade_plant",42},{"aloe_vera",32},{"chaste_tree",82},{"cane_cholla",70},{"mexican_fencepost",82}}
local tags={}; for _,v in ipairs(desert) do table.insert(tags,{name=v[1],height=v[2],frames=4}) end
local function pad(im,x,y,rx,ry)
 oval(im,x,y,rx+1,ry+1,ink); oval(im,x,y,rx,ry,dark); oval(im,x-1,y-1,math.max(1,rx-1),math.max(1,ry-1),green)
 line(im,x-rx+2,y-ry+2,x-rx+1,y+ry-2,light)
 for yy=math.floor(y-ry+2),math.floor(y+ry-1),4 do p(im,x+2,yy,"d1cfa0"); p(im,x-rx,yy+1,"bdc397") end
end
local function stem(im,x,y,xx,yy,width)
 line(im,x,y,xx,yy,ink,width+2); line(im,x,y,xx,yy,"78553e",width); line(im,x-1,y,xx-1,yy,"b88c58",1)
 for t=0,4 do local u=t/4; p(im,x+(xx-x)*u+1,y+(yy-y)*u,"d6ad73") end
end
local function leaf(im,x,y,xx,yy,w,c)
 local dx,dy=xx-x,yy-y; local length=math.max(1,math.sqrt(dx*dx+dy*dy)); local nx,ny=-dy/length*w,dx/length*w
 poly(im,{{x,y},{x+dx*.45+nx,y+dy*.45+ny},{xx,yy},{x+dx*.4-nx*.6,y+dy*.4-ny*.6}},ink)
 poly(im,{{x,y},{x+dx*.5+nx*.6,y+dy*.5+ny*.6},{xx,yy},{x+dx*.5-nx*.2,y+dy*.5-ny*.2}},c or green)
 line(im,x,y,xx,yy,light)
end
local function bloom(im,x,y,color,phase)
 for _,v in ipairs({{-3,0},{3,0},{0,-3},{0,3},{-2,-2},{2,-2}}) do oval(im,x+v[1],y+v[2],2,2,color) end
 oval(im,x,y,2,2,"8a5633"); p(im,x-1,y-1,"f7df88"); if phase%2==1 then p(im,x+3,y-2,"ffedb2") end
end
document("desert_flora",64,96,{"Trunks and ground contact","Deep foliage","Leaves and ribs","Flowers fruit and thorns"},tags,function(name,frame,im)
 local a,b,c,d=im[1],im[2],im[3],im[4]; local wob=frame==1 and 1 or (frame==3 and -1 or 0)
 if name=="opuntia" then
  stem(a,32,95,31,75,4)
  for _,v in ipairs({{31,79,6,9},{21,69,7,9},{41,67,7,10},{24,53,5,8},{43,49,5,7},{32,61,5,8}}) do pad(b,v[1],v[2],v[3],v[4]) end
  for _,v in ipairs({{21,58},{43,40},{30,51},{17,65}}) do oval(d,v[1],v[2]+wob,2,3,"873a51"); p(d,v[1]-1,v[2]-1+wob,"e1837a") end
 elseif name=="joshua_tree" or name=="chaste_tree" then
  local j=name=="joshua_tree"; stem(a,31,95,32,43,j and 7 or 5); stem(a,32,66,17,44,4); stem(a,32,53,48,34,4); stem(a,32,45,30,23,4)
  for _,v in ipairs(j and {{16,41},{29,20},{48,31},{35,48}} or {{17,42},{31,22},{47,34},{36,49},{22,60}}) do
   if j then for k=0,10 do local angle=k/10*math.pi*2; leaf(c,v[1],v[2]+4,v[1]+math.cos(angle)*(10+(k%3)*2),v[2]+math.sin(angle)*10,2,k%2==0 and green or dark) end
   else
    for k=0,7 do local angle=k/8*math.pi*2; leaf(c,v[1],v[2]+5,v[1]+math.cos(angle)*9,v[2]+math.sin(angle)*8,3,green) end
    for yy=0,8,2 do oval(d,v[1]+wob,v[2]-yy,math.max(1,3-math.floor(yy/4)),1,yy%4==0 and "bc8fca" or "785387") end
   end
  end
  if j then for y=54,88,5 do line(d,29,y,34,y+2,"594336"); p(d,28,y,"d3b27c") end end
 elseif name=="golden_barrel" then
  oval(b,32,80,15,15,ink); oval(c,32,79,13,14,"8c963f")
  for offset=-10,10,4 do for y=68,90 do local curve=offset*(0.5+0.5*math.sin((y-66)/26*math.pi)); p(c,32+curve,y,"c2ba5a"); if y%4==0 then line(d,31+curve,y,33+curve,y-1,"e9d69c") end end end
  oval(d,32,68,5,2,"b88238"); p(d,30,67,"f1d579")
 elseif name=="saguaro" or name=="mexican_fencepost" then
  local ribs=name=="saguaro" and {{31,14,5},{19,47,4},{45,35,4}} or {{21,35,4},{31,15,5},{43,26,4}}
  for index,v in ipairs(ribs) do
   if name=="saguaro" and index>1 then line(b,v[1],67,31,67,ink,9); line(c,v[1],66,31,66,green,6) end
   local base=name=="saguaro" and index>1 and 67 or 95
   oval(b,v[1],v[2]+v[3],v[3]+1,v[3]+1,ink); rect(b,v[1]-v[3]-1,v[2]+v[3],v[3]*2+3,base-v[2]-v[3]+1,ink)
   rect(c,v[1]-v[3],v[2]+v[3],v[3]*2+1,base-v[2]-v[3],green); oval(c,v[1],v[2]+v[3],v[3],v[3],green)
   for y=v[2]+4,base-1 do p(c,v[1]-2,y,light); p(c,v[1]+2,y,dark); if y%5==0 then p(d,v[1]-v[3],y,"d8d1a3"); p(d,v[1]+2,y,"bdc397") end end
   if frame%2==0 then p(d,v[1],v[2]+2,"e7d2a9") end
  end
 elseif name=="tumbleweed" then
  oval(b,32,77,20,18,"55432f")
  for k=0,15 do local angle=k/16*math.pi*2; local x=32+math.cos(angle)*17; local y=77+math.sin(angle)*16
   line(c,32+math.cos(angle+2)*12,77+math.sin(angle+2)*12,x,y,k%2==0 and "a58655" or "c1a472")
   line(d,x,y,32+math.cos(angle+0.7)*19,77+math.sin(angle+0.7)*16,"d3ba84")
  end
  for k=0,8 do line(d,16+k*4,69+(k%3)*4,21+k*3,87-k%4,"b89a67") end
 elseif name=="ghost_plant" or name=="foxtail_agave" or name=="aloe_vera" then
  local ghost=name=="ghost_plant"; local agave=name=="foxtail_agave"; local color=ghost and "9cbcb1" or (agave and "669c8a" or "578c57")
  for k=0,10 do local angle=-math.pi+0.1+k/10*(math.pi-0.2); local radius=ghost and 18 or (agave and 24 or 22)
   leaf(c,32,94,32+math.cos(angle)*radius,94+math.sin(angle)*(ghost and 17 or (agave and 30 or 27)),ghost and 5 or 3,color)
   if name=="aloe_vera" then p(d,32+math.cos(angle)*radius*.6,94+math.sin(angle)*20,"e5d9a7") end
  end
  if agave then
   line(a,32,86,37,48,"6c784e",3); line(a,37,48,46,30,"6c784e",3); line(a,46,30,44,25,"6c784e",3)
   for y=29,57,3 do local x=42-(y-29)/6; oval(d,x+wob,y,3,2,y%2==0 and "d6d69c" or "b6bd79") end
  elseif ghost then oval(d,32,87,4,3,"cee0c5"); p(d,30,85,"f0e6d2") end
 elseif name=="cane_cholla" then
  stem(a,32,95,32,66,3)
  for _,v in ipairs({{32,68,31,35},{31,62,17,51},{32,56,46,43},{17,51,16,30},{46,43,47,27}}) do
   line(b,v[1],v[2],v[3],v[4],ink,7); line(c,v[1],v[2],v[3],v[4],"70916b",5)
   local steps=math.max(math.abs(v[3]-v[1]),math.abs(v[4]-v[2])); for n=0,steps,4 do local t=n/steps; local x=v[1]+(v[3]-v[1])*t; local y=v[2]+(v[4]-v[2])*t; line(d,x-3,y,x+3,y-1,"d4d5ad"); p(d,x,y+1,"9eaf83") end
  end
  for _,v in ipairs({{16,28},{32,34},{47,25}}) do oval(d,v[1],v[2],3,2,"a75f6f"); p(d,v[1]-1,v[2]-1,"df9d9a") end
 elseif name=="jade_plant" then
  stem(a,32,95,31,67,4); stem(a,31,82,19,71,2); stem(a,31,77,43,65,2)
  for _,v in ipairs({{16,70},{23,65},{29,61},{37,61},{44,64},{22,77},{39,76},{31,72}}) do oval(b,v[1],v[2],6,4,ink); oval(c,v[1],v[2]-1,5,3,"578b65"); line(d,v[1]-3,v[2]-2,v[1]+1,v[2]-3,"a4c27d") end
 else
  local lily=name=="desert_lily"; local marigold=name=="desert_marigold"
  local stems=lily and {{31,45},{40,56},{24,61}} or (marigold and {{20,67},{32,61},{44,70},{37,77}} or {{16,72},{25,67},{35,63},{46,71},{40,82},{22,84}})
  for _,v in ipairs(stems) do
   line(a,32,95,v[1],v[2]+wob,ink,3); line(c,32,94,v[1],v[2]+wob,green)
   leaf(c,v[1],v[2]+14,v[1]-9,v[2]+8,3,green); leaf(c,v[1],v[2]+19,v[1]+9,v[2]+11,3,light)
   if lily then bloom(d,v[1],v[2]+wob,"f0e5cf",frame); line(d,v[1],v[2]-2+wob,v[1],v[2]+2+wob,"d8b867")
   else bloom(d,v[1],v[2]+wob,marigold and "d9aa43" or "d3bc55",frame) end
  end
  if not lily and not marigold then for k=0,13 do local x=15+(k*11)%35; local y=78+(k*7)%16; oval(b,x,y,4,3,dark); oval(c,x-1,y-1,3,2,"7b9d78"); p(d,x-2,y-2,"b4c3a0") end end
 end
 -- Root clumps visually tie each plant to the existing forest ground style.
 line(a,27,95,37,95,ink); for x=27,37,3 do p(d,x,94,light) end
end)
dofile(root .. "/tools/export_planet_expansion_aseprite.lua")
print("PLANET_EXPANSION_DESIGN native_documents=6 desert_species=15 tool_tiers_added=3 terrain_ores=7")
