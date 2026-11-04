local root=assert(app.params.root)
app.fs.makeAllDirectories(root.."/assets/sprites/source/magic");app.fs.makeAllDirectories(root.."/assets/sprites/magic")
local names={"ember_wand","frost_wand","storm_staff","crystal_staff","mending_tome","ward_book","greater_ward_book","lumen_tome","mana_tonic","ember_bolt","frost_bolt","crystal_bolt","lightning","ward_aura","mend_aura","lumen_orb","burn_status","frost_status"}
local function rgba(h)return app.pixelColor.rgba(tonumber(h:sub(1,2),16),tonumber(h:sub(3,4),16),tonumber(h:sub(5,6),16),255)end
for index,name in ipairs(names)do
 local w,h,count=24,40,3
 if index==9 then w,h=16,24 elseif index>=10 and index<=12 then w,h,count=24,16,4 elseif index==13 then w,h,count=32,8,4 elseif index==14 or index==15 then w,h,count=64,64,4 elseif index==16 then w,h,count=32,32,4 elseif index>=17 then w,h,count=12,12,4 end
 local s=Sprite(w,h,ColorMode.RGB);s.layers[1].name="Silhouette and binding";s:newLayer().name="Facets, pages and material detail";s:newLayer().name="Runes, highlights and animated spell core"
 for frame=1,count do
  if frame>1 then s:newEmptyFrame()end
  local pulse=frame==2 or frame==3
  for layer=1,3 do
   local im=Image(w,h,ColorMode.RGB)
   local function p(x,y,c)x=math.floor(x+.5);y=math.floor(y+.5);if x>=0 and x<w and y>=0 and y<h then im:drawPixel(x,y,rgba(c))end end
   local function box(x,y,ww,hh,c)for yy=y,y+hh-1 do for xx=x,x+ww-1 do p(xx,yy,c)end end end
   local function line(x,y,xx,yy,c)local n=math.max(math.abs(xx-x),math.abs(yy-y));for i=0,n do local t=n==0 and 0 or i/n;p(x+(xx-x)*t,y+(yy-y)*t,c)end end
   local cols={{"934f51","e58e61","ffe1a0"},{"477b9d","87c9d6","e7f8df"},{"655c9b","b0a1e0","f2e8b5"},{"536e98","91bcd2","e2f2ed"},{"476f62","93c69c","e7e6b1"},{"486385","89b9ce","d9e8e1"},{"73538b","ba9adb","f1dfb3"},{"9a794d","e5c784","fff2c1"}}
   local col=cols[math.min(index,8)]
   if index<=4 then
    local staff=index>=3;local tip=staff and 3 or 11
    if layer==1 then box(10,tip+7,4,29-tip,"4d424c");box(9,tip+8,6,3,"655751");box(9,tip+16,6,6,"4b4d5c");box(7,tip+1,10,8,col[1]);box(9,tip-1,6,12,col[1])
     if staff then line(8,8,5,3,"566071");line(15,8,19,3,"566071");box(9,35,6,3,"485867")end
    elseif layer==2 then box(11,tip+10,2,27-tip,"b8915f");line(11,tip+12,11,33,"dec18d");for y=tip+17,tip+21,2 do line(10,y,13,y+1,"c5a885")end
     box(9,tip+2,6,6,col[2]);line(9,tip+3,11,tip,col[3]);line(11,tip,14,tip+3,col[2]);p(13,tip+6,col[1]);box(10,34,4,1,"d0b07a")
    else box(10,tip+1,2,4,col[3]);p(13,tip+2,"f8efcc");line(9,tip+10,14,tip+10,"d1c3a1")
     if frame>1 then p(4,tip+frame,col[2]);p(18,tip+8-frame,col[3]);p(11,tip-2,col[3])end
     if index==3 then line(8,4,10,6,col[3]);line(15,5,18,2,col[3])elseif index==4 then line(12,2,14,5,col[3]);line(13,5,11,8,col[2])end
    end
   elseif index<=8 then
    if layer==1 then box(3,10,18,25,"3e475c");box(1,12,3,21,col[1]);box(5,8,14,2,col[1]);box(5,35,14,2,"4b414e")
    elseif layer==2 then box(4,11,15,22,col[1]);box(6,12,13,20,col[2]);box(7,14,10,17,col[1]);line(5,11,18,11,"d4c5a0");line(5,33,18,33,"cfbd97");line(4,13,4,31,"b89970");box(2,16,3,2,"c5ad7e");box(2,28,3,2,"c5ad7e");box(19,20,3,5,"d1b875")
     if index==7 then line(7,14,16,14,"d3b77a");line(7,30,16,30,"d3b77a");p(7,22,"ebca9d");p(16,22,"ebca9d")end
    else
     local ink=pulse and col[3] or col[2]
     if index==5 then box(11,18,2,10,ink);box(8,22,8,2,ink)
     elseif index==6 or index==7 then line(9,18,15,18,ink);line(9,18,8,24,ink);line(15,18,16,24,ink);line(8,24,12,28,ink);line(16,24,12,28,ink);p(12,21,col[3])
     else line(12,17,16,23,ink);line(16,23,12,29,ink);line(12,29,8,23,ink);line(8,23,12,17,ink);box(11,21,3,4,col[3])end
     p(6,13,col[3]);p(17,31,col[3]);if frame>1 then p(0,8+frame,col[2]);p(22,11-frame,col[3])end
    end
   elseif index==9 then
    if layer==1 then box(4,1,8,4,"534956");box(5,5,6,3,"70829a");box(2,9,12,12,"4b5975");box(4,21,8,2,"4b5975")
    elseif layer==2 then box(3,10,10,10,"797dc0");box(4,11,8,8,"a69be2");box(4,2,8,1,"bb9467");box(6,6,4,2,"c5d3d1");line(4,12,4,17,"d7e5e4")
    else box(6,13,5,5,pulse and "e4d4f1" or "c7b5e7");p(10,10,"f6e4b3");p(6,20,"bac5db")end
   elseif index<=12 then
    local pal=cols[index==10 and 1 or (index==11 and 2 or 4)]
    if layer==1 then line(3,8,20,8,pal[1]);line(7,6,17,4,pal[1]);line(7,10,17,12,pal[1])
    elseif layer==2 then
     if index==10 then for x=2,18 do local yy=7+((x+frame)%3)-1;box(x,yy,3,2,pal[2])end;box(15,5,5,6,pal[2])
     elseif index==11 then line(3,8,19,8,pal[2]);line(11,5,21,8,pal[2]);line(21,8,11,11,pal[2]);line(12,4,16,8,pal[2]);line(16,8,12,12,pal[2])
     else line(5,8,17,4,pal[2]);line(17,4,22,8,pal[2]);line(22,8,17,12,pal[2]);line(17,12,5,8,pal[2]);line(9,8,19,8,pal[3])end
    else box(16,7,5,2,pal[3]);p(21,8,"fff6d9");p(2+frame,5,pal[2]);p(5+frame,11,pal[2])end
   elseif index==13 then
    local pts={{0,4},{6,2},{10,6},{16,1},{21,5},{26,3},{31,4}}
    for i=1,#pts-1 do local a,b=pts[i],pts[i+1];local shift=(frame%2)*1
     if layer==1 then line(a[1],a[2]+1,b[1],b[2]+1,"666ca2")elseif layer==2 then line(a[1],a[2],b[1],b[2],"b5b9ed")else line(a[1],a[2]-shift,b[1],b[2]-shift,"f4eccf")end
    end
   elseif index==14 or index==15 then
    local base=index==14 and "658cad" or "6b9b7b";local bright=index==14 and "a9dce2" or "c7e8ae"
    if layer==1 then
     for y=4,59 do for x=8,55 do local d=((x-31.5)/23)^2+((y-31.5)/28)^2;if d>.91 and d<1.04 and (x+y+frame)%4~=0 then p(x,y,base)end end end
    elseif layer==2 then
     for i=0,7 do local a=i*math.pi/4;local x=32+math.cos(a)*21;local y=32+math.sin(a)*26;line(x-2,y,x+2,y,bright);line(x,y-2,x,y+2,bright)end
    else
     for i=0,6 do local x=12+(i*7+frame*3)%40;local y=8+(i*11+frame*5)%48
      if index==15 then line(x-1,y,x+1,y,"d7eabd");line(x,y-1,x,y+1,"d7eabd")else p(x,y,"bbd8e4")end
     end
    end
   elseif index==16 then
    if layer==1 then line(16,3,28,16,"9d8d71");line(28,16,16,28,"9d8d71");line(16,28,3,16,"9d8d71");line(3,16,16,3,"9d8d71")
    elseif layer==2 then box(12,9,8,14,"dec994");box(9,12,14,8,"dec994");box(12,12,8,8,"f5e5b8")
    else box(14,13,4,6,"fff8dc");p(5+frame,6,"f7d69b");p(25-frame,25,"f7d69b");line(15,0,15,4,"daca9b")end
   else
    local ice=index==18;local dark=ice and "4a7a9b" or "984f4c";local light=ice and "c6e5e3" or "f4ca88"
    if layer==1 then box(3,3,6,7,dark)elseif layer==2 then
     if ice then line(2,6,10,6,"8fc9df");line(6,2,6,10,"8fc9df");line(3,3,9,9,"8fc9df");line(3,9,9,3,"8fc9df")else line(4,9,3,5,"df8460");line(3,5,6,1+frame%2,"df8460");line(6,2,9,8,"df8460");box(4,5,4,4,"df8460")end
    else box(5,5,2,4,light);p(6,3,light)end
   end
   if frame==1 and layer==1 then s.layers[1]:cel(1).image=im else s:newCel(s.layers[layer],frame,im,Point(0,0))end
  end
  s.frames[frame].duration=.12
 end
 s:newTag(1,1).name="idle";s:newTag(2,count).name=index<=9 and "cast" or "loop"
 s:saveAs(root.."/assets/sprites/source/magic/"..name..".aseprite");s:close()
end
dofile(root.."/tools/export_magic_aseprite.lua")
print("MAGIC_AUTHORED sources=18 frames=63 layers=3")
