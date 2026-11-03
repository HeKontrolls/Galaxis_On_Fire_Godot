-- Precolors every selectable layer inside Aseprite. Godot never repaints pixels.
local root=assert(app.params.root)
local source=root .. "/assets/sprites/source/characters/"
local output=root .. "/assets/sprites/characters/"; app.fs.makeAllDirectories(output)
local function C(hex) return app.pixelColor.rgba(tonumber(hex:sub(1,2),16),tonumber(hex:sub(3,4),16),tonumber(hex:sub(5,6),16),255) end
local function mapping(from,to,map) map=map or {}; for i,hex in ipairs(from) do map[C(hex)]=C(to[i]) end; return map end
local function recolor(source,map)
 local im=Image(source.width,source.height,ColorMode.RGB)
 for y=0,source.height-1 do for x=0,source.width-1 do local pixel=source:getPixel(x,y); if app.pixelColor.rgbaA(pixel)>0 then im:drawPixel(x,y,map[pixel] or pixel) end end end
 return im
end
local function layer_images(s,layer)
 local result={}
 for index=1,#s.frames do local im=Image(s.width,s.height,ColorMode.RGB); local cel=layer:cel(index); if cel then im:drawImage(cel.image,cel.position) end; result[index]=im end
 return result
end
local metadata,catalog_json; local sheets=0
for _,model in ipairs({"male","female"}) do
 local s=assert(app.open(source .. "avatar_" .. model .. ".aseprite")); local data=json.decode(s.data)
 -- Encode JSON userdata directly: nesting it inside a Lua table produces null.
 catalog_json=catalog_json or json.encode(data.catalog)
 metadata=metadata or {version=1,canvas={32,40},columns=10,frames=38,animations={}}
 if #metadata.animations==0 then for _,tag in ipairs(s.tags) do local durations={}
  for index=tag.fromFrame.frameNumber,tag.toFrame.frameNumber do table.insert(durations,s.frames[index].duration) end
  table.insert(metadata.animations,{name=tag.name,first=tag.fromFrame.frameNumber-1,count=#durations,durations=durations})
 end end
 local folder=output .. model .. "/"; app.fs.makeAllDirectories(folder)
 local by_name={}; for _,layer in ipairs(s.layers) do by_name[layer.name]=layer end
 for _,component in ipairs(data.components) do
  local originals=layer_images(s,assert(by_name[component.name])); local palette=data.catalog.palettes[component.category]
  local master=palette[component.master+1].ramp
  for color,entry in ipairs(palette) do
   local sheet=Image(320,160,ColorMode.RGB); local map=mapping(master,entry.ramp)
   for index,im in ipairs(originals) do sheet:drawImage(recolor(im,map),Point(((index-1)%10)*32,math.floor((index-1)/10)*40)) end
   sheet:saveAs(folder .. component.name .. string.format("_%02d.png",color-1)); sheets=sheets+1
  end
 end
 print("AVATAR_EXPORTED model=" .. model .. " layers=" .. #s.layers .. " frames=" .. #s.frames)
 s:close()
end
local arms=assert(app.open(source .. "avatar_arms.aseprite")); local data=json.decode(arms.data)
local catalog=data.catalog; local originals={}
for index=1,#arms.frames do local im=Image(8,12,ColorMode.RGB); im:drawSprite(arms,index); originals[index]=im end
app.fs.makeAllDirectories(output .. "arms/")
for skin,skin_palette in ipairs(catalog.palettes.skin) do for cloth,cloth_palette in ipairs(catalog.palettes.clothing) do
 local map=mapping(catalog.palettes.skin[1].ramp,skin_palette.ramp)
 mapping(catalog.palettes.clothing[1].ramp,cloth_palette.ramp,map)
 local sheet=Image(24,96,ColorMode.RGB)
 for index,im in ipairs(originals) do sheet:drawImage(recolor(im,map),Point(((index-1)%3)*8,math.floor((index-1)/3)*12)) end
 sheet:saveAs(output .. string.format("arms/skin_%02d_cloth_%02d.png",skin-1,cloth-1)); sheets=sheets+1
end end
arms:close()
local encoded=json.encode(metadata)
local file=assert(io.open(output .. "avatar.json","w")); file:write(encoded:sub(1,-2) .. ',"catalog":' .. catalog_json .. '}'); file:close()
print("ASEPRITE_AVATAR_EXPORT atlases=" .. sheets .. " models=2 animation_frames=38 colors_prebaked=true")
if app.fs.isFile(root .. "/assets/sprites/source/characters/avatar_solid_arms.aseprite") then dofile(root .. "/tools/export_solid_arm_aseprite.lua") end
