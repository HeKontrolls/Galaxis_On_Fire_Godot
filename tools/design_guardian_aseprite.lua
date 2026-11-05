-- All drawing, native layers, animation tags and PNG exports authored in Aseprite.
local root=assert(app.params.root)
local src=root.."/assets/sprites/source/expedition/"
local out=root.."/assets/sprites/expedition/"
app.fs.makeAllDirectories(src);app.fs.makeAllDirectories(out)
local function color(h) return app.pixelColor.rgba(tonumber(h:sub(1,2),16),tonumber(h:sub(3,4),16),tonumber(h:sub(5,6),16),255) end
local function brush(im)
 local function p(x,y,c) x=math.floor(x+.5);y=math.floor(y+.5);if x>=0 and y>=0 and x<im.width and y<im.height then im:drawPixel(x,y,color(c)) end end
 local function rect(x,y,w,h,c) for yy=y,y+h-1 do for xx=x,x+w-1 do p(xx,yy,c) end end end
 local function line(x,y,xx,yy,c) local n=math.max(math.abs(xx-x),math.abs(yy-y));for i=0,n do local t=n==0 and 0 or i/n;p(x+(xx-x)*t,y+(yy-y)*t,c) end end
 local function poly(points,c)
  for y=0,im.height-1 do
   local hits={};local j=#points
   for i=1,#points do local a,b=points[i],points[j];if (a[2]<=y and b[2]>y) or (b[2]<=y and a[2]>y) then hits[#hits+1]=a[1]+(y-a[2])*(b[1]-a[1])/(b[2]-a[2]) end;j=i end
   table.sort(hits);for i=1,#hits-1,2 do for x=math.ceil(hits[i]),math.floor(hits[i+1]) do p(x,y,c) end end
  end
 end
 return p,rect,line,poly
end
local function new_sprite(w,h,layers,frames)
 local s=Sprite(w,h,ColorMode.RGB);s.layers[1].name=layers[1]
 for i=2,#layers do s:newLayer().name=layers[i] end
 for i=2,frames do s:newEmptyFrame() end
 return s
end
local function cel(s,layer,frame,im)
 local old=s.layers[layer]:cel(frame);if old then old.image=im else s:newCel(s.layers[layer],frame,im,Point(0,0)) end
