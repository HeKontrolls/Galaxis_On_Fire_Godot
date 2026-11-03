local root=assert(app.params.root)
app.fs.makeAllDirectories(root.."/assets/sprites/source/weapons")
local function rgba(h) return app.pixelColor.rgba(tonumber(h:sub(1,2),16),tonumber(h:sub(3,4),16),tonumber(h:sub(5,6),16),255) end
local function author(name,w,h,count,paint,tags)
 local s=Sprite(w,h,ColorMode.RGB);s.layers[1].name="Wood, steel and shaft silhouettes";s:newLayer().name="Material facets and leather fittings";s:newLayer().name="Strings, binding and edge light"
 for f=1,count do
  if f>1 then s:newEmptyFrame() end
  for l=1,3 do
   local im=Image(w,h,ColorMode.RGB)
   local function p(x,y,c) x=math.floor(x+.5);y=math.floor(y+.5);if x>=0 and x<w and y>=0 and y<h then im:drawPixel(x,y,rgba(c)) end end
   local function box(x,y,ww,hh,c) for yy=y,y+hh-1 do for xx=x,x+ww-1 do p(xx,yy,c) end end end
   local function line(x,y,xx,yy,c) local steps=math.max(math.abs(xx-x),math.abs(yy-y));for i=0,steps do local t=steps==0 and 0 or i/steps;p(x+(xx-x)*t,y+(yy-y)*t,c) end end
   paint(f,l,p,box,line)
   if f==1 and l==1 then s.layers[1]:cel(1).image=im else s:newCel(s.layers[l],f,im,Point(0,0)) end
  end
  s.frames[f].duration=.12
 end
 for _,tag in ipairs(tags) do s:newTag(tag[2],tag[3]).name=tag[1] end
 s:saveAs(root.."/assets/sprites/source/weapons/"..name..".aseprite");s:close()
end
local bow_names={"wood_bow","copper_bow","iron_bow","iron_crossbow"}
local metals={{"654b36","b38851","edd29b"},{"704535","c17d4b","f1bd7c"},{"3c505b","8faeb7","dce7db"},{"37464e","879da4","d6dcd2"}}
local function bows(f,l,p,box,line)
 local kind=math.floor((f-1)/3)+1;local phase=(f-1)%3;local col=metals[kind]
 if kind<4 then
  local nodes={{10,2},{14,5},{17,10},{19,16},{19,24},{17,30},{14,35},{10,38}}
  if l==1 then
   for i=1,#nodes-1 do local a,b=nodes[i],nodes[i+1];for dx=-1,1 do line(a[1]+dx,a[2],b[1]+dx,b[2],col[1]) end end
   box(17,16,4,9,"584336")
  elseif l==2 then
   for i=1,#nodes-1 do local a,b=nodes[i],nodes[i+1];line(a[1],a[2],b[1],b[2],col[2]) end
   line(10,3,13,6,col[3]);line(14,7,16,12,col[3]);line(17,27,15,32,col[3]);line(13,35,10,37,col[3])
   box(18,16,3,9,"8d5f43");for y=17,23,2 do line(18,y,20,y+1,"c19768") end
   if kind==2 then box(15,8,3,3,"94603c");box(15,29,3,3,"94603c");p(16,8,"f3ce86");p(16,31,"f3ce86") end
   if kind==3 then box(18,12,3,3,"617f8d");box(18,26,3,3,"617f8d");p(19,12,"c1d6d5");p(19,28,"c1d6d5") end
  else
   local pulled=10-phase*4
   line(10,3,pulled,20,"b0a483");line(pulled,20,10,37,"d3c8a5")
   p(10,3,col[3]);p(10,37,col[3]);box(18,15,3,1,col[3]);box(18,24,3,1,col[3])
  end
 else
  if l==1 then
   box(6,18,24,6,"514238");box(6,20,8,10,"514238");box(16,22,5,7,"514238")
   for i=0,14 do local y=4+i;local x=22+math.floor(math.sin(i/14*math.pi/2)*5);box(x,y,3,2,col[1]);box(x,38-y,3,2,col[1]) end
  elseif l==2 then
   box(8,19,18,3,"ae8253");line(8,20,13,27,"c7a06e");box(17,23,3,4,"845b3d");box(13,18,12,1,"e1b57b")
   for i=0,14 do local y=4+i;local x=22+math.floor(math.sin(i/14*math.pi/2)*5);p(x+1,y,col[2]);p(x+1,38-y,col[2]);if i%4==0 then p(x,y,col[3]);p(x,38-y,col[3]) end end
   box(21,16,7,3,col[2]);box(21,22,7,3,col[2]);box(24,18,4,4,"495e69");line(23,19,29,19,"c6d6d2")
  else
   local latch=phase==0 and 11 or (phase==1 and 26 or 18)
   line(23,4,latch,20,"d2c7a4");line(latch,20,23,34,"aa9b7e")
   box(15,21,2,3,"dbc17f");p(27,17,"e8dabe");p(27,24,"e8dabe");p(10,24,"76553b")
   box(27,14,2,2,"d4ba75");box(27,25,2,2,"d4ba75")
  end
 end
