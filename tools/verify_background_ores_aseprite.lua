local root=assert(app.params.root)
local count=0
for _,name in ipairs({"background_ores","mattock"}) do
 local s=assert(app.open(root.."/assets/sprites/source/underground/"..name..".aseprite"))
 assert(#s.frames==(name=="mattock" and 1 or 18));assert(#s.layers==(name=="mattock" and 3 or 2))
 local sheet=Image{fromFile=root.."/assets/sprites/underground/"..name..".png"}
 for i=1,#s.frames do local im=Image(s.width,s.height,ColorMode.RGB);im:drawSprite(s,i)
  local ox=name=="mattock" and 0 or ((i-1)%3)*16;local oy=name=="mattock" and 0 or math.floor((i-1)/3)*16
  for y=0,s.height-1 do for x=0,s.width-1 do local p=im:getPixel(x,y);assert(p==sheet:getPixel(ox+x,oy+y));local alpha=app.pixelColor.rgbaA(p);assert(alpha==0 or alpha==255);count=count+1 end end
 end
 s:close()
end
print("BACKGROUND_ORE_ART_VERIFIED frames=19 pixels="..count)
