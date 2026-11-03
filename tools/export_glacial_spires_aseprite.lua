local root=assert(app.params.root)
local out=root .. "/assets/sprites/glacial_spires/"; app.fs.makeAllDirectories(out)
local body=assert(app.open(root .. "/assets/sprites/source/expansion/glacial_spires.aseprite"))
local image=Image(body.width,body.height,ColorMode.RGB); image:drawSprite(body,1); image:saveAs(out .. "glacial_body.png"); body:close()
local edges=assert(app.open(root .. "/assets/sprites/source/expansion/glacial_edges.aseprite"))
local sheet=Image(96,16,ColorMode.RGB)
for i=1,6 do local cell=Image(16,16,ColorMode.RGB); cell:drawSprite(edges,i); sheet:drawImage(cell,Point((i-1)*16,0)) end
sheet:saveAs(out .. "glacial_edges.png"); edges:close()
print("ASEPRITE_GLACIAL_EXPORTED documents=2 body=128x256 edge_frames=6")
