local root=assert(app.params.root)
local pixels=0
for _,name in ipairs({"crops","farm_items","soil"}) do
 local s=assert(app.open(root.."/assets/sprites/source/farming/"..name..".aseprite"))
 local count=name=="soil" and 2 or 15
 assert(#s.layers==3 and #s.frames==count)
 assert(#s.tags==(name=="crops" and 5 or count))
 local columns=name=="crops" and 3 or count
 local sheet=Image{fromFile=root.."/assets/sprites/farming/"..name..".png"}
 assert(sheet.width==s.width*columns and sheet.height==s.height*math.ceil(count/columns))
 for frame=1,count do
  local im=Image(s.width,s.height,ColorMode.RGB);im:drawSprite(s,frame)
  local opaque=0
  for y=0,s.height-1 do for x=0,s.width-1 do
   local px=im:getPixel(x,y)
   assert(px==sheet:getPixel((frame-1)%columns*s.width+x,math.floor((frame-1)/columns)*s.height+y))
   local a=app.pixelColor.rgbaA(px);assert(a==0 or a==255)
   if a==255 then opaque=opaque+1 end
   pixels=pixels+1
  end end
  assert(opaque>15,"Empty farming frame")
 end
 s:close()
end
print("FARMING_ART_VERIFIED native sources=3 frames=32 pixels="..pixels)
