local root=assert(app.params.root)
local pixels=0
for _,name in ipairs({"wood_spear","copper_spear","iron_spear","iron_dagger","iron_warhammer","crystal_blade"}) do
 local s=assert(app.open(root.."/assets/sprites/source/weapons/"..name..".aseprite"))
 assert(#s.layers==3 and #s.frames==1 and #s.tags==1)
 local exported=Image{fromFile=root.."/assets/sprites/weapons/"..name..".png"}
 local flat=Image(s.width,s.height,ColorMode.RGB);flat:drawSprite(s,1)
 assert(exported.width==s.width and exported.height==s.height)
 local painted=0
 for y=0,s.height-1 do for x=0,s.width-1 do
  local px=flat:getPixel(x,y);assert(px==exported:getPixel(x,y))
  local alpha=app.pixelColor.rgbaA(px);assert(alpha==0 or alpha==255)
  if alpha>0 then painted=painted+1 end
  pixels=pixels+1
 end end
 assert(painted>60 and app.pixelColor.rgbaA(flat:getPixel(0,0))==0)
 s:close()
end
local f=assert(io.open(root.."/.godot/melee_art_verified.txt","w"));f:write("PASS six layered Aseprite sources; "..pixels.." pixels match exports; binary alpha and animation tags verified\n");f:close()
