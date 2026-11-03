local root=assert(app.params.root)
local src=root.."/assets/sprites/source/underground/";local out=root.."/assets/sprites/underground/"
local s=assert(app.open(src.."cave_formations.aseprite"));assert(#s.layers==2 and #s.frames==12 and #s.tags==12)
local pixels=0
for _,tag in ipairs(s.tags) do
 local im=Image(32,48,ColorMode.RGB);im:drawSprite(s,tag.fromFrame.frameNumber)
 local actual=Image{fromFile=out..tag.name..".png"}
 for y=0,47 do for x=0,31 do assert(im:getPixel(x,y)==actual:getPixel(x,y),tag.name.." export mismatch");pixels=pixels+1 end end
end
s:close()
local t=assert(app.open(src.."cave_tiles.aseprite"));assert(#t.layers==2 and #t.frames==7 and #t.tags==7)
local actual=Image{fromFile=out.."cave_tiles.png"}
for i=1,7 do
 local im=Image(16,16,ColorMode.RGB);im:drawSprite(t,i)
 for y=0,15 do for x=0,15 do assert(im:getPixel(x,y)==actual:getPixel((i-1)*16+x,y),"Cave tile mismatch");pixels=pixels+1 end end
end
t:close();print("UNDERGROUND_ART_VERIFIED frames=19 pixels="..pixels)
