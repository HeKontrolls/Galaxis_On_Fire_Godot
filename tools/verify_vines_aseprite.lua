local root=assert(app.params.root)
local s=assert(app.open(root.."/assets/sprites/source/ecology/hanging_vines.aseprite"))
assert(#s.layers==2 and #s.frames==3 and #s.tags==3,"Vine source structure changed")
local sheet=Image{fromFile=root.."/assets/sprites/ecology/hanging_vines.png"}
assert(sheet.width==48 and sheet.height==24)
for i=1,3 do
 local im=Image(16,24,ColorMode.RGB);im:drawSprite(s,i)
 for y=0,23 do for x=0,15 do assert(im:getPixel(x,y)==sheet:getPixel((i-1)*16+x,y),"Native vine export mismatch") end end
end
s:close();print("VINE_ART_VERIFIED styles=3 pixels=1152")
