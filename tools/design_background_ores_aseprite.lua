local root=assert(app.params.root)
local function c(h) return app.pixelColor.rgba(tonumber(h:sub(1,2),16),tonumber(h:sub(3,4),16),tonumber(h:sub(5,6),16),255) end
local function pixel(im,x,y,h) if x>=0 and x<im.width and y>=0 and y<im.height then im:drawPixel(x,y,c(h)) end end
local s=Sprite(16,16,ColorMode.RGB);s.layers[1].name="Recessed stone fracture";s:newLayer().name="Mineral faces and highlights"
local palettes={{"454750","83848a","b3adb4"},{"704634","bd8058","ecc195"},{"555963","9caab3","e0d9cc"},{"7a5c30","c6a14c","f6dd88"},{"614879","a77bd1","e4baff"},{"3a737b","6cb9c8","c4f6ec"}}
for ore=1,6 do for variant=0,2 do
 local frame=(ore-1)*3+variant+1;if frame>1 then s:newEmptyFrame() end
 local base,vein=Image(16,16),Image(16,16)
 local pal=palettes[ore]
 for n=0,3 do
  local x=2+(n*5+variant*3)%11;local y=2+(n*3+variant*5)%11
  for yy=-1,3 do for xx=-1,3 do if xx*xx+yy*yy<13 then pixel(base,x+xx,y+yy,"41434c") end end end
  for yy=0,2 do for xx=0,2 do pixel(vein,x+xx,y+yy,yy==2 and pal[1] or pal[2]) end end
  pixel(vein,x,y,pal[3]);pixel(vein,x+1,y,pal[3]);pixel(vein,x+2,y+2,pal[1])
  for k=0,3 do pixel(base,x-k,y+k,"4d5059") end
 end
 if frame==1 then s.layers[1]:cel(1).image=base else s:newCel(s.layers[1],frame,base,Point(0,0)) end
 s:newCel(s.layers[2],frame,vein,Point(0,0))
end end
for i,name in ipairs({"coal","copper","iron","gold","crystal","diamond"}) do s:newTag((i-1)*3+1,i*3).name=name end
s:saveAs(root.."/assets/sprites/source/underground/background_ores.aseprite");s:close()
local tool=Sprite(32,40,ColorMode.RGB);tool.layers[1].name="Ash handle and leather grip";tool:newLayer().name="Steel pick and adze";tool:newLayer().name="Edge highlights"
local shaft,head,edge=Image(32,40),Image(32,40),Image(32,40)
for y=10,36 do for x=15,17 do pixel(shaft,x,y,x==15 and "775437" or (x==16 and "bb9260" or "5a4440")) end end
for y=27,33 do if y%3==0 then for x=15,17 do pixel(edge,x,y,"dbc19a") end end end
for x=3,28 do local y=7+math.floor((x-15)^2/45)
 for yy=y,y+3 do pixel(head,x,yy,yy==y and "bacdd0" or "526973") end
 pixel(edge,x,y,"e4e5d6")
end
for y=9,15 do for x=24,28 do pixel(head,x,y,x==24 and "a5bec6" or "526973") end end
for x=13,19 do for y=6,12 do pixel(head,x,y,x<16 and "a8b7bb" or "738c96") end end
for i,im in ipairs({shaft,head,edge}) do if i==1 then tool.layers[1]:cel(1).image=im else tool:newCel(tool.layers[i],1,im,Point(0,0)) end end
tool:newTag(1,1).name="mattock_grip_16_32"
tool:saveAs(root.."/assets/sprites/source/underground/mattock.aseprite");tool:close()
dofile(root.."/tools/export_background_ores_aseprite.lua")
print("BACKGROUND_ORE_ART_AUTHORED")
