-- Sparse deliberate highlight clusters; do not bury readable color masses in noise.
return function(a,b,out,family,morph,pose,pal)
 local function rgba(h) return app.pixelColor.rgba(tonumber(h:sub(1,2),16),tonumber(h:sub(3,4),16),tonumber(h:sub(5,6),16),255) end
 local mid,light=rgba(pal[2]),rgba(pal[3])
 local function sample(x,y)
  if x<0 or x>=48 or y<0 or y>=40 then return 0 end
  local c=b:getPixel(x,y);return app.pixelColor.rgbaA(c)>0 and c or a:getPixel(x,y)
 end
 for y=16,28 do for x=12,29 do
  -- Small scale/fur glints only inside the midtone, keeping faces and silhouettes clear.
  if (x+family*2)%7==0 and (y+math.floor(x/7)*3)%8==0 and sample(x,y)==mid and sample(x+1,y)==mid and sample(x,y-1)==mid and sample(x,y+1)==mid then
   out:drawPixel(x,y,light);out:drawPixel(x+1,y,light)
  end
 end end
end
