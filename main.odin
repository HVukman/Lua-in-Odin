package main


import "core:fmt"
import lua "vendor:lua/5.4" // or whatever version you want
import "core:c/libc"
import "base:runtime"
import "core:testing"


open_sys :: proc "c" (L:^lua.State)->i32{

    context = runtime.default_context()
    L_Reg1 : lua.L_Reg
    v_aos: [1]lua.L_Reg
    v_aos[0]=L_Reg1


    return 1
}

hello_from_odin :: proc "c" (L:^lua.State)->i32{
    context = runtime.default_context()
    libc.printf("Calling Odin from Lua")
    libc.printf("\n")
    return 1
}

// define function in Odin for Lua
multiplication :: proc "c" (L:^lua.State) -> i32{
    // check if integer
    a:=lua.L_checkinteger(L,1)
    b:=lua.L_checkinteger(L,2)
    c:lua.Integer = a*b
    // push integer on stack
    lua.pushinteger(L,c)
    return 1
}





main :: proc() {



}

@(test)
testing ::proc(t: ^testing.T){
    L := lua.L_newstate(); // Create a new Lua state
    defer lua.close(L); // Clean up later
    if L == nil {
        fmt.println("Failed to create Lua state");
        return;
    }

    lua.L_openlibs(L); // Load Lua standard libraries

    lua.pushinteger(L,34) // push int on stack
    lua.setglobal(L,cstring("answer"))
    test: =  cstring("print(answer)")

    // doing a string in lua
	if lua.L_dostring(L, test) != 0 {
        fmt.println("Error executing Lua ");
    }

    script : cstring = "print('Hello from Lua!')";
    if lua.L_dostring(L, script) != 0 {
        fmt.println("Error executing Lua ");
    }

    lua.L_requiref(L,cstring("example"),hello_from_odin,1)
    lua.L_requiref(L, "sys", open_sys, 1)

     // calling sys
    if (lua.L_dofile(L,"main.lua")) == 0{
        lua.pop(L, lua.gettop(L))
    }


    // push c function on stack and setglobal or
    //  lua.pushcfunction(L, multiplication)
    //  lua.setglobal(L, "mul")
    // register function and global
    lua.register(L,"mul",multiplication)
    test2:=cstring("print(mul(7,6))")
    if lua.L_dostring(L, test2) != 0 {
        fmt.println("Error executing Lua script");
    }

    // creating a library mymath with function mul
    L_Reg1 : lua.L_Reg

    L_Reg1.func=multiplication
    L_Reg1.name=cstring("mul")


    // create new table
    lua.newtable(L)

    // set function multiplication
    lua.L_setfuncs(L,&L_Reg1, 0)

    lua.setglobal(L,cstring("mymath"))

    test3:=cstring("print(mymath.mul(3,3))")
    if lua.L_dostring(L, test3) != 0 {
        fmt.println("Error executing Lua script");
    }


    // doing a script
    if (lua.L_dofile(L,"script.lua")) == 0{
        lua.pop(L, lua.gettop(L))
    }
    else{
        fmt.println("couldnt load file")
    }

    // store information in script
    if (lua.L_dofile(L,"script2.lua")) == 0{
        lua.pop(L, lua.gettop(L))
    }
    else{
        fmt.println(" couldn't load file")
        lua.L_error(L, "Could not load file %s" , "script2.lua")
    }
    // get variable message from script
    lua.getglobal(L,cstring("message"))

    if (lua.isstring(L,-1)){
        answer:=lua.tostring(L,-1)
        lua.pop(L,1)
        fmt.println( "message from lua  \n", answer)
    }
    else{
        fmt.println("couldn't load script")
        lua.L_error(L, "Could not load file %s" , "script2.lua")
    }

    // calling a function
    if (lua.L_dofile(L,"script3.lua")) == 0{
        // if ok pop it from stack
        lua.pop(L, lua.gettop(L))
    }
    else{
        fmt.println("couldnt load file")
        lua.L_error(L, "Could not load file %s" , "script3.lua")
    }

    // pushing function on stack
    lua.getglobal(L,cstring("great_function"))

    if (lua.isfunction(L,-1)){
        // calling with no arguments
        if (lua.pcall(L,0,1,0) )== 0 {
            // if ok pop it from stack
            lua.pop(L,lua.gettop(L))
        }
        else{
            fmt.println("couldnt load function")
            lua.L_error(L, "Could not load function" )
        }

    }
    else{
        fmt.println("couldn't load script")
        lua.L_error(L, "Could not load file %s" , "script3.lua")
    }

    // calling a function that takes two argument and returns one
    // for script 4
    lua.L_loadfile(L,"script4.lua")
    // load file by calling it
    if (lua.pcall(L,0,1,0) ) == 0{
        lua.pop(L, lua.gettop(L))
    }
    else{
        fmt.println("couldnt load file script 4")
        lua.L_error(L, "Could not load file %s" , "script4.lua")
    }
    // get function and push arguments
    lua.getglobal(L,cstring("my_function"))
    lua.pushinteger(L,3)
    lua.pushinteger(L,34)

    // Execute my_function with 2 arguments and 1 return value
    // The two values on the stack are automatically consumed
        if (lua.pcall(L,2,1,0) )== 0 {

            if (lua.isinteger(L,-1)){
                result:=lua.tointeger(L,-1)
                lua.pop(L,lua.gettop(L))
                fmt.println("Result: ", result)
            }

        }
        else{
            fmt.println("couldnt load function")
        }

        lua.getglobal(L,cstring("my_function"))
        lua.pushnumber(L, 12.0)
        lua.pushinteger(L,34)

            if (lua.pcall(L,2,1,0) )== 0 {

                if (lua.isinteger(L,-1)){
                    result:=lua.tointeger(L,-1)
                    lua.pop(L,lua.gettop(L))
                    fmt.println("Result: ", result)
                }

            }
            else{
                fmt.println("couldnt load function")
            }

    // Using function consume_Table from script4.lua

    lua.getglobal(L,cstring("consume_table"))
    // pushing a table in odin

    lua.newtable(L)
    // Alternative: lua.createtable(L,0,2) sets space for 2 arguments

    lua.pushinteger(L,1) // push integer key
    lua.pushnumber(L,3.5)  // push number
    lua.settable(L,-3) // set field 1 of table on index -3 of stack

    lua.pushinteger(L,2) // push integer key
    lua.pushnumber(L,8.6) // push number
    lua.settable(L,-3) // set field 2 of table on index -3 of stack

    // call function consume_Table with 1 argument, the table on stack
    if (lua.pcall(L,1,1,0) )== 0 {

        if (lua.isnumber(L,-1)){
            result:=lua.tonumber(L,-1)
            lua.pop(L,lua.gettop(L))
            fmt.println("Result: ", f32(result))
        }

    }
    else{
    	fmt.println(lua.L_checkstring(L,-1))
        fmt.println("couldnt load function consume_table")
    }


    lua.getglobal(L,cstring("consume_table2"))
    lua.createtable(L,0,2)

    lua.pushinteger(L,1) // push integer key
    lua.pushnumber(L,5.5)  // push number
    lua.settable(L,-3) // set field 1 of table on index -3 of stack

    lua.pushinteger(L,2) // push integer key
    lua.pushnumber(L,18.6) // push number
    lua.settable(L,-3) // set field 2 of table on index -3 of stack

    // call function consume_table2 with 1 argument, the table on stack
    if (lua.pcall(L,1,1,0) )== 0 {
    // get table value stored with integer key
         lua.pushinteger(L,1) // push integer key
         lua.gettable(L,-2)
         result:= f32(lua.L_checknumber(L,-1))
         lua.pop(L,lua.gettop(L))
         fmt.printfln(" result consume_table2 %.2f" , result)

    }
    else{
    	fmt.println(lua.L_checkstring(L,-1))
        fmt.println("couldnt load function consume_table2")
    }

    faultystring: cstring = `printa+b)`
    rc := lua.L_dostring(L, faultystring)

    fmt.println("rc =", rc)

    if rc != 0 {
        err := lua.tostring(L, -1)
        fmt.println("Lua error:", err)
        lua.pop(L, 1)
    } else {
        fmt.println("ok")
    }


}
