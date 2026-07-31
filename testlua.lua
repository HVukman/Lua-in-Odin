-- comparison with array defined in odin (script5.lua)
local a = {}
local limit = 1000000

for i = 1, limit do
    a[i] = 0.0
end

a[1] = 3.3
a[4] = 8.9

print(a[1])
print(a[4])


local mb = collectgarbage("count") / 1024
print(string.format("%.2f MB", mb))
