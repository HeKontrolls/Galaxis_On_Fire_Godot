local root=assert(app.params.root)
local count=0
for _,spec in ipairs({{"underground_ores","ores"},{"advanced_pickaxes","tools"},{"advanced_materials","materials"},{"glacial_ice","ice"},{"glacial_facets","ice_faces"},{"desert_flora","desert_life"}}) do
 local s=assert(app.open(root .. "/assets/sprites/source/expansion/" .. spec[1] .. ".aseprite"))
 assert(#s.layers>=3,"Editable layers required")
 for _,tag in ipairs(s.tags) do
  for frame=tag.fromFrame.frameNumber,tag.toFrame.frameNumber do
   local source=Image(s.width,s.height,ColorMode.RGB); source:drawSprite(s,frame)
   local path=root .. "/assets/sprites/expansion/" .. spec[2] .. "/" .. tag.name .. string.format("_%02d.png",frame-tag.fromFrame.frameNumber)
   local png=Image{fromFile=path}; assert(not png:isEmpty(),path)
   local offset=s.height-png.height
   for y=0,offset-1 do for x=0,s.width-1 do assert(app.pixelColor.rgbaA(source:getPixel(x,y))==0,"Cropped opaque pixel: " .. path) end end
   for y=0,png.height-1 do for x=0,png.width-1 do
    local a,b=source:getPixel(x,y+offset),png:getPixel(x,y)
    if app.pixelColor.rgbaA(a)>0 or app.pixelColor.rgbaA(b)>0 then assert(a==b,"Export differs: " .. path) end
   end end
   count=count+1
  end
 end
 s:close()
end
print("EXPANSION_ASEPRITE_VERIFIED documents=6 exports=" .. count)
