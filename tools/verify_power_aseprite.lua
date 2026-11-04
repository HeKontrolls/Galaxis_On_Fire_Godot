local root=assert(app.params.root)
local sources,frames,pixels=0,0,0
for _,file in ipairs(app.fs.listFiles(root.."/assets/sprites/source/power")) do
 if app.fs.fileExtension(file)=="aseprite" then
  local s=assert(app.open(root.."/assets/sprites/source/power/"..file));assert(#s.layers==3)
  assert((#s.frames==4 and #s.tags==3) or (#s.frames==1 and #s.tags==1))
  local sheet=Image{fromFile=root.."/assets/sprites/power/"..app.fs.fileTitle(file)..".png"}
  assert(sheet.width==s.width*#s.frames and sheet.height==s.height)
  for frame=1,#s.frames do
   local im=Image(s.width,s.height,ColorMode.RGB);im:drawSprite(s,frame);local painted=0
   for y=0,s.height-1 do for x=0,s.width-1 do
    local px=im:getPixel(x,y);assert(px==sheet:getPixel((frame-1)*s.width+x,y))
    local a=app.pixelColor.rgbaA(px);assert(a==0 or a==255);if a==255 then painted=painted+1 end;pixels=pixels+1
   end end
   assert(painted>8);frames=frames+1
  end
  sources=sources+1;s:close()
 end
end
assert(sources==31 and frames==109)
print("POWER_ART_VERIFIED sources="..sources.." frames="..frames.." pixels="..pixels)

if app.params.report then local f=assert(io.open(app.params.report,"w"));f:write("POWER_ART_VERIFIED sources="..sources.." frames="..frames.." pixels="..pixels);f:close()end
