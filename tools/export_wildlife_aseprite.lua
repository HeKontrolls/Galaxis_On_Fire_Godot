local root=assert(app.params.root)
for family=0,8 do
 local s=assert(app.open(root.."/assets/sprites/source/monsters/wildlife_"..family..".aseprite"))
 local sheet=Image(384,80,ColorMode.RGB)
 for i=1,16 do local im=Image(48,40,ColorMode.RGB);im:drawSprite(s,i);sheet:drawImage(im,Point(((i-1)%8)*48,math.floor((i-1)/8)*40)) end
 sheet:saveAs(root.."/assets/sprites/monsters/wildlife_"..family..".png")
 local f=assert(io.open(root.."/assets/sprites/monsters/wildlife_"..family..".json","w"));f:write('{"frame_width":48,"frame_height":40,"morphs":2,"frames_per_morph":8,"frame_duration":0.12,"pivot":[24,36]}');f:close();s:close()
end
print("WILDLIFE_EXPORTED families=9 frames=144")
