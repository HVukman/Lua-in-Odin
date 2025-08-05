package main

import "core:fmt"
import lua "vendor:lua/5.4" // or whatever version you want
import "core:c"
import "core:c/libc"
import "base:runtime"
import "core:testing"
import "core:sys/windows"
import "core:mem"
import "base:intrinsics"
import "core:strings"

account :struct {
    name: [dynamic]cstring,
    balance: i32
}


mt_account_new :: proc "c"(L:^lua.State)->i32 {

    context = runtime.default_context()

    name := lua.L_checkstring(L,1)
    balance := lua.L_checkinteger(L,2)
    dist := libc.size_t(size_of(account))

    new := account
    self : = lua.newuserdata(L,libc.size_t(size_of(new)))

    append_elem(&new.name, name)
    new.balance = i32(balance)
    
    lua.L_setmetatable(L,cstring("mt_account"))
    return 1
}

push_mt_account :: proc "c"(L:^lua.State) -> int{
   // push new account
    context = runtime.default_context()
    L_Reg1 : lua.L_Reg

    L_Reg1.func=mt_account_new
    L_Reg1.name=cstring("mt_account_new")

    lua.L_newmetatable(L,"mt_account")
    lua.L_setfuncs(L,&L_Reg1, 0)
    
    lua.pushvalue(L,-1)
    lua.setfield(L,-2,"__index")

    return 1
}

mt_account_delete:: proc "c" (L:^lua.State)->i32 {
 // delete account
  context = runtime.default_context()
  dist := libc.size_t(size_of(account))

  new := account
  self := lua.L_checkudata(L,1,"mt_account")
  delete (new.name)
  
  return 0;
}

mt_account_deposit:: proc "c" (L:^lua.State)->i32 {
  context = runtime.default_context()

  new := account
  self := lua.L_checkudata(L,1,"mt_account")
  n := lua.L_checknumber(L, 2);
  new.balance += i32(n);

  return 0;
}

mt_account_withdraw:: proc "c" (L:^lua.State)->i32 {
   context = runtime.default_context()

  new := account
  self := lua.L_checkudata(L,1,"mt_account")
  n := lua.L_checknumber(L, 2);
  new.balance -= i32(n);

  return 0;
}

mt_account_get_name:: proc "c" (L:^lua.State)->i32 {
  context = runtime.default_context()

  new := account
  self := lua.L_checkudata(L,1,"mt_account")
  name := new.name[:]
  builder := strings.builder_from_bytes(transmute([]u8)name)
  finally := strings.to_cstring(&builder)
  
  lua.pushstring(L, finally );
  return 1;
}

mt_account_get_balance:: proc "c" (L:^lua.State)->i32 {
  new := account
  self := lua.L_checkudata(L,1,"mt_account")
  balance := lua.L_checkinteger(L,new.balance)
  lua.pushinteger(L,balance)
  
  return 1;
}

register_mt_account:: proc "c" (L:^lua.State)->i32 {
    context = runtime.default_context()
    L_Reg1 : lua.L_Reg
   // creating the fields for Account
   L_Reg1.func=mt_account_new
   L_Reg1.name=cstring("new")
   L_Reg1.func= mt_account_delete
   L_Reg1.name=cstring("__gc")
   L_Reg1.func= mt_account_deposit
   L_Reg1.name=cstring("deposit")
   L_Reg1.func= mt_account_withdraw
   L_Reg1.name=cstring("withdraw")
   L_Reg1.func= mt_account_get_name
   L_Reg1.name=cstring("get_name")
   L_Reg1.func= mt_account_get_balance
   L_Reg1.name=cstring("get_balance")
   L_Reg1.func = nil
   L_Reg1.name = nil

  
    lua.L_setfuncs(L,&L_Reg1,0)
    lua.L_newmetatable(L, cstring("mt_account"))
  
    lua.pushvalue(L,-1)
    lua.setfield(L,-2,"__index")

    return 1;
}

open_sys :: proc "c" (L:^lua.State)->i32{
    
    context = runtime.default_context()
    L_Reg1 : lua.L_Reg
    v_aos: [1]lua.L_Reg 
   
    v_aos[0]=L_Reg1

    lua.L_newlib(L,v_aos[:])
    register_mt_account(L)
    lua.setfield(L,-2,"Account")

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
   
     // calling sys
    lua.L_requiref(L, "sys", open_sys, 1)

    
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
    
    // test metatable (not working :( )
    new_string:=cstring("local acc = sys.Account.new(\"Jason\", 1000) \n print(string.format(\"name: %s, balance: %d\", acc:get_name(), acc:get_balance()))")
    if lua.L_dostring(L, new_string) != 0 {
        // get error message from lua
        raised_error:= lua.tostring(L,lua.gettop(L))
        fmt.println(raised_error)
        // always pop
        lua.pop(L,lua.gettop(L))
    }



  


}


