package main


import "core:fmt"
import lua "vendor:lua/5.4" // or whatever version you want
import "core:c/libc"
import "base:runtime"
import "core:testing"

PixelArray :: struct {
    pixels: []pixel,
    index: int
}


pixel :: struct {
	red : u8,
	green : u8,
	blue : u8,
}

// make new pixel in color array
// pixel_array[1].r = 244
color_newindex :: proc "c" (L: ^lua.State ) -> i32 {

	context = runtime.default_context()

    return 0

}

// get pixel index from color array
color_index :: proc "c" (L: ^lua.State ) -> i32 {


	context = runtime.default_context()

    return 1

}


pixel_meta := []lua.L_Reg{
    {"getr",  getr},
    {"getb",  getb},
    {"getg" , getg},
    {"setr",  setr},
    {"setb",  setb},
    {"setg" , setg},

    {nil, nil},
}

color_meta := []lua.L_Reg{
    {"getpixel" , getpixel},
    {"setpixel" , setpixel},
    {"size" , size},
    {nil, nil},
}

colorlib := []lua.L_Reg{
	 {"newpixel",  pixel_new},
    {"newpixels",  pixels_new},

    {nil, nil},
}

size :: proc "c" (L: ^lua.State) -> i32 {

	context = runtime.default_context()
    v := cast(^PixelArray)lua.L_checkudata(L, 1, "PixelArrayMT")
    lua.pushinteger(L, lua.Integer(len(v.pixels)))
    return 1
}


// new pixel
//
//
pixel_new :: proc "c" (L: ^lua.State) -> i32 {

	context = runtime.default_context()
	r := lua.L_checkinteger(L,1)
	g := lua.L_checkinteger(L,2)
	b := lua.L_checkinteger(L,3)

	v:= cast(^pixel)lua.newuserdata(L, size_of(pixel))
	lua.L_getmetatable(L, "PixelMT")
	lua.setmetatable(L,-2)

    return 1
}
getr :: proc "c" (L: ^lua.State) -> i32 {

	v:= cast(^pixel)lua.L_checkudata(L,1,"PixelMT")
	lua.pushinteger(L, lua.Integer(v.red))
	return 1
}

getb :: proc "c" (L: ^lua.State) -> i32 {

	v:= cast(^pixel)lua.L_checkudata(L,1,"PixelMT")
	lua.pushinteger(L, lua.Integer(v.blue))
	return 1
}

getg :: proc "c" (L: ^lua.State) -> i32 {

	v:= cast(^pixel)lua.L_checkudata(L,1,"PixelMT")
	lua.pushinteger(L, lua.Integer(v.green))
	return 1
}

setr :: proc "c" (L: ^lua.State) -> i32 {

	v:= cast(^pixel)lua.L_checkudata(L,1,"PixelMT")
	r := lua.L_checknumber(L,2)
	v.red = u8(r)
	return 0
}

setb :: proc "c" (L: ^lua.State) -> i32 {

	v:= cast(^pixel)lua.L_checkudata(L,1,"PixelMT")
	b := lua.L_checknumber(L,2)
	v.blue = u8(b)
	return 0
}

setg :: proc "c" (L: ^lua.State) -> i32 {

	v:= cast(^pixel)lua.L_checkudata(L,1,"PixelMT")
	g := lua.L_checknumber(L,2)
	v.green = u8(g)
	return 0
}

// new pixel vector
pixels_new :: proc "c" (L: ^lua.State) -> i32 {

	context = runtime.default_context()
	n:= lua.L_checkinteger(L,1)
	nbytes:= uint(size_of(PixelArray) + (n-1)* size_of(pixel))
	a := cast(^PixelArray)lua.newuserdata(L, nbytes)
	a.pixels= make([]pixel, n)
    a.index = 0  // or whatever default you want

	lua.L_getmetatable(L, "PixelArrayMT")
	lua.setmetatable(L,-2)

    return 1
}

setpixel :: proc "c" (L: ^lua.State) -> i32 {


    // Get the PixelArray userdata
    v := cast(^PixelArray)lua.L_checkudata(L, 1, "PixelArrayMT")


    index := int(lua.L_checkinteger(L, 2))


    // Get the RGB values
    r := u8(lua.L_checkinteger(L, 3))
    g := u8(lua.L_checkinteger(L, 4))
    b := u8(lua.L_checkinteger(L, 5))

    // Cast the raw data pointer to pixel array
    pixels := cast([]pixel)v.pixels

    // Set the pixel (convert to 0-based index)
    pixels[index - 1].red = r
    pixels[index - 1].green = g
    pixels[index - 1].blue = b
    return 0
}


getpixel :: proc "c" (L: ^lua.State) -> i32 {


	context = runtime.default_context()

	v:= cast(^PixelArray)lua.L_checkudata(L,1,"PixelArrayMT")
	index := int(lua.L_checkinteger(L,2))
	pxiel_:= cast(^pixel)lua.newuserdata(L, size_of(pixel))
	pxiel_.blue = v.pixels[index-1].blue
	pxiel_.red = v.pixels[index-1].red
	pxiel_.green= v.pixels[index-1].green

	lua.L_getmetatable(L, "PixelMT")
	lua.setmetatable(L,-2)
	return 1
}

// https://www.lua.org/pil/28.3.html
luacolor_open :: proc "c" (L: ^lua.State) -> i32 {

	context = runtime.default_context()
	lua.L_newmetatable(L, "PixelMT")
	lua.L_newlib(L, pixel_meta)
	lua.setfield(L,-2, "__index")
	lua.pop(L,1)

	lua.L_newmetatable(L, "PixelArrayMT")
	lua.L_newlib(L, color_meta)
	lua.setfield(L,-2, "__index")
	lua.pop(L,1)


	lua.L_newlib(L, colorlib)
	return 1
}
