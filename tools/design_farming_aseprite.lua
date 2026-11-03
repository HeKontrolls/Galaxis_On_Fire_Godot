local root=assert(app.params.root)
app.fs.makeAllDirectories(root.."/assets/sprites/source/farming")
local function color(h) return app.pixelColor.rgba(tonumber(h:sub(1,2),16),tonumber(h:sub(3,4),16),tonumber(h:sub(5,6),16),255) end
local p,box,line,ell,leaf
local function canvas(w,h)
 local im=Image(w,h,ColorMode.RGB)
 p=function(x,y,c) x=math.floor(x);y=math.floor(y);if x>=0 and x<w and y>=0 and y<h then im:drawPixel(x,y,color(c)) end end
 box=function(x,y,ww,hh,c) for yy=y,y+hh-1 do for xx=x,x+ww-1 do p(xx,yy,c) end end end
 line=function(x,y,xx,yy,c) local n=math.max(math.abs(xx-x),math.abs(yy-y));for i=0,n do local t=n==0 and 0 or i/n;p(x+(xx-x)*t,y+(yy-y)*t,c) end end
 ell=function(x,y,ww,hh,c) for yy=y,y+hh-1 do for xx=x,x+ww-1 do if ((xx-x+.5)/ww*2-1)^2+((yy-y+.5)/hh*2-1)^2<=1 then p(xx,yy,c) end end end end
 leaf=function(x,y,dx,dy,tone)
  line(x,y,x+dx,y+dy,"315936")
  for i=1,math.max(math.abs(dx),math.abs(dy)) do
   local t=i/math.max(math.abs(dx),math.abs(dy));local xx=x+dx*t;local yy=y+dy*t
   local r=math.max(0,math.floor(math.sin(t*math.pi)*2.1));box(math.floor(xx)-r,math.floor(yy),r*2+1,2,tone or "4b8c43")
  end
  line(x,y,x+dx,y+dy,"7fba55")
 end
 return im
end
local names={"Corn","Carrot","Potato","Tomato","Wheat"}
local function save_sprite(name,w,h,count,draw,tags)
 local s=Sprite(w,h,ColorMode.RGB);s.layers[1].name="Silhouette";s:newLayer().name="Form and material";s:newLayer().name="Highlights and small details"
 for f=1,count do
  if f>1 then s:newEmptyFrame() end
  for l=1,3 do
   local im=canvas(w,h);draw(f,l)
   if f==1 and l==1 then s.layers[1]:cel(1).image=im else s:newCel(s.layers[l],f,im,Point(0,0)) end
  end
  s.frames[f].duration=.25
 end
 for _,tag in ipairs(tags) do s:newTag(tag[2],tag[3]).name=tag[1] end
 s:saveAs(root.."/assets/sprites/source/farming/"..name..".aseprite");s:close()
