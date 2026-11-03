local root=assert(app.params.root)
local s=assert(app.open(root.."/assets/sprites/source/ecology/hanging_vines.aseprite"))
local sheet=Image(48,24,ColorMode.RGB)
for i=1,3 do local im=Image(16,24,ColorMode.RGB);im:drawSprite(s,i);sheet:drawImage(im,Point((i-1)*16,0)) end
local out=root.."/assets/sprites/ecology/";app.fs.makeAllDirectories(out)
sheet:saveAs(out.."hanging_vines.png");s:close()
print("VINES_EXPORTED styles=3 root_middle_tip=9")
