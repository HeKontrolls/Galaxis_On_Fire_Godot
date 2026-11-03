-- Native Aseprite painting: one uninterrupted shoulder-to-fist sprite per outfit.
local root=assert(app.params.root); local catalog=dofile(root .. "/tools/avatar_catalog.lua")
local function C(hex) return app.pixelColor.rgba(tonumber(hex:sub(1,2),16),tonumber(hex:sub(3,4),16),tonumber(hex:sub(5,6),16),255) end
local ink=C("292935"); local skin=catalog.palettes.skin[1].ramp; local cloth=catalog.palettes.clothing[1].ramp
local s=Sprite(8,20,ColorMode.RGB); s.layers[1].name="Continuous arm and fist"; s:newLayer().name="Sleeve and fabric highlights"
local index=0; local tags={}
for _,model in ipairs(catalog.models) do for _,style in ipairs(catalog.shirt_styles) do
 index=index+1; if index>1 then s:newEmptyFrame(index) end
 local body,sleeve=Image(8,20,ColorMode.RGB),Image(8,20,ColorMode.RGB)
 local left=model=="female" and 3 or 2; local right=5
 for y=1,18 do for x=left,right do
  local edge=x==left or x==right or y==1 or y==18
  body:drawPixel(x,y,edge and ink or C(skin[2]))
 end end
 for y=3,16 do body:drawPixel(left+1,y,C(y<14 and skin[3] or skin[2])) end
 body:drawPixel(right,16,C(skin[1])); body:drawPixel(right,17,C(skin[2]))
 local cuff=style[1]=="jacket" and 14 or (style[1]=="workshirt" and 8 or 6)
 for y=1,cuff do for x=left,right do sleeve:drawPixel(x,y,(x==left or x==right or y==1) and ink or C(cloth[2])) end end
 for y=3,cuff-1 do sleeve:drawPixel(left+1,y,C(cloth[3])) end
 for x=left,right do sleeve:drawPixel(x,cuff,C(style[1]=="workshirt" and "e2dfc9" or cloth[1])) end
 s:newCel(s.layers[1],index,body,Point(0,0)); s:newCel(s.layers[2],index,sleeve,Point(0,0))
 table.insert(tags,{name=model .. "_" .. style[1],index=index})
end end
for _,tag in ipairs(tags) do s:newTag(tag.index,tag.index).name=tag.name end
local palette=Palette(256); local slot=0
for _,category in ipairs({"skin","clothing"}) do for _,entry in ipairs(catalog.palettes[category]) do for _,hex in ipairs(entry.ramp) do
 palette:setColor(slot,Color{r=tonumber(hex:sub(1,2),16),g=tonumber(hex:sub(3,4),16),b=tonumber(hex:sub(5,6),16)}); slot=slot+1
end end end
s:setPalette(palette)
s.data=json.encode({version=1,canvas={8,20},shoulder={4,1},grip={4,17},catalog=catalog})
s:saveAs(root .. "/assets/sprites/source/characters/avatar_solid_arms.aseprite"); s:close()
dofile(root .. "/tools/export_solid_arm_aseprite.lua")
print("ASEPRITE_SOLID_ARM_DESIGN models=2 sleeve_styles=4 connected_arm=true")
