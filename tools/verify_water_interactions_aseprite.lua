local root=assert(app.params.root)
local s=assert(app.open(root.."/assets/sprites/source/underground/water_interactions.aseprite"))
assert(#s.layers==2 and #s.frames==16 and #s.tags==2)
local sheet=Image{fromFile=root.."/assets/sprites/underground/water_interactions.png"}
for i=1,16 do local im=Image(64,24,ColorMode.RGB);im:drawSprite(s,i)
 for y=0,23 do for x=0,63 do local c=im:getPixel(x,y);assert(c==sheet:getPixel(((i-1)%8)*64+x,math.floor((i-1)/8)*24+y));local a=app.pixelColor.rgbaA(c);assert(a==0 or a==255) end end
end
s:close();print("WATER_INTERACTIONS_VERIFIED frames=16 pixels=24576")
