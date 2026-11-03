local root=assert(app.params.root)
local s=assert(app.open(root .. "/assets/sprites/source/ecology/ground_cover.aseprite"))
local output=root .. "/assets/sprites/ground_cover/"; app.fs.makeAllDirectories(output)
local metadata=json.decode(s.data); metadata.animations={}
local columns=7; local sheet=Image(s.width*columns,s.height*math.ceil(#s.frames/columns),ColorMode.RGB)
for _,tag in ipairs(s.tags) do
 local durations={}
 for index=tag.fromFrame.frameNumber,tag.toFrame.frameNumber do
  local im=Image(s.width,s.height,ColorMode.RGB); im:drawSprite(s,index)
  im:saveAs(output .. tag.name .. string.format("_%02d.png",index-tag.fromFrame.frameNumber))
  sheet:drawImage(im,Point(((index-1)%columns)*s.width,math.floor((index-1)/columns)*s.height))
  table.insert(durations,s.frames[index].duration)
 end
 table.insert(metadata.animations,{name=tag.name,count=#durations,durations=durations})
end
sheet:saveAs(output .. "ground_cover_sheet.png")
local f=assert(io.open(output .. "ground_cover.json","w")); f:write(json.encode(metadata)); f:close()
print("ASEPRITE_COVER_EXPORT species=" .. #s.tags .. " frames=" .. #s.frames .. " layers=" .. #s.layers)
s:close()
