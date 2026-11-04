local root=assert(app.params.root)
dofile(root .. "/tools/verify_shovels_aseprite.lua")
dofile(root .. "/tools/verify_glacial_spires_aseprite.lua")
dofile(root .. "/tools/verify_biome_backgrounds_aseprite.lua")
dofile(root .. "/tools/verify_planet_expansion_aseprite.lua")
local out=root .. "/assets/sprites/redesigned/"
local exported=0
for _,spec in ipairs({{"captain",38,5,6},{"elder",24,5,4},{"tools",13,3,13},{"captain_parts",3,2,3},{"stations",8,3,2}}) do
  local name=spec[1]
  local s=assert(app.open(root .. "/assets/sprites/source/frontier/" .. name .. ".aseprite"))
  assert(#s.frames==spec[2] and #s.layers==spec[3] and #s.tags==spec[4],name .. " source structure mismatch")
  for _,tag in ipairs(s.tags) do
    local first,last=tag.fromFrame.frameNumber,tag.toFrame.frameNumber
    for index=first,last do
      local path=out
      if name=="captain" or name=="elder" then
        local action,direction=tag.name:match("^(%w+)_(%w+)$")
        path=path .. name .. "/" .. action .. "/" .. direction .. string.format("/frame_%03d.png",index-first)
      elseif name=="tools" then path=path .. "tools/" .. tag.name .. ".png"
      elseif name=="captain_parts" then path=path .. "captain/" .. tag.name .. ".png"
      else path=path .. "stations/" .. tag.name:gsub("_idle$",""):gsub("_burn$","") .. string.format("_%02d.png",index-first) end
      local rendered=Image(s.width,s.height,ColorMode.RGB); rendered:drawSprite(s,index)
      local file=Image{fromFile=path}
      assert(rendered.width==file.width and rendered.height==file.height,"PNG dimensions differ: " .. path)
      for y=0,file.height-1 do for x=0,file.width-1 do
        local a,b=rendered:getPixel(x,y),file:getPixel(x,y)
        if app.pixelColor.rgbaA(a)>0 or app.pixelColor.rgbaA(b)>0 then
          assert(a==b,"PNG differs from Aseprite source: " .. path .. " at " .. x .. "," .. y .. " colors=" .. a .. "/" .. b)
        end
      end end
      assert(not file:isEmpty(),"Empty art: " .. path)
      exported=exported+1
    end
  end
  s:close()
end
print("ASEPRITE_SOURCE_VERIFIED documents=5 matching_exports=" .. exported)
if app.fs.isFile(root .. "/assets/sprites/source/ecology/ground_life.aseprite") then
  dofile(root .. "/tools/verify_ground_life_aseprite.lua")
end
if app.fs.isFile(root .. "/assets/sprites/source/ecology/ground_cover.aseprite") then
  dofile(root .. "/tools/verify_ground_cover_aseprite.lua")
end
if app.fs.isFile(root .. "/assets/sprites/source/characters/avatar_male.aseprite") then
  dofile(root .. "/tools/verify_avatar_aseprite.lua")
end
dofile(root .. "/tools/verify_expedition_aseprite.lua")
dofile(root .. "/tools/verify_monsters_aseprite.lua")
dofile(root .. "/tools/verify_flyers_aseprite.lua")
dofile(root .. "/tools/verify_wildlife_aseprite.lua")
dofile(root .. "/tools/verify_vines_aseprite.lua")
dofile(root .. "/tools/verify_underground_aseprite.lua")
dofile(root .. "/tools/verify_water_interactions_aseprite.lua")
if app.fs.isFile(root .. "/assets/sprites/source/characters/avatar_solid_arms.aseprite") then
  dofile(root .. "/tools/verify_solid_arm_aseprite.lua")
end
dofile(root .. "/tools/verify_gravel_aseprite.lua")
dofile(root .. "/tools/verify_background_ores_aseprite.lua")
dofile(root .. "/tools/verify_housing_aseprite.lua")
dofile(root .. "/tools/verify_door_aseprite.lua")

dofile(root .. "/tools/verify_farming_aseprite.lua")

dofile(root .. "/tools/verify_weapons_aseprite.lua")

dofile(root .. "/tools/verify_power_aseprite.lua")

dofile(root .. "/tools/verify_magic_aseprite.lua")

dofile(root .. "/tools/verify_alchemy_aseprite.lua")
