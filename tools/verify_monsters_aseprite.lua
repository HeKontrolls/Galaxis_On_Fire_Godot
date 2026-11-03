local root=assert(app.params.root)
local names={"moss_prowler","tide_crab","reef_stalker","dune_scorpion","ember_crawler","shale_scavenger","ice_walker","tundra_beast"}
local pixels=0
for _,name in ipairs(names) do
 local s=assert(app.open(root.."/assets/sprites/source/monsters/"..name..".aseprite"))
 assert(#s.layers==3 and #s.frames==18 and #s.tags==6,name.." timeline/layers incorrect")
 local sheet=Image{fromFile=root.."/assets/sprites/monsters/"..name..".png"}
 assert(sheet.width==288 and sheet.height==120)
 for index=1,18 do
  local im=Image(48,40,ColorMode.RGB);im:drawSprite(s,index)
  local ox=((index-1)%6)*48;local oy=math.floor((index-1)/6)*40
  for y=0,39 do for x=0,47 do
   assert(im:getPixel(x,y)==sheet:getPixel(ox+x,oy+y),name.." export mismatch");pixels=pixels+1
   local alpha=app.pixelColor.rgbaA(im:getPixel(x,y));assert(alpha==0 or alpha==255,name.." contains softened edge pixels")
   if im:getPixel(x,y)==app.pixelColor.rgba(23,33,43,255) then
    for dy=-2,2 do for dx=-2,2 do
     local xx,yy=x+dx,y+dy
     assert(xx>=0 and xx<48 and yy>=0 and yy<40 and app.pixelColor.rgbaA(im:getPixel(xx,yy))>0,name.." has black exterior outline")
    end end
   end
   if x==0 or x==47 or y==0 or y==39 then assert(app.pixelColor.rgbaA(im:getPixel(x,y))==0,name.." clipped sprite") end
  end end
 end
 s:close()
end
print("MONSTER_ART_VERIFIED families=8 frames=144 pixels="..pixels)
