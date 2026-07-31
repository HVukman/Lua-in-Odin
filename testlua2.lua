-- comparison with color in odin (script6.lua)
local limit = 1000000

local colors = {}
local gray = {255,255,255}
for i = 1, limit  do
    table.insert(colors, gray)
end

local mb = collectgarbage("count") / 1024
print(string.format("%.2f MB", mb))
