-- for Lua 5.1 (emulating bitwise operators)
-- lua 5.1 doesn't support bitwise operation yet
-- copy from acn.sha2.lua


local acn_bitwise = {}
--local AND, OR, XOR, SHL, SHR, ROL, ROR, NOT, NORM, HEX, XOR_BYTE

local AND_of_two_bytes = {[0] = 0}  -- look-up table (256*256 entries)
local idx = 0
for y = 0, 127 * 256, 256 do
   for x = y, y + 127 do
      x = AND_of_two_bytes[x] * 2
      AND_of_two_bytes[idx] = x
      AND_of_two_bytes[idx + 1] = x
      AND_of_two_bytes[idx + 256] = x
      AND_of_two_bytes[idx + 257] = x + 1
      idx = idx + 2
   end
   idx = idx + 256
end

local function and_or_xor(x, y, operation)
   -- operation: nil = AND, 1 = OR, 2 = XOR
   local x0 = x % 2^32
   local y0 = y % 2^32
   local rx = x0 % 256
   local ry = y0 % 256
   local res = AND_of_two_bytes[rx + ry * 256]
   x = x0 - rx
   y = (y0 - ry) / 256
   rx = x % 65536
   ry = y % 256
   res = res + AND_of_two_bytes[rx + ry] * 256
   x = (x - rx) / 256
   y = (y - ry) / 256
   rx = x % 65536 + y % 256
   res = res + AND_of_two_bytes[rx] * 65536
   res = res + AND_of_two_bytes[(x + y - rx) / 256] * 16777216
   if operation then
      res = x0 + y0 - operation * res
   end
   return res
end

function acn_bitwise.AND(x, y)
   return and_or_xor(x, y)
end

function acn_bitwise.OR(x, y)
   return and_or_xor(x, y, 1)
end

function acn_bitwise.XOR(x, y, z, t, u)          -- 2..5 arguments
   if z then
      if t then
         if u then
            t = and_or_xor(t, u, 2)
         end
         z = and_or_xor(z, t, 2)
      end
      y = and_or_xor(y, z, 2)
   end
   return and_or_xor(x, y, 2)
end

function acn_bitwise.lshift(x, by)
   return x * 2 ^ by
end

function acn_bitwise.dectohex(x)
   local B,K,OUT,I,D=16,"0123456789abcdef","",0
   while x > 0 do
       I=I+1
       x,D=math.floor(x/B),math.mod(x,B)+1
       OUT=string.sub(K,D,D)..OUT
   end
   return OUT
end

return acn_bitwise