local root=assert(app.params.root)
local pixels=0
for _,record in ipairs({{"expedition/mining_guardian",8,4,6},{"expedition/survey_core",1,3,1},{"weapons/faultline_hammer",1,3,1}}) do
 local s=assert(app.open(root.."/assets/sprites/source/"..record[1]..".aseprite"))
 local sheet=Image{fromFile=root.."/assets/sprites/"..record[1]..".png"}
 assert(#s.frames==record[2] and #s.layers==record[3] and #s.tags==record[4])
 assert(sheet.width==s.width*#s.frames and sheet.height==s.height)
 for frame=1,#s.frames do
  local im=Image(s.width,s.height,ColorMode.RGB);im:drawSprite(s,frame)
  local painted=0
  for y=0,s.height-1 do for x=0,s.width-1 do
   local px=im:getPixel(x,y);assert(px==sheet:getPixel(x+(frame-1)*s.width,y))
   local alpha=app.pixelColor.rgbaA(px);assert(alpha==0 or alpha==255)
   if alpha>0 then painted=painted+1 end
   pixels=pixels+1
  end end
  assert(painted>100 and app.pixelColor.rgbaA(im:getPixel(0,0))==0)
 end
 s:close()
end
local f=assert(io.open(root.."/.godot/guardian_art_verified.txt","w"));f:write("PASS 3 native Aseprite documents, 10 frames, "..pixels.." exact export pixels; binary transparency and animation tags verified\n");f:close()
