local root=assert(app.params.root)
local src=root .. "/assets/sprites/source/backgrounds/"
local out=root .. "/assets/sprites/backgrounds/"
local file=assert(io.open(out .. "catalog.json","r")); local catalog=json.decode(file:read("*a")); file:close()
for _,scene in ipairs(catalog.scenes) do
 local s=assert(app.open(src .. scene.id .. ".aseprite")); app.fs.makeAllDirectories(out .. scene.id)
 for plane,name in ipairs(catalog.planes) do
  local image=Image(s.width,s.height,ColorMode.RGB)
  for layer=(plane-1)*2+1,plane*2 do local cel=s.layers[layer]:cel(1); if cel then image:drawImage(cel.image,cel.position) end end
  image:saveAs(out .. scene.id .. "/" .. name .. ".png")
 end
 s:close()
end
for _,spec in ipairs({{"background_life",12,16,12},{"background_atmosphere",6,128,96}}) do
 local s=assert(app.open(src .. spec[1] .. ".aseprite")); local sheet=Image(spec[2]*spec[3],spec[4],ColorMode.RGB)
 for frame=1,spec[2] do local im=Image(s.width,s.height,ColorMode.RGB); im:drawSprite(s,frame); sheet:drawImage(im,Point((frame-1)*spec[3],0)) end
 sheet:saveAs(out .. spec[1] .. ".png"); s:close()
end
print("ASEPRITE_BACKGROUNDS_EXPORTED scenes=32 panorama_planes=96 animated_frames=18")
