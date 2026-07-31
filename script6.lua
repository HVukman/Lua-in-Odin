-- script for color library
local color_ = require("colors")

local limit = 1000000
local pixels = color_.newpixels(limit)


for i = 1, limit - 1 do
    pixels:setpixel(i, 255, 255, 255)
end

local mb = collectgarbage("count") / 1024
print(string.format("%.2f MB", mb))
