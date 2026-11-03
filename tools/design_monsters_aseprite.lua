-- Authored in native Aseprite: material-separated, high-readability creatures.
local root=assert(app.params.root)
local src=root.."/assets/sprites/source/monsters/"
app.fs.makeAllDirectories(src)
-- Stable asset keys keep existing saves, animation layout and gameplay pivots intact.
local names={"moss_prowler","tide_crab","reef_stalker","dune_scorpion","ember_crawler","shale_scavenger","ice_walker","tundra_beast"}
local palettes={
 {{"873b52","e57943","ffd985","67487e","f5ebbd"},{"99425f","ee8b68","ffe2a1","655b9b","fff0ce"},{"995839","eeb743","ffe9a0","704777","f8d8b8"}},
 {{"663b88","aa73cd","e2b6f0","ec795c","ffe7ad"},{"753d78","ca74ab","f5bfda","e79d54","fff1c2"},{"414c8d","818bd5","c8d4ff","e88f70","fff0bf"}},
 {{"923d69","e87398","ffc3c1","527da5","b3f2ef"},{"a34b48","f08b65","ffdfab","5c65a5","dddcff"},{"7950a0","bd8ee3","efceff","449d9e","c5ffdb"}},
 {{"663d8e","9d69cb","e8b8ec","39b0b8","bdfff0"},{"435e9e","6b97dc","c8dfff","ba5bb7","ffccf0"},{"85479a","c072c9","f5c1ed","4199cb","c2f4ff"}},
 {{"5e5273","bca6bb","fff0cb","42c8c0","c4fff1"},{"575877","9faecc","f4f3e0","63bde4","d5fcff"},{"6c5068","c1a2ac","ffe0c5","76d6a4","e3ffb3"}},
 {{"673c92","ab6ed1","edb3f2","e5a74f","fff0b9"},{"5d438f","9274cf","dbc5ff","eb9370","ffe2b3"},{"85436d","c66c9e","ffc7dc","6bcbc9","d0fff1"}},
 {{"7d304b","c65066","ff9f8b","5a4d88","ffe9ba"},{"8e3b39","dc6744","ffb877","634b87","fff0ce"},{"733a65","bb6097","f4a6cd","414f88","fce9bf"}},
 {{"295b78","43a6b2","a6ead9","eb9275","ffe3ad"},{"385b87","658fc8","c4e2f9","e695b2","ffe5cc"},{"386d76","65b6a0","c4f3be","d77ba6","ffe2c4"}}
}
local paint=dofile(root.."/tools/monster_anatomy_aseprite.lua")
local material=dofile(root.."/tools/monster_materials_aseprite.lua")
for family,name in ipairs(names) do
 local s=Sprite(48,40,ColorMode.RGB);local body=s.layers[1];body.name="Silhouette and colored shadows"
 local detail=s:newLayer();detail.name="Armor, face and identifying markings"
 local texture=s:newLayer();texture.name="Selective pixel highlights"
 for morph=0,2 do for pose=0,5 do
  local index=morph*6+pose+1;if index>1 then s:newEmptyFrame() end
  local a,b,t=Image(48,40,ColorMode.RGB),Image(48,40,ColorMode.RGB),Image(48,40,ColorMode.RGB)
  paint(a,b,family,morph,pose,palettes[family][morph+1])
  material(a,b,t,family,morph,pose,palettes[family][morph+1])
  if index==1 then body:cel(1).image=a else s:newCel(body,index,a,Point(0,0)) end
  s:newCel(detail,index,b,Point(0,0));s:newCel(texture,index,t,Point(0,0))
  s.frames[index].duration=pose<2 and (pose==0 and 1.1 or 0.12) or 0.14
 end end
 for morph=0,2 do s:newTag(morph*6+1,morph*6+2).name="morph_"..morph.."_idle";s:newTag(morph*6+3,morph*6+6).name="morph_"..morph.."_walk" end
 s:saveAs(src..name..".aseprite");s:close()
end
dofile(root.."/tools/export_monsters_aseprite.lua")
print("MONSTERS_AUTHORED families=8 morphs=24 native_frames=144")
