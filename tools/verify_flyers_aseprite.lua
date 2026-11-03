local root=assert(app.params.root)
local count=0
for family=0,7 do
 local s=assert(app.open(root.."/assets/sprites/source/monsters/flying_"..family..".aseprite"))
 assert(#s.layers==3 and #s.frames==18 and #s.tags==3)
 local sheet=Image{fromFile=root.."/assets/sprites/monsters/flying_"..family..".png"}
 assert(sheet.width==384 and sheet.height==144)
 for i=1,18 do
  local im=Image(64,48,ColorMode.RGB);im:drawSprite(s,i)
  for y=0,47 do for x=0,63 do
   local pixel=im:getPixel(x,y);local alpha=app.pixelColor.rgbaA(pixel)
   assert(pixel==sheet:getPixel(((i-1)%6)*64+x,math.floor((i-1)/6)*48+y),"Flyer export mismatch")
   assert(alpha==0 or alpha==255,"Soft sprite edge")
   assert(pixel~=app.pixelColor.rgba(23,33,43,255),"Black stroke")
   if x==0 or x==63 or y==0 or y==47 then assert(alpha==0,"Clipped wing") end
   count=count+1
  end end
 end
 s:close()
end
print("FLYER_ART_VERIFIED frames=144 pixels="..count)
