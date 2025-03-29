package main

import "core:fmt"
import lua "vendor:lua/5.4" // or whatever version you want
import "core:c"
import "base:runtime"

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

    v_aos: [dynamic]lua.L_Reg 
    defer delete(v_aos)

    append(&v_aos,L_Reg1)

    // create new table 
    lua.newtable(L)

    // set function multiplication
    lua.L_setfuncs(L,raw_data(v_aos), 0)

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

    // stroint information in script
    if (lua.L_dofile(L,"script2.lua")) == 0{   
        lua.pop(L, lua.gettop(L))
    }
    else{
        fmt.println("couldnt load file")
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
    }

    // calling a function
    if (lua.L_dofile(L,"script3.lua")) == 0{  
        // if ok pop it from stack 
        lua.pop(L, lua.gettop(L))
    }
    else{
        fmt.println("couldnt load file")
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
        }
       
    }
    else{
        fmt.println("couldn't load script")
    }

    // calling a function that takes two argument and returns one
    // for script 4
    if (lua.L_dofile(L,"script4.lua")) == 0{   
        lua.pop(L, lua.gettop(L))
    }
    else{
        fmt.println("couldnt load file script4")
    }
    // get function and push arguments
    lua.getglobal(L,cstring("my_function"))
    lua.pushinteger(L,3)
    lua.pushinteger(L,34)

    // Execute my_function with 2 arguments and 1 return value
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
       
    
   // intentional error in string
    faultystring:=cstring("print(return")
    if lua.L_dostring(L, faultystring) != 0 {
        // get error message from lua
        raised_error:= lua.tostring(L,lua.gettop(L))
        fmt.println(raised_error)
        // always pop
        lua.pop(L,lua.gettop(L))
    }

    


}

