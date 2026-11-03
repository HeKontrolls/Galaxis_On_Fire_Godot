-- Original adventurer with Terraria-inspired proportions. Edits only the
-- captain and articulated arm documents inside Aseprite.
local root=assert(app.params.root)
local source=root .. "/assets/sprites/source/frontier/"
local function color(hex) return app.pixelColor.rgba(tonumber(hex:sub(1,2),16),tonumber(hex:sub(3,4),16),tonumber(hex:sub(5,6),16),255) end
local p={}
for key,hex in pairs({ink="292935",hair="654735",hairdark="402e30",hairhi="9b744a",
  skin="edb78f",skinhi="ffdab0",skinshade="bd826d",eye="f5f0d8",pupil="2b3748",
  shirt="477f94",shirtlight="7bbac1",shirtshade="31596e",collar="cfddc9",
  pants="495f80",pantslight="7895b0",pantsshade="303e59",shoe="513c3b",shoelight="8b6951",
  belt="70503a",brass="d0ad70"}) do p[key]=color(hex) end
local function pixel(im,x,y,c) if x>=0 and y>=0 and x<im.width and y<im.height then im:drawPixel(x,y,c) end end
local function rect(im,x,y,w,h,c) for yy=y,y+h-1 do for xx=x,x+w-1 do pixel(im,xx,yy,c) end end end
local function line(im,x,y,xx,yy,c,w)
  local dx=math.abs(xx-x); local sx=x<xx and 1 or -1; local dy=-math.abs(yy-y); local sy=y<yy and 1 or -1; local err=dx+dy
  while true do
    local width=w or 1; rect(im,x-math.floor(width/2),y-math.floor(width/2),width,width,c)
    if x==xx and y==yy then break end
    local e=err*2; if e>=dy then err=err+dy; x=x+sx end; if e<=dx then err=err+dx; y=y+sy end
  end
