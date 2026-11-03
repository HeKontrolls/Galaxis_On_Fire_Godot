local root=assert(app.params.root)
local pixels=0
for _,name in ipairs({"ship_damaged","ship_ready","drive_core","hull_plate","drive_coil","sentinel","orbital_ship","pod_strut"}) do
 local sprite=assert(app.open(root.."/assets/sprites/source/expedition/"..name..".aseprite"))
 assert(#sprite.layers==2 and #sprite.frames==1 and #sprite.tags==1, name.." must retain editable layers and a frame tag")
 local expected=Image(sprite.width,sprite.height,ColorMode.RGB); expected:drawSprite(sprite,1)
 local actual=Image{fromFile=root.."/assets/sprites/expedition/"..name..".png"}
 assert(actual.width==sprite.width and actual.height==sprite.height,name.." dimensions differ")
 for y=0,actual.height-1 do for x=0,actual.width-1 do assert(expected:getPixel(x,y)==actual:getPixel(x,y),name.." export differs from native source"); pixels=pixels+1 end end
 assert(app.pixelColor.rgbaA(actual:getPixel(0,0))==0,name.." must have a transparent border")
 sprite:close()
end
local robot=assert(app.open(root.."/assets/sprites/source/expedition/robot_guide.aseprite"))
assert(#robot.layers==2 and #robot.frames==12 and #robot.tags==4,"Robot must retain its layered animation timeline")
for _,tag in ipairs(robot.tags) do
 for index=tag.fromFrame.frameNumber,tag.toFrame.frameNumber do
  local expected=Image(robot.width,robot.height,ColorMode.RGB); expected:drawSprite(robot,index)
  local path=root.."/assets/sprites/redesigned/robot_guide/"..tag.name:gsub("_","/")..string.format("/frame_%03d.png",index-tag.fromFrame.frameNumber)
  local actual=Image{fromFile=path}
  assert(actual.width==48 and actual.height==48,"Robot canvas differs")
  for y=0,47 do for x=0,47 do assert(actual:getPixel(x,y)==expected:getPixel(x,y),"Robot export differs from native frame"); pixels=pixels+1 end end
 end
end
robot:close()
print("EXPEDITION_ART_VERIFIED static_sprites=8 robot_frames=12 pixels="..pixels)
