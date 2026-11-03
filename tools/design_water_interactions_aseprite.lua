local root=assert(app.params.root)
local path=root.."/assets/sprites/source/underground/"
local s=Sprite(64,24,ColorMode.RGB);s.layers[1].name="Surface wave rings"
local drops=s:newLayer();drops.name="Splash droplets and highlights"
local function rgba(h) return app.pixelColor.rgba(tonumber(h:sub(1,2),16),tonumber(h:sub(3,4),16),tonumber(h:sub(5,6),16),255) end
for style=0,1 do for frame=0,7 do
 local index=style*8+frame+1;if index>1 then s:newEmptyFrame() end
 local a,b=Image(64,24,ColorMode.RGB),Image(64,24,ColorMode.RGB)
 local r=5+frame*3.4;local ry=1.4+frame*.27
 for x=2,61 do for y=12,21 do
  local d=((x-32)/r)^2+((y-16)/ry)^2
  if math.abs(d-1)<.22 and (x+frame)%7~=0 then a:drawPixel(x,y,rgba(y<16 and "92bac9" or "c3dee1")) end
 end end
 if style==1 and frame<6 then
  for j=-2,2 do
   local x=32+j*(3+frame);local y=15-math.floor(6*math.sin((frame+1)/7*math.pi))+math.abs(j)
   b:drawPixel(x,y,rgba("c6e0e2"));if j%2==0 then b:drawPixel(x,y-1,rgba("8eb8cc")) end
  end
 end
 if index==1 then s.layers[1]:cel(1).image=a else s:newCel(s.layers[1],index,a,Point(0,0)) end
 s:newCel(drops,index,b,Point(0,0));s.frames[index].duration=.1
end end
s:newTag(1,8).name="ripple";s:newTag(9,16).name="splash"
s:saveAs(path.."water_interactions.aseprite");s:close()
dofile(root.."/tools/export_water_interactions_aseprite.lua")
