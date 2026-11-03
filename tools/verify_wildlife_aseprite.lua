local root=assert(app.params.root);local pixels=0
for family=0,8 do
 local s=assert(app.open(root.."/assets/sprites/source/monsters/wildlife_"..family..".aseprite"))
 assert(#s.layers==3 and #s.frames==16 and #s.tags==(family==8 and 2 or 12),"Native source structure")
 local actual=Image{fromFile=root.."/assets/sprites/monsters/wildlife_"..family..".png"}
 for frame=1,16 do
  local im=Image(48,40,ColorMode.RGB);im:drawSprite(s,frame)
  for y=0,39 do for x=0,47 do
   local c=im:getPixel(x,y);assert(c==actual:getPixel(((frame-1)%8)*48+x,math.floor((frame-1)/8)*40+y),"Export mismatch")
   local a=app.pixelColor.rgbaA(c);assert(a==0 or a==255,"Soft alpha")
   if x==0 or x==47 or y==0 or y==39 then assert(a==0,"Clipped canvas") end
   if a>0 then
    local edge=false;for _,d in ipairs({{-1,0},{1,0},{0,-1},{0,1}}) do if x+d[1]>=0 and x+d[1]<48 and y+d[2]>=0 and y+d[2]<40 and app.pixelColor.rgbaA(im:getPixel(x+d[1],y+d[2]))==0 then edge=true end end
    if edge then assert(app.pixelColor.rgbaR(c)+app.pixelColor.rgbaG(c)+app.pixelColor.rgbaB(c)>135,"Black external stroke") end
   end
   pixels=pixels+1
  end end
 end
 s:close()
end
print("WILDLIFE_ART_VERIFIED families=9 frames=144 pixels="..pixels)
