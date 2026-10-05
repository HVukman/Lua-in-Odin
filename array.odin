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