end
local review=Image(512,112,ColorMode.RGB)
local s=new_sprite(64,64,{"Mechanical silhouette", "Salvaged brass and teal armor", "Rivets fractures and hazard paint", "Core lenses and exhaust"},8)
for f=1,8 do
 local bob=(f==2 or f==5) and 1 or 0
 local charge=f==4 or f==5
 local slam=f==7
 local lift=f==6 and -12 or (slam and 6 or 0)
 for layer=1,4 do
  local im=Image(64,64,ColorMode.RGB);local p,r,l,poly=brush(im)
  local y=21+bob
  if layer==1 then
   -- Heavy separated treads, asymmetric shoulder, exposed spine, right-hand drill.
   r(13,44,9,13,"374b51");r(35,43,9,14,"374b51")
   poly({{8,54},{14,51},{25,54},{25,62},{8,62}},"34454e")
   poly({{32,54},{41,51},{48,55},{48,62},{31,62}},"34454e")
   r(18,37,23,12,"3c565a");r(12,y+1,32,24,"385457")
   poly({{12,y+2},{18,y-5},{33,y-7},{44,y+1},{41,y+21},{16,y+23}},"466064")
   r(5,y+1+lift,10,17,"4d5551");r(3,y+12+lift,13,9,"605441")
   r(42,y+5,11,11,"4b5553")
   poly({{50,y+2},{63,y+11},{50,y+20}},"475660")
   r(23,y-13,12,9,"3b5357");l(26,y-14,24,y-19,"74897e");l(24,y-19,28,y-22,"74897e")
   r(17,y-4,4,5,"604e43");r(38,y-3,4,8,"604e43")
  elseif layer==2 then
   poly({{14,y+2},{19,y-3},{32,y-5},{39,y},{37,y+9},{16,y+12}},"b99551")
   poly({{13,y+14},{27,y+10},{37,y+13},{37,y+21},{17,y+21}},"538784")
   poly({{30,y-4},{42,y+2},{39,y+14},{34,y+11}},"8a703f")
   l(15,y+1,29,y-3,"e9d49c");l(15,y+2,15,y+8,"c9b97b")
   r(18,y+1,13,9,"2f5058");r(21,y+4,7,7,"294b56")
   r(24,y-12,9,6,"b39b6a");r(25,y-10,9,4,"346066")
   r(7,y+2+lift,6,13,"b08b4d");r(5,y+14+lift,9,5,"c1a571")
   r(10,y+7+lift,3,5,"d7c392");r(44,y+6,7,9,"aa8955")
   poly({{51,y+4},{61,y+11},{51,y+18}},"a9baba")
   poly({{51,y+11},{61,y+11},{51,y+18}},"718b96")
   r(15,46,5,10,"a5aaa0");r(37,46,5,10,"a5aaa0")
   r(10,55,13,5,"6f8585");r(33,55,13,5,"6f8585")
   l(12,54,21,54,"abb7a3");l(35,54,42,54,"abb7a3")
   r(23,44,12,3,"9a784c")
  elseif layer==3 then
   -- Broken plates, copper piping, louvered belly and small alternating caution stripes.
   for x=17,35,6 do p(x,y+18,"a7c3a9");p(x+1,y+19,"325d62") end
   for yy=y+12,y+17,2 do l(21,yy,30,yy-2,"31575f") end
   l(31,y-1,29,y+2,"6d573c");l(29,y+2,33,y+4,"6d573c");p(31,y+4,"e0c384")
   for x=10,44,3 do if x<24 or x>31 then r(x,58,2,3,"405961");p(x,57,"acb6a2") end end
   for yy=46,54,3 do l(14,yy,20,yy,"576e75");l(36,yy,42,yy,"576e75") end
   l(39,y+2,42,y+6,"d6b177");l(42,y+6,40,y+18,"d6b177")
   l(17,y+9,15,y+16,"bb7850");l(15,y+16,18,y+19,"bb7850")
   for yy=y+5,y+16,4 do l(51,yy,56,yy+3,"435d6c");l(51,yy+1,55,yy+3,"dae1cb") end
   r(43,y+7,2,7,"edd08c");r(46,y+8,2,7,"635c43")
   p(16,y+5,"f0d7a0");p(36,y+5,"f0d7a0");p(8,y+4+lift,"f0d7a0")
   for i=0,2 do r(6+i*3,y+15+lift,2,2,"596061") end
   r(24,y-7,2,2,"e1c488");p(34,y+18,"d8a266")
  else
   local glow=(f==3 or f==6 or charge or slam) and "ffd27b" or "82e2df"
   r(22,y+3,5,8,glow);r(20,y+5,9,4,glow);r(23,y+5,4,4,"edf8cb")
   r(27,y-10,5,2,glow);p(28,y-22,"e3b57b")
   if charge then for i=0,2 do l(6-i*2,y+23+i*3,1,y+23+i*3,"c19b67") end end
   if f==8 then r(18,y-4,2,2,"809c94");r(16,y-7,3,2,"5e797c") end
   if slam then for i=0,3 do p(2+i*3,61-i%2*3,"e1be7b");p(20+i*5,62-i%2*2,"b78b5c") end end
  end
  cel(s,layer,f,im)
 end
 s.frames[f].duration=(f==3 or f==6) and .22 or .14
 local flat=Image(64,64,ColorMode.RGB);flat:drawSprite(s,f);review:drawImage(flat,Point((f-1)*64,0))
