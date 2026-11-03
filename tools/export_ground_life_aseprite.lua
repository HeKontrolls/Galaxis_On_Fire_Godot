local root=assert(app.params.root)
local s=assert(app.open(root .. "/assets/sprites/source/ecology/ground_life.aseprite"))
local output=root .. "/assets/sprites/ground_life/"; app.fs.makeAllDirectories(output)
local metadata=json.decode(s.data); metadata.animations={}
local sheet=Image(24*11,32*8,ColorMode.RGB)
for _,tag in ipairs(s.tags) do
  local durations={}
  for index=tag.fromFrame.frameNumber,tag.toFrame.frameNumber do
    local frame=Image(24,32,ColorMode.RGB); frame:drawSprite(s,index)
    frame:saveAs(output .. tag.name .. string.format("_%02d.png",index-tag.fromFrame.frameNumber))
    sheet:drawImage(frame,Point(((index-1)%11)*24,math.floor((index-1)/11)*32))
    table.insert(durations,s.frames[index].duration)
  end
  table.insert(metadata.animations,{name=tag.name,count=#durations,durations=durations})
end
sheet:saveAs(output .. "ground_life_sheet.png")
local f=assert(io.open(output .. "ground_life.json","w")); f:write(json.encode(metadata)); f:close()
print("ASEPRITE_ECOLOGY_EXPORT species=" .. #s.tags .. " frames=" .. #s.frames .. " layers=" .. #s.layers)
s:close()