end
local function crop(f,l)
 local kind=math.floor((f-1)/3)+1;local stage=(f-1)%3+1
 if stage==1 then
  if l==1 then box(15,40,2,8,"315936") end
  if l==2 then leaf(16,44,-5,-5,kind==5 and "82a153" or "4b914b");leaf(16,44,5,-7) end
  if l==3 then p(16,41,"a3c766");p(15,46,"6a9c41") end
  return
 end
 if kind==1 then
  local top=stage==2 and 22 or 5
  if l==1 then box(15,top+4,3,43-top,"355b32");box(18,21,4,13,"46622e") end
  if l==2 then
   box(16,top+3,1,44-top,"8aa84c")
   for i=0,3 do local y=44-i*7;leaf(16,y,(i%2==0 and -1 or 1)*(9+i%2*2),-6-i%2,"508f42") end
   if stage==3 then ell(18,20,5,12,"ce9a32");ell(18,20,4,10,"e8bc49");leaf(18,33,7,-10,"5e9841");leaf(19,33,-3,-7) end
  end
  if l==3 and stage==3 then
   for i=0,4 do p(19,21+i*2,"ffe18a");p(21,22+i*2,"a97831") end
   line(16,6,16,13,"d6b874");line(16,9,12,6,"c4a05a");line(16,9,20,4,"e3cb88");p(13,4,"e3cb88")
  end
 elseif kind==2 then
  if l==1 then ell(12,42,8,6,"974d2e");box(15,33,2,11,"355e37") end
  if l==2 then
   if stage==3 then ell(13,42,6,5,"e78a35");line(15,44,19,44,"f6b459");p(13,45,"b3612b") end
   for i=0,4 do local dx=(i-2)*3;local y=stage==2 and 36 or 29;line(16,43,16+dx,y+math.abs(i-2),"4a8642");for j=0,3 do local xx=16+dx*j/4;local yy=42-(42-y)*j/4;line(xx-2,yy,xx+1,yy-3,"79af51");p(xx+2,yy-2,"4c914c") end end
  end
  if l==3 then p(16,39,"a4bf61");p(13,35,"a4bf61");p(19,34,"a4bf61") end
 elseif kind==3 then
  if l==1 then box(15,32,2,16,"3a5535");ell(7,33,18,12,"284b3c") end
  if l==2 then
   for i=0,4 do local x=9+i*3;ell(x,35-(i%2)*5,7,7,"467f4e");ell(x+1,35-(i%2)*5,4,4,"6b9e54");line(x+3,38-(i%2)*5,16,45,"718c42") end
   if stage==3 then ell(8,44,7,4,"aa8255");p(10,44,"d4ac76");p(13,46,"70553c") end
  end
  if l==3 and stage==3 then
   for _,v in ipairs({{11,31},{19,30},{22,37}}) do ell(v[1],v[2],4,4,"b3a8c4");p(v[1]+1,v[2]+1,"eed98b");p(v[1]+2,v[2]+3,"9b82a2") end
  end
 elseif kind==4 then
  if l==1 then box(19,20,2,28,"79573c");box(15,27,2,21,"315738");line(7,42,24,32,"315738") end
  if l==2 then
   box(19,21,1,26,"b18b58")
   for i=0,5 do local x=6+(i*7)%18;local y=28+(i*5)%16;ell(x,y,7,5,"397146");line(x+1,y+2,x+5,y+1,"7f9f50");line(16,44,x+3,y+2,"538047") end
   if stage==3 then for _,v in ipairs({{9,38},{21,34},{14,29},{18,42}}) do ell(v[1],v[2],5,5,"a34538");ell(v[1],v[2],4,3,"e46f42");p(v[1]+1,v[2],"f4ac65");p(v[1]+2,v[2]-1,"80a24e") end end
  end
  if l==3 then box(16,34,5,1,"aa9865");if stage==2 then p(11,32,"ecd777");p(22,37,"ecd777") end end
 else
  local top=stage==2 and 23 or 13
  if l==1 then for i=0,3 do line(13+i,47,9+i*4,top+i%2*4,"667344") end end
  if l==2 then for i=0,3 do
   local x=9+i*4;local yy=top+i%2*4;line(13+i,47,x,yy,"c3ac5c")
   if stage==3 then for n=0,4 do box(x-2,yy+n*2,2,2,"b48943");box(x,yy+1+n*2,2,2,"e2c577");p(x-2,yy+n*2,"f0d995") end;line(x,yy-3,x,yy+8,"e5c878") end
   leaf(14+i,43,x<16 and -5 or 6,-8,stage==3 and "99a450" or "69944a")
  end end
  if l==3 and stage==3 then for i=0,3 do p(9+i*4,top+i%2*4,"fff0b0") end end
 end
