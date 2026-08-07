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

## Creating Userdata

Userdata is created via Metatables. Here is the array library (adopted from [here](https://www.lua.org/pil/28.1.html):
```

package main

import "core:fmt"
import lua "vendor:lua/5.4"
import "core:c/libc"
import "base:runtime"

array :: struct {
    values: []f64,
}


array_newindex :: proc "c" (L: ^lua.State ) -> i32 {

	context = runtime.default_context()

	a := cast(^array)lua.touserdata(L, 1)
    index := int(lua.L_checkinteger(L, 2))
	val := f64(lua.L_checknumber(L, 3))
    a.values[index-1] = val
    return 0

}


array_index :: proc "c" (L: ^lua.State ) -> i32 {

	context = runtime.default_context()
	a := cast(^array)lua.touserdata(L, 1)
    index := int(lua.L_checkinteger(L, 2))
    lua.pushnumber(L, lua.Number(a.values[index-1]))

    return 1

}


array_meta := []lua.L_Reg{
    {"__index",  array_index},
    {"__newindex",  array_newindex},
    { "__gc", array_delete }, // set the garbage method

    {nil, nil},
}

arraylib := []lua.L_Reg{
    {"new",  luaarray_new},
    {nil, nil},
}


array_delete :: proc "c" (L: ^lua.State) -> i32 {

	context = runtime.default_context()
	a := cast(^array)lua.touserdata(L, 1)
    delete (a.values)
	return 0
}


luaarray_new :: proc "c" (L: ^lua.State) -> i32 {

	context = runtime.default_context()
	n := int(lua.L_checkinteger(L, 1))
    nbytes :uint= uint(size_of(array) + (n - 1) * size_of(f64)) // This is the most important part. Make room for the data.

    a := cast(^array)lua.newuserdata(L, nbytes)
    a.values = make([]f64, n)
	lua.L_setmetatable(L, "array")
	return 1
}


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

```
-- Using array library
local array = require("array")

local limit = 100000
local a = array.new(limit)
a[1] = 3.3
a[4] = 8.9
print(" a[1] as array", a[1])
print(" a[4] as array", a[4])
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

More than half of memory less is used. Is it faster? No. Lua tables are highly optimized for access. 
