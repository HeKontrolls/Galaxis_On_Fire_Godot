local root=assert(app.params.root)
local s=Sprite(32,40,ColorMode.RGB)
local labels={"Shaft and grip","Spade silhouette","Material facets"}
for i,name in ipairs(labels) do local layer=i==1 and s.layers[1] or s:newLayer(); layer.name=name end
local function color(h) return app.pixelColor.rgba(tonumber(h:sub(1,2),16),tonumber(h:sub(3,4),16),tonumber(h:sub(5,6),16),255) end
local function pixel(im,x,y,c) if x>=0 and x<32 and y>=0 and y<40 then im:drawPixel(x,y,color(c)) end end
local function line(im,x,y,xx,yy,c) local steps=math.max(math.abs(xx-x),math.abs(yy-y)); for i=0,steps do local t=steps==0 and 0 or i/steps; pixel(im,math.floor(x+(xx-x)*t+.5),math.floor(y+(yy-y)*t+.5),c) end end
local names={"wood","gold","stone","copper","iron","diamond","netherite"}
local shades={{"4a342d","95613d","d0a26b"},{"62462b","c29b43","f4d784"},{"353e43","7f8c89","bcc4b2"},{"5b3d32","ba7849","e5b47d"},{"34424a","8cabb9","d8e4e7"},{"234952","419ca9","a4e9df"},{"242630","504957","aa91a5"}}
for i,name in ipairs(names) do
 if i>1 then s:newEmptyFrame(i) end
 local shaft,head,detail=Image(32,40),Image(32,40),Image(32,40)
 for y=14,36 do for x=15,17 do pixel(shaft,x,y,"3e302e") end; pixel(shaft,16,y,"ad8052") end
 line(detail,16,18,16,33,"d0ad75"); line(detail,15,29,17,29,"51454a"); line(detail,15,32,17,32,"705342")
 local col=shades[i]
 for y=3,19 do
  local width=y<6 and 5 or (y<14 and 6 or math.max(0,19-y))
  for x=16-width,16+width do
   pixel(head,x,y,col[1])
   if math.abs(x-16)<width and y>3 and y<18 then pixel(head,x,y,x<16 and col[3] or col[2]) end
  end
 end
 line(detail,16,5,16,16,col[2]); line(detail,12,5,19,5,col[3]); line(detail,11,8,11,12,col[3]); line(detail,14,18,18,18,col[3])
 if name=="wood" then line(detail,13,7,13,14,"70503b"); line(detail,19,8,19,14,"70503b") end
 for j,im in ipairs({shaft,head,detail}) do s:newCel(s.layers[j],i,im,Point(0,0)) end
end
for i,name in ipairs(names) do local tag=s:newTag(i,i); tag.name=name .. "_shovel" end
local source=root .. "/assets/sprites/source/frontier/shovels.aseprite"
s:saveAs(source); s:close()
dofile(root .. "/tools/export_shovels_aseprite.lua")
