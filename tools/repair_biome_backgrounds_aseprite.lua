local root=assert(app.params.root)
local integrity=dofile(root .. "/tools/biome_background_integrity.lua")
local f=assert(io.open(root .. "/assets/sprites/backgrounds/catalog.json","r"))
local catalog=json.decode(f:read("*a")); f:close()
local holes,loose,groups=0,0,0
for _,scene in ipairs(catalog.scenes) do
 local path=root .. "/assets/sprites/source/backgrounds/" .. scene.id .. ".aseprite"
 local s=assert(app.open(path))
 local scene_holes,scene_loose=0,0
 for plane=1,3 do
  local shape,detail=Image(s.width,s.height,ColorMode.RGB),Image(s.width,s.height,ColorMode.RGB)
  local a,b=s.layers[plane*2-1]:cel(1),s.layers[plane*2]:cel(1)
  shape:drawImage(a.image,a.position); detail:drawImage(b.image,b.position)
  local filled,removed,components=integrity.repair(shape,detail)
  scene_holes=scene_holes+filled; scene_loose=scene_loose+removed
  holes=holes+filled; loose=loose+removed; groups=groups+components
  a.image=shape; a.position=Point(0,0); b.image=detail; b.position=Point(0,0)
 end
 s:saveAs(path); s:close()
 print("BACKGROUND_REPAIRED " .. scene.id .. " foundation_pixels=" .. scene_holes .. " detached_pixels=" .. scene_loose)
end
dofile(root .. "/tools/export_biome_backgrounds_aseprite.lua")
print("BACKGROUND_INTEGRITY_REPAIRED planes=96 foundation_pixels=" .. holes .. " detached_pixels=" .. loose .. " detached_groups=" .. groups)
