-- Author and export native layered pixel art in Aseprite. No external rasterizer.
local root=assert(app.params.root)
local source=root.."/assets/sprites/source/weapons/"
local output=root.."/assets/sprites/weapons/"
app.fs.makeAllDirectories(source);app.fs.makeAllDirectories(output)
local names={"wood_spear","copper_spear","iron_spear","iron_dagger","iron_warhammer","crystal_blade"}
local review=Image(6*48,80,ColorMode.RGB)
local function color(h) return app.pixelColor.rgba(tonumber(h:sub(1,2),16),tonumber(h:sub(3,4),16),tonumber(h:sub(5,6),16),255) end
for kind,name in ipairs(names) do
 local spear=kind<=3;local height=spear and 64 or 40
 local s=Sprite(32,height,ColorMode.RGB)
 s.layers[1].name="Silhouette and material shadows"
 s:newLayer().name="Faceted metal, wood grain and crystal"
 s:newLayer().name="Leather wraps, rivets and cutting edges"
 for layer=1,3 do
  local im=Image(32,height,ColorMode.RGB)
  local function p(x,y,c) x=math.floor(x+.5);y=math.floor(y+.5);if x>=0 and x<32 and y>=0 and y<height then im:drawPixel(x,y,color(c)) end end
  local function box(x,y,w,h,c) for yy=y,y+h-1 do for xx=x,x+w-1 do p(xx,yy,c) end end end
  local function line(x,y,xx,yy,c) local n=math.max(math.abs(xx-x),math.abs(yy-y));for i=0,n do local t=n==0 and 0 or i/n;p(x+(xx-x)*t,y+(yy-y)*t,c) end end
  local dark,metal,light="344954","7897a5","dce8e4"
  if kind==2 then dark,metal,light="693d35","bb7146","f6ce88" end
  if spear then
   if layer==1 then
    box(14,16,4,46,"4e3931");box(13,59,6,3,dark)
    for y=2,20 do local half=math.min(4,math.floor((y-2)/3));if y>16 then half=math.floor((22-y)/2) end;box(16-half,y,half*2+1,1,kind==1 and "614331" or dark) end
   elseif layer==2 then
    box(15,19,2,40,"ad8050");line(15,25,15,46,"d6af73");line(17,28,17,54,"78543b")
    for y=4,18 do local half=math.min(3,math.floor((y-3)/3));box(16-half,y,half+1,1,kind==1 and "cf9d61" or light);box(17,y,half,1,kind==1 and "93704a" or metal) end
    box(14,20,5,3,kind==1 and "9b7550" or metal);box(14,59,4,2,metal)
   else
    for y=23,28,2 do line(14,y,18,y+1,"d1b48a") end
    box(14,48,4,10,"775346");for y=48,56,2 do line(14,y,17,y+1,"bf9270") end
    p(14,20,light);p(17,21,light);p(15,60,light)
    if kind==3 then line(13,29,11,34,"597e8d");line(14,29,12,36,"9bbcc0") end
   end
  elseif kind==4 then
   if layer==1 then
    box(14,22,5,14,"463e40");box(10,24,13,3,dark)
    for y=8,23 do local w=math.min(3,math.floor((y-8)/3));box(16-w,y,w*2+1,1,dark) end
   elseif layer==2 then
    for y=10,23 do local w=math.min(2,math.floor((y-9)/3));box(16-w,y,w+1,1,light);box(17,y,w,1,metal) end
    box(11,24,11,2,metal);box(15,28,3,6,"ab7052");box(14,35,5,2,metal)
   else
    p(11,24,light);p(21,24,light);for y=28,33,2 do line(15,y,17,y+1,"e0b17b") end
    p(15,35,light);box(15,25,3,2,"d4ae60")
   end
  elseif kind==5 then
   if layer==1 then
    box(14,14,5,23,"4e3931");box(5,5,22,12,dark);box(3,7,4,8,dark);box(26,8,4,6,dark)
   elseif layer==2 then
    box(6,6,19,9,"617c89");box(5,7,4,7,"9fb8bb");box(10,6,12,3,"b4c8c6");box(22,8,4,7,"485e6c")
    box(15,17,3,17,"ae7c50");box(13,17,7,3,"b09359");box(13,35,7,3,metal)
    box(12,10,8,4,"425e6e");line(14,10,16,13,"9eb4b7");line(16,13,18,10,"9eb4b7")
   else
    line(6,6,23,6,light);line(4,8,4,12,light);box(16,7,2,2,"e6cd85");box(16,14,2,2,"c9a467")
    box(14,25,5,9,"61453d");for y=25,32,2 do line(14,y,18,y+1,"c39469") end
    p(14,35,light);p(18,36,light);p(25,9,"b3c9c5")
   end
  else
   if layer==1 then
    box(14,25,5,12,"42475a");box(8,25,16,3,"485278")
    for y=1,24 do local half=math.min(5,math.floor((y-1)*.55));if y>19 then half=3 end;box(16-half,y,half*2+1,1,"355270") end
   elseif layer==2 then
    for y=3,23 do local half=math.min(4,math.floor((y-2)*.5));box(16-half,y,half+1,1,"a0e7ec");box(17,y,math.max(0,half-1),1,"6482c9") end
    line(16,3,16,23,"e2fcf4");line(18,8,20,18,"9899e4");line(12,18,15,12,"76baca")
    box(9,25,14,2,"c4a766");box(15,29,3,6,"596587");box(14,36,5,2,"bf9c61")
   else
    line(10,25,14,24,"f0d998");line(19,24,22,25,"f0d998");box(15,25,3,3,"7ddbdc");p(16,25,"effff0")
    for y=30,34,2 do line(15,y,17,y+1,"97b5c2") end
    p(15,36,"f1d28c");p(12,17,"effff7");p(19,12,"d2bcff")
   end
  end
  if layer==1 then s.layers[1]:cel(1).image=im else s:newCel(s.layers[layer],1,im,Point(0,0)) end
 end
 s:newTag(1,1).name="held_and_inventory"
 s:saveAs(source..name..".aseprite")
 local flat=Image(32,height,ColorMode.RGB);flat:drawSprite(s,1);flat:saveAs(output..name..".png")
 review:drawImage(flat,Point((kind-1)*48+8,70-height))
 local f=assert(io.open(output..name..".json","w"));f:write(string.format('{"frame_width":32,"frame_height":%d,"pivot":[16,%d],"tags":[{"name":"held_and_inventory","from":0,"to":0}],"animation":"runtime aimed thrust or swing"}',height,spear and 56 or 32));f:close()
 s:close()
end
review:resize(1152,320)
review:saveAs(root.."/.godot/melee_art_review.png")
print("MELEE_ART: six native layered Aseprite sources and transparent exports")
