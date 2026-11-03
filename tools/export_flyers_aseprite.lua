local root=assert(app.params.root)
for family=0,7 do
 local s=assert(app.open(root.."/assets/sprites/source/monsters/flying_"..family..".aseprite"))
 local sheet=Image(384,144,ColorMode.RGB)
 for i=1,18 do local im=Image(64,48,ColorMode.RGB);im:drawSprite(s,i);sheet:drawImage(im,Point(((i-1)%6)*64,math.floor((i-1)/6)*48)) end
 sheet:saveAs(root.."/assets/sprites/monsters/flying_"..family..".png")
 local file=assert(io.open(root.."/assets/sprites/monsters/flying_"..family..".json","w"));file:write('{"frame_width":64,"frame_height":48,"morphs":3,"frames_per_morph":6,"frame_duration":0.12,"pivot":[32,24]}');file:close();s:close()
end
print("FLYERS_EXPORTED families=8 frames=144")
