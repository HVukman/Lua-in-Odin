Adapted from: https://lucasklassmann.com/blog/2019-02-02-embedding-lua-in-c/

Just run: odin run .

Shows:
  * Starting a Lua state
  * Defining variables for Lua
  * Doing Lua Strings in Odin
  * Loading scripts
  * Creating functions in Odin for Lua
  * Creating a namespace in Odin for Lua and adding functions
  * Calling Lua functions from Odin with and without return
  * Getting errors from Lua

Don't forget the lua files.

Update 08-05-2025: Removed the dynamic allocations, since they are not needed. Added tests. Trying to do metatables, but the fields of the tables are not recognized.
