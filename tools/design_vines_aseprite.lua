local root=assert(app.params.root)
local src=root.."/assets/sprites/source/ecology/"
app.fs.makeAllDirectories(src)
local s=Sprite(16,24,ColorMode.RGB);s.layers[1].name="Stems and tendrils"
local leaves=s:newLayer();leaves.name="Leaves, veins and highlights"
local palettes={{"203c2b","39723d","70a34d","b0cb76"},{"263f31","427653","79a66b","bdd595"},{"223d43","386365","63958b","9cbdb0"}}
local function color(h) return app.pixelColor.rgba(tonumber(h:sub(1,2),16),tonumber(h:sub(3,4),16),tonumber(h:sub(5,6),16),255) end
for style=0,2 do
 if style>0 then s:newEmptyFrame() end
 local a,b=Image(16,24,ColorMode.RGB),Image(16,24,ColorMode.RGB);local c=palettes[style+1]
 local function p(im,x,y,t) if x>=0 and x<16 and y>=0 and y<24 then im:drawPixel(x,y,color(c[t])) end end
 for y=0,23 do local x=8+((y%8==3 or y%8==4) and 1 or 0);p(a,x,y,1);p(a,x+1,y,2);if y%3==0 then p(a,x,y,3) end end
 -- A clinging root at the top; middle and tapering tip repeat at eight-pixel intervals.
 for x=4,12 do p(a,x,1+math.abs(x-8)//3,2) end
 local function leaf(x,y,side,size)
  for row=0,4 do local width=({1,3,4,3,1})[row+1];for k=0,math.min(width,size)-1 do p(b,x+side*k,y+row,1);if k>0 and row>0 and row<4 then p(b,x+side*k,y+row,2) end end end
  for i=0,2 do p(b,x+side*i,y+1+i,3) end;p(b,x+side,y+1,4)
 end
 leaf(7,7,-1,style==1 and 5 or 4);leaf(10,10,1,4)
 leaf(7,17,-1,3);leaf(10,19,1,2)
 if style==1 then leaf(6,11,-1,3) end
 if style==2 then p(b,4,9,4);p(b,13,12,4);p(b,5,19,3) end
 if style==0 then s.layers[1]:cel(1).image=a else s:newCel(s.layers[1],style+1,a,Point(0,0)) end
 s:newCel(leaves,style+1,b,Point(0,0))
end
for i,name in ipairs({"trailing_ivy","heartleaf","cave_creeper"}) do s:newTag(i,i).name=name end
s:saveAs(src.."hanging_vines.aseprite");s:close()
dofile(root.."/tools/export_vines_aseprite.lua")
