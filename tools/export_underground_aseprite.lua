local root=assert(app.params.root)
local src=root.."/assets/sprites/source/underground/";local out=root.."/assets/sprites/underground/"
app.fs.makeAllDirectories(out)
local s=assert(app.open(src.."cave_formations.aseprite"))
for _,tag in ipairs(s.tags) do local im=Image(32,48,ColorMode.RGB);im:drawSprite(s,tag.fromFrame.frameNumber);im:saveAs(out..tag.name..".png") end
s:close()
local t=assert(app.open(src.."cave_tiles.aseprite"));local atlas=Image(112,16,ColorMode.RGB)
for i=1,7 do local im=Image(16,16,ColorMode.RGB);im:drawSprite(t,i);atlas:drawImage(im,Point((i-1)*16,0)) end
atlas:saveAs(out.."cave_tiles.png");t:close();print("UNDERGROUND_EXPORTED formations=12 biome_tiles=7")
