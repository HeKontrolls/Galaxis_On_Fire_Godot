local root=assert(app.params.root)
local s=assert(app.open(root .. "/assets/sprites/source/characters/avatar_solid_arms.aseprite")); local data=json.decode(s.data)
assert(s.width==8 and s.height==20 and #s.frames==8 and #s.tags==8 and #s.layers==2,"Invalid solid arm source")
local function C(hex) return app.pixelColor.rgba(tonumber(hex:sub(1,2),16),tonumber(hex:sub(3,4),16),tonumber(hex:sub(5,6),16),255) end
local originals={}
for frame=1,8 do local im=Image(8,20,ColorMode.RGB); im:drawSprite(s,frame); originals[frame]=im
 local seen,queue={},{{4,1}}; seen[1*8+4]=true; local index=1; local connected=0; local opaque=0
 while index<=#queue do local p=queue[index]; index=index+1; connected=connected+1
  for _,delta in ipairs({{1,0},{-1,0},{0,1},{0,-1}}) do local x,y=p[1]+delta[1],p[2]+delta[2]; local key=y*8+x
   if x>=0 and x<8 and y>=0 and y<20 and not seen[key] and app.pixelColor.rgbaA(im:getPixel(x,y))>0 then seen[key]=true; table.insert(queue,{x,y}) end
  end
 end
 for y=0,19 do for x=0,7 do if app.pixelColor.rgbaA(im:getPixel(x,y))>0 then opaque=opaque+1 end end end
 assert(connected==opaque and seen[17*8+4],"Arm must be one connected shoulder-to-fist piece")
end
local count=0
for skin,skin_color in ipairs(data.catalog.palettes.skin) do for cloth,cloth_color in ipairs(data.catalog.palettes.clothing) do
 local map={}; for shade=1,3 do map[C(data.catalog.palettes.skin[1].ramp[shade])]=C(skin_color.ramp[shade]); map[C(data.catalog.palettes.clothing[1].ramp[shade])]=C(cloth_color.ramp[shade]) end
 local im=Image{fromFile=root .. string.format("/assets/sprites/characters/solid_arms/skin_%02d_cloth_%02d.png",skin-1,cloth-1)}
 assert(im.width==8 and im.height==160,"Invalid solid arm atlas size")
 for frame,original in ipairs(originals) do for y=0,19 do for x=0,7 do
  local expected=original:getPixel(x,y); expected=map[expected] or expected; local actual=im:getPixel(x,(frame-1)*20+y)
  assert(expected==actual or (app.pixelColor.rgbaA(expected)==0 and app.pixelColor.rgbaA(actual)==0),"Solid arm palette export differs from source"); count=count+1
 end end end
end end
s:close(); print("ASEPRITE_SOLID_ARM_VERIFIED models=2 styles=4 connected_sources=8 matching_atlases=72 RGBA_pixels=" .. count)
