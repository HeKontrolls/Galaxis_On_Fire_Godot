local root=assert(app.params.root)
app.fs.makeAllDirectories(root.."/assets/sprites/farming")
for _,name in ipairs({"crops","farm_items","soil"}) do
 local s=assert(app.open(root.."/assets/sprites/source/farming/"..name..".aseprite"))
 local columns=name=="crops" and 3 or #s.frames
 local rows=math.ceil(#s.frames/columns)
 local sheet=Image(s.width*columns,s.height*rows,ColorMode.RGB)
 for i=1,#s.frames do local im=Image(s.width,s.height,ColorMode.RGB);im:drawSprite(s,i);sheet:drawImage(im,Point((i-1)%columns*s.width,math.floor((i-1)/columns)*s.height)) end
 sheet:saveAs(root.."/assets/sprites/farming/"..name..".png")
 local tags={};for _,t in ipairs(s.tags) do table.insert(tags,string.format('{"name":"%s","from":%d,"to":%d}',t.name,t.fromFrame.frameNumber-1,t.toFrame.frameNumber-1)) end
 local f=assert(io.open(root.."/assets/sprites/farming/"..name..".json","w"));f:write(string.format('{"frame_width":%d,"frame_height":%d,"columns":%d,"frames":%d,"pivot":[%d,%d],"tags":[%s]}',s.width,s.height,columns,#s.frames,s.width/2,s.height,table.concat(tags,",")));f:close();s:close()
end
print("FARMING_EXPORTED")
