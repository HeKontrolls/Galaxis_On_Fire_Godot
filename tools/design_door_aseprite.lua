local root=assert(app.params.root)
local s=Sprite(32,48,ColorMode.RGB);s.layers[1].name="Door leaf and jamb";s:newLayer().name="Wood panels, iron straps and window";s:newLayer().name="Brass fittings and edge light"
local function rgba(h) return app.pixelColor.rgba(tonumber(h:sub(1,2),16),tonumber(h:sub(3,4),16),tonumber(h:sub(5,6),16),255) end
for frame=1,4 do
 if frame>1 then s:newEmptyFrame() end
 for layer=1,3 do
  local im=Image(32,48,ColorMode.RGB)
  local function p(x,y,c) if x>=0 and x<32 and y>=0 and y<48 then im:drawPixel(x,y,rgba(c)) end end
  local function box(x,y,w,h,c) for yy=y,y+h-1 do for xx=x,x+w-1 do p(xx,yy,c) end end end
  local widths={14,11,7,3};local w=widths[frame];local x=9
  if layer==1 then
   box(8,0,2,48,"583f35");box(x,1,w,46,"654431")
   if frame==1 then box(22,0,2,48,"593e34");box(8,0,16,2,"ad8754");box(8,46,16,2,"5a4033") end
  elseif layer==2 then
   box(x,2,math.max(1,w-1),1,"c3a06b");box(x,3,1,42,"ad7e4d");box(x+w-1,3,1,42,"49382f")
   if w>=7 then
    box(x+2,5,w-4,15,"483c36");box(x+3,6,math.max(1,w-6),12,"4d7b82");box(x+3,7,math.max(1,w-6),2,"89b0ae")
    box(x+2,24,w-4,17,"8b633e");box(x+3,25,math.max(1,w-6),1,"bb925a");box(x+3,39,math.max(1,w-6),1,"614630")
    if w>=11 then box(x+math.floor(w/2),6,1,13,"7b5b3e");box(x+2,30,w-4,1,"765136") end
   end
   for _,y in ipairs({10,34}) do box(x,y,math.min(w,5),2,"545b61");p(x+1,y,"9fa9a5") end
  else
   for _,y in ipairs({11,35}) do p(8,y,"c5b486") end
   if w>=7 then box(x+w-3,23,2,3,"d6b463");p(x+w-3,23,"f5daa0");p(x+w-3,26,"4e3d31") end
   if w>=11 then p(x+3,34,"6e4c33");p(x+4,35,"ad804d");p(x+4,15,"abc8bf") end
  end
  if frame==1 and layer==1 then s.layers[1]:cel(1).image=im else s:newCel(s.layers[layer],frame,im,Point(0,0)) end
 end
 s.frames[frame].duration=0.06
end
s:newTag(1,1).name="closed";s:newTag(2,4).name="opening";s:newTag(4,4).name="open";local closing=s:newTag(1,3);closing.name="closing";closing.aniDir=AniDir.REVERSE
s:saveAs(root.."/assets/sprites/source/housing/door.aseprite");s:close()
dofile(root.."/tools/export_door_aseprite.lua")
print("DOOR_AUTHORED frames=4 layers=3")
