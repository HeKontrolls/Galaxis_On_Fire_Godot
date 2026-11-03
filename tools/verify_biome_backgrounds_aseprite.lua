local root=assert(app.params.root)
local integrity=dofile(root .. "/tools/biome_background_integrity.lua")
local src=root .. "/assets/sprites/source/backgrounds/"; local out=root .. "/assets/sprites/backgrounds/"
local f=assert(io.open(out .. "catalog.json","r")); local catalog=json.decode(f:read("*a")); f:close()
assert(#catalog.scenes==32 and #catalog.planes==3)
local pixels=0
for index,scene in ipairs(catalog.scenes) do
 assert(scene.climate==(index-1)//4 and scene.biome==(index-1)%4)
 local s=assert(app.open(src .. scene.id .. ".aseprite")); assert(#s.layers==6 and #s.frames==1 and #s.tags==1)
 for plane,name in ipairs(catalog.planes) do
  local image=Image(s.width,s.height,ColorMode.RGB)
  local shape,detail=Image(s.width,s.height,ColorMode.RGB),Image(s.width,s.height,ColorMode.RGB)
  local a,b=s.layers[plane*2-1]:cel(1),s.layers[plane*2]:cel(1)
  shape:drawImage(a.image,a.position); detail:drawImage(b.image,b.position)
  assert(integrity.foundation(shape,false)==0,"Floating landform/gap below mountain: " .. scene.id .. "/" .. name)
  assert(integrity.orphans(shape,detail,false)==0,"Detached scenery: " .. scene.id .. "/" .. name)
  for layer=(plane-1)*2+1,plane*2 do local cel=s.layers[layer]:cel(1); image:drawImage(cel.image,cel.position) end
  local png=Image{fromFile=out .. scene.id .. "/" .. name .. ".png"}; assert(png.width==640 and png.height==256 and not png:isEmpty())
  for y=0,255 do
   assert(image:getPixel(0,y)==image:getPixel(639,y),"Panorama seam " .. scene.id)
   for x=0,639 do local a,b=image:getPixel(x,y),png:getPixel(x,y)
    if app.pixelColor.rgbaA(a)>0 or app.pixelColor.rgbaA(b)>0 then assert(a==b,"Aseprite background export mismatch " .. scene.id) end
    pixels=pixels+1
   end
  end
  assert(app.pixelColor.rgbaA(png:getPixel(320,0))==0,"Backgrounds preserve the open sky")
  local footing=png:getPixel(0,255)
  assert(app.pixelColor.rgbaA(footing)==255,"Opaque panorama footing: " .. scene.id)
  for y=248,255 do for x=0,639 do assert(png:getPixel(x,y)==footing,"Panorama footing must extend without stripes: " .. scene.id) end end
 end
 s:close()
end
for _,spec in ipairs({{"background_life",12,16,12},{"background_atmosphere",6,128,96}}) do
 local s=assert(app.open(src .. spec[1] .. ".aseprite")); local png=Image{fromFile=out .. spec[1] .. ".png"}
 assert(#s.layers==2 and #s.frames==spec[2])
 for frame=1,spec[2] do local im=Image(s.width,s.height,ColorMode.RGB); im:drawSprite(s,frame); assert(not im:isEmpty())
  for y=0,s.height-1 do for x=0,s.width-1 do
   local a,b=im:getPixel(x,y),png:getPixel(x+(frame-1)*spec[3],y)
   if app.pixelColor.rgbaA(a)>0 or app.pixelColor.rgbaA(b)>0 then assert(a==b,"Ambient native frame mismatch") end
   pixels=pixels+1
  end end
 end
 s:close()
end
print("ASEPRITE_BACKGROUNDS_VERIFIED documents=34 seamless_planes=96 animated_frames=18 matching_pixels=" .. pixels)
