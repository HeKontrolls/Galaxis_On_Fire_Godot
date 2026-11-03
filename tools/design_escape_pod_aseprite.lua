-- All painting takes place inside Aseprite; sources retain separate material/detail layers.
local root=assert(app.params.root)
local src=root.."/assets/sprites/source/expedition/"
local out=root.."/assets/sprites/expedition/"
app.fs.makeAllDirectories(src); app.fs.makeAllDirectories(out)
local mirror=false
local function color(hex) return app.pixelColor.rgba(tonumber(hex:sub(1,2),16),tonumber(hex:sub(3,4),16),tonumber(hex:sub(5,6),16),255) end
local function p(im,x,y,c) x=math.floor(x); y=math.floor(y); if mirror then x=im.width-1-x end; if x>=0 and y>=0 and x<im.width and y<im.height then im:drawPixel(x,y,color(c)) end end
local function rect(im,x,y,w,h,c) for yy=y,y+h-1 do for xx=x,x+w-1 do p(im,xx,yy,c) end end end
local function line(im,x,y,xx,yy,c) local n=math.max(math.abs(xx-x),math.abs(yy-y)); for i=0,n do local t=n==0 and 0 or i/n; p(im,x+(xx-x)*t,y+(yy-y)*t,c) end end
local function poly(im,pts,c)
 for y=0,im.height-1 do local xs={}; for i=1,#pts do local a=pts[i]; local b=pts[i%#pts+1]; if (a[2]<=y and b[2]>y) or (b[2]<=y and a[2]>y) then xs[#xs+1]=a[1]+(y-a[2])*(b[1]-a[1])/(b[2]-a[2]) end end; table.sort(xs); for i=1,#xs-1,2 do for x=math.ceil(xs[i]),math.floor(xs[i+1]) do p(im,x,y,c) end end end
end
local function oval(im,cx,cy,rx,ry,c) for y=cy-ry,cy+ry do for x=cx-rx,cx+rx do if ((x-cx)/rx)^2+((y-cy)/ry)^2<=1 then p(im,x,y,c) end end end end
local function make(name,w,h,paint)
 local s=Sprite(w,h,ColorMode.RGB); local base=s.layers[1]; base.name="Hull and silhouette"; local details=s:newLayer(); details.name="Panels, lights and damage"
 local a=Image(w,h,ColorMode.RGB); local b=Image(w,h,ColorMode.RGB); paint(a,b)
 if name=="ship_damaged" then
  -- Bake the collapsed, partially buried pose into the native pixel artwork.
  -- Nearest-pixel sampling inside Aseprite keeps the game's hard pixel edges.
  local ca=Image(w,h,ColorMode.RGB); local cb=Image(w,h,ColorMode.RGB)
  local angle=-0.16; local co=math.cos(angle); local si=math.sin(angle)
  for y=0,h-1 do for x=0,w-1 do
   local dx=x-96; local dy=y-94
   local sx=math.floor(96+co*dx+si*dy+0.5); local sy=math.floor(77-si*dx+co*dy+0.5)
   if sx>=0 and sx<w and sy>=0 and sy<h then ca:drawPixel(x,y,a:getPixel(sx,sy)); cb:drawPixel(x,y,b:getPixel(sx,sy)) end
  end end
  a=ca; b=cb
  -- Torn plating and a snapped landing bracket lie in the impact dirt.
  poly(a,{{4,108},{14,101},{30,105},{34,111},{3,111}},"29373e")
  line(b,8,107,16,104,"a0a99d"); line(b,16,104,26,108,"c3a57d")
  poly(a,{{156,105},{165,100},{179,103},{187,110},{155,111}},"33424a")
  line(b,162,104,178,106,"b7bba8"); line(b,179,107,183,109,"75604c")
  rect(b,145,108,8,2,"a47547"); rect(b,146,106,3,2,"d1ab71")
 end
 base:cel(1).image=a; s:newCel(details,1,b,Point(0,0)); s:newTag(1,1).name="idle"
 s:saveAs(src..name..".aseprite"); local im=Image(w,h,ColorMode.RGB); im:drawSprite(s,1); im:saveAs(out..name..".png"); s:close()
