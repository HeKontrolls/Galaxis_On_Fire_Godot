local root=assert(app.params.root)
local s=assert(app.open(root.."/assets/sprites/source/housing/door.aseprite"))
local sheet=Image(128,48,ColorMode.RGB)
for i=1,4 do local im=Image(32,48,ColorMode.RGB);im:drawSprite(s,i);sheet:drawImage(im,Point((i-1)*32,0)) end
sheet:saveAs(root.."/assets/sprites/housing/door.png")
local f=assert(io.open(root.."/assets/sprites/housing/door.json","w"));f:write('{"frame_width":32,"frame_height":48,"pivot":[8,48],"footprint":[1,3],"closed":[0],"opening":[1,2,3],"open":[3],"closing":[2,1,0],"frame_duration":0.06}');f:close();s:close()
print("DOOR_EXPORTED")
