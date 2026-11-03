local root=assert(app.params.root)
for _,name in ipairs({"ship_damaged","ship_ready","drive_core","hull_plate","drive_coil","sentinel","orbital_ship","pod_strut"}) do
 local sprite=assert(app.open(root.."/assets/sprites/source/expedition/"..name..".aseprite"))
 local image=Image(sprite.width,sprite.height,ColorMode.RGB); image:drawSprite(sprite,1)
 image:saveAs(root.."/assets/sprites/expedition/"..name..".png"); sprite:close()
end
dofile(root.."/tools/export_robot_guide_aseprite.lua")
print("EXPEDITION_EXPORTED static_sprites=8 robot_frames=12")
