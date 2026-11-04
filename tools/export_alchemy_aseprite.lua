local root=assert(app.params.root)
for _,file in ipairs(app.fs.listFiles(root.."/assets/sprites/source/alchemy"))do
 if app.fs.fileExtension(file)=="aseprite" then
  local s=assert(app.open(root.."/assets/sprites/source/alchemy/"..file));local sheet=Image(s.width*#s.frames,s.height,ColorMode.RGB)
  for frame=1,#s.frames do local im=Image(s.width,s.height,ColorMode.RGB);im:drawSprite(s,frame);sheet:drawImage(im,Point((frame-1)*s.width,0))end
  local name=app.fs.fileTitle(file);sheet:saveAs(root.."/assets/sprites/alchemy/"..name..".png")
  local f=assert(io.open(root.."/assets/sprites/alchemy/"..name..".json","w"));f:write(string.format('{"frame_width":%d,"frame_height":%d,"frames":%d,"pivot":[%d,%d],"grip":[%d,%d],"tags":["idle"%s]}',s.width,s.height,#s.frames,s.width/2,s.height,s.width/2,s.height-11,#s.frames>1 and ',"'..s.tags[2].name..'"' or ''));f:close();s:close()
 end
end
print("ALCHEMY_EXPORTED")
