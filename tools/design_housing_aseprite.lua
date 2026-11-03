-- Native Aseprite furnishing set, drawn at the existing 16-pixel block scale.
local root=assert(app.params.root)
app.fs.makeAllDirectories(root.."/assets/sprites/source/housing")
local function rgba(h) return app.pixelColor.rgba(tonumber(h:sub(1,2),16),tonumber(h:sub(3,4),16),tonumber(h:sub(5,6),16),255) end
local function paint(w,h)
 local im=Image(w,h,ColorMode.RGB)
 local function p(x,y,c) x=math.floor(x);y=math.floor(y);if x>=0 and x<w and y>=0 and y<h then im:drawPixel(x,y,rgba(c)) end end
 local function box(x,y,ww,hh,c) for yy=y,y+hh-1 do for xx=x,x+ww-1 do p(xx,yy,c) end end end
 local function line(x,y,xx,yy,c) local n=math.max(math.abs(xx-x),math.abs(yy-y));for i=0,n do local t=n==0 and 0 or i/n;p(x+(xx-x)*t,y+(yy-y)*t,c) end end
 return im,p,box,line
end
local function sprite(name,w,h,frames,tags,draw)
 local s=Sprite(w,h,ColorMode.RGB);s.layers[1].name="Structure and silhouette";s:newLayer().name="Material facets and fittings";s:newLayer().name="Flame and fine highlights"
 for frame=1,frames do
  if frame>1 then s:newEmptyFrame() end
  for layer=1,3 do
   local im,p,box,line=paint(w,h);draw(frame,layer,p,box,line)
   if frame==1 and layer==1 then s.layers[1]:cel(1).image=im else s:newCel(s.layers[layer],frame,im,Point(0,0)) end
  end
  s.frames[frame].duration=0.16
 end
 for _,tag in ipairs(tags) do s:newTag(tag[2],tag[3]).name=tag[1] end
 s:saveAs(root.."/assets/sprites/source/housing/"..name..".aseprite");s:close()
