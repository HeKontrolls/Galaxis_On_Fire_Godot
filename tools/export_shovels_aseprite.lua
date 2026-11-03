local root=assert(app.params.root)
local s=assert(app.open(root .. "/assets/sprites/source/frontier/shovels.aseprite"))
local out=root .. "/assets/sprites/shovels/"; app.fs.makeAllDirectories(out)
for _,tag in ipairs(s.tags) do local image=Image(32,40,ColorMode.RGB); image:drawSprite(s,tag.fromFrame.frameNumber); image:saveAs(out .. tag.name .. ".png") end
print("ASEPRITE_SHOVELS_EXPORTED materials=" .. #s.tags); s:close()
