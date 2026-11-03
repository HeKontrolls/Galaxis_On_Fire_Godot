-- Reference-directed small surface rocks. All pixels are painted in Aseprite.
-- Keeps the saved document's canvas, pivots, layers, frame counts and tags.
local root=assert(app.params.root)
local function C(s) return app.pixelColor.rgba(tonumber(s:sub(1,2),16),tonumber(s:sub(3,4),16),tonumber(s:sub(5,6),16),255) end
local function px(im,x,y,c) x=math.floor(x); y=math.floor(y); if x>=0 and y>=0 and x<48 and y<40 then im:drawPixel(x,y,c) end end
local function line(im,x,y,xx,yy,c)
 x=math.floor(x); y=math.floor(y); xx=math.floor(xx); yy=math.floor(yy)
 local dx=math.abs(xx-x); local sx=x<xx and 1 or -1; local dy=-math.abs(yy-y); local sy=y<yy and 1 or -1; local e=dx+dy
 while true do px(im,x,y,c); if x==xx and y==yy then break end
  local e2=2*e; if e2>=dy then e=e+dy; x=x+sx end; if e2<=dx then e=e+dx; y=y+sy end end
end
local function poly(im,p,c)
 for y=0,39 do local xs={}
  for i,a in ipairs(p) do local b=p[i%#p+1]; if (a[2]<=y and b[2]>y) or (b[2]<=y and a[2]>y) then table.insert(xs,a[1]+(y-a[2])*(b[1]-a[1])/(b[2]-a[2])) end end
  table.sort(xs); for i=1,#xs-1,2 do for x=math.ceil(xs[i]),math.floor(xs[i+1]) do px(im,x,y,c) end end
 end
 for i,a in ipairs(p) do local b=p[i%#p+1]; line(im,a[1],a[2],b[1],b[2],c) end
end
local gray={C("2a403f"),C("4a5e58"),C("6d7e72"),C("95a28b"),C("b9c3a4")}
local warm={C("54483b"),C("7e7055"),C("a28e68"),C("c7b187"),C("e1cda3")}
local dark={C("28343d"),C("424f57"),C("626f73"),C("89938e"),C("b2b8a6")}
local moss={C("244634"),C("427346"),C("6d9a5a"),C("a5ba73")}
local function stone(im,cx,bottom,w,h,p,seed)
 -- Broken rounded outline; shallow interlocking faces and one-pixel seams.
 local left=cx-math.floor(w/2); local right=left+w-1; local top=bottom-h+1
 poly(im[1],{{left+2,bottom},{left,bottom-3},{left+1,top+5},{left+4,top+3},{left+5,top+1},{cx+1,top},{right-2,top+3},{right,top+6},{right-1,bottom-2},{right-3,bottom}},p[1])
 poly(im[2],{{left+2,bottom-2},{left+2,top+6},{left+5,top+4},{left+6,top+2},{cx+1,top+2},{right-3,top+4},{right-2,bottom-3},{right-4,bottom-1}},p[3])
 poly(im[3],{{left+3,top+6},{left+6,top+3},{cx,top+2},{cx+3,top+4},{cx,top+6},{left+6,top+8}},p[4])
 poly(im[3],{{cx+2,top+6},{right-3,top+5},{right-2,bottom-3},{cx+2,bottom-2},{cx-1,top+8}},p[2])
 line(im[4],left+4,top+5,left+7,top+3,p[5]); line(im[4],cx,top+3,cx+2,top+4,p[4])
 line(im[4],cx,top+6,cx-2,top+8,p[1]); line(im[4],cx-2,top+8,cx,top+10,p[2])
 for y=top+3,bottom-2 do for x=left+3,right-2 do
  if app.pixelColor.rgbaA(im[2]:getPixel(x,y))>0 then
   local q=(x*13+y*23+seed*7)%47
   if q==0 then px(im[4],x,y,p[4]); px(im[4],x+1,y,p[3]) elseif q==17 then px(im[4],x,y,p[2]) end
  end
 end end
end
local function growth(im,x,y,sw,light)
 line(im,x-2,y+1,x+2,y,moss[1]); line(im,x-2,y,x+1,y-1,moss[2]); px(im,x,y-2,moss[3])
 px(im,x+1+sw,y-2,moss[light and 4 or 3]); px(im,x-1,y-1,moss[3])
end
local function paint(name,n)
 local im={Image(48,40),Image(48,40),Image(48,40),Image(48,40)}
 local sw=({0,1,0,-1})[n+1]
 if name=="pebble_cluster" then
  stone(im,15,39,9,7,gray,1); stone(im,24,39,12,10,gray,3); stone(im,34,39,8,7,gray,4)
  growth(im[4],13,38,0,false); px(im[4],28,38,moss[2])
 elseif name=="granite_boulder" then
  stone(im,14,39,12,10,gray,3); stone(im,25,39,20,18,gray,6); stone(im,37,39,10,9,gray,9)
  growth(im[4],19,35,0,false); growth(im[4],31,38,0,true)
  line(im[4],22,25,24,23,gray[5]); px(im[4],27,31,gray[4])
 elseif name=="mossy_boulder" then
  stone(im,15,39,13,11,gray,4); stone(im,26,39,20,19,gray,7); stone(im,37,39,10,9,gray,2)
  for i,p in ipairs({{11,36},{16,34},{21,27},{25,23},{29,26},{33,33},{35,37},{23,37}}) do growth(im[4],p[1],p[2],i%3==0 and sw or 0,i%2==0) end
  -- Short ground-level blades tuck the stones into vegetation.
  line(im[4],9,39,8+sw,35,moss[2]); line(im[4],10,39,12+sw,35,moss[3]); line(im[4],39,39,41+sw,35,moss[2])
 elseif name=="sandstone_rock" then
  stone(im,16,39,13,10,warm,3); stone(im,28,39,20,15,warm,8); stone(im,39,39,7,7,warm,1)
  line(im[4],22,31,27,30,warm[2]); line(im[4],27,30,32,31,warm[2]); line(im[4],23,35,34,34,warm[4]); px(im[4],18,38,warm[3])
 elseif name=="basalt_rock" then
  stone(im,13,39,11,10,dark,9); stone(im,24,39,18,17,dark,5); stone(im,36,39,14,12,dark,6)
  line(im[4],23,29,25,31,dark[1]); line(im[4],25,31,24,34,dark[1]); growth(im[4],12,37,0,false)
 end
 return im
end
local source=root .. "/assets/sprites/source/ecology/ground_cover.aseprite"
local s=assert(app.open(source))
local tags={pebble_cluster=true,granite_boulder=true,mossy_boulder=true,sandstone_rock=true,basalt_rock=true}
for _,tag in ipairs(s.tags) do if tags[tag.name] then
 for frame=tag.fromFrame.frameNumber,tag.toFrame.frameNumber do
  local images=paint(tag.name,frame-tag.fromFrame.frameNumber)
  for layer,im in ipairs(images) do s.layers[layer]:cel(frame).image=im end
 end
end end
s:saveAs(source); s:close()
dofile(root .. "/tools/export_ground_cover_aseprite.lua")
print("ASEPRITE_REFERENCE_ROCKS five compact stone groups, fine cracks and low moss edging")
dofile(root .. "/tools/refine_ground_rocks_closeup_aseprite.lua")
