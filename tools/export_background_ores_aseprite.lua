local root=assert(app.params.root)
for _,name in ipairs({"background_ores","mattock"}) do
 local s=assert(app.open(root.."/assets/sprites/source/underground/"..name..".aseprite"))
 local sheet=Image(name=="mattock" and 32 or 48,name=="mattock" and 40 or 96,ColorMode.RGB)
 for i=1,#s.frames do local im=Image(s.width,s.height,ColorMode.RGB);im:drawSprite(s,i);sheet:drawImage(im,Point(name=="mattock" and 0 or ((i-1)%3)*16,name=="mattock" and 0 or math.floor((i-1)/3)*16)) end
 sheet:saveAs(root.."/assets/sprites/underground/"..name..".png")
 local f=assert(io.open(root.."/assets/sprites/underground/"..name..".json","w"));f:write(name=="mattock" and '{"frame_width":32,"frame_height":40,"pivot":[16,32],"tag":"mattock_grip_16_32"}' or '{"frame_width":16,"frame_height":16,"variants":3,"ore_ids":[20,21,22,23,24,25]}');f:close();s:close()
end
print("BACKGROUND_ORE_ART_EXPORTED")
