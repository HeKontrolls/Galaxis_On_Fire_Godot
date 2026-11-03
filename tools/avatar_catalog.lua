-- Shared by the Aseprite construction/export helpers; persisted in the sources.
local function ramp(hex)
 local r,g,b=tonumber(hex:sub(1,2),16),tonumber(hex:sub(3,4),16),tonumber(hex:sub(5,6),16)
 local function h(rr,gg,bb) return string.format("%02x%02x%02x",math.floor(rr),math.floor(gg),math.floor(bb)) end
 return {h(r*.49+12,g*.49+10,b*.49+13),hex,h(r*.67+244*.33,g*.67+235*.33,b*.67+209*.33)}
end
local function palette(values)
 local result={}
 for _,v in ipairs(values) do table.insert(result,{name=v[1],color=v[2],ramp=v[3] or ramp(v[2])}) end
 return result
end
return {
 models={"male","female"}, model_names={"Male","Female"},
 hair_styles={{"cropped","Cropped"},{"swept","Side Swept"},{"curls","Curly"},{"bob","Bob"},{"long","Long Layers"},{"ponytail","Ponytail"},{"braids","Braids"},{"mohawk","Mohawk"}},
 shirt_styles={{"tee","Classic Tee"},{"tunic","Explorer Tunic"},{"jacket","Field Jacket"},{"workshirt","Work Shirt"}},
 pants_styles={{"trousers","Trousers"},{"jeans","Jeans"},{"cargo","Cargo Pants"},{"shorts","Shorts"}},
 shoes_styles={{"boots","Leather Boots"},{"sneakers","Sneakers"},{"workboots","Work Boots"},{"slipons","Slip-ons"}},
 palettes={
  skin=palette({{"Warm","edb78f",{"bd826d","edb78f","ffdab0"}},{"Fair","f6d6bc"},{"Tan","c58d66"},{"Brown","9a6548"},{"Deep","684735"},{"Olive","b89574"}}),
  hair=palette({{"Chestnut","654735"},{"Dark Brown","392c2b"},{"Black","252735"},{"Blonde","ccb36c"},{"Auburn","ab553f"},{"Silver","b5bec7"},{"White","e2dfd0"},{"Blue","537faf"},{"Teal","4caa9a"},{"Plum","a068a7"},{"Rose","ce859e"},{"Emerald","63914b"}}),
  clothing=palette({{"Teal","487f8d"},{"Denim","486c9c"},{"Burgundy","a64f5d"},{"Fern","5d8658"},{"Ochre","c69a4c"},{"Plum","80618f"},{"Rose","d28a9c"},{"Cream","ddd5ba"},{"Charcoal","46505c"},{"White","e6e8df"},{"Orange","c47746"},{"Leather","805b42"}}),
  eyes=palette({{"Brown","7a573d"},{"Blue","507cb6"},{"Green","569568"},{"Hazel","9c985c"},{"Gray","819296"},{"Amber","cb9d40"},{"Violet","9672bb"},{"Ruby","af555f"}})
 }
}
