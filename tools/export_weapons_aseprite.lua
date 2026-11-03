local root=assert(app.params.root)
app.fs.makeAllDirectories(root.."/assets/sprites/weapons")
for _,name in ipairs({"bows","arrows","arrow_icons"}) do
 local s=assert(app.open(root.."/assets/sprites/source/weapons/"..name..".aseprite"))
 local columns=name=="bows" and 3 or 1;local rows=math.ceil(#s.frames/columns)
 local sheet=Image(s.width*columns,s.height*rows,ColorMode.RGB)
 for i=1,#s.frames do local im=Image(s.width,s.height,ColorMode.RGB);im:drawSprite(s,i);sheet:drawImage(im,Point((i-1)%columns*s.width,math.floor((i-1)/columns)*s.height)) end
 sheet:saveAs(root.."/assets/sprites/weapons/"..name..".png")
 local tag_data={};for _,t in ipairs(s.tags) do table.insert(tag_data,string.format('{"name":"%s","from":%d,"to":%d}',t.name,t.fromFrame.frameNumber-1,t.toFrame.frameNumber-1)) end
 local f=assert(io.open(root.."/assets/sprites/weapons/"..name..".json","w"));f:write(string.format('{"frame_width":%d,"frame_height":%d,"columns":%d,"rows":%d,"pivot":[%d,%d],"tags":[%s]}',s.width,s.height,columns,rows,name=="bows" and 19 or (name=="arrows" and 29 or 16),s.height/2,table.concat(tag_data,",")));f:close();s:close()
end
print("WEAPONS_EXPORTED")
