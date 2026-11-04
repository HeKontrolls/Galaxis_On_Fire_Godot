local root=assert(app.params.root)
local names={"wall_light","ceiling_light","floodlight","red_signal_lamp","wall_switch","push_button","pressure_plate","daylight_sensor"}
local function color(h)return app.pixelColor.rgba(tonumber(h:sub(1,2),16),tonumber(h:sub(3,4),16),tonumber(h:sub(5,6),16),255)end
for index,name in ipairs(names) do
 local w,h=16,16
 if index==2 or index==7 then w=32 elseif index==3 then w,h=32,32 end
 local s=Sprite(w,h,ColorMode.RGB)
 s.layers[1].name="Housing, brackets and silhouette";s:newLayer().name="Glass, metal and mechanism";s:newLayer().name="Light core, contacts and indicators"
 for frame=1,4 do
  if frame>1 then s:newEmptyFrame()end
  local on=frame==2 or frame==3;local fault=frame==4
  for layer=1,3 do
   local im=Image(w,h,ColorMode.RGB)
   local function p(x,y,c)if x>=0 and x<w and y>=0 and y<h then im:drawPixel(x,y,color(c))end end
   local function box(x,y,ww,hh,c)for yy=y,y+hh-1 do for xx=x,x+ww-1 do p(xx,yy,c)end end end
   local function line(x,y,xx,yy,c)local n=math.max(math.abs(xx-x),math.abs(yy-y));for i=0,n do local t=n==0 and 0 or i/n;p(math.floor(x+(xx-x)*t+.5),math.floor(y+(yy-y)*t+.5),c)end end
   local edge="354b58";local metal="607e83";local rim="afc0b4";local copper="b88854";local glow=on and "fff0b5" or "779aa0";local led=fault and "e68569" or (on and "98d7a3" or "527b78")
   if index==1 then
    if layer==1 then box(1,4,3,11,edge);box(3,5,11,9,edge);box(6,3,5,2,edge);box(6,14,4,2,edge)
    elseif layer==2 then box(2,5,1,8,copper);box(4,6,9,7,metal);box(5,7,7,5,glow);line(5,5,12,5,rim);box(7,14,2,1,copper);p(1,5,rim);p(1,12,rim)
    else line(6,7,6,11,on and "fff8d6" or "bed2ce");box(7,1,3,4,copper);box(1,9,3,2,"bfa4de");p(12,13,led)end
   elseif index==2 then
    if layer==1 then box(4,1,3,5,edge);box(25,1,3,5,edge);box(1,5,30,8,edge);box(3,13,26,2,edge)
    elseif layer==2 then box(2,6,28,1,rim);box(3,7,26,5,metal);box(5,8,22,3,glow);box(4,13,24,1,copper);box(5,2,1,3,copper);box(26,2,1,3,copper)
    else line(6,8,25,8,on and "fff8d6" or "bed2ce");for x=5,26,7 do p(x,10,on and "e1d392" or "5b7c83")end;box(15,1,3,4,copper);box(1,11,3,2,"bfa4de");p(29,12,led)end
   elseif index==3 then
    if layer==1 then box(3,7,25,14,edge);box(6,4,19,3,edge);box(6,21,18,3,edge);box(14,24,5,5,edge);box(8,29,18,3,edge)
    elseif layer==2 then box(4,8,23,12,metal);box(7,5,17,2,rim);box(7,9,17,10,copper);box(9,10,13,8,glow);line(5,8,5,18,rim);line(8,22,23,22,rim);box(15,25,2,5,copper);box(10,30,14,1,metal);p(5,19,rim);p(26,19,rim)
    else box(11,11,9,5,on and "fff8d6" or "bad0c8");line(8,9,8,18,"dfc28c");for y=10,17,3 do box(24,y,2,1,edge)end;box(15,1,3,4,copper);box(1,9,3,2,"bfa4de");p(25,23,led)end
   elseif index==4 then
    if layer==1 then box(2,4,12,11,edge);box(4,2,8,2,edge)
    elseif layer==2 then box(3,5,10,8,metal);box(5,4,6,8,on and "e87861" or "713f4c");box(4,6,8,4,on and "ef916d" or "965664");line(4,13,11,13,copper);p(3,14,rim);p(12,14,rim)
    else box(5,5,2,3,on and "ffd1a0" or "b87c7a");box(7,1,3,3,copper);box(1,9,3,2,"bfa4de");p(12,12,led)end
   elseif index==5 then
    if layer==1 then box(2,2,12,14,edge)
    elseif layer==2 then box(3,3,10,12,metal);line(3,3,12,3,rim);box(5,6,6,7,"293e4c");line(7,10,on and 10 or 7,on and 7 or 5,copper);line(8,10,on and 11 or 8,on and 7 or 5,"e3ce9f");p(3,14,rim);p(12,14,rim)
    else box(4,1,3,4,copper);box(10,1,3,4,copper);p(11,12,led);p(4,12,"9fbcac")end
   elseif index==6 then
    if layer==1 then box(2,3,12,13,edge)
    elseif layer==2 then box(3,4,10,11,metal);line(3,4,12,4,rim);box(4,7,8,6,"4c4352");box(5,on and 9 or 7,6,on and 3 or 4,on and "ae654f" or "d08a65");line(6,on and 9 or 7,9,on and 9 or 7,"edbf8d");p(3,14,rim);p(12,14,rim)
    else box(7,1,3,4,copper);box(12,11,3,2,led);p(4,5,copper)end
   elseif index==7 then
    if layer==1 then box(1,12,30,4,edge);box(3,on and 11 or 8,26,on and 2 or 5,edge)
    elseif layer==2 then box(2,13,28,2,copper);box(4,on and 11 or 9,24,2,metal);for x=5,26,4 do p(x,on and 11 or 9,rim)end;box(5,12,2,1,"e1ba79");box(25,12,2,1,"e1ba79")
    else box(15,1,3,4,copper);line(16,4,16,8,edge);box(28,11,3,2,led);p(2,14,rim);p(29,14,rim)end
   else
    if layer==1 then box(1,10,14,6,edge);box(3,5,10,6,edge);box(5,3,6,2,edge)
    elseif layer==2 then box(2,11,12,3,metal);box(4,6,8,5,on and "78b7b2" or "48678c");box(6,4,4,2,on and "b1d5b9" or "8cabc2");for x=5,11,3 do line(x,7,x,10,"385c73")end;line(4,8,11,8,"c0d0bd");line(3,14,12,14,copper)
    else box(7,1,3,4,copper);box(12,11,3,2,led);p(5,6,"e2e6c9");p(3,12,rim)end
   end
   if frame==1 and layer==1 then s.layers[1]:cel(1).image=im else s:newCel(s.layers[layer],frame,im,Point(0,0))end
  end
  s.frames[frame].duration=.2
 end
 s:newTag(1,1).name="off";s:newTag(2,3).name="online";s:newTag(4,4).name="fault"
 s:saveAs(root.."/assets/sprites/source/power/"..name..".aseprite");s:close()
end
dofile(root.."/tools/export_power_aseprite.lua")
print("POWER_FIXTURES_AUTHORED sources=8 frames=32 layers=3")