end
for _,ready in ipairs({false,true}) do
 make(ready and "ship_ready" or "ship_damaged",192,112,function(a,b)
  -- Capsule, thermal shield, ascent thrusters, service hatch and impact-scarred panels.
  poly(a,{{42,83},{48,50},{66,16},{87,7},{115,10},{137,31},{153,75},{146,94},{51,98}},"172932")
  poly(a,{{48,80},{55,49},{71,21},{89,12},{113,15},{131,34},{146,77},{139,87},{56,90}},"789096")
  poly(a,{{57,52},{75,24},{89,17},{103,17},{97,40},{91,79},{57,84}},"c4d0c5")
  poly(a,{{104,17},{115,21},{132,41},{141,74},{131,84},{112,81}},"526c78")
  poly(a,{{46,80},{149,78},{155,91},{141,100},{54,101},{38,92}},"263843")
  for y=86,98,4 do line(b,49,y,142,y-1,"526470") end
  poly(a,{{22,58},{43,51},{52,65},{46,92},{21,94},{15,82}},"20323c")
  poly(a,{{23,61},{39,56},{46,67},{41,86},{23,87},{21,79}},"a8774b")
  poly(a,{{149,49},{167,52},{178,75},{174,90},{150,89},{140,67}},"233641")
  poly(a,{{152,55},{163,57},{172,75},{168,84},{152,83},{147,67}},"b78654")
  for _,x in ipairs({25,153}) do rect(b,x,66,13,3,"e1b783"); for xx=x,x+12,3 do rect(b,xx,74,1,9,"4b5250") end end
  -- Recessed oval hatch and cyan pressure window, readable at the normal pixel scale.
  oval(a,99,58,24,30,"263c48"); oval(a,99,57,21,27,"aabcb9"); oval(a,99,57,17,23,"4c6570")
  oval(b,99,47,12,12,"193b50"); oval(b,99,46,9,9,ready and "70d0d7" or "4e92aa")
  line(b,95,39,91,47,"d0efe7"); line(b,99,39,94,49,"9acbd1")
  rect(b,94,65,14,3,"253d49"); rect(b,105,64,3,7,"d7b279"); rect(b,90,74,18,2,"78939a")
  for i=0,7 do local angle=i/8*math.pi*2; p(b,99+math.cos(angle)*20,57+math.sin(angle)*26,"e2dbbc") end
  line(b,63,37,76,25,"f0ead1"); line(b,56,51,68,51,"536b73"); line(b,128,43,140,64,"91a8a6")
  if ready then
   for _,x in ipairs({52,137}) do rect(a,x,99,5,10,"22323e"); rect(b,x+1,100,2,8,"a9b8b4"); rect(a,x-7,108,19,3,"283a45"); rect(b,x-5,108,15,1,"99a9a4") end
  end
  rect(b,122,66,10,13,"283b44"); rect(b,124,68,6,3,ready and "a9e1ad" or "e18e57")
  for y=74,77,2 do rect(b,124,y,5,1,"798d8b") end
  -- Painted identification bars and caution chevrons.
  rect(b,66,62,4,14,"d79d56"); rect(b,65,68,6,2,"f0d19a")
  for x=63,127,8 do line(b,x,91,x+4,95,"a98951") end
  if not ready then
   poly(b,{{112,23},{126,29},{140,49},{136,74},{121,82},{112,67},{117,51},{109,36}},"182a34")
   poly(b,{{120,35},{130,42},{135,55},{130,69},{122,68},{124,54},{117,44}},"35454c")
   for y=43,64,5 do line(b,122,y,132,y+2,"8a7658"); line(b,122,y+1,131,y+3,"4d5550") end
   line(b,119,40,117,57,"b88651"); line(b,117,57,124,72,"d0a16a")
   line(b,131,48,137,58,"5d9a9e"); line(b,137,58,134,73,"45707c")
   poly(b,{{127,29},{143,40},{139,50},{131,44}},"a5afa3")
   line(b,130,32,140,41,"ddd6b9")
   poly(b,{{48,69},{65,57},{76,63},{73,81},{56,91},{40,87}},"394147")
   for i=0,5 do line(b,49+i*3,76,59+i*3,68,"66655a") end
   line(b,91,36,104,44,"dce4d4"); line(b,104,44,94,53,"dce4d4"); line(b,104,44,109,39,"c7d4ca")
   rect(b,124,68,6,3,"d9774e"); rect(b,125,68,2,1,"f4bf80")
   poly(b,{{115,20},{124,26},{131,36},{123,43},{115,38},{109,29}},"293b42")
   line(b,115,23,119,30,"ddad78"); line(b,119,30,115,36,"0e202d"); line(b,115,36,125,40,"d0a475")
   poly(b,{{24,83},{38,81},{42,90},{35,96},{19,93}},"263036")
   line(b,146,82,161,94,"d9a16c"); line(b,161,94,177,97,"9a784f")
   line(b,148,87,157,99,"455252"); line(b,157,99,172,100,"cc8b57")
   line(b,103,39,100,44,"d0e7df"); line(b,100,44,105,48,"d0e7df")
  else
   poly(b,{{113,23},{123,27},{128,37},{121,40},{113,35}},"9eafaa")
   line(b,116,26,123,34,"dce4ce"); rect(b,27,88,11,3,"79c9d1"); rect(b,155,85,12,3,"79c9d1")
  end
 end)
