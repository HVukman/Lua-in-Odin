Adapted from: https://lucasklassmann.com/blog/2019-02-02-embedding-lua-in-c/

Just run: 
```
odin test .
```
Shows:
  * Starting a Lua state
  * Defining variables for Lua
  * Doing Lua Strings in Odin
  * Loading scripts
  * Creating functions in Odin for Lua
  * Creating a namespace in Odin for Lua and adding functions
  * Calling Lua functions from Odin with and without return
  * Getting errors from Lua

Don't forget the Lua files.

Update 08-05-2025: Removed the dynamic allocations, since they are not needed. Added tests. Trying to do metatables, but the fields of the 
tables are not recognized.

Update 05-21-2026 : Removed metatables. Added luafile example.

Update 07-30-2026 : Showed how to add tables in Odin and how to pass them to functions.

Update 07-31-2026 : Figured out metatables and userdata. Showed two examples in script5 and script6.lua. Testlua scripts show the comparison in pure Lua. Way less Ram is used with Userdata.

## Quickstart

```
package main


import "core:fmt"
import lua "vendor:lua/5.4" // or other version


main :: proc() {


	L := lua.L_newstate(); // Create a new Lua state
    defer lua.close(L); // Clean up later
    if L == nil {
        fmt.println("Failed to create Lua state");
        return;
    }
     lua.L_openlibs(L); // Load Lua standard libraries
    // doing a script example: script.lua
	/*
	print("hello world")
	*/
    if (lua.L_dofile(L,"script.lua")) == 0{
        lua.pop(L, lua.gettop(L))
    }
    else{
        fmt.println("couldnt load file")
    }
}

```
## Creating Userdata

