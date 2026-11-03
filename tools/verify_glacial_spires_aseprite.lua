local root=assert(app.params.root)
local out=root .. "/assets/sprites/glacial_spires/"
local pixels=0
for _,spec in ipairs({{"glacial_spires","glacial_body",1,128,256},{"glacial_edges","glacial_edges",6,16,16}}) do
 local s=assert(app.open(root .. "/assets/sprites/source/expansion/" .. spec[1] .. ".aseprite"))
 local png=Image{fromFile=out .. spec[2] .. ".png"}
 assert(#s.frames==spec[3] and #s.layers>=3 and #s.tags==spec[3],"Glacial source structure")
 for frame=1,spec[3] do
  local rendered=Image(s.width,s.height,ColorMode.RGB); rendered:drawSprite(s,frame)
  assert(not rendered:isEmpty(),"Glacial frame cannot be empty")
  for y=0,spec[5]-1 do for x=0,spec[4]-1 do
   local a,b=rendered:getPixel(x,y),png:getPixel(x+(frame-1)*spec[4],y)
   if app.pixelColor.rgbaA(a)>0 or app.pixelColor.rgbaA(b)>0 then assert(a==b,"Native glacial export differs") end
   pixels=pixels+1
  end end
 end
 s:close()
end
local tip=Image{fromFile=out .. "glacial_edges.png"}
assert(app.pixelColor.rgbaA(tip:getPixel(0,0))==0 and app.pixelColor.rgbaA(tip:getPixel(15,0))==0,"Needle tip corners must be transparent")
assert(app.pixelColor.rgbaA(tip:getPixel(8,0))>0,"Needle tip needs a pointed apex")
print("ASEPRITE_GLACIAL_VERIFIED source_frames=7 matching_pixels=" .. pixels)