end
local crop_tags={};for i,n in ipairs(names) do table.insert(crop_tags,{n,(i-1)*3+1,i*3}) end
save_sprite("crops",32,48,15,crop,crop_tags)
local item_names={"Corn","Carrot","Potato","Tomato","Wheat","Crop Seeds","Carrot Seeds","Seed Potato","Tomato Seeds","Wheat Seeds","Roasted Corn","Baked Potato","Tomato Soup","Bread","Vegetable Stew"}
local function item(f,l)
 if f>=6 and f<=10 and f~=8 then
  local accent=({[6]="e6bb51",[7]="e88f43",[9]="e36e52",[10]="cfbc77"})[f]
  if l==1 then box(7,7,18,22,"6f654c");box(8,5,16,25,"b5a27c") end
  if l==2 then box(9,8,14,19,"d3c49b");box(9,8,14,3,accent);box(11,14,10,9,"8d8e62");ell(14,15,4,6,accent);p(15,14,"92b16d");line(8,6,23,6,"ede0b8") end
  if l==3 then line(10,28,22,28,"8f7c57");p(12,24,"f4e7bc");p(20,24,"f4e7bc") end
 elseif f==1 or f==11 then
  if l==1 then ell(11,3,12,25,"8b6633");leaf(16,29,-12,-12,"375a38");leaf(17,29,12,-15,"375a38") end
  if l==2 then ell(12,4,10,22,f==11 and "bf8037" or "ebbc42");for y=5,23,3 do for x=13,19,3 do box(x,y,2,2,f==11 and "e5b55a" or "ffe17e") end end;leaf(15,28,-10,-8,"5b9749");leaf(18,28,9,-10,"80ad51") end
  if l==3 and f==11 then for i=0,4 do p(14+i%3*2,7+i*3,"795036") end end
 elseif f==2 then
  if l==1 then line(9,28,21,12,"a45531");line(10,28,22,12,"a45531");ell(16,11,9,8,"a45531") end
  if l==2 then for i=0,13 do local x=11+i*.7;local y=27-i;local r=math.floor(i/4);box(math.floor(x)-r,y,r*2+1,1,"de8039") end;leaf(22,12,-2,-10);leaf(22,12,6,-7);leaf(22,12,-8,-6) end
  if l==3 then line(13,25,21,14,"f8b05b");line(18,18,20,19,"ad5b30");p(16,23,"ad5b30") end
 elseif f==3 or f==8 or f==12 then
  if l==1 then ell(5,11,22,15,"75553e") end
  if l==2 then ell(6,11,20,13,f==12 and "a67642" or "b99a6b");ell(8,12,14,7,f==12 and "c28c4d" or "d2b884");line(11,23,22,21,"977650") end
  if l==3 then
   if f==12 then line(11,13,22,21,"5e503b");ell(13,14,8,5,"edcf86");p(15,15,"fff0bd");p(19,17,"7c9a4e")
   elseif f==8 then leaf(18,12,-3,-8,"81934d");leaf(18,10,5,-4,"9eb366");p(12,18,"8b704d")
   else p(11,16,"93774e");p(19,14,"93774e");p(21,19,"93774e");p(10,13,"ecd3a2") end
  end
 elseif f==4 then
  if l==1 then ell(5,10,23,19,"853e36") end
  if l==2 then ell(6,10,21,17,"c55440");ell(7,11,15,12,"e6744b");line(13,11,23,12,"5d713c");line(18,8,15,14,"7c9e50") end
  if l==3 then ell(9,13,5,3,"f5b37a");p(21,24,"ae493a");p(17,8,"b9bd70") end
 elseif f==5 then
  if l==1 then for i=0,2 do line(9+i*4,29,12+i*5,6,"7b7346") end end
  if l==2 then for i=0,2 do local x=12+i*5;for y=5+i,14+i,3 do box(x-2,y,3,2,"c7a253");box(x+1,y+1,2,2,"e5c574");p(x-2,y,"f8e0a0") end end;box(10,23,11,2,"b58247") end
  if l==3 then line(10,23,19,24,"f5d790");p(13,28,"cbb068") end
 elseif f==14 then
  if l==1 then ell(3,10,26,18,"815238");box(5,21,22,6,"815238") end
  if l==2 then ell(4,10,24,16,"bb833e");box(5,19,22,5,"c18f4b");ell(6,11,19,9,"deb66e");for i=0,2 do line(10+i*6,12,7+i*6,18,"996739");line(11+i*6,12,9+i*6,16,"f2d18b") end end
  if l==3 then line(7,24,24,24,"e1b978");p(7,15,"f5dea1");p(25,20,"9c6d38") end
 else
  if l==1 then ell(3,11,26,9,"54636a");ell(5,13,22,16,"43515b") end
  if l==2 then ell(4,11,24,8,"bcc2af");ell(6,12,20,6,f==13 and "b9523c" or "9b723c");box(7,17,18,6,"6d8c90");ell(8,21,16,6,"607b82");line(6,17,25,17,"b7c7bb") end
  if l==3 then
   for i=0,5 do p(9+i*2,13+i%2*2,f==13 and "ef9b5e" or "d5a65e") end
   if f==15 then box(11,13,3,2,"df9b50");box(19,14,2,2,"bdc671");box(15,12,2,2,"7da365") end
   line(8,19,8,22,"9bb8b4");p(13,13,"8da458");p(20,13,"8da458")
  end
 end
end
local item_tags={};for i,n in ipairs(item_names) do table.insert(item_tags,{n,i,i}) end
save_sprite("farm_items",32,32,15,item,item_tags)
save_sprite("soil",16,16,2,function(f,l)
 local base=f==1 and "785237" or "4c3930";local dark=f==1 and "513b2d" or "302d2a";local light=f==1 and "a37948" or "736047"
 if l==1 then box(0,0,16,16,base) end
 if l==2 then for y=1,13,4 do box(0,y,16,2,dark);box(0,y+2,16,1,light) end end
 if l==3 then for i=0,15 do local x=(i*7)%16;local y=(i*11)%16;p(x,y,(i%2==0 and base or light)) end end
end,{{"dry",1,1},{"watered",2,2}})
dofile(root.."/tools/export_farming_aseprite.lua")
print("FARMING_AUTHORED 3 layered native sources, 32 frames")
