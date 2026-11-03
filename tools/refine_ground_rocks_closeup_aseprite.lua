-- Close-up reference pass: overlapping grey chunks, deep seams and vivid
-- ground vegetation. All raster work uses the running Aseprite Lua API.
local root=assert(app.params.root)
local function C(s) return app.pixelColor.rgba(tonumber(s:sub(1,2),16),tonumber(s:sub(3,4),16),tonumber(s:sub(5,6),16),255) end
local function px(im,x,y,c) x=math.floor(x); y=math.floor(y); if x>=0 and x<48 and y>=0 and y<40 then im:drawPixel(x,y,c) end end
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
local gray={C("26392f"),C("46554a"),C("707b6c"),C("9da58e"),C("c5cbb5")}
local dark={C("273431"),C("414d48"),C("626f67"),C("929d8c"),C("b7c2a8")}
local warm={C("514736"),C("7d6d4d"),C("a38f64"),C("c8b184"),C("e0cd9c")}
local moss={C("124a2c"),C("1c7939"),C("38aa46"),C("76cf58"),C("a8db7a")}
local function piece(im,outline,face,light,shadow,p)
 poly(im[1],outline,p[1]); poly(im[2],face,p[3]); poly(im[3],light,p[4]); if shadow then poly(im[3],shadow,p[2]) end
 -- Short broken highlights suggest chipped stone rather than polished planes.
 for i=2,#light-1,2 do local a=light[i]; px(im[4],a[1],a[2],p[5]); if i%4==0 then px(im[4],a[1]+1,a[2],p[4]) end end
end
local function mat(im,x,y,side,sw)
 -- Irregular emerald moss follows a stone lip, then trails into a crevice.
 line(im,x-3,y+1,x+3,y,moss[1]); line(im,x-2,y,x+2,y-1,moss[2]); line(im,x-1,y-1,x+2,y-2,moss[3])
 px(im,x,y-3,moss[4]); px(im,x+1+sw,y-2,moss[4]); px(im,x-2,y-1,moss[4]); px(im,x+3,y,moss[2])
 line(im,x+side*2,y,x+side*3,y+3,moss[2]); px(im,x+side*3,y+3,moss[3])
end
local function grass(im,x,y,side,sw)
 line(im,x,y,x+side*2+sw,y-5,moss[1]); line(im,x,y-1,x+side*2+sw,y-4,moss[3]); px(im,x+side*2+sw,y-5,moss[4])
 line(im,x+1,y,x+side*4+sw,y-2,moss[2]); px(im,x+side*4+sw,y-3,moss[3])
end
local function low_group(im,p,small)
 if small then
  piece(im,{{12,39},{11,36},{14,33},{19,33},{21,36},{20,39}},{{13,37},{15,34},{18,34},{20,37},{18,38}},{{14,35},{16,34},{18,35},{16,37}},nil,p)
  piece(im,{{20,39},{19,35},{23,31},{28,31},{32,35},{31,39}},{{21,37},{21,35},{24,32},{28,33},{30,36},{29,38}},{{22,35},{24,33},{26,33},{26,35},{24,37}},{{27,35},{30,36},{29,38},{26,38}},p)
  return
 end
 piece(im,{{9,39},{7,35},{10,30},{14,29},{18,31},{19,37},{16,39}},{{9,35},{11,31},{14,31},{17,33},{17,37},{12,38}},{{10,34},{12,31},{15,32},{13,35}},{{15,34},{17,34},{17,37},{14,38}},p)
 piece(im,{{17,39},{14,35},{16,29},{21,26},{27,25},{31,29},{32,35},{28,39}},{{17,34},{18,30},{22,28},{26,27},{29,30},{30,34},{27,37},{20,38}},{{18,32},{21,29},{25,28},{27,30},{24,32},{22,35}},{{26,32},{29,30},{30,34},{26,37},{23,36}},p)
 piece(im,{{29,39},{28,35},{32,32},{37,33},{40,37},{38,39}},{{30,36},{33,34},{36,34},{38,37},{36,38}},{{31,35},{34,34},{35,35},{33,37}},nil,p)
 line(im[4],22,29,21,32,p[1]); line(im[4],21,32,23,34,p[2]); px(im[4],27,29,p[5])
