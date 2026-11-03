local root=assert(app.params.root)
local s=assert(app.open(root.."/assets/sprites/source/housing/door.aseprite"))
assert(#s.layers==3 and #s.frames==4 and #s.tags==4)
for _,tag in ipairs(s.tags) do if tag.name=="closing" then assert(tag.aniDir==AniDir.REVERSE) end end
local sheet=Image{fromFile=root.."/assets/sprites/housing/door.png"};assert(sheet.width==128 and sheet.height==48)
for frame=1,4 do local im=Image(32,48,ColorMode.RGB);im:drawSprite(s,frame)
 for y=0,47 do for x=0,31 do local p=im:getPixel(x,y);assert(p==sheet:getPixel((frame-1)*32+x,y));local a=app.pixelColor.rgbaA(p);assert(a==0 or a==255) end end
end
s:close();print("DOOR_ART_VERIFIED frames=4 pixels=6144")