end
if app.params.only_pod=="true" then print("CRASHED_POD_AUTHORED native_frames=2"); return end
make("pod_strut",8,8,function(a,b) rect(a,1,0,6,8,"21333d"); rect(b,2,0,2,8,"8ba29e"); rect(b,5,0,1,8,"476270") end)
make("orbital_ship",144,56,function(a,b)
 poly(a,{{3,22},{24,19},{31,11},{88,10},{116,17},{139,25},{139,31},{112,40},{30,42},{24,35},{3,34}},"152b3b")
 poly(a,{{26,23},{34,14},{87,14},{114,21},{132,27},{110,35},{32,36}},"718d96")
 poly(a,{{39,16},{88,16},{105,21},{56,23}},"b5c7c2")
 poly(a,{{27,36},{45,32},{114,31},{104,38},{33,39}},"3c586a")
 poly(a,{{52,13},{60,3},{83,3},{94,12}},"293f50"); rect(b,62,6,19,3,"86d5d9")
 for x=61,79,6 do rect(b,x,6,1,4,"25485c") end
 for _,y in ipairs({15,34}) do rect(a,7,y,26,9,"2d485b"); rect(b,13,y+1,17,2,"a3b6b4"); rect(b,5,y+2,5,5,"75dae6") end
 for x=42,98,8 do rect(b,x,26,4,2,"90d9d6") end
 line(b,104,24,124,27,"d7dfc8"); line(b,56,34,90,34,"be9360")
 rect(a,99,38,4,12,"334d5e"); rect(b,100,39,1,9,"99adac"); rect(a,96,48,11,2,"415d68")
end)
-- Companion robot: four native animation tags, both directions, a blinking visor and walking feet.
local s=Sprite(48,48,ColorMode.RGB); local base=s.layers[1]; base.name="Robot chassis"; local detail=s:newLayer(); detail.name="Visor, status lamps and wear"
local frame=0
local tags={}
for _,direction in ipairs({"east","west"}) do for _,action in ipairs({"idle","walk"}) do
 local first=frame+1; local count=action=="idle" and 2 or 4
 for f=0,count-1 do
  frame=frame+1; if frame>1 then s:newEmptyFrame(frame) end
  mirror=direction=="west"
  local a=Image(48,48,ColorMode.RGB); local b=Image(48,48,ColorMode.RGB)
  local stride=action=="walk" and ({-2,0,2,0})[f+1] or 0
  local bob=action=="walk" and f%2 or 0
  rect(a,17+stride,30,5,8,"314857"); rect(a,26-stride,30,5,8,"314857")
  rect(b,18+stride,32,2,5,"9aaca8"); rect(b,27-stride,32,2,5,"9aaca8")
  rect(a,15+stride,37,9,3,"263b48"); rect(a,25-stride,37,9,3,"263b48")
  rect(b,16+stride,37,6,1,"bac7b9"); rect(b,27-stride,37,5,1,"bac7b9")
  rect(a,15,19+bob,19,14,"263d4a"); rect(a,17,20+bob,15,10,"a8b8ad")
  rect(b,20,24+bob,8,5,"496778"); rect(b,21,25+bob,5,2,"d8a562"); p(b,30,23+bob,"86e1d0")
  rect(a,11,22+bob,5,10,"304b5a"); rect(b,12,23+bob,2,6,"d0aa75"); rect(a,33,22+bob,5,10,"304b5a"); rect(b,34,23+bob,2,6,"d0aa75")
  poly(a,{{14,8+bob},{30,6+bob},{36,11+bob},{34,20+bob},{16,21+bob},{12,17+bob}},"263c4b")
  poly(a,{{16,9+bob},{29,8+bob},{33,12+bob},{31,18+bob},{16,18+bob},{14,15+bob}},"c0cabe")
  rect(b,17,11+bob,15,6,"214255")
  local eye=(action=="idle" and f==1) and 1 or 3
  rect(b,20,12+bob,3,eye,"89e0dc"); rect(b,27,12+bob,3,eye,"89e0dc")
  line(a,17,8+bob,17,3+bob,"344f61"); p(b,17,2+bob,"e8b56d")
  rect(b,25,19+bob,5,1,"617f87"); p(b,15,12+bob,"f0d8a3")
  s:newCel(base,frame,a,Point(0,0)); s:newCel(detail,frame,b,Point(0,0))
  s.frames[frame].duration=action=="walk" and 0.15 or (f==0 and 1.4 or 0.12)
 end
 tags[#tags+1]={first=first,last=frame,name=action.."_"..direction}
end end
for _,tag in ipairs(tags) do s:newTag(tag.first,tag.last).name=tag.name end
mirror=false
s:saveAs(src.."robot_guide.aseprite"); s:close()
dofile(root.."/tools/export_robot_guide_aseprite.lua")
print("ESCAPE_POD_ART authored=4 robot_frames=12")
