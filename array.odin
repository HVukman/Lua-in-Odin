package main

// Source:
// https://martin-fieber.de/blog/cpp-and-lua/#user-data

import "core:fmt"
import lua "vendor:lua/5.4" // or whatever version you want
import "core:c/libc"
import "base:runtime"

array :: struct {
    values: []f64,
}



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

array_meta := []lua.L_Reg{
    {"__index",  array_index},
    {"__newindex",  array_newindex},
    { "__gc", array_delete },
   /* {"set",  setarray},
    {"get",  getarray},
    {"size", getsize},*/
    {nil, nil},
}

arraylib := []lua.L_Reg{
    {"new",  luaarray_new},
   /* {"set",  setarray},
    {"get",  getarray},
    {"size", getsize},*/
    {nil, nil},
}

array_delete :: proc "c" (L: ^lua.State) -> i32 {

	context = runtime.default_context()
	n := int(lua.L_checkinteger(L, 1))
    nbytes :uint= uint(size_of(array) + (n - 1) * size_of(f64))

    a := cast(^array)lua.newuserdata(L, nbytes)
    delete (a.values)
	return 0
}

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

luaarray_open :: proc "c" (L: ^lua.State) -> i32 {

	context = runtime.default_context()
	lua.L_newmetatable(L, "array")
	lua.L_setfuncs(L, raw_data(array_meta), 0)
	lua.L_newlib(L, arraylib)
	return 1
}
