local root=assert(app.params.root)
local total=0
for _,name in ipairs({"chair","table","ladder","wood_background","fireplace"}) do
 local s=assert(app.open(root.."/assets/sprites/source/housing/"..name..".aseprite"));assert(#s.layers==3)
 local sheet=Image{fromFile=root.."/assets/sprites/housing/"..name..".png"};assert(sheet.width==s.width*#s.frames and sheet.height==s.height)
 for i=1,#s.frames do local im=Image(s.width,s.height,ColorMode.RGB);im:drawSprite(s,i)
  for y=0,s.height-1 do for x=0,s.width-1 do local pix=im:getPixel(x,y);assert(pix==sheet:getPixel((i-1)*s.width+x,y));local a=app.pixelColor.rgbaA(pix);assert(a==0 or a==255);total=total+1 end end
 end
 if name=="fireplace" then assert(#s.frames==5 and #s.tags==2) end
 s:close()
end
print("HOUSING_ART_VERIFIED sprites=5 frames=12 pixels="..total)
