local root=assert(app.params.root)
local s=assert(app.open(root .. "/assets/sprites/source/ecology/ground_life.aseprite"))
assert(s.width==24 and s.height==32 and #s.frames==88 and #s.layers==3 and #s.tags==22,"Ecology document structure differs")
local count=0
for _,tag in ipairs(s.tags) do
  assert(tag.toFrame.frameNumber-tag.fromFrame.frameNumber==3,"Each species requires four animation frames")
  for index=tag.fromFrame.frameNumber,tag.toFrame.frameNumber do
    local native=Image(24,32,ColorMode.RGB); native:drawSprite(s,index)
    local exported=Image{fromFile=root .. "/assets/sprites/ground_life/" .. tag.name .. string.format("_%02d.png",index-tag.fromFrame.frameNumber)}
    for y=0,31 do for x=0,23 do local a=native:getPixel(x,y); local b=exported:getPixel(x,y)
      if app.pixelColor.rgbaA(a)>0 or app.pixelColor.rgbaA(b)>0 then assert(a==b,"Export differs: " .. tag.name) end
    end end
    count=count+1
  end
end
s:close()
print("ASEPRITE_ECOLOGY_VERIFIED species=22 frames=" .. count .. " layers=3 matching_visible_pixels=true")
