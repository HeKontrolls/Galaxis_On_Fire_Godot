-- Export saved editable documents without rebuilding or repainting the art.
local root=assert(app.params.root,"Pass --script-param root=<project>")
dofile(root .. "/tools/export_shovels_aseprite.lua")
dofile(root .. "/tools/export_glacial_spires_aseprite.lua")
dofile(root .. "/tools/export_biome_backgrounds_aseprite.lua")
local sources=root .. "/assets/sprites/source/frontier/"
local out=root .. "/assets/sprites/redesigned/"
local function image(s,index,path)
  app.fs.makeAllDirectories(app.fs.filePath(path))
  local im=Image(s.width,s.height,ColorMode.RGB); im:drawSprite(s,index); im:saveAs(path)
end
for _,name in ipairs({"captain","elder","tools","captain_parts","stations"}) do
  local s=assert(app.open(sources .. name .. ".aseprite"))
  local metadata=json.decode(s.data)
  metadata.animations={}
  for _,tag in ipairs(s.tags) do
    local first,last=tag.fromFrame.frameNumber,tag.toFrame.frameNumber
    if name=="tools" or name=="captain_parts" then assert(first==last,"Static item tags must contain one frame: " .. tag.name) end
    local durations={}
    for index=first,last do
      table.insert(durations,s.frames[index].duration)
      local base=out
      if name=="captain" or name=="elder" then
        local action,direction=tag.name:match("^(%w+)_(%w+)$")
        base=base .. name .. "/" .. action .. "/" .. direction .. string.format("/frame_%03d.png",index-first)
      elseif name=="tools" then
        base=base .. "tools/" .. tag.name .. ".png"
      elseif name=="captain_parts" then
        base=base .. "captain/" .. tag.name .. ".png"
      else
        local station=tag.name:gsub("_idle$",""):gsub("_burn$","")
        base=base .. "stations/" .. station .. string.format("_%02d.png",index-first)
      end
      image(s,index,base)
    end
    table.insert(metadata.animations,{name=tag.name,first=first,last=last,count=last-first+1,durations=durations})
  end
  local cols=math.min(10,#s.frames); local rows=math.ceil(#s.frames/cols)
  local sheet=Image(s.width*cols,s.height*rows,ColorMode.RGB)
  for index=1,#s.frames do sheet:drawSprite(s,index,Point(((index-1)%cols)*s.width,math.floor((index-1)/cols)*s.height)) end
  sheet:saveAs(out .. name .. "_sheet.png")
  local f=assert(io.open(out .. name .. ".json","w")); f:write(json.encode(metadata)); f:close()
  print("Exported " .. name .. ": " .. #s.frames .. " frames from " .. #s.layers .. " layers")
  s:close()
end
print("ASEPRITE_EXPORT complete")
dofile(root .. "/tools/export_expedition_aseprite.lua")
if app.fs.isFile(root .. "/assets/sprites/source/expansion/desert_flora.aseprite") then dofile(root .. "/tools/export_planet_expansion_aseprite.lua") end
if app.fs.isFile(root .. "/assets/sprites/source/ecology/ground_life.aseprite") then
  dofile(root .. "/tools/export_ground_life_aseprite.lua")
end
if app.fs.isFile(root .. "/assets/sprites/source/ecology/ground_cover.aseprite") then
  dofile(root .. "/tools/export_ground_cover_aseprite.lua")
end
if app.fs.isFile(root .. "/assets/sprites/source/characters/avatar_male.aseprite") then
  dofile(root .. "/tools/export_avatar_aseprite.lua")
end
dofile(root .. "/tools/export_monsters_aseprite.lua")
dofile(root .. "/tools/export_flyers_aseprite.lua")
dofile(root .. "/tools/export_wildlife_aseprite.lua")
dofile(root .. "/tools/export_vines_aseprite.lua")
dofile(root .. "/tools/export_underground_aseprite.lua")
dofile(root .. "/tools/export_water_interactions_aseprite.lua")
dofile(root .. "/tools/export_gravel_aseprite.lua")
dofile(root .. "/tools/export_background_ores_aseprite.lua")
dofile(root .. "/tools/export_housing_aseprite.lua")
dofile(root .. "/tools/export_door_aseprite.lua")
