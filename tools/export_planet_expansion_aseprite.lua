local root=assert(app.params.root)
for _,spec in ipairs({{"underground_ores","ores"},{"advanced_pickaxes","tools"},{"advanced_materials","materials"},{"glacial_ice","ice"},{"glacial_facets","ice_faces"},{"desert_flora","desert_life"}}) do
 local s=assert(app.open(root .. "/assets/sprites/source/expansion/" .. spec[1] .. ".aseprite")); local data=json.decode(s.data)
 local out=root .. "/assets/sprites/expansion/" .. spec[2] .. "/"; app.fs.makeAllDirectories(out)
 local metadata={version=1,animations={}}
 for index,tag in ipairs(s.tags) do
  local height=s.height; local rendered={}; local top=s.height-1
  for frame=tag.fromFrame.frameNumber,tag.toFrame.frameNumber do
   local full=Image(s.width,s.height,ColorMode.RGB); full:drawSprite(s,frame); rendered[frame]=full
   if spec[1]=="desert_flora" then for y=0,s.height-1 do for x=0,s.width-1 do if app.pixelColor.rgbaA(full:getPixel(x,y))>0 then top=math.min(top,y) end end end end
  end
  if spec[1]=="desert_flora" then height=s.height-math.max(0,top-1) end
  local entry={name=tag.name,count=tag.toFrame.frameNumber-tag.fromFrame.frameNumber+1,durations={},canvas={s.width,height}}
  for frame=tag.fromFrame.frameNumber,tag.toFrame.frameNumber do
   local full=rendered[frame]
   -- Native Aseprite crops transparent headroom; every species keeps its ground pivot.
   local image=Image(s.width,height,ColorMode.RGB); image:drawImage(full,Point(0,height-s.height))
   image:saveAs(out .. tag.name .. string.format("_%02d.png",frame-tag.fromFrame.frameNumber))
   table.insert(entry.durations,s.frames[frame].duration)
  end
  table.insert(metadata.animations,entry)
 end
 local file=assert(io.open(out .. "atlas.json","w")); file:write(json.encode(metadata)); file:close()
 print("EXPANSION_EXPORTED " .. spec[1] .. " frames=" .. #s.frames .. " tags=" .. #s.tags); s:close()
end
local ice=assert(app.open(root .. "/assets/sprites/source/expansion/glacial_ice.aseprite"))
local sheet=Image(64,16,ColorMode.RGB)
for frame=1,4 do local cell=Image(16,16,ColorMode.RGB); cell:drawSprite(ice,frame); sheet:drawImage(cell,Point((frame-1)*16,0)) end
sheet:saveAs(root .. "/assets/sprites/expansion/ice/glacial_ice_sheet.png"); ice:close()
