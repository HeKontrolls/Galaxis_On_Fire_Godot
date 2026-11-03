-- All drawing runs inside Aseprite. No exterior ink stroke, smoothing or filters.
return function(a,b,f,v,pose,pal)
 local shadow,body,light,accent,cream=table.unpack(pal)
 local eyeink="392841"
 local function rgb(h) return app.pixelColor.rgba(tonumber(h:sub(1,2),16),tonumber(h:sub(3,4),16),tonumber(h:sub(5,6),16),255) end
 local function p(im,x,y,c) x=math.floor(x);y=math.floor(y);if x>0 and x<47 and y>0 and y<39 then im:drawPixel(x,y,rgb(c)) end end
 local function box(im,x,y,w,h,c) for yy=y,y+h-1 do for xx=x,x+w-1 do p(im,xx,yy,c) end end end
 local function line(im,x,y,xx,yy,c,w) local n=math.ceil(math.max(math.abs(xx-x),math.abs(yy-y)));for i=0,n do local q=n==0 and 0 or i/n;box(im,math.floor(x+(xx-x)*q),math.floor(y+(yy-y)*q),w or 1,w or 1,c) end end
 local function poly(im,pts,c)
  for y=1,38 do local xs={};for i=1,#pts do local u,z=pts[i],pts[i%#pts+1];if (u[2]<=y and z[2]>y) or (z[2]<=y and u[2]>y) then xs[#xs+1]=u[1]+(y-u[2])*(z[1]-u[1])/(z[2]-u[2]) end end;table.sort(xs);for i=1,#xs-1,2 do for x=math.ceil(xs[i]),math.floor(xs[i+1]) do p(im,x,y,c) end end end
 end
 local function eye(x,y)
  box(b,x-1,y-1,5,4,cream)
  if pose==1 then line(b,x-1,y+1,x+3,y+1,shadow) else box(b,x+1,y,2,3,eyeink);p(b,x+1,y,cream) end
 end
 local walk=pose>=2
 local step=walk and ({-2,0,2,0})[pose-1] or 0
 local bob=walk and pose%2 or 0
 local function leg(x,y,kx,ky,fx,far)
  local c=far and shadow or body
  line(a,x,y,kx,ky,c,3);line(a,kx,ky,fx,33,c,2)
  box(a,fx-1,34,6,2,c)
  if not far then line(b,x,y,kx,ky,light);box(b,fx+1,34,3,1,cream) end
 end
 if f==1 then
  -- Torchcrest: amber biped, tall swept feather ears, cream throat, violet tail.
  poly(a,{{19,24},{10,22-step},{3,15-step},{5,25},{13,29},{23,29}},accent)
  line(b,5,20-step,12,25,light);leg(22,26,18-step,30,18-step,true)
  poly(a,{{15,22+bob},{18,15+bob},{25,13+bob},{31,18+bob},{32,26},{26,31},{19,30}},shadow)
  poly(b,{{17,22+bob},{20,16+bob},{26,15+bob},{29,19+bob},{29,26},{24,29},{19,27}},body)
  poly(b,{{26,19+bob},{31,19+bob},{30,27},{26,30},{24,26}},cream)
  leg(26,28,29+step,31,27+step,false)
  poly(a,{{24,16+bob},{21,7},{23,3+v},{28,9},{29,13},{32,6-v},{36,3},{35,15+bob},{39,18+bob},{38,23+bob},{31,25+bob},{26,22+bob}},body)
  poly(b,{{24,7},{25,5+v},{27,12},{26,15}},accent);poly(b,{{32,12},{34,6},{34,14}},accent)
  poly(b,{{27,15+bob},{31,12+bob},{35,15+bob},{36,18+bob},{29,18+bob}},light)
  poly(b,{{32,21+bob},{39,19+bob},{41,21+bob},{38,24+bob},{32,24+bob}},cream)
  eye(33,17+bob);p(b,39,21+bob,shadow)
  line(b,20,19+bob,24,21+bob,accent,2);line(b,18,23+bob,23,24+bob,accent,2)
  line(a,29,24,33,27-step,body,2);line(b,33,27-step,36,26-step,cream)
  if v==1 then poly(b,{{17,18},{13,12},{19,15},{22,18}},light) elseif v==2 then poly(b,{{28,15},{28,5},{31,8},{31,15}},light) end
 elseif f==2 then
  -- Crown conch: tall violet chambered shell on a coral, three-footed crawler.
  for j=0,2 do leg(16+j*7,29,14+j*8+step*(j%2*2-1),32,13+j*8+step*(j%2*2-1),j==0) end
  poly(a,{{10,25},{9,16},{15,8},{21,5},{23,2+v},{27,8},{32,12},{34,23},{29,30},{17,31}},shadow)
  poly(b,{{12,23},{12,16},{17,10},{23,7},{28,12},{31,18},{30,24},{25,28},{17,28}},body)
  poly(b,{{14,16},{18,11},{23,9},{27,13},{27,18},{23,22},{17,22}},light)
  poly(b,{{17,17},{20,14},{24,14},{25,17},{22,20},{19,20}},shadow)
  line(b,19,16,22,15,cream);line(b,22,15,23,17,cream)
  line(b,14,24,19,26,accent,2);line(b,22,26,28,22,accent,2)
  for j=0,2 do poly(b,{{11+j*5,14-j*2},{10+j*5,8-j*2+v},{14+j*5,10-j*2},{16+j*5,15-j*2}},cream) end
  poly(a,{{25,27},{30,22+bob},{36,22+bob},{41,26+bob},{40,31},{33,33},{25,31}},accent)
  poly(b,{{30,25+bob},{35,24+bob},{39,27+bob},{37,30},{30,30}},cream)
  line(a,34,24,34,17+bob,accent,2);eye(34,17+bob)
  line(a,39,26,43,21+bob,accent,2);box(b,42,20+bob,3,2,cream)
  line(b,36,30,39,29,shadow)
  if v==2 then poly(b,{{12,21},{5,17},{7,23},{14,26}},accent);line(b,7,19,12,23,cream) end
 elseif f==3 then
  -- Coraljaw: rose amphibian, huge pale jaw and asymmetric branching head fans.
  poly(a,{{19,24},{10,24},{5,18-step},{3,23},{7,30},{19,31}},shadow)
  poly(b,{{18,26},{10,26},{5,22-step},{8,28},{17,29}},accent)
  leg(19,27,15-step,32,13-step,true);leg(31,28,34+step,32,34+step,false)
  poly(a,{{13,25+bob},{17,18+bob},{27,17+bob},{34,19+bob},{41,23+bob},{43,28+bob},{38,32},{23,32},{16,29}},shadow)
  poly(b,{{15,25+bob},{19,20+bob},{28,19+bob},{35,21+bob},{40,24+bob},{39,28},{29,29},{19,28}},body)
  poly(b,{{26,27+bob},{41,25+bob},{41,29+bob},{36,32},{26,31}},cream)
  line(b,30,28+bob,40,27+bob,shadow)
  for j=0,2 do local x=23+j*4;local top=9+(j+v)%3*2
   line(a,x,21+bob,x-2,top,accent,2);line(b,x-1,19+bob,x-2,top,light)
   line(a,x-2,top+2,x-6,top-2,accent,2);box(b,x-6,top-2,2,2,cream)
   line(a,x-2,top+4,x+1,top+1,accent,2)
  end
  eye(36,22+bob);box(b,20,23+bob,3,2,light);box(b,24,24+bob,2,2,light)
  if v==2 then poly(b,{{9,26},{5,12},{10,16},{13,26}},body);line(b,7,16,10,24,light) end
 elseif f==4 then
  -- Veilrunner: violet kangaroo-like runner with a turquoise ribbed sail.
  poly(a,{{18,27},{10,28},{4,23-step},{3,26},{8,33},{18,32}},shadow)
  line(b,5,26,10,30,body,2)
  poly(a,{{16,25},{12,20},{14,9+v},{18,4+v},{22,8},{26,4+v},{29,9},{30,23}},accent)
  for j=0,3 do line(b,18+j*3,24,15+j*4,10+(j+v)%2*3,cream) end
  poly(a,{{17,23+bob},{23,17+bob},{29,19+bob},{31,26},{26,31},{19,31}},shadow)
  poly(b,{{18,24+bob},{24,19+bob},{28,21+bob},{29,27},{24,29},{19,28}},body)
  leg(23,28,16-step,31,20-step,true);leg(25,27,30+step,30,28+step,false)
  poly(a,{{27,22+bob},{27,14+bob},{31,10+bob},{37,11+bob},{40,16+bob},{38,20+bob},{32,23+bob}},body)
  poly(b,{{29,14+bob},{32,12+bob},{37,13+bob},{38,16+bob},{32,17+bob}},light)
  poly(b,{{32,20+bob},{39,17+bob},{41,19+bob},{36,23+bob},{30,25}},cream)
  eye(34,15+bob);line(a,29,25,34,26-step,accent,2);line(b,34,26-step,37,25-step,cream)
  if v==1 then line(a,33,12,34,5,body,2);line(b,34,5,37,4,light) elseif v==2 then poly(b,{{29,13},{26,6},{31,9}},light) end
 elseif f==5 then
  -- Kiln beetle: ivory segmented carapace, cyan vents and a forked horn.
  for j=0,2 do
   leg(15+j*7,27,10+j*8+step*(j%2*2-1),31,9+j*8+step*(j%2*2-1),j==0)
  end
  poly(a,{{8,26},{10,18+bob},{16,12+bob},{25,11+bob},{32,16+bob},{36,24},{33,30},{19,32},{11,30}},shadow)
  for j=0,2 do local x=11+j*7
   poly(b,{{x,24},{x+1,17+bob},{x+6,13+bob+j%2},{x+10,18+bob},{x+10,25},{x+5,29},{x,28}},body)
   poly(b,{{x+1,20+bob},{x+3,16+bob},{x+6,15+bob},{x+9,18+bob},{x+8,21+bob}},light)
   line(b,x+2,25,x+6,27,accent,2);line(b,x+2,25,x+5,26,cream)
  end
  poly(a,{{30,25},{35,20+bob},{41,22+bob},{43,28},{39,32},{33,30}},shadow)
  poly(b,{{33,25},{36,22+bob},{40,24+bob},{40,29},{35,29}},light)
  poly(b,{{36,23+bob},{35,13-v},{38,9-v},{40,12},{38,14},{39,22}},body)
  line(b,37,19,37,12-v,light);line(b,38,12-v,42,9-v,light,2)
  box(b,38,25,3,2,accent);p(b,39,25,cream)
  line(b,35,31,38,33,light);line(b,40,30,43,31,light)
  if v==2 then poly(b,{{14,18},{12,8},{17,12},{19,18}},light) end
 elseif f==6 then
  -- Hammerhorn: upright plum creature, broad amber shovel head, huge forearms.
  leg(20,27,18-step,31,17-step,true);leg(28,28,30+step,31,29+step,false)
  poly(a,{{17,17+bob},{25,14+bob},{31,18+bob},{33,26},{29,31},{19,30},{15,25}},shadow)
  poly(b,{{18,19+bob},{24,16+bob},{29,20+bob},{29,27},{25,29},{19,27}},body)
  poly(b,{{21,20+bob},{27,20+bob},{28,25},{24,28},{21,25}},light)
  poly(a,{{17,20+bob},{12,19+bob},{8,24-step},{7,31-step},{13,34-step},{17,29}},body)
  poly(b,{{11,24-step},{14,22},{15,27},{12,30-step},{9,29-step}},light)
  line(b,9,31-step,13,32-step,cream,2)
  poly(a,{{30,20+bob},{35,19+bob},{40,24+step},{41,32},{35,34},{31,28}},body)
  poly(b,{{35,22+bob},{38,26+step},{38,30},{35,31},{33,26}},light)
  poly(a,{{22,19+bob},{19,12+bob},{15,10+bob},{15,6+bob},{35,5+bob},{41,9+bob},{39,15+bob},{30,17+bob},{28,21}},accent)
  poly(b,{{17,7+bob},{34,6+bob},{38,9+bob},{30,11+bob},{19,10+bob}},cream)
  poly(b,{{24,13+bob},{30,12+bob},{29,19+bob},{25,21}},light)
  eye(34,11+bob);line(b,25,17+bob,29,17+bob,shadow)
  if v==1 then poly(b,{{18,9},{17,2},{21,4},{23,9}},cream) elseif v==2 then poly(b,{{31,8},{33,2},{36,3},{35,9}},cream) end
 elseif f==7 then
  -- Ruby tusker: warm-red quadruped, violet hooves, ivory brows and curled tusks.
  leg(16,27,12-step,31,11-step,true);leg(30,28,33-step,31,33-step,true)
  poly(a,{{8,25},{10,15+bob},{17,10+bob},{27,10+bob},{34,17+bob},{38,23},{37,30},{28,32},{16,31}},shadow)
  poly(b,{{10,24},{13,16+bob},{18,12+bob},{26,13+bob},{32,18+bob},{33,27},{27,29},{17,28}},body)
  for j=0,3 do poly(b,{{12+j*4,18+bob},{15+j*4,14+bob},{18+j*4,18+bob},{17+j*4,22+bob},{14+j*4,20+bob}},light) end
  leg(18,28,17+step,32,16+step,false);leg(29,28,29+step,32,28+step,false)
  poly(a,{{29,22+bob},{31,16+bob},{38,16+bob},{42,22+bob},{42,29},{37,32},{31,29}},body)
  poly(b,{{31,18+bob},{38,17+bob},{40,21+bob},{33,21+bob}},cream)
  eye(36,22+bob);box(b,40,27,3,3,accent)
  poly(b,{{34,27},{37,28},{37,33},{41,33},{43,29},{43,34},{39,36},{34,34}},cream)
  line(b,34,28,35,32,light);line(a,9,23,5,20-step,body,2)
  if v==0 then poly(b,{{18,15},{16,6},{21,9},{24,15}},cream) elseif v==1 then poly(b,{{25,15},{27,4},{30,7},{29,17}},cream) else for x=16,25,5 do poly(b,{{x,16},{x+1,7},{x+4,15}},cream) end end
 elseif f==8 then
  -- Plume strider: teal running bird, peach wing fan, antler crown, thin gold legs.
  leg(22,27,19-step,31,18-step,true);leg(27,27,30+step,31,30+step,false)
  poly(a,{{18,27},{10,26},{4,19-step},{5,15-step},{14,20},{20,19}},shadow)
  poly(b,{{7,18-step},{14,22},{20,23},{18,26},{12,24}},accent)
  poly(a,{{14,24+bob},{18,16+bob},{25,13+bob},{32,17+bob},{33,24},{28,30},{19,30}},shadow)
  poly(b,{{17,23+bob},{20,18+bob},{27,16+bob},{31,20+bob},{29,27},{23,29},{18,27}},body)
  poly(b,{{18,22+bob},{23,18+bob},{27,20+bob},{26,26},{20,28},{16,26}},accent)
  for j=0,2 do line(b,19+j*3,22+bob,18+j*3,25+bob,cream) end
  poly(a,{{28,20+bob},{29,10+bob},{34,7+bob},{39,11+bob},{38,17+bob},{33,21+bob}},body)
  poly(b,{{30,12+bob},{34,9+bob},{37,11+bob},{35,14+bob}},light)
  poly(b,{{36,14+bob},{43,15+bob},{40,19+bob},{36,18+bob}},cream)
  eye(34,12+bob)
  line(a,30,11,27,5,accent,2);line(b,28,6,29,3,cream);line(b,28,6,25,4,cream)
  line(a,35,9,37,3+v,accent,2);line(b,37,4+v,40,3+v,cream)
  if v==2 then poly(b,{{30,10},{31,2},{34,4},{34,10}},cream) end
 end
end
