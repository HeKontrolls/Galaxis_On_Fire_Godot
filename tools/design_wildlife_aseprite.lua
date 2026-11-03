local root=assert(app.params.root)
local src=root.."/assets/sprites/source/monsters/";app.fs.makeAllDirectories(src)
local palettes={
 {"3e713f","72a14f","c9d981","799d54","2e4238"}, {"3a777c","639e9d","b8dbcc","f0e6b0","2d414c"},
 {"826c45","b69862","e4ce93","ebb564","4f4936"}, {"547f97","87b6c8","e0eee0","b6d5f3","364f63"},
 {"7c4643","b1664d","e0a570","ffca6a","422f33"}, {"725886","a27cad","dcc6dd","93d2d5","43394e"},
 {"485852","7a8980","bcc3a2","86a59f","303d40"}, {"71626d","a49b9b","d9c9af","9fa7ab","453f4b"},
 {"6c5466","8f748e","bbadad","bca082","403746"}}
local function rgba(h) return app.pixelColor.rgba(tonumber(h:sub(1,2),16),tonumber(h:sub(3,4),16),tonumber(h:sub(5,6),16),255) end
for family=0,8 do
 local s=Sprite(48,40,ColorMode.RGB);s.layers[1].name="Gel, shell and wing anatomy"
 local details=s:newLayer();details.name="Organs, facets, eyes and limbs"
 local grain=s:newLayer();grain.name="Opaque pixel clusters"
 for morph=0,1 do for pose=0,7 do
  local index=morph*8+pose+1;if index>1 then s:newEmptyFrame() end
  local a,b,t=Image(48,40,ColorMode.RGB),Image(48,40,ColorMode.RGB),Image(48,40,ColorMode.RGB)
  local pal=palettes[family+1];local dark,mid,light,accent,ink=pal[1],pal[2],pal[3],pal[4],pal[5]
  local function p(im,x,y,c) x=math.floor(x);y=math.floor(y);if x>0 and x<47 and y>0 and y<39 then im:drawPixel(x,y,rgba(c)) end end
  local function box(im,x,y,w,h,c) for yy=y,y+h-1 do for xx=x,x+w-1 do p(im,xx,yy,c) end end end
  local function line(im,x,y,xx,yy,c) local n=math.max(math.abs(xx-x),math.abs(yy-y));for i=0,n do local q=n==0 and 0 or i/n;p(im,x+(xx-x)*q,y+(yy-y)*q,c) end end
  local function poly(im,pts,c)
   for y=1,38 do local xs={};for i=1,#pts do local u,v=pts[i],pts[i%#pts+1];if (u[2]<=y and v[2]>y) or (v[2]<=y and u[2]>y) then xs[#xs+1]=u[1]+(y-u[2])*(v[1]-u[1])/(v[2]-u[2]) end end;table.sort(xs);for i=1,#xs-1,2 do for x=math.ceil(xs[i]),math.floor(xs[i+1]) do p(im,x,y,c) end end end
  end
  local function oval(im,cx,cy,rx,ry,c)
   for y=math.floor(cy-ry),math.ceil(cy+ry) do for x=math.floor(cx-rx),math.ceil(cx+rx) do if ((x-cx)/rx)^2+((y-cy)/ry)^2<=1 then p(im,x,y,c) end end end
  end
  if family<6 then
   local rx,top=12+morph,19-morph
   if pose==2 or pose==5 then rx=15;top=25 elseif pose==3 then rx=9;top=11 elseif pose==4 then rx=11;top=16 elseif pose==7 then rx=13;top=21 end
   local cy=(top+35)/2;local ry=(35-top)/2
   -- Scalloped gel silhouette, with layered refraction rather than an ink border.
   oval(a,24,cy,rx,ry,dark);oval(a,23,cy-1,rx-1,ry-1,mid)
   for x=24-rx+2,24+rx-2 do if x%5~=0 then box(a,x,33,2,3,dark) end end
   line(b,18,top+3,22,top+1,light);line(b,17,top+5,17,top+7,light);box(b,20,top+3,2,2,light)
   local core_y=math.floor(cy+1)
   poly(b,{{21,core_y-3},{26,core_y-4},{30,core_y},{27,core_y+4},{22,core_y+3},{20,core_y}},accent)
   line(b,22,core_y-2,26,core_y-3,light);line(b,22,core_y+2,27,core_y+3,dark)
   for j=0,3 do local x=16+j*4;local yy=math.floor(cy)+j%2*3;box(b,x,yy,2,1,dark) end
   if family==0 then
    line(b,23,core_y+2,25,core_y-3,dark);poly(b,{{24,core_y-1},{19,core_y-4},{20,core_y-1},{24,core_y+1}},dark)
    if morph==1 then poly(b,{{27,top+1},{29,top-4},{33,top-2},{31,top+2}},mid);line(b,28,top,31,top-2,light) end
   elseif family==1 then
    for _,v in ipairs({{18,core_y+2},{28,top+3},{33,core_y+3}}) do oval(b,v[1],v[2],2,2,light);p(b,v[1],v[2],mid) end
    line(b,17,32,21,33,light);line(b,26,33,30,32,light)
   elseif family==2 then
    for j=0,10 do box(b,15+(j*7)%19,math.floor(cy)-2+(j*3)%7,1+j%2,1,j%3==0 and light or dark) end
    if morph==1 then poly(b,{{19,top+3},{20,top-2},{23,top},{25,top+4}},accent) end
   elseif family==3 or family==5 then
    for j=0,2 do local x=18+j*5;local height=4+(j+morph)%3*2
     poly(b,{{x,top+5},{x+1,top-height},{x+4,top-1},{x+3,top+7}},accent)
     line(b,x+1,top-height+1,x+1,top+3,light);line(b,x+3,top,x+3,top+6,dark)
    end
   elseif family==4 then
    line(b,18,core_y-3,22,core_y,accent);line(b,22,core_y,20,core_y+4,accent)
    line(b,28,core_y-3,30,core_y,accent);line(b,30,core_y,29,core_y+4,light)
    box(b,24,top+3,2,1,accent)
   end
   local eye_y=math.max(top+7,math.floor(cy)-1)
   if pose==1 then line(b,29,eye_y+1,32,eye_y+1,ink)
   else box(b,29,eye_y,2,3,ink);p(b,29,eye_y,light) end
   line(b,32,eye_y+5,33,eye_y+5,dark)
  elseif family==6 then
   local step=(pose%2==0 and -2 or 2)
   for side=-1,1,2 do for j=0,2 do
    local x=17+j*6;local foot=x+step*(j%2==0 and 1 or -1)
    line(a,x,27,x+side*4,31,dark);line(a,x+side*4,31,foot+side*5,35,mid);line(b,foot+side*5,35,foot+side*7,35,light)
   end end
   poly(a,{{12,27},{15,20},{23,17},{30,19},{35,25},{34,31},{28,34},{18,33}},dark)
   poly(b,{{15,26},{18,21},{24,19},{30,22},{32,27},{29,31},{20,31}},mid)
   line(b,24,20,25,31,dark);line(b,19,21,17,27,light);line(b,27,21,30,25,accent)
   for y=23,29,3 do line(b,18,y,22,y+1,accent);line(b,27,y,30,y+1,light) end
   poly(b,{{31,26},{36,25},{40,28},{39,31},{33,32}},dark);box(b,35,27,2,1,accent)
   line(b,38,29,42,28,mid);line(b,42,28,43,31,light);line(b,38,31,41,34,mid)
   if morph==1 then poly(b,{{28,21},{30,14},{33,17},{32,24}},mid);line(b,30,15,31,20,light) end
  elseif family==7 then
   local bend=(pose%2==0 and -2 or 2)
   for j=0,3 do
    local x=17+j*5
    for side=-1,1,2 do local knee=x+side*(7+j%2);local yy=25+j%2*2
     line(a,x,yy,knee,yy-5+j%2,dark);line(b,knee,yy-5+j%2,knee+side*3+bend,35-j%2,mid);p(b,knee+side*3+bend,35-j%2,light)
    end
   end
   poly(a,{{10,25},{13,18},{21,16},{28,20},{29,28},{23,32},{15,31}},dark)
   poly(b,{{13,24},{16,20},{22,19},{26,23},{24,28},{17,29}},mid)
   for j=0,2 do poly(b,{{15+j*3,22},{17+j*3,20},{19+j*3,25},{17+j*3,27}},light) end
   oval(b,32,26,6,5,mid);line(b,30,23,34,23,light)
   box(b,35,24,2,2,ink);p(b,35,24,accent);p(b,32,24,accent)
   line(b,36,29,39,32,dark);line(b,39,32,38,34,light)
   if morph==1 then line(b,14,20,11,15,mid);line(b,11,15,14,14,light) end
  else
   local flap=({-7,-3,2,7,10,5,0,-4})[pose+1]
   for side=-1,1,2 do
    local tip=24+side*19;local yy=20+flap
    poly(a,{{24,25},{24+side*8,17+flap/2},{tip,yy},{tip-side*3,yy+8},{tip-side*7,yy+5},{24+side*8,31},{24,29}},dark)
    poly(b,{{24,25},{24+side*8,19+flap/2},{tip-side*2,yy+2},{tip-side*7,yy+4},{24+side*7,29}},mid)
    line(b,24,25,tip-side*2,yy+2,light);line(b,24,26,24+side*8,29,accent)
   end
   poly(b,{{20,23},{21,16-morph},{24,20},{28,16},{29,25},{27,31},{22,31}},mid)
   line(b,22,21,22,17,light);box(b,25,24,2,1,accent);line(b,23,29,25,30,light)
   line(b,23,31,21,34,dark);line(b,26,31,28,33,dark)
  end
  -- Deliberate two-pixel clusters; transparency is always binary.
  for y=2,37 do for x=2,45 do
   local c=b:getPixel(x,y);if app.pixelColor.rgbaA(c)==0 then c=a:getPixel(x,y) end
   if c==rgba(mid) then local h=(math.floor(x/2)*13+math.floor(y/2)*7+family*5+morph*3)%23
    if h<3 then p(t,x,y,dark) elseif h==7 then p(t,x,y,light) end
   end
  end end
  if index==1 then s.layers[1]:cel(1).image=a else s:newCel(s.layers[1],index,a,Point(0,0)) end
  s:newCel(details,index,b,Point(0,0));s:newCel(grain,index,t,Point(0,0));s.frames[index].duration=0.12
 end end
 for morph=0,1 do local base=morph*8
  if family==8 then s:newTag(base+1,base+8).name="morph_"..morph.."_fly"
  else for _,tag in ipairs({{"idle",1,2},{"windup",3,3},{"jump",4,4},{"fall",5,5},{"land",6,6},{"walk",7,8}}) do s:newTag(base+tag[2],base+tag[3]).name="morph_"..morph.."_"..tag[1] end end
 end
 s:saveAs(src.."wildlife_"..family..".aseprite");s:close()
end
dofile(root.."/tools/export_wildlife_aseprite.lua")
