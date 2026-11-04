local root=assert(app.params.root)
for _,file in ipairs(app.fs.listFiles(root.."/assets/sprites/source/magic"))do
 if app.fs.fileExtension(file)=="aseprite" then
  local s=assert(app.open(root.."/assets/sprites/source/magic/"..file));local sheet=Image(s.width*#s.frames,s.height,ColorMode.RGB)
  for frame=1,#s.frames do local im=Image(s.width,s.height,ColorMode.RGB);im:drawSprite(s,frame);sheet:drawImage(im,Point((frame-1)*s.width,0))end
  local name=app.fs.fileTitle(file);sheet:saveAs(root.."/assets/sprites/magic/"..name..".png")
  local f=assert(io.open(root.."/assets/sprites/magic/"..name..".json","w"));f:write(string.format('{"frame_width":%d,"frame_height":%d,"frames":%d,"tags":["idle","%s"],"grip":[%d,%d]}',s.width,s.height,#s.frames,#s.frames==3 and "cast" or "loop",s.width/2,#s.frames==3 and s.height-11 or s.height/2));f:close();s:close()
 end
end
print("MAGIC_EXPORTED")
