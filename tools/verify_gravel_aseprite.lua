local root=assert(app.params.root)
local s=assert(app.open(root.."/assets/sprites/source/terrain/gravel.aseprite"))
assert(#s.frames==4 and #s.layers==2 and #s.tags==1)
local sheet=Image{fromFile=root.."/assets/sprites/terrain/gravel.png"}
assert(sheet.width==64 and sheet.height==16)
for i=1,4 do local im=Image(16,16,ColorMode.RGB);im:drawSprite(s,i)
 for y=0,15 do for x=0,15 do assert(im:getPixel(x,y)==sheet:getPixel((i-1)*16+x,y));assert(app.pixelColor.rgbaA(im:getPixel(x,y))==255) end end
end
s:close();print("GRAVEL_VERIFIED frames=4 pixels=1024")