end
local function paint(name,n)
 local im={Image(48,40),Image(48,40),Image(48,40),Image(48,40)}
 local sw=({0,1,0,-1})[n+1]
 if name=="mossy_boulder" then
  -- A taller heap of interlocking stones, as in the user's second close-up.
  piece(im,{{9,39},{7,34},{10,28},{18,27},{24,31},{25,37},{20,39}},{{10,35},{12,29},{17,29},{21,32},{22,36},{18,38}},{{12,32},{14,29},{17,30},{17,33},{14,35}},{{18,33},{21,33},{22,36},{18,38},{16,36}},gray)
  piece(im,{{10,29},{8,24},{11,20},{17,18},{22,20},{24,25},{20,30}},{{11,25},{12,21},{17,20},{20,22},{21,25},{17,28},{13,28}},{{12,23},{15,20},{18,21},{18,24},{15,26}},{{18,24},{21,24},{21,26},{17,28}},gray)
  piece(im,{{20,24},{18,19},{21,14},{27,12},{31,15},{33,20},{29,25}},{{21,20},{23,15},{27,14},{29,16},{30,20},{27,23}},{{23,17},{25,14},{28,15},{28,18},{25,20}},{{28,18},{30,18},{30,21},{27,23},{25,22}},gray)
  piece(im,{{23,37},{21,30},{26,25},{32,22},{38,25},{40,30},{37,36},{32,39}},{{24,31},{27,27},{32,24},{36,26},{37,30},{35,34},{30,36}},{{26,29},{30,25},{33,25},{33,29},{30,31}},{{33,29},{37,28},{37,31},{34,35},{30,36},{29,33}},gray)
  for i,v in ipairs({{10,25,-1},{17,20,1},{25,14,-1},{29,20,1},{35,25,1},{25,28,-1},{15,33,-1},{31,36,1},{11,38,-1}}) do mat(im[4],v[1],v[2],v[3],i%3==0 and sw or 0) end
  grass(im[4],8,39,-1,sw); grass(im[4],39,39,1,sw); grass(im[4],22,39,-1,sw)
 elseif name=="pebble_cluster" then
  low_group(im,gray,true); mat(im[4],14,36,-1,0); mat(im[4],28,35,1,0); grass(im[4],10,39,-1,0)
 else
  local p=name=="sandstone_rock" and warm or (name=="basalt_rock" and dark or gray)
  low_group(im,p,false)
  mat(im[4],13,32,-1,0); mat(im[4],27,29,1,0); mat(im[4],31,37,1,0); grass(im[4],8,39,-1,0); grass(im[4],39,39,1,0)
  if name=="sandstone_rock" then line(im[4],18,35,22,34,p[2]); line(im[4],24,33,28,32,p[4]) end
  if name=="basalt_rock" then line(im[4],23,30,24,33,p[1]); line(im[4],24,33,22,35,p[2]) end
 end
 return im
end
local source=root .. "/assets/sprites/source/ecology/ground_cover.aseprite"
local s=assert(app.open(source))
local rocks={pebble_cluster=true,granite_boulder=true,mossy_boulder=true,sandstone_rock=true,basalt_rock=true}
for _,tag in ipairs(s.tags) do if rocks[tag.name] then for index=tag.fromFrame.frameNumber,tag.toFrame.frameNumber do
 local images=paint(tag.name,index-tag.fromFrame.frameNumber)
 for layer,im in ipairs(images) do s.layers[layer]:cel(index).image=im end
end end end
s:saveAs(source); s:close()
dofile(root .. "/tools/export_ground_cover_aseprite.lua")
print("ASEPRITE_CLOSEUP_ROCKS interlocking grey chunks, dark seams, emerald moss and grass edging")
