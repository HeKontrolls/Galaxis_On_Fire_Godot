local root=assert(app.params.root)
app.fs.makeAllDirectories(root.."/assets/sprites/source/terrain")
local s=Sprite(16,16,ColorMode.RGB);s.layers[1].name="Gravel bed"
local pebbles=s:newLayer();pebbles.name="Pebble facets and quartz chips"
local function col(h) return app.pixelColor.rgba(tonumber(h:sub(1,2),16),tonumber(h:sub(3,4),16),tonumber(h:sub(5,6),16),255) end
local function p(im,x,y,c) if x>=0 and x<16 and y>=0 and y<16 then im:drawPixel(x,y,col(c)) end end
for frame=1,4 do
 if frame>1 then s:newEmptyFrame() end
 local bed,stones=Image(16,16,ColorMode.RGB),Image(16,16,ColorMode.RGB)
 for y=0,15 do for x=0,15 do p(bed,x,y,(x*7+y*3+frame)%9<2 and "64646e" or "77747b") end end
 for row=0,3 do for n=0,3 do
  local x=n*5-2+(row%2)*2+(frame%2);local y=row*4-1
  local mid=({"9a9392","8c919b","aca49a","85808c"})[(row+n+frame)%4+1]
  for yy=0,2 do for xx=0,3 do if not (yy==0 and xx==0) and not (yy==2 and xx==3) then p(stones,x+xx,y+yy,mid) end end end
  p(stones,x+1,y,"c2bab0");p(stones,x+2,y,"c2bab0");p(stones,x,y+2,"555765");p(stones,x+1,y+3,"555765")
 end end
 if frame==1 then s.layers[1]:cel(1).image=bed else s:newCel(s.layers[1],frame,bed,Point(0,0)) end
 s:newCel(pebbles,frame,stones,Point(0,0))
end
s:newTag(1,4).name="terrain_variants"
s:saveAs(root.."/assets/sprites/source/terrain/gravel.aseprite");s:close()
dofile(root.."/tools/export_gravel_aseprite.lua")
print("GRAVEL_AUTHORED frames=4")
