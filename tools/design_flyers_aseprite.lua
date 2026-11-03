local root=assert(app.params.root)
local src=root.."/assets/sprites/source/monsters/";app.fs.makeAllDirectories(src)
local palettes={{"29452c","598440","a2b963"},{"30544f","60957b","b4c591"},{"354c65","658d9d","b8d0c4"},{"60452c","a77a42","d9b570"},{"3e3033","775046","bd8356"},{"45434b","7c7b80","b6b8a6"},{"335767","6ba0ab","c1e0d1"},{"4a3d45","806579","b8a092"}}
local function rgba(h) return app.pixelColor.rgba(tonumber(h:sub(1,2),16),tonumber(h:sub(3,4),16),tonumber(h:sub(5,6),16),255) end
for family=0,7 do
 local s=Sprite(64,48,ColorMode.RGB);s.layers[1].name="Wings and silhouette";local body=s:newLayer();body.name="Body, markings and eyes";local texture=s:newLayer();texture.name="Pixel material clusters"
 for morph=0,2 do for pose=0,5 do
  local index=morph*6+pose+1;if index>1 then s:newEmptyFrame() end
  local a,b,t=Image(64,48,ColorMode.RGB),Image(64,48,ColorMode.RGB),Image(64,48,ColorMode.RGB)
  local pal=palettes[family+1];local dark,mid,light=pal[1],pal[2],pal[3]
  local flap=({-10,-6,1,9,1,-6})[pose+1]
  local function p(im,x,y,c) x=math.floor(x);y=math.floor(y);if x>0 and x<63 and y>0 and y<47 then im:drawPixel(x,y,rgba(c)) end end
  local function box(im,x,y,w,h,c) for yy=y,y+h-1 do for xx=x,x+w-1 do p(im,xx,yy,c) end end end
  local function line(im,x,y,xx,yy,c) local n=math.max(math.abs(xx-x),math.abs(yy-y));for i=0,n do local q=n==0 and 0 or i/n;p(im,x+(xx-x)*q,y+(yy-y)*q,c) end end
  local function poly(im,pts,c)
   for y=1,46 do local xs={};for i=1,#pts do local aa,bb=pts[i],pts[i%#pts+1];if (aa[2]<=y and bb[2]>y) or (bb[2]<=y and aa[2]>y) then xs[#xs+1]=aa[1]+(y-aa[2])*(bb[1]-aa[1])/(bb[2]-aa[2]) end end;table.sort(xs);for i=1,#xs-1,2 do for x=math.ceil(xs[i]),math.floor(xs[i+1]) do p(im,x,y,c) end end end
  end
  if family==0 then
   poly(a,{{31,24},{24,15+flap},{11,10+flap/2},{8,15+flap/2},{12,20+flap/2},{10,24},{20,28},{28,28}},dark)
   poly(a,{{30,23},{23,16+flap},{12,12+flap/2},{11,16+flap/2},{15,21+flap/2},{13,23},{22,26}},mid)
   poly(a,{{29,25},{16,25},{10,34-flap/2},{17,38-flap/2},{27,32},{33,27}},mid)
   for _,q in ipairs({{18,19+flap/2},{19,31-flap/3}}) do box(b,q[1]-2,q[2]-2,6,5,light);box(b,q[1],q[2]-1,3,3,dark) end
   line(b,29,24,14,14+flap/2,light);line(b,28,26,16,35-flap/2,light)
  elseif family==1 or family==3 then
   for side=-1,1,2 do
    local yy=20+side*(5+flap/2)
    poly(a,{{31,24},{11,yy-3},{5,yy},{12,yy+3},{30,26}},dark)
    poly(a,{{31,24},{13,yy-1},{8,yy},{15,yy+2},{30,25}},mid)
    line(b,30,24,9,yy,light)
    poly(a,{{33,23},{45,yy-4},{54,yy-2},{48,yy+2},{33,25}},mid);line(b,34,24,50,yy-1,light)
   end
   if family==1 then line(b,11,26,29,25,mid);line(b,13,27,28,26,light)
   else poly(b,{{14,28},{24,19},{32,21},{33,28},{25,32}},mid);for x=19,29,4 do line(b,x,23,x+2,29,dark) end;poly(b,{{14,28},{9,32},{19,30}},light) end
  elseif family==2 then
   poly(a,{{39,23},{28,14},{8,12+flap},{17,25},{7,35-flap/2},{29,32},{42,28}},dark)
   poly(a,{{37,24},{27,17},{12,15+flap},{21,25},{12,33-flap/2},{28,29},{40,27}},mid)
   line(b,36,25,15,17+flap,light);line(b,34,27,15,31-flap/2,light)
   line(b,25,26,4,29+morph,mid);line(b,4,29+morph,3,35+morph,light)
  elseif family==5 then
   for side=-1,1,2 do
    local yy=24+side*(9+flap/2)
    poly(a,{{31,24},{17,yy},{8,yy-side*5},{13,yy+side*6},{27,27}},dark)
    poly(b,{{29,24},{18,yy},{11,yy-side*2},{16,yy+side*3}},mid)
    line(b,13,yy,25,24,light)
    poly(a,{{34,25},{46,yy},{52,yy-side*6},{49,yy+side*4},{36,27}},mid)
   end
  elseif family==6 then
   for side=-1,1,2 do
    for j=0,2 do local x=11+j*6;local yy=24+side*(14-j*3+flap/2);poly(a,{{31,24},{x,yy},{x+4,yy+side*(5+morph)},{28,28}},dark);poly(b,{{30,24},{x+2,yy+side},{x+4,yy+side*3},{28,27}},mid);line(b,x+2,yy+side,29,25,light) end
   end
  else
   -- Scalloped membranous wings; lava forms are shorter and plated.
   local span=family==4 and 3 or 0
   for side=-1,1,2 do
    local yy=24+side*(13+flap/2)
    poly(a,{{32,25},{24,yy},{7+span,yy-side*3},{12+span,yy+side*5},{16,yy+side*2},{20,27+side*5},{25,26+side*3},{30,28}},dark)
    poly(a,{{30,25},{23,yy+side*2},{10+span,yy},{16,yy+side},{20,26+side*4},{27,27}},mid)
    line(b,30,25,10+span,yy,light);line(b,30,25,20,yy+side*5,light)
   end
  end
  -- A compact body stays aligned to the existing combat box.
  poly(b,{{24,23},{28,19},{36,20},{42,23},{44,27},{38,30},{28,29}},dark)
  poly(b,{{27,23},{30,21},{36,22},{41,24},{41,26},{36,28},{29,27}},mid)
  line(b,29,22,36,23,light)
  if family==4 then for x=28,36,4 do line(b,x,25,x+2,27,"dd773f");p(b,x+1,26,"f5b467") end end
  if family==5 or family==6 then poly(b,{{29,22},{32,16-morph},{36,22}},light) end
  if family==0 or family==1 or family==3 then
   line(b,38,22,41,16-morph,mid);line(b,41,16-morph,45,15-morph,light)
   line(b,32,28,29,33,mid);line(b,36,28,36,33,mid)
  elseif family==7 then poly(b,{{35,23},{34,15-morph},{39,19},{41,23}},mid);poly(b,{{41,27},{43,29},{40,30}},light) end
  box(b,39,24,2,1,family==4 and "f6be67" or "d9cc8c")
  if morph==1 then for x=17,29,4 do box(b,x,24+(x%3),2,1,light) end
  elseif morph==2 then line(b,29,21,27,15,mid);line(b,27,15,24,13,light) end
  -- Opaque clustered grain, clipped to native material pixels.
  for y=2,45 do for x=2,61 do
   local c=b:getPixel(x,y);if app.pixelColor.rgbaA(c)==0 then c=a:getPixel(x,y) end
   if c==rgba(mid) or c==rgba(light) then
    local h=(math.floor(x/2)*17+math.floor(y/2)*11+family*7+morph*3)%19
    if h<4 then p(t,x,y,dark) elseif h<7 and y%2==0 then p(t,x,y,light) end
   end
  end end
  if index==1 then s.layers[1]:cel(1).image=a else s:newCel(s.layers[1],index,a,Point(0,0)) end
  s:newCel(body,index,b,Point(0,0));s:newCel(texture,index,t,Point(0,0));s.frames[index].duration=0.12
 end end
 for morph=0,2 do s:newTag(morph*6+1,morph*6+6).name="morph_"..morph.."_fly" end
 s:saveAs(src.."flying_"..family..".aseprite");s:close()
end
dofile(root.."/tools/export_flyers_aseprite.lua")
