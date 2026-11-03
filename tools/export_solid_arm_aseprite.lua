local root=assert(app.params.root)
local s=assert(app.open(root .. "/assets/sprites/source/characters/avatar_solid_arms.aseprite")); local data=json.decode(s.data)
local output=root .. "/assets/sprites/characters/solid_arms/"; app.fs.makeAllDirectories(output)
local function C(hex) return app.pixelColor.rgba(tonumber(hex:sub(1,2),16),tonumber(hex:sub(3,4),16),tonumber(hex:sub(5,6),16),255) end
local originals={}; for frame=1,8 do local im=Image(8,20,ColorMode.RGB); im:drawSprite(s,frame); originals[frame]=im end
for skin,skin_color in ipairs(data.catalog.palettes.skin) do for cloth,cloth_color in ipairs(data.catalog.palettes.clothing) do
 local map={}; for shade=1,3 do map[C(data.catalog.palettes.skin[1].ramp[shade])]=C(skin_color.ramp[shade]); map[C(data.catalog.palettes.clothing[1].ramp[shade])]=C(cloth_color.ramp[shade]) end
 local sheet=Image(8,160,ColorMode.RGB)
 for frame,im in ipairs(originals) do for y=0,19 do for x=0,7 do local pixel=im:getPixel(x,y); sheet:drawPixel(x,(frame-1)*20+y,map[pixel] or pixel) end end end
 sheet:saveAs(output .. string.format("skin_%02d_cloth_%02d.png",skin-1,cloth-1))
end end
s:close(); print("ASEPRITE_SOLID_ARM_EXPORT native_frames=8 precolored_atlases=72")
