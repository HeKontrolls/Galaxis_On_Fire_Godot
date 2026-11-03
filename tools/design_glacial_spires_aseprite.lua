local root=assert(app.params.root)
local source=root .. "/assets/sprites/source/expansion/"
local function rgba(hex) return app.pixelColor.rgba(tonumber(hex:sub(1,2),16),tonumber(hex:sub(3,4),16),tonumber(hex:sub(5,6),16),255) end
local function pixel(im,x,y,c) x=math.floor(x); y=math.floor(y); if x>=0 and x<im.width and y>=0 and y<im.height then im:drawPixel(x,y,rgba(c)) end end
local function line(im,x,y,xx,yy,c)
 local steps=math.max(math.abs(xx-x),math.abs(yy-y)); for i=0,steps do local t=steps==0 and 0 or i/steps; pixel(im,math.floor(x+(xx-x)*t+.5),math.floor(y+(yy-y)*t+.5),c) end
end
local function triangle(im,a,b,c,color)
 for y=0,im.height-1 do for x=0,im.width-1 do
  local function side(p,q) return (x-p[1])*(q[2]-p[2])-(y-p[2])*(q[1]-p[1]) end
  local d,e,f=side(a,b),side(b,c),side(c,a)
  if not ((d<0 or e<0 or f<0) and (d>0 or e>0 or f>0)) then pixel(im,x,y,color) end
 end end
end
local function layers(s,names) for i,name in ipairs(names) do local layer=i==1 and s.layers[1] or s:newLayer(); layer.name=name end end
local body=Sprite(128,256,ColorMode.RGB)
layers(body,{"Deep glacier body","Long crystal planes","Fractures and splinters","Frost and glints"})
local images={Image(128,256),Image(128,256),Image(128,256),Image(128,256)}
for y=0,255 do for x=0,127 do
 pixel(images[1],x,y,"5d96b3")
 local phase=(x+y*.25)%64
 local c=phase<7 and "b3dfe7" or (phase<16 and "91c8d9" or (phase<34 and "6baec8" or (phase<47 and "4a7e9f" or "659fbb")))
 pixel(images[2],x,y,c)
 local grain=(x*71+y*137+x*y*13)%173
 if grain==0 then pixel(images[4],x,y,"a7d4df") elseif grain==7 and phase>34 then pixel(images[3],x,y,"5888a4") end
end end
for _,crack in ipairs({{11,27,28,39,34,57},{74,61,65,77,83,89},{104,118,87,134,92,149},{27,170,46,182,39,199},{101,212,81,226,86,244}}) do
 line(images[3],crack[1],crack[2],crack[3],crack[4],"355d7e")
 line(images[3],crack[3],crack[4],crack[5],crack[6],"456f8e")
 line(images[4],crack[1],crack[2]-1,crack[3]-1,crack[4]-1,"b6dee7")
 line(images[3],crack[3],crack[4],crack[3]+10,crack[4]+2,"4e7a98")
end
for _,spot in ipairs({{22,16},{78,105},{119,161},{42,217},{11,245}}) do
 pixel(images[4],spot[1],spot[2],"eff9f5"); line(images[4],spot[1]-1,spot[2]+1,spot[1]+1,spot[2]+1,"cbeaf0")
end
for i,im in ipairs(images) do body:newCel(body.layers[i],1,im,Point(0,0)) end
body:newTag(1,1).name="glacial_body"
body:saveAs(source .. "glacial_spires.aseprite"); body:close()

local edges=Sprite(16,16,ColorMode.RGB)
layers(edges,{"Silhouette","Crystal face","Frost edge"})
local names={"needle_tip","left_tip","right_tip","flat_top","left_edge","right_edge"}
for i,name in ipairs(names) do
 if i>1 then edges:newEmptyFrame(i) end
 local im={Image(16,16),Image(16,16),Image(16,16)}
 if i<=3 then
  local apex=i==1 and 8 or (i==2 and 15 or 0)
  triangle(im[1],{apex,0},{0,15},{15,15},"78b9cd")
  triangle(im[2],{apex,0},{math.floor((apex+15)/2),15},{15,15},"4f87a7")
  line(im[3],apex,0,0,15,"c3e9ec"); pixel(im[3],apex,0,"f1fcf7")
  line(im[3],apex,1,15,15,"8cc8d8")
 elseif i==4 then
  line(im[3],0,0,15,0,"d4eef1"); for x=1,15,4 do pixel(im[2],x,1,"a7d8e3") end
 elseif i==5 then
  line(im[3],0,0,0,15,"bfe4eb"); line(im[2],1,0,1,15,"91c9d8"); pixel(im[3],2,7,"e4f5f2")
 else
  line(im[1],15,0,15,15,"335e80"); line(im[2],14,0,14,15,"6baac3"); pixel(im[3],13,10,"aedce4")
 end
 for layer,image in ipairs(im) do edges:newCel(edges.layers[layer],i,image,Point(0,0)) end
end
for i,name in ipairs(names) do edges:newTag(i,i).name=name end
edges:saveAs(source .. "glacial_edges.aseprite"); edges:close()
dofile(root .. "/tools/export_glacial_spires_aseprite.lua")
