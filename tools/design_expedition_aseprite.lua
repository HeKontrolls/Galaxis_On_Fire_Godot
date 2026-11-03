-- Native Aseprite authoring: editable silhouettes and detail layers, tagged frames.
local root=assert(app.params.root)
local src=root.."/assets/sprites/source/expedition/"
local out=root.."/assets/sprites/expedition/"
app.fs.makeAllDirectories(src); app.fs.makeAllDirectories(out)
local function c(hex) return app.pixelColor.rgba(tonumber(hex:sub(1,2),16),tonumber(hex:sub(3,4),16),tonumber(hex:sub(5,6),16),255) end
local function p(im,x,y,col) x=math.floor(x); y=math.floor(y); if x>=0 and y>=0 and x<im.width and y<im.height then im:drawPixel(x,y,c(col)) end end
local function rect(im,x,y,w,h,col) for yy=y,y+h-1 do for xx=x,x+w-1 do p(im,xx,yy,col) end end end
local function line(im,x,y,xx,yy,col) local n=math.max(math.abs(xx-x),math.abs(yy-y)); for i=0,n do local t=n==0 and 0 or i/n; p(im,x+(xx-x)*t,y+(yy-y)*t,col) end end
local function poly(im,pts,col)
 for y=0,im.height-1 do local xs={}; for i=1,#pts do local a=pts[i]; local b=pts[i%#pts+1]; if (a[2]<=y and b[2]>y) or (b[2]<=y and a[2]>y) then xs[#xs+1]=a[1]+(y-a[2])*(b[1]-a[1])/(b[2]-a[2]) end end; table.sort(xs); for i=1,#xs-1,2 do for x=math.ceil(xs[i]),math.floor(xs[i+1]) do p(im,x,y,col) end end end
end
local function make(name,w,h,paint)
 local s=Sprite(w,h,ColorMode.RGB); s.layers[1].name="Silhouette and materials"
 local detail=s:newLayer(); detail.name="Panels, highlights and lights"
 local a=Image(w,h,ColorMode.RGB); local b=Image(w,h,ColorMode.RGB); paint(a,b)
 s.cels[1].image=a; s:newCel(detail,1,b,Point(0,0)); local tag=s:newTag(1,1); tag.name="idle"
 s:saveAs(src..name..".aseprite"); local image=Image(w,h,ColorMode.RGB); image:drawSprite(s,1); image:saveAs(out..name..".png"); s:close()
end
for _,ready in ipairs({false,true}) do
 make(ready and "ship_ready" or "ship_damaged",96,48,function(a,b)
  -- Broad lifting body, raised cockpit, winglets and two articulated landing feet.
  poly(a,{{5,28},{18,21},{22,9},{39,4},{55,8},{61,20},{83,22},{93,32},{80,38},{16,38}},"172630")
  poly(a,{{9,28},{24,23},{25,11},{39,7},{53,10},{58,23},{82,25},{88,31},{77,35},{17,35}},"6d8490")
  poly(a,{{13,27},{26,23},{58,23},{83,27},{77,30},{20,30}},"b0c5c9")
  poly(a,{{28,12},{39,9},{49,12},{53,21},{26,21}},"172f40")
  poly(b,{{30,13},{39,11},{46,13},{49,18},{28,18}},ready and "78d8df" or "4d819b")
  line(b,37,12,34,20,"c2f0e9"); line(b,39,13,37,20,"467889")
  poly(a,{{6,28},{1,36},{25,33},{32,27}},"405765"); line(b,4,34,23,29,"a6bac0")
  poly(a,{{67,25},{83,14},{88,15},{84,31}},"405765"); line(b,75,24,84,17,"afc1bf")
  rect(a,55,25,22,10,"243e4d"); rect(b,57,26,17,6,"9a704b")
  for x=59,72,3 do rect(b,x,27,1,4,ready and "f3c276" or "523f38") end
  for _,x in ipairs({22,70}) do rect(a,x,36,3,8,"253540"); rect(b,x+1,37,1,6,"b9c9c7"); rect(a,x-4,44,12,3,"1c2934"); rect(b,x-3,44,10,1,"a2b3b7") end
  line(b,33,26,49,26,"d9e2d6"); line(b,31,32,51,32,"415965")
  for _,x in ipairs({19,31,51,79}) do p(b,x,29,"f1d7a6") end
  rect(b,77,30,5,2,ready and "91dda1" or "dd7755")
  if not ready then
   poly(b,{{37,25},{45,25},{49,31},{44,34},{35,31}},"29333b")
   line(b,38,25,42,28,"e6a267"); line(b,42,28,40,31,"b18366"); line(b,41,30,47,33,"080e19")
   line(b,78,23,86,20,"c79d73"); line(b,81,23,90,25,"4f423a")
  else rect(b,37,27,9,3,"d9dfcb"); rect(b,40,27,3,3,"cf9057") end
 end)