Userdata is created via Metatables. Here is the array library (Update 10-05-2026, added metamethods, adopted from [here](https://www.lua.org/pil/28.1.html)):
```
package main

// Kinda Source:
// https://martin-fieber.de/blog/cpp-and-lua/#user-data

import "core:fmt"
import lua "vendor:lua/5.4"
import "core:c/libc"
import "base:runtime"
import "core:slice"
import "core:math"

array :: struct {
    values: []f64,
}


// Create an entry in an array
array_newindex :: proc "c" (L: ^lua.State ) -> i32 {

	context = runtime.default_context()

	a := cast(^array)lua.touserdata(L, 1)

    //lua.L_argcheck(L, a != nil, 1, "array expected")

    index := int(lua.L_checkinteger(L, 2))
	val := f64(lua.L_checknumber(L, 3))


	/*
    lua.L_argcheck(
        L,
        1 <= index && index <= len(a.values),
        2,
        "index out of range",
    )
    */


    a.values[index-1] = val


    return 0

}

// get index from array
array_index :: proc "c" (L: ^lua.State ) -> i32 {

	context = runtime.default_context()

	a := cast(^array)lua.touserdata(L, 1)

   // lua.L_argcheck(L, a != nil, 1, "array expected")

    index := int(lua.L_checkinteger(L, 2))

   /* lua.L_argcheck(
        L,
        1 <= index && index <= len(a.values),
        2,
        "index out of range",
    )
    */

    lua.pushnumber(L, lua.Number(a.values[index-1]))

    return 1

}

// array length
// #a
array_length :: proc "c" (L: ^lua.State) -> i32 {

	context = runtime.default_context()
	a := cast(^array)lua.touserdata(L, 1)
    lua.pushinteger(L, lua.Integer(len(a.values)))
	return 1
}


// concatenate operator
// a..b
array_concat :: proc "c" (L: ^lua.State) -> i32 {
    context = runtime.default_context()

    a := cast(^array)lua.L_checkudata(L, 1, "array")
    b := cast(^array)lua.L_checkudata(L, 2, "array")

    total := len(a.values) + len(b.values)
    nbytes :uint= uint(size_of(array) + (total ) * size_of(f64))
    result := cast(^array)lua.newuserdata(L, nbytes)

    result.values = make([]f64, total)

    for i in 0 ..< len(a.values) {
        result.values[i] = a.values[i]
    }
    for i in 0 ..< len(b.values){
        result.values[len(a.values) + i] = b.values[i]
    }

    lua.L_setmetatable(L, "array")
    return 1
}

// addition operator
// a+ b

array_add :: proc "c" (L: ^lua.State) -> i32 {
    context = runtime.default_context()

    a := cast(^array)lua.L_checkudata(L, 1, "array")
    b := cast(^array)lua.L_checkudata(L, 2, "array")


    if len(a.values)!=len(b.values) {
    	lua.L_error(L, "Arrays must be of same length!")
     	return 0
    }

    total := len(a.values) + len(b.values)
    nbytes :uint= uint(size_of(array) + (total ) * size_of(f64))
    result := cast(^array)lua.newuserdata(L, nbytes)

    result.values = make([]f64, total)

    for i in 0 ..< len(a.values) {
        result.values[i] = a.values[i] + b.values[i]
    }

    lua.L_setmetatable(L, "array")
    return 1
}

// subtract operator
// a - b

array_sub :: proc "c" (L: ^lua.State) -> i32 {
    context = runtime.default_context()

    a := cast(^array)lua.L_checkudata(L, 1, "array")
    b := cast(^array)lua.L_checkudata(L, 2, "array")


    if len(a.values)!=len(b.values) {
    	lua.L_error(L, "Arrays must be of same length!")
     	return 0
    }

    total := len(a.values) - len(b.values)
    nbytes :uint= uint(size_of(array) + (total ) * size_of(f64))
    result := cast(^array)lua.newuserdata(L, nbytes)

    result.values = make([]f64, total)

    for i in 0 ..< len(a.values) {
        result.values[i] = a.values[i] + b.values[i]
    }

    lua.L_setmetatable(L, "array")
    return 1
}

// mul operator
// a * b

array_mul :: proc "c" (L: ^lua.State) -> i32 {
    context = runtime.default_context()

    a := cast(^array)lua.L_checkudata(L, 1, "array")
    b := cast(^array)lua.L_checkudata(L, 2, "array")


    if len(a.values)!=len(b.values) {
    	lua.L_error(L, "Arrays must be of same length!")
     	return 0
    }

    total := len(a.values)
    nbytes :uint= uint(size_of(array) + (total ) * size_of(f64))
    result := cast(^array)lua.newuserdata(L, nbytes)

    result.values = make([]f64, total)

    for i in 0 ..< len(a.values) {
        result.values[i] = a.values[i] * b.values[i]
    }

    lua.L_setmetatable(L, "array")
    return 1
}

// div operator
// a / b

array_div :: proc "c" (L: ^lua.State) -> i32 {
    context = runtime.default_context()

    a := cast(^array)lua.L_checkudata(L, 1, "array")
    b := cast(^array)lua.L_checkudata(L, 2, "array")


    if len(a.values)!=len(b.values) {
    	lua.L_error(L, "Arrays must be of same length!")
     	return 0
    }

    total := len(a.values)
    nbytes :uint= uint(size_of(array) + (total ) * size_of(f64))
    result := cast(^array)lua.newuserdata(L, nbytes)

    result.values = make([]f64, total)

    for i in 0 ..< len(a.values) {
        result.values[i] = a.values[i] / b.values[i]
    }

    lua.L_setmetatable(L, "array")
    return 1
}

// pow operator
// a ^ b

array_pow :: proc "c" (L: ^lua.State) -> i32 {
    context = runtime.default_context()

    a := cast(^array)lua.L_checkudata(L, 1, "array")
    b := cast(^array)lua.L_checkudata(L, 2, "array")


    if len(a.values)!=len(b.values) {
    	lua.L_error(L, "Arrays must be of same length!")
     	return 0
    }

    total := len(a.values)
    nbytes :uint= uint(size_of(array) + (total ) * size_of(f64))
    result := cast(^array)lua.newuserdata(L, nbytes)

    result.values = make([]f64, total)

    for i in 0 ..< len(a.values) {
        result.values[i] = math.pow_f64( a.values[i] , b.values[i])
    }

    lua.L_setmetatable(L, "array")
    return 1
}

// equality operator
// a == b

array_eq :: proc "c" (L: ^lua.State) -> i32 {
    context = runtime.default_context()

    a := cast(^array)lua.L_checkudata(L, 1, "array")
    b := cast(^array)lua.L_checkudata(L, 2, "array")


    if len(a.values)!=len(b.values) {
    	lua.L_error(L, "Arrays must be of same length!")
     	return 0
    }

    res := true


    for i in 0 ..< len(a.values) {
        res = a.values[i] == b.values[i]
        if res ==false{
        	break
        }
    }

    lua.pushboolean(L,b32(res))

    return 1
}


// less than operator
// a <  b

array_lt :: proc "c" (L: ^lua.State) -> i32 {
	context = runtime.default_context()

    a := cast(^array)lua.L_checkudata(L, 1, "array")
    b := cast(^array)lua.L_checkudata(L, 2, "array")


    if len(a.values)!=len(b.values) {
    	lua.L_error(L, "Arrays must be of same length!")
     	return 0
    }

    res := true


    for i in 0 ..< len(a.values) {
        res = a.values[i] < b.values[i]
        if res ==false{
        	break
        }
    }

    lua.pushboolean(L,b32(res))

    return 1
}

// less equal than operator
// a <= b

array_le :: proc "c" (L: ^lua.State) -> i32 {
	context = runtime.default_context()

    a := cast(^array)lua.L_checkudata(L, 1, "array")
    b := cast(^array)lua.L_checkudata(L, 2, "array")


    if len(a.values)!=len(b.values) {
    	lua.L_error(L, "Arrays must be of same length!")
     	return 0
    }

    res := true


    for i in 0 ..< len(a.values) {
        res = a.values[i] <= b.values[i]
        if res ==false{
        	break
        }
    }

    lua.pushboolean(L,b32(res))

    return 1
}


// unary minus
// -a

array_unm :: proc "c" (L: ^lua.State) -> i32 {
    context = runtime.default_context()

    a := cast(^array)lua.L_checkudata(L, 1, "array")

    total := len(a.values)
    nbytes :uint= uint(size_of(array) + (total ) * size_of(f64))
    result := cast(^array)lua.newuserdata(L, nbytes)

    result.values = make([]f64, total)

    for i in 0 ..< len(a.values) {
        result.values[i] = -a.values[i]
    }

    lua.L_setmetatable(L, "array")
    return 1
}

// metatable methods
array_meta := []lua.L_Reg{
    {"__index",  array_index},
    {"__newindex",  array_newindex},
    { "__gc", array_delete }, // set the garbage method
    { "__len", array_length }, // set the length method (#array)
    { "__add", array_add }, // a+b (where a and b are arrays)
    { "__sub", array_sub }, // a-b
    { "__mul", array_mul}, // a*b
    { "__div", array_div}, // a/b
    { "__pow", array_pow}, // a^b
    { "__eq", array_eq}, // a==b
    { "__lt", array_lt}, // a<b
    { "__le", array_le}, // a<=b
    { "__unm", array_unm}, // -a
    { "__concat", array_concat },
    {nil, nil},
}

arraylib := []lua.L_Reg{
    {"new",  luaarray_new},
    {nil, nil},
}

// called when garbage collecting
array_delete :: proc "c" (L: ^lua.State) -> i32 {

	context = runtime.default_context()
	a := cast(^array)lua.touserdata(L, 1)
    delete (a.values)
	return 0
}

lua_array_sort :: proc "c" (L: ^lua.State) -> i32 {

	context = runtime.default_context()
 	a := cast(^array)lua.L_checkudata(L, 1, "array")

    cool_slice := a.values
    slice.sort(cool_slice)

    for i:=1;i<len(a.values);i+=1{
    	a.values[i] = cool_slice[i]
    }
	return 0
}

lua_array_binsearch :: proc "c" (L: ^lua.State) -> i32 {

	context = runtime.default_context()

 	a := cast(^array)lua.L_checkudata(L, 1, "array")
    b:= lua.L_checknumber(L,2)

    idx,found := slice.binary_search(a.values[0:len(a.values)],f64(b))
    if found{
    	lua.pushinteger(L,lua.Integer(idx+1)) // to match luaarray
     	return 1
    }else{
    	lua.pushboolean(L,b32(found))
     	return 1
    }
	return 0
}


// Create a new array of size n
luaarray_new :: proc "c" (L: ^lua.State) -> i32 {

	context = runtime.default_context()
	n := int(lua.L_checkinteger(L, 1))
    nbytes :uint= uint(size_of(array) + (n - 1) * size_of(f64))

    a := cast(^array)lua.newuserdata(L, nbytes)
    a.values = make([]f64, n)
    // userdata is already on the Lua stack
	lua.L_setmetatable(L, "array")
	return 1
}

// Register the new library
luaarray_open :: proc "c" (L: ^lua.State) -> i32 {

	context = runtime.default_context()
	lua.L_newmetatable(L, "array")
	lua.L_setfuncs(L, raw_data(array_meta), 0)
	lua.L_newlib(L, arraylib)
	return 1
}

```
This userdata needs to be deleted with an extra GC method, if it needs to be deleted in Odin too. Likewise for example, Textures in Raylib etc.
This wastes way less Ram than an equivalent Lua program. 
Update 10-05-2026 : I added new metamethods to the array class. Now you can add, subtract and compare arrays.

```
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


```
Testscript in Lua: (testlua.lua)
```
-- comparison with array defined in odin (script5.lua)
local a = {}
local limit = 100000

for i = 1, limit do
    a[i] = 0.0
end

a[1] = 3.3
a[4] = 8.9

print(a[1])
print(a[4])


local mb = collectgarbage("count") / 1024
print(string.format("%.2f MB", mb))

```


```
odin run .
a[1] as array  3.3
a[4] as array  8.9
0.78 MB
```

```
lua .\testlua.lua
3.3
8.9
2.02 MB
```

More than half of memory less is used. Is it faster? For small arrays: No. Yes, for very big arrays. Lua tables are highly optimized for access. 
