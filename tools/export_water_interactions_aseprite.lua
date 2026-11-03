local root=assert(app.params.root)
local s=assert(app.open(root.."/assets/sprites/source/underground/water_interactions.aseprite"))
local sheet=Image(512,48,ColorMode.RGB)
for i=1,16 do local im=Image(64,24,ColorMode.RGB);im:drawSprite(s,i);sheet:drawImage(im,Point(((i-1)%8)*64,math.floor((i-1)/8)*24)) end
sheet:saveAs(root.."/assets/sprites/underground/water_interactions.png")
local f=assert(io.open(root.."/assets/sprites/underground/water_interactions.json","w"));f:write('{"frame_width":64,"frame_height":24,"frames_per_animation":8,"animations":["ripple","splash"],"frame_duration":0.1,"pivot":[32,16]}');f:close();s:close()
print("WATER_INTERACTIONS_EXPORTED frames=16")
