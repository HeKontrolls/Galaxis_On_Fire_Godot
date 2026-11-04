local root=assert(app.params.root)
app.fs.makeAllDirectories(root.."/assets/sprites/source/alchemy");app.fs.makeAllDirectories(root.."/assets/sprites/alchemy")
local names={"alchemy_desk","cauldron","blank_wand","blank_staff","blank_tome","fire_essence","frost_essence","storm_essence","life_essence","spirit_essence","arcane_ink","bone_fragment","soul_wand","grave_tome","crafted_wand","crafted_staff","crafted_tome","soul_bolt","blight_bolt","blight_status","bone_servitor","grave_wraith","bone_hound"}
local function rgba(h)return app.pixelColor.rgba(tonumber(h:sub(1,2),16),tonumber(h:sub(3,4),16),tonumber(h:sub(5,6),16),255)end
for index,name in ipairs(names)do
 local w,h,count=24,40,3
 if index<=2 then w,h=48,32 elseif index>=6 and index<=12 then w,h,count=16,16,1 elseif index==18 or index==19 then w,h,count=24,16,4 elseif index==20 then w,h,count=12,12,4 elseif index>=21 then w,h,count=32,32,4 end
 local s=Sprite(w,h,ColorMode.RGB);s.layers[1].name="Furniture, silhouette and bindings";s:newLayer().name="Materials, pages, bone and glass";s:newLayer().name="Runes, facets and animated highlights"
 for frame=1,count do
  if frame>1 then s:newEmptyFrame()end
  local active=frame>1
  for layer=1,3 do
   local im=Image(w,h,ColorMode.RGB)
   local function p(x,y,c)x=math.floor(x+.5);y=math.floor(y+.5);if x>=0 and x<w and y>=0 and y<h then im:drawPixel(x,y,rgba(c))end end
   local function box(x,y,ww,hh,c)for yy=y,y+hh-1 do for xx=x,x+ww-1 do p(xx,yy,c)end end end
   local function line(x,y,xx,yy,c)local n=math.max(math.abs(xx-x),math.abs(yy-y));for i=0,n do local t=n==0 and 0 or i/n;p(x+(xx-x)*t,y+(yy-y)*t,c)end end
   local wood="826044";local gold="c9aa72";local rim="b7c9bc";local violet=active and "d4b9ee" or "9b89bd"
   if index==1 then
    if layer==1 then box(1,15,46,5,"493f39");box(4,20,5,12,"493f39");box(39,20,5,12,"493f39");box(5,26,37,3,"493f39");box(2,11,17,4,"3c4050");box(24,7,5,8,"3d515c");box(34,3,6,12,"3d515c")
    elseif layer==2 then box(2,15,44,2,"b48c57");box(4,18,40,2,wood);line(6,20,6,30,"b18b5c");line(41,20,41,30,"b18b5c");line(8,27,39,27,wood);box(4,11,13,4,"dfd0a2");line(10,11,10,15,"8f826a");box(25,9,3,5,"8bb9b9");box(35,6,4,8,"718e8f");box(36,3,2,2,gold);box(34,11,6,4,"87b3a0");box(18,13,5,2,"527c79")
    else line(4,16,44,16,"e0c38d");for x=5,15,3 do p(x,12,"9b8a76")end;box(25,11,3,2,active and "bce0bd" or "8fb6af");box(36,9,2,3,"c5e5ca");line(19,12,22,5,"d5d9bf");p(22,5,"eff0d3");p(20,29,gold);p(25,29,gold);if active then p(31,5+frame,"aebddc")end end
   elseif index==2 then
    if layer==1 then box(6,8,36,17,"364752");box(10,25,28,4,"364752");box(11,27,4,5,"4b443d");box(33,27,4,5,"4b443d");box(2,11,5,7,"364752");box(41,11,5,7,"364752");box(10,4,28,4,"364752")
    elseif layer==2 then box(7,9,34,14,"5e7072");box(11,6,26,5,"789698");box(13,7,22,3,active and "91b27c" or "688379");box(11,13,3,9,"9baca0");box(15,24,18,2,"7d8c7f");line(3,12,3,16,"93a39d");line(44,12,44,16,"93a39d");box(19,28,11,3,"a36c4b");box(21,29,7,3,active and "efb56c" or "b98259")
    else for x=14,34,5 do p(x,6,gold)end;box(20,15,8,8,"475e61");line(21,16,27,22,gold);line(27,16,21,22,gold);p(24,17,"c7e0bb");if active then for i=1,3 do local x=14+i*6;local y=4-((i+frame)%3);p(x,y,"b7cfad");p(x+1,y,"b7cfad")end end end
   elseif index>=6 and index<=12 then
    local cols={{"a85b4f","eaa177"},{"548a9c","bce2d9"},{"77729e","d0c6ef"},{"558779","acd4a1"},{"637a91","b2d4bd"},{"705477","ba91cc"}}
    local c=cols[index-5] or {"8a806c","e1d7b9"}
    if index==12 then
     if layer==1 then line(3,12,11,4,"776b62");box(2,11,3,3,"776b62");box(10,2,3,3,"776b62")elseif layer==2 then line(4,11,11,4,"c9c3aa");line(5,12,12,5,"b4b69e");box(2,10,3,3,"d8d5bb");box(10,2,3,3,"d8d5bb")else p(3,10,"f1e4c4");p(11,2,"f1e4c4");p(8,8,"f1e4c4")end
    elseif layer==1 then box(5,1,6,3,"695346");box(6,4,4,3,"607582");box(3,7,10,7,"435968");box(5,14,6,2,"435968")
    elseif layer==2 then box(4,8,8,5,c[1]);box(5,6,6,2,"93b5b4");box(6,2,4,1,gold);box(6,10,4,3,c[2]);line(4,8,4,12,"c0d8c5")
    else p(6,5,"e5e6c9");p(10,8,c[2]);p(8,10,"f0e6c4");p(6,14,"a9c5b7")end
   elseif index<=17 then
    local book=index==5 or index==14 or index==17
    if book then
     if layer==1 then box(3,9,18,27,"46525e");box(1,12,3,21,"3c4755");box(5,7,14,2,"616073")
     elseif layer==2 then box(4,10,15,23,index==5 and "816956" or (index==14 and "65577d" or "5b6d87"));box(6,12,11,19,index==5 and "b5a281" or "9aa6bd");box(7,13,9,17,"4e586d");line(5,33,18,33,"d1c19d");box(19,20,3,5,gold);p(2,14,gold);p(2,29,gold)
     else if index==14 then box(9,17,6,6,"b4c6b4");box(10,23,4,3,"b4c6b4");p(10,19,"4e6a71");p(13,19,"4e6a71");line(9,28,15,28,gold)elseif index==17 then line(11,16,15,22,violet);line(15,22,11,28,violet);line(11,28,8,22,violet);line(8,22,11,16,violet);p(11,21,"e7dcc4")else line(9,18,14,18,"a89c83");line(9,22,14,22,"a89c83");line(9,26,12,26,"a89c83")end;p(6,11,gold);p(17,31,gold)end
    else
     local staff=index==4 or index==16;local top=staff and 3 or 10
     if layer==1 then box(10,top+5,4,32-top,"57463f");box(9,top+13,6,7,"4e4a55");box(8,top,8,8,index<=4 and "75695e" or "5d677e")
     elseif layer==2 then line(11,top+7,11,35,"c1a372");for y=top+14,top+19,2 do line(10,y,13,y+1,"d3b789")end;box(9,top+1,6,5,index==13 and "a5c9b3" or (index<=4 and "b7ab8c" or violet));line(10,35,13,35,gold)
     else if index==13 then p(10,top+2,"527471");p(13,top+2,"527471");box(11,top+5,2,2,"cad3b9")elseif index>4 then p(10,top+1,"efe4c1");box(11,top+2,2,3,"c1d9e5")end
      if staff then line(8,top+5,5,top,"b4af9a");line(15,top+5,18,top,"b4af9a")end
      if active and index>4 then p(5,top+frame,"bfd3bd");p(18,top+7-frame,violet)end
     end
    end
   elseif index==18 or index==19 then
    local shade=index==18 and "487b79" or "69557d";local bright=index==18 and "c1e4bf" or "c5a3d9"
    if layer==1 then line(2,8,19,8,shade);box(14,5,6,7,shade)elseif layer==2 then for i=1,6 do box(3+i*3,5+(i+frame)%6,3,2,index==18 and "83b9a2" or "a388b9")end else box(16,6,4,4,bright);p(20,8,"e5e7c6");p(4+frame,3,bright);p(8,12-frame%2,bright)end
   elseif index==20 then
    if layer==1 then box(3,2,6,8,"5b4c6e")elseif layer==2 then box(4,3,5,5,"a38ab8");box(3,8,2,2,"a38ab8");box(8,8,2,2,"a38ab8")else p(5,4,"dfc2de");p(8,5,"dfc2de");p(6,8,"dfc2de")end
   else
    local drift=frame%2;local bone="c2c6ad";local shine="e4dbbc";local shadow="667e7e";local spirit="8cc5b3"
    if index==21 then
     if layer==1 then box(11,3+drift,11,9,"4b6770");box(13,12,6,12,"4b6770");line(11,16,7,22,"4b6770");line(21,16,25,21,"4b6770");line(14,23,11,29,"4b6770");line(18,23,21,29,"4b6770")
     elseif layer==2 then box(12,4+drift,9,7,bone);box(14,11,5,2,bone);box(15,14,2,11,bone);for y=15,21,3 do line(12,y,20,y,shadow)end;line(11,16,8,22,bone);line(21,16,24,21,bone);line(15,23,12,29,bone);line(18,23,20,29,bone)
     else p(14,7+drift,"538c86");p(18,7+drift,"538c86");line(13,4+drift,19,4+drift,shine);p(16,16,spirit);p(9,27,spirit);p(23,27-frame%2,spirit)end
    elseif index==22 then
     if layer==1 then box(9,5+drift,15,12,"496772");box(11,17,11,8,"496772");line(12,24,7,29,"496772");line(21,24,26,28,"496772")
     elseif layer==2 then box(11,6+drift,11,9,"9bb7b0");box(12,16,9,8,"779e9e");line(9,15,5,21,"779e9e");line(24,15,28,20,"779e9e");for y=19,26,3 do line(12,y,22,y,"8cafaa")end
     else line(12,7+drift,19,7+drift,shine);box(12,10+drift,3,2,"d0e4bf");box(18,10+drift,3,2,"d0e4bf");p(15,15,"476c77");p(9,28-frame%3,spirit);p(23,28-frame%2,spirit);p(15,29,spirit)end
    else
     if layer==1 then box(8,12,17,10,"4c6970");box(22,7+drift,8,10,"4c6970");line(9,13,3,6,"4c6970");line(10,21,7+drift,29,"4c6970");line(22,21,25-drift,29,"4c6970")
     elseif layer==2 then line(8,15,24,15,bone);for x=10,22,4 do line(x,15,x,21,bone)end;box(23,8+drift,6,7,bone);box(27,13+drift,4,3,bone);line(10,21,8+drift,28,bone);line(22,21,24-drift,28,bone);line(9,13,4,7,bone)
     else p(26,10+drift,"9ed8ba");line(23,8+drift,27,8+drift,shine);p(11,13,shine);p(16,20,shine);p(6,29,spirit);p(26,29,spirit)end
    end
   end
   if frame==1 and layer==1 then s.layers[1]:cel(1).image=im else s:newCel(s.layers[layer],frame,im,Point(0,0))end
  end
  s.frames[frame].duration=.15
 end
 s:newTag(1,1).name="idle"
 if count>1 then s:newTag(2,count).name=index<=2 and "working" or (count==3 and "cast" or "loop")end
 s:saveAs(root.."/assets/sprites/source/alchemy/"..name..".aseprite");s:close()
end
dofile(root.."/tools/export_alchemy_aseprite.lua")
print("ALCHEMY_AUTHORED sources=23 frames=61 layers=3")