end
local function poly(im,points,c)
  local lo,hi=99,0; for _,v in ipairs(points) do lo=math.min(lo,v[2]); hi=math.max(hi,v[2]) end
  for y=lo,hi do
    local xs={}
    for i,a in ipairs(points) do local b=points[i%#points+1]
      if (a[2]<=y and b[2]>y) or (b[2]<=y and a[2]>y) then table.insert(xs,a[1]+(y-a[2])*(b[1]-a[1])/(b[2]-a[2])) end
    end
    table.sort(xs); for i=1,#xs-1,2 do for x=math.ceil(xs[i]),math.floor(xs[i+1]) do pixel(im,x,y,c) end end
  end
  for i,a in ipairs(points) do local b=points[i%#points+1]; line(im,a[1],a[2],b[1],b[2],c) end
end
local function border(im,x,y,w,h,c) rect(im,x,y,w,h,p.ink); rect(im,x+1,y+1,w-2,h-2,c) end
local function player(action,n)
  local back,legs,body,head,details=Image(32,40),Image(32,40),Image(32,40),Image(32,40),Image(32,40)
  local bob=action=="walk" and ({0,-1,-1,0,-1,-1})[n+1] or (action=="idle" and n==2 and -1 or 0)
  local step=action=="walk" and ({-3,-1,2,3,1,-2})[n+1] or 0
  local front=action=="walk" and ({0,2,3,0,0,0})[n+1] or 0
  local rear=action=="walk" and ({0,0,0,0,2,3})[n+1] or 0
  if action=="jump" then step=({-1,-2,-3,-3,-2,-1,0,1,1})[n+1]; front=({1,2,3,4,4,3,2,1,0})[n+1]; rear=front+1 end
  -- Rear arm: short sleeve and bare wrist, swinging against the stride.
  local arm=action=="walk" and math.floor(-step/2) or 0
  border(back,8+arm,18+bob,5,8,p.shirtshade)
  border(back,8+arm,24+bob,5,6,p.skinshade); rect(back,9+arm,25+bob,3,3,p.skin)
  -- Trouser knees and separated shoes form the movement silhouette.
  line(legs,13,29,13-step,36-rear,p.ink,5); line(legs,13,29,13-step,35-rear,p.pantsshade,3)
  border(legs,10-step,36-rear,7,4,p.shoe); rect(legs,11-step,37-rear,4,1,p.shoelight)
  line(legs,19,29,19+step,36-front,p.ink,5); line(legs,19,29,19+step,35-front,p.pants,3)
  line(legs,19,30,19+step,34-front,p.pantslight)
  border(legs,17+step,36-front,7,4,p.shoe); rect(legs,18+step,37-front,4,1,p.shoelight)
  -- Plain tunic with a light collar and compact belt, no headgear or pack.
  poly(body,{{12,16+bob},{19,16+bob},{23,19+bob},{22,29},{10,29},{9,21+bob}},p.ink)
  poly(body,{{12,17+bob},{19,17+bob},{21,20+bob},{20,28},{12,28},{11,21+bob}},p.shirt)
  rect(body,11,20+bob,2,7,p.shirtshade); rect(body,15,20+bob,3,6,p.shirtlight)
  rect(body,11,28,11,3,p.belt); rect(body,16,29,3,1,p.brass)
  rect(details,14,16+bob,5,2,p.skinshade); line(details,13,18+bob,17,19+bob,p.collar)
  rect(details,20,19+bob,2,3,p.shirtlight)
  -- Rounded head and short one-pixel nose. A high-contrast eye remains
  -- readable at the actual 32x40 game scale rather than only in a zoom.
  poly(head,{{12,5+bob},{19,4+bob},{22,7+bob},{22,11+bob},{23,12+bob},{22,14+bob},{20,16+bob},{14,16+bob},{11,13+bob},{10,8+bob}},p.ink)
  poly(head,{{13,7+bob},{19,6+bob},{21,8+bob},{21,11+bob},{22,12+bob},{21,13+bob},{19,15+bob},{14,15+bob},{12,12+bob}},p.skin)
  rect(head,13,11+bob,2,3,p.skinshade); rect(head,15,12+bob,4,2,p.skinhi)
  poly(head,{{10,7+bob},{11,4+bob},{14,4+bob},{15,3+bob},{18,4+bob},{21,3+bob},{23,6+bob},{22,9+bob},{19,8+bob},{17,10+bob},{15,8+bob},{13,9+bob},{12,12+bob},{10,11+bob}},p.hairdark)
  poly(head,{{12,5+bob},{15,5+bob},{16,4+bob},{19,5+bob},{21,5+bob},{22,7+bob},{19,7+bob},{17,8+bob},{14,7+bob},{12,9+bob}},p.hair)
  line(head,13,5+bob,15,5+bob,p.hairhi); line(head,18,6+bob,20,6+bob,p.hairhi)
  if action=="idle" and n==3 then line(head,18,11+bob,21,11+bob,p.skinshade)
  else rect(head,18,10+bob,3,3,p.eye); rect(head,20,10+bob,1,3,p.pupil) end
  pixel(head,22,12+bob,p.skinhi); pixel(head,20,14+bob,p.skinshade)
  return {back,legs,body,head,details}
end
local captain=assert(app.open(source .. "captain.aseprite"))
for i,name in ipairs({"Rear arm","Legs and shoes","Shirt and belt","Hair and face","Cloth details"}) do captain.layers[i].name=name end
for _,tag in ipairs(captain.tags) do
  local action,direction=tag.name:match("^(%w+)_(%w+)$")
  for index=tag.fromFrame.frameNumber,tag.toFrame.frameNumber do
    local images=player(action,index-tag.fromFrame.frameNumber)
    for layer,im in ipairs(images) do
      if direction=="west" then im:flip(FlipType.HORIZONTAL) end
      captain.layers[layer]:cel(index).image=im
    end
  end
end
local metadata=json.decode(captain.data); metadata.design="Original rounded-head adventurer; mouse-controlled articulated front arm"; captain.data=json.encode(metadata)
captain:saveAs(source .. "captain.aseprite"); captain:close()
local arms=assert(app.open(source .. "captain_parts.aseprite"))
for _,tag in ipairs(arms.tags) do
  local im,detail=Image(8,12),Image(8,12)
  if tag.name=="hand" then border(im,2,4,4,5,p.skinshade); rect(detail,3,5,2,2,p.skinhi)
  elseif tag.name=="upper_arm" then
    border(im,2,0,4,12,p.shirtshade); line(detail,3,1,3,6,p.shirtlight); rect(detail,3,8,2,3,p.skin)
  else border(im,2,0,4,12,p.skinshade); rect(detail,3,1,2,9,p.skin); line(detail,3,2,3,7,p.skinhi) end
  arms.layers[1]:cel(tag.fromFrame.frameNumber).image=im
  arms.layers[2]:cel(tag.fromFrame.frameNumber).image=detail
end
arms:saveAs(source .. "captain_parts.aseprite"); arms:close()
dofile(root .. "/tools/export_aseprite_art.lua")
print("ASEPRITE_PLAYER_REVISION complete")
