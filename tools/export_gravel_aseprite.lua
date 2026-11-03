local root=assert(app.params.root)
local s=assert(app.open(root.."/assets/sprites/source/terrain/gravel.aseprite"))
local sheet=Image(64,16,ColorMode.RGB)
for i=1,4 do local im=Image(16,16,ColorMode.RGB);im:drawSprite(s,i);sheet:drawImage(im,Point((i-1)*16,0)) end
sheet:saveAs(root.."/assets/sprites/terrain/gravel.png")
local f=assert(io.open(root.."/assets/sprites/terrain/gravel.json","w"));f:write('{"frame_width":16,"frame_height":16,"variants":4,"pivot":[8,16],"tag":"terrain_variants"}');f:close();s:close()
print("GRAVEL_EXPORTED")
