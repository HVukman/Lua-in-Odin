-- Using array library
local array = require("array")

local limit = 1000000
local a = array.new(limit)
local b = array.new(limit - 100)
a[1] = 3.3
a[4] = 8.9
b[1] = 4.0
print("length a ", #a)
print("length b ", #b)
print(" a[1] as array", a[1])
print(" a[4] as array", a[4])

local conc = a .. b
print("conc a b ", #conc)

local added = a + a
print(" a plus a [1] ", added[1])

local newa = array.new(limit)
local newb = array.new(limit)

local rand = math.random()

for i = 1, limit do
    newa[i] = rand
    newb[i] = rand
end

-- unary minus
newa = -newa

-- equality operators
local check1 = newa < newb
local check2 = newa == newb
local check3 = newa <= newb

-- check1 and check3 should be true
print ("checks " , check1 , check2, check3)

local nClock = os.clock()
local mul_ab
mul_ab = newa * newb
print("mul newa newb ", mul_ab[3])
print("multiply took with arrays ", os.clock() - nClock)

local tablenewa = {}
local tablenewb = {}
local tablemulab = {}

for i = 1, (#mul_ab) do
    table.insert(tablenewa, rand)
    table.insert(tablenewb, rand)
    table.insert(tablemulab, 0.0)     -- preallocate table
end

nClock = os.clock()
for i = 1, (limit) do
    table.insert(tablemulab, tablenewa[i] * tablenewb[i])
end
print("multable ab ", tablemulab[3])
print("multiply took with tables", os.clock() - nClock)


-- print(" a[6] as array " , a[6]) -- nil

local mb = collectgarbage("count") / 1024
print(string.format("%.2f MB", mb))