end
local tags={};for i,n in ipairs(bow_names) do table.insert(tags,{n,(i-1)*3+1,i*3}) end
for i,n in ipairs(bow_names) do for j,pose in ipairs(i==4 and {"loaded","fired","reloading"} or {"idle","half_draw","full_draw"}) do table.insert(tags,{n.."_"..pose,(i-1)*3+j,(i-1)*3+j}) end end
author("bows",32,40,12,bows,tags)
local arrow_names={"stone_arrow","copper_arrow","iron_arrow","crystal_arrow"}
local tips={{"4d5b62","92a6a7","d7dfd2"},{"794c39","c5864c","f5cb89"},{"445768","98b8c5","e0ede8"},{"3b777e","65c9c9","c4fff1"}}
author("arrows",32,12,4,function(f,l,p,box,line)
 local col=tips[f]
 if l==1 then line(2,6,27,6,"6d573c");for x=25,31 do local span=math.floor((31-x)*.7);box(x,6-span,1,span*2+1,col[1]) end
 elseif l==2 then line(3,5,26,5,"d5b97f");for x=26,30 do local span=math.floor((31-x)*.6);box(x,6-span,1,span*2+1,col[2]) end;line(26,4,30,6,col[3]);line(3,3,8,6,"b1b59d");line(3,9,8,6,"798c7b");line(1,5,5,6,"e2d7b7")
 else p(28,5,col[3]);p(7,5,"f5e3b7");p(7,7,"856a48");if f==4 then p(26,7,"a1edee");p(29,6,"edfffb") end end
end,{{arrow_names[1],1,1},{arrow_names[2],2,2},{arrow_names[3],3,3},{arrow_names[4],4,4}})
author("arrow_icons",32,32,4,function(f,l,p,box,line)
 local col=tips[f]
 for i=0,2 do local sx=5+i*6;local sy=29-i*2;local tx=sx+11;local ty=sy-21
  if l==1 then line(sx,sy,tx,ty,"6d563e");line(sx+1,sy,tx+1,ty,col[1]);for y=ty-5,ty+1 do local width=math.floor((y-ty+5)*.65);box(tx-width,y,width*2+1,1,col[1]) end
  elseif l==2 then line(sx+1,sy-1,tx+1,ty,"c5ab78");for y=ty-4,ty do local width=math.floor((y-ty+4)*.5);box(tx-width,y,width*2+1,1,col[2]) end;line(tx,ty-4,tx-1,ty,col[3]);line(sx,sy-5,sx-2,sy-2,"d8d8b7");line(sx+3,sy-4,sx+2,sy-7,"92aa99")
  else p(tx,ty-3,col[3]);p(sx+1,sy-4,"f4deab");line(sx-1,sy-2,sx+2,sy-3,"a58b5e") end
 end
end,{{arrow_names[1],1,1},{arrow_names[2],2,2},{arrow_names[3],3,3},{arrow_names[4],4,4}})
dofile(root.."/tools/export_weapons_aseprite.lua")
print("WEAPONS_AUTHORED native sources=3 frames=20 layers=3")
