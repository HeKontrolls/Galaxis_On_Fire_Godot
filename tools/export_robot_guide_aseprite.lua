local root=assert(app.params.root)
local s=assert(app.open(root.."/assets/sprites/source/expedition/robot_guide.aseprite"))
local out=root.."/assets/sprites/redesigned/"
local animations={}
for _,tag in ipairs(s.tags) do
 local path=out.."robot_guide/"..tag.name:gsub("_","/").."/"; app.fs.makeAllDirectories(path)
 local durations={}; local count=0
 for index=tag.fromFrame.frameNumber,tag.toFrame.frameNumber do
  local image=Image(s.width,s.height,ColorMode.RGB); image:drawSprite(s,index); image:saveAs(path..string.format("frame_%03d.png",count))
  durations[#durations+1]=tostring(s.frames[index].duration); count=count+1
 end
 animations[#animations+1]='{"name":"'..tag.name..'","count":'..count..',"durations":['..table.concat(durations,",")..']}'
end
local f=assert(io.open(out.."robot_guide.json","w")); f:write('{"animations":['..table.concat(animations,",")..']}'); f:close(); s:close()
print("ROBOT_GUIDE_EXPORTED frames=12")