end
make("drive_core",32,32,function(a,b)
 poly(a,{{6,26},{10,22},{23,22},{28,26},{27,31},{4,31}},"283e4d"); rect(b,7,27,18,2,"748c96")
 poly(a,{{10,4},{20,3},{26,11},{24,21},{16,26},{7,20},{6,11}},"1c3344")
 poly(a,{{11,7},{19,6},{23,12},{21,19},{16,22},{10,18},{9,12}},"3d7891")
 poly(b,{{14,8},{19,9},{21,14},{17,20},{12,17},{12,12}},"73e6d8")
 line(b,14,9,13,15,"d3ffef"); line(b,18,12,18,17,"b6ffdc")
 for _,y in ipairs({7,20}) do rect(b,7,y,4,3,"bb8c54"); rect(b,21,y,4,3,"bb8c54") end
end)
make("hull_plate",24,24,function(a,b)
 poly(a,{{4,3},{17,2},{22,8},{20,20},{5,22},{1,15}},"263b48")
 poly(a,{{5,5},{16,4},{19,8},{17,18},{6,19},{4,14}},"78949e")
 line(b,6,6,15,5,"d1dfda"); line(b,6,8,6,16,"b2c9cb"); line(b,8,16,16,15,"435d6a")
 for _,q in ipairs({{5,6},{16,7},{7,17},{16,17}}) do p(b,q[1],q[2],"efc588") end
end)
make("drive_coil",24,24,function(a,b)
 rect(a,3,6,18,14,"213b4a"); rect(a,5,4,14,15,"567786"); rect(b,7,3,10,3,"b5cac8")
 for y=7,17,3 do rect(b,4,y,16,2,"cc8c50"); rect(b,6,y,10,1,"f1c47b"); rect(b,17,y,2,2,"855b3d") end
 rect(b,9,6,3,12,"86dacf"); rect(a,6,20,3,3,"405b66"); rect(a,15,20,3,3,"405b66")
end)
make("sentinel",32,32,function(a,b)
 for _,x in ipairs({2,24}) do poly(a,{{x,19},{x+6,17},{x+7,25},{x+4,30},{x-1,30}},"23313b"); line(b,x+2,21,x+3,27,"b58a62") end
 poly(a,{{4,9},{11,4},{23,5},{29,13},{28,23},{21,28},{8,27},{3,20}},"20323f")
 poly(a,{{7,10},{12,7},{21,8},{26,14},{25,21},{20,25},{10,23},{6,18}},"647b83")
 poly(b,{{8,11},{13,8},{19,9},{13,13},{8,19}},"a5b4ad")
 rect(b,9,14,15,5,"172835"); rect(b,11,15,11,2,"f0b35e"); rect(b,15,15,3,3,"ffebaa")
 line(b,12,21,20,22,"3a505d"); rect(b,14,24,7,1,"c9a46f")
 line(a,10,6,6,1,"293e49"); p(b,6,1,"80d6ce")
end)
print("EXPEDITION_ASEPRITE_AUTHORED documents=6 exports=6")
dofile(root.."/tools/design_escape_pod_aseprite.lua")
