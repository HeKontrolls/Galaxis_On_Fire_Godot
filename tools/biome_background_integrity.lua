-- Native Aseprite checks/repairs for solid landscape planes. Vegetation and
-- rock arches live in the detail layer, so their intentional openings remain.
local M={}
local pc=app.pixelColor
local function opaque(image,x,y) return pc.rgbaA(image:getPixel(x,y))>0 end

function M.foundation(shape,repair)
 local holes=0
 for x=0,shape.width-1 do
  local ground=false; local last=0
  for y=0,shape.height-1 do
   local c=shape:getPixel(x,y)
   if pc.rgbaA(c)>0 then ground=true; last=c
   elseif ground then holes=holes+1; if repair then shape:drawPixel(x,y,last) end end
  end
 end
 return holes
end

function M.orphans(shape,detail,repair)
 local w,h=shape.width,shape.height; local visited={}; local count,groups=0,0
 for y=0,h-1 do for x=0,w-1 do
  local start=y*w+x
  if not visited[start] and not opaque(shape,x,y) and opaque(detail,x,y) then
   local queue={start}; visited[start]=true; local head=1; local grounded=false
   while head<=#queue do
    local index=queue[head]; head=head+1
    local cx,cy=index%w,index//w
    for dy=-1,1 do for dx=-1,1 do
     local nx,ny=(cx+dx)%w,cy+dy
     if ny>=0 and ny<h then
      if opaque(shape,nx,ny) then grounded=true
      else
       local next=ny*w+nx
       if not visited[next] and opaque(detail,nx,ny) then visited[next]=true; queue[#queue+1]=next end
      end
     end
    end end
   end
   if not grounded then
    groups=groups+1; count=count+#queue
    if repair then for _,index in ipairs(queue) do detail:drawPixel(index%w,index//w,0) end end
   end
  end
 end end
 return count,groups
end

function M.repair(shape,detail)
 local holes=M.foundation(shape,true)
 local loose,groups=M.orphans(shape,detail,true)
 -- A quiet, opaque footing allows the engine to extend the panorama down
 -- without stretching speckles or water ripples into vertical stripes.
 local counts={}; local base=0; local largest=0; local w,h=shape.width,shape.height
 for x=0,w-1 do local c=shape:getPixel(x,h-1); counts[c]=(counts[c] or 0)+1
  if counts[c]>largest then largest=counts[c]; base=c end
 end
 local flat=pc.rgbaA(base)==255
 for y=h-8,h-1 do for x=0,w-1 do
  if shape:getPixel(x,y)~=base or opaque(detail,x,y) then flat=false end
 end end
 if not flat then
  for y=h-32,h-1 do
   local t=math.min(1,(y-(h-32))/23)
   for x=0,w-1 do
    local c=shape:getPixel(x,y)
    shape:drawPixel(x,y,pc.rgba(math.floor(pc.rgbaR(c)*(1-t)+pc.rgbaR(base)*t+.5),math.floor(pc.rgbaG(c)*(1-t)+pc.rgbaG(base)*t+.5),math.floor(pc.rgbaB(c)*(1-t)+pc.rgbaB(base)*t+.5),255))
    c=detail:getPixel(x,y)
    detail:drawPixel(x,y,pc.rgba(pc.rgbaR(c),pc.rgbaG(c),pc.rgbaB(c),math.floor(pc.rgbaA(c)*(1-t)+.5)))
   end
  end
 end
 for y=0,h-1 do shape:drawPixel(w-1,y,shape:getPixel(0,y)); detail:drawPixel(w-1,y,detail:getPixel(0,y)) end
 return holes,loose,groups
end

return M
