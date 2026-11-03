local root=assert(app.params.root)
local s=assert(app.open(root .. "/assets/sprites/source/frontier/shovels.aseprite"))
assert(#s.frames==7 and #s.layers==3 and #s.tags==7,"Shovel source structure")
for _,tag in ipairs(s.tags) do
 local rendered=Image(32,40,ColorMode.RGB); rendered:drawSprite(s,tag.fromFrame.frameNumber)
 local png=Image{fromFile=root .. "/assets/sprites/shovels/" .. tag.name .. ".png"}
 assert(not png:isEmpty() and app.pixelColor.rgbaA(png:getPixel(16,32))>0,"Shovel grip")
 for y=0,39 do for x=0,31 do local a,b=rendered:getPixel(x,y),png:getPixel(x,y); if app.pixelColor.rgbaA(a)>0 or app.pixelColor.rgbaA(b)>0 then assert(a==b,"Shovel export differs") end end end
end
print("ASEPRITE_SHOVELS_VERIFIED exports=7"); s:close()
