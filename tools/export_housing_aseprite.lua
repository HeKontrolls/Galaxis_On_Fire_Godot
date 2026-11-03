local root=assert(app.params.root)
app.fs.makeAllDirectories(root.."/assets/sprites/housing")
for _,name in ipairs({"chair","table","ladder","wood_background","fireplace"}) do
 local s=assert(app.open(root.."/assets/sprites/source/housing/"..name..".aseprite"))
 local sheet=Image(s.width*#s.frames,s.height,ColorMode.RGB)
 for i=1,#s.frames do local im=Image(s.width,s.height,ColorMode.RGB);im:drawSprite(s,i);sheet:drawImage(im,Point((i-1)*s.width,0)) end
 sheet:saveAs(root.."/assets/sprites/housing/"..name..".png")
 local f=assert(io.open(root.."/assets/sprites/housing/"..name..".json","w"));f:write(string.format('{"frame_width":%d,"frame_height":%d,"frames":%d,"pivot":[0,%d],"frame_duration":0.16}',s.width,s.height,#s.frames,s.height));f:close();s:close()
end
print("HOUSING_EXPORTED")
