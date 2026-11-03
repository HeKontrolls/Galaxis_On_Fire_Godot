local root=assert(app.params.root)
local out=root.."/assets/sprites/monsters/";app.fs.makeAllDirectories(out)
local names={"moss_prowler","tide_crab","reef_stalker","dune_scorpion","ember_crawler","shale_scavenger","ice_walker","tundra_beast"}
for _,name in ipairs(names) do
 local s=assert(app.open(root.."/assets/sprites/source/monsters/"..name..".aseprite"))
 local sheet=Image(288,120,ColorMode.RGB)
 for index=1,18 do local im=Image(48,40,ColorMode.RGB);im:drawSprite(s,index);sheet:drawImage(im,Point(((index-1)%6)*48,math.floor((index-1)/6)*40)) end
 sheet:saveAs(out..name..".png")
 local f=assert(io.open(out..name..".json","w"));f:write('{"frame_width":48,"frame_height":40,"morphs":3,"frames_per_morph":6,"pivot":[24,36],"idle":{"frames":[0,1],"durations":[1.1,0.12]},"walk":{"frames":[2,3,4,5],"durations":[0.14,0.14,0.14,0.14]}}');f:close();s:close()
end
print("MONSTERS_EXPORTED sheets=8 frames=144")
