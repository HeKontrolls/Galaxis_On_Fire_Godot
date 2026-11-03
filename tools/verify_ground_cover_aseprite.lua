local root=assert(app.params.root)
local s=assert(app.open(root .. "/assets/sprites/source/ecology/ground_cover.aseprite"))
assert(s.width==48 and s.height==40 and #s.layers==4 and #s.tags==10 and #s.frames==28,"Ground-cover document structure differs")
local count=0
for _,tag in ipairs(s.tags) do
 for index=tag.fromFrame.frameNumber,tag.toFrame.frameNumber do
  local native=Image(48,40,ColorMode.RGB); native:drawSprite(s,index)
  local exported=Image{fromFile=root .. "/assets/sprites/ground_cover/" .. tag.name .. string.format("_%02d.png",index-tag.fromFrame.frameNumber)}
  for y=0,39 do for x=0,47 do local a=native:getPixel(x,y); local b=exported:getPixel(x,y)
   if app.pixelColor.rgbaA(a)>0 or app.pixelColor.rgbaA(b)>0 then assert(a==b,"Ground-cover export differs: " .. tag.name) end
  end end
  count=count+1
 end
end
s:close()
print("ASEPRITE_COVER_VERIFIED species=10 frames=" .. count .. " layers=4 matching_visible_pixels=true")
