local root=assert(app.params.root)
app.fs.makeAllDirectories(root.."/assets/sprites/source/power");app.fs.makeAllDirectories(root.."/assets/sprites/power")
local names={"biomass_generator","coal_generator","fuel_generator","wood_power_pole","power_connector","power_switch","electric_lamp","logic_input","logic_output","not_gate","and_gate","or_gate","xor_gate","nand_gate","nor_gate","rs_nor_latch","rs_nand_latch","t_flip_flop","wire","logic_wire","raw_biomass","biofuel","refined_fuel"}
local font={A={"010","101","111","101","101"},B={"110","101","110","101","110"},C={"011","100","100","100","011"},D={"110","101","101","101","110"},F={"111","100","110","100","100"},I={"111","010","010","010","111"},K={"101","101","110","101","101"},L={"100","100","100","100","111"},N={"101","111","111","111","101"},O={"010","101","101","101","010"},R={"110","101","110","101","101"},S={"011","100","010","001","110"},T={"111","010","010","010","010"},X={"101","101","010","101","101"}}
local function rgba(h)return app.pixelColor.rgba(tonumber(h:sub(1,2),16),tonumber(h:sub(3,4),16),tonumber(h:sub(5,6),16),255)end
for index,name in ipairs(names) do
 if not app.params.only or app.params.only==name then
 local w,h=32,32
 if index<=3 then w,h=48,32 elseif index==4 then w,h=16,128 elseif index==5 or index==8 or index>=19 then w,h=16,16 elseif index==6 or index==9 then w,h=32,16 elseif index==7 then w,h=16,32 end
 local count=index<=18 and 4 or 1
 local s=Sprite(w,h,ColorMode.RGB);s.layers[1].name="Cabinet and silhouette";s:newLayer().name="Mechanism and material detail";s:newLayer().name="Terminals, labels and indicator lights"
 for frame=1,count do
  if frame>1 then s:newEmptyFrame() end
  local on=frame==2 or frame==3;local fault=frame==4
  for layer=1,3 do
   local im=Image(w,h,ColorMode.RGB)
   local function p(x,y,c)x=math.floor(x+.5);y=math.floor(y+.5);if x>=0 and y>=0 and x<w and y<h then im:drawPixel(x,y,rgba(c))end end
   local function box(x,y,ww,hh,c)for yy=y,y+hh-1 do for xx=x,x+ww-1 do p(xx,yy,c)end end end
   local function line(x,y,xx,yy,c)local n=math.max(math.abs(xx-x),math.abs(yy-y));for i=0,n do local t=n==0 and 0 or i/n;p(x+(xx-x)*t,y+(yy-y)*t,c)end end
   local function label(text,x,y,c)for j=1,#text do local glyph=font[text:sub(j,j)];if glyph then for yy=1,5 do for xx=1,3 do if glyph[yy]:sub(xx,xx)=="1" then p(x+(j-1)*4+xx-1,y+yy-1,c)end end end end end end
   local steel="455762";local rim="8cacae";local pale="c7d5bd";local copper="b97e49";local led=fault and "ed7454" or (on and "9bea9f" or "526760")
   if index<=3 then
    if layer==1 then
     box(1,7,46,23,"293d46");box(3,5,41,24,steel);box(4,29,8,3,"37434a");box(36,29,8,3,"37434a")
     if index==2 then box(34,0,7,8,"3b4c55");box(32,1,10,3,"789197")end
     if index==3 then box(3,4,13,25,"487a71");box(4,2,10,3,"627b78")end
    elseif layer==2 then
     line(3,6,42,6,rim);box(5,10,13,16,index==1 and "5c6e42" or "303b43");box(20,10,23,17,"334953");box(21,11,21,1,"7a9a9f")
     if index==1 then for i=0,11 do local x=6+i*7%11;local y=12+i*5%12;box(x,y,3,2,i%2==0 and "91a552" or "b4bb68")end end
     if index==2 then for i=0,7 do box(6+i*5%10,12+i*3%10,3,3,i%2==0 and "4f5355" or "727267")end;box(8,24,6,2,on and "edaf5f" or "856443")end
     if index==3 then box(6,7,7,18,"668f7a");line(7,8,7,22,"aec5a0");box(5,13,9,4,"d7bd72");box(6,25,7,1,"345858")end
     for yy=14,23,3 do box(20,yy,4,2,copper);p(21,yy,"edc184")end
     box(27,12,12,12,"5b7a80");box(29,14,8,8,"263e4d");box(32,17,2,2,"d0c89f")
     if frame%2==0 then line(29,15,37,21,"94aaa0");line(30,21,36,15,"94aaa0")else line(33,13,33,23,"94aaa0");line(28,18,38,18,"94aaa0")end
     for x=5,41,6 do box(x,27,3,2,"d6ad64")end
    else
     box(23,1,3,4,copper);p(24,1,"f8dd91");box(40,10,3,2,led)
     for _,pos in ipairs({{4,8},{43,8},{4,28},{43,28}})do p(pos[1],pos[2],pale)end
     label(index==1 and "B" or (index==2 and "C" or "F"),8,17,index==1 and "d7d99c" or "d8b985")
    end
   elseif index==4 then
    if layer==1 then
     box(6,6,5,122,"543d32");box(1,6,14,3,"5a4536");box(1,20,14,3,"5a4536");box(4,122,9,6,"47565a")
    elseif layer==2 then
     box(7,8,2,114,"ab8052");line(8,13,8,121,"d0a26a");box(1,6,14,1,"bc9864");box(1,20,14,1,"bc9864")
     for _,y in ipairs({1,15})do box(2,y,3,5,"607f90");box(11,y,3,5,"607f90");box(2,y+1,3,1,"c6d6ce");box(11,y+1,3,1,"c6d6ce")end
     line(3,23,8,36,"a08056");line(12,23,8,36,"a08056")
     for y=43,102,15 do p(7,y,"69513b");line(9,y-2,9,y+4,"866141")end
     box(5,107,7,11,"465e68");box(6,108,5,8,"91a49b");box(5,123,7,1,"92a39a")
    else
     box(7,1,3,4,copper);p(8,1,"ffe6a8");box(7,110,3,4,copper);p(8,111,"f4d795");p(6,108,pale);p(10,116,pale)
     for y=40,94,18 do p(7,y,"b3a178");p(9,y+2,"654b35")end
    end
   elseif index==5 then
    if layer==1 then box(4,3,9,12,"344852")elseif layer==2 then box(5,5,7,8,"91a9a1");for y=5,11,3 do box(4,y,9,1,"c3d0b9")end else box(7,1,3,4,copper);p(8,8,led);p(6,13,"e2ce91")end
   elseif index==6 or index==9 then
    if layer==1 then box(1,1,30,15,"2b424b")elseif layer==2 then box(2,2,28,12,"536a70");line(2,2,29,2,rim)
     if index==6 then box(10,7,13,6,"293d45");line(12,10,on and 22 or 18,on and 10 or 5,"d3c49d");p(12,10,copper)
     else box(10,5,13,8,"293d45");for x=12,19,2 do box(x,7,1,5,copper)end;line(21,6,on and 26 or 24,on and 9 or 4,"d3c49d")end
    else box(4,1,3,4,copper);box(26,1,3,4,copper);p(5,1,"f9dd91");p(27,1,"f9dd91");p(25,11,led)
     if index==9 then box(1,11,3,2,"bfa4de");box(28,11,3,2,led)end end
   elseif index==7 then
    if layer==1 then box(6,4,5,27,"3d545e");box(3,7,11,15,"3a4d54");box(4,29,9,3,"3a4d54")
    elseif layer==2 then box(5,8,7,12,on and "e4cf8c" or "738f96");box(6,9,4,10,on and "fff0af" or "c1d0c6");box(5,21,7,3,"879b98");box(7,24,3,6,"9c7a4b");line(5,9,5,17,pale)
    else box(7,1,3,4,copper);box(1,9,3,2,"bfa4de");p(12,24,led);p(5,30,"c9bc8e")end
   elseif index==8 then
    if layer==1 then box(1,2,14,14,"304951")elseif layer==2 then box(2,3,12,12,"5b7375");box(4,7,8,6,"283c43");line(5,11,on and 11 or 7,on and 8 or 5,"d7c59a")else box(7,1,3,4,copper);box(12,11,3,2,led);p(3,13,pale)end
   elseif index<=18 then
    if layer==1 then box(1,2,30,30,"29434b");box(3,4,26,26,"3d615e")
    elseif layer==2 then
     line(3,4,28,4,rim);line(3,5,3,29,"78958c");box(8,9,17,17,"253a43");box(9,10,15,15,"314952")
     for y=12,24,4 do line(4,y,8,y,copper);line(24,y,28,y,copper)end
     for y=7,27,5 do p(6,y,"779a6b");p(26,y,"6e8e72")end
     local labels={"NOT","AND","OR","XOR","NAND","NOR","RS","RS","T"}
     local text=labels[index-9];label(text,16-math.floor(#text*4/2),index>=16 and 11 or 15,pale)
     if index==16 then label("NOR",10,20,"c1a576")elseif index==17 then label("NAND",8,20,"c1a576")elseif index==18 then label("CLK",10,20,"c1a576")end
    else
     box(15,1,3,4,copper);box(1,9,3,2,"bca0d9");box(28,9,3,2,led)
     if index~=10 then box(1,23,3,2,"bca0d9")end
     if index>=16 then box(28,23,3,2,on and "455b5b" or "78cbb0")end
     p(27,6,led);p(4,28,pale);p(27,28,pale)
    end
   else
    if index==19 or index==20 then
     local col=index==19 and "c28a4e" or "74ac9e"
     if layer==1 then for y=3,12 do for x=3,12 do local d=((x-7.5)/5)^2+((y-7.5)/5)^2;if d<1 and d>.35 then p(x,y,"604d40")end end end
     elseif layer==2 then for y=3,12 do for x=3,12 do local d=((x-7.5)/5)^2+((y-7.5)/5)^2;if d<.9 and d>.45 then p(x,y,col)end end end;line(11,11,14,14,col)
     else for _,pos in ipairs({{4,5},{5,4},{6,3},{4,7}})do p(pos[1],pos[2],"ead498")end;box(12,12,3,2,index==19 and "ddaa68" or "b9a1de")end
    elseif index==21 then
     if layer==1 then box(2,7,12,7,"4c593a")elseif layer==2 then for i=0,19 do box(2+i*7%12,3+i*5%11,2,2,i%2==0 and "8ca35a" or "bdba74")end else line(4,10,12,12,"a17a45");p(3,5,"d4ca8e")end
    else
     if layer==1 then box(3,4,11,11,"334d50");box(5,1,6,4,"536a61")elseif layer==2 then box(4,5,9,9,index==22 and "668c58" or "ba8051");line(4,5,11,5,"d3c996");box(5,7,6,5,"d3bc78");p(6,2,"d4d0aa")else label(index==22 and "B" or "F",7,7,"4a664c");p(12,13,"d9c48b")end
    end
   end
   if frame==1 and layer==1 then s.layers[1]:cel(1).image=im else s:newCel(s.layers[layer],frame,im,Point(0,0))end
  end
  s.frames[frame].duration=.2
 end
 s:newTag(1,1).name="off"
 if count==4 then s:newTag(2,3).name="online";s:newTag(4,4).name="fault"end
 s:saveAs(root.."/assets/sprites/source/power/"..name..".aseprite");s:close()
 end
end
if app.params.only then dofile(root.."/tools/export_power_aseprite.lua") else dofile(root.."/tools/design_power_fixtures_aseprite.lua")end
print("POWER_AUTHORED native sources=31 frames=109 layers=3")
