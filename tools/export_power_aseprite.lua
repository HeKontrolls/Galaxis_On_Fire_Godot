local root=assert(app.params.root)
for _,file in ipairs(app.fs.listFiles(root.."/assets/sprites/source/power")) do
 if app.fs.fileExtension(file)=="aseprite" then
  local s=assert(app.open(root.."/assets/sprites/source/power/"..file));local sheet=Image(s.width*#s.frames,s.height,ColorMode.RGB)
  for i=1,#s.frames do local im=Image(s.width,s.height,ColorMode.RGB);im:drawSprite(s,i);sheet:drawImage(im,Point((i-1)*s.width,0))end
  local name=app.fs.fileTitle(file);sheet:saveAs(root.."/assets/sprites/power/"..name..".png")
  local f=assert(io.open(root.."/assets/sprites/power/"..name..".json","w"));f:write(string.format('{"frame_width":%d,"frame_height":%d,"frames":%d,"pivot":[%d,%d],"tags":["off"%s]}',s.width,s.height,#s.frames,s.width/2,s.height,#s.frames==4 and ',"online","fault"' or ''));f:close();s:close()
 end
end
print("POWER_EXPORTED")
