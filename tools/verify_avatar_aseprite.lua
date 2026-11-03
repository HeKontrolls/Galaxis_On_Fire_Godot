-- Read-only, exhaustive visible RGBA comparison against editable Aseprite cels.
local root=assert(app.params.root); local source=root .. "/assets/sprites/source/characters/"
local output=root .. "/assets/sprites/characters/"; local pixels,sheets=0,0
local function C(hex) return app.pixelColor.rgba(tonumber(hex:sub(1,2),16),tonumber(hex:sub(3,4),16),tonumber(hex:sub(5,6),16),255) end
local function map(from,to,result) result=result or {}; for i,color in ipairs(from) do result[C(color)]=C(to[i]) end; return result end
local function compare(im,original,ox,oy,colors,path)
 for y=0,original.height-1 do for x=0,original.width-1 do
  local raw=original:getPixel(x,y); local expected=colors[raw] or raw; local actual=im:getPixel(ox+x,oy+y)
  assert((app.pixelColor.rgbaA(expected)==0 and app.pixelColor.rgbaA(actual)==0) or expected==actual,"Avatar differs from source: " .. path .. " at " .. ox+x .. "," .. oy+y)
  pixels=pixels+1
 end end
end
for _,model in ipairs({"male","female"}) do
 local s=assert(app.open(source .. "avatar_" .. model .. ".aseprite")); local data=json.decode(s.data)
 assert(s.width==32 and s.height==40 and #s.frames==38 and #s.layers==30 and #s.tags==6,"Invalid avatar document structure")
 local layers={}; for _,layer in ipairs(s.layers) do layers[layer.name]=layer end
 for _,component in ipairs(data.components) do
  local originals={}; local layer=assert(layers[component.name])
  for index=1,38 do local im=Image(32,40,ColorMode.RGB); local cel=layer:cel(index); if cel then im:drawImage(cel.image,cel.position) end; originals[index]=im end
  -- Every animation has a baked opposite-facing version.
  for frame=1,19 do for y=0,39 do for x=0,31 do
   assert(originals[frame]:getPixel(x,y)==originals[frame+19]:getPixel(31-x,y),"Unmirrored layer " .. component.name)
  end end end
  local palette=data.catalog.palettes[component.category]
  for index,color in ipairs(palette) do
   local path=output .. model .. "/" .. component.name .. string.format("_%02d.png",index-1)
   local exported=Image{fromFile=path}; assert(exported.width==320 and exported.height==160,"Invalid avatar atlas dimensions")
   local colors=map(palette[component.master+1].ramp,color.ramp)
   for frame,im in ipairs(originals) do compare(exported,im,((frame-1)%10)*32,math.floor((frame-1)/10)*40,colors,path) end
   sheets=sheets+1
  end
 end
 s:close()
end
local s=assert(app.open(source .. "avatar_arms.aseprite")); local data=json.decode(s.data)
assert(s.width==8 and s.height==12 and #s.frames==24 and #s.layers==3 and #s.tags==24,"Invalid articulated arms document")
local originals={}; for frame=1,24 do local im=Image(8,12,ColorMode.RGB); im:drawSprite(s,frame); assert(not im:isEmpty(),"Empty arm part"); originals[frame]=im end
for skin,skin_color in ipairs(data.catalog.palettes.skin) do for clothing,clothing_color in ipairs(data.catalog.palettes.clothing) do
 local path=output .. string.format("arms/skin_%02d_cloth_%02d.png",skin-1,clothing-1)
 local exported=Image{fromFile=path}; assert(exported.width==24 and exported.height==96,"Invalid articulated arm atlas")
 local colors=map(data.catalog.palettes.skin[1].ramp,skin_color.ramp); map(data.catalog.palettes.clothing[1].ramp,clothing_color.ramp,colors)
 for frame,im in ipairs(originals) do compare(exported,im,((frame-1)%3)*8,math.floor((frame-1)/3)*12,colors,path) end
 sheets=sheets+1
end end
s:close()
print("ASEPRITE_AVATAR_VERIFIED documents=3 atlases=" .. sheets .. " matching_RGBA_pixels=" .. pixels .. " animation_mirrors=all")