end
sprite("chair",16,32,1,{{"placed",1,1}},function(frame,layer,p,box,line)
 if layer==1 then
  box(2,2,3,28,"593e34");box(11,18,3,13,"593e34");box(3,3,10,3,"815637")
  box(3,7,9,11,"684936");box(1,18,14,4,"815637");box(4,23,8,2,"815637")
 elseif layer==2 then
  box(3,2,2,16,"b78b54");box(5,4,6,2,"d1a669");box(5,8,5,7,"416575");box(6,9,4,5,"76949a")
  box(2,18,12,2,"c29a61");box(2,17,12,2,"4e7983");box(3,17,10,1,"a8bdb0")
  line(3,23,3,30,"ae7f4d");line(12,23,12,30,"ae7f4d");box(5,23,6,1,"bc8c50")
 else
  p(3,4,"e5c78d");p(3,20,"e5c78d");p(12,20,"e5c78d");line(5,11,5,14,"9db7b0");p(10,14,"253d50")
 end
end)
sprite("table",48,32,1,{{"placed",1,1}},function(frame,layer,p,box,line)
 if layer==1 then
  box(1,8,46,6,"644334");box(6,14,4,17,"684834");box(38,14,4,17,"684834")
  box(8,22,32,3,"684834");box(4,30,8,2,"684834");box(36,30,8,2,"684834")
 elseif layer==2 then
  box(2,8,44,2,"c09a63");box(3,10,42,2,"966e47");line(3,9,43,9,"e1bd7e")
  line(7,15,7,29,"bf935a");line(39,15,39,29,"b78b54");line(10,22,37,22,"aa7f4e")
  for x=7,39,8 do p(x,12,"d8bc80");p(x,13,"4d3c34") end
  box(27,9,10,5,"376071");box(28,9,8,2,"79a0a5");line(27,13,36,13,"b7bda1")
  box(9,5,11,3,"566c58");line(9,5,18,5,"b9c6a2");box(10,7,10,1,"e0c49b")
 else
  line(15,10,22,10,"78513c");line(30,11,34,11,"c39b60");p(7,26,"e3c285");p(39,25,"d1ae70")
  box(11,6,7,1,"d2d3af");p(18,5,"4b534d")
 end
end)
sprite("ladder",16,16,1,{{"segment",1,1}},function(frame,layer,p,box,line)
 if layer==1 then box(2,0,3,16,"5b4034");box(11,0,3,16,"5b4034");box(4,3,8,3,"765139");box(4,11,8,3,"765139")
 elseif layer==2 then line(3,0,3,15,"b78c53");line(12,0,12,15,"b78c53");line(4,3,11,3,"dec18b");line(4,11,11,11,"dec18b");line(5,4,10,4,"a97a47");line(5,12,10,12,"a97a47")
 else for _,y in ipairs({4,12}) do p(3,y,"d3c3a1");p(12,y,"d3c3a1") end end
end)
sprite("wood_background",16,16,4,{{"plank_variants",1,4}},function(frame,layer,p,box,line)
 if layer==1 then box(0,0,16,16,"624537");box(0,1,16,6,"7c583f");box(0,9,16,6,"74503d")
 elseif layer==2 then
  line(0,0,15,0,"a17a50");line(0,8,15,8,"97704b");line(0,6,15,6,"684837");line(0,14,15,14,"634433")
  local seam=(frame*5)%15;line(seam,1,seam,6,"513b32");local other=(seam+8)%16;line(other,9,other,14,"503a31")
  line((frame*3)%8+2,3,(frame*3)%8+6,3,"8a6244");line(4,12,9,12,"845d42")
 else p((frame*5+2)%15,2,"ba9768");p((frame*5+10)%15,10,"b28e60");p(8,4,"624536");p(9,5,"976f49") end
end)
sprite("fireplace",48,48,5,{{"unlit",1,1},{"burning",2,5}},function(frame,layer,p,box,line)
 if layer==1 then
  box(15,1,18,12,"54515b");box(6,12,36,5,"6f6971");box(7,17,34,26,"55515c");box(2,43,44,5,"615c66")
  box(14,25,20,18,"302c34");box(17,21,14,7,"302c34");box(20,19,8,7,"302c34")
 elseif layer==2 then
  for _,r in ipairs({{16,2,8,4},{25,2,7,4},{16,7,6,4},{23,7,9,4},{8,18,7,5},{8,24,5,7},{8,32,5,9},{33,18,6,6},{35,25,4,7},{35,33,4,8},{15,18,5,3},{28,18,5,3},{14,22,3,4},{31,22,3,4},{4,44,12,3},{17,44,13,3},{31,44,12,3}}) do
   box(r[1],r[2],r[3],r[4],"827b82");line(r[1],r[2],r[1]+r[3]-1,r[2],"b0a6a0");p(r[1]+1,r[2]+2,"696571")
  end
  box(5,12,38,3,"99908f");line(6,12,41,12,"d2bfa6");line(3,43,44,43,"b6a599")
  box(16,38,15,3,"78513b");line(17,38,29,38,"bc8250");box(19,36,14,2,"644331");p(31,38,"c09460")
 elseif frame>1 then
  local phase=frame-2
  for x=17,31 do
   local height=4+((x*5+phase*3)%11);if x<19 or x>29 then height=3+phase%2 end
   for y=37-height,38 do
    local col=y>35 and "ffdb87" or (y>32 and "fda24c" or "db6233")
    if y>37-height+1 or x%3~=0 then p(x,y,col) end
   end
   if x%4==phase then p(x,39,"f6c65c") end
  end
  line(16,42,31,42,"be784d");p(14,31+phase,"b18b68");p(33,34-phase,"b18b68");p(23+phase,22-phase,"e79b55")
 end
end)
dofile(root.."/tools/export_housing_aseprite.lua")
print("HOUSING_AUTHORED sprites=5 frames=12")
