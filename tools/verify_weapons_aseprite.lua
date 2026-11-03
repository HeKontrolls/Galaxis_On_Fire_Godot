local root=assert(app.params.root)
local pixels=0
for _,name in ipairs({"bows","arrows","arrow_icons"}) do
 local s=assert(app.open(root.."/assets/sprites/source/weapons/"..name..".aseprite"))
 local count=name=="bows" and 12 or 4
 local columns=name=="bows" and 3 or 1
 assert(#s.layers==3 and #s.frames==count and #s.tags==(name=="bows" and 16 or 4))
 local sheet=Image{fromFile=root.."/assets/sprites/weapons/"..name..".png"}
 assert(sheet.width==s.width*columns and sheet.height==s.height*math.ceil(count/columns))
 for frame=1,count do
  local im=Image(s.width,s.height,ColorMode.RGB);im:drawSprite(s,frame)
  local painted=0
  for y=0,s.height-1 do for x=0,s.width-1 do
   local px=im:getPixel(x,y);assert(px==sheet:getPixel((frame-1)%columns*s.width+x,math.floor((frame-1)/columns)*s.height+y))
   local a=app.pixelColor.rgbaA(px);assert(a==0 or a==255)
   if a==255 then painted=painted+1 end
   pixels=pixels+1
  end end
  assert(painted>20)
 end
 s:close()
end
print("WEAPONS_ART_VERIFIED native sources=3 frames=20 pixels="..pixels)
