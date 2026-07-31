local array = require("array")

local limit = 1000000
local a = array.new(limit)
a[1] = 3.3
a[4] = 8.9
print(" a[1] as array", a[1])
print(" a[4] as array", a[4])
-- print(" a[6] as array " , a[6]) -- nil

local mb = collectgarbage("count") / 1024
print(string.format("%.2f MB", mb))