end
for _,tag in ipairs({{"idle",1,2},{"warn_charge",3,3},{"charge",4,5},{"warn_slam",6,6},{"slam",7,7},{"recover",8,8}}) do s:newTag(tag[2],tag[3]).name=tag[1] end
s:saveAs(src.."mining_guardian.aseprite")
local sheet=Image(512,64,ColorMode.RGB)
for f=1,8 do local im=Image(64,64,ColorMode.RGB);im:drawSprite(s,f);sheet:drawImage(im,Point((f-1)*64,0)) end
sheet:saveAs(out.."mining_guardian.png");s:close()
local names={"faultline_hammer","survey_core"}
for i,name in ipairs(names) do
 local h=i==1 and 40 or 32
 local item=new_sprite(32,h,{"Material silhouette","Faceted surfaces","Engravings and reactor light"},1)
 for layer=1,3 do
  local im=Image(32,h,ColorMode.RGB);local p,r,l,poly=brush(im)
  if i==1 then
   if layer==1 then r(14,14,5,23,"4f5148");poly({{3,7},{9,3},{24,5},{29,9},{26,18},{8,17},{3,13}},"3c565c")
   elseif layer==2 then
    poly({{5,8},{10,5},{23,7},{25,11},{23,16},{9,15},{5,12}},"6a9790")
    r(5,8,4,6,"cbb17c");r(22,7,4,9,"af894f");l(10,5,22,7,"c4d7b8")
    r(15,18,3,15,"b79364");r(13,35,7,3,"96aaa0");r(13,18,7,3,"c9ac70")
   else
    r(12,8,7,5,"304e59");r(14,8,3,6,"81e7da");p(15,9,"effacc")
    for y=25,33,2 do l(14,y,18,y+1,"655e4e");p(15,y,"d7bd88") end
    l(8,7,8,13,"efe1a9");p(23,8,"efce90");l(19,13,21,14,"314d57");p(15,36,"e6dbb6")
   end
  else
   if layer==1 then poly({{9,3},{23,5},{28,14},{24,26},{12,29},{4,20},{4,11}},"3e5661")
   elseif layer==2 then
    poly({{10,5},{21,7},{25,14},{22,24},{12,26},{7,19},{7,12}},"b29a66")
    poly({{12,8},{21,10},{23,17},{18,24},{10,20},{9,13}},"46767e")
    l(10,5,20,7,"e3ce92");l(5,13,5,19,"9bbfb4");l(12,26,21,24,"67887c")
   else
    poly({{15,9},{20,13},{19,20},{14,23},{11,18},{12,12}},"79ded4")
    l(15,11,15,21,"e1f6c4");r(8,8,3,2,"eee0ad");r(22,20,2,3,"ead49e")
    p(21,8,"6b604c");p(10,23,"3c5761");l(8,18,10,20,"d5b881")
   end
  end
  cel(item,layer,1,im)
 end
 item:newTag(1,1).name="held_and_inventory"
 local sourcePath=i==1 and root.."/assets/sprites/source/weapons/" or src
 local outputPath=i==1 and root.."/assets/sprites/weapons/" or out
 item:saveAs(sourcePath..name..".aseprite")
 local flat=Image(32,h,ColorMode.RGB);flat:drawSprite(item,1);flat:saveAs(outputPath..name..".png")
 review:drawImage(flat,Point(12+(i-1)*64,72));item:close()
end
local f=assert(io.open(out.."mining_guardian.json","w"));f:write('{"frame_width":64,"frame_height":64,"pivot":[32,64],"hitbox":[8,16,48,48],"tags":{"idle":[0,1],"warn_charge":[2,2],"charge":[3,4],"warn_slam":[5,5],"slam":[6,6],"recover":[7,7]}}');f:close()
f=assert(io.open(root.."/assets/sprites/weapons/faultline_hammer.json","w"));f:write('{"frame_width":32,"frame_height":40,"pivot":[16,32],"tags":[{"name":"held_and_inventory","from":0,"to":0}],"animation":"runtime aimed swing"}');f:close()
review:resize(1536,336);review:saveAs(root.."/.godot/guardian_art_review.png")
print("GUARDIAN_ART native Aseprite: 8-frame guardian, layered hammer and Survey Core")
