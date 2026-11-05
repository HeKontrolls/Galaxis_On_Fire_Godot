local root=assert(app.params.root);local pixels=0;local sources=0
local src=root.."/assets/sprites/source/equipment/";local out=root.."/assets/sprites/equipment/"
for _,material in ipairs({"fiber","copper","iron"}) do for _,model in ipairs({"male","female"}) do
 local s=assert(app.open(src..material.."_"..model..".aseprite"));assert(#s.layers==6 and #s.frames==38 and #s.tags==6);sources=sources+1
 for part_index,part in ipairs({"head","chest","boots"}) do
  local exported=Image{fromFile=out..material.."_"..model.."_"..part..".png"};assert(exported.width==320 and exported.height==160)
  for index,layer in ipairs(s.layers) do layer.isVisible=math.ceil(index/2)==part_index end
  for frame=1,38 do
   local flat=Image(32,40,ColorMode.RGB);flat:drawSprite(s,frame);local painted=0
   for y=0,39 do for x=0,31 do
    local pixel=flat:getPixel(x,y);assert(pixel==exported:getPixel((frame-1)%10*32+x,math.floor((frame-1)/10)*40+y))
    local a=app.pixelColor.rgbaA(pixel);assert(a==0 or a==255);if a>0 then painted=painted+1 end;pixels=pixels+1
   end end
   assert(painted>20)
  end
 end
 s:close()
end end
for _,file in ipairs(app.fs.listFiles(src)) do
 if file:match("%.aseprite$") and not file:match("_male") and not file:match("_female") then
  local s=assert(app.open(src..file));assert(#s.tags>=1 and #s.layers>=2);local flat=Image(s.width,s.height,ColorMode.RGB);flat:drawSprite(s,1)
  local exported=Image{fromFile=out..file:gsub("%.aseprite$",".png")}
  for y=0,s.height-1 do for x=0,s.width-1 do assert(flat:getPixel(x,y)==exported:getPixel(x,y));pixels=pixels+1 end end
  sources=sources+1;s:close()
 end
end
local f=assert(io.open(root.."/.godot/equipment_art_verified.txt","w"));f:write("PASS "..sources.." native Aseprite sources, "..pixels.." matching pixels; six armor animations per model and tier\n");f:close()
